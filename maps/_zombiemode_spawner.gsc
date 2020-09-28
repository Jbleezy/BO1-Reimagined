#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_net;
#include maps\_zombiemode_audio;


#using_animtree( "generic_human" );
init()
{
	level._CONTEXTUAL_GRAB_LERP_TIME = .3; // This is the time it takes to move into position for each bar.

	zombies = getEntArray( "zombie_spawner", "script_noteworthy" );

	for( i = 0; i < zombies.size; i++ )
	{
		if( is_spawner_targeted_by_blocker( zombies[i] ) )
		{
			zombies[i].is_enabled = false;
		}
	}

	array_thread(zombies, ::add_spawn_function, ::zombie_spawn_init);
//MJM - No sense in automatically calling this if you're not going to do rise behavior.
//	array_thread(zombies, ::add_spawn_function, ::zombie_rise);
	array_thread(zombies, ::add_spawn_function, maps\_zombiemode::round_spawn_failsafe);

	// I'm putting this in here for now so that we can fit in the ffotd
	//add player intersection tracker
	level thread track_players_intersection_tracker();
}


track_players_intersection_tracker()
{
	self endon( "disconnect" );
	self endon( "death" );
	level endon( "end_game" );

	wait( 5 );

	while ( 1 )
	{
		//killed_players = false;
		players = get_players();
		for ( i = 0; i < players.size; i++ )
		{
			if ( players[i] maps\_laststand::player_is_in_laststand() || "spectator" == players[i].sessionstate )
			{
				continue;
			}

			for ( j = 0; j < players.size; j++ )
			{
				if ( i == j || players[j] maps\_laststand::player_is_in_laststand() || "spectator" == players[j].sessionstate )
				{
					continue;
				}

				if ( isDefined( level.player_intersection_tracker_override ) )
				{
					if ( players[i] [[level.player_intersection_tracker_override]]( players[j] ) )
					{
						continue;
					}
				}

				//Check height first
				if ( abs(players[i].origin[2] - players[j].origin[2] ) > 75 )
					continue;

				//Check 2d distance
				distance_apart = distance2d( players[i].origin, players[j].origin );
				//IPrintLnBold( "player=", i, ",", j, "distance_apart=", distance_apart );

				if ( abs(distance_apart) > 18 )
					continue;

				if(players[i].origin[2] > players[j].origin[2])
				{
					if(level.gamemode != "survival" && players[i].vsteam != players[j].vsteam)
					{
						players[j] dodamage( 1000, (0, 0, 0) );
					}
					players[i] random_push();
				}
				else
				{
					if(level.gamemode != "survival" && players[i].vsteam != players[j].vsteam)
					{
						players[i] dodamage( 1000, (0, 0, 0) );
					}
					players[j] random_push();
				}
			}
		}
		wait( .05 );
	}
}

random_push()
{
	vector = VectorNormalize((RandomIntRange(-100, 101), RandomIntRange(-100, 101), 0)) * (100, 100, 100);
	self SetVelocity(vector);
}

#using_animtree( "generic_human" );
is_spawner_targeted_by_blocker( ent )
{
	if( IsDefined( ent.targetname ) )
	{
		targeters = GetEntArray( ent.targetname, "target" );

		for( i = 0; i < targeters.size; i++ )
		{
			if( targeters[i].targetname == "zombie_door" || targeters[i].targetname == "zombie_debris" )
			{
				return true;
			}

			result = is_spawner_targeted_by_blocker( targeters[i] );
			if( result )
			{
				return true;
			}
		}
	}

	return false;
}

add_cusom_zombie_spawn_logic(func)
{
	if(!IsDefined(level._zombie_custom_spawn_logic))
	{
		level._zombie_custom_spawn_logic = [];
	}

	level._zombie_custom_spawn_logic[level._zombie_custom_spawn_logic.size] = func;
}


// set up zombie walk cycles
zombie_spawn_init( animname_set )
{
	if( !isDefined( animname_set ) )
	{
		animname_set = false;
	}

	self.targetname = "zombie";
	self.script_noteworthy = undefined;

	if( !animname_set )
	{
		self.animname = "zombie";
	}

	self thread play_ambient_zombie_vocals();

	self.ignoreall = true;
	self.ignoreme = true; // don't let attack dogs give chase until the zombie is in the playable area
	self.allowdeath = true; 			// allows death during animscripted calls
	self.force_gib = true; 		// needed to make sure this guy does gibs
	self.is_zombie = true; 			// needed for melee.gsc in the animscripts
	self.has_legs = true; 			// Sumeet - This tells the zombie that he is allowed to stand anymore or not, gibbing can take
									// out both legs and then the only allowed stance should be prone.
	self allowedStances( "stand" );

	self.zombie_damaged_by_bar_knockdown = false; // This tracks when I can knock down a zombie with a bar

	self.gibbed = false;
	self.head_gibbed = false;

	// might need this so co-op zombie players cant block zombie pathing
//	self PushPlayer( true );
//	self.meleeRange = 128;
//	self.meleeRangeSq = anim.meleeRange * anim.meleeRange;

	self.disableArrivals = true;
	self.disableExits = true;
	self.grenadeawareness = 0;
	self.badplaceawareness = 0;

	self.ignoreSuppression = true;
	self.suppressionThreshold = 1;
	self.noDodgeMove = true;
	self.dontShootWhileMoving = true;
	self.pathenemylookahead = 0;

	self.badplaceawareness = 0;
	self.chatInitialized = false;

	self.a.disablepain = true;
	self disable_react(); // SUMEET - zombies dont use react feature.

	self.maxhealth = level.zombie_health;
	self.health = level.zombie_health;

	self.freezegun_damage = 0;

	self.dropweapon = false;
	level thread zombie_death_event( self );

	// We need more script/code to get this to work properly
//	self add_to_spectate_list();
//	self random_tan();
	self set_zombie_run_cycle();
	self thread zombie_think();
	self thread zombie_gib_on_damage();
	self thread zombie_damage_failsafe();

	if(IsDefined(level._zombie_custom_spawn_logic))
	{
		if(IsArray(level._zombie_custom_spawn_logic))
		{
			for(i = 0; i < level._zombie_custom_spawn_logic.size; i ++)
			{
			self thread [[level._zombie_custom_spawn_logic[i]]]();
			}
		}
		else
		{
			self thread [[level._zombie_custom_spawn_logic]]();
		}
	}

	// MM - mixed zombies test
// 	if ( flag( "crawler_round" ) ||
// 		 ( IsDefined( level.mixed_rounds_enabled ) && level.mixed_rounds_enabled == 1 &&
// 		   level.zombie_total > 10 &&
// 		   level.round_number > 5 && RandomInt(100) < 10 ) )
// 	{
// 		self thread make_crawler();
// 	}

	// self thread zombie_head_gib();

	if ( !isdefined( self.no_eye_glow ) || !self.no_eye_glow )
	{
		self thread delayed_zombie_eye_glow();	// delayed eye glow for ground crawlers (the eyes floated above the ground before the anim started)
	}
	self.deathFunction = ::zombie_death_animscript;
	self.flame_damage_time = 0;

	self.meleeDamage = 50;
	self.no_powerups = true;

	self zombie_history( "zombie_spawn_init -> Spawned = " + self.origin );

	self.thundergun_disintegrate_func = ::zombie_disintegrate;
	self.thundergun_knockdown_func = ::zombie_knockdown;
	self.tesla_head_gib_func = ::zombie_tesla_head_gib;

	self setTeamForEntity( "axis" );

	if ( isDefined(level.achievement_monitor_func) )
	{
		self [[level.achievement_monitor_func]]();
	}

	if ( isDefined( level.zombie_init_done ) )
	{
		self [[ level.zombie_init_done ]]();
	}

	self.zombie_init_done = true;
	self notify( "zombie_init_done" );
}

/*
delayed_zombie_eye_glow:
Fixes problem where zombies that climb out of the ground are warped to their start positions
and their eyes glowed above the ground for a split second before their animation started even
though the zombie model is hidden. and applying this delay to all the zombies doesn't really matter.
*/
delayed_zombie_eye_glow()
{
	self endon("zombie_delete");

	wait .5;
	self zombie_eye_glow();
}


zombie_damage_failsafe()
{
	self endon ("death");

	continue_failsafe_damage = false;
	while (1)
	{
		//should only be for zombie exploits
		wait 0.5;

		if ( !isdefined( self.enemy ) || !IsPlayer( self.enemy ) )
		{
			continue;
		}

		if (self istouching(self.enemy))
		{
			old_org = self.origin;
			if (!continue_failsafe_damage)
			{
				wait 5;
			}

			//make sure player doesn't die instantly after getting touched by a zombie.
			if (!isdefined(self.enemy) || !IsPlayer( self.enemy ) || self.enemy hasperk("specialty_armorvest") /*|| self.enemy hasperk("specialty_armorvest_upgrade")*/)
			{
				continue;
			}

			if (self istouching(self.enemy)
				&& !self.enemy maps\_laststand::player_is_in_laststand()
				&& isalive(self.enemy))
			{
				//TODO	THIS SHOULD NOT BE A PERMANENT FIX, ONLY TEMP TEST
				//MM -10/13/09  This distance used to be 35
				if (distancesquared(old_org, self.origin) < (60 * 60) )
				{
					setsaveddvar("player_deathInvulnerableTime", 0);
					self.enemy DoDamage( self.enemy.health + 1000, self.enemy.origin, undefined, undefined, "riflebullet" );
					setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);

					continue_failsafe_damage = true;
				}
			}
		}
		else
		{
			continue_failsafe_damage = false;
		}
	}
}

set_zombie_run_cycle( new_move_speed )
{
	if ( isDefined( new_move_speed ) )
	{
		self.zombie_move_speed = new_move_speed;
	}
	else
	{
		self set_run_speed();
		self.zombie_move_speed_original = self.zombie_move_speed;
	}

	self.needs_run_update = true;

	death_anims = level._zombie_deaths[self.animname];

	self.deathanim = random(death_anims);

// var = 0;

	switch(self.zombie_move_speed)
	{
	case "walk":
		var = randomintrange(1, 9);
		self set_run_anim( "walk" + var );
		self.run_combatanim = level.scr_anim[self.animname]["walk" + var];
		break;
	case "run":
		var = 1;
		// zombies have one extra run anim now
		if(self.animname == "zombie")
		{
			var = randomintrange(1, 8);
		}
		else
		{
			var = randomintrange(1, 7);
		}
		self set_run_anim( "run" + var );
		self.run_combatanim = level.scr_anim[self.animname]["run" + var];
		break;
	case "sprint":
		var = 1;
		if(is_true(self.zombie_move_speed_supersprint))
		{
			var = randomintrange(5, 7);
		}
		else
		{
			var = randomintrange(1, 5);
		}
		self set_run_anim( "sprint" + var );
		self.run_combatanim = level.scr_anim[self.animname]["sprint" + var];
		break;
	}

//	self thread print3d_ent( self.zombie_move_speed+var, (1,1,1), 2.0, (0,0,72), "", true );
}

set_run_speed()
{
	rand = randomintrange( level.zombie_move_speed, level.zombie_move_speed + 35 );

//	self thread print_run_speed( rand );
	if( rand <= 35 && level.gamemode == "survival" )
	{
		self.zombie_move_speed = "walk";
	}
	else if( rand <= 70 )
	{
		self.zombie_move_speed = "run";
	}
	else
	{
		self.zombie_move_speed = "sprint";

		if(rand > 105)
		{
			if(level.script == "zombie_cod5_asylum" && flag("power_on"))
			{
				self.zombie_move_speed_supersprint = true;
			}
		}
	}
}


should_skip_teardown( find_flesh_struct_string )
{
	// Riser who spawns in the playable area
	if( IsDefined(find_flesh_struct_string) && find_flesh_struct_string == "find_flesh" )
	{
		return true;
	}
	// Used on dogs...could be used on a zombie who spawns in and immediately chases player
	if( isDefined( self.script_string ) && self.script_string == "zombie_chaser" )
	{
		return true;
	}

	return false;
}

// JL 12/08/09 this is the main zombie think thread that starts when they spawn in
zombie_think()
{
	self endon( "death" );
	assert( !self.isdog );

	//node = level.exterior_goals[randomint( level.exterior_goals.size )];

	// MM - 5/8/9 Add ability for risers to find_flesh immediately after spawning if the
	//	rise struct has the script_noteworthy "find_flesh"
	find_flesh_struct_string = undefined;

	//CHRIS_P - test dudes rising from ground
	if (GetDvarInt( #"zombie_rise_test") || (isDefined(self.script_string) && self.script_string == "riser" ))
	{
		// Wait until the zombie has risen before continuing
		self thread do_zombie_rise();
		self waittill("risen", find_flesh_struct_string );
	}
	else
	{
		self notify("no_rise");
	}

	// RAVEN BEGIN bhackbarth: Add callback to allow custom functionality similar to that of the riser
	if ( IsDefined(level.zombie_custom_think_logic) )
	{
		shouldWait = self [[ level.zombie_custom_think_logic ]]();
		if ( shouldWait )
		{
			self waittill("zombie_custom_think_done", find_flesh_struct_string);
		}
	}
	// RAVEN END

	node = undefined;

	desired_nodes = [];
	self.entrance_nodes = [];

	if ( IsDefined( level.max_barrier_search_dist_override ) )
	{
		max_dist = level.max_barrier_search_dist_override;
	}
	else
	{
		max_dist = 500;
	}

	if( !IsDefined(find_flesh_struct_string) && IsDefined( self.target ) && self.target != "" )
	{
		desired_origin = get_desired_origin();

		AssertEx( IsDefined( desired_origin ), "Spawner @ " + self.origin + " has a .target but did not find a target" );

		origin = desired_origin;

		node = getclosest( origin, level.exterior_goals );
		self.entrance_nodes[0] = node;

		self zombie_history( "zombie_think -> #1 entrance (script_forcegoal) origin = " + self.entrance_nodes[0].origin );
	}
	// JMA - this is used in swamp to spawn outdoor zombies and immediately rush the player
	// JMA - if riser becomes a non-riser, make sure they go to a barrier first instead of chasing a player
	else if ( self should_skip_teardown( find_flesh_struct_string ) )
	{
		self zombie_setup_attack_properties();
		//if the zombie has a target, make them go there first
		if (isDefined(self.target))
		{
			end_at_node = GetNode(self.target, "targetname");
			if (isDefined(end_at_node))
			{
				self setgoalnode (end_at_node);
				self waittill("goal");
			}
		}

		self thread find_flesh();
		self zombie_complete_emerging_into_playable_area();
		return;
	}
	else
	{
		origin = self.origin;

		desired_origin = get_desired_origin();
		if( IsDefined( desired_origin ) )
		{
			origin = desired_origin;
		}

		// Get the 3 closest nodes
		//
		nodes = get_array_of_closest( origin, level.exterior_goals, undefined, 3 );

		// Figure out the distances between them, if any of them are greater than 256 units compared to the previous, drop it
		desired_nodes[0] = nodes[0];
		prev_dist = Distance( self.origin, nodes[0].origin );
		for( i = 1; i < nodes.size; i++ )
		{
			dist = Distance( self.origin, nodes[i].origin );
			if( ( dist - prev_dist ) > max_dist )
			{
				break;
			}

			prev_dist = dist;
			desired_nodes[i] = nodes[i];
		}

		node = desired_nodes[0];
		if( desired_nodes.size > 1 )
		{
			node = desired_nodes[RandomInt(desired_nodes.size)];
		}

		self.entrance_nodes = desired_nodes;

		self zombie_history( "zombie_think -> #1 entrance origin = " + node.origin );

		// Incase the guy does not move from spawn, then go to the closest one instead
		self thread zombie_assure_node();
	}

	AssertEx( IsDefined( node ), "Did not find a node!!! [Should not see this!]" );

	level thread draw_line_ent_to_pos( self, node.origin, "goal" );

	self.first_node = node; // This is the first locatin the zombies go to

	// what is the zombies goal radius at this point
	self thread zombie_goto_entrance( node ); // sends the zombie to the node right in front of the window
}

get_desired_origin()
{
	if( IsDefined( self.target ) )
	{
		ent = GetEnt( self.target, "targetname" );
		if( !IsDefined( ent ) )
		{
			ent = getstruct( self.target, "targetname" );
		}

		if( !IsDefined( ent ) )
		{
			ent = GetNode( self.target, "targetname" );
		}

		AssertEx( IsDefined( ent ), "Cannot find the targeted ent/node/struct, \"" + self.target + "\" at " + self.origin );

		return ent.origin;
	}

	return undefined;
}

zombie_goto_entrance( node, endon_bad_path )
{
	assert( !self.isdog );

	self endon( "death" );
	level endon( "intermission" );

	if( IsDefined( endon_bad_path ) && endon_bad_path )
	{
		// If we cannot go to the goal, then end...
		// Used from find_flesh
		self endon( "bad_path" );
	}

	self zombie_history( "zombie_goto_entrance -> start goto entrance " + node.origin );

	self.got_to_entrance = false;

	self.goalradius = 128;

	self SetGoalPos( node.origin );
	self waittill( "goal" );
	self.got_to_entrance = true;

	self zombie_history( "zombie_goto_entrance -> reached goto entrance " + node.origin );

	// Guy should get to goal and tear into building until all barrier chunks are gone
	// They go into this function and do everything they and then comeback once all the barriers are removed
	/*self tear_into_building();

	self endon( "bad_path" );

	//REMOVED THIS, WAS CAUSING ISSUES
	if(isDefined(self.first_node.clip))
	{
		if(!isDefined(self.first_node.clip.disabled) || !self.first_node.clip.disabled)// This was commented out
		{ // This was commented out
			self.first_node.clip disable_trigger();// This was commented out
			self.first_node.clip connectpaths();
			//IPrintLnBold( "Connecting Paths" );
		}// This was commented out
	}

	// Here is where the zombie would play the traversal into the building( if it's a window )
	// and begin the player seek logic
	//IPrintLnBold("zombie going to attack mode");
	self zombie_setup_attack_properties();

	if( isDefined( level.pre_aggro_pathfinding_func ) )
	{
		self [[ level.pre_aggro_pathfinding_func ]]();
	}

	self thread find_flesh();

	// wait for them to traverse out of the spawn closet
	self waittill( "zombie_start_traverse" );
	self waittill( "zombie_end_traverse" );
	self zombie_complete_emerging_into_playable_area();*/

	self thread tear_into_building_loop();
}

tear_into_building_loop()
{
	self endon( "stop_tear_into_building_loop" );
	self endon( "death" );
	level endon( "intermission" );

	// Guy should get to goal and tear into building until all barrier chunks are gone
	// They go into this function and do everything they and then comeback once all the barriers are removed
	self tear_into_building();

	self reset_attack_spot();

	wait_network_frame(); // need this for zombies to attack correctly

	self endon( "stop_tear_into_building" );

	self thread tear_into_building_loop_watch_for_bad_path();

	self StopAnimscripted();

	if(isDefined(self.first_node.clip))
	{
		if(!isDefined(self.first_node.clip.disabled) || !self.first_node.clip.disabled)
		{
			self.first_node.clip disable_trigger();
			self.first_node.clip connectpaths();
		}
	}

	// Here is where the zombie would play the traversal into the building( if it's a window )
	// and begin the player seek logic
	self zombie_setup_attack_properties();

	if( isDefined( level.pre_aggro_pathfinding_func ) )
	{
		self [[ level.pre_aggro_pathfinding_func ]]();
	}

	self thread find_flesh();

	self waittill( "zombie_start_traverse" );

	self thread tear_into_building_loop_end();
}

// watch for bad path after tearing down all barrier and before starting to traverse over the barrier
tear_into_building_loop_watch_for_bad_path()
{
	self endon("zombie_start_traverse");
	self endon( "death" );
	level endon( "intermission" );

	self notify("stop_check_for_traverse");

	while(all_chunks_destroyed(self.first_node.barrier_chunks))
	{
		wait_network_frame();
	}

	self thread check_for_traverse();

	self notify("stop_tear_into_building");

	// turn off find flesh
	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );
	self OrientMode( "face default" );
	self.ignoreall = true;

	self thread tear_into_building_loop();
}

// sometimes zombies still traverse after turning off find flesh
// if that happens we need to turn back on find flesh or else they won't move until barrier chunks are destroyed
check_for_traverse()
{
	self endon("stop_check_for_traverse");

	self waittill("zombie_start_traverse");

	self notify("stop_tear_into_building_loop");
	self reset_attack_spot();
	self thread find_flesh();
	self thread tear_into_building_loop_end();
}

tear_into_building_loop_end()
{
	self endon( "death" );
	level endon( "intermission" );

	// wait for them to traverse out of the spawn closet
	self waittill( "zombie_end_traverse" );
	self zombie_complete_emerging_into_playable_area();
}

// Here the zombies constantly search
zombie_assure_node()
{
	self endon( "death" );
	self endon( "goal" );
	level endon( "intermission" );

	start_pos = self.origin;
	if(IsDefined(self.entrance_nodes))
	{
		for( i = 0; i < self.entrance_nodes.size; i++ )
		{
			if( self zombie_bad_path() )
			{
				self zombie_history( "zombie_assure_node -> assigned assured node = " + self.entrance_nodes[i].origin );

				println( "^1Zombie @ " + self.origin + " did not move for 1 second. Going to next closest node @ " + self.entrance_nodes[i].origin );
				level thread draw_line_ent_to_pos( self, self.entrance_nodes[i].origin, "goal" );
				self.first_node = self.entrance_nodes[i];
				self SetGoalPos( self.entrance_nodes[i].origin );
			}
			else
			{
				return;
			}
		}
	}
	// CHRISP - must add an additional check, since the 'self.entrance_nodes' array is not dynamically updated to accomodate for entrance points that can be turned on and off
	// only do this if it's the asylum map
	wait(2);
	// Get more nodes and try again
	nodes = get_array_of_closest( self.origin, level.exterior_goals, undefined, 20 );
	if(IsDefined(nodes))
	{
		self.entrance_nodes = nodes;
		for( i = 0; i < self.entrance_nodes.size; i++ )
		{
			if( self zombie_bad_path() )
			{
				self zombie_history( "zombie_assure_node -> assigned assured node = " + self.entrance_nodes[i].origin );

				println( "^1Zombie @ " + self.origin + " did not move for 1 second. Going to next closest node @ " + self.entrance_nodes[i].origin );
				level thread draw_line_ent_to_pos( self, self.entrance_nodes[i].origin, "goal" );
				self.first_node = self.entrance_nodes[i];
				self SetGoalPos( self.entrance_nodes[i].origin );
			}
			else
			{
				return;
			}
		}
	}

	self zombie_history( "zombie_assure_node -> failed to find a good entrance point" );

	//assertmsg( "^1Zombie @ " + self.origin + " did not find a good entrance point... Please fix pathing or Entity setup" );
	wait(20);
	//iprintln( "^1Zombie @ " + self.origin + " did not find a good entrance point... Please fix pathing or Entity setup" );
	level.zombie_total++;
	self DoDamage( self.health + 10, self.origin );

//	//add this zombie back into the spawner queue to be re-spawned
//	if(is_true(level.put_timed_out_zombies_back_in_queue ))
//	{
//		level.zombie_total++;
//	}

	//add this to the stats even tho he really didn't 'die'
	level.zombies_timeout_spawn++;

}

zombie_bad_path()
{
	self endon( "death" );
	self endon( "goal" );

	self thread zombie_bad_path_notify();
	self thread zombie_bad_path_timeout();

	self.zombie_bad_path = undefined;
	while( !IsDefined( self.zombie_bad_path ) )
	{
		wait( 0.05 );
	}

	self notify( "stop_zombie_bad_path" );

	return self.zombie_bad_path;
}

zombie_bad_path_notify()
{
	self endon( "death" );
	self endon( "stop_zombie_bad_path" );

	self waittill( "bad_path" );
	self.zombie_bad_path = true;
}

zombie_bad_path_timeout()
{
	self endon( "death" );
	self endon( "stop_zombie_bad_path" );

	wait( 2 );
	self.zombie_bad_path = false;
}

// This controls the zombies breaking into the building.
// Self is a specific zombie
// Node is the player's origin
tear_into_building()
{
	self endon( "death" ); // this is a zombie
	self endon("teleporting");

	self zombie_history( "tear_into_building -> start" ); // update history that they have started to tear in

	while( 1 )
	{
		if( IsDefined( self.first_node.script_noteworthy ) )
		{
			if( self.first_node.script_noteworthy == "no_blocker" )
			{
				return; // if no blocker checks out ok... then allow the zombie to connect paths
			}
		}

		if( !IsDefined( self.first_node.target ) )
		{
			return;
		}

		// barrier_chunks is the exterior_goal that has all the bars and boards connected to it.
		// remember all_chunks_destroyed is in utility script _zombie_utility
		if( all_chunks_destroyed( self.first_node.barrier_chunks ) ) // If barrier_chunks status says all chunks are destroyed then continue
		{
			// Send this notify but only accept the first time it comes through.
			self zombie_history( "tear_into_building -> all chunks destroyed" ); // Enter the building if all chunks are gone. This is threaded for each zombie
			return;
		}

		// If an attacking_spot is availiable then they well grab one, if not they taunt.
		if( !get_attack_spot( self.first_node ) )
		{
			self zombie_history( "tear_into_building -> Could not find an attack spot" );

			self thread do_a_taunt();
			wait .5;
			continue;
		}

		// This is where the zombie moves into position to tear down a board/bar
		self.goalradius = 2;
		//self maps\_zombiemode_utility:: lerp( chunk );
		self SetGoalPos( self.attacking_spot, self.first_node.angles );
		attacking_spot1a = self.attacking_spot;
		self waittill( "goal" );

		//	If you wait for "orientdone", you NEED to also have a timeout.
		//	Otherwise, zombies could get stuck waiting to do their facing.
		self waittill_notify_or_timeout( "orientdone", 1 );

		self zombie_history( "tear_into_building -> Reach position and orientated" );

		// chrisp - do one final check to make sure that the boards are still torn down
		// this *mostly* prevents the zombies from coming through the windows as you are boarding them up.
		if( all_chunks_destroyed( self.first_node.barrier_chunks ) )
		{
			self zombie_history( "tear_into_building -> all chunks destroyed" );
			return;
		}

		// Now tear down boards
		while( 1 )
		{
			if(isDefined(self.zombie_board_tear_down_callback))
			{
				self [[self.zombie_board_tear_down_callback]]();
			}

			chunk = get_closest_non_destroyed_chunk( self.origin, self.first_node.barrier_chunks );

			if( !IsDefined( chunk ) )
			{
				if( !all_chunks_destroyed( self.first_node.barrier_chunks ) )
				{
					attack = self should_attack_player_thru_boards();
					if(isDefined(attack) && !attack && self.has_legs)
					{
						self do_a_taunt();
					}
					else
					{
						wait_network_frame();
					}
					continue;
				}

				return;
			}

			self zombie_history( "tear_into_building -> animating" );

			tear_anim = get_tear_anim(chunk, self);

			chunk maps\_zombiemode_blockers::update_states("target_by_zombie");

			self thread maps\_zombiemode_audio::do_zombies_playvocals( "teardown", self.animname );
			self AnimScripted( "tear_anim", attacking_spot1a, self.first_node.angles, tear_anim, "normal", undefined, 1, 0.3 );

			// play long tear sound here - SG
			if ( tear_anim == %ai_zombie_bar_bend_l || tear_anim == %ai_zombie_bar_bend_l_2 || tear_anim == %ai_zombie_bar_bend_r || tear_anim == %ai_zombie_bar_bend_r_2 || tear_anim == %ai_zombie_bar_bend_m_1 || tear_anim == %ai_zombie_bar_bend_m_2 )
			{
				self playsound( "zmb_bar_bend" );
			}

			self zombie_tear_notetracks( "tear_anim", chunk, self.first_node, tear_anim );

			//chrisp - fix the extra tear anim bug
			if( all_chunks_destroyed( self.first_node.barrier_chunks ) )
			{
				return;
			}

			//chris - adding new window attack & gesture animations ;)
			attack = self should_attack_player_thru_boards();
			if(isDefined(attack) && !attack && self.has_legs)
			{
				self do_a_taunt();
			}
		}
	}
}


/*------------------------------------
checks to see if the zombie should
do a taunt when tearing thru the boards
------------------------------------*/
do_a_taunt()
{
	self endon ("death"); // Jluyties 02/16/10 added death check, cause of crash

	if( !self.has_legs)
	{
		return false;
	}

	if(!IsDefined(level._zombie_board_taunt[self.animname]))
	{
		return false;
	}

	self.old_origin = self.origin;
	/*if(GetDvar( #"zombie_taunt_freq") == "")
	{
		setdvar("zombie_taunt_freq","5");
	}
	freq = GetDvarInt( #"zombie_taunt_freq");*/
	freq = 10;

	if( freq >= randomint(100) )
	{
		anime = random(level._zombie_board_taunt[self.animname]);
		self thread maps\_zombiemode_audio::do_zombies_playvocals( "taunt", self.animname );
		self animscripted("zombie_taunt",self.origin,self.angles,anime, "normal", undefined, 1, 0.4 );
		wait(getanimlength(anime));
		self ForceTeleport(self.old_origin);
		return true;
	}

	return false;
}

/*------------------------------------
checks to see if the players are near
the entrance and tries to attack them
thru the boards. 50% chance
Self is a zombie
------------------------------------*/
should_attack_player_thru_boards()
{

	//no board attacks if they are crawlers
	if( !self.has_legs)
	{
		return false;
	}

	//DCS 083110: check glass section or walls are all broken through.
	/*if(IsDefined(self.first_node.barrier_chunks))
	{
		for(i=0;i<self.first_node.barrier_chunks.size;i++)
		{
			if(IsDefined(self.first_node.barrier_chunks[i].unbroken) && self.first_node.barrier_chunks[i].unbroken == true )
			{
				return false;
			}
		}
	}*/

	if(GetDvar( #"zombie_reachin_freq") == "")
	{
		setdvar("zombie_reachin_freq","50");
	}
	freq = GetDvarInt( #"zombie_reachin_freq");

	players = get_players();
	attack = false;

	self.player_targets = [];
	for(i=0;i<players.size;i++)
	{
		if ( isAlive( players[i] ) && !isDefined( players[i].revivetrigger ) && distance2d( self.origin, players[i].origin ) <= 90 && 
			players[i] DamageConeTrace(self GetEye(), players[i]) )
		{
			self.player_targets[self.player_targets.size] = players[i];
			attack = true;
		}
	}
	if(attack && freq >= randomint(100) )
	{
		//iprintln("checking attack");
		// index 0 is center, index 2 is left and index 1 is the right
		//check to see if the guy is left, right, or center
		self.old_origin = self.origin;
		if(self.attacking_spot_index == 0) //he's in the center
		{

		if(randomint(100) > 50)
		{
				//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", %body, 1, 0.4 );
				self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
				self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", undefined, 1, 0.3 );
		}
		else
		{
			//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", %body, 1, 0.4 );
			self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
			self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", undefined, 1, 0.3 );
		}
		self window_notetracks( "window_melee" );
		}
		else if(self.attacking_spot_index == 2) //<-- he's to the left
		{
			//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", %body, 1, 0.4 );
			self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
			self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_r_out, "normal", undefined, 1, 0.3 );
			self window_notetracks( "window_melee" );
		}
		else if(self.attacking_spot_index == 1) //<-- he's to the right
		{
			//self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", %body, 1, 0.4 );
			self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
			self animscripted("window_melee",self.origin,self.angles,%ai_zombie_window_attack_arm_l_out, "normal", undefined, 1, 0.3 );
			self window_notetracks( "window_melee" );
		}
	}
	else
	{
		return false;
	}
}
window_notetracks(msg)
{
	while(1)
	{
		self waittill( msg, notetrack );

		if( notetrack == "end" )
		{
			//self waittill("end");
			self teleport(self.old_origin);

			return;
		}
		if( notetrack == "fire" )
		{
			if(self.ignoreall)
			{
				self.ignoreall = false;
			}

			// just hit a player
			if ( isDefined( self.first_node ) )
			{
				_MELEE_DIST_SQ = 90*90;
				_TRIGGER_DIST_SQ = 51*51;

				for ( i = 0; i < self.player_targets.size; i++ )
				{
					playerDistSq = Distance2DSquared( self.player_targets[i].origin, self.origin );
					heightDiff = abs( self.player_targets[i].origin[2] - self.origin[2] ); // be sure we're on the same floor
					if ( playerDistSq < _MELEE_DIST_SQ && (heightDiff * heightDiff) < _MELEE_DIST_SQ )
					{
						triggerDistSq = Distance2DSquared( self.player_targets[i].origin, self.first_node.trigger_location.origin );
						heightDiff = abs( self.player_targets[i].origin[2] - self.first_node.trigger_location.origin[2] ); // be sure we're on the same floor
						if ( triggerDistSq < _TRIGGER_DIST_SQ && (heightDiff * heightDiff) < _TRIGGER_DIST_SQ )
						{
							self.player_targets[i] DoDamage( self.meleeDamage, self.origin, self, 0, "MOD_MELEE" );
							break;
						}
					}
				}
			}
			else
			{
				self melee();
			}
		}
	}
}

reset_attack_spot()
{
	if( IsDefined( self.attacking_node ) )
	{
		node = self.attacking_node;
		index = self.attacking_spot_index;
		node.attack_spots_taken[index] = false;

		self.prev_attacking_node = node;
		self.prev_attacking_spot_index = index;

		self.attacking_node = undefined;
		self.attacking_spot_index = undefined;
	}
}

get_attack_spot( node )
{
	index = undefined;
	if(IsDefined(self.prev_attacking_node) && self.prev_attacking_node == node && !node.attack_spots_taken[self.prev_attacking_spot_index])
	{
		index = self.prev_attacking_spot_index;
	}
	else
	{
		index = self get_attack_spot_index( node );
	}

	if( !IsDefined( index ) )
	{
		return false;
	}

	self.attacking_node = node;
	self.attacking_spot_index = index;
	node.attack_spots_taken[index] = true;
	self.attacking_spot = node.attack_spots[index];

	return true;
}

get_attack_spot_index( node )
{
	indexes = [];
	for( i = 0; i < node.attack_spots.size; i++ )
	{
		if( !node.attack_spots_taken[i] )
		{
			indexes[indexes.size] = i;
		}
	}

	if( indexes.size == 0 )
	{
		return undefined;
	}

	return indexes[RandomInt( indexes.size )];
}

// Self is zombie
zombie_tear_notetracks( msg, chunk, node, tear_anim )
{
	// JL: Setup random chance for bars getting bent or not
	random_chance = undefined;
	self endon("death");
	chunk thread check_for_zombie_death(self);

	attack_times = 0;

	// Five's barrier tear down anims for glass and wall barriers have multiple notetracks for breaking the barrier, only break on the last one
	max_attack_times = 1;
	if(IsDefined(chunk.unbroken_section) && IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board")
	{
		if(!IsDefined(chunk.material))
		{
			if(IsDefined(self.random_tear_anim))
			{
				if(self.random_tear_anim == 1)
				{
					max_attack_times = 4;
				}
				else
				{
					max_attack_times = 2;
				}
			}
		}
		if(IsDefined(chunk.material) && chunk.material == "glass")
		{
			max_attack_times = 2;
		}
	}
	

	while( 1 )
	{
		self waittill( msg, notetrack );

		if( notetrack == "end" )
		{
			return;
		}

		attack_times++;

		if( notetrack == "board" )
		{
			if( !chunk.destroyed )
			{
				//PlayFx( level._effect["wood_chunk_destory"], chunk.origin );
				// jl created another function for dust so we create offsets with its timing
				if(chunk.script_noteworthy == "4" || chunk.script_noteworthy == "6" || chunk.script_noteworthy == "5" || chunk.script_noteworthy == "1")
				{
					chunk thread zombie_boardtear_offset_fx_horizontle(chunk, node);
				}
				else
				{
					chunk thread zombie_boardtear_offset_fx_verticle(chunk, node);
				}

				if(attack_times < max_attack_times)
				{
					chunk thread maps\_zombiemode_blockers::zombie_boardtear_audio_offset(chunk);
					continue;
				}

				self.lastchunk_destroy_time = getTime();

				zomb = self;
				level thread maps\_zombiemode_blockers::remove_chunk( chunk, node, true, zomb );
				chunk notify("destroyed");

			}
		}

		// Jl jan 10 09
		// added new bar checks for system
		else if( notetrack == "bar_bend" )
		{
			if( !chunk.destroyed )
			{
				self.lastchunk_destroy_time = getTime();

					if( chunk.script_noteworthy == "3" ) // this is the far left , this bar now bends it does not leave
					{
						if( IsDefined( chunk.script_string ) )
						{
							if( chunk.script_string == "prestine_bend"  ) //
							{
								// Put 50/50 chance to either bend bar or not
								//random_chance = RandomInt( 11 );
								//if( random_chance >= 4 )
								//{
									bar_bend_left = spawn( "script_model", chunk.origin);
									// jl, debug iprintlnbold("BEND LEFT");
									bar_bend_left RotateTo( chunk.angles ,  0.2, 0.1, 0.1 );
									bar_bend_left waittill("rotatedone");
									bar_bend_left SetModel( "p_zom_win_cell_bars_01_vert01_bent" ); // jl this should not be the 180, this is a hack to adjust for the prefab orientation not being aligned
									chunk Hide();
									thread bar_repair_bend_left( bar_bend_left, chunk);
								//}

								//else
								//{
												// I need to change the timing of this.
								//				level thread maps\_zombiemode_blockers::remove_chunk( chunk, node, true );
								//				chunk notify("destroyed");
								//}
							}

							// this is for the bent bars
							else if ( chunk.script_string == "bar_bend" )
							{
								bar_bend_left = spawn( "script_model", chunk.origin);
								bar_bend_left RotateTo( chunk.angles ,  0.2, 0.1, 0.1 );
								bar_bend_left waittill("rotatedone");
								bar_bend_left SetModel( "p_zom_win_cell_bars_bent_01_vert01_bent" ); // jl this should not be the 180, this is a hack to adjust for the prefab orientation not being aligned
								chunk Hide();
								thread bar_repair_bend_left( bar_bend_left, chunk);
							}
						}
				  }

//----------------------------------------------------


					if( chunk.script_noteworthy == "5" ) // this is the far left , this bar now bends it does not leave
					{
						if( IsDefined( chunk.script_string ) )
						{
							if( chunk.script_string == "prestine_bend"  ) //
							{
								// Put 50/50 chance to either bend bar or not
								//random_chance = RandomInt( 11 );
								//if( random_chance >= 4 )
								//{
									bar_bend_right = spawn( "script_model", chunk.origin);
									// jl, debug iprintlnbold("BEND LEFT");
									bar_bend_right RotateTo( chunk.angles ,  0.2, 0.1, 0.1 );
									bar_bend_right waittill("rotatedone");
									bar_bend_right SetModel( "p_zom_win_cell_bars_01_vert04_bent" ); // jl this should not be the 180, this is a hack to adjust for the prefab orientation not being aligned
									chunk Hide();
									thread bar_repair_bend_right( bar_bend_right, chunk);
								//}

								//else
								//{
												// I need to change the timing of this.
								//				level thread maps\_zombiemode_blockers::remove_chunk( chunk, node, true );
								//				chunk notify("destroyed");
								//}
							}

							// this is for the bent bars
							else if ( chunk.script_string == "bar_bend" )
							{
								bar_bend_right = spawn( "script_model", chunk.origin);
								bar_bend_right RotateTo( chunk.angles ,  0.2, 0.1, 0.1 );
								bar_bend_right waittill("rotatedone");
								bar_bend_right SetModel( "p_zom_win_cell_bars_bent_01_vert04_bent" ); // jl this should not be the 180, this is a hack to adjust for the prefab orientation not being aligned
								chunk Hide();
								thread bar_repair_bend_right( bar_bend_right, chunk);
							}
						}
				  }
		//----------------------------------------------------
					/*
					else if( chunk.script_noteworthy == "5" ) // this is the far right side , this bar now bends it does not leave
					{
						if( IsDefined( chunk.script_string )
						{
							if( chunk.script_string == "prestine_bend" )
							{
										bar_bend_right = spawn( "script_model", chunk.origin );
										//iprintlnbold("BEND RIGHT");
										bar_bend_right RotateTo( chunk.angles ,  0.2, 0.1, 0.1 );
										//bar_bend_right RotateTo( chunk.angles +(0, -145,0), 0.2, 0.1, 0.1 );
										wait (0.3);
										bar_bend_right SetModel( "p_zom_win_cell_bars_01_vert04_bent" );
										thread bar_repair_bend_right( bar_bend_right, chunk);
										chunk Hide();
							}


							else if( chunk.script_string == "bar_bend" )
							{
								chunk.angles = chunk GetTagAngles ( "Tag_fx_top" );
								bar_bend_right = spawn( "script_model", chunk.origin );
								//iprintlnbold("BEND RIGHT" );
								bar_bend_right RotateTo( chunk.angles ,  0.2, 0.1, 0.1 );
								wait (0.3);
								bar_bend_right SetModel( "p_zom_win_cell_bars_01_vert04_bent" );
								thread bar_repair_bend_right( bar_bend_right, chunk );
								chunk Hide();
							}
						}
					}
					*/

				zomb = self;
				chunk thread zombie_bartear_offset_fx_verticle( chunk );
				level thread maps\_zombiemode_blockers::remove_chunk( chunk, node, true, zomb );
				chunk notify( "destroyed" );
			}
		}


		//else( notetrack == "bar" )
		else if( notetrack == "bar" )
		{
			if( !chunk.destroyed )
			{
				self.lastchunk_destroy_time = getTime();
					// index 4 and 6 are the horizontle bars
					// here I can do the model swap
					if(chunk.script_noteworthy == "4" || chunk.script_noteworthy == "6")
					{
						if ( IsDefined( chunk.script_squadname ) && ( chunk.script_squadname == "cosmodrome_storage_area" ) )
						{
							// I need to kill this thread.
						}
						if (!IsDefined( chunk.script_squadname ) )
						{
						// this doesn't work because it calls it at the beggining, I need to find where it locks into place
									chunk thread zombie_bartear_offset_fx_horizontle(chunk);
						}
					}
					// this does a model swap and anim tear instead of chunk remove.

					else
					{
						if ( IsDefined( chunk.script_squadname ) && ( chunk.script_squadname == "cosmodrome_storage_area" ) )
						{
							// I need to kill this thread.
						}
						if (!IsDefined( chunk.script_squadname ) )
						{
							// this doesn't work because it calls it at the beggining, I need to find where it locks into place
							chunk thread zombie_bartear_offset_fx_verticle(chunk);
						}



					}

				level thread maps\_zombiemode_blockers::remove_chunk( chunk, node, true, self );
				chunk notify("destroyed");

			}
		}






		/* jl dece 15 09
		 prototyping new grate technique
		 this chunk is doing the throw away and doesn't need to till the last piece is gone..
			else if( IsDefined (chunk.script_parameters) )
			{
				if( chunk.script_parameters == "grate" )
				{
							chunk vibrate(( 0, 270, 0 ), 5, 1, 0.3);
							wait(0.3);
							// first check shake... then swap to differnt state
							//chunk MoveTo( only_z, 0.15);
							//chunk RotateTo( chunk.og_angles,  0.3 );
							//chunk waittill_notify_or_timeout( "rotatedone", 1 );
				}
			}	*/

	}
}

//jl this is rough and deletes them everytime, eventually I want to spawn them in once and just show and hide them
// I need to do this global thing right now because the system is global and I am not keeping track of seperate windows
// This is working except the bar dissappears to late. Is that bad? or can I remove the bar in mid fix
// These while loops may be too expensive
bar_repair_bend_left( bar_bend_left, chunk )
{
	while(1)
	{
		wait(0.2);
		if( chunk get_chunk_state() == "repaired" ) // if any piece has the state of not repaired then return false
		{
			bar_bend_left delete();
			break;
		}
	}
	//chunk waittill("repaired");


//	level waittill ("reset_bar_left");

}

bar_repair_bend_right( bar_bend_right, chunk )
{
	while(1)
	{
		wait(0.2);
		if( chunk get_chunk_state() == "repaired" ) // if any piece has the state of not repaired then return false
		{
			bar_bend_right delete();
			break;
		}
	}
}

// jl I am doing this so I can have an offset of timing for when the chunks come off to give it more life
// 0.8 is too long
// need to offset sound
// need to add this to the boards
zombie_boardtear_offset_fx_horizontle( chunk, node )
{
	// DCS 090110: fx for breaking out glass or wall.
	if ( IsDefined( chunk.script_parameters ) && ( chunk.script_parameters == "repair_board"  || chunk.script_parameters == "board") )
	{
		if(IsDefined(chunk.unbroken) && chunk.unbroken == true)
		{
			if(IsDefined(chunk.material) && chunk.material == "glass")
			{
				PlayFX( level._effect["glass_break"], chunk.origin, node.angles );
				//chunk.unbroken = false;
			}
			else if(IsDefined(chunk.material) && chunk.material == "metal")
			{
				PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin );
				//chunk.unbroken = false;
			}
			else if(IsDefined(chunk.material) && chunk.material == "rock")
			{
				if(	is_true(level.use_clientside_rock_tearin_fx))
				{
					chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_ROCK_FX);
				}
				else
				{
					PlayFX( level._effect["wall_break"], chunk.origin );
				}
				//chunk.unbroken = false;
			}
		}
	}
	if ( IsDefined( chunk.script_parameters ) && ( chunk.script_parameters == "barricade_vents" ) )
	{
		if(	is_true(level.use_clientside_board_fx))
		{
			chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOARD_HORIZONTAL_FX);
		}
		else
		{
			PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin );
		}
	}
	else if(IsDefined(chunk.material) && chunk.material == "rock")
	{
		if(	is_true(level.use_clientside_rock_tearin_fx))
		{
			chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_ROCK_FX);
		}
	}

	else
	{
		if(isDefined(level.use_clientside_board_fx))
		{
			chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOARD_HORIZONTAL_FX);
		}
		else
		{
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (0, 0, 30));
			wait( randomfloat( 0.2, 0.4 ));
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (0, 0, -30));
		}
	}
}

zombie_boardtear_offset_fx_verticle( chunk, node )
{
	// DCS 090110: fx for breaking out glass or wall.
	if ( IsDefined( chunk.script_parameters ) && ( chunk.script_parameters == "repair_board"  || chunk.script_parameters == "board") )
	{
		if(IsDefined(chunk.unbroken) && chunk.unbroken == true)
		{
			if(IsDefined(chunk.material) && chunk.material == "glass")
			{
				PlayFX( level._effect["glass_break"], chunk.origin, node.angles );
				//chunk.unbroken = false;
			}
			else if(IsDefined(chunk.material) && chunk.material == "metal")
			{
				PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin );
				//chunk.unbroken = false;
			}
			else if(IsDefined(chunk.material) && chunk.material == "rock")
			{
				if(	is_true(level.use_clientside_rock_tearin_fx))
				{
					chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_ROCK_FX);
				}
				else
				{
					PlayFX( level._effect["wall_break"], chunk.origin );
				}
				//chunk.unbroken = false;
			}
		}
	}
	if ( IsDefined( chunk.script_parameters ) && ( chunk.script_parameters == "barricade_vents" ) )
	{

		if(isDefined(level.use_clientside_board_fx))
		{
			chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOARD_VERTICAL_FX);
		}
		else
		{
			PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin );
		}
	}
	else if(IsDefined(chunk.material) && chunk.material == "rock")
	{
		if(	is_true(level.use_clientside_rock_tearin_fx))
		{
			chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_ROCK_FX);
		}
	}
	else
	{
		if(isDefined(level.use_clientside_board_fx))
		{
			chunk setclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOARD_VERTICAL_FX);
		}
		else
		{
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (30, 0, 0));
			wait( randomfloat( 0.2, 0.4 ));
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (-30, 0, 0));
		}
	}
}


zombie_bartear_offset_fx_verticle( chunk )
{
/*
		rand_num = 0;
		animation = "";

		switch(rand_num)
		{
			case 0:
				animation = "pain_a";
			break;
			case 1:
				animation = "pain_b";
			break;
			case 2:
				animation = "pain_c";
			break;
			case 3:
				animation = "pain_d";
			break;
			default:
			break;
		}


		rand_num++;
		self anim_single( self, animation );

		if(rand_num > 3)
		{
			rand_num = 0;
		}
*/
		if ( IsDefined ( chunk.script_parameters ) && ( chunk.script_parameters == "bar" ) || ( chunk.script_noteworthy == "board" ))
		{
			// array random grab for fx
			//point = points[i];
			possible_tag_array_1 = [];
			possible_tag_array_1[0] = "Tag_fx_top";
			possible_tag_array_1[1] = "";
			possible_tag_array_1[2] = "Tag_fx_top";
			possible_tag_array_1[3] = "";

			possible_tag_array_2 = [];
			possible_tag_array_2[0] = "";
			possible_tag_array_2[1] = "Tag_fx_bottom";
			possible_tag_array_2[2] = "";
			possible_tag_array_2[3] = "Tag_fx_bottom";
			// now I need a random int between 0 and 3
			possible_tag_array_2 = array_randomize( possible_tag_array_2 );

			random_fx = [];
			random_fx[0] = level._effect["fx_zombie_bar_break"];
			random_fx[1] = level._effect["fx_zombie_bar_break_lite"];
			random_fx[2] = level._effect["fx_zombie_bar_break"];
			random_fx[3] = level._effect["fx_zombie_bar_break_lite"];
			// now I need a random int between 0 and 3
			random_fx = array_randomize( random_fx );

			switch( randomInt( 9 ) ) // This sets up random versions of the bars being pulled apart for variety
			{
				case 0:
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
					break;

				case 1:
								PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_top" );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_bottom" );
					break;

				case 2:
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_bottom" );
					break;

				case 3:
								PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_top" );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
					break;

				case 4:
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
					break;

				case 5:
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
					break;
				case 6:
								PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
					break;
				case 7:
								PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_top" );
					break;
				case 8:
								PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_bottom" );
					break;
			}
		}

		if ( IsDefined ( chunk.script_parameters ) && ( chunk.script_parameters == "grate" ) )
		{
			EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
			chunk play_sound_on_ent( "bar_rebuild_slam" );

			switch( randomInt( 9 ) ) // This sets up random versions of the bars being pulled apart for variety
			{
				case 0:
								PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
					break;

				case 1:
								PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );

					break;

				case 2:
								PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );

					break;

				case 3:
								PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );

					break;

				case 4:
								PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
								wait( randomfloat( 0.0, 0.3 ));
								PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
					break;

				case 5:
								PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
					break;
				case 6:
								PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
					break;
				case 7:
								PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
					break;
				case 8:
								PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
					break;
			}
		}
}

//jl I am doing this so I can have an offset of timing for when the chunks come off to give it more life
zombie_bartear_offset_fx_horizontle( chunk )
{
	if ( IsDefined ( chunk.script_parameters ) && ( chunk.script_parameters == "bar" ) || ( chunk.script_noteworthy == "board" ))
	{
		switch( randomInt( 10 ) ) // This sets up random versions of the bars being pulled apart for variety
		{
			case 0:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
			break;

			case 1:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_right" );
			break;

			case 2:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_right" );
			break;

			case 3:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
			break;

			case 4:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
			break;

			case 5:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
			break;
			case 6:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
			break;
			case 7:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_right" );
			break;
			case 8:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_right" );
			break;
		}
	}
}


check_for_zombie_death(zombie)
{
	self endon("destroyed");

	wait(2.5);
	self maps\_zombiemode_blockers::update_states("repaired");
}



get_tear_anim( chunk, zombo ) // zombo is self
{
	anims = [];
	anims[anims.size] = %ai_zombie_door_tear_high;
	anims[anims.size] = %ai_zombie_door_tear_low;
	anims[anims.size] = %ai_zombie_door_tear_left;
	anims[anims.size] = %ai_zombie_door_tear_right;
	anims[anims.size] = %ai_zombie_door_tear_v1;
	anims[anims.size] = %ai_zombie_door_tear_v2;
	anims[anims.size] = %ai_zombie_door_pound_v1;
	anims[anims.size] = %ai_zombie_door_pound_v2;

	tear_anim = anims[RandomInt( anims.size )];

//---------------------------STANDING-----------------------------------------------------------
	if(isdefined(chunk.script_parameters))
	{

		if( chunk.script_parameters == "board" || chunk.script_parameters == "repair_board") // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{

			if( self.has_legs )
			{

				if(isdefined(chunk.script_noteworthy))
				{
					if(IsDefined(chunk.unbroken) && chunk.unbroken == true)
					{
						// metal vents.
						if(IsDefined(chunk.material) && chunk.material == "metal")
						{
							if(chunk.script_noteworthy == "1")
							{
								tear_anim = %ai_zombie_boardtear_m_1;
							}
							if(chunk.script_noteworthy == "2")
							{
								tear_anim = %ai_zombie_boardtear_m_4;
							}
							if(chunk.script_noteworthy == "3")
							{
								tear_anim = %ai_zombie_door_tear_low;
							}
							if(chunk.script_noteworthy == "4")
							{
								tear_anim = %ai_zombie_boardtear_m_5;
							}
							if(chunk.script_noteworthy == "5")
							{
								tear_anim = %ai_zombie_door_tear_low;
							}
							if(chunk.script_noteworthy == "6")
							{
								tear_anim = %ai_zombie_boardtear_m_6;
							}
						}
						else if(IsDefined(chunk.material) && chunk.material == "glass")
						{
							tear_anim = %ai_zombie_door_pound_v2;
						}
						else
						{
							if(RandomInt(100) < 50)
							{
								tear_anim = %ai_zombie_door_pound_v1;
								zombo.random_tear_anim = 1;
							}
							else
							{
								tear_anim = %ai_zombie_door_pound_v2;
								zombo.random_tear_anim = 2;
							}
						}
					}
					else if(zombo.attacking_spot_index == 0) // This is the center
					{

						if(chunk.script_noteworthy == "1") // this is the order
						{

							tear_anim = %ai_zombie_boardtear_m_1;

						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_m_2;
						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_m_3;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_m_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_m_5;
						}
						else if(chunk.script_noteworthy == "6")
						{

							tear_anim = %ai_zombie_boardtear_m_6;
						}

					}
					else if(zombo.attacking_spot_index == 1) // right
					{
						if(chunk.script_noteworthy == "1")
						{
							tear_anim = %ai_zombie_boardtear_r_1;
						}
						else if(chunk.script_noteworthy == "3")
						{
							tear_anim = %ai_zombie_boardtear_r_3;
						}
						else if(chunk.script_noteworthy == "4")
						{
							tear_anim = %ai_zombie_boardtear_r_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_r_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_r_6;
						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_r_2;
						}

					}
					else if(zombo.attacking_spot_index == 2) // left
					{
						if(chunk.script_noteworthy == "1")
						{

							tear_anim = %ai_zombie_boardtear_l_1;

						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_l_2;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_l_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_l_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_l_6;
						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_l_3;
						}

					}
				}
			}
			else if( self.has_legs == false )
			{

				if(isdefined(chunk.script_noteworthy))
				{

					if(zombo.attacking_spot_index == 0)
					{
						if(chunk.script_noteworthy == "1")
						{

							tear_anim = %ai_zombie_boardtear_crawl_m_1;

						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_crawl_m_2;
						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_crawl_m_3;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_crawl_m_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_crawl_m_5;
						}
						else if(chunk.script_noteworthy == "6")
						{

							tear_anim = %ai_zombie_boardtear_crawl_m_6;
						}

					}
					else if(zombo.attacking_spot_index == 1)
					{
						if(chunk.script_noteworthy == "1")
						{

							tear_anim = %ai_zombie_boardtear_crawl_r_1;

						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_crawl_r_3;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_crawl_r_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_crawl_r_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_crawl_r_6;
						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_crawl_r_2;
						}

					}
					else if(zombo.attacking_spot_index == 2)
					{
						if(chunk.script_noteworthy == "1")
						{

							tear_anim = %ai_zombie_boardtear_crawl_l_1;

						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_crawl_l_2;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_crawl_l_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_crawl_l_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_crawl_l_6;
						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_crawl_l_3;
						}

					}
				}
			}
		}
		else if( chunk.script_parameters == "barricade_vents")
		{
			if( self.has_legs )
			{
				if(zombo.attacking_spot_index == 0)
				{
					if(chunk.script_noteworthy == "1")
					{
						tear_anim = %ai_zombie_boardtear_m_1;
					}
					if(chunk.script_noteworthy == "2")
					{
						tear_anim = %ai_zombie_boardtear_m_4;
					}
					if(chunk.script_noteworthy == "3")
					{
						tear_anim = %ai_zombie_boardtear_m_3;
					}
					if(chunk.script_noteworthy == "4")
					{
						tear_anim = %ai_zombie_boardtear_m_5;
					}
					if(chunk.script_noteworthy == "5")
					{
						tear_anim = %ai_zombie_boardtear_m_2;
					}
					if(chunk.script_noteworthy == "6")
					{
						tear_anim = %ai_zombie_boardtear_m_6;
					}
				}
				else if(zombo.attacking_spot_index == 1) // right
				{
					if(chunk.script_noteworthy == "1")
					{
						tear_anim = %ai_zombie_boardtear_r_1;
					}
					else if(chunk.script_noteworthy == "3")
					{
						tear_anim = %ai_zombie_boardtear_r_3;
					}
					else if(chunk.script_noteworthy == "4")
					{
						tear_anim = %ai_zombie_boardtear_r_4;
					}
					else if(chunk.script_noteworthy == "5")
					{
						tear_anim = %ai_zombie_boardtear_r_5;
					}
					else if(chunk.script_noteworthy == "6")
					{
						tear_anim = %ai_zombie_boardtear_r_6;
					}
					else if(chunk.script_noteworthy == "2")
					{
						tear_anim = %ai_zombie_boardtear_r_2;
					}
				}
				else if(zombo.attacking_spot_index == 2) // left
				{
					if(chunk.script_noteworthy == "1")
					{
						tear_anim = %ai_zombie_boardtear_l_1;
					}
					else if(chunk.script_noteworthy == "2")
					{
						tear_anim = %ai_zombie_boardtear_l_2;
					}
					else if(chunk.script_noteworthy == "4")
					{
						tear_anim = %ai_zombie_boardtear_l_4;
					}
					else if(chunk.script_noteworthy == "5")
					{
						tear_anim = %ai_zombie_boardtear_l_5;
					}
					else if(chunk.script_noteworthy == "6")
					{
						tear_anim = %ai_zombie_boardtear_l_6;
					}
					else if(chunk.script_noteworthy == "3")
					{
						tear_anim = %ai_zombie_boardtear_l_3;
					}
				}
			}
			if( self.has_legs == false )
			{
				if(isdefined(chunk.script_noteworthy))
				{
					if(zombo.attacking_spot_index == 0)
					{
						if(chunk.script_noteworthy == "1")
						{
							tear_anim = %ai_zombie_boardtear_crawl_m_1;
						}
						else if(chunk.script_noteworthy == "2")
						{
							tear_anim = %ai_zombie_boardtear_crawl_m_2;
						}
						else if(chunk.script_noteworthy == "3")
						{
							tear_anim = %ai_zombie_boardtear_crawl_m_3;
						}
						else if(chunk.script_noteworthy == "4")
						{
							tear_anim = %ai_zombie_boardtear_crawl_m_4;
						}
						else if(chunk.script_noteworthy == "5")
						{
							tear_anim = %ai_zombie_boardtear_crawl_m_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_crawl_m_6;
						}
					}
					else if(zombo.attacking_spot_index == 1)
					{
						if(chunk.script_noteworthy == "1")
						{
							tear_anim = %ai_zombie_boardtear_crawl_r_1;
						}
						else if(chunk.script_noteworthy == "3")
						{
							tear_anim = %ai_zombie_boardtear_crawl_r_3;
						}
						else if(chunk.script_noteworthy == "4")
						{
							tear_anim = %ai_zombie_boardtear_crawl_r_4;
						}
						else if(chunk.script_noteworthy == "5")
						{
							tear_anim = %ai_zombie_boardtear_crawl_r_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_crawl_r_6;
						}
						else if(chunk.script_noteworthy == "2")
						{
							tear_anim = %ai_zombie_boardtear_crawl_r_2;
						}
					}
					else if(zombo.attacking_spot_index == 2)
					{
						if(chunk.script_noteworthy == "1")
						{
							tear_anim = %ai_zombie_boardtear_crawl_l_1;
						}
						else if(chunk.script_noteworthy == "2")
						{
							tear_anim = %ai_zombie_boardtear_crawl_l_2;
						}
						else if(chunk.script_noteworthy == "4")
						{
							tear_anim = %ai_zombie_boardtear_crawl_l_4;
						}
						else if(chunk.script_noteworthy == "5")
						{
							tear_anim = %ai_zombie_boardtear_crawl_l_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_crawl_l_6;
						}
						else if(chunk.script_noteworthy == "3")
						{
							tear_anim = %ai_zombie_boardtear_crawl_l_3;
						}
					}
				}
			}
		}
	// jl new code
	// bar 5 and 3 now get bent they do not get thrown off
	// swap four and six for priority
		else if( chunk.script_parameters == "bar" )
		{
			if( self.has_legs )
			{

				if(isdefined(chunk.script_noteworthy))
				{

					if(zombo.attacking_spot_index == 0) // center
					{

						if(chunk.script_noteworthy == "4") // high bar
						{

							tear_anim = %ai_zombie_bartear_m_5;
						}

						else if(chunk.script_noteworthy == "6") // this is low bar
						{

							tear_anim = %ai_zombie_bartear_m_6;
						}

						else if(chunk.script_noteworthy == "1")
						{

							tear_anim = %ai_zombie_bartear_m_3; // second bar from right
							// I can send a notify from here that one type of board is removed but I need to know what window it is from

						}
						else if(chunk.script_noteworthy == "2") // far right
						{

							tear_anim = %ai_zombie_bartear_m_2;
							//tear_anim = %ai_zombie_bartear_m_2; this is the old
						}
						else if(chunk.script_noteworthy == "3") // second bar from right
						{
							tear_anim = %ai_zombie_bar_bend_m_2; // new tear anim
							// alignment is too off
						}

						else if(chunk.script_noteworthy == "5") // this is the far left , this bar now bends it does not leave
						{
							tear_anim = %ai_zombie_bar_bend_m_1; // this is off
						}

					}
					else if(zombo.attacking_spot_index == 1) // right side
					{
						if(chunk.script_noteworthy == "4") // this is the reference for the high bar
						{
							tear_anim = %ai_zombie_bartear_r_5; // anim this is the high grab
							//tear_anim = %ai_zombie_bartear_r_3; this is what it used to be middle left
						}
						else if(chunk.script_noteworthy == "6") // this looks good this is the low bar
						{
							tear_anim = %ai_zombie_bartear_r_6; // anim low grabs
						}


						else if(chunk.script_noteworthy == "1") // this looks good this is second to right
						{
							tear_anim = %ai_zombie_bartear_r_3; // anim second bar from right
						}
						else if(chunk.script_noteworthy == "3") // this is the far right
						{
							tear_anim = %ai_zombie_bar_bend_r; // anim  this is far right
						}
						else if(chunk.script_noteworthy == "2") // this is second to left
						{
							tear_anim = %ai_zombie_bartear_r_2; // anim this grabs the sedonc bar from the left
						}
						else if(chunk.script_noteworthy == "5") // this is far left
						{
							tear_anim = %ai_zombie_bar_bend_r_2; // anim this tears the far left
						}

					}
					else if(zombo.attacking_spot_index == 2) // this is working good now.
					{
						if(chunk.script_noteworthy == "4") // this is the high bar
						{
							tear_anim = %ai_zombie_bartear_l_5;
						}
						else if(chunk.script_noteworthy == "6") // this is the low bar
						{
							tear_anim = %ai_zombie_bartear_l_6;
						}


						else if(chunk.script_noteworthy == "1") // second bar to the right
						{

							tear_anim = %ai_zombie_bartear_l_3;

						}
						else if(chunk.script_noteworthy == "2") // this is second to the left
						{

							tear_anim = %ai_zombie_bartear_l_2;
						}
						else if(chunk.script_noteworthy == "5") // this is the far left
						{
							tear_anim = %ai_zombie_bar_bend_l;
						}

						else if(chunk.script_noteworthy == "3") // this is the far right
						{
							tear_anim = %ai_zombie_bar_bend_L_2;

						}

					}
				}
			}
			if( self.has_legs == false )
			{

				if(isdefined(chunk.script_noteworthy))
				{

					if(zombo.attacking_spot_index == 0)
					{
						if(chunk.script_noteworthy == "1") // second to right
						{

							tear_anim = %ai_zombie_bartear_crawl_m_2;

						}
						else if(chunk.script_noteworthy == "2") // far right
						{

							tear_anim = %ai_zombie_bartear_crawl_m_3;
							//tear_anim = %ai_zombie_bartear_m_2; this is the old
						}
						else if(chunk.script_noteworthy == "3") // second bar from left
						{

							tear_anim = %ai_zombie_bartear_crawl_m_1;
						}
						else if(chunk.script_noteworthy == "4") // high bar
						{

							tear_anim = %ai_zombie_bartear_crawl_m_5;
						}
						else if(chunk.script_noteworthy == "5") // this is the far left
						{

							tear_anim = %ai_zombie_bartear_crawl_m_4;
						}
						else if(chunk.script_noteworthy == "6") // this is low bar
						{

							tear_anim = %ai_zombie_bartear_crawl_m_6;
						}

					}
					else if(zombo.attacking_spot_index == 1)
					{
						if(chunk.script_noteworthy == "1") // this looks good this is second to right
						{
							tear_anim = %ai_zombie_bartear_crawl_r_2; // anim second bar from right
						}
						else if(chunk.script_noteworthy == "3") // this is the far right
						{
							tear_anim = %ai_zombie_bartear_crawl_r_1; // anim  this is far right
						}
						else if(chunk.script_noteworthy == "2") // this is second to left
						{
							tear_anim = %ai_zombie_bartear_crawl_r_3; // anim this grabs the sedonc bar from the left
						}
						else if(chunk.script_noteworthy == "5") // this is far left
						{
							tear_anim = %ai_zombie_bartear_crawl_r_4; // anim this tears the far left
						}
						else if(chunk.script_noteworthy == "6") // this looks good this is the low bar
						{
							tear_anim = %ai_zombie_bartear_crawl_r_6; // anim low grabs
						}
						else if(chunk.script_noteworthy == "4") // this is the reference for the high bar
						{
							tear_anim = %ai_zombie_bartear_crawl_r_5; // anim this is the high grab
							//tear_anim = %ai_zombie_bartear_r_3; this is what it used to be middle left
						}


					}
					else if(zombo.attacking_spot_index == 2)
					{
						if(chunk.script_noteworthy == "1") // second bar to the right
						{

							tear_anim = %ai_zombie_bartear_crawl_l_2;

						}
						else if(chunk.script_noteworthy == "2") // this is second to the left
						{

							tear_anim = %ai_zombie_bartear_crawl_l_3;
						}
						else if(chunk.script_noteworthy == "4") // this is the high bar
						{

							tear_anim = %ai_zombie_bartear_crawl_l_5;
						}
						else if(chunk.script_noteworthy == "5") // this is the far left
						{

							tear_anim = %ai_zombie_bartear_crawl_l_4;
						}
						else if(chunk.script_noteworthy == "6") // this is the low bar
						{
							tear_anim = %ai_zombie_bartear_crawl_l_6;
						}
						else if(chunk.script_noteworthy == "3") // this is the far right
						{

							tear_anim = %ai_zombie_bartear_crawl_l_1;
						}

					}
				}
			}
		}
		// jl added grate
		// I need to set up the crate here
		else if( chunk.script_parameters == "grate" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{

			if( self.has_legs )
			{

				if(isdefined(chunk.script_noteworthy))
				{

					if(zombo.attacking_spot_index == 0) // This is the center
					{
						if(chunk.script_noteworthy == "1") // this is the order
						{

							tear_anim = %ai_zombie_boardtear_m_1;

						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_m_2;
						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_m_3;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_m_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_m_5;
						}
						else if(chunk.script_noteworthy == "6")
						{

							tear_anim = %ai_zombie_boardtear_m_6;
						}

					}
					else if(zombo.attacking_spot_index == 1) // right
					{
						if(chunk.script_noteworthy == "1")
						{

							tear_anim = %ai_zombie_boardtear_r_1;

						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_r_3;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_r_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_r_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_r_6;
						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_r_2;
						}

					}
					else if(zombo.attacking_spot_index == 2) // left
					{
						if(chunk.script_noteworthy == "1")
						{

							tear_anim = %ai_zombie_boardtear_l_1;

						}
						else if(chunk.script_noteworthy == "2")
						{

							tear_anim = %ai_zombie_boardtear_l_2;
						}
						else if(chunk.script_noteworthy == "4")
						{

							tear_anim = %ai_zombie_boardtear_l_4;
						}
						else if(chunk.script_noteworthy == "5")
						{

							tear_anim = %ai_zombie_boardtear_l_5;
						}
						else if(chunk.script_noteworthy == "6")
						{
							tear_anim = %ai_zombie_boardtear_l_6;
						}
						else if(chunk.script_noteworthy == "3")
						{

							tear_anim = %ai_zombie_boardtear_l_3;
						}

					}
				}
			}
		}
	}

	return tear_anim;
}

cap_zombie_head_gibs()
{
	if( !isDefined( level.max_head_gibs_per_frame ) )
	{
		level.max_head_gibs_per_frame = 4;
	}

	while( true )
	{
		level.head_gibs_this_frame = 0;
		wait_network_frame();
	}
}

zombie_head_gib( attacker, means_of_death, tesla )
{
	self endon( "death" );

	if ( !is_mature() )
	{
		return false;
	}

	if ( is_german_build() )
	{
		return;
	}

	if( IsDefined( self.head_gibbed ) && self.head_gibbed )
	{
		return;
	}

	if( !isDefined( level.head_gibs_this_frame ) )
	{
		level thread cap_zombie_head_gibs();
	}

	if( level.head_gibs_this_frame >= level.max_head_gibs_per_frame )
	{
		return;
	}

	level.head_gibs_this_frame++;

	self.head_gibbed = true;

	self zombie_eye_glow_stop();

	size = self GetAttachSize();
	for( i = 0; i < size; i++ )
	{
		model = self GetAttachModelName( i );
		if( IsSubStr( model, "head" ) )
		{
			// SRS 9/2/2008: wet em up
//			self thread headshot_blood_fx();
			if(isdefined(self.hatmodel))
			{
				self detach( self.hatModel, "" );
			}

			self play_sound_on_ent( "zombie_head_gib" );

			self Detach( model, "", true );
			if ( isDefined(self.torsoDmg5) )
			{
				self Attach( self.torsoDmg5, "", true );
			}
			break;
		}
	}

	temp_array = [];
	temp_array[0] = level._ZOMBIE_GIB_PIECE_INDEX_HEAD;
	self gib( "normal", temp_array );
}

damage_over_time( dmg, delay, attacker, means_of_death )
{
	self endon( "death" );

	if( !IsAlive( self ) )
	{
		return;
	}

	if( !IsPlayer( attacker ) )
	{
		attacker = undefined;
	}

	while( 1 )
	{
		if( IsDefined( delay ) )
		{
			wait( delay );
		}

		self DoDamage( dmg, self.origin, attacker, undefined, means_of_death, self.damagelocation );
	}
}

// SRS 9/2/2008: reordered checks, added ability to gib heads with airburst grenades
head_should_gib( attacker, type, point )
{
	if ( !is_mature() )
	{
		return false;
	}

	if ( is_german_build() )
	{
		return false;
	}

	if( self.head_gibbed )
	{
		return false;
	}

	// check if the attacker was a player
	if( !IsDefined( attacker ) || !IsPlayer( attacker ) )
	{
		return false;
	}

	// check the enemy's health
	low_health_percent = ( self.health / self.maxhealth ) * 100;
	if( low_health_percent > 0 )
	{
		return false;
	}

	weapon = attacker GetCurrentWeapon();


	// SRS 9/2/2008: check for damage type
	//  - most SMGs use pistol bullets
	//  - projectiles = rockets, raygun
	if( type != "MOD_RIFLE_BULLET" && type != "MOD_PISTOL_BULLET" )
	{
		// maybe it's ok, let's see if it's a grenade
		if( type == "MOD_GRENADE" || type == "MOD_GRENADE_SPLASH" )
		{
			if( Distance( point, self GetTagOrigin( "j_head" ) ) > 55 )
			{
				return false;
			}
			else
			{
				// the grenade airburst close to the head so return true
				return true;
			}
		}
		else if( type == "MOD_PROJECTILE" )
		{
			if( Distance( point, self GetTagOrigin( "j_head" ) ) > 10 )
			{
				return false;
			}
			else
			{
				return true;
			}
		}
		// shottys don't give a testable damage type but should still gib heads
		else if( WeaponClass( weapon ) != "spread" )
		{
			return false;
		}
	}

	// check location now that we've checked for grenade damage (which reports "none" as a location)
	if( !animscripts\utility::damageLocationIsAny( "head", "helmet", "neck" ) )
	{
		return false;
	}

	// check weapon - don't want "none", base pistol, or flamethrower
	if( weapon == "none"  || weapon == "m1911_zm" || WeaponIsGasWeapon( self.weapon ) )
	{
		return false;
	}

	return true;
}

// does blood fx for fun and to mask head gib swaps
headshot_blood_fx()
{
	if( !IsDefined( self ) )
	{
		return;
	}

	if( !is_mature() )
	{
		return;
	}

	fxTag = "j_neck";
	fxOrigin = self GetTagOrigin( fxTag );
	upVec = AnglesToUp( self GetTagAngles( fxTag ) );
	forwardVec = AnglesToForward( self GetTagAngles( fxTag ) );

	// main head pop fx
	PlayFX( level._effect["headshot"], fxOrigin, forwardVec, upVec );
	PlayFX( level._effect["headshot_nochunks"], fxOrigin, forwardVec, upVec );

	wait( 0.3 );
	if(IsDefined( self ))
	{
		if( self maps\_zombiemode_weap_tesla::enemy_killed_by_tesla() )
		{
			PlayFxOnTag( level._effect["tesla_head_light"], self, fxTag );
		}
		else
		{
			PlayFxOnTag( level._effect["bloodspurt"], self, fxTag );
		}
	}
}


// gib limbs if enough firepower occurs
zombie_gib_on_damage()
{
//	self endon( "death" );

	while( 1 )
	{
		self waittill( "damage", amount, attacker, direction_vec, point, type );

		if( !IsDefined( self ) )
		{
			return;
		}

		if( !self zombie_should_gib( amount, attacker, type ) )
		{
			continue;
		}

		if( self head_should_gib( attacker, type, point ) && type != "MOD_BURNED" )
		{
			self zombie_head_gib( attacker, type );
			if(IsDefined(attacker.headshot_count))
			{
				attacker.headshot_count++;
			}
			else
			{
				attacker.headshot_count = 1;
			}
			//stats tracking
			attacker.stats["headshots"] = attacker.headshot_count;
			attacker.stats["zombie_gibs"]++;

			continue;
		}

		if( !self.gibbed )
		{
			// The head_should_gib() above checks for this, so we should not randomly gib if shot in the head
			if( self animscripts\utility::damageLocationIsAny( "head", "helmet", "neck" ) && type != "MOD_MELEE" )
			{
				continue;
			}



			refs = [];
			switch( self.damageLocation )
			{
				case "torso_upper":
				case "torso_lower":
					// HACK the torso that gets swapped for guts also removes the left arm
					//  so we need to sometimes do another ref
					refs[refs.size] = "guts";
					refs[refs.size] = "right_arm";
					break;

				case "right_arm_upper":
				case "right_arm_lower":
				case "right_hand":
					//if( IsDefined( self.left_arm_gibbed ) )
					//	refs[refs.size] = "no_arms";
					//else
					refs[refs.size] = "right_arm";

					//self.right_arm_gibbed = true;
					break;

				case "left_arm_upper":
				case "left_arm_lower":
				case "left_hand":
					//if( IsDefined( self.right_arm_gibbed ) )
					//	refs[refs.size] = "no_arms";
					//else
					refs[refs.size] = "left_arm";

					//self.left_arm_gibbed = true;
					break;

				case "right_leg_upper":
				case "right_leg_lower":
				case "right_foot":
					if( self.health <= 0 )
					{
						// Addition "right_leg" refs so that the no_legs happens less and is more rare
						refs[refs.size] = "right_leg";
						refs[refs.size] = "right_leg";
						refs[refs.size] = "right_leg";
						refs[refs.size] = "no_legs";
					}
					break;

				case "left_leg_upper":
				case "left_leg_lower":
				case "left_foot":
					if( self.health <= 0 )
					{
						// Addition "left_leg" refs so that the no_legs happens less and is more rare
						refs[refs.size] = "left_leg";
						refs[refs.size] = "left_leg";
						refs[refs.size] = "left_leg";
						refs[refs.size] = "no_legs";
					}
					break;
			default:

				if( self.damageLocation == "none" )
				{
					// SRS 9/7/2008: might be a nade or a projectile
					if( type == "MOD_GRENADE" || type == "MOD_GRENADE_SPLASH" || type == "MOD_PROJECTILE" || type == "MOD_PROJECTILE_SPLASH" )
					{
						// ... in which case we have to derive the ref ourselves
						refs = self derive_damage_refs( point );
						break;
					}
				}
				else
				{
					if(type == "MOD_MELEE")
					{
						refs[refs.size] = "guts";
						refs[refs.size] = "right_arm";
						refs[refs.size] = "left_arm";
					}
					else
					{
						refs[refs.size] = "guts";
						refs[refs.size] = "right_arm";
						refs[refs.size] = "left_arm";
						refs[refs.size] = "right_leg";
						refs[refs.size] = "left_leg";
						refs[refs.size] = "no_legs";
					}
					break;
				}
			}

			if( refs.size )
			{
				self.a.gib_ref = animscripts\zombie_death::get_random( refs );

				//ray gun - always make crawlers
				/*if( (type == "MOD_PROJECTILE" || type == "MOD_PROJECTILE_SPLASH") && (self.damageweapon == "ray_gun_zm" || self.damageweapon == "ray_gun_upgraded_zm") && self.health > 0 && self.has_legs )
				{
					self.a.gib_ref = "no_legs";
				}*/

				// Don't stand if a leg is gone
				if( ( self.a.gib_ref == "no_legs" || self.a.gib_ref == "right_leg" || self.a.gib_ref == "left_leg" ) && self.health > 0 )
				{
					self.has_legs = false;
					self AllowedStances( "crouch" );

					// reduce collbox so player can jump over
					self setPhysParams( 15, 0, 24 );

					health = self.health;
					health = health * 0.1;

					which_anim = RandomInt( 5 );
					if(self.a.gib_ref == "no_legs")
					{
						if(randomint(100) < 50)
						{
							self.deathanim = %ai_zombie_crawl_death_v1;
							self set_run_anim( "death3" );
							self.run_combatanim = level.scr_anim[self.animname]["crawl_hand_1"];
							self.crouchRunAnim = level.scr_anim[self.animname]["crawl_hand_1"];
							self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl_hand_1"];
						}
						else
						{
							self.deathanim = %ai_zombie_crawl_death_v1;
							self set_run_anim( "death3" );
							self.run_combatanim = level.scr_anim[self.animname]["crawl_hand_2"];
							self.crouchRunAnim = level.scr_anim[self.animname]["crawl_hand_2"];
							self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl_hand_2"];
						}


					}
					else if( which_anim == 0 )
					{
						self.deathanim = %ai_zombie_crawl_death_v1;
						self set_run_anim( "death3" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl1"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl1"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl1"];
					}
					else if( which_anim == 1 )
					{
						self.deathanim = %ai_zombie_crawl_death_v2;
						self set_run_anim( "death4" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl2"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl2"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl2"];
					}
					else if( which_anim == 2 )
					{
						self.deathanim = %ai_zombie_crawl_death_v1;
						self set_run_anim( "death3" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl3"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl3"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl3"];
					}
					else if( which_anim == 3 )
					{
						self.deathanim = %ai_zombie_crawl_death_v2;
						self set_run_anim( "death4" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl4"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl4"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl4"];
					}
					else if( which_anim == 4 )
					{
						self.deathanim = %ai_zombie_crawl_death_v1;
						self set_run_anim( "death3" );
						self.run_combatanim = level.scr_anim[self.animname]["crawl5"];
						self.crouchRunAnim = level.scr_anim[self.animname]["crawl5"];
						self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl5"];
					}

					if ( isdefined( self.crawl_anim_override ) )
					{
						self [[ self.crawl_anim_override ]]();
					}
				}
			}

			//if( self.health > 0 )
			{
				// force gibbing if the zombie is still alive
				self thread animscripts\zombie_death::do_gib();

				//stat tracking
				if ( IsPlayer( self ) )
				{
					attacker.stats["zombie_gibs"]++;
				}
			}
		}
	}
}


zombie_should_gib( amount, attacker, type )
{
	if ( !is_mature() )
	{
		return false;
	}

	if ( is_german_build() )
	{
		return false;
	}

	if( !IsDefined( type ) )
	{
		return false;
	}

	if ( IsDefined( self.no_gib ) && ( self.no_gib == 1 ) )
	{
		return false;
	}

	if ( self maps\_zombiemode_weap_freezegun::is_freezegun_damage( type ) || self maps\_zombiemode_weap_freezegun::is_freezegun_shatter_damage( type ) )
	{
		return false;
	}

	switch( type )
	{
		case "MOD_UNKNOWN":
		case "MOD_CRUSH":
		case "MOD_TELEFRAG":
		case "MOD_FALLING":
		case "MOD_SUICIDE":
		case "MOD_TRIGGER_HURT":
		case "MOD_BURNED":
		case "MOD_IMPACT":
			return false;
		case "MOD_MELEE":
			if(!is_true(attacker._bowie_zm_equipped) && !is_true(attacker._sickle_zm_equipped))
			{
				return false;
			}
	}

	if( type == "MOD_PISTOL_BULLET" || type == "MOD_RIFLE_BULLET" )
	{
		if( !IsDefined( attacker ) || !IsPlayer( attacker ) )
		{
			return false;
		}

		weapon = attacker GetCurrentWeapon();

		if( weapon == "none" || weapon == "m1911_zm" )
		{
			return false;
		}

		if( WeaponIsGasWeapon( self.weapon ) )
		{
			return false;
		}
	}

	//ray gun - always gib
	/*if(self.animname == "zombie" || self.animname == "quad_zombie")
	{
		if( type == "MOD_PROJECTILE" || type == "MOD_PROJECTILE_SPLASH" )
		{
			if(self.damageweapon == "ray_gun_zm" || self.damageweapon == "ray_gun_upgraded_zm")
			{
				return true;
			}
		}
	}*/

//	println( "**DEBUG amount = ", amount );
//	println( "**DEBUG self.head_gibbed = ", self.head_gibbed );
//	println( "**DEBUG self.health = ", self.health );

	prev_health = amount + self.health;
	if( prev_health <= 0 )
	{
		prev_health = 1;
	}

	damage_percent = ( amount / prev_health ) * 100;

	if( damage_percent < 10 /*|| damage_percent >= 100*/ )
	{
		return false;
	}

	return true;
}

// SRS 9/7/2008: need to derive damage location for types that return location of "none"
derive_damage_refs( point )
{
	if( !IsDefined( level.gib_tags ) )
	{
		init_gib_tags();
	}

	closestTag = undefined;

	for( i = 0; i < level.gib_tags.size; i++ )
	{
		if( !IsDefined( closestTag ) )
		{
			closestTag = level.gib_tags[i];
		}
		else
		{
			if( DistanceSquared( point, self GetTagOrigin( level.gib_tags[i] ) ) < DistanceSquared( point, self GetTagOrigin( closestTag ) ) )
			{
				closestTag = level.gib_tags[i];
			}
		}
	}

	refs = [];

	// figure out the refs based on the tag returned
	if( closestTag == "J_SpineLower" || closestTag == "J_SpineUpper" || closestTag == "J_Spine4" )
	{
		// HACK the torso that gets swapped for guts also removes the left arm
		//  so we need to sometimes do another ref
		refs[refs.size] = "guts";
		refs[refs.size] = "right_arm";
	}
	else if( closestTag == "J_Shoulder_LE" || closestTag == "J_Elbow_LE" || closestTag == "J_Wrist_LE" )
	{
		refs[refs.size] = "left_arm";
	}
	else if( closestTag == "J_Shoulder_RI" || closestTag == "J_Elbow_RI" || closestTag == "J_Wrist_RI" )
	{
		refs[refs.size] = "right_arm";
	}
	else if( closestTag == "J_Hip_LE" || closestTag == "J_Knee_LE" || closestTag == "J_Ankle_LE" )
	{
		refs[refs.size] = "left_leg";
		refs[refs.size] = "no_legs";
	}
	else if( closestTag == "J_Hip_RI" || closestTag == "J_Knee_RI" || closestTag == "J_Ankle_RI" )
	{
		refs[refs.size] = "right_leg";
		refs[refs.size] = "no_legs";
	}

	ASSERTEX( array_validate( refs ), "get_closest_damage_refs(): couldn't derive refs from closestTag " + closestTag );

	return refs;
}


//
init_gib_tags()
{
	tags = [];

	// "guts", "right_arm", "left_arm", "right_leg", "left_leg", "no_legs"

	// "guts"
	tags[tags.size] = "J_SpineLower";
	tags[tags.size] = "J_SpineUpper";
	tags[tags.size] = "J_Spine4";

	// "left_arm"
	tags[tags.size] = "J_Shoulder_LE";
	tags[tags.size] = "J_Elbow_LE";
	tags[tags.size] = "J_Wrist_LE";

	// "right_arm"
	tags[tags.size] = "J_Shoulder_RI";
	tags[tags.size] = "J_Elbow_RI";
	tags[tags.size] = "J_Wrist_RI";

	// "left_leg"/"no_legs"
	tags[tags.size] = "J_Hip_LE";
	tags[tags.size] = "J_Knee_LE";
	tags[tags.size] = "J_Ankle_LE";

	// "right_leg"/"no_legs"
	tags[tags.size] = "J_Hip_RI";
	tags[tags.size] = "J_Knee_RI";
	tags[tags.size] = "J_Ankle_RI";

	level.gib_tags = tags;
}


//
//
zombie_can_drop_powerups( zombie )
{
	if( level.mutators["mutator_noPowerups"] )
	{
		return false;
	}

	if( !flag( "zombie_drop_powerups" ) ) //is_tactical_grenade( zombie.damageweapon )
	{
		return false;
	}

	if ( isdefined(zombie.no_powerups) && zombie.no_powerups )
	{
		return false;
	}

	return true;
}


//
//	award points on death
zombie_death_points( origin, mod, hit_location, attacker, zombie )
{
	if( !IsDefined( attacker ) || !IsPlayer( attacker ) )
	{
		return;
	}

	if( zombie_can_drop_powerups( zombie ) )
	{
		// DCS 031611: hack to prevent risers from dropping powerups under the ground.
		if(IsDefined(zombie.in_the_ground) && zombie.in_the_ground == true)
		{
			trace = BulletTrace(zombie.origin + (0, 0, 100), zombie.origin + (0, 0, -100), false, undefined);
			origin = trace["position"];
			level thread maps\_zombiemode_powerups::powerup_drop( origin, attacker, zombie );
		}
		else
		{
			trace = GroundTrace(zombie.origin + (0, 0, 5), zombie.origin + (0, 0, -300), false, undefined);
			origin = trace["position"];
			level thread maps\_zombiemode_powerups::powerup_drop( origin, attacker, zombie );
		}
	}

	//AUDIO: Ayers - Decides what vox to play after killing a zombie
	level thread maps\_zombiemode_audio::player_zombie_kill_vox( hit_location, attacker, mod, zombie );

	event = "death";
	if ( (issubstr( zombie.damageweapon, "knife_ballistic_" )) && (mod == "MOD_MELEE" || mod == "MOD_IMPACT") )
	{
		event = "ballistic_knife_death";
	}

	attacker maps\_zombiemode_score::player_add_points( event, mod, hit_location );
}

get_number_variants(aliasPrefix)
{
		for(i=0; i<100; i++)
		{
			if( !SoundExists( aliasPrefix + "_" + i) )
			{
				//iprintlnbold(aliasPrefix +"_" + i);
				return i;
			}
		}
}


dragons_breath_flame_death_fx()
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


// Called from animscripts\zombie_death.gsc
zombie_death_animscript()
{
	self reset_attack_spot();

	if ( self check_zombie_death_animscript_callbacks() )
	{
		return false;
	}

	if( self maps\_zombiemode_weap_tesla::enemy_killed_by_tesla() || self maps\_zombiemode_weap_thundergun::enemy_killed_by_thundergun() )
	{
		return false;
	}
	if ( self maps\_zombiemode_weap_freezegun::should_do_freezegun_death( self.damagemod ) )
	{
		self thread maps\_zombiemode_weap_freezegun::freezegun_death( self.damagelocation, self.origin, self.attacker );
	}
	if ( self maps\_zombiemode_weap_freezegun::is_freezegun_shatter_damage( self.damagemod ) )
	{
		// no points awarded for damage or deaths dealt by the shatter result
		return false;
	}

	// animscript override
	if( IsDefined( level.zombie_death_animscript_override ) )
	{
		self [ [ level.zombie_death_animscript_override ] ] ();
	}

	// If no_legs, then use the AI no-legs death
	if( self.has_legs && IsDefined( self.a.gib_ref ) && self.a.gib_ref == "no_legs" )
	{
		self.deathanim = %ai_gib_bothlegs_gib;
	}

	self.grenadeAmmo = 0;

	// rsh090710 - nuked zombies don't give points but should still possibly drop powerups
	if ( IsDefined( self.nuked ) )
	{
		if( zombie_can_drop_powerups( self ) )
		{
			// DCS 031611: hack to prevent risers from dropping powerups under the ground.
			if(IsDefined(self.in_the_ground) && self.in_the_ground == true)
			{
				trace = BulletTrace(self.origin + (0, 0, 100), self.origin + (0, 0, -100), false, undefined);
				origin = trace["position"];
				level thread maps\_zombiemode_powerups::powerup_drop( origin, self.attacker, self );
			}
			else
			{
				trace = GroundTrace(self.origin + (0, 0, 5), self.origin + (0, 0, -300), false, undefined);
				origin = trace["position"];
				level thread maps\_zombiemode_powerups::powerup_drop( self.origin, self.attacker, self );
			}
		}
	}

	if(!IsDefined(self.nuked) && !IsDefined(self.trap_death))
	{
		// Give attacker points
		//ChrisP - 12/8/08 - added additional 'self' argument
		level zombie_death_points( self.origin, self.damagemod, self.damagelocation, self.attacker, self );
	}

	// switch to inflictor when SP DoDamage supports it
	if( isdefined( self.attacker ) && isai( self.attacker ) )
	{
		self.attacker notify( "killed", self );
	}


	if( "rottweil72_upgraded_zm" == self.damageweapon && "MOD_RIFLE_BULLET" == self.damagemod )
	{
		self thread dragons_breath_flame_death_fx();
	}
	if( self.damagemod == "MOD_BURNED" || (self.damageWeapon == "molotov_zm" && (self.damagemod == "MOD_GRENADE" || self.damagemod == "MOD_GRENADE_SPLASH")) )
	{
		if(level.flame_death_fx_frame < 5 && !self.isdog)
		{
			level.flame_death_fx_frame++;
			level thread reset_flame_death_fx_frame();
			self thread animscripts\zombie_death::flame_death_fx();
		}
	}
	if( self.damagemod == "MOD_GRENADE" || self.damagemod == "MOD_GRENADE_SPLASH" )
	{
		level notify( "zombie_grenade_death", self.origin );
	}

	return false;
}

reset_flame_death_fx_frame()
{
	level notify("reset_flame_death_fx_frame");
	level endon("reset_flame_death_fx_frame");

	wait_network_frame();

	level.flame_death_fx_frame = 0;
}


check_zombie_death_animscript_callbacks()
{
	if ( !isdefined( level.zombie_death_animscript_callbacks ) )
	{
		return false;
	}

	for ( i = 0; i < level.zombie_death_animscript_callbacks.size; i++ )
	{
		if ( self [[ level.zombie_death_animscript_callbacks[i] ]]() )
		{
			return true;
		}
	}

	return false;
}


register_zombie_death_animscript_callback( func )
{
	if ( !isdefined( level.zombie_death_animscript_callbacks ) )
	{
		level.zombie_death_animscript_callbacks = [];
	}

	level.zombie_death_animscript_callbacks[level.zombie_death_animscript_callbacks.size] = func;
}


damage_on_fire( player )
{
	self endon ("death");
	self endon ("stop_flame_damage");
	//wait( 2 );
	wait( randomfloatrange( 1.0, 3.0 ) );

	while( isdefined( self.is_on_fire) && self.is_on_fire )
	{
		/*if( level.round_number < 6 )
		{
			dmg = level.zombie_health * RandomFloatRange( 0.2, 0.3 ); // 20% - 30%
		}
		else if( level.round_number < 9 )
		{
			dmg = level.zombie_health * RandomFloatRange( 0.15, 0.25 );
		}
		else if( level.round_number < 11 )
		{
			dmg = level.zombie_health * RandomFloatRange( 0.1, 0.2 );
		}
		else
		{
			dmg = level.zombie_health * RandomFloatRange( 0.1, 0.15 );
		}*/

		dmg = 500;

		if ( Isdefined( player ) && Isalive( player ) )
		{
			self DoDamage( dmg, self.origin, player );
		}
		else
		{
			self DoDamage( dmg, self.origin, level );
		}

		wait( randomfloatrange( 1.0, 3.0 ) );
	}
}

player_using_hi_score_weapon( player )
{
	weapon = player GetCurrentWeapon();
	if( weapon == "none" || WeaponIsSemiAuto( weapon ) )
	{
		return( 1 );
	}
	return( 0 );
}

zombie_damage( mod, hit_location, hit_origin, player, amount )
{
	if( is_magic_bullet_shield_enabled( self ) )
	{
		return;
	}

	//ChrisP - 12/8 - no points for killing gassed zombies!
	player.use_weapon_type = mod;
	if(isDefined(self.marked_for_death))
	{
		return;
	}

	if( !IsDefined( player ) )
	{
		return;
	}

	if ( self check_zombie_damage_callbacks( mod, hit_location, hit_origin, player, amount ) )
	{
		return;
	}
	else if( self zombie_flame_damage( mod, player ) )
	{
		if( self zombie_give_flame_damage_points() && !is_true( self.no_damage_points ) )
		{
			player maps\_zombiemode_score::player_add_points( "damage", mod, hit_location, self.isdog );
		}
	}
	else if( self maps\_zombiemode_weap_tesla::is_tesla_damage( mod ) )
	{
		self maps\_zombiemode_weap_tesla::tesla_damage_init( hit_location, hit_origin, player );
		return;
	}
	else
	{
		if ( self maps\_zombiemode_weap_freezegun::is_freezegun_damage( self.damagemod ) )
		{
			self thread maps\_zombiemode_weap_freezegun::freezegun_damage_response( player, amount );
		}

		// no points awarded for damage or deaths dealt by the shatter result
		if ( !self maps\_zombiemode_weap_freezegun::is_freezegun_shatter_damage( self.damagemod ) )
		{
			if( player_using_hi_score_weapon( player ) )
			{
				damage_type = "damage";
			}
			else
			{
				damage_type = "damage_light";
			}

			if ( !is_true( self.no_damage_points ) )
			{
				player maps\_zombiemode_score::player_add_points( damage_type, mod, hit_location, self.isdog );
			}
		}
	}

	if( "rottweil72_upgraded_zm" == self.damageweapon && "MOD_RIFLE_BULLET" == self.damagemod )
	{
		self thread dragons_breath_flame_death_fx();
	}

	if ( IsDefined( self.zombie_damage_fx_func ) )
	{
		self [[ self.zombie_damage_fx_func ]]( mod, hit_location, hit_origin, player );
	}

	modName = remove_mod_from_methodofdeath( mod );

	/*if ( self maps\_zombiemode_weap_freezegun::is_freezegun_damage( self.damagemod ) )
	{
		; // no scaling damage for the freezegun
	}
	else if( is_placeable_mine( self.damageweapon ) )
	{
		if ( IsDefined( self.zombie_damage_claymore_func ) )
		{
			self [[ self.zombie_damage_claymore_func ]]( mod, hit_location, hit_origin, player );
		}
		else if ( isdefined( player ) && isalive( player ) )
		{
			self DoDamage( level.round_number * randomintrange( 100, 200 ), self.origin, player);
		}
		else
		{
			self DoDamage( level.round_number * randomintrange( 100, 200 ), self.origin, undefined );
		}
	}
	else if ( mod == "MOD_GRENADE" || mod == "MOD_GRENADE_SPLASH" )
	{
		if ( isdefined( player ) && isalive( player ) )
		{
			self DoDamage( level.round_number + randomintrange( 100, 200 ), self.origin, player, 0, modName, hit_location);
		}
		else
		{
			self DoDamage( level.round_number + randomintrange( 100, 200 ), self.origin, undefined, 0, modName, hit_location );
		}
	}
	else if( mod == "MOD_PROJECTILE" || mod == "MOD_EXPLOSIVE" || mod == "MOD_PROJECTILE_SPLASH" )
	{
		if ( isdefined( player ) && isalive( player ) )
		{
			self DoDamage( level.round_number * randomintrange( 0, 100 ), self.origin, player, 0, modName, hit_location);
		}
		else
		{
			self DoDamage( level.round_number * randomintrange( 0, 100 ), self.origin, undefined, 0, modName, hit_location );
		}
	}*/

	//AUDIO Plays a sound when Crawlers are created
	if( IsDefined( self.a.gib_ref ) && (self.a.gib_ref == "no_legs") && isalive( self ) )
	{
		if ( isdefined( player ) )
		{
			rand = randomintrange(0, 100);
			if(rand < 10)
			{
				player create_and_play_dialog( "general", "crawl_spawn" );
			}
		}
	}
	else if( IsDefined( self.a.gib_ref ) && ( (self.a.gib_ref == "right_arm") || (self.a.gib_ref == "left_arm") ) )
	{
		if( self.has_legs && isalive( self ) )
		{
			if ( isdefined( player ) )
			{
				rand = randomintrange(0, 100);
				if(rand < 7)
				{
					player create_and_play_dialog( "general", "shoot_arm" );
				}
			}
		}
	}
	//self thread maps\_zombiemode_powerups::check_for_instakill( player, mod, hit_location );
}

zombie_damage_ads( mod, hit_location, hit_origin, player, amount )
{
	if( is_magic_bullet_shield_enabled( self ) )
	{
		return;
	}

	player.use_weapon_type = mod;
	if( !IsDefined( player ) )
	{
		return;
	}

	if ( self check_zombie_damage_callbacks( mod, hit_location, hit_origin, player, amount ) )
	{
		return;
	}
	else if( self zombie_flame_damage( mod, player ) )
	{
		if( self zombie_give_flame_damage_points() && !is_true( self.no_damage_points ) )
		{
			player maps\_zombiemode_score::player_add_points( "damage_ads", mod, hit_location );
		}
	}
	else if( self maps\_zombiemode_weap_tesla::is_tesla_damage( mod ) )
	{
		self maps\_zombiemode_weap_tesla::tesla_damage_init( hit_location, hit_origin, player );
		return;
	}
	else
	{
		if ( self maps\_zombiemode_weap_freezegun::is_freezegun_damage( self.damagemod ) )
		{
			self thread maps\_zombiemode_weap_freezegun::freezegun_damage_response( player, amount );
		}

		// no points awarded for damage or deaths dealt by the shatter result
		if ( !self maps\_zombiemode_weap_freezegun::is_freezegun_shatter_damage( self.damagemod ) )
		{
			if( player_using_hi_score_weapon( player ) )
			{
				damage_type = "damage";
			}
			else
			{
				damage_type = "damage_light";
			}

			if ( !is_true( self.no_damage_points ) )
			{
				player maps\_zombiemode_score::player_add_points( damage_type, mod, hit_location );
			}
		}
	}

	//self thread maps\_zombiemode_powerups::check_for_instakill( player, mod, hit_location );
}


check_zombie_damage_callbacks( mod, hit_location, hit_origin, player, amount )
{
	if ( !isdefined( level.zombie_damage_callbacks ) )
	{
		return false;
	}

	for ( i = 0; i < level.zombie_damage_callbacks.size; i++ )
	{
		if ( self [[ level.zombie_damage_callbacks[i] ]]( mod, hit_location, hit_origin, player, amount ) )
		{
			return true;
		}
	}

	return false;
}


register_zombie_damage_callback( func )
{
	if ( !isdefined( level.zombie_damage_callbacks ) )
	{
		level.zombie_damage_callbacks = [];
	}

	level.zombie_damage_callbacks[level.zombie_damage_callbacks.size] = func;
}


zombie_give_flame_damage_points()
{
	if( GetTime() > self.flame_damage_time )
	{
		self.flame_damage_time = GetTime() + level.zombie_vars["zombie_flame_dmg_point_delay"];
		return true;
	}

	return false;
}

zombie_flame_damage( mod, player )
{
	if( mod == "MOD_BURNED" )
	{
		self.moveplaybackrate = 0.8;

		if( !IsDefined( self.is_on_fire ) || ( Isdefined( self.is_on_fire ) && !self.is_on_fire ) )
		{
			self thread damage_on_fire( player );
		}

		do_flame_death = true;
		dist = 100 * 100;
		ai = GetAiArray( "axis" );
		for( i = 0; i < ai.size; i++ )
		{
			if( IsDefined( ai[i].is_on_fire ) && ai[i].is_on_fire )
			{
				if( DistanceSquared( ai[i].origin, self.origin ) < dist )
				{
					do_flame_death = false;
					break;
				}
			}
		}

		if( do_flame_death )
		{
			self thread animscripts\zombie_death::flame_death_fx();
		}

		return true;
	}

	return false;
}


zombie_death_event( zombie )
{
	zombie waittill( "death" );

	// Need to check in case he got deleted earlier
	if ( !IsDefined( zombie ) )
	{
		return;
	}

	//Track all zombies killed
	level.global_zombies_killed++;

	//track stats on zombies killed by traps
	if(isDefined(zombie.marked_for_death) && !isDefined(zombie.nuked))
	{
		level.zombie_trap_killed_count++;
	}

	zombie check_zombie_death_event_callbacks();

	// this gets called before the freezegun gets a chance to set freezegun_death, so we check whether it will do it
	if ( !zombie maps\_zombiemode_weap_freezegun::should_do_freezegun_death( zombie.damagemod ) )
	{
		zombie thread maps\_zombiemode_audio::do_zombies_playvocals( "death", zombie.animname );
		zombie thread zombie_eye_glow_stop();
	}

	if ( maps\_zombiemode_weapons::is_weapon_included( "freezegun_zm" ) )
	{
		zombie thread maps\_zombiemode_weap_freezegun::freezegun_clear_extremity_damage_fx();
		zombie thread maps\_zombiemode_weap_freezegun::freezegun_clear_torso_damage_fx();
	}

	// this is controlling killstreak voice over in the asylum.gsc
	if(isdefined (zombie.attacker) && isplayer(zombie.attacker) )
	{

		//this tracks the zombies killed by a player for stat tracking
		level.zombie_player_killed_count++;

		if(!isdefined ( zombie.attacker.killcounter))
		{
			zombie.attacker.killcounter = 1;
		}
		else
		{
			zombie.attacker.killcounter ++;
		}

		if ( IsDefined( zombie.sound_damage_player ) && zombie.sound_damage_player == zombie.attacker )
		{
			zombie.attacker maps\_zombiemode_audio::create_and_play_dialog( "kill", "damage" );
		}

		zombie.attacker notify( "zom_kill", zombie );

		damageloc = zombie.damagelocation;
		damagemod = zombie.damagemod;
		attacker = zombie.attacker;
		weapon = zombie.damageWeapon;

		bbPrint( "zombie_kills: round %d zombietype zombie damagetype %s damagelocation %s playername %s playerweapon %s playerx %f playery %f playerz %f zombiex %f zombiey %f zombiez %f",
				level.round_number, damagemod, damageloc, attacker.playername, weapon, attacker.origin, zombie.origin );
	}
	else
	{
		if(zombie.ignoreall && !is_true(zombie.marked_for_death)  )
		{
			level.zombies_timeout_spawn++;
		}
	}

	level notify( "zom_kill" );
	level.total_zombies_killed++;
}


check_zombie_death_event_callbacks()
{
	if ( !isdefined( level.zombie_death_event_callbacks ) )
	{
		return;
	}

	for ( i = 0; i < level.zombie_death_event_callbacks.size; i++ )
	{
		self [[ level.zombie_death_event_callbacks[i] ]]();
	}
}


register_zombie_death_event_callback( func )
{
	if ( !isdefined( level.zombie_death_event_callbacks ) )
	{
		level.zombie_death_event_callbacks = [];
	}

	level.zombie_death_event_callbacks[level.zombie_death_event_callbacks.size] = func;
}


// this is where zombies go into attack mode, and need different attributes set up
zombie_setup_attack_properties()
{
	self zombie_history( "zombie_setup_attack_properties()" );

	// allows zombie to attack again
	self.ignoreall = false;

	// push the player out of the way so they use traversals in the house.
	//self PushPlayer( true );

	self.pathEnemyFightDist = 64;
	self.meleeAttackDist = 64;

	//try to prevent always turning towards the enemy
	self.maxsightdistsqrd = 128 * 128;

	// turn off transition anims
	self.disableArrivals = true;
	self.disableExits = true;
}


// the seeker logic for zombies
find_flesh()
{
	self endon( "death" );
	level endon( "intermission" );
	self endon( "stop_find_flesh" );

	if( level.intermission )
	{
		return;
	}

	self.helitarget = true;
	self.ignoreme = false; // don't let attack dogs give chase until the zombie is in the playable area
	self.noDodgeMove = true; // WW (0107/2011) - script_forcegoal KVP overwites this variable which allows zombies to push the player in laststand

	//PI_CHANGE - 7/2/2009 JV Changing this to an array for the meantime until we get a more substantial fix
	//for ignoring multiple players - Reenabling change 274916 (from DLC3)
	self.ignore_player = [];

	self zombie_history( "find flesh -> start" );

	self.goalradius = 32;
	while( 1 )
	{
		zombie_poi = undefined;
		// try to split the zombies up when the bunch up
		// see if a bunch zombies are already near my current target; if there's a bunch
		// and I'm still far enough away, ignore my current target and go after another one
		near_zombies = getaiarray("axis");
		same_enemy_count = 0;
		for (i = 0; i < near_zombies.size; i++)
		{
			if ( isdefined( near_zombies[i] ) && isalive( near_zombies[i] ) )
			{
				if ( isdefined( near_zombies[i].favoriteenemy ) && isdefined( self.favoriteenemy )
				&&	near_zombies[i].favoriteenemy == self.favoriteenemy )
				{
					if ( distancesquared( near_zombies[i].origin, self.favoriteenemy.origin ) < 225 * 225
					&&	 distancesquared( near_zombies[i].origin, self.origin ) > 525 * 525)
					{
						same_enemy_count++;
					}
				}
			}
		}

		if (same_enemy_count > 12)
		{
			self.ignore_player[self.ignore_player.size] = self.favoriteenemy;
		}

		//PI_CHANGE_BEGIN - 6/18/09 JV It was requested that we use the poi functionality to set the "wait" point while all players
		//are in the process of teleportation. It should not intefere with the monkey.  The way it should work is, if all players are in teleportation,
		//zombies should go and wait at the stage, but if there is a valid player not in teleportation, they should go to him
		if (isDefined(level.zombieTheaterTeleporterSeekLogicFunc) )
		{
       		self [[ level.zombieTheaterTeleporterSeekLogicFunc ]]();
       	}
       	//PI_CHANGE_END

	    if( IsDefined( level._poi_override ) )
	    {
	    	zombie_poi = self [[ level._poi_override ]]();
	    }

	    if( !IsDefined( zombie_poi ) )
	    {
	    	zombie_poi = self get_zombie_point_of_interest( self.origin );
	    }

		players = get_players();

		// If playing single player, never ignore the player
		if( players.size == 1 )
		{
			self.ignore_player = [];
		}
		//PI_CHANGE_BEGIN - 7/2/2009 JV Reenabling change 274916 (from DLC3)
		else
		{
			for(i = 0; i < self.ignore_player.size; i++)
			{
				if( IsDefined( self.ignore_player[i] ) && IsDefined( self.ignore_player[i].ignore_counter ) && self.ignore_player[i].ignore_counter > 3 )
				{
					self.ignore_player[i].ignore_counter = 0;
					self.ignore_player = array_remove( self.ignore_player, self.ignore_player[i] );
				}
			}
		}
		//PI_CHANGE_END

		player = self get_closest_valid_player( self.origin, self.ignore_player );

		if( !isDefined( player ) && !isDefined( zombie_poi ) )
		{
			self zombie_history( "find flesh -> can't find player, continue" );
			if( IsDefined( self.ignore_player ) )
			{
				self.ignore_player = [];
			}

			wait( 1 );
			continue;
		}

		//PI_CHANGE - 7/2/2009 JV Reenabling change 274916 (from DLC3)
		//self.ignore_player = undefined;
		if ( !isDefined( level.check_for_alternate_poi ) || ![[level.check_for_alternate_poi]]() )
		{
			self.enemyoverride = zombie_poi;
			self.favoriteenemy = player;
		}

		self thread zombie_pathing();

		//PI_CHANGE_BEGIN - 7/2/2009 JV Reenabling change 274916 (from DLC3)
		if( players.size > 1 )
		{
			for(i = 0; i < self.ignore_player.size; i++)
			{
				if( IsDefined( self.ignore_player[i] ) )
				{
					if( !IsDefined( self.ignore_player[i].ignore_counter ) )
						self.ignore_player[i].ignore_counter = 0;
					else
						self.ignore_player[i].ignore_counter += 1;
				}
			}
		}
		//PI_CHANGE_END

		self thread attractors_generated_listener();

		rand_float = RandomFloatRange( 1, 3 );
		self.zombie_path_timer = GetTime() + ( rand_float * 1000 );// + path_timer_extension;
		level waittill_notify_or_timeout("attractor_positions_generated", rand_float);

		self notify( "path_timer_done" );

		self zombie_history( "find flesh -> bottom of loop" );

		debug_print( "Zombie is re-acquiring enemy, ending breadcrumb search" );
		self notify( "zombie_acquire_enemy" );
	}
}


//this lets them wake up and go after things like the monkey bomb immediately
attractors_generated_listener()
{
	self endon( "death" );
	level endon( "intermission" );
	self endon( "stop_find_flesh" );
	self endon( "path_timer_done" );

	level waittill( "attractor_positions_generated" );
	self.zombie_path_timer = 0;
}


zombie_pathing()
{
	self endon( "death" );
	self endon( "zombie_acquire_enemy" );
	level endon( "intermission" );

	/#
	self animscripts\debug::debugPushState( "zombie_pathing" );
	#/

	assert( IsDefined( self.favoriteenemy ) || IsDefined( self.enemyoverride ) );

	self thread zombie_follow_enemy();
	self waittill( "bad_path" );

	level.zombie_pathing_failed ++;

	//If we get here then we have a bad path and the zombie can't use the regular pathing system to find the player
	//.....  crap!

	if( isDefined( self.enemyoverride ) )
	{
		debug_print( "Zombie couldn't path to point of interest at origin: " + self.enemyoverride[0] + " Falling back to breadcrumb system" );
		if( isDefined( self.enemyoverride[1] ) )
		{
			self.enemyoverride = self.enemyoverride[1] invalidate_attractor_pos( self.enemyoverride, self );
			self.zombie_path_timer = 0;
			return;
		}
	}
	else
	{
		if( IsDefined( self.favoriteenemy ) )
		{
			debug_print( "Zombie couldn't path to player at origin: " + self.favoriteenemy.origin + " Falling back to breadcrumb system" );
		}
	}

	if( !isDefined( self.favoriteenemy ) )
	{
		self.zombie_path_timer = 0;
		return;
	}
	else
	{
		self.favoriteenemy endon( "disconnect" );
	}

	//this is for selecting the valid player from the player to use for tracking purposes.
	players = get_players();
	valid_player_num = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( is_player_valid( players[i], true ) )
		{
			valid_player_num += 1;
		}
	}
	//PI_CHANGE_BEGIN - 7/2/2009 JV Reenabling change 274916 (from DLC3)
	if( players.size > 1 )
	{
		if( array_check_for_dupes( self.ignore_player, self.favoriteenemy) )
		{
			self.ignore_player[self.ignore_player.size] = self.favoriteenemy;
		}

		if( self.ignore_player.size < valid_player_num )
		{
			self.zombie_path_timer = 0;
			return;
		}
	}
	//PI_CHANGE_END

	crumb_list = self.favoriteenemy.zombie_breadcrumbs;
	bad_crumbs = [];

	while( 1 )
	{
		if( !is_player_valid( self.favoriteenemy, true ) )
		{
			self.zombie_path_timer = 0;
			return;
		}

		goal = zombie_pathing_get_breadcrumb( self.favoriteenemy.origin, crumb_list, bad_crumbs, ( RandomInt( 100 ) < 20 ) );

		if ( !IsDefined( goal ) )
		{
			debug_print( "Zombie exhausted breadcrumb search" );

			//zombies failed to get breadcrumbs
			level.zombie_breadcrumb_failed ++;

			goal = self.favoriteenemy.spectator_respawn.origin;
		}

		debug_print( "Setting current breadcrumb to " + goal );

		self.zombie_path_timer += 100;
		self SetGoalPos( goal );
		self waittill( "bad_path" );

		debug_print( "Zombie couldn't path to breadcrumb at " + goal + " Finding next breadcrumb" );
		for( i = 0; i < crumb_list.size; i++ )
		{
			if( goal == crumb_list[i] )
			{
				bad_crumbs[bad_crumbs.size] = i;
				break;
			}
		}
	}

	/#
	self animscripts\debug::debugPopState();
	#/
}

zombie_pathing_get_breadcrumb( origin, breadcrumbs, bad_crumbs, pick_random )
{
	assert( IsDefined( origin ) );
	assert( IsDefined( breadcrumbs ) );
	assert( IsArray( breadcrumbs ) );

	/#
		if ( pick_random )
		{
			debug_print( "Finding random breadcrumb" );
		}
	#/

	for( i = 0; i < breadcrumbs.size; i++ )
	{
		if ( pick_random )
		{
			crumb_index = RandomInt( breadcrumbs.size );
		}
		else
		{
			crumb_index = i;
		}

		if( crumb_is_bad( crumb_index, bad_crumbs ) )
		{
			continue;
		}

		return breadcrumbs[crumb_index];
	}

	return undefined;
}

crumb_is_bad( crumb, bad_crumbs )
{
	for ( i = 0; i < bad_crumbs.size; i++ )
	{
		if ( bad_crumbs[i] == crumb )
		{
			return true;
		}
	}

	return false;
}

jitter_enemies_bad_breadcrumbs( start_crumb )
{
	trace_distance = 35;
	jitter_distance = 2;

	index = start_crumb;

	while (isdefined(self.favoriteenemy.zombie_breadcrumbs[ index + 1 ]))
	{
		current_crumb = self.favoriteenemy.zombie_breadcrumbs[ index ];
		next_crumb = self.favoriteenemy.zombie_breadcrumbs[ index + 1 ];

		angles = vectortoangles(current_crumb - next_crumb);

		right = anglestoright(angles);
		left = anglestoright(angles + (0,180,0));

		dist_pos = current_crumb + vector_scale( right, trace_distance );

		trace = bulletTrace( current_crumb, dist_pos, true, undefined );
		vector = trace["position"];

		if (distance(vector, current_crumb) < 17 )
		{
			self.favoriteenemy.zombie_breadcrumbs[ index ] = current_crumb + vector_scale( left, jitter_distance );
			continue;
		}


		// try the other side
		dist_pos = current_crumb + vector_scale( left, trace_distance );

		trace = bulletTrace( current_crumb, dist_pos, true, undefined );
		vector = trace["position"];

		if (distance(vector, current_crumb) < 17 )
		{
			self.favoriteenemy.zombie_breadcrumbs[ index ] = current_crumb + vector_scale( right, jitter_distance );
			continue;
		}

		index++;
	}

}

zombie_follow_enemy()
{
	self endon( "death" );
	self endon( "zombie_acquire_enemy" );
	self endon( "bad_path" );

	level endon( "intermission" );

	while( 1 )
	{
		if( isDefined( self.enemyoverride ) && isDefined( self.enemyoverride[1] ) )
		{
			if( distanceSquared( self.origin, self.enemyoverride[0] ) > 1*1 )
			{
				self OrientMode( "face motion" );
			}
			else
			{
				self OrientMode( "face point", self.enemyoverride[1].origin );
			}
			self.ignoreall = true;
			self SetGoalPos( self.enemyoverride[0] );
		}
		else if( IsDefined( self.favoriteenemy ) )
		{
			self.ignoreall = false;
			self OrientMode( "face default" );
			self SetGoalPos( self.favoriteenemy.origin );

			distSq = distanceSquared( self.origin, self.favoriteenemy.origin );

			extra_wait_time = 0;
			if( distSq > 3200 * 3200 )
			{
				extra_wait_time = 2.0 + randomFloat( 1.0 );
			}
			else if( distSq > 2200 * 2200 )
			{
				extra_wait_time = 1.0 + randomFloat( 0.5 );
			}
			else if( distSq > 1200 * 1200 )
			{
				extra_wait_time = 0.5 + randomFloat( 0.5 );
			}
			if( extra_wait_time > 0 )
			{
				wait extra_wait_time;
			}
		}

		// LDS - changed this from a level specific catch function to a general one that can be overloaded based
		//       on the conditions in a level that can render a player inaccessible to zombies.
		if( isDefined( level.inaccesible_player_func ) )
		{
			self [[ level.inaccessible_player_func ]]();
		}

		wait( 0.1 );
	}
}

// When a Zombie spawns, set his eyes to glowing.
zombie_eye_glow()
{
	if(!IsDefined(self))
	{
		return;
	}
	if ( !isdefined( self.no_eye_glow ) || !self.no_eye_glow )
	{
		self haseyes(1);
	}
}

// Called when either the Zombie dies or if his head gets blown off
zombie_eye_glow_stop()
{
	if(!IsDefined(self))
	{
		return;
	}
	if ( !isdefined( self.no_eye_glow ) || !self.no_eye_glow )
	{
		self haseyes(0);
	}
}


//
// DEBUG
//

zombie_history( msg )
{
/#
	if( !IsDefined( self.zombie_history ) )
	{
		self.zombie_history = [];
	}

	self.zombie_history[self.zombie_history.size] = msg;
#/
}

/*
	Zombie Rise Stuff
*/
// zombie_rise()
// {
// 	self endon("death");
// 	self endon("no_rise");
//
// 	while(!IsDefined(self.do_rise))
// 	{
// 		wait_network_frame();
// 	}
//
// 	self do_zombie_rise();
// }


/*
zombie_rise:
Zombies rise from the ground
*/
do_zombie_rise()
{
	self endon("death");

	self.zombie_rise_version = (RandomInt(99999) % 2) + 1;	// equally choose between version 1 and verson 2 of the animations
	if (self.zombie_move_speed != "walk")
	{
		// only do version 1 anims for "run" and "sprint"
		self.zombie_rise_version = 1;
	}

	self.in_the_ground = true;

	//self.zombie_rise_version = 1; // TESTING: override version

	if ( IsDefined( self.zone_name ) )
	{
		spots = level.zones[ self.zone_name ].rise_locations;
	}
	else if ( IsDefined( self.rise_target_name ) )
	{
		spots = GetStructArray(self.rise_target_name, "targetname");
	}
	// JMA - this is used in swamp to only spawn risers in active player zones
	else if( IsDefined( level.zombie_rise_spawners ) )
	{
		if ( IsArray( level.zombie_rise_spawners ) )
		{
			spots = level.zombie_rise_spawners[ self.script_index ];
		}
		else
		{
			spots = level.zombie_rise_spawners;
		}
	}
	else
	{
		spots = GetStructArray("zombie_rise", "targetname");
	}

	spot = undefined;

	if( spots.size < 1 )
	{
		return;
	}
	else
	{
		spot = random(spots);
	}

	/#
	if (GetDvarInt( #"zombie_rise_test"))
	{
		spot = SpawnStruct();			// I know this never gets deleted, but it's just for testing
		spot.origin = (472, 240, 56);	// TEST LOCATION
		spot.angles = (0, 0, 0);
	}
	#/

	if( !isDefined( spot.angles ) )
	{
		spot.angles = (0, 0, 0);
	}
	anim_org = spot.origin;
	anim_ang = spot.angles;
	//TODO: bbarnes: do a bullet trace to the ground so the structs don't have to be exactly on the ground.
	if (self.zombie_rise_version == 2)
	{
		anim_org = anim_org + (0, 0, -14);	// version 2 animation starts 14 units below the ground
	}
	else
	{
		anim_org = anim_org + (0, 0, -45);	// start the animation 45 units below the ground
	}

	level thread zombie_rise_death(self, spot);

	// face goal
	target_org = maps\_zombiemode_spawner::get_desired_origin();
	if (IsDefined(target_org))
	{
		anim_ang = VectorToAngles(target_org - self.origin);
		self.anchor.angles = (0, anim_ang[1], 0);
	}

	self Hide();
	self ForceTeleport(anim_org, anim_ang);
	wait_network_frame();
	self thread hide_pop();

	spot thread zombie_rise_fx(self);

	//self animMode("nogravity");
	//self setFlaggedAnimKnoballRestart("rise", level.scr_anim["zombie"]["rise_walk"], %body, 1, .1, 1);	// no "noclip" mode for these anim functions

	//recheck this in case his speed changed after he spawned
	if (self.zombie_move_speed != "walk")
	{
		// only do version 1 anims for "run" and "sprint"
		self.zombie_rise_version = 1;
	}

	self AnimScripted("rise", anim_org, anim_ang, self get_rise_anim());
	self animscripts\zombie_shared::DoNoteTracks("rise", ::handle_rise_notetracks, undefined, spot);

	self notify("rise_anim_finished");
	spot notify("stop_zombie_rise_fx");
	self.in_the_ground = false;
	self notify("risen", spot.script_noteworthy );
}

hide_pop()
{
	self endon( "death" );
	wait( 0.5 );
	if ( IsDefined( self ) )
	{
		self Show();
	}
}

handle_rise_notetracks(note, spot)
{
	// the anim notetracks control which death anim to play
	// default to "deathin" (still in the ground)

	if (note == "deathout" || note == "deathhigh")
	{
		self.zombie_rise_death_out = true;
		self notify("zombie_rise_death_out");

		wait 2;
		spot notify("stop_zombie_rise_fx");
	}
}

/*
zombie_rise_death:
Track when the zombie should die, set the death anim, and stop the animscripted so he can die
*/
zombie_rise_death(zombie, spot)
{
	//self.nodeathragdoll = true;
	zombie.zombie_rise_death_out = false;

	zombie endon("rise_anim_finished");

	while (zombie.health > 1)	// health will only go down to 1 when playing animation with AnimScripted()
	{
		zombie waittill("damage", amount);
	}

	if(IsDefined(spot.anchor))
	{
		spot.anchor Delete();
	}

	spot notify("stop_zombie_rise_fx");

	zombie.deathanim = zombie get_rise_death_anim();
	zombie StopAnimScripted();	// stop the anim so the zombie can die.  death anim is handled by the anim scripts.
}

/*
zombie_rise_fx:	 self is the script struct at the rise location
Play the fx as the zombie crawls out of the ground and thread another function to handle the dust falling
off when the zombie is out of the ground.
*/
zombie_rise_fx(zombie)
{

	if(!is_true(level.riser_fx_on_client))
	{
		self thread zombie_rise_dust_fx(zombie);
		self thread zombie_rise_burst_fx(zombie);
	}
	else
	{
		self thread zombie_rise_burst_fx(zombie);
	}
	zombie endon("death");
	self endon("stop_zombie_rise_fx");
	wait 1;
	if (zombie.zombie_move_speed != "sprint")
	{
		// wait longer before starting billowing fx if it's not a really fast animation
		wait 1;
	}
}

zombie_rise_burst_fx(zombie)
{
	self endon("stop_zombie_rise_fx");
	self endon("rise_anim_finished");

	if(IsDefined(self.script_string) && self.script_string == "in_water" && (!is_true(level._no_water_risers)) )
	{
		if(is_true(level.riser_fx_on_client) )
		{
			zombie setclientflag(level._ZOMBIE_ACTOR_ZOMBIE_RISER_FX_WATER);
  	}
  	else
  	{
    	playsoundatposition ("zmb_zombie_spawn_water", self.origin);
			playfx(level._effect["rise_burst_water"],self.origin + ( 0,0,randomintrange(5,10) ) );
			wait(.25);
			playfx(level._effect["rise_billow_water"],self.origin + ( randomintrange(-10,10),randomintrange(-10,10),randomintrange(5,10) ) );
		}
	}
	else if(IsDefined(self.script_string) && self.script_string == "in_snow")
	{

		if(is_true(level.riser_fx_on_client))
		{
			// this needs to have "level.riser_type = "snow" set in the level script to work properly in snow levels!
			zombie setclientflag(level._ZOMBIE_ACTOR_ZOMBIE_RISER_FX);
  	}
  	else
  	{

    	playsoundatposition ("zmb_zombie_spawn_snow", self.origin);
			playfx(level._effect["rise_burst_snow"],self.origin + ( 0,0,randomintrange(5,10) ) );
			wait(.25);
			playfx(level._effect["rise_billow_snow"],self.origin + ( randomintrange(-10,10),randomintrange(-10,10),randomintrange(5,10) ) );
		}
	}
	else
	{
		if(isDefined(zombie.zone_name ) && isDefined(level.zones[zombie.zone_name]) )
		{
			low_g_zones = getentarray(zombie.zone_name,"targetname");

			if(isDefined(low_g_zones[0].script_string) && low_g_zones[0].script_string == "lowgravity")
			{
				zombie setclientflag(level._ZOMBIE_ACTOR_ZOMBIE_RISER_LOWG_FX);
			}
			else
			{
				if(is_true(level.riser_fx_on_client))
				{
					zombie setclientflag(level._ZOMBIE_ACTOR_ZOMBIE_RISER_FX);
				}
				else
				{
					playsoundatposition ("zmb_zombie_spawn", self.origin);
					playfx(level._effect["rise_burst"],self.origin + ( 0,0,randomintrange(5,10) ) );
					wait(.25);
					playfx(level._effect["rise_billow"],self.origin + ( randomintrange(-10,10),randomintrange(-10,10),randomintrange(5,10) ) );
				}
			}
		}
		else
		{
			if(is_true(level.riser_fx_on_client))
			{
				zombie setclientflag(level._ZOMBIE_ACTOR_ZOMBIE_RISER_FX);
			}
			else
			{
				playsoundatposition ("zmb_zombie_spawn", self.origin);
				playfx(level._effect["rise_burst"],self.origin + ( 0,0,randomintrange(5,10) ) );
				wait(.25);
				playfx(level._effect["rise_billow"],self.origin + ( randomintrange(-10,10),randomintrange(-10,10),randomintrange(5,10) ) );
			}
		}
	}
}

zombie_rise_dust_fx(zombie)
{
	dust_tag = "J_SpineUpper";

	self endon("stop_zombie_rise_dust_fx");
	self thread stop_zombie_rise_dust_fx(zombie);

	dust_time = 7.5; // play dust fx for a max time
	dust_interval = .1; //randomfloatrange(.1,.25); // wait this time in between playing the effect

	//TODO - add rising dust stuff ere
	if(IsDefined(self.script_string) && self.script_string == "in_water")
	{

		for (t = 0; t < dust_time; t += dust_interval)
		{
			PlayfxOnTag(level._effect["rise_dust_water"], zombie, dust_tag);
			wait dust_interval;
		}

	}
	else if(IsDefined(self.script_string) && self.script_string == "in_snow")
	{

		for (t = 0; t < dust_time; t += dust_interval)
		{
			PlayfxOnTag(level._effect["rise_dust_snow"], zombie, dust_tag);
			wait dust_interval;
		}

	}
	else
	{
		for (t = 0; t < dust_time; t += dust_interval)
		{
		PlayfxOnTag(level._effect["rise_dust"], zombie, dust_tag);
		wait dust_interval;
		}
	}
}

stop_zombie_rise_dust_fx(zombie)
{
	zombie waittill("death");
	self notify("stop_zombie_rise_dust_fx");
}

/*
get_rise_anim:
Return a random rise animation based on a possible set of animations
*/
get_rise_anim()
{
	///* TESTING: put this block back in
	speed = self.zombie_move_speed;
	return random(level._zombie_rise_anims[self.animname][self.zombie_rise_version][speed]);
	//*/

	//return %ai_zombie_traverse_ground_v1_crawlfast;
	//return %ai_zombie_traverse_ground_v2_walk;
	//return %ai_zombie_traverse_ground_v2_walk_altB;
}

/*
get_rise_death_anim:
Return a random death animation based on a possible set of animations
*/
get_rise_death_anim()
{
	possible_anims = [];

	if (self.zombie_rise_death_out)
	{
		possible_anims = level._zombie_rise_death_anims[self.animname][self.zombie_rise_version]["out"];
	}
	else
	{
		possible_anims = level._zombie_rise_death_anims[self.animname][self.zombie_rise_version]["in"];
	}

	return random(possible_anims);
}



// gib limbs if enough firepower occurs
make_crawler()
{
	//	self endon( "death" );
	if( !IsDefined( self ) )
	{
		return;
	}

	self.has_legs = false;
	self.needs_run_update = true;
	self AllowedStances( "crouch" );

	damage_type[0] = "right_foot";
	damage_type[1] = "left_foot";

	refs = [];
	switch( damage_type[ RandomInt(damage_type.size) ] )
	{
	case "right_leg_upper":
	case "right_leg_lower":
	case "right_foot":
		// Addition "right_leg" refs so that the no_legs happens less and is more rare
		refs[refs.size] = "right_leg";
		refs[refs.size] = "right_leg";
		refs[refs.size] = "right_leg";
		refs[refs.size] = "no_legs";
		break;

	case "left_leg_upper":
	case "left_leg_lower":
	case "left_foot":
		// Addition "left_leg" refs so that the no_legs happens less and is more rare
		refs[refs.size] = "left_leg";
		refs[refs.size] = "left_leg";
		refs[refs.size] = "left_leg";
		refs[refs.size] = "no_legs";
		break;
	}

	if( refs.size )
	{
		self.a.gib_ref = animscripts\zombie_death::get_random( refs );

		// Don't stand if a leg is gone
		if( ( self.a.gib_ref == "no_legs" || self.a.gib_ref == "right_leg" || self.a.gib_ref == "left_leg" ) && self.health > 0 )
		{
			self.has_legs = false;
			self AllowedStances( "crouch" );

			which_anim = RandomInt( 5 );
			if(self.a.gib_ref == "no_legs")
			{

				if(randomint(100) < 50)
				{
					self.deathanim = %ai_zombie_crawl_death_v1;
					self set_run_anim( "death3" );
					self.run_combatanim = level.scr_anim[self.animname]["crawl_hand_1"];
					self.crouchRunAnim = level.scr_anim[self.animname]["crawl_hand_1"];
					self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl_hand_1"];
				}
				else
				{
					self.deathanim = %ai_zombie_crawl_death_v1;
					self set_run_anim( "death3" );
					self.run_combatanim = level.scr_anim[self.animname]["crawl_hand_2"];
					self.crouchRunAnim = level.scr_anim[self.animname]["crawl_hand_2"];
					self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl_hand_2"];
				}


			}
			else if( which_anim == 0 )
			{
				self.deathanim = %ai_zombie_crawl_death_v1;
				self set_run_anim( "death3" );
				self.run_combatanim = level.scr_anim[self.animname]["crawl1"];
				self.crouchRunAnim = level.scr_anim[self.animname]["crawl1"];
				self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl1"];
			}
			else if( which_anim == 1 )
			{
				self.deathanim = %ai_zombie_crawl_death_v2;
				self set_run_anim( "death4" );
				self.run_combatanim = level.scr_anim[self.animname]["crawl2"];
				self.crouchRunAnim = level.scr_anim[self.animname]["crawl2"];
				self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl2"];
			}
			else if( which_anim == 2 )
			{
				self.deathanim = %ai_zombie_crawl_death_v1;
				self set_run_anim( "death3" );
				self.run_combatanim = level.scr_anim[self.animname]["crawl3"];
				self.crouchRunAnim = level.scr_anim[self.animname]["crawl3"];
				self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl3"];
			}
			else if( which_anim == 3 )
			{
				self.deathanim = %ai_zombie_crawl_death_v2;
				self set_run_anim( "death4" );
				self.run_combatanim = level.scr_anim[self.animname]["crawl4"];
				self.crouchRunAnim = level.scr_anim[self.animname]["crawl4"];
				self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl4"];
			}
			else if( which_anim == 4 )
			{
				self.deathanim = %ai_zombie_crawl_death_v1;
				self set_run_anim( "death3" );
				self.run_combatanim = level.scr_anim[self.animname]["crawl5"];
				self.crouchRunAnim = level.scr_anim[self.animname]["crawl5"];
				self.crouchrun_combatanim = level.scr_anim[self.animname]["crawl5"];
			}

			if ( isdefined( self.crawl_anim_override ) )
			{
				self [[ self.crawl_anim_override ]]();
			}
		}
	}

//	if( self.health > 0 )
//	{
//		// force gibbing if the zombie is still alive
//		self thread animscripts\zombie_death::do_gib();
//
//		//stat tracking
//		attacker.stats["zombie_gibs"]++;
//	}
}

zombie_disintegrate( player )
{
	self DoDamage( self.health + 666, player.origin, player );

	if ( self.health <= 0 )
	{
		player maps\_zombiemode_score::player_add_points( "death", "", "", self.isdog );

		if( self.has_legs )
		{
			self.deathanim = random( level._zombie_knockdowns[self.animname]["front"]["has_legs"] );
		}
		else
		{
			self.deathanim = random( level._zombie_tesla_crawl_death[self.animname] );
		}

		self swap_to_dissolve_models();
		self setDeathContents( level.CONTENTS_CORPSE ); // this lets bullets and such go straight through a dissolving zombie
		self playweapondeatheffects( player GetCurrentWeapon() );
		self.thundergun_death = true;
		self.thundergun_disintegrated_death = true;
		self.skip_death_notetracks = true;
		self.nodeathragdoll = true;

		wait( GetDvarFloat( #"cg_dissolveTransitionTime" ) + 4 );
		self_delete();
	}
}

zombie_knockdown( player, gib )
{
	if ( gib && !self.gibbed )
	{
		self.a.gib_ref = random( level.thundergun_gib_refs );
		self thread animscripts\zombie_death::do_gib();
	}

	damage = level.zombie_vars["thundergun_knockdown_damage"];
	if(isDefined(level.override_thundergun_damage_func))
	{
		self[[level.override_thundergun_damage_func]](player,gib);
	}
	else
	{
		self.thundergun_handle_pain_notetracks = maps\_zombiemode_weap_thundergun::handle_thundergun_pain_notetracks;
		self DoDamage( damage, player.origin, player );
	}
}

// for now only regular zombies can head gib from the tesla
zombie_tesla_head_gib()
{
	self endon("death");

	if(self.animname == "quad_zombie")
	{
		return;
	}

	if( RandomInt( 100 ) < level.zombie_vars["tesla_head_gib_chance"] )
	{
		wait( RandomFloat( 0.53, 1.0 ) );
		self zombie_head_gib();
	}
	else
	{
		network_safe_play_fx_on_tag( "tesla_death_fx", 2, level._effect["tesla_shock_eyes"], self, "J_Eyeball_LE" );
	}
}

play_ambient_zombie_vocals()
{
    self endon( "death" );

    if( self.animname == "monkey_zombie" )
	{
        return;
	}

    while(1)
    {
        type = "ambient";
        float = 2;

        if( !IsDefined( self.zombie_move_speed ) )
        {
            wait(.5);
            continue;
        }

        switch(self.zombie_move_speed)
	    {
			case "walk":    type="ambient"; float=4;    break;
			case "run":     type="sprint";  float=4;    break;
			case "sprint":  type="sprint";  float=4;    break;
		}

		if( self.animname == "zombie" && !self.has_legs )
		{
		    type = "crawler";
		}
		else if( self.animname == "thief_zombie" )
		{
		    float = 1.2;
		}

		self thread maps\_zombiemode_audio::do_zombies_playvocals( type, self.animname );

		wait(RandomFloatRange(1,float));
    }
}

zombie_complete_emerging_into_playable_area()
{
	self.completed_emerging_into_playable_area = true;
	self notify( "completed_emerging_into_playable_area" );
	self.no_powerups = false;
}

// ------------------------------------------------------------------------------------------------
// DCS 030111: adding tracking for zombies when get too far away.
// ------------------------------------------------------------------------------------------------
zombie_tracking_init()
{
	flag_wait( "all_players_connected" );
	
	while(true)
	{
		zombies = GetAIArray("axis");
		if(!IsDefined(zombies))
		{
			break;
		}
		else
		{
			for (i = 0; i < zombies.size; i++)
			{
				zombies[i] thread delete_zombie_noone_looking(1500);
			}
		}
		wait_network_frame();	
	}	
}	
//-------------------------------------------------------------------------------
//	DCS 030111: 
//	if can't be seen kill and so replacement can spawn closer to player.
//	self = zombie to check.
//-------------------------------------------------------------------------------
delete_zombie_noone_looking(how_close)
{
	self endon( "death" );

	if(!IsDefined(how_close))
	{
		how_close = 1000;
	}

	if(!IsDefined(self.animname) || (IsDefined(self.animname) && self.animname != "zombie"))
	{
		return;
	}

	playable_area = getentarray("player_volume","script_noteworthy");
	in_playable_area = false;
	for (i = 0; i < playable_area.size; i++)
	{
		if (self istouching(playable_area[i]))
		{
			in_playable_area = true;
			break;
		}
	}

	if(!in_playable_area)
	{
		return;
	}

	if(!IsDefined(self.player_in_sight_time))
		self.player_in_sight_time = GetTime();

	can_be_seen = false;
	near = false;
	
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		// pass through players in spectator mode.
		if(players[i].sessionstate == "spectator")
		{
			continue;
		}

		//zombie must be in line of sight of a player, in an active zone, or near the player to not bleed out

		//BulletTracePassed() checks if there is any collision between the player and the zombie
		//player_can_see_me() checks if the player is looking at the direction of the zombie
		if(!can_be_seen)
			can_be_seen = BulletTracePassed( players[i] GetEye(), self.origin, false, undefined ) && self player_can_see_me(players[i]);

		if(!near)
			near = level.zones[self get_current_zone()].is_active || Distance(self.origin, players[i].origin) < how_close;		
	}

	//reset player player_in_sight_time if a player can see zombie or player is near zombie
	if(can_be_seen || near)
	{
		self.player_in_sight_time = GetTime();
		return;
	}

	//wait_network_frame();
	time = GetTime() - self.player_in_sight_time;
	if(time >= 5000)
	{
		if(IsDefined(self.electrified) && self.electrified == true)
		{
			return;
		}		
		// zombie took damage, don't touch.
		if(self.health != level.zombie_health)
		{
			return;
		}
		//VR11 delayed kill
		if(is_true(self.humangun_delayed_kill_active))
		{
			return;
		}
		//VR11 human zombie
		if(is_true(self.humangun_zombie_1st_hit_response))
		{
			return;
		}
		//Wunderwaffe delayed kill
		if(is_true(self.zombie_tesla_hit))
		{
			return;
		}
		//Zombie is outside the map
		if(!is_true(self.completed_emerging_into_playable_area))
		{
			return;
		}
		// exclude rising zombies that haven't finished rising.
		/*if(is_true(self.in_the_ground))
		{
			return;
		}
		// exclude falling zombies that haven't dropped.
		if(is_true(self.in_the_ceiling))
		{
			return;
		}*/

		//IPrintLnBold("deleting zombie out of view");
		level.zombie_total++;
		self DoDamage(self.health + 1000, self.origin);
		//self maps\_zombiemode_spawner::reset_attack_spot();
		//self notify("zombie_delete");
		//self Delete();	
	}
}
//-------------------------------------------------------------------------------
// Utility for checking if the player can see the zombie (ai).
// Can the player see me?
//-------------------------------------------------------------------------------
player_can_see_me( player )
{
	playerAngles = player getplayerangles();
	playerForwardVec = AnglesToForward( playerAngles );
	playerUnitForwardVec = VectorNormalize( playerForwardVec );

	banzaiPos = self.origin;
	playerPos = player GetOrigin();
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