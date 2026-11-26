/// @description  set_window_scale(scale)
function set_window_scale(argument0) {
	// Size the window from the logical game resolution, including the optional widescreen width.
	var scale = max(1, argument0);
	window_set_size(round(standard_aspect_width(global.opaspectratio) * scale), round(240 * scale));
	// yes this hurts but it's widescreen proper, so sue me
	if (os_is_browser) window_center();



}
