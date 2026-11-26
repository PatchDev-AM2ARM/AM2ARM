debug = 0;
global.ingame = 0;
global.transitiontype = 0;
global.transitionx = 0;
global.transitiony = 0;
// Load language, the second-screen choice and saved options first, then fit the layout to the screens.
init_languages();
dual_settings_load();
load_gameoptions();
port_locale_refresh();
dual_layout_update();
writelog("Options Loaded");
init_stats();

randomize_zeta_heads();
randomize_omega_types();

// Extra modes start locked; saved completion and Fusion records restore them.


// Load resource mods.
load_resources();


// Restore earned progress and ensure the companion extras save exists before loading it.
if (file_exists("data.sav")) load_stats();

if (file_exists("data.sav"))
{
    if (file_exists("extras.sav")) load_stats2();
    else { save_stats2(); load_stats2(); }
}


//Rename old 1.2+ - 1.3.3 files names
if (!file_exists("save1") && !file_exists("save2") && !file_exists("save3"))
{
    if (file_exists("saveX1") && !file_exists("save1")) { file_copy("saveX1", "save1"); }
    if (file_exists("saveX2") && !file_exists("save2")) { file_copy("saveX2", "save2"); }
    if (file_exists("saveX3") && !file_exists("save3")) { file_copy("saveX2", "save3"); }
}


// Enable palette effects only when both shader resources report that they compiled.
global.shaders_compiled = false;
if (shaders_are_supported()) {
    if (shader_is_compiled(shGameBoy) && shader_is_compiled(shPaletteSwap)) {
      global.shaders_compiled = true;
    }
}

// DEBUG

//global.mod_gamebeaten = false;

/// Input3D Code
/*
input_init();
inputHeld[ds_list_size(inputList)-1] = 0;
inputPressed[ds_list_size(inputList)-1] = 0;
inputReleased[ds_list_size(inputList)-1] = 0;
input[ds_list_size(inputList)-1] = 1;

/* */
/*  */
