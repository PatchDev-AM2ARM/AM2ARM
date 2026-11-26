global.bubble_frame++;
// Begin a new camera snapshot before any ordinary Step event.
global.bubble_view_ready = false;
/// @description  Check for gamepad input on Android.
if(init) exit;

// Gamepad disconnect fix: joydetected latched on forever, but a reconnected pad
// gets a new gamepad slot, so input polls (touch_keys) kept reading the dead
// opjoyid slot — and oTouchControls is disabled while joydetected is set, so a
// mid-game disconnect lost ALL input. Clearing the latch when the detected slot
// drops brings touch controls back instantly and re-arms the scan below, which
// re-latches the pad (on its new slot) at the first button press.
if(((os_type == os_android) || (os_type == os_linux)) && global.joydetected == 1 && !gamepad_is_connected(global.opjoyid)) {
    global.joydetected = 0;
}

if(((os_type == os_android) || (os_type == os_linux)) && global.joydetected == 0) {
    for (var i = 0; i < gamepad_get_device_count(); i++;) {
        if (gamepad_is_connected(i)) {
            for(var ia = 0; ia < gamepad_button_count(i); ia++) {
                if(gamepad_button_check(i, ia)) { 
                    global.opjoyid = i;
                    global.joydetected = 1;
                }
            }
            for(var ia = 0; ia < gamepad_axis_count(i); ia++) {
                if(gamepad_axis_value(i, ia) != 0) {
                    global.opjoyid = i;
                    global.joydetected = 1;
                }
            }
        }
    }
}

/// Input3D Code
/*
for (var i = 0; i < listSize; i++) {
    inputHeld[i] = min(1, keyboard_check(inputArray[i, 0]) + input_gamepad_check(gamepadIndex, inputArray[i, 1])); // 
    inputReleased[i] = 0;
    if (inputHeld[i] != 0) {
        input[i] += 1;
    } else {
        if (input[i] != 0) {
            inputReleased[i] = 1;
        }
        input[i] = 0;
    }
    
    if (input[i] == 1) {
        inputPressed[i] = 1;
    } else {
        inputPressed[i] = 0;
    }
}

/* */
/// Widescreen space

if (widescreen) {
    widescreen_space = standard_aspect_width(aspect_ratio) - 320;
} else {
    widescreen_space = 0;
    //view_enabled[1] = false;
    __view_set( e__VW.Visible, 1, false );
}

//wAlpha = max(0, wAlpha - (1/30));

/* */
/*  */
