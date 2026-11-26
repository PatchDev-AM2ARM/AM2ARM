/// @description Initialize touch controls.
device_mouse_dbclick_enable(false);
device_screen_size = sqrt(power(display_get_width() / display_get_dpi_x(), 2) + power(display_get_height() / display_get_dpi_y(), 2));
draw = 1;
alpha = 0;
// Track the touch device assigned to each control; -1 means no finger currently owns it.
st_pressed[0] = -1;
st_pressed[1] = -1;

jump_pressed[0] = -1;
jump_pressed[1] = -1;

fire_pressed[0] = -1;
fire_pressed[1] = -1;

aimupleft_pressed[0] = -1;
aimupleft_pressed[1] = -1;

aimdownleft_pressed[0] = -1;
aimdownleft_pressed[1] = -1;

aimupright_pressed[0] = -1;
aimupright_pressed[1] = -1;

aimdownright_pressed[0] = -1;
aimdownright_pressed[1] = -1;

missile_pressed[0] = -1;
missile_pressed[1] = -1;

// Hold mode needs a separate touch action to choose the missile type.
weapon_select_pressed = -1;
weapon_select_language = -1;
weapon_select_label = "";

morph_pressed[0] = -1;
morph_pressed[1] = -1;

pause_pressed[0] = -1;
pause_pressed[1] = -1;

up_pressed[0] = -1;
up_pressed[1] = -1;

down_pressed[0] = -1;
down_pressed[1] = -1;

right_pressed[0] = -1;
right_pressed[1] = -1;

left_pressed[0] = -1;
left_pressed[1] = -1;

// Wake-tap: device indexes whose current touch began while the overlay was
// invisible with a pad latched -- they reveal the overlay but never actuate.
for (i = 0; i < 5; i += 1) wake_touch[i] = 0;

vdir = 0;
vdist = 0;
rdist = 0;
mx = 0;
my = 0;
joyx = 0;
joyy = 0;


touch_layout_apply();
// Draw the original button sprites directly; never resample or replace their assets.
