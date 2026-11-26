// Reactor warnings and area arrivals stay above, independently of health and ammo placement.
if (global.ingame) {
    if (surface_exists(gui_surface)) {
        if (global.ingame && displaygui && room != rm_transition && instance_exists(oCharacter)) {
            // GM2026: GUI canvas is pinned to window pixels (display_set_gui_size in Step),
            // so draw at the same window coords as the world composite — no
            // application_get_position() offset (that was for the default app-surface-
            // anchored GUI mapping, which we no longer use).
            var _overlay_alpha = 1;
            // Let the reactor's white flash cover health and ammunition as well as the room.
            if (dual_enabled && instance_exists(oA4EscapeExplosion)) {
                _overlay_alpha = 1 - clamp(oA4EscapeExplosion.whitealpha, 0, 1);
            }
            var _sharp = sharp_scale_begin(gui_surface, display_scale);
            draw_surface_ext(gui_surface, displayx, displayy, display_scale, display_scale, 0, -1, _overlay_alpha);
            sharp_scale_end(_sharp);
        }
    }
}

// Fade the upper gameplay and its overlay together during room changes.
if (dual_enabled && !dual_setup_needed && dual_room_alpha < 1) {
    draw_set_color(c_black);
    draw_set_alpha(1 - dual_room_alpha);
    draw_rectangle(0, 0, window_get_width(), window_get_height(), false);
    draw_set_alpha(1);
    draw_set_color(c_white);
}

//draw_text(4, 32, "Gamepad Index: " + string(global.gamepadIndex));
//draw_text(4, 48, "Control Type: " + string(global.controltype));


// Keep the upper display black while the short blackout counter remains active.
if (black > 0) {
    draw_set_alpha(1);
    draw_set_color(c_black);
    draw_rectangle(0, 0, display_get_width(), display_get_height(), false);
}

/* */
/*  */

// Render after the upper composite; the lower canvas has fixed independent dimensions.
dual_draw();
