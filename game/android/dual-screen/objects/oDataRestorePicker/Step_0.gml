if (state == "restart") exit;

if (state == "confirm") {
    if (oControl.kUp && oControl.kUpPushedSteps == 0
    ||  oControl.kDown && oControl.kDownPushedSteps == 0) {
        confirm_sel = 1 - confirm_sel;
        sfx_play(sndMenuMove);
    }
    if (oControl.kMenu2 && oControl.kMenu2PushedSteps == 0) {
        sfx_play(sndMenuCancel);
        state = pend_return;
        confirm_sel = 1;
        event_user(0);
        exit;
    }
    if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
        sfx_play(sndMenuSel);
        if (confirm_sel == 1) {          // No
            state = pend_return;
            confirm_sel = 1;
            event_user(0);
            exit;
        }
        // Apply only a complete validated stage; keep the current saves on failure.
        var source = (pend_kind == "slot") ? "save" + string(pend_src + 1) : "data.sav";
        var target = (pend_kind == "slot") ? "save" + string(pend_dst + 1) : "data.sav";
        var valid = scr_stage_normalize("restorestage_" + source) == 1;
        if (pend_kind != "slot" && scr_stage_normalize("restorestage_extras.sav") < 0) valid = false;
        if (!valid || save_transfer_apply(source, target) != 1) {
            if (!valid) {
                if (pend_kind == "slot") has_slot[pend_src] = 0;
                else has_unlocks = 0;
            }
            confirm_sel = 1;
            state = "source";
            event_user(0);
            global.tiptext = get_text("Misc", "RestoreFail");
            exit;
        }
        if (pend_kind != "slot") applied_unlocks = 1;
        // The title room is frozen persistent while rm_options runs, so the
        // file select is unreachable from here (with() finds nothing). Flag
        // it; its own Step re-reads the slot files when the room thaws.
        global.saves_dirty = 1;
        confirm_sel = 1;
        state = "source";
        event_user(0);
        global.tiptext = get_text("Misc", "RestoreApplied");
    }
    exit;
}

// source / dest navigation
if (oControl.kDown && oControl.kDownPushedSteps == 0) {
    cursel = (cursel + 1) mod item_count;
    sfx_play(sndMenuMove);
    sel_apply();
}
if (oControl.kUp && oControl.kUpPushedSteps == 0) {
    cursel = (cursel + item_count - 1) mod item_count;
    sfx_play(sndMenuMove);
    sel_apply();
}
if (oControl.kMenu2 && oControl.kMenu2PushedSteps == 0) {
    sfx_play(sndMenuCancel);
    if (state == "dest") {
        state = "source";
        event_user(0);
    } else picker_exit();
    exit;
}
if (oControl.kMenu1 && oControl.kMenu1PushedSteps == 0) {
    sfx_play(sndMenuSel);
    if (state == "source") {
        if (item_kind[cursel] == "slot") {
            pend_src = item_val[cursel];
            state = "dest";
            event_user(0);
        } else if (item_kind[cursel] == "unlocks") {
            pend_kind = "unlocks";
            pend_return = "source";
            state = "confirm";
        } else picker_exit();
    } else {
        // dest screen
        if (item_kind[cursel] == "slot") {
            pend_kind = "slot";
            pend_dst = item_val[cursel];
            pend_return = "dest";
            state = "confirm";
        } else {
            state = "source";
            event_user(0);
        }
    }
}
