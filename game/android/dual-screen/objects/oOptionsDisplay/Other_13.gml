/// @description  Load tip text

if (os_type != os_android) {
    tip[opFullscreen] = get_text("OptionsDisplay", "Fullscreen_Tip");
    tip[opScale] = get_text("OptionsDisplay", "DisplayScale_Tip");
}
// Keep help text indexed by the same row IDs used for navigation and value changes.
tip[opVSync] = get_text("OptionsDisplay", "VSync_Tip");
tip[opSensitivity] = get_text("Misc", "SensitivityMode_Tip");
tip[opNano] = nano_option_text("Nano_Tip", "Fewer particles and lights; lighter water effects.");
tip[opWidescreen] = android_orientation_text("AspectRatio_Tip", "Choose 4:3, 16:9 or 3:2. Changes apply on the next room transition in-game.");
if (opOrientation >= 0) tip[opOrientation] = android_orientation_text("Orientation_Tip", "Choose landscape, portrait, or automatic screen rotation.");
tip[opDualScreen] = port_caption("Show the map and menus on the second screen.");
if (opSwapScreens >= 0) tip[opSwapScreens] = port_caption("Swap the gameplay and map screens.");
tip[opShowHUD] = oControl.dual_enabled ? port_caption("Choose the screen for health and ammunition.") : get_text("OptionsDisplay", "HUDDisplay_Tip");
tip[opShowMap] = get_text("OptionsDisplay", "HUDMap_Tip");
tip[opCounterStyle] = get_text("OptionsDisplay", "MonsterCounter_Tip");
tip[opShowHints] = get_text("OptionsDisplay", "Hints_Tip");
if (buttonsEnabled) {
    tip[opButtonType] = get_text("ExtrasMenu", "Controller_Tip");
}
tip[opShowScans] = get_text("OptionsDisplay", "ScanNotifications_Tip");
tip[opLanguage] = get_text("OptionsDisplay", "Language_Tip");
tip[menuSize] = get_text("GlobalOptions", "ExitMain_Tip");
