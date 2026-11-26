draw_set_color(c_black);
draw_set_alpha(image_alpha);
draw_rectangle(__view_get( e__VW.XView, 0 ) - 10 - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) - 10, __view_get( e__VW.XView, 0 ) + __view_get( e__VW.WView, 0 ) + 10 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + __view_get( e__VW.HView, 0 ) + 10, false);

