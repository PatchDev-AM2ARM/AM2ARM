// HUD strip presentation, transitions and fallback composition.
// Runs in oControl scope. Keep render-target, alpha and blend-state handling explicit.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function dual_art_help() {
    var _top = floor(dual_height - 41 * dual_art_scale);
    var _height = floor(8 * dual_art_scale);
    dual_art_rect(-dual_pad, _top, dual_width, _height, make_color_rgb(8, 58, 8));
    port_draw_help_text(155, _top, dual_width - 16, _height);
}

function dual_art_flash(_escape, _fade) {
    // Apply the same reactor glow in screen coordinates. Each temporary strip
    // clips the glow to its own band; health and icon pixels are never rescaled.
    var _matrix = matrix_get(matrix_world), _blend = gpu_get_blendmode_ext_sepalpha();
    for (var _band = 0; _band < 3; ++_band) {
        var _title_band = _band == 2;
        var _rows = _title_band ? (dual_art_output_title[2] > 0 ? 32 : 0)
            : (_band == 0 ? dual_art_output_top : dual_art_output_bottom);
        if (_rows == 0) continue;
        var _scratch = _title_band ? dual_art_flash_title : (_band == 0 ? dual_art_flash_top : dual_art_flash_bottom);
        if (surface_exists(_scratch) && (surface_get_width(_scratch) != dual_art_width || surface_get_height(_scratch) != _rows))
            surface_free(_scratch);
        if (!surface_exists(_scratch)) _scratch = surface_create(dual_art_width, _rows);
        if (_title_band) dual_art_flash_title = _scratch;
        else if (_band == 0) dual_art_flash_top = _scratch; else dual_art_flash_bottom = _scratch;
        var _source_y = _title_band ? 64 : (_band == 0 ? 0 : 128 - _rows);
        surface_set_target(_scratch);
        matrix_set(matrix_world, matrix_build_identity());
        gpu_set_blendmode_ext(bm_one, bm_zero);
        draw_clear_alpha(c_black, _title_band ? 0 : 1);
        draw_surface_part_ext(dual_art_output, 0, _source_y, dual_art_width, _rows, 0, 0, 1, 1, c_white, 1);
        var _left = (dual_width - dual_art_width * dual_art_scale) / 2;
        var _top = _band == 0 ? 0 : dual_height - _rows * dual_art_scale;
        var _scale = dual_art_scale;
        if (_title_band) {
            _scale *= dual_art_output_title[2] / max(1, dual_art_pixels);
            _left += dual_art_output_title[0] * dual_art_scale - dual_art_width * _scale / 2;
            _top = dual_art_output_title[1] * dual_art_scale - 16 * _scale;
        }
        matrix_set(matrix_world, matrix_build(-_left / _scale, -_top / _scale, 0,
            0, 0, 0, 1 / _scale, 1 / _scale, 1));
        gpu_set_blendmode_ext_sepalpha(bm_zero, bm_inv_src_alpha, bm_zero, bm_one);
        draw_set_color(c_black); draw_set_alpha(1 - _fade);
        draw_rectangle(0, 0, dual_width, dual_height, false);
        if (_title_band) {
            // Accumulate the light before masking it with the title's coverage.
            // This retains both the glow sprite's alpha and the glyph's alpha.
            surface_reset_target();
            if (!surface_exists(dual_art_flash_light)) dual_art_flash_light = surface_create(dual_art_width, 32);
            surface_set_target(dual_art_flash_light);
            draw_clear_alpha(c_black, 0);
        }
        gpu_set_blendmode(bm_add);
        draw_set_color(c_white); draw_set_alpha(1);
        if (!_escape.fadeout) {
            var _camera = widescreen ? 1 : 0;
            var _sx = dual_width / __view_get(e__VW.WView, _camera);
            var _sy = dual_height / __view_get(e__VW.HView, _camera);
            var _x = (_escape.x - __view_get(e__VW.XView, _camera)) * _sx;
            var _y = (_escape.y - __view_get(e__VW.YView, _camera)) * _sy;
            var _xs = _escape.image_xscale * _sx, _ys = _escape.image_yscale * _sy;
            var _sprite = _escape.sprite_index, _frame = _escape.image_index;
            draw_sprite_ext(_sprite, _frame, _x, _y, _xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
            draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
            draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
            draw_sprite_ext(_sprite, _frame, _x, _y, _xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
        }
        draw_set_alpha(clamp(_escape.whitealpha, 0, 1));
        draw_rectangle(0, 0, dual_width, dual_height, false);
        draw_set_alpha(1); surface_reset_target();
        matrix_set(matrix_world, matrix_build_identity());
        if (_title_band) {
            surface_set_target(_scratch);
            gpu_set_blendmode_ext_sepalpha(bm_dest_alpha, bm_one, bm_zero, bm_one);
            draw_surface(dual_art_flash_light, 0, 0);
            surface_reset_target();
        }
        surface_set_target(dual_art_output);
        gpu_set_blendmode_ext(bm_one, bm_zero);
        draw_surface(_scratch, 0, _source_y);
        surface_reset_target();
    }
    gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]); matrix_set(matrix_world, _matrix);
    draw_set_color(c_white); draw_set_alpha(1);
}

function dual_art_finish(_old_alpha, _frontend, _escape, _send) {
    var _retain = room == rm_transition && !dual_loading_transition;
    var _death = _frontend == DUAL_FRONTEND_DEATH && room == rm_death && instance_exists(oDeathSequence);
    var _eligible = !dual_setup_needed
        && (_frontend == DUAL_FRONTEND_GAMEPLAY || _death) && room != rm_loading;
    var _fade = !dual_keep_room_map ? dual_room_alpha : 1;
    if (room == rm_transition && instance_exists(oTransition))
        _fade = dual_keep_room_map ? 1 : 1 - clamp(oTransition.fade, 0, 1);
    if (_death) _fade = 1 - clamp(oDeathSequence.fade, 0, 1);
    dual_art_output_fade = clamp(_fade, 0, 1);
    // Retained transition/death images and reactor flashes always follow their
    // live path. Their pixels must never be reused for ordinary gameplay.
    if (!_eligible || _retain || _death) dual_art_output_key = [];
    if (!_eligible) {
        dual_art_output_hints = 0;
        dual_art_output_title = [0, 0, 0];
        dual_art_output_top = 0;
        dual_art_output_bottom = 0;
    } else if (!_retain && !_death) {
        if (!surface_exists(dual_art_output)) {
            dual_art_output = effect_surface_create(dual_art_width, 128);
            dual_art_output_key = [];
        }
        var _previous = _old_alpha > 0 && surface_exists(dual_art_previous);
        dual_art_output_hints = dual_art_hint_mask | (_previous ? dual_art_previous_hints : 0);
        dual_art_output_title = dual_art_top_rows > 0 ? dual_art_title_layout
            : (_previous ? dual_art_previous_title : [0, 0, 0]);
        var _key = [dual_art_generation, dual_art_width, dual_art_top_rows,
            dual_art_footer_rows, dual_art_output_title];
        var _hit = !_previous && _escape == noone
            && array_equals(_key, dual_art_output_key);
        if (!_hit) {
            dual_art_compose_output(_old_alpha, _previous);
            // Keep the existing independent snapshot on a hit. Transition and
            // reactor frames still invalidate it through the live path above.
            dual_art_output_key = !_previous && _escape == noone ? variable_clone(_key) : [];
        }
        if (_escape != noone) { dual_art_flash(_escape, dual_art_output_fade); dual_art_output_fade = 1; }
    }
    if (_send && surface_exists(dual_art_output)) {
        surface_set_target(dual_art_output);
        dual_art_each_layer(dual_x, dual_y, dual_art_send_layer);
        surface_reset_target();
    }
}

// Call _layer for each HUD strip. Folding them into the map would shrink HUD lettering.
function dual_art_each_layer(_x, _y, _layer) {
    var _pixels = dual_art_pixels;
    var _left = _x + floor((dual_width * dual_scale - dual_art_width * _pixels) / 2);
    var _bottom = _y + dual_height * dual_scale;
    if (dual_art_output_top > 0) {
        _layer(_left, _y, _pixels, 0, 0, dual_art_width, dual_art_output_top);
        var _title = dual_art_output_title, _scale = _title[2];
        if (_scale > 0) _layer(_left + round(_title[0] * _pixels - dual_art_width * _scale / 2),
            _y + round(_title[1] * _pixels - 16 * _scale), _scale, 0, 64, dual_art_width, 32);
    }
    if (dual_art_output_bottom > 0) {
        _layer(_left, _bottom - dual_art_output_bottom * _pixels, _pixels,
            0, 128 - dual_art_output_bottom, dual_art_width, dual_art_output_bottom);
        // A separate integer output scale preserves every glyph
        // pixel while keeping labels on their original grid.
        var _hint_scale = max(0.5, floor(_pixels / 2));
        var _ends = [floor(dual_art_width / 3) - 1, floor(dual_art_width * 2 / 3) - 1, dual_art_width];
        for (var _i = 0; _i < 3; ++_i) if ((dual_art_output_hints & (1 << _i)) != 0)
            _layer(_left + (_ends[_i] - 2) * _pixels - 32 * _hint_scale,
                _bottom - 14 * _pixels, _hint_scale, _i * 32, 56, 32, 8);
    }
}

// DualScreen_Draw reads the current surface target, dual_art_output here.
function dual_art_send_layer(_x, _y, _scale, _left, _top, _width, _height) {
    DualScreen_Draw(_x, _y, _width * _scale, _height * _scale,
        _left / dual_art_width, _top / 128, _width / dual_art_width, _height / 128, dual_art_output_fade, 1);
}

function dual_art_draw_layer(_x, _y, _scale, _left, _top, _width, _height) {
    draw_surface_part_ext(dual_art_output, _left, _top, _width, _height, _x, _y, _scale, _scale,
        merge_color(c_black, c_white, dual_art_output_fade), 1);
}

function dual_art_fallback() {
    if (!surface_exists(dual_art_output)) return;
    var _world = matrix_get(matrix_world), _blend = gpu_get_blendmode_ext_sepalpha();
    surface_set_target(dual_surface);
    matrix_set(matrix_world, matrix_build_identity());
    gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
    var _color = merge_color(c_black, c_white, dual_art_output_fade);
    var _left = (dual_width - dual_art_width * dual_art_scale) / 2;
    if (dual_art_output_top > 0)
        draw_surface_part_ext(dual_art_output, 0, 0, dual_art_width, dual_art_output_top,
            _left, 0, dual_art_scale, dual_art_scale, _color, 1);
    if (dual_art_output_bottom > 0)
        draw_surface_part_ext(dual_art_output, 0, 128 - dual_art_output_bottom, dual_art_width, dual_art_output_bottom,
            _left, dual_height - dual_art_output_bottom * dual_art_scale, dual_art_scale, dual_art_scale, _color, 1);
    dual_art_draw_title_layer(dual_art_output, dual_art_output_title, dual_art_output_fade);
    dual_art_draw_hint_layer(dual_art_output, dual_art_output_hints, dual_art_output_fade);
    surface_reset_target();
    matrix_set(matrix_world, _world); gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]);
}

// When swapped, the strips go over the map on the main screen.
function dual_art_draw_primary() {
    if (!surface_exists(dual_art_output)) return;
    gpu_set_blendmode_ext(bm_one, bm_inv_src_alpha);
    dual_art_each_layer(dual_x, dual_y, dual_art_draw_layer);
}

function dual_art_draw_hint_layer(_surface, _mask, _brightness = 1) {
    if (_mask == 0) return;
    var _pixels = max(1, dual_art_pixels);
    var _scale = dual_art_scale * max(0.5, floor(_pixels / 2)) / _pixels;
    var _left = (dual_width - dual_art_width * dual_art_scale) / 2;
    var _ends = [floor(dual_art_width / 3) - 1, floor(dual_art_width * 2 / 3) - 1, dual_art_width];
    for (var _i = 0; _i < 3; ++_i) if ((_mask & (1 << _i)) != 0)
        draw_surface_part_ext(_surface, _i * 32, 56, 32, 8,
            _left + (_ends[_i] - 2) * dual_art_scale - 32 * _scale,
            dual_height - 14 * dual_art_scale, _scale, _scale,
            merge_color(c_black, c_white, _brightness), 1);
}

// Blend the current and previous HUD layers during menu transitions.
function dual_art_compose_output(_old_alpha, _previous) {
    var _blend = gpu_get_blendmode_ext_sepalpha(), _world = matrix_get(matrix_world);
    surface_set_target(dual_art_output);
    matrix_set(matrix_world, matrix_build_identity());
    draw_clear_alpha(c_black, 0);
    // Both inputs contain premultiplied pixels. Interpolate color and
    // coverage together so neither overlapping nor disappearing bands pop.
    gpu_set_blendmode_ext(bm_one, bm_one);
    var _alpha = _previous ? 1 - _old_alpha : 1;
    if (surface_exists(dual_art_surface) && (dual_art_top_rows > 0 || dual_art_footer_rows > 0))
        draw_surface_ext(dual_art_surface, 0, 0, 1, 1, 0, merge_color(c_black, c_white, _alpha), _alpha);
    if (_previous)
        draw_surface_ext(dual_art_previous, 0, 0, 1, 1, 0, merge_color(c_black, c_white, _old_alpha), _old_alpha);
    dual_art_output_top = max(dual_art_top_rows, _previous ? dual_art_previous_top : 0);
    dual_art_output_bottom = max(dual_art_footer_rows, _previous ? dual_art_previous_bottom : 0);
    surface_reset_target();
    matrix_set(matrix_world, _world); gpu_set_blendmode_ext_sepalpha(_blend[0], _blend[1], _blend[2], _blend[3]);
}
