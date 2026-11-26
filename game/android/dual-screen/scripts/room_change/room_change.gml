/// @description  room_change(target_room, transition_type)
function room_change(argument0, argument1) {
	// Store the destination and transition style before capturing the outgoing image and entering the transition room.
	global.targetroom = argument0;
	global.transitiontype = argument1;
	with (oControl) {
	    // Loading can enter the next transition before any loading-room Draw event.
	    if (dual_enabled) {
	        dual_loading_transition = room == rm_loading;
	        // Only travel between area rooms keeps the lower map visible.
	        dual_keep_room_map = global.ingame
	            && string_copy(room_get_name(room), 1, 4) == "rm_a"
	            && string_copy(room_get_name(argument0), 1, 4) == "rm_a";
	    }

	    //show_debug_message("oControl commanded to generate screen_surface")
	    event_user(3);
	    fadedone = 0;
	}
	room_goto(rm_transition);



}
