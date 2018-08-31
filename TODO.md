# Call of Duty: Black Ops Zombies - Reimagined

## Created by: Jbleezy / Jbird

## TODO

## Might Need Todo
* Make zombies not try to go for players on Verruckt who are on the other side of the map when the power is off
* Figure out bug that causes cosmonaut to delete himself occasionally
* Ascension: Fix high round invisible and invincible zombies after being damaged from the centrifuge
* Fix Ascension monkey pathing
* Fix kino round skip bug
* Fix trap g_spawn error (getting hit twice and running through a trap causes g_spawn?, couldn't get it to happen)
* Shang: fix crawlers from bleeding out and not allowing extra zombies to spawn in (couldn't get it to happen)
* COTD: fix Director not doing anim when getting angry
* Der Riese: fix Warehouse trap light being yellow while active sometimes (might be fixed, now uses Spawn() instead of network_safe_spawn())
* Fix issue where zombies have no anim (possibly somehow caused from the added anims or old barrier code?)

## Cannot Do
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
* Ray Gun: fix sprint and dive anims to match BO1 idle anim position
* Make dvars unchangeable from console
* Five: get wall barrier and metal vent barrier tear down and rebuild sounds from other maps working - zmb_rock_fix, zmb_vent_fix, zmb_break_rock_barrier, evt_vent_slat_remove (cannot find the sounds)
* Add fast ADS to Speed Cola (when it becomes possible through game_mod)
* Add fast grenade throw to Speed Cola (when it becomes possible through game_mod)
* Add fast sprint recovery to Deadshot (when it becomes possible through game_mod)
* Add fast ADS move speed to Deadshot (when it becomes possible through game_mod)
* Add left and right empty idle, drop, raise, sprint, and dive anims for dual wields weapons (when it becomes possible through game_mod, engine currently uses only main weapon anims for these)