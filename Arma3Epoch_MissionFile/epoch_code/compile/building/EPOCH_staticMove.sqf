/*
	Author: Aaron Clark - EpochMod.com

    Contributors:

	Description:
	Base building base building with ghost preview.

    Licence:
    Arma Public License Share Alike (APL-SA) - https://www.bistudio.com/community/licenses/arma-public-license-share-alike

    Github:
    https://github.com/EpochModTeam/Epoch/tree/release/Sources/epoch_code/compile/building/EPOCH_simulSwap.sqf

    Example:
    [_object,_item] spawn EPOCH_staticMove;

    Parameter(s):
		_this select 0: OBJECT - Base building object
		_this select 1: STRING - Item to consume on build finalization

	Returns:
	NOTHING
*/
//[[[cog import generate_private_arrays ]]]
private ["_snapped","_EPOCH_1","_EPOCH_2","_allowedSnapObjects","_allowedSnapPoints","_arr_snapPoints","_baselineSnapPos","_cfgBaseBuilding","_class","_currentOffSet","_currentPos","_currentTarget","_dir2","_direction","_distance","_energyCost","_ins","_isSnap","_lastCheckTime","_maxHeight","_maxSnapDistance","_nearestObject","_nearestObjects","_numberOfContacts","_objSlot","_objType","_offSet","_offsetZPos","_pOffset","_pos1","_pos1_snap","_pos2","_pos2ATL","_pos2_snap","_pos_snapObj","_rejectMove","_simulClass","_snapChecks","_snapConfig","_snapDistance","_snapPointsPara","_snapPointsPerp","_snapPos","_snapPos1","_snapPosition","_snapType","_stabilityCheck","_up2","_worldspace"];
//[[[end]]]
if !(isNil "EPOCH_simulSwap_Lock") exitWith{};

params [
	["_object",objNull],
	["_item",""]
];

// exit if object is nulll
if (isNull _object) exitWith{ EPOCH_target = objNull; };
// exit if item is not given
if (_item == "") exitWith{ EPOCH_target = objNull; };

if (EPOCH_playerEnergy <= 0) exitWith{
	["Need Energy", 5] call Epoch_message;
};

// Remove object if not allowed
if !(_object call EPOCH_isBuildAllowed) exitWith{ deleteVehicle _object };

EPOCH_simulSwap_Lock = true;
_objType = typeOf _object;
_cfgBaseBuilding = 'CfgBaseBuilding' call EPOCH_returnConfig;
_class = getText(_cfgBaseBuilding >> _objType >> "GhostPreview");

if (_class != "") then {
	_energyCost = getNumber(_cfgBaseBuilding >> _objType >> "energyCost");
	_maxHeight = getNumber(_cfgBaseBuilding >> _objType >> "maxHeight");
	_simulClass = getText(_cfgBaseBuilding >> _objType >> "simulClass");
	_snapChecks = getArray(("CfgSnapChecks" call EPOCH_returnConfig) >> _objType >> "nails");
	_allowedSnapPoints = getArray(_cfgBaseBuilding >> _class >> "allowedSnapPoints");
	_allowedSnapObjects = getArray(_cfgBaseBuilding >> _class >> "allowedSnapObjects");

	if (_energyCost == 0) then {_energyCost = 0.1;};

	_maxSnapDistance = 1;
	_lastCheckTime = diag_tickTime;
	_stabilityCheck = false;

	// force sim check if object has sim class and default max height to 9m if not already specified
	if (_simulClass != "") then {
		_stabilityCheck = true;
		if (_maxHeight == 0) then {
			_maxHeight = 500;
		};
	};

	_CfgEpochClient = 'CfgEpochClient' call EPOCH_returnConfig;
	_maxBuildingHeight = getNumber(_CfgEpochClient >> "maxBuildingHeight");
	if !(_maxBuildingHeight == 0) then {
		_maxHeight = _maxHeight min _maxBuildingHeight;
	};

	_objSlot = _object getVariable["BUILD_SLOT", -1];

	deleteVehicle _object;

	_pos2 = player modelToWorldVisual[EPOCH_X_OFFSET, EPOCH_Y_OFFSET, EPOCH_Z_OFFSET];

	EPOCH_target = createVehicle[_class, _pos2, [], 0, "CAN_COLLIDE"];
	// send to server
	[EPOCH_target] remoteExec ["EPOCH_localCleanup",2];

	if (_pos2 select 2 > _maxHeight) then {
		_pos2 set[2, _maxHeight];
	};

	_pos2ATL = _pos2;
	if (surfaceIsWater _pos2ATL) then {
		_pos2ATL = ASLtoATL _pos2ATL;
	};
	EPOCH_target setposATL _pos2ATL;

	EPOCH_target attachTo[player];
	_currentTarget = EPOCH_target;

	if (_objSlot != -1) then {
		_currentTarget setVariable["BUILD_SLOT", _objSlot, true];
	};

	EPOCH_X_OFFSET = 0;
	EPOCH_Y_OFFSET = 5;
	EPOCH_Z_OFFSET = 0;
	EPOCH_buildDirection = 0;
	EPOCH_buildDirectionPitch = 0;
	EPOCH_buildDirectionRoll = 0;
	EPOCH_target_attachedTo = player;
	EP_snap = objNull;
	EP_snapPos = [0, 0, 0];
	_isSnap = false;
	_currentOffSet = [];
	_EPOCH_1 = diag_tickTime;
	_EPOCH_2 = diag_tickTime;
	_nearestObjects = [];
	_Snapdirection = EPOCH_snapDirection;
	_snapped = false;
	_currentTargetAttachedTo = player;
	_AnchorPos = [];
	_helper = objnull;
	
	if (typeof EPOCH_target in ["CinderWallHalf_Ghost_EPOCH","WoodLargeWall_Ghost_EPOCH"]) then {
		_helper = "Sign_Arrow_Direction_Yellow_F" createVehicleLocal (getpos EPOCH_target);
		_helper attachto [EPOCH_target, [0, -0.5, 1]];
		_helper setdir 180;
	};

	_MoveObject = {
		if (!(_currentOffSet isEqualTo _offSet) || EPOCH_doRotate || !isnull EP_snap && _currentTargetAttachedTo isequalto EPOCH_target_attachedTo) then {
			_currentOffSet = _offSet;
			EPOCH_doRotate = false;
			EPOCH_arr_snapPoints = [];
			EP_snap = objnull;
			_pos2ATL = _pos2;
			if (surfaceIsWater _pos2ATL) then {
				_pos2ATL = ASLtoATL _pos2ATL;
			};
			EPOCH_target setposATL _pos2ATL;
			if (_currentTargetAttachedTo isequalto player) then {
				EPOCH_target attachTo [player];
			}
			else {
				{
					detach _x;
				} forEach attachedObjects player;
			};
			_newDirAndUp = [[sin EPOCH_buildDirection * cos EPOCH_buildDirectionPitch, cos EPOCH_buildDirection * cos EPOCH_buildDirectionPitch, sin EPOCH_buildDirectionPitch],[[ sin EPOCH_buildDirectionRoll,-sin EPOCH_buildDirectionPitch,cos EPOCH_buildDirectionRoll * cos EPOCH_buildDirectionPitch],-EPOCH_buildDirection] call BIS_fnc_rotateVector2D];
			EPOCH_target setVectorDirAndUp _newDirAndUp;
		};
	};

	while {EPOCH_target == _currentTarget} do {
		_rejectMove = false;
		if ((diag_tickTime - _lastCheckTime) > 10) then {
			_lastCheckTime = diag_tickTime;
			_rejectMove = !(EPOCH_target call EPOCH_isBuildAllowed);
		};
		if (_rejectMove) exitWith{
			deleteVehicle EPOCH_target;
			_currentTarget = objnull;
		};
		if (player distance _currentTarget > 15) exitWith{
			deleteVehicle EPOCH_target;
			_currentTarget = objnull;
			["Building Abort: Distance to high", 5] call Epoch_message;
		};
		if ((diag_tickTime - _EPOCH_1) > 1) then {
			_EPOCH_1 = diag_tickTime;
			if !(isNull EPOCH_target) then {
				_nearestObjects = nearestObjects[EPOCH_target, _allowedSnapObjects, 12];
				EPOCH_playerEnergy = (EPOCH_playerEnergy - _energyCost) max 0;
			};
		};
		if !(_currentTargetAttachedTo isequalto EPOCH_target_attachedTo) then {
			_currentTargetAttachedTo = EPOCH_target_attachedTo;
			EPOCH_X_OFFSET = 0;
			EPOCH_Z_OFFSET = 0;
			EPOCH_doRotate = true;
			if !(_currentTargetAttachedTo isequalto player) then {
				EPOCH_buildDirection = getdir EPOCH_target;
				EPOCH_Y_OFFSET = 0;
				_AnchorPos = getposasl EPOCH_target;
			}
			else {
				EPOCH_buildDirection = 0;
				EPOCH_Y_OFFSET = 5;
			};
		};
		_offSet = [EPOCH_X_OFFSET, EPOCH_Y_OFFSET, EPOCH_Z_OFFSET];
		if (_currentTargetAttachedTo isequalto player) then {
			_pos2 = _currentTargetAttachedTo modelToWorldVisual _offSet;
			if (surfaceIsWater _pos2) then {
				_pos2 set[2, ((getPosASL _currentTargetAttachedTo) select 2) + EPOCH_Z_OFFSET];
			};
		}
		else {
			_pos2 = [(_AnchorPos select 0) + EPOCH_X_OFFSET,(_AnchorPos select 1) + EPOCH_Y_OFFSET,(_AnchorPos select 2) + EPOCH_Z_OFFSET];
			if !(surfaceIsWater _pos2) then {
				_pos2 = asltoatl _pos2;
			};
		};
		if (_pos2 select 2 > _maxHeight) then {
			_pos2 set[2, _maxHeight];
			EPOCH_doRotate = true;
		};
		if (_currentTargetAttachedTo isequalto player) then {
			if (!(_nearestobjects isequalto []) && EPOCH_buildMode == 1) then {
				if ((_pos2 distance EP_snapPos) > _maxSnapDistance || EPOCH_snapDirection != _Snapdirection) then {
					_Snapdirection = EPOCH_snapDirection;
					EP_snapPos = [0,0,0];
					_snapped = false;
					{
						_nearestObject = _x;
						_isSnap = false;
						_snapPosition = [0, 0, 0];
						if (!isNull _nearestObject) then {
							_snapConfig = _cfgBaseBuilding >> (typeOf _nearestObject);
							_snapPointsPara = getArray(_snapConfig >> "snapPointsPara");
							_snapPointsPerp = getArray(_snapConfig >> "snapPointsPerp");

							// base line for z height offset
							_baselineSnapPos = _nearestObject modelToWorldVisual [0,0,0];
							{
								_x params ["_snapPoints","_type"];
								{
									if (_x in _allowedSnapPoints) then {
										_pOffset = _nearestObject selectionPosition _x;
										_snapPos = _nearestObject modelToWorldVisual _pOffset;
										if (surfaceIsWater _snapPos) then {
											_snapPos set[2, ((getPosASL _nearestObject) select 2) + (_pOffset select 2)];
										};
										_snapDistance = _pos2 distance _snapPos;
										if (_snapDistance < _maxSnapDistance) exitWith{
											_isSnap = true;
											_snapPosition = _snapPos;
											_snapType = _type;
										};
									};
								} forEach _snapPoints;
							} forEach [[_snapPointsPara,"para"],[_snapPointsPerp,"perp"]];
							_distance = _pos2 distance _currentTarget;
							if (_isSnap && _distance < 5) exitwith {
								EP_snap = _nearestObject;
								EP_snapPos = _snapPosition;
								_direction = getDir _nearestObject;
								if (_snapType == "perp") then {
									_snapPos1 = [_snapPosition select 0, _snapPosition select 1, 0];
									_pos_snapObj = getposATL _nearestObject;
									_pos_snapObj set[2, 0];
									_direction = _direction - (_snapPos1 getDir _pos_snapObj);
								} 
								else {
									_direction = 0;
								};
								if (EPOCH_snapDirection > 0) then {
									if (EPOCH_snapDirection == 1) then {
										_direction = _direction + 90;
									};
									if (EPOCH_snapDirection == 2) then {
										_direction = _direction + 180;
									};
									if (EPOCH_snapDirection == 3) then {
										_direction = _direction + 270;
									};
								};
								if (_direction > 360) then {
									_direction = _direction - ((floor (_direction/360))*360);
								};
								if (_direction < 0) then {
									_direction = _direction + ((floor (-_direction/360))*360);
								};
								{
									detach _x;
								} forEach attachedObjects player;
								_dir2 = [vectorDir _nearestObject, _direction] call BIS_fnc_returnVector;
								if (_pos2 select 2 > _maxHeight) then {
									_pos2 set[2, _maxHeight];
								};
								if (surfaceIsWater _snapPosition) then {
									_snapPosition = ASLtoATL _snapPosition;
								};
								_currentTarget setVectorDirAndUp[_dir2, (vectorUp _nearestObject)];
								_currentTarget setposATL _snapPosition;
								_snapped = true;
								_arr_snapPoints = [];
								EPOCH_arr_snapPoints = [];
								{
									_pos1_snap = _currentTarget modelToWorldVisual (_x select 0);
									_pos2_snap = _currentTarget modelToWorldVisual (_x select 1);
									_ins = lineIntersectsSurfaces [AGLToASL _pos1_snap, AGLToASL _pos2_snap,player,_currentTarget,true,1,"VIEW","FIRE"];
									if (count _ins > 0) then {
										if (surfaceIsWater _snapPosition) then {
											_arr_snapPoints pushBackUnique (_ins select 0 select 0);
										} else {
											_arr_snapPoints pushBackUnique ASLToATL(_ins select 0 select 0);
										};
									};
									if (count _arr_snapPoints >= 2) exitWith { EPOCH_arr_snapPoints = _arr_snapPoints; }
								} forEach _snapChecks;
							};
						};
						if (_snapped) exitwith {};
					} forEach _nearestObjects;
				};
				if (!_snapped) then {
					[] call _MoveObject;
				};
			}
			else {
				[] call _MoveObject;
			};
		}
		else {
			[] call _MoveObject;
		};
	};

	EPOCH_arr_snapPoints = [];

	{
		detach _x;
	} forEach attachedObjects _currentTargetAttachedTo;
	
	if (!isnull _helper) then {
		deletevehicle _helper;
	};

	if !(isNull _currentTarget) then {

		// check if touching ground
		_currentPos = getPosATL _currentTarget;
		if (_currentPos select 2 > _maxHeight) then {
			_currentPos set[2, _maxHeight];
			_currentTarget setPosATL _currentPos;
		};

		_currentPos set[2, (_currentPos select 2) + 0.1];

		// remove item here
		if (([player, _item] call BIS_fnc_invRemove) == 1) then {

			if (_stabilityCheck && !isTouchingGround _currentTarget) then {

				_offsetZPos = [_currentPos select 0, _currentPos select 1, (_currentPos select 2) - 0.5];
				if !(terrainIntersect[_currentPos, _offsetZPos]) then {

					_numberOfContacts = 0;
					{
				        _pos1_snap = _currentTarget modelToWorldVisual (_x select 0);
				        _pos2_snap = _currentTarget modelToWorldVisual (_x select 1);
				        _ins = lineIntersectsSurfaces [AGLToASL _pos1_snap, AGLToASL _pos2_snap,player,_currentTarget,true,1,"VIEW","FIRE"];
				        if (count _ins > 0) then {
							_numberOfContacts = _numberOfContacts + 1;
				        };
						if (_numberOfContacts >= 2) exitWith {}
				    } forEach _snapChecks;

					if (_numberOfContacts < 2) then {
						// TODO: foundations need to be handled
						// change to sim
						_worldspace = [getposATL _currentTarget, vectordir _currentTarget, vectorup _currentTarget];
						deleteVehicle _currentTarget;
						_currentTarget = createVehicle[_simulClass, (_worldspace select 0), [], 0, "CAN_COLLIDE"];

						_currentTarget setVectorDirAndUp[_worldspace select 1, _worldspace select 2];
						_currentTarget setposATL(_worldspace select 0);

					};
				};
			};
			_currentTarget spawn EPOCH_countdown;
		};
	};
};

[] spawn{
	uiSleep 2;
	EPOCH_simulSwap_Lock = nil;
};
