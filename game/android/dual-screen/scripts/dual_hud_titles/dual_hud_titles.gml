// Localized HUD title state, fitting and title-layer drawing.
// Runs in oControl scope. Text fitting uses actual glyph ink and whole physical pixels.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function dual_art_title_state() {
    var _inputs = dual_art_title_inputs;
    var _language = global.currentlanguage, _file = global.language[_language];
    if (array_length(_inputs) != 10 || _inputs[0] != dual_backdrop
        || _inputs[1] != dual_lab_entrance || _inputs[2] != dual_research_site
        || _inputs[3] != dual_waterfalls || _inputs[4] != dual_backdrop_previous
        || _inputs[5] != dual_previous_lab_entrance || _inputs[6] != dual_previous_research_site
        || _inputs[7] != dual_previous_waterfalls || _inputs[8] != _language || _inputs[9] != _file) {
        _inputs[0] = dual_backdrop; _inputs[1] = dual_lab_entrance;
        _inputs[2] = dual_research_site; _inputs[3] = dual_waterfalls;
        _inputs[4] = dual_backdrop_previous; _inputs[5] = dual_previous_lab_entrance;
        _inputs[6] = dual_previous_research_site; _inputs[7] = dual_previous_waterfalls;
        _inputs[8] = _language; _inputs[9] = _file;
        dual_art_title_current = dual_area_title(dual_backdrop, dual_lab_entrance,
            dual_research_site, dual_waterfalls);
        dual_art_title_previous = dual_area_title(dual_backdrop_previous, dual_previous_lab_entrance,
            dual_previous_research_site, dual_previous_waterfalls);
        // Translation lookup may reset its cache; retain our inputs afterward.
        dual_art_title_inputs = _inputs;
    }
    var _title = dual_art_title_current;
    var _fade = dual_backdrop_blend(), _alpha = 1;
    if (_fade < 1) {
        var _previous = dual_art_title_previous;
        if (_previous != _title) {
            if (_fade < 0.5) { _title = _previous; _alpha = 1 - 2 * _fade; }
            else _alpha = 2 * _fade - 1;
        }
    }
    dual_art_title_state_cache.text = _title;
    dual_art_title_state_cache.alpha = _alpha;
    return dual_art_title_state_cache;
}

function dual_art_lines(_text, _width) {
    draw_set_font(port_hud_font(_text));
    var _words = string_split(_text, " "), _lines = [], _line = "";
    for (var _i = 0; _i < array_length(_words); ++_i) {
        var _next = _line == "" ? _words[_i] : _line + " " + _words[_i];
        if (_line != "" && string_width(_next) > _width) {
            array_push(_lines, _line); _line = _words[_i];
        } else _line = _next;
    }
    if (_line != "") array_push(_lines, _line);
    return _lines;
}

// Measure translated titles from actual ink, including original-font accents.
// Use the existing title layer and whole physical pixels at presentation.
function dual_art_locale_title(_x, _y, _width, _height, _original = false) {
    var _title = dual_art_title_state();
    draw_set_font(_original ? port_hud_font(_title.text) : fontLocaleCompact);
    var _base = max(1, dual_art_pixels), _scale = _base, _lines = [];
    var _line_ink = [], _text_height = 0;
    var _title_ink = port_text_ink(_title.text, _original), _split_words = _title_ink[2];
    while (true) {
        var _available = min(dual_art_width - 2, floor(_width * _base / _scale) - 1);
        _lines = port_wrap_text(_title.text, _available, _split_words);
        _text_height = max(0, array_length(_lines) - 1) * 2;
        _line_ink = [];
        for (var _i = 0; _i < array_length(_lines); ++_i) {
            var _ink = port_text_ink(_lines[_i], _original);
            array_push(_line_ink, _ink);
            _text_height += _ink[1] - _ink[0];
        }
        // A third short line can be clearer than shrinking every glyph. The
        // atlas has 32 rows; both that limit and the visible box must fit.
        var _fits = _text_height + 1 <= 32 && (_text_height + 1) * _scale <= _height * _base;
        for (var _i = 0; _i < array_length(_lines); ++_i)
            if (string_width(_lines[_i]) > _available) _fits = false;
        if (_fits) break;
        // Preserve words where a small scale change suffices. At the readable
        // two-pixel floor, balance oversized words instead of stranding letters.
        if (_scale <= 2 && !_split_words) { _split_words = true; continue; }
        if (_scale == 1) break;
        _scale--;
    }
    dual_art_title_layout = [_x + _width / 2, _y + _height / 2, _scale];
    var _top = 64 + floor((32 - _text_height) / 2);
    draw_set_halign(fa_left); draw_set_valign(fa_top); draw_set_alpha(_title.alpha);
    for (var _i = 0; _i < array_length(_lines); ++_i) {
        var _left = floor((dual_art_width - string_width(_lines[_i])) / 2);
        var _ink = _line_ink[_i], _origin = _top - _ink[0];
        draw_set_color(c_black); draw_text(_left + 1, _origin + 1, _lines[_i]);
        draw_set_color(c_white); draw_text(_left, _origin, _lines[_i]);
        _top += _ink[1] - _ink[0] + 2;
    }
    draw_set_alpha(1);
}

function dual_art_title(_x, _y, _width, _height = 16, _word_width = 56) {
    var _caption_font = port_hud_font(dual_art_title_state().text);
    if (_caption_font == fontLocaleCompact || port_locale_layout_active()) {
        dual_art_locale_title(_x, _y, _width, _height, _caption_font != fontLocaleCompact);
        return;
    }
    // Prefer the same two-line caption on every display. A wider panel must
    // not join those words and then shrink them merely for exceeding 56 pixels.
    var _title = dual_art_title_state();
    var _lines = dual_art_lines(_title.text, min(_word_width, _width));
    if (array_length(_lines) > 2) _lines = dual_art_lines(_title.text, _width);
    var _long = array_length(_lines) > 2;
    for (var _i = 0; _i < array_length(_lines); ++_i)
        if (string_width(_lines[_i]) > _width) _long = true;
    if (_long) {
        // Retain every pixel of the same font. The GPU gives long captions a
        // smaller integer output scale, independent of the health/ammo grid.
        var _base = max(1, dual_art_pixels);
        var _scale = max(1, _base - 1);
        while (true) {
            var _available = floor(_width * _base / _scale);
            _lines = dual_art_lines(_title.text, _available);
            var _fits = (6 + (array_length(_lines) - 1) * 8) * _scale <= _height * _base;
            for (var _i = 0; _i < array_length(_lines); ++_i)
                if (string_width(_lines[_i]) > _available) _fits = false;
            if (_fits || _scale == 1) break;
            _scale--;
        }
        dual_art_title_layout = [_x + _width / 2, _y + _height / 2, _scale];
        // Rows 64..95 are unused by the visible header and footer strips.
        _x = 0; _y = 64; _width = dual_art_width; _height = 32;
    }
    draw_set_alpha(_title.alpha);
    var _top = _y + floor((_height - (5 + (array_length(_lines) - 1) * 8)) / 2);
    for (var _i = 0; _i < array_length(_lines); ++_i) {
        var _text = _lines[_i];
        dual_art_text(_text, _x + floor((_width - string_width(_text)) / 2), _top + _i * 8);
    }
    draw_set_alpha(1);
}

function dual_art_draw_title_layer(_surface, _layout, _brightness = 1) {
    if (_layout[2] <= 0) return;
    var _scale = dual_art_scale * _layout[2] / max(1, dual_art_pixels);
    var _left = (dual_width - dual_art_width * dual_art_scale) / 2;
    draw_surface_part_ext(_surface, 0, 64, dual_art_width, 32,
        _left + _layout[0] * dual_art_scale - dual_art_width * _scale / 2,
        _layout[1] * dual_art_scale - 16 * _scale,
        _scale, _scale, merge_color(c_black, c_white, _brightness), 1);
}
