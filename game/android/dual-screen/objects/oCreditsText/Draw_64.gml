if (oControl.dual_enabled) exit; // The shared two-panel scene draws the credits.
// Rasterize Android credit lettering on the same native grid as the game.
// Direct window-space font drawing can land centered glyphs on half game pixels.
var _native_gui = os_type == os_android && surface_exists(oControl.gui_surface);
var _matrix = matrix_get(matrix_world);
if (_native_gui) {
    surface_set_target(oControl.gui_surface);
    draw_clear_alpha(c_black, 0);
    matrix_set(matrix_world, matrix_build(WIDE_SPACE, 0, 0, 0, 0, 0, 1, 1, 1));
} else display_set_gui_size(320, 240);
var _text_y = (_native_gui ? round(y) : y) + 17;
draw_set_alpha(image_alpha);
draw_set_font(fontGUI2);

// Left
draw_set_halign(fa_right);
draw_cool_text(X_POS - 12, _text_y, textLeft, c_black, c_white, c_white, 1);

// Right
draw_set_halign(fa_left);
draw_cool_text(X_POS + 12, _text_y, textRight, c_black, c_white, c_white, 1);

// Center
draw_set_halign(fa_center);
draw_cool_text(X_POS, _text_y, textCenter, c_black, c_white, c_white, 1);

// Header
draw_cool_text(X_POS, _text_y, textHeader, c_black, c_dkgray, c_gray, 1);

// Draw the original opening and closing bars on the native grid as well.
var _aperture = _native_gui ? round(yoffset) : yoffset;
draw_set_alpha(1);
draw_set_color(c_black);
draw_rectangle(0 - WIDE_SPACE, 0, 330 + WIDE_SPACE, 120 - _aperture, false);
draw_rectangle(0 - WIDE_SPACE, 120 + _aperture, 330 + WIDE_SPACE, 250, false);
if (_native_gui) {
    surface_reset_target();
    matrix_set(matrix_world, _matrix);
    var _sharp = sharp_scale_begin(oControl.gui_surface, oControl.display_scale);
    draw_surface_ext(oControl.gui_surface, oControl.displayx, oControl.displayy,
        oControl.display_scale, oControl.display_scale, 0, c_white, 1);
    sharp_scale_end(_sharp);
}
