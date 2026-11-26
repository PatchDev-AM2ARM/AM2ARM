// Let the ending music clock drive the dual-panel credits when enabled; previews retain the original step path.
if (oControl.dual_enabled && dual_credits_step()) exit;

// User fadeout input
if (canfadeout && (oControl.kMenu1 || oControl.kMenu2 || oControl.kStart)) fadeout = 1;

// Fadeout routine
if (fadeout) {
    if (yoffset > 0) {
        yoffset -= 1;
    } else event_user(0);
}

// Credits cutscene animation
if (statetime == 360) instance_create(192, 88, oCreditsShip);

// Fade in
if (statetime > 520) {
    if (image_alpha < 1) image_alpha += 0.05;
}

// This dictates the credit scrolling speed
if (statetime == 700) vspeed = SCROLL_SPEED; // -0.34;

// This stops the credits on the final line
if (y <= ystart + 8 - (TEXT_ROWS * 12)) vspeed = 0;

statetime++;

