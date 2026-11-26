function nano_render_same(_a,_b) {
    var _n = array_length(_a);
    if (_n != array_length(_b)) return false;
    for (var _i=0; _i<_n; ++_i) if (_a[_i] != _b[_i]) return false;
    return true;
}

// The key describes pixels, not world position. Animated frames, arms, facing,
// palette and tint all invalidate it. A recreated surface explicitly clears it.
function nano_render_player_redraw() {
    if (global.android_app || !global.nano_enabled || shader_current()!=-1) {
        if (array_length(oCharacter.nano_render_pose)>0) oCharacter.nano_render_pose=[];
        return true;
    }
    var _p=oCharacter, _c=oControl;
    // A trail can recreate a lost image from its own Draw event. Sprite frame -1
    // then uses that caller's image_index, not necessarily the player's frame.
    var _key=[room,_p.surf,_p.sprite_index,floor(image_index),
        _p.aspr1,_p.asprx,_p.aspry,_p.aspr2,_p.aspr2x,_p.aspr2y,_p.aspr2a,
        _p.mirror,_p.image_blend,_p.image_alpha,_p.armmsl,
        global.currentsuit,_c.mod_fusion,_c.msr_fusionsuit,
        _c.PowerPalette,_c.VariaPalette,_c.GravityPalette];
    if (nano_render_same(_key,_p.nano_render_pose)) {
        shader_reset();
        return false;
    }
    _p.nano_render_pose=_key;
    return true;
}

// Health, ammo, selection, map cells and menu visibility update immediately.
// Nano keeps the minimap highlight steady; cell and marker changes still invalidate it.
function nano_render_hud_redraw() {
    if (global.android_app || !global.nano_enabled || dual_enabled) {
        if (array_length(nano_render_hud_key)>0) nano_render_hud_key=[];
        return true;
    }
    if (!global.ingame || !instance_exists(oCharacter)) {
        nano_render_hud_key=[];
        return true;
    }
    var _p=oCharacter;
    var _key=[room,gui_surface,widescreen_space,displaygui,global.opshowhud,
        global.classicmode,global.playerhealth,global.etanks,mod_etankhealthmult,
        global.maxmissiles,global.maxsmissiles,global.maxpbombs,
        global.missiles,global.smissiles,global.pbombs,global.currentweapon,
        global.opmslstyle,_p.state,_p.sjball,_p.armmsl,
        hudflash,hudflashfx,guifont1,guifont1a,global.guifont2,
        global.ophudshowmap,global.ophudshowmetrcount,global.monstersarea,global.monstersleft,
        nano_render_map_revision,global.mapmarker,
        draw_get_alpha(),draw_get_color(),draw_get_halign(),draw_get_valign()];
    if (nano_render_same(_key,nano_render_hud_key)) {
        // Preserve the drawing state left by draw_gui, including on a cache hit.
        if (displaygui && global.opshowhud && global.classicmode==0) {
            draw_set_alpha(1); draw_set_color(c_white); draw_set_font(global.guifont2);
            if (global.ophudshowmap) draw_set_colour_write_enable(true,true,true,true);
        }
        return false;
    }
    nano_render_hud_key=_key;
    return true;
}

