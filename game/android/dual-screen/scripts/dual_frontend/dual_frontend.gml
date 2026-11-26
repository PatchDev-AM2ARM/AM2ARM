// Keep the same scene codes when routing the two displays.
#macro DUAL_FRONTEND_GAMEPLAY 0
#macro DUAL_FRONTEND_TITLE 1
#macro DUAL_FRONTEND_MENU 2
#macro DUAL_FRONTEND_CREDITS 3
#macro DUAL_FRONTEND_DEATH 4

/// Shared native-pixel scene for title and credits; the panels sample adjacent regions.
function dual_frontend_mode() {
    if (room == rm_death || room == gameoverroom) return DUAL_FRONTEND_DEATH;
    if (room == rm_credits) return DUAL_FRONTEND_CREDITS;
    // Preserve panel roles through a title/menu fade, including while a save starts loading.
    if (room == rm_transition) {
        if (dual_frontend_previous_mode == DUAL_FRONTEND_TITLE || dual_frontend_previous_mode == DUAL_FRONTEND_MENU) return DUAL_FRONTEND_MENU;
        if (dual_frontend_previous_mode == DUAL_FRONTEND_DEATH) return DUAL_FRONTEND_DEATH;
        return DUAL_FRONTEND_GAMEPLAY;
    }
    if (room == titleroom) return instance_exists(oGameSelMenu) ? DUAL_FRONTEND_MENU : DUAL_FRONTEND_TITLE;
    if (!global.ingame && (room == rm_options || room == rm_gameplay || room == rm_gallery)) return DUAL_FRONTEND_MENU;
    return DUAL_FRONTEND_GAMEPLAY;
}

function dual_title_scroll() {
    return round(clamp(dual_title_offset / 400, 0, 1) * max(0, sprite_get_height(sTitleAnimated) - 240 - dual_height));
}

// Route lower-panel gestures according to the same title, menu, credits, or death mode used for drawing.
function dual_frontend_input(_input) {
    var _mode = dual_frontend_mode();
    if (_mode != DUAL_FRONTEND_TITLE) dual_title_press_frames = 0;
    if (_mode == DUAL_FRONTEND_GAMEPLAY) return false;
    if (room == rm_transition) return true;
    if (_mode == DUAL_FRONTEND_TITLE) {
        // The original intro recognizes the second held frame; retain that path
        // for a quick tap, then release before a later tap opens file selection.
        if (_input.tap) dual_title_press_frames = 2;
        if (dual_title_press_frames > 0) {
            ctrl_Start = 1;
            dual_title_press_frames--;
        }
        return true;
    }
    // Pass a credits tap through the existing Back control; the credits object still decides whether skipping is allowed.
    if (_mode == DUAL_FRONTEND_CREDITS) { if (_input.tap) ctrl_Menu2 = 1; return true; }
    if (_mode != DUAL_FRONTEND_MENU) return true;
    if (_input.tap && room == titleroom && instance_exists(oGameSelMenu) && oGameSelMenu.active) {
        // A first tap selects a file; a second tap opens its existing load/copy/erase menu.
        var _px = _input.x + 5;
        for (var _i = 0; _i < 3; ++_i) {
            var _slot = oGameSelMenu.op[_i];
            if (_px >= _slot.x - 19 && _px <= _slot.x + 207 && _input.y - dual_page_y >= _slot.y - 9 && _input.y - dual_page_y <= _slot.y + 24) {
                if (global.curropt == _i) ctrl_Menu1 = 1;
                else { global.curropt = _i; global.saveslot = _i; sfx_play(sndMenuMove); }
            }
        }
    }
    return true;
}

// Choose the active menu's Exit row and synthesize Select so its normal save-and-close path runs.
function frontend_back() {
    // Original settings pages only handle Select on their Exit row.
    // Use that path for controller Back, including saving changed options.
    if (!ctrl_Menu2 || kMenu2 || room == rm_transition || dual_frontend_mode() != DUAL_FRONTEND_MENU) return;
    var _menus = [oOptionsDisplay, oOptionsSound, oOptionsControl, oOptionsExtras,
        oOptionsData, oOptionsGame, oOptionsJoypad, oOptionsXJoypad,
        oOptionsMogaJoypad, oOptionsKeyboard, oOptionsMain];
    for (var _i = 0; _i < array_length(_menus); ++_i) {
        var _menu = instance_find(_menus[_i], 0);
        if (_menu == noone || !_menu.active) continue;
        // A controller binding capture must still receive its chosen button.
        if (variable_instance_exists(_menu, "editing") && _menu.editing) return;
        global.curropt = variable_instance_exists(_menu, "menuSize") ? _menu.menuSize : _menu.lastitem;
        ctrl_Menu1 = 1;
        return;
    }
    if (instance_exists(oGalleryMenu) && oGalleryMenu.active) {
        if (oGalleryMenu.state == 1) global.curropt = 3;
        ctrl_Menu1 = 1;
    }
}

function dual_frontend_scene(_mode) {
    // Title artwork keeps its native width. The upper slice has its own 240px
    // height; a taller lower panel must not narrow the upper widescreen image.
    var _upper_height = 240;
    var _scene_width = dual_scene_width;
    var _scene_center = _scene_width / 2;
    var _page_x = (_scene_width - 320) / 2;
    var _page_y = (_upper_height - 240) / 2;
    var _scene_height = _upper_height + dual_height;
    // Resize the shared scene only when its dimensions change, then save drawing state for restoration.
    if (surface_exists(dual_scene) && (surface_get_width(dual_scene) != _scene_width
        || surface_get_height(dual_scene) != _scene_height)) surface_free(dual_scene);
    if (!surface_exists(dual_scene)) dual_scene = surface_create(_scene_width, _scene_height);
    var _matrix = matrix_get(matrix_world);
    var _font = draw_get_font(), _color = draw_get_color(), _alpha = draw_get_alpha();
    var _ha = draw_get_halign(), _va = draw_get_valign();
    matrix_set(matrix_world, matrix_build_identity());
    surface_set_target(dual_scene);
    draw_clear(c_black);
    draw_set_alpha(1);
    draw_set_valign(fa_top);
    if (_mode == DUAL_FRONTEND_CREDITS && instance_exists(oCreditsText)) {
        // The existing object remains the sole clock for music, flyby, scrolling and fades.
        // Two whole pixels per backdrop pixel fill the taller scene without repeating the planet.
        draw_background_ext(bgIntroSC2, round((_scene_width - sprite_get_width(bgIntroSC2) * 2) / 2), 0, 2, 2, 0, c_white, 1);
        with (oCreditsShip) {
            draw_sprite_ext(sprite_index, image_index, round(x) + _page_x, round(y) + _page_y,
                image_xscale, image_yscale, image_angle, image_blend, image_alpha);
        }
        with (oCreditsText) {
            // Start in the lower panel and settle the last line above, at the original time.
            var _progress = clamp((ystart - y) / max(1, TEXT_ROWS * 12 - 8), 0, 1);
            var _text_y = round(y + _upper_height + 31 - (_upper_height - 4) * _progress);
            draw_set_font(fontGUI2);
            draw_set_halign(fa_right);
            draw_cool_text(_scene_center - 12, _text_y, textLeft, c_black, c_white, c_white, image_alpha);
            draw_set_halign(fa_left);
            draw_cool_text(_scene_center + 12, _text_y, textRight, c_black, c_white, c_white, image_alpha);
            draw_set_halign(fa_center);
            draw_cool_text(_scene_center, _text_y, textCenter, c_black, c_white, c_white, image_alpha);
            draw_cool_text(_scene_center, _text_y, textHeader, c_black, c_dkgray, c_gray, image_alpha);
            draw_set_alpha(1);
            draw_set_color(c_black);
            var _upper_open = round(yoffset * _upper_height / 120);
            var _lower_open = round(yoffset * oControl.dual_height / 120);
            draw_rectangle(0, 0, _scene_width, _upper_height - _upper_open, false);
            draw_rectangle(0, _upper_height + _lower_open, _scene_width, _scene_height, false);
        }
    } else {
        if (instance_exists(oTitleAnimation)) {
            dual_title_offset = oTitleAnimation.bgyoff;
            dual_title_frame = oTitleAnimation.subim;
        }
        draw_sprite(sTitleAnimated, dual_title_frame, floor((_scene_width - sprite_get_width(sTitleAnimated)) / 2), -dual_title_scroll());
        draw_set_alpha(1);
        // Draw title lettering into the upper region and start prompts into the adjacent lower region.
        matrix_set(matrix_world, matrix_build(_page_x, _page_y, 0, 0, 0, 0, 1, 1, 1));
        with (oTitleText1) if (visible) event_perform(ev_draw, 0);
        with (oTitleText2) if (visible) event_perform(ev_draw, 0);
        matrix_set(matrix_world, matrix_build(_page_x, _upper_height, 0, 0, 0, 0, 1, 1, 1));
        with (oPressStart) if (visible) event_perform(ev_draw, 0);
        with (oPressStart2) if (visible) event_perform(ev_draw, 0);
    }
    surface_reset_target();
    matrix_set(matrix_world, _matrix);
    draw_set_font(_font); draw_set_color(_color); draw_set_alpha(_alpha);
    draw_set_halign(_ha); draw_set_valign(_va);
}

function dual_draw_frontend_upper() {
    if (!dual_enabled) return false;
    var _mode = dual_frontend_mode();
    if (room != rm_transition) dual_frontend_previous_mode = _mode;
    if (_mode < DUAL_FRONTEND_TITLE || _mode > DUAL_FRONTEND_CREDITS) return false;
    // Build the shared scene, then scale only its upper slice to this window, in the chosen ratio.
    dual_frontend_scene(_mode);
    dual_draw();
    var _full_width = surface_get_width(dual_scene);
    var _scene_width = min(_full_width, standard_aspect_width(global.opaspectratio));
    var _upper_height = surface_get_height(dual_scene) - dual_height;
    var _scale = android_display_scale(_scene_width, _upper_height);
    var _scene_x = round((window_get_width() - _scene_width * _scale) / 2);
    var _scene_y = round((window_get_height() - _upper_height * _scale) / 2);
    dual_swap_capture_area(_scene_x, _scene_y, _scene_width * _scale, _upper_height * _scale);
    var _sharp = sharp_scale_begin(dual_scene, _scale);
    draw_surface_part_ext(dual_scene, (_full_width - _scene_width) / 2, 0, _scene_width, _upper_height,
        _scene_x, _scene_y,
        _scale, _scale, c_white, instance_exists(oTransition) ? 1 - clamp(oTransition.fade, 0, 1) : 1);
    sharp_scale_end(_sharp);
    if (_mode != DUAL_FRONTEND_CREDITS) {
        // Keep the version inside the title picture, including a centered 4:3 one.
        var _font = draw_get_font(), _color = draw_get_color(), _alpha = draw_get_alpha();
        var _ha = draw_get_halign(), _va = draw_get_valign();
        // The original object fades away to create file selection. The upper logo
        // stays in place while the lower prompt gives way to those save cards.
        var _label_alpha = instance_exists(oDrawTitleBG)
            ? (oDrawTitleBG.fadeout ? 1 : oDrawTitleBG.image_alpha) : (_mode == DUAL_FRONTEND_MENU ? 1 : 0);
        if (instance_exists(oTransition)) _label_alpha *= 1 - clamp(oTransition.fade, 0, 1);
        // Fit the supplied lettering, excluding its transparent outer padding.
        // Draw directly on every upper panel so RG DS also keeps the full detail.
        var _logo_width = 1618, _logo_height = 447;
        var _logo_in_picture = dual_swap_active() || _scene_width < _full_width;
        var _logo_window_width = _logo_in_picture ? _scene_width * _scale : window_get_width();
        var _logo_window_height = _logo_in_picture ? _upper_height * _scale : window_get_height();
        var _logo_scale = min(_logo_window_width * 0.82 / _logo_width,
            _logo_window_height * 0.52 / _logo_height);
        var _logo_filter = gpu_get_texfilter();
        gpu_set_texfilter(true);
        draw_sprite_part_ext(sDualScreenTitle, 0, 8, 245, _logo_width, _logo_height,
            round((window_get_width() - _logo_width * _logo_scale) / 2),
            round((window_get_height() - _logo_height * _logo_scale) / 2),
            _logo_scale, _logo_scale, c_white, _label_alpha);
        gpu_set_texfilter(_logo_filter);
        var _label_scale = max(1, floor(_scale));
        draw_set_font(global.fontVersion);
        draw_set_color(c_white);
        draw_set_halign(fa_left); draw_set_valign(fa_top);
        draw_set_alpha(_label_alpha);
        draw_text_transformed(max(0, _scene_x) + _label_scale, max(0, _scene_y) + _label_scale,
            string_hash_to_newline(global.am2r_version), _label_scale, _label_scale, 0);
        draw_set_font(_font); draw_set_color(_color); draw_set_alpha(_alpha);
        draw_set_halign(_ha); draw_set_valign(_va);
    }
    return true;
}

// Capture the most recent lower frame once when entering death mode so the death fade can reuse it.
function dual_frontend_snapshot(_mode) {
    if (_mode == DUAL_FRONTEND_DEATH && !dual_death_active && surface_exists(dual_surface)) {
        if (!surface_exists(dual_death_surface)) dual_death_surface = surface_create(dual_width, dual_height);
        surface_copy(dual_death_surface, 0, 0, dual_surface);
    }
    dual_death_active = _mode == DUAL_FRONTEND_DEATH;
}

function dual_draw_frontend_lower(_mode) {
    if (_mode == DUAL_FRONTEND_GAMEPLAY) return false;
    if (_mode == DUAL_FRONTEND_DEATH) {
        if (room == rm_death && instance_exists(oDeathSequence) && surface_exists(dual_death_surface)) {
            draw_surface_ext(dual_death_surface, -dual_pad, 0, 1, 1, 0, c_white, 1 - clamp(oDeathSequence.fade, 0, 1));
        }
        return true;
    }
    // Sample the lower region at native pixel size before layering file selection or settings over it.
    if (surface_exists(dual_scene)) draw_surface_part(dual_scene, (surface_get_width(dual_scene) - dual_width) / 2,
        surface_get_height(dual_scene) - dual_height, dual_width, dual_height, -dual_pad, 0);
    if (_mode == DUAL_FRONTEND_MENU && surface_exists(application_surface)) {
        // Settings/gallery own their backdrop. Their transparent pixels must not reveal
        // the title planet, including the extra rows around the native 240px page.
        if (room != titleroom) draw_clear(c_black);
        var _page_y = room == titleroom ? dual_page_y : floor((dual_height - 240) / 2);
        draw_surface(application_surface, -5, _page_y);
        // Front-end menus use the handheld controls. File cards retain direct taps.
    }
    return true;
}

// Ending cues keep their original 60 Hz positions, even when a rendered frame is late.
// This runs in oCreditsText context: its position, fade, and timing fields remain owned by that object.
function dual_credits_step() {
    if (!dual_music_clock) return false;
    // Use the credits music position when available, with elapsed time as a fallback and no backward clock movement.
    var _clock = statetime + max(0, current_time - dual_last_clock_ms) * 60 / 1000;
    var _voice = oControl.dual_credits_voice;
    if (audio_is_playing(_voice)) _clock = audio_sound_get_track_position(_voice) * 60;
    _clock = max(statetime, _clock);
    dual_last_clock_ms = current_time;
    // Cross the ship cue once, then derive scrolling and fade values from the same ending clock.
    if (statetime < 360 && _clock >= 360) instance_create(192, 88, oCreditsShip);
    image_alpha = clamp((_clock - 520) * 0.05, 0, 1);
    vspeed = 0;
    y = max(ystart + 8 - TEXT_ROWS * 12, ystart + max(0, _clock - 700) * SCROLL_SPEED);
    fadeout = _clock >= 6000;
    yoffset = fadeout ? max(0, 120 - (_clock - 6000)) : min(120, _clock * 0.5);
    statetime = _clock;
    if (_clock >= 6120) event_user(0);
    return true;
}
