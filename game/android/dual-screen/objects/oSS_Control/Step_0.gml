// Open the four-way page selector only after deactivating the current page's input handlers.
if (active && oControl.kMenu2 && oControl.kMenu2PushedSteps == 0 && instance_number(oSubScrChange) == 0 && canchange) {
    if (global.ssmode == 3) {
        save_gameoptions();
        with (oPauseMenuOptions) active = 0;
        with (oOptionsMain) active = 0;
        with (oOptionsData) {
            active = 0;
            alarm[0] = -1;
        }
        with (oOptionsDisplay) if (active != 0) {
            active = 0;
            load_resources();
        }
        with (oOptionsSound) active = 0;
        with (oOptionsControl) active = 0;
        with (oOptionsKeyboard) active = 0;
        with (oOptionsJoypad) active = 0;
        with (oOptionsQuit) active = 0;
        with (oOptionsReload) active = 0;
        with (oOptionsExtras) active = 0; // 1.5.1 fix NOT QUITE
    }
    if (global.ssmode == 2) with (oLogScreenControl) active = 0;
    if (global.ssmode == 1) with (oSubscreenMenu) active = 0;
    if (global.ssmode == 0) with (oMapCursor) active = 0;
    if (oControl.dual_enabled) sfx_play(sndMenuMove);
    instance_create(x, y, oSubScrChange);
}
// Schedule fallback map disposal during backgrounding and recreate a missing surface when needed.
if(os_type == os_android && os_is_paused()) alarm[1] = 1;
if (!oControl.dual_enabled && !surface_exists(s_map)) {
    surface_free(s_map);
    s_map = surface_create(2048, 1024);
    surface_set_target(s_map);
    draw_surface_map();
    surface_reset_target();
}
