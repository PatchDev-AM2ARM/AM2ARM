/// @description  set_fullscreen(enable)
function set_fullscreen(argument0) {
	var flag = argument0;
	// Native builds switch fullscreen directly; the browser path instead chooses a fitting integer window scale.
	if (os_is_native) {
	    window_set_fullscreen(flag);
	} else {
	    var scale;
	    if (flag) {
	        scale = floor(min(browser_width / (320 + oControl.widescreen_space), browser_height / 240));
	    } else scale = global.opscale;
	    set_window_scale(scale);
	}



}
