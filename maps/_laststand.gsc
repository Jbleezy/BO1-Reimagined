#include maps\_utility;
#include maps\_hud_util;

init()
{
	if (level.script=="frontend")
		return ;

	PrecacheItem( "syrette_sp" );
	//PrecacheItem( "colt_dirty_harry" );
	precachestring( &"GAME_BUTTON_TO_REVIVE_PLAYER" );
	precachestring( &"GAME_PLAYER_NEEDS_TO_BE_REVIVED" );
	precachestring( &"GAME_PLAYER_IS_REVIVING_YOU" );
	precachestring( &"GAME_REVIVING" );

	if( !IsDefined( level.laststandpistol ) )
	{
		level.laststandpistol = "m1911";
		PrecacheItem( level.laststandpistol );
	}

	//CODER_MOD: TOMMYK 07/13/2008 - Revive text
	if( !arcadeMode() )
	{
		level thread revive_hud_think();
	}

	level.primaryProgressBarX = 0;
	level.primaryProgressBarY = 110;
	level.primaryProgressBarHeight = 4;
	level.primaryProgressBarWidth = 120;

	if ( IsSplitScreen() )
	{
		level.primaryProgressBarY = 280;
	}

	if( GetDvar( #"revive_trigger_radius" ) == "" )
	{
		SetDvar( "revive_trigger_radius", "40" );
	}
}


player_is_in_laststand()
{
	return ( IsDefined( self.revivetrigger ) );
}


player_num_in_laststand()
{
	num = 0;
	players = get_players();

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] player_is_in_laststand() )
		{
			num++;
		}
	}

	return num;
}


player_all_players_in_laststand()
{
	return ( player_num_in_laststand() == get_players().size );
}


player_any_player_in_laststand()
{
	return ( player_num_in_laststand() > 0 );
}


PlayerLastStand( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if( GetDvar( #"zombiemode" ) != "1" && sMeansOfDeath == "MOD_CRUSH" ) // if getting run over by a tank then kill the guy even if in laststand
	{
		if( self player_is_in_laststand() )
		{
			self mission_failed_during_laststand( self );
		}
		return;
	}

	if( self player_is_in_laststand() )
	{
		return;
	}

	//CODER_MOD: TOMMYK 06/26/2008 - For coop scoreboards
	self.downs++;
	//stat tracking
	self.stats["downs"] = self.downs;
	dvarName = "player" + self GetEntityNumber() + "downs";
	setdvar( dvarName, self.downs );

	//PI CHANGE: player shouldn't be able to jump while in last stand mode (only was a problem in water) - specifically disallow this
	self AllowJump(false);
	self AllowLean(false);
	//END PI CHANGE

	if( IsDefined( level.playerlaststand_func ) )
	{
		[[level.playerlaststand_func]]( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration );
	}

	//CODER_MOD: Jay (6/18/2008): callback to challenge system
	// removing coop challenges for now MGORDON
	// maps\_challenges_coop::doMissionCallback( "playerDied", self );

	if ( !laststand_allowed( sWeapon, sMeansOfDeath, sHitLoc ) )
	{
		self mission_failed_during_laststand( self );
		return;
	}

	// check for all players being in last stand
	if ( player_all_players_in_laststand() )
	{
		self mission_failed_during_laststand( self );
		return;
	}

	// vision set
	if ( GetDvar( #"zombiemode" ) == "1" )
	{
		self VisionSetLastStand( "zombie_last_stand", 1 );
	}
	else
	{
		self VisionSetLastStand( "laststand", 1 );
	}

	if(IsDefined(self._retain_perks))
	{
		self.health = 250;
	}
	else
	{
		self.health = 100;
	}

	//self thread call_overloaded_func( "maps\_arcademode", "arcademode_player_laststand" );

	// revive trigger
	self revive_trigger_spawn();

	// laststand weapons
	self laststand_disable_player_weapons();
	self laststand_give_pistol();

	// AI
	self.ignoreme = true;

	// bleed out timer
	self thread laststand_bleedout( GetDvarFloat( #"player_lastStandBleedoutTime" ) );

	self notify( "player_downed" );
	self thread refire_player_downed();
}

refire_player_downed()
{
	self endon("player_revived");
	self endon("death");
	wait(1.0);
	if(self.num_perks)
	{
		self notify("player_downed");
	}

}

laststand_allowed( sWeapon, sMeansOfDeath, sHitLoc )
{
	//MOD TK, loads of stuff will now send u into laststand
	if (   GetDvar( #"zombiemode" ) != "1"
		&& sMeansOfDeath != "MOD_PISTOL_BULLET"
		&& sMeansOfDeath != "MOD_RIFLE_BULLET"
		&& sMeansOfDeath != "MOD_HEAD_SHOT"
		&& sMeansOfDeath != "MOD_MELEE"
		&& sMeansOfDeath != "MOD_BAYONET"
		&& sMeansOfDeath != "MOD_GRENADE"
		&& sMeansOfDeath != "MOD_GRENADE_SPLASH"
		&& sMeansOfDeath != "MOD_PROJECTILE"
		&& sMeansOfDeath != "MOD_PROJECTILE_SPLASH"
		&& sMeansOfDeath != "MOD_EXPLOSIVE"
		&& sMeansOfDeath != "MOD_BURNED")
	{
		return false;
	}

	if( level.laststandpistol == "none" )
	{
		return false;
	}

	return true;
}


// self = a player
laststand_disable_player_weapons()
{
	weaponInventory = self GetWeaponsList();
	self.lastActiveWeapon = self GetCurrentWeapon();
	self SetLastStandPrevWeap( self.lastActiveWeapon );
	self.laststandpistol = undefined;

	//ASSERTEX( self.lastActiveWeapon != "none", "Last active weapon is 'none,' an unexpected result." );

	self.hadpistol = false;

	if ( isdefined( self.weapon_taken_by_losing_specialty_additionalprimaryweapon ) && self.lastActiveWeapon == self.weapon_taken_by_losing_specialty_additionalprimaryweapon )
	{
		self.lastActiveWeapon = "none";
		self.weapon_taken_by_losing_specialty_additionalprimaryweapon = undefined;
	}

	for( i = 0; i < weaponInventory.size; i++ )
	{
		weapon = weaponInventory[i];

		if ( WeaponClass( weapon ) == "pistol" && !IsDefined( self.laststandpistol ) )
		{
			self.laststandpistol = weapon;
			self.hadpistol = true;

		}

		switch( weapon )
		{
			// this player was killed while reviving another player
		case "syrette_sp":
		// player was killed drinking perks-a-cola
		case "zombie_perk_bottle_doubletap":
		case "zombie_perk_bottle_revive":
		case "zombie_perk_bottle_jugg":
		case "zombie_perk_bottle_sleight":
		case "zombie_perk_bottle_marathon":
		case "zombie_perk_bottle_nuke":
		case "zombie_perk_bottle_deadshot":
		case "zombie_perk_bottle_additionalprimaryweapon":
			self TakeWeapon( weapon );
			self.lastActiveWeapon = "none";
			continue;
		}
	}

	if( IsDefined( self.hadpistol ) && self.hadpistol == true && IsDefined( level.zombie_last_stand_pistol_memory ) )
	{
		self [ [ level.zombie_last_stand_pistol_memory ] ]();
	}


	if ( !IsDefined( self.laststandpistol ) )
	{
		self.laststandpistol = level.laststandpistol;
	}

	self DisableWeaponCycling();

	if( GetDvar( #"zombiemode" ) != "1" )
	{
		self DisableOffhandWeapons();
	}


}


// self = a player
laststand_enable_player_weapons()
{
	if ( !self.hadpistol )
	{
		self TakeWeapon( self.laststandpistol );
	}

	if( IsDefined( self.hadpistol ) && self.hadpistol == true && IsDefined( level.zombie_last_stand_ammo_return ) )
	{
		[ [ level.zombie_last_stand_ammo_return ] ]();
	}

	self EnableWeaponCycling();
	self EnableOffhandWeapons();

	// if we can't figure out what the last active weapon was, try to switch a primary weapon
	//CHRIS_P: - don't try to give the player back the mortar_round weapon ( this is if the player killed himself with a mortar round)
	if( self.lastActiveWeapon != "none" && self.lastActiveWeapon != "mortar_round" && self.lastActiveWeapon != "mine_bouncing_betty" && self.lastActiveWeapon != "claymore_zm" && self.lastActiveWeapon != "spikemore_zm" )
	{
		self SwitchToWeapon( self.lastActiveWeapon );
	}
	else
	{
		primaryWeapons = self GetWeaponsListPrimaries();
		if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
	}
}

laststand_clean_up_on_disconnect( playerBeingRevived, reviverGun )
{
	reviveTrigger = playerBeingRevived.revivetrigger;

	playerBeingRevived waittill("disconnect");

	if( isdefined( reviveTrigger ) )
	{
		reviveTrigger delete();
	}

	if( isdefined( self.reviveProgressBar ) )
	{
		self.reviveProgressBar destroyElem();
	}

	if( isdefined( self.reviveTextHud ) )
	{
		self.reviveTextHud destroy();
	}

	self revive_give_back_weapons( reviverGun );
}

laststand_give_pistol()
{
	assert( IsDefined( self.laststandpistol ) );
	assert( self.laststandpistol != "none" );
	//assert( WeaponClass( self.laststandpistol ) == "pistol" );

	if( IsDefined( level.zombie_last_stand  ) )// CODER_MOD (Austin 5/4/08): zombiemode loadout setup GetDvar( #"zombiemode" ) == "1" || IsSubStr( level.script, "nazi_zombie_" )
	{
		[ [ level.zombie_last_stand ] ](); // SCRIPT MOD (Walter 08-02-10): moved zombie scripts in to zombie files.

		/*
		self GiveWeapon( self.laststandpistol );
		ammoclip = WeaponClipSize( self.laststandpistol );

		if (self.laststandpistol == "ray_gun_zm")
		{
			self SetWeaponAmmoClip( self.laststandpistol, ammoclip );
			self SetWeaponAmmoStock( self.laststandpistol, 0 );

		}
		else
		{
			self SetWeaponAmmoStock( self.laststandpistol, ammoclip * 2 );
		}

		//self GiveWeapon( "knife_zm" );
		self SwitchToWeapon( self.laststandpistol );
		*/
	}
	else
	{
		self GiveWeapon( self.laststandpistol );
		self GiveMaxAmmo( self.laststandpistol );
		self SwitchToWeapon( self.laststandpistol );
	}


}


Laststand_Bleedout( delay )
{
	self endon ("player_revived");
	self endon ("disconnect");

	//self PlayLoopSound("heart_beat",delay);	// happens on client now DSL

	// Notify client that we're in last stand.

	setClientSysState("lsm", "1", self);

	self.bleedout_time = delay;

	while ( self.bleedout_time > Int( delay * 0.5 ) )
	{
		self.bleedout_time -= .5;
		wait( .5 );
	}

	if ( GetDvar( #"zombiemode" ) == "1" )
	{
		self VisionSetLastStand( "zombie_death", delay * 0.5 );
	}
	else
	{
		self VisionSetLastStand( "death", delay * 0.5 );
	}

	while ( self.bleedout_time > 0 )
	{
		self.bleedout_time -= .5;
		wait( .5 );
	}

	//CODER_MOD: TOMMYK 07/13/2008
	while( self.revivetrigger.beingRevived == 1 )
	{
		wait( 0.1 );
	}

	self notify("bled_out");
	wait_network_frame(); //to guarantee the notify gets sent and processed before the rest of this script continues to turn the guy into a spectator

	setClientSysState("lsm", "0", self);	// Notify client last stand ended.

	level notify("bleed_out", self GetEntityNumber());

	if (isdefined(level.is_zombie_level ) && level.is_zombie_level)
	{
		self [[level.player_becomes_zombie]]();
	}
	else if (isdefined(level.is_specops_level ) && level.is_specops_level)
	{
		self thread [[level.spawnSpectator]]();
	}
	else
	{
		self.ignoreme = false;
		self mission_failed_during_laststand( self );
	}
}


// spawns the trigger used for the player to get revived
revive_trigger_spawn()
{
	radius = GetDvarInt( #"revive_trigger_radius" );

	self.revivetrigger = spawn( "trigger_radius", self.origin, 0, radius, radius );
	//self.revivetrigger setHintString( "" ); // only show the hint string if the triggerer is facing me
	self.revivetrigger setHintString( &"GAME_BUTTON_TO_REVIVE_PLAYER" );
	self.revivetrigger setCursorHint( "HINT_NOICON" );

	self.revivetrigger EnableLinkTo();
	self.revivetrigger LinkTo( self );

	//CODER_MOD: TOMMYK 07/13/2008 - Revive text
	self.revivetrigger.beingRevived = 0;
	self.revivetrigger.createtime = gettime();

	self thread revive_trigger_think();

	//self.revivetrigger thread revive_debug();
}

// logic for the revive trigger
revive_trigger_think()
{
	self endon ( "disconnect" );
	self endon ( "zombified" );
	self endon ( "stop_revive_trigger" );

	while ( 1 )
	{
		//assert( DistanceSquared( self.origin, self.revivetrigger.origin ) <= 25 );
		//drawcylinder( self.revivetrigger.origin, 32, 32 );

		players = get_players();

		//self.revivetrigger setHintString( "" );

		for ( i = 0; i < players.size; i++ )
		{
			//PI CHANGES - revive should work in deep water for nazi_zombie_sumpf
			d = 0;
			d = self depthinwater();

			if(level.gamemode != "survival" && players[i].vsteam != self.vsteam)
			{
				self.revivetrigger SetInvisibleToPlayer( players[i], true );
			}
			else if ( players[i] can_revive( self ) || d > 20)
			//END PI CHANGES
			{
				// TODO: This will turn on the trigger hint for every player within
				// the radius once one of them faces the revivee, even if the others
				// are facing away. Either we have to display the hints manually here
				// (making sure to prioritize against any other hints from nearby objects),
				// or we need a new combined radius+lookat trigger type.
				//self.revivetrigger setHintString( &"GAME_BUTTON_TO_REVIVE_PLAYER" );
				//break;
				self.revivetrigger SetInvisibleToPlayer( players[i], false );
			}
			else
			{
				self.revivetrigger SetInvisibleToPlayer( players[i], true );
			}
		}

		for ( i = 0; i < players.size; i++ )
		{
			reviver = players[i];

			if ( !reviver is_reviving( self ) )
			{
				continue;
			}

			// give the syrette
			gun = reviver GetCurrentWeapon();
			assert( IsDefined( gun ) );
			//assert( gun != "none" );
			if ( gun == "syrette_sp" )
			{
				//already reviving somebody
				continue;
			}

			reviver GiveWeapon( "syrette_sp" );
			reviver SwitchToWeapon( "syrette_sp" );
			reviver SetWeaponAmmoStock( "syrette_sp", 1 );

			reviver thread wait_for_weapon_switch();

			//CODER_MOD: TOMMY K
			revive_success = reviver revive_do_revive( self, gun );

			reviver revive_give_back_weapons( gun );

			//PI CHANGE: player couldn't jump - allow this again now that they are revived
			self AllowJump(true);
			self AllowLean(true);
			//END PI CHANGE

			if ( revive_success )
			{
				self thread revive_success( reviver );
				return;
			}
			else
			{
				break;
			}
		}

		self notify("update_revive_waypoint");

		wait ( 0.05 );
	}
}

//wait until switched weapon to know player fully has syrette so we know for sure to switch weapons or not in revive_give_back_weapons()
wait_for_weapon_switch()
{
	self endon("taking_syrette");

	self.switched_to_syrette = false;

	while(1)
	{
		wait_network_frame();

		if(self GetCurrentWeapon() == "syrette_sp")
			break;

		if(!self IsSwitchingWeapons())
			break;
	}

	self.switched_to_syrette = true;
}

revive_give_back_weapons( gun )
{
	self notify("taking_syrette");

	syrette_in_hand = false;
	if(self GetCurrentWeapon() == "syrette_sp" || !self.switched_to_syrette)
	{
		syrette_in_hand = true;
	}

	// take the syrette
	self TakeWeapon( "syrette_sp" );

	// Don't switch to their old primary weapon if they got put into last stand while trying to revive a teammate
	if ( self player_is_in_laststand() )
	{
		return;
	}

	if(syrette_in_hand)
	{
		if ( gun != "none" && gun != "equip_gasmask_zm" && gun != "lower_equip_gasmask_zm" && self HasWeapon( gun ) ) // gun != "mine_bouncing_betty" && gun != "claymore_zm" && gun != "spikemore_zm" &&
		{
			self SwitchToWeapon( gun );
		}
		else
		{
			// try to switch to first primary weapon
			primaryWeapons = self GetWeaponsListPrimaries();
			if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
			{
				self SwitchToWeapon( primaryWeapons[0] );
			}
		}
	}
}

can_revive( revivee )
{
	if ( !isAlive( self ) )
	{
		return false;
	}

	if ( self player_is_in_laststand() )
	{
		return false;
	}

	if( self.sessionstate == "spectator" )
	{
		return false;
	}

	if(IsDefined(self.current_equipment_active) && IsDefined(self.current_equipment_active["equip_hacker_zm"]) && self.current_equipment_active["equip_hacker_zm"])
	{
		return false;
	}

	if( !isDefined( revivee.revivetrigger ) )
	{
		return false;
	}

	if ( !self IsTouching( revivee.revivetrigger ) )
	{
		return false;
	}

	if(level.gamemode != "survival" && revivee.vsteam != self.vsteam)
	{
		return false;
	}

	//PI CHANGE: can revive in deep water in sumpf
	if (revivee depthinwater() > 10)
	{
		return true;
	}
	//END PI CHANGE

	if ( !self is_facing( revivee ) )
	{
		return false;
	}

	if( !SightTracePassed( self.origin + ( 0, 0, 50 ), revivee.origin + ( 0, 0, 30 ), false, undefined ) )
	{
		return false;
	}

	//chrisp - fix issue where guys can sometimes revive thru a wall
	if(!bullettracepassed(self.origin + (0,0,50), revivee.origin + ( 0, 0, 30 ), false, undefined) )
	{
		return false;
	}

	// SRS 9/2/2008: in zombie mode, disallow revive if potential reviver is a zombie
	if( IsDefined( level.is_zombie_level ) && level.is_zombie_level )
	{
		if( IsDefined( self.is_zombie ) && self.is_zombie )
		{
			return false;
		}
		if( isDefined( level.can_revive ) )
		{
			return [[level.can_revive]]( revivee );
		}
	}

	return true;
}

is_reviving( revivee )
{
	return ( can_revive( revivee ) && self UseButtonPressed() );
}

is_facing( facee )
{
	orientation = self getPlayerAngles();
	forwardVec = anglesToForward( orientation );
	forwardVec2D = ( forwardVec[0], forwardVec[1], 0 );
	unitForwardVec2D = VectorNormalize( forwardVec2D );
	toFaceeVec = facee.origin - self.origin;
	toFaceeVec2D = ( toFaceeVec[0], toFaceeVec[1], 0 );
	unitToFaceeVec2D = VectorNormalize( toFaceeVec2D );

	dotProduct = VectorDot( unitForwardVec2D, unitToFaceeVec2D );
	return ( dotProduct > 0.9 ); // reviver is facing within a ~52-degree cone of the player
}

// self = reviver
revive_do_revive( playerBeingRevived, reviverGun )
{
	assert( self is_reviving( playerBeingRevived ) );
	// reviveTime used to be set from a Dvar, but this can no longer be tunable:
	// it has to match the length of the third-person revive animations for
	// co-op gameplay to run smoothly.
	reviveTime = 3;

	if ( self HasPerk( "specialty_quickrevive" ) )
	{
		reviveTime = reviveTime / 2;
	}
	//else if ( self HasPerk( "specialty_quickrevive_upgrade" ) )
	//{
	//	reviveTime = reviveTime / 3;
	//}

	timer = 0;
	revived = false;

	//CODER_MOD: TOMMYK 07/13/2008
	playerBeingRevived.revivetrigger.beingRevived = 1;
	playerBeingRevived.revive_hud setText( &"GAME_PLAYER_IS_REVIVING_YOU", self );
	playerBeingRevived revive_hud_show_n_fade( 3.0 );

	playerBeingRevived notify("update_revive_waypoint");

	playerBeingRevived.revivetrigger setHintString( "" );

	playerBeingRevived startrevive( self );

	if( !isdefined(self.reviveProgressBar) )
	{
		self.reviveProgressBar = self createPrimaryProgressBar();
	}

	if( !isdefined(self.reviveTextHud) )
	{
		self.reviveTextHud = newclientHudElem( self );
	}

	self thread laststand_clean_up_on_disconnect( playerBeingRevived, reviverGun );

	self.reviveProgressBar updateBar( 0.01, 1 / reviveTime );

	self.reviveTextHud.alignX = "center";
	self.reviveTextHud.alignY = "middle";
	self.reviveTextHud.horzAlign = "center";
	self.reviveTextHud.vertAlign = "bottom";
	self.reviveTextHud.y = -113;
	if ( IsSplitScreen() )
	{
		self.reviveTextHud.y = -107;
	}
	self.reviveTextHud.foreground = true;
	self.reviveTextHud.font = "default";
	self.reviveTextHud.fontScale = 1.8;
	self.reviveTextHud.alpha = 1;
	self.reviveTextHud.color = ( 1.0, 1.0, 1.0 );
	self.reviveTextHud setText( &"GAME_REVIVING" );

	//chrisp - zombiemode addition for reviving vo
	// cut , but leave the script just in case
	//self thread say_reviving_vo();

	while( self is_reviving( playerBeingRevived ) )
	{
		wait( 0.05 );
		timer += 0.05;

		if ( self player_is_in_laststand() )
		{
			break;
		}

		if( IsDefined( playerBeingRevived.revivetrigger.auto_revive ) && playerBeingRevived.revivetrigger.auto_revive == true )
		{
			break;
		}

		if( timer >= reviveTime)
		{
			revived = true;
			break;
		}
	}

	if( isdefined( self.reviveProgressBar ) )
	{
		self.reviveProgressBar destroyElem();
	}

	if( isdefined( self.reviveTextHud ) )
	{
		self.reviveTextHud destroy();
	}

	if( IsDefined( playerBeingRevived.revivetrigger.auto_revive ) && playerBeingRevived.revivetrigger.auto_revive == true )
	{
		// ww: just fall through this part, no stoprevive
	}
	else if( !revived )
	{
		playerBeingRevived stoprevive( self );
	}

	//CODER_MOD: TOMMYK 07/13/2008
	playerBeingRevived.revivetrigger setHintString( &"GAME_BUTTON_TO_REVIVE_PLAYER" );
	playerBeingRevived.revivetrigger.beingRevived = 0;

	return revived;
}

say_revived_vo()
{
	if( GetDvar( #"zombiemode" ) == "1" || IsSubStr( level.script, "nazi_zombie_" ) ) // CODER_MOD (Austin 5/4/08): zombiemode loadout setup
	{
		players = get_players();
		for(i=0; i<players.size; i++)
		{
			if (players[i] == self)
			{
				self playsound("plr_" + i + "_vox_revived" + "_" + randomintrange(0, 2));
			}
		}
	}
}

auto_revive( reviver )
{
	if( IsDefined( self.revivetrigger ) )
	{
		self.revivetrigger.auto_revive = true;
		if( self.revivetrigger.beingRevived == 1 )
		{
			while( 1 )
			{
				if( self.revivetrigger.beingRevived == 0 )
				{
					break;
				}
				wait_network_frame();

			}
		}
		self.revivetrigger.auto_trigger = false;
	}

	self reviveplayer();

	//make sure max health is set back to default
	if( isdefined(self.preMaxHealth) )
	{
		self SetMaxHealth( self.preMaxHealth );
	}

	setClientSysState("lsm", "0", self);	// Notify client last stand ended.

	self notify( "stop_revive_trigger" );
	self.revivetrigger delete();
	self.revivetrigger = undefined;

	self laststand_enable_player_weapons();

	self AllowJump( true );
	self AllowLean( true );

	self.ignoreme = false;

	if(IsDefined(reviver))
	{
		// ww: moving the revive tracking, wasn't catching below the auto_revive
		reviver.revives++;
		//stat tracking
		reviver.stats["revives"] = reviver.revives;
	}

	self thread say_revived_vo();
	self notify ( "player_revived", reviver );
}


remote_revive( reviver )
{
	if ( !self player_is_in_laststand() )
	{
		return;
	}

	if(level.gamemode != "survival" && self.vsteam != reviver.vsteam)
	{
		return;
	}

	// ww: achievement change, no damage in rounds now revive
	reviver giveachievement_wrapper( "SP_ZOM_NODAMAGE" );

	self auto_revive( reviver );

}


revive_success( reviver )
{
	self notify ( "player_revived", reviver );
	self reviveplayer();

	//make sure max health is set back to default
	if( isdefined(self.preMaxHealth) )
	{
		self SetMaxHealth( self.preMaxHealth );
	}

	//CODER_MOD: TOMMYK 06/26/2008 - For coop scoreboards
	reviver.revives++;
	//stat tracking
	reviver.stats["revives"] = reviver.revives;

	// CODER MOD: TOMMY K - 07/30/08
	//reviver thread call_overloaded_func( "maps\_arcademode", "arcademode_player_revive" );

	//CODER_MOD: Jay (6/17/2008): callback to revive challenge
	if( isdefined( level.missionCallbacks ) )
	{
		// removing coop challenges for now MGORDON
		//maps\_challenges_coop::doMissionCallback( "playerRevived", reviver );
	}

	setClientSysState("lsm", "0", self);	// Notify client last stand ended.

	self.revivetrigger delete();
	self.revivetrigger = undefined;

	self laststand_enable_player_weapons();

	self.ignoreme = false;

	self thread say_revived_vo();

}


revive_force_revive( reviver )
{
	assert( IsDefined( self ) );
	assert( IsPlayer( self ) );
	assert( self player_is_in_laststand() );

	self thread revive_success( reviver );
}

// the text that tells players that others are in need of a revive
revive_hud_create()
{
	self.revive_hud = newclientHudElem( self );
	self.revive_hud.alignX = "center";
	self.revive_hud.alignY = "middle";
	self.revive_hud.horzAlign = "center";
	self.revive_hud.vertAlign = "bottom";
	self.revive_hud.y = -50;
	self.revive_hud.foreground = true;
	self.revive_hud.font = "default";
	self.revive_hud.fontScale = 1.5;
	self.revive_hud.alpha = 0;
	self.revive_hud.color = ( 1.0, 1.0, 1.0 );
	self.revive_hud setText( "" );

	if( GetDvar( #"zombiemode" ) == "1" )
	{
		self.revive_hud.y = -80;
	}
}

//CODER_MOD: TOMMYK 07/13/2008
revive_hud_think()
{
	self endon ( "disconnect" );

	while ( 1 )
	{
		wait( 0.1 );

		if ( !player_any_player_in_laststand() )
		{
			continue;
		}

		players = get_players();
		playerToRevive = undefined;

		for( i = 0; i < players.size; i++ )
		{
			if( !players[i] player_is_in_laststand() || !isDefined( players[i].revivetrigger.createtime ) )
			{
				continue;
			}

			if( !isDefined(playerToRevive) || playerToRevive.revivetrigger.createtime > players[i].revivetrigger.createtime )
			{
				playerToRevive = players[i];
			}
		}

		if( isDefined( playerToRevive ) )
		{
			for( i = 0; i < players.size; i++ )
			{
				if( players[i] player_is_in_laststand() )
				{
					continue;
				}

				if( GetDvar( #"g_gametype" ) == "vs" )
				{
					if( players[i].team != playerToRevive.team )
					{
						continue;
					}
				}

				if( level.gamemode != "survival" && players[i].vsteam != playerToRevive.vsteam ) 
				{
					continue;
				}

				players[i] thread fadeReviveMessageOver( playerToRevive, 3.0 );
			}

			playerToRevive.revivetrigger.createtime = undefined;
			wait( 3.5 );
		}
	}
}

//CODER_MOD: TOMMYK 07/13/2008
fadeReviveMessageOver( playerToRevive, time )
{
	revive_hud_show();
	self.revive_hud setText( &"GAME_PLAYER_NEEDS_TO_BE_REVIVED", playerToRevive );
	self.revive_hud fadeOverTime( time );
	self.revive_hud.alpha = 0;
}

revive_hud_show()
{
	assert( IsDefined( self ) );
	assert( IsDefined( self.revive_hud ) );

	self.revive_hud.alpha = 1;
}

//CODER_MOD: TOMMYK 07/13/2008
revive_hud_show_n_fade(time)
{
	revive_hud_show();

	self.revive_hud fadeOverTime( time );
	self.revive_hud.alpha = 0;
}

drawcylinder(pos, rad, height)
{
	currad = rad;
	curheight = height;

	for (r = 0; r < 20; r++)
	{
		theta = r / 20 * 360;
		theta2 = (r + 1) / 20 * 360;

		line(pos + (cos(theta) * currad, sin(theta) * currad, 0), pos + (cos(theta2) * currad, sin(theta2) * currad, 0));
		line(pos + (cos(theta) * currad, sin(theta) * currad, curheight), pos + (cos(theta2) * currad, sin(theta2) * currad, curheight));
		line(pos + (cos(theta) * currad, sin(theta) * currad, 0), pos + (cos(theta) * currad, sin(theta) * currad, curheight));
	}
}

mission_failed_during_laststand( dead_player )
{
	if( IsDefined( level.no_laststandmissionfail ) && level.no_laststandmissionfail )
	{
		return;
	}

	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		if( isDefined( players[i] ) )
		{
			//players[i] thread call_overloaded_func( "maps\_quotes", "displaymissionfailed" );
			if( players[i] == self )
			{
				//players[i] thread call_overloaded_func( "maps\_quotes", "displayplayerdead" );
				println( "Player #"+i+" is dead" );
			}
			else
			{
				//players[i] thread call_overloaded_func( "maps\_quotes", "displayteammatedead", dead_player );
				println( "Player #"+i+" is alive" );
			}
		}
	}
	missionfailed();
}
