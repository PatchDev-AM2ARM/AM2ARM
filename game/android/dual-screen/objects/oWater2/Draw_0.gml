draw_set_color(make_colour_rgb(10, 10, 80));
draw_set_blend_mode(bm_add);
draw_rectangle(__view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ), __view_get( e__VW.XView, 0 ) + 320 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 250, false);
draw_set_blend_mode(bm_normal);

