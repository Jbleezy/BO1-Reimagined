#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;


// Jump Pad
// Trigger points to a struct which is the start point
// Start point targets another struct which is the end point
// If the End Point has a target then this should be used to create the poi for the landing area
// Each jump pad can have multiple landing spots that are chosen randomly by default
// Overrides are as follows:
// On Trigger:
//		Script_flag_wait - This string dictates when the pad will become active. Should probably be "on_power"
//		Script_parameters - This variable should also be added to the level._jump_pad_override array, the function should set where the pad's destination is.
//		Script_string - This variable should also be added to the level._jump_pad_override_array, and the function should return an array.
//		This first spot in the array should be the velocity to send the player and the second spot should be the amount of time the player should be in
//		the air.

init()
{
	if( is_true( level._uses_jump_pads ) )
	{
		level jump_pad_init();
	}
}

// jumppad setup
jump_pad_init()
{
	// set up the override array
	level._jump_pad_override = [];

	jump_pad_triggers = GetEntArray( "trig_jump_pad", "targetname" );

	if( !IsDefined( jump_pad_triggers ) )
	{
		return;
	}

	for( i = 0; i < jump_pad_triggers.size; i++ )
	{
		jump_pad_triggers[i].start = getstruct( jump_pad_triggers[i].target, "targetname" );
		jump_pad_triggers[i].destination = getstructarray( jump_pad_triggers[i].start.target, "targetname" );

		if( IsDefined( jump_pad_triggers[i].script_string ) )
		{
			jump_pad_triggers[i].overrides = StrTok( jump_pad_triggers[i].script_string, "," );
		}

		jump_pad_triggers[i] thread jump_pad_think();
	}

	// anything that needs to be on the player should go here
	level thread jump_pad_player_variables();
}

// variables for the player when it comes to jump pads
jump_pad_player_variables()
{
	flag_wait( "all_players_connected" );

	players = GetPlayers();
	for( j = 0; j < players.size; j++ )
	{
		players[j]._padded = false;
		players[j].lander = false;
	}
}

// jump pad main function
jump_pad_think()
{
	self endon( "destroyed" );

	end_point = undefined;
	start_point = undefined;
	z_velocity = undefined;
	z_dist = undefined;
	fling_this_way = undefined;
	jump_time = undefined;

	world_gravity = GetDvarInt( "bg_gravity" ); // 800;
	gravity_pulls = 13.3 * -1; // this is gravity divided by the amount of frames in a second (800/60).
	top_velocity_sq = 900 * 900;
	forward_scaling = 1.0;

	if( IsDefined( self.script_flag_wait ) )
	{
		if( !IsDefined( level.flag[ self.script_flag_wait ] ) )
		{
			flag_init( self.script_flag_wait );
		}

		flag_wait( self.script_flag_wait );
	}


	while( IsDefined( self ) )
	{
		self waittill( "trigger", who );

		if( IsPlayer( who ) )
		{
			self thread trigger_thread( who, ::jump_pad_start, ::jump_pad_cancel );
		}

	}

}

// figures out where to send the player then launches them if they haven't left the pad
jump_pad_start( ent_player, endon_condition )
{
	self endon( "endon_condition" );

	ent_player endon( "left_jump_pad" );
	ent_player endon("death");
	ent_player endon("disconnect");


	// objects
	end_point = undefined;
	start_point = undefined;
	z_velocity = undefined;
	z_dist = undefined;
	fling_this_way = undefined;
	jump_time = undefined;

	world_gravity = GetDvarInt( "bg_gravity" ); // 800;
	gravity_pulls = 13.3 * -1; // this is gravity divided by the amount of frames in a second (800/60).
	top_velocity_sq = 900 * 900;
	forward_scaling = 1.0;

	start_point = self.start; // using the start struct here because we don't want the player to be sent without having to steer a bit

	// any extra special trigger behavior should go on the trigger in the name KVP, tokenize that string then use a switch to decide at the action
	if( IsDefined( self.name ) )
	{
		self._action_overrides = StrTok( self.name, "," );

		if( IsDefined( self._action_overrides ) )
		{

			for( i = 0; i < self._action_overrides.size; i++ )
			{

				ent_player jump_pad_player_overrides( self._action_overrides[i] );

			}

		}

	}

	if( IsDefined( self.script_wait ) )
	{
		if( self.script_wait < 1 )
		{
			self playsound( "evt_jump_pad_charge_short" );
		}
		else
		{
			self playsound( "evt_jump_pad_charge" );
		}
		wait( self.script_wait );
	}
	else
	{
		self playsound( "evt_jump_pad_charge" );
		wait( 1.0 ); // give the player a moment if they don't want to jump
	}


	// if the trigger has an override set up then use it to find the end point
	if( IsDefined( self.script_parameters ) && IsDefined( level._jump_pad_override[ self.script_parameters ] ) )
	{
		end_point = self [[ level._jump_pad_override[ self.script_parameters ] ]]( ent_player );
	}

	if( !IsDefined( end_point ) )
	{
		// choose randomly between all the end points
		end_point = self.destination[ RandomInt( self.destination.size ) ];
	}

	// special override to change the velocity and jump timing for a pad
	if( IsDefined( self.script_string ) && IsDefined( level._jump_pad_override[ self.script_string ] ) )
	{
			info_array = self [[ level._jump_pad_override[ self.script_string ] ]]( start_point, end_point );

			fling_this_way = info_array[0];
			jump_time = info_array[1];
	}
	else
	{
		end_spot = end_point.origin;

		// randomness
		if( !is_true( self.script_airspeed ) )
		{
			rand_end = ( RandomFloat( -1, 1 ), RandomFloat( -1, 1 ), 0 );

			rand_scale = RandomInt( 100 );

			rand_spot = vector_scale( rand_end, rand_scale );

			end_spot = end_point.origin + rand_spot;
		}

		// distance
		pad_dist = Distance( start_point.origin, end_spot );

		z_dist = end_spot[2] - start_point.origin[2];

		// velocity
		jump_velocity = end_spot - start_point.origin;



		// the end point is much higher than the start point so we need to double the z_velocity and scale up the x & y
		if( z_dist > 40 && z_dist < 135 )
		{
			z_dist *= 2.5;
			forward_scaling = 1.1;

			/#
			if( GetDvarInt( "jump_pad_tweaks" ) ) // TODO: Remove check in to dvars for debugging
			{
				if( GetDvar( "jump_pad_z_dist" ) != "" )
				{
					z_dist *= GetDvarFloat( "jump_pad_z_dist" );
				}

				if( GetDvar( "jump_pad_forward" ) != "" )
				{
					forward_scaling = GetDvarFloat( "jump_pad_forward" );
				}
			}
			#/
		}
		else if( z_dist >= 135 )
		{
			z_dist *= 2.7;
			forward_scaling = 1.3;

			/#
			if( GetDvarInt( "jump_pad_tweaks" ) ) // TODO: Remove check in to dvars for debugging
			{
				if( GetDvar( "jump_pad_z_dist" ) != "" )
				{
					z_dist *= GetDvarFloat( "jump_pad_z_dist" );
				}

				if( GetDvar( "jump_pad_forward" ) != "" )
				{
					forward_scaling = GetDvarFloat( "jump_pad_forward" );
				}
			}
			#/

		}
		else if( z_dist < 0 ) // end_point is lower than the start point
		{
			z_dist *= 2.4;
			forward_scaling = 1.0;

			/#
			if( GetDvarInt( "jump_pad_tweaks" ) ) // TODO: Remove check in to dvars for debugging
			{
				if( GetDvar( "jump_pad_z_dist" ) != "" )
				{
					z_dist *= GetDvarFloat( "jump_pad_z_dist" );
				}

				if( GetDvar( "jump_pad_forward" ) != "" )
				{
					forward_scaling = GetDvarFloat( "jump_pad_forward" );
				}
			}
			#/


		}


			// get the z velocity
			z_velocity = 2 * z_dist * world_gravity;

			// make sure the z velocity isn't a negative
			if( z_velocity < 0 )
			{
				z_velocity *= -1;
			}

			// make sure the distance isn't a negative
			if( z_dist < 0 )
			{
				z_dist *= -1;
			}

			// time
			jump_time = Sqrt( 2 * pad_dist / world_gravity );
			jump_time_2 = Sqrt( 2 * z_dist / world_gravity );
			jump_time = jump_time + jump_time_2;
			if( jump_time < 0 )
			{
				jump_time *= -1;
			}

			// velocity
			x = jump_velocity[0] * forward_scaling / jump_time;
			y = jump_velocity[1] * forward_scaling / jump_time;
			z = z_velocity / jump_time;

			// final vector
			fling_this_way = ( x, y, z );
	}

	// create poi
	if( IsDefined( end_point.target ) )
	{
		poi_spot = getstruct( end_point.target, "targetname" );
	}
	else
	{
		poi_spot = end_point;
	}

	// pass on any checks info needed for the poi creation in to jump_pad_move
	if( !IsDefined( self.script_index ) ) // this checks to see if the attract function should be started on the poi_spot
	{
		ent_player.script_index = undefined;
	}
	else
	{
		ent_player.script_index = self.script_index;
	}

	// some pads should probably send the player even if they are jumping
	if( IsDefined( self.script_start ) && self.script_start == 1 )
	{
		if( !is_true( ent_player._padded ) )
		{
			self playsound( "evt_jump_pad_launch" );
			playfx(level._effect["jump_pad_jump"],self.origin);
			ent_player thread jump_pad_move( fling_this_way, jump_time, poi_spot, self ); // move the player in the proper direction

			if( IsDefined( self.script_label ) )
			{
				level notify( self.script_label );
			}
			return;
		}
	}
	else // player must be on the ground to be tossed
	{
		if( ent_player IsOnGround() && !is_true( ent_player._padded ) )
		{
			self playsound( "evt_jump_pad_launch" );
			playfx(level._effect["jump_pad_jump"],self.origin);
			ent_player thread jump_pad_move( fling_this_way, jump_time, poi_spot, self ); // move the player in the proper direction

			if( IsDefined( self.script_label ) )
			{
				level notify( self.script_label );
			}
			return;
		}
	}

	// failsafe against timing where the player spams jump button as they land and being able to stay on the pad
	wait( 0.5 );
	if ( ent_player IsTouching( self ) )
	{
		self jump_pad_start( ent_player, endon_condition );
	}

}

// player left the jump pad trigger, don't toss them
jump_pad_cancel( ent_player )
{
	ent_player notify( "left_jump_pad" );

	if( IsDefined( ent_player.poi_spot ) && !is_true( ent_player._padded ) )
	{
		// ent_player.poi_spot Delete();
	}

	// any extra special trigger behavior should go on the trigger in the name KVP, tokenize that string then use a switch to decide at the action
	if( IsDefined( self.name ) )
	{
		self._action_overrides = StrTok( self.name, "," );

		if( IsDefined( self._action_overrides ) )
		{

			for( i = 0; i < self._action_overrides.size; i++ )
			{

				ent_player jump_pad_player_overrides( self._action_overrides[i] );

			}

		}

	}

}


jump_pad_move( vec_direction, flt_time, struct_poi, trigger )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "stop_jump_pad_move" );

	self thread stop_jump_pad_move_on_left_jump_pad();

	attract_dist = undefined;
	num_attractors = 30;
	added_poi_value = 0;
	start_turned_on = true;
	// poi_spot = undefined;
	poi_start_func = undefined;

	while( is_true( self.divetoprone ) || is_true( self._padded ) )
	{
		wait( 0.05 );
		// wait_network_frame();
	}

	self notify("stop_checking_left_jump_pad");

	start_time = GetTime();
	jump_time = flt_time * 500;

	self._padded = 1;
	self.lander = 1;

	self SetStance( "stand" );

	wait( 0.1 );

	// low triggers are ok because they get turned off
	if ( isdefined( trigger.script_label ) )
	{
		if ( issubstr( trigger.script_label, "low" ) )
		{
			self.jump_pad_current = undefined;
			self.jump_pad_previous = undefined;
		}
		else if ( !isdefined( self.jump_pad_current ) )
		{
			self.jump_pad_current = trigger;
		}
		else
		{
			self.jump_pad_previous = self.jump_pad_current;
			self.jump_pad_current = trigger;
		}
	}

	if( IsDefined( self.poi_spot ) )
	{
		level jump_pad_ignore_poi_cleanup( self.poi_spot );

		self.poi_spot deactivate_zombie_point_of_interest();

		self.poi_spot Delete();
	}

	if( IsDefined( struct_poi ) )
	{
		self.poi_spot = Spawn( "script_origin", struct_poi.origin );

		if( IsDefined( level._pad_poi_ignore ) )
		{
			level [[level._pad_poi_ignore]]( self.poi_spot );
		}

		self thread jump_pad_enemy_follow_or_ignore( self.poi_spot );

		if( IsDefined( level._jump_pad_poi_start_override ) && !is_true( self.script_index ) )
		{
			poi_start_func = level._jump_pad_poi_start_override;
		}

		if( IsDefined( level._jump_pad_poi_end_override ) )
		{
			poi_end_func = level._jump_pad_poi_end_override;
		}

		self.poi_spot create_zombie_point_of_interest( attract_dist, num_attractors, added_poi_value, start_turned_on, poi_start_func );
		self thread disconnect_failsafe_pad_poi_clean();
	}


	self SetOrigin( self.origin + ( 0, 0, 1 ) );

	if( 20 >= randomintrange( 0, 101 ) )
	{
		self thread maps\_zombiemode_audio::create_and_play_dialog( "general", "jumppad" );
	}

	while( GetTime() - start_time < jump_time )
	{
		self SetVelocity( vec_direction );
		wait( 0.05 );
	}

	while( !self IsOnGround() )
	{
		wait( 0.05 );
	}

	self._padded = 0;
	self.lander = 0;

	jump_pad_triggers = GetEntArray( "trig_jump_pad", "targetname" );

	for( i = 0; i < jump_pad_triggers.size; i++ )
	{
		if( self IsTouching( jump_pad_triggers[i] ) )
		{
			level thread failsafe_pad_poi_clean( jump_pad_triggers[i], self.poi_spot );
			return;
		}
	}

	if( IsDefined( self.poi_spot ) )
	{
		level jump_pad_ignore_poi_cleanup( self.poi_spot );
		self.poi_spot Delete();
	}
}

stop_jump_pad_move_on_left_jump_pad()
{
	self endon("stop_checking_left_jump_pad");

	self waittill("left_jump_pad");
	self notify("stop_jump_pad_move");
}

// make sure to delete the poi in cases where the player disconnects while it's active
disconnect_failsafe_pad_poi_clean()
{
	self notify( "kill_disconnect_failsafe_pad_poi_clean" );
	self endon( "kill_disconnect_failsafe_pad_poi_clean" );
	self.poi_spot endon( "death" );

	self waittill( "disconnect" );

	if ( IsDefined( self.poi_spot ) )
	{
		level jump_pad_ignore_poi_cleanup( self.poi_spot );

		self.poi_spot deactivate_zombie_point_of_interest();

		self.poi_spot Delete();
	}
}

// make sure to delete the poi in cases where the player lands on the pad for just a moment before falling off
failsafe_pad_poi_clean( ent_trig, ent_poi )
{

	if( IsDefined( ent_trig.script_wait ) )
	{
		wait( ent_trig.script_wait );
	}
	else
	{
		wait( 0.5 );
	}

	if( IsDefined( ent_poi ) )
	{
		level jump_pad_ignore_poi_cleanup( ent_poi );

		ent_poi deactivate_zombie_point_of_interest();

		ent_poi Delete();
	}
}

// sets all zombies not chasing the player to ignore the poi that is going to be created
// enemy stays set as the player they were chasing for a few moments in to the jump
jump_pad_enemy_follow_or_ignore( ent_poi )
{
	self endon( "death" );
	self endon( "disconnect" );

	zombies = GetAIArray( "axis" );

	players = GetPlayers();
	valid_players = 0;
	for( p = 0; p < players.size; p++ )
	{
		if ( is_player_valid( players[p] ) )
		{
			valid_players++;
		}
	}

	for( i = 0; i < zombies.size; i++ )
	{
		ignore_poi = false;

		if( !IsDefined( zombies[i] ) )
		{
			continue;
		}

		enemy = zombies[i].favoriteenemy;

		if( IsDefined( enemy ) )
		{
			if ( players.size > 1 && valid_players > 1 )
			{
				if ( enemy != self || ( IsDefined( enemy.jump_pad_previous ) && enemy.jump_pad_previous == enemy.jump_pad_current ) )
				{
					ignore_poi = true;
				}
			}
		}

		if ( is_true( ignore_poi ) )
		{
			zombies[i] thread add_poi_to_ignore_list( ent_poi );
		}
		else
		{
			zombies[i].ignore_distance_tracking = true;
			zombies[i]._pad_follow = 1;
			zombies[i] thread stop_chasing_the_sky( ent_poi );
		}
	}
}

// makes sure the poi is removed from the enemies ignore list
jump_pad_ignore_poi_cleanup( ent_poi )
{
	zombies = GetAIArray( "axis" );

	for( i = 0; i < zombies.size; i++ )
	{
		if( IsDefined( zombies[i] ) )
		{
			if( is_true( zombies[i]._pad_follow ) )
			{
				zombies[i]._pad_follow = 0;
				zombies[i] notify( "stop_chasing_the_sky" );
				zombies[i].ignore_distance_tracking = false;
			}

			if( IsDefined( ent_poi ) )
			{
				zombies[i] thread remove_poi_from_ignore_list( ent_poi );
			}

		}

	}

}

// If a zombie is chasing a guy jumping around and comes close to another player then they should break off and attack
// the closer player
// the favoriteenemy is usually the enemy from the start, but when the player is far from the zombie the zombie drops them as
// their .enemy, so for this check we need to see if the player getting close is not the .favoriteenemy
stop_chasing_the_sky( ent_poi )
{
	self endon( "death" );
	self endon( "stop_chasing_the_sky" );

	while( is_true( self._pad_follow ) )
	{
		if ( IsDefined( self.favoriteenemy ) )
		{
			players = getplayers();
			for ( i = 0; i < players.size; i++ )
			{
				if ( is_player_valid( players[i] ) && players[i] != self.favoriteenemy )
				{
					if ( Distance2DSquared( players[i].origin, self.origin ) < 100 * 100 )
					{
						self add_poi_to_ignore_list( ent_poi );
						return;
					}
				}
			}
		}

		wait( 0.1 );
	}

	//wait( 0.5 ); // allow the zombies time to get close while the next pad warms up

	self._pad_follow = 0;
	self.ignore_distance_tracking = false;
	self notify( "stop_chasing_the_sky" );

}

// Runs any special player behavior wanted while the player is touching the pad trigger
jump_pad_player_overrides( st_behavior, int_clean )
{
	if( !IsDefined( st_behavior ) || !IsString( st_behavior ) )
	{
		return;
	}

	if( !IsDefined( int_clean ) ) //int_clean decides if the behavior is applied or removed, not defining it means you want to set the behavior
	{
		int_clean = 0;
	}

	switch( st_behavior )
	{
		case "no_sprint":

			if( !int_clean )
			{
				//self AllowSprint( int_clean );
			}
			else
			{
				//self AllowSprint( int_clean );
			}
			break;


		default:

			if( IsDefined( level._jump_pad_level_behavior ) )
			{
				self [[ level._jump_pad_level_behavior ]]( st_behavior, int_clean );
			}
			else
			{
				// nothing happens
			}

			break;

	}

}
