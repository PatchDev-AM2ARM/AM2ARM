/// @description  load_gameoptions()
function load_gameoptions() {

	// Establish option defaults before reading the saved configuration.
	global.oporientation = 0;
	global.opfullscreen = 0; // originally 1
	global.opscale = 0;
	global.opvsync = 0;
	global.nano_enabled = false;
	global.opshowhud = 1;
	global.ophudshowmap = 1;
	global.ophudshowmetrcount = 1;
	global.ophudshowhints = 1;
	global.ophudshowmedalmsg = 1;
	global.ophudshowlogmsg = 1;
	global.oplowhpstyle = 0;
	global.opsoundvolume = 70;
	global.opmusicvolume = 70;
	global.opsoundfx = 1;
	global.opaimstyle = 1;
	global.opmslstyle = 1;
	global.opspdstyle = 0;
	global.opwlkstyle = 1;
	global.opmrpstyle = 1;
	global.opautoclimb = 1;
	global.opautomorph = 1;
	global.opanalogwalk = 1;
	global.opexitkeyenable = 0;
	global.opdebug = 0;
	global.opwritelog = 0;
	global.compatibilitymode = 0;
	global.sensitivitymode = 0;
	global.widescreen_enabled = 1;
	global.opaspectratio = 1;
	oControl.aspect_auto = !global.android_app;
	with (oControl) standard_aspect_apply(global.opaspectratio);
	global.oppixelperfect = 0;
	oControl.mod_insanitymode = 0;
	oControl.touch_scale = 4;
	oControl.touch_inset = 0;
	oControl.touch_aim_balance = 0;
	oControl.mod_collecteditemsmap = 0;
	// Initialize bindings and create a configuration file on the first run.
	set_default_keys();
	set_default_joypad();
	set_default_xjoypad();
	if (!file_exists("config.ini")) save_gameoptions();
	if (file_exists("config.ini")) {
	    ini_open("config.ini");
	    oControl.dual_hud_top = ini_read_real("DualScreen", "HUDTop", 0) != 0;
	    // Load display, HUD and audio preferences.
	    global.opfullscreen = ini_read_real("Screen", "Fullscreen", 0);
	    global.opscale = ini_read_real("Screen", "Scale", 0);
	    global.opvsync = ini_read_real("Screen", "VSync", 0);
	    global.nano_enabled = ini_read_real("Screen", "Nano", 0) == 1;
	    global.oporientation = clamp(round(ini_read_real("Screen", "Orientation", 0)), 0, 2);
	    global.currentlanguage = ini_read_real("Screen", "Language", 0);
	    global.opshowhud = ini_read_real("Screen", "ShowHUD", 1);
	    global.ophudshowmap = ini_read_real("Screen", "ShowHUDMap", 1);
	    global.ophudshowmetrcount = ini_read_real("Screen", "ShowHUDCounter", 1);
	    global.ophudshowhints = ini_read_real("Screen", "ShowHints", 1);
	    global.ophudshowmedalmsg = ini_read_real("Screen", "ShowMedalMessage", 1);
	    global.ophudshowlogmsg = ini_read_real("Screen", "ShowLogMessage", 1);
	    global.oplowhpstyle = ini_read_real("Screen", "LowEnergyNotificationStyle", 0);
	    global.opsoundvolume = ini_read_real("Sound", "SoundVolume", 100);
	    global.opmusicvolume = ini_read_real("Sound", "MusicVolume", 100);
	    global.opsoundfx = ini_read_real("Sound", "SoundEffects", 0);
	    // Load legacy joystick, gamepad and keyboard bindings into the shared input configuration.
	    global.openablejoy = ini_read_real("Control", "EnableJoystick", 1);
	    global.opdeadzone = ini_read_real("Control", "JoystickDeadzone", 50);
	    global.opjoyid = ini_read_real("Control", "JoystickID", 1);
	    global.opjoybtn_xax = ini_read_real("Control", "JoystickXAxis", 0);
	    global.opjoybtn_yax = ini_read_real("Control", "JoystickYAxis", 1);
	    global.opjoybtn_a = ini_read_real("Control", "JoystickButtonA", 1);
	    global.opjoybtn_b = ini_read_real("Control", "JoystickButtonB", 2);
	    global.opjoybtn_x = ini_read_real("Control", "JoystickButtonX", 9);
	    global.opjoybtn_l = ini_read_real("Control", "JoystickButtonL", 3);
	    global.opjoybtn_l2 = ini_read_real("Control", "JoystickButtonL2", 7);
	    global.opjoybtn_r = ini_read_real("Control", "JoystickButtonR", 4);
	    global.opjoybtn_r2 = ini_read_real("Control", "JoystickButtonR2", 8);
	    global.opjoybtn_sel = ini_read_real("Control", "JoystickButtonSelect", 5);
	    global.opjoybtn_str = ini_read_real("Control", "JoystickButtonStart", 6);
	    global.opjoybtn_menu1 = ini_read_real("Control", "JoystickButtonMenuOK", 6);
	    global.opjoybtn_menu2 = ini_read_real("Control", "JoystickButtonMenuCancel", 6);
	    global.opxjoyenable = ini_read_real("Control", "EnableXBJoypad", 1);
	    global.opxjoydz = ini_read_real("Control", "XBJoypadDeadzone", 20);
	    global.opxjoyvib = ini_read_real("Control", "XBJoypadVibration", 1);
	    global.opxjoybtn_a = ini_read_real("Control", "XBJoypadButtonA", global.opxjoybtn_a);
	    global.opxjoybtn_b = ini_read_real("Control", "XBJoypadButtonB", global.opxjoybtn_b);
	    global.opxjoybtn_x = ini_read_real("Control", "XBJoypadButtonX", global.opxjoybtn_x);
	    global.opxjoybtn_l = ini_read_real("Control", "XBJoypadButtonL", global.opxjoybtn_l);
	    global.opxjoybtn_l2 = ini_read_real("Control", "XBJoypadButtonL2", global.opxjoybtn_l2);
	    global.opxjoybtn_r = ini_read_real("Control", "XBJoypadButtonR", global.opxjoybtn_r);
	    global.opxjoybtn_r2 = ini_read_real("Control", "XBJoypadButtonR2", global.opxjoybtn_r2);
	    global.opxjoybtn_sel = ini_read_real("Control", "XBJoypadButtonSelect", global.opxjoybtn_sel);
	    global.opxjoybtn_str = ini_read_real("Control", "XBJoypadButtonStart", global.opxjoybtn_str);
	    global.opxjoybtn_menu1 = ini_read_real("Control", "XBJoypadButtonMenuOK", global.opxjoybtn_menu1);
	    global.opxjoybtn_menu2 = ini_read_real("Control", "XBJoypadButtonMenuCancel", global.opxjoybtn_menu2);
    
	    global.opkeybtn_up = ini_read_real("Control", "KeyboardButtonUp", 38);
	    global.opkeybtn_down = ini_read_real("Control", "KeyboardButtonDown", 40);
	    global.opkeybtn_left = ini_read_real("Control", "KeyboardButtonLeft", 37);
	    global.opkeybtn_right = ini_read_real("Control", "KeyboardButtonRight", 39);
	    global.opkeybtn_a = ini_read_real("Control", "KeyboardButtonA", 88);
	    global.opkeybtn_b = ini_read_real("Control", "KeyboardButtonB", 90);
	    global.opkeybtn_x = ini_read_real("Control", "KeyboardButtonX", 9);
	    global.opkeybtn_l = ini_read_real("Control", "KeyboardButtonL", 68);
	    global.opkeybtn_l2 = ini_read_real("Control", "KeyboardButtonL2", 67);
	    global.opkeybtn_r = ini_read_real("Control", "KeyboardButtonR", 17);
	    global.opkeybtn_r2 = ini_read_real("Control", "KeyboardButtonR2", 32);
	    global.opkeybtn_select = ini_read_real("Control", "KeyboardButtonSelect", 65);
	    global.opkeybtn_start = ini_read_real("Control", "KeyboardButtonStart", 13);
	    global.opkeybtn_menu1 = ini_read_real("Control", "KeyboardButtonMenuOK", 65);
	    global.opkeybtn_menu2 = ini_read_real("Control", "KeyboardButtonMenuCancel", 13);
    
	    // Load control styles and optional movement assists.
	    global.opaimstyle = ini_read_real("Control", "AimStyle", 0);
	    global.opmslstyle = ini_read_real("Control", "MissileStyle", 0);
	    global.opmrpstyle = ini_read_real("Control", "MorphStyle", 0);
	    global.opspdstyle = ini_read_real("Control", "SpiderballStyle", 0);
	    global.opanalogwalk = ini_read_real("Control", "AnalogWalk", 1);
	    global.opautoclimb = ini_read_real("Control", "AutoClimb", 0);
	    global.opautomorph = ini_read_real("Control", "AutoMorph", 0);
	    global.opexitkeyenable = ini_read_real("Control", "EnableExitButton", 0);
	    global.opkeybtn_exit = ini_read_real("Control", "KeyboardButtonExit", 27);
	    global.opjoybtn_exit = ini_read_real("Control", "JoystickButtonExit", 10);
	    global.opxjoybtn_exit = ini_read_real("Control", "XBJoypadButtonExit", global.opxjoybtn_exit);
	    global.opdebug = ini_read_real("Debug", "IdLikeToUseTheDebugToolsPlease", 0);
	    global.opwritelog = ini_read_real("Debug", "WriteLog", 0);
	    global.opapril = ini_read_real("Debug", "ForceAprilsFool", 0);
    
    
	    // Extras
	    oControl.mod_buttonsconfig = ini_read_real("Extras", "Controller", 0);
	    oControl.mod_earlybaby = ini_read_real("Extras", "EarlyBaby", 0);
	    oControl.mod_lowhealthwarning = ini_read_real("Extras", "LowHealthWarning", 1); 
	    oControl.msr_fusionsuit = ini_read_real("Extras", "FusionSuitMSR", 0);
	    oControl.mod_monstersextremecheck = ini_read_real("Extras", "ExtremeLabMonsters", 0);
	    oControl.mod_IGT = ini_read_real("Extras", "DisplayIGT", 0);
    
	    // Android
	    global.opjoybtn_padu = ini_read_real("Control", "JoystickDPadUp", 36);
	    global.opjoybtn_padd = ini_read_real("Control", "JoystickDPadDown", 37);
	    global.opjoybtn_padl = ini_read_real("Control", "JoystickDPadLeft", 38);
	    global.opjoybtn_padr = ini_read_real("Control", "JoystickDPadRight", 39);
	    global.opanalog_stick = ini_read_real("Control", "JoystickType", 0);
	    global.opanalog_invert = ini_read_real("Control", "JoystickInvert", 0);
	    global.compatibilitymode = ini_read_real("Control", "CompatibilityMode", 0);
    
	    global.dpad_rebind = ini_read_real("Control", "RebindDPad", 0);
    
	    oControl.touch_scale = clamp(ini_read_real("Control", "TouchScale", 4), 3, 8);
	    oControl.touch_inset = clamp(ini_read_real("Control", "TouchInset", 0), 0, 5);
	    oControl.touch_aim_balance = clamp(ini_read_real("Control", "TouchAimBalance", 0), 0, 1);
    
	    // Languages
	    // Fall back to the first language when the saved language index exceeds the available list.
	    if(global.currentlanguage > array_length_1d(global.language) - 1) {
	        global.currentlanguage = 0;
	        ini_write_real("Screen", "Language", global.currentlanguage);
	    }
    
	    // 1.5.1 sensitivity mode
	    global.sensitivitymode = ini_read_real("Screen", "SensitivityMode", 0);
    
	    // Widescreen toggle
	    var _legacy_wide = ini_read_real("Screen", "Widescreen", 1);
	    if (ini_key_exists("Screen", "Widescreen")) oControl.aspect_auto = false;
	    global.opaspectratio = standard_aspect_validate(
	        ini_read_real("Screen", "AspectRatio", -1), _legacy_wide);
	    with (oControl) standard_aspect_apply(global.opaspectratio);

	    // Pixel Perfect (Android)
	    global.oppixelperfect = ini_read_real("Screen", "PixelPerfect", 0);
    
	    // Gameplay Menu
	    oControl.mod_insanitymode = ini_read_real("GameplayMenu", "InsanityMode", 0);
    
	    // Remember setting
	    oControl.mod_collecteditemsmap = ini_read_real("Extras", "MapItemsCollected", 0);
    
	    // Helper Septoggs
	    // Moved from scr_load_mods because of load order when insanitymode changed
	    if(oControl.mod_insanitymode == 1) {
	        oControl.mod_septoggs_bombjumps_easy = 0;
	        oControl.mod_septoggs_hijump_easy = 0;
	    }
	    else {
	        oControl.mod_septoggs_bombjumps_easy = 1;
	        oControl.mod_septoggs_hijump_easy = 0;
	    }
    
	    ini_close();
	} // if (file_exists("config.ini"))
	with (oControl) dual_apply_hud_layout();
	android_gamepad_configure();
	// Apply display settings and replace unavailable legacy joystick axes with defaults.
	apply_screenres();
	if (global.android_app && !oControl.dual_enabled) Android_Orientation(global.oporientation);
	if (joystick_exists(global.opjoyid)) {
	    if (global.opjoybtn_xax >= 4 && joystick_axes(global.opjoyid) < 4) global.opjoybtn_xax = 0;
	    if (global.opjoybtn_xax >= 2 && joystick_axes(global.opjoyid) < 2) global.opjoybtn_xax = 0;
	    if (global.opjoybtn_yax >= 4 && joystick_axes(global.opjoyid) < 4) global.opjoybtn_yax = 1;
	    if (global.opjoybtn_yax >= 2 && joystick_axes(global.opjoyid) < 2) global.opjoybtn_yax = 1;
	    if (global.opjoybtn_xax >= 6 && joystick_has_pov() == 0) global.opjoybtn_xax = 0;
	    if (global.opjoybtn_yax >= 6 && joystick_has_pov() == 0) global.opjoybtn_yax = 1;
	}






}
