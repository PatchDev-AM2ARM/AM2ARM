if (active) {
    // Menu DOWN
    if (oControl.kDown > 0 && (oControl.kDownPushedSteps == 0 || oControl.kDownPushedSteps > 30 && timer == 0)) {      
        global.curropt += 1;
        // Wrap
        if (global.curropt > menuSize) global.curropt = 0;
        // Skip inactive
        while (canEdit[global.curropt] == 0) {
            global.curropt += 1;
            // Wrap again (safety)
            if (global.curropt > menuSize) global.curropt = 0;
        }
        // New target
        targetY = op[global.curropt].y + 16;
        if (targetY > vTargetY) targetY = vTargetY;
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    } // Menu UP
    else if (oControl.kUp > 0 && (oControl.kUpPushedSteps == 0 || oControl.kUpPushedSteps > 30 && timer == 0)) {
        global.curropt -= 1;
        // Wrap
        if (global.curropt < 0) global.curropt = menuSize;
        // Skip inactive
        while (canEdit[global.curropt] == 0)
        {
            global.curropt -= 1;
            // Wrap again (safety)
            if (global.curropt < 0) global.curropt = menuSize;
        }
        // New target
        targetY = op[global.curropt].y + 16;
        if (targetY > vTargetY) targetY = vTargetY;
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    }
    
    var input = oControl.kRight - oControl.kLeft;
    var inputSteps = oControl.kRightPushedSteps - oControl.kLeftPushedSteps;
    
    // Menu LEFT and RIGHT
    if (input != 0 && inputSteps == 0 && global.curropt < menuSize && oControl.kDown == 0 && oControl.kUp == 0) {
        
        if (os_type != os_android) {
            // Fullscreen
            if (global.curropt == opFullscreen) {
                global.opfullscreen = !global.opfullscreen;
                set_fullscreen(global.opfullscreen);
                if (!global.opfullscreen) {
                    global.opscale = 1;
                    // Update window scale
                    alarm[1] = 1;
                }
            }
            
            // Scale
            if (global.curropt == opScale) {
                if (global.opfullscreen) {
                    global.opscale = wrap(global.opscale + input, 0, 4);
                }
                if (!global.opfullscreen) {
                    global.opscale = wrap(global.opscale + input, 1, 4)
                    set_window_scale(global.opscale);
                }
            }
        }
        
        // VSync
        if (global.curropt == opVSync) {
            global.opvsync = !global.opvsync;
            display_reset(0, global.opvsync);
            if (!global.opfullscreen) set_window_scale(global.opscale);
        }
        

        // Sensitivity Mode
        if (global.curropt == opSensitivity) {
            global.sensitivitymode = !global.sensitivitymode;
        }
        
        if (global.curropt == opNano) global.nano_enabled = !global.nano_enabled;

        // Aspect ratio. Active gameplay switches at the next room boundary.
        if (global.curropt == opWidescreen) {
            global.opaspectratio = wrap(global.opaspectratio + input, 0, 2);
            oControl.aspect_auto = false;
            if (room == rm_options) {
                var _old_width = 320 + oControl.widescreen_space;
                with (oControl) standard_aspect_apply(global.opaspectratio);
                oControl.widescreen_switch = false;
                if (os_type != os_android && global.opfullscreen == 0) {
                    var _scale = window_get_height() / 240;
                    set_window_scale(_scale);
                    window_set_position(window_get_x() + (_old_width - standard_aspect_width(global.opaspectratio)) * _scale / 2, window_get_y());
                }
                if (global.opfullscreen == 1 || os_type == os_android) {
                    display_reset(0, global.opvsync);
                }
            }
        }

        if (global.curropt == opOrientation) {
            global.oporientation = wrap(global.oporientation + input, 0, 2);
            Android_Orientation(global.oporientation);
        }

        // Reopen the menu, since its rows depend on this option.
        if (global.curropt == opDualScreen) {
            with (oControl) dual_set_enabled(!dual_enabled);
            sfx_play(sndMenuMove);
            with (instance_create(50, 92, oOptionsDisplay)) {
                global.curropt = opDualScreen;
                global.tiptext = tip[opDualScreen];
                targetY = min(op[opDualScreen].y + 16, vTargetY);
            }
            instance_destroy();
            exit;
        }

        if (global.curropt == opSwapScreens) {
            with (oControl) dual_swap_set(!dual_swap_screens);
        }

        // Show HUD
        if (global.curropt == opShowHUD) {
            // Move health and ammunition between the two screens.
            if (oControl.dual_enabled) {
                with (oControl) {
                    dual_hud_top = !dual_hud_top;
                    dual_apply_hud_layout();
                }
            } else global.opshowhud = !global.opshowhud;
        }
        // Show Map
        if (global.curropt == opShowMap) global.ophudshowmap = !global.ophudshowmap;
        
        // Monster Counter
        if (global.curropt == opCounterStyle) {
            global.ophudshowmetrcount = wrap(global.ophudshowmetrcount + input, 0, 2);
        }
        
        // Show Hints
        if (global.curropt == opShowHints) global.ophudshowhints = !global.ophudshowhints;
        
        // Button Prompt Style
        if (buttonsEnabled && global.curropt == opButtonType) {
            var inputMax = 5 - ((os_type == os_android) * 2);
            oControl.mod_buttonsconfig = wrap(oControl.mod_buttonsconfig + input, 0, inputMax);
            
            // Update events
            event_user(3);
            event_user(4);
        }
        
        // Show Scans
        if (global.curropt == opShowScans) global.ophudshowlogmsg = !global.ophudshowlogmsg;
        
        // Language
        if (global.curropt == opLanguage) {
            global.currentlanguage = wrap(global.currentlanguage + input, 0, langCount - 1);
            port_locale_refresh();
            
            // Update events
            event_user(3);
            event_user(4);
            global.tiptext = tip[global.curropt];
        }
        
        sfx_play(sndMenuMove);
        
        // Update text
        event_user(2);
    }

    if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
        // On Exit, reload resources, save options, reset the menu camera, and recreate the main settings menu.
        if (global.curropt == menuSize) {
            load_resources();
            save_gameoptions();
            __view_set( e__VW.Object, 0, noone );
            __view_set( e__VW.YView, 0, 0 );
            instance_create(50, 92, oOptionsMain);
            instance_destroy();
            sfx_play(sndMenuSel);
        }
    }
}

// Ease the menu camera toward the selected row while the timer limits held-key repeats.
if (targetY != y) y += (targetY - y) / 10;

timer -= 1;

if (timer < 0) timer = 8;
