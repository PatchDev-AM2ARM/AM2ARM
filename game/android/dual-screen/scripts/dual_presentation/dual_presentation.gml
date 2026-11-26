// Upper-panel pause images and swapped-screen presentation.
// Runs in oControl scope. Coordinates belong to the existing scene/HUD surfaces.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function dual_pause_blend() {
    if (room != rm_subscreen || !instance_exists(oSS_Fg)) return 0;
    var _t = clamp(oSS_Fg.ealpha, 0, 1);
    return _t * _t * (3 - 2 * _t);
}

// Capture only health and ammo before leaving the gameplay room for the pause menu.
function dual_capture_upper_hud() {
    if (!instance_exists(oCharacter)) return;
    var _width = 320 + widescreen_space;
    if (!surface_exists(dual_upper_hud_surface)) dual_upper_hud_surface = surface_create(_width, 24);
    if (surface_get_width(dual_upper_hud_surface) != _width) surface_resize(dual_upper_hud_surface, _width, 24);
    var _font = draw_get_font(), _color = draw_get_color(), _alpha = draw_get_alpha();
    var _ha = draw_get_halign(), _va = draw_get_valign();
    surface_set_target(dual_upper_hud_surface);
    draw_clear_alpha(c_black, 0);
    draw_set_halign(fa_left); draw_set_valign(fa_top);
    draw_gui(true);
    surface_reset_target();
    // Keep the paused HUD available if Android discards its drawing surface in the background.
    if (buffer_exists(dual_upper_hud_buffer)) buffer_delete(dual_upper_hud_buffer);
    dual_upper_hud_width = _width;
    dual_upper_hud_buffer = buffer_create(_width * 24 * 4, buffer_fixed, 1);
    buffer_get_surface(dual_upper_hud_buffer, dual_upper_hud_surface, 0);
    draw_set_font(_font); draw_set_color(_color); draw_set_alpha(_alpha);
    draw_set_halign(_ha); draw_set_valign(_va);
}

// Keep the captured gameplay view on the upper panel while the lower panel owns the pause controls.
function dual_draw_paused_upper() {
    if (!dual_enabled || room != rm_subscreen) {
        dual_pause_valid = false;
        return false;
    }
    if (surface_exists(screen_surface)) {
        if (!surface_exists(dual_pause_surface)) {
            dual_pause_surface = surface_create(dual_pause_width, 240);
            dual_pause_valid = false;
        }
        // Preserve the player's palette; use Olive only when the filter is off.
        var _selected = palette_number > 0;
        var _palette = _selected ? palette_number : 1;
        if (!dual_pause_valid || dual_pause_palette != _palette) {
            surface_resize(dual_pause_surface, dual_pause_width, 240);
            surface_set_target(dual_pause_surface);
            draw_clear(c_black);
            if (global.shaders_compiled) set_8bit_shader(_palette);
            draw_surface_part_ext(screen_surface, 0, 0, dual_pause_width, 240, 0, 0, 1, 1, c_white, 1);
            shader_reset();
            surface_reset_target();
            dual_pause_valid = true;
            dual_pause_palette = _palette;
        }
        var _scale = os_type == os_android ? android_display_scale(dual_pause_width, 240)
            : min(window_get_width() / dual_pause_width, window_get_height() / 240);
        if (os_type != os_android && global.oppixelperfect) _scale = max(1, floor(_scale));
        var _x = round((window_get_width() - dual_pause_width * _scale) / 2);
        var _y = round((window_get_height() - 240 * _scale) / 2);
        dual_swap_capture_area(_x, _y, dual_pause_width * _scale, 240 * _scale);
        var _blend = dual_pause_blend();
        if (!_selected && _blend < 1) {
            var _sharp = sharp_scale_begin(screen_surface, _scale);
            draw_surface_part_ext(screen_surface, 0, 0, dual_pause_width, 240, _x, _y,
                _scale, _scale, c_white, 1);
            sharp_scale_end(_sharp);
        }
        var _sharp = sharp_scale_begin(dual_pause_surface, _scale);
        draw_surface_ext(dual_pause_surface, _x, _y, _scale, _scale, 0, c_white, _selected ? 1 : _blend);
        sharp_scale_end(_sharp);
        var _color = draw_get_color(), _alpha = draw_get_alpha();
        draw_set_color(c_black);
        draw_set_alpha((_selected ? 0.7 : 0.5) * _blend);
        draw_rectangle(_x, _y, _x + dual_pause_width * _scale, _y + 240 * _scale, false);
        draw_set_color(_color); draw_set_alpha(_alpha);
        // Keep the selected top HUD readable while the gameplay behind it is paused and dimmed.
        if (dual_hud_top) {
            if (!surface_exists(dual_upper_hud_surface) && buffer_exists(dual_upper_hud_buffer)) {
                dual_upper_hud_surface = surface_create(dual_upper_hud_width, 24);
                buffer_set_surface(dual_upper_hud_buffer, dual_upper_hud_surface, 0);
            }
            if (surface_exists(dual_upper_hud_surface)) {
                _sharp = sharp_scale_begin(dual_upper_hud_surface, _scale);
                draw_surface_ext(dual_upper_hud_surface, _x, _y, _scale, _scale, 0, c_white, 1);
                sharp_scale_end(_sharp);
            }
        }
    }
    return true;
}

// The second screen receives the displayed picture without the main screen's letterbox.
// Each producer supplies its actual bounds; setup and loading retain the window.
function dual_swap_capture_area(_x, _y, _width, _height) {
    var _window_width = window_get_width(), _window_height = window_get_height();
    var _left = clamp(round(_x), 0, _window_width - 1);
    var _top = clamp(round(_y), 0, _window_height - 1);
    var _right = clamp(round(_x + _width), _left + 1, _window_width);
    var _bottom = clamp(round(_y + _height), _top + 1, _window_height);
    dual_swap_x = _left;
    // Native framebuffer copies use a bottom-left origin.
    dual_swap_y = _window_height - _bottom;
    dual_swap_width = _right - _left;
    dual_swap_height = _bottom - _top;
}

function dual_swap_draw() {
    if (!dual_swap_active() || !surface_exists(dual_surface)) return;
    // GUI End follows every Post Draw and Draw GUI producer, including fades.
    // A balanced target change flushes GameMaker's batched drawing before native
    // code copies the finished window. Never leave a target active across events.
    surface_set_target(dual_surface);
    surface_reset_target();
    if (DualScreen_SwapFrame(dual_swap_x, dual_swap_y, dual_swap_width, dual_swap_height) != 1) return;
    dual_frames++;
    var _world = matrix_get(matrix_world), _filter = gpu_get_texfilter();
    var _blend = gpu_get_blendmode_ext_sepalpha();
    var _color = draw_get_color(), _alpha = draw_get_alpha();
    matrix_set(matrix_world, matrix_build_identity());
    gpu_set_texfilter(false);
    gpu_set_blendmode(bm_normal);
    draw_set_color(c_white); draw_set_alpha(1);
    draw_clear(c_black);
    draw_surface_ext(dual_surface, dual_x, dual_y, dual_scale, dual_scale, 0, c_white, 1);
    dual_art_draw_primary();
    draw_set_color(_color); draw_set_alpha(_alpha);
    gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]); gpu_set_texfilter(_filter);
    matrix_set(matrix_world, _world);
}
