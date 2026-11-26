// Status digits, weapon-state updates and fallback toolbar drawing.
// Called by the display and pause paths. Existing function names remain stable.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function dual_toolbar_button(_bounds, _label, _selected, _top = -1, _bottom = -1, _hint = -1) {
    dual_button(_bounds[0], _bounds[1], _label, _selected, _top, _bottom, _hint);
}

function dual_button(_left, _right, _label, _selected, _top = -1, _bottom = -1, _hint = -1) {
    if (dual_art_footer_rows > 0) return;
    if (_top < 0) _top = dual_art_map_controls_top();
    if (_bottom < 0) _bottom = dual_height - 1;
    draw_set_color(_selected ? make_color_rgb(8, 48, 0) : c_black);
    draw_rectangle(_left, _top, _right, _bottom, false);
    draw_set_color(_selected ? make_color_rgb(100, 240, 80) : make_color_rgb(24, 72, 12));
    draw_rectangle(_left, _top, _right, _bottom, true);
    draw_set_halign(fa_center);
    var _valign = draw_get_valign();
    draw_set_valign(fa_middle);
    draw_set_color(c_white);
    // A corner hint must not move the label when pause or prompt style changes.
    draw_text(floor((_left + _right) / 2), floor((_top + _bottom) / 2), port_caption(_label));
    draw_set_valign(_valign);
    if (_hint >= 0) draw_sprite(_hint, 0, _right - sprite_get_width(_hint) - 2, _top + 2);
    draw_set_halign(fa_left);
}

function dual_hud_yellow_sheet() {
    // Cache the original blue tanks and recolored weapon selections.
    if (surface_exists(oControl.dual_hud_sheet)) return oControl.dual_hud_sheet;
    var _source = [make_color_rgb(110, 221, 253), make_color_rgb(16, 184, 219),
        make_color_rgb(36, 127, 187), make_color_rgb(124, 224, 101),
        make_color_rgb(45, 208, 0), make_color_rgb(0, 145, 0), make_color_rgb(0, 79, 0),
        make_color_rgb(0, 98, 0)];
    var _yellow = make_color_rgb(242, 206, 69);
    var _target = [_yellow, make_color_rgb(217, 184, 55), make_color_rgb(163, 130, 32),
        make_color_rgb(255, 233, 145), _yellow, make_color_rgb(169, 144, 48),
        make_color_rgb(92, 78, 26), make_color_rgb(115, 98, 34)];
    var _armed = [c_white, c_white, c_white, c_white, c_white,
        make_color_rgb(169, 169, 169), make_color_rgb(92, 92, 92), make_color_rgb(115, 115, 115)];
    var _world = matrix_get(matrix_world), _view = matrix_get(matrix_view);
    var _projection = matrix_get(matrix_projection), _filter = gpu_get_texfilter();
    var _color = draw_get_color(), _alpha = draw_get_alpha(), _blend = gpu_get_blendmode();
    matrix_set(matrix_world, matrix_build_identity());
    gpu_set_texfilter(false);
    gpu_set_blendmode(bm_normal);
    draw_set_alpha(1);
    oControl.dual_hud_sheet = surface_create(320, 34);
    surface_set_target(oControl.dual_hud_sheet);
    draw_clear_alpha(c_black, 0);
    draw_sprite_ext(bg_SubScrTop, 0, 0, 0, 1, 1, 0, c_white, 1);
    // Reuse the Standard selection artwork and its scanlines inside the green dividers.
    draw_sprite_part(sGUIMissile, 1, 1, 1, 14, 10, 111, 2);
    draw_sprite_part(sGUISMissile, 1, 1, 1, 14, 10, 193, 2);
    draw_sprite_part(sGUIPBomb, 1, 1, 1, 14, 10, 257, 2);
    draw_sprite_ext(sGUIETank, 1, 0, 14, 1, 1, 0, c_white, 1);
    // Keep a white copy for the original hold-to-arm state.
    draw_sprite_ext(bg_SubScrTop, 0, 0, 20, 1, 1, 0, c_white, 1);
    draw_sprite_part(sGUIMissile, 1, 1, 1, 14, 10, 111, 22);
    draw_sprite_part(sGUISMissile, 1, 1, 1, 14, 10, 193, 22);
    draw_sprite_part(sGUIPBomb, 1, 1, 1, 14, 10, 257, 22);
    surface_reset_target();
    // A one-time pixel replacement avoids surface-palette sampling differences on mobile GPUs.
    var _pixels = buffer_create(320 * 34 * 4, buffer_fixed, 1);
    buffer_get_surface(_pixels, oControl.dual_hud_sheet, 0);
    var _regions = [[111, 2, 14, 10], [193, 2, 14, 10], [257, 2, 14, 10], [0, 14, 6, 6],
        [111, 22, 14, 10], [193, 22, 14, 10], [257, 22, 14, 10]];
    for (var _r = 0; _r < array_length(_regions); ++_r) {
        if (_r == 3) continue; // Keep the energy tank in its original blue palette.
        var _region = _regions[_r];
        for (var _y = _region[1]; _y < _region[1] + _region[3]; ++_y) {
            for (var _x = _region[0]; _x < _region[0] + _region[2]; ++_x) {
                var _offset = (_y * 320 + _x) * 4;
                // Leave the dividers green and clip one pixel from each selected box corner.
                if (_r != 3 && (_x == _region[0] || _x == _region[0] + _region[2] - 1)
                    && (_y == _region[1] || _y == _region[1] + _region[3] - 1)) {
                    buffer_poke(_pixels, _offset, buffer_u32, $ff000000 | make_color_rgb(8, 58, 8));
                    continue;
                }
                var _pixel = buffer_peek(_pixels, _offset, buffer_u32);
                if ((_pixel & $ff000000) == 0) continue;
                for (var _c = 0; _c < array_length(_source); ++_c) {
                    if ((_pixel & $ffffff) != _source[_c]) continue;
                    // Blend the darker selection shades into the bar; keep the bright symbol opaque.
                    var _pixel_color = _r > 3 ? _armed[_c] : _target[_c];
                    if (_r != 3 && (_c == 6 || _c == 7)) {
                        _pixel_color = merge_color(make_color_rgb(8, 58, 8), _pixel_color, 0.65);
                    }
                    buffer_poke(_pixels, _offset, buffer_u32, (_pixel & $ff000000) | _pixel_color);
                    break;
                }
            }
        }
    }
    buffer_set_surface(_pixels, oControl.dual_hud_sheet, 0);
    buffer_delete(_pixels);
    gpu_set_texfilter(_filter);
    gpu_set_blendmode(_blend);
    matrix_set(matrix_world, _world); matrix_set(matrix_view, _view);
    matrix_set(matrix_projection, _projection);
    draw_set_color(_color); draw_set_alpha(_alpha);
    return oControl.dual_hud_sheet;
}

// The equipment page has its own compact status row, independent of the map HUD.
function dual_draw_equipment_status(_x, _y, _width) {
    if (oControl.dual_hud_top) return;
    var _font = draw_get_font(), _color = draw_get_color();
    var _ha = draw_get_halign(), _va = draw_get_valign();
    draw_set_font(fontGUI2);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(make_color_rgb(8, 58, 8));
    draw_rectangle(_x, _y + 3, _x + _width - 1, _y + 16, false);
    // Keep the original dividers and center the six-pixel E between them.
    draw_sprite_part(bg_SubScrTop, 0, 0, 0, 1, 14, _x + 4, _y + 3);
    draw_sprite_part(bg_SubScrTop, 0, 4, 0, 7, 14, _x + 9, _y + 3);
    draw_sprite_part(bg_SubScrTop, 0, 15, 0, 1, 14, _x + 19, _y + 3);
    dual_draw_health(_x + 4, _y);
    // Refresh weapon highlights in oControl even when an equipment-page object called this drawing helper.
    with (oControl) dual_update_weapon_state();
    var _counts = [global.missiles, global.smissiles, global.pbombs];
    var _maximums = [global.maxmissiles, global.maxsmissiles, global.maxpbombs];
    var _icons = [110, 192, 256];
    var _frames = [oControl.dual_missile_frame, oControl.dual_super_frame, oControl.dual_bomb_frame];
    var _right = _x + _width - 4;
    // Pack ammo at the right edge. Fixed digit cells prevent movement as ammo
    // changes (especially this font's narrow "1"). Unowned ammo has no field.
    var _digit = string_width("0"), _slash = string_width("/");
    for (var _a = 2; _a >= 0; --_a) {
        if (_maximums[_a] <= 0) continue;
        var _places = max(string_length(string(_counts[_a])), string_length(string(_maximums[_a])));
        var _value_x = _right - (2 * _places * _digit + _slash);
        var _icon_x = _value_x - 17;
        // Keep unselected weapons green; highlight the selected weapon in yellow.
        if (_frames[_a] > 0) {
            draw_surface_part_ext(dual_hud_yellow_sheet(), _icons[_a], _frames[_a] > 1 ? 20 : 0, 16, 14,
                _icon_x, _y + 3, 1, 1, c_white, draw_get_alpha());
        } else draw_sprite_part(bg_SubScrTop, 0, _icons[_a], 0, 16, 14, _icon_x, _y + 3);
        draw_set_color(c_white);
        for (var _side = 0; _side < 2; ++_side) {
            var _value = string(_side == 0 ? _counts[_a] : _maximums[_a]);
            var _end = _value_x + _places * _digit + _side * (_places * _digit + _slash);
            for (var _d = 1; _d <= string_length(_value); ++_d) {
                var _char = string_char_at(_value, _d);
                draw_text(floor(_end - (string_length(_value) - _d + 1) * _digit
                    + (_digit - string_width(_char)) / 2), _y + 2, _char);
            }
        }
        draw_text(_value_x + _places * _digit, _y + 2, "/");
        _right = _value_x - 23;
    }
    draw_set_font(_font); draw_set_color(_color);
    draw_set_halign(_ha); draw_set_valign(_va);
}

function dual_draw_health(_x, _y, _scale = 1) {
    var _font = draw_get_font(), _color = draw_get_color();
    var _ha = draw_get_halign(), _va = draw_get_valign();
    draw_set_font(fontGUI2);
    draw_set_halign(fa_left);
    draw_set_valign(fa_top);

    var _digits = gui_health();
    draw_set_color(c_black);
    draw_text_transformed(_x + 19 * _scale, _y + 3 * _scale, _digits, _scale, _scale, 0);
    // Pulse red with the existing low-energy alarm; its thresholds and timing stay unchanged.
    var _warning = oControl.hpalarm > 0 && oControl.hudflash > 0;
    draw_set_color(_warning ? merge_color(c_white, c_red, oControl.hudflashfx / 4) : c_white);
    draw_text_transformed(_x + 18 * _scale, _y + 2 * _scale, _digits, _scale, _scale, 0);
    var _tanks = clamp(floor(global.etanks), 0, 30);
    // Native two-row tank order. Additional modifier tanks fit inside the same health field.
    var _pitch = min(6, floor(60 / max(1, ceil(_tanks / 2))));
    for (var _tank = 0; _tank < _tanks; ++_tank) {
        var _full = global.playerhealth > 99.9 + _tank * 100 * oControl.mod_etankhealthmult;
        if (_full) {
            draw_surface_part_ext(dual_hud_yellow_sheet(), 0, 14, 6, 6,
                _x + (36 + floor(_tank / 2) * _pitch) * _scale, _y + (4 + (_tank mod 2) * 6) * _scale,
                _pitch / 6 * _scale, _pitch / 6 * _scale, c_white, draw_get_alpha());
        } else draw_sprite_ext(sGUIETank, 0, _x + (36 + floor(_tank / 2) * _pitch) * _scale,
            _y + (4 + (_tank mod 2) * 6) * _scale, _pitch / 6 * _scale, _pitch / 6 * _scale, 0, c_white, draw_get_alpha());
    }
    draw_set_font(_font);
    draw_set_color(_color);
    draw_set_halign(_ha);
    draw_set_valign(_va);
}

function dual_update_weapon_state() {
    // Match the original HUD's selection/arming rules in hold and toggle modes.
    if (instance_exists(oCharacter)) {
        var _ball = oCharacter.state == 23 || oCharacter.state == 24 || oCharacter.state == 27
            || oCharacter.state == 54 || oCharacter.state == 55 || oCharacter.sjball;
        var _missile = global.currentweapon == 1;
        var _super = global.currentweapon == 2;
        var _bomb = global.currentweapon == 3;
        var _frame = 1;
        if (global.opmslstyle == 0) {
            _missile = _missile && !_ball;
            _super = _super && !_ball;
            _bomb = _ball;
            _frame += oCharacter.armmsl;
        }
        dual_missile_frame = _missile ? _frame : 0;
        dual_super_frame = _super ? _frame : 0;
        dual_bomb_frame = _bomb ? _frame : 0;
    }
}
