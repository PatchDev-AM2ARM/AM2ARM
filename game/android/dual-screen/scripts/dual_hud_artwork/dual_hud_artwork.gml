// Lower-HUD geometry and drawing into the native-pixel artwork strips.
// Runs in oControl scope; drawing helpers use the caller-selected target surface.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

// All lower HUD artwork is composed once on the reference's native pixel grid.
// The second screen scales these two small strips directly to whole physical pixels.
function dual_art_header_rows() {
    return oControl.dual_hud_top ? 16 : oControl.dual_art_header_height;
}

function dual_art_map_controls_top() {
    return oControl.dual_height - 15 * oControl.dual_art_scale;
}

function dual_art_page_controls_top() {
    return dual_art_map_controls_top();
}

function dual_art_geometry() {
    // Keep each artwork pixel square. Only empty layout space
    // expands on wider screens; the map keeps its own scale.
    dual_art_pixels = max(1, floor(dual_width * dual_scale / 177));
    var _scale = dual_art_pixels / dual_scale;
    var _tanks = variable_global_exists("etanks") ? clamp(global.etanks, 0, 30) : 0;
    if (_scale == dual_art_scale && dual_width == dual_art_geometry_width
        && dual_height == dual_art_geometry_height && _tanks == dual_art_geometry_tanks
        && dual_hud_top == dual_art_geometry_hud_top) return;
    dual_nano_clock_only = false;
    dual_art_geometry_width = dual_width;
    dual_art_geometry_height = dual_height;
    dual_art_geometry_tanks = _tanks;
    dual_art_geometry_hud_top = dual_hud_top;
    var _font = draw_get_font();
    var _width = max(177, floor(dual_width / _scale + 0.001));
    dual_art_health_height = max(16, ceil(_tanks / 10) * 10 + 6);
    dual_art_title_full = false;
    dual_art_title_rows = 0;
    var _header = dual_art_health_height + 18;
    if (_scale != dual_art_scale || _width != dual_art_width || _header != dual_art_header_height) {
        if (_width != dual_art_width) dual_art_reset_images();
        dual_art_scale = _scale;
        dual_art_width = _width;
        dual_art_header_height = _header;
        dual_apply_hud_layout();
    }
    draw_set_font(_font);
}

function dual_art_rect(_x, _y, _w, _h, _color) {
    draw_set_color(_color);
    draw_rectangle(_x, _y, _x + _w - 1, _y + _h - 1, false);
}

// The Standard HUD's original ammo digits already contain their one-pixel shadow.
function dual_art_digits(_value, _x, _y, _places = 0) {
    var _text = string(_value);
    _x += max(0, _places - string_length(_text)) * 7;
    for (var _i = 1; _i <= string_length(_text); ++_i)
        draw_sprite(sGUIFont2, real(string_char_at(_text, _i)), _x + (_i - 1) * 7, _y);
}

function dual_art_text(_text, _x, _y) {
    // Fixed HUD punctuation keeps the original five-row font in every language.
    var _font = variable_global_exists("port_original_fonts") ? global.port_original_fonts[1] : fontGUI2;
    draw_set_font(_font); draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_set_color(c_black); draw_text(_x + 1, _y - 4, _text);
    draw_set_color(c_white); draw_text(_x, _y - 5, _text);
}

// Counts stay on the map screen when health and ammunition move above.
function dual_art_metroids(_y, _separate = true) {
    var _extra = dual_art_width - 177;
    if (_separate) {
        draw_sprite_part(sDualHudHeader, 0, 98, 0, 79, 16, 98 + _extra, _y);
    } else {
        // Keep both counters together on 4:3 panels, omitting the health
        // divider while retaining the separator beside the local arrow.
        draw_sprite_part(sDualHudHeader, 0, 99, 0, 35, 16, 99 + _extra, _y);
        draw_sprite_part(sDualHudHeader, 0, 134, 0, 43, 16, 134 + _extra, _y);
    }
    dual_art_digits(to_string_lz(global.monstersleft), 118 + _extra, 5 + _y);
    dual_art_digits(to_string_lz(global.monstersarea), 160 + _extra, 5 + _y);
}

function dual_art_title_header() {
    var _width = dual_art_width - 81;
    dual_art_rect(0, 0, dual_art_width, 16, make_color_rgb(8, 58, 8));
    dual_art_rect(0, 0, 1, 16, make_color_rgb(5, 31, 5));
    dual_art_metroids(0);
    dual_art_title(2, 0, _width, 16, _width);
}

function dual_art_header() {
    var _extra = dual_art_width - 177;
    var _health_height = dual_art_health_height;
    var _dy = floor((_health_height - 16) / 2), _ammo_y = _health_height + 1;
    var _green = make_color_rgb(8, 58, 8), _dark = make_color_rgb(5, 31, 5);
    dual_art_rect(0, 0, dual_art_width, _health_height, _green);
    draw_sprite_part(sDualHudHeader, 0, 0, 0, 98, 16, 0, _dy);
    // Allow the one-pixel canvas rounding used by the AYANEO lower panel.
    var _open_health_row = dual_width * 3 >= dual_height * 4 - 2;
    dual_art_metroids(_dy, !_open_health_row);
    for (var _i = 0; _i < 3; ++_i) {
        if (_open_health_row && _i == 1) continue;
        var _x = [0, 98 + _extra, dual_art_width - 1][_i];
        dual_art_rect(_x, 0, 1, _health_height, _dark);
    }
    var _health = gui_health();
    for (var _i = 1; _i <= string_length(_health); ++_i) {
        var _digit = real(string_char_at(_health, _i));
        draw_sprite(sGUIFont1, _digit, 3 + (_i - 1) * 13, 2 + _dy);
        if (hpalarm > 0 && hudflash > 0)
            draw_sprite_ext(sGUIFont1A, _digit, 3 + (_i - 1) * 13, 2 + _dy,
                1, 1, 0, c_white, clamp(hudflashfx / 4, 0, 1));
    }
    for (var _i = 0; _i < clamp(global.etanks, 0, 30); ++_i) {
        var _full = global.playerhealth > 99.9 + _i * 100 * mod_etankhealthmult;
        draw_sprite_part(sDualHudIcons, 0, _full ? 4 : 21, 49, 6, 10,
            33 + (_i mod 10) * 6, 3 + floor(_i / 10) * 10);
    }
    dual_art_rect(0, _ammo_y, dual_art_width, 16, _green);
    dual_art_rect(dual_art_width - 1, _ammo_y, 1, 16, _dark);
    dual_update_weapon_state();
    var _frames = [dual_missile_frame, dual_super_frame, dual_bomb_frame];
    var _counts = [global.missiles, global.smissiles, global.pbombs];
    var _maximums = [global.maxmissiles, global.maxsmissiles, global.maxpbombs];
    var _ix = [1, 41, 74], _nx = [18, 58, 87], _places = [3, 2, 2];
    var _overflow = max(0, string_length(string(_counts[0])) - 3) * 7;
    var _overflow2 = max(0, string_length(string(_counts[1])) - 2) * 7;
    var _overflow3 = max(0, string_length(string(_counts[2])) - 2) * 7;
    // Modifiers can increase capacity. Grow those fields, keeping their font
    // intact; the title then has the remaining space rather than overlapping.
    if (_overflow + _overflow2 + _overflow3 > 0) {
        dual_art_rect(0, _ammo_y, dual_art_width, 16, _green);
        _ix[1] += _overflow; _nx[1] += _overflow;
        _ix[2] += _overflow + _overflow2; _nx[2] += _overflow + _overflow2;
    }
    for (var _a = 0; _a < 3; ++_a) {
        // Capacity records ownership; zero remaining ammo still displays an owned weapon.
        if (_maximums[_a] <= 0) continue;
        // Borders belong to acquired weapons too, including their shared edges.
        // Keep the original one-pixel strips without empty placeholders.
        // Integer scaling leaves extra columns on wider grids. Distribute
        // them across the ammo cells, keeping the title under the counters.
        // Center each original icon/digit group without resampling its pixels.
        var _edges = [0, 40, 73, 102];
        var _left_extra = floor(_extra * _edges[_a] / 102);
        var _right_extra = floor(_extra * _edges[_a + 1] / 102);
        var _shift = _left_extra + floor((_right_extra - _left_extra) / 2);
        dual_art_rect(_ix[_a] - 1 + _left_extra, _ammo_y, 1, 16, _dark);
        dual_art_rect(_nx[_a] + _places[_a] * 7 + 1 + _right_extra, _ammo_y, 1, 16, _dark);
        dual_art_rect(_nx[_a] - 3 + _shift, _ammo_y + 3, 1, 10, _dark);
        var _cut = _a == 2 ? 2 : 0, _width = _a == 2 ? 12 : 16;
        // The supplied sheet uses grey / green / yellow. Hold separates
        // selection from engagement; Toggle highlights its selected weapon.
        var _state = 0;
        if (_maximums[_a] > 0)
            _state = global.opmslstyle == 0 ? clamp(_frames[_a], 0, 2) : (_frames[_a] > 0 ? 2 : 1);
        draw_sprite_part(sDualHudIcons, 0, _state * 16 + _cut, _a * 16, _width, 12, _ix[_a] + _shift, _ammo_y + 2);
        dual_art_digits(_counts[_a], _nx[_a] + _shift, _ammo_y + 5, _places[_a]);
    }
    var _split = 102 + _extra + _overflow + _overflow2 + _overflow3;
    dual_art_rect(_split, _ammo_y, 1, 16, _dark);
    dual_art_title(_split + 1, _ammo_y, dual_art_width - _split - 2);
    draw_set_color(c_white);
}

function dual_art_counter(_text, _x, _y) {
    for (var _i = 1; _i <= string_length(_text); ++_i) {
        var _char = string_char_at(_text, _i);
        if (_char == "1") {
            draw_sprite_part(sGUIFont2, 1, 1, 0, 4, 6, _x, _y);
            _x += 4;
        } else if (string_pos(_char, "023456789") > 0) {
            draw_sprite(sGUIFont2, real(_char), _x, _y);
            _x += 7;
        } else {
            dual_art_text(_char, _x, _y);
            _x += string_width(_char);
        }
    }
}

function dual_art_stats(_y) {
    var _extra = dual_art_width - 177, _split = 106 + floor(_extra * 0.6);
    var _clock_shift = floor((_split - 106) / 2);
    var _percent_shift = _split - 106 + floor((dual_art_width - _split - 71) / 2);
    dual_art_rect(0, _y + 1, dual_art_width, 14, make_color_rgb(8, 58, 8));
    for (var _i = 0; _i < 3; ++_i) {
        var _x = [0, _split, dual_art_width - 1][_i];
        dual_art_rect(_x, _y + 1, 1, 14, make_color_rgb(5, 31, 5));
    }
    draw_sprite_part(sDualHudFooter, 0, 21, 3, 14, 10, 21 + _clock_shift, _y + 3);
    draw_sprite_part(sDualHudFooter, 0, 120, 3, 14, 10, 120 + _percent_shift, _y + 3);
    dual_art_counter(steps_to_time2(global.gametime), 38 + _clock_shift, _y + 5);
    var _count = mod_percentofitems == 1 ? round(global.itemstaken / 88 * 100) : global.itemstaken;
    dual_art_counter(string(_count) + (mod_percentofitems == 1 ? "%" : ""), 138 + _percent_shift, _y + 5);
}

function dual_art_button_hints(_paused) {
    // Reuse the current bindings and controller artwork, including hot-plug changes.
    if (!_paused) return dual_art_no_hints;
    return [get_button_sprite("Menu1"), get_button_sprite("Menu2"), get_button_sprite("Start")];
}

function dual_art_native_buttons(_paused, _map_page, _y) {
    var _labels = ["+", "-", "1x", "FIT MAP", "FOLLOW"];
    var _hints = dual_art_button_hints(_paused);
    var _selected = [false, false, false, dual_overview, dual_follow];
    var _starts = [0, 18, 36, 69, 127 + floor((dual_art_width - 177) / 2)];
    var _ends = [17, 35, 68, _starts[4] - 1, dual_art_width];
    if (_paused) {
        _labels = ["SELECT", "MENU", "RESUME"];
        if (_map_page) {
            var _editing = instance_exists(oMapCursor) && oMapCursor.state == 1;
            _labels = [_editing ? "DONE" : (global.mapmarker ? "EDIT" : "MARKER"), _editing ? "DELETE" : "MENU", "UNPAUSE"];
        }

        _starts = [0, floor(dual_art_width / 3), floor(dual_art_width * 2 / 3)];
        _ends = [_starts[1] - 1, _starts[2] - 1, dual_art_width];
    }
    for (var _i = 0; _i < array_length(_labels); ++_i) {
        // The four-way selector only exposes Resume, as before.
        if (_paused && instance_exists(oSubScrChange) && _i < 2) continue;
        var _left = _starts[_i], _width = _ends[_i] - _left;
        var _active = !_paused && _selected[_i];
        var _border = _active ? make_color_rgb(100, 240, 80) : make_color_rgb(8, 58, 8);
        dual_art_rect(_left, _y, _width, 15, _border);
        dual_art_rect(_left + 1, _y + 1, _width - 2, 13, _active ? make_color_rgb(8, 48, 0) : c_black);
        var _hint = _paused ? _hints[_i] : -1;
        var _label_y = _y + 5;
        if (_hint >= 0) {
            // Keep the original glyph pixels in unused atlas rows. Present them
            // at half the HUD's output scale, without moving the action label.
            // Each 32x8 slot is right-aligned, including wider L3/R3 bindings.
            draw_sprite(_hint, 0, _i * 32 + 32 - sprite_get_width(_hint), 56);
            // Explicit assignment preserves every hint bit in the native compiler.
            dual_art_hint_mask = dual_art_hint_mask | (1 << _i);
        }
        var _part = [], _sheet = sDualHudFooter;
        switch (_labels[_i]) {
            case "+": _part = [6, 21, 5, 5]; break;
            case "-": _part = [24, 23, 5, 1]; break;
            case "1x": _part = [47, 21, 10, 5]; break;
            case "FIT MAP": _part = [73, 21, 49, 5]; break;
            case "FOLLOW": _part = [131, 21, 42, 5]; break;
            case "SELECT": _sheet = sDualHudMenuFooter; _part = [8, 20, 41, 5]; break;
            case "MENU": _sheet = sDualHudMenuFooter; _part = [75, 20, 28, 5]; break;
            case "RESUME": _sheet = sDualHudMenuFooter; _part = [127, 20, 42, 5]; break;
        }
        var _caption = port_caption(_labels[_i]);
        // The symbols remain artwork; translated actions use full Unicode glyphs.
        if (_caption != _labels[_i]) _part = [];
        if (array_length(_part) > 0) {
            draw_sprite_part(_sheet, 0, _part[0], _part[1], _part[2], _part[3],
                _left + floor((_width - _part[2]) / 2), _y + floor((15 - _part[3]) / 2));
        } else {
            var _caption_font = port_hud_font(_caption);
            draw_set_font(_caption_font);
            if (_caption_font == fontLocaleCompact) {
                var _tx = _left + floor((_width - string_width(_caption)) / 2);
                draw_set_halign(fa_left); draw_set_valign(fa_top);
                draw_set_color(c_black); draw_text(_tx + 1, _y + 1, _caption);
                draw_set_color(c_white); draw_text(_tx, _y, _caption);
            } else dual_art_text(_caption, _left + floor((_width - string_width(_caption)) / 2), _label_y);
        }
    }
}
