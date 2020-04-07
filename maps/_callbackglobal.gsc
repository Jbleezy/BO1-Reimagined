#include maps\_utility; 
#include common_scripts\utility;
#include maps\_music;
init()
{
	level.splitscreen = isSplitScreen();
	level.xenon = ( GetDvar( #"xenonGame" ) == "true" );
	level.ps3 = ( GetDvar( #"ps3Game" ) == "true" );
	level.wii = ( GetDvar( #"wiiGame" ) == "true" );
	level.onlineGame = GetDvarInt( #"onlinegame" );
	level.systemLink = GetDvarInt( #"systemlink" );
	level.console = ( level.xenon || level.ps3 || level.wii );

	PrecacheMenu( "briefing" );


	level.rankedMatch = ( level.onlineGame

                        );
	level.profileLoggedIn = ( GetDvar( #"xblive_loggedin" ) == "1" );

}
SetupCallbacks()
{
	level.otherPlayersSpectate = false;

	level.spawnPlayer = ::spawnPlayer;
	level.spawnClient = ::spawnClient;
	level.spawnSpectator = ::spawnSpectator;
	level.spawnIntermission = ::spawnIntermission;


	level.onSpawnPlayer = ::default_onSpawnPlayer;
	level.onPostSpawnPlayer = ::default_onPostSpawnPlayer;
	level.onSpawnSpectator = ::default_onSpawnSpectator;
	level.onSpawnIntermission = ::default_onSpawnIntermission;
	level.onStartGameType = ::blank;
	level.onPlayerConnect = ::blank;
	level.onPlayerDisconnect = ::blank;
	level.onPlayerDamage = ::blank;
	level.onPlayerKilled = ::blank;
	level.onPlayerWeaponSwap = ::blank;

	level._callbacks["on_first_player_connect"]	= [];
	level._callbacks["on_player_connect"]		= [];
	level._callbacks["on_player_disconnect"]	= [];
	level._callbacks["on_player_damage"]		= [];
	level._callbacks["on_player_last_stand"]	= [];
	level._callbacks["on_player_killed"]		= [];

	level._callbacks["on_actor_damage"]			= [];
	level._callbacks["on_actor_killed"]			= [];
	level._callbacks["on_vehicle_damage"]		= [];
	level._callbacks["on_save_restored"]		= [];

	if (!IsDefined(level.onMenuMessage))
		level.onMenuMessage = ::blank;
	if (!IsDefined(level.onDec20Message))
		level.onDec20Message = ::blank;
}
AddCallback(event, func)
{
	AssertEx(IsDefined(event), "Trying to set a callback on an undefined event.");
	AssertEx(IsDefined(level._callbacks[event]), "Trying to set callback for unknown event '" + event + "'.");

	level._callbacks[event] = add_to_array(level._callbacks[event], func, false);
}
RemoveCallback(event, func)
{
	AssertEx(IsDefined(event), "Trying to remove a callback on an undefined event.");
	AssertEx(IsDefined(level._callbacks[event]), "Trying to remove callback for unknown event '" + event + "'.");

	level._callbacks[event] = array_remove( level._callbacks[event], func, true );
}
Callback(event)
{
	AssertEx(IsDefined(level._callbacks[event]), "Must init callback array before trying to call it.");
	for (i = 0; i < level._callbacks[event].size; i++)
	{
		callback = level._callbacks[event][i];
		if (IsDefined(callback))
		{
			self thread [[callback]]();
		}
	}
}
blank( arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10 )
{
}
Callback_CurveNotify( string, curveId, nodeIndex )
{
	level notify( string, curveId, nodeIndex );
}
Callback_StartGameType()
{


}
BriefInvulnerability()
{
	self endon( "disconnect" );

	self EnableInvulnerability();


	wait (3);



	if(IsDefined(self))
	{
		if(IsDefined(self.invulnerable) && (self.invulnerable == true))
		{

		}
		else
		{
			self DisableInvulnerability();

		}
	}
}
Callback_SaveRestored()
{


	players = get_players();
	level.debug_player = players[0];

	num = 0;

	if( isdefined( level._save_pos ) )
	{
		num = level._save_trig_ent;
	}


	for( i = 0; i < 4; i++ )
	{
		player = players[i];
		if( isDefined( player ) )
		{
			player thread BriefInvulnerability();


			if( isdefined( player.savedVisionSet ) )
			{
				player VisionSetNaked( player.savedVisionSet, 0.1 );
			}
			if( GetDvar( #"zombiemode") != "1" )
			{

				dvarName = "player" + player GetEntityNumber() + "downs";
				player.downs = getdvarint( dvarName );
			}


		}
	}




	level Callback("on_save_restored");
}
Player_BreadCrumb_Reset( position, angles )
{
	if( !isdefined( angles ) )
	{
		angles = ( 0, 0, 0 );
	}

	level.playerPrevOrigin0 = position;
	level.playerPrevOrigin1 = position;

	if( !isdefined( level._player_breadcrumbs ) )
	{
		level._player_breadcrumbs = [];

		for( i = 0; i < 4; i ++ )
		{
			level._player_breadcrumbs[i] = [];
			for( j = 0; j < 4; j ++ )
			{
				level._player_breadcrumbs[i][j] = spawnstruct();
			}
		}

	}

	for( i = 0; i < 4; i ++ )
	{
		for( j = 0; j < 4; j ++ )
		{
			level._player_breadcrumbs[i][j].pos = position;
			level._player_breadcrumbs[i][j].ang = angles;
		}
	}
}
Player_BreadCrumb_Update()
{
	self endon( "disconnect" );
	drop_distance = 70;
	right = anglestoright( self.angles ) * drop_distance;
	level.playerPrevOrigin0 = self.origin + right;
	level.playerPrevOrigin1 = self.origin - right;

	if( !isdefined( level._player_breadcrumbs ) )
	{
		Player_BreadCrumb_Reset( self.origin, self.angles );
	}

	num = self GetEntityNumber();

	while( 1 )
	{
		wait 1;
		dist_squared = distancesquared( self.origin, level.playerPrevOrigin0 );
		if( dist_squared > 500*500 )
		{
			right = anglestoright( self.angles ) * drop_distance;
			level.playerPrevOrigin0 = self.origin + right;
			level.playerPrevOrigin1 = self.origin - right;
		}
		else if( dist_squared > drop_distance*drop_distance )
		{
			level.playerPrevOrigin1 = level.playerPrevOrigin0;
			level.playerPrevOrigin0 = self.origin;
		}

		dist_squared = distancesquared( self.origin, level._player_breadcrumbs[num][0].pos );


		dropBreadcrumbs = true;

		if(IsDefined( level.flag ) && IsDefined( level.flag["drop_breadcrumbs"]))
		{
			if(!flag("drop_breadcrumbs"))
			{
				dropBreadcrumbs = false;
			}
		}

		if( dropBreadcrumbs && (dist_squared > drop_distance * drop_distance) )
		{
			for( i = 2; i >= 0; i -- )
			{
				level._player_breadcrumbs[num][i + 1].pos = level._player_breadcrumbs[num][i].pos;
				level._player_breadcrumbs[num][i + 1].ang = level._player_breadcrumbs[num][i].ang;
			}

			level._player_breadcrumbs[num][0].pos = PlayerPhysicsTrace(self.origin, self.origin + ( 0, 0, -1000 ));
			level._player_breadcrumbs[num][0].ang = self.angles;
		}

	}
}
SetPlayerSpawnPos()
{
	players = get_players();
	player = players[0];
	if( !isdefined( level._player_breadcrumbs ) )
	{
		spawnpoints = getentarray( "info_player_deathmatch", "classname" );

		if( player.origin == ( 0, 0, 0 ) && isdefined( spawnpoints ) && spawnpoints.size > 0 )
		{
			Player_BreadCrumb_Reset( spawnpoints[0].origin, spawnpoints[0].angles );
		}
		else
		{
			Player_BreadCrumb_Reset( player.origin, player.angles );
		}
	}

	too_close = 30;
	spawn_pos = level._player_breadcrumbs[0][0].pos;
	dist_squared = distancesquared( player.origin, spawn_pos );
	if( dist_squared > 500*500 )
	{
		if( player.origin != ( 0, 0, 0 ) )
		{
			spawn_pos = player.origin +( 0, 30, 0 );
		}
	}
	else if( dist_squared < too_close*too_close )
	{
		spawn_pos = level._player_breadcrumbs[0][1].pos;
	}

	spawn_angles = vectornormalize( player.origin - spawn_pos );
	spawn_angles = vectorToAngles( spawn_angles );

	if( !playerpositionvalid( spawn_pos ) )
	{


		spawn_pos = player.origin;
		spawn_angles = player.angles;
	}

}
Callback_PlayerConnect()
{

	thread first_player_connect();


	self waittill( "begin" );
	self reset_clientdvars();
	waittillframeend;


	wait(0.1);


	level notify( "connected", self );
	self Callback("on_player_connect");
	self thread maps\_load_common::player_special_death_hint();
	self thread maps\_flashgrenades::monitorFlash();
	if( GetDvar( #"zombiemode" ) == "0" )
	{



		info_player_spawn = getentarray( "info_player_deathmatch", "classname" );
		if( isdefined( info_player_spawn ) && info_player_spawn.size > 0 )
		{


			players = get_players("all");
			if( Isdefined( players ) &&( players.size != 0 ) )
			{
				if( players[0] == self )
				{
					println( "2:  Setting player origin to info_player_start " + info_player_spawn[0].origin );
					self setOrigin( info_player_spawn[0].origin );
					self setPlayerAngles( info_player_spawn[0].angles );
					self thread Player_BreadCrumb_Update();
				}
				else
				{
					println( "Callback_PlayerConnect:  Setting player origin near host position " + players[0].origin );
					self SetPlayerSpawnPos();
					self thread Player_BreadCrumb_Update();
				}
			}
			else
			{
				println( "Callback_PlayerConnect:  Setting player origin to info_player_start " + info_player_spawn[0].origin );
				self setOrigin( info_player_spawn[0].origin );
				self setPlayerAngles( info_player_spawn[0].angles );
				self thread Player_BreadCrumb_Update();
			}
		}
	}




	if( !IsDefined( self.flag ) )
	{
		self.flag = [];
		self.flags_lock = [];
	}
	if( !IsDefined( self.flag["player_has_red_flashing_overlay"] ) )
	{
		self player_flag_init( "player_has_red_flashing_overlay" );
		self player_flag_init( "player_is_invulnerable" );
	}
	if( !IsDefined( self.flag["loadout_given"] ) )
	{
		self player_flag_init( "loadout_given" );
	}
	self player_flag_clear( "loadout_given" );





	if( GetDvar( #"r_reflectionProbeGenerate" ) == "1" )
	{
		waittillframeend;

		self thread spawnPlayer();
		return;
	}

	self setClientDvar( "ui_allow_loadoutchange", "1" );
	self thread[[level.spawnClient]]();
	dvarName = "player" + self GetEntityNumber() + "downs";
	setdvar( dvarName, self.downs );


}
reset_clientdvars()
{
	if( IsDefined( level.reset_clientdvars ) )
	{
		self [[level.reset_clientdvars]]();
		return;
	}
	self SetClientDvars( "compass", "1",
						 "hud_showStance", "1",
						 "cg_thirdPerson", "0",
						 "cg_fov", "65",
						 "cg_cursorHints","4",
						 "cg_thirdPersonAngle", "0",
						 "hud_showobjectives","1",
						 "ammoCounterHide", "0",
						 "miniscoreboardhide", "0",
						 "ui_hud_hardcore", "0",
						 "credits_active", "0",
						 "hud_missionFailed", "0",
						 "cg_cameraUseTagCamera", "1",
						 "cg_drawCrosshair", "1",
						 "r_heroLightScale", "1 1 1",
						 "r_fog_disable", "0",
						 "r_dof_tweak", "0",
						 "player_sprintUnlimited", "0",
						 "r_bloomTweaks", "0",
						 "r_exposureTweak", "0",
						 "cg_aggressiveCullRadius", "0",
						 "sm_sunSampleSizeNear", "0.25"
						 );
	self AllowSpectateTeam( "allies", false );
	self AllowSpectateTeam( "axis", false );
	self AllowSpectateTeam( "freelook", false );
	self AllowSpectateTeam( "none", false );
}
Callback_PlayerDisconnect()
{
	self Callback("on_player_disconnect");
}
Callback_PlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	if( IsDefined( self.overridePlayerDamage ) )
	{
		iDamage = self [[self.overridePlayerDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
	}
	else if( IsDefined( level.overridePlayerDamage ) )
	{
		iDamage = self [[level.overridePlayerDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
	}
	AssertEx(IsDefined(iDamage), "You must return a value from a damage override function.");
	self Callback("on_player_damage");
	if (is_true(self.magic_bullet_shield))
	{
		maxHealth = self.maxHealth;

		self.health += iDamage;

		self.maxHealth = maxHealth;
	}

	/*if( isdefined( self.divetoprone ) && self.divetoprone == 1 )
	{
		if( sMeansOfDeath == "MOD_GRENADE_SPLASH" )
		{

			dist = Distance2d(vPoint, self.origin);
			if( dist > 32 )
			{

				dot_product = vectordot( AnglesToForward( self.angles ), vDir );
				if( dot_product > 0 )
				{

					iDamage = int( iDamage * 0.5 );
				}
			}
		}
	}*/
	println("CB PD");

	if( isdefined( eAttacker ) && ((isPlayer( eAttacker )) && (eAttacker.team == self.team))&& ( !isDefined( level.friendlyexplosivedamage ) || !level.friendlyexplosivedamage ))
	{
		if( !isDefined(level.is_friendly_fire_on) || ![[level.is_friendly_fire_on]]() )
		{
			if( self != eAttacker)
			{

				println("Exiting - players can't hut each other.");
				return;
			}
			else if( sMeansOfDeath != "MOD_GRENADE_SPLASH"
					&& sMeansOfDeath != "MOD_GRENADE"
					&& sMeansOfDeath != "MOD_EXPLOSIVE"
					&& sMeansOfDeath != "MOD_PROJECTILE"
					&& sMeansOfDeath != "MOD_PROJECTILE_SPLASH"
					&& sMeansOfDeath != "MOD_BURNED"
					&& sMeansOfDeath != "MOD_SUICIDE" )
			{
				println("Exiting - damage type verbotten.");


				return;
			}
		}
	}

	// Remove shellshock from explosive weapons (using "MOD_MELEE" since it automatically makes players stop sprinting)
	if(sMeansOfDeath == "MOD_GRENADE_SPLASH" || sMeansOfDeath == "MOD_PROJECTILE_SPLASH")
	{
		sMeansOfDeath = "MOD_MELEE"; // TODO - make sure this doesn't have any unintended side effects
		//self thread stop_running();
	}

	if ( isdefined(eAttacker) && eAttacker != self )
	{
		if ( maps\_damagefeedback::doDamageFeedback( sWeapon, eInflictor ) )
		{
			if ( iDamage > 0 )
			{
				eAttacker thread maps\_damagefeedback::updateDamageFeedback();
			}
		}
	}
	self maps\_dds::update_player_damage( eAttacker );
	if (iDamage >= self.health)
	{
		if ((sMeansOfDeath == "MOD_CRUSH")
			&& IsDefined(eAttacker) && IsDefined(eAttacker.classname)
			&& (eAttacker.classname == "script_vehicle"))
		{
			SetDvar( "ui_deadquote", "@SCRIPT_MOVING_VEHICLE_DEATH" );
		}
	}

	if ( is_true( level.disable_player_damage_knockback ) )
	{
		iDFlags = iDFlags | level.iDFLAGS_NO_KNOCKBACK;
	}
	PrintLn("Finishplayerdamagage wrapper.");
	self finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
}
finishPlayerDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	self finishPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
}
incrGrenadeKillCount()
{
	if (!isPlayer(self) )
	{
		return;
	}
	if (!isDefined(self.grenadeKillCounter) )
	{
		self.grenadeKillCounter = 0;
	}
	self.grenadeKillCounter++;
	if( self.grenadeKillCounter >= 5 )
	{
		self giveachievement_wrapper( "SP_GEN_FRAGMASTER" );
	}
	wait( 0.25 );
	self.grenadeKillCounter--;
}
Callback_ActorDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	self endon("death");
	if( IsDefined( self.overrideActorDamage ) )
	{
		iDamage = self [[self.overrideActorDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
	}
	else if( IsDefined( level.overrideActorDamage ) )
	{
		iDamage = self [[level.overrideActorDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
	}
	AssertEx(IsDefined(iDamage), "You must return a value from a damage override function.");
	self Callback("on_actor_damage");
	if ( is_true(self.magic_bullet_shield ) && !is_true( self.bulletcam_death ) )
	{
		MIN_PAIN_INTERVAL = 500;
		t = GetTime();
		if ((t - self._mbs.last_pain_time > MIN_PAIN_INTERVAL)
			|| (sMeansOfDeath == "MOD_EXPLOSIVE"))
		{


			if (self.allowPain || is_true(self._mbs.allow_pain_old))
			{
				enable_pain();
			}
			self._mbs.last_pain_time = t;
			self thread ignore_me_timer( self._mbs.ignore_time, "stop_magic_bullet_shield" );
			self thread turret_ignore_me_timer( self._mbs.turret_ignore_time );
		}
		else
		{
			self._mbs.allow_pain_old = self.allowPain;
			disable_pain();
		}
		self.delayedDeath = false;

		maxHealth = self.maxHealth;

		self.health += iDamage;

		self.maxHealth = maxHealth;
	}
	else if (!is_true(self.a.doingRagdollDeath))
	{
		iDamage = maps\_bulletcam::try_bulletcam( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
		if( GetDvar( #"zombiemode") != "1" )
		{
			if (!self call_overloaded_func( "animscripts\balcony", "balconyDamage", iDamage, sHitLoc, sMeansOfDeath ))
			{

				self animscripts\revive::tryGoingDown( iDamage, sHitLoc );
			}
		}
	}

	if ( IsDefined(eAttacker) && eAttacker != self )
	{
		if ( maps\_damagefeedback::doDamageFeedback( sWeapon, eInflictor ) )
		{
			if ( iDamage > 0 )
			{
				eAttacker thread maps\_damagefeedback::updateDamageFeedback();
			}
		}
	}
	self maps\_dds::update_actor_damage( eAttacker, sMeansOfDeath );

	if( self.health - iDamage <= 0 && sWeapon == "crossbow_sp" )
	{
		self.dofiringdeath = false;
	}

	if( isPlayer( eAttacker ) && ( self.health - iDamage <= 0 ) )
	{
		println( "player killed enemy with "+sWeapon+" via "+sMeansOfDeath );
		if ( self.team == "axis" && GetDvar( #"zombiemode" ) != "1"  )
		{
			if ( sWeapon == "explosive_bolt_sp" || sWeapon == "crossbow_explosive_alt_sp" )
			{
				killedSoFar = 1 + GetPersistentProfileVar( 0, 0 );
				if( killedSoFar >= 30 )
				{
					eAttacker giveachievement_wrapper( "SP_GEN_CROSSBOW" );
				}
				SetPersistentProfileVar( 0, killedSoFar );
			}
			if( ( sMeansOfDeath == "MOD_GRENADE" || sMeansOfDeath == "MOD_GRENADE_SPLASH" ) && sWeapon == "frag_grenade_sp" )
			{
				eAttacker thread incrGrenadeKillCount();
			}
		}
	}
	self finishActorDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
}
finishActorDamageWrapper( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	self finishActorDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime );
}
Callback_RevivePlayer()
{
	self endon( "disconnect" );
	self RevivePlayer();
}
Callback_PlayerLastStand( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self endon( "disconnect" );
	self Callback("on_player_last_stand");
	[[maps\_laststand::PlayerLastStand]]( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration );
}
Callback_PlayerKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	self thread[[level.onPlayerKilled]]( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration );




	self.downs++;
	dvarName = "player" + self GetEntityNumber() + "downs";
	setdvar( dvarName, self.downs );
	if( IsDefined( level.player_killed_shellshock ) )
	{
		self ShellShock( level.player_killed_shellshock, 3 );
	}
	else
	{
		self ShellShock( "death", 3 );
	}
	self PlayLocalSound( "evt_player_death" );

	self setmovespeedscale( 1.0 );
	self.ignoreme = false;
	self notify( "killed_player" );
	self Callback("on_player_killed");

	wait( 1 );

	if( IsDefined( level.overridePlayerKilled ) )
	{
		self [[level.overridePlayerKilled]]();
	}
	if( get_players().size > 1 )
	{




		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if( isDefined( players[i] ) )
			{

				if( !isAlive( players[i] ) )
				{

					println( "Player #"+i+" is dead" );
				}
				else
				{

					println( "Player #"+i+" is alive" );
				}
			}
		}
		missionfailed();
		return;
	}

}
Callback_ActorKilled( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime )
{
	if( IsDefined( self.overrideActorKilled ) )
	{
		self [[self.overrideActorKilled]]( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime );
	}
	else if( IsDefined( level.overrideActorKilled ) )
	{
		self [[level.overrideActorKilled]]( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime );
	}
	self Callback("on_actor_killed");
}
Callback_VehicleDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, damageFromUnderneath, modelIndex, partName )
{
	self endon("death");
	if( IsDefined( self.overrideVehicleDamage ) )
	{
		iDamage = self [[self.overrideVehicleDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, damageFromUnderneath, modelIndex, partName );
	}
	else if( IsDefined( level.overrideVehicleDamage ) )
	{
		iDamage = self [[level.overrideVehicleDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, damageFromUnderneath, modelIndex, partName );
	}
	AssertEx(IsDefined(iDamage), "You must return a value from a damage override function.");
	self Callback("on_vehicle_damage");
	if( self IsVehicleImmuneToDamage( iDFlags, sMeansOfDeath, sWeapon ) )
	{
		return;
	}
	if( self maps\_vehicle::friendlyfire_shield_callback( eAttacker, iDamage, sMeansOfDeath ) )
	{
		return;
	}

	self finishVehicleDamage(eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime, damageFromUnderneath, modelIndex, partName, false);
}
spawnClient()
{
	self endon( "disconnect" );
	self endon( "end_respawn" );
	println( "*************************spawnClient****" );




	self unlink();

	if( isdefined( self.spectate_cam ) )
	{
		self.spectate_cam delete();
	}
	if( level.otherPlayersSpectate )
	{
		self thread	[[level.spawnSpectator]]();
	}
	else
	{
		self thread	[[level.spawnPlayer]]();
	}
}
spawnPlayer( spawnOnHost )
{
	self endon( "disconnect" );
	self endon( "spawned_spectator" );
	self notify( "spawned" );
	self notify( "end_respawn" );


	synchronize_players();
	setSpawnVariables();

	self.sessionstate = "playing";
	self.spectatorclient = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = self.health;
	self.shellshocked = false;
	self.inWater = false;
	self.friendlydamage = undefined;
	self.hasSpawned = true;
	self.spawnTime = getTime();
	self.afk = false;
	println( "*************************spawnPlayer****" );
	self detachAll();
	if( IsDefined( level.custom_spawnPlayer ) )
	{
		self [[level.custom_spawnPlayer]]();
		return;
	}
	if( isdefined( level.onSpawnPlayer ) )
	{
		self [[level.onSpawnPlayer]]();
	}
	wait_for_first_player();

	if( isdefined( spawnOnHost ) )
	{
		self Spawn( get_players()[0].origin, get_players()[0].angles );
		self SetPlayerSpawnPos();
	}
	else
	{
		self Spawn( self.origin, self.angles );
	}
	if( isdefined( level.onPostSpawnPlayer ) )
	{
		self[[level.onPostSpawnPlayer]]();
	}
	if( isdefined( level.onPlayerWeaponSwap ) )
	{
		self thread[[level.onPlayerWeaponSwap]]();
	}


	self maps\_introscreen::introscreen_player_connect();

	waittillframeend;







	if( self != get_players("all")[0] )
	{
		wait( 0.5 );
	}

	self notify( "spawned_player" );
}
synchronize_players()
{

	if( !IsDefined( level.flag ) || !IsDefined( level.flag["all_players_connected"] ) )
	{
		println( "^1****    ERROR: You must call _load::main() if you don't want bad coop things to happen!    ****" );
		println( "^1****    ERROR: You must call _load::main() if you don't want bad coop things to happen!    ****" );
		println( "^1****    ERROR: You must call _load::main() if you don't want bad coop things to happen!    ****" );
		return;
	}


	if( GetNumConnectedPlayers() == GetNumExpectedPlayers() )
	{
		return;
	}
	if( flag( "all_players_connected" ) )
	{
		return;
	}

	background = undefined;
	if ( level.onlineGame || level.systemLink )
	{
		self OpenMenu( "briefing" );
	}
	else
	{
		background = NewHudElem();
		background.x = 0;
		background.y = 0;
		background.horzAlign = "fullscreen";
		background.vertAlign = "fullscreen";
		background.foreground = true;
		background SetShader( "black", 640, 480 );
	}

	flag_wait( "all_players_connected" );
	if ( level.onlineGame || level.systemLink )
	{
		players = get_players("all");
		for ( i = 0; i < players.size; i++ )
		{
			players[i] CloseMenu();
		}
	}
	else
	{
		assert( IsDefined( background ) );
		background Destroy();
	}
}
spawnSpectator()
{
	self endon( "disconnect" );
	self endon( "spawned_spectator" );
	self notify( "spawned" );
	self notify( "end_respawn" );
	setSpawnVariables();

	self.sessionstate = "spectator";
	self.spectatorclient = -1;
	if( isdefined( level.otherPlayersSpectateClient ) )
	{
		self.spectatorclient = level.otherPlayersSpectateClient getEntityNumber();
	}
	self setClientDvars( "cg_thirdPerson", 0 );
	self setSpectatePermissions();

	self.archivetime = 0;
	self.psoffsettime = 0;
	self.statusicon = "";
	self.maxhealth = self.health;
	self.shellshocked = false;
	self.inWater = false;
	self.friendlydamage = undefined;
	self.hasSpawned = true;
	self.spawnTime = getTime();
	self.afk = false;
	println( "*************************spawnSpectator***" );
	self detachAll();
	if( isdefined( level.onSpawnSpectator ) )
	{
		self[[level.onSpawnSpectator]]();
	}

	self Spawn( self.origin, self.angles );

	waittillframeend;

	flag_wait( "all_players_connected" );

	self notify( "spawned_spectator" );
}
setSpectatePermissions()
{
	self AllowSpectateTeam( "allies", true );
	self AllowSpectateTeam( "axis", false );
	self AllowSpectateTeam( "freelook", false );
	self AllowSpectateTeam( "none", false );
}
spawnIntermission()
{
	self notify( "spawned" );
	self notify( "end_respawn" );

	self setSpawnVariables();

	self freezeControls( false );

	self setClientDvar( "cg_everyoneHearsEveryone", "1" );

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	[[level.onSpawnIntermission]]();
	self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
}
default_onSpawnPlayer()
{
}
default_onPostSpawnPlayer()
{
}
default_onSpawnSpectator()
{
}
default_onSpawnIntermission()
{
	spawnpointname = "info_intermission";
	spawnpoints = getentarray( spawnpointname, "classname" );


	if(spawnpoints.size < 1)
	{
		println( "NO " + spawnpointname + " SPAWNPOINTS IN MAP" );
		return;
	}

	spawnpoint = spawnpoints[RandomInt(spawnpoints.size)];
	if( isDefined( spawnpoint ) )
	{
		self spawn( spawnpoint.origin, spawnpoint.angles );
	}
}
first_player_connect()
{

	waittillframeend;
	if( isDefined( self ) )
	{
		level notify( "connecting", self );
		players = get_players();
		if( isdefined( players ) &&( players.size == 0 || players[0] == self ) )
		{
			level notify( "connecting_first_player", self );
			self waittill( "spawned_player" );

			waittillframeend;

			level notify( "first_player_ready", self );
			if( GetDvar( #"zombiemode") != "1" )
			{
				prefetchnext();
			}
			self Callback("on_first_player_connect");
		}
	}

}
setSpawnVariables()
{
	resetTimeout();

	self StopShellshock();
	self StopRumble( "damage_heavy" );
}

stop_running()
{
	self endon( "death" );
	self endon( "disconnect" );

	self AllowSprint(false);
	wait 1;
	self AllowSprint(true);
}
