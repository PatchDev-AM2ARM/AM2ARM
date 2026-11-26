// Keep the original pause UI in its 4:3 layout on the lower screen.
if (oControl.dual_enabled) with (oControl) dual_pause_begin();
// Choose the initial pause page from pending log or lower-toolbar requests before creating its objects.
if (global.gotolog > -1 && global.ophudshowlogmsg == 1) global.ssmode = 2;
if (oControl.dual_enabled && oControl.dual_pending_action == 1) global.ssmode = 0;
// Only the fallback path needs a separate pause-map surface; the dual-screen map remains in oControl.
s_map = -1;
if (!oControl.dual_enabled) {
s_map = surface_create(2048, 1024);
surface_set_target(s_map);
draw_surface_map();
surface_reset_target();
}

// Create the shared pause frame and selected page, then schedule activation for the next alarm.
instance_create(0, 0, oSS_Bg);
instance_create(0, 0, oSS_Fg);
event_user(1);
active = 0;
alarm[0] = 1;
canchange = 1;

modeindex = 0;
if (global.gamemode == 3) modeindex = get_text("Title-Additions", "GameSlot_NewGame_ClassicMode");
if (global.gamemode == 4) modeindex = get_text("Title-Additions", "GameSlot_NewGame_AM2Random");
if (global.gamemode == 5) modeindex = get_text("Title-Additions", "GameSlot_NewGame_SplitRandom");

widescreen = oControl.widescreen;
widescreen_space = oControl.widescreen_space;
