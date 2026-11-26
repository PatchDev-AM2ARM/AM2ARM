/// @description  ctrl_vibrate()
function ctrl_vibrate(argument0, argument1, argument2) {
	// Avoid competing with the large quake effects that already control vibration.
	if (global.opxjoyvib && (!instance_exists(oBigQuake)) && (!instance_exists(oBigQuakeQueen))) {
	    // On desktop and gmloader-next, a temporary vibration object stops the motors after the requested duration.
	    if (!global.android_app) {
	        global.vibL = argument0;
	        global.vibR = argument1;
	        with (oVibrate) instance_destroy();
	        o = instance_create(0, 0, oVibrate);
	        o.alarm[0] = argument2;
	    }
	    // On Android, these duration choices select the matching haptic effects.
	    else {   
	        if(floor(argument2) == 10) {
	            immersion_play_effect(6);
	        } else if(floor(argument2) == 15) {
	            immersion_play_effect(15);
	        } else if(floor(argument2) == 20) {
	            immersion_play_effect(82);
	        }
	    }
	}



}
