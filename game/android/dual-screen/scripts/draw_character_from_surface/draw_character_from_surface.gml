/// @description  draw_character_from_surface()
function draw_character_from_surface(argument0, argument1, argument2, argument3) {
	// Draw the cached player image at its world position when the surface is available.
	if (surface_exists(oCharacter.surf)) {
	    draw_surface_ext(oCharacter.surf, argument0 - 32, argument1 - 54, 1, 1, 0, argument2, argument3);
	} else {
	    // Rebuild a lost player surface for subsequent drawing.
	    surface_free(oCharacter.surf);
	    oCharacter.surf = surface_create(64, 64);
	    oCharacter.nano_render_pose = [];
	    draw_character_to_surface();
	}



}
