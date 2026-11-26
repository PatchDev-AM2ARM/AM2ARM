/// @description  bluetooth_keys()
function touch_keys() {
	// Clear the shared controls before combining controller and touch input.
	ctrl_Left = 0;
	ctrl_Right = 0;
	ctrl_Up = 0;
	ctrl_Down = 0;
	ctrl_A = 0;
	ctrl_B = 0;
	ctrl_X = 0;
	ctrl_L = 0;
	ctrl_R = 0;
	ctrl_Select = 0;
	ctrl_Start = 0;
	ctrl_L2 = 0;
	ctrl_R2 = 0;
	ctrl_Exit = 0;
	ctrl_Menu1 = 0;
	ctrl_Menu2 = 0;
	walk_zone = 0;
	// Drive vibration from the active quake or drill effect while gameplay is running.
	// Haptic Effects
	if(global.opxjoyvib && instance_exists(oBigQuake) && global.ingame) {
	    if(floor(oBigQuake.statetime) == 575) {
	        immersion_play_effect(34);
	    }
	    if ((oBigQuake.statetime > 640) && (oBigQuake.statetime < 1150)) {
	        immersion_play_effect(28);
	    }
	    else if(floor(oBigQuake.statetime) == 1150){
	        immersion_stop();
	        immersion_play_effect(41);
	    }
	}
	if(global.opxjoyvib && instance_exists(oBigQuakeQueen) && global.ingame) {
	    if(floor(oBigQuakeQueen.statetime) == 75) {
	        immersion_play_effect(33);
	    }
	    else if ((oBigQuakeQueen.statetime > 140) && (oBigQuakeQueen.statetime < 575)) {
	        immersion_play_effect(27);
	    }
	    else if(floor(oBigQuakeQueen.statetime) == 575){
	        immersion_stop();
	        immersion_play_effect(40);
	    }
	}
	if(global.opxjoyvib && sfx_isplaying(sndDrillLoop) && global.ingame) {
	    immersion_play_effect(111);
	}
	if(!global.ingame || room == rm_transition) {
	    immersion_stop();
	}
	// Read named gamepad buttons when the controller uses the normal mapping.
	// Virtual keycodes
	if (gamepad_is_supported()) {
	    if (gamepad_is_connected(global.opjoyid) && global.joydetected && !global.compatibilitymode) {    
	        // The motors keep their last strength, so send 0 when vibration is off.
	        if (!global.android_app) {
	            var _drill = (sfx_isplaying(sndDrillLoop) && global.ingame) ? 0.1 : 0;
	            gamepad_set_vibration(global.opjoyid, global.opxjoyvib * max(global.vibL, _drill), global.opxjoyvib * max(global.vibR, _drill));
	        }
	        xjoyx = gamepad_axis_value(global.opjoyid, gp_axislh);
	        xjoyy = gamepad_axis_value(global.opjoyid, gp_axislv);
	        if (is_past_deadzone(xjoyx, xjoyy, 1)) {
	            if (is_walkzone(xjoyx, xjoyy, 2)) walk_zone = 1;
	            if (ctrl_Left == 0 && ctrl_Right == 0 && xjoyx < -(global.opxjoydz / 200)) {
	                ctrl_Left = -xjoyx;
	                global.controltype = 2;
	            }
	            if (ctrl_Left == 0 && ctrl_Right == 0 && xjoyx > global.opxjoydz / 200) {
	                ctrl_Right = xjoyx;
	                global.controltype = 2;
	            }
	            if (ctrl_Up == 0 && ctrl_Down == 0 && xjoyy < -(global.opxjoydz / 200)) {
	                ctrl_Up = 1;
	                global.controltype = 2;
	            }
	            if (ctrl_Up == 0 && ctrl_Down == 0 && xjoyy > global.opxjoydz / 200) {
	                ctrl_Down = 1;
	                global.controltype = 2;
	            }
	        }        
	        if (ctrl_Left == 0 && ctrl_Right == false && gamepad_button_check(global.opjoyid, gp_padl) ) {
	            ctrl_Left = 1;
	            global.controltype = 2;
	            walk_zone = 0;
	        }
	        if (ctrl_Left == 0 && ctrl_Right == false && gamepad_button_check(global.opjoyid, gp_padr)) {
	            ctrl_Right = 1;
	            global.controltype = 2;
	            walk_zone = 0;
	        }
	        if (ctrl_Up == 0 && ctrl_Down == false && gamepad_button_check(global.opjoyid, gp_padu)) {
	            ctrl_Up = 1;
	            global.controltype = 2;
	            walk_zone = 0;
	        }
	        if (ctrl_Up == 0 && ctrl_Down == false && gamepad_button_check(global.opjoyid, gp_padd)) {
	            ctrl_Down = 1;
	            global.controltype = 2;
	            walk_zone = 0;
	        }
	        // Merge gamepad action buttons into the common controls.
	        if (ctrl_A == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_a) || (global.opxjoybtn_a == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_A = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_B == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_b) || (global.opxjoybtn_b == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_B = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_X == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_x) || (global.opxjoybtn_x == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_X = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_L == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_l) || (global.opxjoybtn_l == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_L = 1;
	            global.controltype = 2;
	        }
	        if (global.opaimstyle == 1 && ctrl_L2 == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_l2) || (global.opxjoybtn_l2 == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_L2 = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_R == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_r) || (global.opxjoybtn_r == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_R = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_R2 == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_r2) || (global.opxjoybtn_r2 == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_R2 = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_Select == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_sel) || (global.opxjoybtn_sel == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_Select = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_Start == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_str) || (global.opxjoybtn_str == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_Start = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_Exit == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_exit) || (global.opxjoybtn_exit == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_Exit = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_Menu1 == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_menu1) || (global.opxjoybtn_menu1 == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_Menu1 = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_Menu2 == false && gamepad_button_check(global.opjoyid, global.opxjoybtn_menu2) || (global.opxjoybtn_menu2 == gp_select && keyboard_check(vk_backspace))) {
	            ctrl_Menu2 = 1;
	            global.controltype = 2;
	        }
	    } // if (gamepad_is_connected(global.opjoyid) && global.joydetected && !global.compatibilitymode)
	} // if (gamepad_is_supported())
	// Compatibility mode reads saved raw axes and button numbers instead.
	// Numbered scancodes
	if (gamepad_is_supported()) {
	    if (gamepad_is_connected(global.opjoyid) && global.joydetected && global.compatibilitymode) {
	        // Choose a stick, optionally exchanging the horizontal and vertical axes.
	        if(global.opanalog_stick == 0) {
	            if(global.opanalog_invert == 0) {
	                xjoyx = gamepad_axis_value(global.opjoyid, gp_axislh);
	                xjoyy = gamepad_axis_value(global.opjoyid, gp_axislv);
	            }
	            else {
	                xjoyx = gamepad_axis_value(global.opjoyid, gp_axislv);
	                xjoyy = gamepad_axis_value(global.opjoyid, gp_axislh);
	            }
	        } 
	        else {
	            if(global.opanalog_invert == 0) {
	                xjoyx = gamepad_axis_value(global.opjoyid, gp_axisrh);
	                xjoyy = gamepad_axis_value(global.opjoyid, gp_axisrv);
	            }
	            else {
	                xjoyx = gamepad_axis_value(global.opjoyid, gp_axisrv);
	                xjoyy = gamepad_axis_value(global.opjoyid, gp_axisrh);
	            }
	        }
	        if (is_past_deadzone(xjoyx, xjoyy, 0)) {
	            if (is_walkzone(xjoyx, xjoyy, 0)) walk_zone = 1;
	            if (ctrl_Left == 0 && ctrl_Right == 0 && xjoyx < -(global.opxjoydz / 200)) {
	                ctrl_Left = -xjoyx;
	                global.controltype = 1;
	            }
	            if (ctrl_Left == 0 && ctrl_Right == 0 && xjoyx > global.opxjoydz / 200) {
	                ctrl_Right = xjoyx;
	                global.controltype = 1;
	            }
	            if (ctrl_Up == 0 && ctrl_Down == 0 && xjoyy < -(global.opxjoydz / 200)) {
	                ctrl_Up = 1;
	                global.controltype = 1;
	            }
	            if (ctrl_Up == 0 && ctrl_Down == 0 && xjoyy > global.opxjoydz / 200) {
	                ctrl_Down = 1;
	                global.controltype = 1;
	            }
	        }
	        // Convert the saved one-based button numbers to the gamepad API indices.
	        if (ctrl_Left == 0 && ctrl_Right == false && gamepad_button_check(global.opjoyid, global.opjoybtn_padl-1)) {
	            ctrl_Left = 1;
	            global.controltype = 1;
	            walk_zone = 0;
	        }
	        if (ctrl_Left == 0 && ctrl_Right == false && gamepad_button_check(global.opjoyid, global.opjoybtn_padr-1)) {
	            ctrl_Right = 1;
	            global.controltype = 1;
	            walk_zone = 0;
	        }
	        if (ctrl_Up == 0 && ctrl_Down == false && gamepad_button_check(global.opjoyid, global.opjoybtn_padu-1)) {
	            ctrl_Up = 1;
	            global.controltype = 1;
	            walk_zone = 0;
	        }
	        if (ctrl_Up == 0 && ctrl_Down == false && gamepad_button_check(global.opjoyid, global.opjoybtn_padd-1)) {
	            ctrl_Down = 1;
	            global.controltype = 1;
	            walk_zone = 0;
	        }
	        if (ctrl_A == false && gamepad_button_check(global.opjoyid, global.opjoybtn_a-1)) {
	            ctrl_A = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_B == false && gamepad_button_check(global.opjoyid, global.opjoybtn_b-1)) {
	            ctrl_B = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_X == false && gamepad_button_check(global.opjoyid, global.opjoybtn_x-1)) {
	            ctrl_X = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_L == false && gamepad_button_check(global.opjoyid, global.opjoybtn_l-1)) {
	            ctrl_L = 1;
	            global.controltype = 1;
	        }
	        if (global.opaimstyle == 1 && ctrl_L2 == false && gamepad_button_check(global.opjoyid, global.opjoybtn_l2-1)) {
	            ctrl_L2 = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_R == false && gamepad_button_check(global.opjoyid, global.opjoybtn_r-1)) {
	            ctrl_R = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_R2 == false && gamepad_button_check(global.opjoyid, global.opjoybtn_r2-1)) {
	            ctrl_R2 = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_Select == false && gamepad_button_check(global.opjoyid, global.opjoybtn_sel-1)) {
	            ctrl_Select = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_Start == false && gamepad_button_check(global.opjoyid, global.opjoybtn_str-1)) {
	            ctrl_Start = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_Exit == false && gamepad_button_check(global.opjoyid, global.opjoybtn_exit-1)) {
	            ctrl_Exit = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_Menu1 == false && gamepad_button_check(global.opjoyid, global.opjoybtn_menu1-1)) {
	            ctrl_Menu1 = 1;
	            global.controltype = 1;
	        }
	        if (ctrl_Menu2 == false && gamepad_button_check(global.opjoyid, global.opjoybtn_menu2-1)) {
	            ctrl_Menu2 = 1;
	            global.controltype = 1;
	        }
	    } // if (gamepad_is_connected(global.opjoyid) && global.joydetected && global.compatibilitymode)
	} // if (gamepad_is_supported())
	// Touch controls fill the same fields after controller input has been read.
	// Touch -- runs LAST so a connected pad wins conflicts via the ctrl_* == 0
	// guards below (dual input: touch is never muted by joydetected anymore).
	if (instance_exists(oTouchControls)) {
	    if (oTouchControls.fire_pressed[0] != -1) {
	        ctrl_A = 1;
	        global.controltype = 0;
	    }
	    if (oTouchControls.jump_pressed[0] != -1) {
	        ctrl_B = 1;
	        global.controltype = 0;
	    }
	    if (oTouchControls.morph_pressed[0] != -1) {
	        ctrl_X = 1;
	        global.controltype = 0;
	    }
	    // The diagonal aim buttons also turn an upright player toward the aimed side.
	    if (oTouchControls.aimupleft_pressed[0] != -1) {
	        ctrl_L = 1;
	        if(instance_exists(oCharacter) && oCharacter.facing == oCharacter.RIGHT) {
	            if (oCharacter.state != oCharacter.BALL && 
	                oCharacter.state != oCharacter.AIRBALL && 
	                oCharacter.state != oCharacter.SPIDERBALL && 
	                oCharacter.state != oCharacter.GRABBEDQUEENMORPH && 
	                oCharacter.state != oCharacter.GRABBEDQUEENBELLY) {
	                    ctrl_Left = 1;
	            }
	        }
	        global.controltype = 0;
	    }
	    if (global.opaimstyle && oTouchControls.aimdownleft_pressed[0] != -1) {
	        ctrl_L2 = 1;
	        if(instance_exists(oCharacter) && oCharacter.facing == oCharacter.RIGHT) {
	            if (oCharacter.state != oCharacter.BALL && 
	                oCharacter.state != oCharacter.AIRBALL && 
	                oCharacter.state != oCharacter.SPIDERBALL && 
	                oCharacter.state != oCharacter.GRABBEDQUEENMORPH && 
	                oCharacter.state != oCharacter.GRABBEDQUEENBELLY) {
	                    ctrl_Left = 1;
	            }
	        }
	        global.controltype = 0;
	    }
	        if (oTouchControls.aimupright_pressed[0] != -1) {
	        ctrl_L = 1;
	        if(instance_exists(oCharacter) && oCharacter.facing == oCharacter.LEFT) {
	            if (oCharacter.state != oCharacter.BALL && 
	                oCharacter.state != oCharacter.AIRBALL && 
	                oCharacter.state != oCharacter.SPIDERBALL && 
	                oCharacter.state != oCharacter.GRABBEDQUEENMORPH && 
	                oCharacter.state != oCharacter.GRABBEDQUEENBELLY) {
	                    ctrl_Right = 1;
	            }
	        }
	        global.controltype = 0;
	    }
	    if (global.opaimstyle && oTouchControls.aimdownright_pressed[0] != -1) {
	        ctrl_L2 = 1;
	        if(instance_exists(oCharacter) && oCharacter.facing == oCharacter.LEFT) {
	            if (oCharacter.state != oCharacter.BALL && 
	                oCharacter.state != oCharacter.AIRBALL && 
	                oCharacter.state != oCharacter.SPIDERBALL && 
	                oCharacter.state != oCharacter.GRABBEDQUEENMORPH && 
	                oCharacter.state != oCharacter.GRABBEDQUEENBELLY) {
	                    ctrl_Right = 1;
	            }
	        }
	        global.controltype = 0;
	    }
	    if (oTouchControls.missile_pressed[0] != -1) {
	        ctrl_R = 1;
	        global.controltype = 0;
	    }
	    // Use the same Select action as a controller without changing Hold or Toggle rules.
	    if (touch_weapon_select_available() && oTouchControls.weapon_select_pressed != -1) {
	        ctrl_Select = 1;
	        global.controltype = 0;
	    }
	    if (oTouchControls.pause_pressed[0] != -1) {
	        ctrl_Start = 1;
	        global.controltype = 0;
	    }
	    if (oTouchControls.fire_pressed[0] != -1) {
	        ctrl_Menu1 = 1;
	        global.controltype = 0;
	    }
	    if (oTouchControls.jump_pressed[0] != -1) {
	        ctrl_Menu2 = 1;
	        global.controltype = 0;
	    }
	    // Apply the touch-stick deadzone and respect explicit direction buttons.
	    xjoyx = oTouchControls.joyx;
	    xjoyy = oTouchControls.joyy;
	    if (is_past_deadzone(xjoyx, xjoyy, 2)) {
	        if (is_walkzone(xjoyx, xjoyy, 2)) walk_zone = 1;
	        if (ctrl_Left == 0 && ctrl_Right == 0 && xjoyx < -(global.opxjoydz / 100) && oTouchControls.up_pressed[0] == -1 && oTouchControls.down_pressed[0] == -1) {
	            ctrl_Left = -xjoyx;
	            global.controltype = 2;
	        }
	        if (ctrl_Left == 0 && ctrl_Right == 0 && xjoyx > (global.opxjoydz / 100) && oTouchControls.up_pressed[0] == -1 && oTouchControls.down_pressed[0] == -1) {
	            ctrl_Right = xjoyx;
	            global.controltype = 2;
	        }
	        if (ctrl_Up == 0 && ctrl_Down == 0 && xjoyy < -(global.opxjoydz / 100) && oTouchControls.left_pressed[0] == -1 && oTouchControls.right_pressed[0] == -1) {
	            ctrl_Up = 1;
	            global.controltype = 2;
	        }
	        if (ctrl_Up == 0 && ctrl_Down == 0 && xjoyy > (global.opxjoydz / 100) && oTouchControls.left_pressed[0] == -1 && oTouchControls.right_pressed[0] == -1) {
	            ctrl_Down = 1;
	            global.controltype = 2;
	        }
	    }
	}



}


// Show a separate selector only when Hold mode has two owned missile types.
function touch_weapon_select_available() {
    return global.ingame && global.opmslstyle == 0
        && global.maxmissiles > 0 && global.maxsmissiles > 0;
}

// --- Immersion haptics SDK bridge (GM2026 port) ---
// The GMS 1.4 Immersion haptics functions were removed in GameMaker 2026.
// These forward the original Immersion UHL effect ids to the AM2RHaptics
// Android extension (extensions/AM2RHaptics/AndroidSource/Java/AM2RHaptics.java),
// which approximates each effect with android.os.Vibrator waveforms.
// Defined here (outside touch_keys()) so they register as global functions.
function immersion_stop() {
	if (global.android_app) AM2RHaptics_Stop();
}
function immersion_play_effect(_effect) {
	if (global.android_app) AM2RHaptics_Play(_effect);
}
