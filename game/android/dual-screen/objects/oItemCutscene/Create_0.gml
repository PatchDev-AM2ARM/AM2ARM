opset = 0;
ealpha = 0;
fadeout = 0;
active = 0;
size = 0;

if(instance_exists(oNotification)) oNotification.visible = false //added
Mute_Loops();
if (global.itemtype == 0) {
    alarm[0] = 360;
    if(oMusicV2.bossbgm == sndJump) {
        mus_pause(oMusicV2.currentbgm);
    }
    else {
        mus_pause(oMusicV2.bossbgm);
    }
    mus_play_once(musItemGet);
} else {
    alarm[0] = 60;
    sfx_play(sndMessage);
}

// GM2026/Android fix: 'surf' used to ALIAS the live render surface, and Draw_0 then drew
// the surface onto itself every frame — the 1.4 freeze-frame trick literally depended on
// that feedback loop to keep the frozen image alive. Self-sampling a render target is
// undefined on mobile GLES and accumulates garbage blocks (white-pixel glitch, bottom
// right). Snapshot the last gameplay frame once instead; freed before leaving the room.
var _src = oControl.screen_surface;
surfoff = 0;
if (oControl.widescreen) {
    _src = oControl.widescreen_surface;
    surfoff = oControl.widescreen_space / 2;
}
if (surface_exists(_src)) {
    surf = surface_create(surface_get_width(_src), surface_get_height(_src));
    surface_copy(surf, 0, 0, _src);
} else surf = -1;

