// Capture the current game view and keep the room for returning from the pause screen.
if (global.ingame == 1 && global.enablecontrol == 1 && room != rm_transition && ((!keyboard_check(vk_alt)) || (os_type == os_linux))) {
    // Marker and Menu requests play their sound when the requested page action opens.
    if (dual_enabled && dual_pending_action == 0) sfx_play(sndMenuMove);
    // Keep a health-and-ammo snapshot available if its screen is changed while paused.
    if (dual_enabled) dual_capture_upper_hud();
    event_user(3);
    global.ingame = 0;
    global.targetx = oCharacter.x;
    global.targety = oCharacter.y;
    global.offsetx = 0;
    global.offsety = 0;
    room_persistent = true;
    if (instance_exists(oCharacter)) with (oCharacter) persistent = false;
    if (instance_exists(oCamera)) with (oCamera) persistent = false;
    if (instance_exists(oNotification)) with (oNotification) persistent = false;
    if (instance_exists(oScanMonster)) with (oScanMonster) persistent = false;
    global.currentroom = room;
    global.ssmode = 0;
    room_change(16, 3);
    Mute_Loops();
    global.vibL = 0;
    global.vibR = 0;
}
