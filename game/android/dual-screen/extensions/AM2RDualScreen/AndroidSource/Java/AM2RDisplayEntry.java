package ${YYAndroidPackageName};

import android.app.Activity;
import android.app.ActivityOptions;
import android.content.Intent;
import android.graphics.Color;
import android.graphics.drawable.ColorDrawable;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.view.Display;
import android.view.View;

public final class AM2RDisplayEntry extends Activity {
    private static AM2RDisplayEntry pending;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private boolean previewShown, openedGame;
    private final Runnable fallback = () -> { openGame(); finish(); };

    @Override protected void onCreate(Bundle state) {
        super.onCreate(state);
        if (pending != null) pending.finish();
        View preview = null;
        if (getWindowManager().getDefaultDisplay().getDisplayId() != Display.DEFAULT_DISPLAY
                && RunnerActivity.CurrentActivity != null && RunnerActivity.mExtension != null) {
            for (Object extension : RunnerActivity.mExtension) {
                if (extension instanceof AM2RDualScreen) {
                    preview = ((AM2RDualScreen) extension).createResumePreview(this);
                    break;
                }
            }
        }
        if (preview == null) {
            openGame();
            return;
        }
        // Cover the lower launcher with the last map while the upper game surface wakes.
        pending = this;
        previewShown = true;
        getWindow().setBackgroundDrawable(new ColorDrawable(Color.BLACK));
        setContentView(preview);
        AM2RDualScreen.immersive(getWindow());
        if (Build.VERSION.SDK_INT >= 29 && preview.isHardwareAccelerated()) {
            preview.getViewTreeObserver().registerFrameCommitCallback(() -> ui.post(this::openGame));
        } else {
            preview.postOnAnimation(() -> ui.post(this::openGame));
        }
        // A removed display must not leave a loading window behind.
        ui.postDelayed(fallback, 4000);
    }

    private void openGame() {
        if (openedGame || isFinishing()) return;
        openedGame = true;
        // Open the existing game above without first moving its window onto the launcher's screen.
        Intent game = new Intent(this, RunnerActivity.class);
        game.setAction(Intent.ACTION_MAIN);
        game.addCategory(Intent.CATEGORY_LAUNCHER);
        game.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_SINGLE_TOP);
        ActivityOptions options = ActivityOptions.makeBasic();
        if (Build.VERSION.SDK_INT >= 26) options.setLaunchDisplayId(Display.DEFAULT_DISPLAY);
        try {
            startActivity(game, options.toBundle());
        } catch (SecurityException | IllegalArgumentException error) {
            android.util.Log.w("AM2RDualScreen", "Unable to open the upper display", error);
            finish();
        }
        if (!previewShown) finish();
    }

    static void finishAfterLowerDraw(View view) {
        AM2RDisplayEntry entry = pending;
        if (entry == null || !entry.openedGame) return;
        // Retire the cached image only after the live lower window has submitted its frame.
        if (Build.VERSION.SDK_INT >= 29 && view.isHardwareAccelerated()) {
            view.getViewTreeObserver().registerFrameCommitCallback(() -> entry.ui.post(entry::finish));
        } else {
            view.post(entry::finish);
        }
    }

    @Override protected void onDestroy() {
        ui.removeCallbacksAndMessages(null);
        if (pending == this) pending = null;
        super.onDestroy();
    }
}
