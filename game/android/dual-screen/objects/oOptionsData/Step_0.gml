// Async result delivered by oControl's Social event
if (result_pending) {
    result_pending = 0;
    if (result_action == "backup") {
        // Staged PC-format exports are consumed; drop them. (A cancelled
        // picker never reaches here -- stale stages are cleared and rebuilt
        // by scr_stage_export_pc on the next backup.)
        file_delete("backupstage_save1");
        file_delete("backupstage_save2");
        file_delete("backupstage_save3");
        file_delete("backupstage_data.sav");
        file_delete("backupstage_extras.sav");
        if (result_ok) global.tiptext = get_text("Misc", "BackupDone");
        else global.tiptext = get_text("Misc", "BackupFail");
    } else {
        if (result_ok) {
            // Staged files may be PC-format (different game_id keystream);
            // convert in place before anything reads or applies them.
            found1 = scr_stage_normalize("restorestage_save1") == 1;
            found2 = scr_stage_normalize("restorestage_save2") == 1;
            found3 = scr_stage_normalize("restorestage_save3") == 1;
            foundu = scr_stage_normalize("restorestage_data.sav") == 1;
            if (scr_stage_normalize("restorestage_extras.sav") < 0) foundu = 0;
            if (!(found1 || found2 || found3 || foundu)) {
                global.tiptext = get_text("Misc", "RestoreFail");
                exit;
            }
            var p = instance_create(x, y, oDataRestorePicker);
            p.has_slot[0] = found1;
            p.has_slot[1] = found2;
            p.has_slot[2] = found3;
            p.has_unlocks = foundu;
            with (p) event_user(0);
            instance_destroy();
            exit;
        } else global.tiptext = get_text("Misc", "RestoreFail");
    }
}

// Preserve ordinary backup/restore while sharing their stages with one sync at a time.
op[1].enabled = !ingame;
if (global.android_app) {
    op[3].enabled = global.am2r_sync.enabled;
    op[4].enabled = global.am2r_sync.enabled && !ingame;
    op[5].enabled = global.am2r_sync.enabled;
    tip[3] = global.am2r_sync.message;
}
if (active) {
    if (oControl.kDown && oControl.kDownPushedSteps == 0) {
        repeat (lastitem + 1) {
            global.curropt = (global.curropt + 1) mod (lastitem + 1);
            if (op[global.curropt].enabled) break;
        }
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    }
    if (oControl.kUp && oControl.kUpPushedSteps == 0) {
        repeat (lastitem + 1) {
            global.curropt = (global.curropt + lastitem) mod (lastitem + 1);
            if (op[global.curropt].enabled) break;
        }
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    }
    if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
        if (global.curropt == lastitem) {
            if (global.am2r_sync.busy) save_sync_cancel();
            sfx_play(sndMenuSel);
            instance_create(50, 92, oOptionsMain);
            instance_destroy();
            exit;
        }
        if (!op[global.curropt].enabled) exit;
        if (save_sync_busy() || (global.android_app && SaveSync_Busy())) {
            global.tiptext = port_caption("Please wait for the current transfer to finish.");
            exit;
        }
        sfx_play(sndMenuSel);
        switch (global.curropt) {
            case 0:
                var names = ["save1", "save2", "save3", "data.sav", "extras.sav"];
                var export_ok = true, exported = 0;
                for (var n = 0; n < array_length(names); n++) {
                    var exported_file = scr_stage_export_pc(names[n]);
                    if (exported_file < 0) export_ok = false;
                    if (exported_file == 1) exported++;
                }
                if (export_ok && exported > 0) {
                    if (global.android_app) global.am2r_sync.transfer = SaveTransfer_Backup() == 1;
                    else {
                        result_action = "backup";
                        result_ok = save_folder_backup();
                        result_pending = 1;
                    }
                }
                else {
                    for (var n = 0; n < array_length(names); n++) file_delete("backupstage_" + names[n]);
                    global.tiptext = get_text("Misc", "BackupFail");
                }
                break;
            case 1:
                if (global.android_app) global.am2r_sync.transfer = SaveTransfer_Restore() == 1;
                else {
                    result_action = "restore";
                    result_ok = save_folder_restore();
                    result_pending = 1;
                }
                break;
            case 2:
                global.am2r_sync.picker = SaveSync_SelectFolder() == 1;
                if (!global.am2r_sync.picker) save_sync_notice("The folder picker is unavailable.");
                break;
            case 3: save_sync_request(!ingame, false); break;
            case 4: save_sync_request(true, true); break;
            case 5:
                if (SaveSync_Disable() == 1) {
                    global.am2r_sync.enabled = false;
                    global.am2r_sync.due = -1;
                    save_sync_notice("Save sync is off. Existing saves were kept.");
                }
                break;
        }
    }
}
