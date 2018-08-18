# Call of Duty: Black Ops Zombies - Reimagined
## Created by: Jbleezy / Jbird

## TODO
* Fix zombies sounds on classic maps to sound like they are coming from the correct direction
* Five: get wall barrier and metal vent barrier tear down and rebuild sounds from other maps working (zmb_rock_fix, zmb_vent_fix, zmb_break_rock_barrier, evt_vent_slat_remove)
* Try making dvars unchangeable from console
* Deadshot: add fast ADS move speed correctly
* Fix sprint and dive anims on Ray Gun
* Optimize zombies in barrier and traversing barrier code (sometimes zombies still get stuck in barrier)

### Cannot Find Fix
* Fix bug where first damage taken after being downed and getting revived or spawning back in doesnt deal damage to player (only happens when last damage taken was from player and first damage after spawn/revive is from player also, health goes down for 1 frame but then goes right back to max health next frame)
* Show player's perks when spectating
* Find a way to be able to shoot through more than 3 zombies
* Get weapons to not lose damage when going through surfaces (already have fix in gsc, try to add fix from weapon file)
* Fix textures getting changed when getting sprayed with flamethrower attachment
* Kino: fix noises in dressing room being tied to FPS (could not find in any gsc or csc)
* Fix Thompson viewmodel (part of the model doesn't show on right side of weapon, can be seen on empty reload, is not like that on base BO1 or WaW)
* Turrets: remove damage markers from players
* Turn off Der Riese easter egg song noises after they have been activated
* Moon: fix sliding sound keep playing when off object

### Might Be Fixed
* Make zombies not try to go for players on Verruckt who are on the other side of the map when the power is off
* Figure out bug that causes cosmonaut to delete himself occasionally
* Make insta kill powerups work in high rounds
* Ascension: Fix high round invisible and invincible zombies after being damaged from the centrifuge
* Fix Ascension monkey pathing
* Fix kino round skip bug
* Fix Wunderwaffe not arcing after first kill rarely
* Fix Der Riese trap lights rarely not turning red when active (can't get it to happen again, happened first time turning on trap on round 20)
* Gun Game: fix rare bug where multiple gun increment powerups spawn (might be fixed, not sure what causes it, not caused from killing multiple zombies from the same shot)
* Fix trap g_spawn error (getting hit twice and running through a trap causes g_spawn?, couldn't get it to happen)
* Shang: fix crawlers from bleeding out and not allowing extra zombies to spawn in (couldn't get it to happen)
* COTD: fix Director not doing anim when getting angry

### Cannot Do Yet
* Add fast ADS to Speed Cola (when it becomes possible through game_mod)
* Add fast grenade throw to Speed Cola (when it becomes possible through game_mod)
* Add fast sprint recovery to Deadshot (when it becomes possible through game_mod)
* Add left and right empty idle, drop, raise, sprint, and dive anims for dual wields weapons (engine currently uses only main weapon anims for these)

## GAME_MOD TODO
* Fix grenades giving more ammo than they should (made fix)
* Fix being able to buy grenades when you already have max amount (made fix)
* Fix grenade not throwing when holding fire button with a non-auto weapon (made fix)
* Add check for client dvars in server code
* Allow changing FOV to 65
* Make friends list alphabetical order
* 8 player zombies
* Options - fix performance tab issues
* Add the rest of the multiplayer perks
* Fix Connecting... issue
* Fix weapon swap on player leave
* Fix COTD outro showing on all maps after loading COTD in a session
* Get actionslot 2 highlighting to work
* Fix demigod
* Make online version of the scoreboard show in solo
* Get brightness to work without having to be in fullscreen
* Add LAN
* Make dual wield weapons use attack bind for left weapon and ADS bind for right weapon
* Allow changing timescale from GetTimeScale() function when sv_cheats dvar is set to 0
* Add GetMoveSpeedScale() function
* Add ActionSlotOneButtonPressed() function
* Fix ActionSlotTwoButtonPressed() function
* Add ActionSlotThreeButtonPressed() function
* Add ActionSlotFourButtonPressed() function
* Add WeaponSwitchButtonPressed() function
* Add WeaponReloadEndTime() function
* Add IsReloading() function
* Fix ChangeLevel() causing weapon index mismatch error
* Add specialty_fastads perk
* Add specialty_fastinteract perk
* Add specialty_sprintrecovery perk
* Add specialty_stalker perk (fast movement while ads)
* Add perk for faster movement while ads
* Make ADS rechamber anim speed relative to rechamber time in weapon file (currently only non-ADS rechamber anim speed is changed)
* Fix being able to throw another grenade at the of another grenades anim
* Allow fire button to be used to melee with melee weapons
* Fix alive players movement being stopped when other players spawn in (caused from .sessionstate change)
* Fix projectiles not spawning occasionally when shooting weapons
* Make it so shooting the last bullet of a rechamber weapon will rechamber the bullet before auto switching
* Find out how to send something from client to server
* Dual wield weapon fire input - add dvar "gpad_enabled" check that works for all players
* Make dual wield weapons fire left weapon with fire button and right right weapon with ads button
* Death Machine: don't allow spin up by pressing ADS
* Death Machine: check if Stamin-Up increases move speed with Death Machine
* 007EF7D0 - iprintln address (try it out)
* Allow melee while ADS with a sniper scope
* Add space between grenades on HUD (CG_OFFHAND_WEAPON_ICON_FRAG - 103 and CG_OFFHAND_WEAPON_ICON_SMOKEFLASH - 104)
* Make it so you can queue another shot on non-auto weapons by pressing the fire button during the fire time of the current shot (similar to BO3)
* Fix freeze on map load on Ascension
* Fix player names getting changed to "Unknown Soldier" on scoreboard and chat after fast_restart if name is too short
* Make it so perks that are not engine based only use 1 bit
* Make it so players can look up and down 90 degrees (currently at 85)
* Allow multiple pap camos to be used from weaponOptions.csv (currently only looks for the keyword "gold")
* Don't allow reload to start during fire time or last fire time
* Always use empty drop/raise anim if empty (currently quick drop/raise anim will play even when empty)
* Make all dual wield anims work separately for each weapon (currently empty idle, raise, drop, sprint, and dive anims are not separate)
* Fix being able to cancel melee animation by switching weapons with a weapon that has an empty clip
* Use Sleepy when game crashes on map load