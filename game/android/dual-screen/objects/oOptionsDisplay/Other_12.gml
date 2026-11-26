/// @description  Update option text

// Fullscreen, Scale
if (os_type != os_android) {
    if (global.opfullscreen) {
        op[opFullscreen].optext = get_text("GlobalOptions", "Enabled");
        op[opScale].label = get_text("OptionsDisplay", "DisplayScale");
    } else {
        op[opFullscreen].optext = get_text("GlobalOptions", "Disabled");
        op[opScale].label = get_text("OptionsDisplay", "WindowSize");
    }

    // Scale sizes
    switch (global.opscale) {
        case 0: op[opScale].optext = get_text("OptionsDisplay", "DisplayScale_Stretch"); break;
        case 1: op[opScale].optext = "1X"; break;
        case 2: op[opScale].optext = "2X"; break;
        case 3: op[opScale].optext = "3X"; break;
        case 4: op[opScale].optext = "4X"; break;
        default: op[opScale].optext = "[!]"; break;
    }
}

// Vsync
if (global.opvsync) {
    op[opVSync].optext = get_text("GlobalOptions", "Enabled");
} else {
    op[opVSync].optext = get_text("GlobalOptions", "Disabled");
}


// Sensitivity Mode
if (global.sensitivitymode) {
    op[opSensitivity].optext = get_text("GlobalOptions", "Enabled");
} else {
    op[opSensitivity].optext = get_text("GlobalOptions", "Disabled");
}

op[opNano].optext = get_text("GlobalOptions", global.nano_enabled ? "Enabled" : "Disabled");

// Aspect ratio
switch (global.opaspectratio) {
    case 0: op[opWidescreen].optext = "4:3"; break;
    case 1: op[opWidescreen].optext = "16:9"; break;
    case 2: op[opWidescreen].optext = "3:2"; break;
}

if (opOrientation >= 0) {
    var _keys = ["Orientation_Landscape", "Orientation_Portrait", "Orientation_Automatic"];
    var _labels = ["Landscape", "Portrait", "Automatic"];
    op[opOrientation].optext = android_orientation_text(_keys[global.oporientation], _labels[global.oporientation]);
}

// Show HUD
if (global.opshowhud) {
    op[opShowHUD].optext = get_text("GlobalOptions", "Enabled");
} else op[opShowHUD].optext = get_text("GlobalOptions", "Disabled");

// Show Map
if (global.ophudshowmap) {
    op[opShowMap].optext = get_text("GlobalOptions", "Enabled");
} else op[opShowMap].optext = get_text("GlobalOptions", "Disabled");

// Monster Counter Style
switch (global.ophudshowmetrcount) {
    case 0: op[opCounterStyle].optext = get_text("GlobalOptions", "Disabled"); break;
    case 1: op[opCounterStyle].optext = get_text("OptionsDisplay", "MonsterCounter_Local"); break;
    case 2: op[opCounterStyle].optext = get_text("OptionsDisplay", "MonsterCounter_Global"); break;
    default: op[opCounterStyle].optext = "[!]"; break;
}

// Update Monster Counter tip text
if (global.curropt == opCounterStyle) {
    switch (global.ophudshowmetrcount) {
        case 0: global.tiptext = get_text("OptionsDisplay", "MonsterCounter_Disabled_Tip"); break;
        case 1: global.tiptext = get_text("OptionsDisplay", "MonsterCounter_Local_Tip"); break;
        case 2: global.tiptext = get_text("OptionsDisplay", "MonsterCounter_Global_Tip"); break;
        default: global.tiptext = "[!]"; break;
    }
}

// Show Hints
if (global.ophudshowhints) {
    op[opShowHints].optext = get_text("GlobalOptions", "Enabled");
} else op[opShowHints].optext = get_text("GlobalOptions", "Disabled");

// Button Display Type
if (buttonsEnabled) {
    switch (oControl.mod_buttonsconfig) {
        case 0: op[opButtonType].optext = get_text("ExtrasMenu", "XBox"); break;
        case 1: op[opButtonType].optext = get_text("ExtrasMenu", "Playstation"); break;
        case 2: op[opButtonType].optext = get_text("ExtrasMenu", "NintendoPro"); break;
        case 3: op[opButtonType].optext = get_text("ExtrasMenu", "SNESColored"); break;
        case 4: op[opButtonType].optext = get_text("ExtrasMenu", "MOGA"); break;
        case 5: op[opButtonType].optext = get_text("ExtrasMenu", "OUYA"); break;
        default: op[opButtonType].optext = "[!]"; break;
    }
}

// Show Scans
if (global.ophudshowlogmsg) {
    op[opShowScans].optext = get_text("GlobalOptions", "Enabled");
} else op[opShowScans].optext = get_text("GlobalOptions", "Disabled");

// Language
op[opLanguage].optext = lang[global.currentlanguage];

op[opDualScreen].optext = get_text("GlobalOptions", oControl.dual_enabled ? "Enabled" : "Disabled");
op[opDualScreen].enabled = canEdit[opDualScreen];
if (opSwapScreens >= 0) op[opSwapScreens].optext = get_text("GlobalOptions", oControl.dual_swap_screens ? "Enabled" : "Disabled");

// The map and Metroid counts always stay on the lower display.
if (oControl.dual_enabled) {
    // Show the chosen screen without changing the map or counter settings.
    op[opShowHUD].optext = oControl.dual_hud_top ? port_caption("Top Screen") : port_caption("Lower Screen");
    op[opShowMap].optext = port_caption("Lower Screen");
    op[opCounterStyle].optext = port_caption("Global + Local");
    op[opShowMap].enabled = 0;
    op[opCounterStyle].enabled = 0;
}

canEdit[opWidescreen] = !oControl.dual_aspect_locked;
op[opWidescreen].enabled = canEdit[opWidescreen];
if (!canEdit[opWidescreen]) op[opWidescreen].optext = port_caption("4:3 (Fixed)");
