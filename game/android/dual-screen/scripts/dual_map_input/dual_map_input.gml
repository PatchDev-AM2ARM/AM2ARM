// Lower-map control bounds, controller input and gestures.
// Runs in oControl scope. Drawing and hit testing share the same layout coordinates.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function dual_layout_controls() {
    // The same native artwork and touch bounds serve both HUD positions.
    var _r = dual_art_scale, _w = dual_art_width;
    var _left = -dual_pad + (dual_width - _w * _r) / 2;
    var _starts = [0, 18, 36, 69, 127 + floor((_w - 177) / 2)];
    var _ends = [17, 35, 68, _starts[4] - 1, _w];
    dual_map_buttons = array_create(5);
    dual_action_buttons = array_create(3);
    for (var _i = 0; _i < 5; ++_i)
        dual_map_buttons[_i] = [_left + _starts[_i] * _r, _left + _ends[_i] * _r];
    for (var _i = 0; _i < 3; ++_i)
        dual_action_buttons[_i] = [_left + floor(_w * _i / 3) * _r,
            _left + (floor(_w * (_i + 1) / 3) - (_i < 2 ? 1 : 0)) * _r];
}

// Return the toolbar slot containing this horizontal position, or no slot when the tap falls in a gap.
function dual_toolbar_hit(_buttons, _x) {
    for (var _i = 0; _i < array_length(_buttons); ++_i) {
        if (_x >= _buttons[_i][0] && _x <= _buttons[_i][1]) return _i;
    }
    return -1;
}

function dual_map_action(_action) {
    // A toolbar action replaces the current pinch adjustment with a zoom, overview, or follow choice.
    dual_gesture_until = 0;
    sfx_play(sndMenuMove);
    switch (_action) {
        case 1:
            var _next = dual_zoom > 2 ? 2 : (dual_zoom > 1 ? 1 : (dual_zoom > 0.5 ? 0.5 : 0.25));
            dual_zoom = min(dual_zoom, max(min(1, dual_map_fit_zoom()), _next));
            dual_overview = false;
            break;
        case 2: dual_zoom = dual_zoom < 0.5 ? 0.5 : (dual_zoom < 1 ? 1 : (dual_zoom < 2 ? 2 : 4)); dual_overview = false; break;
        case 3: dual_follow = false; dual_overview = true; break;
        case 4: dual_zoom = dual_manual_zoom; dual_follow = true; dual_overview = false; break;
        case 5: dual_zoom = 1; dual_overview = false; break;
    }
    // Remember deliberate zoom changes so Follow can return from the temporary Fit Map view.
    if (_action == 1 || _action == 2 || _action == 5) dual_manual_zoom = dual_zoom;
}

function dual_map_fit_zoom() {
    // Quarter-pixel cell steps use the available height on shorter panels.
    // Tile boundaries are snapped individually; the finished map is never resized.
    var _cell = max(2, floor(4 * min(16, (dual_width - 16) / max(1, dual_map_max_x - dual_map_min_x),
        (dual_map_bottom - dual_map_top - 4) / max(1, dual_map_max_y - dual_map_min_y))) / 4);
    if (_cell >= 8) _cell = 8 * floor(_cell / 8);
    return _cell / 8;
}

function dual_map_pick_cell(_pixel, _origin) {
    // Invert the same rounded tile boundaries used by the compact map.
    return ceil((floor(_pixel - _origin) + 0.5) / (8 * dual_zoom)) - 1;
}

function dual_map_pad_available(_button) {
    // Preserve confirm/menu/pause and the original collected-item toggle before shortcuts.
    return global.joydetected && !global.compatibilitymode && gamepad_is_connected(global.opjoyid)
        && _button != global.opxjoybtn_menu1 && _button != global.opxjoybtn_menu2
        && _button != global.opxjoybtn_str && _button != global.opxjoybtn_r;
}

function dual_map_toolbar_input(_input, _paused) {
    if (!_paused && _input.tap && _input.y >= dual_art_map_controls_top() && _input.y < dual_height) {
        var _button = dual_toolbar_hit(dual_map_buttons, _input.x);
        if (_button >= 0) dual_map_action([2, 1, 5, 3, 4][_button]);
    }
    if (_paused && instance_exists(oMapCursor) && oMapCursor.active) {
        var _buttons = [gp_shoulderl, gp_shoulderr, gp_face4, gp_face3];
        for (var _b = 0; _b < 4; ++_b) {
            if (dual_map_pad_available(_buttons[_b]) && gamepad_button_check_pressed(global.opjoyid, _buttons[_b])) {
                dual_map_action(_b + 1);
            }
        }
    }
}

// Merge touch actions before global_control() derives pressed/held states.
// The same existing menu events handle controller buttons and lower-screen taps.
function dual_input() {
    if (!dual_enabled) exit;
    // Consume one batch of lower-screen gestures before oControl converts raw controls into pressed and held states.
    var _payload = DualScreen_Touch();
    var _input = dual_idle_input;
    if (_payload != "") {
        dual_nano_dirty = true;
        // Touches are in screen pixels.
        _input = json_parse(_payload);
        _input.x = (_input.x - dual_x) / dual_scale - dual_pad;
        _input.y = (_input.y - dual_y) / dual_scale;
        _input.originX = (_input.originX - dual_x) / dual_scale - dual_pad;
        _input.originY = (_input.originY - dual_y) / dual_scale;
        _input.dx /= dual_scale;
        _input.dy /= dual_scale;
    }
    if (dual_setup_needed) {
        if (_input.tap) dual_setup_tap = dual_setup_hit(_input.x + 5, _input.y - floor((dual_height - 240) / 2));
        return;
    }
    dual_marker_pan = false;
    if (dual_frontend_input(_input)) return;

    if (room == rm_subscreen) {
        if (instance_exists(oSS_Fg) && oSS_Fg.fadeout) {
            ctrl_Menu1 = ctrl_Menu2 = ctrl_Start = 0;
            dual_pending_action = 0;
            exit;
        }
        var _map_page = global.ssmode == 0 && !instance_exists(oSubScrChange);
        // A direction held in gameplay must be released before it can browse the paused map.
        if (!(ctrl_Left || ctrl_Right || ctrl_Up || ctrl_Down)) dual_pause_direction_ready = true;
        if (!dual_pause_direction_ready) ctrl_Left = ctrl_Right = ctrl_Up = ctrl_Down = 0;
        // Replay a gameplay toolbar request only after the pause page has finished opening.
        if (dual_pending_action != 0 && instance_exists(oSS_Fg) && oSS_Fg.active && !oSS_Fg.fadein) {
            if (dual_pending_action == 1 && _map_page && instance_exists(oMapCursor) && oMapCursor.active) {
                ctrl_Menu1 = 1;
                dual_pending_action = 0;
            } else if (dual_pending_action == 2 && oSS_Control.canchange && !instance_exists(oSubScrChange)) {
                ctrl_Menu2 = 1;
                dual_pending_action = 0;
            }
        }
        if (_input.tap && _input.y >= ( _map_page ? dual_art_map_controls_top() : dual_art_page_controls_top())) {
            var _button = dual_toolbar_hit(dual_action_buttons, _input.x);
            if (_button == 0) ctrl_Menu1 = 1;
            if (_button == 1) ctrl_Menu2 = 1;
            if (_button == 2) ctrl_Start = 1;
        }
        // Pause pages retain their native pixels, centered inside the 310-pixel panel.
        var _px = _input.x + 5, _py = _input.y - dual_page_y;
        if (instance_exists(oSubScrChange)) {
            if (_input.tap && _input.y < dual_art_page_controls_top() && oSubScrChange.state == 1) {
                // The original four-way menu also accepts a tap on each sector.
                var _menu_y = dual_menu_center_y;
                if (abs(_px - 160) > abs(_py - _menu_y)) {
                    if (_px < 160) ctrl_Left = 1; else ctrl_Right = 1;
                } else {
                    if (_py < _menu_y) ctrl_Up = 1; else ctrl_Down = 1;
                }
            }
        } else if (_map_page && instance_exists(oMapCursor)) {
            // Pause activates controls on the permanent map; no second map viewport.
            dual_map_gesture(_input);
            dual_map_toolbar_input(_input, true);
            var _moving = ctrl_Left || ctrl_Right || ctrl_Up || ctrl_Down;
            if (_moving && oMapCursor.active) {
                dual_follow = false;
                dual_overview = false;
                if (oMapCursor.state == 1) dual_marker_pan = true;
                else {
                    dual_center_x += (ctrl_Right - ctrl_Left) / (4 * dual_zoom);
                    dual_center_y += (ctrl_Down - ctrl_Up) / (4 * dual_zoom);
                }
            }
            if (_input.tap && _input.y >= dual_map_top && _input.y < dual_map_bottom && oMapCursor.state == 1) {
                var _ox = round(155 - dual_center_x * 8 * dual_zoom);
                var _oy = round((dual_map_top + dual_map_bottom) / 2 - dual_center_y * 8 * dual_zoom);
                global.mapmarkerx = clamp(dual_map_pick_cell(_input.x, _ox), 3, 76);
                global.mapmarkery = clamp(dual_map_pick_cell(_input.y, _oy), 3, 59);
                with (oMapMarker) event_user(0);
            }
        // Resolve a settings-page tap against editable row instances in their scrolled world coordinates.
        } else if (global.ssmode == 3 && _input.tap && _py >= 42 && _py < 198) {
            // Wrapped translated help can cover the lowest menu rows. Match
            // the visible panel so a tap on its text cannot change a setting.
            if (instance_exists(oSS_Fg)
                && _py >= oSS_Fg.port_help_top) exit;
            var _world_x = __view_get(e__VW.XView, 0) + _px;
            var _world_y = __view_get(e__VW.YView, 0) + _py;
            var _chosen = noone;
            var _rows = [oPauseOption, oOptionLR, oOptionSlider];
            for (var _r = 0; _r < array_length(_rows); ++_r) {
                for (var _i = 0; _i < instance_number(_rows[_r]); ++_i) {
                    var _row = instance_find(_rows[_r], _i);
                    if (variable_instance_exists(_row, "enabled") && !_row.enabled) continue;
                    if (variable_instance_exists(_row, "canEdit") && !_row.canEdit) continue;
                    if (instance_exists(oOptionsDisplay) && oOptionsDisplay.active) {
                        if (_row.optionid < 0 || _row.optionid > oOptionsDisplay.menuSize) continue;
                        if (!oOptionsDisplay.canEdit[_row.optionid]) continue;
                    }
                    if (_world_x >= _row.x - 4 && abs(_world_y - _row.y - 2) <= 8) _chosen = _row;
                }
            }
            // Select the tapped row, then feed its confirm or left/right action into the existing menu controls.
            if (_chosen != noone) {
                global.curropt = _chosen.optionid;
                if (_chosen.object_index == oPauseOption) ctrl_Menu1 = 1;
                else if (_world_x < _chosen.x + _chosen.textoffset) ctrl_Left = 1;
                else ctrl_Right = 1;
            }
        }
        exit;
    }
    if (!global.ingame) {
        if (room != rm_transition) dual_pending_action = 0;
        exit;
    }
    dual_map_gesture(_input);
    dual_map_toolbar_input(_input, false);
    // Match the original pause gate: a cutscene tap must not queue a later menu action.
    if (!global.enablecontrol || room == rm_transition) {
        dual_pending_action = 0;
        exit;
    }
}

function dual_map_gesture(_input) {
    // Dragging from inside the map turns off following and moves its center in map-cell units.
    if (_input.originY >= dual_map_top && _input.originY < dual_map_bottom && (_input.dx != 0 || _input.dy != 0)) {
        dual_follow = false;
        dual_overview = false;
        dual_center_x -= _input.dx / (8 * dual_zoom);
        dual_center_y -= _input.dy / (8 * dual_zoom);
    }
    if (_input.zoom != 0) {
        dual_overview = false;
        if (current_time >= dual_gesture_until) dual_gesture_zoom = dual_zoom;
        dual_gesture_zoom = clamp(dual_gesture_zoom * power(2, _input.zoom), min(1, dual_map_fit_zoom()), 4);
        dual_gesture_until = current_time + 200;
        // Accumulate small pinch movements before rounding, so they never get lost.
        dual_zoom = dual_gesture_zoom < 1
            ? max(min(1, dual_map_fit_zoom()), round(dual_gesture_zoom * 32) / 32) : dual_gesture_zoom;
        dual_manual_zoom = dual_zoom;
    }
}
