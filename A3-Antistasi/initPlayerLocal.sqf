#include "Garage\defineCommon.inc"

if (hasInterface) then
	{
	waitUntil {!isNull player};
	waitUntil {player == player};
	player removeweaponGlobal "itemmap";
	player removeweaponGlobal "itemgps";
	//Disable player saving until they're fully ready, and have chosen whether to load their save.
	player setVariable ["canSave", false, true];
	};
if (isMultiplayer) then
	{
	if (!isServer) then
		{
		call compile preprocessFileLineNumbers "initFuncs.sqf";
		call compile preprocessFileLineNumbers "initVar.sqf";
		waitUntil {!isNil "initVar"}; diag_log format ["Antistasi MP Client. initVar is public. Version %1",antistasiVersion];
		}
	else
		{
		waitUntil {sleep 0.5;(!isNil "serverInitDone")};
		};
	[] execVM "briefing.sqf";
	};
if (!hasInterface) exitWith
	{
	if (worldName == "Tanoa") then {call compile preprocessFileLineNumbers "roadsDB.sqf"};
	if (worldName == "Altis") then {call compile preprocessFileLineNumbers "roadsDBAltis.sqf"};
	if (worldName == "chernarus_summer") then {call compile preprocessFileLineNumbers "roadsDBcherna.sqf"};
	[clientOwner] remoteExec ["A3A_fnc_addHC",2];
	};
_isJip = _this select 1;
if (isMultiplayer) then
	{
	if (side player == teamPlayer) then {player setVariable ["eligible",true,true]};
	musicON = false;
	//waitUntil {scriptdone _introshot};
	disableUserInput true;
	cutText ["Waiting for Players and Server Init","BLACK",0];
	diag_log "Antistasi MP Client. Waiting for serverInitDone";
	waitUntil {(!isNil "serverInitDone")};
	cutText ["Starting Mission","BLACK IN",0];
	diag_log "Antistasi MP Client. serverInitDone is public";
	diag_log format ["Antistasi MP Client: JIP?: %1",_isJip];
	if (hasTFAR) then {[] execVM "orgPlayers\radioJam.sqf"};//reestablecer cuando controle las variables
	tkPunish = if ("tkPunish" call BIS_fnc_getParamValue == 1) then {true} else {false};
	if ((side player == teamPlayer) and tkPunish) then
		{
		player addEventHandler ["Fired",
			{
			_typeX = _this select 1;
			if ((_typeX == "Put") or (_typeX == "Throw")) then
				{
				if (player distance petros < 50) then
					{
					deleteVehicle (_this select 6);
					if (_typeX == "Put") then
						{
						if (player distance petros < 10) then {[player,60] spawn A3A_fnc_punishment};
						};
					};
				};
			}];
		};
	if (!isNil "placementDone") then {_isJip = true};//workaround for BIS fail on JIP detection
	}
else
	{
	theBoss = player;
	groupX = group player;
	if (worldName == "Tanoa") then {groupX setGroupId ["Pulu","GroupColor4"]} else {groupX setGroupId ["Stavros","GroupColor4"]};
	player setIdentity "protagonista";
	player setUnitRank "COLONEL";
	player hcSetGroup [group player];
	waitUntil {/*(scriptdone _introshot) and */(!isNil "serverInitDone")};
	//_nul = addMissionEventHandler ["Loaded", {_nul = [] execVM "statistics.sqf";_nul = [] execVM "reinitY.sqf";}];
	};
[] execVM "CREATE\ambientCivs.sqf";
private ["_colourTeamPlayer", "_colorInvaders"];
_colourTeamPlayer = teamPlayer call BIS_fnc_sideColor;
_colorInvaders = Invaders call BIS_fnc_sideColor;
_positionX = if (side player == side (group petros)) then {position petros} else {getMarkerPos "respawn_west"};
{
_x set [3, 0.33]
} forEach [_colourTeamPlayer, _colorInvaders];
_introShot = [
		_positionX, // Target position
		format ["%1",worldName], // SITREP text
		50, //  altitude
		50, //  radius
		90, //  degrees viewing angle
		0, // clockwise movement
		[
			["\a3\ui_f\data\map\markers\nato\o_inf.paa", _colourTeamPlayer, markerPos "insertMrk", 1, 1, 0, "Insertion Point", 0],
			["\a3\ui_f\data\map\markers\nato\o_inf.paa", _colorInvaders, markerPos "towerBaseMrk", 1, 1, 0, "Radio Towers", 0]
		]
	] spawn BIS_fnc_establishingShot;

//Trigger credits loading.
[] spawn {
	waitUntil {!isNil "BIS_fnc_establishingShot_playing" && {BIS_fnc_establishingShot_playing}};
	private _credits = [] execVM "credits.sqf";
};
		
disableUserInput false;
player addWeaponGlobal "itemmap";
if !(hasIFA) then {player addWeaponGlobal "itemgps"};
player setVariable ["spawner",true,true];
if (isMultiplayer) then
	{
	if ("pMarkers" call BIS_fnc_getParamValue == 1) then {[] execVM "playerMarkers.sqf"};
	};
if (!hasACE) then
	{
	[player] execVM "Revive\initRevive.sqf";
	tags = [] execVM "tags.sqf";
	}
else
	{
	if (hasACEhearing) then {player addItem "ACE_EarPlugs"};
	if (!hasACEMedical) then {[player] execVM "Revive\initRevive.sqf"};
	};

if (player getVariable ["pvp",false]) exitWith
	{
	lastVehicleSpawned = objNull;
	pvpEnabled = if ("allowPvP" call BIS_fnc_getParamValue == 1) then {true} else {false};
	if ((!_isJIP) or !pvpEnabled) then
		{
		["noPvP",false,1,false,false] call BIS_fnc_endMission;
		diag_log "Antistasi: PvP player kicked because he is not jipping or PvP slots are disabled";
		}
	else
		{
		if (not([player] call A3A_fnc_isMember)) then
			{
			["noPvP",false,1,false,false] call BIS_fnc_endMission;
			diag_log "Antistasi: PvP player kicked because he is not member";
			}
		else
			{
			if ({(side group _x != teamPlayer)} count playableUnits > {(side group _x == teamPlayer)} count playableUnits) then
				{
				["noPvP",false,1,false,false] call BIS_fnc_endMission;
				diag_log "Antistasi: PvP player kicked because PvP players number is equal to non PvP";
				}
			else
				{
				[player] remoteExec ["A3A_fnc_playerHasBeenPvPCheck",2];
				diag_log "Antistasi: PvP player logged in, doing server side checks if the player has been rebel recently";
				};
			};
		};
	if (side player == Occupants) then
		{
		if (activeUSAF) then {[player] call A3A_fnc_RHSdress};
		}
	else
		{
		if (activeAFRF) then {[player] call A3A_fnc_RHSdress};
		};
	if (hasACE) then {[] call A3A_fnc_ACEpvpReDress};
	respawnTeamPlayer setMarkerAlphaLocal 0;
	//Let a player in a vehicle if they're: A passenger, or the vehicle is a light unarmed vehicle.
	player addEventHandler ["GetInMan",
		{
		private ["_unit","_veh", "_role"];
		_unit = _this select 0;
		_role = _this select 1;
		_veh = _this select 2;
		if (_veh != lastVehicleSpawned) then
			{
			private _isACEHandcuffed = _unit getVariable ["ACE_captives_isHandcuffed", false];
			if (!((typeOf _veh) in (vehNATOLightUnarmed + vehCSATLightUnarmed)) && !(_role == "Cargo") && !_isACEHandcuffed) then
				{
				//ACE has a loop which tries to force handcuffed players back into vehicles if anything kicks them out.
				//The spawn stops Arma hanging indefinitely in an infinite loop if /somehow/ we hit that condition.
				_unit spawn { moveOut _this };
				hint "PvP player are only allowed to use their own or other PvP player vehicles";
				};
			};
		}];
	player addEventHandler ["InventoryOpened",
		{
		_override = false;
		_boxX = typeOf (_this select 1);
		if ((_boxX == NATOAmmoBox) or (_boxX == CSATAmmoBox)) then {_override = true};
		_override
		}];
	_nameX = if (side player == Occupants) then {nameOccupants} else {nameInvaders};
	waituntil {!isnull (finddisplay 46)};
	gameMenu = (findDisplay 46) displayAddEventHandler ["KeyDown",
		{
		_handled = FALSE;
		if (_this select 1 == 207) then
			{
			if (!hasACEhearing) then
				{
				if (soundVolume <= 0.5) then
					{
					0.5 fadeSound 1;
					hintSilent "You've taken out your ear plugs.";
					}
				else
					{
					0.5 fadeSound 0.1;
					hintSilent "You've inserted your ear plugs.";
					};
				};
			}
		else
			{
			if (_this select 1 == 21) then
				{
				closedialog 0;
				_nul = createDialog "NATO_player";
				};
			};
		_handled
		}];
	};

player setVariable ["score",0,true];
player setVariable ["owner",player,true];
player setVariable ["punish",0,true];
player setVariable ["moneyX",100,true];
player setUnitRank "PRIVATE";
player setVariable ["rankX",rank player,true];

stragglers = creategroup teamPlayer;
(group player) enableAttack false;
player setUnitTrait ["camouflageCoef",0.8];
player setUnitTrait ["audibleCoef",0.8];

if (activeGREF) then {[player] call A3A_fnc_RHSdress};
player setUnitLoadout ((getUnitLoadout player) call A3A_fnc_stripGearFromLoadout);
player setvariable ["compromised",0];
player addEventHandler ["FiredMan",
	{
	_player = _this select 0;
	if (captive _player) then
		{
		//if ({((side _x== Invaders) or (side _x== Occupants)) and (_x knowsAbout player > 1.4)} count allUnits > 0) then
		if ({if (((side _x == Occupants) or (side _x == Invaders)) and (_x distance player < 300)) exitWith {1}} count allUnits > 0) then
			{
			[_player,false] remoteExec ["setCaptive",0,_player];
			_player setCaptive false;
			}
		else
			{
			_city = [citiesX,_player] call BIS_fnc_nearestPosition;
			_size = [_city] call A3A_fnc_sizeMarker;
			_dataX = server getVariable _city;
			if (random 100 < _dataX select 2) then
				{
				if (_player distance getMarkerPos _city < _size * 1.5) then
					{
					[_player,false] remoteExec ["setCaptive",0,_player];
					_player setCaptive false;
					if (vehicle _player != _player) then
						{
						{if (isPlayer _x) then {[_x,false] remoteExec ["setCaptive",0,_x]; _x setCaptive false}} forEach ((assignedCargo (vehicle _player)) + (crew (vehicle _player)) - [player]);
						};
					};
				};
			};
		}
	}
	];
player addEventHandler ["InventoryOpened",
	{
	private ["_playerX","_containerX","_typeX"];
	_control = false;
	_playerX = _this select 0;
	if (captive _playerX) then
		{
		_containerX = _this select 1;
		_typeX = typeOf _containerX;
		if (((_containerX isKindOf "Man") and (!alive _containerX)) or (_typeX == NATOAmmoBox) or (_typeX == CSATAmmoBox)) then
			{
			if ({if (((side _x== Invaders) or (side _x== Occupants)) and (_x knowsAbout _playerX > 1.4)) exitWith {1}} count allUnits > 0) then
				{
				[_playerX,false] remoteExec ["setCaptive",0,_playerX];
				_playerX setCaptive false;
				}
			else
				{
				_city = [citiesX,_playerX] call BIS_fnc_nearestPosition;
				_size = [_city] call A3A_fnc_sizeMarker;
				_dataX = server getVariable _city;
				if (random 100 < _dataX select 2) then
					{
					if (_playerX distance getMarkerPos _city < _size * 1.5) then
						{
						[_playerX,false] remoteExec ["setCaptive",0,_playerX];
						_playerX setCaptive false;
						};
					};
				};
			};
		};
	_control
	}];
/*
player addEventHandler ["InventoryClosed",
	{
	_control = false;
	_uniform = uniform player;
	_typeSoldier = getText (configfile >> "CfgWeapons" >> _uniform >> "ItemInfo" >> "uniformClass");
	_sideType = getNumber (configfile >> "CfgVehicles" >> _typeSoldier >> "side");
	if ((_sideType == 1) or (_sideType == 0) and (_uniform != "")) then
		{
		if !(player getVariable ["disguised",false]) then
			{
			hint "You are wearing an enemy uniform, this will make the AI attack you. Beware!";
			player setVariable ["disguised",true];
			player addRating (-1*(2001 + rating player));
			};
		}
	else
		{
		if (player getVariable ["disguised",false]) then
			{
			hint "You removed your enemy uniform";
			player addRating (rating player * -1);
			};
		};
	_control
	}];
*/
player addEventHandler ["HandleHeal",
	{
	_player = _this select 0;
	if (captive _player) then
		{
		if ({((side _x== Invaders) or (side _x== Occupants)) and (_x knowsAbout player > 1.4)} count allUnits > 0) then
			{
			[_player,false] remoteExec ["setCaptive",0,_player];
			_player setCaptive false;
			}
		else
			{
			_city = [citiesX,_player] call BIS_fnc_nearestPosition;
			_size = [_city] call A3A_fnc_sizeMarker;
			_dataX = server getVariable _city;
			if (random 100 < _dataX select 2) then
				{
				if (_player distance getMarkerPos _city < _size * 1.5) then
					{
					[_player,false] remoteExec ["setCaptive",0,_player];
					_player setCaptive false;
					};
				};
			};
		}
	}
	];
player addEventHandler ["WeaponAssembled",
	{
	private ["_veh"];
	_veh = _this select 1;
	if (_veh isKindOf "StaticWeapon") then
		{
		if (not(_veh in staticsToSave)) then
			{
			staticsToSave pushBack _veh;
			publicVariable "staticsToSave";
			[_veh] call A3A_fnc_AIVEHinit;
			};
		_markersX = markersX select {sidesX getVariable [_x,sideUnknown] == teamPlayer};
		_pos = position _veh;
		if (_markersX findIf {_pos inArea _x} != -1) then {hint "Static weapon has been deployed for use in a nearby zone, and will be used by garrison militia if you leave it here the next time the zone spawns"};
		}
	else
		{
		_veh addEventHandler ["Killed",{[_this select 0] remoteExec ["A3A_fnc_postmortem",2]}];
		};
	}];
player addEventHandler ["WeaponDisassembled",
		{
		_bag1 = _this select 1;
		_bag2 = _this select 2;
		//_bag1 = objectParent (_this select 1);
		//_bag2 = objectParent (_this select 2);
		[_bag1] call A3A_fnc_AIVEHinit;
		[_bag2] call A3A_fnc_AIVEHinit;
		}
	];

player addEventHandler ["GetInMan",
	{
	private ["_unit","_veh"];
	_unit = _this select 0;
	_veh = _this select 2;
	_exit = false;
	if (isMultiplayer) then
		{
		if !([player] call A3A_fnc_isMember) then
			{
			_owner = _veh getVariable "ownerX";
			if (!isNil "_owner") then
				{
				if (_owner isEqualType "") then
					{
					if ({getPlayerUID _x == _owner} count (units group player) == 0) then
						{
						hint "You cannot board other player vehicle if you are not in the same group";
						moveOut _unit;
						_exit = true;
						};
					};
				};
			};
		};
	if (!_exit) then
		{
		if (((typeOf _veh) in arrayCivVeh) or ((typeOf _veh) in civBoats)) then
			{
			if (!(_veh in reportedVehs)) then
				{
				[] spawn A3A_fnc_undercover;
				};
			};
		};
	}
	];

if (isMultiplayer) then
	{
	["InitializePlayer", [player]] call BIS_fnc_dynamicGroups;//Exec on client
	["InitializeGroup", [player,teamPlayer,true]] call BIS_fnc_dynamicGroups;
	membershipEnabled = if ("membership" call BIS_fnc_getParamValue == 1) then {true} else {false};
	if (membershipEnabled) then
		{
		if !([player] call A3A_fnc_isMember) then
			{
			if (isServer) then
				{
				membersX pushBack (getPlayerUID player);
				publicVariable "membersX";
				};
			_nonMembers = {(side group _x == teamPlayer) and !([_x] call A3A_fnc_isMember)} count playableUnits;
			if (_nonMembers >= (playableSlotsNumber teamPlayer) - bookedSlots) then {["memberSlots",false,1,false,false] call BIS_fnc_endMission};
			if (memberDistance != 16000) then {[] execVM "orgPlayers\nonMemberDistance.sqf"};
			};
		};
	};

waitUntil {scriptdone _introshot};
if (_isJip) then
	{
	_nul = [] execVM "modBlacklist.sqf";
	player setVariable ["punish",0,true];
	waitUntil {!isNil "posHQ"};
	player setPos posHQ;
	[true] execVM "reinitY.sqf";
	if (not([player] call A3A_fnc_isMember)) then
		{
		if ((serverCommandAvailable "#logout") or (isServer)) then
			{
			membersX pushBack (getPlayerUID player);
			publicVariable "membersX";
			hint "You are not in the member's list, but as you are Server Admin, you have been added up. Welcome!"
			}
		else
			{
			hint "Welcome Guest\n\nYou have joined this server as guest";
			//if ((count playableUnits == maxPlayers) and (({[_x] call A3A_fnc_isMember} count playableUnits) < count membersX) and (serverName in officialServers)) then {["serverFull",false,1,false,false] call BIS_fnc_endMission};
			};
		}
	else
		{
		hint format ["Welcome back %1", name player];
		if ((isNil "theBoss" || {isNull theBoss}) && {{([_x] call A3A_fnc_isMember) and (side (group _x) == teamPlayer)} count playableUnits == 1}) then
			{
			[player] call A3A_fnc_theBossInit;
			};
		};
		if ((isNil "theBoss" || {isNull theBoss}) && {[player] call A3A_fnc_isMember}) then {
			{
			[] remoteExec ["A3A_fnc_assigntheBoss",2];
			};
		};
	waitUntil {!(isNil "missionsX")};
	if (count missionsX > 0) then
		{
		{
		_tsk = _x select 0;
		if ([_tsk] call BIS_fnc_taskExists) then
			{
			_state = _x select 1;
			if ((_tsk call BIS_fnc_taskState) != _state) then
				{
				/*
				_tskVar = _tsk call BIS_fnc_taskVar;
				_tskVar setTaskState _state;
				*/
				[_tsk,_state] call bis_fnc_taskSetState;
				};
			};
		} forEach missionsX;
		};
	if (isNil "placementDone") then
		{
		waitUntil {!isNil "theBoss"};
		if (player == theBoss) then
		    {
		    waitUntil {!(isNil"loadLastSave")};
		    if !(loadLastSave) then
	    		{
	    		_nul = [] spawn A3A_fnc_placementSelection;
					player setVariable ['canSave', true, true];
	    		};
			};
		}
	else
		{
		_nul = [] execVM "Dialogs\firstLoad.sqf";
		};
	diag_log "Antistasi MP Client. JIP client finished";
	player setPos (getMarkerPos respawnTeamPlayer);
	}
else
	{
	if (isNil "placementDone") then
		{
		waitUntil {!isNil "theBoss"};
		if (player == theBoss) then
		    {
		    player setVariable ["score", 25,true];
		    if (isMultiplayer) then
		    	{
		    	HC_commanderX synchronizeObjectsAdd [player];
				player synchronizeObjectsAdd [HC_commanderX];
		    	//_nul = [] execVM "Dialogs\initMenu.sqf";
		    	if !(loadLastSave) then
		    		{
		    		_nul = [] spawn A3A_fnc_placementSelection;
						//This shouldn't really be here, but it's triggered on every other path through the code.
						//This big if statement needs tidying, really.
						player setVariable ['canSave', true, true];
		    		}
		    	else
		    		{
		    		_nul = [true] execVM "Dialogs\firstLoad.sqf";
			    	};
		    	diag_log "Antistasi MP Client. Client finished";
		    	}
		    else
		    	{
		    	membersX = [];
		    	player setUnitTrait ["medic",true];
		    	player setUnitTrait ["engineer",true];
		    	 _nul = [] execVM "Dialogs\firstLoad.sqf";
		    	};
		    }
		else
			{
			player setVariable ["score", 0,true];
			_nul = [true] execVM "Dialogs\firstLoad.sqf";
			player setPos (getMarkerPos respawnTeamPlayer);
			};
		}
	else
		{
		if !(isServer) then
			{
			_nul = [] execVM "Dialogs\firstLoad.sqf";
			player setPos (getMarkerPos respawnTeamPlayer);
			};
		};
	};

_textX = [];

if ((hasTFAR) or (hasACRE)) then
	{
	_textX = ["TFAR or ACRE Detected\n\nAntistasi detects TFAR or ACRE in the server config.\nAll players will start with addon default radios.\nDefault revive system will shut down radios while players are inconscious.\n\n"];
	};
if (hasACE) then
	{
	_textX = _textX + ["ACE 3 Detected\n\nAntistasi detects ACE modules in the server config.\nACE items added to arsenal and ammoboxes. Default AI control is disabled\nIf ACE Medical is used, default revive system will be disabled.\nIf ACE Hearing is used, default earplugs will be disabled."];
	};
if (hasRHS) then
	{
	_textX = _textX + ["RHS Detected\n\nAntistasi detects RHS in the server config.\nDepending on the modules will have the following effects.\n\nAFRF: Replaces CSAT by a mix of russian units\n\nUSAF: Replaces NATO by a mix of US units\n\nGREF: Recruited AI will count with RHS as basic weapons, replaces FIA with Chdk units. Adds some civilian trucks"];
	};
if (hasFFAA) then
	{
	_textX = _textX + ["FFAA Detected\n\nAntistasi detects FFAA in the server config.\nFIA Faction will be replaced by Spanish Armed Forces"];
	};

if (hasTFAR or hasACE or hasRHS or hasACRE or hasFFAA) then
	{
	[_textX] spawn
		{
		sleep 0.5;
		_textX = _this select 0;
		"Integrated Mods Detected" hintC _textX;
		hintC_arr_EH = findDisplay 72 displayAddEventHandler ["unload", {
			0 = _this spawn {
				_this select 0 displayRemoveEventHandler ["unload", hintC_arr_EH];
				hintSilent "";
			};
			}];
		};
	};
waituntil {!isnull (finddisplay 46)};
gameMenu = (findDisplay 46) displayAddEventHandler ["KeyDown",A3A_fnc_keys];
//removeAllActions boxX;

if ((!isServer) and (isMultiplayer)) then {boxX call jn_fnc_arsenal_init};

boxX allowDamage false;
boxX addAction ["Transfer Vehicle cargo to Ammobox", "[] call A3A_fnc_empty"];
boxX addAction ["Move this asset", "moveHQObject.sqf",nil,0,false,true,"","(_this == theBoss)"];
flagX addAction ["HQ Management", {[] execVM "Dialogs\dialogHQ.sqf"},nil,0,false,true,"","(_this == theBoss) and (petros == leader group petros)"];
flagX allowDamage false;
flagX addAction ["Unit Recruitment", {if ([player,300] call A3A_fnc_enemyNearCheck) then {hint "You cannot recruit units while there are enemies near you"} else {nul=[] execVM "Dialogs\unit_recruit.sqf"}},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (side (group _this) == teamPlayer)"];
flagX addAction ["Buy Vehicle", {if ([player,300] call A3A_fnc_enemyNearCheck) then {hint "You cannot buy vehicles while there are enemies near you"} else {nul = createDialog "vehicle_option"}},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (side (group _this) == teamPlayer)"];
if (isMultiplayer) then {flagX addAction ["Personal Garage", {nul = [GARAGE_PERSONAL] spawn A3A_fnc_garage},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (side (group _this) == teamPlayer)"]};
flagX addAction ["Move this asset", "moveHQObject.sqf",nil,0,false,true,"","(_this == theBoss)"];

//Adds a light to the flag
private _flagLight = "#lightpoint" createVehicle (getPos flagX);
_flagLight setLightDayLight true;
_flagLight setLightColor [1, 1, 0.9];
_flagLight setLightBrightness 0.2;
_flagLight setLightAmbient [1, 1, 0.9];
_flagLight lightAttachObject [flagX, [0, 0, 4]];
_flagLight setLightAttenuation [7, 0, 0.5, 0.5];

vehicleBox allowDamage false;
vehicleBox addAction ["Heal, Repair and Rearm", "healandrepair.sqf",nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (side (group _this) == teamPlayer)"];
vehicleBox addAction ["Move this asset", "moveHQObject.sqf",nil,0,false,true,"","(_this == theBoss)"];

fireX allowDamage false;
[fireX, "fireX"] call A3A_fnc_flagaction;

mapX allowDamage false;
mapX addAction ["Game Options", {hint format ["Antistasi - %2\n\nVersion: %1\n\nDifficulty: %3\nUnlock Weapon Number: %4\nLimited Fast Travel: %5",antistasiVersion,worldName,if (skillMult == 1) then {"Normal"} else {if (skillMult == 0.5) then {"Easy"} else {"Hard"}},minWeaps,if (limitedFT) then {"Yes"} else {"No"}]; nul=CreateDialog "game_options";},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (side (group _this) == teamPlayer)"];
mapX addAction ["Map Info", {nul = [] execVM "cityinfo.sqf";},nil,0,false,true,"","(isPlayer _this) and (_this == _this getVariable ['owner',objNull]) and (side (group _this) == teamPlayer)"];
mapX addAction ["Move this asset", "moveHQObject.sqf",nil,0,false,true,"","(_this == theBoss)"];
if (isMultiplayer) then {mapX addAction ["AI Load Info", "[] remoteExec [""A3A_fnc_AILoadInfo"",2]",nil,0,false,true,"","(_this == theBoss)"]};
_nul = [player] execVM "OrgPlayers\unitTraits.sqf";
groupPetros = group petros;
groupPetros setGroupIdGlobal ["Petros","GroupColor4"];
petros setIdentity "friendlyX";
petros setName "Petros";
petros disableAI "MOVE";
petros disableAI "AUTOTARGET";
petros addAction ["Mission Request", {nul=CreateDialog "mission_menu";},nil,0,false,true,"","_this == theBoss"];

disableSerialization;
//1 cutRsc ["H8erHUD","PLAIN",0,false];
_layer = ["statisticsX"] call bis_fnc_rscLayer;
_layer cutRsc ["H8erHUD","PLAIN",0,false];
[] spawn A3A_fnc_statistics;

while {true} do {
	sleep 180;	//каждые  проверяет на нахождение в тс
		
	["ARMA 3 REALWAR",45] spawn {
	params ["_serverName","_time"];
	if ((call TFAR_fnc_getTeamSpeakServerName) == _serverName) exitwith {};
	cutText ["", "BLACK FADED", _time+2];
	_time = _time + time;

	waituntil {Sleep 2;
	["<t size='2.5' color='#FF0000'>Вы не подключены<br />к TeamSpeak серверу!<br /><br />IP адрес: <br /><t color='#00ff00'>arma3realwar",0,0,1] spawn BIS_fnc_dynamicText;
	((call TFAR_fnc_getTeamSpeakServerName) == _serverName) or (time > _time)};
	cutText ["", "BLACK IN", 2];
	if ((call TFAR_fnc_getTeamSpeakServerName) == _serverName) exitwith {};
	["Endts",true,2] call BIS_fnc_endMission;
	};

};
