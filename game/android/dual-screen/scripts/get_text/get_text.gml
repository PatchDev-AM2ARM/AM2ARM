/// @description Read a selected-language key, falling back to bundled English.
function get_text(argument0, argument1) {
    var text = language_text(global.currentlanguage, argument0, argument1);
    if (text == "[!]" && global.currentlanguage != 0) text = language_text(0, argument0, argument1);
    return text;
}

function language_text(_language, _section, _key) {
    var _file = global.language[_language];
    var _text = port_text(_file, _section);
    if (variable_struct_exists(_text, _key)) return variable_struct_get(_text, _key);
    ini_open(_file);
    _text = ini_read_string(_section, _key, "[!]");
    ini_close();
    return _text;
}
