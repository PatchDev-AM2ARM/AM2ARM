// Visible menu artwork spans native rows 51 through 190, centered at 121.
var _menu_y = __view_get(e__VW.YView, 0) + (oControl.dual_enabled ? oControl.dual_menu_center_y - 121 : 0);
// equips
draw_sprite_ext(sprite_index, -1, __view_get( e__VW.XView, 0 ) + 160 + offset, _menu_y + 120, 1, 1, 0, -1, 1);
draw_background(bg_SubScrMenuEqu, __view_get( e__VW.XView, 0 ) + 196 + offset, _menu_y + 103);
// logs
draw_sprite_ext(sprite_index, -1, __view_get( e__VW.XView, 0 ) + 160 - offset, _menu_y + 120, 1, 1, 180, -1, 1);
draw_background(bg_SubScrMenuLog, __view_get( e__VW.XView, 0 ) + 90 - offset, _menu_y + 103);
// map
draw_sprite_ext(sprite_index, -1, __view_get( e__VW.XView, 0 ) + 160, _menu_y + 120 - offset, 1, 1, 90, -1, 1);
draw_background(bg_SubScrMenuMap, __view_get( e__VW.XView, 0 ) + 143, _menu_y + 50 - offset);
// options
draw_sprite_ext(sprite_index, -1, __view_get( e__VW.XView, 0 ) + 160, _menu_y + 120 + offset, 1, 1, 270, -1, 1);
draw_background(bg_SubScrMenuOpt, __view_get( e__VW.XView, 0 ) + 143, _menu_y + 156 + offset);
// widescreen fix for screen edges
if (oControl.widescreen) {
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_rectangle(__view_get( e__VW.XView, 0 ) + 320 + offset, __view_get( e__VW.YView, 0 ), __view_get( e__VW.XView, 0 ) + 320 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 240, false);
    draw_rectangle(__view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ), __view_get( e__VW.XView, 0 ) + (oControl.widescreen_space/2) - offset, __view_get( e__VW.YView, 0 ) + 240, false);
    draw_set_color(c_white);
}
