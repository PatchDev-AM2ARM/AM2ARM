// GM2026 divergence fix: in GMS1.4, surface_set_target() inside a draw event switched
// the projection to the surface's own pixel space, so this event could draw at raw
// (0, 212+) and land at the bottom-left of the canvas. In GM2026 the active view's
// WORLD projection stays in effect, so those raw coords landed at ROOM (0,212) — the
// notification rendered at the room's corner instead of the screen's (proven with an
// on-device marker-bar probe). Draw in view space instead, on exactly one view pass
// (the widescreen canvas view 1 when widescreen is on, view 0 otherwise) so the popup
// isn't painted twice at offset positions.
// Hide notifications while the reactor explosion covers the screens.
if (oControl.dual_enabled && (instance_exists(oA4EscapeExplosion) || instance_exists(oA4EscapeExplosionFail))) exit;

if (oControl.widescreen) {
    if (view_current != 1) exit;
} else {
    if (view_current != 0) exit;
}

if (oControl.widescreen){
    if (surface_exists(oControl.widescreen_surface)) {
        surface_set_target(oControl.widescreen_surface);
    }
} else {
    if (surface_exists(application_surface)) {
        surface_set_target(application_surface);
    }
}

vx = __view_get( e__VW.XView, view_current );
vy = __view_get( e__VW.YView, view_current ) + offset;
draw_background_ext(bgNotification, vx, vy + 212, 1, 1, 0, -1, 0.7);
draw_set_font(fontGUI2);
draw_set_alpha(1);
/*if (!log) {
    draw_set_color(c_white); // og c_white
    draw_text(vx + 7, vy + 214, text1);
    if (btn2_name == "") {
        if (btn1_name != "") {
            draw_txt_1button(vx + 7, vy + 224, text2, 1, btn1_name, 1);
        } else {
            draw_set_font(fontMenuSmall);
            draw_text(vx + 7, vy + 224, text2);
        }
    } else draw_txt_2buttons(vx + 7, vy + 224, text2, 1, btn1_name, btn2_name, 1);
} else if (log) {*/ // logs
    draw_set_color(make_colour_rgb(224, 248, 208)); // og c_white
    draw_text(vx + 7, vy + 214, string_hash_to_newline(text1));
    if (btn2_name == "") {
        if (btn1_name != "") {
            draw_txt_1button_log(vx + 7, vy + 224, text2, 1, btn1_name, 1);
        } else {
            draw_set_font(fontMenuSmall);
            draw_text(vx + 7, vy + 224, string_hash_to_newline(text2));
        }
    } else draw_txt_2buttons_log(vx + 7, vy + 224, text2, 1, btn1_name, btn2_name, 1);
//}
//draw_set_color(c_white);
surface_reset_target();

/* */
/*  */
