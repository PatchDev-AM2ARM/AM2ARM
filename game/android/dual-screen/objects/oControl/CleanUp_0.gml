// Release the lower-display surfaces and transfer buffer owned by this controller.
dual_cleanup();
if (variable_instance_exists(id, "effect_cache")) effect_cache_clear(effect_cache);
