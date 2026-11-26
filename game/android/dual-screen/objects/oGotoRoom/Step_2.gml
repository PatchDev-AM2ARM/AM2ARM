if ((direction == 0 || direction == 180) && oCharacter.y <= y + 8 && oCharacter.y > y - height - 8 || (direction == 90 || direction == 270) && oCharacter.x >= x && oCharacter.x < x + height) {
    if (direction == 0 && oCharacter.x > x - 4 && oCharacter.x < x + 16 || direction == 180 && oCharacter.x < x + 4 && oCharacter.x > x - 16 || direction == 90 && oCharacter.y < y + 4 && oCharacter.y > y - 16 || direction == 270 && oCharacter.y > y - 4 && oCharacter.y < y + 16) {
        // Carry the room-authored entrance and camera coordinates through the transition room.
        global.targetx = targetx;
        global.targety = targety;
        global.camstartx = camstartx;
        global.camstarty = camstarty;
        oCamera.x = global.camstartx;
        oCamera.y = global.camstarty;
        // Preserve Samus's offset along the doorway so crossing does not force her to its center.
        if (direction == 0 || direction == 180) {
            global.offsety = oCharacter.y - y;
            global.offsetx = 0;
        }
        if (direction == 90 || direction == 270) {
            global.offsetx = oCharacter.x - x;
            global.offsety = 0;
        }
        global.transitiontype = 1;
        global.transitionx = transitionx + global.offsetx;
        global.transitiony = transitiony + global.offsety;
        with (oCharacter) {
            x -= __view_get( e__VW.XView, 0 );
            y -= __view_get( e__VW.YView, 0 );
            visible = false;
        }
        
        // Widescreen
        if (global.widescreen_enabled) {
            var _target_space = standard_aspect_width(global.opaspectratio) - 320;
            var targetwidth;
            // Edge case rooms
            switch (targetroom) {
                case rm_a3a20: // Zig-zag room
                case rm_a7c01: // Egg room
                case rm_a6b13: // Nest vertical shaft
                case rm_a2a07: targetwidth = 320; break; // Varia
                case rm_a3a01: { // Torizo
                    if (global.event[152] > 0) {
                        targetwidth = ds_map_find_value(oControl.room_width_map, targetroom); // after torizo
                    } else {
                        targetwidth = 320; // before torizo
                    }
                    break;
                }
                default: targetwidth = ds_map_find_value(oControl.room_width_map, targetroom); break;
            }
            
            if (targetwidth > 320) {
                if (targetx <= 320) 
                    global.transitionx -= _target_space/2 - max(0, ((_target_space + 320)) - targetwidth)/2;
                else if (targetx >= targetwidth-320) 
                    global.transitionx += _target_space/2 - max(0, ((_target_space + 320)) - targetwidth)/2;
                else {
                    if(camstartx <= floor(_target_space/2)+160)
                        global.transitionx -= max(0, floor(_target_space/2) - 320);
                    if(camstartx >= abs(floor((_target_space/2)+160) - targetwidth))
                        global.transitionx += max(0, floor(_target_space/2) - 320);
                }
            }
        }
        
        if (global.opaspectratio != oControl.aspect_ratio) oControl.widescreen_switch = true;
        
        oControl.mod_previous_room = room;
        
        room_change(targetroom, 1);
        Mute_Loops();
        StopAmbLoops();
    }
}










/*if ((direction == 0 || direction == 180) && oCharacter.y <= y + 8 && oCharacter.y > y - height - 8 || (direction == 90 || direction == 270) && oCharacter.x >= x && oCharacter.x < x + height) {
    if (direction == 0 && oCharacter.x > x - 4 && oCharacter.x < x + 16 || direction == 180 && oCharacter.x < x + 4 && oCharacter.x > x - 16 || direction == 90 && oCharacter.y < y + 4 && oCharacter.y > y - 16 || direction == 270 && oCharacter.y > y - 4 && oCharacter.y < y + 16) {
        global.targetx = targetx;
        global.targety = targety;
        global.camstartx = camstartx;
        global.camstarty = camstarty;
        oCamera.x = global.camstartx;
        oCamera.y = global.camstarty;
        if (direction == 0 || direction == 180) {
            global.offsety = oCharacter.y - y;
            global.offsetx = 0;
        }
        if (direction == 90 || direction == 270) {
            global.offsetx = oCharacter.x - x;
            global.offsety = 0;
        }
        global.transitiontype = 1;
        global.transitionx = transitionx + global.offsetx;
        global.transitiony = transitiony + global.offsety;
        with (oCharacter) {
            x -= view_xview[0];
            y -= view_yview[0];
            visible = false;
        }
        
        oControl.mod_previous_room = room;
        room_change(targetroom, 1);
        Mute_Loops();
        StopAmbLoops();
    } // if (direction == 0 && oCharacter.x > x - 4 && oCharacter.x < x + 16 || direction == 180 && oCharacter.x < x + 4 && oCharacter.x > x - 16 || direction == 90 && oCharacter.y < y + 4 && oCharacter.y > y - 16 || direction == 270 && oCharacter.y > y - 4 && oCharacter.y < y + 16)
} // if ((direction == 0 || direction == 180) && oCharacter.y <= y + 8 && oCharacter.y > y - height - 8 || (direction == 90 || direction == 270) && oCharacter.x >= x && oCharacter.x < x + height)

/* */
/*  */
