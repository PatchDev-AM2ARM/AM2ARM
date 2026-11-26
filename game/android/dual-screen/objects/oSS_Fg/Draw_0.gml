if (oControl.dual_enabled && instance_exists(oSubScrChange)) {
    // Keep the same frame when switching between the selector and its pages.
    var _x = __view_get(e__VW.XView, 0), _y = __view_get(e__VW.YView, 0);
    draw_background_ext(bg_SubScrBottom, _x, _y + 30 - rectoffset, 10, 1, 0, c_white, ealpha);
    draw_background_ext(bg_SubScrBottom, _x, _y + 198 + rectoffset, 10, 1, 0, c_white, ealpha);
    exit;
}
draw_set_color(c_black);
draw_set_alpha(1);
draw_rectangle(__view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ), __view_get( e__VW.XView, 0 ) + 330 + (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 41 - rectoffset, false);
draw_rectangle(__view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 198 + rectoffset, __view_get( e__VW.XView, 0 ) + 330 + (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 250, false);
if (global.ssmode == 0) { // MAP
    if (oControl.mod_collecteditemsmap == 1 && itemcollunlock) ///Grafh78
    {
        if (widescreen) { // bar extension
            draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - 64, __view_get( e__VW.YView, 0 ) + 210 + rectoffset, 2, 1, 0, -1, ealpha);
            draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) + 320, __view_get( e__VW.YView, 0 ) + 210 + rectoffset, 2, 1, 0, -1, ealpha);
        }    
        draw_background_ext(scr_SubScrTop_swap(), __view_get( e__VW.XView, 0 ), __view_get( e__VW.YView, 0 ) + 210 + rectoffset, 1, 1, 0, -1, ealpha);
    }
    // top green bar
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 30 - rectoffset, 10 + (4*widescreen), 1, 0, -1, ealpha);
    if (widescreen) { // bottom infobar extension
        draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - 64, __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 2, 1, 0, -1, ealpha);
        draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) + 320, __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 2, 1, 0, -1, ealpha);
    }
    if (oControl.mod_percentofitems == 1) { // map bottom infobar
        draw_background_ext(bg_MapBottom2, __view_get( e__VW.XView, 0 ), __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 1, 1, 0, -1, ealpha); 
    } else { 
        draw_background_ext(bg_MapBottom, __view_get( e__VW.XView, 0 ), __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 1, 1, 0, -1, ealpha); 
    }
    draw_set_alpha(ealpha);
    draw_set_font(fontGUI2);
    draw_set_halign(fa_center);
    draw_set_color(c_black);
    draw_text(__view_get( e__VW.XView, 0 ) + 161, __view_get( e__VW.YView, 0 ) + 30 - rectoffset, string_hash_to_newline(maptext));
    draw_set_color(c_white);
    draw_text(__view_get( e__VW.XView, 0 ) + 160, __view_get( e__VW.YView, 0 ) + 29 - rectoffset, string_hash_to_newline(maptext));
    draw_set_halign(fa_left);
    if (hidetext == 0) {
        draw_set_color(c_black);
        draw_text(__view_get( e__VW.XView, 0 ) + 18, __view_get( e__VW.YView, 0 ) + 198 + rectoffset, string_hash_to_newline(timetext));
        //if (oControl.mod_percentofitems == 1) { draw_text(view_xview[0] + 214, view_yview[0] + 198 + rectoffset, string("100%")); }
        if (oControl.mod_percentofitems == 1) { draw_text(__view_get( e__VW.XView, 0 ) + 215, __view_get( e__VW.YView, 0 ) + 198 + rectoffset, string_hash_to_newline(string(round(global.itemstaken / 88 * 100)) + "%")); }
        draw_text(__view_get( e__VW.XView, 0 ) + 260, __view_get( e__VW.YView, 0 ) + 198 + rectoffset, string_hash_to_newline(metrtext1));
        draw_text(__view_get( e__VW.XView, 0 ) + 304, __view_get( e__VW.YView, 0 ) + 198 + rectoffset, string_hash_to_newline(metrtext2));
        if (oControl.mod_collecteditemsmap == 1 && itemcollunlock) ///Grafh78
        {
            draw_text(__view_get( e__VW.XView, 0 ) + 19, __view_get( e__VW.YView, 0 ) + 210 + rectoffset, string_hash_to_newline(string(global.etanks) + "/10"));
            draw_text(__view_get( e__VW.XView, 0 ) + 129, __view_get( e__VW.YView, 0 ) + 210 + rectoffset, string_hash_to_newline(string(global.mtanks) + "/44"));
            if (global.stanks > 0) draw_text(__view_get( e__VW.XView, 0 ) + 211, __view_get( e__VW.YView, 0 ) + 210 + rectoffset, string_hash_to_newline(string(global.stanks) + "/10"));
            if (global.ptanks > 0) draw_text(__view_get( e__VW.XView, 0 ) + 275, __view_get( e__VW.YView, 0 ) + 210 + rectoffset, string_hash_to_newline(string(global.ptanks) + "/10"));
        } 
        draw_set_color(c_white);
        draw_text(__view_get( e__VW.XView, 0 ) + 17, __view_get( e__VW.YView, 0 ) + 197 + rectoffset, string_hash_to_newline(timetext));
        //if (oControl.mod_percentofitems == 1) { draw_text(view_xview[0] + 213, view_yview[0] + 197 + rectoffset, string("100%")); }
        if (oControl.mod_percentofitems == 1) { draw_text(__view_get( e__VW.XView, 0 ) + 214, __view_get( e__VW.YView, 0 ) + 197 + rectoffset, string_hash_to_newline(string(round(global.itemstaken / 88 * 100)) + "%")); }
        draw_text(__view_get( e__VW.XView, 0 ) + 259, __view_get( e__VW.YView, 0 ) + 197 + rectoffset, string_hash_to_newline(metrtext1));
        draw_text(__view_get( e__VW.XView, 0 ) + 303, __view_get( e__VW.YView, 0 ) + 197 + rectoffset, string_hash_to_newline(metrtext2));
        if (oControl.mod_collecteditemsmap == 1 && itemcollunlock) ///Grafh78
        {
        draw_text(__view_get( e__VW.XView, 0 ) + 18, __view_get( e__VW.YView, 0 ) + 209 + rectoffset, string_hash_to_newline(string(global.etanks) + "/10"));
        draw_text(__view_get( e__VW.XView, 0 ) + 128, __view_get( e__VW.YView, 0 ) + 209 + rectoffset, string_hash_to_newline(string(global.mtanks) + "/44"));
            if (global.stanks > 0) draw_text(__view_get( e__VW.XView, 0 ) + 210, __view_get( e__VW.YView, 0 ) + 209 + rectoffset, string_hash_to_newline(string(global.stanks) + "/10"));
            if (global.ptanks > 0) draw_text(__view_get( e__VW.XView, 0 ) + 274, __view_get( e__VW.YView, 0 ) + 209 + rectoffset, string_hash_to_newline(string(global.ptanks) + "/10"));
        }
        draw_set_font(fontMenuSmall2);
        if (!oControl.dual_enabled && oMapCursor.state == 0)
        {
            draw_txt_1button(__view_get( e__VW.XView, 0 ) + 2, __view_get( e__VW.YView, 0 ) + 225 + rectoffset, tip2text, 1, "Menu1", ealpha);
            if (itemcollunlock) draw_txt_1button(__view_get( e__VW.XView, 0 ) + 125, __view_get( e__VW.YView, 0 ) + 225 + rectoffset, tip6text, 1, "Missile", ealpha);
        }
        if (!oControl.dual_enabled && oMapCursor.state == 1)
        {
            if (oControl.mod_collecteditemsmap == 1 && itemcollunlock) ///Grafh78
            {
               draw_set_color(c_black);
               draw_set_alpha(1);
               draw_rectangle(__view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 212 + rectoffset, __view_get( e__VW.XView, 0 ) + 330 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 232 + rectoffset, false);
            }
            draw_txt_1button(__view_get( e__VW.XView, 0 ) + 2, __view_get( e__VW.YView, 0 ) + 212 + rectoffset, tip3text, 1, "DPad", ealpha);
            draw_txt_1button(__view_get( e__VW.XView, 0 ) + 2, __view_get( e__VW.YView, 0 ) + 225 + rectoffset, tip4text, 1, "Menu2", ealpha);
        }
        if (!oControl.dual_enabled && oMapCursor.state == 2)
        {
            draw_txt_1button(__view_get( e__VW.XView, 0 ) + 2, __view_get( e__VW.YView, 0 ) + 225 + rectoffset, tip5text, 1, "Menu1", ealpha);
            if (itemcollunlock) draw_txt_1button(__view_get( e__VW.XView, 0 ) + 125, __view_get( e__VW.YView, 0 ) + 225 + rectoffset, tip6text, 1, "Missile", ealpha);
        }
        
    }
} // if (global.ssmode == 0)
if (global.ssmode == 1) { // Equipment?
    // Offset the equipment HUD into the lower page's cropped margin before drawing its health and ammo strip.
    var _hud_x = oControl.dual_enabled ? 5 : 0;
    if (widescreen == 1) { // bar extension
        draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - 64, __view_get( e__VW.YView, 0 ) + 30 - rectoffset, 2, 1, 0, -1, ealpha);
        draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) + 320, __view_get( e__VW.YView, 0 ) + 30 - rectoffset, 2, 1, 0, -1, ealpha);
    }
    //draw_background_ext(bg_SubScrBottom, 0, 198 + rectoffset, 10, 1, 0, -1, ealpha);
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 10 + (4*widescreen), 1, 0, -1, ealpha);
    draw_set_alpha(ealpha);
    draw_txt_1button(__view_get( e__VW.XView, 0 ) + 160, __view_get( e__VW.YView, 0 ) + 196 + rectoffset, oSubscreenMenu.dtext, 0, "Fire", ealpha);
    if (oControl.dual_enabled) {
        dual_draw_equipment_status(_hud_x, 27 - rectoffset, 310);
    } else {
        draw_background_ext(scr_SubScrTop_swap(), _hud_x, 30 - rectoffset, 1, 1, 0, -1, ealpha);
        draw_set_font(fontGUI2);
        draw_set_color(c_black);
        //19, 129, 211, 275
        //18, 128, 210, 274
        draw_text(20, 30 - rectoffset, string_hash_to_newline(string(ceil(global.playerhealth)) + "/" + string(global.maxhealth)));
        draw_text(_hud_x + global.percent1M, 30 - rectoffset, string_hash_to_newline(string(global.missiles) + "/" + string(global.maxmissiles)));
        if (global.stanks > 0) draw_text(_hud_x + global.percent1SM, 30 - rectoffset, string_hash_to_newline(string(global.smissiles) + "/" + string(global.maxsmissiles)));
        if (global.ptanks > 0) draw_text(_hud_x + global.percent1PB, 30 - rectoffset, string_hash_to_newline(string(global.pbombs) + "/" + string(global.maxpbombs)));
        draw_set_color(c_white);
        draw_text(19, 29 - rectoffset, string_hash_to_newline(string(ceil(global.playerhealth)) + "/" + string(global.maxhealth)));
        draw_text(_hud_x + global.percent2M, 29 - rectoffset, string_hash_to_newline(string(global.missiles) + "/" + string(global.maxmissiles)));
        if (global.stanks > 0) draw_text(_hud_x + global.percent2SM, 29 - rectoffset, string_hash_to_newline(string(global.smissiles) + "/" + string(global.maxsmissiles)));
        if (global.ptanks > 0) draw_text(_hud_x + global.percent2PB, 29 - rectoffset, string_hash_to_newline(string(global.pbombs) + "/" + string(global.maxpbombs)));
    }

    if (hidetext == 0) {
        // Keep the selection hint below the equipment list and above the
        // description, clear of the native buttons on a 240px panel.
        var _item_help_y = oControl.dual_enabled ? 181 : 212;
        draw_background(bg_SubScrTipArrow1, __view_get( e__VW.XView, 0 ) + _hud_x + 2, __view_get( e__VW.YView, 0 ) + _item_help_y + 5 + rectoffset);
        draw_set_font(fontMenuSmall2);
        draw_set_color(c_white);
        draw_text(__view_get( e__VW.XView, 0 ) + _hud_x + 25, __view_get( e__VW.YView, 0 ) + _item_help_y + rectoffset, string_hash_to_newline(etiptext1));
        if (!oControl.dual_enabled) draw_txt_1button(__view_get( e__VW.XView, 0 ) + 2, __view_get( e__VW.YView, 0 ) + 225 + rectoffset, etiptext2, 1, "Menu1", ealpha);
        }
}
if (global.ssmode == 2) { // Logs
    //draw_background_ext(bg_SubScrBottom, view_xview[0], view_yview[0] + 30 - rectoffset, 10, 1, 0, -1, ealpha);
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 30 - rectoffset, 10 + (4*widescreen), 1, 0, -1, ealpha);
    //draw_background_ext(bg_SubScrBottom, view_xview[0], view_yview[0] + 198 + rectoffset, 10, 1, 0, -1, ealpha);
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 10 + (4*widescreen), 1, 0, -1, ealpha);
    draw_set_alpha(ealpha);
    draw_set_font(fontGUI2);
    draw_set_halign(fa_center);
    draw_set_color(c_black);
    draw_text(__view_get( e__VW.XView, 0 ) + 161, __view_get( e__VW.YView, 0 ) + 30 - rectoffset, string_hash_to_newline(logtitle));
    draw_set_color(c_white);
    draw_text(__view_get( e__VW.XView, 0 ) + 160, __view_get( e__VW.YView, 0 ) + 29 - rectoffset, string_hash_to_newline(logtitle));
    draw_set_halign(fa_left);
    if (hidetext == 0) {
        draw_set_font(fontMenuSmall2);
        draw_set_color(c_white);
    }
}
if (global.ssmode == 3) { // Options
    // draw_background_ext(bg_SubScrBottom, view_xview[0], view_yview[0] + 30 - rectoffset, 10, 1, 0, -1, ealpha);
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 30 - rectoffset, 10 + (4*widescreen), 1, 0, -1, ealpha);
    // draw_background_ext(bg_SubScrBottom, view_xview[0], view_yview[0] + 198 + rectoffset, 10, 1, 0, -1, ealpha);
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ) - (widescreen_space/2), __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 10 + (4*widescreen), 1, 0, -1, ealpha);
    draw_set_alpha(ealpha);
    draw_set_font(fontGUI2);
    draw_set_halign(fa_center);
    draw_set_color(c_black);
    draw_text(__view_get( e__VW.XView, 0 ) + 161, __view_get( e__VW.YView, 0 ) + 30 - rectoffset, string_hash_to_newline(opt_text1));
    draw_set_color(c_white);
    draw_text(__view_get( e__VW.XView, 0 ) + 160, __view_get( e__VW.YView, 0 ) + 29 - rectoffset, string_hash_to_newline(opt_text1));
    draw_set_halign(fa_left);
    draw_set_alpha(ealpha);
    port_help_top = rectoffset + port_draw_pause_help(__view_get(e__VW.XView, 0),
        __view_get(e__VW.YView, 0) + rectoffset, 212);
}
if (!oControl.dual_enabled && hidechangetip == 0 && hidetext == 0 && oSS_Control.canchange) {
    draw_set_font(fontMenuSmall2);
    draw_set_color(c_white);
    draw_txt_1button(__view_get( e__VW.XView, 0 ) + 318, __view_get( e__VW.YView, 0 ) + 225 + rectoffset, tip1text, 2, "Menu2", ealpha);
}
// Cover page text during the selector transition while leaving its moving frame visible.
if (hidetext) {
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ), __view_get( e__VW.YView, 0 ) + 30 - rectoffset, 10, 1, 0, -1, ealpha);
    draw_background_ext(bg_SubScrBottom, __view_get( e__VW.XView, 0 ), __view_get( e__VW.YView, 0 ) + 198 + rectoffset, 10, 1, 0, -1, ealpha);
    if (oControl.mod_collecteditemsmap == 1 && itemcollunlock) ///Grafh78
    {    
        draw_set_color(c_black);
        draw_set_alpha(1);
        draw_rectangle(__view_get( e__VW.XView, 0 ) - (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 212 + rectoffset, __view_get( e__VW.XView, 0 ) + 330 + (oControl.widescreen_space/2), __view_get( e__VW.YView, 0 ) + 232 + rectoffset, false);
    }
}
