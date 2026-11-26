// HUD cache keys, dirty decisions and cached-image lifetime.
// Runs in oControl scope. Cache keys include language generation and display geometry.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function dual_art_prepare(_game, _frontend, _ui_paused, _pause_map) {
    dual_art_hint_mask = 0;
    dual_art_title_layout = dual_art_empty_title;
    dual_art_top_rows = 0;
    dual_art_footer_rows = 0;
    if (dual_setup_needed || !_game || _frontend != DUAL_FRONTEND_GAMEPLAY
        || room == rm_transition || room == rm_loading) return;
    var _page_menu = _ui_paused && !_pause_map;
    dual_art_top_rows = _page_menu ? 0 : dual_art_header_rows();
    // All menu pages share one frame and button row. Timer and item
    // collection remain on the map, including while it is paused.
    dual_art_footer_rows = _page_menu ? 15 : 31;
    if (surface_exists(dual_art_surface) && surface_get_width(dual_art_surface) != dual_art_width)
        surface_free(dual_art_surface);
    if (!surface_exists(dual_art_surface)) {
        dual_art_surface = effect_surface_create(dual_art_width, 128);
        dual_art_cache_state = [];
    }
    var _key = dual_art_cache_key(_ui_paused, _pause_map);
    // During a time-based area fade the alpha may advance even between the
    // key and a GPU readback. Keep the original live redraw for its full span.
    var _title_live = dual_backdrop_previous >= 0 && current_time < dual_backdrop_since + 600;
    var _hit = !_title_live && array_equals(_key, dual_art_cache_state);
    if (_hit) {
        dual_art_title_layout = dual_art_cache_title;
        dual_art_hint_mask = dual_art_cache_hints;
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_alpha(1); draw_set_color(c_white);
        return;
    }
    var _clock_only = global.nano_enabled && !_title_live
        && dual_art_footer_rows == 31 && dual_art_clock_only(dual_art_cache_state, _key);
    dual_art_generation++;
    var _world = matrix_get(matrix_world), _view = matrix_get(matrix_view), _projection = matrix_get(matrix_projection);
    var _blend = gpu_get_blendmode_ext_sepalpha();
    matrix_set(matrix_world, matrix_build_identity());
    surface_set_target(dual_art_surface);
    if (_clock_only) {
        // Preserve the header, title atlas and button hints exactly. Only the
        // opaque statistics band changed; its original draw routine is reused.
        dual_art_title_layout = dual_art_cache_title;
        dual_art_hint_mask = dual_art_cache_hints;
        draw_set_alpha(1); draw_set_halign(fa_left); draw_set_valign(fa_top);
        gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
        dual_art_rect(0, 97, dual_art_width, 16, c_black);
        dual_art_stats(97);
    } else {
        draw_clear_alpha(c_black, 0); draw_set_alpha(1); draw_set_color(c_white);
        gpu_set_blendmode_ext_sepalpha(bm_src_alpha, bm_inv_src_alpha, bm_one, bm_inv_src_alpha);
        if (dual_art_top_rows > 0) dual_art_rect(0, 0, dual_art_width, dual_art_top_rows, c_black);
        dual_art_rect(0, 128 - dual_art_footer_rows, dual_art_width, dual_art_footer_rows, c_black);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        if (dual_art_top_rows > 0) {
            if (dual_hud_top) dual_art_title_header();
            else dual_art_header();
        }
        if (dual_art_footer_rows == 31) dual_art_stats(97);
        var _controls = _ui_paused || (global.ingame && global.enablecontrol && room != rm_transition);
        draw_set_alpha(_controls ? 1 : 0.4);
        dual_art_native_buttons(_ui_paused, _pause_map, 113);
    }
    draw_set_alpha(1);
    surface_reset_target();
    gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]);
    matrix_set(matrix_world, _world); matrix_set(matrix_view, _view); matrix_set(matrix_projection, _projection);
    draw_set_color(c_white);
    dual_art_cache_state = variable_clone(_key);
    dual_art_cache_title = dual_art_title_layout;
    dual_art_cache_hints = dual_art_hint_mask;

}

function dual_art_clock_only(_old, _next) {
    if (array_length(_old) != 42 || array_length(_next) != 42 || _old[27] == _next[27]) return false;
    for (var _i = 0; _i < 42; ++_i)
        if (_i != 27 && _old[_i] != _next[_i]) return false;
    return true;
}

function dual_art_reset_images() {
    dual_art_hint_mask = 0;
    dual_art_output_hints = 0;
    dual_art_previous_hints = 0;
    dual_art_cache_hints = 0;
    dual_art_output_key = [];
    dual_art_generation = 0;
    dual_art_cache_state = [];
    var _surfaces = [dual_art_output, dual_art_previous, dual_art_flash_top, dual_art_flash_bottom,
        dual_art_flash_title, dual_art_flash_light];
    for (var _i = 0; _i < array_length(_surfaces); ++_i)
        if (surface_exists(_surfaces[_i])) surface_free(_surfaces[_i]);
    dual_art_output = -1;
    dual_art_previous = -1;
    dual_art_flash_top = -1;
    dual_art_flash_bottom = -1;
    dual_art_flash_title = -1;
    dual_art_flash_light = -1;
    dual_art_title_layout = [0, 0, 0];
    dual_art_output_title = [0, 0, 0];
    dual_art_previous_title = [0, 0, 0];
    dual_art_output_top = 0;
    dual_art_output_bottom = 0;
    dual_art_previous_top = 0;
    dual_art_previous_bottom = 0;
}

function dual_art_snapshot() {
    dual_art_previous_hints = dual_art_output_hints;
    dual_art_previous_title = dual_art_output_title;
    dual_art_previous_top = dual_art_output_top;
    dual_art_previous_bottom = dual_art_output_bottom;
    if (!surface_exists(dual_art_output)) return;
    if (!surface_exists(dual_art_previous)) dual_art_previous = surface_create(dual_art_width, 128);
    surface_copy(dual_art_previous, 0, 0, dual_art_output);
}

function dual_art_hold_sheet() {
    if (surface_exists(oControl.dual_art_hold)) return oControl.dual_art_hold;
    var _world = matrix_get(matrix_world), _view = matrix_get(matrix_view);
    var _projection = matrix_get(matrix_projection), _filter = gpu_get_texfilter();
    var _color = draw_get_color(), _alpha = draw_get_alpha(), _blend = gpu_get_blendmode();
    matrix_set(matrix_world, matrix_build_identity());
    gpu_set_texfilter(false); gpu_set_blendmode(bm_normal);
    oControl.dual_art_hold = surface_create(16, 48);
    surface_set_target(oControl.dual_art_hold);
    draw_clear_alpha(c_black, 0);
    draw_sprite_part(sDualHudIcons, 0, 32, 0, 16, 48, 0, 0);
    surface_reset_target();
    var _pixels = buffer_create(16 * 48 * 4, buffer_fixed, 1);
    buffer_get_surface(_pixels, oControl.dual_art_hold, 0);
    for (var _p = 0; _p < 16 * 48; ++_p) {
        var _offset = _p * 4, _pixel = buffer_peek(_pixels, _offset, buffer_u32);
        if ((_pixel & $ff000000) == 0) continue;
        var _v = max(_pixel & 255, (_pixel >> 8) & 255, (_pixel >> 16) & 255);
        buffer_poke(_pixels, _offset, buffer_u32, (_pixel & $ff000000) | make_color_rgb(_v, _v, _v));
    }
    buffer_set_surface(_pixels, oControl.dual_art_hold, 0);
    buffer_delete(_pixels);
    gpu_set_texfilter(_filter); gpu_set_blendmode(_blend);
    matrix_set(matrix_world, _world); matrix_set(matrix_view, _view); matrix_set(matrix_projection, _projection);
    draw_set_color(_color); draw_set_alpha(_alpha);
    return oControl.dual_art_hold;
}

// A cache hit changes only atlas generation. The existing map, fades, help text
// and GPU presentation still run every frame at their original cadence.
function dual_art_cache_key(_ui_paused, _pause_map) {
    dual_update_weapon_state();
    var _title = dual_art_title_state();
    var _hints = dual_art_button_hints(_ui_paused);
    var _blink = hpalarm > 0 && hudflash > 0 ? clamp(hudflashfx / 4, 0, 1) : 0;
    var _editing = instance_exists(oMapCursor) && oMapCursor.state == 1;
    var _key = dual_art_key_scratch;
    _key[0] = dual_art_width;
    _key[1] = dual_art_scale;
    _key[2] = dual_art_header_height;
    _key[3] = dual_art_health_height;
    _key[4] = dual_art_top_rows;
    _key[5] = dual_art_footer_rows;
    _key[6] = fontGUI2;
    _key[7] = gui_health();
    _key[8] = global.playerhealth;
    _key[9] = global.etanks;
    _key[10] = mod_etankhealthmult;
    _key[11] = _blink;
    _key[12] = global.monstersleft;
    _key[13] = global.monstersarea;
    _key[14] = global.opmslstyle;
    _key[15] = dual_missile_frame;
    _key[16] = dual_super_frame;
    _key[17] = dual_bomb_frame;
    _key[18] = global.missiles;
    _key[19] = global.smissiles;
    _key[20] = global.pbombs;
    _key[21] = global.maxmissiles;
    _key[22] = global.maxsmissiles;
    _key[23] = global.maxpbombs;
    _key[24] = _title.text;
    _key[25] = _title.alpha;
    _key[26] = dual_art_pixels;
    _key[27] = floor(global.gametime / 60);
    _key[28] = mod_percentofitems;
    _key[29] = global.itemstaken;
    _key[30] = _ui_paused;
    _key[31] = _pause_map;
    _key[32] = _editing;
    _key[33] = global.mapmarker;
    _key[34] = _hints[0];
    _key[35] = _hints[1];
    _key[36] = _hints[2];
    _key[37] = dual_overview;
    _key[38] = dual_follow;
    _key[39] = _ui_paused || (global.ingame && global.enablecontrol && room != rm_transition);
    _key[40] = instance_exists(oSubScrChange);
    _key[41] = port_locale_revision();
    return _key;
}
