if (instance_exists(oCharacter)) {
    oCharacter.x = -100;
    oCharacter.y = -100;
}

// Apply a deferred ratio before destination instances cache their view width.
if (global.opaspectratio != oControl.aspect_ratio && oControl.widescreen_switch) {
    var _old_width = 320 + oControl.widescreen_space;
    with (oControl) standard_aspect_apply(global.opaspectratio);
    if (os_type != os_android && global.opfullscreen == 0) {
        var _scale = window_get_height() / 240;
        set_window_scale(_scale);
        window_set_position(window_get_x() + (_old_width - standard_aspect_width(global.opaspectratio)) * _scale / 2, window_get_y());
    }
}
oControl.widescreen_switch = false;

room_goto(global.targetroom);

