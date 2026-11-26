if (global.opaimstyle) {
    op[0].optext = get_text("OptionsControl", "AimingStyle_2Buttons");
} else op[0].optext = get_text("OptionsControl", "AimingStyle_1Button");
if (global.opmslstyle) {
    op[1].optext = get_text("OptionsControl", "MissileStyle_Toggle");
} else op[1].optext = get_text("OptionsControl", "MissileStyle_Hold");
if (global.opmrpstyle) {
    op[2].optext = get_text("GlobalOptions", "Enabled");
} else op[2].optext = get_text("GlobalOptions", "Disabled");
if (global.opspdstyle == 0) op[3].optext = get_text("OptionsControl", "SpiderballActivation_Toggle");
if (global.opspdstyle == 1) op[3].optext = get_text("OptionsControl", "SpiderballActivation_Classic");
if (global.opspdstyle == 2) op[3].optext = get_text("OptionsControl", "SpiderballActivation_Hold");
if (global.opautoclimb) {
    op[4].optext = get_text("GlobalOptions", "Enabled");
} else op[4].optext = get_text("GlobalOptions", "Disabled");
if (global.opautomorph) {
    op[5].optext = get_text("GlobalOptions", "Enabled");
} else op[5].optext = get_text("GlobalOptions", "Disabled");

if(os_type == os_android) {
    if (global.opxjoyvib) {
        op[6].optext = get_text("GlobalOptions", "Enabled");
    } else op[6].optext = get_text("GlobalOptions", "Disabled");
}

if (global.compatibilitymode) {
    op[7].optext = get_text("GlobalOptions", "Enabled");
} else op[7].optext = get_text("GlobalOptions", "Disabled");

if (global.curropt == 0) {
    if (global.opaimstyle) {
        global.tiptext = get_text("OptionsControl", "AimingStyle_2Buttons_Tip");
    } else global.tiptext = get_text("OptionsControl", "AimingStyle_1Button_Tip");
}
if (global.curropt == 1) {
    if (global.opmslstyle) {
        global.tiptext = get_text("OptionsControl", "MissileStyle_Toggle_Tip");
    } else global.tiptext = get_text("OptionsControl", "MissileStyle_Hold_Tip");
}
if (global.curropt == 2) {
    if (global.opmrpstyle) {
        global.tiptext = get_text("OptionsControl", "ClassicMorphball_Enabled_Tip");
    } else global.tiptext = get_text("OptionsControl", "ClassicMorphball_Disabled_Tip");
}
if (global.curropt == 3) {
    if (global.opspdstyle == 0) global.tiptext = get_text("OptionsControl", "SpiderballActivation_Toggle_Tip");
    if (global.opspdstyle == 1) global.tiptext = get_text("OptionsControl", "SpiderballActivation_Classic_Tip");
    if (global.opspdstyle == 2) global.tiptext = get_text("OptionsControl", "SpiderballActivation_Hold_Tip");
}

op[9].slwidth = op[9].w * touch_options_value(9);
op[10].slwidth = op[10].w * touch_options_value(10);
op[11].slwidth = op[11].w * touch_options_value(11);
// Refresh only after a geometry change; unrelated options do not move held touches.
with (oTouchControls) {
    if (scale != oControl.touch_scale || layout_inset != oControl.touch_inset
        || layout_aim_balance != oControl.touch_aim_balance) event_user(0);
}

