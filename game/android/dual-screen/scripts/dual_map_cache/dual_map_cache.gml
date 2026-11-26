// Explored-map column caches and compact map rendering.
// Runs in oControl scope. Invalidation and volatile-surface recreation stay together.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

function dual_compact_corners(_width, _height) {
    var _frames = sprite_get_number(sMapCorner);
    if (array_length(dual_corner_pixels) == 0) {
        // Read the existing contour artwork once. No copied image data is baked
        // into source, and no readback is needed on later map frames or zooms.
        var _sheet = surface_create(8 * _frames, 8);
        surface_set_target(_sheet);
        draw_clear_alpha(c_black, 0);
        for (var _f = 0; _f < _frames; ++_f) draw_sprite_part(sMapCorner, _f, 0, 0, 8, 8, _f * 8, 0);
        surface_reset_target();
        var _pixels = buffer_create(_frames * 64 * 4, buffer_fixed, 1);
        buffer_get_surface(_pixels, _sheet, 0);
        dual_corner_pixels = array_create(_frames * 64, 0);
        for (var _f = 0; _f < _frames; ++_f) {
            for (var _sy = 0; _sy < 8; ++_sy) {
                for (var _sx = 0; _sx < 8; ++_sx) {
                    var _pixel = buffer_peek(_pixels, (_sy * _frames * 8 + _f * 8 + _sx) * 4, buffer_u32);
                    dual_corner_pixels[_f * 64 + _sy * 8 + _sx] = _pixel;
                }
            }
        }
        buffer_delete(_pixels);
        surface_free(_sheet);
    }
    // Fractional spacing alternates adjacent integer tile widths and heights.
    // Cache each small corner shape, keeping its outlines at the final pixel size.
    var _key = _width * 9 + _height;
    if (is_array(dual_corner_table[_key])) return dual_corner_table[_key];
    var _table = array_create(_frames * _width * _height, 0);
    for (var _f = 0; _f < _frames; ++_f) {
        for (var _dy = 0; _dy < _height; ++_dy) {
            for (var _dx = 0; _dx < _width; ++_dx) {
                var _edge = false, _filled = 0, _fill_color = 0, _samples = 0;
                for (var _sy = floor(_dy * 8 / _height); _sy < ceil((_dy + 1) * 8 / _height); ++_sy) {
                    for (var _sx = floor(_dx * 8 / _width); _sx < ceil((_dx + 1) * 8 / _width); ++_sx) {
                        var _pixel = dual_corner_pixels[_f * 64 + _sy * 8 + _sx];
                        if ((_pixel & $ff000000) != 0) {
                            if ((_pixel & $ffffff) == $ffffff) _edge = true;
                            else { ++_filled; _fill_color = _pixel; }
                        }
                        ++_samples;
                    }
                }
                // Keep thin edges and the corner's own colored interior. Some
                // map cells consist entirely of this artwork, with no base block.
                _table[_f * _width * _height + _dy * _width + _dx] = _edge
                    ? ($ff000000 | c_white)
                    : (_filled * 2 >= _samples ? _fill_color : 0);
            }
        }
    }
    dual_corner_table[_key] = _table;
    return _table;
}

// Pending compact columns outlive the full-size map's per-frame dirty list.
// Large invalidations and overlapping detail sprites retain the full renderer.
function dual_compact_full_redraw() {
    dual_compact_dirty = true;
    dual_compact_full = true;
    dual_compact_columns = [];
}

function dual_compact_queue_columns(_columns) {
    dual_compact_dirty = true;
    if (dual_compact_full) return;
    for (var _i = 0; _i < array_length(_columns); ++_i) {
        var _x = _columns[_i], _found = false;
        for (var _j = 0; _j < array_length(dual_compact_columns); ++_j)
            if (dual_compact_columns[_j] == _x) { _found = true; break; }
        if (!_found) array_push(dual_compact_columns, _x);
        if (array_length(dual_compact_columns) > 8) {
            dual_compact_full_redraw(); return;
        }
    }
}

function dual_compact_map_update() {
    if (dual_zoom >= 1) return;
    var _cell = max(1, 8 * dual_zoom);
    // Rebuild the reduced map surface when its cell size changes, and otherwise reuse unchanged content.
    if (!surface_exists(dual_compact_map) || dual_compact_cell != _cell) {
        if (surface_exists(dual_compact_map)) surface_free(dual_compact_map);
        dual_compact_map = effect_surface_create(80 * _cell, 80 * _cell);
        dual_compact_cell = _cell;
        dual_compact_full_redraw();
    }
    if (!surface_exists(dual_compact_map) || !dual_compact_dirty) return;
    dual_map_base_revision++;
    var _small = floor(_cell), _large = ceil(_cell);
    var _detail = _small >= 6;
    dual_compact_corners(_small, _small);
    if (_large != _small) {
        dual_compact_corners(_small, _large);
        dual_compact_corners(_large, _small);
        dual_compact_corners(_large, _large);
    }
    // Draw at the final cell size instead of discarding pixels from an 8px tile.
    // Keep normal details for slight zoom-outs; simplify only the smaller overview cells.
    var _colors = [c_black, make_color_rgb(0, 0, 255), make_color_rgb(0, 128, 128),
                   make_color_rgb(0, 128, 0), make_color_rgb(95, 0, 127)];
    // Overview cells never draw outside their column. Detailed symbols do,
    // so only use replacement strips below the original detail threshold.
    var _partial = !dual_compact_full && !_detail
        && array_length(dual_compact_columns) > 0;
    var _map_height = surface_get_height(dual_compact_map);
    if (_partial) {
        if (surface_exists(dual_compact_strip)
                && (surface_get_width(dual_compact_strip) != _large
                    || surface_get_height(dual_compact_strip) != _map_height))
            surface_free(dual_compact_strip);
        if (!surface_exists(dual_compact_strip)) dual_compact_strip = effect_surface_create(_large, _map_height);
        _partial = surface_exists(dual_compact_strip);
    }
    var _passes = _partial ? array_length(dual_compact_columns) : 1;
    for (var _pass = 0; _pass < _passes; ++_pass) {
        var _first_x = _partial ? dual_compact_columns[_pass] : dual_map_min_x;
        var _last_x = _partial ? _first_x + 1 : dual_map_max_x;
        var _first_y = _partial ? 0 : dual_map_min_y;
        var _last_y = _partial ? 80 : dual_map_max_y;
        var _origin_x = _partial ? floor(_first_x * _cell + 0.5) : 0;
        surface_set_target(_partial ? dual_compact_strip : dual_compact_map);
        draw_clear_alpha(c_black, 0);
        for (var _mx = _first_x; _mx < _last_x; ++_mx) {
            for (var _my = _first_y; _my < _last_y; ++_my) {
                var _idx = _mx * 80 + _my;
                if (dual_map_seen[_idx] <= 0) continue;
                var _tile = string(dual_map_tiles[_idx]);
                if (_tile == "0") continue;
                var _fill = string_pos(string_char_at(_tile, 5), "1234");
                var _x = floor(_mx * _cell + 0.5), _y = floor(_my * _cell + 0.5);
                var _width = floor((_mx + 1) * _cell + 0.5) - _x;
                var _height = floor((_my + 1) * _cell + 0.5) - _y;
                _x -= _origin_x;
                var _right = _x + _width - 1, _bottom = _y + _height - 1;
                if (_fill > 0) {
                    draw_set_color(_colors[_fill]);
                    draw_rectangle(_x, _y, _right, _bottom, false);
                }
                var _corner = string_pos(string_char_at(_tile, 7), "123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefgh") - 1;
                if (_corner >= 0) {
                    var _table = dual_compact_corners(_width, _height);
                    for (var _cy = 0; _cy < _height; ++_cy) {
                        for (var _cx = 0; _cx < _width; ++_cx) {
                            var _shape = _table[_corner * _width * _height + _cy * _width + _cx];
                            if (_shape == 0) continue;
                            var _color = _shape & $ffffff;
                            draw_set_color(_color == c_white && !_detail ? make_color_rgb(144, 184, 168) : _color);
                            draw_rectangle(_x + _cx, _y + _cy, _x + _cx, _y + _cy, false);
                        }
                    }
                }
                draw_set_color(_detail ? c_white : make_color_rgb(144, 184, 168));
                if (string_char_at(_tile, 1) == "1") draw_rectangle(_x, _y, _right, _y, false);
                if (string_char_at(_tile, 2) == "1") draw_rectangle(_right, _y, _right, _bottom, false);
                if (string_char_at(_tile, 3) == "1") draw_rectangle(_x, _bottom, _right, _bottom, false);
                if (string_char_at(_tile, 4) == "1") draw_rectangle(_x, _y, _x, _bottom, false);
                if (_detail) {
                    if (string_char_at(_tile, 1) == "2") draw_sprite_ext(sMapHPass, 0, _x, _y, _width / 8, 1, 0, c_white, 1);
                    if (string_char_at(_tile, 2) == "2") draw_sprite_ext(sMapVPass, 0, _right, _y, 1, _height / 8, 0, c_white, 1);
                    if (string_char_at(_tile, 3) == "2") draw_sprite_ext(sMapHPass, 0, _x, _bottom, _width / 8, 1, 0, c_white, 1);
                    if (string_char_at(_tile, 4) == "2") draw_sprite_ext(sMapVPass, 0, _x, _y, 1, _height / 8, 0, c_white, 1);
                }
            }
        }
        if (_detail) {
            // Draw original-size symbols last so neighboring room fills cannot erase them.
            for (var _mx = _first_x; _mx < _last_x; ++_mx) {
                for (var _my = _first_y; _my < _last_y; ++_my) {
                    var _idx = _mx * 80 + _my;
                    var _seen = dual_map_seen[_idx];
                    if (_seen <= 0) continue;
                    var _tile = string(dual_map_tiles[_idx]);
                    if (_tile == "0") continue;
                    var _symbol = string_char_at(_tile, 6);
                    if (_symbol == "0" && _seen != 10 && _seen != 11) continue;
                    var _x = round((_mx + 0.5) * _cell - 4), _y = round((_my + 0.5) * _cell - 4);
                    draw_mapblock(_x, _y, "0", "0", "0", "0", "0", _symbol, _seen, "0");
                }
            }
        }
        draw_set_color(c_white);
        surface_reset_target();
        if (_partial) {
            var _span = floor((_first_x + 1) * _cell + 0.5) - _origin_x;
            // Copy replaces transparent pixels too, removing cells no longer visible.
            surface_copy_part(dual_compact_map, _origin_x, 0, dual_compact_strip, 0, 0, _span, _map_height);
        }
    }
    dual_compact_dirty = false;
    dual_compact_full = false;
    dual_compact_columns = [];
}

// Observation harness for a separate local Android package.

function dual_map_column_cache_new() {
    return {ready:false, seen:[], tiles:[], dirty:[],
        minY:array_create(80, 80), maxY:array_create(80, 0)};
}

function dual_map_columns_changed() {
    var _cache = dual_map_columns_cache;
    _cache.dirty = [];
    var _reset = !dual_map_valid || !_cache.ready;
    var _seen_changed = _reset || !array_equals(_cache.seen, global.dmap);
    var _tiles_changed = _reset || !array_equals(_cache.tiles, global.map);
    if (_seen_changed || _tiles_changed) {
        if (_reset) {
            _cache.seen = array_create(80);
            _cache.tiles = array_create(80);
        }
        for (var _x = 0; _x < 80; ++_x) {
            var _seen_column = _reset || (_seen_changed && !array_equals(_cache.seen[_x], global.dmap[_x]));
            var _tile_column = _reset || (_tiles_changed && !array_equals(_cache.tiles[_x], global.map[_x]));
            var _dirty = _seen_column;
            if (!_dirty && _tile_column) {
                for (var _y = 0; _y < 80 && !_dirty; ++_y)
                    _dirty = global.dmap[_x, _y] > 0
                        && dual_map_tiles[_x * 80 + _y] != global.map[_x, _y];
            }
            // Never retain aliases to the mutable game arrays.
            if (_seen_column) _cache.seen[_x] = variable_clone(global.dmap[_x]);
            if (_tile_column) _cache.tiles[_x] = variable_clone(global.map[_x]);
            if (_dirty) array_push(_cache.dirty, _x);
        }
        _cache.ready = true;
    }
    var _changed = array_length(_cache.dirty) > 0;

    return _changed;
}

function dual_map_cached_bounds() {
    var _cache = dual_map_columns_cache;
    dual_map_min_x = 80; dual_map_min_y = 80;
    dual_map_max_x = 0; dual_map_max_y = 0;
    for (var _x = 0; _x < 80; ++_x) {
        if (_cache.maxY[_x] <= 0) continue;
        dual_map_min_x = min(dual_map_min_x, _x);
        dual_map_max_x = max(dual_map_max_x, _x + 1);
        dual_map_min_y = min(dual_map_min_y, _cache.minY[_x]);
        dual_map_max_y = max(dual_map_max_y, _cache.maxY[_x]);
    }
}

function dual_map_repaint_cached_columns() {
    dual_map_base_revision++;
    var _cache = dual_map_columns_cache, _columns = _cache.dirty;
    if (!surface_exists(dual_map_column)) dual_map_column = effect_surface_create(8, 640);
    if (!dual_map_valid || array_length(_columns) > 8 || !surface_exists(dual_map_column)) {
        dual_map_repaint_cached_full();
        return;
    }
    for (var _c = 0; _c < array_length(_columns); ++_c) {
        var _x = _columns[_c], _min_y = 80, _max_y = 0;
        surface_set_target(dual_map_column);
        draw_clear_alpha(c_black, 0);
        for (var _y = 0; _y < 80; ++_y) {
            var _idx = _x * 80 + _y, _seen = global.dmap[_x, _y];
            dual_map_seen[_idx] = _seen;
            dual_map_tiles[_idx] = global.map[_x, _y];
            if (_seen <= 0) continue;
            var _tile = string(dual_map_tiles[_idx]);
            if (_tile == "0") continue;
            _min_y = min(_min_y, _y); _max_y = max(_max_y, _y + 1);
            draw_mapblock(0, _y * 8, string_char_at(_tile, 1), string_char_at(_tile, 2),
                string_char_at(_tile, 3), string_char_at(_tile, 4), string_char_at(_tile, 5),
                string_char_at(_tile, 6), _seen, string_char_at(_tile, 7));
        }
        surface_reset_target();
        surface_copy_part(dual_map, _x * 8, 0, dual_map_column, 0, 0, 8, 640);
        _cache.minY[_x] = _min_y; _cache.maxY[_x] = _max_y;
    }
    dual_map_cached_bounds();
    dual_map_valid = true;
    dual_compact_queue_columns(_columns);
}

function dual_map_repaint_cached_full() {
    dual_map_base_revision++;
    var _cache = dual_map_columns_cache;
    surface_set_target(dual_map);
    draw_clear_alpha(c_black, 0);
    for (var _x = 0; _x < 80; ++_x) {
        var _min_y = 80, _max_y = 0;
        for (var _y = 0; _y < 80; ++_y) {
            var _seen = global.dmap[_x, _y], _idx = _x * 80 + _y;
            dual_map_seen[_idx] = _seen;
            dual_map_tiles[_idx] = global.map[_x, _y];
            if (_seen <= 0) continue;
            var _tile = string(global.map[_x, _y]);
            if (_tile == "0") continue;
            _min_y = min(_min_y, _y); _max_y = max(_max_y, _y + 1);
            draw_mapblock(_x * 8, _y * 8, string_char_at(_tile, 1), string_char_at(_tile, 2),
                string_char_at(_tile, 3), string_char_at(_tile, 4), string_char_at(_tile, 5),
                string_char_at(_tile, 6), _seen, string_char_at(_tile, 7));
        }
        _cache.minY[_x] = _min_y; _cache.maxY[_x] = _max_y;
    }
    surface_reset_target();
    dual_map_cached_bounds();
    dual_map_valid = true;
    dual_compact_full_redraw();
}

function dual_draw_map_base_contents(_ox, _oy) {
    dual_draw_backdrop();
    // Repeat a small cached grid past map bounds, as the pause screen does.
    if (dual_zoom >= 1) {
        var _grid_size = 192 * dual_zoom;
        var _grid_x = ((_ox mod _grid_size) + _grid_size) mod _grid_size - _grid_size;
        var _grid_y = ((_oy mod _grid_size) + _grid_size) mod _grid_size - _grid_size;
        gpu_set_blendmode(bm_add);
        for (var _gx = _grid_x; _gx < 310 + dual_pad; _gx += _grid_size) {
            for (var _gy = _grid_y; _gy < dual_height; _gy += _grid_size) {
                draw_surface_ext(dual_grid, _gx, _gy, dual_zoom, dual_zoom, 0, c_white, 0.65);
            }
        }
        gpu_set_blendmode(bm_normal);
    } else {
        // Keep every tile boundary when zoomed out, using thin, dim lines over the area picture.
        var _grid_cell = 8 * dual_zoom;
        draw_set_color(make_color_rgb(8, 88, 16));
        draw_set_alpha(0.2 + 0.3 * clamp((_grid_cell - 2) / 6, 0, 1));
        gpu_set_blendmode(bm_add);
        // Snap each line to the same tile boundaries as the reduced map.
        for (var _col = ceil((-dual_pad - _ox) / _grid_cell);
             _ox + _col * _grid_cell < 310 + dual_pad; ++_col) {
            var _line_x = _ox + floor(_col * _grid_cell + 0.5);
            draw_rectangle(_line_x, dual_map_top, _line_x, dual_map_bottom - 1, false);
        }
        for (var _row = ceil((dual_map_top - _oy) / _grid_cell);
             _oy + _row * _grid_cell < dual_map_bottom; ++_row) {
            var _line_y = _oy + floor(_row * _grid_cell + 0.5);
            draw_rectangle(-dual_pad, _line_y, 309 + dual_pad, _line_y, false);
        }
        gpu_set_blendmode(bm_normal);
        draw_set_alpha(1);
        draw_set_color(c_white);
    }
    if (dual_zoom < 1) draw_surface(dual_compact_map, _ox, _oy);
    else draw_surface_ext(dual_map, _ox, _oy, dual_zoom, dual_zoom, 0, c_white, 1);
}

// Cache only the backdrop, grid and discovered map. Markers, HUD, fades and
// presentation remain live at the original cadence in dual_draw.
function dual_draw_map_base(_ox, _oy) {
    if (dual_backdrop_previous >= 0 && current_time < dual_backdrop_since + 600) {
        dual_map_base_key = [];
        dual_draw_map_base_contents(_ox, _oy);
        return;
    }
    var _key = [dual_width, dual_height, dual_pad, dual_map_top, dual_map_bottom,
        _ox, _oy, dual_zoom, dual_backdrop, dual_backdrop_previous,
        dual_map_base_revision, dual_map, dual_grid, dual_compact_map];
    if (surface_exists(dual_map_base)
        && (surface_get_width(dual_map_base) != dual_width
            || surface_get_height(dual_map_base) != dual_height))
        surface_free(dual_map_base);
    if (!surface_exists(dual_map_base)) {
        dual_map_base = effect_surface_create(dual_width, dual_height);
        dual_map_base_key = [];
    }
    if (!surface_exists(dual_map_base)) {
        // Keep the original renderer available when an allocation cannot be made.
        dual_draw_map_base_contents(_ox, _oy);
        return;
    }
    if (!array_equals(_key, dual_map_base_key)) {
        // Render into the normal lower target first so its backdrop sampling
        // stays identical. Retain those pixels before live overlays are drawn.
        dual_draw_map_base_contents(_ox, _oy);
        var _world = matrix_get(matrix_world);
        // Surface copying observes the world transform; do not copy the map's
        // horizontal padding a second time on wider device profiles.
        matrix_set(matrix_world, matrix_build_identity());
        surface_copy(dual_map_base, 0, 0, surface_get_target());
        matrix_set(matrix_world, _world);
        // This fresh key contains scalar values only; no mutable map arrays are retained.
        dual_map_base_key = _key;
        return;
    }
    gpu_set_blendmode(bm_normal);
    draw_set_color(c_white); draw_set_alpha(1);
    // The base already contains its blended pixels. Copy their RGBA values
    // exactly, including partially transparent detail sprites, without blending twice.
    gpu_set_blendmode_ext(bm_one, bm_zero);
    draw_surface(dual_map_base, -dual_pad, 0);
    gpu_set_blendmode(bm_normal);
}
