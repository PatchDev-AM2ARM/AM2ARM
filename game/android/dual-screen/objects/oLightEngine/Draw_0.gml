if (global.nano_enabled && nano_light_draw()) exit;
// Preserve surface recovery even when the base image is not consumed.
if (world_draw_unused() && surface_exists(surf)) { draw_set_blend_mode(bm_normal); exit; }
// Subtract the remaining mask from the scene, leaving the areas around lights visible.
draw_set_blend_mode(bm_subtract);
if (surface_exists(surf)) {
    draw_surface_ext(surf, __view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ), 1, 1, 0, make_color_hsv(0, 0, light_mask_opacity(image_alpha) * 255), 1); // view[0] previously
} else {
    event_user(0);
    event_user(1);
}
draw_set_blend_mode(bm_normal);

