// Start the dual-screen pause page on black; its upper frozen gameplay image is composed separately.
if (oControl.dual_enabled) {
    draw_set_color(c_black);
    draw_set_alpha(1);
    draw_rectangle(__view_get(e__VW.XView, 0), __view_get(e__VW.YView, 0),
        __view_get(e__VW.XView, 0) + 320, __view_get(e__VW.YView, 0) + 240, false);
} else if (surface_exists(oControl.screen_surface)) {
    draw_surface(oControl.screen_surface, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ));
    draw_surface_ext(oControl.screen_surface, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2) + 1, __view_get( e__VW.YView, 0 ), 1, 1, 0, -1, 0.5 * image_alpha);
    draw_surface_ext(oControl.screen_surface, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2) - 1, __view_get( e__VW.YView, 0 ), 1, 1, 0, -1, 0.5 * image_alpha);
    draw_surface_ext(oControl.screen_surface, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2) + 2, __view_get( e__VW.YView, 0 ), 1, 1, 0, -1, 0.2 * image_alpha);
    draw_surface_ext(oControl.screen_surface, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2) - 2, __view_get( e__VW.YView, 0 ), 1, 1, 0, -1, 0.2 * image_alpha);
}
// Layer the pause shading, scanlines, and edge artwork using the background object's fade.
draw_set_color(c_black);
if (!fadeout) draw_set_alpha(0.8);
if (fadeout) draw_set_alpha(0.8 * image_alpha);
draw_rectangle(__view_get( e__VW.XView, 0 )-(oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ), __view_get( e__VW.XView, 0 ) + 330 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 250, false);
if (global.ssmode > 0) draw_background_tiled_ext(bg_SubScrScanlines, __view_get( e__VW.XView, 0 )-(oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ), 1, 1, -1, 0.2 * image_alpha);
draw_background_ext(bg_SubScrFX, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ), 1, 1, 0, -1, 0.8 * image_alpha);
draw_background_ext(bg_SubScrFX, __view_get( e__VW.XView, 0 ) + 320 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ), -1, 1, 0, -1, 0.8 * image_alpha);
draw_background_ext(bg_SubScrFX, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 240, 1, -1, 0, -1, 0.8 * image_alpha);
draw_background_ext(bg_SubScrFX, __view_get( e__VW.XView, 0 ) + 320 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 240, -1, -1, 0, -1, 0.8 * image_alpha);
