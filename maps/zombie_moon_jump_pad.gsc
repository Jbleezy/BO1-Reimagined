#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

init()
{
	level._uses_jump_pads = true;

	// -- special anims for the accelerated run
	level.scr_anim["zombie"]["low_g_super_sprint"] = %ai_zombie_supersprint_lowg;

	level.scr_anim["zombie"]["crawl_super_sprint"] = %ai_zombie_crawl_supersprint;
	level.scr_anim["zombie"]["crawl_low_g_super_sprint"] = %ai_zombie_crawl_supersprint_lowg;

	level.scr_anim["quad_zombie"]["super_sprint"] = %ai_zombie_quad_supersprint;
	level.scr_anim["quad_zombie"]["low_g_super_sprint"] = %ai_zombie_quad_supersprint_lowg;

	level maps\_zombiemode_jump_pad::init();

	level moon_jump_pad_overrides();

	level thread moon_biodome_temptation_init();
	level thread moon_jump_pads_low_gravity();
	level thread moon_jump_pads_malfunctions();
	level thread moon_jump_pad_cushion_sound_init();
}

// array is defined in _zombiemode_jump_pad
moon_jump_pad_overrides()
{
	level._jump_pad_override[ "biodome_logic" ] = ::moon_jump_pad_progression_end; // biodome trigger parameters decide which direction to go and wildcard possiblity
	level._jump_pad_override[ "low_grav" ] = ::moon_low_gravity_velocity; // biodome triggers should have this set as their script_string to override the velocity and jump time
	level._jump_pad_override[ "moon_vertical_jump" ] = ::moon_vertical_jump; // receiving bay trigger uses this script string to properly launch the player

	level._jump_pad_poi_start_override = ::moon_zombie_run_change;

	// level._jump_pad_activate_flag = "power_on"; // jump pads should not work until the power is activated

	// level._jump_pad_velocity_override = ::moon_low_gravity_velocity;

	flag_init( "pad_allow_anim_change" );
	level._jump_pad_anim_change = [];
	flag_set( "pad_allow_anim_change" );
	level thread jump_pad_throttle_anim_changes();

}

moon_jump_pad_progression_end( ent_player )
{

	if ( IsDefined( self.start.script_string ) ) // give the player the string becuase it informs of direction
	{
		ent_player.script_string = self.start.script_string;
	}

	if ( IsDefined( ent_player.script_string ) )
	{
		end_spot_array = self.destination;

		end_spot_array = array_randomize( end_spot_array );

		// check to see if the end point has something defined, this will give me the struct array to use for the power up
		// pull

		for ( i = 0; i < end_spot_array.size; i++ )
		{

			if ( IsDefined( end_spot_array[i].script_string ) && end_spot_array[i].script_string == ent_player.script_string  )
			{

				end_point = end_spot_array[i];

				if ( RandomInt( 100 ) < 5 && !level._pad_powerup && IsDefined( end_point.script_parameters ) ) //
				{

					temptation_array = level._biodome_tempt_arrays[ end_point.script_parameters ];
					// Assert( IsDefined( temptation_array ) );

					if(  IsDefined( temptation_array ) )
					{

						// level thread moon_biodome_powerup_temptation( temptation_array );

					}

				}

				return end_point; // return the struct going in the proper direction

			}

		}

	}

}

// start point is the player
// end point is the struct at the destination
moon_low_gravity_velocity( ent_start_point, struct_end_point )
{
	// check to see if the low gravity should be done

	end_point = struct_end_point;
	start_point = ent_start_point;
	z_velocity = undefined;
	z_dist = undefined;
	fling_this_way = undefined;

	world_gravity = GetDvarInt( "bg_gravity" ); // 800;
	//gravity_pulls = 13.3 * -1; // this is gravity divided by the amount of frames in a second (800/60).
	//top_velocity_sq = 900 * 900;
	forward_scaling = 1.0;

	end_spot = struct_end_point.origin;

	// randomness
	if( !is_true( self.script_airspeed ) )
	{
		rand_end = ( RandomFloat( 0.1, 1.2 ), RandomFloat( 0.1, 1.2 ), 0 );

		rand_scale = RandomInt( 100 );

		rand_spot = vector_scale( rand_end, rand_scale );

		end_spot = struct_end_point.origin + rand_spot;
	}


	// distance
	pad_dist = Distance( start_point.origin, end_spot );

	z_dist = end_spot[2] - start_point.origin[2];

	// velocity
	jump_velocity = end_spot - start_point.origin;

	// the end point is much higher than the start point so we need to double the z_velocity and scale up the x & y
	if( z_dist > 40 && z_dist < 135 )
	{
		z_dist *= 0.05;

		forward_scaling = 0.8;

		/#
		if( GetDvarInt( "jump_pad_tweaks" ) ) // TODO: Remove check in to dvars for debugging
		{
			z_dist *= GetDvarFloat( "jump_pad_z_dist" );
			forward_scaling = GetDvarFloat( "jump_pad_forward" );
		}
		#/

	}
	else if( z_dist >= 135 )
	{
		z_dist *= 0.2;
		forward_scaling = 0.7;

		/#
		if( GetDvarInt( "jump_pad_tweaks" ) ) // TODO: Remove check in to dvars for debugging
		{
			z_dist *= GetDvarFloat( "jump_pad_z_dist" );
			forward_scaling = GetDvarFloat( "jump_pad_forward" );
		}
		#/

	}
	else if( z_dist < 0 ) // end_point is lower than the start point
	{
		z_dist *= 0.1;
		forward_scaling = 0.95;

		/#
		if( GetDvarInt( "jump_pad_tweaks" ) ) // TODO: Remove check in to dvars for debugging
		{
			z_dist *= GetDvarFloat( "jump_pad_z_dist" );
			forward_scaling = GetDvarFloat( "jump_pad_forward" );
		}
		#/

	}


	// get the z velocity
	z_velocity = 0.75 * z_dist * world_gravity;	 // 1.2

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
	jump_time_2 = Sqrt( z_dist / world_gravity ); // 2 *
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

	jump_info = [];
	jump_info[0] = fling_this_way;
	jump_info[1] = jump_time;

	return jump_info;

}

// ------------------------------------------------------------------------

// This will send the player more vertical that forward, used first for the recieveing bay area
moon_vertical_jump( ent_start_point, struct_end_point )
{
	end_point = struct_end_point;
	start_point = ent_start_point;
	z_velocity = undefined;
	z_dist = undefined;
	fling_this_way = undefined;

	world_gravity = GetDvarInt( "bg_gravity" ); // 800;
	//gravity_pulls = 13.3 * -1; // this is gravity divided by the amount of frames in a second (800/60).
	//top_velocity_sq = 900 * 900;
	//forward_scaling = 0.9;
	//end_random_scale = ( RandomFloatRange( -1, 1 ), RandomFloatRange( -1, 1 ), 0 );

	//vel_random = ( RandomIntRange( 2, 6 ), RandomIntRange( 2, 6 ), 0 );

	// distance
	pad_dist = Distance( start_point.origin, end_point.origin );

	// velocity from all dimensions
	//jump_velocity = end_point.origin - start_point.origin;

	// get the z distance only
	z_dist = end_point.origin[2] - start_point.origin[2];

	// scale the z so the player goes up farther
	z_dist *= 1.5;

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
	//x = jump_velocity[0] * forward_scaling / jump_time;
	//y = jump_velocity[1] * forward_scaling / jump_time;
	z = z_velocity / jump_time;

	//fling_vel = ( x, y, z ) + vel_random;

	// final vector
	fling_this_way = ( 0, 0, z );

	jump_info = [];
	jump_info[0] = fling_this_way;
	jump_info[1] = jump_time;

	return jump_info;
}

// ------------------------------------------------------------------------
// Biodome temptation
// set up the structs in to array sets based on which pads they are near
moon_biodome_temptation_init()
{
	// objects
	level._biodome_tempt_arrays = [];

	level._biodome_tempt_arrays[ "struct_tempt_left_medium_start" ] = getstructarray( "struct_tempt_left_medium_start", "targetname" );
	level._biodome_tempt_arrays[ "struct_tempt_right_medium_start" ] = getstructarray( "struct_tempt_right_medium_start", "targetname" );

	level._biodome_tempt_arrays[ "struct_tempt_left_tall" ] = getstructarray( "struct_tempt_left_tall", "targetname" );
	level._biodome_tempt_arrays[ "struct_tempt_middle_tall" ] = getstructarray( "struct_tempt_middle_tall", "targetname" );
	level._biodome_tempt_arrays[ "struct_tempt_right_tall" ] = getstructarray( "struct_tempt_right_tall", "targetname" );

	level._biodome_tempt_arrays[ "struct_tempt_left_medium_end" ] = getstructarray( "struct_tempt_left_medium_end", "targetname" );
	level._biodome_tempt_arrays[ "struct_tempt_right_medium_end" ] = getstructarray( "struct_tempt_right_medium_end", "targetname" );

	level._pad_powerup = false;

	flag_wait( "all_players_connected" );

	level thread moon_biodome_random_pad_temptation();

}

// Randomly will spawn a power up around one of the jump pads if the zone is active
moon_biodome_random_pad_temptation()
{
	level endon( "end_game" );

	// temptation structs
	structs = getstructarray( "struct_biodome_temptation", "script_noteworthy" );

	while( true )
	{
		// randomly choose one of the structs
		rand = RandomInt( structs.size );

		//Assert( IsDefined( level._biodome_tempt_arrays[ structs[ rand ].targetname ] ) );

		if( IsDefined( level._biodome_tempt_arrays[ structs[ rand ].targetname ] ) )
		{
			// grab the array to use
			tempt_array = level._biodome_tempt_arrays[ structs[ rand ].targetname ];

			tempt_array = array_randomize( tempt_array );

			if( isDefined( level.zones[ "forest_zone" ] ) && is_true( level.zones[ "forest_zone" ].is_enabled ) && !level._pad_powerup )
			{
				level thread moon_biodome_powerup_temptation( tempt_array );
			}
		}

		wait( RandomIntRange( 60, 180 ) );

	}
}

// spawns a power up and moves it around a pad
moon_biodome_powerup_temptation( struct_array )
{
	powerup = Spawn( "script_model", struct_array[0].origin );
	level thread moon_biodome_temptation_active( powerup );
	// kill this function if the powerup leaves
	powerup endon( "powerup_grabbed" );
	powerup endon( "powerup_timedout" );

	temptation_array = array( "double_points", "nuke", "insta_kill", "fire_sale");
	temptation_array = array_randomize(temptation_array);
	temptation_array[temptation_array.size] = "full_ammo";
	temptation_array[temptation_array.size] = "free_perk";
	temptation_index = 0;
	spot_index = 0;
	first_time = true;
	struct = undefined;
	rotation = 0;

	//temptation_array = array_randomize( temptation_array );

	while( IsDefined( powerup ) )
	{
		//iprintln(temptation_array[ temptation_index ]);
		powerup maps\_zombiemode_powerups::powerup_setup( temptation_array[ temptation_index ] );

		// only start these threads on the first time through
		// timeout and grab will delete the powerup which
		if( first_time )
		{
			powerup thread maps\_zombiemode_powerups::powerup_timeout();
			powerup thread maps\_zombiemode_powerups::powerup_wobble();
			powerup thread maps\_zombiemode_powerups::powerup_grab();
			first_time = false;
		}

		powerup.origin = struct_array[ spot_index ].origin; // move the powerup

		if( rotation == 0 )
		{
			wait( 10 );
			rotation++;
		}
		else if( rotation == 1 )
		{
			wait( 7.5 );
			rotation++;
		}
		else if( rotation == 2 )
		{
			wait( 5 );
			rotation++;
		}
		else if( rotation == 3 )
		{
			wait( 2.5 );
			rotation++;
		}
		else
		{
			wait( 2.5 );
			rotation++;
		}

		// make sure the loop stays in the right amount
		temptation_index++;
		if( temptation_index >= temptation_array.size )
		{
			temptation_index = 0;
		}

		spot_index++;
		if( spot_index >= struct_array.size )
		{
			spot_index = 0;
		}
	}

}

// notifies the temptation system that there is already a powerup out
moon_biodome_temptation_active( ent_powerup )
{
	level._pad_powerup = true;

	while( IsDefined( ent_powerup ) )
	{
		wait( 0.1 );
	}

	level._pad_powerup = false;
}

// ------------------------------------------------------------------------

// function waits for the biodome to be compromised then sets all dome pads to the low gravity setting
moon_jump_pads_low_gravity()
{
	level endon( "end_game" );

	biodome_pads = GetEntArray( "biodome_pads", "script_noteworthy" );
	biodome_compromised = false;

	while( !biodome_compromised )
	{
		level waittill( "digger_arm_smash", digger, zone );

		if( digger == "biodome" && IsArray( zone ) && zone[0] == "forest_zone" )
		{
			biodome_compromised = true;
		}

	}

	for( i = 0; i < biodome_pads.size; i++ )
	{
		biodome_pads[i].script_string = "low_grav";
	}

}

// ------------------------------------------------------------------------

// randomly malfunctions some of the lower biodome jump pads
moon_jump_pads_malfunctions()
{
	level endon( "end_game" );

	// level._CLIENTFLAG_SCRIPTMOVER_DOME_MALFUNCTION_PAD = 3

	jump_pad_triggers = GetEntArray( "trig_jump_pad", "targetname" );

	flag_wait( "all_players_connected" );

	wait( 2.0 );

	// grab the pads that will malfunction
	level._dome_malfunction_pads = [];

	for( i = 0; i < jump_pad_triggers.size; i++ )
	{
		pad = jump_pad_triggers[i];

		if( IsDefined( pad.script_label ) )
		{

			if( pad.script_label == "pad_labs_low" )
			{
				level._dome_malfunction_pads = add_to_array( level._dome_malfunction_pads, pad, false );
			}
			else if( pad.script_label == "pad_magic_box_low" )
			{
				level._dome_malfunction_pads = add_to_array( level._dome_malfunction_pads, pad, false );
			}
			else if( pad.script_label == "pad_teleporter_low" )
			{
				level._dome_malfunction_pads = add_to_array( level._dome_malfunction_pads, pad, false );
			}

		}

	}

	/#
	// make sure the array has pads in it
	if( level._dome_malfunction_pads.size == 0 )
	{
		PrintLn( "$$$$ malfunction pads missing $$$$" );
		return;
	}
	#/

	// wait for power
	flag_wait( "power_on" );

	for( i = 0; i < level._dome_malfunction_pads.size; i++ )
	{
		level._dome_malfunction_pads[i] thread moon_pad_malfunction_think();
	}

}

moon_pad_malfunction_think()
{
	level endon( "end_game" );

	// spawn the client point
	pad_hook = Spawn( "script_model", self.origin );
	pad_hook SetModel( "tag_origin" );

	while( IsDefined( self ) )
	{
		wait( RandomIntRange( 30, 60 ) );

		/#
		PrintLn( "$$$$ Shut down pad $$$$" );
		#/

		// set the malfunction flag on the first one
		pad_hook playsound( "zmb_turret_down" );
		pad_hook SetClientFlag( level._CLIENTFLAG_SCRIPTMOVER_DOME_MALFUNCTION_PAD );
		wait_network_frame();

		// move the trigger away
		self trigger_off();

		wait( RandomIntRange( 10, 30 ) );

		pad_hook playsound( "zmb_turret_startup" );
		pad_hook ClearClientFlag( level._CLIENTFLAG_SCRIPTMOVER_DOME_MALFUNCTION_PAD );
		wait_network_frame();

		self trigger_on();

		/#
		PrintLn( "$$$$ Start up pad $$$$" );
		#/

//		// delete script model
//		pad_hook Delete();

	}

}

// make the zombies chasing the player on the jump pads run faster
moon_zombie_run_change( ent_poi )
{
	self endon( "death" );

	if( is_true( self._pad_chase ) ) // find_flesh will keep calling this function when looking for best_poi
	{
		return;
	}

	if( IsDefined( self.animname ) && self.animname == "astro_zombie" )
	{
		return; // no messing with the astro animations
	}

	if( IsDefined( self.script_string ) && self.script_string == "riser" )
	{
		while( is_true( self.in_the_ground ) )
		{
			wait( 0.05 );
		}
	}

	if( !IsDefined( self.ent_flag ) || !IsDefined( self.ent_flag["pad_anim_change"] ) )
	{
		self ent_flag_init( "pad_anim_change" );
	}

	/#
	Assert( IsDefined( self.ent_flag["pad_anim_change" ] ) );
	#/

	// figure out which anim they are currently playing
	self._pre_pad_run = self jump_pad_store_movement_anim();
	self._pad_chase = 1;

	low_grav = 0; // use the lowgrav anim or not
	chase_anim = undefined;

	flag_wait( "pad_allow_anim_change" ); // permission for adding to the array
	level._jump_pad_anim_change = add_to_array( level._jump_pad_anim_change, self, false ); // no dupes allowed

	self ent_flag_wait( "pad_anim_change" );

	curr_zone = self get_current_zone();
	if( !IsDefined( curr_zone ) && IsDefined( self.zone_name ) )
	{
		curr_zone = self.zone_name;
	}

	if( IsDefined( curr_zone )&& IsDefined( level.zones[curr_zone].volumes[0].script_string )
			&& level.zones[curr_zone].volumes[0].script_string == "lowgravity" )
	{
		// check for the script_string
		// check to see if it is lowgravity
		low_grav = 1;
	}

	// find the anim based self.animname
	if( self.animname == "zombie" )
	{

		if( self.has_legs ) // standing
		{

			if( low_grav ) // use the lowgrav anim
			{
				chase_anim = "low_g_super_sprint";
			}
			else
			{
				chase_anim = "sprint6";
			}

		}
		else // legless
		{

			if( low_grav ) // use the lowgrav anim
			{
				chase_anim = "crawl_low_g_super_sprint";
			}
			else
			{
				chase_anim = "crawl_super_sprint";
			}

		}
	}
	else if( self.animname == "quad_zombie" ) // quads
	{
		// check to see if area is low grav
		if( low_grav ) // use the lowgrav anim
		{
			chase_anim = "low_g_super_sprint";
		}
		else
		{
			chase_anim = "super_sprint";
		}

	}
	else if( self.animname == "astro_zombie" ) // greer
	{
		// do we want to do anything special with this one?
	}

	if(IsDefined(chase_anim))
		self moon_jump_pad_run_switch( chase_anim );

	self thread moon_stop_running_to_catch();
}


// -- store and return the current zombie movement anim
jump_pad_store_movement_anim()
{
	self endon( "death" );

	/#
	Assert( IsDefined( self.run_combatanim ) );
	Assert( IsDefined( self.zombie_move_speed ) );
	#/

	current_anim = self.run_combatanim;
	anim_keys = GetArrayKeys( level.scr_anim[self.animname] );

	for( j = 0; j < anim_keys.size; j++ )
	{
		if( level.scr_anim[ self.animname ][ anim_keys[j] ] == current_anim )
		{
			return anim_keys[j];
		}
	}

	/#
	AssertMsg( "couldn't find zombie run anim in the array keys" );
	#/

}

// resets the ai's animation back to normal
moon_stop_running_to_catch()
{
	self endon( "death" );

	// if some other function stopped the poi chase then early out
	if( !is_true( self._pad_chase ) )
	{
		return;
	}

	if( IsDefined( self.animname ) && self.animname == "astro_zombie" )
	{
		return; // don't screw with the animations on the astro
	}

	while( is_true( self._pad_follow ) )
	{
		wait( 0.05 );
	}

	// self waittill( "stop_chasing_the_sky" );

	/#
	Assert( IsDefined( self.zombie_move_speed ) );
	Assert( IsDefined( self.ent_flag["pad_anim_change"] ) );
	#/

	flag_wait( "pad_allow_anim_change" ); // permission for adding to the array
	level._jump_pad_anim_change = add_to_array( level._jump_pad_anim_change, self, false ); // no dupes allowed

	// wait for permission to change anim
	self ent_flag_wait( "pad_anim_change" );

	// check if low gravity or not
	low_grav = 0;
	curr_zone = self get_current_zone();

	if( IsDefined( curr_zone )&& IsDefined( level.zones[curr_zone].volumes[0].script_string )
			&& level.zones[curr_zone].volumes[0].script_string == "lowgravity" )
	{
		// check for the script_string
		// check to see if it is lowgravity
		low_grav = 1;
	}

	anim_set = undefined;

	switch(self.zombie_move_speed)
	{

		// -- WALK
		case "walk":
			if( low_grav )
			{
				if( self.has_legs )
				{
					var = RandomIntRange( 1, level.num_anim[self.animname]["walk"] + 1 );

					anim_set = "walk_moon" + var;

					break;
				}
				else
				{
					var = RandomIntRange( 1, level.num_anim[self.animname]["crawl"] + 1 );

					anim_set = "crawl_moon" + var;

					break;
				}
			}
			else
			{
				if( self.has_legs )
				{
					var = RandomIntRange( 1, 9 );

					anim_set = "walk" + var;

					break;
				}
				else
				{
					var = RandomIntRange( 1, 7 );

					anim_set = "crawl" + var;

					break;
				}

			}

		// -- RUN
		case "run":
			if( low_grav )
			{
				if( self.has_legs )
				{
					var = RandomIntRange( 1, level.num_anim[self.animname]["run"] + 1 ) ;

					anim_set = "run_moon" + var;

					break;
				}
				else
				{
					var = RandomIntRange( 1, level.num_anim[self.animname]["crawl"] + 1 );

					anim_set = "crawl_moon" + var;

					break;
				}
			}
			else
			{
				if( self.has_legs )
				{
					var = RandomIntRange( 1, 7 );

					anim_set = "run" + var;

					break;
				}
				else
				{
					var = RandomIntRange( 1, 3 );

					anim_set = "crawl_hand_" + var;

					break;
				}

			}

		// -- SPRINT
		case "sprint":
			if( low_grav )
			{
				if( self.has_legs )
				{
					var = RandomIntRange( 1, level.num_anim[self.animname]["sprint"] + 1 );

					anim_set = "sprint_moon" + var;

					break;
				}
				else
				{
					var = RandomIntRange( 1,  level.num_anim[self.animname]["crawl"] + 1 );

					anim_set = "crawl_moon" + var;

					break;
				}
			}
			else
			{
				if( self.has_legs )
				{
					var = RandomIntRange( 1, 5 );

					anim_set = "sprint" + var;

					break;
				}
				else
				{
					var = RandomIntRange( 1, 4 );

					anim_set = "crawl_sprint" + var;

					break;
				}

			}

	}

	self moon_jump_pad_run_switch( anim_set );

	self._pad_chase = 0;
}



// -- jump pad run throttle
jump_pad_throttle_anim_changes()
{
	if( !IsDefined( level._jump_pad_anim_change ) )
	{
		level._jump_pad_anim_change = [];
	}

	int_max_num_zombies_per_frame = 7; // how many guys it can allow at a time
	array_zombies_allowed_to_switch = [];

	// loop through the array
	while( IsDefined( level._jump_pad_anim_change ) )
	{
		if( level._jump_pad_anim_change.size == 0 )
		{
			wait( 0.1 );
			continue;
		}

		array_zombies_allowed_to_switch = level._jump_pad_anim_change;

		for( i = 0; i < array_zombies_allowed_to_switch.size; i++  )
		{
			if( !IsAlive( array_zombies_allowed_to_switch[i] ) )
			{
				continue;
			}

			array_zombies_allowed_to_switch[i] ent_flag_set( "pad_anim_change" );

			if( i >= int_max_num_zombies_per_frame )
			{
				break; // no more zombies should be allowed to change until the next server frame
			}
		}

		flag_clear( "pad_allow_anim_change" );

		wait( 0.05 );

		// now clean out those that were allowed to change
		for( i = 0; i < array_zombies_allowed_to_switch.size; i++ )
		{
			zmb = array_zombies_allowed_to_switch[i];

			if( !IsAlive( zmb ) || !IsDefined( zmb ) )
			{
				continue; // dude is dead or gone. Curse you distance tracking!
			}

			if( zmb ent_flag( "pad_anim_change" ) )
			{
				// remove this one from the level array
				level._jump_pad_anim_change = array_remove( level._jump_pad_anim_change, zmb );
				zmb ent_flag_clear( "pad_anim_change" );
			}

		}

		// clean any dead or undefined from the main array
		level._jump_pad_anim_change = array_removedead( level._jump_pad_anim_change );
		level._jump_pad_anim_change = array_removeundefined( level._jump_pad_anim_change );

		flag_set( "pad_allow_anim_change" );

		wait( 0.1 );

	}

}

// changes the run anim on an ent
moon_jump_pad_run_switch( str_anim_key )
{
	self endon( "death" );

	self.a.runBlendTime = 0.9;
	self clear_run_anim();

	self.needs_run_update = true;

	self set_run_anim( str_anim_key );
	self.run_combatanim = level.scr_anim[self.animname][str_anim_key];
	self.crouchRunAnim = level.scr_anim[self.animname][str_anim_key];
	self.crouchrun_combatanim = level.scr_anim[self.animname][str_anim_key];
}

// readies the cushion triggers to make a sound when a player comes through for a lanfing
moon_jump_pad_cushion_sound_init()
{
	flag_wait( "all_players_connected" );

	cushion_sound_triggers = GetEntArray( "trig_cushion_sound", "targetname" );

	if( !IsDefined( cushion_sound_triggers ) || cushion_sound_triggers.size == 0 )
	{
		// early out
		return;
	}

	for( i = 0; i < cushion_sound_triggers.size; i++ )
	{
		cushion_sound_triggers[i] thread moon_jump_pad_cushion_play_sound();
	}

}

// plays a sound on the trigger each time a player hit it after using a jump pad
moon_jump_pad_cushion_play_sound()
{
	while( IsDefined( self ) )
	{
		self waittill( "trigger", who );

		if( IsPlayer( who ) && is_true( who._padded ) )
		{
			// play sound on trigger
			self PlaySound( "evt_jump_pad_land" );
		}
	}
}
