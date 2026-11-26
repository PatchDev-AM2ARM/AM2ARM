package ${YYAndroidPackageName};

import android.content.ContentResolver;
import android.content.Intent;
import android.database.Cursor;
import android.net.Uri;
import android.provider.DocumentsContract;
import android.util.Log;

import com.yoyogames.runner.RunnerJNILib;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.HashMap;
import java.util.Locale;
import java.util.Map;
import java.util.Arrays;

/**
 * Save backup/restore for the AM2R Android port.
 *
 * Saves live in app-private storage, unreachable without root; this class is
 * the player-facing way across that wall. Backup writes the save files into a
 * timestamped subfolder of a user-picked SAF tree; Restore copies allowlisted
 * files back in from a picked folder (which may be a copy of the PC save
 * directory -- GML validates and converts the format). Raw DocumentsContract only: the
 * runner does not bundle androidx.documentfile.
 *
 * Individual save files are bounded to 1 MiB, so I/O runs inline on the callback thread.
 */
public class AM2RSaveTransfer extends ExtensionBase
{
    private static final String TAG = "yoyo";
    private static final int REQ_BACKUP  = 0x4D01;
    private static final int REQ_RESTORE = 0x4D02;
    private static final int EVENT_OTHER_SOCIAL = 70;
    private static final String[] SAVE_FILES =
        { "save1", "save2", "save3", "data.sav", "extras.sav" };
    private static final long MAX_SAVE_BYTES = SaveTransferFiles.MAX_BYTES;
    private SaveSyncAndroid saveSync;

    private synchronized SaveSyncAndroid sync() {
        if (saveSync == null) saveSync = new SaveSyncAndroid(RunnerActivity.CurrentActivity, this::sendSyncResult);
        return saveSync;
    }

    public double SaveSync_SetText(String json) { return sync().setText(json) ? 1 : 0; }

    public double SaveSync_Configured() { return sync().configured() ? 1 : 0; }
    public double SaveSync_Busy() { return sync().busy() ? 1 : 0; }
    public double SaveSync_SelectFolder() {
        try { return sync().selectFolder() ? 1 : 0; }
        catch (Exception unavailable) { return 0; }
    }
    public double SaveSync_Disable() { return sync().disable() ? 1 : 0; }
    public double SaveSync_Check(double allowImport, double review) { return sync().check(allowImport != 0, review != 0); }
    public double SaveSync_Choose(double choice) { return sync().choose((int) choice) ? 1 : 0; }
    public double SaveSync_Apply() { return sync().apply() ? 1 : 0; }
    public double SaveSync_Complete() { return sync().complete() ? 1 : 0; }
    public double SaveSync_Cancel() { sync().cancel(); return 1; }

    private void sendSyncResult(int ticket, String action, String detail, String names, int choice) {
        int map = RunnerJNILib.jCreateDsMap(null, null, null);
        RunnerJNILib.DsMapAddString(map, "type", "am2r_savesync");
        RunnerJNILib.DsMapAddDouble(map, "ticket", ticket);
        RunnerJNILib.DsMapAddString(map, "action", action);
        RunnerJNILib.DsMapAddString(map, "detail", detail);
        RunnerJNILib.DsMapAddString(map, "names", names);
        RunnerJNILib.DsMapAddDouble(map, "choice", choice);
        RunnerJNILib.CreateAsynEventWithDSMap(map, EVENT_OTHER_SOCIAL);
    }

    // The return value reports the picker launch request; completion arrives later through the Social event.
    public double SaveTransfer_Backup()  { return launchPicker(REQ_BACKUP); }
    public double SaveTransfer_Restore() {
        if (sync().busy()) return 0;
        try { clearStages(); return launchPicker(REQ_RESTORE); }
        catch (Exception e) { sendResult("restore", false, 0); return 0; }
    }

    // Startup calls this before reading saves so an interrupted replacement can be recovered.
    public double SaveTransfer_Recover() {
        try { new SaveTransferFiles(filesDir()).recover(); return 1; }
        catch (Exception e) { Log.e(TAG, "AM2RSaveTransfer :: recovery pending", e); return -1; }
    }

    // GML validates the chosen stage before asking this bridge to replace the selected live save.
    public double SaveTransfer_Apply(String source, String target) {
        if (sync().busy()) return 0;
        try { new SaveTransferFiles(filesDir()).apply(source, target); return 1; }
        catch (Exception e) { Log.e(TAG, "AM2RSaveTransfer :: restore not applied", e); return 0; }
    }

    private void clearStages() throws IOException {
        // Discard prior import stages before a new folder selection can supply replacements.
        for (String name : SAVE_FILES) {
            File file = new File(filesDir(), "restorestage_" + name);
            if (file.exists() && !file.delete()) throw new IOException("Cannot clear prior restore");
        }
    }

    private double launchPicker(int req)
    {
        if (sync().busy()) return 0;
        RunnerActivity act = RunnerActivity.CurrentActivity;
        if (act == null) return 0.0;
        Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT_TREE);
        try {
            act.startActivityForResult(i, req);
            return 1.0;
        } catch (Exception e) {
            Log.e(TAG, "AM2RSaveTransfer :: no picker available", e);
            sendResult(req == REQ_BACKUP ? "backup" : "restore", false, 0);
            return 0.0;
        }
    }

    @Override
    public void onActivityResult(int requestCode, int resultCode, Intent data)
    {
        if (requestCode == SaveSyncAndroid.PICK_FOLDER) { sync().selected(resultCode, data); return; }
        // Handle only this extension's folder selections; cancellation is reported separately from failure.
        if (requestCode != REQ_BACKUP && requestCode != REQ_RESTORE) return;
        String action = (requestCode == REQ_BACKUP) ? "backup" : "restore";
        if (resultCode != android.app.Activity.RESULT_OK || data == null || data.getData() == null) {
            sendResult(action, false, -1);   // cancelled -- GML stays silent
            return;
        }
        try {
            if (requestCode == REQ_BACKUP) doBackup(data.getData());
            else                           doStage(data.getData());
        } catch (Exception e) {
            Log.e(TAG, "AM2RSaveTransfer :: " + action + " failed", e);
            sendResult(action, false, 0);
        }
    }

    private File filesDir()
    {
        return RunnerActivity.CurrentActivity.getFilesDir();
    }

    private void doBackup(Uri tree) throws Exception
    {
        // Missing conversion is a failure, never a raw Android-format fallback.
        int expected = 0;
        for (String name : SAVE_FILES) {
            File src = new File(filesDir(), "backupstage_" + name);
            if (src.isFile()) expected++;
            else if (new File(filesDir(), name).exists()) throw new IOException("Save export incomplete");
        }
        if (expected == 0) { sendResult("backup", false, 0); return; }
        // Create a fresh backup directory inside the folder chosen by the player.
        ContentResolver cr = RunnerActivity.CurrentActivity.getContentResolver();
        Uri parent = DocumentsContract.buildDocumentUriUsingTree(tree, DocumentsContract.getTreeDocumentId(tree));
        String stamp = new SimpleDateFormat("yyyyMMdd-HHmmss", Locale.US).format(new Date());
        Uri dir = DocumentsContract.createDocument(cr, parent,
                DocumentsContract.Document.MIME_TYPE_DIR, "AM2R-Backup-" + stamp);
        if (dir == null) throw new IOException("Cannot create backup folder");
        int copied = 0;
        try {
            for (String name : SAVE_FILES) {
                File src = new File(filesDir(), "backupstage_" + name);
                if (!src.isFile()) continue;
                Uri dst = DocumentsContract.createDocument(cr, dir, "application/octet-stream", name);
                if (dst == null) throw new IOException("Cannot create backup file");
                try (InputStream in = new FileInputStream(src); OutputStream out = cr.openOutputStream(dst)) {
                    pipe(in, out);
                }
                // Read each exported file back and compare its hash with the converted local stage.
                try (InputStream check = cr.openInputStream(dst)) {
                    if (check == null || !Arrays.equals(SaveTransferFiles.hash(src), SaveTransferFiles.hash(check)))
                        throw new IOException("Backup verification failed");
                }
                copied++;
            }
        } catch (Exception failure) {
            // This directory was created by this operation, never an existing backup.
            try { DocumentsContract.deleteDocument(cr, dir); } catch (Exception cleanupFailure) { }
            throw failure;
        }
        sendResult("backup", copied == expected, copied);
    }

    private void doStage(Uri tree) throws Exception
    {
        clearStages();
        ContentResolver cr = RunnerActivity.CurrentActivity.getContentResolver();
        Uri children = DocumentsContract.buildChildDocumentsUriUsingTree(
                tree, DocumentsContract.getTreeDocumentId(tree));
        // Accept only known save filenames and reject ambiguous duplicates in the selected folder.
        Map<String, Uri> found = new HashMap<>();
        try (Cursor c = cr.query(children, new String[]{
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
                DocumentsContract.Document.COLUMN_DISPLAY_NAME }, null, null, null)) {
            if (c == null) throw new IOException("Cannot read backup folder");
            while (c.moveToNext()) {
                String docId = c.getString(0), name = c.getString(1);
                for (String want : SAVE_FILES)
                    if (want.equals(name)) {
                        if (found.containsKey(name)) throw new IOException("Duplicate save filename");
                        found.put(name, DocumentsContract.buildDocumentUriUsingTree(tree, docId));
                    }
            }
        }
        // Stage each valid file under a flat prefixed name; skip (and remove)
        // anything unreadable or absurdly sized. GML applies the player's picks.
        int staged = 0;
        boolean[] flag = new boolean[SAVE_FILES.length];
        for (int i = 0; i < SAVE_FILES.length; i++) {
            Uri src = found.get(SAVE_FILES[i]);
            if (src == null) continue;
            File dst = new File(filesDir(), "restorestage_" + SAVE_FILES[i]);
            dst.delete();
            try (InputStream in = cr.openInputStream(src);
                 OutputStream out = new FileOutputStream(dst)) {
                pipe(in, out);
            } catch (Exception e) {
                dst.delete();
                continue;
            }
            long len = dst.length();
            if (len <= 0 || len > MAX_SAVE_BYTES) { dst.delete(); continue; }
            flag[i] = true;
            staged++;
        }
        // Report available stages to GML; format validation and the player's restore choice still follow.
        Log.i(TAG, "AM2RSaveTransfer :: staged " + staged + " file(s)");
        int map = RunnerJNILib.jCreateDsMap(null, null, null);
        RunnerJNILib.DsMapAddString(map, "type", "am2r_savetransfer");
        RunnerJNILib.DsMapAddString(map, "action", "restore");
        RunnerJNILib.DsMapAddDouble(map, "success", staged > 0 ? 1.0 : 0.0);
        RunnerJNILib.DsMapAddDouble(map, "files", staged);
        RunnerJNILib.DsMapAddDouble(map, "found_save1", flag[0] ? 1.0 : 0.0);
        RunnerJNILib.DsMapAddDouble(map, "found_save2", flag[1] ? 1.0 : 0.0);
        RunnerJNILib.DsMapAddDouble(map, "found_save3", flag[2] ? 1.0 : 0.0);
        RunnerJNILib.DsMapAddDouble(map, "found_unlocks", flag[3] ? 1.0 : 0.0);
        RunnerJNILib.CreateAsynEventWithDSMap(map, EVENT_OTHER_SOCIAL);
    }

    private static void pipe(InputStream in, OutputStream out) throws Exception
    {
        SaveTransferFiles.pipe(in, out);
    }

    // Deliver backup or picker status to the game through its asynchronous Social event.
    private void sendResult(String action, boolean ok, int files)
    {
        int map = RunnerJNILib.jCreateDsMap(null, null, null);
        RunnerJNILib.DsMapAddString(map, "type", "am2r_savetransfer");
        RunnerJNILib.DsMapAddString(map, "action", action);
        RunnerJNILib.DsMapAddDouble(map, "success", ok ? 1.0 : 0.0);
        RunnerJNILib.DsMapAddDouble(map, "files", files);
        RunnerJNILib.CreateAsynEventWithDSMap(map, EVENT_OTHER_SOCIAL);
    }
}
