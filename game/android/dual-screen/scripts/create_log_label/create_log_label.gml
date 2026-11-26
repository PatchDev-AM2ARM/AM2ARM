/// @description  create_log_label(text)
function create_log_label(argument0) {
	var l;
	// Place a category heading at the caller's next log-list row, accounting for the lower page margin.
	l = instance_create(10 + (oControl.dual_enabled ? 5 : 0) + (oControl.widescreen_space/3), 53 + j * 16, oMenuLabel);
	l.text = argument0;
	l.bg_width = 100;
	j += 1;
	return l;



}
