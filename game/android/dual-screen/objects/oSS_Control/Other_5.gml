if (surface_exists(s_map)) surface_free(s_map);
// Restore the chosen gameplay aspect when leaving pause, then refresh the nearby minimap data.
with (oControl) {
    dual_pause_end();
    event_user(2);
}
