package ${YYAndroidPackageName};

import android.app.Presentation;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.graphics.Canvas;
import android.graphics.Color;
import android.graphics.Paint;
import android.graphics.Rect;
import android.hardware.display.DisplayManager;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.opengl.GLES20;
import android.opengl.GLES30;
import android.view.Display;
import android.view.Choreographer;
import android.view.InputDevice;
import android.view.KeyEvent;
import android.view.MotionEvent;
import android.view.ScaleGestureDetector;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowInsets;
import android.view.WindowInsetsController;
import android.view.WindowManager;
import com.yoyogames.runner.RunnerJNILib;
import java.nio.ByteBuffer;

/**
 * Second-screen window, drawing and touch. Game state, layout and map visibility stay in GML.
 * On Linux, the dualscreen plugin of gmloader-next provides the same functions.
 */
public class AM2RDualScreen extends ExtensionBase implements DisplayManager.DisplayListener {
    private volatile int canvasWidth = 320, canvasHeight = 240;
    private final Handler ui = new Handler(Looper.getMainLooper());
    private final Object frameLock = new Object(), inputLock = new Object();
    private byte[] pixels = new byte[canvasWidth * canvasHeight * 4];
    private ByteBuffer pixelBuffer = ByteBuffer.wrap(pixels);
    private DisplayManager displays;
    private LowerPresentation lower;
    private volatile boolean ready, active = true;
    private boolean started, pending, frameLoop;
    // Retain ownership of the lower display on every ordinary launch.
    private final Choreographer.FrameCallback frameCallback = this::onDisplayFrame;
    private volatile int displayId = -1, physicalWidth, physicalHeight;
    private volatile int primaryDisplayId = -1, primaryWidth, primaryHeight;
    private volatile long frames;
    private double dragX, dragY, zoom, touchX, touchY, originX, originY;
    private boolean tapped;
    private volatile boolean lowerFocused;
    private volatile boolean screenSwap, swapFrameReady;
    private PrimaryMapInput primaryInput;
    private ByteBuffer screenPixels;
    private final int[] readState = new int[7];
    private volatile long swapGpuFrames, swapBitmapFrames, swapFailures;
    private volatile int sourceX, sourceY, sourceWidth, sourceHeight;
    private volatile String framePath = "waiting", swapFailure = "";

    public double DualScreen_Swap(double enabled) {
        boolean next = enabled == 1;
        if (screenSwap == next) return next ? 1 : 0;
        screenSwap = next;
        setSwapFrameReady(false);
        synchronized (inputLock) { dragX = dragY = zoom = 0; tapped = false; }
        ui.post(this::updateSwapInput);
        return next ? 1 : 0;
    }

    private void setSwapFrameReady(boolean value) {
        if (swapFrameReady == value) return;
        swapFrameReady = value;
        ui.post(this::updateSwapInput);
    }

    // Called only after GML flushes all Post Draw and Draw GUI batches.
    public double DualScreen_SwapFrame(double requestedX, double requestedY, double requestedWidth, double requestedHeight) {
        if (!screenSwap || !ready || !active) return 0;
        int x = (int) requestedX, y = (int) requestedY;
        int width = (int) requestedWidth, height = (int) requestedHeight;
        if (x < 0 || y < 0 || width < 1 || height < 1
                || width > 4096 || height > 4096 || x > 4096 - width || y > 4096 - height) return 0;
        sourceX = x; sourceY = y; sourceWidth = width; sourceHeight = height;
        AM2RGpuOutput target = output();
        if (target == null) return 0;
        target.captureScreen(x, y, width, height);
        if (target.present(width, height)) {
            swapGpuFrames++;
            framePath = "gpu";
            setSwapFrameReady(true);
            return 1;
        }
        if (readScreenBitmap(x, y, width, height)) {
            swapBitmapFrames++;
            framePath = "bitmap";
            setSwapFrameReady(true);
            return 1;
        }
        swapFailures++;
        framePath = "failed";
        setSwapFrameReady(false);
        return 0;
    }

    private boolean readScreenBitmap(int x, int y, int width, int height) {
        int bytes = width * height * 4;
        if (screenPixels == null || screenPixels.capacity() != bytes)
            screenPixels = ByteBuffer.allocateDirect(bytes);
        String version = GLES20.glGetString(GLES20.GL_VERSION);
        boolean es3 = version != null && version.startsWith("OpenGL ES 3");
        GLES20.glGetIntegerv(GLES20.GL_PACK_ALIGNMENT, readState, 0);
        if (es3) {
            GLES20.glGetIntegerv(GLES30.GL_PIXEL_PACK_BUFFER_BINDING, readState, 1);
            GLES20.glGetIntegerv(GLES30.GL_PACK_ROW_LENGTH, readState, 2);
            GLES20.glGetIntegerv(GLES30.GL_PACK_SKIP_ROWS, readState, 3);
            GLES20.glGetIntegerv(GLES30.GL_PACK_SKIP_PIXELS, readState, 4);
            GLES20.glGetIntegerv(GLES30.GL_READ_FRAMEBUFFER_BINDING, readState, 5);
            GLES20.glGetIntegerv(GLES30.GL_DRAW_FRAMEBUFFER_BINDING, readState, 6);
            if (readState[5] != readState[6])
                GLES30.glBindFramebuffer(GLES30.GL_READ_FRAMEBUFFER, readState[6]);
            GLES30.glBindBuffer(GLES30.GL_PIXEL_PACK_BUFFER, 0);
            GLES20.glPixelStorei(GLES30.GL_PACK_ROW_LENGTH, 0);
            GLES20.glPixelStorei(GLES30.GL_PACK_SKIP_ROWS, 0);
            GLES20.glPixelStorei(GLES30.GL_PACK_SKIP_PIXELS, 0);
        }
        try {
            GLES20.glPixelStorei(GLES20.GL_PACK_ALIGNMENT, 1);
            screenPixels.position(0);
            GLES20.glReadPixels(x, y, width, height, GLES20.GL_RGBA, GLES20.GL_UNSIGNED_BYTE, screenPixels);
            int error = GLES20.glGetError();
            if (error != GLES20.GL_NO_ERROR) {
                swapFailure = "Screen readback GL " + Integer.toHexString(error);
                return false;
            }
            synchronized (frameLock) {
                copyScreenPixels(screenPixels, pixels, width, height, canvasWidth, canvasHeight);
                pending = true;
            }
            return true;
        } finally {
            GLES20.glPixelStorei(GLES20.GL_PACK_ALIGNMENT, readState[0]);
            if (es3) {
                GLES30.glBindBuffer(GLES30.GL_PIXEL_PACK_BUFFER, readState[1]);
                GLES20.glPixelStorei(GLES30.GL_PACK_ROW_LENGTH, readState[2]);
                GLES20.glPixelStorei(GLES30.GL_PACK_SKIP_ROWS, readState[3]);
                GLES20.glPixelStorei(GLES30.GL_PACK_SKIP_PIXELS, readState[4]);
                if (readState[5] != readState[6])
                    GLES30.glBindFramebuffer(GLES30.GL_READ_FRAMEBUFFER, readState[5]);
            }
        }
    }

    static void fitRect(int width, int height, int outputWidth, int outputHeight, Rect result) {
        float scale = Math.min((float) outputWidth / width, (float) outputHeight / height);
        int w = Math.max(1, Math.round(width * scale)), h = Math.max(1, Math.round(height * scale));
        int left = (outputWidth - w) / 2, top = (outputHeight - h) / 2;
        result.set(left, top, left + w, top + h);
    }

    static void copyScreenPixels(ByteBuffer source, byte[] output, int width, int height,
            int outWidth, int outHeight) {
        // Android's bitmap is top-down; a GL window readback starts at the bottom.
        // Keep wide gameplay square even when the fallback storage is a 4:3 map canvas.
        Rect content = new Rect();
        fitRect(width, height, outWidth, outHeight, content);
        java.util.Arrays.fill(output, (byte) 0);
        for (int y = 0; y < content.height(); y++) {
            int sourceRow = (height - 1 - y * height / content.height()) * width * 4;
            int outputRow = (y + content.top) * outWidth * 4;
            for (int x = 0; x < content.width(); x++) {
                int from = sourceRow + (x * width / content.width()) * 4;
                int to = outputRow + (x + content.left) * 4;
                output[to] = source.get(from);
                output[to + 1] = source.get(from + 1);
                output[to + 2] = source.get(from + 2);
                output[to + 3] = source.get(from + 3);
            }
        }
    }

    public String DualScreen_Info() {
        try {
            org.json.JSONObject info = new org.json.JSONObject();
            boolean swapped = screenSwap && swapFrameReady && ready;
            info.put("swap_requested", screenSwap);
            info.put("swap_active", swapped);
            info.put("ready", ready && active);
            info.put("primary_display_id", primaryDisplayId);
            info.put("presentation_display_id", displayId);
            info.put("primary_role", swapped ? "map" : "gameplay");
            info.put("presentation_role", swapped ? "gameplay" : "map");
            info.put("canvas_width", canvasWidth);
            info.put("canvas_height", canvasHeight);
            info.put("presentation_width", physicalWidth);
            info.put("presentation_height", physicalHeight);
            info.put("primary_width", primaryWidth);
            info.put("primary_height", primaryHeight);
            info.put("capture_width", sourceWidth);
            info.put("capture_height", sourceHeight);
            info.put("capture_left", sourceX);
            info.put("capture_bottom", sourceY);
            info.put("frame_path", framePath);
            info.put("bitmap_frames", frames);
            info.put("swap_gpu_frames", swapGpuFrames);
            info.put("swap_bitmap_frames", swapBitmapFrames);
            info.put("swap_failures", swapFailures);
            info.put("swap_last_failure", swapFailure);
            AM2RGpuOutput target = gpuOutput;
            if (target != null) info.put("gpu", target.observations());
            return info.toString();
        } catch (org.json.JSONException error) {
            return "{}";
        }
    }

    private void updateSwapInput() {
        boolean show = screenSwap && swapFrameReady && ready && active;
        if (show) {
            View root = RunnerActivity.CurrentActivity.findViewById(android.R.id.content);
            if (!(root instanceof ViewGroup)) return;
            if (primaryInput == null || primaryInput.getParent() != root) {
                if (primaryInput != null && primaryInput.getParent() instanceof ViewGroup)
                    ((ViewGroup) primaryInput.getParent()).removeView(primaryInput);
                primaryInput = new PrimaryMapInput(RunnerActivity.CurrentActivity);
                ((ViewGroup) root).addView(primaryInput, new ViewGroup.LayoutParams(-1, -1));
            }
            primaryInput.onSizeChanged(primaryInput.getWidth(), primaryInput.getHeight(), 0, 0);
            primaryInput.setVisibility(View.VISIBLE);
            primaryInput.bringToFront();
        } else if (primaryInput != null) primaryInput.setVisibility(View.GONE);
    }

    private DisplayManager displayManager() {
        if (displays == null)
            displays = (DisplayManager) RunnerActivity.CurrentActivity.getSystemService(Context.DISPLAY_SERVICE);
        return displays;
    }

    private Display secondDisplay() {
        int primary = RunnerActivity.CurrentActivity.getWindowManager().getDefaultDisplay().getDisplayId();
        Display target = null;
        for (Display candidate : displayManager().getDisplays(DisplayManager.DISPLAY_CATEGORY_PRESENTATION)) {
            // Display IDs change across reconnects. A built-in screen keeps the lowest.
            if (candidate.getDisplayId() != primary && (target == null || candidate.getDisplayId() < target.getDisplayId()))
                target = candidate;
        }
        return target;
    }

    public double DualScreen_Available() { return secondDisplay() != null ? 1 : 0; }

    private SharedPreferences preferences() {
        return RunnerActivity.CurrentActivity.getSharedPreferences("dual_screen", Context.MODE_PRIVATE);
    }

    // Also saved here, to claim the display before the game's settings load.
    public double DualScreen_Enable(double enable) {
        final boolean enabled = enable == 1;
        if (preferences().getBoolean("enabled", false) != enabled)
            preferences().edit().putBoolean("enabled", enabled).apply();
        if (enabled) start();
        else ui.post(() -> {
            if (started) displayManager().unregisterDisplayListener(this);
            started = false;
            dismissLower();
        });
        return 1;
    }

    private void start() {
        // Queue display discovery on the UI thread; returning here does not mean a lower display is ready.
        ui.post(() -> {
            if (!started) {
                started = true;
                displayManager().registerDisplayListener(this, ui);
            }
            refreshDisplay();
        });
    }

    private android.graphics.Point screenSize() {
        android.graphics.Point size = new android.graphics.Point(physicalWidth, physicalHeight);
        Display target = size.x > 0 && size.y > 0 ? null : secondDisplay();
        if (target != null) target.getRealSize(size);
        return size;
    }

    public double DualScreen_Width() { return screenSize().x; }
    public double DualScreen_Height() { return screenSize().y; }

    private volatile AM2RGpuOutput gpuOutput;
    private final java.util.concurrent.ConcurrentLinkedQueue<AM2RGpuOutput> retiredGpu = new java.util.concurrent.ConcurrentLinkedQueue<>();
    void gpuShown(boolean shown) {
        LowerPresentation current = lower;
        if (current == null || current.view == null || current.view.gpuShowing == shown) return;
        ui.post(() -> {
            if (lower == current) { current.view.gpuShowing = shown; current.view.invalidate(); }
        });
    }
    private AM2RGpuOutput output() {
        AM2RGpuOutput retired;
        while ((retired = retiredGpu.poll()) != null) retired.disable();
        return gpuOutput;
    }

    public double DualScreen_Begin() {
        AM2RGpuOutput target = output();
        return target != null && ready && active && target.begin() ? 1 : 0;
    }

    // x to height are screen pixels from the top left. u to partHeight are fractions of the current surface target.
    public double DualScreen_Draw(double x, double y, double width, double height,
            double u, double v, double partWidth, double partHeight, double brightness, double blend) {
        AM2RGpuOutput target = gpuOutput;
        if (target == null) return 0;
        target.draw((int) x, (int) y, (int) Math.round(width), (int) Math.round(height),
                (float) u, (float) v, (float) partWidth, (float) partHeight, (float) brightness, blend != 0);
        return 1;
    }

    public double DualScreen_End() {
        AM2RGpuOutput target = gpuOutput;
        boolean sent = target != null && target.present(0, 0);
        if (sent) framePath = "gpu";
        return sent ? 1 : 0;
    }

    public double DualScreen_Ready() { return ready && active ? 1 : 0; }

    // Own the bytes before returning to GML. One pending UI frame; no growing queue.
    public double DualScreen_Frame(double bufferId, double frameWidth, double frameHeight) {
        if (!ready || !active) return 0;
        int width = (int) frameWidth, height = (int) frameHeight, bytes = width * height * 4;
        if (width < 1 || height < 1 || width > 1024 || height > 1024) return 0;
        ByteBuffer source = RunnerJNILib.bufferGetByteBuffer((int) bufferId);
        if (source == null || source.capacity() < bytes) return 0;
        synchronized (frameLock) {
            if (width != canvasWidth || height != canvasHeight) {
                canvasWidth = width; canvasHeight = height;
                pixels = new byte[bytes]; pixelBuffer = ByteBuffer.wrap(pixels);
            }
            source = source.duplicate();
            source.position(0);
            source.get(pixels, 0, bytes);
            pending = true;
            framePath = "bitmap";
        }
        return 1;
    }

    // Consume the newest frame during Android's animation phase. Posting a
    // separate main-thread message from every game frame stalls the sender.
    private void onDisplayFrame(long frameTimeNanos) {
        if (!ready || !active || lower == null) { frameLoop = false; return; }
        presentFrame();
        Choreographer.getInstance().postFrameCallback(frameCallback);
    }

    private void presentFrame() {
        synchronized (frameLock) {
            // Copy the newest submitted image into the bitmap and request a later View redraw.
            if (pending && ready && lower != null && lower.view != null) {
                if (lower.view.bitmap.getWidth() != canvasWidth || lower.view.bitmap.getHeight() != canvasHeight)
                    lower.view.resizeBitmap();
                pixelBuffer.position(0);
                lower.view.bitmap.copyPixelsFromBuffer(pixelBuffer);
                lower.view.invalidate();
                frames++;
            }
            pending = false;
        }
    }

    public String DualScreen_Touch() {
        synchronized (inputLock) {
            if (!tapped && dragX == 0 && dragY == 0 && zoom == 0) return "";
            String result = "{\"dx\":" + dragX + ",\"dy\":" + dragY
                + ",\"zoom\":" + zoom + ",\"tap\":" + tapped
                + ",\"x\":" + touchX + ",\"y\":" + touchY
                + ",\"originX\":" + originX + ",\"originY\":" + originY + "}";
            // Consume accumulated gesture movement once; later input starts a fresh batch for GML.
            dragX = dragY = zoom = 0;
            tapped = false;
            return result;
        }
    }



    // Local debug builds expose functional observations, never commands or save mutations.


    private void refreshDisplay() {
        if (!started || !active) return;
        Display primary = RunnerActivity.CurrentActivity.getWindowManager().getDefaultDisplay();
        android.graphics.Point primarySize = new android.graphics.Point();
        primary.getRealSize(primarySize);
        primaryDisplayId = primary.getDisplayId();
        primaryWidth = primarySize.x; primaryHeight = primarySize.y;
        Display target = secondDisplay();
        // Replace the presentation when its display disappears or a different display is selected.
        if (lower != null && (target == null || lower.getDisplay().getDisplayId() != target.getDisplayId())) dismissLower();
        if (target != null && lower == null) {
            LowerPresentation next = new LowerPresentation(RunnerActivity.CurrentActivity, target);
            try {
                next.show();
                lower = next;
                displayId = target.getDisplayId();
                ready = true;
                immersive(next.getWindow());
            } catch (WindowManager.InvalidDisplayException error) {
                next.dismiss();
            }
        }
        ensureFrameLoop();
    }

    private void ensureFrameLoop() {
        // Start one animation callback chain while the lower display can accept frames.
        if (ready && active && !frameLoop) {
            frameLoop = true;
            Choreographer.getInstance().postFrameCallback(frameCallback);
        }
    }

    // Release the lower window and its bitmap, and discard gestures left over from that window.
    private void dismissLower() {
        ready = false;
        setSwapFrameReady(false);
        lowerFocused = false;
        displayId = -1;
        physicalWidth = physicalHeight = 0;
        if (lower != null) {
            if (gpuOutput != null) { retiredGpu.add(gpuOutput); gpuOutput = null; }
            lower.dismiss();
            if (lower.view != null) lower.view.bitmap.recycle();
            lower = null;
        }
        synchronized (inputLock) { dragX = dragY = zoom = 0; tapped = false; }
    }

    static void immersive(Window window) {
        if (window == null) return;
        window.getDecorView();
        if (android.os.Build.VERSION.SDK_INT >= 30) {
            window.setDecorFitsSystemWindows(false);
            WindowInsetsController controller = window.getInsetsController();
            if (controller != null) {
                controller.setSystemBarsBehavior(WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE);
                controller.hide(WindowInsets.Type.systemBars());
            }
        } else {
            window.getDecorView().setSystemUiVisibility(View.SYSTEM_UI_FLAG_FULLSCREEN
                | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
        }
    }

    // Display changes and activity lifecycle callbacks update readiness without changing GML game state.
    @Override public void onDisplayAdded(int id) { refreshDisplay(); }
    @Override public void onDisplayRemoved(int id) { refreshDisplay(); }
    @Override public void onDisplayChanged(int id) { refreshDisplay(); }
    @Override public void onResume() {
        active = true;
        // The extension exists before game assets load. Claim the lower
        // display now, then let GML supply its first completed frame.
        if (preferences().getBoolean("enabled", false)) start();
    }
    @Override public void onNewIntent(Intent intent) {
        // A launcher tap also reaches an already-resumed game through this callback.
        if (Intent.ACTION_MAIN.equals(intent.getAction()) && intent.hasCategory(Intent.CATEGORY_LAUNCHER)) {
            ui.post(this::refreshDisplay);
        }
    }
    @Override public void onPause() { active = false; }
    @Override public void onStop() { active = false; ui.post(this::dismissLower); }
    @Override public void onDestroy() {
        active = false;
        ui.post(() -> { dismissLower(); if (displays != null) displays.unregisterDisplayListener(this); });
    }
    @Override public void onWindowFocusChanged(boolean focused) {
        ui.post(this::updateGameFocus);
    }

    private void updateGameFocus() {
        // Both windows belong to this game. External apps still take focus normally.
        RunnerActivity.HasFocus = RunnerActivity.CurrentActivity.hasWindowFocus() || lowerFocused;
        if (lower != null && lowerFocused) immersive(lower.getWindow());
    }

    private boolean isGamepad(int source) {
        return (source & InputDevice.SOURCE_GAMEPAD) == InputDevice.SOURCE_GAMEPAD
            || (source & InputDevice.SOURCE_JOYSTICK) == InputDevice.SOURCE_JOYSTICK;
    }

    private final class LowerPresentation extends Presentation {
        LowerView view;
        LowerPresentation(Context context, Display display) {
            super(context, display, android.R.style.Theme_Material_NoActionBar_Fullscreen);
        }
        @Override protected void onCreate(Bundle state) {
            super.onCreate(state);
            // A focusable presentation owns its navigation-bar insets. A non-focusable
            // fullscreen window leaves the launcher's invisible Home target over our buttons.
            getWindow().addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
            view = new LowerView(getContext());
            android.widget.FrameLayout content = new android.widget.FrameLayout(getContext());
            gpuOutput = new AM2RGpuOutput(getContext(), AM2RDualScreen.this);
            content.addView(gpuOutput, new android.widget.FrameLayout.LayoutParams(-1, -1));
            content.addView(view, new android.widget.FrameLayout.LayoutParams(-1, -1));
            setContentView(content);
            immersive(getWindow());
        }
        @Override public void onWindowFocusChanged(boolean focused) {
            super.onWindowFocusChanged(focused);
            lowerFocused = focused;
            ui.post(AM2RDualScreen.this::updateGameFocus);
        }
        // Route controller keys received by the lower window through the game runner's normal input path.
        @Override public boolean dispatchKeyEvent(KeyEvent event) {
            if (isGamepad(event.getSource())) {
                return RunnerActivity.CurrentActivity.dispatchKeyEvent(event);
            }
            if (event.getKeyCode() == KeyEvent.KEYCODE_BACK) return true;
            return super.dispatchKeyEvent(event);
        }
        // Forward controller axis motion as well, even while the lower window has focus.
        @Override public boolean dispatchGenericMotionEvent(MotionEvent event) {
            if (isGamepad(event.getSource())) {
                return RunnerActivity.CurrentActivity.dispatchGenericMotionEvent(event);
            }
            return super.dispatchGenericMotionEvent(event);
        }
    }

    View createResumePreview(Context context) {
        return started && frames > 0 ? new LowerView(context, true) : null;
    }

    // A transparent child in the existing game Activity receives the same map
    // gestures when that Activity displays the map. It creates no extra window
    // and never takes keyboard/gamepad focus from the normal runner path.
    private final class PrimaryMapInput extends LowerView {
        PrimaryMapInput(Context context) { super(context, false, true); }
    }

    private class LowerView extends View {
        Bitmap bitmap;
        final Paint paint = new Paint();
        final Rect destination = new Rect();
        final Rect screenSource = new Rect(), screenDestination = new Rect();
        final ScaleGestureDetector pinch;
        final boolean preview, inputOnly;
        volatile boolean gpuShowing;
        final float slop = 4 * getResources().getDisplayMetrics().density;
        float lastX, lastY, startX, startY;
        boolean dragging, wasPinch;
        LowerView(Context context) {
            this(context, false);
        }
        LowerView(Context context, boolean preview) {
            this(context, preview, false);
        }
        LowerView(Context context, boolean preview, boolean inputOnly) {
            super(context);
            this.preview = preview;
            this.inputOnly = inputOnly;
            setFocusable(false);
            paint.setFilterBitmap(false);
            // Show the last map frame while the game surface resumes above.
            if (!inputOnly) synchronized (frameLock) {
                bitmap = Bitmap.createBitmap(canvasWidth, canvasHeight, Bitmap.Config.ARGB_8888);
                pixelBuffer.position(0);
                bitmap.copyPixelsFromBuffer(pixelBuffer);
            }
            pinch = new ScaleGestureDetector(context, new ScaleGestureDetector.SimpleOnScaleGestureListener() {
                @Override public boolean onScale(ScaleGestureDetector detector) {
                    wasPinch = true;
                    // Accumulate pinch ratios logarithmically so GML can combine several motion events into one zoom change.
                    synchronized (inputLock) { zoom += Math.log(detector.getScaleFactor()) / Math.log(2); }
                    return true;
                }
            });
        }
        void resizeBitmap() {
            bitmap = Bitmap.createBitmap(canvasWidth, canvasHeight, Bitmap.Config.ARGB_8888);
            onSizeChanged(getWidth(), getHeight(), 0, 0);
            invalidate();
        }
        @Override protected void onSizeChanged(int w, int h, int oldW, int oldH) {
            if (!preview && !inputOnly) { physicalWidth = w; physicalHeight = h; }
            // Uniform source pixels. The screen can differ from the native grid by two pixels;
            // cover that rounding with the empty edge margins, never resample text.
            int scale = Math.max(1, Math.min(w / canvasWidth, h / canvasHeight));
            int next = scale + 1;
            if (canvasWidth * next - w <= 2 && canvasHeight * next - h <= 2) scale = next;
            int width = canvasWidth * scale, height = canvasHeight * scale;
            int left = (w-width)/2, top = (h-height)/2;
            destination.set(left, top, left+width, top+height);
        }
        @Override protected void onDraw(Canvas canvas) {
            if (inputOnly) return;
            if (!preview && gpuShowing) { AM2RDisplayEntry.finishAfterLowerDraw(this); return; }
            canvas.drawColor(Color.BLACK);
            if (!preview && screenSwap && swapFrameReady && sourceWidth > 0 && sourceHeight > 0) {
                // Only the fitted gameplay part of the fallback bitmap belongs on
                // the USB screen; its storage padding is not part of the picture.
                fitRect(sourceWidth, sourceHeight, bitmap.getWidth(), bitmap.getHeight(), screenSource);
                fitRect(sourceWidth, sourceHeight, getWidth(), getHeight(), screenDestination);
                canvas.drawBitmap(bitmap, screenSource, screenDestination, paint);
            } else canvas.drawBitmap(bitmap, null, destination, paint);
            if (!preview) AM2RDisplayEntry.finishAfterLowerDraw(this);
        }
        @Override public boolean onTouchEvent(MotionEvent event) {
            if (preview) return true;
            if (inputOnly && !(screenSwap && swapFrameReady && ready)) return false;
            if (!inputOnly && screenSwap && swapFrameReady) return true;
            float x = event.getX(), y = event.getY();
            pinch.onTouchEvent(event);
            switch (event.getActionMasked()) {
                case MotionEvent.ACTION_DOWN:
                    lastX = startX = x; lastY = startY = y;
                    dragging = false; wasPinch = false;
                    synchronized (inputLock) { originX = x; originY = y; }
                    break;
                // After a small movement threshold, collect drag distance unless this gesture has become a pinch.
                case MotionEvent.ACTION_MOVE:
                    if (!wasPinch && !pinch.isInProgress()) {
                        if (Math.hypot(x-startX, y-startY) > slop) dragging = true;
                        if (dragging) synchronized (inputLock) { dragX += x-lastX; dragY += y-lastY; }
                    }
                    lastX = x; lastY = y;
                    break;
                // Treat a release as a tap only when it was neither a drag nor a pinch.
                case MotionEvent.ACTION_UP:
                    if (!dragging && !wasPinch) {
                        synchronized (inputLock) { tapped = true; touchX = x; touchY = y; }
                    }
                    dragging = false;
                    performClick();
                    break;
                case MotionEvent.ACTION_CANCEL:
                    dragging = false;
                    break;
            }
            return true;
        }
        @Override public boolean performClick() { super.performClick(); return true; }
        @Override public boolean onGenericMotionEvent(MotionEvent event) {
            if (preview) return true;
            if (inputOnly && !(screenSwap && swapFrameReady && ready)) return false;
            if (!inputOnly && screenSwap && swapFrameReady) return true;
            if (event.getActionMasked() == MotionEvent.ACTION_SCROLL) {
                synchronized (inputLock) { zoom += event.getAxisValue(MotionEvent.AXIS_VSCROLL) / 4; }
                return true;
            }
            return super.onGenericMotionEvent(event);
        }
    }
}
