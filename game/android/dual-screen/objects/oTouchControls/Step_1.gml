/// @description  Touch input.
// Sample touches before the Step event combines them with controller input.

// Recompute only when geometry or settings change, before sampling any touches.
if (layout_gui_width != display_get_gui_width() || layout_gui_height != display_get_gui_height()
    || layout_revision != oControl.touch_layout_revision || layout_inset != oControl.touch_inset
    || scale != oControl.touch_scale || layout_aim_balance != oControl.touch_aim_balance) {
    touch_layout_apply();
}

// Settings claim slider drags before a finger can press an overlay button.
if (instance_exists(oOptionsControl)) {
    with (oOptionsControl) touch_options_pointer();
}

// Dual input: touch is never muted by a connected gamepad.
// Touch UI visibility + wake-tap: a touch that BEGINS while the overlay is
// invisible and a pad is latched only reveals the overlay; that device is
// flagged and contributes no input until released. The full-screen
// "Touch to Start" block at the bottom is deliberately exempt.
for (i = 0; i < 5; i += 1) {
    if (device_mouse_check_button_pressed(i, 1)) {
        if (alpha == 0 && global.joydetected == 1) wake_touch[i] = 1;
    }
    if (device_mouse_check_button(i, 1)) {
        alpha = 0.5;
        alarm[0] = 240;
    } else wake_touch[i] = 0;
}


var tx, ty;
joyx = 0;
joyy = 0;
stick_x[0] = gui_x[0];
stick_y[0] = gui_y[0];

if (os_is_paused()) mouse_clear(mb_any);

// Joystick
// Claim a finger inside the movement circle, then keep following it until release.
if (st_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_distance(tx, ty, gui_x[0], gui_y[0]) < st_radius) {
                if (st_pressed[1] != i) {
                    st_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
if (device_mouse_check_button(st_pressed[0], 1)) {
    mx = scr_mouse_gui_x(device_mouse_raw_x(st_pressed[0]));
    my = scr_mouse_gui_y(device_mouse_raw_y(st_pressed[0]));
    vdist = min(st_radius, point_distance(mx, my, gui_x[0], gui_y[0]));
    rdist = vdist / st_radius;
    vdir = point_direction(gui_x[0], gui_y[0], mx, my);
    stick_x[0] = gui_x[0] + lengthdir_x(vdist, vdir);
    stick_y[0] = gui_y[0] + lengthdir_y(vdist, vdir);
    joyx = lengthdir_x(rdist, vdir);
    joyy = lengthdir_y(rdist, vdir);
} else st_pressed[0] = -1;


// Jump
// Buttons keep their assigned finger only while it remains held inside the button.
if (jump_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_rectangle(tx, ty, btn_jump[0], btn_jump[1], btn_jump[2], btn_jump[3])) {
                if (jump_pressed[1] != i) {
                    jump_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
else {
    if (device_mouse_check_button(jump_pressed[0], 1)) {
        tx = scr_mouse_gui_x(device_mouse_raw_x(jump_pressed[0]));
        ty = scr_mouse_gui_y(device_mouse_raw_y(jump_pressed[0]));
        if (!point_in_rectangle(tx, ty, btn_jump[0], btn_jump[1], btn_jump[2], btn_jump[3])) {
            jump_pressed[0] = -1;
        }
    } else jump_pressed[0] = -1;
}


// Fire
if (fire_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_rectangle(tx, ty, btn_fire[0], btn_fire[1], btn_fire[2], btn_fire[3])) {
                if (fire_pressed[1] != i) {
                    fire_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
else {
    if (device_mouse_check_button(fire_pressed[0], 1)) {
        tx = scr_mouse_gui_x(device_mouse_raw_x(fire_pressed[0]));
        ty = scr_mouse_gui_y(device_mouse_raw_y(fire_pressed[0]));
        if (!point_in_rectangle(tx, ty, btn_fire[0], btn_fire[1], btn_fire[2], btn_fire[3])) {
            fire_pressed[0] = -1;
        }
    } else fire_pressed[0] = -1;
}


// Missile
if (missile_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_rectangle(tx, ty, btn_missile[0], btn_missile[1], btn_missile[2], btn_missile[3])) {
                if (missile_pressed[1] != i) {
                    missile_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
else {
    if (device_mouse_check_button(missile_pressed[0], 1)) {
        tx = scr_mouse_gui_x(device_mouse_raw_x(missile_pressed[0]));
        ty = scr_mouse_gui_y(device_mouse_raw_y(missile_pressed[0]));
        if (!point_in_rectangle(tx, ty, btn_missile[0], btn_missile[1], btn_missile[2], btn_missile[3])) {
            missile_pressed[0] = -1;
        }
    } else missile_pressed[0] = -1;
}


// Feed one held Select action to the normal weapon logic; it handles press edges.
if (!touch_weapon_select_available()) {
    weapon_select_pressed = -1;
} else if (weapon_select_pressed == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_rectangle(tx, ty, btn_weapon_select[0], btn_weapon_select[1], btn_weapon_select[2], btn_weapon_select[3])) {
                weapon_select_pressed = i;
                break;
            }
        }
    }
} else if (device_mouse_check_button(weapon_select_pressed, 1)) {
    tx = scr_mouse_gui_x(device_mouse_raw_x(weapon_select_pressed));
    ty = scr_mouse_gui_y(device_mouse_raw_y(weapon_select_pressed));
    if (!point_in_rectangle(tx, ty, btn_weapon_select[0], btn_weapon_select[1], btn_weapon_select[2], btn_weapon_select[3])) {
        weapon_select_pressed = -1;
    }
} else weapon_select_pressed = -1;

// Morph
if (morph_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_rectangle(tx, ty, btn_morph[0], btn_morph[1], btn_morph[2], btn_morph[3])) {
                if (morph_pressed[1] != i) {
                    morph_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
else {
    if (device_mouse_check_button(morph_pressed[0], 1)) {
        tx = scr_mouse_gui_x(device_mouse_raw_x(morph_pressed[0]));
        ty = scr_mouse_gui_y(device_mouse_raw_y(morph_pressed[0]));
        if (!point_in_rectangle(tx, ty, btn_morph[0], btn_morph[1], btn_morph[2], btn_morph[3])) {
            morph_pressed[0] = -1;
        }
    } else morph_pressed[0] = -1;
}


// Pause
if (pause_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_rectangle(tx, ty, btn_pause[0], btn_pause[1], btn_pause[2], btn_pause[3])) {
                if (pause_pressed[1] != i) {
                    pause_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
else {
    if (device_mouse_check_button(pause_pressed[0], 1)) {
        tx = scr_mouse_gui_x(device_mouse_raw_x(pause_pressed[0]));
        ty = scr_mouse_gui_y(device_mouse_raw_y(pause_pressed[0]));
        if (!point_in_rectangle(tx, ty, btn_pause[0], btn_pause[1], btn_pause[2], btn_pause[3])) {
            pause_pressed[0] = -1;
        }
    } else pause_pressed[0] = -1;
}


// Aim up left
// Diagonal aim regions share the movement side, so a held stick or another diagonal blocks a new claim.
if (aimupleft_pressed[0] == -1 && aimdownleft_pressed[0] == -1 && aimupright_pressed[0] == -1 && aimdownright_pressed[0] == -1 && st_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_triangle(tx, ty, btn_aimul[0], btn_aimul[1], btn_aimul[2], btn_aimul[3], btn_aimul[4], btn_aimul[5])) {
                if (aimupleft_pressed[1] != i) {
                    aimupleft_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
if (!device_mouse_check_button(aimupleft_pressed[0], 1) || st_pressed[0] != -1) aimupleft_pressed[0] = -1;


// Aim down left
if (aimupleft_pressed[0] == -1 && aimdownleft_pressed[0] == -1 && aimupright_pressed[0] == -1 && aimdownright_pressed[0] == -1 && st_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_triangle(tx, ty, btn_aimdl[0], btn_aimdl[1], btn_aimdl[2], btn_aimdl[3], btn_aimdl[4], btn_aimdl[5])) {
                if (aimdownleft_pressed[1] != i) {
                    aimdownleft_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
if (!device_mouse_check_button(aimdownleft_pressed[0], 1) || st_pressed[0] != -1) aimdownleft_pressed[0] = -1;


// Aim up right
if (aimupleft_pressed[0] == -1 && aimdownleft_pressed[0] == -1 && aimupright_pressed[0] == -1 && aimdownright_pressed[0] == -1 && st_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_triangle(tx, ty, btn_aimur[0], btn_aimur[1], btn_aimur[2], btn_aimur[3], btn_aimur[4], btn_aimur[5])) {
                if (aimupright_pressed[1] != i) {
                    aimupright_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
if (!device_mouse_check_button(aimupright_pressed[0], 1) || st_pressed[0] != -1) aimupright_pressed[0] = -1;


// Aim down right
if (aimupleft_pressed[0] == -1 && aimdownleft_pressed[0] == -1 && aimupright_pressed[0] == -1 && aimdownright_pressed[0] == -1 && st_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_triangle(tx, ty, btn_aimdr[0], btn_aimdr[1], btn_aimdr[2], btn_aimdr[3], btn_aimdr[4], btn_aimdr[5])) {
                if (aimdownright_pressed[1] != i) {
                    aimdownright_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
if (!device_mouse_check_button(aimdownright_pressed[0], 1) || st_pressed[0] != -1) aimdownright_pressed[0] = -1;


// Aim up
if (up_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_triangle(tx, ty, btn_aimu[0], btn_aimu[1], btn_aimu[2], btn_aimu[3], btn_aimu[4], btn_aimu[5])) {
                if (up_pressed[1] != i) {
                    up_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
else {
    if (device_mouse_check_button(up_pressed[0], 1)) {
        tx = scr_mouse_gui_x(device_mouse_raw_x(up_pressed[0]));
        ty = scr_mouse_gui_y(device_mouse_raw_y(up_pressed[0]));
        if (!point_in_triangle(tx, ty, btn_aimu[0], btn_aimu[1], btn_aimu[2], btn_aimu[3], btn_aimu[4], btn_aimu[5])) {
            up_pressed[0] = -1;
        }
    } else up_pressed[0] = -1;
}


// Aim down
if (down_pressed[0] == -1) {
    for (i = 0; i < 5; i += 1) {
        if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(i));
            ty = scr_mouse_gui_y(device_mouse_raw_y(i));
            if (point_in_triangle(tx, ty, btn_aimd[0], btn_aimd[1], btn_aimd[2], btn_aimd[3], btn_aimd[4], btn_aimd[5])) {
                if (down_pressed[1] != i) {
                    down_pressed[0] = i;
                    break;
                }
            }
        }
    }
}
else {
    if (device_mouse_check_button(down_pressed[0], 1)) {
        tx = scr_mouse_gui_x(device_mouse_raw_x(down_pressed[0]));
        ty = scr_mouse_gui_y(device_mouse_raw_y(down_pressed[0]));
        if (!point_in_triangle(tx, ty, btn_aimd[0], btn_aimd[1], btn_aimd[2], btn_aimd[3], btn_aimd[4], btn_aimd[5])) {
            down_pressed[0] = -1;
        }
    } else down_pressed[0] = -1;
}

if(!global.ingame) {
    // Menu right
    if (right_pressed[0] == -1) {
        for (i = 0; i < 5; i += 1) {
            if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
                tx = scr_mouse_gui_x(device_mouse_raw_x(i));
                ty = scr_mouse_gui_y(device_mouse_raw_y(i));
                if (point_in_triangle(tx, ty, btn_aimr[0], btn_aimr[1], btn_aimr[2], btn_aimr[3], btn_aimr[4], btn_aimr[5])) {
                    if (right_pressed[1] != i) {
                        right_pressed[0] = i;
                        break;
                    }
                }
            }
        }
    }
    else {
        if (device_mouse_check_button(right_pressed[0], 1)) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(right_pressed[0]));
            ty = scr_mouse_gui_y(device_mouse_raw_y(right_pressed[0]));
            if (!point_in_triangle(tx, ty, btn_aimr[0], btn_aimr[1], btn_aimr[2], btn_aimr[3], btn_aimr[4], btn_aimr[5])) {
                right_pressed[0] = -1;
            }
        } else right_pressed[0] = -1;
    }
    
    // Menu left
    if (left_pressed[0] == -1) {
        for (i = 0; i < 5; i += 1) {
            if (device_mouse_check_button(i, 1) && !wake_touch[i]) {
                tx = scr_mouse_gui_x(device_mouse_raw_x(i));
                ty = scr_mouse_gui_y(device_mouse_raw_y(i));
                if (point_in_triangle(tx, ty, btn_aiml[0], btn_aiml[1], btn_aiml[2], btn_aiml[3], btn_aiml[4], btn_aiml[5])) {
                    if (left_pressed[1] != i) {
                        left_pressed[0] = i;
                        break;
                    }
                }
            }
        }
    }
    else {
        if (device_mouse_check_button(left_pressed[0], 1)) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(left_pressed[0]));
            ty = scr_mouse_gui_y(device_mouse_raw_y(left_pressed[0]));
            if (!point_in_triangle(tx, ty, btn_aiml[0], btn_aiml[1], btn_aiml[2], btn_aiml[3], btn_aiml[4], btn_aiml[5])) {
                left_pressed[0] = -1;
            }
        } else left_pressed[0] = -1;
    }
}
else {
    right_pressed[0] = -1;
    right_pressed[1] = -1;
    
    left_pressed[0] = -1;
    left_pressed[1] = -1;
}

if (global.gamestarted == 0 || room == gameintroroom || room == rm_credits) {
    // Touch to Start
    if (pause_pressed[0] == -1) {
        for (i = 0; i < 5; i += 1) {
            if (device_mouse_check_button(i, 1)) {
                tx = scr_mouse_gui_x(device_mouse_raw_x(i));
                ty = scr_mouse_gui_y(device_mouse_raw_y(i));
                if (point_in_rectangle(tx, ty, 0, 0, display_get_width(), display_get_height())) {
                    if (pause_pressed[1] != i) {
                        pause_pressed[0] = i;
                        break;
                    }
                }
            }
        }
    }
    else {
        if (device_mouse_check_button(pause_pressed[0], 1)) {
            tx = scr_mouse_gui_x(device_mouse_raw_x(pause_pressed[0]));
            ty = scr_mouse_gui_y(device_mouse_raw_y(pause_pressed[0]));
            if (!point_in_rectangle(tx, ty, 0, 0, display_get_width(), display_get_width())) {
                pause_pressed[0] = -1;
            }
        } else pause_pressed[0] = -1;
    }
}

