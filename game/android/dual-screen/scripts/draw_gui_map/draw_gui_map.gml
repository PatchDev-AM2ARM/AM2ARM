/// @description  draw_gui_map(x, y)
function draw_gui_map(argument0, argument1) {
	var _steady = !global.android_app && global.nano_enabled;
	var _pulse = _steady ? 0.75 : oControl.malpha;
	var _marker_frame = _steady ? 0 : oControl.markfr;
	// Draw the fifteen nearby cells cached by the control object around the player.
	draw_background(bgGUIMapBG, argument0, argument1 + 4);
	if (oControl.m1 != "0") draw_mapblock(argument0 + 16, argument1 + 12, oControl.minimap_cells[0][0], oControl.minimap_cells[0][1], oControl.minimap_cells[0][2], oControl.minimap_cells[0][3], oControl.minimap_cells[0][4], oControl.minimap_cells[0][5], oControl.dm1, oControl.minimap_cells[0][6]);
	if (oControl.m2 != "0") draw_mapblock(argument0, argument1 + 4, oControl.minimap_cells[1][0], oControl.minimap_cells[1][1], oControl.minimap_cells[1][2], oControl.minimap_cells[1][3], oControl.minimap_cells[1][4], oControl.minimap_cells[1][5], oControl.dm2, oControl.minimap_cells[1][6]);
	if (oControl.m3 != "0") draw_mapblock(argument0 + 8, argument1 + 4, oControl.minimap_cells[2][0], oControl.minimap_cells[2][1], oControl.minimap_cells[2][2], oControl.minimap_cells[2][3], oControl.minimap_cells[2][4], oControl.minimap_cells[2][5], oControl.dm3, oControl.minimap_cells[2][6]);
	if (oControl.m4 != "0") draw_mapblock(argument0 + 16, argument1 + 4, oControl.minimap_cells[3][0], oControl.minimap_cells[3][1], oControl.minimap_cells[3][2], oControl.minimap_cells[3][3], oControl.minimap_cells[3][4], oControl.minimap_cells[3][5], oControl.dm4, oControl.minimap_cells[3][6]);
	if (oControl.m5 != "0") draw_mapblock(argument0 + 24, argument1 + 4, oControl.minimap_cells[4][0], oControl.minimap_cells[4][1], oControl.minimap_cells[4][2], oControl.minimap_cells[4][3], oControl.minimap_cells[4][4], oControl.minimap_cells[4][5], oControl.dm5, oControl.minimap_cells[4][6]);
	if (oControl.m6 != "0") draw_mapblock(argument0 + 32, argument1 + 4, oControl.minimap_cells[5][0], oControl.minimap_cells[5][1], oControl.minimap_cells[5][2], oControl.minimap_cells[5][3], oControl.minimap_cells[5][4], oControl.minimap_cells[5][5], oControl.dm6, oControl.minimap_cells[5][6]);
	if (oControl.m7 != "0") draw_mapblock(argument0, argument1 + 12, oControl.minimap_cells[6][0], oControl.minimap_cells[6][1], oControl.minimap_cells[6][2], oControl.minimap_cells[6][3], oControl.minimap_cells[6][4], oControl.minimap_cells[6][5], oControl.dm7, oControl.minimap_cells[6][6]);
	if (oControl.m8 != "0") draw_mapblock(argument0 + 8, argument1 + 12, oControl.minimap_cells[7][0], oControl.minimap_cells[7][1], oControl.minimap_cells[7][2], oControl.minimap_cells[7][3], oControl.minimap_cells[7][4], oControl.minimap_cells[7][5], oControl.dm8, oControl.minimap_cells[7][6]);
	if (oControl.m9 != "0") draw_mapblock(argument0 + 24, argument1 + 12, oControl.minimap_cells[8][0], oControl.minimap_cells[8][1], oControl.minimap_cells[8][2], oControl.minimap_cells[8][3], oControl.minimap_cells[8][4], oControl.minimap_cells[8][5], oControl.dm9, oControl.minimap_cells[8][6]);
	if (oControl.m10 != "0") draw_mapblock(argument0 + 32, argument1 + 12, oControl.minimap_cells[9][0], oControl.minimap_cells[9][1], oControl.minimap_cells[9][2], oControl.minimap_cells[9][3], oControl.minimap_cells[9][4], oControl.minimap_cells[9][5], oControl.dm10, oControl.minimap_cells[9][6]);
	if (oControl.m11 != "0") draw_mapblock(argument0, argument1 + 20, oControl.minimap_cells[10][0], oControl.minimap_cells[10][1], oControl.minimap_cells[10][2], oControl.minimap_cells[10][3], oControl.minimap_cells[10][4], oControl.minimap_cells[10][5], oControl.dm11, oControl.minimap_cells[10][6]);
	if (oControl.m12 != "0") draw_mapblock(argument0 + 8, argument1 + 20, oControl.minimap_cells[11][0], oControl.minimap_cells[11][1], oControl.minimap_cells[11][2], oControl.minimap_cells[11][3], oControl.minimap_cells[11][4], oControl.minimap_cells[11][5], oControl.dm12, oControl.minimap_cells[11][6]);
	if (oControl.m13 != "0") draw_mapblock(argument0 + 16, argument1 + 20, oControl.minimap_cells[12][0], oControl.minimap_cells[12][1], oControl.minimap_cells[12][2], oControl.minimap_cells[12][3], oControl.minimap_cells[12][4], oControl.minimap_cells[12][5], oControl.dm13, oControl.minimap_cells[12][6]);
	if (oControl.m14 != "0") draw_mapblock(argument0 + 24, argument1 + 20, oControl.minimap_cells[13][0], oControl.minimap_cells[13][1], oControl.minimap_cells[13][2], oControl.minimap_cells[13][3], oControl.minimap_cells[13][4], oControl.minimap_cells[13][5], oControl.dm14, oControl.minimap_cells[13][6]);
	if (oControl.m15 != "0") draw_mapblock(argument0 + 32, argument1 + 20, oControl.minimap_cells[14][0], oControl.minimap_cells[14][1], oControl.minimap_cells[14][2], oControl.minimap_cells[14][3], oControl.minimap_cells[14][4], oControl.minimap_cells[14][5], oControl.dm15, oControl.minimap_cells[14][6]);
	// Pulse the current-cell highlight without changing the drawing target's alpha channel.
	draw_set_colour_write_enable(true, true, true, false)
	draw_sprite_ext(sMapHilight, -1, argument0 + 16, argument1 + 12, 1, 1, 0, -1, _pulse);
	draw_set_colour_write_enable(true, true, true, true)
	// Draw the placed marker inside the minimap, or point toward it when it lies outside.
	if (global.mapmarker) {
	    if (oControl.moffx >= -2 && oControl.moffx <= 2 && oControl.moffy >= -1 && oControl.moffy <= 1) draw_sprite(sMapMarker, _marker_frame, argument0 + 16 + oControl.moffx * 8, argument1 + 12 + oControl.moffy * 8);
	    if (oControl.moffx > 2 && oControl.moffy >= -1 && oControl.moffy <= 1) draw_sprite(sHUDMapMarkA, _marker_frame, argument0 + 32, argument1 + 12 + oControl.moffy * 8);
	    if (oControl.moffx < -2 && oControl.moffy >= -1 && oControl.moffy <= 1) draw_sprite_ext(sHUDMapMarkA, _marker_frame, argument0 + 8, argument1 + 12 + oControl.moffy * 8, -1, 1, 0, -1, 1);
	    if (oControl.moffy < -1 && oControl.moffx >= -2 && oControl.moffx <= 2) draw_sprite_ext(sHUDMapMarkA, _marker_frame, argument0 + 24 + oControl.moffx * 8, argument1 + 12, -1, 1, -90, -1, 1);
	    if (oControl.moffy > 1 && oControl.moffx >= -2 && oControl.moffx <= 2) draw_sprite_ext(sHUDMapMarkA, _marker_frame, argument0 + 16 + oControl.moffx * 8, argument1 + 20, -1, 1, 90, -1, 1);
	    if (oControl.moffy < -1 && oControl.moffx > 2) draw_sprite(sHUDMapMarkB, _marker_frame, argument0 + 32, argument1 + 4);
	    if (oControl.moffy < -1 && oControl.moffx < -2) draw_sprite_ext(sHUDMapMarkB, _marker_frame, argument0 + 8, argument1 + 4, -1, 1, 0, -1, 1);
	    if (oControl.moffy > 1 && oControl.moffx > 2) draw_sprite_ext(sHUDMapMarkB, _marker_frame, argument0 + 32, argument1 + 28, 1, -1, 0, -1, 1);
	    if (oControl.moffy > 1 && oControl.moffx < -2) draw_sprite_ext(sHUDMapMarkB, _marker_frame, argument0 + 8, argument1 + 28, -1, -1, 0, -1, 1);
	}



}
