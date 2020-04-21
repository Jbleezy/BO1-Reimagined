
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\zombie_moon_utility;
#include maps\zombie_moon_wasteland;


//*****************************************************************************
// Teleporter
//*****************************************************************************
teleporter_function( name )
{
	// Get the Teleporter Trigger Ent
	teleporter = getent( name, "targetname" );

	teleport_time = 0;

	// Get the fx start and end positions
	str = name + "_bottom_name";
	fx_bottom = getstruct( str, "targetname" );
	str = name + "_top_name";
	fx_top = getstruct( str, "targetname" );


	/***************************/
	/* Update Teleporter State */
	/***************************/

	teleport_state = "Waiting for Players";

	while( 1 )
	{
		// How many players do we have?
		players = get_players();

/#
		//Check for dev cheaters
		for( i=0; i<players.size; i++ )
		{
			if ( IsGodMode( players[i] ) )
			{
				level.devcheater = 1;
			}
			if ( players[i] IsNoTarget() )
			{
				level.devcheater = 1;
			}
		}
#/

		num_players = valid_players_teleport();

		switch( teleport_state )
		{
			// Not Yet Implemented
			case "Waiting for Power":
			break;


			//********************
			// Waiting For Players
			//********************

			case "Waiting for Players":
				num_players_inside = num_players_touching_volume( teleporter );

				if( num_players_inside == 0 )
				{
					//set_teleporter_message( &"NULL_EMPTY" );
				}
				else if ( num_players_inside < num_players )
				{
					//set_teleporter_message( "Teleporter Waiting for Players" );
					//set_teleporter_message( &"ZOMBIE_PARIS_TRANSPORTER_WAITING" );
				}
				else
				{
					//set_teleporter_message( &"ZOMBIE_PARIS_TRANSPORTER_ACTIVATED" );

					// Set teleport start time
					teleport_time = gettime();
					teleport_time += 2500;

					// Special case startup
					//teleporter_starting( teleporter );

					teleport_state = "Teleport Countdown";

					//AUDIO: Triggering some sfx
					clientnotify( "tafx" );

					// Trigger Effect
					//playfx( level._effect["pad_bottom"], fx_bottom.origin );
					//playfx( level._effect["pad_top"], fx_top.origin );
				}
			break;

			//**********************
			// Countdown to Teleport
			//**********************

			case "Teleport Countdown":
				// Check for Players aborting the teleportation
				num_players_inside = num_players_touching_volume( teleporter );
				if ( num_players_inside < num_players )
				{
					//set_teleporter_message( &"ZOMBIE_PARIS_TRANSPORTER_ABORTED"  );
					teleporter_ending( teleporter, 1 );
					teleport_state = "Waiting for Players";
					//AUDIO: Triggering some sfx
					clientnotify( "cafx" );
				}

				// Time to teleport yet?
				else
				{
					current_time = gettime();
					if( teleport_time <= current_time )
					{
						//wait a network frame and valide the players again to make sure nobody bled out on the teleporter on this frame
						wait_network_frame();
						if( num_players_touching_volume( teleporter ) != valid_players_teleport() )
						{
							continue;
						}

						// Get player teleport positions
						target_positions = get_teleporter_target_positions( teleporter, name );

						// Special case startup
						teleporter_starting( teleporter );

						// Teleport the players
						for( i=0; i<players.size; i++ )
						{
							//playfx( level._effect["beam"], fx_bottom.origin );
							teleport_player_to_target( players[i], target_positions );
							//playfx( level._effect["beam"], players[i].origin );
							players[i] clientnotify( "bmfx" );
						}


						// Set next Teleporter State
						teleport_state = "Recharging";
						//set_teleporter_message( &"NULL_EMPTY" );
						teleport_time = gettime() + 5000;

						// give dogs 30 seconds to start spawning.
						level thread nml_dogs_init();
						// Teleporter completed special case checks
						teleporter_ending( teleporter, 0 );
					}
				}
			break;


			//**************************************
			// Recharging Teleporter for Another Use
			//**************************************

			case "Recharging":
				current_time = gettime();
				if( teleport_time <= current_time )
				{
					teleport_state = "Waiting for Players";
				}
			break;
		}

		wait( 0.5 );
	}
}
//*****************************************************************************
//*****************************************************************************
valid_players_teleport()
{

	players = get_players();
	valid_players = 0;
	for( i = 0 ; i < players.size; i++ )
	{
		if( is_player_teleport_valid( players[i] ) )
			valid_players += 1;
	}
	return valid_players;
}
is_player_teleport_valid( player )
{
	if( !IsDefined( player ) )
	{
		return false;
	}

	if( !IsAlive( player ) )
	{
		return false;
	}

	if( !IsPlayer( player ) )
	{
		return false;
	}

	if( player.sessionstate == "spectator" )
	{
		return false;
	}

	if( player.sessionstate == "intermission" )
	{
		return false;
	}

	if ( player isnotarget() )
	{
		return false;
	}
	return true;
}
//*****************************************************************************
// Get the teleporter target_positions
//*****************************************************************************
get_teleporter_target_positions( teleporter_ent, name )
{
	target_positions = [];

	/*********************************************************/
	/* Generator Teleporter									 */
	/* - Pick a random position for the pack a punch machine */
	/* - Teleport players close to pack a punch machine		 */
	/*********************************************************/

	if( (isDefined(teleporter_ent.script_noteworthy)) && (teleporter_ent.script_noteworthy == "enter_no_mans_land") )
	{

		// Get the potential respawn points
		player_starts = getstructarray( "packp_respawn_point", "script_noteworthy" );
		for( i=0; i<player_starts.size; i++ )
		{
			target_positions[i] = player_starts[i];
		}
	}
	else
	{
		//dest_name = get_teleporter_dest_ent_name();
		// DCS 050911: currently always to hanger.
		dest_name = "nml_to_bridge_teleporter";


		for( i=0; i<4; i++ )
		{
			str = dest_name + "_player" + (i+1) + "_position";
			ent = getstruct( str, "targetname" );
			target_positions[i] = ent;
		}
	}

	return( target_positions );
}


//*****************************************************************************
// Return the name of the destination ents that the teleporter is targetting
//*****************************************************************************
get_teleporter_dest_ent_name()
{
	index = level.nml_teleporter_dest_index;
	str = level.nml_teleporter_dest_names[ index ];
	return( str );
}


//*****************************************************************************
//
//*****************************************************************************
teleport_player_to_target( player, target_positions )
{
	player_index = player GetEntityNumber();

	target_ent = undefined;

	// uses position specific to player index(+1), same as respawning so won't telefrag.
	for( i=0; i<target_positions.size; i++ )
	{
		if(IsDefined(target_positions[i].script_int) && target_positions[i].script_int == player_index + 1)
		{
			target_ent = target_positions[i];
		}
	}

	if(!IsDefined(target_ent))
	{
		target_ent = target_positions[ player_index ];
	}

	// Do not allow prone, causes issues with setting angles.
	if( player getstance() == "prone" )
	{
		player SetStance("crouch");
	}

	// adding random offset to additionally avoid telefragging.
	player setorigin( target_ent.origin + (RandomFloat(24), RandomFloat(24), 0));

	if( isdefined( target_ent.angles ) )
	{
		player setplayerangles( target_ent.angles );
	}

	player SetVelocity((0,0,0));

	if( !level.been_to_moon_before )
	{
		level.been_to_moon_before = true;
		level.skit_vox_override = true;
		level thread turn_override_off();
	}
}

turn_override_off()
{
	level notify( "no_multiple_overrides" );
	level endon( "no_multiple_overrides" );

	wait(15);
	level.skit_vox_override = false;
}


//*****************************************************************************
//
//*****************************************************************************
teleporter_starting( teleporter_ent )
{
	// Freeze the Players
	players = get_players();
	for( i=0; i<players.size; i++ )
	{
		player = players[ i ];
		if( is_player_valid(player) )
		{
			player EnableInvulnerability();
		}
	}


	/***************************************************/
	/* Check for special case teleporter functionality */
	/***************************************************/

	if( isDefined( teleporter_ent.script_noteworthy) )
	{
		if( teleporter_ent.script_noteworthy == "enter_no_mans_land" )
		{
			// Just hide the perk machines
			//perk_machines_hide( 1, 1, 1, 1 );
		}
	}
}


//*****************************************************************************
// End teleportation of players
//*****************************************************************************
teleporter_check_for_endgame()
{
	if(level.gamemode != "survival")
	{
		return;
	}

	level waittill_any( "end_game", "track_nml_time" );
	level.nml_best_time = GetTime() - level.nml_start_time;

	players = get_players();
	level.nml_kills = players[0].kills;
	level.nml_score = players[0].score_total;
	//level.nml_didteleport = false;

	level.nml_pap = 0;
	level.nml_speed = 0;
	level.nml_jugg = 0;

	//Store the perk and pap values
	if( isdefined(players[0].pap_used) && players[0].pap_used )
	{
		level.nml_pap = 22;
	}
	if( isdefined(players[0].speed_used) && players[0].speed_used )
	{
		level.nml_speed = 33;
	}
	if( isdefined(players[0].jugg_used) && players[0].jugg_used )
	{
		level.nml_jugg = 44;
	}

	/*player_survival_time = int( level.nml_best_time/1000 );
	player_survival_time_in_mins = maps\_zombiemode::to_mins( player_survival_time );
	IPrintLnBold( "DEAD NO MANS LAND = " + player_survival_time_in_mins ); */
}



display_time_survived()
{
	players = get_players();

	level.nml_best_time = GetTime() - level.nml_start_time;

	//Should only be 1 player......
	level.nml_kills = players[0].kills;
	level.nml_score = players[0].score_total;
	level.nml_didteleport = true;
	level.nml_pap = 0;
	level.nml_speed = 0;
	level.nml_jugg = 0;

	level.left_nomans_land = 1;

	survived = [];
	for( i = 0; i < players.size; i++ )
	{
		//Store the perk and pap values
		if( isdefined(players[i].pap_used) && players[i].pap_used )
		{
			level.nml_pap = 22;
		}
		if( isdefined(players[i].speed_used) && players[i].speed_used )
		{
			level.nml_speed = 33;
		}
		if( isdefined(players[i].jugg_used) && players[i].jugg_used )
		{
			level.nml_jugg = 44;
		}

		survived[i] = NewClientHudElem( players[i] );
		survived[i].alignX = "center";
		survived[i].alignY = "middle";
		survived[i].horzAlign = "center";
		survived[i].vertAlign = "middle";
		survived[i].y -= 100;
		survived[i].foreground = true;
		survived[i].fontScale = 2;
		survived[i].alpha = 0;
		survived[i].color = ( 1.0, 1.0, 1.0 );
		if ( players[i] isSplitScreen() )
		{
			survived[i].y += 40;
		}

		//nomanslandtime = level.nml_best_time;
		//player_survival_time = int( nomanslandtime/1000 );
		player_survival_time = level.total_time;
		player_survival_time_in_mins = maps\_zombiemode::to_mins( player_survival_time );
		survived[i] SetText( &"ZOMBIE_SURVIVED_NOMANS", player_survival_time_in_mins );
		survived[i] FadeOverTime( 1 );
		survived[i].alpha = 1;
	}

	wait( 3.0 );

	for( i = 0; i < players.size; i++ )
	{
		survived[i] FadeOverTime( 1 );
		survived[i].alpha = 0;
	}

	level.left_nomans_land = 2;
}



teleporter_ending( teleporter_ent, was_aborted )
{
	/***********************/
	/* Restore the Players */
	/***********************/

	players = get_players();
	for( i=0; i<players.size; i++ )
	{
		player = players[ i ];
		if( is_player_valid(player) )
		{
			player DisableInvulnerability();
		}
	}

	/***************************************************/
	/* Check for special case teleporter functionality */
	/***************************************************/
	if( !was_aborted )
	{
		flag_set("teleporter_used");

		if( isDefined( teleporter_ent.script_noteworthy) )
		{
			if( teleporter_ent.script_noteworthy == "enter_no_mans_land" )
			{
				flag_set("enter_nml");
				level.on_the_moon = false;
				level thread maps\zombie_moon::zombie_earth_gravity_init();
				level thread nml_ramp_up_zombies();
				//level thread nml_side_stepping_zombies();


				//set for earth sky.
				level clientnotify("NMS");
				level thread sky_transition_fog_settings();

				set_zombie_var( "zombie_intermission_time", 2 );
				set_zombie_var( "zombie_between_round_time", 2 );

				// Save the state of the current round (as best as possible)
				zombies = GetAIArray( "axis");
				astro_spawned = false;
				for(i=0;i<zombies.size;i++)
				{
					if(zombies[i].animname == "astro_zombie")
					{
						astro_spawned = true;
						break;
					}
				}

				if(astro_spawned)
				{
					level.prev_round_zombies = (zombies.size - 1) + level.zombie_total;
				}
				else
				{
					level.prev_round_zombies = zombies.size + level.zombie_total;
				}

				level.prev_powerup_drop_count = level.powerup_drop_count;

				players = get_players();
				for(i = 0; i < players.size; i++)
				{
					players[i].prev_rebuild_barrier_reward = players[i].rebuild_barrier_reward;
				}

				// No pickups in No Mans Land
 				flag_clear( "zombie_drop_powerups" );

				level thread perk_machine_arrival_update();

				nml_setup_round_spawner();
			}
			else if( teleporter_ent.script_noteworthy == "exit_no_mans_land" )
			{
				flag_clear("enter_nml");
				level notify("stop_ramp");
				flag_clear("start_supersprint");

				level.on_the_moon = true;
				level.ignore_distance_tracking = true;

				// check for how long survived in NML.
				if( isdefined(level.ever_been_on_the_moon) && !level.ever_been_on_the_moon )
				{
					level notify( "track_nml_time" );
					if(level.gamemode == "survival")
					{
						level thread display_time_survived();
					}
					level.ever_been_on_the_moon = true;
				}

				//set for moon sky.
				level clientnotify("MMS");
				//SetSavedDvar( "r_skyTransition", 0 );
				level thread sky_transition_fog_settings();

				// Jump to Next Round
				level.round_number = level.nml_last_round;
				resume_moon_rounds( level.round_number );

				level thread maps\zombie_moon::zombie_moon_gravity_init();

				// resume regular zombiemode spawning.
				level.round_spawn_func = maps\_zombiemode::round_spawning;

				// Power down the Teleporter Gate
				level thread teleporter_to_nml_power_down();

				// Restore normal round intermission times
				set_zombie_var( "zombie_intermission_time", 15 );
				set_zombie_var( "zombie_between_round_time", 10 );

				// Switch pickups back on when exiting No Mans Land
 				flag_set( "zombie_drop_powerups" );
				level.ignore_distance_tracking = false;
			}
		}
	}
}


//*****************************************************************************
// Initialization for Teleporter Cage and Lights
//*****************************************************************************
teleporter_to_nml_init()
{
	// Teleporter to NML gate
	level.teleporter_to_nml_gate_height = 140;
	level.teleporter_to_nml_gate_ent = getent( "teleporter_gate", "targetname" );
	level.teleporter_to_nml_gate_open = 0;
	level.teleporter_to_nml_powerdown_time = 120;

	level.teleporter_to_nml_gate2_ent = getent( "teleporter_gate_top", "targetname" );
	level.teleporter_to_nml_gate2_height = 256;

	// Teleporter exit NML gate
	level.teleporter_exit_nml_gate_ent = getent( "bunker_gate", "targetname" );
	level.teleporter_exit_nml_gate_height = -195;	// -100
	level.teleporter_exit_nml_gate_open = 1;
	level.teleporter_exit_nml_powerdown_time = 75;

	level.teleporter_exit_nml_gate2_ent = getent( "bunker_gate_2", "targetname" );
	level.teleporter_exit_nml_gate2_height = -96;

	// Shared Gate Data
	level.teleporter_gate_move_time = 3;

	init_teleporter_lights();
	teleporter_lights_red();

	if(level.gamemode != "survival")
	{
		return;
	}

	level thread teleporter_exit_nml_think();
	level thread teleporter_waiting_for_electric();
}


//*****************************************************************************
// Teleporter to NML: Doesn't work until the electric is turned on
//*****************************************************************************
teleporter_waiting_for_electric()
{
	//flag_wait( "power_on" );

	teleporter_to_nml_gate_move( 1 );
}

//*****************************************************************************
// Either open or close the teleporter gate
// - Moves the gates SBM, sets lights and updates paths
//*****************************************************************************
teleporter_to_nml_gate_move( open_it )
{
	// Is the gate already in the desired position?
	if( (level.teleporter_to_nml_gate_open && open_it) || (!level.teleporter_to_nml_gate_open && !open_it) )
	{
		return;
	}

	level.teleporter_to_nml_gate_open = open_it;

	// Move the gate
	gate_height = level.teleporter_to_nml_gate_height;
	gate2_height = level.teleporter_to_nml_gate2_height;

	if( !open_it )
	{
		gate_height *= -1.0;
	}

	time = level.teleporter_gate_move_time;
	accel = time / 6.0;

	ent = level.teleporter_to_nml_gate_ent;
	ent2 = level.teleporter_to_nml_gate2_ent;

	// play sound when open teleporter gate
	ent PlaySound( "amb_teleporter_gate_start" );
	ent playloopsound( "amb_teleporter_gate_loop", .5 );

	pos = ( ent.origin[0], ent.origin[1], ent.origin[2]-gate_height );
	ent moveto ( pos, time, accel, accel );
	ent thread play_stopmoving_sounds();

	pos2 = ( ent2.origin[0], ent2.origin[1], ent2.origin[2]+gate_height );
	ent2 moveto ( pos2, time, accel, accel );

	// Update Paths
	if( open_it )
	{
		ent connectpaths();
	}
	else
	{
		ent disconnectpaths();
	}

	// Update Lights
	if( open_it )
	{
		teleporter_lights_green();
	}
	else
	{
		teleporter_lights_red();
	}
}


//*****************************************************************************
// Grab the names of the teleporter to NML lights
//*****************************************************************************
init_teleporter_lights()
{
	level.teleporter_lights = [];

	level.teleporter_lights[ level.teleporter_lights.size ] = "zapper_teleport_opening_1";
	level.teleporter_lights[ level.teleporter_lights.size ] = "zapper_teleport_opening_2";
	level.teleporter_lights[ level.teleporter_lights.size ] = "zapper_teleport_opening_3";
	level.teleporter_lights[ level.teleporter_lights.size ] = "zapper_teleport_opening_4";
}


//*****************************************************************************
//
//*****************************************************************************
teleporter_lights_red()
{
	for( i=0; i<level.teleporter_lights.size; i++ )
	{
		zapper_light_red( level.teleporter_lights[i], "targetname" );
	}
}

//*****************************************************************************
//
//*****************************************************************************
teleporter_lights_green()
{
	for( i=0; i<level.teleporter_lights.size; i++ )
	{
		zapper_light_green( level.teleporter_lights[i], "targetname" );
	}
}

//*****************************************************************************
// The teleporter is unavailable for a time period
//  - Represented to the player by the red/green lights
//*****************************************************************************
teleporter_to_nml_power_down()
{

	// Close the Teleporter Gate
	teleporter_to_nml_gate_move( 0 );

	if(level.gamemode != "survival")
	{
		return;
	}

	// Waittill round over for return reset.
	/*if(flag("teleporter_used") && is_true(level.first_teleporter_use))
	{
		level waittill("between_round_over");
		wait_network_frame();
	}*/

	if(!isDefined(level.first_teleporter_use))
	{
		level.first_teleporter_use = true;
	}

	// waittill next round over after return to moon.
	//level waittill("between_round_over");

	flag_wait("power_on");

	// Wait for a bit before the gate re-opens
	time = gettime();
	open_door_time = time + (level.teleporter_to_nml_powerdown_time * 1000);

	lights_mode = 0;

	dt = open_door_time - time;
	time0 = time + (dt / 4.0);
	time1 = time + (dt / 2.0);
	time2 = time + ((3.0 * dt) / 4.0);
	time3 = open_door_time - 0.75;

	// Wait for the timeout
	while( time < open_door_time )
	{
		time = gettime();

		switch( lights_mode )
		{
			case 0:
				if( time >= time0 )
				{
					zapper_light_green( level.teleporter_lights[0], "targetname" );
					lights_mode++;
				}
			break;

			case 1:
				if( time >= time1 )
				{
					zapper_light_green( level.teleporter_lights[1], "targetname" );
					lights_mode++;
				}
			break;

			case 2:
				if( time >= time2 )
				{
					zapper_light_green( level.teleporter_lights[2], "targetname" );
					lights_mode++;
				}
			break;

			case 3:
				if( time >= time3 )
				{
					zapper_light_green( level.teleporter_lights[3], "targetname" );
					lights_mode++;
					// Open the Teleporter Gate
					teleporter_to_nml_gate_move( 1 );
				}
			break;

			default:
				wait( 0.1 );
			break;
		}

		wait( 1 );
	}
}


//*****************************************************************************
// Either open or close the teleporter gate exiting NML
// - Moves the gates SBM, sets lights and updates paths
//*****************************************************************************
teleporter_exit_nml_think()
{
	// Bring the gate down so that when we enter No Mans Land the gate is covering the teleporter
	wait( 3 );
	level thread teleporter_exit_nml_gate_move( 0 );

	// Update Control
	while( 1 )
	{
		// Wait for players to enter No mans land
		flag_wait( "enter_nml" );

		if(level.on_the_moon == false)
		{
			wait(20);
		}
		else
		{
			wait( level.teleporter_exit_nml_powerdown_time );
		}
		level thread teleporter_exit_nml_gate_move( 1 );

		// Wait for players to exit No Mans Land
		while(flag("enter_nml"))
		{
			wait(1);
		}
		level thread teleporter_exit_nml_gate_move( 0 );
	}
}

//*****************************************************************************
//*****************************************************************************
teleporter_exit_nml_gate_move( open_it )
{
	// Is the gate already in the desired position?
	if( (level.teleporter_exit_nml_gate_open && open_it) || (!level.teleporter_exit_nml_gate_open && !open_it) )
	{
		return;
	}

	level.teleporter_exit_nml_gate_open = open_it;

	// Move the gate
	gate_height = level.teleporter_exit_nml_gate_height;
	gate2_height = level.teleporter_exit_nml_gate2_height;

	if( !open_it )
	{
		gate_height *= -1.0;
		gate2_height *= -1.0;
	}

	time = level.teleporter_gate_move_time;
	accel = time / 6.0;

	ent = level.teleporter_exit_nml_gate_ent;

	// play sound when open teleporter gate
	ent PlaySound( "amb_teleporter_gate_start" );
	ent playloopsound( "amb_teleporter_gate_loop", .5 );


	// move secondary gate
	ent2 = level.teleporter_exit_nml_gate2_ent;
	pos2 = ( ent2.origin[0], ent2.origin[1], ent2.origin[2]-gate2_height );
 	ent2 moveto ( pos2, time, accel, accel );

	// move primary gate
	pos = ( ent.origin[0], ent.origin[1], ent.origin[2]-gate_height );
	ent moveto ( pos, time, accel, accel );

	ent thread play_stopmoving_sounds();

	// Update Paths
	if( open_it )
	{
		ent connectpaths();
	}
	else
	{
		wait( level.teleporter_gate_move_time );
		ent disconnectpaths();
	}
}

play_stopmoving_sounds()
{
	self waittill( "movedone" );
	self stoploopsound( .5 );
	self playsound( "amb_teleporter_gate_stop" );
}
