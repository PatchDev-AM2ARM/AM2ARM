/// @description  Input3D with heavy Lojical mods - Controller Connected

touch_layout_receive(async_load);

if (os_type == os_linux) {
    var event = ds_map_find_value(async_load, "event_type");
    
    if (event == "gamepad discovered") {
        global.opjoyid = ds_map_find_value(async_load, "pad_index");
    } else if (event == "gamepad lost") {
        global.opjoyid = 1; // reset, I hope (PROBABLY NOT NECESSARY)
    }
}


// Apply device-specific mappings when Android discovers or reconnects a pad.
if (os_type == os_android && ds_map_find_value(async_load, "event_type") == "gamepad discovered") {
    android_gamepad_configure();
}
