// Display state lifecycle and per-frame composition.
// Runs in oControl scope. Keep initialization, polling cadence and draw routing here.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

/// Lower display. All coordinates are independent of the upper viewport.
/// @description Initialize the controller-owned display state once.
/// @context oControl
function dual_init() {
    dual_lower_step = -1;
    dual_nano_last_step = -60;
    dual_nano_last_call = current_time;
    dual_nano_previous = false;
    dual_nano_dirty = true;
    dual_nano_clock_only = false;
    dual_nano_poll_column = 0;
    dual_nano_last_health = -1;
    dual_nano_last_ammo = -1;
    dual_nano_last_super = -1;
    dual_nano_last_bombs = -1;
    dual_nano_last_weapon = -1;
    dual_nano_last_time = -1;
    dual_nano_last_items = -1;
    dual_nano_last_monsters = -1;
    dual_nano_last_area = -1;
    dual_nano_last_cell_x = -1;
    dual_nano_last_cell_y = -1;
    dual_map_columns_cache = dual_map_column_cache_new();
    dual_map_base = -1;
    dual_map_base_key = [];
    dual_map_base_revision = 0;
    dual_art_generation = 0;
    dual_art_output_key = [];
    dual_art_cache_state = [];
    dual_art_key_scratch = array_create(42, 0);
    dual_art_title_inputs = [];
    dual_art_title_state_cache = {text:"", alpha:1};
    dual_art_title_current = "";
    dual_art_title_previous = "";
    dual_art_empty_title = [0, 0, 0];
    dual_art_no_hints = [-1, -1, -1];
    dual_art_pixels = 1;
    dual_art_cache_title = [0, 0, 0];
    // oControl owns the display state initialized here and uses it from its input, draw, and cleanup events.
    // Set by dual_settings_load.
    dual_available = false;
    dual_enabled = false;
    dual_choice = -1;
    dual_controller_splash = false;
    dual_hud_top = false;
    dual_upper_hud_surface = -1;
    dual_upper_hud_buffer = -1;
    dual_upper_hud_width = 320;
    dual_idle_input = {dx:0, dy:0, zoom:0, tap:false, x:0, y:0, originX:0, originY:0};
    dual_swap_screens = false;
    dual_setup_needed = false;
    dual_setup_choice = 0;
    dual_setup_tap = -1;
    dual_setup_ready = false;
    dual_setup_surface = -1;
    // Set by dual_layout_apply.
    dual_window_width = 0; dual_window_height = 0;
    dual_screen_width = 0; dual_screen_height = 0;
    dual_layout_swap = false;
    dual_scale = 1; dual_x = 0; dual_y = 0;
    dual_width = 320; dual_height = 240; dual_pad = 5;
    dual_scene_width = 426; dual_page_y = 0; dual_aspect_locked = false;
    // Mark render surfaces as absent; draw paths create them when their image is first needed.
    dual_surface = -1;
    dual_scene = -1;
    dual_room_surface = -1;
    dual_output_room = -1;
    dual_room_alpha = 1;
    dual_fade_step = -1;
    dual_loading_transition = false;
    dual_keep_room_map = false;
    dual_frontend_previous_mode = DUAL_FRONTEND_GAMEPLAY;
    dual_death_surface = -1;
    dual_death_active = false;
    dual_title_offset = 0;
    dual_title_frame = 0;
    dual_title_press_frames = 0;
    dual_credits_voice = -1;
    dual_map = -1;
    dual_map_column = -1;
    dual_compact_map = -1;
    dual_compact_cell = 0;
    dual_compact_strip = -1;
    dual_compact_full_redraw();
    dual_corner_pixels = [];
    dual_corner_table = array_create(81, 0);
    dual_grid = -1;
    dual_hud_sheet = -1;
    dual_art_hold = -1;
    dual_art_surface = -1;
    dual_art_help_font = -1;
    dual_art_width = 177;
    dual_art_scale = 1;
    dual_art_header_height = 34;
    dual_art_health_height = 16;
    dual_art_geometry_width = -1;
    dual_art_geometry_height = -1;
    dual_art_geometry_tanks = -1;
    dual_art_geometry_hud_top = false;
    dual_art_title_full = false;
    dual_art_title_rows = 0;
    dual_art_output = -1;
    dual_art_previous = -1;
    dual_art_flash_top = -1;
    dual_art_flash_bottom = -1;
    dual_art_flash_title = -1;
    dual_art_flash_light = -1;
    dual_art_title_layout = [0, 0, 0];
    dual_art_hint_mask = 0;
    dual_art_output_hints = 0;
    dual_art_previous_hints = 0;
    dual_art_cache_hints = 0;
    dual_art_output_title = [0, 0, 0];
    dual_art_previous_title = [0, 0, 0];
    dual_art_output_top = 0;
    dual_art_output_bottom = 0;
    dual_art_previous_top = 0;
    dual_art_previous_bottom = 0;
    dual_art_output_fade = 1;
    dual_art_top_rows = 0;
    dual_art_footer_rows = 0;
    dual_buffer = -1;
    // Start the map centered on its default grid position, with player following and normal zoom enabled.
    dual_follow = true;
    dual_center_x = 40;
    dual_center_y = 40;
    dual_map_top = 54;
    dual_map_bottom = 232;
    dual_zoom = 1;
    dual_manual_zoom = 1;
    dual_gesture_zoom = 1;
    dual_gesture_until = 0;
    dual_next_map = 0;
    dual_map_valid = false;
    // Cache discovery and tile content separately so a changed map cell can trigger repainting.
    dual_map_seen = array_create(6400, -1);
    dual_map_tiles = array_create(6400, "");
    dual_last_cell_x = -1;
    dual_last_cell_y = -1;
    dual_had_game = false;
    dual_map_min_x = 0;
    dual_map_min_y = 0;
    dual_map_max_x = 80;
    dual_map_max_y = 80;
    dual_frames = 0;
    dual_steps = 0;
    dual_paused = false;
    dual_pause_width = 320;
    dual_pause_surface = -1;
    dual_pause_valid = false;
    dual_pause_palette = -1;
    dual_backdrop = -1;
    dual_backdrop_previous = -1;
    dual_lab_entrance = false;
    dual_previous_lab_entrance = false;
    dual_research_site = false;
    dual_previous_research_site = false;
    dual_waterfalls = false;
    dual_previous_waterfalls = false;
    dual_backdrop_since = 0;
    dual_backdrop_room = -1;
    dual_backdrop_variant = -1;
    dual_reset_area_titles();
    dual_overview = false;
    dual_marker_pan = false;
    dual_missile_frame = 0;
    dual_super_frame = 0;
    dual_bomb_frame = 0;
    // Track pause actions requested from gameplay until the destination page is ready to accept them.
    dual_pending_action = 0;
    dual_pause_direction_ready = false;
    dual_transition_surface = -1;
    dual_menu_key = -1;
    dual_ui_paused = false;
    dual_menu_center_y = 121;
    dual_transition_kind = 0;
    dual_transition_until = 0;
    dual_layout_controls();
}

// Nano holds idle map artwork between status changes and clock ticks. Touch gestures,
// movement between map cells and HUD changes redraw immediately. Input runs every
// step; health/ammo/cell changes, menus, transitions and missing surfaces redraw
// immediately. The gameplay output and its simulation are never gated here.
function dual_nano_reuse(_eligible, _cell_x, _cell_y) {
    dual_nano_clock_only = false;
    // The second window can be replaced while the GML surface survives.
    // Resume with a fresh submission instead of waiting for the next idle tick.
    if (current_time - dual_nano_last_call > 250 || current_time < dual_nano_last_call)
        dual_nano_dirty = true;
    dual_nano_last_call = current_time;
    if (!global.nano_enabled || !_eligible) {
        dual_nano_last_step = dual_steps;
        // This frame may contain a menu or transition instead of the idle map.
        dual_nano_previous = false;
        dual_nano_dirty = false;
        return false;
    }
    // gui_health also performs this clamp on an ordinary HUD cache hit.
    if (global.playerhealth < 0) gui_health();
    var _clock_second = floor(global.gametime / 60);
    var _same = dual_nano_last_health == global.playerhealth
        && dual_nano_last_ammo == global.missiles && dual_nano_last_super == global.smissiles
        && dual_nano_last_bombs == global.pbombs && dual_nano_last_weapon == global.currentweapon
        && dual_nano_last_items == global.itemstaken
        && dual_nano_last_monsters == global.monstersleft && dual_nano_last_area == global.monstersarea
        && dual_nano_last_cell_x == _cell_x && dual_nano_last_cell_y == _cell_y;
    if (dual_nano_previous && !dual_nano_dirty && _same && surface_exists(dual_surface)
        && surface_exists(dual_map) && surface_exists(dual_grid)
        && surface_exists(dual_art_surface) && surface_exists(dual_art_output)) {
        if (dual_nano_map_changed()) dual_next_map = 0;
        else {
            if (dual_nano_last_time == _clock_second && dual_steps - dual_nano_last_step < 60) return true;
            // The small rolling checks already cover the whole idle map within
            // 60 steps. Do not rescan all 6,400 cells on the clock's redraw frame.
            dual_nano_clock_only = true;
        }
    }
    dual_nano_previous = true;
    dual_nano_dirty = false;
    dual_nano_last_step = dual_steps;
    dual_nano_last_health = global.playerhealth;
    dual_nano_last_ammo = global.missiles;
    dual_nano_last_super = global.smissiles;
    dual_nano_last_bombs = global.pbombs;
    dual_nano_last_weapon = global.currentweapon;
    dual_nano_last_time = _clock_second;
    dual_nano_last_items = global.itemstaken;
    dual_nano_last_monsters = global.monstersleft;
    dual_nano_last_area = global.monstersarea;
    dual_nano_last_cell_x = _cell_x;
    dual_nano_last_cell_y = _cell_y;
    return false;
}

function dual_nano_map_changed() {
    var _cache = dual_map_columns_cache;
    if (!dual_map_valid || !_cache.ready) return true;
    // Two columns, then one, then one: 80 columns in 60 idle frames,
    // retaining the old scan budget without concentrating it into one frame.
    var _columns = (dual_nano_poll_column mod 4 == 0) ? 2 : 1;
    for (var _i = 0; _i < _columns; ++_i) {
        var _x = dual_nano_poll_column;
        dual_nano_poll_column = (_x + 1) mod 80;
        // Keep snapshots untouched: the full refresh still needs to discover
        // and repaint these edits. Item, health and cell changes bypass this.
        if (!array_equals(_cache.seen[_x], global.dmap[_x])
            || !array_equals(_cache.tiles[_x], global.map[_x])) return true;
    }
    return false;
}

/// @description Compose lower output, respecting the existing per-step guard.
/// @context oControl
function dual_draw() {
    // Compose once per game step even when an earlier draw route already submitted it.
    if (dual_lower_step == dual_steps) return;
    dual_lower_step = dual_steps;
    if (!dual_enabled) exit;
    var _escape = noone;
    if (instance_exists(oA4EscapeExplosion)) _escape = instance_find(oA4EscapeExplosion, 0);
    if (instance_exists(oA4EscapeExplosionFail)) _escape = instance_find(oA4EscapeExplosionFail, 0);
    var _room_changed = dual_output_room != room;
    // Submit each game frame so scrolling and touch panning keep the upper display's cadence.
    // Capture the last lower image before a transition room replaces its contents.
    if (_room_changed && room == rm_transition && surface_exists(dual_surface)) {
        if (!surface_exists(dual_room_surface)) dual_room_surface = surface_create(dual_width, dual_height);
        surface_copy(dual_room_surface, 0, 0, dual_surface);
    }
    dual_output_room = room;

    var _frontend = dual_frontend_mode();
    var _game = _frontend == DUAL_FRONTEND_GAMEPLAY && variable_global_exists("map") && variable_global_exists("mapposx")
        && (global.ingame || room == rm_subscreen || room == rm_transition || room == itemroom || room == rm_death);
    var _cell_x = _game ? global.mapposx : -1;
    var _cell_y = _game ? global.mapposy : -1;
    var _paused = room == rm_subscreen;
    var _ui_paused = _paused && (!instance_exists(oSS_Fg) || !oSS_Fg.fadeout);
    var _pause_map = _ui_paused && global.ssmode == 0 && !instance_exists(oSubScrChange);
    // When gameplay becomes available, reset map caches and return to following the player.
    if (_game && !dual_had_game) {
        dual_follow = true;
        dual_overview = false;
        dual_zoom = 1;
        dual_manual_zoom = 1;
        dual_next_map = 0;
        dual_map_valid = false;
        // Clear each field separately so the first map frame has no old area to fade from.
        dual_backdrop = -1;
        dual_backdrop_previous = -1;
        dual_lab_entrance = false;
        dual_previous_lab_entrance = false;
        dual_research_site = false;
        dual_previous_research_site = false;
        dual_waterfalls = false;
        dual_previous_waterfalls = false;
        dual_backdrop_room = -1;
    }
    dual_had_game = _game;

    var _nano_eligible = _game && global.ingame && global.enablecontrol && !_paused
        && !_room_changed && !dual_setup_needed && _escape == noone
        && room != rm_transition && room != rm_loading && room != itemroom && room != rm_death
        && current_time >= dual_transition_until && dual_room_alpha >= 1
        && (dual_backdrop_previous < 0 || current_time >= dual_backdrop_since + 600);
    if (dual_nano_reuse(_nano_eligible, _cell_x, _cell_y)) return;

    if (_game) {
        dual_update_backdrop();
        dual_art_geometry();
        if (dual_overview) {
            dual_center_x = (dual_map_min_x + dual_map_max_x) / 2;
            dual_center_y = (dual_map_min_y + dual_map_max_y) / 2;
            dual_zoom = dual_map_fit_zoom();
        }
        if (dual_follow) {
            // Exactly the minimap's integer cell, including room map offsets.
            dual_center_x = _cell_x + 0.5;
            dual_center_y = _cell_y + 0.5;
        }
        if (_pause_map && dual_marker_pan && global.mapmarker) {
            // Keep controller-edited markers visible without moving a touch-browsed map.
            var _half_x = (dual_width - 20) / (16 * dual_zoom);
            var _half_y = (dual_map_bottom - dual_map_top - 20) / (16 * dual_zoom);
            dual_center_x = clamp(dual_center_x, global.mapmarkerx + 0.5 - _half_x, global.mapmarkerx + 0.5 + _half_x);
            dual_center_y = clamp(dual_center_y, global.mapmarkery + 0.5 - _half_y, global.mapmarkery + 0.5 + _half_y);
        }
        dual_center_x = clamp(dual_center_x, 0, 80);
        dual_center_y = clamp(dual_center_y, 0, 80);
    }

    // Save the caller's font, color, alpha, and alignment before composing a frame for the ready window.
    if (DualScreen_Ready() == 1) {
        var _font = draw_get_font(), _color = draw_get_color(), _alpha = draw_get_alpha();
        var _ha = draw_get_halign(), _va = draw_get_valign();
        draw_set_alpha(1);
        draw_set_color(c_white);
        draw_set_halign(fa_left);
        draw_set_valign(fa_top);
        var _menu_key = _ui_paused ? (instance_exists(oSubScrChange) ? 4 : global.ssmode) : -1;
        if (!surface_exists(dual_surface)) {
            dual_surface = surface_create(dual_width, dual_height);
            dual_menu_key = _menu_key;
            dual_ui_paused = _ui_paused;
            dual_transition_until = 0;
        }
        if (_menu_key != dual_menu_key) {
            dual_art_snapshot();
            if (!surface_exists(dual_transition_surface)) dual_transition_surface = surface_create(dual_width, dual_height);
            // Blend from the actual last lower frame, including an interrupted fade.
            surface_copy(dual_transition_surface, 0, 0, dual_surface);
            dual_transition_kind = _ui_paused == dual_ui_paused ? 0 : (_ui_paused ? 1 : 2);
            dual_menu_key = _menu_key;
            dual_ui_paused = _ui_paused;
            dual_transition_until = current_time + 160;
        }
        dual_art_prepare(_game, _frontend, _ui_paused, _pause_map);
        // Reuse a fixed pixel-transfer buffer and lazily create the grid and map surfaces.
        if (!buffer_exists(dual_buffer)) dual_buffer = buffer_create(dual_width * dual_height * 4, buffer_fixed, 1);
        if (!surface_exists(dual_grid)) {
            dual_grid = effect_surface_create(192, 192);
            surface_set_target(dual_grid);
            draw_clear(c_black);
            for (var _gx = 0; _gx < 192; _gx += 24) {
                for (var _gy = 0; _gy < 192; _gy += 24) draw_background(bgMapScreenBG, _gx, _gy);
            }
            surface_reset_target();
        }
        if (!surface_exists(dual_map)) {
            dual_map = effect_surface_create(640, 640);
            dual_map_valid = false;
            dual_next_map = 0;
        }
        if (_game && !dual_nano_clock_only
            && (current_time >= dual_next_map || _cell_x != dual_last_cell_x || _cell_y != dual_last_cell_y)) {
            dual_next_map = current_time + 250;
            dual_last_cell_x = _cell_x;
            dual_last_cell_y = _cell_y;
            // Poll the original data, including item and monster changes made by
            // existing objects. Repaint only when visible tile content has changed.
            if (dual_map_columns_changed()) dual_map_repaint_cached_columns();
        }
        if (_game) dual_compact_map_update();

        // Retain the pre-death lower image, then draw the active setup, menu, transition, or gameplay panel.
        dual_frontend_snapshot(_frontend);
        surface_set_target(dual_surface);
        draw_clear(c_black);
        var _lower_matrix = matrix_get(matrix_world);
        matrix_set(matrix_world, matrix_build(dual_pad, 0, 0, 0, 0, 0, 1, 1, 1));
        draw_set_font(fontMenuSmall);
        if (dual_setup_needed) {
            matrix_set(matrix_world, matrix_build((dual_width - 320) / 2, floor((dual_height - 240) / 2), 0, 0, 0, 0, 1, 1, 1));
            dual_setup_draw_page(false);
        } else if (room == rm_transition) {
            // Keep the map visible between game rooms; retain fades for loading and Game Over.
            if (!dual_loading_transition && surface_exists(dual_room_surface) && instance_exists(oTransition)) {
                draw_surface_ext(dual_room_surface, -dual_pad, 0, 1, 1, 0, c_white,
                    dual_keep_room_map ? 1 : 1 - clamp(oTransition.fade, 0, 1));
            }
        } else if (room == rm_loading) {
            // Loading can replace rooms before they have produced their first image.
            // Both panels remain black until the destination begins its fade-in.
        } else if (dual_draw_frontend_lower(_frontend)) {
            // The shared scene owns these panels; gameplay chrome stays hidden.
        } else if (_ui_paused && !_pause_map && surface_exists(application_surface)) {
            // Trim only the five-pixel side margins; resampling the 320-pixel page
            // into 310 pixels deletes columns from lettering and equipment artwork.
            // The original page has flat border pixels outside its artwork.
            // Extend those columns on wider panels, including their exact bar
            // positions and fade, without resampling the text or illustrations.
            var _page_margin = (dual_width - surface_get_width(application_surface)) / 2;
            if (_page_margin > 0) {
                var _page_height = surface_get_height(application_surface);
                draw_surface_part_ext(application_surface, 0, 0, 1, _page_height,
                    -dual_pad, dual_page_y, _page_margin, 1, c_white, 1);
                draw_surface_part_ext(application_surface, surface_get_width(application_surface) - 1, 0, 1, _page_height,
                    315, dual_page_y, _page_margin, 1, c_white, 1);
            }
            draw_surface(application_surface, -5, dual_page_y);
            if (dual_art_footer_rows > 0) {
                draw_set_color(c_black);
                draw_rectangle(-dual_pad, dual_art_page_controls_top(),
                    310 + dual_pad, dual_height, false);
            }
            if (!instance_exists(oSubScrChange)) {
                dual_toolbar_button(dual_action_buttons[0], "SELECT", false, dual_art_page_controls_top(), dual_height - 1, get_button_sprite("Menu1"));
                dual_toolbar_button(dual_action_buttons[1], "MENU", false, dual_art_page_controls_top(), dual_height - 1, get_button_sprite("Menu2"));
            }
            dual_toolbar_button(dual_action_buttons[2], "RESUME", false, dual_art_page_controls_top(), dual_height - 1, get_button_sprite("Start"));
        } else if (_game) {
            var _ox = round(155 - dual_center_x * 8 * dual_zoom);
            var _oy = round((dual_map_top + dual_map_bottom) / 2 - dual_center_y * 8 * dual_zoom);
            dual_draw_map_base(_ox, _oy);
            var _marker_scale = max(0.75, dual_zoom);
            draw_sprite_ext(sMapHilight, 0, round(_ox + (_cell_x + 0.5) * 8 * dual_zoom - 4 * _marker_scale),
                round(_oy + (_cell_y + 0.5) * 8 * dual_zoom - 4 * _marker_scale),
                _marker_scale, _marker_scale, 0, c_white, global.nano_enabled && !_paused ? 0.8 : 0.55 + 0.35 * sin(current_time / 250));
            if (global.mapmarker) {
                var _marker_x = round(_ox + (global.mapmarkerx + 0.5) * 8 * dual_zoom - 4 * _marker_scale);
                var _marker_y = round(_oy + (global.mapmarkery + 0.5) * 8 * dual_zoom - 4 * _marker_scale);
                draw_sprite_ext(sMapMarker, global.nano_enabled && !_paused ? 0 : markfr, _marker_x, _marker_y, _marker_scale, _marker_scale, 0, c_white, 1);
                if (_pause_map && instance_exists(oMapCursor) && oMapCursor.state == 1) {
                    draw_sprite_ext(sMapMarkerMove, markfr, _marker_x, _marker_y, _marker_scale, _marker_scale, 0, c_white, 1);
                }
            }
            // Reserve the chosen HUD height above the map and one context-sensitive toolbar below it.
            draw_set_color(c_black);
            draw_rectangle(-dual_pad, 0, 310 + dual_pad, dual_map_top - 1, false);
            draw_rectangle(-dual_pad, dual_map_bottom, 310 + dual_pad, dual_height, false);
            draw_set_font(fontMenuSmall);
            // Fanfare and scripted scenes keep their original input locks.
            draw_set_alpha(_paused || (global.ingame && global.enablecontrol && room != rm_transition) ? 1 : 0.4);
            if (_pause_map) {
                var _editing = instance_exists(oMapCursor) && oMapCursor.state == 1;
                var _marker = _editing ? "DONE" : (global.mapmarker ? "EDIT" : "MARKER");
                dual_toolbar_button(dual_action_buttons[0], _marker, false, dual_art_map_controls_top(), dual_height - 1, get_button_sprite("Menu1"));
                dual_toolbar_button(dual_action_buttons[1], _editing ? "DELETE" : "MENU", false, dual_art_map_controls_top(), dual_height - 1, get_button_sprite("Menu2"));
                dual_toolbar_button(dual_action_buttons[2], "UNPAUSE", false, dual_art_map_controls_top(), dual_height - 1, get_button_sprite("Start"));
            } else {
                dual_toolbar_button(dual_map_buttons[0], "+", false);
                dual_toolbar_button(dual_map_buttons[1], "-", false);
                dual_toolbar_button(dual_map_buttons[2], "1x", false);
                dual_toolbar_button(dual_map_buttons[3], "FIT MAP", dual_overview);
                dual_toolbar_button(dual_map_buttons[4], "FOLLOW", dual_follow);
            }
            draw_set_alpha(1);
        }
        // Return to the original drawing transform before blending whole-panel transitions and fades.
        matrix_set(matrix_world, _lower_matrix);
        var _old_alpha = clamp((dual_transition_until - current_time) / 160, 0, 1);
        if (dual_transition_kind == 1) _old_alpha = _ui_paused ? 1 - dual_pause_blend() : 0;
        if (dual_transition_kind == 2) _old_alpha = _paused ? dual_pause_blend() : 0;
        if (room != rm_transition && room != rm_loading && _frontend == DUAL_FRONTEND_GAMEPLAY
            && _old_alpha > 0 && surface_exists(dual_transition_surface)) {
            draw_surface_ext(dual_transition_surface, 0, 0, 1, 1, 0, c_white, _old_alpha);
        }
        if (!dual_setup_needed && !dual_keep_room_map && room != rm_transition && dual_room_alpha < 1) {
            draw_set_color(c_black);
            draw_set_alpha(1 - dual_room_alpha);
            draw_rectangle(0, 0, dual_width, dual_height, false);
            draw_set_alpha(1);
        }
        // Both panels follow the reactor's existing white flash, including a failed escape.
        if (_escape != noone) {
            var _mode = gpu_get_blendmode();
            gpu_set_blendmode(bm_add);
            draw_set_color(c_white);
            // The blast brightens gameplay before the white fade starts; mirror that glow below too.
            if (!_escape.fadeout) {
                var _camera = widescreen ? 1 : 0;
                var _sx = dual_width / __view_get(e__VW.WView, _camera);
                var _sy = dual_height / __view_get(e__VW.HView, _camera);
                var _x = (_escape.x - __view_get(e__VW.XView, _camera)) * _sx;
                var _y = (_escape.y - __view_get(e__VW.YView, _camera)) * _sy;
                var _xs = _escape.image_xscale * _sx, _ys = _escape.image_yscale * _sy;
                var _sprite = _escape.sprite_index, _frame = _escape.image_index;
                draw_sprite_ext(_sprite, _frame, _x, _y, _xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
                draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, _ys, _escape.image_angle, c_white, _escape.image_alpha);
                draw_sprite_ext(_sprite, _frame, _x, _y, -_xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
                draw_sprite_ext(_sprite, _frame, _x, _y, _xs, -_ys, _escape.image_angle, c_white, _escape.image_alpha);
            }
            draw_set_alpha(clamp(_escape.whitealpha, 0, 1));
            draw_rectangle(0, 0, dual_width, dual_height, false);
            gpu_set_blendmode(_mode);
            draw_set_alpha(1);
        }
        // Capture the lower target before its normal reset flushes drawing.
        // When swapped, the final GUI End event sends the complete gameplay image instead.
        // Retain this native map and its separate full-resolution HUD for the runner.
        var _swap = dual_swap_active();
        var _sent = !_swap && DualScreen_Begin() == 1;
        if (_sent) DualScreen_Draw(dual_x, dual_y, dual_width * dual_scale, dual_height * dual_scale, 0, 0, 1, 1, 1, 0);
        surface_reset_target();
        dual_art_finish(_old_alpha, _frontend, _escape, _sent);
        if (_sent) _sent = DualScreen_End() == 1;
        // An unsupported or unavailable GPU path always falls back to the existing output.
        if (!_sent && !_swap) {
            dual_art_fallback();
            buffer_get_surface(dual_buffer, dual_surface, 0);
            DualScreen_Frame(dual_buffer, dual_width, dual_height);
        }
        // Count calls to the frame bridge here; Android records bitmap updates separately.
        if (!_swap) dual_frames++;
        draw_set_font(_font); draw_set_color(_color); draw_set_alpha(_alpha);
        draw_set_halign(_ha); draw_set_valign(_va);
    } else {
        // A recreated window may become ready on a later frame.
        dual_nano_dirty = true;
    }
}

// Release oControl's drawing surfaces and transfer buffer when its Cleanup event runs.
/// @description Release display surfaces, buffers and cached controller images.
/// @context oControl
function dual_cleanup() {
    if (surface_exists(dual_map_base)) surface_free(dual_map_base);
    dual_map_base_key = [];
    dual_art_reset_images();
    if (surface_exists(dual_upper_hud_surface)) surface_free(dual_upper_hud_surface);
    if (buffer_exists(dual_upper_hud_buffer)) buffer_delete(dual_upper_hud_buffer);
    if (surface_exists(dual_pause_surface)) surface_free(dual_pause_surface);
    if (surface_exists(dual_setup_surface)) surface_free(dual_setup_surface);
    if (surface_exists(dual_scene)) surface_free(dual_scene);
    if (surface_exists(dual_room_surface)) surface_free(dual_room_surface);
    if (surface_exists(dual_death_surface)) surface_free(dual_death_surface);
    if (surface_exists(dual_surface)) surface_free(dual_surface);
    if (surface_exists(dual_map)) surface_free(dual_map);
    if (surface_exists(dual_map_column)) surface_free(dual_map_column);
    if (surface_exists(dual_compact_strip)) surface_free(dual_compact_strip);
    if (surface_exists(dual_compact_map)) surface_free(dual_compact_map);
    if (surface_exists(dual_grid)) surface_free(dual_grid);
    if (surface_exists(dual_hud_sheet)) surface_free(dual_hud_sheet);
    if (surface_exists(dual_art_hold)) surface_free(dual_art_hold);
    if (surface_exists(dual_art_surface)) surface_free(dual_art_surface);
    if (dual_art_help_font >= 0) font_delete(dual_art_help_font);
    if (surface_exists(dual_transition_surface)) surface_free(dual_transition_surface);
    if (buffer_exists(dual_buffer)) buffer_delete(dual_buffer);
}
