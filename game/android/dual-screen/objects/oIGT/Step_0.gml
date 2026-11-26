if(!oControl.mod_IGT || oControl.dual_enabled) instance_destroy();
if (surface_exists(igt_surface) && (surface_get_width(igt_surface) != (320 + oControl.widescreen_space))) { // widescreen fix
    surface_free(igt_surface);
}
if (!surface_exists(igt_surface)) igt_surface = surface_create(320 + oControl.widescreen_space, 240);
    if (surface_exists(igt_surface)) {
    
        var compl = string(round(global.itemstaken / 88 * 100));
        
        // Prepare the timer and optional item percentage on a transparent surface for the HUD to scale.
        surface_set_target(igt_surface);
        draw_clear_alpha(c_black, 0);
        draw_set_font(fontGUI2);
        draw_set_halign(fa_left);
        draw_set_alpha(100/255);
        draw_set_color(c_black);
        draw_rectangle(0, 20, 54 - (4*string_count("1", steps_to_time2(global.gametime))), 29, false);
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_cool_text(4, 16, steps_to_time2(global.gametime), c_black, c_white, c_gray, 1);
        
        if (oControl.mod_collecteditemsmap == 1) {
            draw_set_halign(fa_right);
            //draw_cool_text(surface_get_width(igt_surface) - 4, 26, string(round(global.itemstaken / 88 * 100)) + "%", c_black, c_white, c_gray, 1);
            //draw_cool_text(4, 22, string(round(global.itemstaken / 88 * 100)) + "%", c_black, c_white, c_gray, 1);
            //draw_cool_text(54, 14, string(round(global.itemstaken / 88 * 100)) + "%", c_black, c_white, make_color_rgb(255, 228, 2), 1);
            draw_set_alpha(100/255);
            draw_set_color(c_black);
            draw_rectangle(320 + oControl.widescreen_space + (4*string_count("1", compl)) - (7*(string_length(compl) - 1)) - 21, 32, 320 + oControl.widescreen_space, 41, false);
            draw_set_alpha(1);
            draw_set_color(c_white);
            draw_cool_text(surface_get_width(igt_surface) - 3, 28, compl + "%", c_black, c_white, c_silver, 1);
            draw_set_halign(fa_left);
        }
        
        //draw_sprite(sHUD_GT, image_index, 316, 32); // DEBUG
        surface_reset_target();
    }

