// Nano keeps room lighting in a world-aligned cache. Moving projectile glows
// are omitted; the player's flashlight is composed in the final mask shader.
function nano_light_dirty() {
    if (!variable_global_exists("nano_light_generation")) global.nano_light_generation = 0;
    global.nano_light_generation++;
}

function nano_light_init() {
    nano_surf = -1;
    nano_active = false;
    nano_generation = -1;
    nano_rebuilds = 0;
    nano_origin_x = 0;
    nano_origin_y = 0;
    nano_shader_ok = shader_is_compiled(shNanoLight);
    if (nano_shader_ok) {
        nano_u_flash = shader_get_uniform(shNanoLight, "uFlash");
        nano_u_uv = shader_get_uniform(shNanoLight, "uLightUv");
        nano_u_origin = shader_get_uniform(shNanoLight, "uOrigin");
        nano_sampler = shader_get_sampler_index(shNanoLight, "uLightTexture");
        nano_shader_ok = nano_sampler >= 0;
    }
}

function nano_light_update() {
    nano_active = false;
    if (!global.nano_enabled || !nano_shader_ok) return false;
    // Some unlit rooms use these enemies as the only distant light sources.
    // Preserve their original moving illumination rather than hiding the route.
    if (global.darkness >= 3 && instance_exists(oGlowFly)) return false;
    var _wide = oControl.widescreen;
    var _vx = __view_get(e__VW.XView, _wide), _vy = __view_get(e__VW.YView, _wide);
    var _lost = !surface_exists(nano_surf);
    var _outside = _vx < nano_origin_x || _vx + 512 > nano_origin_x + 1024
        || _vy < nano_origin_y || _vy + 256 > nano_origin_y + 512;
    if (_lost || _outside || nano_generation != global.nano_light_generation) {
        if (_lost) nano_surf = effect_surface_create(1024, 512);
        // A failed allocation uses the existing lighting implementation.
        if (!surface_exists(nano_surf)) return false;
        nano_origin_x = floor(_vx / 256) * 256 - 256;
        nano_origin_y = floor(_vy / 128) * 128 - 128;
        var _ox = nano_origin_x, _oy = nano_origin_y;
        surface_set_target(nano_surf);
        // The mask changes RGB only. bm_subtract also multiplies destination
        // alpha; an opaque clear would punch holes outside the light quads.
        draw_clear_alpha(make_color_rgb(254, 254, 254), 0);
        draw_set_blend_mode(bm_subtract);
        with (oLight) {
            if (object_index == oFlashlight64 || nano_dynamic_light) continue;
            var _x = x - _ox, _y = y - _oy;
            var _xs = image_xscale, _ys = image_yscale;
            var _radius_x = sprite_get_width(sprite_index) * abs(_xs) + 2;
            var _radius_y = sprite_get_height(sprite_index) * abs(_ys) + 2;
            if (_x + _radius_x < 0 || _x - _radius_x > 1024
                || _y + _radius_y < 0 || _y - _radius_y > 512) continue;
            image_blend = make_color_hsv(0, 0, image_alpha * 255);
            draw_sprite_ext(sprite_index, -1, _x, _y, _xs, _ys, 0, image_blend, 1);
            draw_sprite_ext(sprite_index, -1, _x, _y, -_xs, _ys, 0, image_blend, 1);
            draw_sprite_ext(sprite_index, -1, _x, _y, _xs, -_ys, 0, image_blend, 1);
            draw_sprite_ext(sprite_index, -1, _x, _y, -_xs, -_ys, 0, image_blend, 1);
        }
        draw_set_blend_mode(bm_normal);
        surface_reset_target();
        nano_generation = global.nano_light_generation;
        nano_rebuilds++;
    }
    nano_active = true;
    return true;
}

function nano_light_draw() {
    if (!nano_active || !surface_exists(nano_surf)) {
        if (!nano_light_update()) return false;
    }
    if (world_draw_unused()) { draw_set_blend_mode(bm_normal); return true; }
    var _wide = oControl.widescreen;
    var _vx = __view_get(e__VW.XView, _wide), _vy = __view_get(e__VW.YView, _wide);
    // Camera tracking can move after Step. Never sample outside the cache.
    if (_vx < nano_origin_x || _vx + 512 > nano_origin_x + 1024
        || _vy < nano_origin_y || _vy + 256 > nano_origin_y + 512) {
        if (!nano_light_update()) return false;
    }
    var _flash_x = 0, _flash_y = 0, _flash_alpha = 0;
    if (instance_exists(oFlashlight64)) {
        _flash_x = oFlashlight64.x - nano_origin_x;
        _flash_y = oFlashlight64.y - nano_origin_y;
        _flash_alpha = oFlashlight64.image_alpha;
    }
    var _texture = sprite_get_texture(sLight0, 0), _uv = sprite_get_uvs(sLight0, 0);
    var _tx = texture_get_texel_width(_texture) * 0.5;
    var _ty = texture_get_texel_height(_texture) * 0.5;
    shader_set(shNanoLight);
    texture_set_stage(nano_sampler, _texture);
    shader_set_uniform_f(nano_u_flash, _flash_x, _flash_y, _flash_alpha);
    shader_set_uniform_f(nano_u_origin, 1024, 512);
    shader_set_uniform_f(nano_u_uv, _uv[0] + _tx, _uv[1] + _ty, _uv[2] - _tx, _uv[3] - _ty);
    draw_set_blend_mode(bm_subtract);
    draw_surface_part_ext(nano_surf, _vx - nano_origin_x, _vy - nano_origin_y,
        512, 256, __view_get(e__VW.XView, 0) - oControl.widescreen_space / 2, __view_get(e__VW.YView, 0),
        1, 1, make_color_hsv(0, 0, light_mask_opacity(image_alpha) * 255), 1);
    shader_reset();
    // Keep the warning lenses visible; their old pulse is not a dynamic mask.
    draw_set_blend_mode(bm_add);
    with (oA8RedLight) {
        if (x + 20 < _vx || x - 20 > _vx + 512 || y + 20 < _vy || y - 20 > _vy + 256) continue;
        draw_sprite_ext(sprite_index, -1, x, y, 1, 1, 0, c_white, image_alpha);
    }
    draw_set_blend_mode(bm_normal);
    return true;
}
