if (oControl.dual_enabled && instance_exists(oGameSelMenu)) {
    // Native file-selection layer lines up with the lower half of the shared background.
    var _height = oControl.dual_height;
    var _scroll = round(clamp(bgyoff / 400, 0, 1) * max(0, sprite_get_height(sTitleAnimated) - 240 - _height));
    draw_sprite(sTitleAnimated, subim, -53, -240 - oControl.dual_page_y - _scroll);
    exit;
}
draw_sprite(sTitleAnimated, subim, -53, -bgyoff);

/*if (global.custom_background == false) draw_background(bgTitleScreen, 0, -bgyoff);
else draw_sprite(oControl.sprTitleScroll, subim, 0, -bgyoff);

/* */
/*  */
