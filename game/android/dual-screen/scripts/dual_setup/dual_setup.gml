// Second-screen choice, first-run setup and the layout for the screens in use.
// Runs in oControl scope. The saved option values are stable interfaces.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

// Call before load_gameoptions, which reads dual_enabled.
function dual_settings_load() {
    ini_open("config.ini");
    // Earlier Dual Screen builds saved a hardware profile, and a swap option for two of them.
    var _profile = ini_read_real("DualScreen", "DeviceProfile", -1);
    var _swap = 0;
    if (_profile == 1) _swap = ini_read_real("DualScreen", "RGDSSwapScreens", 0);
    if (_profile == 2) _swap = ini_read_real("DualScreen", "RetroidAddon", 0);
    dual_choice = ini_read_real("DualScreen", "Enabled", _profile >= 0 ? 1 : -1);
    dual_swap_screens = ini_read_real("DualScreen", "SwapScreens", _swap) == 1;
    ini_close();

    dual_available = DualScreen_Available() == 1;
    dual_enabled = dual_available && dual_choice != 0;
    dual_setup_needed = dual_enabled && dual_choice < 0;
    // gmloader-next returns 0 when it can't open the window.
    if (DualScreen_Enable(dual_enabled) != 1) dual_enabled = false;
    if (!dual_enabled) {
        dual_setup_needed = false;
        return;
    }
    DualScreen_Swap(dual_swap_screens);
}

function dual_settings_save() {
    ini_open("config.ini");
    ini_write_real("DualScreen", "Enabled", dual_choice);
    ini_write_real("DualScreen", "SwapScreens", dual_swap_screens ? 1 : 0);
    ini_close();
}

function dual_set_enabled(_enabled) {
    if (DualScreen_Enable(_enabled) != 1) return;
    dual_enabled = _enabled;
    dual_choice = _enabled ? 1 : 0;
    dual_settings_save();
    if (dual_enabled) {
        DualScreen_Swap(dual_swap_screens);
        with (oTouchControls) instance_destroy();
        // Force a new layout and restart the map.
        dual_window_width = 0;
        dual_had_game = false;
        dual_layout_update();
        if (room == rm_subscreen) dual_pause_begin();
    } else {
        if (os_type == os_android) instance_create(0, 0, oTouchControls);
        if (global.android_app) Android_Orientation(global.oporientation);
        if (dual_aspect_locked) {
            dual_aspect_locked = false;
            if (room != rm_subscreen) standard_aspect_apply(aspect_ratio);
        }
    }
}

// The pause pages are 4:3, on the lower screen.
function dual_pause_begin() {
    if (dual_paused) return;
    dual_pause_width = 320 + widescreen_space;
    dual_pause_direction_ready = false;
    dual_paused = true;
    widescreen = false;
    widescreen_space = 0;
    __view_set(e__VW.Visible, 1, false);
}

function dual_pause_end() {
    if (!dual_paused) return;
    dual_paused = false;
    standard_aspect_apply(aspect_ratio);
}

function dual_setup_hit(_x, _y) {
    if (_x < 36 || _x > 284) return -1;
    for (var _i = 0; _i < 3; ++_i) {
        if (_y >= 112 + 32 * _i && _y <= 136 + 32 * _i) return _i;
    }
    return -1;
}

function dual_setup_step() {
    // Require the opening confirm or direction buttons to be released before setup can accept a choice.
    if (!dual_setup_ready) {
        dual_setup_ready = !(kMenu1 || kMenu2 || kStart || kUp || kDown);
        dual_setup_tap = -1;
        return;
    }
    var _previous_choice = dual_setup_choice;
    if (kUp && kUpPushedSteps == 0) dual_setup_choice = wrap(dual_setup_choice - 1, 0, 2);
    if (kDown && kDownPushedSteps == 0) dual_setup_choice = wrap(dual_setup_choice + 1, 0, 2);
    if (dual_setup_choice != _previous_choice) sfx_play(sndMenuMove);
    if (device_mouse_check_button_pressed(0, mb_left)) {
        var _scale = max(1, floor(min(window_get_width() / 320, window_get_height() / 240)));
        var _x = (device_mouse_x_to_gui(0) - round((window_get_width() - 320 * _scale) / 2)) / _scale;
        var _y = (device_mouse_y_to_gui(0) - round((window_get_height() - 240 * _scale) / 2)) / _scale;
        dual_setup_tap = dual_setup_hit(_x, _y);
    }
    var _confirm = (kMenu1 && kMenu1PushedSteps == 0) || (kStart && kStartPushedSteps == 0);
    if (dual_setup_tap >= 0) {
        dual_setup_choice = dual_setup_tap;
        _confirm = true;
    }
    dual_setup_tap = -1;
    if (!_confirm) return;
    sfx_play(sndMenuSel);
    if (dual_setup_choice == 1) {
        // Preview the output route without saving an unfinished setup.
        dual_swap_screens = !dual_swap_screens;
        dual_lower_step = -1;
        DualScreen_Swap(dual_swap_screens);
        dual_setup_choice = 0;
        dual_setup_ready = false;
        return;
    }
    dual_setup_finish(dual_setup_choice == 0);
}

function dual_setup_finish(_use) {
    // A saved choice skips setup; later user choices are never overridden.
    dual_choice = _use ? 1 : 0;
    dual_enabled = _use;
    DualScreen_Enable(_use);
    // Devices with a 640x480 second screen need Nano.
    if (_use && DualScreen_Width() <= 640) global.nano_enabled = true;
    dual_settings_save();
    save_gameoptions();
    dual_setup_needed = false;
    if (surface_exists(dual_setup_surface)) surface_free(dual_setup_surface);
    dual_setup_surface = -1;
    // Resume the original startup event only after a choice is saved.
    alarm[0] = 1;
}

function dual_draw_setup_upper() {
    if (!dual_setup_needed) return false;
    if (!surface_exists(dual_setup_surface)) dual_setup_surface = surface_create(320, 240);
    // Draw the setup page into a native-size surface.
    var _matrix = matrix_get(matrix_world);
    var _font = draw_get_font(), _color = draw_get_color(), _alpha = draw_get_alpha();
    var _ha = draw_get_halign(), _va = draw_get_valign();
    matrix_set(matrix_world, matrix_build_identity());
    surface_set_target(dual_setup_surface);
    draw_clear(c_black);
    dual_setup_draw_page(true);
    surface_reset_target();
    var _scale = max(1, floor(min(window_get_width() / 320, window_get_height() / 240)));
    draw_surface_ext(dual_setup_surface, round((window_get_width() - 320 * _scale) / 2),
        round((window_get_height() - 240 * _scale) / 2), _scale, _scale, 0, c_white, 1);
    matrix_set(matrix_world, _matrix);
    draw_set_font(_font); draw_set_color(_color); draw_set_alpha(_alpha);
    draw_set_halign(_ha); draw_set_valign(_va);
    return true;
}

function dual_setup_draw_page(_gameplay) {
    draw_set_alpha(1);
    draw_set_font(fontGUI2);
    draw_set_halign(fa_center); draw_set_valign(fa_middle);
    draw_set_color(make_color_rgb(12, 52, 4));
    draw_rectangle(0, 22, 320, 44, false);
    draw_set_color(c_white);
    draw_text(160, 33, port_caption("CHECK SCREEN ORDER"));
    draw_text(160, 66, _gameplay ? port_caption("GAMEPLAY") : port_caption("MAP AND MENUS"));
    draw_set_font(fontMenuSmall);
    draw_text(160, 88, port_caption("Gameplay above, map below."));
    draw_set_font(fontGUI2);
    var _labels = ["KEEP THIS ORDER", "SWAP DISPLAYS", "USE ONE SCREEN"];
    for (var _i = 0; _i < 3; ++_i) {
        var _top = 112 + _i * 32;
        draw_set_color(_i == dual_setup_choice ? make_color_rgb(16, 72, 4) : make_color_rgb(3, 16, 2));
        draw_rectangle(36, _top, 284, _top + 24, false);
        draw_set_color(_i == dual_setup_choice ? make_color_rgb(100, 240, 80) : make_color_rgb(24, 72, 12));
        draw_rectangle(36, _top, 284, _top + 24, true);
        draw_set_color(c_white);
        draw_text(160, _top + 12, port_caption(_labels[_i]));
    }
    draw_set_font(fontMenuSmall);
    draw_text(160, 218, port_caption("Change this later in Display settings."));
}

function dual_apply_hud_layout() {
    // Top placement leaves only the title/counter row above the map.
    dual_map_top = ceil(dual_art_header_rows() * dual_art_scale);
    dual_map_bottom = dual_height - ceil(31 * dual_art_scale);
    dual_layout_controls();
    dual_next_map = 0;
}

// Screens can be resized, swapped or reconnected while the game runs.
function dual_layout_update() {
    if (dual_steps mod 15 == 0) standard_aspect_auto();
    if (!dual_enabled) return;
    var _window_width = window_get_width(), _window_height = window_get_height();
    // DualScreen_Width and DualScreen_Height call into Java, so check them four times a second.
    if (_window_width == dual_window_width && _window_height == dual_window_height
        && dual_swap_screens == dual_layout_swap && dual_steps mod 15 != 0) return;
    var _screen_width = DualScreen_Width(), _screen_height = DualScreen_Height();
    if (_window_width < 1 || _window_height < 1 || _screen_width < 1 || _screen_height < 1) return;
    if (_window_width == dual_window_width && _window_height == dual_window_height
        && _screen_width == dual_screen_width && _screen_height == dual_screen_height
        && dual_swap_screens == dual_layout_swap) return;
    dual_window_width = _window_width;
    dual_window_height = _window_height;
    dual_screen_width = _screen_width;
    dual_screen_height = _screen_height;
    dual_layout_swap = dual_swap_screens;
    dual_layout_apply();
}

// Fit the lower canvas, toolbar, pause-page origin, and shared scene to the screens.
function dual_layout_apply() {
    var _map_width = dual_swap_screens ? dual_window_width : dual_screen_width;
    var _map_height = dual_swap_screens ? dual_window_height : dual_screen_height;
    var _game_aspect = dual_swap_screens ? dual_screen_width / dual_screen_height
        : dual_window_width / dual_window_height;
    dual_scene_width = clamp(2 * round(120 * _game_aspect), 320, 426);
    // A whole-number scale keeps pixels square. The layout needs 310x240.
    dual_scale = max(1, floor(min(_map_width / 310, _map_height / 240)));
    dual_width = clamp(ceil(_map_width / dual_scale), 310, dual_scene_width);
    dual_height = clamp(ceil(_map_height / dual_scale), 240, 320);
    dual_x = floor((_map_width - dual_width * dual_scale) / 2);
    dual_y = floor((_map_height - dual_height * dual_scale) / 2);
    dual_pad = (dual_width - 310) / 2;
    // Taller canvases have room for the buttons below the pause page.
    dual_page_y = dual_height >= 270 ? 0 : floor((dual_height - 240) / 2);
    // A 4:3 main screen has no room for a wider view.
    var _locked = _game_aspect < 1.4;
    if (_locked != dual_aspect_locked) {
        dual_aspect_locked = _locked;
        if (room != rm_subscreen) standard_aspect_apply(aspect_ratio);
    }
    dual_layout_controls();
    dual_map_bottom = dual_height - 38;
    dual_apply_hud_layout();
    // The native menu and its touch sectors share the fixed page frame.
    dual_menu_center_y = 121;
    dual_art_reset_images();
    // Discard images and transfer storage whose dimensions belong to the previous layout.
    if (surface_exists(dual_surface)) surface_free(dual_surface);
    if (surface_exists(dual_transition_surface)) surface_free(dual_transition_surface);
    if (surface_exists(dual_death_surface)) surface_free(dual_death_surface);
    if (surface_exists(dual_scene)) surface_free(dual_scene);
    if (surface_exists(dual_room_surface)) surface_free(dual_room_surface);
    if (buffer_exists(dual_buffer)) buffer_delete(dual_buffer);
    dual_surface = dual_transition_surface = dual_death_surface = dual_scene = dual_buffer = -1;
    dual_room_surface = -1;
    dual_output_room = -1;
    dual_transition_until = 0;
}

function dual_swap_active() {
    return dual_enabled && dual_swap_screens && DualScreen_Ready() == 1;
}

function dual_swap_set(_enabled) {
    if (!dual_enabled) return;
    dual_swap_screens = _enabled;
    dual_lower_step = -1;
    dual_settings_save();
    DualScreen_Swap(dual_swap_screens);
}
