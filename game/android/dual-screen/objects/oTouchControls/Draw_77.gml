/// @description  Draw on-screen controls.

if(global.gamestarted == 0 || room == rm_credits || room == rm_score || room == rm_death || room == gameintroroom) exit;

var _layout_preview = instance_exists(oOptionsControl) && (global.curropt >= 9 && global.curropt <= 11);
if (draw == 1 && (alpha != 0 || _layout_preview)) {
    if (_layout_preview) alpha = 0.5;
    // Scale the original artwork once at the current output resolution.
    var _art_scale = buttonScale;
    var _filter = gpu_get_texfilter();
    gpu_set_texfilter(true);
    draw_set_color(c_white);
    draw_set_alpha(alpha);
    
    draw_set_circle_precision(64);
    
    if(global.ingame || room == rm_subscreen || room == rm_secretEnding) {
        draw_sprite_ext(sTouchButtonPause, 0, btn_pause_x, btn_pausearrow_y, pauseScale, pauseScale, 0, c_white, alpha/3);
        draw_roundrect_ext(btn_pause[0], btn_pause[1], btn_pause[2], btn_pause[3], 30, 30, 1); 
    }
    
    if (room != rm_secretEnding) {
        // Jump
        draw_roundrect(btn_jump[0], btn_jump[1], btn_jump[2], btn_jump[3], true);
        
        // Fire
        draw_roundrect(btn_fire[0], btn_fire[1], btn_fire[2], btn_fire[3], true);
        
        draw_sprite_ext(sTouchButtonX, 0, mean(btn_fire[0], btn_fire[2]), mean(btn_fire[1], btn_fire[3]), _art_scale, _art_scale, 0, c_white, alpha/3);
        draw_sprite_ext(sTouchButtonS, 0, mean(btn_jump[0], btn_jump[2]), mean(btn_jump[1], btn_jump[3]), _art_scale, _art_scale, 0, c_white, alpha/3);
        
        draw_circle(gui_x[0], gui_y[0], st_radius, 1);
        
        if (instance_exists(oSS_Fg) && global.ssmode == 0 && oSS_Fg.hidetext == 0 && oSS_Fg.itemcollunlock) {
            draw_roundrect(btn_missile[0], btn_missile[1], btn_missile[2], btn_missile[3], true);
            draw_sprite_ext(sTouchButtonT, 0, mean(btn_missile[0], btn_missile[2]), mean(btn_missile[1], btn_missile[3]), _art_scale, _art_scale, 0, c_white, alpha/3);
        }
        
        if (global.ingame || room == itemroom || _layout_preview) {
            // Up Left
            draw_triangle(btn_aimul[0], btn_aimul[1], btn_aimul[2], btn_aimul[3], btn_aimul[4], btn_aimul[5], 1);
            // Down Left
            if (global.opaimstyle) draw_triangle(btn_aimdl[0], btn_aimdl[1], btn_aimdl[2], btn_aimdl[3], btn_aimdl[4], btn_aimdl[5], 1);
            // Up Right
            draw_triangle(btn_aimur[0], btn_aimur[1], btn_aimur[2], btn_aimur[3], btn_aimur[4], btn_aimur[5], 1);
            // Down Right
            if (global.opaimstyle) draw_triangle(btn_aimdr[0], btn_aimdr[1], btn_aimdr[2], btn_aimdr[3], btn_aimdr[4], btn_aimdr[5], 1);
            
            // Missile
            draw_roundrect(btn_missile[0], btn_missile[1], btn_missile[2], btn_missile[3], true);
            
            //Morph
            draw_roundrect(btn_morph[0], btn_morph[1], btn_morph[2], btn_morph[3], true);
            
            draw_sprite_ext(sTouchButtonT, 0, mean(btn_missile[0], btn_missile[2]), mean(btn_missile[1], btn_missile[3]), _art_scale, _art_scale, 0, c_white, alpha/3);
            draw_sprite_ext(sTouchButtonC, 0, mean(btn_morph[0], btn_morph[2]), mean(btn_morph[1], btn_morph[3]), _art_scale, _art_scale, 0, c_white, alpha/3);

            // Label the Hold-only selector using the existing localized control name.
            if (touch_weapon_select_available()) {
                if (weapon_select_language != global.currentlanguage) {
                    weapon_select_language = global.currentlanguage;
                    weapon_select_label = get_text("OptionsControlCommands", "WeaponSelect");
                }
                draw_roundrect(btn_weapon_select[0], btn_weapon_select[1], btn_weapon_select[2], btn_weapon_select[3], true);
                var _font = draw_get_font(), _ha = draw_get_halign(), _va = draw_get_valign();
                draw_set_font(fontMenuSmall);
                draw_set_halign(fa_center);
                draw_set_valign(fa_middle);
                var _size = min((btn_weapon_select[2] - btn_weapon_select[0]) * 0.85 / max(1, string_width(weapon_select_label)),
                    (btn_weapon_select[3] - btn_weapon_select[1]) * 0.5 / max(1, string_height(weapon_select_label)));
                draw_text_transformed(mean(btn_weapon_select[0], btn_weapon_select[2]), mean(btn_weapon_select[1], btn_weapon_select[3]),
                    weapon_select_label, _size, _size, 0);
                draw_set_font(_font);
                draw_set_halign(_ha);
                draw_set_valign(_va);
            }
            
            draw_set_alpha(alpha/3);   
            draw_circle(stick_x[0], stick_y[0], min(50, st_radius * 0.4), 0);
        }
        else {
            draw_set_alpha(alpha/3); 
            // Up  
            draw_triangle(btn_uparrow[0], btn_uparrow[1], btn_uparrow[2], btn_uparrow[3], btn_uparrow[4], btn_uparrow[5], 0);
            // Down
            draw_triangle(btn_downarrow[0], btn_downarrow[1], btn_downarrow[2], btn_downarrow[3], btn_downarrow[4], btn_downarrow[5], 0);
            // Left
            draw_triangle(btn_leftarrow[0], btn_leftarrow[1], btn_leftarrow[2], btn_leftarrow[3], btn_leftarrow[4], btn_leftarrow[5], 0);
            // Right
            draw_triangle(btn_rightarrow[0], btn_rightarrow[1], btn_rightarrow[2], btn_rightarrow[3], btn_rightarrow[4], btn_rightarrow[5], 0);
        }
    }
    
    draw_set_alpha(1);
    gpu_set_texfilter(_filter);
}

