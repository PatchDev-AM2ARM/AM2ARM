/// @description  Reload ALL text (usually for lang files)

// Label
op[50].text = get_text("OptionsDisplay", "Title_Display");

// Fullscreen, scale
if (os_type != os_android) {
    op[opFullscreen].label = get_text("OptionsDisplay", "Fullscreen");
    
    if (global.opfullscreen) {
        op[opScale].label = get_text("OptionsDisplay", "DisplayScale");
    } else op[opScale].label = get_text("OptionsDisplay", "WindowSize");
}

op[opVSync].label = get_text("OptionsDisplay", "VSync");
op[51].text = get_text("OptionsDisplay", "Title_HUD");
op[opSensitivity].label = get_text("Misc", "SensitivityMode");
op[opNano].label = nano_option_text("Nano", "Nano");
op[opWidescreen].label = android_orientation_text("AspectRatio", "Aspect Ratio");
if (opOrientation >= 0) op[opOrientation].label = android_orientation_text("Orientation", "Orientation");
op[opDualScreen].label = port_caption("Dual Screen");
if (opSwapScreens >= 0) op[opSwapScreens].label = port_caption("Swap Screens");
op[opShowHUD].label = oControl.dual_enabled ? port_caption("HUD Screen Position") : get_text("OptionsDisplay", "HUDDisplay");
op[opShowMap].label = get_text("OptionsDisplay", "HUDMap");
op[opCounterStyle].label = get_text("OptionsDisplay", "MonsterCounter");
op[52].text = get_text("OptionsDisplay", "Title_Notifications");
op[opShowHints].label = get_text("OptionsDisplay", "Hints");
if (buttonsEnabled) {
    op[opButtonType].label = get_text("ExtrasMenu", "Controller");
}
op[opShowScans].label = get_text("OptionsDisplay", "ScanNotifications");
op[opLanguage].label = get_text("OptionsDisplay", "Language");

op[53].label = get_text("OptionsDisplay", "Author") + " " + langAuthor[global.currentlanguage];

op[54].label = langAuthor2[global.currentlanguage];

op[menuSize].label = get_text("GlobalOptions", "Exit");

// Refresh the pause-page heading and menu hint in the foreground object after changing language.
with (oSS_Fg) {
    port_refresh_subscreen_text();
}
