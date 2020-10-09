#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

//-------------------------------------------------------------------------------
// setup and kick off think functions
//-------------------------------------------------------------------------------
teleporter_init()
{
	PreCacheModel("collision_wall_128x128x10");

	// DCS: added to fix non-attacking dogs.
	level.dog_melee_range = 130;
	level thread dog_blocker_clip();

	level.teleport = [];
	level.active_links = 0;
	level.countdown = 0;

	level.teleport_delay = 2;
	level.teleport_cost = 1500;
	level.teleport_cooldown = 5;
	level.is_cooldown = false;
	level.active_timer = -1;
	level.teleport_time = 0;

	flag_init( "teleporter_pad_link_1" );
	flag_init( "teleporter_pad_link_2" );
	flag_init( "teleporter_pad_link_3" );

	wait_for_all_players();

	// Get the Pad triggers
	for ( i=0; i<3; i++ )
	{
		trig = GetEnt( "trigger_teleport_pad_" + i, "targetname");
		if ( IsDefined(trig) )
		{
			level.teleporter_pad_trig[i] = trig;
		}
	}

	thread teleport_pad_think( 0 );
	thread teleport_pad_think( 1 );
	thread teleport_pad_think( 2 );
	thread teleport_core_think();

	thread start_black_room_fx();
	thread init_pack_door();

	SetDvar( "factoryAftereffectOverride", "-1" );
	SetSavedDvar( "zombiemode_path_minz_bias", 13 );
	level.no_dog_clip = true;

	packapunch_see = getent( "packapunch_see", "targetname" );
	if(isdefined( packapunch_see ) )
	{
		packapunch_see thread play_packa_see_vox();
	}

	level.teleport_ae_funcs = [];

	/*if( !IsSplitscreen() )
	{
		level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_cod5_factory_teleporter::teleport_aftereffect_fov;
	}*/
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_cod5_factory_teleporter::teleport_aftereffect_shellshock;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_cod5_factory_teleporter::teleport_aftereffect_shellshock_electric;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_cod5_factory_teleporter::teleport_aftereffect_bw_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_cod5_factory_teleporter::teleport_aftereffect_red_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_cod5_factory_teleporter::teleport_aftereffect_flashy_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_cod5_factory_teleporter::teleport_aftereffect_flare_vision;
}

//-------------------------------------------------------------------------------
// sets up up the pack a punch door
//-------------------------------------------------------------------------------
init_pack_door()
{
	//DCS: create collision blocker till door in place at load.
	if(level.gamemode == "survival")
	{
		level thread pack_door_move_up();
	}

	flag_wait( "all_players_connected" );

	//DCS: waite for door to be in place then delete blocker.
	wait(2);

	door = getent( "pack_door", "targetname" );

	// Open slightly the first two times
	flag_wait( "teleporter_pad_link_1" );
	door movez( -35, 1.5, 1 );
	if(level.gamemode == "survival")
	{
		door playsound( "packa_door_2" );
		door thread packa_door_reminder();
	}
	wait(1.5);

	// Second link
	flag_wait( "teleporter_pad_link_2" );
	door movez( -25, 1.5, 1 );
	if(level.gamemode == "survival")
	{
		door playsound( "packa_door_2" );
	}
	wait(1.5);

	// Final Link
	flag_wait( "teleporter_pad_link_3" );
	door movez( -60, 1.5, 1 );
	door playsound( "packa_door_2" );
	//door rotateyaw( -90, 1.5, 1 );
	wait(1.5);

	clip = getentarray( "pack_door_clip", "targetname" );
	for ( i = 0; i < clip.size; i++ )
	{
		clip[i] connectpaths();
		clip[i] delete();
	}
}

pack_door_move_up()
{
	collision = spawn("script_model", (-56, 467, 157));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();

	door = getent( "pack_door", "targetname" );
	door.origin = door.origin - (0, 0, 50);

	flag_wait( "all_players_spawned" );

	wait 1.5;

	door movez(  50, 1.5, 0 );
	door playsound( "packa_door_1" );

	wait(1.5);
	collision Delete();
}

//-------------------------------------------------------------------------------
// handles activating and deactivating pads for cool down
//-------------------------------------------------------------------------------
pad_manager()
{
	for ( i = 0; i < level.teleporter_pad_trig.size; i++ )
	{
		// shut off the pads
		level.teleporter_pad_trig[i] sethintstring( &"WAW_ZOMBIE_TELEPORT_COOLDOWN" );
		level.teleporter_pad_trig[i] teleport_trigger_invisible( false );
	}

	level.is_cooldown = true;
	wait( level.teleport_cooldown );
	level.is_cooldown = false;

	for ( i = 0; i < level.teleporter_pad_trig.size; i++ )
	{
		if ( level.teleporter_pad_trig[i].teleport_active )
		{
			level.teleporter_pad_trig[i] sethintstring( &"REIMAGINED_TELEPORT_TO_CORE", level.teleport_cost );
		}
		else
		{
			level.teleporter_pad_trig[i] sethintstring( &"REIMAGINED_LINK_TPAD" );
		}
//		level.teleporter_pad_trig[i] teleport_trigger_invisible( false );
	}
}

//-------------------------------------------------------------------------------
// staggers the black room fx
//-------------------------------------------------------------------------------
start_black_room_fx()
{
	for ( i = 901; i <= 904; i++ )
	{
		wait( 1 );
		exploder( i );
	}
}

//-------------------------------------------------------------------------------
// handles turning on the pad and waiting for link
//-------------------------------------------------------------------------------
teleport_pad_think( index )
{
	tele_help = getent( "tele_help_" + index, "targetname" );
	if(isdefined( tele_help ) )
	{
		tele_help thread play_tele_help_vox();
	}

	active = false;

	// init the pad
	level.teleport[index] = "waiting";

	trigger = level.teleporter_pad_trig[ index ];

	trigger setcursorhint( "HINT_NOICON" );
	trigger sethintstring( &"ZOMBIE_NEED_POWER" );

	flag_wait( "power_on" );

	trigger sethintstring( &"REIMAGINED_POWER_UP_TPAD" );
	trigger.teleport_active = false;

	if ( isdefined( trigger ) )
	{
		while ( !active )
		{
			if(level.gamemode == "survival")
			{
				trigger waittill( "trigger", user );
			}
			else
			{
				user = get_players()[0];
			}

			if(level.is_cooldown)
			{
				continue;
			}

			if ( level.active_links < 3 )
			{
				trigger_core = getent( "trigger_teleport_core", "targetname" );
				trigger_core teleport_trigger_invisible( false );
			}

			// when one starts the others disabled
			for ( i=0; i<level.teleporter_pad_trig.size; i++ )
			{
				level.teleporter_pad_trig[ i ] teleport_trigger_invisible( true );
			}
			level.teleport[index] = "timer_on";

			// start the countdown back to the core
			trigger thread teleport_pad_countdown( index, 30 );
			teleporter_vo( "countdown", trigger );

			// wait for the countdown
			while ( level.teleport[index] == "timer_on" )
			{
				wait( .05 );
			}

			// core was activated in time
			if ( level.teleport[index] == "active" )
			{
				active = true;
				ClientNotify( "pw" + index );	// pad wire #

				//AUDIO
				ClientNotify( "tp" + index );	// Teleporter #

				// MM - Auto teleport the first time
				teleporter_wire_wait( index );

//				trigger teleport_trigger_invisible( true );
				trigger thread player_teleporting( index, user, true );
			}
			else
			{
				// Reenable triggers
 				for ( i=0; i<level.teleporter_pad_trig.size; i++ )
 				{
 					level.teleporter_pad_trig[ i ] teleport_trigger_invisible( false );
 				}
			}
			wait( .05 );
		}

		if ( level.is_cooldown )
		{
			// shut off the pads
			trigger sethintstring( &"WAW_ZOMBIE_TELEPORT_COOLDOWN" );
			trigger teleport_trigger_invisible( false );
			trigger.teleport_active = true;
		}
		else
		{
			trigger thread teleport_pad_active_think( index );
		}
	}
}

//-------------------------------------------------------------------------------
// updates the teleport pad timer
//-------------------------------------------------------------------------------
teleport_pad_countdown( index, time )
{
	self endon( "stop_countdown" );

//	iprintlnbold( &"WAW_ZOMBIE_START_TPAD" );

	if ( level.active_timer < 0 )
	{
		level.active_timer = index;
	}

	level.countdown++;

	//AUDIO
	ClientNotify( "pac" + index );
	ClientNotify( "TRf" );	// Teleporter receiver map light flash

	// start timer for all players
	//	Add a second for VO sync
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		players[i] thread maps\_zombiemode_timer::start_timer( time+1, "stop_countdown" );
	}
	wait( time+1 );

	if ( level.active_timer == index )
	{
		level.active_timer = -1;
	}

	// ran out of time to activate teleporter
	level.teleport[index] = "timer_off";
//	iprintlnbold( "out of time" );
	ClientNotify( "TRs" );	// Stop flashing the receiver map light

	level.countdown--;
}

//-------------------------------------------------------------------------------
// handles teleporting players when triggered
//-------------------------------------------------------------------------------
teleport_pad_active_think( index )
{
//	self endon( "player_teleported" );

	// link established, can be used to teleport
	self setcursorhint( "HINT_NOICON" );
	self.teleport_active = true;

	user = undefined;

//	self sethintstring( &"WAW_ZOMBIE_TELEPORT_TO_CORE" );
//	self teleport_trigger_invisible( false );

	while ( 1 )
	{
		self waittill( "trigger", user );

		if ( is_player_valid( user ) && user.score >= level.teleport_cost && !level.is_cooldown )
		{
			for ( i = 0; i < level.teleporter_pad_trig.size; i++ )
			{
				level.teleporter_pad_trig[i] teleport_trigger_invisible( true );
			}

			user maps\_zombiemode_score::minus_to_player_score( level.teleport_cost );

			// Non-threaded so the trigger doesn't activate before the cooldown
			self player_teleporting( index, user, false );
		}
	}
}

//-------------------------------------------------------------------------------
// handles moving the players and fx, etc...moved out so it can be threaded
//-------------------------------------------------------------------------------
player_teleporting( index, user, first_time )
{
	if(!IsDefined(first_time))
		first_time = false;

	if(!IsDefined(level.times_teleported))
	{
		level.times_teleported = 0;
	}

	if(level.times_teleported <= 3)
	{
		level.times_teleported++;
	}

	times_teleported = level.times_teleported; //save the current amount because the global variable might change

	level.time_since_last_teleport = GetTime() - level.teleport_time;

	// begin the teleport
	// add 3rd person fx
	teleport_pad_start_exploder( index );

	// play startup fx at the core
	exploder( 105 );

	//AUDIO
	if(level.gamemode == "survival" || (level.gamemode != "survival" && !first_time))
	{
		ClientNotify( "tpw" + index );
	}

	// start fps fx
	self thread teleport_pad_player_fx( level.teleport_delay );

	if(level.gamemode == "survival" || (level.gamemode != "survival" && !first_time))
	{
		//AUDIO
		self thread teleport_2d_audio();
	}

	// Activate the TP zombie kill effect
	self thread teleport_nuke( undefined, 300, user);	//range 300

	// wait a bit
	wait( level.teleport_delay );

	self notify( "fx_done" );

	// add 3rd person beam fx
	teleport_pad_end_exploder( index );

	// teleport the players
	self teleport_players(user);

	if(level.gamemode == "survival" || (level.gamemode != "survival" && !first_time))
	{
		//AUDIO
		ClientNotify( "tpc" + index );
	}

	// only need this if it's not cooling down
	if ( level.is_cooldown == false )
	{
		thread pad_manager();
	}

	// Now spawn a powerup goodie after a few seconds
	wait( 2.0 );
	ss = getstruct( "teleporter_powerup", "targetname" );
	is_powerup = false;
	if ( IsDefined( ss ) )
	{
		if(level.round_number < 15 || first_time)
		{
			is_powerup = true;
		}

		if(!is_powerup)
		{
			// starting at round 15, chance of getting a powerup goes down by 5% each round (minimum of 15% chance)
			chance = (level.round_number - 14) * 5;
			if(chance > 85)
			{
				chance = 85;
			}

			is_powerup = RandomInt(100) >= chance;
		}

		// if versus mode, then only spawn powerups once all links are active or else it will try to spawn 3 powerups at the beginning of the match since the teleporters are automatically linked at the beginning of the match
		spawn = true;
		if(level.gamemode != "survival" && times_teleported < 3)
		{
			spawn = false;
		}

		if(spawn)
		{
			ss thread maps\_zombiemode_powerups::special_powerup_drop(ss.origin, is_powerup);
		}
	}

	is_dog = !is_powerup;
	// dogs always spawn in versus modes
	if(level.gamemode != "survival")
	{
		is_dog = !first_time;
	}

	if(is_dog)
	{
		thread play_sound_2d( "sam_nospawn" );
		dog_spawners = GetEntArray( "special_dog_spawner", "targetname" );
		maps\_zombiemode_ai_dogs::special_dog_spawn( undefined, 2 * get_players().size );
	}

	level.teleport_time = GetTime();

	level notify("teleporter_end");
}

//-------------------------------------------------------------------------------
// pad fx for the start of the teleport
//-------------------------------------------------------------------------------
teleport_pad_start_exploder( index )
{
	switch ( index )
	{
	case 0:
		exploder( 202 );
		break;

	case 1:
		exploder( 302 );
		break;

	case 2:
		exploder( 402 );
		break;
	}
}

//-------------------------------------------------------------------------------
// pad fx for the end of the teleport
//-------------------------------------------------------------------------------
teleport_pad_end_exploder( index )
{
	switch ( index )
	{
	case 0:
		exploder( 201 );
		break;

	case 1:
		exploder( 301 );
		break;

	case 2:
		exploder( 401 );
		break;
	}
}

//-------------------------------------------------------------------------------
// used to enable / disable the pad use trigger for players
//-------------------------------------------------------------------------------
teleport_trigger_invisible( enable )
{
	players = getplayers();

	for ( i = 0; i < players.size; i++ )
	{
		if ( isdefined( players[i] ) )
		{
			self SetInvisibleToPlayer( players[i], enable );
		}
	}
}

//-------------------------------------------------------------------------------
// checks if player is within radius of the teleport pad
//-------------------------------------------------------------------------------
player_is_near_pad( player )
{
	radius = 88;
	scale_factor = 2;

	dist = Distance2D( player.origin, self.origin );
	dist_touching = radius * scale_factor;

	if ( dist < dist_touching )
	{
		return true;
	}

	return false;
}


//-------------------------------------------------------------------------------
// this is the 1st person effect seen when touching the teleport pad
//-------------------------------------------------------------------------------
teleport_pad_player_fx( delay )
{
	self endon( "fx_done" );

	while ( 1 )
	{
		players = getplayers();
		for ( i = 0; i < players.size; i++ )
		{
			if ( isdefined( players[i] ) )
			{
				if ( self player_is_near_pad( players[i] ) )
				{
					players[i] SetTransported( delay );
				}
				else
				{
					players[i] SetTransported( 0 );
				}
			}
		}
		wait ( .05 );
	}
}

//-------------------------------------------------------------------------------
// send players back to the core
//-------------------------------------------------------------------------------
teleport_players(user)
{
	level endon("round_restarted");

	player_radius = 16;

	players = getplayers();

	core_pos = [];
	occupied = [];
	image_room = [];
	players_touching = [];		// the players that will actually be teleported

	player_idx = 0;

	prone_offset = (0, 0, 49);
	crouch_offset = (0, 0, 20);
	stand_offset = (0, 0, 0);

	// send players to a black room to flash images for a few seconds
	for ( i = 0; i < 4; i++ )
	{
		core_pos[i] = getent( "origin_teleport_player_" + i, "targetname" );
		occupied[i] = false;
		image_room[i] = getent( "teleport_room_" + i, "targetname" );

		if ( isdefined( players[i] ) )
		{
			players[i] settransported( 0 );

			if ( self player_is_near_pad( players[i] ) )
			{
				players[i] thread cleanup_on_round_restart();

				players_touching[player_idx] = i;
				player_idx++;

				players[i].inteleportation = true;

				if ( isdefined( image_room[i] ) )
				{
					players[i] disableOffhandWeapons();
					players[i] disableweapons();
					if( players[i] getstance() == "prone" )
					{
						desired_origin = image_room[i].origin + prone_offset;
					}
					else if( players[i] getstance() == "crouch" )
					{
						desired_origin = image_room[i].origin + crouch_offset;
					}
					else
					{
						desired_origin = image_room[i].origin + stand_offset;
					}

					players[i].teleport_origin = spawn( "script_origin", players[i].origin );
					players[i].teleport_origin.angles = players[i].angles;
					players[i] linkto( players[i].teleport_origin );
					players[i].teleport_origin.origin = desired_origin;
					players[i] FreezeControls( true );
					wait_network_frame();

					if( IsDefined( players[i] ) )
					{
						setClientSysState( "levelNotify", "black_box_start", players[i] );
						players[i].teleport_origin.angles = image_room[i].angles;
					}
				}
			}
		}
	}

	wait( 2 );

	// Nuke anything at the core
	core = GetEnt( "trigger_teleport_core", "targetname" );
	core thread teleport_nuke( undefined, 300, user);	// Max any zombies at the pad range 300

	// check if any players are standing on top of core teleport positions
	for ( i = 0; i < players.size; i++ )
	{
		if ( isdefined( players[i] ) )
		{
			for ( j = 0; j < 4; j++ )
			{
				if ( !occupied[j] )
				{
					dist = Distance2D( core_pos[j].origin, players[i].origin );
					if ( dist < player_radius )
					{
						occupied[j] = true;
					}
				}
			}
			setClientSysState( "levelNotify", "black_box_end", players[i] );
		}
	}

	wait_network_frame();

	// move players to the core
	for ( i = 0; i < players_touching.size; i++ )
	{
		player_idx = players_touching[i];
		player = players[player_idx];

		if ( !IsDefined( player ) )
		{
			continue;
		}

		// find a free space at the core
		slot = i;
		start = 0;
		while ( occupied[slot] && start < 4 )
		{
			start++;
			slot++;
			if ( slot >= 4 )
			{
				slot = 0;
			}
		}
		occupied[slot] = true;
		pos_name = "origin_teleport_player_" + slot;
		teleport_core_pos = getent( pos_name, "targetname" );

		player unlink();

		assert( IsDefined( player.teleport_origin ) );
		player.teleport_origin delete();
		player.teleport_origin = undefined;

		player enableweapons();
		player enableoffhandweapons();
		player setorigin( core_pos[slot].origin );
		player setplayerangles( core_pos[slot].angles );
		player FreezeControls( false );
		player thread teleport_aftereffects();

		vox_rand = randomintrange(1,100);  //RARE: Sets up rare post-teleport line

		if( vox_rand <= 2 )
		{
			//player teleporter_vo( "vox_tele_sick_rare" );
			//iprintlnbold( "Hey, this is the random teleport sickness line!" );
		}
		else
		{
			//player teleporter_vo( "vox_tele_sick" );
		}

		//player achievement_notify( "DLC3_ZOMBIE_FIVE_TELEPORTS" );

		player.inteleportation = false;
	}

	// play beam fx at the core
	exploder( 106 );
}

cleanup_on_round_restart()
{
	level endon("teleporter_end");

	level waittill( "round_restarted" );

	setClientSysState( "levelNotify", "black_box_end", self );

	self.teleport_origin delete();
	self.teleport_origin = undefined;

	self.inteleportation = false;
}

//-------------------------------------------------------------------------------
// updates the hint string when countdown is started and expired
//-------------------------------------------------------------------------------
teleport_core_hint_update()
{
	self setcursorhint( "HINT_NOICON" );

	while ( 1 )
	{
		// can't use teleporters until power is on
		/*if ( !flag( "power_on" ) )
		{
			self sethintstring( &"ZOMBIE_NEED_POWER" );
		}
		else if ( teleport_pads_are_active() )
		{
			self sethintstring( &"WAW_ZOMBIE_LINK_TPAD" );
		}
		else if ( level.active_links == 0 )
		{
			self sethintstring( &"WAW_ZOMBIE_INACTIVE_TPAD" );
		}*/
		if ( teleport_pads_are_active() )
		{
			self sethintstring( &"REIMAGINED_LINK_TPAD" );
		}
		else
		{
			self sethintstring( "" );
		}

		wait( .05 );
	}
}

//-------------------------------------------------------------------------------
// establishes the link between teleporter pads and the core
//-------------------------------------------------------------------------------
teleport_core_think()
{
	trigger = getent( "trigger_teleport_core", "targetname" );
	if ( isdefined( trigger ) )
	{
		trigger thread teleport_core_hint_update();

		// disable teleporters to power is turned on
		flag_wait( "power_on" );

		/#
			if ( GetDvarInt( #"zombie_cheat" ) >= 6 )
			{
				for ( i = 0; i < level.teleport.size; i++ )
				{
					level.teleport[i] = "timer_on";
				}
			}
        #/

			while ( 1 )
			{
				if ( teleport_pads_are_active() )
				{
					cheat = false;

					/#
						if ( GetDvarInt(#"zombie_cheat") >= 6 )
						{
							cheat = true;
						}
                     #/

				    /*if ( !cheat )
					{
						trigger waittill( "trigger" );
					}*/

					if(level.gamemode == "survival")
					{
						trigger waittill( "trigger" );
					}

					//				trigger teleport_trigger_invisible( true );

					//				iprintlnbold( &"WAW_ZOMBIE_LINK_ACTIVE" );

					// link the activated pads
					for ( i = 0; i < level.teleport.size; i++ )
					{
						if ( isdefined( level.teleport[i] ) )
						{
							if ( level.teleport[i] == "timer_on" )
							{
								level.teleport[i] = "active";
								level.active_links++;
								flag_set( "teleporter_pad_link_"+level.active_links );

								//AUDIO
								ClientNotify( "scd" + i );
								teleport_core_start_exploder( i );

								// check for all teleporters active
								if ( level.active_links == 3 )
								{
									exploder( 101 );

									if(level.gamemode == "survival")
									{
										ClientNotify( "pap1" );	// Pack-A-Punch door on
									}
									else
									{
										level thread delay_clientnotify("pap1"); // needs a delay or it won't work
									}

									teleporter_vo( "linkall", trigger );
//										if( level.round_number <= 7 )
//										{
//											achievement_notify( "DLC3_ZOMBIE_FAST_LINK" );
//										}
									Earthquake( 0.3, 2.0, trigger.origin, 3700 );
								}

								// stop the countdown for the teleport pad
								pad = "trigger_teleport_pad_" + i;
								trigger_pad = getent( pad, "targetname" );
								trigger_pad stop_countdown();
								ClientNotify( "TRs" );	// Stop flashing the receiver map light
								level.active_timer = -1;
							}
						}
					}
				}

				wait( .05 );
			}
	}
}

delay_clientnotify(notify_string)
{
	wait 1;

	ClientNotify(notify_string);
}

stop_countdown()
{
	self notify( "stop_countdown" );
	players = get_players();

	for( i = 0; i < players.size; i++ )
	{
		players[i] notify( "stop_countdown" );
	}
}

//-------------------------------------------------------------------------------
// checks if any of the teleporter pads are counting down
//-------------------------------------------------------------------------------
teleport_pads_are_active()
{
	// have any pads started?
	if ( isdefined( level.teleport ) )
	{
		for ( i = 0; i < level.teleport.size; i++ )
		{
			if ( isdefined( level.teleport[i] ) )
			{
				if ( level.teleport[i] == "timer_on" )
				{
					return true;
				}
			}
		}
	}

	return false;
}

//-------------------------------------------------------------------------------
// starts the exploder for the teleport pad fx
//-------------------------------------------------------------------------------
teleport_core_start_exploder( index )
{
	switch ( index )
	{
	case 0:
		exploder( 102 );
		break;

	case 1:
		exploder( 103 );
		break;

	case 2:
		exploder( 104 );
		break;
	}
}

teleport_2d_audio()
{
	self endon( "fx_done" );

	while ( 1 )
	{
		players = getplayers();

		wait(1.7);

		for ( i = 0; i < players.size; i++ )
		{
			if ( isdefined( players[i] ) )
			{
				if ( self player_is_near_pad( players[i] ) )
				{
					setClientSysState("levelNotify", "t2d", players[i]);
				}
			}
		}
	}
}


// kill anything near the pad
teleport_nuke( max_zombies, range, user )
{
	zombies = getaispeciesarray("axis");

	zombies = get_array_of_closest( self.origin, zombies, undefined, max_zombies, range );

	for (i = 0; i < zombies.size; i++)
	{
		//wait (randomfloatrange(0.2, 0.3));
		if( !IsDefined( zombies[i] ) )
		{
			continue;
		}

		if( is_magic_bullet_shield_enabled( zombies[i] ) )
		{
			continue;
		}

		if( !( zombies[i].isdog ) )
		{
			zombies[i] maps\_zombiemode_spawner::zombie_head_gib();
		}

		zombies[i].trap_death = true;
		zombies[i].no_powerups = true;
		zombies[i] dodamage( zombies[i].health + 1000, zombies[i].origin, user );
		playsoundatposition( "nuked", zombies[i].origin );
	}
}

teleporter_vo( tele_vo_type, location )
{
	if( !isdefined( location ))
	{
		self thread teleporter_vo_play( tele_vo_type, 2 );
	}
	else
	{
		players = get_players();
		for (i = 0; i < players.size; i++)
		{
			if (distance (players[i].origin, location.origin) < 64)
			{
				switch ( tele_vo_type )
				{
					case "linkall":
						players[i] thread teleporter_vo_play( "tele_linkall" );
						break;
					case "countdown":
						players[i] thread teleporter_vo_play( "tele_count", 3 );
						break;
				}
			}
		}
	}
}

teleporter_vo_play( vox_type, pre_wait )
{
	if(!isdefined( pre_wait ))
	{
		pre_wait = 0;
	}
	wait(pre_wait);
	self maps\_zombiemode_audio::create_and_play_dialog( "level", vox_type );
}

play_tele_help_vox()
{
	level endon( "tele_help_end" );

	while(1)
	{
		self waittill("trigger", who);

		if( flag( "power_on" ) )
		{
			who thread teleporter_vo_play( "tele_help" );
			level notify( "tele_help_end" );
		}

		while(IsDefined (who) && (who) IsTouching (self))
		{
			wait(0.1);
		}
	}
}

play_packa_see_vox()
{
	wait(10);

	if( !flag( "teleporter_pad_link_3" ) )
	{
		self waittill("trigger", who);
		who thread teleporter_vo_play( "perk_packa_see" );
	}
}


//
//	This should match the perk_wire_fx_client function
//	waits for the effect to travel along the wire
teleporter_wire_wait( index )
{
	targ = getstruct( "pad_"+index+"_wire" ,"targetname");
	if ( !IsDefined( targ ) )
	{
		return;
	}

	while(isDefined(targ))
	{
		if(isDefined(targ.target))
		{
			target = getstruct(targ.target,"targetname");
			wait( 0.1 );

			targ = target;
		}
		else
		{
			break;
		}
	}
}

// Teleporter Aftereffects
teleport_aftereffects()
{
	if( GetDvar( "factoryAftereffectOverride" ) == "-1" )
	{
		self thread [[ level.teleport_ae_funcs[RandomInt(level.teleport_ae_funcs.size)] ]]();
	}
	else
	{
		self thread [[ level.teleport_ae_funcs[int(GetDvar( "factoryAftereffectOverride" ))] ]]();
	}
}

teleport_aftereffect_shellshock()
{
	println( "*** Explosion Aftereffect***\n" );
	self shellshock( "explosion", 1.25 );
}

teleport_aftereffect_shellshock_electric()
{
	println( "***Electric Aftereffect***\n" );
	self shellshock( "electrocution", 1.25 );
}

// tae indicates to Clientscripts that a teleporter aftereffect should start

teleport_aftereffect_fov()
{
	setClientSysState( "levelNotify", "tae", self );
}

teleport_aftereffect_bw_vision( localClientNum )
{
	setClientSysState( "levelNotify", "tae", self );
}

teleport_aftereffect_red_vision( localClientNum )
{
	setClientSysState( "levelNotify", "tae", self );
}

teleport_aftereffect_flashy_vision( localClientNum )
{
	setClientSysState( "levelNotify", "tae", self );
}

teleport_aftereffect_flare_vision( localClientNum )
{
	setClientSysState( "levelNotify", "tae", self );
}

packa_door_reminder()
{
	while( !flag( "teleporter_pad_link_3" ) )
	{
		rand = randomintrange(4,16);
		self playsound( "packa_door_hitch" );
		wait(rand);
	}
}

dog_blocker_clip()
{
	//DCS: create collision blocker for dog near revive.
	collision = spawn("script_model", (-106, -2294, 216));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 37.2, 0);
	collision Hide();

	// adding clip for barricade glitch
	collision = spawn("script_model", (-1208, -439, 363));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();
}
