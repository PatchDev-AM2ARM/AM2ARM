// Begin the pause fade from transparent and prepare the labels and counters displayed by its pages.
ealpha = 0;
dual_fade_started = current_time;
dual_fade_from = 0;
active = 0;
fadeout = 0;
fadein = 1;
rectoffset = 32;
prevsuit = global.currentsuit;
hidechangetip = 0;
hidetext = 0;
port_help_top = 198;
port_refresh_subscreen_text();
timetext = steps_to_time2(global.gametime);
if (global.monstersleft < 10) {
    metrtext1 = "0" + string(global.monstersleft);
} else metrtext1 = string(global.monstersleft);
if (global.monstersarea < 10) {
    metrtext2 = "0" + string(global.monstersarea);
} else metrtext2 = string(global.monstersarea);
opt_text2 = "";

missilepressed = false;
itemcollunlock = false;
if (global.unlock[0] == 1 || global.unlock[1] == 1 || global.unlock[2] == 1) { itemcollunlock = true; }

widescreen = oControl.widescreen;
widescreen_space = oControl.widescreen_space;

