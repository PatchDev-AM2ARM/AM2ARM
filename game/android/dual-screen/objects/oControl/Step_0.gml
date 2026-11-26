// Advance the simulation-step counter used to keep a shared fade from advancing once per camera draw.
dual_steps++;
dual_layout_update();
//
// Release the captured transition frame once the normal room fade has finished.
if (fadedone >= 1 && room != rm_transition && room != rm_subscreen && room != itemroom && room != rm_death) {
    dual_keep_room_map = false;
    global.transitiontype = 0;
    event_user(4);
}
//
if (!init) {
    if (os_type == os_linux) {
        linux_keys();
    } else if (os_type == os_android) {
        touch_keys();
        if (!global.android_app) {
            // Use the controller's physical controls even if the player remaps pause.
            var _pad = global.opjoyid;
            var _held = gamepad_is_connected(_pad) && gamepad_button_check(_pad, gp_start) && gamepad_button_check(_pad, gp_select);
            if (!_held) quit_chord_since = -1;
            else if (quit_chord_since < 0) quit_chord_since = current_time;
            else if (current_time - quit_chord_since >= 1000) {
                game_end();
                exit;
            }
        }
    } else { // windows, any other weird platforms
        check_keys();
    }
    // Merge lower-screen actions into raw input before pressed and held menu states are computed.
    dual_input();
    frontend_back();
    if (room != rm_transition) global_control();
    if (dual_setup_needed) dual_setup_step();
    else {
        if (kExit && global.opexitkeyenable) game_end();
        if (kStart && kStartPushedSteps == 0) event_user(0);
    }
}
//
if (global.ingame == 1) {
    if (malpha > -1) malpha -= 0.02;
    if (malpha <= 0) malpha = 1;
    markfr += 0.25;
    if (markfr > 4) markfr = 0;
    global.roomtime += 1;
    //
    // Choose a low-health warning level for the repeating health alarm to use.
    hpalarm = 0;
    if (true)
    {
        if (global.maxhealth < 100)
        {
            //if (global.playerhealth < 50) hpalarm = 1;
            if (global.playerhealth < 30) hpalarm = 2;
            if (global.playerhealth < 10) hpalarm = 3;
        }
        else if (global.maxhealth < 500)
        {
            if (global.playerhealth < 50) hpalarm = 1;
            if (global.playerhealth < 30) hpalarm = 2;
            if (global.playerhealth < 10) hpalarm = 3;
        }
        else
        {
            if (global.playerhealth < 100) hpalarm = 1;
            if (global.playerhealth < 50) hpalarm = 2;
            if (global.playerhealth < 25) hpalarm = 3;
        }
    }
    else
    {
        if (global.maxhealth == 99) {
            if (global.playerhealth < 50) hpalarm = 1;
            if (global.playerhealth < 30) hpalarm = 2;
            if (global.playerhealth < 10) hpalarm = 3;
        } else if (global.maxhealth > 99) {
            if (global.playerhealth < 100) hpalarm = 1;
            if (global.playerhealth < 60) hpalarm = 2;
            if (global.playerhealth < 20) hpalarm = 3;
        }
    }
    //
    if (hudflash > 0) {
        hudflash -= 1;
        if (hudflashfx > 0) {
            hudflashfx -= 1;
        } else hudflashfx = 4;
    }
}
// view:
// Keep the base game view at its native size before computing its position and scale in the window.
control_view_dimensions();
/*view_wport[0] = 640;
view_wview[0] = 640;
view_hport[0] = 480;
view_hview[0] = 480;*/
// display offset:
var _display_window_width = window_get_width();
var _display_window_height = window_get_height();
// Android uses the drawable window directly. Avoid calculating the desktop
// fullscreen layout first, only to replace it with the Android result.
if (os_type == os_android) {
    display_scale = android_display_scale_for_window(320 + widescreen_space, 240,
        _display_window_width, _display_window_height);
    displayx = (_display_window_width - (320 + widescreen_space) * display_scale) / 2;
    displayy = (_display_window_height - 240 * display_scale) / 2;
} else {
    if (window_get_fullscreen()) {
        if (global.opscale == 0) {
            if (!widescreen) {
                if (display_get_height() < display_get_width()) {
                    display_scale = display_get_height() / 240;
                } else display_scale = display_get_width() / (320);
            } else {
                
                if (((display_get_width() / (320 + widescreen_space)) * 240) <= display_get_height()) {
                    display_scale = display_get_width() / (320 + widescreen_space);
                }
                else display_scale = display_get_height() / 240;
            }
        } else display_scale = global.opscale;
    
        //displayx = display_get_width() / 2 - 320 * display_scale / 2;
        //displayy = display_get_height() / 2 - 240 * display_scale / 2;
        displayx = display_get_width() / 2 - (320 + widescreen_space) * display_scale / 2;
        displayy = display_get_height() / 2 - 240 * display_scale / 2;
    } else {
        if (_display_window_height < _display_window_width) {
            display_scale = _display_window_height / 240;
        } else display_scale = _display_window_width / (320 + widescreen_space);
        //displayx = _display_window_width / 2 - 320 * display_scale / 2;
        //displayy = _display_window_height / 2 - 240 * display_scale / 2;
        displayx = _display_window_width / 2 - (320 + widescreen_space) * display_scale / 2;
        displayy = _display_window_height / 2 - 240 * display_scale / 2;
    }
    if (global.oppixelperfect) {
        display_scale = max(1, floor(display_scale));
        displayx = display_get_width() / 2 - (320 + widescreen_space) * display_scale / 2;
        displayy = display_get_height() / 2 - 240 * display_scale / 2;
    }
}
displayx = round(displayx);
displayy = round(displayy);
// GM2026 parity: the Draw GUI canvas defaults to the APPLICATION SURFACE size (320x240
// here), not window pixels like GMS1.4 — so the HUD composite below rendered into a tiny
// canvas and showed only its blown-up top-left corner (giant blurry "99"). Pin the GUI
// canvas to real window pixels when needed (also repairs temporary GUI overrides).
control_gui_dimensions(_display_window_width, _display_window_height);
// Recreate the upper overlay when its width changes, then draw health and ammo on the chosen display.
if (surface_exists(gui_surface)) { // fix for widescreen HUD issues on boot
    if (surface_get_width(gui_surface) != (320 + widescreen_space)) surface_free(gui_surface);
}
if (!surface_exists(gui_surface)) {
    gui_surface = surface_create(320 + widescreen_space, 240);
    nano_render_hud_key = [];
}
if (surface_exists(gui_surface) && nano_render_hud_redraw()) {
    surface_set_target(gui_surface);
    draw_clear_alpha(c_black, 0);
    if ((!dual_enabled || dual_hud_top) && global.ingame && displaygui && instance_exists(oCharacter)) {
        draw_gui(dual_enabled);
        // debug room drawing for widescreen debug
        /*if (global.opshowhud && instance_exists(oTestKeys)) { 
            draw_set_font(fontMenuSmall);
            draw_text(4, 24, room_get_name(room));
        }*/
    }
    surface_reset_target();
}

if (debug > 0) {
    global.playerhealth = global.maxhealth;
    global.missiles = 99;
    global.smissiles = 99;
    global.pbombs = 99;
}
//
if (black > 0) black -= 1;
// a workaround for Alt getting stuck on Alt+Tab:
if (os_is_paused()) keyboard_clear(vk_alt);
// on HTML5, keep the game in center of the tab:
if (os_is_browser) set_fullscreen(global.opfullscreen);

//Translator Test Room
/*if(global.ingame && oControl.mod_debugRoom == 1) {
switch translatestep
{
    case 0:
        if keyboard_check(ord('T')) { translatestep++; }
        break;
    case 1:
        if keyboard_check(ord('R')) { translatestep++; }
        break;
    case 2:
        if keyboard_check(ord('A')) { translatestep++; }
        break;
    case 3:
        if keyboard_check(ord('N')) { translatestep++; }
        break;
    case 4:
        if keyboard_check(ord('S')) { translatestep++; }
        break;
    case 5:
        if keyboard_check(ord('L')) { translatestep++; }
        break;
    case 6:
        if keyboard_check(ord('A')) { translatestep++; }
        break;
    case 7:
        if keyboard_check(ord('T')) { translatestep++; }
        break;
    case 8:
        if keyboard_check(ord('E')) { translatestep++; }
        break;
    case 9:
        if keyboard_check(ord('5')) { translatestep++; }
        break;
    case 10:
        if keyboard_check(ord('7')) { translatestep++; }
        break;
    case 11:
        if keyboard_check(ord('4')) 
        {
            translatestep++; 
            global.targetx = 64;
            global.targety = 1168;
            global.camstartx = 90;
            global.camstarty = 64;
            global.offsetx = 0;
            global.offsety = 0;
            room_goto(rm_TranslationTest);
        }
        break;
    default:
        translatestep = 0;
        break;
}
}
*/
if(!dual_enabled && instance_exists(oCharacter) && mod_IGT && !instance_exists(oIGT)) {
    instance_create(0, 0, oIGT);
}

/* */
/*  */

// Sync queued saves after normal updates, never during initialization.
if (!init) save_sync_step();
