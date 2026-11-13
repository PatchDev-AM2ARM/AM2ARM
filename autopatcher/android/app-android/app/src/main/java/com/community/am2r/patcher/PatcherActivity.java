package com.community.am2r.patcher;

import android.app.Activity;
import android.animation.ValueAnimator;
import android.content.Intent;
import android.content.res.ColorStateList;
import android.graphics.Typeface;
import android.graphics.Paint;
import android.graphics.drawable.ColorDrawable;
import android.graphics.drawable.StateListDrawable;
import android.media.AudioAttributes;
import android.media.SoundPool;
import android.net.Uri;
import android.os.Bundle;
import android.os.SystemClock;
import android.view.Gravity;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.View;
import android.util.TypedValue;
import android.view.animation.LinearInterpolator;
import android.widget.Button;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ProgressBar;
import android.widget.ScrollView;
import android.widget.TextView;

public final class PatcherActivity extends Activity implements PatchJob.Listener {
    private static final int PICK_ZIP = 1;
    private static final int ACCENT = 0xffffffff, PALE = 0xffffffff;
    private Typeface menuFont, smallFont;
    private TitleBackdrop backdrop;
    private ImageView banner;
    private View menuColumns;
    private ValueAnimator intro;
    private TextView status, editionHelp;
    private ProgressBar bar;
    private Button standard, dual, pick, install;
    private String edition = "standard";
    private PatchJob job;
    private Uri outputUri;
    private String outputName;
    private int navDirection;
    private long navTime;
    private SoundPool menuSounds;
    private int menuSound;
    private boolean menuSoundReady;

    @Override public void onCreate(Bundle saved) {
        super.onCreate(saved);
        menuFont = getResources().getFont(R.font.am2r_menu);
        smallFont = getResources().getFont(R.font.am2r_small);
        // Load the original menu beep once; Android's media volume controls its playback.
        menuSounds = new SoundPool.Builder().setMaxStreams(2).setAudioAttributes(new AudioAttributes.Builder()
                .setUsage(AudioAttributes.USAGE_GAME).setContentType(AudioAttributes.CONTENT_TYPE_SONIFICATION).build()).build();
        menuSounds.setOnLoadCompleteListener((pool, sound, result) -> menuSoundReady = result == 0);
        menuSound = menuSounds.load(this, R.raw.menu_move, 1);
        // Restore the edition choice and any saved output information when the activity is recreated.
        edition = getPreferences(MODE_PRIVATE).getString("edition", "standard");
        if (!edition.equals("dual")) edition = "standard";
        if (saved != null) {
            edition = saved.getString("edition", edition);
            outputName = saved.getString("outputName");
            String uri = saved.getString("outputUri");
            if (uri != null) outputUri = Uri.parse(uri);
        }
        // Reconnect to a retained patch operation so a configuration change can keep showing its progress.
        job = (PatchJob) getLastNonConfigurationInstance();
        buildLayout();
        if (job != null) { edition = job.edition; job.attach(this); }
        refreshEdition(); immersive();
        if (saved == null && job == null) playIntro();
    }
    private int dp(float n) { return Math.round(n * getResources().getDisplayMetrics().density); }
    private TextView label(String text, int size, int color) {
        TextView v = new TextView(this);
        v.setText(text); v.setTextColor(color); gameFont(v, size, size > 12);
        return v;
    }
    private void gameFont(TextView view, int size, boolean menu) {
        // Choose whole font-pixel sizes and disable smoothing for the original menu lettering.
        int base = menu ? 13 : 8;
        int scale = Math.max(1, Math.round(size * getResources().getDisplayMetrics().scaledDensity / base));
        view.setTypeface(menu ? menuFont : smallFont);
        view.setTextSize(TypedValue.COMPLEX_UNIT_PX, base * scale);
        view.setIncludeFontPadding(false);
        view.setPaintFlags(view.getPaintFlags() & ~Paint.ANTI_ALIAS_FLAG & ~Paint.SUBPIXEL_TEXT_FLAG);
    }
    private Button button(String text) {
        Button v = new Button(this) {
            @Override public boolean performClick() {
                if (isEnabled()) playMenuBeep();
                return super.performClick();
            }
        };
        v.setSoundEffectsEnabled(false);
        v.setOnFocusChangeListener((view, focused) -> {
            if (focused && !view.isInTouchMode()) playMenuBeep();
        });
        v.setText(text); v.setTextColor(PALE); gameFont(v, 21, true);
        v.setGravity(Gravity.CENTER_VERTICAL | Gravity.LEFT); v.setAllCaps(false);
        v.setMaxLines(1); v.setHorizontallyScrolling(false);
        // Fit long labels in whole font-pixel steps without wrapping or smoothing the lettering.
        int[] sizes = new int[Math.max(1, Math.round(v.getTextSize() / 13))];
        for (int i = 0; i < sizes.length; i++) sizes[i] = 13 * (i + 1);
        v.setAutoSizeTextTypeUniformWithPresetSizes(sizes, TypedValue.COMPLEX_UNIT_PX);
        v.setMinWidth(0); v.setMinimumWidth(0);
        v.setMinHeight(dp(48)); v.setMinimumHeight(dp(48)); v.setPadding(dp(10), dp(8), dp(10), dp(8));
        v.setStateListAnimator(null);
        // Give pressed, focused, and selected controls distinct backgrounds for touch and controller navigation.
        StateListDrawable bg = new StateListDrawable();
        bg.addState(new int[]{android.R.attr.state_pressed}, new ColorDrawable(0xcc707070));
        bg.addState(new int[]{android.R.attr.state_focused}, new ColorDrawable(0xcc4b4b4b));
        bg.addState(new int[]{android.R.attr.state_selected}, new ColorDrawable(0xaa282828));
        bg.addState(new int[]{}, new ColorDrawable(0x00000000));
        v.setBackground(bg); v.setFocusable(true); v.setId(View.generateViewId()); return v;
    }
    private void playMenuBeep() {
        // Keep startup, the intro, and background activity changes silent.
        if (menuSounds != null && menuSoundReady && hasWindowFocus()
                && menuColumns != null && menuColumns.getAlpha() == 1) {
            menuSounds.play(menuSound, 1, 1, 1, 0, 1);
        }
    }
    private void buildLayout() {
        FrameLayout frame = new FrameLayout(this);
        backdrop = new TitleBackdrop(this);
        frame.addView(backdrop, new FrameLayout.LayoutParams(-1, -1));
        ScrollView scroll = new ScrollView(this);
        scroll.setFillViewport(true);
        scroll.setClipToPadding(false);
        scroll.setPadding(0, dp(8), 0, dp(8));
        FrameLayout.LayoutParams viewport = new FrameLayout.LayoutParams(-1, -1);
        viewport.bottomMargin = dp(24);
        frame.addView(scroll, viewport);
        LinearLayout body = new LinearLayout(this);
        body.setOrientation(LinearLayout.VERTICAL);
        body.setGravity(Gravity.CENTER);
        scroll.addView(body, new ScrollView.LayoutParams(-1, -2));
        banner = new ImageView(this);
        banner.setImageResource(R.drawable.am2arm_banner);
        banner.setScaleType(ImageView.ScaleType.FIT_CENTER);
        banner.setContentDescription("AM2ARM Autopatcher");
        body.addView(banner, new LinearLayout.LayoutParams(dp(320), dp(86)));
        LinearLayout menu = new LinearLayout(this);
        menuColumns = menu;
        menu.setOrientation(LinearLayout.VERTICAL);
        menu.setPadding(0, dp(4), 0, dp(4));
        body.addView(menu, new LinearLayout.LayoutParams(-1, -2));
        TextView version = label("AUTOPATCHER  1.6.1", 12, PALE);
        version.setGravity(Gravity.CENTER);
        version.setPadding(0, 0, 0, dp(8));
        menu.addView(version);
        standard = button("STANDARD");
        dual = button("DUAL SCREEN");
        menu.addView(standard, new LinearLayout.LayoutParams(-1, dp(48)));
        menu.addView(dual, new LinearLayout.LayoutParams(-1, dp(48)));
        standard.setOnClickListener(v -> selectEdition("standard"));
        dual.setOnClickListener(v -> selectEdition("dual"));
        editionHelp = label("", 12, 0xffcccccc);
        editionHelp.setPadding(dp(10), dp(3), dp(10), dp(5));
        menu.addView(editionHelp);
        pick = button("CHOOSE AM2R 1.1 ZIP");
        pick.setOnClickListener(v -> pickZip());
        menu.addView(pick, new LinearLayout.LayoutParams(-1, dp(48)));
        bar = new ProgressBar(this, null, android.R.attr.progressBarStyleHorizontal);
        bar.setMax(1000);
        bar.setProgressTintList(ColorStateList.valueOf(ACCENT));
        bar.setProgressBackgroundTintList(ColorStateList.valueOf(0xff333333));
        LinearLayout.LayoutParams meter = new LinearLayout.LayoutParams(-1, dp(4));
        meter.topMargin = dp(5);
        menu.addView(bar, meter);
        status = label("Select your original Windows 1.1 ZIP.\nYour source file stays unchanged.", 10, PALE);
        status.setPadding(dp(10), dp(5), dp(10), dp(5));
        menu.addView(status);
        install = button("INSTALL AM2ARM");
        install.setOnClickListener(v -> installApk());
        install.setVisibility(outputUri == null ? View.GONE : View.VISIBLE);
        menu.addView(install, new LinearLayout.LayoutParams(-1, dp(48)));
        TextView link = label("github.com/PatchDev-AM2ARM/AM2ARM", 8, PALE);
        link.setGravity(Gravity.RIGHT);
        FrameLayout.LayoutParams footer = new FrameLayout.LayoutParams(-1, -2, Gravity.BOTTOM);
        footer.setMargins(dp(12), 0, dp(12), dp(6));
        frame.addView(link, footer);
        frame.addOnLayoutChangeListener((v, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom) -> {
            int pictureWidth = Math.min(right-left, Math.round((bottom-top)*426f/240));
            int sideBar = (right-left-pictureWidth)/2;
            int width = Math.min(pictureWidth-dp(32), dp(520));
            int logoHeight = Math.min(dp(104), Math.max(dp(44), Math.round((bottom-top)*.18f)));
            int logoWidth = Math.min(pictureWidth-dp(32), Math.round(logoHeight*1920f/521));
            if (menu.getLayoutParams().width != width)
                menu.setLayoutParams(new LinearLayout.LayoutParams(width, -2));
            if (banner.getLayoutParams().width != logoWidth || banner.getLayoutParams().height != logoHeight)
                banner.setLayoutParams(new LinearLayout.LayoutParams(logoWidth, logoHeight));
            if (footer.rightMargin != sideBar+dp(12)) {
                footer.setMargins(sideBar+dp(12), 0, sideBar+dp(12), dp(6));
                link.setLayoutParams(footer);
            }
        });
        setContentView(frame);
        (edition.equals("dual") ? dual : standard).requestFocus();
        refreshEdition();
    }
    private void selectEdition(String next) {
        if (job != null && job.running) return;
        // Changing editions clears the prior result and remembers the new preference for the next launch.
        if (!edition.equals(next)) {
            edition = next; outputUri = null; outputName = null; job = null;
            install.setVisibility(View.GONE); bar.setProgress(0);
            status.setText("Select your original Windows 1.1 ZIP.\nYour source file stays unchanged.");
            getPreferences(MODE_PRIVATE).edit().putString("edition", edition).apply();
        }
        refreshEdition();
    }
    private void refreshEdition() {
        standard.setSelected(edition.equals("standard")); dual.setSelected(edition.equals("dual"));
        editionHelp.setText(edition.equals("dual") ? "Gameplay above. Map below."
                : "Gameplay on a single screen");
        // Disable edition and source changes while the current operation is running.
        boolean busy = job != null && job.running;
        for (Button b : new Button[]{standard, dual, pick}) { b.setEnabled(!busy); b.setAlpha(busy ? .5f : 1); }
        install.setText(edition.equals("dual") ? "INSTALL DUAL SCREEN" : "INSTALL STANDARD");
    }
    // Ask the system document picker for the player's original ZIP; patching starts in its result callback.
    private void pickZip() {
        Intent i = new Intent(Intent.ACTION_OPEN_DOCUMENT); i.addCategory(Intent.CATEGORY_OPENABLE); i.setType("*/*");
        i.putExtra(Intent.EXTRA_MIME_TYPES, new String[]{"application/zip", "application/octet-stream", "application/x-zip-compressed"});
        startActivityForResult(i, PICK_ZIP);
    }
    @Override protected void onActivityResult(int request, int result, Intent data) {
        super.onActivityResult(request, result, data);
        if (request != PICK_ZIP || result != RESULT_OK || data == null || data.getData() == null) return;
        if (job != null && job.running) return;
        outputUri = null; outputName = null; install.setVisibility(View.GONE);
        // Capture this source and edition in a new operation, attach the UI, then start its background thread.
        job = new PatchJob(getApplicationContext(), edition, data.getData()); job.attach(this); refreshEdition(); job.start();
    }
    @Override public void onPatchUpdate(PatchJob updated) {
        // Ignore updates from a replaced operation or an activity that is already closing.
        if (isFinishing() || job != updated) return;
        bar.setIndeterminate(updated.running && updated.progress < 0);
        if (updated.progress >= 0) bar.setProgress(updated.progress);
        status.setText(updated.message); outputUri = updated.outputUri; outputName = updated.outputName;
        install.setVisibility(outputUri == null ? View.GONE : View.VISIBLE); refreshEdition();
    }
    // Keep Android's installation result available for reporting compatibility problems.
    private void installApk() {
        if (outputUri == null) return;
        startActivity(new Intent(this, InstallActivity.class).setData(outputUri).putExtra("edition", edition));
    }
    // Retain the operation across configuration changes while detaching each destroyed activity's listener.
    @Override public Object onRetainNonConfigurationInstance() { return job; }
    @Override protected void onPause() { finishIntro(); super.onPause(); }
    @Override protected void onDestroy() {
        finishIntro();
        if (job != null) job.detach(this);
        if (menuSounds != null) { menuSounds.release(); menuSounds = null; }
        super.onDestroy();
    }
    @Override protected void onSaveInstanceState(Bundle out) {
        out.putString("edition", edition); out.putString("outputName", outputName);
        if (outputUri != null) out.putString("outputUri", outputUri.toString()); super.onSaveInstanceState(out);
    }
    private void immersive() {
        getWindow().getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY | View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION);
    }
    @Override public void onWindowFocusChanged(boolean focus) { super.onWindowFocusChanged(focus); if (focus) immersive(); }
    private void playIntro() {
        if (!ValueAnimator.areAnimatorsEnabled()) return;
        backdrop.setIntroProgress(0, 0); banner.setAlpha(0f); menuColumns.setAlpha(0);
        menuColumns.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_NO_HIDE_DESCENDANTS);
        intro = ValueAnimator.ofFloat(0, 1); intro.setDuration(1200);
        intro.setInterpolator(new LinearInterpolator());
        // Slide the artwork into place before revealing the menu and restoring its accessibility descendants.
        intro.addUpdateListener(animation -> {
            float progress = (float)animation.getAnimatedValue();
            float elapsed = progress * 1.2f;
            float slide = Math.min(1, elapsed / .85f);
            backdrop.setIntroProgress(1 - (float)Math.pow(1 - slide, 3), Math.min(1, elapsed / .3f));
            banner.setAlpha(Math.min(1, Math.max(0, (elapsed - .5f) / .45f)));
            menuColumns.setAlpha(Math.min(1, Math.max(0, (elapsed - .85f) / .35f)));
            if (progress >= 1) menuColumns.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO);
        });
        menuColumns.post(() -> { if (intro != null) intro.start(); });
    }
    private void finishIntro() {
        if (intro == null) return;
        intro.cancel(); intro = null; backdrop.setIntroProgress(1, 1); banner.setAlpha(1f); menuColumns.setAlpha(1);
        menuColumns.setImportantForAccessibility(View.IMPORTANT_FOR_ACCESSIBILITY_AUTO);
    }
    // Consume the touch that skips the intro so it cannot also activate a menu control.
    @Override public boolean dispatchTouchEvent(MotionEvent event) {
        if (intro != null && intro.isRunning()) {
            if (event.getAction() == MotionEvent.ACTION_UP) finishIntro();
            return true;
        }
        return super.dispatchTouchEvent(event);
    }
    @Override public boolean dispatchKeyEvent(KeyEvent event) {
        if (intro != null && intro.isRunning()) {
            if (event.getAction() == KeyEvent.ACTION_UP) finishIntro();
            return true;
        }
        // Let the controller's confirm button activate whichever menu control currently has focus.
        if (event.getKeyCode() == KeyEvent.KEYCODE_BUTTON_A) {
            if (event.getAction() == KeyEvent.ACTION_UP && getCurrentFocus() != null) getCurrentFocus().performClick(); return true;
        }
        // Move directional-button focus here so Android does not add its own navigation tone.
        if (event.hasNoModifiers()) {
            int dir = 0;
            switch (event.getKeyCode()) {
                case KeyEvent.KEYCODE_DPAD_UP: dir = View.FOCUS_UP; break;
                case KeyEvent.KEYCODE_DPAD_DOWN: dir = View.FOCUS_DOWN; break;
                case KeyEvent.KEYCODE_DPAD_LEFT: dir = View.FOCUS_LEFT; break;
                case KeyEvent.KEYCODE_DPAD_RIGHT: dir = View.FOCUS_RIGHT; break;
            }
            if (dir != 0) {
                if (event.getAction() == KeyEvent.ACTION_DOWN) {
                    View focus = getCurrentFocus(), next = focus == null ? pick : focus.focusSearch(dir);
                    if (next != null) next.requestFocus(dir);
                }
                return true;
            }
        }
        return super.dispatchKeyEvent(event);
    }
    @Override public boolean onGenericMotionEvent(MotionEvent e) {
        if ((e.getSource() & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK) {
            float x = e.getAxisValue(MotionEvent.AXIS_HAT_X), y = e.getAxisValue(MotionEvent.AXIS_HAT_Y);
            if (Math.abs(x) < .5f) x = e.getAxisValue(MotionEvent.AXIS_X);
            if (Math.abs(y) < .5f) y = e.getAxisValue(MotionEvent.AXIS_Y);
            // Turn hat or stick movement into focus navigation with a delay between repeated moves.
            int dir = Math.abs(y) > .5f ? (y < 0 ? View.FOCUS_UP : View.FOCUS_DOWN)
                    : Math.abs(x) > .5f ? (x < 0 ? View.FOCUS_LEFT : View.FOCUS_RIGHT) : 0;
            long now = SystemClock.uptimeMillis();
            if (dir != 0 && (dir != navDirection || now - navTime > 240)) {
                View focus = getCurrentFocus(), next = focus == null ? pick : focus.focusSearch(dir);
                if (next != null) next.requestFocus(); navTime = now;
            }
            navDirection = dir; return true;
        }
        return super.onGenericMotionEvent(e);
    }
}
