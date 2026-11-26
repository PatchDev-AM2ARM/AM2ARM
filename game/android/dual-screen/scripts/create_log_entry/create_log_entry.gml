/// @description  create_log_entry(log_id)
function create_log_entry(argument0) {
	var logid, lobj;
	logid = global.log[argument0];
	// Add discovered logs to the caller's list; oLogScreenControl owns lbl, logobj, i, j, and lognum.
	if (logid != 0) {
	    lobj = instance_create(10 + (oControl.dual_enabled ? 5 : 0) + (oControl.widescreen_space/3), 53 + j * 16, oLogEntry);
	    lobj.label = lbl[argument0];
	    lobj.optionid = i;
	    lobj.logid = argument0;
	    logobj[i] = lobj;
	    i += 1;
	    j += 1;
	    lognum += 1;
	}



}
