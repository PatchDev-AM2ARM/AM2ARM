if (active && touch_slider_finger < 0) {
    if (oControl.kDown > 0 && (oControl.kDownPushedSteps == 0 || oControl.kDownPushedSteps > 30 && timer == 0) && !inputdel) {
        global.curropt += 1;
        if (global.curropt > lastitem) global.curropt = 0;
        while (canedit[global.curropt] == 0) global.curropt += 1;
        targety = op[global.curropt].y + 8 + 8;
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    }
    if (oControl.kUp > 0 && (oControl.kUpPushedSteps == 0 || oControl.kUpPushedSteps > 30 && timer == 0) && !inputdel) {
        global.curropt -= 1;
        if (global.curropt < 0) global.curropt = lastitem;
        while (canedit[global.curropt] == 0) global.curropt -= 1;
        targety = op[global.curropt].y + 8 + 8;
        sfx_play(sndMenuMove);
        global.tiptext = tip[global.curropt];
    }
    if (!oControl.kDown && !oControl.kUp) {
        var _direction = (oControl.kRight > 0) - (oControl.kLeft > 0);
        var _held = _direction > 0 ? oControl.kRightPushedSteps : oControl.kLeftPushedSteps;
        if (global.curropt == 3 && _direction != 0 && _held == 0)
            global.opspdstyle = (global.opspdstyle + _direction + 3) mod 3;
        if ((global.curropt >= 9 && global.curropt <= 11) && canedit[global.curropt]
            && _direction != 0 && (_held == 0 || _held > 8)) {
            if (touch_options_set(global.curropt, touch_options_value(global.curropt) + _direction * 0.01)) {
                if (_held == 0) sfx_play(sndMenuMove);
                event_user(2);
            }
        }
    }
    if (((oControl.kLeft > 0 && oControl.kLeftPushedSteps == 0) || (oControl.kRight > 0 && oControl.kRightPushedSteps == 0)) && (((os_type != os_android) && global.curropt < 6) || ((os_type == os_android || os_type == os_linux) && global.curropt < 8)) && ((oControl.kDown == 0) && (oControl.kUp == 0))) {
        if (global.curropt == 0) global.opaimstyle = !global.opaimstyle;
        if (global.curropt == 1) global.opmslstyle = !global.opmslstyle;
        if (global.curropt == 2) global.opmrpstyle = !global.opmrpstyle;
        if (global.curropt == 4) global.opautoclimb = !global.opautoclimb;
        if (global.curropt == 5) global.opautomorph = !global.opautomorph;
        if (os_type == os_android && global.curropt == 6) {
            global.opxjoyvib = !global.opxjoyvib;
            if (global.opxjoyvib) ctrl_vibrate(1, 1, 15);
        }
        if ((os_type == os_android || os_type == os_linux) && global.curropt == 7) { // OG 
            global.compatibilitymode = !global.compatibilitymode;
            android_gamepad_configure();
        }
        sfx_play(sndMenuMove);
        event_user(2);
    }
    if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
        if (os_type != os_android && global.curropt == 6) {
            save_gameoptions();
            __view_set( e__VW.Object, 0, noone );
            __view_set( e__VW.YView, 0, 0 );
            instance_create(50, 92, oOptionsKeyboard);
            instance_destroy();
            sfx_play(sndMenuSel);
        }
        // Choose the remapping screen that matches the platform and selected controller backend.
        if (global.curropt == 8 && canedit[8]) {
            save_gameoptions();
            __view_set( e__VW.Object, 0, noone );
            __view_set( e__VW.YView, 0, 0 );
            if ((os_type != os_android) && (os_type != os_linux) && (global.controltype == 2)) {
                instance_create(50, 92, oOptionsXJoypad);
            }
            else if (((os_type == os_android) || (os_type == os_linux)) && global.compatibilitymode == 0) {
                instance_create(50, 92, oOptionsMogaJoypad);
            } else {
                instance_create(50, 92, oOptionsJoypad);
            }
            instance_destroy();
            sfx_play(sndMenuSel);
        }
        if (global.curropt == lastitem) {
            save_gameoptions();
            __view_set( e__VW.Object, 0, noone );
            __view_set( e__VW.YView, 0, 0 );
            instance_create(50, 92, oOptionsMain);
            instance_destroy();
            sfx_play(sndMenuSel);
        }
    } // if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0)
} // if (active)
if (targety != y) y += (targety - y) / 10;
timer -= 1;
if (timer < 0) timer = 8;
inputdel = max(0, inputdel - 1);

