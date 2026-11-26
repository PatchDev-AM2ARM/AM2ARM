/// @description Keep touch artwork and hitboxes in the same safe GUI rectangle.
function touch_layout_apply() {
    var _w = display_get_gui_width(), _h = display_get_gui_height();
    var _sx = _w / max(1, display_get_width());
    var _sy = _h / max(1, display_get_height());
    var _side = 25 + max(oControl.touch_safe_left, oControl.touch_safe_right) * _sx;
    var _top = oControl.touch_safe_top * _sy;
    var _bottom = oControl.touch_safe_bottom * _sy;
    scale = oControl.touch_scale;
    st_radius = _h / max(1, scale);
    // Leave room for both clusters, Pause, and the Hold-only weapon selector.
    st_radius = min(st_radius, max(1, (_w - 2 * _side - 50) / 4.5),
        max(1, (_h - _top - _bottom - 50) / 2.55));
    control_radius = st_radius;
    var _space = max(0, (_w - 2 * _side - 4.5 * st_radius - 50) / 2);
    var _inset = min(_h * 0.2, _space) * oControl.touch_inset / 5;
    st_offset = _side + _inset + st_radius;
    gui_x[0] = st_offset;
    gui_x[1] = _w - st_offset;
    gui_y[0] = _h - _bottom - 25 - st_radius;
    gui_y[1] = gui_y[0];
    btn_width = st_radius;
    btn_height = st_radius;
    btn_y = gui_y[1];
    btn_x = _w - _side - _inset;
    btn_jump_x = btn_x - btn_width * 2;
    btn_fire_x = btn_x - btn_width;
    btn_missile_x = btn_jump_x;
    btn_missile_y = btn_y - btn_height;
    btn_morph_x = btn_fire_x;
    btn_morph_y = btn_y - btn_height;
    btn_pause_x = mean(gui_x[0] + st_radius, btn_jump_x);
    btn_pause_y = gui_y[1] + st_radius;

    buttonScale = ((150*btn_width)/300)/150; // ((150*btn_width)/300)/150
    pauseScale = ((50*btn_height/3)/85)/50;

    btn_jump[0] = btn_jump_x;
    btn_jump[1] = btn_y+10;
    btn_jump[2] = btn_jump_x + btn_width-10;
    btn_jump[3] = btn_y + btn_height;

    btn_fire[0] = btn_fire_x+10;
    btn_fire[1] = btn_y + 10;
    btn_fire[2] = btn_fire_x + btn_width;
    btn_fire[3] = btn_y + btn_height;

    btn_missile[0] = btn_missile_x;
    btn_missile[1] = btn_missile_y;
    btn_missile[2] = btn_missile_x + btn_width - 10;
    btn_missile[3] = btn_missile_y + btn_height - 10;

    // Keep the ammo switch above the arm button, with a gap between touch targets.
    btn_weapon_select[0] = btn_missile[0];
    btn_weapon_select[1] = btn_missile[1] - btn_height * 0.55;
    btn_weapon_select[2] = btn_missile[2];
    btn_weapon_select[3] = btn_missile[1] - btn_height * 0.05;

    btn_morph[0] = btn_morph_x + 10;
    btn_morph[1] = btn_morph_y;
    btn_morph[2] = btn_morph_x + btn_width;
    btn_morph[3] = btn_morph_y + btn_height - 10;

    btn_pause[0] = btn_pause_x - btn_width/4;
    btn_pause[1] = btn_pause_y - btn_height/3;
    btn_pause[2] = btn_pause_x + btn_width/4;
    btn_pause[3] = btn_pause_y;

    btn_pausearrow_y = btn_pause_y - btn_height/3/2;

    // Share the fixed left-hand footprint between the stick and diagonal targets.
    // Keep the original gap to each diagonal edge, including at the largest setting.
    var _aim_leg = control_radius * lerp(0.5, 0.95, oControl.touch_aim_balance);
    // Up Left
    btn_aimul[0] = gui_x[0] - st_radius;
    btn_aimul[1] = gui_y[0] - st_radius;
    btn_aimul[2] = (gui_x[0] - st_radius) + _aim_leg;
    btn_aimul[3] = (gui_y[0] - st_radius);
    btn_aimul[4] = (gui_x[0] - st_radius);
    btn_aimul[5] = (gui_y[0] - st_radius) + _aim_leg;

    // Down Left
    btn_aimdl[0] = gui_x[0] - st_radius;
    btn_aimdl[1] = gui_y[0] + st_radius;
    btn_aimdl[2] = (gui_x[0] - st_radius) + _aim_leg;
    btn_aimdl[3] = (gui_y[0] + st_radius);
    btn_aimdl[4] = (gui_x[0] - st_radius);
    btn_aimdl[5] = (gui_y[0] + st_radius) - _aim_leg;

    // Up Right
    btn_aimur[0] = gui_x[0] + st_radius;
    btn_aimur[1] = gui_y[0] - st_radius;
    btn_aimur[2] = (gui_x[0] + st_radius) - _aim_leg;
    btn_aimur[3] = (gui_y[0] - st_radius);
    btn_aimur[4] = (gui_x[0] + st_radius);
    btn_aimur[5] = (gui_y[0] - st_radius) + _aim_leg;

    // Down Right
    btn_aimdr[0] = gui_x[0] + st_radius;
    btn_aimdr[1] = gui_y[0] + st_radius;
    btn_aimdr[2] = (gui_x[0] + st_radius) - _aim_leg;
    btn_aimdr[3] = (gui_y[0] + st_radius);
    btn_aimdr[4] = (gui_x[0] + st_radius);
    btn_aimdr[5] = (gui_y[0] + st_radius) - _aim_leg;

    st_radius = control_radius - (_aim_leg - control_radius * 0.5) / sqrt(2);

    // Up Button
    btn_aimu[0] = gui_x[0];
    btn_aimu[1] = gui_y[0] - st_radius/4;
    btn_aimu[2] = gui_x[0] - st_radius;
    btn_aimu[3] = gui_y[0] - st_radius;
    btn_aimu[4] = gui_x[0] + st_radius;
    btn_aimu[5] = gui_y[0] - st_radius;

    // Down Button
    btn_aimd[0] = gui_x[0];
    btn_aimd[1] = gui_y[0] + st_radius/4;
    btn_aimd[2] = gui_x[0] - st_radius;
    btn_aimd[3] = gui_y[0] + st_radius;
    btn_aimd[4] = gui_x[0] + st_radius;
    btn_aimd[5] = gui_y[0] + st_radius;

    // Right Button
    btn_aimr[0] = gui_x[0] + st_radius/4;
    btn_aimr[1] = gui_y[0];
    btn_aimr[2] = gui_x[0] + st_radius;
    btn_aimr[3] = gui_y[0] + st_radius;
    btn_aimr[4] = gui_x[0] + st_radius;
    btn_aimr[5] = gui_y[0] - st_radius;

    // Left Button
    btn_aiml[0] = gui_x[0] - st_radius/4;
    btn_aiml[1] = gui_y[0];
    btn_aiml[2] = gui_x[0] - st_radius;
    btn_aiml[3] = gui_y[0] + st_radius;
    btn_aiml[4] = gui_x[0] - st_radius;
    btn_aiml[5] = gui_y[0] - st_radius;

    // Up Arrow
    btn_uparrow[0] = gui_x[0];
    btn_uparrow[1] = gui_y[0] - st_radius/1.25;
    btn_uparrow[2] = gui_x[0] + st_radius/4;
    btn_uparrow[3] = gui_y[0] - st_radius/2;
    btn_uparrow[4] = gui_x[0] - st_radius/4;
    btn_uparrow[5] = gui_y[0] - st_radius/2;

    // Down Arrow
    btn_downarrow[0] = gui_x[0];
    btn_downarrow[1] = gui_y[0] + st_radius/1.25;
    btn_downarrow[2] = gui_x[0] + st_radius/4;
    btn_downarrow[3] = gui_y[0] + st_radius/2;
    btn_downarrow[4] = gui_x[0] - st_radius/4;
    btn_downarrow[5] = gui_y[0] + st_radius/2;

    // Left Arrow
    btn_leftarrow[0] = gui_x[0] - st_radius/1.25;
    btn_leftarrow[1] = gui_y[0];
    btn_leftarrow[2] = gui_x[0] - st_radius/2;
    btn_leftarrow[3] = gui_y[0] - st_radius/4;
    btn_leftarrow[4] = gui_x[0] - st_radius/2;
    btn_leftarrow[5] = gui_y[0] + st_radius/4;

    // Right Arrow
    btn_rightarrow[0] = gui_x[0] + st_radius/1.25;
    btn_rightarrow[1] = gui_y[0];
    btn_rightarrow[2] = gui_x[0] + st_radius/2;
    btn_rightarrow[3] = gui_y[0] - st_radius/4;
    btn_rightarrow[4] = gui_x[0] + st_radius/2;
    btn_rightarrow[5] = gui_y[0] + st_radius/4;

    // A moved target must not claim a finger that was already held elsewhere.
    if (variable_instance_exists(id, "layout_gui_width")) {
        for (var _finger = 0; _finger < 5; _finger++) {
            wake_touch[_finger] = device_mouse_check_button(_finger, mb_left);
        }
    }
    st_pressed[0] = -1; st_pressed[1] = -1;
    jump_pressed[0] = -1; jump_pressed[1] = -1;
    fire_pressed[0] = -1; fire_pressed[1] = -1;
    aimupleft_pressed[0] = -1; aimupleft_pressed[1] = -1;
    aimdownleft_pressed[0] = -1; aimdownleft_pressed[1] = -1;
    aimupright_pressed[0] = -1; aimupright_pressed[1] = -1;
    aimdownright_pressed[0] = -1; aimdownright_pressed[1] = -1;
    missile_pressed[0] = -1; missile_pressed[1] = -1;
    morph_pressed[0] = -1; morph_pressed[1] = -1;
    pause_pressed[0] = -1; pause_pressed[1] = -1;
    up_pressed[0] = -1; up_pressed[1] = -1;
    down_pressed[0] = -1; down_pressed[1] = -1;
    left_pressed[0] = -1; left_pressed[1] = -1;
    right_pressed[0] = -1; right_pressed[1] = -1;
    weapon_select_pressed = -1;
    joyx = 0; joyy = 0;
    stick_x[0] = gui_x[0]; stick_y[0] = gui_y[0];
    stick_x[1] = gui_x[1]; stick_y[1] = gui_y[1];
    layout_gui_width = _w;
    layout_gui_height = _h;
    layout_revision = oControl.touch_layout_revision;
    layout_inset = oControl.touch_inset;
    layout_aim_balance = oControl.touch_aim_balance;
}

/// @description Read the safe rectangle supplied by the Android runner.
function touch_layout_receive(_event) {
    if (_event[? "type"] != "DisplayLayoutInfo") return;
    var _left = touch_layout_edge(_event, "left");
    var _right = touch_layout_edge(_event, "right");
    var _top = touch_layout_edge(_event, "top");
    var _bottom = touch_layout_edge(_event, "bottom");
    if (touch_safe_left != _left || touch_safe_right != _right
        || touch_safe_top != _top || touch_safe_bottom != _bottom) {
        touch_safe_left = _left; touch_safe_right = _right;
        touch_safe_top = _top; touch_safe_bottom = _bottom;
        touch_layout_revision++;
    }
}

function touch_layout_edge(_event, _edge) {
    var _safe = _event[? "safeinset" + _edge];
    var _waterfall = _event[? "waterfallinset" + _edge];
    if (is_undefined(_safe)) _safe = 0;
    if (is_undefined(_waterfall)) _waterfall = 0;
    return max(0, _safe, _waterfall);
}

// Keep the saved size divisor and inset compatible with earlier installations.
// The size slider maps linearly to the visible radius, rather than its divisor.
function touch_options_value(_row) {
    if (_row == 9) return clamp((1 / oControl.touch_scale - 1 / 8) / (1 / 3 - 1 / 8), 0, 1);
    if (_row == 11) return oControl.touch_aim_balance;
    return clamp(1 - oControl.touch_inset / 5, 0, 1);
}

function touch_options_set(_row, _value) {
    _value = clamp(_value, 0, 1);
    if (_row == 9) {
        var _scale = 1 / lerp(1 / 8, 1 / 3, _value);
        if (abs(oControl.touch_scale - _scale) < 0.000001) return false;
        oControl.touch_scale = _scale;
    } else if (_row == 11) {
        if (abs(oControl.touch_aim_balance - _value) < 0.000001) return false;
        oControl.touch_aim_balance = _value;
    } else {
        var _inset = 5 * (1 - _value);
        if (abs(oControl.touch_inset - _inset) < 0.000001) return false;
        oControl.touch_inset = _inset;
    }
    return true;
}

function touch_options_pointer() {
    if (os_type != os_android || !active) return;
    if (touch_slider_finger >= 0 && (!device_mouse_check_button(touch_slider_finger, mb_left) || os_is_paused())) {
        touch_slider_finger = -1;
        touch_slider_row = -1;
    }
    if (os_is_paused()) return;
    if (touch_slider_finger < 0) {
        for (var _finger = 0; _finger < 5; _finger++) {
            if (!device_mouse_check_button_pressed(_finger, mb_left)) continue;
            var _point = touch_options_point(_finger);
            // Ignore the header/footer and off-screen rows while this list scrolls.
            var _screen_y = _point[1] - __view_get(e__VW.YView, 0);
            if (_screen_y < 41 || _screen_y >= 194) continue;
            for (var _row = 9; _row <= 11; _row++) {
                var _slider = op[_row];
                if (!canedit[_row] || !_slider.visible) continue;
                var _left = _slider.x + _slider.textoffset;
                if (point_in_rectangle(_point[0], _point[1], _left - 6, _slider.y - 4,
                    _left + _slider.w + 6, _slider.y + 12)) {
                    touch_slider_finger = _finger;
                    touch_slider_row = _row;
                    global.curropt = _row;
                    global.tiptext = tip[_row];
                    targety = _slider.y + 16;
                    break;
                }
            }
            if (touch_slider_finger >= 0) break;
        }
    }
    if (touch_slider_finger < 0) return;
    var _held_finger = touch_slider_finger;
    with (oTouchControls) {
        wake_touch[_held_finger] = 1;
        alpha = 0.5;
        alarm[0] = 240;
    }
    var _held = op[touch_slider_row];
    var _position = touch_options_point(_held_finger);
    if (touch_options_set(touch_slider_row, (_position[0] - _held.x - _held.textoffset) / _held.w)) event_user(2);
}

function touch_options_point(_finger) {
    var _x = scr_mouse_gui_x(device_mouse_raw_x(_finger)) * window_get_width() / display_get_gui_width();
    var _y = scr_mouse_gui_y(device_mouse_raw_y(_finger)) * window_get_height() / display_get_gui_height();
    return [(_x - oControl.displayx) / oControl.display_scale + __view_get(e__VW.XView, 0) - oControl.widescreen_space / 2,
        (_y - oControl.displayy) / oControl.display_scale + __view_get(e__VW.YView, 0)];
}

function android_orientation_text(_key, _fallback) {
    var _text = get_text("OptionsDisplay", _key);
    return _text == "[!]" ? _fallback : _text;
}
