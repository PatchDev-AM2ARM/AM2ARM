/// @description  mus_play_once(sound)
function mus_play_once(argument0) {
	// Start one non-looping voice if needed and retain the credits voice for the dual-screen ending clock.
	if (!audio_is_playing(argument0)) {
	    var _voice = audio_play_sound(argument0, 1, false);
        if (oControl.dual_enabled && argument0 == musCredits) oControl.dual_credits_voice = _voice;
	    audio_sound_gain(argument0, global.opmusicvolume / 100, 0);
	}



}
