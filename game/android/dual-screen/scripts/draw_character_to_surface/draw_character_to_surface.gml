/// @description  draw_character_to_surface()
function draw_character_to_surface() {
	// Compose the player at a fixed origin so the same image can be reused for glows and trails.
	if (surface_exists(oCharacter.surf)) {
	    if (!nano_render_player_redraw()) return;
	    surface_set_target(oCharacter.surf);
	    draw_clear_alpha(c_blue, 0);
	    draw_character(oCharacter.sprite_index, 32, 54, oCharacter.aspr1, oCharacter.asprx, oCharacter.aspry, oCharacter.aspr2, oCharacter.aspr2x, oCharacter.aspr2y, oCharacter.aspr2a, oCharacter.mirror, oCharacter.image_blend, oCharacter.image_alpha, oCharacter.armmsl, -1);
	    surface_reset_target();
	}



}
