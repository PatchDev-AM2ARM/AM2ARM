/// @description  set_widescreen();
function set_widescreen() {
	//if(widescreen) {
	    //widescreen_space = floor(window_get_width()*240/window_get_height()) - 320; // Get space to set on widescreen?
    
	    //if(widescreen_space % 2 == 1) widescreen_space += 1; // fix for odd numbered scales?
    
	    // for testing we're just gonna ignore all that lol
	    //widescreen_space = 426 - 320;
    
	    // Configure the additional wide camera around the original view.
	    __view_set( e__VW.Visible, 1, true ); // widescreen view
	    // So this creates an extra view that displays over view 0
    
	    __view_set( e__VW.WView, 1, __view_get( e__VW.WView, 0 )+widescreen_space ); // Take view, expand to widescreen res
	    __view_set( e__VW.HView, 1, __view_get( e__VW.HView, 0 ) ); // no duh
    
	    __view_set( e__VW.WPort, 1, __view_get( e__VW.WPort, 0 )-widescreen_space ); // e x p a n d?
	    __view_set( e__VW.HPort, 1, __view_get( e__VW.HPort, 0 ) ); // no duh
    
	    __view_set( e__VW.XView, 1, __view_get( e__VW.XView, 0 )-widescreen_space/2 ); // move backwards to center everything
	    __view_set( e__VW.YView, 1, __view_get( e__VW.YView, 0 ) ); // no duh
    
	    //view_xport[1] = view_xport[0]; // this should fix the quakes?
	    //view_yport[1] = view_yport[0];
    
	    // Recreate its drawing surface if needed and bind that surface to the wide view.
	    if (surface_exists(widescreen_surface)) {
            if (surface_get_width(widescreen_surface) != 320 + widescreen_space
                || surface_get_height(widescreen_surface) != 240)
                surface_free(widescreen_surface);
        }
        if (!surface_exists(widescreen_surface)) {
	       widescreen_surface = surface_create(__view_get( e__VW.WView, 1 ), __view_get( e__VW.HView, 1 ));
	    }
    
	    __view_set( e__VW.SurfaceID, 1, widescreen_surface );
	//}



}

// Read the actual camera: room changes can replace it, and other events may resize it.
function control_view_dimensions() {
    var _camera = view_get_camera(0);
    if (camera_get_view_width(_camera) != 320 || camera_get_view_height(_camera) != 240) {
        camera_set_view_size(_camera, 320, 240);
        global.bubble_view_ready = false;
    }
    if (view_get_wport(0) != 320) view_set_wport(0, 320);
    if (view_get_hport(0) != 240) view_set_hport(0, 240);
}

function control_gui_dimensions(_width, _height) {
    // Credits temporarily override this canvas. Query it rather than trusting a
    // last-requested size across another event, room change or Android resume.
    if (display_get_gui_width() != _width || display_get_gui_height() != _height)
        display_set_gui_size(_width, _height);
}

// Only pure rendering may use this predicate. Both Draw events still execute,
// including their RNG/state effects. Menus and transitions consume the base image.
function world_draw_unused() {
    return view_current == 0 && oControl.widescreen && global.ingame
        && surface_exists(oControl.widescreen_surface)
        && room != rm_subscreen && room != rm_transition && room != itemroom
        && room != rm_death && room != rm_loading;
}

// Saved ratio IDs retain the original 4:3 / 16:9 choices; 3:2 adds 40 pixels.
function standard_aspect_width(_ratio) {
    switch (_ratio) {
        case 0: return 320;
        case 2: return 360;
        default: return 426;
    }
}

function standard_aspect_validate(_ratio, _legacy_wide) {
    if (_ratio == 0 || _ratio == 1 || _ratio == 2) return _ratio;
    return _legacy_wide ? 1 : 0;
}

// Called in oControl only. Gameplay changes wait for the next room transition,
// so existing room instances and frozen pause images keep one consistent width.
function standard_aspect_apply(_ratio) {
    aspect_ratio = _ratio;
    if (dual_enabled && dual_aspect_locked) _ratio = 0;
    global.widescreen_enabled = _ratio != 0;
    widescreen = _ratio != 0;
    widescreen_space = standard_aspect_width(_ratio) - 320;
    if (!widescreen) __view_set(e__VW.Visible, 1, false);
}

// Use the ratio that fits the panel until the player picks one. Called in oControl only.
// The window gets its real size after startup, so this is polled.
function standard_aspect_auto() {
    if (!aspect_auto || global.ingame || room == rm_subscreen) return;
    var _width = window_get_width(), _height = window_get_height();
    if (dual_swap_active()) {
        _width = DualScreen_Width();
        _height = DualScreen_Height();
    }
    if (_width < 1 || _height < 1) return;
    var _ratio = standard_panel_aspect(_width, _height);
    if (_ratio == global.opaspectratio) return;
    global.opaspectratio = _ratio;
    standard_aspect_apply(_ratio);
}

/// Choose the supported view that fills the most panel area without stretching.
function standard_panel_aspect(_width, _height) {
    var _best = 0, _largest = 0;
    for (var _id = 0; _id < 3; ++_id) {
        var _view = standard_aspect_width(_id);
        var _scale = min(_width / _view, _height / 240);
        var _area = _view * _scale * _scale;
        if (_area > _largest) { _best = _id; _largest = _area; }
    }
    return _best;
}
