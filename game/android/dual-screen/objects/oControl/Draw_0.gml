if (dual_enabled) {
    // Draw runs once per camera. Keep a single fade clock for both panels,
    // then cover their complete composites, including the lower toolbar.
    if (dual_fade_step != dual_steps) {
        dual_fade_step = dual_steps;
        dual_room_alpha = 1;
        if (room != initroom && global.transitiontype < 2) {
            dual_room_alpha = clamp(fadedone, 0, 1);
            fadedone = min(1, fadedone + 0.1);
        }
    }
// The non-dual fallback draws its room fade directly over the game view.
} else if (fadedone < 1 && room != initroom) {
    if (global.transitiontype < 2) {
        draw_set_alpha(1 - fadedone);
        draw_set_color(c_black);
        draw_rectangle(-widescreen_space/2, 0, room_width+widescreen_space/2, room_height, false);
        //if (instance_exists(oCharacter) && global.transitiontype == true) draw_character(oCharacter.sprite_index, oCharacter.x, oCharacter.y, oCharacter.aspr1, oCharacter.asprx, oCharacter.aspry, oCharacter.aspr2, oCharacter.aspr2x, oCharacter.aspr2y, oCharacter.aspr2a, oCharacter.mirror, oCharacter.image_blend, 1 - fadedone, oCharacter.armmsl, oCharacter.image_index);
        if (instance_exists(oCharacter) && global.transitiontype == true) { //BUGFIX
            if(oCharacter.juststarted == 0) {
                draw_set_blend_mode(bm_add);
                draw_character(oCharacter.sprite_index, oCharacter.x, oCharacter.y, oCharacter.aspr1, oCharacter.asprx, oCharacter.aspry, oCharacter.aspr2, oCharacter.aspr2x, oCharacter.aspr2y, oCharacter.aspr2a, oCharacter.mirror, oCharacter.image_blend, 1 - fadedone, oCharacter.armmsl, oCharacter.image_index);
                draw_set_blend_mode(bm_normal);
            }
        }
        fadedone += 0.1;
    }
}
draw_set_alpha(1);
if (showfps) {
    draw_set_font(fontMenuSmall);
    draw_set_color(c_white);
}

draw_set_font(fontMenuTiny);
draw_set_color(c_white);
draw_set_alpha(0.6);
draw_set_halign(fa_right);
if (0) draw_text(__view_get( e__VW.XView, 0 ) + __view_get( e__VW.WView, 0 ) - 2, __view_get( e__VW.YView, 0 ) + 232, string_hash_to_newline("1.1 T1"));
if (0) draw_text(__view_get( e__VW.XView, 0 ) + __view_get( e__VW.WView, 0 ) - 2, __view_get( e__VW.YView, 0 ) + 232, string_hash_to_newline("WORK IN PROGRESS"));
draw_set_alpha(1);
draw_set_halign(fa_left);

/*
//Added for testing purposes!!!
draw_set_alpha(1);
draw_set_font(fontMenuSmall);
draw_set_color(c_white);
//draw_point(x, y);

var tdraw = 6;
draw_text(10, 16, "RandomGameBool: " + string(oControl.mod_randomgamebool));


/* */
/*  */
