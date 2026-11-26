// Port captions are loaded when the language changes, never from the Draw loop.
// English literals are stable identifiers for native dialogs and HUD actions.
function port_locale_refresh() {
    if (!variable_global_exists("language") || !variable_global_exists("currentlanguage")) return;
    if (!variable_global_exists("port_caption_keys")) {
        global.port_caption_keys = {};
        var _path = working_directory + "lang/port-ui.json";
        if (file_exists(_path)) {
            var _buffer = buffer_load(_path);
            var _keys = json_parse(buffer_read(_buffer, buffer_string));
            buffer_delete(_buffer);
            if (is_struct(_keys)) global.port_caption_keys = _keys;
        }
    }
    if (!variable_global_exists("port_ink_bounds")) {
        global.port_ink_bounds = {}; global.port_original_ink_bounds = {}; global.port_ink_cache = {};
        var _ink_path = working_directory + "lang/fonts/locale-ink.json";
        if (file_exists(_ink_path)) {
            var _buffer = buffer_load(_ink_path);
            global.port_ink_bounds = json_parse(buffer_read(_buffer, buffer_string));
            buffer_delete(_buffer);
        }
        _ink_path = working_directory + "lang/fonts/hud-original-ink.json";
        if (file_exists(_ink_path)) {
            var _buffer = buffer_load(_ink_path);
            global.port_original_ink_bounds = json_parse(buffer_read(_buffer, buffer_string));
            buffer_delete(_buffer);
        }
    }
    var _captions = {}, _keys = global.port_caption_keys;
    var _names = variable_struct_get_names(_keys);
    ini_open(global.language[global.currentlanguage]);
    for (var _i = 0; _i < array_length(_names); ++_i) {
        var _english = _names[_i];
        var _text = ini_read_string("PortUI", variable_struct_get(_keys, _english), _english);
        variable_struct_set(_captions, _english, _text);
    }
    ini_close();
    var _own = port_text(global.language[global.currentlanguage], "PortUI");
    _names = variable_struct_get_names(_own);
    for (var _i = 0; _i < array_length(_names); ++_i) {
        variable_struct_set(_captions, _names[_i], variable_struct_get(_own, _names[_i]));
    }
    global.port_captions = _captions;
    global.port_locale_generation = port_locale_revision() + 1;

    // Upstream's bundled TTFs already contain the translated glyphs. Preserve
    // those fonts (and user replacements) instead of changing the entire menu
    // style when a language is selected. Inspect HUD coverage once at startup.
    if (!variable_global_exists("port_original_fonts"))
        global.port_original_fonts = [fontGUI, fontGUI2, fontMenuSmall, fontMenuTiny, fontMenuSmall2, fontSubScr];
    if (!variable_global_exists("port_hud_glyphs"))
        global.port_hud_glyphs = font_get_info(fontGUI2).glyphs;

    if (variable_global_exists("am2r_sync"))
        global.am2r_sync.message = port_caption(global.am2r_sync.message_source);
    // Android's system picker remains in the system language. Our confirmation
    // dialogs use the language selected in the game, including after a change.
    if (global.android_app) SaveSync_SetText(json_stringify(_captions));
}

// The language files come from the restore pack. Text added since is in port-text.json.
function port_text(_file, _section) {
    static _none = {};
    static _text = undefined;
    if (is_undefined(_text)) {
        _text = {};
        var _path = working_directory + "lang/port-text.json";
        if (file_exists(_path)) {
            var _buffer = buffer_load(_path);
            var _loaded = json_parse(buffer_read(_buffer, buffer_string));
            buffer_delete(_buffer);
            if (is_struct(_loaded)) _text = _loaded;
        }
    }
    var _language = variable_struct_get(_text, filename_change_ext(filename_name(_file), ""));
    if (is_undefined(_language)) return _none;
    var _rows = variable_struct_get(_language, _section);
    return is_undefined(_rows) ? _none : _rows;
}

function port_caption(_english) {
    if (variable_global_exists("port_captions")
        && variable_struct_exists(global.port_captions, _english))
        return variable_struct_get(global.port_captions, _english);
    return _english;
}

function port_locale_revision() {
    return variable_global_exists("port_locale_generation") ? global.port_locale_generation : 0;
}

function port_locale_layout_active() {
    return variable_global_exists("currentlanguage") && global.currentlanguage != 0;
}

// Choose fallback only when the actual loaded font lacks a caption's glyphs.
// font_add file fonts load Unicode coverage beyond their legacy range arguments.
function port_hud_font(_text) {
    if (variable_global_exists("port_hud_glyphs"))
        for (var _i = 1; _i <= string_length(_text); ++_i)
            if (!variable_struct_exists(global.port_hud_glyphs, string_char_at(_text, _i)))
                return fontLocaleCompact;
    return variable_global_exists("port_original_fonts") ? global.port_original_fonts[1] : fontGUI2;
}

// Word wrapping also handles Japanese and long unspaced names. Preserve whole
// words where possible; split a word only when it cannot fit on its own line.
function port_wrap_text(_text, _width, _split_long = true) {
    var _lines = [], _paragraphs = string_split(string_hash_to_newline(_text), "\n");
    for (var _p = 0; _p < array_length(_paragraphs); ++_p) {
        var _words = string_split(_paragraphs[_p], " "), _line = "";
        for (var _w = 0; _w < array_length(_words); ++_w) {
            var _word = _words[_w], _next = _line == "" ? _word : _line + " " + _word;
            if (string_width(_next) <= _width) { _line = _next; continue; }
            if (_line != "") { array_push(_lines, _line); _line = ""; }
            if (!_split_long) { _line = _word; continue; }
            var _parts = max(1, ceil(string_width(_word) / max(1, _width)));
            var _max_chars = ceil(string_length(_word) / _parts);
            for (var _i = 1; _i <= string_length(_word); ++_i) {
                var _char = string_char_at(_word, _i);
                if (_line != "" && (string_length(_line) >= _max_chars || string_width(_line + _char) > _width)) {
                    array_push(_lines, _line); _line = "";
                }
                _line += _char;
            }
        }
        array_push(_lines, _line);
    }
    return _lines;
}

// Keep the original pixel font and 16px row grid. Only captions wider than
// their column wrap; ordinary English rows retain their original coordinates.
function port_draw_menu_text(_x, _y, _text, _width, _color = c_white) {
    draw_set_font(fontGUI2);
    var _lines = port_wrap_text(_text, _width);
    var _top = _y - 4 - (array_length(_lines) > 1 ? 4 : 0);
    for (var _line = 0; _line < array_length(_lines); ++_line) {
        draw_set_color(c_black);
        draw_text(_x + 1, _top + _line * 8 + 1, _lines[_line]);
        draw_set_color(_color);
        draw_text(_x, _top + _line * 8, _lines[_line]);
    }
}

// Keep the English help band and font in every language. An overlong tip
// scrolls inside that band at whole pixels, after a pause at either end. Cache
// its raster only when needed; changing selection or language resets the scroll.
function port_draw_help_text(_center, _top, _width, _height = 14, _font = fontMenuSmall2) {
    draw_set_font(_font);
    var _text = string_replace_all(string_hash_to_newline(global.tiptext), "\n", " ");
    var _advance = string_width(_text);
    if (_advance <= _width) {
        if (variable_global_exists("port_help_cache")) {
            if (!is_undefined(global.port_help_cache) && surface_exists(global.port_help_cache.surface)) surface_free(global.port_help_cache.surface);
            global.port_help_cache = undefined;
        }
        draw_set_halign(fa_center); draw_set_valign(fa_top);
        draw_set_color(c_black); draw_text(_center + 1, _top - 1, _text);
        draw_set_color(c_white); draw_text(_center, _top - 2, _text);
        draw_set_halign(fa_left);
        return;
    }
    var _revision = port_locale_revision();
    if (!variable_global_exists("port_help_cache") || is_undefined(global.port_help_cache)
        || global.port_help_cache.text != _text || global.port_help_cache.font != _font
        || global.port_help_cache.revision != _revision || global.port_help_cache.width != _width) {
        if (variable_global_exists("port_help_cache") && !is_undefined(global.port_help_cache)
            && surface_exists(global.port_help_cache.surface)) surface_free(global.port_help_cache.surface);
        global.port_help_cache = {text:_text, font:_font, revision:_revision, width:_width,
            surface:-1, started:current_time};
    }
    var _cache = global.port_help_cache;
    if (!surface_exists(_cache.surface)) {
        var _matrix = matrix_get(matrix_world), _alpha = draw_get_alpha();
        _cache.surface = surface_create(ceil(_advance) + 2, max(32, _height + 2));
        surface_set_target(_cache.surface); matrix_set(matrix_world, matrix_build_identity());
        draw_clear_alpha(c_black, 0); draw_set_alpha(1);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_color(c_black); draw_text(1, 1, _text);
        draw_set_color(c_white); draw_text(0, 0, _text);
        surface_reset_target(); matrix_set(matrix_world, _matrix); draw_set_alpha(_alpha);
    }
    var _distance = ceil(_advance) + 1 - _width;
    var _travel = _distance / 24 * 1000;
    var _elapsed = (current_time - _cache.started) % (2800 + _travel);
    var _offset = floor(clamp((_elapsed - 1400) * 24 / 1000, 0, _distance));
    draw_surface_part_ext(_cache.surface, _offset, 2, _width, _height,
        _center - floor(_width / 2), _top, 1, 1, c_white, draw_get_alpha());
    draw_set_color(c_white); draw_set_halign(fa_left);
}

function port_draw_pause_help(_x, _y, _bottom) {
    draw_set_color(make_color_rgb(8, 58, 8));
    draw_rectangle(_x - 64, _y + 198, _x + 383, _y + 211, false);
    port_draw_help_text(_x + 160, _y + 198, 304);
    return 198;
}

// Measure ink once per caption. Transparent font padding is not visible height.
function port_text_ink(_text, _original = false) {
    var _key = (_original ? "original:" : "locale:") + _text;
    if (variable_struct_exists(global.port_ink_cache, _key))
        return variable_struct_get(global.port_ink_cache, _key);
    var _map = _original ? global.port_original_ink_bounds : global.port_ink_bounds;
    var _top = 14, _bottom = 0, _cjk = false;
    for (var _i = 1; _i <= string_length(_text); ++_i) {
        var _point = ord(string_char_at(_text, _i)), _code = string(_point);
        if ((_point >= 11904 && _point <= 40959) || (_point >= 65382 && _point <= 65437)) _cjk = true;
        if (!variable_struct_exists(_map, _code)) continue;
        var _bounds = variable_struct_get(_map, _code);
        if (_bounds[1] <= _bounds[0]) continue;
        _top = min(_top, _bounds[0]); _bottom = max(_bottom, _bounds[1]);
    }
    var _result = _bottom > _top ? [_top, _bottom, _cjk] : [0, 14, _cjk];
    variable_struct_set(global.port_ink_cache, _key, _result);
    return _result;
}

// Refresh labels without restarting the pause fade or changing its state.
function port_refresh_subscreen_text() {
    maptext = get_text("Subscreen", "Title_Map");
    tip1text = get_text("Subscreen", "Menu_Tip");
    tip2text = get_text("Subscreen", "Marker_Tip");
    tip3text = get_text("Subscreen", "MarkerPos_Tip");
    tip4text = get_text("Subscreen", "DeleteMarker_Tip");
    tip5text = get_text("Subscreen", "EditMarker_Tip");
    tip6text = get_text("Misc", "Items_Tip");
    etiptext1 = get_text("Subscreen", "SelectItem_Tip");
    etiptext2 = get_text("Subscreen", "ToggleItem_Tip");
    logtitle = get_text("Subscreen", "Title_Logs");
    ltiptext1 = get_text("Subscreen", "SelectCategory_Tip");
    ltiptext2 = get_text("Subscreen", "SelectLog_Tip");
    ltiptext3 = get_text("Subscreen", "ExpandLog_Tip");
    ltiptext4 = get_text("Subscreen", "ScrollText_Tip");
    ltiptext5 = get_text("Subscreen", "Back_Tip");
    opt_text1 = get_text("Subscreen", "Title_Options");
}
