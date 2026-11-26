// Area selection, scan-gated titles and map backdrops.
// Runs in oControl scope. Language and room/scan state are inputs to the title cache.
// See SOURCE-MAP.txt for event entry points and shared state ownership.

// Reveal named areas through their saved environment scans, not their room prefixes alone.
function dual_backdrop_for_room(_room) {
    var _name = string_lower(room_get_name(_room));
    if (string_copy(_name, 1, 4) != "rm_a") return -1;
    var _family = string_copy(_name, 1, 6);
    var _number = real(string_copy(_name, 7, 2));
    switch (_family) {
        case "rm_a0h":
            // The local research scan reveals its own station artwork.
            if ((_room == rm_a0h14 || _room == rm_a0h15) && global.log[4] > 1) return bgMapA0Research;
            // The mining scan unlocks the mine, its branches and the connected breeding grounds.
            if (_number >= 17 && _number <= 26 && global.log[25] > 0) return bgMapA0Mining;
            // The tower approach begins at h30; h35 leads toward the first Omega encounter.
            if (_number >= 35) return bgMapA0Depths;
            if (_number >= 30) return bgMapA0Middle;
            return bgMapA0Surface;
        case "rm_a1a": return global.log[21] > 0 ? bgMapA1Temple : bgMapA0Surface;
        case "rm_a1b":
            // The nest scan starts beyond b01, at the entrances b02 through b05.
            return _number >= 2 && global.log[22] > 0 ? bgMapA1Nest : bgMapA0Surface;
        case "rm_a1h":
            // h05 introduces the Temple; the side caves h09 and h10 branch off before it.
            return _number >= 5 && _number <= 8 && global.log[21] > 0 ? bgMapA1Outer : bgMapA0Surface;
        case "rm_a2a": return global.log[23] > 0 ? bgMapA2Hydro : bgMapA0Surface;
        case "rm_a2c":
            if (global.log[22] > 0) return bgMapA2Nest;
            return global.log[23] > 0 ? bgMapA2Outer : bgMapA0Surface;
        case "rm_a2h":
            return _number >= 2 && global.log[23] > 0 ? bgMapA2Outer : bgMapA0Surface;
        case "rm_a3a": return global.log[24] > 0 ? bgMapA3Factory : bgMapA0Surface;
        case "rm_a3b": return global.log[22] > 0 ? bgMapA3Nest : bgMapA0Surface;
        case "rm_a3h":
            // The scan inside h04 waits until Samus crosses the tall wall.
            // h08 and h09 connect to the approach, not the factory side.
            return _number >= 4 && _number <= 7 && global.log[24] > 0 ? bgMapA3Outer : bgMapA0Surface;
        case "rm_a4a":
            if (global.log[26] == 0) return bgMapA0Middle;
            return global.event[200] > 0 ? bgMapA4TowerOn : bgMapA4TowerOff;
        case "rm_a4b":
            if (global.log[27] > 0) {
                // The escape changes the whole damaged route after the blast finishes.
                if (global.event[203] >= 9 && !instance_exists(oA4EscapeExplosion)) return bgMapA4Ruins;
                if (global.event[203] > 0) return bgMapA4Reactor;
                // b16 holds the first reactor scan; b19 branches from the approach.
                if (_number >= 16 && _number <= 18) return bgMapA4Reactor;
            }
            return global.log[26] > 0 ? bgMapA4Outer : bgMapA0Middle;
        case "rm_a4h":
            // The exterior and its side caverns share the Tower's saved scan.
            return global.log[26] > 0 ? bgMapA4Outer : bgMapA0Middle;
        case "rm_a5a": return global.log[28] > 0 ? bgMapA5Hall : bgMapA0Middle;
        case "rm_a5b": return global.log[28] > 0 ? bgMapA5Water : bgMapA0Middle;
        case "rm_a5c":
            if (global.log[28] == 0) return bgMapA0Middle;
            return bgMapA5Inner;
        case "rm_a5h":
            return _number >= 4 && global.log[28] > 0 ? bgMapA5Outer : bgMapA0Middle;
        case "rm_a6a": return bgMapA6Outer;
        case "rm_a6b":
            return _number >= 5 && global.log[40] > 0 ? bgMapA6Nest : bgMapA6Outer;
        case "rm_a7a": return bgMapA7Outer;
        case "rm_a7b":
            return _number >= 6 && global.log[29] > 0 ? bgMapA7Labs : bgMapA7Outer;
        case "rm_a7c": return global.log[29] > 0 ? bgMapA7Egg : bgMapA7Outer;
        case "rm_a8a": return global.log[6] > 0 ? bgMapA8Ship : bgMapA0Surface;
        case "rm_a8h":
            return _number >= 1 && global.log[6] > 0 ? bgMapA8Outer : bgMapA0Surface;
    }
    return bgMapA0Surface;
}

function dual_reset_area_titles() {
    dual_title_cache = {};
    dual_title_language = -1;
    dual_title_file = "";
    dual_art_title_inputs = [];
}

function dual_area_title(_image, _lab_entrance = false, _research_site = false, _waterfalls = false) {
    // Reuse translated area names until the selected language changes.
    var _file = global.language[global.currentlanguage];
    if (dual_title_language != global.currentlanguage || dual_title_file != _file) {
        dual_reset_area_titles();
        dual_title_language = global.currentlanguage;
        dual_title_file = _file;
    }
    var _cache_key = string(_image) + ":" + string(_lab_entrance) + ":" + string(_research_site)
        + ":" + string(_waterfalls);
    if (variable_struct_exists(dual_title_cache, _cache_key)) return variable_struct_get(dual_title_cache, _cache_key);
    // Use the chosen artwork so captions share its room thresholds, variants
    // and preservation through pause, fanfare and temporary transition rooms.
    var _key = "";
    switch (_image) {
        case bgMapA0Mining: _key = "MiningFacility"; break;
        case bgMapA1Temple: case bgMapA1Outer: _key = "GoldenTemple"; break;
        case bgMapA1Nest: case bgMapA2Nest: case bgMapA3Nest: _key = "BreedingGrounds"; break;
        case bgMapA2Hydro: case bgMapA2Outer: _key = "HydroStation"; break;
        case bgMapA3Factory: case bgMapA3Outer: _key = "IndustrialComplex"; break;
        case bgMapA4TowerOff: case bgMapA4TowerOn: case bgMapA4Outer: _key = "Tower"; break;
        case bgMapA4Reactor: case bgMapA4Ruins: _key = "PowerPlant"; break;
        case bgMapA5Hall: case bgMapA5Water: case bgMapA5Inner:
        case bgMapA5Outer: _key = "PowerDistribution"; break;
        case bgMapA6Nest: _key = "OmegaNest"; break;
        // The laboratory entrance shares city artwork but gains its name after the scan.
        case bgMapA7Outer: if (_lab_entrance) _key = "GeneticLabs"; break;
        case bgMapA7Labs: case bgMapA7Egg: _key = "GeneticLabs"; break;
        case bgMapA8Ship: case bgMapA8Outer: _key = "Thoth"; break;
    }
    var _title = _key == "" ? get_text("Subscreen", "Title_Map") : get_text("Logs", _key);
    if (_research_site || _image == bgMapA0Research) {
        _title = get_text("Subscreen", "Title_ResearchSite");
        if (_title == "[!]") _title = "GF RESEARCH SITE";
    }
    if (_waterfalls) {
        _title = get_text("Subscreen", "Title_Waterfalls");
        if (_title == "[!]") _title = "WATERFALLS";
    }
    variable_struct_set(dual_title_cache, _cache_key, _title);
    return _title;
}

function dual_update_backdrop() {
    // Pause, item fanfare, death and transition rooms keep the last game area.
    var _ruins = global.event[203] >= 9 && !instance_exists(oA4EscapeExplosion);
    var _variant = (global.event[200] > 0) + 2 * (global.event[250] > 0)
        + 4 * _ruins + 8 * (global.event[203] > 0);
    // A completed scan can reveal this area's picture before Samus leaves the room.
    var _discovered = (global.log[6] > 0) + 2 * (global.log[21] > 0)
        + 4 * (global.log[22] > 0) + 8 * (global.log[23] > 0)
        + 16 * (global.log[24] > 0) + 32 * (global.log[26] > 0)
        + 64 * (global.log[27] > 0) + 128 * (global.log[28] > 0)
        + 256 * (global.log[29] > 0) + 512 * (global.log[40] > 0)
        + 1024 * (global.log[25] > 0) + 2048 * (global.log[4] > 1);
    _variant += 16 * _discovered;
    if (room == dual_backdrop_room && _variant == dual_backdrop_variant) return;
    dual_backdrop_room = room;
    dual_backdrop_variant = _variant;
    var _image = dual_backdrop_for_room(room);
    if (_image < 0) return;
    var _room_name = string_lower(room_get_name(room));
    var _family = string_copy(_room_name, 1, 6);
    var _number = real(string_copy(_room_name, 7, 2));
    var _lab_entrance = _image == bgMapA7Outer && global.log[29] > 0 && _family == "rm_a7b";
    // The waterfall route shares city artwork, but not the laboratory's caption.
    var _waterfalls = _family == "rm_a7a" && _number >= 1 && _number <= 8;
    // The initial Research Team briefing is log state 1; only the local
    // mobile-site scan upgrades it to 2. Imported completed scans work too.
    var _research_site = global.log[4] > 1 && (room == rm_a0h14 || room == rm_a0h15);
    if (_image == dual_backdrop && _lab_entrance == dual_lab_entrance
        && _research_site == dual_research_site && _waterfalls == dual_waterfalls) return;
    dual_previous_research_site = dual_research_site;
    dual_research_site = _research_site;
    dual_previous_waterfalls = dual_waterfalls;
    dual_waterfalls = _waterfalls;
    dual_backdrop_previous = dual_backdrop;
    dual_previous_lab_entrance = dual_lab_entrance;
    dual_backdrop = _image;
    dual_lab_entrance = _lab_entrance;
    dual_backdrop_since = current_time;
}

function dual_backdrop_blend() {
    var _fade = clamp((current_time - dual_backdrop_since) / 600, 0, 1);
    _fade = _fade * _fade * (3 - 2 * _fade);
    if (dual_backdrop_previous < 0) _fade = 1;
    return _fade;
}

function dual_draw_backdrop() {
    var _fade = dual_backdrop_blend();
    // Cover the map with a uniform scale and crop the excess without stretching the scene.
    var _images = [dual_backdrop_previous, dual_backdrop];
    var _weights = [1 - _fade, _fade];
    var _mode = gpu_get_blendmode();
    gpu_set_blendmode(bm_add);
    for (var _i = 0; _i < 2; ++_i) {
        var _image = _images[_i];
        if (_image < 0 || _weights[_i] <= 0) continue;
        var _width = sprite_get_width(_image), _height = sprite_get_height(_image);
        var _center_x = _width / 2;
        var _scale = max(dual_width / (2 * min(_center_x, _width - _center_x)),
            (dual_map_bottom - dual_map_top) / _height);
        draw_sprite_ext(_image, 0, floor(155 - _center_x * _scale),
            floor((dual_map_top + dual_map_bottom - _height * _scale) / 2),
            _scale, _scale, 0, c_white, (dual_zoom < 1 ? 0.10 : 0.38) * _weights[_i]);
    }
    gpu_set_blendmode(_mode);
}
