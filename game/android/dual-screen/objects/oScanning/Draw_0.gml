if (global.ophudshowlogmsg) {
    draw_background_ext(bgNotification, __view_get( e__VW.XView, 0 ) + xoffset - 40 - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + yoffset - 4, 1, 1, 0, -1, image_alpha*0.7);
    draw_sprite_ext(sprite_index, -1, __view_get( e__VW.XView, 0 ) + xoffset - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + yoffset, 1, 1, 0, -1, image_alpha);
    draw_set_font(fontGUI2);
    draw_set_color(make_colour_rgb(224, 248, 208)); // OG c_white
    draw_set_alpha(image_alpha);
    draw_text(__view_get( e__VW.XView, 0 ) + xoffset + 8 - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + yoffset - 5, string_hash_to_newline(text));
}

