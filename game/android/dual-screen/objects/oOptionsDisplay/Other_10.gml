/// @description  Create menu options

var i = 1;

// Label
op[50] = instance_create(x, y, oMenuLabel);
op[50].text = get_text("OptionsDisplay", "Title_Display");

// Fullscreen and scale should NOT exist on Android
if (os_type != os_android) {
    // Fullscreen
    op[opFullscreen] = instance_create(x, y + SPACER * i, oOptionLR);
    op[opFullscreen].label = get_text("OptionsDisplay", "Fullscreen");
    op[opFullscreen].optionid = opFullscreen;
    i++;
    
    // Scale
    op[opScale] = instance_create(x, y + SPACER * i, oOptionLR);
    
    // Scale on fullscreen, size on not
    if (global.opfullscreen) {
        op[opScale].label = get_text("OptionsDisplay", "DisplayScale");
    } else op[opScale].label = get_text("OptionsDisplay", "WindowSize");
    op[opScale].optionid = opScale;
    i++;
}

// VSync
op[opVSync] = instance_create(x, y + SPACER * i, oOptionLR);
op[opVSync].label = get_text("OptionsDisplay", "VSync");
op[opVSync].optionid = opVSync;
i++;

// Sensitivity Mode
op[opSensitivity] = instance_create(x, y + SPACER * i, oOptionLR);
op[opSensitivity].label = get_text("Misc", "SensitivityMode");
op[opSensitivity].optionid = opSensitivity;
i++;

// Nano preset
op[opNano] = instance_create(x, y + SPACER * i, oOptionLR);
op[opNano].label = nano_option_text("Nano", "Nano");
op[opNano].optionid = opNano;
i++;

// Widescreen
op[opWidescreen] = instance_create(x, y + SPACER * i, oOptionLR);
op[opWidescreen].label = android_orientation_text("AspectRatio", "Aspect Ratio");
op[opWidescreen].optionid = opWidescreen;
i++;

if (opOrientation >= 0) {
    op[opOrientation] = instance_create(x, y + SPACER * i, oOptionLR);
    op[opOrientation].label = android_orientation_text("Orientation", "Orientation");
    op[opOrientation].optionid = opOrientation;
    i++;
}

// Second screen
op[opDualScreen] = instance_create(x, y + SPACER * i, oOptionLR);
op[opDualScreen].label = port_caption("Dual Screen");
op[opDualScreen].optionid = opDualScreen;
i++;
if (opSwapScreens >= 0) {
    op[opSwapScreens] = instance_create(x, y + SPACER * i, oOptionLR);
    op[opSwapScreens].label = port_caption("Swap Screens");
    op[opSwapScreens].optionid = opSwapScreens;
    i++;
}

// HUD Header
op[51] = instance_create(x, y + SPACER * i, oMenuLabel);
op[51].text = get_text("OptionsDisplay", "Title_HUD");
i++;

// HUD Display
op[opShowHUD] = instance_create(x, y + SPACER * i, oOptionLR);
op[opShowHUD].label = oControl.dual_enabled ? port_caption("HUD Screen Position") : get_text("OptionsDisplay", "HUDDisplay");
op[opShowHUD].optionid = opShowHUD;
i++;

// Map Display
op[opShowMap] = instance_create(x, y + SPACER * i, oOptionLR);
op[opShowMap].label = get_text("OptionsDisplay", "HUDMap");
op[opShowMap].optionid = opShowMap;
i++;

// Monster Counter Style
op[opCounterStyle] = instance_create(x, y + SPACER * i, oOptionLR);
op[opCounterStyle].label = get_text("OptionsDisplay", "MonsterCounter");
op[opCounterStyle].optionid = opCounterStyle;
i++;

// Notification Header
op[52] = instance_create(x, y + SPACER * i, oMenuLabel);
op[52].text = get_text("OptionsDisplay", "Title_Notifications");
i++;

// Show Hints
op[opShowHints] = instance_create(x, y + SPACER * i, oOptionLR);
op[opShowHints].label = get_text("OptionsDisplay", "Hints");
op[opShowHints].optionid = opShowHints;
i++;

// Button Display Type
if (buttonsEnabled) {
    op[opButtonType] = instance_create(x, y + SPACER * i, oOptionLR);
    op[opButtonType].label = get_text("ExtrasMenu", "Controller");
    op[opButtonType].optionid = opButtonType;
    i++;
}

// Show Scans
op[opShowScans] = instance_create(x, y + SPACER * i, oOptionLR);
op[opShowScans].label = get_text("OptionsDisplay", "ScanNotifications");
op[opShowScans].optionid = opShowScans;
i++;

// Language
op[opLanguage] = instance_create(x, y + SPACER * i, oOptionLR);
op[opLanguage].label = get_text("OptionsDisplay", "Language");
op[opLanguage].optionid = opLanguage;
i++;

// Author display
op[53] = instance_create(x, y + SPACER * i, oPauseOption);
// The space here will not carry from the lang file, so we manually insert it.
op[53].label = get_text("OptionsDisplay", "Author") + " " + langAuthor[global.currentlanguage];
op[53].optionid = 53;
op[53].canEdit = 0;
op[53].color = c_gray;
i++;

var author2text = get_text("OptionsDisplay", "Author");
op[54] = instance_create(x + 8, y + SPACER * i, oPauseOption);
// The space here will not carry from the lang file, so we manually insert it.
op[54].label = langAuthor2[global.currentlanguage];
op[54].optionid = 54;
op[54].canEdit = 0;
op[54].color = c_gray;
i++;

// Exit - This will always be the last option
op[menuSize] = instance_create(x, y + SPACER * i, oPauseOption);
op[menuSize].optionid = menuSize;
op[menuSize].label = get_text("GlobalOptions", "Exit");

// Update options text
event_user(2);
