package ${YYAndroidPackageName};

import android.content.Context;
import android.hardware.input.InputManager;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.os.SystemClock;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.os.VibratorManager;
import android.util.Log;
import android.view.InputDevice;

import com.yoyogames.runner.RunnerJNILib;

/**
 * Controller and device haptics + gamepad hot-plug detection for the AM2R Android port.
 *
 * The GMS 1.4 game used the Immersion UHL SDK, whose functions were removed in
 * GameMaker 2026. The GML code still passes the original Immersion effect ids
 * (see scripts/touch_keys and scripts/ctrl_vibrate); this class approximates
 * each of the ids the game actually uses with android.os.Vibrator waveforms.
 *
 * Effect ids in use:
 *   6   bump (player damage)
 *   15  double strong click (knockback / menu toggle test buzz)
 *   82  explosion (missile impact)
 *   27  long buzz 100% (queen earthquake sustain — called every frame)
 *   28  long buzz 66%  (earthquake sustain — called every frame)
 *   33  ramp up 100%   (queen earthquake start)
 *   34  ramp up 66%    (earthquake start)
 *   40  ramp down 100% (queen earthquake end)
 *   41  ramp down 66%  (earthquake end)
 *   111 texture (drill loop — called every frame)
 *
 * Hot-plug: the GM runner only re-enumerates gamepads on activity resume — its
 * Bluetooth ACL receiver never receives broadcasts on Android 12+ (that needs
 * the runtime BLUETOOTH_CONNECT permission, which the runner never requests)
 * and USB has no event path at all. So while the game stays foregrounded, a
 * pad that disconnects or reconnects is never noticed. This class registers an
 * InputManager.InputDeviceListener (permission-free, covers BT and USB) and
 * nudges the runner's own native re-enumeration hook — the same one its
 * onResume path uses — whenever any input device is added or removed.
 */
public class AM2RHaptics extends ExtensionBase implements InputManager.InputDeviceListener
{
    // Change orientation through the runner so its input/rotation mask stays in sync.
    public double Android_Orientation(double value) {
        final int mode = Math.max(0, Math.min(2, (int) Math.round(value)));
        mMainHandler.post(new Runnable() {
            @Override public void run() {
                if (RunnerActivity.CurrentActivity == null) return;
                boolean landscape = mode != 1;
                boolean portrait = mode != 0;
                RunnerActivity.CurrentActivity.RestrictOrientation(
                    landscape, portrait, landscape, portrait, false);
            }
        });
        return mode;
    }

    private volatile Vibrator mVibrator = null;
    private int mSustainEffect = -1;
    private long mSustainUntil = 0;

    private final Handler mMainHandler = new Handler(Looper.getMainLooper());
    private boolean mHotplugRegistered = false;

    public AM2RHaptics()
    {
        // The extension is constructed during runner setup; the activity may not
        // be fully up yet, so registration retries on the main looper until it is.
        mMainHandler.post(new Runnable() {
            @Override
            public void run() { registerHotplugListener(); }
        });
    }

    private void registerHotplugListener()
    {
        // Wait for the runner activity before registering one listener for input-device changes.
        if (mHotplugRegistered) return;
        Context ctx = RunnerActivity.CurrentActivity;
        if (ctx == null) {
            mMainHandler.postDelayed(new Runnable() {
                @Override
                public void run() { registerHotplugListener(); }
            }, 500);
            return;
        }
        InputManager im = (InputManager) ctx.getApplicationContext().getSystemService(Context.INPUT_SERVICE);
        if (im == null) return;
        im.registerInputDeviceListener(this, mMainHandler);
        mHotplugRegistered = true;
        Log.i("yoyo", "AM2RHaptics :: gamepad hot-plug listener registered");
    }

    // Ask the runner to refresh its gamepad list when Android reports a device change.
    @Override
    public void onInputDeviceAdded(int deviceId)
    {
        Log.i("yoyo", "AM2RHaptics :: input device added (id " + deviceId + "), re-enumerating gamepads");
        mVibrator = null;
        RunnerJNILib.onGamepadChange();
    }

    @Override
    public void onInputDeviceRemoved(int deviceId)
    {
        Log.i("yoyo", "AM2RHaptics :: input device removed (id " + deviceId + "), re-enumerating gamepads");
        mVibrator = null;
        RunnerJNILib.onGamepadChange();
    }

    @Override
    public void onInputDeviceChanged(int deviceId)
    {
        RunnerJNILib.onGamepadChange();
    }

    // The runner's gamepad_set_vibration does nothing on Android, so the controller's motor is used here.
    private static Vibrator controllerVibrator()
    {
        for (int id : InputDevice.getDeviceIds()) {
            InputDevice device = InputDevice.getDevice(id);
            if (device == null || (device.getSources() & InputDevice.SOURCE_GAMEPAD) != InputDevice.SOURCE_GAMEPAD) continue;
            Vibrator v = Build.VERSION.SDK_INT >= 31 ? device.getVibratorManager().getDefaultVibrator() : device.getVibrator();
            if (v != null && v.hasVibrator()) return v;
        }
        return null;
    }

    private Vibrator getVibrator()
    {
        if (mVibrator == null) mVibrator = controllerVibrator();
        // Cache the device vibrator through the service available on this Android version.
        if (mVibrator == null) {
            Context ctx = RunnerActivity.CurrentActivity;
            if (ctx == null) return null;
            if (Build.VERSION.SDK_INT >= 31) {
                VibratorManager vm = (VibratorManager) ctx.getSystemService(Context.VIBRATOR_MANAGER_SERVICE);
                if (vm != null) mVibrator = vm.getDefaultVibrator();
            } else {
                mVibrator = (Vibrator) ctx.getSystemService(Context.VIBRATOR_SERVICE);
            }
        }
        return mVibrator;
    }

    private void oneShot(Vibrator v, long ms, int amp)
    {
        // Use intensity when supported, with a duration-only fallback on older Android versions.
        if (Build.VERSION.SDK_INT >= 26) {
            if (!v.hasAmplitudeControl()) amp = VibrationEffect.DEFAULT_AMPLITUDE;
            v.vibrate(VibrationEffect.createOneShot(ms, amp));
        } else {
            v.vibrate(ms);
        }
    }

    private void waveform(Vibrator v, long[] timings, int[] amps)
    {
        if (Build.VERSION.SDK_INT >= 26 && v.hasAmplitudeControl()) {
            v.vibrate(VibrationEffect.createWaveform(timings, amps, -1));
        } else {
            // Legacy fallback: timings alone act as an off/on pattern.
            v.vibrate(timings, -1);
        }
    }

    public double AM2RHaptics_Play(double effectId)
    {
        Vibrator v = getVibrator();
        if (v == null || !v.hasVibrator()) return 0.0;

        int id = (int) effectId;
        long now = SystemClock.uptimeMillis();

        // Sustained effects arrive once per frame; don't restart one mid-buzz
        // or the vibrator stutters.
        boolean sustained = (id == 27 || id == 28 || id == 111);
        if (sustained && id == mSustainEffect && now < mSustainUntil - 80) return 1.0;
        if (!sustained) { mSustainEffect = -1; mSustainUntil = 0; }

        // Translate the effect IDs still sent by the game into short pulses, ramps, or sustained bursts.
        switch (id) {
            case 6:
                oneShot(v, 25, 150);
                break;
            case 15:
                waveform(v, new long[]{0, 25, 40, 25}, new int[]{0, 255, 0, 255});
                break;
            case 82:
                waveform(v, new long[]{0, 80, 40, 45}, new int[]{0, 255, 0, 130});
                break;
            case 27:
                oneShot(v, 450, 210);
                mSustainEffect = 27; mSustainUntil = now + 450;
                break;
            case 28:
                oneShot(v, 450, 130);
                mSustainEffect = 28; mSustainUntil = now + 450;
                break;
            case 33:
                waveform(v, new long[]{0, 60, 60, 60, 60, 60}, new int[]{0, 40, 90, 150, 210, 255});
                break;
            case 34:
                waveform(v, new long[]{0, 60, 60, 60, 60, 60}, new int[]{0, 25, 60, 100, 140, 170});
                break;
            case 40:
                waveform(v, new long[]{0, 60, 60, 60, 60, 60}, new int[]{0, 255, 210, 150, 90, 40});
                break;
            case 41:
                waveform(v, new long[]{0, 60, 60, 60, 60, 60}, new int[]{0, 170, 140, 100, 60, 25});
                break;
            case 111:
                waveform(v, new long[]{0, 35, 30, 35, 30, 35}, new int[]{0, 90, 0, 90, 0, 90});
                mSustainEffect = 111; mSustainUntil = now + 165;
                break;
            default:
                oneShot(v, 30, 128);
                break;
        }
        return 1.0;
    }

    public double AM2RHaptics_Stop()
    {
        // Clear the sustained-effect gate as well as cancelling the current vibration.
        mSustainEffect = -1;
        mSustainUntil = 0;
        Vibrator v = getVibrator();
        if (v != null) v.cancel();
        return 1.0;
    }

    @Override
    public void onPause()
    {
        // Never leave the motor running when the app is backgrounded.
        AM2RHaptics_Stop();
    }
}
