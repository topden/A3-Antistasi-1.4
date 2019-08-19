//usage: place on the map markers covering the areas where you want the AAF operate, and put names depending on if they are powerplants,resources, bases etc.. The marker must cover the whole operative area, it's buildings etc.. (for example in an airport, you must cover more than just the runway, you have to cover the service buildings etc..)
//markers cannot have more than 500 mts size on any side or you may find "insta spawn in your nose" effects.
//do not do it on cities and hills, as the mission will do it automatically
//the naming convention must be as the following arrays, for example: first power plant is "power", second is "power_1" thir is "power_2" after you finish with whatever number.
//to test automatic zone creation, init the mission with debug = true in init.sqf
//of course all the editor placed objects (petros, flag, respawn marker etc..) have to be ported to the new island
//deletion of a marker in the array will require deletion of the corresponding marker in the editor
//only touch the commented arrays

_fnc_rw_mrkArray = {
	params ["_mrkName"];
	private _return = allMapMarkers select { ((_x splitString "_") select 0) isEqualTo _mrkName };
	_return
};

forcedSpawn = [];
citiesX = [];

airportsX = ["airport"] call _fnc_rw_mrkArray;
spawnPoints = ["spawnPoint"] call _fnc_rw_mrkArray;
resourcesX = ["resource"] call _fnc_rw_mrkArray;
factories = ["factory"] call _fnc_rw_mrkArray;
outposts = ["outpost"] call _fnc_rw_mrkArray;
seaports = ["seaport"] call _fnc_rw_mrkArray;
controlsX = ["control"] call _fnc_rw_mrkArray;
seaMarkers = ["seaPatrol"] call _fnc_rw_mrkArray;
seaSpawn = ["seaSpawn"] call _fnc_rw_mrkArray;
seaAttackSpawn = ["seaAttackSpawn"] call _fnc_rw_mrkArray;

private ["_name", "_sizeX", "_sizeY", "_size", "_pos", "_mrk"];

configProperties [
	configfile >> "CfgWorlds" >> worldName >> "Names",
	"getText (_x >> ""type"") == ""Hill"""
] apply {
	_name = getText (_x >> "name");
	if (!(_name in ["Magos",""])) then {
		_sizeX = getNumber (_x >> "radiusA");
		_sizeY = getNumber (_x >> "radiusB");
		_size = [_sizeX, _sizeY] select {_sizeX <= _sizeY};
		_pos = getArray (_x >> "position");
		_size = [_size, 50] select {_size < 10};

		_mrk = createmarker [format ["%1", _name], _pos];
		_mrk setMarkerSize [_size, _size];
		_mrk setMarkerShape "ELLIPSE";
		_mrk setMarkerBrush "SOLID";
		_mrk setMarkerColor "ColorRed";
		_mrk setMarkerText _name;
		controlsX pushBack _name;
	};
};

(seaMarkers + seaSpawn + seaAttackSpawn + spawnPoints) apply {_x setMarkerAlpha 0};

defaultControlIndex = (count controlsX) - 1;
outpostsFIA = [];
destroyedCities = [];
garrison setVariable ["Synd_HQ", [], true];
markersX = airportsX + resourcesX + factories + outposts + seaports + controlsX + ["Synd_HQ"];

markersX apply {
	_x setMarkerAlpha 0;
	spawner setVariable [_x, 2, true];
};

private ["nameX", "_roads", "_numCiv", "_roadsProv", "_roadcon", "roadsX", "_dmrk", "_info"];

configProperties [
	configfile >> "CfgWorlds" >> worldName >> "Names",
	"getText (_x >> ""type"") in [""NameCityCapital"",""NameCity"",""NameVillage"",""CityCenter""]"
] apply {
	_nameX = getText (_x >> "name");
	if (!(_nameX in ["", "Lakatoro01", "Galili01", "Sosovu01", "Ipota01", "hill12", "V_broad22"])) then {
		_sizeX = getNumber (_x >> "radiusA");
		_sizeY = getNumber (_x >> "radiusB");
		_size = [_sizeX, _sizeY] select {_sizeX <= _sizeY};
		_pos = getArray (_x >> "position");
		_size = [_size, 400] select {_size < 400};
		_roads = [];
		_numCiv = 0;
		if (worldname in ["Tanoa", "Altis", "chernarus_summer"]) then {
			_roads = roadsX getVariable _nameX;
			_numCiv = server getVariable _nameX;
			if (isNil "_numCiv") then {
				_numCiv = (count (nearestObjects [_pos, ["house"], _size]));
				_roadsProv = _pos nearRoads _size;
				_roadsProv apply {
					_roadcon = roadsConnectedto _x;
					if (count _roadcon == 2) then {
						_roads pushBack (getPosATL _x);
					};
				};
				roadsX setVariable [_nameX, _roads];
			};
		} else {
			_numCiv = (count (nearestObjects [_pos, ["house"], _size]));
			_roadsProv = _pos nearRoads _size;
			_roadsProv apply {
				_roadcon = roadsConnectedto _x;
				if (count _roadcon == 2) then {
					_roads pushBack (getPosATL _x);
				};
			};
			roadsX setVariable [_nameX, _roads];
		};
		_numVeh = round (_numCiv / 3);
		_nroads = count _roads;
		_nearRoadsFinalSorted = [_roads, [], {_pos distance _x}, "ASCEND"] call BIS_fnc_sortBy;
		_pos = _nearRoadsFinalSorted select 0;
		if (isNil "_pos") then {diag_log format ["Falla %1", _nameX]};
		_mrk = createmarker [format ["%1", _nameX], _pos];
		_mrk setMarkerSize [_size, _size];
		_mrk setMarkerShape "RECTANGLE";
		_mrk setMarkerBrush "SOLID";
		_mrk setMarkerColor colorOccupants;
		_mrk setMarkerText _nameX;
		_mrk setMarkerAlpha 0;
		citiesX pushBack _nameX;
		spawner setVariable [_nameX, 2, true];
		_dmrk = createMarker [format ["Dum%1", _nameX], _pos];
		_dmrk setMarkerShape "ICON";
		_dmrk setMarkerType "loc_Ruin";
		_dmrk setMarkerColor colorOccupants;
		if (_nroads < _numVeh) then {_numVeh = _nroads};
		sidesX setVariable [_mrk, Occupants, true];
		_info = [_numCiv, _numVeh, prestigeOPFOR, prestigeBLUFOR];
		server setVariable [_nameX, _info, true];
	};
};

markersX = markersX + citiesX;
sidesX setVariable ["Synd_HQ", teamPlayer, true];

antennasDead = [];
banks = [];

private ["_posAntennas", "_posBank", "_blacklistPos", "_mrkFinal", "_antennaProv"];
mrkAntennas = [];

switch (worldName) do {
	case "Tanoa": {
		_posAntennas = [[6617.95,7853.57,0.200073], [7486.67,9651.9,1.52588e-005], [6005.47,10420.9,0.20298], [2437.25,7224.06,0.0264893], [4701.6,3165.23,0.0633469], [11008.8,4211.16,-0.00154114], [10114.3,11743.1,9.15527e-005], [10949.8,11517.3,0.14209], [11153.3,11435.2,0.210876], [12889.2,8578.86,0.228729], [2682.94,2592.64,-0.000686646], [2690.54,12323,0.0372467], [2965.33,13087.1,0.191544], [13775.8,10976.8,0.170441]];
		_blacklistPos = [8, 12];
		_posBank = [[5893.41,10253.1,-0.687263], [9507.5,13572.9,0.133848]];//same as RT for Bank buildings, select the biggest buildings in your island, and make a DB with their positions.
		antennas = [antenna];
		_posAntennas pushBack (getPos antenna);
	};
	case "Altis": {
		_posAntennas = [[14451.5,16338,0.000354767], [15346.7,15894,-3.8147e-005], [16085.1,16998,7.08781], [17856.7,11734.1,0.863045], [9496.2,19318.5,0.601898], [9222.87,19249.1,0.0348206], [20944.9,19280.9,0.201118], [20642.7,20107.7,0.236603], [18709.3,10222.5,0.716034], [6840.97,16163.4,0.0137177], [19319.8,9717.04,0.215622], [19351.9,9693.04,0.639175], [10316.6,8703.94,0.0508652], [8268.76,10051.6,0.0100708], [4583.61,15401.1,0.262543],[4555.65,15383.2,0.0271606], [4263.82,20664.1,-0.0102234], [26274.6,22188.1,0.0139847], [26455.4,22166.3,0.0223694]];
		_blacklistPos = [1, 4, 7, 8, 9, 10, 12, 15, 17];
		_posBank = [[16586.6,12834.5,-0.638584], [16545.8,12784.5,-0.485485], [16633.3,12807,-0.635017], [3717.34,13391.2,-0.164862], [3692.49,13158.3,-0.0462074], [3664.31,12826.5,-0.379545], [3536.99,13006.6,-0.508585], [3266.42,12969.9,-0.549738]];
		antennas = [];
	};
	case "chernarus_summer": {
		_posAntennas = [[6444.13,6545.83,-0.106628], [5264.35,5314.45,0.0291748], [4968.53,9964.4,0], [3715.81,5984.25,0], [6563.69,3405.56,0.0547104],[4548.22,3131.85,0.570232], [13010.1,5964.96,-0.0164185], [3029.57,2350.28,0.0183334], [13477.6,3345.84,0.0729446], [12937,12763.6,0.164017]];
		_blackListPos = [1, 7];
		antennas = [];
	};
	default {
		antennas = nearestObjects [[worldSize /2, worldSize/2,0], ["Land_TTowerBig_1_F", "Land_TTowerBig_2_F", "Land_Communication_F", "Land_Vysilac_FM","Land_A_TVTower_base", "Land_Telek1"], worldSize];
		banks = nearestObjects [[worldSize /2, worldSize/2,0], ["Land_Offices_01_V1_F"], worldSize];
		antennas apply {
			_mrkFinal = createMarker [format ["Ant%1", _x], position _x];
			_mrkFinal setMarkerShape "ICON";
			_mrkFinal setMarkerType "loc_Transmitter";
			_mrkFinal setMarkerColor "ColorBlack";
			_mrkFinal setMarkerText "Radio Tower";
			mrkAntennas pushBack _mrkFinal;
			_x addEventHandler [
				"Killed",
				{
					_antenna = _this select 0;
					citiesX apply {
						if ([antennas,_x] call BIS_fnc_nearestPosition == _antenna) then {
							[_x,false] spawn A3A_fnc_blackout;
						};
					};
					_mrk = [mrkAntennas, _antenna] call BIS_fnc_nearestPosition;
					antennas = antennas - [_antenna]; antennasDead pushBack (getPos _antenna); deleteMarker _mrk;
					publicVariable "antennas"; publicVariable "antennasDead";
					["TaskSucceeded",["", "Radio Tower Destroyed"]] remoteExec ["BIS_fnc_showNotification",teamPlayer];
					["TaskFailed",["", "Radio Tower Destroyed"]] remoteExec ["BIS_fnc_showNotification",Occupants];
				}
			];
		};
	};
};

if (count _posAntennas > 0) then {
	for "_i" from 0 to (count _posAntennas - 1) do {
		_antennaProv = nearestObjects [_posAntennas select _i,["Land_TTowerBig_1_F", "Land_TTowerBig_2_F", "Land_Communication_F", "Land_Vysilac_FM","Land_A_TVTower_base","Land_Telek1"], 35];
		if (count _antennaProv > 0) then {
			_antenna = _antennaProv select 0;
			if (_i in _blacklistPos) then {
				_antenna setdamage 1;
			} else {
				antennas pushBack _antenna;
				_mrkFinal = createMarker [format ["Ant%1", _i], _posAntennas select _i];
				_mrkFinal setMarkerShape "ICON";
				_mrkFinal setMarkerType "loc_Transmitter";
				_mrkFinal setMarkerColor "ColorBlack";
				_mrkFinal setMarkerText "Radio Tower";
				mrkAntennas pushBack _mrkFinal;
				_antenna addEventHandler [
					"Killed",
					{
						_antenna = _this select 0;
						citiesX apply {
							if ([antennas, _x] call BIS_fnc_nearestPosition == _antenna) then {
								[_x, false] spawn A3A_fnc_blackout
							};
						};
						_mrk = [mrkAntennas, _antenna] call BIS_fnc_nearestPosition;
						antennas = antennas - [_antenna];
						antennasDead pushBack (getPos _antenna);
						deleteMarker _mrk;
						publicVariable "antennas";
						publicVariable "antennasDead";
						["TaskSucceeded", ["", "Radio Tower Destroyed"]] remoteExec ["BIS_fnc_showNotification", teamPlayer];
						["TaskFailed", ["", "Radio Tower Destroyed"]] remoteExec ["BIS_fnc_showNotification", Occupants];
					}
				];
			};
		};
	};
};

if (count _posBank > 0) then {
	for "_i" from 0 to (count _posBank - 1) do {
		_bankProv = nearestObjects [_posBank select _i, ["Land_Offices_01_V1_F"], 25];
		if (count _bankProv > 0) then {
			_banco = _bankProv select 0;
			banks = banks + [_banco];
		};
	};
};

blackListDest = (markersX - controlsX - ["Synd_HQ"] - citiesX) select {!((position ([getMarkerPos _x] call A3A_fnc_findNearestGoodRoad)) inArea _x)};

publicVariable "blackListDest";
//the following is the console code snippet I use to pick positions of any kind of building. You may do this for gas stations, banks, radios etc.. markerPos "Base_4" is because it's in the middle of the island, and inside the array you may find the type of building I am searching for. Paste the result in a txt and add it to the corresponding arrays.
/*
pepe = nearestObjects [markerPos "base_4", ["Land_Communication_F","Land_TTowerBig_1_F","Land_TTowerBig_2_F"], 16000];
pospepe = [];
{pospepe = pospepe + getPos _x} forEach pepe;
copytoclipboard str pospepe;
*/

publicVariable "markersX";
publicVariable "citiesX";
publicVariable "airportsX";
publicVariable "resourcesX";
publicVariable "factories";
publicVariable "outposts";
publicVariable "controlsX";
publicVariable "seaports";
publicVariable "destroyedCities";
publicVariable "forcedSpawn";
publicVariable "outpostsFIA";
publicVariable "seaMarkers";
publicVariable "spawnPoints";
publicVariable "antennas";
publicVariable "antennasDead";
publicVariable "mrkAntennas";
publicVariable "banks";
publicVariable "seaSpawn";
publicVariable "seaAttackSpawn";
publicVariable "defaultControlIndex";

if (isMultiplayer) then {
	[petros, "hint","Zones Init Completed"] remoteExec ["A3A_fnc_commsMP", -2]
};
