#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

#using_animtree("generic_human");

//-----------------------------------------------------------------------
// setup temple monkey
//-----------------------------------------------------------------------
init()
{
	// find all the spawners and add our custom spawn functionality
	maps\_zombiemode_ai_monkey::init_monkey_zombie_anims();
	precache_ambient_monkey_anims();

	level._effect["monkey_death"] = loadfx("maps/zombie/fx_zmb_monkey_death");
	level._effect["monkey_spawn"] =		loadfx("maps/zombie/fx_zombie_ape_spawn_dust");
	level._effect["monkey_eye_glow"] =	LoadFx( "maps/zombie/fx_zmb_monkey_eyes" );
	level._effect["monkey_gib"] =	LoadFx( "maps/zombie_temple/fx_ztem_zombie_mini_squish" );
	level._effect["monkey_gib_no_gore"] = LoadFX("maps/zombie_temple/fx_ztem_monkey_shrink");
	level._effect["monkey_launch"] = loadfx("weapon/grenade/fx_trail_rpg");

	level.scr_anim[ "monkey_zombie" ][ "slide" ] = %ai_zombie_monkey_slide_traverse;

	level.monkey_zombie_spawners = GetEntArray( "monkey_zombie_spawner", "targetname" );
	array_thread( level.monkey_zombie_spawners, ::add_spawn_function, maps\_zombiemode_ai_monkey::monkey_prespawn );

	PrecacheRumble("explosion_generic");

	level.nextMonkeyStealRound = 1; //5;
	level.monkey_zombie_health = level.zombie_vars["zombie_health_start"];

	level.stealer_monkey_spawns = GetStructArray("stealer_monkey_spawn", "targetname");
	level.stealer_monkey_exits = GetStructArray("stealer_monkey_exit", "targetname");

	if ( GetDvar("monkey_steal_debug") == "" )
	{
		SetDvar("monkey_steal_debug","0");
	}

	/#
	cheat = GetDvarInt("monkey_steal_debug");
	if ( cheat )
	{
		level.nextMonkeyStealRound = 1;
	}
    #/

    /*if(level.gamemode != "survival")
    {
    	return;
    }*/

	// make all barriers with the zone they are in
	level thread _setup_zone_info();
	level thread _watch_for_powerups();

	//setup
	monkey_ambient_init();

	//Monkeys watch for greandes
	level thread monkey_grenade_watcher_temple();
}

monkey_grenade_watcher_temple()
{
	wait_for_all_players();
	level thread maps\_zombiemode_ai_monkey::monkey_grenade_watcher();
}

monkey_templeThink(spawner)
{
	self thread _monkey_TempleThinkInternal(spawner);
}

//Search out to find a barrier that meet criteria
monkey_GetMonkeySpawnLocation(minDist, checkVisible, skipStartArea)
{
	visitedZones = [];

	needToVisit = [];

	startZone = self _ent_GetZoneName();
	needToVisit[0] = startZone;

	zoneCounter = 0;

	while(needToVisit.size>0)
	{
		zoneCounter++;
		visitName = needToVisit[0];
		zone = level.zones[visitName];
		if(isdefined(zone.barriers) && (!skipStartArea || startZone!=visitName))
		{
			//Randomize order so the same barrier isn't always picked
			barriers = array_randomize_knuth(zone.barriers);
			for(i=0;i<barriers.size;i++)
			{
				text = "Zone: " + zoneCounter + " Barrier: " + i;
				if(barriers[i] barrier_test(zone, self, minDist, checkVisible))
				{
					//barriers[i] thread printText(text);
					return barriers[i];
				}
//				else
//				{
//
//					barriers[i] thread printText(text, true);
//				}
			}
		}

		//Add Current zone to visited list
		visitedZones[visitedZones.size] = visitName;

		needToVisit = array_remove_index(needToVisit, 0);

		//Add all adjacent zones
		azKeys = GetArrayKeys( zone.adjacent_zones );
		azKeys = array_randomize_knuth(azKeys); //Radomize order we visit neighbors
		for ( i=0; i < azKeys.size; i++ )
		{
			name = azKeys[i];
			if(!is_in_array(visitedZones, name))	//Don't repeat zones
			{
				adjZone = zone.adjacent_zones[name];
				globalZone = level.zones[name];
				if ( adjZone.is_connected && globalZone.is_enabled )
				{
					needToVisit[needToVisit.size] = name;
				}
			}
		}
	}

	return undefined;
}

barrier_test(zone, ent, minDist, checkVisible)
{
	//If the zone is not active it is safe to spawn there
	if(!zone.is_active)
	{
		return true;
	}

	//Min distance the barrier must be from ent to be valid
	minDist2 	= minDist*minDist;

	//Check that the barrier is at least a min distance from ent
	distToBarrier = distancesquared(ent.origin, self.origin);
	if(distToBarrier < minDist2)
	{
		//self thread printText("Too Close To Power Up (" + sqrt(distToBarrier) + "<"+minDist+")", true );
		return false;
	}

	if(checkVisible)
	{
		//Max distance that player can "see"
		//Assume any barrier past can not be seen
		playerVisDist 	= 1800.0;
		playerVisDist2	= playerVisDist*playerVisDist;

		//Check that no players can see this barrier
		players = get_players();
		for(i=0;i<players.size;i++)
		{
			player = players[i];

			distToPlayer2 = distancesquared(player.origin, self.origin);
			if(distToPlayer2 < playerVisDist2)
			{
				if(self player_can_see_me( player ))
				{
					return false;
				}
			}
		}
	}

	//Passed all tests, this barrier should not be visible
	return true;
}

ent_GatherValidBarriers(zoneOverride, ignoreOccupied, ignoreVisible)
{
	// do a depth first search starting from the monkeys zone to find all zones that are connected to us
	valid_barriers = [];

	monkeyZone = zoneOverride;
	if ( !IsDefined(monkeyZone) )
	{
		monkeyZone = self _ent_GetZoneName();
	}

	if ( IsDefined(monkeyZone) )
	{
		s = SpawnStruct();
		zoneNames = _getConnectedZoneNames(monkeyZone, s);

		players = get_players();
		for ( i = 0; i < zoneNames.size; i++ )
		{
			name = zoneNames[i];
			zone = level.zones[name];

			//Skip zones with players in them
			if(is_true(ignoreOccupied) && zone.is_occupied)
			{
				continue;
			}

			barriers = [];
			//Skip barriers in FOV
			if(is_true(ignoreVisible))
			{
				barriers = _get_non_visible_barriers(zone.barriers);
			}
			else if(isdefined(zone.barriers))
			{
				barriers = zone.barriers;
			}

			if ( barriers.size>0 )
			{
				valid_barriers = array_combine(valid_barriers, barriers);
			}
		}
	}

	return valid_barriers;
}

printText(text, red)
{
	level endon("stopPrints");

	if( !isDefined(level.printOffsets) )
	{
		level.printOffsets = [];
	}

	originStr = "(" + self.origin[0]+","+self.origin[1]+","+self.origin[2] + ")";

	if( !isDefined(level.printOffsets[originStr]) )
	{
		level.printOffsets[originStr] = (0,0,0);
	}
	else
	{
		level.printOffsets[originStr] += (0,0,20);
	}

	offset = ( 0, 0, 45 ) + level.printOffsets[originStr];

	color = (0,1,0); //green
	if(is_true(red))
	{
		color = (1,0,0);
	}
	while(1)
	{
		print3d( ( self.origin + offset ), text, color, 0.85 );
		wait .05;
	}
}

printTextStop()
{
	level notify("stopPrints");
	level.printOffsets = [];
}

_get_non_visible_barriers(barriers)
{
	returnBarriers = [];
	if(isdefined(barriers))
	{
		players = get_players();
		for(i=0;i<barriers.size;i++)
		{
			canSee = false;
			for(j=0;j<players.size;j++)
			{
				if( abs(barriers[i].origin[2] - players[j].origin[2]) < 200 )
				{
					if( barriers[i] player_can_see_me( players[j] ) )
					{
						//barriers[i] thread printText("Player " + j + " can see.", true );
						canSee = true;
						break;
					}
				}
			}

			if(!canSee)
			{
				returnBarriers[returnBarriers.size] = barriers[i];
			}
		}
	}

	return returnBarriers;
}

player_can_see_me( player )
{
	playerAngles = player getplayerangles();
	playerForwardVec = AnglesToForward( playerAngles );
	playerUnitForwardVec = VectorNormalize( playerForwardVec );

	banzaiPos = self.origin;
	playerPos = player GetEyeApprox();
	playerToBanzaiVec = banzaiPos - playerPos;
	playerToBanzaiUnitVec = VectorNormalize( playerToBanzaiVec );

	forwardDotBanzai = VectorDot( playerUnitForwardVec, playerToBanzaiUnitVec );
	angleFromCenter = ACos( forwardDotBanzai );

	playerFOV = GetDvarFloat( #"cg_fov" );
	banzaiVsPlayerFOVBuffer = GetDvarFloat( #"g_banzai_player_fov_buffer" );
	if ( banzaiVsPlayerFOVBuffer <= 0 )
	{
		banzaiVsPlayerFOVBuffer = 0.2;
	}

	playerCanSeeMe = ( angleFromCenter <= ( playerFOV * 0.5 * ( 1 - banzaiVsPlayerFOVBuffer ) ) );

	return playerCanSeeMe;
}

getBarrierAttackLocation(barrier)
{
	forward = AnglesToForward(barrier.angles);
	attack_location = barrier.origin + forward * 80.0;
	attack_location = (attack_location[0], attack_location[1], attack_location[2] - 30.0);
	return attack_location;
}

///////////////////////////////////////////////////////////////////////////////////////////

_ent_GetZone()
{
	zoneName = self _ent_GetZoneName();
	if ( IsDefined(zoneName) )
	{
		return level.zones[zoneName];
	}

	return undefined;
}

_ent_GetZoneName()
{
	zkeys = GetArrayKeys( level.zones );
	for ( z = 0; z < zkeys.size; z++ )
	{
		zoneName = zkeys[z];
		zone = level.zones[zoneName];

		for ( v = 0; v < zone.volumes.size; v++ )
		{
			touching = self IsTouching(zone.volumes[v]);
			if ( touching )
			{
				return zoneName;
			}
		}
	}

	return undefined;

}

_setup_zone_info()
{
	// need to wait for it to get inited...hack
	wait(1.0);

	checkEnt = spawn("script_origin", (0,0,0));
	for ( i = 0; i < level.exterior_goals.size; i++ )
	{
		goal = level.exterior_goals[i];
		forward = AnglesToForward(goal.angles);
		checkEnt.origin = goal.origin + forward * 100.0;

		zoneName = checkEnt _ent_GetZoneName();
		valid = IsDefined(zoneName) && IsDefined(level.zones[zoneName]);
		if ( !valid )
		{
			iprintln("Could not find zone for barrier: " + checkEnt.origin);
			continue;
		}

		goal.zoneName = zoneName;
		zone = level.zones[zoneName];
		if ( !IsDefined( zone.barriers ) )
		{
			zone.barriers = [];
		}

		zone.barriers[zone.barriers.size] = goal;
	}

	checkEnt Delete();

	// now go through all the spawners and add them to the zones as well
	for ( i = 0; i < level.monkey_zombie_spawners.size; i++ )
	{
		zoneName = level.monkey_zombie_spawners[i].script_noteworthy;
		zone = level.zones[zoneName];
		if ( !IsDefined(zone.monkey_spawners) )
		{
			zone.monkey_spawners = [];
		}
		zone.monkey_spawners[zone.monkey_spawners.size] = level.monkey_zombie_spawners[i];
	}
}

_monkey_TempleThinkInternal(spawner)
{
	self endon("death");

	spawner.count = 100;
	spawner.last_spawn_time = GetTime();

	//maps\_zombiemode_ai_monkey::monkey_zombie_default_enter_level();
	PlayFX( level._effect["monkey_death"], self.origin );
	playsoundatposition( "zmb_bolt", self.origin );

	self.deathFunction = ::_monkey_zombieTempleDeathCallback;
	self.spawnZone = spawner.script_noteworthy;
	self.shrink_ray_fling = ::_monkey_TempleFling;

	self thread monkey_zombie_choose_sprint_temple();
	self thread _monkey_GotoBoards();
}

monkey_zombie_choose_run_temple(movePlayBackRate)
{
	if(isDefined(moveplaybackrate))
	{
		self.moveplaybackrate = movePlayBackRate;
	}
	rand = randomIntRange( 1, 3 );
	self set_run_anim( "run"+rand );
	self.run_combatanim = level.scr_anim["monkey_zombie"]["run"+rand];
	self.crouchRunAnim = level.scr_anim["monkey_zombie"]["run"+rand];
	self.crouchrun_combatanim = level.scr_anim["monkey_zombie"]["run"+rand];

	self.zombie_move_speed = "run";
}

monkey_zombie_choose_sprint_temple(movePlayBackRate)
{
	if(isDefined(moveplaybackrate))
	{
		self.moveplaybackrate = movePlayBackRate;
	}

	rand = randomIntRange( 1, 5 );
	self set_run_anim( "sprint"+rand );
	self.run_combatanim = level.scr_anim["monkey_zombie"]["sprint"+rand];
	self.crouchRunAnim = level.scr_anim["monkey_zombie"]["sprint"+rand];
	self.crouchrun_combatanim = level.scr_anim["monkey_zombie"]["sprint"+rand];

	self.zombie_move_speed = "sprint";
}

_monkey_zombieTempleDeathCallback()
{
	self maps\_zombiemode_spawner::reset_attack_spot();

	self.grenadeAmmo = 0;

	self thread maps\_zombiemode_audio::do_zombies_playvocals( "death", self.animname );
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();

	PlayFX( level._effect["monkey_death"], self.origin );

    if( IsDefined( self.attacker ) && IsPlayer( self.attacker ) )
        self.attacker maps\_zombiemode_audio::create_and_play_dialog( "kill", "thief" );

	if( self.damagemod == "MOD_BURNED" )
	{
		self thread animscripts\zombie_death::flame_death_fx();
	}

	return false;
}

#using_animtree("generic_human");
_monkey_GotoBoards()
{
	self endon("death");
	self endon("shrink");

	barriers = level.zones[self.spawnZone].barriers;
	if(!isDefined(barriers))
	{
		barriers = [];
	}
	barriers = _sort_by_num_boards(barriers);

	for ( i = 0; i < barriers.size; i++ )
	{
		barrier = barriers[i];
		location = getBarrierAttackLocation(barrier);
		//maps\_debug::drawDebugLine(self.origin, location, (1,1,1), 100 );

		self.goalradius = 32;
		self SetGoalPos( location );
		self waittill( "goal" );

		self SetGoalPos(self.origin);

		while ( true )
		{
			chunk = _find_chunk(barrier.barrier_chunks);
			if ( !IsDefined(chunk) )
			{
				break;
			}

			self _monkey_DestroyBoards(barrier, chunk, location);
		}
	}

	self _monkey_remove();
}

_find_chunk(barrier_chunks)
{
	ASSERT( IsDefined(barrier_chunks), "_zombiemode_utility::all_chunks_destroyed - Barrier chunks undefined" );
	for( i = 0; i < barrier_chunks.size; i++ )
	{
		if( barrier_chunks[i] get_chunk_state() == "repaired" )
		{
			return barrier_chunks[i];
		}
	}

	return undefined;
}

_monkey_DestroyBoards(barrier, chunk, location)
{
	chunk maps\_zombiemode_blockers::update_states("target_by_zombie");

	self Teleport( location, self.angles );
	perk_attack_anim = %ai_zombie_monkey_attack_perks_front;
	time = getAnimLength( perk_attack_anim );
	self animscripted( "perk_attack_anim", location, self.angles, perk_attack_anim, "normal", %body, 1, 0.2 );
	self thread maps\_zombiemode_ai_monkey::play_attack_impacts( time );

	PlayFx( level._effect["wood_chunk_destory"], chunk.origin );
	if(chunk.script_noteworthy == "4" || chunk.script_noteworthy == "6")
	{
		chunk thread maps\_zombiemode_spawner::zombie_boardtear_offset_fx_horizontle(chunk, barrier);
	}
	else
	{
		chunk thread maps\_zombiemode_spawner::zombie_boardtear_offset_fx_verticle(chunk, barrier);
	}

	level thread maps\_zombiemode_blockers::remove_chunk( chunk, barrier, true, self );
	chunk maps\_zombiemode_blockers::update_states("destroyed");
	chunk notify("destroyed");

	wait(time);

}

_sort_by_num_boards(barriers)
{
	// just return barriers for now
	return barriers;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

_watch_for_powerups()
{
	if ( !IsDefined(level.monkey_zombie_spawners) || level.monkey_zombie_spawners.size == 0 )
	{
		return;
	}

	level waittill("powerup_dropped", powerup);

	level thread _watch_for_powerups();

	if(!isDefined(powerup))
	{
		return;
	}

	if ( level.round_number < level.nextMonkeyStealRound )
	{
		return;
	}

	wait .5;

	if ( _canGrabPowerup(powerup) )
	{
		_grab_powerup(powerup);
	}
}

_canGrabPowerup(powerup)
{
	return IsDefined(powerup) && (!IsDefined(powerup.claimed) || !powerup.claimed);
}

_grab_powerup(powerup)
{
	powerup endon("powerup_timedout");

	// just use the first spawner and teleport the monkey (like dogs)
	spawner = level.monkey_zombie_spawners[0];

	monkey = spawner StalingradSpawn();
	while ( spawn_failed(monkey) )
	{
		//iprintln("monkey spawn failed");
		wait_network_frame();
		monkey = spawner StalingradSpawn();
	}

	//Try always stealing
	level.nextMonkeyStealRound = 1; //level.round_number + RandomIntRange(2,4);
	/#
	cheat = GetDvarInt("monkey_steal_debug");
	if ( cheat )
	{
		// just slam it down so monkeys chase powerups every time
		level.nextMonkeyStealRound = 1;
	}
    #/

	//Players are getting hung up on monkeys and not understanding why.
	//NOTE: If we turn off collision we will not get aim assist
	//monkey setplayercollision(0);

	monkey.ignore_enemy_count = true;
	monkey.meleeDamage = 10;
	monkey.custom_damage_func = ::monkey_temple_custom_damage;

	monkey ForceTeleport(powerup.origin, monkey.angles);
	location = monkey _monkey_GetSpawnLocation(powerup.origin);
	monkey ForceTeleport( location, monkey.angles );
	monkey.deathFunction = ::_monkey_zombieTempleEscapeDeathCallback;
	monkey.shrink_ray_fling = ::_monkey_TempleFling;
	monkey.zombie_sliding = ::_monkey_TempleSliding;

	monkey.no_shrink = false;
	monkey.ignore_solo_last_stand = 1;

	monkey disable_pain();

	// Don't play fx to help sell that monkeys come from enviroment
	//PlayFX( level._effect["monkey_death"], monkey.origin );
	//playsoundatposition( "zmb_stealer_spawn", monkey.origin );

	spawner.count = 100;
	spawner.last_spawn_time = GetTime();

	// path to the powerup
	monkey thread monkey_zombie_choose_sprint_temple();
	//monkey thread maps\_zombiemode_ai_monkey::play_random_monkey_vox();

	monkey.powerup_to_grab = powerup;
	monkey thread _monkey_zombie_grenade_watcher();
	monkey thread _monkey_CheckPlayableArea();
	monkey thread _monkey_timeout();
	monkey thread _monkey_StealPowerup();
}

_monkey_play_stolen_loop()
{
	self endon( "death" );
	self endon("powerup_dropped");

	while(1)
	{
		playsoundatposition( "zmb_stealer_stolen", self.origin );
		wait 0.845;
	}

}

_monkey_GetSpawnLocation(location)
{
//	printTextStop();

	best = self monkey_GetMonkeySpawnLocation(700, false, true);
	if(!isDefined(best))
	{
		best = self monkey_GetMonkeySpawnLocation(700, true, false);
	}
	if(!isDefined(best))
	{
		best = self monkey_GetMonkeySpawnLocation(0, false, false);
	}

	// if we still haven't found a location, just use the powerup's origin
	ret = location;
	if ( IsDefined(location) )
	{
		ret = getBarrierAttackLocation(best);
	}

	return ret;
}

_monkey_StealPowerup()
{
	self endon("death");
	self endon("end_monkey_steal");

	self _monkey_GrabPowerup();

	//If we don't have a power up and we have not attacked the player already
	if(!isDefined(self.powerUp) && !is_true(self.attack_player))
	{
		self monkey_attack_player();
	}

	self thread _monkey_PathCheck();
	self _monkey_Escape();

}

_monkey_PathCheck()
{
	self notify( "end_pathcheck" );
	self endon( "end_pathcheck" );
	self endon( "escape_goal" );
	self endon( "death" );

	self waittill( "bad_path" );

	self notify( "end_monkey_steal" );
	self.melee_count = 0;

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if ( is_player_valid( players[i] ) )
		{
			self.player_stole_power_up = players[i];
		}
	}

	self monkey_attack_player();
	self thread _monkey_StealPowerup();
}

_monkey_GrabPowerup()
{
	if (isDefined(self.powerup_to_grab))
	{
		self thread _monkey_watch_for_death();
		self.goalradius = 16;
		self SetGoalPos( self.powerup_to_grab.origin );
		self _monkey_Grap_powerup_wait();
	}

	if ( _canGrabPowerup(self.powerup_to_grab) )
	{
		//Slow down because power up is heavy
		self monkey_zombie_choose_run_temple();

		self.powerup_to_grab show();
		self _monkey_BindPowerup(self.powerup_to_grab);
		self.powerup = self.powerup_to_grab;
		self.powerup_to_grab = undefined;

		if(isDefined(self.powerup.grab_count))
		{
			self.powerup.grab_count++;
		}
		else
		{
			self.powerup.grab_count = 1;
		}

		//Set up red fx so players know they can not grab the power up
		self.powerup thread powerup_red(self);

		self.powerup thread _powerup_Randomize(self);

		// stop all the normal powerup threads
		self thread _monkey_play_stolen_loop();
		self.powerup.stolen = true;
		self.powerup notify("powerup_grabbed");

		self thread player_random_response_to_theft();
	}
}

player_random_response_to_theft()
{
	players = get_players();

	for(i=0;i<players.size;i++)
	{
		if( distancesquared( self.origin, players[i].origin ) <= 500*500 )
		{
			players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "thief_steal" );
			return;
		}
	}
}

_monkey_Grap_powerup_wait()
{
	self endon("goal");

	self.powerup_to_grab waittill("death");
	self.player_stole_power_up = self.powerup_to_grab.power_up_grab_player;
}

_monkey_watch_for_death()
{
	self waittill("death");
	if( isDefined(self.powerup_to_grab) )
	{
		self.powerup_to_grab.claimed = false;
		level notify("powerup_dropped", self.powerup_to_grab);
	}

}

powerup_red(monkey)
{
	monkey endon("death");

	//Stop the green fx
	if(isDefined(self.fx_green))
	{
		self.fx_green delete();
	}

	self.fx_red = maps\_zombiemode_net::network_safe_spawn( "monkey_red_powerup", 2, "script_model", self.origin );
	self.fx_red setmodel("tag_origin");
	self.fx_red LinkTo(self);
	playfxontag(level._effect["powerup_on_red"],self.fx_red,"tag_origin");
}

_monkey_Escape()
{
	self endon("death");
	self endon("end_monkey_steal");

	self notify( "stop_find_flesh" );

	self.escaping = true;
	self _monkey_add_time();

	location = (0,0,0);
	angles = (0,0,0);
	playExitAnim = false;
	if(level.stealer_monkey_exits.size>0)
	{
		playExitAnim = true;
		randStruct = random(level.stealer_monkey_exits);
		location = randStruct.origin;
		angles = randStruct.angles;
	}
	else
	{
		valid_escapes = self ent_GatherValidBarriers();

		// now run to the farthest away valid barrier to give players time to shoot him
		maxDist = 0.0;
		bestBarrier = undefined;
		for ( i = 0; i < valid_escapes.size; i++ )
		{
			dist2 = DistanceSquared(self.origin, valid_escapes[i].origin);
			if ( dist2 > maxDist )
			{
				maxDist = dist2;
				bestBarrier = valid_escapes[i];
			}
		}

		location = getBarrierAttackLocation(bestBarrier);
	}

	self.goalradius = 8;
	self SetGoalPos( location );
	self waittill( "goal" );
	self notify( "escape_goal" );

	if(playExitAnim)
	{
		if(!isDefined(angles))
		{
			angles = (0,0,0);
		}
		escapeAnim = %ai_zombie_monkey_pap_escape;
		self animscripted("monkey_steal_exit", location, angles, escapeAnim);
		wait( GetAnimLength( escapeAnim ) );
	}

	hasPowerUp = IsDefined(self.powerup);
	if ( hasPowerUp )
	{
		level notify("monkey_powerup_escape");
	}

	level thread escape_monkey_counter(hasPowerUp);

	self _monkey_remove();
}

escape_monkey_counter(hasPowerUp)
{
	if(!isDefined(level.monkey_escape_count))
	{
		level.monkey_escape_count = 0;
		level.monkey_escape_with_powerup_count = 0;
	}

	level.monkey_escape_count++;
	if(hasPowerUp)
	{
		level.monkey_escape_with_powerup_count++;
	}

	if(level.monkey_escape_with_powerup_count%5 == 0)
	{
		level thread launch_monkey();
	}
}

launch_monkey()
{
	//Hard coded launch location behind the temple
	effectEnt = Spawn("script_model", (-24, 1448, 1000));

	if(isDefined(effectEnt))
	{
		effectEnt endon("death");
		effectEnt SetModel("tag_origin");
		effectEnt.angles = (90,0,0);

		PlayFXOnTag(level._effect["monkey_launch"], effectEnt, "tag_origin" );

		launchTime = 6;
		effectEnt MoveTo(effectEnt.origin + (0,0,2500), launchTime, 3);
		wait launchTime;
		effectEnt Delete();
	}
}

_monkey_CheckPlayableArea()
{
	self endon("death");

	canDamage = true;

	areas = getentarray("player_volume","script_noteworthy");

	while ( true )
	{
		inArea = false;
		for ( i = 0; i < areas.size && !inArea; i++ )
		{
			inArea = self IsTouching(areas[i]);
		}

		if ( canDamage && !inArea )
		{
			println("monkey no damage");
			canDamage = false;
			self magic_bullet_shield();

		}
		else if ( !canDamage && inArea )
		{
			println("monkey damage");
			canDamage = true;
			self stop_magic_bullet_shield();
		}

		wait(0.2);
	}
}

_monkey_timeout()
{
	self endon("death");

	if(!isDefined(self.endTime))
	{
		self.endTime = GetTime() + 60000;
	}

	while(self.endTime>GetTime())
	{
		wait .5;
	}

	// remove ourself
	self _monkey_remove();
}

_monkey_add_time()
{
	self.endTime = GetTime() + 60000;
}

_monkey_zombieTempleEscapeDeathCallback()
{
	self.grenadeAmmo = 0;

	playsoundatposition("zmb_stealer_death", self.origin);
	//self thread maps\_zombiemode_audio::do_zombies_playvocals( "death", self.animname );
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();

	if( isdefined( self.attacker ) && isPlayer( self.attacker ) )
	{
		self.attacker maps\_zombiemode_audio::create_and_play_dialog( "kill", "thief" );

		//Special bonus if you kill the monkey before he hits you
		isFavoriteEnemy = isDefined(self.favoriteenemy) && self.favoriteenemy == self.attacker;
		noMeleeHits = !isdefined(self.melee_count) || self.melee_count==0;
		/*if( is_true(self.attacking_player) && noMeleeHits && isFavoriteEnemy )
		{
			self.attacker maps\_zombiemode_score::player_add_points( "thundergun_fling", 500, (0,0,0), false );
		}*/

		if(!is_true(self.nuked) && !is_true(self.trap_death))
		{
			self.attacker maps\_zombiemode_score::player_add_points( "damage" );
		}
	}

	if ( IsDefined(self.powerup) )
	{
		self _monkey_dropStolenPowerUp();
	}
//	else if ( _canGrabPowerup(self.powerup_to_grab) && (!IsDefined(self.nuked) || !self.nuked) )
//	{
//		level thread maps\_zombiemode_powerups::specific_powerup_drop( "full_ammo", self.origin );
//	}
	if( "rottweil72_upgraded_zm" == self.damageweapon && "MOD_RIFLE_BULLET" == self.damagemod )
	{
		self thread _monkey_temple_dragons_breath_flame_death_fx();
	}

	if(is_true(self.do_gib_death))
	{
		self thread _monkey_gib();
		self delayThread(0.05, ::self_delete);
	}

	return false;
}

_monkey_temple_dragons_breath_flame_death_fx()
{
	if ( self.isdog )
	{
		return;
	}

	if( !IsDefined( level._effect ) || !IsDefined( level._effect["character_fire_death_sm"] ) )
	{
/#
		println( "^3ANIMSCRIPT WARNING: You are missing level._effect[\"character_fire_death_sm\"], please set it in your levelname_fx.gsc. Use \"env/fire/fx_fire_player_sm\"" );
#/
		return;
	}

	PlayFxOnTag( level._effect["character_fire_death_sm"], self, "J_SpineLower" );

	tagArray = [];
	if( !IsDefined( self.a.gib_ref ) || self.a.gib_ref != "left_arm" )
	{
		tagArray[tagArray.size] = "J_Elbow_LE";
		tagArray[tagArray.size] = "J_Wrist_LE";
	}
	if( !IsDefined( self.a.gib_ref ) || self.a.gib_ref != "right_arm" )
	{
		tagArray[tagArray.size] = "J_Elbow_RI";
		tagArray[tagArray.size] = "J_Wrist_RI";
	}
	if( !IsDefined( self.a.gib_ref ) || (self.a.gib_ref != "no_legs" && self.a.gib_ref != "left_leg") )
	{
		tagArray[tagArray.size] = "J_Knee_LE";
		tagArray[tagArray.size] = "J_Ankle_LE";
	}
	if( !IsDefined( self.a.gib_ref ) || (self.a.gib_ref != "no_legs" && self.a.gib_ref != "right_leg") )
	{
		tagArray[tagArray.size] = "J_Knee_RI";
		tagArray[tagArray.size] = "J_Ankle_RI";
	}

	tagArray = array_randomize( tagArray );
	PlayFxOnTag( level._effect["character_fire_death_sm"], self, tagArray[0] );
}

_monkey_dropStolenPowerUp()
{
	returnPowerUp = self.powerup;
	if( isdefined(self.powerup))
	{
		self notify("powerup_dropped");
		self.powerup notify("stop_randomize");

		if( isDefined(self.powerup.fx_red) )
		{
			self.powerup.fx_red delayThread( 0.1, ::self_delete );// Delete();
			self.powerup.fx_red = undefined;
		}

		//Send more monkeys after it
		self.powerup.claimed = false;
		level notify("powerup_dropped", self.powerup);

		origin = self.origin;
		if(is_true(self.is_traversing))
		{
			origin = groundpos( self.origin + (0,0,10) );
		}

		//Move off the ground a little
		origin = origin + (0,0,40);
		self.powerup Unlink();

		self.powerup.origin = origin;

		self.powerup thread maps\_zombiemode_powerups::powerup_timeout();
		self.powerup thread maps\_zombiemode_powerups::powerup_wobble();
		self.powerup thread maps\_zombiemode_powerups::powerup_grab();
		self.powerup = undefined;
	}

	return returnPowerUp;
}

_monkey_remove(playFX)
{
	self notify("remove");

	if(!isdefined(playFX))
	{
		playFX = true;
	}

	if ( IsDefined(self.powerup) )
	{
		if( isdefined(self.powerup.fx_red) )
		{
			self.powerup.fx_red Delete();
			self.powerup.fx_red = undefined;
		}
		self.powerup Delete();
	}

	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();
// Don't play fx to help sell that monkeys come from enviroment
//	if(playFX)
//	{
//		PlayFX( level._effect["monkey_death"], self.origin );
//		playsoundatposition( "zmb_bolt", self.origin );
//	}

	self Delete();
}

_getConnectedZoneNames(zoneName, params)
{
	if ( !IsDefined(params.tested) )
	{
		params.tested = [];
	}

	ret = [];
	if ( !IsDefined(params.tested[zoneName]) )
	{
		// add ourself to the list
		ret[0] = zoneName;

		// mark ourself as test so to not repeat work/recurse forever
		params.tested[zoneName] = true;

		zone = level.zones[zoneName];
		azKeys = GetArrayKeys( zone.adjacent_zones );
		for ( i=0; i < azKeys.size; i++ )
		{
			name = azKeys[i];
			adjZone = zone.adjacent_zones[name];
			globalZone = level.zones[name];
			if ( adjZone.is_connected && globalZone.is_enabled )
			{
				zoneNames = _getConnectedZoneNames(name, params);
				ret = array_combine(ret, zoneNames);
			}
		}
	}

	return ret;
}

_powerup_Randomize(monkey)
{
	self endon("stop_randomize");
	monkey endon("remove");

	powerup_cycle = array("nuke", "double_points", "insta_kill");

	if(level.chest_moves >= 1)
	{
		powerup_cycle = add_to_array(powerup_cycle, "fire_sale");
	}

	if(level.gamemode != "survival")
	{
		powerup_cycle = add_to_array(powerup_cycle, "bonus_points_team");
		powerup_cycle = add_to_array(powerup_cycle, "meat");
	}

	if(level.gamemode == "gg")
	{
		powerup_cycle = add_to_array(powerup_cycle, "upgrade_weapon");
	}

	powerup_cycle = array_randomize_knuth(powerup_cycle);

	powerup_cycle[powerup_cycle.size] = "full_ammo"; //Ammo is always last

	//Find current power up name
	currentPowerUp = undefined;
	keys = GetArrayKeys( level.zombie_powerups );
	for(i=0;i<keys.size;i++)
	{
		if(level.zombie_powerups[keys[i]].powerup_name == self.powerup_name)
		{
			currentPowerUp = keys[i];
			break;
		}
	}
	//Move the current powerup to the front of the list
	if(isdefined(currentPowerUp))
	{
		powerup_cycle = array_remove(powerup_cycle, currentPowerUp);
		powerup_cycle = array_insert(powerup_cycle, currentPowerUp, 0);
	}
	//Add Perk bottle if this is a max ammo
	if(currentPowerUp == "full_ammo") //&& self.grab_count == 1
	{
		index = randomintrange(1, powerup_cycle.size - 1);
		powerup_cycle = array_insert(powerup_cycle, "free_perk", index);
	}

	wait 1;

	index = 1; //Skip first because it is set to the current powerup
	while ( true )
	{
		powerupName = powerup_cycle[index];
		index++;
		if ( index >= powerup_cycle.size )
		{
			index = 0;
		}

		/*struct = level.zombie_powerups[powerupName];

		self SetModel( struct.model_name );

		self.powerup_name 	= struct.powerup_name;
		self.hint 			= struct.hint;

		if( IsDefined( struct.fx ) )
		{
			self.fx = struct.fx;
		}*/

		self maps\_zombiemode_powerups::powerup_setup( powerupName );

		monkey _monkey_BindPowerup(self);

		if(powerupName=="free_perk")
		{
			wait .25;
		}
		else
		{
			wait 1;
		}
	}
}


array_randomize_knuth(array)
{
	n = array.size;
	while ( n > 0 )
	{
		// integer [0,n)
		index = RandomInt(n);
		n = n - 1;
		temp = array[index];
		array[index] = array[n];
		array[n] = temp;
	}

	return array;
}

_monkey_BindPowerup(powerup)
{
	powerup Unlink();

	powerup.angles = self.angles;
	powerup.origin = self.origin;

	offset = (0,0,40.0);
	angles = (0,0,0);

	//switch ( powerup.powerup_name )
	//{
	//case "fire_sale":
	//	offset = (0,0,50.0);
	//	break;
	//case "insta_kill":
	//	angles = (0,90,0);
	//	break;
	//default:
	//	break;
	//}

	powerup LinkTo(self, "tag_origin", offset, angles);
}

_monkey_gib()
{
	if(is_mature())
	{
		playfx(level._effect["monkey_gib"], self.origin);
	}
	else
	{
		playfx( level._effect["monkey_gib_no_gore"], self.origin );
	}
	self Hide();
}


_monkey_TempleFling( player )
{
	self.do_gib_death = true;
	self DoDamage( self.health + 666, self.origin, player);
}

_monkey_TempleSliding( slide_node )
{
	self endon( "death" );
	level endon( "intermission" );

	if ( is_true( self.sliding ) )
	{
		return;
	}

	self notify("end_monkey_steal");

	self.is_traversing = true;
	self notify("zombie_start_traverse");
	self thread maps\zombie_temple_waterslide::zombie_slide_watch();

	self thread maps\zombie_temple_waterslide::play_zombie_slide_looper();

	self.sliding = true;
	self.ignoreall = true;

	//self notify( "stop_find_flesh" );
	//self notify( "zombie_acquire_enemy" );

	self thread set_monkey_slide_anim();

	self SetGoalNode(slide_node);
	check_dist_squared = 60*60;
	while(Distancesquared(self.origin, slide_node.origin) > check_dist_squared )//self.goalradius)
	{
		wait(0.01);
	}
	//self waittill("goal");

	self thread monkey_zombie_choose_sprint_temple();

	self notify("water_slide_exit");
	self.sliding = false;
	self.is_traversing = false;
	self notify("zombie_end_traverse");
	//self.ignoreall = false;

	self thread _monkey_StealPowerup();
}

set_monkey_slide_anim()
{
	self set_run_anim( "slide" );
	self.run_combatanim = level.scr_anim["monkey_zombie"]["slide"];
	self.crouchRunAnim = level.scr_anim["monkey_zombie"]["slide"];
	self.crouchrun_combatanim = level.scr_anim["monkey_zombie"]["slide"];
	self.needs_run_update = true;
}




///////////////
// Non AI
//////////////
#using_animtree( "critter" );
precache_ambient_monkey_anims()
{
	level.scr_anim[ "monkey" ][ "calm_idle" ][0] 		= %ai_zombie_monkey_calm_idle_03;
	level.scr_anim[ "monkey" ][ "excited" ][0] 			= %a_monkey_freaked_01;
	level.scr_animtree[ "monkey" ] = #animtree;

	level.scr_anim[ "monkey" ][ "shot_death" ][0]		 = %a_monkey_shot_death;

	//	level.scr_anim[ "monkey" ][ "calm_pace" ][0] 			= %a_monkey_calm_pace;
	//	level.scr_anim[ "monkey" ][ "calm_idle_2_pace" ][0] = %a_monkey_calm_idle_2_pace;
	//	level.scr_anim[ "monkey" ][ "calm_pace_2_idle" ][0] = %a_monkey_calm_pace_2_idle;
}

monkey_ambient_init()
{
	flag_init("monkey_ambient_excited");
	monkey_ambient_level_set_next_sound();
	level.ambient_monkey_locations = GetStructArray( "monkey_ambient", "targetname" );

	level thread monkey_crowd_noise();
	level thread monkey_ambient_drops_add_array();
	level thread monkey_ambient_drops_remove_array();

	level thread manage_ambient_monkeys(4);
}
monkey_crowd_noise()
{

	//Crowd sounds
	origin1 = GetEnt("evt_monkey_crowd01_origin","targetname");
	origin2 = GetEnt("evt_monkey_crowd02_origin","targetname");

	if(!isDefined(origin1) || !isDefined(origin2))
	{
		return;
	}

	while(1)
	{
		flag_wait("monkey_ambient_excited");

		origin1 playloopsound("evt_monkey_crowd01",2);
		origin2 playloopsound("evt_monkey_crowd02",2);

		while(flag("monkey_ambient_excited"))
		{
			wait .1;
		}

		origin1 stoploopsound(3);
		origin2 stoploopsound(3);
	}

}

manage_ambient_monkeys(max_monkeys)
{
	checkZone = "temple_start_zone";

	level.active_monkeys = [];

	playerInZone = false;
	hackToFixStart = true;
	while ( true )
	{
		if(!hackToFixStart)
		{
			wait_network_frame();
		}

		if ( zone_is_active(checkZone) || hackToFixStart )
		{
			if ( level.active_monkeys.size == 0 && !playerInZone )
			{
				level.ambient_monkey_locations = array_randomize_knuth(level.ambient_monkey_locations);
				for ( i = 0; i < max_monkeys; i++ )
				{
					level.ambient_monkey_locations[i] monkey_ambient_spawn();
					if(!hackToFixStart)
					{
						wait_network_frame();
					}
					wait_network_frame();//May need two, because multiple monkeys are showing up in the same snap shot
				}
			}

			if(hackToFixStart)
			{
				while(!zone_is_active(checkZone))
				{
					wait .1;
				}
			}
			hackToFixStart = false;
			playerInZone = true;
		}
		else
		{
			playerInZone = false;
			array_thread( level.active_monkeys, ::cleanup_monkey );
		}
	}
}

zone_is_active( zone_name )
{
	if ( !IsDefined(level.zones) ||
		!IsDefined(level.zones[ zone_name ]) ||
		!level.zones[ zone_name ].is_active )
	{
		return false;
	}

	return true;
}

cleanup_monkey()
{
	self.location.monkey = undefined;
	self notify( "monkey_cleanup" );
	level.active_monkeys = array_remove(level.active_monkeys, self);
	self.anim_spot Delete();
	self Delete();
}

monkey_ambient_spawn()
{
	self.monkey = Spawn( "script_model", self.origin );
	self.monkey.angles = self.angles;
	self.monkey SetModel( "c_zombie_monkey" );
	self.monkey.animname = "monkey";
	self.monkey UseAnimTree( #animtree );
	self.monkey setCanDamage(true);
	self.health = 9999;

	maps\_zombiemode_weap_shrink_ray::add_shrinkable_object(self.monkey);

	self.monkey.location = self;

	self.monkey.anim_spot = Spawn("script_model", self.origin);
	self.monkey.anim_spot.angles = self.angles;
	self.monkey.anim_spot SetModel("tag_origin");

	level.active_monkeys = array_add(level.active_monkeys, self.monkey);

	self.monkey monkey_ambient_set_next_sound();
	self.monkey thread monkey_ambient_noise();
	self.monkey thread monkey_ambient_watch_for_power_up();
	self.monkey thread monkey_ambient_wait_to_be_shot();
	self.monkey thread monkey_ambient_idle();
	self.monkey thread monkey_ambient_shrink();
}

monkey_ambient_idle()
{
	self.anim_spot notify("monkey_stop_loop");
	self.anim_spot thread maps\_anim::anim_loop_aligned( self, "calm_idle", "tag_origin", "monkey_stop_loop" );
	self SetAnimTime( level.scr_anim[ "monkey" ][ "calm_idle"][0], RandomFloat( 0.99 ) );
}

monkey_ambient_wait_to_be_shot()
{
	self endon("monkey_cleanup");

	self waittill( "damage", damage, attacker, direction_vec, point, type, modelName, tagName, partName, iDFlags );

	if(isdefined(level.cross_bow_bolts))
	{
		level.cross_bow_bolts = array_removeUndefined(level.cross_bow_bolts);
		for(i=0;i<level.cross_bow_bolts.size;i++)
		{
			bolt = level.cross_bow_bolts[i];
			linkedTo = bolt GetLinkedEnt();
			if(isdefined(linkedTo) && linkedTo==self)
			{
				bolt delete();
				//snigl: Tried to unlink the bolt but it didn't work:(
//				bolt unlink();
//				wait_network_frame();
//				physicsexplosionsphere(bolt.origin, 1, 1, 1); //Need to wake it up
			}
		}
	}

	self.alive = false;
	self notify("monkey_killed");
	playsoundatposition("zmb_stealer_death", self.origin);
	self startragdoll();

	//temp test
//	if( IsDefined( level._effect["napalm_explosion"] ) )
//	{
//		playfx(level._effect["napalm_explosion"], self.origin);
//	}
//	radiusdamage(self.origin, 200, 300, 100);

	//self.anim_spot maps\_anim::anim_single_aligned(self, "shot_death");
	//self monkey_ambient_wait_for_remove();
	//self.anim_spot thread monkey_ambient_wait_to_spawn();
	//self delete();
}
monkey_ambient_wait_for_remove()
{
	self endon("monkey_cleanup");
	self endon("monkey_killed");

	wait 10;
}

monkey_ambient_drops_add_array()
{
	self endon("monkey_cleanup");
	self endon("monkey_killed");

	level.monkey_drops = [];

	while(1)
	{
		level waittill("powerup_dropped", powerup);
		level.monkey_drops[level.monkey_drops.size] = powerup;

		if(level.monkey_drops.size == 1)
		{
			flag_set("monkey_ambient_excited");
		}
	}
}

monkey_ambient_drops_remove_array()
{
	while(1)
	{
		previousSize = level.monkey_drops.size;
		level.monkey_drops = remove_undefined_from_array(level.monkey_drops);

		for(i=0;i<level.monkey_drops.size;i++)
		{
			if(IsDefined(level.monkey_drops[i].stolen) && level.monkey_drops[i].stolen)
				level.monkey_drops = array_remove(level.monkey_drops, level.monkey_drops[i]);
		}

		if(level.monkey_drops.size == 0 && previousSize != 0)
		{
			flag_clear("monkey_ambient_excited");
		}
		wait .1;
	}
}

monkey_ambient_watch_for_power_up()
{
	self endon("monkey_killed");
	self endon("monkey_cleanup");

	while ( true )
	{
		flag_wait("monkey_ambient_excited");

		wait randomfloatrange(0, 1); //Don't start at the same time

		self.excited = true;
		self thread monkey_ambient_excited_noise();
		self.anim_spot notify("monkey_stop_loop");
		self.anim_spot thread maps\_anim::anim_loop_aligned( self, "excited", "tag_origin", "monkey_stop_loop" );
		self SetAnimTime( level.scr_anim[ "monkey" ][ "excited" ][0], RandomFloat( 0.99 ) );

		while(flag("monkey_ambient_excited"))
		{
			wait .1;
		}

		//So all anims don't line up
		wait randomfloatrange(0, 4);

		self.excited = false;
		monkey_ambient_idle();
	}
}
monkey_ambient_level_set_next_sound()
{
	level.ambient_monkey_next_sound_time = GetTime() + randomFloatRange(3,6)*1000;
}
monkey_ambient_set_next_sound()
{
	self.next_sound_time = GetTime() + randomFloatRange(6,12)*1000;
}
monkey_ambient_can_make_sound()
{
	if(GetTime() < level.ambient_monkey_next_sound_time)
	{
		return false;
	}

	if(GetTime() < self.next_sound_time)
	{
		return false;
	}

	return true;
}
monkey_ambient_noise()
{
	self endon("monkey_killed");
	self endon("monkey_cleanup");

	while(1)
	{
		if(self monkey_ambient_can_make_sound())
		{
			//PlaySound
			self thread monkey_ambient_play_sound("zmb_stealer_ambient");
			self monkey_ambient_set_next_sound();
			monkey_ambient_level_set_next_sound();
		}
		wait .1;
	}
}

monkey_ambient_excited_noise()
{
	self endon("monkey_killed");
	self endon("monkey_cleanup");

	while(self.excited)
	{
		self thread monkey_ambient_play_sound("zmb_stealer_excited");
		wait randomfloatrange(1.5, 3.0);
	}
}

monkey_ambient_play_sound(soundName)
{
	while(is_true(level.monkey_ambient_sound_choke))
	{
		wait_network_frame();
	}

	//println("^2 Monkey " + self getentitynumber() + " " + soundName + " @ " + gettime());
	level.monkey_ambient_sound_choke = true;
	self playsound(soundname);
	wait_network_frame();
	level.monkey_ambient_sound_choke = false;
}

monkey_ambient_shrink()
{
	waitStr = self waittill_any_return("shrunk","death","monkey_killed","monkey_cleanup");
	maps\_zombiemode_weap_shrink_ray::remove_shrinkable_object(self);
	if(waitStr=="shrunk")
	{
		self thread _monkey_gib();
		self thread cleanup_monkey();
	}
}

monkey_ambient_gib_all()
{
	for(i=level.active_monkeys.size-1; i>=0; i--)
	{
		monkey = level.active_monkeys[i];
		monkey thread _monkey_gib();
		monkey thread cleanup_monkey();
	}
}

/////////////////////
//Throw back grenades
/////////////////////

//-----------------------------------------------------------------
// checks if grenade is close enough to go after
//-----------------------------------------------------------------
#using_animtree( "generic_human" );
_monkey_zombie_grenade_watcher()
{
	self endon( "death" );

	grenade_respond_dist_sq = 120 * 120;

	while ( 1 )
	{
		if ( is_true( self.monkey_grenade ) )
		{
			wait_network_frame();
			continue;
		}

		if ( level.monkey_grenades.size > 0 )
		{
			for ( i = 0; i < level.monkey_grenades.size; i++ )
			{
				grenade = level.monkey_grenades[i];
				if ( !isdefined( grenade ) || isdefined( grenade.monkey ) )	// monkey already responding
				{
					wait_network_frame();
					continue;
				}

				if(isDefined(self.powerup))
				{
					wait_network_frame();
					continue;
				}

				grenade_dist_sq = DistanceSquared( self.origin, grenade.origin );
				if ( grenade_dist_sq <= grenade_respond_dist_sq )
				{
					grenade.monkey = self;
					self.monkey_grenade = grenade;
					self monkey_zombie_grenade_response();
					break;
				}
			}
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// checks if grenade is close enough to go after
//-----------------------------------------------------------------
monkey_zombie_grenade_response()
{
	self endon( "death" );

	self notify("end_monkey_steal");

	self monkey_zombie_grenade_pickup();

	self thread _monkey_StealPowerup();

}


monkey_zombie_grenade_pickup()
{
	self endon( "death" );

	pickup_dist_sq = 32*32;
	picked_up = false;

	while ( isdefined( self.monkey_grenade ) )
	{
		self SetGoalPos( self.monkey_grenade.origin );

		grenade_dist_sq = DistanceSquared( self.origin, self.monkey_grenade.origin );
		if ( grenade_dist_sq <= pickup_dist_sq )
		{
			self.monkey_thrower = self.monkey_grenade.thrower;
			self.monkey_grenade delete();
			self.monkey_grenade = undefined;
			picked_up = true;
		}

		wait_network_frame();
	}

	if ( picked_up )
	{
		while ( 1 )
		{
			self SetGoalPos( self.monkey_thrower.origin );
			target_dir = self.monkey_thrower.origin - self.origin;
			monkey_dir = AnglesToForward( self.angles );

			dot = VectorDot( VectorNormalize( target_dir ), VectorNormalize( monkey_dir ) );
			if ( dot >= 0.5 )
			{
				break;
			}

			wait_network_frame();
		}

		self thread monkey_zombie_grenade_throw( self.monkey_thrower );
		self waittill( "throw_done" );
	}
}

//-----------------------------------------------------------------
// wait for anim notetrack to throw a grenade
//-----------------------------------------------------------------
monkey_zombie_grenade_throw_watcher( target, animname )
{
	self endon( "death" );

	self waittillmatch( animname, "grenade_throw" );

	throw_angle = RandomIntRange( 20, 30 );

	dir = VectorToAngles( target.origin - self.origin );
	dir = ( dir[0] - throw_angle, dir[1], dir[2] );
	dir = AnglesToForward( dir );

	velocity = dir * 550;

	fuse = RandomFloatRange( 1, 2 );
	hand_pos = self GetTagOrigin( "J_Thumb_RI_1");
	//hand_pos = self GetTagOrigin( "TAG_WEAPON_RIGHT" );

	grenade_type = target get_player_lethal_grenade();
	target MagicGrenadeType( grenade_type, hand_pos, velocity, fuse );
}

//-----------------------------------------------------------------
// plays a throw anim followed by a taunt anim
//-----------------------------------------------------------------
monkey_zombie_grenade_throw( target )
{
	self endon( "death" );

	throw_anim = [];

	forward = VectorNormalize( AnglesToForward( self.angles ) );
	end_pos = self.origin + vector_scale( forward, 96 );

	if ( BulletTracePassed( self.origin, end_pos, false, undefined ) )
	{
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_01;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_02;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_03;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_04;
	}
	else
	{
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_01;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_02;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_03;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_04;
	}

	throw_back_anim = throw_anim[ RandomInt( throw_anim.size ) ];
	//self SetFlaggedAnimKnobAllRestart( "throw_back_anim", throw_back_anim, %body, 1, .1, 1 );
	self animscripted( "throw_back_anim", self.origin, self.angles, throw_back_anim );
	self thread monkey_zombie_grenade_throw_watcher( target, "throw_back_anim" );
	animscripts\traverse\zombie_shared::wait_anim_length( throw_back_anim, .02 );

//	choose = RandomInt( level._zombie_board_taunt["monkey_zombie"].size );
//	taunt_anim = level._zombie_board_taunt["monkey_zombie"][ choose ];
//	//self SetFlaggedAnimKnobAllRestart( "taunt_anim", taunt_anim, %body, 1, .1, 1 );
//	self animscripted( "taunt_anim", self.origin, self.angles, taunt_anim );
//	animscripts\traverse\zombie_shared::wait_anim_length( taunt_anim, .02 );

	self notify( "throw_done" );
}

///////////////
//Attack Player
///////////////
monkey_attack_player()
{
	self endon("death");

	self.attack_player = true; //Tried to attack player
	self.attacking_player = true; //Currently attacking the player

	players = getplayers();
	self.ignore_player = [];

	player = undefined;
	if(isDefined(self.player_stole_power_up) && is_player_valid(self.player_stole_power_up))
	{
		player = self.player_stole_power_up;
	}
	if( isDefined( player ) )
	{
		self.favoriteenemy = player;
		self thread monkey_obvious_vox();

		self _monkey_add_time();
		self thread monkey_pathing();

		self thread monkey_attack_player_wait_wrapper(self.favoriteenemy);
		self waittill("end_monkey_attacks");
	}


}
monkey_attack_player_wait_wrapper(player)
{
	self monkey_attack_player_wait(player);
	self monkey_stop_attck_player();
}
monkey_attack_player_wait(player)
{
	self endon( "death" );
	self endon("end_monkey_steal");

	attackTimeEnd = GetTime() + 20000;
	while(attackTimeEnd>GetTime())
	{
		if(!is_player_valid(player))
		{
			break;
		}

		if(isdefined(self.melee_count) && self.melee_count>=1)
		{
			break;
		}
		wait .1;
	}
}
monkey_stop_attck_player()
{
	self notify("end_monkey_attacks");
	self.ignoreall = true;

	//Only clear is attacking and enemy if we are alive.
	//Death functions want to know if monkey was attacking
	if(IsAlive(self))
	{
		self.favoriteenemy = undefined;
		self.attacking_player = false;
	}
}
monkey_pathing()
{
	self endon( "death" );
	self endon("end_monkey_attacks");

	self.ignoreall = false;
	self.pathEnemyFightDist = 64;
	self.meleeAttackDist = 64;
	while ( IsDefined( self.favoriteenemy) )
	{
		self.goalradius = 32;
		self OrientMode( "face default" );
		self SetGoalPos( self.favoriteenemy.origin );

		wait_network_frame();
	}
}

monkey_temple_custom_damage( player )
{
	self endon( "death" );

	damage = self.meleeDamage;
	if(!isDefined(self.melee_count))
	{
		self.melee_count = 0;
	}
	self.melee_count++;

	//Take monkey if hit by the monkey
	if(isDefined(player) && player.score>0)
	{
		pointsToSteal = int(min(player.score, 50));
		player maps\_zombiemode_score::minus_to_player_score( pointsToSteal );
	}

	return damage;
}

monkey_obvious_vox()
{
	self endon( "death" );
	self endon( "end_monkey_attacks" );

	while(1)
	{
		self playsound( "zmb_stealer_attack" );
		wait(randomfloatrange(2,4));
	}
}
