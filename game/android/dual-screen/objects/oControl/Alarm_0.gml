if (joystick_exists(global.opjoyid)) {
    global.joydetected = 1;
} else global.joydetected = 0;
init = 0;
// Hold the startup room change until screen setup has saved a choice.
if (dual_setup_needed) exit;
//touch_scale = 4;
// Create the single-screen touch overlay only when the dedicated lower-screen controls are disabled.
if (os_type == os_android && !dual_enabled) instance_create(0, 0, oTouchControls);
//instance_create(0, 0, oTouchControls);
if (1) {
    room_change(19, 0);
} else {
    load_character_vars();
    reset_map();
    init_map();
    global.save_room = initroom;
    set_start_location();
    global.ingame = 1;
    global.newgame = 0;
    global.targetx = 32;
    global.targety = 128;
    global.start_room = asset_get_index("rm_a7b10");
    get_loadout(10);
    mus_set_current(273);
    room_change(global.start_room, 3);
}
