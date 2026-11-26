offset = 160;
state = 0;
with (oSS_Fg) hidetext = 1;
if (oControl.dual_enabled) {
    // Retire the outgoing page before exposing the selector. Its rows remain
    // visible when merely deactivated, especially after Display settings scroll.
    with (oSS_Control) event_user(0);
    // The lower compositor supplies the fade; omit the old full-screen shutter.
    offset = 0;
    state = 1;
    __view_set(e__VW.Object, 0, noone);
    __view_set(e__VW.YView, 0, 0);
}
