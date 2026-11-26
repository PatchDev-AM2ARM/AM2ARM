// Keep folder access and sync status separate from the game's saved progress.
function save_sync_init() {
    if (global.android_app) SaveSync_Cancel();
    global.am2r_sync = {
        enabled: global.android_app && SaveSync_Configured() == 1,
        busy: false, picker: false, transfer: false, review: false,
        ticket: 0, started: 0, checked: -10000,
        revision: 0, sent: 0, due: -1,
        message_source: "Save sync is off.", message: "Save sync is off."
    };
    save_sync_notice(global.am2r_sync.enabled ? "Automatic save sync is on." : "Save sync is off.");
}

// Import only while choosing saves or using Data outside a running game.
function save_sync_can_import() {
    return !global.ingame && !instance_exists(oSS_Control)
        && ((instance_exists(oGameSelMenu) && oGameSelMenu.active)
        || instance_exists(oOptionsData));
}

function save_sync_busy() {
    return global.am2r_sync.busy || global.am2r_sync.picker || global.am2r_sync.transfer;
}

function save_sync_notice(text) {
    global.am2r_sync.message_source = text;
    global.am2r_sync.message = port_caption(text);
    if (instance_exists(oOptionsData)) global.tiptext = global.am2r_sync.message;
}

// Export only validated copies; a partial set cannot reach the shared folder.
function save_sync_export() {
    var names = ["save1", "save2", "save3", "data.sav", "extras.sav"];
    var valid = true;
    for (var n = 0; n < array_length(names); n++) {
        if (scr_stage_export_pc(names[n]) < 0) valid = false;
    }
    if (file_exists("data.sav") != file_exists("extras.sav")) valid = false;
    if (!valid) {
        for (var n = 0; n < array_length(names); n++) file_delete("backupstage_" + names[n]);
    }
    return valid;
}

function save_sync_request(allow_import, review) {
    var state = global.am2r_sync;
    if (!global.android_app || !state.enabled || save_sync_busy() || SaveSync_Busy()) return false;
    state.due = -1;
    state.checked = current_time;
    if (!save_sync_export()) {
        save_sync_notice("Sync stopped: a save could not be validated.");
        return false;
    }
    state.ticket = SaveSync_Check(allow_import && save_sync_can_import(), review);
    if (state.ticket <= 0) return false;
    state.busy = true;
    state.review = false;
    state.started = current_time;
    state.sent = state.revision;
    save_sync_notice("Checking shared saves...");
    return true;
}

function save_sync_cancel() {
    if (global.android_app) SaveSync_Cancel();
    var state = global.am2r_sync;
    state.ticket = 0;
    state.checked = current_time;
    state.busy = false;
    state.review = false;
    save_sync_notice("Sync paused. You can continue with local saves.");
}

// Queue work after the save has closed; achievement writes alone wait for a menu.
function save_sync_saved(safe_point) {
    if (!variable_global_exists("am2r_sync")) return;
    var state = global.am2r_sync;
    state.revision++;
    if (safe_point && state.enabled) state.due = 2;
}

function save_sync_step() {
    var state = global.am2r_sync;
    if (!state.enabled || !global.android_app) return;
    if (state.busy && !state.review && current_time - state.started > 10000) save_sync_cancel();
    if (state.due >= 0 && !save_sync_busy() && !SaveSync_Busy()) {
        if (state.due > 0) state.due--;
        else save_sync_request(false, false);
    }
}

// Read shared unlocks only after the whole validated save set has been committed.
function save_sync_refresh() {
    with (oControl) {
        init_stats();
        if (file_exists("data.sav")) load_stats();
        if (file_exists("extras.sav")) load_stats2();
    }
    global.saves_dirty = 1;
    with (oGameSelMenu) {
        op[3].enabled = global.mod_gamebeaten;
        op[5].enabled = global.gallery[0] || global.gallery[1] || global.gallery[2];
    }
}

function save_sync_result(result) {
    var state = global.am2r_sync;
    var ticket = result[? "ticket"];
    var action = result[? "action"];
    if (ticket == 0) {
        state.picker = false;
        if (action == "configured") {
            state.enabled = SaveSync_Configured() == 1;
            save_sync_notice("Automatic sync is on. Checking saves...");
            save_sync_request(save_sync_can_import(), false);
        } else if (action == "error") save_sync_notice(result[? "detail"]);
        return;
    }
    // Ignore late provider replies after cancellation or a newer request.
    if (!state.busy || ticket != state.ticket) return;
    state.started = current_time;
    if (action == "review") { state.review = true; return; }
    if (action == "choice") {
        state.review = false;
        if (!save_sync_can_import() || SaveSync_Choose(result[? "choice"]) != 1) save_sync_cancel();
        return;
    }
    if (action == "ready") {
        if (!save_sync_can_import()) { save_sync_cancel(); return; }
        var names = string_split(result[? "names"], ",");
        var allowed = ["save1", "save2", "save3", "data.sav", "extras.sav"];
        var seen = [false, false, false, false, false];
        var valid = array_length(names) > 0 && array_length(names) <= 5;
        for (var n = 0; n < array_length(names); n++) {
            var index = -1;
            for (var k = 0; k < 5; k++) if (names[n] == allowed[k]) index = k;
            if (index < 0) valid = false;
            else if (seen[index]) valid = false;
            else {
                seen[index] = true;
                if (scr_stage_normalize("syncstage_" + names[n]) != 1) valid = false;
            }
        }
        if (seen[3] != seen[4]) valid = false;
        if (!valid) {
            save_sync_cancel();
            save_sync_notice("Shared saves are incomplete or damaged. Nothing was replaced.");
            return;
        }
        if (SaveSync_Apply() != 1) {
            save_sync_cancel();
            save_sync_notice("Save import failed. Previous saves were retained.");
            if (SaveTransfer_Recover() != 1) {
                show_message(port_caption("Save recovery needs free storage. Reopen the game after freeing space."));
                game_end();
            }
            return;
        }
        save_sync_refresh();
        if (!save_sync_export() || SaveSync_Complete() != 1) {
            save_sync_cancel();
            save_sync_notice("Saves loaded. Check sync again to finish updating the folder.");
        }
        return;
    }
    state.busy = false;
    state.checked = current_time;
    state.review = false;
    if ((action == "done" || action == "imported") && state.revision == state.sent) state.due = -1;
    save_sync_notice(result[? "detail"]);
}
