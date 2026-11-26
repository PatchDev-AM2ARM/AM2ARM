if (oControl.dual_enabled) {
    // One clock drives both the upper tint and the lower controls.
    // Give the stronger dimming of an already-selected palette a gentler transition.
    var _duration = oControl.palette_number > 0 ? 300 : 180;
    var _progress = clamp((current_time - dual_fade_started) / _duration, 0, 1);
    ealpha = lerp(dual_fade_from, fadeout ? 0 : 1, _progress);
    rectoffset = round(32 * (1 - ealpha));
    fadein = !fadeout && _progress < 1;
} else {
    if (fadein) {
        if (rectoffset > 0) {
            rectoffset -= 2;
        } else fadein = 0;
    }
    if (fadeout) rectoffset += 2;
    if (ealpha < 1 && fadeout == 0) ealpha += 0.05;
    if (ealpha > 0 && fadeout) ealpha -= 0.05;
}
if (active && !fadein && oControl.kStart && oControl.kStartPushedSteps == 0) event_user(0);
if (ealpha >= 1 && fadeout == 0) active = 1;
// Return to the persistent gameplay room and unmute its loops only after the pause fade reaches zero.
if (ealpha <= 0 && fadeout) {
    global.ingame = 1;
    global.transitiontype = 3;
    room_goto(global.currentroom);
    Unmute_Loops();
    save_gameoptions(); // save mod_collecteditemsmap
}

// Toggle the collected-item map option once per missile-button hold.
if (oControl.kMissile && oControl.kSelectPushedSteps == 0 && !missilepressed)
{
    missilepressed = true;
    if (oControl.mod_collecteditemsmap == 0) oControl.mod_collecteditemsmap = 1;
    else oControl.mod_collecteditemsmap = 0;
}

if (missilepressed && !oControl.kMissile) { missilepressed = false; }
