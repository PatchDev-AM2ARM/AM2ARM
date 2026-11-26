
// Capture the game view used as the frozen background of menus and transitions.
if (!surface_exists(screen_surface)) screen_surface = surface_create(512+widescreen_space, 256);
surface_set_target(screen_surface);
draw_clear(c_black);

if(widescreen) {
    if (surface_exists(widescreen_surface)) {
        draw_surface(widescreen_surface, 0, 0);
    }
} else if (surface_exists(application_surface)) {
    draw_surface(application_surface, 0, 0);
}
    
surface_reset_target();
// Only the Android app loses its surfaces in the background.
if (os_is_native && global.android_app) {
    // GM2026 fix: the surface_save -> PNG -> sprite_add round-trip loads garbage on this Android
    // runtime, washing the resumed pause screen bright (probe-verified: surface existed, content
    // was a uniform bright wash instead of the frozen frame). Save raw pixels instead:
    // u32 w, u32 h, then RGBA. Restored byte-exact via buffer_set_surface in oSS_Bg Step.
    var _src = -1;
    if (widescreen) {
        if (surface_exists(widescreen_surface)) _src = widescreen_surface;
    } else {
        if (surface_exists(application_surface)) _src = application_surface;
    }
    if (_src != -1) {
        var _w = surface_get_width(_src);
        var _h = surface_get_height(_src);
        var _buf = buffer_create(8 + _w * _h * 4, buffer_fixed, 1);
        buffer_write(_buf, buffer_u32, _w);
        buffer_write(_buf, buffer_u32, _h);
        buffer_get_surface(_buf, _src, 8);
        buffer_save(_buf, "tempscr.buf");
        buffer_delete(_buf);
        tempscr_written = true;
    }
}





/*if (!surface_exists(screen_surface)) screen_surface = surface_create(512 + widescreen_space, 256);
surface_set_target(screen_surface);
draw_clear(c_black);

if(widescreen) if (surface_exists(widescreen_surface)) draw_surface(widescreen_surface, 0, 0);
else           if (surface_exists(application_surface)) draw_surface(application_surface, 0, 0);

surface_reset_target();
if (os_is_native) {
    if (widescreen) {
        if (surface_exists(widescreen_surface)) {
            surface_save(widescreen_surface, working_directory + "/tempscr");
        }
    } else if (surface_exists(application_surface)) {
        surface_save(application_surface, working_directory + "/tempscr");
    }
}

/* */
/*  */
