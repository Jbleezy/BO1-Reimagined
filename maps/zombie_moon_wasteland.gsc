
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

#include maps\zombie_moon_teleporter;


//*****************************************************************************
// Misc initializations for "No Mans Land"
//*****************************************************************************


#using_animtree( "generic_human" );

//----------------------------------------------------------------------------------------------
// setup low gravity anims
//----------------------------------------------------------------------------------------------
init_supersprint_anims()
{
	// added for zombie speed buff
	level.scr_anim["zombie"]["sprint5"] = %ai_zombie_fast_sprint_01;
	level.scr_anim["zombie"]["sprint6"] = %ai_zombie_fast_sprint_02;
}

init_no_mans_land()
{
	flag_init("enter_nml");
	flag_init("teleporter_used");
	flag_init("start_supersprint");

	level.on_the_moon = false;
	level.ever_been_on_the_moon = false;
	level.initial_spawn = true;
	level.nml_didteleport = false;

	level.nml_dog_health = 150;

	//level._effect[ "lightning_dog_spawn" ]	= Loadfx( "maps/zombie/fx_zombie_dog_lightning_buildup" );

	/*******************************************************/
	/* Teleporter Message - Shared text by all teleporters */
	/*******************************************************/

	//init_teleporter_message();
	level thread init_supersprint_anims();

	maps\_zombiemode_zone_manager::zone_init( "nml_zone" );

	//set for earth sky at start
	//SetSavedDvar( "r_skyTransition", 1 );

	// Power Gate
	teleporter_to_nml_init();


	/*******************************************/
	/* Init the player in NML detection volume */
	/*******************************************/

	ent = getent( "nml_dogs_volume", "targetname" );
	ent thread check_players_in_nml_dogs_volume();
	level.num_nml_dog_targets = 0;


	/************************************************************/
	/* Get Perk Machine Entities								*/
	/* This is a little long winded but how else can you do it? */
	/************************************************************/

	get_perk_machine_ents();
	level.last_perk_index = -1;
	level.first_perk = true;

	// DCS 050911: starting in nml.
	if(level.gamemode == "survival")
	{
		level thread zombie_moon_start_init();
	}

	level.NML_REACTION_INTERVAL		  = 2000;	  // time interval between reactions
	level.NML_MIN_REACTION_DIST_SQ    = 32*32;	  // minimum distance from the player to be able to react
	level.NML_MAX_REACTION_DIST_SQ	  = 2400*2400;// maximum distance from the player to be able to react

	level.nml_start_perk = GetDvar("nml_start_perk");
}

//******************************************************************************
zombie_moon_start_init()
{
	flag_wait( "begin_spawning" );

	level thread nml_dogs_init();

	teleporter = getent( "generator_teleporter", "targetname" );
	teleporter_ending( teleporter, 0 );
}

nml_dogs_init()
{
	level.nml_dogs_enabled = false;
	wait(30);
	level.nml_dogs_enabled = true;
}
//******************************************************************************
nml_setup_round_spawner()
{
	// Remember the last round number for when we return
	if(IsDefined(level.round_number))
	{
		if(flag("between_rounds"))
		{
			level.nml_last_round = level.round_number + 1;
			level.prev_round_zombies = [[ level.max_zombie_func ]]( level.zombie_vars["zombie_max_ai"] );
		}
		else
		{
			level.nml_last_round = level.round_number;
		}
	}
	else
	{
		level.nml_last_round = 1; // start of level.
	}

	level.round_spawn_func = ::nml_round_manager;

	// Kill current round and prepare a NML Style round spawngin system
	Init_Moon_NML_Round( level.nml_last_round );
}

//*****************************************************************************
// How many players inside the volume ent?
//*****************************************************************************
num_players_touching_volume( volume )
{
	players = get_players();
	num_players_inside = 0;

	for( i=0; i<players.size; i++ )
	{
		ent = players[i];
		if(!isAlive(ent) || !isPlayer(ent) || ent.sessionstate == "spectator")
		{
			continue;
		}
		if( ent istouching( volume ) )
		{
			num_players_inside++;
		}
	}

	return( num_players_inside );
}


//*****************************************************************************
// Check if any players are inside the deadly dog volume in NML
//*****************************************************************************
check_players_in_nml_dogs_volume()
{
	while( 1 )
	{
		level.num_nml_dog_targets = num_players_touching_volume( self );
		wait( 1.3 );
	}
}


//*****************************************************************************
// Level specific Text
//
// Teleporter: "Players in Teleporter"
//			 : "Teleporter Activated"
// N M L     : "Zombie Wasteland"
//           : "Time Remaining"
//*****************************************************************************
init_hint_hudelem( x, y, alignX, alignY, fontscale, alpha )
{
	self.x = x;
	self.y = y;
	self.alignX = alignX;
	self.alignY = alignY;
	self.fontScale = fontScale;
	self.alpha = alpha;
	self.sort = 20;
}

init_teleporter_message()
{
	players = get_players();
	for( i=0; i<players.size; i++ )
	{
		player = players[i];
		player.teleporter_message = newClientHudElem( player );
		player.teleporter_message init_hint_hudelem( 320, 140, "center", "bottom", 1.6, 1.0 );
		player.teleporter_message SetText( &"NULL_EMPTY" );
	}
	level.lastMessageTime = 0;
}

set_teleporter_message( message )
{
	/**************************************************************/
	/* Make sure text isn't replaced with "" for a period of time */
	/**************************************************************/

	if( message != &"NULL_EMPTY" )
	{
		level.lastMessageTime = gettime();
	}

	time = gettime() - level.lastMessageTime;
	if( (time < (1000 * 1)) && (message == &"NULL_EMPTY") )
	{
		return;
	}


	/******************************************/
	/* Set the message string for all players */
	/******************************************/

	players = get_players();
	for( i=0; i<players.size; i++ )
	{
		player = players[i];
		if ( IsDefined( player.teleporter_message ) )
		{
			player.teleporter_message SetText( message );
		}
	}
}


//*****************************************************************************
//
//*****************************************************************************
Init_Moon_NML_Round( target_round )
{

	// delete all active zombies/force next round, then reset.
	zombies = GetAIArray( "axis" );

	if ( IsDefined( zombies ) )
	{
		for (i = 0; i < zombies.size; i++)
		{
			if ( is_true( zombies[i].ignore_nml_delete ) )
			{
				continue;
			}

			if(IsDefined(zombies[i].fx_quad_trail))
			{
				zombies[i].fx_quad_trail Delete();
			}
			zombies[i] maps\_zombiemode_spawner::reset_attack_spot();
			zombies[i] notify("zombie_delete");
			zombies[i] Delete();
		}
	}
	level.zombie_health = level.zombie_vars["zombie_health_start"];
	maps\_zombiemode::ai_calculate_health(level.nml_last_round);
	level.zombie_total = 0;
	level.round_number = level.nml_last_round;

	if(level.gamemode != "survival")
	{
		return;
	}

	level.chalk_override = " ";
	
	level thread clear_nml_rounds();
		
	// failsafe to clear hud.
	level waittill("between_round_over");
	if ( IsDefined( level.chalk_override ) )
	{
		level.chalk_hud1 SetText( level.chalk_override );
		level.chalk_hud2 SetText( " " );
	}	
}

clear_nml_rounds()
{
	level endon("restart_round");

	while(IsDefined(level.chalk_override))
	{
		if ( IsDefined( level.chalk_override ) )
		{
			if(IsDefined(level.chalk_hud1))
			{
				level.chalk_hud1 SetText( level.chalk_override );
			}

			if(IsDefined(level.chalk_hud2))
			{
				level.chalk_hud2 SetText( level.chalk_override );
			}
		}

		wait(1.0);
	}
}

//*****************************************************************************
//
//*****************************************************************************
resume_moon_rounds( target_round )
{
	if ( target_round < 1 )
	{
		target_round = 1;
	}
	level.chalk_override = undefined;

	level.zombie_health = level.zombie_vars["zombie_health_start"];
	level.zombie_total = 0;

	maps\_zombiemode::ai_calculate_health(target_round);

	level notify( "restart_round" );

	level._from_nml = true;

	// kill all active zombies
	zombies = GetAiSpeciesArray( "axis", "all" );

	if ( IsDefined( zombies ) )
	{
		for (i = 0; i < zombies.size; i++)
		{
			if ( is_true( zombies[i].ignore_nml_delete ) )
			{
				continue;
			}

			if ( zombies[i].isdog )
			{
				zombies[i] DoDamage( zombies[i].health + 10, zombies[i].origin );

				continue;
			}

			if ( IsDefined( zombies[i].fx_quad_trail ) )
			{
				zombies[i].fx_quad_trail Delete();
			}

			zombies[i] maps\_zombiemode_spawner::reset_attack_spot();
			zombies[i] notify("zombie_delete");
			zombies[i] Delete();
		}
	}
}


//*****************************************************************************
//*****************************************************************************
nml_round_manager()
{
	level endon("restart_round");

	// *** WHAT IS THIS? ***
	level.dog_targets = getplayers();
	for( i=0; i<level.dog_targets.size; i++ )
	{
		level.dog_targets[i].hunted_by = 0;
	}

	level.nml_start_time = GetTime();

	// Time when dog spawns start in NML
	dog_round_start_time = 2000;
	dog_can_spawn_time = -1000*10;
	dog_difficulty_min_time = 3000;
	dog_difficulty_max_time = 9500;

	// Attack Waves setup
	wave_1st_attack_time = (1000 * 25);//(1000 * 40);
	prepare_attack_time = (1000 * 2.1);
	wave_attack_time = (1000 * 35);		// 40
	cooldown_time = (1000 * 16);		// 25
	next_attack_time = (1000 * 26);		// 32

	/*if(level.num_astro_zombies)
		max_zombies = 23;
	else
		max_zombies = 24;*/
	max_zombies = 24;

	next_round_time = level.nml_start_time + wave_1st_attack_time;
	mode = "normal_spawning";

	area = 1;

	// Once some AI appear, make sure the round never ends
	level thread nml_round_never_ends();

	while( 1 )
	{
		current_time = GetTime();

		wait_override = 0.0;


		/**************************************************************/
		/* There is a limit of 24 AI entities, wait to hit this limit */
		/**************************************************************/

		zombies = GetAiSpeciesArray( "axis", "all" );

		while( zombies.size >= max_zombies )
		{
			zombies = GetAiSpeciesArray( "axis", "all" );
			wait( 0.5 );
		}


		/***************************/
		/* Update the Spawner Mode */
		/***************************/

		if(level.initial_spawn == true)
		{
			spawn_a_zombie( 10, "nml_zone_spawners", 0.01 );
		}
		else
		{
			ai = spawn_a_zombie( max_zombies, "nml_zone_spawners", 0.01 );
			if( isdefined (ai) )
			{
				ai.zombie_move_speed = "sprint";

				//Normal sprint (1,4)
				//Super-sprint (5,6)

				if(flag("start_supersprint"))
				{
					theanim = "sprint" + randomintrange(1, 6);
				}
				else
				{
					theanim = "sprint" + randomintrange(1, 4);
				}

				if( IsDefined( ai.pre_black_hole_bomb_run_combatanim ) )
				{
					ai.pre_black_hole_bomb_run_combatanim = theanim;
				}
				else
				{
					ai set_run_anim( theanim );
					ai.run_combatanim = level.scr_anim[ai.animname][theanim];
					ai.walk_combatanim = level.scr_anim[ai.animname][theanim];
					ai.crouchRunAnim = level.scr_anim[ai.animname][theanim];
					ai.crouchrun_combatanim = level.scr_anim[ai.animname][theanim];
					ai.needs_run_update = true;
				}
			}
		}

		// Check for Spawner Wave to Start
		if( current_time > next_round_time )
		{
			/*next_round_time = current_time + prepare_attack_time;
			mode = "preparing_spawn_wave";
			level thread screen_shake_manager( next_round_time );*/

			level.initial_spawn = false;
			level notify( "start_nml_ramp" );

			zombies = GetAiSpeciesArray( "axis" );
			for( i=0; i < zombies.size; i++ )
			{
				if( zombies[i].has_legs && zombies[i].animname == "zombie") // make sure not a dog.
				{
					zombies[i].zombie_move_speed = "sprint";

					//Normal sprint (1,4)
					//Super-sprint (5,6)
					if(flag("start_supersprint"))
					{
						theanim = "sprint" + randomintrange(1, 6);
					}
					else
					{
						theanim = "sprint" + randomintrange(1, 4);
					}

					level.initial_spawn = false;
					level notify( "start_nml_ramp" );

					if( IsDefined( zombies[i].pre_black_hole_bomb_run_combatanim ) )
					{
						zombies[i].pre_black_hole_bomb_run_combatanim = theanim;
					}
					else
					{
						zombies[i] set_run_anim( theanim );
						zombies[i].run_combatanim = level.scr_anim[zombies[i].animname][theanim];
						zombies[i].walk_combatanim = level.scr_anim[zombies[i].animname][theanim];
						zombies[i].crouchRunAnim = level.scr_anim[zombies[i].animname][theanim];
						zombies[i].crouchrun_combatanim = level.scr_anim[zombies[i].animname][theanim];
						zombies[i].needs_run_update = true;
					}
				}
			}

			level notify( "nml_attack_wave" );
		}

		/***************************************************************************************/
		/* If there are any dog targets (players running about in NML (away from the platform) */
		/* Send dogs after them																   */
		/***************************************************************************************/

		num_dog_targets = 0;
		if( (current_time - level.nml_start_time) > dog_round_start_time )
		{
			skip_dogs = 0;

			// *** DIFFICULTY FOR 1 Player ***
			players = get_players();
			if( players.size <= 1 )
			{
				dt = current_time - dog_can_spawn_time;
				if( dt < 0 )
				{
					//iPrintLn( "DOG SKIP" );
					skip_dogs = 1;
				}
			}

			if( !skip_dogs && level.nml_dogs_enabled == true && RandomInt(100) < 15)
			{
				num_dog_targets = level.num_nml_dog_targets;
				//iPrintLn( "Num Dog Targets: " + num_dog_targets );

				if( num_dog_targets )
				{
					// Send 2 dogs after each player
					dogs = getaispeciesarray( "axis", "dog" );
					num_dog_targets *= 2;

					if( dogs.size < num_dog_targets )
					{
						//IPrintLnBold("Spawn a dog");
						ai = maps\_zombiemode_ai_dogs::special_dog_spawn();

						//set their health to current level immediately.
						zombie_dogs = GetAISpeciesArray("axis","zombie_dog");
						if(IsDefined(zombie_dogs))
						{
							for( i=0; i<zombie_dogs.size; i++ )
							{
								if(zombie_dogs[i].health == zombie_dogs[i].maxhealth)
								{
									zombie_dogs[i].maxhealth = int( level.nml_dog_health );
									zombie_dogs[i].health = int( level.nml_dog_health );
								}
							}
						}
					}
				}
			}
		}

		if( level.initial_spawn )
		{
			//wait randomfloatrange( 0.1, 0.8 );
			wait 0.4;
		}
		else
		{
			//wait randomfloatrange( 0.01, 0.2 );
			wait 0.1;
		}
	}
}


//*****************************************************************************
//
//*****************************************************************************
nml_wave_attack( num_in_wave, spawner_name )
{
	level endon("wave_attack_finished");
	level endon("restart_round");

	while( 1 )
	{
		zombies = GetAiSpeciesArray( "axis", "all" );
		if( zombies.size < num_in_wave )
		{
			ai = spawn_a_zombie( num_in_wave, spawner_name, 0.01 );
			if( isdefined (ai) )
			{
				ai.ignore_gravity = true;
				ai.zombie_move_speed = "sprint";

				//Normal sprint (1,4)
				//Super-sprint (5,6)
				if(flag("start_supersprint"))
				{
					theanim = "sprint" + randomintrange(1, 6);
				}
				else
				{
					theanim = "sprint" + randomintrange(1, 4);
				}

				if( IsDefined( ai.pre_black_hole_bomb_run_combatanim ) )
				{
					ai.pre_black_hole_bomb_run_combatanim = theanim;
				}
				else
				{
					ai set_run_anim( theanim );
					ai.run_combatanim = level.scr_anim[ai.animname][theanim];
					ai.walk_combatanim = level.scr_anim[ai.animname][theanim];
					ai.crouchRunAnim = level.scr_anim[ai.animname][theanim];
					ai.crouchrun_combatanim = level.scr_anim[ai.animname][theanim];
					ai.needs_run_update = true;
				}

			}
		}

		wait randomfloatrange( 0.3, 1.0 );
	}
}


//*****************************************************************************
//*****************************************************************************
spawn_a_zombie( max_zombies, spawner_zone_name, wait_delay )
{
	// Don't spawn a new zombie if we are at the limit
	zombies = getaispeciesarray( "axis" );
	if( zombies.size >= max_zombies )
	{
		return( undefined );
	}

	zombie_spawners = getentarray( spawner_zone_name, "targetname" );

	spawn_point = zombie_spawners[RandomInt( zombie_spawners.size )];

	ai = spawn_zombie( spawn_point );
	if( IsDefined( ai ) )
	{
		ai thread maps\_zombiemode::round_spawn_failsafe();
		ai.zone_name = spawner_zone_name;

		if ( is_true( level.mp_side_step ) )
		{
			ai.shouldSideStepFunc = ::nml_shouldSideStep;
			ai.sideStepAnims = [];

			ai.sideStepAnims["step_left"]	= array( %ai_zombie_MP_sidestep_left_a, %ai_zombie_MP_sidestep_left_b );
			ai.sideStepAnims["step_right"]	= array( %ai_zombie_MP_sidestep_right_a, %ai_zombie_MP_sidestep_right_b );
		}
	}

	wait( wait_delay );
	wait_network_frame();

	return( ai );
}

//*****************************************************************************
//*****************************************************************************
screen_shake_manager( next_round_time )
{
	level endon( "nml_attack_wave" );
	level endon("restart_round");

	time = 0;
	while( time < next_round_time )
	{
		level thread attack_wave_screen_shake();
		wait_time = randomfloatrange(0.25, 0.35);
		wait( wait_time );
		time = gettime();
	}
}

attack_wave_screen_shake()
{
	/**********************************************************/
	/* Get a position that averages all the players positions */
	/**********************************************************/

	num_valid = 0;
	players = get_players();
	pos = ( 0, 0, 0 );

	for( i=0; i<players.size; i++ )
	{
		player = players[i];
		if( is_player_valid(player) )
		{
			pos += player.origin;
			num_valid ++;
		}
	}

	if( !num_valid )
	{
		return;
	}

	shake_position = ( (pos[0]/num_valid), (pos[1]/num_valid), (pos[2]/num_valid) );


	/**********/
	/* Rumble */
	/**********/

	thread rumble_all_players( "damage_heavy" );


	/****************/
	/* Shake Screen */
	/****************/

	scale = 0.4;
	duration = 1.0;
	radius = 42 * 400;

	//earthquake( scale, duration, shake_position, radius );
}


rumble_all_players(high_rumble_string, low_rumble_string, rumble_org, high_rumble_range, low_rumble_range)
{
	players = get_players();

	for (i = 0; i < players.size; i++)
	{
		if (isdefined (high_rumble_range) && isdefined (low_rumble_range) && isdefined(rumble_org))
		{
			if (distance (players[i].origin, rumble_org) < high_rumble_range)
			{
				players[i] playrumbleonentity(high_rumble_string);
			}
			else if (distance (players[i].origin, rumble_org) < low_rumble_range)
			{
				players[i] playrumbleonentity(low_rumble_string);
			}
		}
		else
		{
			players[i] playrumbleonentity(high_rumble_string);
		}
	}
}

//*****************************************************************************
//*****************************************************************************
get_perk_machine_ents()
{
	nml_position_helper = getstruct( "nml_perk_location_helper", "script_noteworthy" );
	nml_dist = 42 * 100;

	level.speed_cola_ents = get_vending_ents( "vending_sleight", "speedcola_perk", nml_position_helper.origin, nml_dist );
//	iPrintLn( "COLA ENT: " + level.speed_cola_ents.size );

	level.jugg_ents = get_vending_ents( "vending_jugg", "jugg_perk", nml_position_helper.origin, nml_dist );
//	iPrintLn( "JUGG ENT: " + level.jugg_ents.size );
}

get_vending_ents( vending_name, perk_script_string, nml_pos, nml_radius )
{
	names = [];
	names[0] = vending_name;
	//names[1] = "audio_bump_trigger";
	names[1] = "zombie_vending";

	ent_array = [];
	for( i=0; i<names.size; i++ )
	{
		ents = getentarray( names[i], "targetname" );
		for( j=0; j<ents.size; j++ )
		{
			ent = ents[j];
			if( isdefined(ent.script_string) && (ent.script_string == perk_script_string) )
			{
				if( (abs(nml_pos[0] - ent.origin[0]) < nml_radius) &&
					(abs(nml_pos[1] - ent.origin[1]) < nml_radius) &&
					(abs(nml_pos[2] - ent.origin[2]) < nml_radius) )
				{
					ent_array[ ent_array.size ] = ent;
				}
			}
		}
	}

	return( ent_array );
}


move_perk( dist, time, accel )
{
	//***********
	// Speed Cola
	//***********

	ent = level.speed_cola_ents[0];
	pos = (ent.origin[0], ent.origin[1], ent.origin[2]+dist);
	ent moveto ( pos, time, accel, accel );

	level.speed_cola_ents[1] trigger_off();


	//***********
	// Jugg
	//***********

	ent = level.jugg_ents[0];
	pos = (ent.origin[0], ent.origin[1], ent.origin[2]+dist);
	ent moveto ( pos, time, accel, accel );

	level.jugg_ents[1] trigger_off();

}


perk_machines_hide( cola, jug, moving )
{
	if(!IsDefined(moving))
	{
		moving = false;
	}
	if( cola )
	{
		level.speed_cola_ents[0] hide();
	}
	else
	{
		level.speed_cola_ents[0] show();
	}

	if( jug )
	{
		level.jugg_ents[0] hide();
	}
	else
	{
		level.jugg_ents[0] show();
	}

	if(moving)
	{
		level.speed_cola_ents[1] trigger_off();
		level.jugg_ents[1] trigger_off();

		if(IsDefined(level.speed_cola_ents[1].hackable))
		{
			maps\_zombiemode_equip_hacker::deregister_hackable_struct(level.speed_cola_ents[1].hackable);
		}

		if(IsDefined(level.jugg_ents[1].hackable))
		{
			maps\_zombiemode_equip_hacker::deregister_hackable_struct(level.jugg_ents[1].hackable);
		}
	}
	else
	{
		hackable = undefined;

		if(cola)
		{
			level.jugg_ents[1] trigger_on();
			if(IsDefined(level.jugg_ents[1].hackable))
			{
				hackable = level.jugg_ents[1].hackable;
			}

			level thread maps\_zombiemode_perks::add_bump_trigger("specialty_armorvest", level.jugg_ents[0].origin);
		}
		else
		{
			level.speed_cola_ents[1] trigger_on();

			if(IsDefined(level.speed_cola_ents[1].hackable))
			{
				hackable = level.speed_cola_ents[1].hackable;
			}

			level thread maps\_zombiemode_perks::add_bump_trigger("specialty_fastreload", level.jugg_ents[0].origin);
		}

		maps\_zombiemode_equip_hacker::register_pooled_hackable_struct(hackable, maps\_zombiemode_hackables_perks::perk_hack, maps\_zombiemode_hackables_perks::perk_hack_qualifier);
	}
}


perk_machine_show_selected( perk_index, moving )
{
	switch( perk_index )
	{
		case 0:
			perk_machines_hide( 0, 1, moving );
		break;

		case 1:
			perk_machines_hide( 1, 0, moving );
		break;
	}
}


//*****************************************************************************
//*****************************************************************************
perk_machine_arrival_update()
{
	top_height = 1200;		// 700
	fall_time = 4;
	num_model_swaps = 20;

	perk_index = randomintrange( 0, 2 );

	// Flash an effect to the perk machines destination
	ent = level.speed_cola_ents[0];
	level thread perk_arrive_fx( ent.origin );

	level thread maps\_zombiemode_perks::remove_bump_trigger("specialty_armorvest");
	level thread maps\_zombiemode_perks::remove_bump_trigger("specialty_fastreload");

	//while( 1 )
	{
		// Move the perk machines high in the sky
		move_perk( top_height, 0.01, 0.001 );
		wait( 0.3 );
		perk_machines_hide( 0, 0, true );
		wait( 1 );

		// Start the machines falling
		move_perk( top_height*-1, fall_time, 1.5 );

		// Swap visible Perk as we fall
		wait_step = fall_time / num_model_swaps;
		for( i=0; i<num_model_swaps; i++ )
		{
			perk_machine_show_selected( perk_index, true );
			wait( wait_step );

			perk_index++;
			if( perk_index > 1 )
			{
				perk_index = 0;
			}
		}

		// Make sure we don't get a perk machine duplicate next time we visit
		if(level.first_perk)
		{
			//host can choose which perk initally spawns from game settings
			level.first_perk = false;
			if(level.nml_start_perk == "random")
			{
				perk_index = randomintrange( 0, 2 );
			}
			else if(level.nml_start_perk == "speed")
			{
				perk_index = 0;
			}
			else
			{
				perk_index = 1;
			}
		}
		else
		{
			if(level.last_perk_index == 0)
			{
				perk_index = 1;
			}
			else
			{
				perk_index = 0;
			}
		}

		level.last_perk_index = perk_index;
		perk_machine_show_selected( perk_index, false );

	}
}


//*****************************************************************************
//*****************************************************************************
perk_arrive_fx( pos )
{
	wait( 0.15 );

	Playfx( level._effect["lightning_dog_spawn"], pos );
	playsoundatposition( "zmb_hellhound_spawn", pos );
	playsoundatposition( "zmb_hellhound_bolt", pos );

	wait( 1.1 );
	Playfx( level._effect["lightning_dog_spawn"], pos );
	playsoundatposition( "zmb_hellhound_spawn", pos );
	playsoundatposition( "zmb_hellhound_bolt", pos );
}

//*****************************************************************************
//*****************************************************************************
nml_round_never_ends()
{
	wait( 2 );

	level endon( "restart_round" );

	while( flag("enter_nml") )
	{
		zombies = GetAiSpeciesArray( "axis", "all" );
		if( zombies.size >= 2 )
		{
			// This ensures the round will never end
			level.zombie_total = 100;
			return;
		}
		wait( 1 );
	}
}

nml_side_stepping_zombies()
{
	level.mp_side_step = false;
	level waittill( "nml_attack_wave" );
	level.mp_side_step = true;
}

nml_ramp_up_zombies()
{
	self endon( "stop_ramp" );

	level waittill( "start_nml_ramp" );

	// start at round level entered no mans land
	level.nml_timer = level.nml_last_round;

	while(flag("enter_nml"))
	{
		//Check for health bump.

		if ( !level.on_the_moon )
		{
			level.nml_timer++;

			//level thread maps\_zombiemode::chalk_one_up(level.nml_timer);

	    	// DCS: ramping up zombies, play round change sound (# 88706)
      		thread play_sound_2d( "evt_nomans_warning" );

			zombies = GetAISpeciesArray("axis", "zombie");
			for( i=0; i<zombies.size; i++ )
			{
				//remove zombies from this array that have already taken damage or had thier head gibbed
				if( (zombies[i].health != level.zombie_health) || is_true(zombies[i].gibbed) || is_true(zombies[i].head_gibbed) )
				{
					zombies = array_remove(zombies, zombies[i]);
				}
			}

			maps\_zombiemode::ai_calculate_health(level.nml_timer);

			// all zombies full health ramp up.
			for( i=0; i<zombies.size; i++ )
			{
				if( is_true(zombies[i].gibbed) || is_true(zombies[i].head_gibbed))
				{
					continue;
				}

				zombies[i].health = level.zombie_health;

				if ( is_true( level.mp_side_step ) )
				{
					zombies[i].shouldSideStepFunc = ::nml_shouldSideStep;
					zombies[i].sideStepAnims = [];

					zombies[i].sideStepAnims["step_left"]	= array( %ai_zombie_MP_sidestep_left_a, %ai_zombie_MP_sidestep_left_b );
					zombies[i].sideStepAnims["step_right"]	= array( %ai_zombie_MP_sidestep_right_a, %ai_zombie_MP_sidestep_right_b );
				}
			}

			level thread nml_dog_health_increase();
			zombie_dogs = GetAISpeciesArray("axis","zombie_dog");
			if(IsDefined(zombie_dogs))
			{
				for( i=0; i<zombie_dogs.size; i++ )
				{
					if(zombie_dogs[i].health == zombie_dogs[i].maxhealth)
					{
						zombie_dogs[i].maxhealth = int( level.nml_dog_health);
						zombie_dogs[i].health = int( level.nml_dog_health );
					}
				}
			}
			//iprintln( "RAMP UP: " + level.nml_timer + " - " + level.zombie_health );
		}

		if(	level.nml_timer == 6)
		{
			flag_set("start_supersprint");
		}

		wait(20.0);
	}
}

nml_dog_health_increase()
{
	if( level.nml_timer < 4)
	{
		level.nml_dog_health = 150;
	}
	else if( level.nml_timer >= 4 && level.nml_timer < 6) //80 seconds.
	{
		level.nml_dog_health = 400;
	}
	else if( level.nml_timer >= 6 && level.nml_timer < 15 ) //2 minutes
	{
		level.nml_dog_health = 800;
	}
	else if( level.nml_timer >= 15 && level.nml_timer < 30 ) // 5 minutes
	{
		level.nml_dog_health = 1200;
	}
	else if(level.nml_timer >= 30)//10 minutes or more
	{
		level.nml_dog_health = 1600;
	}
}

nml_shouldSideStep()
{
	if ( self nml_canSideStep() )
	{
		return "step";
	}

	return "none";
}

nml_canSideStep()
{
	if( GetTime() - self.a.lastSideStepTime < level.NML_REACTION_INTERVAL )
		return false;

	if( !IsDefined(self.enemy) )
		return false;

	if( self.a.pose != "stand" )
		return false;

	distSqFromEnemy = DistanceSquared(self.origin, self.enemy.origin);

	// don't do it too close to the enemy
	if( distSqFromEnemy < level.NML_MIN_REACTION_DIST_SQ )
	{
		return false;
	}

	// don't do it too far from the enemy
	if( distSqFromEnemy > level.NML_MAX_REACTION_DIST_SQ )
	{
		return false;
	}

	// don't do it if not path or too close to destination
	if( !IsDefined(self.pathgoalpos) || DistanceSquared(self.origin, self.pathgoalpos) < level.NML_MIN_REACTION_DIST_SQ )
	{
		return false;
	}

	// make sure the AI's running straight
	if( abs(self GetMotionAngle()) > 15 )
	{
		return false;
	}

	return true;
}
