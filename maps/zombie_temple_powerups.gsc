/// zombie_temple_powerups.gsc

#include maps\_utility; 
#include common_scripts\utility; 
#include maps\_zombiemode_utility;
#include maps\_zombiemode_utility_raven;
#include maps\_zombiemode;  

// needs to be called after zombiemode has been setup (after powerups have been initialized)
init()
{
	level._zombiemode_special_powerup_setup = ::temple_special_powerup_setup;
	level._zombiemode_powerup_grab = :: temple_powerup_grab;

	maps\_zombiemode_powerups::add_zombie_powerup("monkey_swarm", "zombie_pickup_monkey", &"ZOMBIE_POWERUP_MONKEY_SWARM" );

	level.playable_area = getentarray("player_volume","script_noteworthy");

	level._effect["zombie_kill"] = LoadFX("impacts/fx_flesh_hit_body_fatal_lg_exit_mp");
}

temple_special_powerup_setup( powerup )
{
	// don't do anything
	return true;
}

temple_powerup_grab( powerup )
{
	if ( !IsDefined(powerup) )
	{
		return;
	}

	switch ( powerup.powerup_name )
	{
	case "monkey_swarm":
		level thread monkey_swarm(powerup);
		break;

	default:
		break;
	}
}

monkey_swarm( powerup )
{
	monkey_count_per_player = 2;

	// pause zombie spawning so we can get the monkeys in
	flag_clear("spawn_zombies");

	// spawn in the monkeys where the powerup dropped for now
	players = GetPlayers();

	level.monkeys_left_to_spawn = players.size * monkey_count_per_player;

	for ( i = 0; i < players.size; i++ )
	{
		players[i] thread player_monkey_think(monkey_count_per_player);
	}

	// wait until all the monkeys are spawned
	while ( level.monkeys_left_to_spawn > 0 )
	{
		wait_network_frame();
	}

	flag_set("spawn_zombies");
}

player_monkey_think(numMonkeys)
{
	// find monkey spawns in the level
	spawns = GetEntArray( "monkey_zombie_spawner", "targetname" );
	if ( spawns.size == 0 )
	{
		level.monkeys_left_to_spawn -= numMonkeys;
		return;
	}

	// TODO: find a good spot to spawn in monkeys
	spawnRadius = 10.0;

	zoneOverride = undefined;
	if ( IsDefined(self.is_on_waterslide) && self.is_on_waterslide )
	{
		zoneOverride = "caves1_zone";
	}
	else if ( IsDefined(self.is_on_minecart) && self.is_on_minecart )
	{
		zoneOverride = "waterfall_lower_zone";
	}

	barriers = self maps\zombie_temple_ai_monkey::ent_GatherValidBarriers(zoneOverride);

	println("Spawn Monkeys: " + numMonkeys);

	for ( i = 0; i < numMonkeys; i++ )
	{
		wait(RandomFloat(1.0, 2.0));

		zombie = self _ent_GetBestZombie(300.0);
		if ( !IsDefined(zombie) )
		{
			zombie = self _ent_GetBestZombie();
		}

		bloodFX = false;

		angles = (0, RandomFloat(360.0), 0);
		forward = AnglesToForward(angles);
		spawnLoc = self.origin + spawnRadius * forward;
		spawnAngles = self.angles;

		if ( IsDefined(zombie) )
		{
			// delete the zombie and increment the level count so we can make sure we get an ai in the world
			spawnLoc = zombie.origin + (0,0,50);
			spawnAngles = zombie.angles;
			zombie Delete();
			level.zombie_total++;
			bloodFX = true;
		}
		else if ( barriers.size > 0 )
		{
			// spawn the monkey by the closest, valid barrier to them to make sure they are not in solid
			// choose the closest barrier to the player
			best = undefined;
			bestDist = 0.0;
			for ( b = 0; b < barriers.size; b++ )
			{
				barrier = barriers[b];
				dist2 = DistanceSquared(barrier.origin, self.origin);
				if ( !IsDefined(best) || dist2 < bestDist )
				{
					best = barrier;
					bestDist = dist2;
				}
			}

			spawnLoc = maps\zombie_temple_ai_monkey::getBarrierAttackLocation(best);
			spawnAngles = best.angles;
		}

		// make sure we always decrement the count to let zombies start spawning again
		level.monkeys_left_to_spawn--;

		println("Spawning monkey");
		monkey = spawns[i] StalingradSpawn();

		if ( spawn_failed(monkey) )
		{
			println("monkey spawn failed");
			continue;
		}

		spawns[i].count = 100;
		spawns[i].last_spawn_time = GetTime();

		monkey.attacking_zombie = false;
		monkey.no_shrink = true;

		monkey SetPlayerCollision(false);

		monkey maps\_zombiemode_ai_monkey::monkey_prespawn();
	
		monkey ForceTeleport( spawnLoc, spawnAngles );

		if ( bloodFX )
		{
			PlayFX( level._effect["zombie_kill"], spawnLoc );
		}
		
		PlayFX( level._effect["monkey_death"], spawnLoc );
		
		playsoundatposition( "zmb_bolt", spawnLoc );

		monkey magic_bullet_shield();
		monkey disable_pain();

		monkey thread maps\_zombiemode_ai_monkey::monkey_zombie_choose_run();
		//monkey thread maps\_zombiemode_ai_monkey::play_random_monkey_vox();

		monkey thread monkey_powerup_timeout();
		monkey thread monkey_protect_player(self);
	}
}

monkey_powerup_timeout()
{
	wait(60.0);

	self.timeout = true;
	while ( self.attacking_zombie )
	{
		wait(0.1);
	}

	if ( IsDefined(self.zombie) )
	{
		// release our claim on the zombie
		self.zombie.monkey_claimed = false;
	}

	PlayFX( level._effect["monkey_death"], self.origin );
	playsoundatposition( "zmb_bolt", self.origin );

	self notify("timeout");
	self Delete();
}

monkey_protect_player(player)
{
	self endon("timeout");

	// wait a bit before doing anything
	wait(0.5);

	while ( true )
	{
		if ( IsDefined(self.timeout) && self.timeout )
		{
			self waittill("forever");
		}
		
		zombie = player _ent_GetBestZombie();
		
		if ( IsDefined(zombie) )
		{
			self thread monkey_attack_zombie(zombie);
			self waittill_any("bad_path", "zombie_killed");

			if ( IsDefined(zombie) )
			{
				zombie.monkey_claimed = false;
			}
		}
		else
		{
			goalDist = 64;
			checkDist2 = goalDist * goalDist;

			dist2 = DistanceSquared(self.origin, player.origin);
			if ( dist2 > checkDist2 )
			{
				self.goalradius = goalDist; 
				self SetGoalEntity( player );

				self waittill("goal");
				self SetGoalPos(self.origin);
			}
		}

		wait(0.5);
	}
}

#using_animtree("generic_human");
monkey_attack_zombie(zombie)
{
	self endon("bad_path");
	self endon("timeout");

	self.zombie = zombie;
	zombie.monkey_claimed = true;
	self.goalradius = 32; 
	self SetGoalPos( zombie.origin );

	// wait until we get there, or the zombie is killed by a player
	checkDist2 = self.goalradius * self.goalradius;
	while ( true ) 
	{
		if ( !IsDefined(zombie) || !IsAlive(zombie) )
		{
			self notify("zombie_killed");
			return;
		}

		dist2 = DistanceSquared(zombie.origin, self.origin);
		if ( dist2 < checkDist2 )
		{
			break;
		}

		self SetGoalPos(zombie.origin);

		wait_network_frame();
	}

	self.attacking_zombie = true;

	zombie_anim = %ai_zombie_taunts_9;
	zombie notify("stop_find_flesh");
	zombie animscripted("zombie_react", zombie.origin, zombie.angles, zombie_anim, "normal", %body, 1, 0.2);

	forward = AnglesToForward(zombie.angles);

	// link to the zombie and play our attack anim
	perk_attack_anim = %ai_zombie_monkey_attack_perks_front;
	time = getAnimLength( perk_attack_anim );
	self maps\_zombiemode_audio::do_zombies_playvocals( "attack", "monkey_zombie" );
	self animscripted( "perk_attack_anim", zombie.origin + forward * 35.0, zombie.angles - (0,180,0), perk_attack_anim, "normal", %body, 1, 0.2 );
	wait(time);

	self.attacking_zombie = false;
	if ( IsDefined(zombie) )
	{
		// don't let these zombies drop powerups
		zombie.no_powerups = true;

		// kill the zombie (pop his head off)
		zombie.a.gib_ref = "head";
		zombie dodamage(zombie.health + 666, zombie.origin);
		
		players = GetPlayers();
		for(i = 0; i < players.size; i++)
		{
			// nuke powerup does the same thing we want, w/o having to update the common files
			players[i] maps\_zombiemode_score::player_add_points( "nuke_powerup", 20 ); 
		}
	}

	self.zombie = undefined;
	self notify("zombie_killed");
}

_ent_GetBestZombie(minDist)
{
	bestZombie = undefined;
	bestDist = 0.0;

	// find the closest zombie to attack
	zombies = GetAiSpeciesArray( "axis", "all" );

	if ( IsDefined(minDist) )
	{
		bestDist = minDist * minDist;
	}
	else
	{
		bestDist = 99999999.0;
	}

	for ( i = 0; i < zombies.size; i++ )
	{
		z = zombies[i];
		if ( IsDefined(z.monkey_claimed) && z.monkey_claimed )
		{
			continue;
		}

		// ignore other monkeys
		if ( (IsDefined(z.animname) && z.animname == "monkey_zombie") )
		{
			continue;
		}

		// don't attach to napalm zombies (they are on fire) or sonic (make the player beat them)
		if ( z.classname == "actor_zombie_napalm" || z.classname == "actor_zombie_sonic" )
		{
			continue;
		}

		dist2 = DistanceSquared(z.origin,self.origin);
		if ( dist2 < bestDist )
		{
			valid = z _ent_InPlayableArea();
			if ( valid )
			{
				bestZombie = z;
				bestDist = dist2;
			}
		}
	}

	return bestZombie;

}

_ent_InPlayableArea()
{
	for (i = 0; i < level.playable_area.size; i++)
	{
		if (self IsTouching(level.playable_area[i]))
		{
			return true;
		}
	}

	return false;
}