y -= 8;
sep = 16;
op[50] = instance_create(x, y, oMenuLabel);
op[50].text = get_text("OptionsControl", "Title_Control");
op[0] = instance_create(x, y + sep, oOptionLR);
op[0].label = get_text("OptionsControl", "AimingStyle");
op[0].optionid = 0;
op[1] = instance_create(x, y + sep * 2, oOptionLR);
op[1].label = get_text("OptionsControl", "MissileStyle");
op[1].optionid = 1;
op[2] = instance_create(x, y + sep * 3, oOptionLR);
op[2].label = get_text("OptionsControl", "ClassicMorphball");
op[2].optionid = 2;
op[3] = instance_create(x, y + sep * 4, oOptionLR);
op[3].label = get_text("OptionsControl", "SpiderballActivation");
op[3].optionid = 3;
op[4] = instance_create(x, y + sep * 5, oOptionLR);
op[4].label = get_text("OptionsControl", "AutoClimb");
op[4].optionid = 4;
op[5] = instance_create(x, y + sep * 6, oOptionLR);
op[5].label = get_text("OptionsControl", "AutoMorph");
op[5].optionid = 5;

// Use this menu position for keyboard settings on desktop and haptics on Android.
if(os_type != os_android) {
    op[6] = instance_create(x, y + sep * 7, oPauseOption);
    op[6].optionid = 6;
    op[6].label = get_text("OptionsControl", "KeyboardSettings");
}
else {
    op[6] = instance_create(x, y + sep * 7, oOptionLR);
    op[6].label = get_text("Android", "Haptics");
    op[6].optionid = 6;
}

op[7] = instance_create(x, y + sep * 8, oOptionLR);
op[7].optionid = 7;
op[7].label = get_text("Android", "CompatibilityMode");
op[7].visible = false; // OG False
canedit[7] = 0; // OG 0
if(os_type == os_android || os_type == os_linux) {
    op[7].visible = true;
    canedit[7] = 1;
}
i = 8; // OG 8 PLEASE DON'T BE BORKED ON ANDROID
if(os_type == os_android || os_type == os_linux) i = 9; // probably don't need the linux one here but idk
op[8] = instance_create(x, y + sep * i, oPauseOption);
op[8].optionid = 8;
op[8].label = get_text("OptionsControl", "JoypadSettings");
op[8].enabled = 1;
// Disable controller settings when neither input path reports a controller.
if (global.joydetected == 0 && !gamepad_is_connected(global.gamepadIndex)) {
    op[8].enabled = 0;
    canedit[8] = 0;
    op[8].label = get_text("OptionsControl", "NoJoypad");
}
i++ // AHHHHHHHHHHHH
op[9] = instance_create(x, y + sep * i, oOptionSlider);
op[9].show_handle = true;
op[9].optionid = 9;
op[9].label = get_text("Android", "TouchScale");
// Hide the overlay rows when the game uses a lower display or a desktop window.
if (os_type != os_android || oControl.dual_enabled) {
    op[9].visible = false;
    canedit[9] = 0;
    i --;
}

i++;
op[10] = instance_create(x, y + sep * i, oOptionSlider);
op[10].show_handle = true;
op[10].optionid = 10;
op[10].label = get_text("Android", "TouchInset");
if (op[10].label == "[!]") op[10].label = "Control Spacing";
if (os_type != os_android || oControl.dual_enabled) {
    op[10].visible = false;
    canedit[10] = 0;
    i--;
}

i++;
op[11] = instance_create(x, y + sep * i, oOptionSlider);
op[11].optionid = 11;
op[11].show_handle = true;
op[11].label = get_text("Android", "TouchAimBalance");
if (os_type != os_android || oControl.dual_enabled) {
    op[11].visible = false;
    canedit[11] = 0;
    i--;
}

i++;
op[12] = instance_create(x, y + sep * i, oPauseOption);
op[12].optionid = 12;
op[12].label = get_text("GlobalOptions", "Exit");

event_user(2);
