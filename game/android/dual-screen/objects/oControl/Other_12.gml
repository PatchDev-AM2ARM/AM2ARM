// Cache the map tiles and discovery flags around Samus for the HUD minimap.
m1 = string(global.map[global.mapposx, global.mapposy]);
m2 = string(global.map[global.mapposx - 2, global.mapposy - 1]);
m3 = string(global.map[global.mapposx - 1, global.mapposy - 1]);
m4 = string(global.map[global.mapposx, global.mapposy - 1]);
m5 = string(global.map[global.mapposx + 1, global.mapposy - 1]);
m6 = string(global.map[global.mapposx + 2, global.mapposy - 1]);
m7 = string(global.map[global.mapposx - 2, global.mapposy]);
m8 = string(global.map[global.mapposx - 1, global.mapposy]);
m9 = string(global.map[global.mapposx + 1, global.mapposy]);
m10 = string(global.map[global.mapposx + 2, global.mapposy]);
m11 = string(global.map[global.mapposx - 2, global.mapposy + 1]);
m12 = string(global.map[global.mapposx - 1, global.mapposy + 1]);
m13 = string(global.map[global.mapposx, global.mapposy + 1]);
m14 = string(global.map[global.mapposx + 1, global.mapposy + 1]);
m15 = string(global.map[global.mapposx + 2, global.mapposy + 1]);
dm1 = global.dmap[global.mapposx, global.mapposy];
dm2 = global.dmap[global.mapposx - 2, global.mapposy - 1];
dm3 = global.dmap[global.mapposx - 1, global.mapposy - 1];
dm4 = global.dmap[global.mapposx, global.mapposy - 1];
dm5 = global.dmap[global.mapposx + 1, global.mapposy - 1];
dm6 = global.dmap[global.mapposx + 2, global.mapposy - 1];
dm7 = global.dmap[global.mapposx - 2, global.mapposy];
dm8 = global.dmap[global.mapposx - 1, global.mapposy];
dm9 = global.dmap[global.mapposx + 1, global.mapposy];
dm10 = global.dmap[global.mapposx + 2, global.mapposy];
dm11 = global.dmap[global.mapposx - 2, global.mapposy + 1];
dm12 = global.dmap[global.mapposx - 1, global.mapposy + 1];
dm13 = global.dmap[global.mapposx, global.mapposy + 1];
dm14 = global.dmap[global.mapposx + 1, global.mapposy + 1];
dm15 = global.dmap[global.mapposx + 2, global.mapposy + 1];
if (global.mapmarker) {
    moffx = global.mapmarkerx - global.mapposx;
    moffy = global.mapmarkery - global.mapposy;
}


// Decode at the existing cell/discovery refresh, not on every HUD draw.
var _tiles = [m1,m2,m3,m4,m5,m6,m7,m8,m9,m10,m11,m12,m13,m14,m15];
for (var _i = 0; _i < 15; ++_i) {
    var _tile = _tiles[_i];
    minimap_cells[_i] = _tile == "0" ? 0 : [
        string_char_at(_tile,1), string_char_at(_tile,2), string_char_at(_tile,3),
        string_char_at(_tile,4), string_char_at(_tile,5), string_char_at(_tile,6),
        string_char_at(_tile,7)];
}

nano_render_map_revision++;
