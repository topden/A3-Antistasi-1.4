params ["_name", "_getClass"];

private _config = ( "[(configName _x) isEqualTo _name, (getText ( _x >> ""name"")) isEqualTo _name ] select (_getClass)"
configClasses ( configFile >> "CfgWorlds" >> worldName >> "Names" ) ) select 0;
private _return = [getText (_config >> "name"), configName _config] select (_getClass);

_return
