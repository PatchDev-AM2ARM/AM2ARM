// Backup and restore for gmloader-next, where there is no folder picker.
function save_folder_names() {
    return ["save1", "save2", "save3", "data.sav", "extras.sav"];
}

function save_folder_copy(_from, _to) {
    file_delete(_to);
    file_copy(_from, _to);
    return file_exists(_to) && md5_file(_to) == md5_file(_from);
}

// Copy the PC-format stages to backup. The last backup moves to backup/previous.
function save_folder_backup() {
    var _names = save_folder_names();
    directory_create("backup");
    directory_create("backup/previous");
    for (var _i = 0; _i < array_length(_names); _i++) {
        var _file = "backup/" + _names[_i], _previous = "backup/previous/" + _names[_i];
        if (!file_exists(_file)) continue;
        file_delete(_previous);
        file_rename(_file, _previous);
    }
    for (var _i = 0; _i < array_length(_names); _i++) {
        var _stage = "backupstage_" + _names[_i];
        if (file_exists(_stage) && !save_folder_copy(_stage, "backup/" + _names[_i])) return false;
    }
    return true;
}

// Stage the backup folder for the restore screen. False when it has no saves.
function save_folder_restore() {
    var _names = save_folder_names(), _found = false;
    for (var _i = 0; _i < array_length(_names); _i++) {
        var _file = "backup/" + _names[_i], _stage = "restorestage_" + _names[_i];
        file_delete(_stage);
        if (file_exists(_file) && save_folder_copy(_file, _stage)) _found = true;
    }
    return _found;
}

// Returns 1 on success, the same as SaveTransfer_Apply.
function save_transfer_apply(_source, _target) {
    if (global.android_app) return SaveTransfer_Apply(_source, _target);
    var _sources = [_source], _targets = [_target];
    if (_source == "data.sav" && file_exists("restorestage_extras.sav")) {
        array_push(_sources, "extras.sav");
        array_push(_targets, "extras.sav");
    }
    // A .new file is always whole, so an interrupted restore can finish on the next start.
    for (var _i = 0; _i < array_length(_sources); _i++) {
        if (!save_folder_copy("restorestage_" + _sources[_i], _targets[_i] + ".part")) {
            file_delete(_targets[_i] + ".part");
            return 0;
        }
    }
    for (var _i = 0; _i < array_length(_targets); _i++) file_rename(_targets[_i] + ".part", _targets[_i] + ".new");
    save_folder_recover();
    return 1;
}

// Put finished copies in place and drop unfinished ones.
function save_folder_recover() {
    var _names = save_folder_names();
    for (var _i = 0; _i < array_length(_names); _i++) {
        file_delete(_names[_i] + ".part");
        if (!file_exists(_names[_i] + ".new")) continue;
        file_delete(_names[_i]);
        file_rename(_names[_i] + ".new", _names[_i]);
    }
}
