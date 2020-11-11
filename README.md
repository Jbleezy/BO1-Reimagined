# Call of Duty: Black Ops Zombies - Reimagined

## Created by: Jbleezy

[YouTube](https://youtube.com/c/ItsJbirdJustin1)

[Twitch](https://twitch.tv/jbleezy)

[Twitter](https://twitter.com/ItsJbleezy)

[Donate](https://streamlabs.com/jbleezy)

## Change Notes

## General
* Insta kill rounds (rounds where zombies have round 1 health) happen every odd round starting at round 163
* Any hintstring that previously showed "Press & hold" or "Press" at the beginning has been changed to only show "Hold"
* Power hintstrings on classic maps have been changed to show the same hintstring on non classic maps
* Hintstrings are now invisible while the current action is not available for the player
* Round now ends immediately when last zombie is killed (previously up to a one second delay)
* Intermission time decreased from 15 seconds to 10 seconds
* Maps now auto restart in coop after intermission
* Maps now auto restart correctly (box location gets randomized again)

## Players
* Unlimited sprint
* Backwards move speed, strafe move speed, and sprint strafe move speed are now all at 100%
* Self revives in solo are active whenever the player has at least 1 perk
* Decreased normal health regeneration delay from 2.4 seconds to 2 seconds
* Decreased low health regeneration delay from 5 seconds to 4 seconds
* Normal health regeneration rate is no longer instant
* Changed health regeneration rate to 100 health per second (previously fully restored health in 0.5 seconds)
* Removed melee lunging
* Removed maximum fall damage cap (previously capped at 110)
* All players are attracted equally
* Can now dive again right away after just diving
* Can now move after diving quicker
* Decreased dive startup time
* Can now look up and down 90 degrees (previously 85 degrees)
* Added a points cap of 10 million
* Added heartbeat and breathing sounds when low on health
* Added heartbeat sound when down
* Text when being revived in solo now only displays "Reviving"
* Added death hands animation from Black Ops 2
* Dead players can chat with alive players
* Can now red screen after bleeding out and respawning
* Characters no longer make hurt sounds from explosions if you have PHD Flopper
* Can now shoot when looking at another player
* Player names now disappear instantly after being out of line of sight of them
* Added a minimum weapon switch delay of 50 milliseconds
* If a player switches weapons while reviving, their weapon will not get switched when finishing a revive
* Lean is now disabled while down since downed players cannot be revived while they are leaning
* Fixed a bug where players were able to damage themselves by meleeing and leaning at the same time
* Fixed a bug where a player was able to revive another player by bleeding out next to them in water
* Fixed a bug where downed players were able to occasionally damage alive players
* Too many weapons penalty has been changed to only take the weapon that the player shouldnt have
* Fixed a bug where the first damage taken after being revived or respawning would sometimes not register
* Fixed a bug where players were able to freeze in mid air with no weapon in hand if they held the fire button while spawning in
* Fixed players getting stuck in the air when jumping next to an object with high FPS

## HUD
* HUD items now have some distance away from the edge of the screen
* Damage icon time now matches the health regeneration time
* Zombie counter displayed on the top left
* Total time displayed on the top right
* Round time displayed on the top right
* Total time at the end of each round displayed on the top right between rounds
* Sidequest completion time displayed on top center
* Health bar displayed on the bottom left
* Zone name displayed on the bottom left
* Character names displayed next to player's points
* Ammo display on HUD no longer fades away
* Grenades on HUD are now more spread out
* Removed Reload, No Ammo, and Low Ammo HUD messages
* Removed bloodsplat on D-pad
* Fixed attachments on D-pad being highlighted incorrectly
* Score highlights now only show one positive amount and one negative amount per player at a time
* Negative score color is now slightly brighter
* Yellow insta kill shows on HUD during insta kill rounds
* Removed blur on in-game pause menu
* Removed black border on top and bottom of in-game pause menu

## Settings
* Restart level button enabled for host in online matches
* Removed popup menu when changing graphic content to unrestricted
* Reduced graphic content now only removes blood
* Combat settings: removed Sprint/Hold Breath option and Steady Sniper option (sniper scopes are always steady now)
* Combat settings: added Previous Weapon option
* Combat settings: changed name of "USE EQUIPMENT" to "EQUIPMENT"
* Combat settings: changed name of "GROUND SUPPORT" to "PLACEABLE MINE"
* Option to change FOV (65-120 in intervals of 5)
* Option to change max FPS (60, 90, 120, 180, 240, 360, 500, 750, 1000, or unlimited)
* Option to show FPS on HUD
* Option to change weapon switch delay
* Option to enable or disable fog
* Options to enable or disable enemy counter, timer, health bar, zone names, and character names
* Option to enable or disable character dialog (host only)
* Option to choose which room you start in on Verruckt (host only)
* Option to choose which perk you start with on No Man's Land (host only)
* Option to choose the initial box location on maps that have a random initial box location (host only)
* Option to choose which gamemode to play, including random which includes every gamemode except Survival (host only)
* Option to choose random, free-for-all, or custom teams in Versus gamemodes

## Weapons
* All bullet damage (except for shotguns) will now deal full damage through multiple zombies or thin walls
* All body shots now deal the same amount of damage
* Neck shots, head shots, and helmet shots now all deal the same amount of damage
* All body shots will now give 50 points for a kill
* Neck shots now give 100 points for a kill
* Melee kills can no longer count as headshots
* All weapons now have sprint and dive animations
* All weapons now always use correct empty clip drop animation
* Ammo now gets added at the same time that it does in the reload animation of all weapons

### New Weapons

#### Combat Knife
* Wield your current knife by pressing the new melee weapon keybind (found in combat settings)
* If you have no other weapon, you will hold your knife by default
* 110% move speed

#### Molotovs
* Added in classic maps
* Deal infinite damage on impact

#### Springfield
* Added in Verruckt on the wall in replace of the Kar98k wallbuy on the Quick Revive side

#### AK47
* Upgraded name: The Red Mist
* Upgraded version has flamethrower attachment
* 30 rounds per clip
* Unupgraded: damage - 150
* Unupgraded: headshot damage - 600
* Upgraded: damage - 210
* Upgraded: headshot damage - 1050

#### PPSH
* Upgraded name: The Reaper
* 71 rounds per clip
* Unupgraded: damage - 100
* Unupgraded: headshot damage - 400
* Upgraded: damage - 150
* Upgraded: headshot damage - 600

#### PSG1
* Upgraded name: Psychotic Salient Genius
* Replaces the Dragunov
* 10 rounds per clip
* Unupgraded: damage - 500
* Unupgraded: headshot damage - 2500
* Upgraded: damage - 1000
* Upgraded: headshot damage - 8000

#### Stoner63
* Upgraded name: Stoned69
* Unupgraded: 60 rounds per clip
* Upgraded: 90 rounds per clip
* Unupgraded: damage - 160
* Unupgraded: headshot damage - 480
* Upgraded: damage - 230
* Upgraded: headshot damage - 690

### Explosive Weapons
* Removed shellshock effect from all explosive weapon damage
* Explosion radius is the same for all explosive weapons
* Damage scaling over rounds is now done at a more consistent rate
* Damage scaling caps at round 100
* No longer deal half damage to players if they were diving away from the explosion

### Light Machine Guns
* Decreased move speed from 87.5% to 85%

### Pistols
* Increased move speed from 100% to 110%
* Increased move speed while aiming from 200% to 220%

### Shotguns
* Decreased spread when aiming

### Snipers
* Decreased move speed from 95% to 90%
* Removed idle sway while aiming
* Increased FOV when aiming from 15 to 30
* Variable zoom scopes now only have one scope option

### Submachine Guns
* Decreased move speed from 110% to 105%
* Decreased move speed while aiming from 220% to 210%

### AK74u
* Increased move speed from 100% to 105%
* Increased move speed while aiming from 200% to 210%
* Changed wallbuy hintstring from "AK-74u" to "AK74u"
* Upgraded: fixed fire sound

### AUG
* Upgraded: decreased stock ammo from 390 to 360
* Upgraded: increased shotgun stock ammo from 30 to 36
* Upgraded: added name of weapon attachment on HUD

### Ballistic Knife
* Knives pick up automatically when close to them
* Knives that are picked up no longer automatically fill the clip if the Ballistic Knife is not the player's current weapon
* Decreased time to start reloading from .7 seconds to .5 seconds
* Fixed a bug where a knife could be picked up if the player had max stock ammo
* Obtaining the Bowie Knife or Sickle no longer gives you more ammo
* Fixed a bug where a knife could not be picked up if another knife is fired and lands before the first knife
* Fixed a bug where knives on the ground would disappear whenever the player uses the Pack-a-Punch machine
* No longer gibs zombies on impact
* Knife now glows as soon as it is attached to a zombie
* Knife no longer attaches to a zombie if the knife kills the zombie
* Fixed first raise animation from showing the ring floating
* Fixed empty clip animations with Bowie Knife still showing the blade
* Unupgraded: increased impact damage from 450 to 500 (weapon file shows it is suppose to do this amount of damage but it does not)
* Unupgraded: increased melee damage with Bowie Knife or Sickle from 1000 to 1350
* Upgraded: increased impact damage from 900 to 1000 (weapon file shows it is suppose to do this amount of damage but it does not)
* Upgraded: increased melee damage with Bowie Knife or Sickle from 1500 to 1850

### BAR
* Replaced BAR + Bipod with BAR
* Removed bipod from weapon model
* All BAR wallbuys now cost 1800
* Increased headshot damage from 270 to 400

### China Lake
* Can now fire without aiming
* Now rechambers while aiming
* Increased explosion radius by 28%
* Increased damage scaling over rounds
* Decreased sprint recovery time from .6 seconds to .3 seconds
* Decreased time to start rechambering and reloading after firing from 1 second to .5 seconds
* Unupgraded: decreased rechamber time from 2 seconds to 1 second
* Unupgraded: increased minimum explosive damage from 75 to 150
* Upgraded: decreased rechamber time from 1.4 seconds to .7 seconds
* Upgraded: increased impact damage from 1000 to 1200
* Upgraded: increased minimum explosive damage from 75 to 300

### Commando
* Upgraded: increased stock ammo from 360 to 480

### Crossbow Explosive Bolt
* Added on Moon
* Crossbow bolt beeping rate no longer changes depending on your FPS
* No longer gibs zombies on impact
* Increased explosion radius by 28%
* Increased damage scaling over rounds
* Unupgraded: changed name from "Crossbow Explosive Tip" to "Crossbow Explosive Bolt"
* Unupgraded: increased impact damage from 675 to 750 (weapon file shows it is suppose to do this amount of damage but it does not)
* Unupgraded: increased minimum explosive damage from 75 to 150
* Unupgraded: increased maximum explosive damage from 400 to 600
* Upgraded: increased impact damage from 675 to 2250 (weapon file shows it is suppose to do this amount of damage but it does not)
* Upgraded: increased headshot impact damage from 3000 to 9000
* Upgraded: increased minimum explosive damage from 225 to 625
* Upgraded: zombies get attracted immediately
* Upgraded: all zombies get attracted directly to the bolt
* Upgraded: zombies that are stuck with the bolt now stop doing the taunt animation immediately after the bolt explodes

### CZ75
* Added empty clip animations

### CZ75 Dual Wield
* Decreased recoil
* Fixed empty clip idle, drop, and raise animations
* Unupgraded: increased stock ammo from 228 to 240

### Double-Barreled Shotgun
* Spread increases while moving
* Fixed animations
* Fixed shell eject effect showing 2 shells
* Upgraded: changed name from "24 Bore long range" to "24 Bore"
* Upgraded: removed additional headshot damage

### Dragunov
* Removed (replaced by PSG1)

### Famas
* Unupgraded: increased stock ammo from 150 to 300
* Upgraded: increased stock ammo from 225 to 450

### FG42
* Upgraded: decreased stock ammo from 400 to 384

### G11
* Unupgraded: increased stock ammo from 144 to 240
* Upgraded: increased stock ammo from 288 to 384

### Gewehr 43
* Unupgraded: increased damage from 120 to 130
* Upgraded: decreased stock ammo from 170 to 168

### HK21
* Upgraded: decreased stock ammo from 750 to 600

### HS10
* Upgraded: fixed right weapon fire sound
* Upgraded: decreased hipfire spread
* Upgraded: decreased recoil

### Kar98k
* Unupgraded: increased damage from 170 to 500
* Unupgraded: increased headshot damage from 350 to 1000
* Upgraded: increased stock ammo from 60 to 64
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

### M1 Garand
* Added sound that plays when first obtaining
* Fixed raise animation
* Decreased raise time from .8 seconds to .6 seconds

### M14
* Added empty clip animations

### M16
* Unupgraded: increased stock ammo from 120 to 150
* Upgraded: increased stock ammo from 270 to 300
* Upgraded: increased grenade launcher stock ammo from 8 to 10
* Upgraded: increased grenade launcher damage scaling over rounds
* Upgraded: decreased grenade launcher explosion radius by 36%
* Upgraded: increased grenade launcher impact damage from 700 to 800
* Upgraded: increased grenade launcher maximum explosive damage from 400 to 600
* Upgraded: increased grenade launcher minimum explosive damage from 75 to 150
* Upgraded: added name of weapon attachment on HUD
* Upgraded: ammo for weapon attachment now shows on HUD

### M1911
* Upgraded: decreased stock ammo from 50 to 48
* Upgraded: increased explosion radius by 28%
* Upgraded: increased impact damage from 1000 to 1200
* Upgraded: increased minimum explosion damage from 75 to 300
* Upgraded: camo now displays when downed in solo

### M72 LAW
* Can now fire without aiming
* Decreased time to start reloading from 1.06 seconds to .5 seconds
* Increased explosion radius by 12%
* Fixed dive to prone animation from looping
* Fixed sprint footstep sounds happening too slow
* Unupgraded: increased maximum explosion damage from 320 to 1500
* Unupgraded: increased minimum explosion damage from 100 to 375
* Upgraded: increased maximum explosion damage from 600 to 2500
* Upgraded: increased minimum explosion damage from 100 to 625

### MP40
* Fixed sprinting animation not playing correctly when clip is empty
* Now uses World at War upgraded camo on Der Riese

### Olympia
* Unupgraded: increased stock ammo from 38 to 40
* Unupgraded: increased maximum damage per pellet from 120 to 180
* Upgraded: increased maximum damage per pellet from 200 to 300
* Upgraded: fire effect now plays when damaging a zombie

### PM63
* Unupgraded: increased stock ammo from 100 to 120
* Upgraded: increased stock ammo from 225 to 250
* Upgraded: decreased hipfire spread
* Upgraded: decreased recoil

### Python
* Upgraded: now given to the player when downed on solo if they have the weapon

### RPK
* Fixed empty drop animation
* Fixed dive to prone animation from looping
* Fixed sprint footstep sounds happening too fast

### Sawed-Off Double-Barreled Shotgun
* Decreased range by 25%
* Increased spread by 25%
* Decreased recoil by 33%
* Decreased reload time from 3 seconds to 2.5 seconds
* Spread increases while moving
* Fixed animations
* Fixed shell eject effect showing 2 shells
* Changed name from "Sawed-Off Double-Barreled Shotgun w/ Grip" to "Sawed-Off Double-Barreled Shotgun"
* Changed wallbuy hintstring from "Sawed-Off Shotgun" to "Sawed-Off Double-Barreled Shotgun"

### Spectre
* Unupgraded: increased stock ammo from 120 to 240
* Upgraded: increased stock ammo from 225 to 360

### Stakeout
* Unupgraded: increased stock ammo from 54 to 60
* Changed dive animation times

### STG-44
* Upgraded: changed name from "Spatz-447 +" to "Spatz-447"

### Thompson
* Upgraded: decreased stock ammo from 250 to 240
* Fixed empty raise animation

### Trench Gun
* Spread increases while moving
* Fixed shell eject effect showing 2 shells

### Type 100
* Unupgraded: increased stock ammo from 160 to 180
* Upgraded: increased stock ammo from 220 to 240

### Wonder Weapons

### Ray Gun
* Removed weapon bob from movement
* Added sprint and dive animations from Black Ops 2
* Added sound from Black Ops 2 that plays when first obtaining
* Added sound from Black Ops 2 that plays when attempting to fire without any ammo
* Increased move speed from 100% to 105%
* Increased move speed while aiming from 100% to 105%
* Decreased first raise time from 2.4 seconds to 1.8 seconds
* Fixed first raise animation lasting too long at the end
* Fixed knob being in incorrect position
* Unupgraded: increased impact damage from 1000 to 1500
* Unupgraded: increased minimum explosion damage from 300 to 750
* Upgraded: increased impact damage from 1000 to 2000
* Upgraded: increased minimum explosion damage from 300 to 1000
* Upgraded: camo now displays on more of the weapon

#### Wunderwaffe
* Now always arcs to other zombies within line of sight
* Can now down yourself with Wunderwaffe damage (previously could only take you down to 1 health but not down you)
* The initial zombie that is hit will now always be the zombie that is closest to the bolt's location
* Unupgraded: decreased self damage radius by 72%
* Unupgraded: increased zombie damage radius by 36% (now has the same radius as the upgraded version)
* Upgraded: decreased self damage radius by 134%
* Upgraded: increased maximum amount of kills from 10 to 15
* Upgraded: decreased time between kills by 33%
* Upgraded: gold camo on Der Riese, regular camo on Call of the Dead
* Upgraded: gold camo is now shinier
* Added sprint and dive animations on classic maps
* Bulbs now light up correctly after reload cancelling

#### Thundergun
* Weapon fails happen less often
* Kills all zombies at once
* Gives 50 points for each kill
* Zombies are now flung based on the angles of the player who fired the Thundergun
* Decreased range by 6.25%
* Fixed empty clip idle, drop, raise, and sprint in animations
* Zombies no longer gib from being knocked down
* Zombies no longer drop powerups when killed from being knocked down

#### Winter's Howl
* Changed fire type to automatic
* Weapon fails happen less often
* Kills zombies in 1-3 shots depending on how far away the zombie was from the shot
* No longer drops powerups
* Damages frozen zombies
* Zombies that die from the Winter's Howl will now shatter automatically after 3-4 seconds (previously 5-6 seconds)
* Zombies that die from the shatter effect no longer get frozen
* Shatter effect no longer shatters other zombies
* Shatter effect no longer gibs other zombies that die from the shatter
* Increased move speed from 100% to 105%
* Increased move speed while aiming from 100% to 105%
* Decreased first raise time by 50%
* Fixed an error that crashed the game if zombies were shattered instantly after being killed
* Fixed an error in the sprint out animation
* Unupgraded: increase minimum damage from 500 to 750
* Unupgraded: increase maximum damage from 1000 to 1500
* Unupgraded: increased maximum damage range by 500%
* Unupgraded: shatter effect now deals 500 damage (previously 250-500 depending on range)
* Unupgraded: increase minimum damage from 750 to 1000
* Unupgraded: increase maximum damage from 1500 to 2000
* Upgraded: decreased radius by 33% (now has the same radius as the unupgraded version)
* Upgraded: increased maximum damage range by 375%
* Upgraded: decreased shatter range by 60% (now has the same range as the unupgraded version)
* Upgraded: shatter effect now deals 500 damage (previously 500-750 depending on range)
* Upgraded: camo now displays on more of the weapon

#### Scavenger
* Infinite explosion damage
* Added impact damage

#### V-R11
* Now has a small splash damage (still only affects one player or zombie)
* Can affect yourself
* Human zombies now target the closest zombie to them
* Zombies die when they get close to a human zombie
* Director is no longer attracted towards the human zombie
* Shooting the Director while he is calm no longer makes him angry
* Owner of V-R11 gets 50% of any points that the player who they shot earns for its duration (previously 75%)
* Unupgraded: permanently makes the Director calm when shot at him
* Unupgraded: human zombie lasts for 10 seconds
* Upgraded: human zombie lasts for 15 seconds
* Upgraded: human zombie explodes when it dies
* Upgraded: removed explosion effect from shooting the same human zombie multiple times

#### Shrink Ray
* Weapon fails happen less often
* Fixed an error that crashed the game when shrinking zombies and allowing them to regrow many times throughout a game
* Shrunk zombies: increased damage from 5 to 10
* Unupgraded: decreased range by 6.25%
* Unupgraded: increased radius by 50%
* Upgraded: decreased range by 62.5% (now has the same range as the unupgraded version)
* Upgraded: increased radius by 7% (now has the same radius as the unupgraded version)

#### Zap Gun
* Upgraded: decreased stock ammo from 100 to 96

#### Wave Gun
* Weapon fails happen less often
* Kills all zombies at once
* No longer instantly kills zombies traversing over barriers
* Gives 50 points for each kill
* Decreased range by 6.25%

### Equipment

#### Lethal Grenades
* Cannot be thrown faster than intended when throwing a grenade right after after throwing one
* Increased impact damage from 15 to 30
* Impact damage now does not get decreased after damaging other zombies

##### Frag Grenade
* Changed upwards projectile speed

##### Semtex
* Can no longer be cancelled while throwing
* Now always cost 250 points to buy (previously costed 130 points after first buy)
* Semtex beeping rate no longer changes depending on your FPS
* Changed upwards projectile speed

##### Stielhandgranate
* Now deals damage on impact
* Added HUD icon from Call of Duty: WWII
* Added projectile trail effect
* Added throw back animation
* Stationary grenades now idle correctly

#### Tactical Grenades
* Now cannot be thrown faster than intended when throwing a grenade right after after throwing one
* Increased impact damage from 15 to 30
* Impact damage now does not get decreased after damaging other zombies
* Fixed a bug where tactical grenades wouldn't work if they were thrown before a previously thrown tactical grenade had activated
* Now always stay upright

##### Gersh Device
* Now uses model from Black Ops 3
* Zombies get attracted immediately
* Fixed a bug where zombies would attempt to get sucked into a Gersh Device shortly after it had already disappeared
* Fixed a bug where zombies would not always switch back to their normal run animation after a Gersh Device ends
* Changed upwards projectile speed

##### Matryoshka Dolls
* Now uses model from Black Ops 3
* Infinite explosion damage (except for the Director)
* Increased explosion damage on the Director from 4500 to 9000
* Removed 1 player limit

##### Monkey Bombs
* Increased explosion radius by 156%
* Zombies are no longer attracted before it activates
* Zombies get attracted immediately once it activates
* All zombies get attracted directly to the Monkey Bomb
* Removed on Nacht, Verruckt, and Shi No Numa

##### QED
* Now uses model from Black Ops 3
* 100% chance of teleporting the player when thrown outside the map
* 100% chance of reviving players when thrown near downed player
* 100% chance of giving a perk when thrown near a perk machine that is powered on
* 100% chance of opening a door when thrown near a door
* 100% chance of upgrading the player's weapon when thrown near the Pack-a-Punch machine
* 100% chance of turning off an exacavtor when thrown near an excavator panel
* 100% chance of fling effect when thrown near Cosmonaut or zombie
* Guaranteed results order: teleport player, revive players, give nearest perk, open nearest door, upgrade weapon, stop excavator, fling effect
* All other effects have a chance of spawning when none of the forced effects are activated
* Fling effect only kills zombies within line of sight
* Fling effet now kills all zombies at once
* Free perk effect now only gives the perk to the player who threw the QED
* Revive player effect now only revives players near where the QED was thrown
* Random weapon powerup now gives player max ammo on a weapon if they already have the weapon
* Starburst weapons no longer damage players
* Removed red powerup effect
* Removed unupgrade weapon effect

#### Mines
* Limit of 30 mines per player placed on the map at once
* Can now be repurchased to refill ammo
* Can now be picked up while pressing the melee button
* Increased explosion radius by 28%
* Increased move speed from 100% to 110%
* Decreased first purchase HUD text font size

##### Bouncing Betty
* Increased placing speed
* Can now explode after being placed for 1 second (previously 2 seconds)
* Can now be picked up
* No longer keeps moving and making sounds after being placed
* First raise time is now the same as regular raise time

##### Claymore
* Added placing sound
* Added activation sound
* Can no longer be picked up after being triggered
* First raise animation is now the same as regular raise animation
* First raise time is now the same as regular raise time
* Changed dive animation times

##### Spikemore
* Added activation sound
* Can no longer be picked up after being triggered
* First raise animation is now the same as regular raise animation
* First raise time is now the same as regular raise time
* Changed dive animation times

#### Useable Equipment

##### Hacker
* Every player can have the hacker
* Does not move locations when picked up
* All hackables can now be hacked while crouch or prone
* Can now only hack one item at a time
* Melee disabled during hack
* Pressing the lethal grenade button or ADS button will no longer restart a hack
* Removed points reward given between rounds
* Decreased time to hack doors from 32.7 seconds to 15 seconds
* Decreased time to hack players from 10 seconds to 1.5 seconds
* Decreased time to hack teddy bear locations from 5 seconds to 3 seconds
* Hacking a Max Ammo gives a Perk Bottle
* Hacking a powerup will reset its timer
* Hacking a Death Machine will now give the Max Ammo its correct glow color
* Increased powerup hack trigger radius by 25%
* Buying a hacked wallbuy will give you the upgraded version of that weapon
* Unupgraded and upgraded ammo both cost the price of unupgraded ammo when hacked
* Wallbuy hintstrings now update when hacked to reflect their current prices
* Doors are free to hack
* Hacking the box twice no longer gives you 950 points
* Hacking a teddy bear location will now only lock that box for the remainder of the current round
* Fire sale box can spawn at locations where the box has been hacked

##### P.E.S.
* Now uses model and animations from Black Ops 3
* Players now only lose their helmet when taking different equipment
* Fixed a bug where players were able to get no weapon in their hand by pressing the P.E.S. helmet button repeatedly
* Changed name from "P.E.S" to "P.E.S."
* D-pad now stays highlighted while putting on and taking off the P.E.S. helmet

#### Melee Weapons

##### Sickle
* Now uses model from Black Ops 3

## Wallbuys
* Purchasing ammo no longer fills the clip
* Decreased upgraded ammo cost from 4500 points to 2500 points
* Can now purchase ammo for weapons with attachments if only the attachment ammo is not full
* Multiple players can now purchase the Bowie Knife and Sickle at the same time
* Players now keep the Bowie Knife and Sickle if they down during the purchase animation
* Claymores, Bouncing Betties, and Spikemores now all require the player to be looking at the wallbuy to be able to buy them
* Sniper cabinet: weapon ammo now costs exactly 25% the cost of the weapon

## Mystery Box
* Players will now get every weapon they can from the box before getting duplicates
* All weapons have the same probability to be obtained
* Weapons will not appear again in a row while floating up (unless it is the final weapon)
* Cycles through all locations before going to a previous location again
* An effect now plays when the Mystery Box is moving if it is the last Mystery Box location of a Mystery Box location cycle
* Decreased time between uses from 3 seconds to 1.5 seconds
* Decreased weapon pickup time from 12 seconds to 9 seconds
* Box flies up higher when moving
* Now plays an animation when spawning in
* Instantly appears at its new location when moving instead of waiting 8 seconds
* Every player now sees the same weapons in the box when the weapons are floating up
* Can only see weapons floating up that the player can currently obtain
* Ray Gun can now be obtained without moving the Mystery Box on all maps
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
* Removed perk limit
* Perks now become active as soon as the player starts to put away the perk bottle
* Added gloss to all perk bottles
* Now uses 3rd person perk drink animation from Black Ops 2
* Multiple players can now buy the same perk at the same time
* Perks now fade in on the HUD when obtained
* Removed blur effect that previously happened after buying a perk
* Perk order no longer changes when losing a perk
* All perk machines now make a sound when bumping into them

### Quick Revive
* Decreases health regeneration delay by 25%
* Increases health regeneration rate by 25%
* Increased cost in solo from 500 points to 1500 points
* No longer gives the player a self revive in solo
* No longer automatically powered on in solo
* Hintstring now says "Quick Revive" in solo and coop

### Speed Cola
* Switch weapons twice as fast
* No longer increases board repair speed
* No longer increases Hacker hack speed

### Double Tap
* 1.5x bullet damage (stacks with Deadshot)
* Decreased time between burst fire shots by 25%

### Stamin-Up
* No longer gives 110% sprint speed with any weapon
* Now gives +10% move speed and sprint speed

### PHD Flopper
* Fixed a bug where players took 1 damage when falling without diving

### Deadshot Daiquiri
* Increased cost from 1000 to 1500
* 2x headshot damage (stacks with Double Tap)
* Removed headshot aim assist with controllers

### Mule Kick
* Only available on Call of the Dead, Shangri-La, and Moon
* Fixed not being available when playing offline on every map except for Moon
* Added jingle
* Fixed 3rd person model
* Removed bottom part of machine model
* Additional weapon slot will now always be the correct weapon
* Added the Mule Kick perk icon as an indicator for which weapon is the player's additional weapon
* Lost weapon is given back when perk is rebought (except if it was a limited weapon and another player has it now, the player already has the weapon, the player has the upgraded version of the weapon and the weapon that the player had lost is the unupgraded version of that weapon, or the player bled out)
* Gives ammo back if the player already has the weapon that they had previously lost when perk is rebought

## Powerups
* Decreased initial chance for a powerup to drop from 3% to 2%
* Chance for a powerup to drop now gradually increases when a zombie is killed and doesn't drop a powerup
* Chance for a powerup to drop resets to the initial chance when a powerup drops
* Guaranteed powerup drop within 100 valid kills
* Decreased multiplier added to next guaranteed powerup from points from 14% to 10%
* An effect now plays when a powerup drops if it is the last powerup of a powerup cycle
* Grabbing a powerup that is already active will add to its current remaining time instead of resetting its remaining time
* Powerups allign on the center of the HUD
* Powerups on HUD now fade in and out when they are about to end instead of blinking
* Powerups on the ground now last for 30 seconds (previously 26.5 seconds)
* Powerups will now not be grabbed automatically if dropped near where a player died at
* Powerups that are not initally active are now guaranteed to be added to your current powerup cycle when they become active
* Only normal powerup drops now effect the powerup cycle

### Carpenter
* Removed

### Death Machine
* Switch weapons to end duration
* Increased minimum damage from 300 to 500
* Kills zombies in 4 body shots
* Kills zombies in 2 headshots
* Decreased raise time from 1.55 seconds to 1.1 seconds
* Decreased drop time from .75 seconds to .3 seconds
* Powerup can now spawn while one is already active

### Fire Sale
* Traps cost 10 points
* Traps have no cooldown
* Powerup can now drop while one is already active

### Nuke
* Now obtainable on round 1 on all maps
* Kills all zombies instantly
* Zombies killed from a Nuke count as kills for the player who grabbed the Nuke

### Wunderwaffe (Powerup)
* Now displays lightning bolt model and HUD icon
* Switch weapons to end powerup duration
* Powerup can now drop while one is already active

## Traps
* All trap kills now count as kills for the player who activated the trap
* All traps now kill instantly
* Fixed trap handles being moved to the wrong spot and trap lights staying green if a trap was activated while the trap handle was still moving up
* All trap triggers now display active and cooldown hintstrings
* All traps now take players' points as soon as the trigger is activated
* Fixed traps showing damage FX when player is spectating if the player bled out in a trap and the trap is active
* Fixed a bug where sometimes traps would not kill players

### Electric Traps (All Maps)
* Increased player damage with Jugger-Nog from 16 to 25
* No longer instantly kills players with 100 health or less if they have Jugger-Nog
* Decreased stun duration from 2.5 seconds to 1.5 seconds (now matches the duration of the electricity being on screen)
* Only the trap handle that was activated now moves down

### Electric Traps (Shi No Numa)
* Decreased cooldown time from 90 seconds to 25 seconds (same as Verruckt and Der Riese)
* Trap ready sound plays near the trap (previously played near the Flogger)

### Flogger (Shi No Numa)
* Changed player damage to 100 (previously 25 damage in solo and instantly kills in coop)
* Cannot damage a player again if the player is still touching the Flogger and has already been damaged by the Flogger
* Both triggers are now completely independent of eachother
* One trigger can not be activated if the other trigger is currently active
* Lights and hintstrings now display correctly when activating one trigger while the other trigger is on cooldown

### Turrets (Kino Der Toten and Ascension)
* Added 45 second cooldown
* Increased minimum damage from 250 to 500
* Kills zombies in 4 shots
* Locks on to a new target quicker
* Targets the zombie that is closest to the turret
* Added green light when turret is ready
* Shows hintstring when active
* Nova crawlers now do not explode from turret damage
* No longer deals damage to players

## Blockers

### Doors
* Doors now push any players out that are touching them after they have fully opened
* Fixed a bug where two or more players could trigger a door that has multiple triggers at the same time and both pay to open the door
* Doors that fall down now get deleted after 1 second (previously 60 seconds)

## Barriers
* Increased maximum amount of barrier rebuild points each round by 10
* Can no longer rebuild barriers while sprinting or diving
* Removed limit of 3 zombies being able to traverse over a barrier at once
* Zombies now immediately traverse over a barrier if there are no boards on it (previously would go into position to tear down boards first)
* Fixed a bug where zombies would get stuck in a barrier if a board was repaired as the zombie was beginning to go over the barrier
* Zombies behind a barrier will now only attack if they can see a player
* All wall barriers and metal vent barriers can now be rebuilt
* Glass barriers now start off with glass and wooden boards
* On glass barriers, zombies will now tear down all of the glass first
* Zombies can now attack through all glass barriers, wall barriers, and metal barriers
* Fixed a bug where glass barriers and wall barriers had to be rebuilt twice for the repair to take affect if the barrier was rebuilt right after it got destroyed
* Fixed a bug where glass barriers and wall barriers were destroyed at slightly incorrect times
* Zombies now always use the same animation when tearing down glass barriers
* Zombies now randomly choose between two animations when tearing down wall barriers

## Zombies
* Increased the maximum amount of zombies per round in a 2 player match from slightly less than 2x the amount as solo to exactly 2x the amount as solo
* Decreased the maximum amount of zombies per round in a 3 player match from slightly less than 4x the amount as solo to exactly 3x the amount as solo
* Decreased the maximum amount of zombies per round in a 4 player match from slightly less than 8x the amount as solo to exactly 4x the amount as solo
* Zombies now only have an additonal spawn delay when a full horde is spawned in
* Decreased additional spawn delay time from 1.2 seconds to 1 second
* Added 2 previously unused run animations
* Removed collision from zombies as soon as they are dead
* No longer make sounds after death
* Fixed a bug where zombies would bleed out occasionally if they were standing in the same spot they were 30 seconds ago
* Zombies that are not damaged no longer bleed out from being too far away from players
* Zombies can no longer be headless while alive
* 4 round and 5 round special rounds now happen more equally
* Max health: 1 million
* Decreased damage from 60 to 50
* Fixed a bug that caused ceiling spawns to be able to be disabled
* Fixed a bug that caused spawning zombies to be able to collide with players while they were still invisible to the player
* Zombies can now gib when damaged from the Bowie Knife or Sickle
* Fixed certain zombie swipes that damaged players at incorrect times
* Ceiling spawner zombies now fall from the ceiling quicker
* Ceiling spawner zombies now always play land animation

### Hellhounds
* Initial hellhound round always happens on round 5 or 6
* Flaming hellhounds now deal damage to players who are close to them when they explode
* No longer gain additional points for killing hellhounds with wonder weapons
* Decreased 2nd hellhound round health from 900 to 800
* Decreased 3rd hellhound round health from 1300 to 1200
* Fixed a bug that caused spawning hellhounds to be able to collide with players while they were still invisible to the player

### Nova Crawlers
* The player who killed a Nova Crawler gets the kills for any zombies killed from the explosion of the Nova Crawler
* Now award kill points immediately if killed while crawling on a wall

### Thief
* Initial thief round always happens 1 or 2 rounds after turning on the power
* Health increase per round: 1000
* Max health: 30,000
* Same health no matter how many payers are in the match
* No longer affected by insta kills or nukes
* No longer affected by explosive damage scaling
* Fixed an error that crashed the game if the thief attempted to steal a player's weapon while they were using Pack-a-Punch

### Monkeys (Ascension)
* Initial monkey round always happens 1 or 2 rounds after buying a perk
* Health is now a fixed amount each monkey round (previously was based on what round you were on)
* 1st monkey round health: 150
* 2nd monkey round health: 400
* 3rd monkey round health: 800
* 4th monkey round health: 1200
* 5th monkey round health: 1600
* Decreased maximum health to 1600
* Increased damage done to perks by 5x
* No longer deal 10x damage when a player is near the perk
* Fixed a bug where perks would be lost on monkey rounds when they shouldn't be
* No longer stop attacking perks when damaged by a player
* Grenades thrown back by monkeys will no longer damage the player that threw the grenade if they have PHD Flopper

### Director
* No longer gains additional health for each additional player
* Upgraded assault rifles no longer deal extra damage to the Director
* No longer affected by explosive damage scaling
* Increased damage from 60 to 80
* Always drops Wunderwaffe regardless of whether or not you have completed the sidequest
* Only slows down players close to him when shot at while calm
* Fixed a bug that caused shotgun damage on the Director to only count one pellet of damage per shot
* Fixed a bug that caused the Director to not be able to electrify a player anymore after the player knifed an electrified zombie during an insta kill
* Now only electrifies zombies that are within a certain radius
* No longer plays audio after exiting the map due to being hit by the upgraded V-R11
* Fixed a bug that would sometimes cause the Director to sream in the water after already being killed
* No longer screams in the water if damaged while attacking
* Electrified zombies can drop a Max Ammo from the Director whenever the Director re-enters the map
* Electrified zombies now need to be killed with a valid weapon to drop a Max Ammo from the Director
* Electrified zombies no longer need the power on to drop a Max Ammo from the Director
* Electrified zombies no longer drop a Max Ammo from the Director and a normal powerup at the same time

### Monkeys (Shangri-La)
* Monkeys keep attempting to spawn until successfully spawned during the whole duration while a powerup is active on the ground
* Removed 500 points bonus for killing a monkey that is chasing you
* The powerup that a Monkey picks up no longer has to initially be a Max Ammo for Perk Bottle to be cycled through (still has to be picked up as a Max Ammo)
* Fixed a bug where monkeys would not spawn in certain situations where the max amount of zombies were already spawned in
* Monkey ambient sounds go away once all the powerups currently on the map have been picked up by monkeys
* Fixed a bug where Monkeys would not go after a powerup that spawned at the same time or almost the same time as another powerup
* Monkeys now wait .5 seconds to spawn instead of a random amount between 0 and 1 second
* Grenades thrown back by monkeys will no longer damage the player that threw the grenade if they have PHD Flopper

### Napalm
* Kills from Napalm explosion or flames count for the player who killed the Napalm or the player who triggered the Napalm
* Can be damaged while in the ground
* No longer gains additional health for each additional player
* No longer gives additional points when killed
* No longer affected by explosive damage scaling
* No longer attracted towards Monkey Bombs

### Shrieker
* Decreased health multiplier from 2.5 to 2
* Can be damaged while in the ground
* No longer gains additional health for each additional player
* No longer gives points when damaged
* No longer affected by insta kills
* No longer affected by explosive damage scaling
* No longer attracted towards Monkey Bombs

### Cosmonaut
* Can be damaged by the Zap Gun (unupgraded: 1500 damage, upgraded: 2000 damage)
* Can be killed by the Wave Gun
* No longer affected by explosive damage scaling
* Decreased damage from 60 to 50
* No longer teleports players that activate a jump pad between the time of being grabbed and when they would have been teleported
* Now kills any zombies nearby when Cosmonaut explodes
* Now dies if trapped in a zone due to the excavator being active
* Fixed a bug where the Cosmonaut would get stuck in place if spawned in while a player was on the jump pads
* Fixed a bug where the Cosmonaut would be attracted towards a Gersh Device and move faster than intended after the Pack-a-Punch gates had been hacked

## Maps
* Easter egg songs can now be reactivated once the song is over
* The zone that the player is in is now calculated more accurately
* Added out of bounds death barriers to all maps

### Nacht Der Untoten
* Added Mystery Box light
* Now uses marine characters and voicelines from World at War
* Zombies now spawn in the Help Room zone and the Upstairs zone when in the corner in the Start zone near the Help Room zone door

### Verruckt
* Added Mystery Box light
* Added super-sprinters (only spawn after the power is on, start spawning on round 10, all super-sprinters by round 13)
* Now uses marine characters and voicelines from World at War
* Added Mystery Box locations in the North Balcony zone and the Kitchen zone
* Decreased cost of the door between the North Upstairs zone and the Kitchen zone from 1000 points to 750 points
* Fixed zone issue in the South Balcony zone near the Showers zone door
* Fixed zombie pathing near Speed Cola
* Removed intro text

### Shi No Numa
* Changed Mystery Box light color to blue
* Removed the need power hintstring for perks while they are spawning
* Fixed a bug where players were able to buy Quick Revive on solo while it was still in the process of spawning
* Last perk is buyable while it is spawning
* Objects can now be seen from farther away

#### Zipline
* Decreased cost from 1500 to 750
* Decreased cooldown time from 40 seconds to 15 seconds
* Hintstrings now display when the zipline is active and cooling down
* The zipline trigger near the hut can now be activated when the zipline is on either side

### Der Riese
* Added Mystery Box location in the Mainframe zone
* Zombies now spawn in the Outside Warehouse zone when in the Courtyard zone
* Zombies now spawn in the Bridge Warehouse Side zone when in the Upper Warehouse zone
* Zombies no longer spawn in the Upper Warehouse zone when in the Bridge Warehouse Side zone
* Zombies no longer spawn in the Outside Laboratory zone when in the Teleporter A zone
* Zombies no longer spawn in the Outside Laboratory zone when in the Teleporter C zone
* Increased cost of the door between the Outside Warehouse zone and the Warehouse zone from 750 points to 1000 points
* Increased cost of the door between the Outside Laboratory zone and the Laboratory zone from 750 points to 1000 points
* Increased cost of the debris between the Laboratory zone and the Bridge Laboratory Side zone from 1000 points to 1250 points
* Increased cost of the debris between the Warehouse zone and the Upper Warehouse zone from 1000 points to 1250 points
* Increased cost of the door between the Upper Warehouse zone and the Teleporter B zone from 750 points to 1250 points
* Decreased mid round hellhounds starting round from 16 to 15
* Mid round hellhounds now spawn when no doors are open
* Mid round hellhounds now have the same delay between spawns as zombies
* Players will no longer get stuck on curbs
* Fixed Mystery Box use trigger in the Laboratory
* Easter egg song now plays the whole song
* Removed intro text
* Fixed a bug that caused the Laboratory trap to turn on when opening the door to Teleporter A while still having the trap door closed
* Traps now display a hintstring when the power is on but the trap cannot be activated due to a door being closed
* Fixed a bug where a hellhound round could end prematurely if hellhounds were spawned from the teleporters and killed before the hellhound round started to spawn hellhounds

#### Teleporters
* Teleporters now kill zombies on any round
* Guranteed teleporter powerup when linking each teleporter
* Chance decrease per round of teleporter powerup spawn decreased from 15% to 5%
* Minimum of 15% chance of teleporter powerup spawn
* Hellhounds always spawn whenever a teleporter powerup does not spawn
* Hellhounds will not spawn whenever a teleporter powerup spawns
* Amount of hellhounds spawned in from teleporter is now 2 multiplied by the amount of players (previously always 4)
* Max ammo now has the same chance of spawning from the teleporter as all other drops
* Mainframe no longer displays a hintstring for needing power or needing to activate a link
* Decreased shellshock effect time from 4 seconds to 1.25 seconds
* Vision effect times no longer linked to FPS
* Fixed a bug that allowed players to link teleporters while the teleporters were on cooldown
* Fixed a bug that caused no effect to happen after teleporting

#### Sidequest
* Reward: spawns a random powerup at the teleporter powerup spawn location

### Kino Der Toten
* Upper part of Lobby Hallway zone is now part of Lobby zone
* Players no longer get teleported to special rooms unless both radios on the map have been activated
* Players no longer get teleported out of the Pack-a-Punch room if there is a weapon currently in the Pack-a-Punch machine
* Box lights now blink correctly with higher FPS

#### Teleporter
* Teleporter now kills zombies on any round
* Teleporter light is now green initially after turning on the power
* Teleporter mainframe pad no longer displays the need power hintstring
* Teleporter mainframe pad will now display the link not active hintstring every time the teleporter needs to be linked
* Decreased shellshock effect time from 3 seconds to 1.25 seconds
* Vision effect times no longer linked to FPS
* Fixed a bug that caused no effect to happen after teleporting

### Five
* All 6 barriers in the Conference Room zone are always active
* Zombies no longer spawn in the Quick Reive hallway when in the Hallway zone
* Trap pieces are already in place
* Decreased cost of the 2 debris between the North War Room zone and the South War Room zone from 1250 points to 1000 points
* Pack-a-Punch machine will stay available for as long as the defcon room is active
* If all players on a floor use an elevator or get downed when the power is off, all zombies will now respawn
* If all players on a floor use an elevator or get downed when the power is on, all zombies that were in the map will now go through teleporters and all zombies that were in barriers will now respawn
* Fixed lighting on the top floor being incorrect
* All characters now use the correct viewmodel arms
* Fixed a bug that caused zombies to not go through a trap if the trap was active when a thief round ended
* Fixed a bug that caused the alarms during a thief round to not shut off at the end of a thief round if the thief was killed too quick
* Fixed a bug that caused zombies to start going through the Panic Room portal before the Panic Room door closed

#### Elevators
* Decreased time to be able to use an elevator again after it has stopped from 2.1 seconds to 1.25 seconds
* Hintstring for elevators will now not show up until the elvator becomes usable again

#### Teleporters
* Teleporting no longer takes players' weapons away temporarily
* Teleporting no longer freezes players' controls
* Fixed teleporters showing they were ready to use again too early after teleporting through them
* Player height position is now more accurate when exiting the teleporter
* Added 1 second delay before zombies can come through the teleporter after a player teleports
* Added .1 second delay between zombie teleports to prevent zombies from getting stuck
* Decreased maximum time for zombies to teleport from 20 seconds to 15 seconds
* Fixed a bug that caused no FX or sound to happen when zombies teleported from the Panic Room portal to the War Room portal

### Ascension
* Added Double Tap perk machine in the Outside Launch Area zone
* Zombies no longer spawn in the Stairs zone when in the Centrifuge Zone
* Zombies now spawn in the Stairs zone when in the Upper Centrifuge Zone

#### Centrifuge
* Increased player damage to 100 (previously 16 in solo and 44 in coop)
* Increased maximum cooldown time from 90 seconds to 120 seconds
* No longer stops spinning for entire rounds
* Fixed a bug where zombies that were killed from the Centrifuge in higher rounds became invisible and invincible
* Can damage a player if they are diving or crouching in the air
* Cannot damage a player again if the player is still touching the Centrifuge and has already been damaged by the Centrifuge
* The player that is closest to a zombie that is killed from the Centrifuge gets the kill

#### Lunar Lander
* Decreased cooldown after using the lunar lander from 30 seconds to 15 seconds
* Increased cooldown after calling the lunar lander from 3 seconds to 15 seconds
* Lander station no longer kills or moves players if the lander station moves down while the player is standing on it
* Kills from the lunar lander now count as actual kills
* Zombies now have a better death animation when killed by the lunar lander
* Player who activates the lunar lander is forced to ride the lunar lander

#### Sidequest
* Completable with any amount of players
* Monkey round step: buttons no longer have to be pressed at the same time, only on the same monkey round
* Lunar lander step: first use Centrifuge lander, then use Stamin-Up lander, then use PHD Flopper lander, and last use Speed Cola lander
* Lunar lander step: HITSAM easter egg now only requiers the letters SAM (was not enough room to fit HITSAM)
* Reward: 90 second Death Machines for the rest of the match

### Call of the Dead
* Players now start with Semtex
* Added Mystery Box location in the Ship Stern zone
* Removed zombie spawn delay at the beginning of a match
* Decreased the delay between switching Pack-a-Punch locations from 100-120 seconds to 15 seconds
* Zombies now spawn in the Beach zone when in the Ship Path zone
* Increased cost of the debris between the Lighthouse Cove zone and the Lower Ship Cargo Hold zone from 750 points to 1000 points
* Zombies no longer take damage from the water when low on health
* Fixed a bug where players could occasionally die in the Lighthouse Station Roof zone if they jumped too far off the staircase

#### Flinger
* Zombies flung now count as actual kills
* Available whenever the power is on
* Will not activate if the player is in the air
* Removed explosion effect from flung zombies

#### Zipline
* Always available
* FOV no longer changes while riding the zipline
* Weapon is no longer out while riding the zipline

#### Sidequest
* Steps in solo are now the same as in coop
* Intro voicelines can now be cancelled correctly
* Fuse spawns at the beginning of the match
* Generators' damage hitbox is now more accurate
* Generators can now be damaged by any type of explosive
* Bottle spawns at the beginning of the match
* Bottle is now given to the player who breaks the ice
* No longer have to melee the door after giving the bottle to the crew
* Radio order now resets after a wrong radio is activated
* Sound for inputting the radios in the wrong order now goes off everytime
* Inputting the foghorns in the wrong order no longer makes the players wait a round to try again
* Lighthouse dials can now be rotated faster
* Rotating a lighthouse dial no longer rotates other lighthouse dials
* Human zombie travelling up the light house needs to be damaged for 10000 health (previously 5000 health multiplied the amount of players)
* Reward: upgraded Wunderwaffe from every Wunderwaffe powerup for the rest of the game

### Shangri-La
* Players now start with Semtex
* Pack-a-Punch stones do not have to be stepped on at the same time
* Quick Revive now spawns in randomly with Jugger-Nog and Speed Cola
* Mule Kick now spawns in randomly with Double Tap, PHD Flopper, Stamin-Up, and Deadshot
* Removed Mule Kick perk spawn location in the Waterfall zone
* Added random perk spawn location in the Waterslide Exit zone
* Mystery Box can now start in the Water Wheels zone
* Zombies now spawn in the Minecart Area zone when in the Waterslide Exit zone after the power is on
* Zombies now spawn in the Waterfall Tunnel zone when in the Upper Waterfall zone
* Zombies now spawn in the Waterfall zone when in the upper part of the Waterfall Tunnel zone
* Increased cost of the door between the Waterslide Exit zone and the Turntable zone from 1000 points to 1250 points
* Increased cost of the debris between the Waterfall zone and the Water Cave zone from 1000 points to 1250 points
* Added Pack-a-Punch FX
* Eclipse mode activatable with 1-4 players
* Can activate eclipse mode one more time after sidequest completion to stay in eclipse mode for the rest of the match
* While a weapon is in Pack-a-Punch, players will not be pushed off the stairs
* Zombies killed from the Pack-a-Punch stairs now count as kills and award kills to the player closest to them
* Gongs now move and make a sound when meleed if they have already been meleed recently
* Mud pit walls now only activate when a player is on the ground
* Fixed a bug where players were able to sprint and enter prone in the mud pit if they were drinking a perk while entering the mud pit

#### Spikes
* Now kills zombies (except for Shrieker and Napalm)
* Deal 50 damage to players
* Will not activate if the player is in the air, crouch, prone, or down

#### Waterfall
* Now kills zombies (except for Shrieker and Napalm)
* Now costs 500 points
* Requires the power on to be usable
* Displays a hintstring when active

#### Minecart
* Available whenever the power is on
* Kills from the minecart now count as actual kills
* Travels back up 2x faster
* Player who activates the minecart is forced to ride the minecart

#### Geysers
* Available whenever the power is on

#### Waterslide
* Available whenever the power is on

#### Sidequest
* Completable with any amount of players
* Stepping stones step: stones stay down until a new stone on the same side has been stepped on
* Waterslide step: only 1 player now required
* No longer recompletable in a match
* Melee stones step: Increased melee range for stones
* Mud pit step: radio is no longer required to be played in order to complete
* Fixed a bug where players could clip through the wall behind Pack-a-Punch during the sidequest
* Reward: all players get permanent perks

### Moon
* Players now start with Semtex
* Moved Quick Revive perk machine to Tunnel 6
* Added Mystery Box locations in Tunnel 6 and Tunnel 11
* Added Fire Sale, Max Ammo, and Perk Bottle to jump pad powerup cycle
* Zombies no longer spawn in the Launch Area zone when in the Upper Tunnel 6 zone
* Zombies no longer spawn in the Launch Area zone when in the Upper Tunnel 11 zone
* Zombies no longer spawn in the M.P.D. zone when in the Lower Tunnel 6 zone
* Removed the forced jumping in low gravity
* Excavators will not reactivate for places that have already been breached
* Fixed the invisible digger glitch
* Gersh Devices and QEDs no longer breach windows
* Added line of sight check on explosions for breaching windows
* Fixed bug where players could stay on jump pads in low gravity indefinitely by diving upon landing on them
* Jump pads now fling players correctly when a player dives on a jump pad
* Pack-a-Punch hackable gates are now solid when moving (previously players were able to hack Pack-a-Punch and then escape before the gates closed to get 1000 points)
* Teleporter can be used unlimited times per round
* Teleporting no longer resets the amount of powerups that can be obtained in a round
* Fixed a bug where players would sometimes be moving in a different direction after teleporting
* Fixed a bug where the next round would only have one zombie if players teleported to No Man's Land while the round was changing and the Cosmonaut was spawned in
* Fixed a bug that caused the amount of zombies on round 1 to be the amount of zombies that should be on round 2
* Teleporter gate doesn't start going down until power is on
* When Tunnel 6 or Tunnel 11 are breached from an excavator, the areas with doors closed to the excavator will not get breached until the doors are opened
* Jump pad in Receiving Bay now only pushes players upwards
* Excavator sounds no longer linked to FPS
* Teleporter sounds no longer linked to FPS
* Fixed a bug where the sky would turn bright right after restarting the map
* Removed certain triggers on the map that move players

#### No Man's Land
* Zombies now spawn at a consistent rate
* Increased maximum amount of zombies that can spawn in from 20 to 24
* Increased hellhounds' minimum health from 100 to 150
* Now displays a more accurate time of how long you survived
* Fixed a bug where hellhounds' health was not increased to what their health should be when they initially spawned

#### Sidequest
* Full sidequest completable with any amount of players
* Full sidequest completable without Richtofen
* No longer requires the completion of previous sidequests
* Part 1 reward - 90 second Death Machines for the rest of the match
* Full reward - permanent perks
* Richtofen now does not get the full reward until the end with everyone else
* Pipe is already in place
* QED now does no effect when teleporting objects
* Fixed visual FX when teleporting objects using a Gersh Device

### Dead Ops Arcade
* Fates are now always in the same order (Fate of Fortune - top, Fate of Firepower - right, Fate of Friendship - bottom, Fate of Furious Feet - left)

## Gamemodes

### Survival
* Standard gameplay

### Versus
* Competitive gameplay
* 2 teams or free-for-all
* Power is already on
* No walking zombies
* Shooting enemy players slows them down
* Knifing enemy players pushes them
* Upgraded weapons slow enemy players down more
* Ballistic Knife, Bowie Knife, and Sickle push enemy players farther
* Mines are triggerable by enemy players
* Enemy mines are destroyable
* Added Bonus Points powerup
* Added Meat powerup
* Powerups have negative effects towards the enemy team
* Max Ammo: unloads the clips of all the enemy players' weapons
* Insta Kill: enemy players do half damage to zombies for 30 seconds
* Double Points: enemy players earn half points for 30 seconds
* Nuke: deals 80 damage to enemy players
* Bonus Points: enemy players lose a random amount of points between 500 and 2500 points
* Perk Bottle: enemy players lose a random perk
* Turrets attack players (won't attack the team that activated the turret)
* Players gain 10 points for slowing down a player if the player is below full health
* If a player assisted in getting an enemy player down, the player will gain 5% of the player's points who downed
* When a enemy player bleeds out, players gain 10% of their current points
* Nacht Der Untoten: all doors and debris are open from the start of the match
* Verruckt: BAR door is open from the start of the match
* Shi No Numa: first room door and debris are open from the start of the match
* Der Riese: first room doors are open from the start of the match
* Der Riese: all teleporters are linked
* Der Riese: powerup spawns at the start of each match
* Der Riese: full health hellhounds spawn from every teleporter use
* Kino Der Toten: teleporter is permanently linked to the mainframe
* Five: first room door and debris between upper and lower War Room are open from the start of the match
* Five: Pack-a-Punch door is now a 1500 point buyable door
* Five: teleporters disabled
* Ascension: first room doors, door near MP5K, and door above Juggernog are open from the start of the match
* Ascension: Pack-a-Punch door is now a 2000 point buyable door
* Ascension: rocket launch disabled
* Call of the Dead: director spawns a random powerup instead of a Wunderwaffe
* Shangri-La: Pack-a-Punch stairs are open from the start of the match
* Moon: start at Receiving Bay zone
* Moon: first room doors are open from the start of the match
* Moon: players can always breathe in low gravity
* Moon: PES and hacker disabled
* Moon: No Man's Land disabled
* Moon: teleporter disabled
* Moon: excavators disabled

#### Grief
* Win by surviving a round after all enemy players are dead

#### Search & Rezurrect
* Round based gamemode
* Unlimited zombies
* 2,000 health zombies
* .5 second zombie spawn rate
* Only sprinting zombies
* Every player starts with 10,000 points and will get 5,000 points at the beginning of each new round if they have less than 5,000 points
* Win a round by getting all enemy players down
* Win the game by winning 3 rounds
* Shangri-La: unlimited Napalm and Shrieker zombies can spawn (only one of each can be spawned in at a time)
* Moon: unlimited Cosmonaut zombies can spawn (only one can be spawned in at a time)

#### Race
* Unlimited zombies
* 1 second initial zombie spawn rate
* Auto revive after 10 seoconds
* Starts at round 1, every 30 seconds round increases until round 20
* Team with most kills after round 20 or first team to 500 kills wins
* Shangri-La: unlimited Napalm and Shrieker zombies can spawn (only one of each can be spawned in at a time)
* Moon: unlimited Cosmonaut zombies can spawn (only one can be spawned in at a time)

#### Gun Game
* Unlimited ammo
* Unlimited zombies
* 2,000 health zombies
* 1 second zombie spawn rate
* Only sprinting zombies
* Auto revive after 10 seoconds
* Wall weapons disabled
* Mystery box disabled
* Win the game the game by progressing through all the weapons
* Weapon order: pistols, shotguns, smg's, assault rifles, lmg's, snipers, explosives, wonder weapons, ballistic knife
* Zombies will drop a gun increment powerup after getting 10 kills with your current weapon
* Only the player who killed the zombie can grab and see the gun increment powerup
* Going down will set the player back one weapon
* New powerup: upgrade weapon powerup (for 30 seconds get the upgraded version of any weapon you are currently on)
* Shangri-La: unlimited Napalm and Shrieker zombies can spawn (only one of each can be spawned in at a time)
* Moon: unlimited Cosmonaut zombies can spawn (only one can be spawned in at a time)

## SPECIAL THANKS
* **_ApexModder_** - perk bump sounds, assisted with localized strings, assisted with client scripting, assisted with menu scripting
* **_HitmanVere_** - sprint and dive animations for World at War weapons
* **_lilrifa_** - assisted with menu scripting
* **_MasadaDRM_** - assisted with weapons and sounds
* **_xSanchez78_** - assisted with client scripting and localized strings
* **_Kody_** - Wunderwaffe gold camo, fixed CIA and CDC viewmodels, assisted with animations
* **_UltraZombieDino_** - Black Ops 3 P.E.S. model and animations, Black Ops 3 Gersh Device model, Black Ops 2 Ray Gun first raise and dry fire sounds, World at War marine models, assisted with World at War weapon models
* **_KagamineAddict_** - updated P.E.S. visor texture
* **_Joshwoocool_** - Black Ops 2 grief shock FX and meat FX
* **_Killer Potato_** - Call of Duty: WWII Stielhandgranate HUD icon
* **_Jerri13_** - Black Ops 3 Gersh Device model
* **_KHEL MHO_** - assisted with Springfield chalk model
* **_ZeRoY_** - function list
* **_UGX_** - scripting reference
* **_SE2Dev_** - LinkerMod
* **_Nukem_** - LinkerMod
* **_DTZxPorter_** - Wraith
* **_Treyarch_** - Assets, source code, and an amazing base game