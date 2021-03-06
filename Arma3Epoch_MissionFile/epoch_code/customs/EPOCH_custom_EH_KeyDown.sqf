/*
	Author: Aaron Clark - EpochMod.com

    Contributors: [Ignatz] He-Man

	Description:
	Custom A3 Epoch KeyUp Eventhandler

    Licence:
    Arma Public License Share Alike (APL-SA) - https://www.bistudio.com/community/licenses/arma-public-license-share-alike

    Github:
    https://github.com/EpochModTeam/Epoch/tree/release/Sources/epoch_code/custom/EPOCH_custom_EH_KeyDown.sqf
*/
params ["_display","_dikCode","_shift","_ctrl","_alt"];
_handled = false;

/* Start VectorBuilding */
if (vehicle player == player) then {

	if (_dikCode == EPOCH_keysBuildMode1 && EPOCH_buildMode > 0) then {
        EPOCH_buildMode = 0;
		["Build Mode: Disabled", 5] call Epoch_message;
		EPOCH_Target = objNull;
        _handled = true;
	};

	if (EPOCH_buildMode > 0) then {
		if (!_ctrl) then {
			_step = 0.5;
			if(_shift)then{_step = 1.5;};
			if(_alt)then{_step = 0.01;};
			switch (_dikCode) do {
				case EPOCH_keysBuildMovUp: { _adj = 0.1;if(_shift)then{_adj = 0.5};if(_alt)then{_adj = 0.01};EPOCH_Z_OFFSET = (EPOCH_Z_OFFSET + _adj) min 6; _handled = true };
				case EPOCH_keysBuildMovDn: { _adj = 0.1;if(_shift)then{_adj = 0.5};if(_alt)then{_adj = 0.01};EPOCH_Z_OFFSET = (EPOCH_Z_OFFSET - _adj) max - 3; _handled = true };
				case EPOCH_keysBuildMovFwd: { _adj = 0.1;if(_shift)then{_adj = 0.5};if(_alt)then{_adj = 0.01};EPOCH_Y_OFFSET = (EPOCH_Y_OFFSET + _adj) min 5; _handled = true };
				case EPOCH_keysBuildMovBak: { _adj = 0.1;if(_shift)then{_adj = 0.5};if(_alt)then{_adj = 0.01};EPOCH_Y_OFFSET = (EPOCH_Y_OFFSET - _adj) max -5; _handled = true };
				case EPOCH_keysBuildMovL: { _adj = 0.1;if(_shift)then{_adj = 0.5};if(_alt)then{_adj = 0.01};EPOCH_X_OFFSET = (EPOCH_X_OFFSET + _adj) min 5; _handled = true };
				case EPOCH_keysBuildMovR: { _adj = 0.1;if(_shift)then{_adj = 0.5};if(_alt)then{_adj = 0.01};EPOCH_X_OFFSET = (EPOCH_X_OFFSET - _adj) max -5; _handled = true };
				case EPOCH_keysBuildRotL: { _adj = 1;if(_shift)then{_adj = 2.5};if(_alt)then{_adj = 0.5};EPOCH_buildDirection = (EPOCH_buildDirection + _adj) min 180; EPOCH_doRotate = true; _handled = true };
				case EPOCH_keysBuildRotR: { _adj = 1;if(_shift)then{_adj = 2.5};if(_alt)then{_adj = 0.5};EPOCH_buildDirection = (EPOCH_buildDirection - _adj) max -180; EPOCH_doRotate = true; _handled = true };
				/*case EPOCH_keysBuildIt: { cursorTarget call EPOCH_fnc_SelectTarget; _handled = true };*/
				case eXpoch_keysVectorResetObject: { EPOCH_X_OFFSET = 0;EPOCH_Y_OFFSET = 5;EPOCH_Z_OFFSET = 0;EPOCH_buildDirection = 0;EPOCH_buildDirectionPitch = 0;EPOCH_buildDirectionRoll = 0;EPOCH_doRotate = true;_handled = true };
			};
			if (Epoch_target iskindof 'Const_Ghost_EPOCH') then {
				switch (_dikCode) do {
					case eXpoch_keysVectorTiltL: {_adj = 1;if(_shift)then{_adj = 2.5};if(_alt)then{_adj = 0.5};EPOCH_buildDirectionRoll = (EPOCH_buildDirectionRoll - _adj) max -180; EPOCH_doRotate = true; _handled = true };
					case eXpoch_keysVectorTiltR: {_adj = 1;if(_shift)then{_adj = 2.5};if(_alt)then{_adj = 0.5};EPOCH_buildDirectionRoll = (EPOCH_buildDirectionRoll + _adj) min 180; EPOCH_doRotate = true; _handled = true };
					case eXpoch_keysVectorTiltAwy: {_adj = 1;if(_shift)then{_adj = 2.5};if(_alt)then{_adj = 0.5};EPOCH_buildDirectionPitch = (EPOCH_buildDirectionPitch - _adj) max -180; EPOCH_doRotate = true; _handled = true };
					case eXpoch_keysVectorTiltTwd: {_adj = 1;if(_shift)then{_adj = 2.5};if(_alt)then{_adj = 0.5};EPOCH_buildDirectionPitch = (EPOCH_buildDirectionPitch + _adj) min 180; EPOCH_doRotate = true; _handled = true };
				};
			};
		};
	};
};
if (_handled) exitwith {_handled};
/* End VectorBuilding */

_handled
