# Call of Duty: Black Ops Zombies - Reimagined
## Created by: Jbleezy / Jbird

[YouTube](https://youtube.com/ItsJbirdJustin)

[Twitch](https://twitch.tv/jbleezy)

[Twitter](https://twitter.com/jbird_justin)

[Donate](https://www.paypal.me/Jbleezy/10)

## Change Notes

## General
* Zombies now only have an additonal spawn delay when a full horde is spawned in
* Additional spawn delay time reduced from 1.2 seconds to 1 second
* 1 second of immunity to zombies after getting revived (solo and coop)
* Insta kill rounds (Rounds where zombies have round 1 health) start at round 163 and happen every odd round thereafter
* All players are attracted equally
* Fixed a bug where zombies would not attack players if one player crouched in front of another player in a corner
* Dead players can chat with alive players
* Backwards move speed, strafe move speed, and sprint strafe move speed are now all at 100%
* Removed friendly fire (not being able to shoot when looking at another player)
* Player names now disappear instantly after being out of line of sight of them
* Added 100 millisecond delay between weapon swaps
* Removed knife lunging
* Fixed a bug where a player was able to revive another player by bleeding out next to them in water
* Fixed a bug where players were able to damage themselves by meleeing and leaning at the same time
* Fixed a bug where downed players were able to occasionally damage alive players
* Pack-a-Punch camo now displays on Mustang & Sally when downed in solo
* Chracters no longer make hurt sounds if you have Flopper and an explosion happens that would have hurt you
* Too many weapons penalty has been changed to only take the weapon that the player shouldnt have
* If a player switches weapons while reviving, their weapon will not get switched when finishing a revive
* Players can now dolphin dive again right away after just dolphin diving
* Players can now move after dolphin diving quicker
* Dolphin dive startup time decreased
* Any hintstring that previously showed "Press & hold" or "Press" at the beginning has been changed to only show "Hold"
* Power hintstrings on classic maps have been changed to show the same hintstring on non classic maps
* Hintstrings are now invisible while the current action is not available for the player
* Intermission time decreased from 15 seconds to 10 seconds
* Maps now auto restart in coop after intermission
* Maps now auto restart correctly (box gets randomized again)
* Fixed a bug where players were able to freeze in mid air with no weapon in hand if they held the fire button while spawning in
* Round now ends immediately when last zombie is killed (previously up to a one second delay)
* Players can now red screen after bleeding out and respawning
* Red screens now start at 25% health (previously 20% health)
* Reduced self explosive damage from 75 to 70

## HUD
* HUD items now have some distance away from the edge of the screen
* Damage marker time set to 3 seconds
* Zombie counter displayed on the top left of the HUD
* Game time displayed on the top right of the HUD
* Round time displayed on the top right of the HUD
* Game time and round time displayed at the end of each round on the top center of the HUD
* Sidequest completion time displayed on top center of the HUD
* Character names displayed next to player's points on the HUD
* Current zone displayed above round number on the HUD
* Ammo display on HUD no longer fades away
* Grenades on HUD are now more spread out
* Removed Reload, No Ammo, and Low Ammo HUD messages
* Removed bloodsplat on D-pad
* Fixed attachments on D-pad being highlighted incorrectly
* Score highlights now only show one positive amount and one negative amount per player at a time
* Negative score color is now slightly brighter
* Yellow insta kill shows on HUD during insta kill rounds
* Removed blur when paused ingame

## Settings
* Removed popup menu when changing graphic content to unrestricted
* Combat settings: removed Sprint/Hold Breath option and Steady Sniper option (sniper scopes are always steady now)
* Combat settings: added Previous Weapon option
* Combat settings: changed name of "USE EQUIPMENT" to "EQUIPMENT"
* Combat settings: changed name of "GROUND SUPPORT" to "PLACEABLE MINE"
* Option to change FOV (65-120 in intervals of 5)
* Option to show FPS on HUD
* Option to change max FPS
* Option to disable fog
* Option to add weapon cycle delay
* Option to disable character dialog (host only)
* Option to disable Mule Kick (host only, always disabled on Nacht, always enabled on Moon)
* Options to disable timer, zombie counter, zone names, and character names
* Option to choose which room you start in on Verruckt (host only)
* Option to choose which perk you start with on No Man's Land (host only)
* Options to set which barriers in Five spawn room you want disabled (host only)
* Option to choose the initial box location on maps that have a random initial box location (host only)
* Option to choose which gamemode you want to play, including random which includes every gamemode except Survival
* Option for random map rotation on versus gamemodes, automatically loads new map after intermission screen

## Weapons
* All bullet damage (except for shotguns) will now deal full damage through multiple enemies or thin walls
* All body shots now deal the same amount of damage
* Neck shots, head shots, and helmet shots now all deal the same amount of damage
* All body shots will now give 50 points for a kill
* Neck shots now give 100 points for a kill
* Melee kills can no longer count as headshots

### New Weapons
#### Combat Knife
* Wield your current knife by pressing the new melee weapon keybind (found in combat settings)
* If you have no other weapon, you will hold your knife by default
* 110% movement speed

#### Molotovs
* Added in classic maps
* Deal infinite damage on impact

#### Springfield
* Added in Verruckt on the wall in replace of the Kar98k wallbuy on the Quick Revive side

#### AK47
* Upgraded name: The Red Mist
* Upgraded version has flamethrower attachment
* 30 rounds per clip unupgraded and upgraded
* Unupgraded: damage - 150
* Unupgraded: headshot damage - 600
* Unupgraded: damage - 210
* Unupgraded: headshot damage - 1050

#### PPSH
* Upgraded name: The Reaper
* 71 rounds per clip unupgraded and upgraded
* Unupgraded: damage - 100
* Unupgraded: headshot damage - 400
* Unupgraded: damage - 140
* Unupgraded: headshot damage - 700

#### PSG1
* Upgraded name: Psychotic Salient Genius 115
* Replaces the Dragunov
* 10 rounds per clip unupgraded and upgraded
* Unupgraded: damage - 500
* Unupgraded: headshot damage - 2500
* Unupgraded: damage - 1000
* Unupgraded: headshot damage - 8000

#### Stoner63
* Upgraded name: Stoned69
* Assault rifle/LMG hybrid weapon
* 90% movement speed (in between LMG and assault rifle movement speed)
* Unupgraded: 60 rounds per clip
* Upgraded: 90 rounds per clip
* Unupgraded: damage - 160
* Unupgraded: headshot damage - 480
* Unupgraded: damage - 230
* Unupgraded: headshot damage - 690

### Explosive weapons
* Removed shellshock effect from all explosive weapon damage
* Removed damage scaling over rounds (except for lethal grenades and mines)

### Snipers
* Removed idle sway while aiming
* Increased FOV when aiming from 15 to 30
* Variable zoom scopes now only have one scope option

### Shotguns
* Reduced spread when aiming

### AK74u
* Upgraded: fixed fire sound

### AUG
* Upgraded: added name of weapon attachment on HUD

### Ballistic Knife
* Knives pick up automatically when close to them
* Fixed a bug where a knife could be picked up if the player had max reserve ammo
* Instantly starts reloading after firing the knife
* Obtaining the Bowie Knife or Sickle no longer gives you more ammo
* Fixed a bug where a knife could not be picked up if another knife is fired after the first knife and lands before the first knife
* No longer gibs zombies on impact
* Knife now glows as soon as it is attached to a zombie
* Knife no longer attaches to a zombie if the knife kills the zombie
* Unupgraded: increased impact damage from 450 to 500 (weapon file shows it is suppose to do this amount of damage but it does not)
* Upgraded: increased impact damage from 900 to 1000 (weapon file shows it is suppose to do this amount of damage but it does not)
* Upgraded: ammo now gets added at the same time that it does in the reload animation

### BAR
* Replaced BAR + Bipod with BAR
* Removed bipod from weapon model
* All BAR wallbuys now cost 1800
* Increased headshot damage from 270 to 400
* Ammo now gets added at the same time that it does in the reload animation

### China Lake
* Can now fire without aiming
* Now rechambers while aiming
* Decreased time to start rechambering after firing from .4 seconds to .2 seconds
* Unupgraded: decreased rechamber time from 2 seconds to 1 second
* Upgraded: decreased rechamber time from 1.4 seconds to .7 seconds
* Instantly starts reloading after firing the last shot
* Unupgraded: impact damage - 1250
* Unupgraded: maximum explosion damage - 1000
* Unupgraded: minimum explosion damage - 500
* Upgraded: impact damage - 2500
* Upgraded: maximum explosion damage - 2000
* Upgraded: minimum explosion damage - 1000

### Crossbow
* Instantly starts reloading after firing the bolt
* Crossbow bolt beeping rate no longer changes depending on your FPS
* No longer gibs zombies on impact
* Unupgraded: increased impact damage from 675 to 750 (weapon file shows it is suppose to do this amount of damage but it does not)
* Unupgraded: maximum explosion damage - 800
* Unupgraded: minimum explosion damage - 400
* Upgraded: increased impact damage from 675 to 2250 (weapon file shows it is suppose to do this amount of damage but it does not)
* Upgraded: increased headshot impact damage from 3000 to 9000
* Upgraded: maximum explosion damage - 2500
* Upgraded: minimum explosion damage - 1250
* Upgraded: zombies now get attracted immediately

### CZ75 Dual Wield
* Reduced recoil
* Unupgraded: increased reserve ammo from 228 to 240

### Double-Barreled Shotgun
* Spread increases while moving
* Fixed animations
* Ammo now gets added at the same time that it does in the reload animation
* Fixed shell eject effect showing 2 shells
* Upgraded: changed name from "24 Bore long range" to "24 Bore"
* Upgraded: removed additional headshot damage

### Dragunov
* Removed (replaced by PSG1)

### Famas
* Unupgraded: increased reserve ammo from 150 to 300
* Upgraded: increased reserve ammo from 225 to 450

### FG42
* Ammo now gets added at the same time that it does in the reload animation when reloading with an empty clip
* Upgraded: decreased reserve ammo from 400 to 384

### G11
* Unupgraded: increased reserve ammo from 144 to 192
* Upgraded: increased reserve ammo from 288 to 384

### Gewehr 43
* Ammo now gets added at the same time that it does in the reload animation
* Unupgraded: increased damage from 120 to 130
* Upgraded: decreased reserve ammo from 170 to 168

### HS10
* Upgraded: fixed right weapon fire sound
* Upgraded: reduced hipfire spread
* Upgraded: reduced recoil

### Kar98k
* Unupgraded: increased damage from 170 to 500
* Unupgraded: increased headshot damage from 350 to 1000
* Upgraded: 50 round clip, no reserve ammo
* Upgraded: increased damage from 1200 to 3000
* Upgraded: increased headshot damage from 2000 to 6000

### Kar98k Scoped
* Added rechamber sound
* Increased damage from 675 to 1000
* Increased headshot damage from 3000 to 4000

### L96A1
* Unupgraded: added variable zoom scope
* Unupgraded: damage - 1000 (previously 500-750 damage depending on where the damage was dealt)
* Unupgraded: headshot damage - 5000 (previously 1500-5000 damage depending on where the damage was dealt)
* Upgraded: damage - 2000 (previously 1000-3000 damage depending on where the damage was dealt)
* Upgraded: headshot damage - 16000 (previously 8000-10000 damage depending on where the damage was dealt)

### M1 Carbine
* Ammo now gets added at the same time that it does in the reload animation

### M1 Garand
* Added sound that plays when first obtaining
* Ammo now gets added at the same time that it does in the reload animation when reloading with an empty clip
* Fixed raise animation
* Decreased raise time from .8 seconds to .6 seconds

### M16
* Unupgraded: increased reserve ammo from 120 to 150
* Upgraded: decreased grenade launcher explosion radius by 36%
* Upgraded: grenade launcher impact damage - 1500
* Upgraded: grenade launcher maximum damage - 1500
* Upgraded: grenade launcher instantly starts reloading after firing the last shot
* Upgraded: added name of weapon attachment on HUD
* Upgraded: ammo for weapon attachment now shows on HUD

### M1911
* Upgraded: impact damage - 2500
* Upgraded: maximum explosion damage - 2500
* Upgraded: minimum explosion damage - 1000

### M72 LAW
* Can now fire without aiming
* Fixed dive to prone animation from looping
* Instantly starts reloading after firing the last shot
* Unupgraded: impact damage - 2000
* Unupgraded: maximum explosion damage - 1500
* Unupgraded: minimum explosion damage - 1000
* Upgraded: impact damage - 3000
* Upgraded: maximum explosion damage - 2500
* Upgraded: minimum explosion damage - 1000

### MP40
* Fixed sprinting animation not playing correctly when clip is empty
* Now uses WaW camo on Der Riese

### Olympia
* Now adds 1 ammo during the reload if reloaded with no ammo
* Unupgraded: max damage per pellet increased from 120 to 180
* Upgraded: max damage per pellet increased from 200 to 300
* Upgraded: fire effect now plays when damaging a zombie
* Upgraded: ammo now gets added at the same time that it does in the reload animation

### PM63
* Unupgraded: increased reserve ammo from 100 to 120
* Upgraded: increased reserve ammo from 225 to 250
* Upgraded: reduced hipfire spread
* Upgraded: reduced recoil

### RPK
* Fixed animation bug when switching weapons from the RPK with an empty clip
* Fixed dive to prone animation from looping

### Sawed-Off Double-Barreled Shotgun
* Decreased range by 25%
* Increased spread by 25%
* Decreased recoil by 33%
* Decreased reload time from 3 seconds to 2.5 seconds
* Spread increases while moving
* Fixed animations
* Ammo now gets added at the same time that it does in the reload animation
* Fixed shell eject effect showing 2 shells
* Changed name from "Sawed-Off Double-Barreled Shotgun w/ Grip" to "Sawed-Off Double-Barreled Shotgun"
* Changed buy hintstring from "Sawed-Off Shotgun" to "Sawed-Off Double-Barreled Shotgun"

### Spectre
* Unupgraded: increased reserve ammo from 120 to 240
* Upgraded: increased reserve ammo from 225 to 360

### STG-44
* Upgraded: changed name from "Spatz-447 +" to "Spatz-447"

### Thompson
* Ammo now gets added at the same time that it does in the reload animation when reloading with an empty clip
* Upgraded: decreased reserve ammo from 250 to 240

### Trench Gun
* Spread increases while moving
* Ammo now gets added at the same time that it does in the reload animation
* Fixed shell eject effect showing 2 shells

### Type 100
* Ammo now gets added at the same time that it does in the reload animation
* Unupgraded: increased reserve ammo from 160 to 180
* Upgraded: increased reserve ammo from 220 to 240

### Wonder Weapons

### Ray Gun
* Ammo now gets added at the same time that it does in the reload animation
* Removed weapon bob from movement
* Added sprint and dive animations from BO2
* Added sound from BO2 that plays when first obtaining
* Added sound from BO2 that plays when attempting to fire without any ammo
* Decreased first raise time from 2.4 seconds to 1.8 seconds
* Fixed first raise animation lasting too long at the end
* Unupgraded: impact damage - 2500
* Unupgraded: maximum explosion damage - 2500
* Unupgraded: minimum explosion damage - 1250
* Upgraded: impact damage - 3000
* Upgraded: maximum explosion damage - 3000
* Upgraded: minimum explosion damage - 1250

#### Wunderwaffe
* Can now down yourself with Wunderwaffe damage (previously could only take you down to 1 health but not down you)
* The initial zombie that is hit will now always be the zombie that is closest to the bolt's location
* Unupgraded: decreased self damage radius by 72%
* Unupgraded: increased zombie damage radius by 45%
* Upgraded: decreased self damage radius by 134%
* Upgraded: increased zombie damage radius by 7%
* Unupgraded and upgraded versions now have the same zombie damage radius and self damage radius
* Upgraded: increased maximum amount of kills from 10 to 24
* Upgraded: decreased time between kills by 50%
* Upgraded: ammo now gets added at the same time that it does in the reload animation
* Upgraded: gold camo on Der Riese, regular camo on Call of the Dead
* Upgraded: gold camo is now shinier
* Added sprint and dive animations on classic maps
* Bulbs now light up correctly after reload cancelling

#### Thundergun
* Gives 50 points for each kill
* No longer does any damage to any enemies that are knocked down and not killed
* Decreased time to start reloading after firing the last shot

#### Winter's Howl
* Unupgraded: minimum damage - 500
* Upgraded: minimum damage - 1000
* Unupgraded: damage to thief - 1000
* Upgraded: damage to thief - 2000
* Each shot slows down the enemy's move speed
* Kills enemies when they are at their slowest move speed (3 shots to kill sprinting enemies)
* Enemies will only be able to do slow hits after taking damage from the Winter's Howl
* Enemies that have been damaged by the Winter's Howl will bleed out after 30 seconds (does not count as a kill)
* Enemies that die from the Winter's Howl will now crumple away faster after being frozen
* Upgraded camo now displays on more of the weapon
* Ammo now gets added at the same time that it does in the reload animation
* Decreased first raise time by 50%
* Fixed an error in the sprint out animation

#### Scavenger
* Infinite damage
* Gives points when dealing impact damage
* ADS disabled while reloading

#### V-R11
* Human zombies now target the closest zombie to them
* Director is no longer attracted towards the human zombie
* Zombies die when they get close to a human zombie
* Human zombie lasts for 10 seconds unupgraded, 15 seconds upgraded
* Upgraded: the human zombie explodes when it dies
* Upgraded: removed explosion effect from shooting the same human zombie multiple times
* Shooting the Director while he is calm no longer makes him angry
* Unupgraded: permamently makes the Director calm when shot at him
* Owner of V-R11 gets 50% of any points that the player who they shot earns for its duration (previously 75%)

#### Baby Gun
* Fixed a bug that caused an error to happen when shrinking enemies and allowing them to regrow many times throughout a game

#### Wave Gun
* Gives 50 points for each kill

### Equipment
* Limit of 120 mines placed on the map at once (each player can place equal amount of mines in coop)
* Grenades now cannot be thrown faster than intended when throwing a grenade right after after throwing one
* Lethal grenades: impact damage - 30
* Fixed a bug where tactical grenades wouldn't work if they were thrown before a previously thrown tactical grenade had activated
* Tactical grenades now always stay upright
* Mines can now be picked up while pressing the melee button

#### Bouncing Betty
* Increased placing speed
* Can now explode after being placed for 1 second (previously 2 seconds)
* Can now be picked up
* No longer keeps moving and making sounds after being placed
* First raise time is now the same as regular raise time

#### Claymore
* Added placing sound
* Added activation sound
* Can no longer be picked up after being triggered
* First raise animation is now the same as regular raise animation
* First raise time is now the same as regular raise time

### Frag Grenade
* Changed upwards projectile speed

#### Gersch Device
* Zombies now get attracted immediately
* Fixed a bug where zombies would attempt to get sucked into a Gersch Device shortly after it had already disappeared

#### Hacker
* Every player can have the hacker
* Does not move locations when picked up
* Can now only hack one item at a time
* Melee disabled during hack
* Pressing the lethal grenade button or ADS button will no longer restart a hack
* Removed points reward given between rounds
* Hacking a Max Ammo gives a Perk Bottle
* Hacking a powerup will reset its timer
* Hacking a Death Machine will now make the Max Ammo glow its correct color
* Powerup hack trigger radius increased by 30%
* Cost to hack wall weapons increased from 3000 points to 5000 points
* Can now unhack wall weapons (costs the same amount to unhack them)
* Buying a hacked wallbuy will give you the upgraded version of that weapon
* Unupgraded and upgraded ammo both cost the price of unupgraded ammo when hacked
* Wallbuy hintstring now updates when hacked to reflect their current prices
* Doors are free to hack
* Time to hack doors decreased from 32.7 seconds to 15 seconds
* Time to hack players decreased from 10 seconds to 1.5 seconds
* Hacking the box twice no longer gives you 950 points
* Hacking a teddy bear location will now only lock that box for the remainder of the current round
* Fire sale box can spawn at locations where the box has been hacked

#### Matroyshka Dolls
* Deal infinite damage (except for the Director)
* Damage increased from 4500 to 9000 on the Director

#### Monkey Bombs
* Zombies now get attracted immediately
* Zombies will now taunt when near a Monkey Bomb
* Will not activate if thrown outside the map
* Removed on Nacht, Verruckt, and Shi No Numa

#### P.E.S.
* Added BO3 model and animations
* Players now only lose their helmet when taking different equipment
* Fixed a bug where players were able to get no weapon in their hand by pressing the P.E.S. helmet button repeatedly
* Changed name from "P.E.S" to "P.E.S."
* D-pad now stays highlighted while putting on and taking off the P.E.S. helmet

#### Semtex
* Now always cost 250 points to buy (previously costed 130 points after first buy)
* Semtex beeping rate no longer changes depending on your FPS
* Changed upwards projectile speed

#### Sickle
* Now uses model from BO3

#### Spikemore
* Added activation sound
* Can no longer be picked up after being triggered
* First raise animation is now the same as regular raise animation
* First raise time is now the same as regular raise time

#### Stielhandgranate
* Now deals damage on impact
* Added projectile trail effect
* Added throw back animation

#### QED
* 100% chance of fling effect when thrown near Cosmonaut or zombie
* 100% chance of reviving player when thrown near downed player
* 100% chance of giving perk when thrown near a perk machine that is powered on
* 100% chance of opening a door when thrown near a door
* 100% chance of upgrading player's weapon when thrown near Pack-a-Punch machine
* 100% chance of hacking an exacavtor when thrown near the panel
* 100% chance of random powerup when throw near a powerup
* Guaranteed results order: fling effect (if near Cosmonaut), revive players, give nearest perk, open nearest door, upgrade weapon, stop excavator, random powerup, fling effect (if near any zombie)
* If thrown outside the map, the player who threw the QED gets teleported to a random location on the map
* Free perk effect now only gives the perk to the player who threw the QED
* Revive player effect now only revives players near where the QED was thrown
* Random weapon powerup now gives player max ammo on a weapon if they already have the weapon
* Starburst weapons no longer damage players
* Removed red powerup effect
* Removed unupgrade weapon effect
* All other effects and random powerup effect have a chance of spawning when none of the forced effects are activated

## Wallbuys
* Upgraded ammo cost reduced from 4500 points to 2500 points
* Can now purchase ammo if reserve ammo is full but clip ammo is not full
* Can now purchase ammo for weapons with attachments if only the attachment ammo is not full
* Can now purchase ammo for dual wield weapons if only the left weapon clip is not full
* Purchasing ammo for dual wield weapons will no longer fully fill the stock ammo if either of the clips are not full
* Multiple players can now buy the Bowie Knife or Sickle at the same time
* Claymores, Bouncing Betties, and Spikemores now all require the player to be looking at the wallbuy to be able to buy them
* Sniper cabinet: weapon ammo now costs exactly 25% the cost of the weapon

## Mystery Box
* Decreased time between uses from 3 seconds to 1.5 seconds
* Decreased weapon pickup time from 12 seconds to 9 seconds
* Flies up twice as high when moving
* Now plays an animation when spawning in (except for Fire Sale Mystery Boxes)
* Instantly appears at its new location when moving instead of waiting 8 seconds
* Wall weapons are in the Mystery Box on classic maps
* Every player now sees the same weapons in the box when the weapons are floating up
* Can only see weapons floating up that the player can currently obtain
* Players will now get every weapon they can from the box before getting duplicates
* If a player does not grab a weapon from the box, then it will be put back into the list of weapons the player can get
* All weapons have the same probability to be obtained
* Ray Gun can now be obtained without moving the Mystery Box on all maps
* Weapons will not appear again in a row while floating up (unless it is the final weapon)
* Cycles through all locations before going to a previous location again
* Hintstring now says "Mystery Box" instead of "Random Weapon"
* Added a separate hintstring for tactical grenades
* Removed sound that plays when obtaining the Ray Gun
* Added sound that plays when obtaining the wonder weapon of the map
* Fixed a bug that would cause there to sometimes be no Mystery Box or multiple Mystery Boxes if a Fire Sale was activated right after the Mystery Box started to move
* Fixed a bug where the Mystery Box weapon would fly away if the Mystery Box was activated as a Fire Sale was ending and the Fire Sale was grabbed as the box was starting to move
* Fixed a bug where weapons would be cycled through faster on higher FPS
* Fixed a bug where the teddy bear would spawn in facing the wrong direction
* Ascension: teddy bear now has sickle
* Moon: teddy bear now has space helmet

## Perks
* Perks now become active as soon as the player starts to put away the perk bottle
* Added gloss to all perk bottles
* Multiple players can now buy the same perk at the same time
* Perks now fade in on the HUD when obtained
* Removed blur effect that previously happened after buying a perk
* Perk order will no longer be changed when losing a perk
* All perk machines on all maps now make a sound when bumping into them

### Quick Revive
* Hintstring now says "Quick Revive" in solo and coop
* Losing Quick Revive in solo from ways other than downing no longer counts as a use of Quick Revive
* Fixed a bug where the Quick Revive perk machine sounds would still play after the machine is gone in solo

### Speed Cola
* Switch weapons twice as fast
* No longer increases board repair speed
* No longer decreases Hacker hack time

### Double Tap
* 1.5x bullet damage (stacks with Deadshot)
* Time between burst fire shots reduced by 25%

### Deadshot
* Increased cost from 1000 to 1500
* 2x headshot damage (stacks with Double Tap)

### Mule Kick
* Removed from Nacht Der Untoten
* Added jingle
* Third weapon slot will now always be the correct weapon
* Name of weapon that will be lost when downed is shown in yellow text
* Lost weapon is given back when perk is rebought (except if it was a limited weapon and someone else has it now, the player already has the weapon, the player has the upgraded version of the weapon and the weapon that the player had lost is the unupgraded version of that weapon, or the player bled out)
* Gives ammo back if the player already has the weapon that they had previously lost when perk is rebought

## Powerups
* Powerups allign on the center of the HUD
* Powerups on HUD now fade in and out when they are about to end instead of blinking
* Powerups on the ground now last for 30 seconds (previously 26.5 seconds)
* An effect now plays when a powerup spawns if it is the last powerup of a powerup cycle
* Grabbing a powerup that is already active will add to its current remaining time instead of resetting its remaining time
* Powerups will now not be grabbed automatically if spawned near where a player died at
* Powerups that are not initally active are now guaranteed to be added to your current powerup cycle when they become active
* Only normal powerup drops now effect the powerup cycle

### Carpenter
* Removed

### Death Machine
* Switch weapons to end duration
* Deals at least 1/4 of zombie's health per body shot
* Deals at least 1/2 of zombie's health per headshot
* Decreased weapon raise time from 1.55 seconds to 1.1 seconds
* Decreased weapon drop time from .75 seconds to .3 seconds
* Powerup can now drop while one is already active

### Fire Sale
* Powerup can now drop while one is already active

### Nuke
* Now obtainable on round 1 on all maps
* Kills all zombies instantly
* Enemies killed by a Nuke no longer drop powerups
* Zombies killed from a Nuke count as kills for the player who grabbed the Nuke

### Wunderwaffe (Powerup)
* Powerup model now shows Wunderwaffe weapon model
* Switch weapons to end powerup duration
* Powerup can now drop while one is already active

## Traps
* All trap kills now count as kills for the player who activated the trap
* All traps now kill instantly
* Fixed trap handles being moved to the wrong spot and trap lights staying green if a trap was activated while the trap handle was still moving up
* All trap triggers now display active and cooldown hintstrings
* All traps now take players' points as soon as the trigger is activated
* Fixed traps showing damage fx when player is spectating if the player bled out in a trap and the trap is active

### Electric Traps (All Maps)
* Stun duration reduced from 2.5 seconds to 1.5 seconds (now matches the duration of the electricity being on screen)
* Only the trap handle that was activated now moves down

### Electric Traps (Shi No Numa)
* Cooldown time reduced from 90 seconds to 25 seconds (same as Verruckt and Der Riese)

### Flogger (Shi No Numa)
* Both triggers are now completely independent of eachother
* One trigger can not be activated if the other trigger is currently active
* Lights and hintstrings now display correctly when activating one trigger while the other trigger is on cooldown
* Now deals 50 damage to players (in solo and coop)
* Cannot damage a player again if the player is still touching the flogger and has already been damaged by the flogger

### Zipline (Sho No Numa)
* Cost decreased from 1500 to 750
* Cooldown time decreased from 40 seconds to 5 seconds
* Hintstrings now display when the zipline is active and cooling down
* The zipline trigger near the hut can now be activated when the zipline is on either side

### Electric Traps (Der Riese)
* Fixed a bug that caused the Trench Gun trap to turn on when opening the door to the teleporter room next to the Trench Gun room while still having the door for next tot the trap closed
* Traps now display a hintstring when the power is on but the trap cannot be activated due to a door being closed

### Teleporters (Der Riese)
* Teleporters now kill zombies on any round
* Guranteed teleporter powerup when first linking teleporter
* Powerup spawned from teleporters stays on the map until picked up or after teleporting again
* Amount of dogs spawned in from teleporter is now 2 multiplied by the amount of players (previously 4)
* Max ammo now has the same chance of spawning from the teleporter as all other drops
* Fixed a bug that allowed players to link teleporters while the teleporters were on cooldown
* Mainframe no longer displays a hintstring for needing power or needing to activate a link

### Turrets (Kino Der Toten and Ascension)
* No longer deal damage to players
* Kills zombies in one shot
* Turrets now lockon to a new target quicker
* Turrets now target the zombie that is closest to the turret

### Lunar Lander (Ascension)
* Added a short delay for the lander to activate after triggering it (so you can activate the lander without having to ride it)
* Lander station no longer kills or moves players if the lander station moves down while the player is standing on it
* Kills from the lunar lander now count as actual kills
* Zombies now have a better death animation when killed by the lunar lander

### Centrifuge (Ascension)
* Cooldown time has been doubled
* No longer stops spinning for entire rounds
* Deals 50 damage to players in solo and coop
* Fixed a bug where zombies that were killed from the Centrifuge in higher round became invisible and invincible
* The player that is closest to a zombie that is killed from the Centrifuge gets the kill

### Flinger (Call of the Dead)
* Zombies flung now count as actual kills

### Zipline (Call of the Dead)
* FOV no longer changes while riding the zipline
* Weapon is no longer out while riding the zipline

### Spikes (Shangri-La)
* Deal 50 damage to players
* 50% change of Killing a zombie
* Spikes will not activate if the player is down or if the player jumping over them

### Waterfall (Shangri-La)
* Now kills zombies (except for Shrieker and Napalm)
* Displays a hintstring when active

### Minecart (Shangri-La)
* Kills from the minecart now count as actual kills
* Travels back up 4x faster

## Blockers
### Doors
* Doors now push any players out that are touching them after they have fully opened
* Fixed a bug where two or more players could trigger a door that has multiple triggers at the same time and both pay to open the door

## Barriers
* No longer have to hold the use button in order to rebuild barriers, only press it
* Can no longer rebuild barriers while sprinting or diving
* Fixed a bug where zombies would get stuck in a barrier if a board was repaired as the zombie was beginning to go over the barrier
* All zombies behind a barrier will now taunt correctly
* Zombies behind a barrier will now only attack if they can see a player
* Zombies will no longer get stuck behind a barrier when there are many zombies behind one barrier
* All wall barriers and metal vent barriers can now be rebuilt
* Glass barriers now start off with glass and wooden boards
* On glass barriers, zombies will now tear down all of the glass first
* Zombies can now attack through all glass barriers, wall barriers, and metal barriers
* Fixed a bug where glass barriers and wall barriers had to be rebuilt twice for the repair to take effect if the barrier was rebuilt right after it got destroyed
* Fixed a bug where glass barriers and wall barriers were destroyed at slightly incorrect times
* Zombies now always use the same animation when tearing down glass barriers
* Zombies now randomly choose between two animations when tearing down wall barriers

## Zombies
* Removed collision from zombies as soon as they are dead
* Fixed a bug where zombies would bleed out occasionally if they were standing in the same spot they were 30 seconds ago
* For zombies to not bleed out, a player must now have line of sight to the zombie in addition to looking at the zombie
* Zombies will now not bleed out if they are in an active zone in addition to being close to a player
* Zombies that bleed out from being too far away will now be killed instead of deleted
* Zombies can no longer be alive and headless
* 4 round and 5 round special rounds will happen more equally now
* Max health: 1 million
* Fixed a bug that caused ceiling spawns to be able to be disabled
* Fixed a bug that caused spawning zombies to be able to collide with players while they were still invisible to the player
* Zombies can now gib when damaged from the Bowie Knife or Sickle
* Fixed certain zombie swipes that damaged players at incorrect times
* Ceiling spawner zombies now fall from the ceiling quicker

### Dogs
* No longer gain additional points for kills from dogs when killing dogs with wonder weapons
* Fixed a bug that caused spawning dogs to be able to collide with players while they were still invisible to the player

### Nova Crawlers
* The player who kills a Nova Crawler gets the kills for any zombies killed from the explosion of the Nova Crawler
* Now award kill points immediately if killed while crawling on a wall

### Thief
* Max health: 30,000
* Health does not change depending on how many payers are in the match
* No longer effected by insta kills or nukes

### Monkeys (Ascension)
* Max health decreased to 1600
* Fixed a bug where perks would be lost on monkey rounds when they shouldn't be
* No longer stop attacking perks when damaged by a player
* Perks now flash red on the HUD when monkeys are dealing extra damage to perks (which happens when a player enters the zone that a monkey is attacking a perk in)

### Director
* Always drops Wunderwaffe regardless of whether or not you have completed the sidequest
* Upgraded assault rifles no longer deal extra damage to the Director
* Max health is now 250,000 no matter how many players are in the match
* Only slows down players close to him when shot at while calm
* Fixed a bug that caused the Director to not be able to electrify a player anymore after the player knifed an electrified zombie during an insta kill
* No longer plays audio after exiting the map due to being hit by the upgraded V-R11
* Fixed a bug that would sometimes cause the Director to sream in the water after already being killed
* No longer screams in the water if damaged while attacking
* Power no longer needs to be on for an electrified zombie to drop a Max Ammo

### Monkeys (Shangri-La)
* Keep attempting to spawn until they successfully spawn during the whole duration while a powerup is active on the ground
* Now always cycle through Nukes and Fire Sales
* The powerup that a Monkey picks up no longer has to initially be a Max Ammo for Perk Bottle to be cycled through (still has to be picked up as a Max Ammo)
* Fixed a bug where monkeys would not spawn in certain situations where the max amount of zombies were already spawned in
* Monkey ambient sounds go away once all the powerups currently on the map have been picked up by monkeys
* Fixed a bug where Monkeys would not go after a powerup that spawned at the same time or almost the same time as another powerup
* Monkeys now wait .5 seconds to spawn instead of a random amount between 0 and 1 second

### Napalm
* Kills from napalm explosion or flames count for the player who killed the napalm or the player who triggered the napalm

### Shrieker
* Damaging a shrieker will now always give points

### Cosmonaut
* Fixed a bug where the Cosmonaut would get stuck in place if spawned in while a player was on the jump pads
* Fixed a bug where the Cosmonaut would be attracted towards a Gersch Device and move faster than intended after the Pack-a-Punch gates had been hacked
* Cosmonaut no longer teleports players that activate a jump pad between the time of being grabbed and when they would have been teleported
* Now kills any zombies nearby when Cosmonaut explodes
* Removed name above Cosmonaut's head

## Maps
* Easter egg songs can now be reactivated once the song is over
* Added out of bounds death barriers to all maps

### Nacht Der Untoten
* Now uses marine characters from World at War
* Removed character dialog

### Verruckt
* Now uses marine characters from World at War
* Fixed zombie pathing near Speed Cola
* Removed character dialog
* Removed intro text

### Shi No Numa
* Removed the need power hintstring for perks while they are spawning
* Fixed a bug where players were able to buy Quick Revive on solo while it was still in the process of spawning
* Last perk is buyable while it is spawning
* Objects can now be seen from farther away

### Der Riese
* Fixed Mystery Box use trigger in Trench Gun room
* Players will no longer get stuck on curbs
* Easter egg song now plays the whole song
* Removed intro text

#### Sidequest
* Reward: spawns a random powerup at the teleporter powerup spawn location

### Kino Der Toten
* Players no longer get teleported to special rooms unless both radios on the map have been activated
* Players no longer get teleported out of the Pack-a-Punch room if there is a weapon currently in the Pack-a-Punch machine
* Box lights now blink correctly with higher FPS
* Teleporter light is now green initially after turning on the power
* Teleporter mainframe pad no longer displays the need power hintstring
* Teleporter mainframe pad will now display the link not active hintstring every time the teleporter needs to be linked

### Five
* Trap pieces are already in place
* Active barriers in the spawn room stay the same throughout the entire match
* Pack-a-Punch machine will stay available for as long as the defcon room is active
* If all players on a floor use an elevator or get downed when the power is off, all zombies will now respawn
* If all players on a floor use an elevator or get downed when the power is on, all zombies will now go through teleporters
* Fixed lighting in the top floor being incorrect
* All characters now use the CIA viewmodel except Castro
* Fixed a bug that caused zombies to not go through a trap if the trap was active when a thief round ends
* Fixed a bug that crashed the game if the thief attempted to steal a player's weapon while they were using Pack-a-Punch

#### Elevators
* Decreased time to be able to use an elevator again after it has stopped from 2.1 seconds to 1 second
* Hintstring for elevators will now not show up until the elvator becomes usable again
* Added .2 second delay for the top elevator to activate after it has been triggered if there is a player blocking it so the elevator can move without the player having to ride it

#### Teleporters
* Teleporting no longer takes players' weapons away temporarily
* Teleporting no longer freezes players' controls
* Fixed teleporters showing they were ready to use again too early after teleporting through them

### Ascension
* The easter egg song teddy bears will float up and rotate around while the song is active

#### Sidequest
* Completable with 1-4 players
* Monkey round step: buttons no longer have to be pressed at the same time, only on the same monkey round
* Lunar lander step: First use centrifuge lander, then use Stamin-Up lander, then use PHD Flopper lander, and last use Speed Cola lander
* Lunar lander step - HITSAM easter egg now only requiers the letters SAM (was not enough room to fit HITSAM)
* Reward: 90 second Death Machines for the rest of the match

### Call of the Dead
* Removed zombie spawn delay at the beginning of a match

#### Sidequest
* Steps in solo are now the same as in coop
* Fuse spawns at the beginning of the match
* Generators' damage hitbox is now more accurate
* Bottle spawns at the beginning of the match
* Bottle is now given to the player who breaks the ice
* Lighthouse dials can now be rotated faster
* Rotating a lighthouse dial no longer rotates other lighthouse dials
* Radio order now resets after a wrong radio is activated
* Human zombie travelling up the light house needs to be damaged for 10000 health (previously 5000 health multiplied the amount of players)
* Reward: upgraded Wunderwaffe from every Wunderwaffe powerup for the rest of the game
* Wunderwaffe powerup from sidequest stays on the map until picked up

### Shangri-La
* Pack-a-Punch stones do not have to be stepped on at the same time
* Eclipse mode activatable with 1-4 players
* Can activate eclipse mode one more time after sidequest completion to stay in eclipse mode for the rest of the match
* While a weapon is in Pack-a-Punch, players will not be pushed off the stairs
* Zombies killed from the Pack-a-Punch stairs now count as kills and award kills to the player closest to them
* Gongs now move and make a sound when meleed if they have already been meleed recently
* Mud pit walls now only activate when a player is on the ground
* Fixed a bug where players were able to sprint and enter prone in the mud pit if they were drinking a perk while entering the mud pit

#### Sidequest
* Completable with 1-4 players
* Stepping stones step: stones stay down until a new stone on the same side has been stepped on
* Waterslide step: only 1 player now required
* No longer recompletable in a match
* Melee stones step: Increased melee range for stones
* Mud pit step: radio is no longer required to be played in order to complete
* Fixed a bug where players could clip through the wall behind Pack-a-Punch during the sidequest
* Reward: all players get permament perks (Quick Revive goes away when downed in solo, can be rebought with all perks)

### Moon
* Added Fire Sale, Max Ammo, and Perk Bottle to jump pad powerup cycle
* Removed the forced jumping in low gravity
* Fixed players getting stuck in the air in low gravity with high FPS
* Excavators will not reactivate for places that have already been breached
* Fixed the invisible digger glitch
* Gersch Devices and QEDs no longer breach windows
* Added line of sight check on explosions for breaching windows
* Fixed bug where players could stay on jump pads in low gravity indefinitely by diving upon landing on them
* Jump pads now fling players correctly when a player dives on a jump pad
* Crawlers get deleted if players are too far away from then and no players are looking at them
* Pack-a-Punch hackable gates are now solid when moving (players were able to hack Pack-a-Punch and then escape before the gates closed to get 1000 points)
* Fixed a bug where players would sometimes be moving in a different direction after teleporting
* Fixed a bug where the next round would only have one zombie if players teleported to No Man's Land while the round was changing and the Cosmonaut was spawned in
* Fixed a bug that caused the amount of zombies on round 1 to be the amount of zombies that should be on round 2
* Teleporter gate doesn't start going down until power is on
* When Tunnel 6 or Tunnel 11 are breached from an excavator, the areas with doors closed to the excavator will not get breached until the doors are opened
* Jump pad in Receiving Bay now only pushes players upwards
* Excavator sounds no longer linked to FPS
* Teleporter sounds no longer linked to FPS
* Announcer tells players when entering a new zone through the airlocks if the zone that the player is going into is not outside
* Fixed a bug where the sky would turn bright right after restarting the map
* Removed certain triggers on the map that move players

#### No Man's Land
* Current No Man's Land round displayed in black where the round number normally is
* Now spawns 24 zombies instead of 20 zombies
* Now displays a more accurate time of how long you survived
* Zombies now spawn more consistently in the middle area during the beginning
* Insta kill rounds can now occur on No Man's Land (except for the initital time you spawn in so players can't exploit No Man's Land insta kill rounds to get more kills)

#### Sidequest
* Full sidequest completable in solo
* Full sidequest completable without Richtofen
* Part 1 reward - 90 second Death Machines for the rest of the match
* Full reward - permament perks (Quick Revive goes away when downed in solo, can be rebought with all perks)

### Dead Ops Arcade
* Fates are now always in the same order (Fate of Fortune - top, Fate of Firepower - right, Fate of Friendship - bottom, Fate of Furious Feet - left)

## Gamemodes

### Survival
* Standard gameplay

### Versus
* Competitive gameplay
* Power is already on
* No walking zombies
* Shoot players to slow them down
* Knife players to push them
* Upgraded weapons slow players down more
* Ballistic knife, bowie knife, and sickle push players farther
* Grenades, mines, flops, and Scavenger explosions deal 25 damage to enemies
* Mines are triggerable by enemy players
* Enemy mines are destroyable
* Powerups have negative effects towards the team that did not grab the powerup
* Mystery Box always initially spawns randomly on maps that the box can spawn randomly
* Mystery Box can initially spawn in the start room on maps that the box can spawn randomly
* Mystery Box can initially spawn anywhere on Five
* Mule Kick disabled on all maps except Moon
* Turrets attack players (won't attack the team that activated the turret)
* Players gain 10 points for slowing down a player if they are below full health
* If an enemy player assisted in getting a player down, the player will gain 5% of the player's points who downed
* When a enemy player bleeds out, players gain 10% of their current points
* Removed all normal powerups except for Fire Sale
* Fire Sale: makes traps cost 10 points
* Added Powerdowns: powerups that do negative effects to the enemy team
* Clip Unload Powerdown: unloads players' clips of the weapon they are currently holding
* Half Damage Powerdown: players do half damage to zombies for 30 seconds
* Half Points Powerdown: players earn half points for 30 seconds
* Punishment Points Powerdown: players lose a random amount of points between 500 and 2500 points
* Slow Down Powerdown: Players move slower for 30 seconds
* Added Meat Powerup
* Nacht Der Untoten: all doors are open from the start of the match
* Shi No Numa: first room doors are open from the start of the match
* Der Riese: first room doors are open from the start of the match
* Der Riese: all teleporters linked
* Der Riese: powerdown spawns from the start of each match
* Der Riese: powerdown and full health dogs spawn from every teleporter use
* Kino Der Toten: teleporter is permamently linked to the mainframe
* Five: all 6 barriers in the start room are enabled
* Five: first room door is open from the start of the match
* Five: teleporters disabled
* Five: Pack-a-Punch door is now a 1500 point buyable door
* Ascension: first room doors, door near MP5K, and door above Juggernog are open from the start of the match
* Ascension: lunar landers disabled
* Ascension: Pack-a-Punch door is now a 1500 point buyable door
* Call of the Dead: director spawns 2 random powerdowns on death
* Shangri-La: Pack-a-Punch stairs are open from the start of the match
* Shangri-La: geyser in the start room is open from the start of the match
* Shangri-La: minecart disabled
* Moon: No Man's Land disabled
* Moon: first room door is open from the start of the match
* Moon: hacker and PES disabled
* Moon: teleporter disabled

#### Grief
* Win by surviving a round after all enemy players are dead

#### Free-for-all Grief
* Win by surviving a round after all enemy players are dead
* Players bleed out instantly
* Quick Revive disabled

#### Search & Rezurrect
* Round based gamemode
* Unlimited zombies
* 2,000 health zombies
* .5 second zombie spawn rate
* Only sprinting zombies
* Every player starts with 5,000 points and will get 5,000 points at the beginning of each new round if they have less than 5,000 points
* Win a round by killing the remainder of the zombies spawned on the map after all enemies have downed
* If both teams die on a round, neither team will get a point
* Win the game by winning 3 rounds
* Shangri-La: unlimited napalm and shrieker zombies can spawn (only one of each can be spawned in at a time though)
* Moon: unlimited cosmonauts zombies can spawn (only one can be spawned in at a time though)

#### Race
* Unlimited zombies
* Auto revive after 10 seoconds
* Starts at round 1, every 45 seconds round increases until round 20
* Gain 500 points on each round increase if you are alive
* First team to 250 kills, or team with most kills after round 20 wins
* Shangri-La: unlimited napalm and shrieker zombies can spawn (only one of each can be spawned in at a time though)
* Moon: unlimited cosmonauts zombies can spawn (only one can be spawned in at a time though)

#### Gun Game
* Unlimited zombies
* Unlimited ammo
* Quick Revive disabled
* Wall weapons disabled
* Mystery box disabled
* Mule Kick disabled
* 2,000 health zombies
* 2 second zombie spawn rate
* Only running zombies
* Auto revive after 10 seoconds
* Win the game the game by progressing through all the weapons
* Weapon order: pistols, shotguns, smg's, assault rifles, lmg's, snipers, explosives, wonder weapons, ballistic knife
* Zombies will drop a gun increment powerup after getting 10 kills with your current weapon
* New powerup: upgrade weapon powerup (for 30 seconds get the upgraded version of any weapon you are currently on)
* Only the player who killed the zombie can grab and see the gun increment powerup
* Shangri-La: unlimited napalm and shrieker zombies can spawn (only one of each can be spawned in at a time though)
* Moon: unlimited cosmonauts zombies can spawn (only one can be spawned in at a time though)

#### King of the Hill (scrapped)
* Unlimited zombies
* Gain points by controlling an area of the map without any enemies contesting the area
* Win the game by reaching the score limit

#### Capture (scrapped)
* Unlimited zombies
* Gain points by capturing the enemy team's meat
* 2 rounds (switch side after the first round)
* Win the game by having the most points at the end of the game
* First round ends if a team scores 3 points

#### Turned (scrapped)
* Unlimited zombies
* Every player starts off not infected
* When a player dies, they become infected
* Infected player must attempt to infect the uninfected player
* Win by being a survivor after the time limit or get all players infected

## TODO
* Add Springfield chalk
* Add BO2 weapon models (M14, M16, Olympia, FN FAL, Galil, Python, AK47, Ballistic Knife, Bowie Knife)
* Add BO3 weapon models (Frag, Semtex, Claymore, Ray Gun, Wunderwaffe, Thundergun, Baby Gun, Wave Gun, Gersch, Matroyshka Dolls, QED, Monkey Bomb, Hacker)
* China Lake: speed up rechamber anim
* Thundergun: speed up last shot anim
* Der Riese: use WaW pap camo for all weapons except Wunderwaffe
* Add death hands from BO2 when you die
* Make players drink perks correctly in third person (fixed in BO2)
* Change perk bottle weapons to only use one weapon file using worldModel and gunModel
* COTD: fix Director not doing anim when initially getting angry
* Fix being able to cancel melee animation by switching weapons with a weapon that has an empty clip
* Five: fix zombies getting stuck after teleporting
* Add collision boxes near invincibilty spots on maps
* Fix zombies sounds on classic maps to sound like they are coming from the correct direction
* Five: get wall barrier tear down sound and metal vent barrier rebuild sound from other maps working
* Try making dvars unchangeable from console
* Fix bug where first damage taken after being downed and getting revived or spawning back in doesnt deal damage to player
* Fix trap g_spawn error (getting hit twice and running through a trap causes g_spawn?, couldn't get it to happen)
* Make better last powerup FX
* Add stielhandgranate icon on HUD
* Look into fixing zombies not going to barriers if they have multiple to choose from (self.entrance_nodes?)
* Deadshot: fix bug with fast ADS move speed where if you ADS right after reloading your move speed is temporarily faster than it should be
* Deadshot: add fast ADS move speed correctly
* Show player's perks when spectating (player.spectatorclient?)
* Shang: fix crawlers from bleeding out and not allowing extra zombies to spawn in (couldn't get it to happen)
* Fix trench gun 3rd person sounds being too loud
* Make it so Death Machine and FG42 weapon models look better with higher FOV
* Fix sprint and dive anims on Ray Gun
* Fix Der Riese Nikolai viewhands for FG42
* Fix Ballistic Knife first raise anim (shows knife at very bottom center of screen at end of anim)
* Use Sleepy when game crashes on map load
* Remove zombie failsafe death print before release
* Replace WaW weapon viewmodels in BO1 with their equivalents in WaW to see if their model is more correct
* Try to use BO1 Thompson sprint and dive anims (need to be adjusted)
* Modify Gersch Device to use projectileSpeedUp instead of projectileSpeedRelativeUp
* Find a way to be able to shoot through more than 3 zombies
* Get weapons to not lose damage when going through surfaces (already have fix in gsc, try to add fix from weapon file)
* Add BO2 meat FX and grief FX in game
* Rename some zone names
* Fix Nikolai viewhands
* Fix textures getting changed when getting sprayed with flamethrower attachment
* Optimize Gersch Device code
* Optimize zombies in barrier and traversing barrier code
* Make it so switching to weapon powerup doesn't take fast switch perk into account
* Kino: fix noises in dressing room being tied to FPS (could not find in any gsc or csc)
* Fix zombies making sounds after death
* Scoped Kar98k: use original scope overlay?
* Molotov Cocktail: fix flame not going on bottle (Use WaW model/anims)
* Get voicelines from WaW for marine characters on Nacht and Verruckt
* Type 100: add empty sprint and dive anims
* Thompson: add empty sprint and dive anims

### Versus Todo
* Add new grief damage fx
* Fix turret attacking team of player that activated turret (if cant fix, then make turrets attack anyone to make it fair)
* Gun Game: fix rare bug where multiple gun increment powerups spawn (might be fixed, not sure what causes it, not caused from killing multiple zombies from the same shot)
* Grief: after enemy team downs, only zombies left for the round are the zombies that are currently spawned in?

### Cannot Find Fix
* Turn off Der Riese easter egg song noises after they have been activated
* Moon: fix sliding sound keep playing when off object

### Might Be Fixed
* Make zombies not try to go for players on Verruckt who are on the other side of the map when the power is off (need to test if fixed)
* Figure out bug that causes cosmonaut to delete himself occasionally
* Make insta kill powerups work in high rounds
* Ascension: Fix high round invisible and invincible zombies after being damaged from the centrifuge
* Fix Ascension monkey pathing
* Fix kino round skip bug
* COTD: fix bug where director does not do angry anim when he should (happened with upgraded waffe powerup but can't reproduce, might be fixed)
* Fix Wunderwaffe not arcing after first kill rarely
* Fix Der Riese trap lights rarely not turning red when active (can't get it to happen again, happened first time turning on trap on round 20)

### Cannot Do Yet
* Add fast ADS to Speed Cola (when it becomes possible through game_mod)
* Add fast grenade throw to Speed Cola (when it becomes possible through game_mod)
* Add fast sprint recovery to Deadshot (when it becomes possible through game_mod)

### Maybe
* Remove switching weapons check from perks, knives, and pack-a-punch?
* Shangri-La: should mud pit sidequest step need the radio to be activated to work? No
* Moon: should teleporter gate start going down before power is on? No
* Should there be a zombie spawn delay?
* Should NML have insta kill rounds? No
* If you have 4 perks or more, still allow players to buy perks but bought perk will replace oldest perk?
* Should special rounds always be 5 rounds apart?
* Health bar for player's health?
* Make wallbuy hintstrings show only buy weapon, buy ammo, or buy upgraded ammo?
* Add C4?
* Verruckt: replace one of the Double Barrel wall buys with sawed off Double Barrel?

### Testing
* Moon sidequest dialog in coop without Richtofen
* Check if zombies are bleeding out on any maps while doing normal strats (add print statement to zombie failsafe death)
* Test if players are able to grief teammates (need 3-4 players)
* Test if zombies are attracted towards players on Verruckt on other side when power door is closed (need 3-4 players)
* Test meat in coop (now using IsTouching() on players)
* Test Trench Gun 3rd person sounds
* Ray Gun: test 3rd person dry fire sound

## BUGS THAT ARE STAYING (IT'S A FEATURE, NOT A BUG)
* Insta kill rounds
* Powerup limit per round reset by teleporting on Moon
* Damaging a zombie resets its hit animation
* Dogs on No Man's Land have 150 health for 1.5 seconds after spawning in
* Trapping the cosmonaut via excavator
* Shi No Numa Flogger double trap activation

## FEATURES THAT WILL NOT BE ADDED
* Additional perk machines on maps
* No more new weapons

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
* Fix rechamber times changed for existing weapons not showing correct anim when ads (try making legacy mod with modified rechamber time and see if it works how it should)
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

## SPECIAL THANKS
* **_WARDOG_** - co-developer
* **_lilrifa_** - assisted with menu scripting
* **_MasadaDRM_** - assisted with weapons and sounds
* **_xSanchez78_** - assisted with client scripting and localized strings
* **_Kody_** - Wunderwaffe gold camo, fixed CIA player viewmodel, assisted with animations
* **_UltraZombieDino_** - BO3 P.E.S. model and animations
* **_KagamineAddict_** - updated P.E.S. visor texture
* **_ZeRoY_** - function list
* **_SE2Dev_** - LinkerMod
* **_Nukem_** - LinkerMod
* **_DTZxPorter_** - Wraith
* **_Treyarch_** - Assets, source code, and an amazing base game

## TESTERS
* **_FleshCrunch_**
* **_Ph3Nix_**
* **_WECoyote99_**
* **_Pure_**
* **_donnellyian1995_**