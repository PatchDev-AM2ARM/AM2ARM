// Replace the outgoing page through the pause controller, then reveal the newly selected page text.
with (oSS_Control) {
    event_user(0);
    event_user(1);
}
state = 2;
with (oSS_Fg) hidetext = 0;
// The lower compositor handles the visual transition, so the dual-screen selector can finish immediately.
if (oControl.dual_enabled) instance_destroy();
