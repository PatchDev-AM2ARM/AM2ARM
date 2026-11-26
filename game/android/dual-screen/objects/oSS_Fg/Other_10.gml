// For the lower display, start closing from the current opacity and ignore repeated close requests.
if (oControl.dual_enabled) {
    if (fadeout) exit;
    sfx_play(sndMenuMove);
    dual_fade_started = current_time;
    dual_fade_from = ealpha;
}
fadeout = 1;
active = 0;
instance_create(0, 0, oMapScrBG3);
if (instance_exists(oOptionsSound) > false) with (oOptionsSound) event_user(3);
// Save settings when closing their page and disable page input for the rest of the fade.
if (global.ssmode == 3) {
    save_gameoptions();
    with (oPauseMenuOptions) active = 0;
    with (oOptionsMain) active = 0;
    with (oOptionsData) {
        active = 0;
        alarm[0] = -1;
    }
    with (oOptionsDisplay) active = 0;
    with (oOptionsSound) active = 0;
    with (oOptionsControl) active = 0;
    with (oOptionsKeyboard) active = 0;
    with (oOptionsJoypad) active = 0;
    with (oOptionsQuit) active = 0;
    with (oOptionsReload) active = 0;
    with (oOptionsExtras) active = 0; // 1.5.1 fix
}
if (global.ssmode == 2) with (oLogScreenControl) active = 0;
if (global.ssmode == 1) with (oSubscreenMenu) active = 0;
if (global.ssmode == 0) with (oMapCursor) active = 0;
