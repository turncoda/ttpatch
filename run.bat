@echo off

set uedit=".\deps\uedit-v1\uedit.exe"
set pretty=".\deps\pretty-v1\pretty.exe"
set pseudopreset=".\deps\pseudopreset-v1\pseudopreset.exe"
set repak=".\deps\repak-v0.1.8-x86_64-pc-windows-msvc\repak.exe"

set player_start_tag=myStart
set original_level=Zone_Library
set mount_point=../../../pseudoregalia/Content/Mods

echo ### Reading from config.txt...
for /f "eol=# delims=" %%a in (config.txt) do set "%%a"

set output_map_name=TimeTrial_%title: =_%
set out_dir=%output_map_name%_by_%author: =_%_p

echo ### Generating output folder...
mkdir %out_dir%\Maps
mkdir %out_dir%\TimeTrial\Data
mkdir %out_dir%\PseudoMenuMod\GamePresets

echo ### Extracting level %original_level% from game pak...
%repak% unpack -o originals/ ^
-i %original_level%.umap ^
-i %original_level%.uexp ^
-s ../../../pseudoregalia/Content/Maps ^
"%game_pak_folder%\pseudoregalia-Windows.pak"

echo ### Transplanting BP_CourseController into level %original_level%...
%uedit% ^
-i originals/%original_level%.umap ^
-o int1.umap ^
--transplant-donor originals\Lab.umap ^
--actor-to-transplant 3

REM The following indices were obtained using `uedit.exe --dump` and are
REM recorded here for reference:
REM
REM 253 BP_SavePoint_C
REM 427 BP_SavePoint_C > DefaultSceneRoot
REM 356 BP_SavePoint_C > associatedPlayerStart
REM 295 BP_SavePoint_C > associatedPlayerStart > CapsuleComponent

echo ### Patching PlayerStart and SavePoint in %original_level%...
%uedit% ^
-i int1.umap ^
-o int2.umap ^
--edit-export "427.RelativeLocation.RelativeLocation=%save_point_location%" ^
--edit-export "295.RelativeLocation.RelativeLocation=%player_start_location%" ^
--edit-export "295.RelativeRotation.RelativeRotation=0,%player_start_yaw%,0" ^
--edit-export "356.PlayerStartTag=%player_start_tag%" ^
--rename-import "DT_SampleWaypointTable>DT_%output_map_name%" ^
--rename-import "/Game/Mods/TimeTrial/DT_SampleWaypointTable>/Game/Mods/TimeTrial/Data/DT_%output_map_name%"

echo ### Disabling some actors in %original_level%...
%uedit% ^
-i int2.umap ^
-o %out_dir%\Maps\%output_map_name%.umap ^
--disable-actor-by-index 253 ^
--disable-actor-by-name BP_LockDoor_C ^
--disable-actor-by-name BP_BreakableWall_C ^
--disable-actor-by-name BP_UpgradeBase_C ^
--disable-actor-by-name BP_TransitionZone_C ^
--disable-actor-by-name BP_HealthPiece_C

echo ### Cleaning up intermediate patched maps...
del int1.umap int1.uexp int2.umap int2.uexp

if %dream_breaker%==true ( set upgrades=%upgrades% --dream-breaker )
if %slide%==true ( set upgrades=%upgrades% --slide )
if %indignation%==true ( set upgrades=%upgrades% --indignation )
if %sun_greaves%==true ( set upgrades=%upgrades% --sun-greaves )
if %sunsetter%==true ( set upgrades=%upgrades% --sunsetter )
if %solar_wind%==true ( set upgrades=%upgrades% --solar-wind )
if %cling_gem%==true ( set upgrades=%upgrades% --cling-gem )
if %ascendant_light%==true ( set upgrades=%upgrades% --ascendant-light )
if %strikebreak%==true ( set upgrades=%upgrades% --strikebreak )
if %soul_cutter%==true ( set upgrades=%upgrades% --soul-cutter )
if %heliacal_power%==true ( set upgrades=%upgrades% --heliacal-power )

echo ### Generating game preset...
%pseudopreset% -o "%out_dir%\PseudoMenuMod\GamePresets\Preset_%output_map_name%" ^
--title "Time Trial: %title%" ^
--author "%author%" ^
--level %output_map_name% ^
--tag %player_start_tag% ^
%upgrades%

echo ### Generating time trial data table...
%pretty% -o "%out_dir%\TimeTrial\Data\DT_%output_map_name%.uasset" -i data.txt

echo ### Packaging...
%repak% pack -m %mount_point% %out_dir%

echo ### Moving %out_dir%.pak to game pak folder...
move %out_dir%.pak "%game_pak_folder%"

echo ### Cleaning up package staging area...
rmdir /s /q %out_dir%

echo ### Success! Verify your newly-generated pak '%out_dir%.pak' has appeared in:
echo ###  %game_pak_folder%

pause
