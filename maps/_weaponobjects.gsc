// AE 4-2-10: added this to the workflow, it comes from the same file name in MP, this is a slimmed down version
#include common_scripts\utility;
#include maps\_utility;

init()
{
	level thread onPlayerConnect();

	level.claymoreFXid = LoadFX( "weapon/claymore/fx_claymore_laser" );

	level.watcherWeaponNames = [];
	level.watcherWeaponNames = getWatcherWeapons();
	level.retrievableWeapons = [];
	level.retrievableWeapons = getRetrievableWeapons();
	setup_retrievable_hint_strings();
	
	level.weaponobjectexplodethisframe = false;
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player.usedWeapons = false;
		player.hits = 0;

		player thread onPlayerSpawned();
	}
}

onPlayerSpawned() // self == player
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		self create_base_watchers();

		//Ensure that the watcher name is the weapon name minus _sp if you want to add weapon specific functionality.
		self create_satchel_watcher();
		self create_ied_watcher();

		if ( GetDvar( #"zombiemode" ) == "1" )
		{
			self create_claymore_watcher_zm();
			self create_ballistic_knife_watcher_zm( "knife_ballistic", "knife_ballistic_zm" );
			self create_ballistic_knife_watcher_zm( "knife_ballistic_upgraded", "knife_ballistic_upgraded_zm" );
			self create_ballistic_knife_watcher_zm( "knife_ballistic_bowie", "knife_ballistic_bowie_zm" );
			self create_ballistic_knife_watcher_zm( "knife_ballistic_bowie_upgraded", "knife_ballistic_bowie_upgraded_zm" );
			
			if ( isdefined( level.create_level_specific_weaponobject_watchers ) )
			{
				self [[level.create_level_specific_weaponobject_watchers]]();
			}
		}
		else
		{
			self create_ballistic_knife_watcher();
		}


		//set up retrievable specific fields
		self setup_retrievable_watcher();

		self thread watch_weapon_object_usage();

		if ( GetDvar( #"zombiemode" ) == "1" )
		{
			// zombiemode never gets "death" notifies on players, so none of this stuff ever gets torn down
			// so we don't want to keep starting new sets of it everytime the player respawns
			return;
		}
	}
}

setup_retrievable_hint_strings()
{
	create_retrievable_hint("hatchet", &"WEAPON_HATCHET_PICKUP");
	create_retrievable_hint("satchel_charge", &"WEAPON_SATCHEL_CHARGE_PICKUP");
	create_retrievable_hint("claymore", &"WEAPON_CLAYMORE_PICKUP");
}

create_retrievable_hint(name, hint)
{
	retrieveHint = spawnStruct();

	retrieveHint.name = name;
	retrieveHint.hint = hint;

	level.retrieveHints[name] = retrieveHint;
}

create_base_watchers()
{
	//Check for die on respawn weapons
	for( i = 0; i < level.watcherWeaponNames.size; i++ )
	{
		watcherName = level.watcherWeaponNames[i];
		sub_str = GetSubStr( watcherName, watcherName.size - 3, watcherName.size );
		if(sub_str == "_sp" || sub_str == "_zm" || sub_str == "_mp")
		{
			watcherName = GetSubStr( watcherName, 0, watcherName.size - 3 );// the - 3 removes the _sp from the weapon name
		}

		self create_weapon_object_watcher( watcherName, level.watcherWeaponNames[i], self.team );
	}

	//Check for retrievable weapons
	for( i = 0; i < level.retrievableWeapons.size; i++ )
	{
		watcherName = level.retrievableWeapons[i];
		sub_str = GetSubStr( watcherName, watcherName.size - 3, watcherName.size );
		if(sub_str == "_sp" || sub_str == "_zm" || sub_str == "_mp")
		{
			watcherName = GetSubStr( watcherName, 0, watcherName.size - 3 );// the - 3 removes the _sp from the weapon name
		}

		self create_weapon_object_watcher( watcherName, level.retrievableWeapons[i], self.team );
	}
}

create_claymore_watcher() // self == player
{
	watcher = self create_use_weapon_object_watcher( "claymore", "claymore_sp", self.team );
	watcher.watchForFire = true;
	watcher.detonate = ::weapon_detonate;
	watcher.onSpawnFX = ::on_spawn_claymore_fx;
	watcher.activateSound = "wpn_claymore_alert";

	detectionConeAngle = weapons_get_dvar_int( "scr_weaponobject_coneangle" );
	watcher.detectionDot = cos( detectionConeAngle );
	watcher.detectionMinDist = weapons_get_dvar_int( "scr_weaponobject_mindist" );
	watcher.detectionGracePeriod = weapons_get_dvar( "scr_weaponobject_graceperiod" );
	watcher.detonateRadius = weapons_get_dvar_int( "scr_weaponobject_radius" );
}

create_claymore_watcher_zm() // self == player
{
	watcher = self create_use_weapon_object_watcher( "claymore", "claymore_zm", self.team );
	watcher.pickup = level.pickup_claymores;
	watcher.pickup_trigger_listener = level.pickup_claymores_trigger_listener;
	watcher.skip_weapon_object_damage = true;
}

on_spawn_claymore_fx()
{
	self endon("death");

	while(1)
	{
		self waittill_not_moving();

		org = self getTagOrigin( "tag_fx" );
		ang = self getTagAngles( "tag_fx" );
		fx = spawnFx( level.claymoreFXid, org, anglesToForward( ang ), anglesToUp( ang ) );
		triggerfx( fx );

		self thread clear_fx_on_death( fx );

		originalOrigin = self.origin;

		while(1)
		{
			wait .25;
			if ( self.origin != originalOrigin )
				break;
		}

		fx delete();
	}
}

clear_fx_on_death( fx )
{
	fx endon("death");
	self waittill("death");
	fx delete();
}

create_satchel_watcher() // self == player
{
	watcher = self create_use_weapon_object_watcher( "satchel_charge", "satchel_charge_sp", self.team );
	watcher.altDetonate = true;
	watcher.watchForFire = true;
	watcher.disarmable = true;
	watcher.headIcon = false;
	watcher.detonate = ::weapon_detonate;
	watcher.altWeapon = "satchel_charge_detonator_sp";
}

create_ied_watcher() // self == player
{
	watcher = self create_use_weapon_object_watcher( "ied", "ied_sp", self.team );
	watcher.altDetonate = true;
	watcher.watchForFire = true;
	watcher.disarmable = false;
	watcher.headIcon = false;
	watcher.detonate = ::weapon_detonate;
	watcher.altWeapon = "satchel_charge_detonator_sp"; //could be changed to ied specific detonator
}

create_ballistic_knife_watcher() // self == player
{
	watcher = self create_use_weapon_object_watcher( "knife_ballistic", "knife_ballistic_sp", self.team );
	watcher.onSpawn = maps\_ballistic_knife::on_spawn;
	watcher.onSpawnRetrieveTriggers = maps\_ballistic_knife::on_spawn_retrieve_trigger;
	watcher.storeDifferentObject = true;
}

create_ballistic_knife_watcher_zm( name, weapon ) // self == player
{
	watcher = self create_use_weapon_object_watcher( name, weapon, self.team );
	watcher.onSpawn = maps\_ballistic_knife::on_spawn;
	watcher.onSpawnRetrieveTriggers = maps\_ballistic_knife::on_spawn_retrieve_trigger;
	watcher.storeDifferentObject = true;

	self notify( "zmb_lost_knife" );
}

create_use_weapon_object_watcher( name, weapon, ownerTeam )
{
	weaponObjectWatcher = create_weapon_object_watcher( name, weapon, ownerTeam );

	return weaponObjectWatcher;
}

weapon_detonate(attacker)
{
	if ( IsDefined( attacker ) )
	{
		self Detonate( attacker );
	}
	else
	{
		self Detonate();
	}
}

create_weapon_object_watcher( name, weapon, ownerTeam )
{
	if ( !IsDefined(self.weaponObjectWatcherArray) )
	{
		self.weaponObjectWatcherArray = [];
	}

	weaponObjectWatcher = get_weapon_object_watcher( name );

	if ( !IsDefined( weaponObjectWatcher ) )
	{ 
		weaponObjectWatcher = SpawnStruct();
		self.weaponObjectWatcherArray[self.weaponObjectWatcherArray.size] = weaponObjectWatcher;
	}

	if ( GetDvar( #"scr_deleteexplosivesonspawn") == "" )
		setdvar("scr_deleteexplosivesonspawn", "1");
	if ( GetDvarInt( #"scr_deleteexplosivesonspawn") == 1 )
	{
		weaponObjectWatcher delete_weapon_object_array();
	}

	if ( !IsDefined( weaponObjectWatcher.objectArray ) )
		weaponObjectWatcher.objectArray = [];

	weaponObjectWatcher.name = name;
	weaponObjectWatcher.ownerTeam = ownerTeam;
	weaponObjectWatcher.type = "use";
	weaponObjectWatcher.weapon = weapon;
	weaponObjectWatcher.watchForFire = false;
	weaponObjectWatcher.disarmable = false;
	weaponObjectWatcher.altDetonate = false;
	weaponObjectWatcher.detectable = true;
	weaponObjectWatcher.headIcon = true;
	weaponObjectWatcher.activateSound = undefined;
	weaponObjectWatcher.altWeapon = undefined;

	// calbacks
	weaponObjectWatcher.onSpawn = undefined;
	weaponObjectWatcher.onSpawnFX = undefined;
	weaponObjectWatcher.onSpawnRetrieveTriggers = undefined;
	weaponObjectWatcher.onDetonated = undefined;
	weaponObjectWatcher.detonate = undefined;

	return weaponObjectWatcher;
}

setup_retrievable_watcher()
{
	//Check for retrievable weapons
	for( i = 0; i < level.retrievableWeapons.size; i++ )
	{
		watcher = get_weapon_object_watcher_by_weapon( level.retrievableWeapons[i] );

		if( !isDefined( watcher.onSpawnRetrieveTriggers ) )
			watcher.onSpawnRetrieveTriggers = ::on_spawn_retrievable_weapon_object;

		if( !isDefined( watcher.pickUp ) )
			watcher.pickUp = ::pick_up;
	}
}

watch_weapon_object_usage() // self == player
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( !IsDefined(self.weaponObjectWatcherArray) )
	{
		self.weaponObjectWatcherArray = [];
	}

	self thread watch_weapon_object_spawn();
	self thread watch_weapon_projectile_object_spawn();
	self thread watch_weapon_object_detonation();
	self thread watch_weapon_object_alt_detonation();
	self thread watch_weapon_object_alt_detonate();
	self thread delete_weapon_objects_on_disconnect();
}

// check for grenade type weapon objects spawning
watch_weapon_object_spawn() // self == player
{
	self endon( "disconnect" );
	self endon( "death" );

	while(1)
	{
		self waittill( "grenade_fire", weapon, weapname );

		watcher = get_weapon_object_watcher_by_weapon( weapname );
		if ( IsDefined(watcher) )
		{
			self add_weapon_object(watcher, weapon);
		}
	}
}

// check for projectile type weapon objects spawning
watch_weapon_projectile_object_spawn() // self == player
{
	self endon( "disconnect" );
	self endon( "death" );

	while(1)
	{
		self waittill( "missile_fire", weapon, weapname );

		watcher = get_weapon_object_watcher_by_weapon( weapname );
		if ( IsDefined(watcher) )
		{
			self add_weapon_object(watcher, weapon);
		}
	}
}

watch_weapon_object_detonation() // self == player
{
	self endon("death");
	self endon("disconnect");

	while(1)
	{
		self waittill( "detonate" );

		weap = self GetCurrentWeapon();
		watcher = get_weapon_object_watcher_by_weapon( weap );
		if ( IsDefined( watcher ) )
		{
			watcher detonate_weapon_object_array();
		}
	}
}

watch_weapon_object_alt_detonation() // self == player
{
	self endon("death");
	self endon("disconnect");
	self endon("no_alt_detonate");

	while(1)
	{
		self waittill( "alt_detonate" );

		for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
		{
			if ( self.weaponObjectWatcherArray[watcher].altDetonate )
			{
				self.weaponObjectWatcherArray[watcher] detonate_weapon_object_array();
			}
		}
	}
}

watch_weapon_object_alt_detonate() // self == player
{
	self endon("death");
	self endon( "disconnect" );	
	self endon( "detonated" );
	level endon( "game_ended" );
	self endon("no_alt_detonate");

	for ( ;; )
	{
		self waittill( "action_notify_use_doubletap" );
		self notify ( "alt_detonate" );
	}
}

delete_weapon_objects_on_disconnect() // self == player
{
	self endon("death");
	self waittill("disconnect");

	if ( !IsDefined(self.weaponObjectWatcherArray) )
		return;

	watchers = [];

	// make a psudo copy of the watchers out of the player 
	// so that when the player ent gets cleaned we still have
	// the object arrays to clean up
	for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
	{
		weaponObjectWatcher = SpawnStruct();
		watchers[watchers.size] = weaponObjectWatcher;
		weaponObjectWatcher.objectArray = [];

		if ( IsDefined(  self.weaponObjectWatcherArray[watcher].objectArray ) )
		{
			weaponObjectWatcher.objectArray =  self.weaponObjectWatcherArray[watcher].objectArray;
		}
	}

	wait .05;

	for ( watcher = 0; watcher < watchers.size; watcher++ )
	{
		watchers[watcher] delete_weapon_object_array();
	}
}

on_spawn_retrievable_weapon_object( watcher, player )
{
	self endon( "death" );

	self SetOwner( player );
	self.owner = player;

	self waittill_not_moving();

	self.pickUpTrigger = Spawn( "trigger_radius_use", self.origin, 0, 64, 64 );
	self.pickUpTrigger SetCursorHint( "HINT_NOICON" );

	if( isDefined(level.retrieveHints[watcher.name]) )
		self.pickUpTrigger SetHintString( level.retrieveHints[watcher.name].hint );
	else
		self.pickUpTrigger SetHintString( &"WEAPON_GENERIC_PICKUP" );

	player ClientClaimTrigger( self.pickUpTrigger );
	self.pickupTrigger enablelinkto();
	self.pickupTrigger linkto( self );
	thread watch_use_trigger( self.pickUpTrigger, watcher.pickUp );
	
	if ( isDefined( watcher.pickup_trigger_listener ) )
	{
		self thread [[watcher.pickup_trigger_listener]]( self.pickUpTrigger, player );
	}

	self thread watch_shutdown( player );
}

//print_origin()
//{
//	while(1)
//	{
//		Print3d(self.origin + (0, 0, 20), "origin");
//		wait(0.05);
//	}
//}

//
// utility type functions
//

// returns dvar value in int
weapons_get_dvar_int( dvar, def )
{
	return int( weapons_get_dvar( dvar, def ) );
}

// dvar set/fetch/check
weapons_get_dvar( dvar, def )
{
	if ( getdvar( dvar ) != "" )
	{
		return GetDvarFloat( dvar );
	}
	else
	{
		SetDvar( dvar, def );
		return def;
	}
}

get_weapon_object_watcher( name )
{
	if ( !IsDefined(self.weaponObjectWatcherArray) )
	{
		return undefined;
	}

	for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
	{
		if ( self.weaponObjectWatcherArray[watcher].name == name )
		{
			return self.weaponObjectWatcherArray[watcher];
		}
	}

	return undefined;
}

get_weapon_object_watcher_by_weapon( weapon )
{
	if ( !IsDefined(self.weaponObjectWatcherArray) )
	{
		return undefined;
	}

	for ( watcher = 0; watcher < self.weaponObjectWatcherArray.size; watcher++ )
	{
		if ( IsDefined(self.weaponObjectWatcherArray[watcher].weapon) && self.weaponObjectWatcherArray[watcher].weapon == weapon )
		{
			return self.weaponObjectWatcherArray[watcher];
		}
		if ( IsDefined(self.weaponObjectWatcherArray[watcher].weapon) && IsDefined(self.weaponObjectWatcherArray[watcher].altWeapon) && self.weaponObjectWatcherArray[watcher].altWeapon == weapon )
		{
			return self.weaponObjectWatcherArray[watcher];
		}
	}

	return undefined;
}

pick_up()
{
	player = self.owner;
	self destroy_ent();
	
	clip_ammo = player GetWeaponAmmoClip( self.name );
	clip_max_ammo = WeaponClipSize( self.name );
	if( clip_ammo < clip_max_ammo )
	{
		clip_ammo++;
	}
	player SetWeaponAmmoClip( self.name, clip_ammo );
}

destroy_ent()
{
	self delete();
}

add_weapon_object(watcher, weapon)
{
	watcher.objectArray[watcher.objectArray.size] = weapon;
	weapon.owner = self;
	weapon.detonated = false;
	weapon.name = watcher.weapon;
	
	if ( !is_true( watcher.skip_weapon_object_damage ) )
	{
		weapon thread weapon_object_damage(watcher);
	}
	
	weapon.owner notify ("weapon_object_placed",weapon);


	if ( IsDefined(watcher.onSpawn) )
		weapon thread [[watcher.onSpawn]](watcher, self);

	if ( IsDefined(watcher.onSpawnFX) )
		weapon thread [[watcher.onSpawnFX]]();

	if( isDefined(watcher.onSpawnRetrieveTriggers) )
		weapon thread [[watcher.onSpawnRetrieveTriggers]](watcher, self);

	// refresh the hud as if we just fired
	RefreshHudAmmoCounter();
}

detonate_weapon_object_array() 
{
	if ( isDefined( self.disableDetonation ) && self.disableDetonation )
		return;

	if ( IsDefined(self.objectArray) ) 
	{
		for ( i = 0; i < self.objectArray.size; i++ )
		{
			if ( isdefined(self.objectArray[i]) )
				self thread wait_and_detonate( self.objectArray[i], 0.1 );
		}
	}

	self.objectArray = [];
}

delete_weapon_object_array() 
{
	if ( IsDefined(self.objectArray) ) 
	{
		for ( i = 0; i < self.objectArray.size; i++ )
		{
			if ( isdefined(self.objectArray[i]) )
				self.objectArray[i] delete();
		}
	}

	self.objectArray = [];
}

watch_use_trigger( trigger, callback )
{
	self endon( "delete" );
	self endon( "death" );
	self endon("pickUpTrigger_death");

	while ( true )
	{
		trigger waittill( "trigger", player );

		if ( !IsAlive( player ) )
			continue;

		if ( !player IsOnGround() )
			continue;

		if ( IsDefined( trigger.triggerTeam ) && ( player.pers["team"] != trigger.triggerTeam ) )
			continue;

		if ( IsDefined( trigger.claimedBy ) && ( player != trigger.claimedBy ) )
			continue;

		if ( player UseButtonPressed() )
			self thread [[callback]]();
	}
}

watch_shutdown( player )
{
	player endon( "disconnect" );

	pickUpTrigger = self.pickUpTrigger;

	self waittill_any( "death", "pickUpTrigger_death" );

	pickUpTrigger delete();
}

weapon_object_damage( watcher ) // self == weapon object
{
	self endon( "death" );

	self setcandamage(true);
	self.health = 100000;

	attacker = undefined;

	while(1)
	{
		self waittill ( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags );
		if ( !isDefined(self.allowAIToAttack) )
		{
			if ( !IsPlayer(attacker) )
				continue;
		}

		// special grenades, should disable for a short time
		if ( damage < 5 ) 
		{
			if ( isdefined( watcher.specialGrenadeDisabledTime ) )
			{
				self thread disabled_by_special_grenade( watcher.specialGrenadeDisabledTime ); 
			}
			continue;
		}

		break;
	}

	if ( level.weaponobjectexplodethisframe )
		wait .1 + randomfloat(.4);
	else
		wait .05;

	if (!IsDefined(self))
		return;

	level.weaponobjectexplodethisframe = true;

	thread reset_weapon_object_explode_this_frame();

	if ( IsDefined( type ) && (IsSubStr( type, "MOD_GRENADE_SPLASH" ) || IsSubStr( type, "MOD_GRENADE" ) || IsSubStr( type, "MOD_EXPLOSIVE" )) )
		self.wasChained = true;

	if ( IsDefined( iDFlags ) && (iDFlags & level.iDFLAGS_PENETRATION) )
		self.wasDamagedFromBulletPenetration = true;

	self.wasDamaged = true;

	watcher thread wait_and_detonate( self, 0.0, attacker );
	// won't get here; got death notify.
}

wait_and_detonate( object, delay, attacker )
{
	object endon("death");

	if ( delay )
		wait ( delay );

	// no double detonations
	if ( object.detonated )
		return;

	if( !IsDefined(self.detonate) )
		return;

	object.detonated = true;
	object notify("detonated");
	object [[self.detonate]](attacker);
}

disabled_by_special_grenade( disableTime )
{
	self notify ( "damagedBySpecial" );
	self endon	( "damagedBySpecial" );
	self endon	( "death" );

	self.disabledBySpecial = true;
	wait ( disableTime );
	self.disabledBySpecial = false;
}

reset_weapon_object_explode_this_frame()
{
	wait .05;
	level.weaponobjectexplodethisframe = false;
}