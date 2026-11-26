// Take control of the upper composite so setup, frontend, pause, and gameplay choose their own presentation.
application_surface_draw_enable(0);
draw_clear(c_black);
dual_swap_x = 0; dual_swap_y = 0;
dual_swap_width = window_get_width(); dual_swap_height = window_get_height();
if (room != rm_transition) dual_controller_splash = room == rm_controller;
if (dual_draw_setup_upper()) exit;
if (dual_enabled && (room == rm_loading || (room == rm_transition && dual_loading_transition))) {
    dual_frontend_previous_mode = DUAL_FRONTEND_GAMEPLAY;
    exit;
}
if (dual_draw_frontend_upper()) exit;
if (dual_draw_paused_upper()) exit;
// Use the same submission order throughout gameplay. Frontend, pause and loading
// routes have already returned above; the per-frame guard prevents duplicate work.
if (global.ingame && room != rm_transition) dual_draw();
dual_swap_capture_area(displayx, displayy, (320 + widescreen_space) * display_scale, 240 * display_scale);

// Apply the optional palette to the gameplay composite after the special panel routes have returned.
if (shader_on && global.shaders_compiled) set_8bit_shader();
/// Draw game surface
if(widescreen) {
    // used view_*port[0] instead of display* previously because Wanderer was supporting all ratios
    if (surface_exists(widescreen_surface)) {
        var _sharp = sharp_scale_begin(widescreen_surface, display_scale);
        // xShake/yShake are game-pixel amounts; unscaled they are 0-5 physical px and
        // imperceptible on high-DPI screens (the viewport jitter oQuake also does never
        // reaches the screen in widescreen mode - view 1 renders to its own surface).
        draw_surface_ext(widescreen_surface, displayx+xShake*display_scale, displayy+yShake*display_scale, display_scale, display_scale, 0, c_white, 1);
        sharp_scale_end(_sharp);
    }
} else {
    if (surface_exists(application_surface)) {
        var _sharp = sharp_scale_begin(application_surface, display_scale);
        draw_game_surface(displayx, displayy, display_scale);
        sharp_scale_end(_sharp);
    }
}



shader_reset();

// Keep the controller artwork sharp by drawing it after the low-resolution room surface.
if (dual_controller_splash) {
    var _controller_filter = gpu_get_texfilter();
    var _controller_alpha = dual_enabled ? 1 : clamp(fadedone, 0, 1);
    if (instance_exists(oTransition)) _controller_alpha *= 1 - clamp(oTransition.fade, 0, 1);
    var _controller_scale = 128 * display_scale / sprite_get_width(sDualScreenController);
    gpu_set_texfilter(true);
    draw_sprite_ext(sDualScreenController, 0,
        round(displayx + (96 + widescreen_space / 2) * display_scale),
        round(displayy + 16 * display_scale),
        _controller_scale, _controller_scale, 0, c_white, _controller_alpha);
    gpu_set_texfilter(_controller_filter);
}
