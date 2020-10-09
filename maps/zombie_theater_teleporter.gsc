#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

//-------------------------------------------------------------------------------
// setup and kick off think functions
//-------------------------------------------------------------------------------
teleporter_init()
{
	level.teleport = [];
	level.teleport_delay = 1.8;
	level.teleport_cost = 0;
	level.teleport_ae_funcs = [];
	level.eeroomsinuse = undefined;

	level.second_hand = GetEnt("zom_clock_second_hand", "targetname");
	level.second_hand_angles = level.second_hand.angles;


	level.zombieTheaterTeleporterSeekLogicFunc = maps\zombie_theater_teleporter::zombieTheaterTeleporterSeekLogic;

	flag_init( "teleporter_linked" );
	flag_init( "core_linked" );

	//wait_for_all_players();

	SetDvar( "theaterAftereffectOverride", "-1" );

	poi1 = getent("teleporter_poi1", "targetname");
	poi2 = getent("teleporter_poi2", "targetname");

	// LDS Treyarch - Added call to the new create_zombie_point_of_interest function so that the poi system is used
	// correctly, attract_dist, num_attractors, added_poi_value, start_turned_on
	poi1 create_zombie_point_of_interest( undefined, 30, 0, false );
	poi2 create_zombie_point_of_interest( 256, 15, 0, false );

	poi1 thread create_zombie_point_of_interest_attractor_positions( 4, 45 );
	poi2 thread create_zombie_point_of_interest_attractor_positions( 4, 45 );

	thread teleport_core_think( 0 );
	thread teleport_link_think();
	thread teleport_pad_think();
	thread theater_fly_me_to_the_moon_init();


	// init pack clock on client
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		setClientSysState( "levelNotify", "pack_clock_start", players[i] );
	}

	/*if( !IsSplitscreen() )
	{
		level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_theater_teleporter::teleport_aftereffect_fov;
	}*/
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_theater_teleporter::teleport_aftereffect_shellshock;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_theater_teleporter::teleport_aftereffect_shellshock_electric;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_theater_teleporter::teleport_aftereffect_bw_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_theater_teleporter::teleport_aftereffect_red_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_theater_teleporter::teleport_aftereffect_flashy_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = maps\zombie_theater_teleporter::teleport_aftereffect_flare_vision;

}

//-------------------------------------------------------------------------------
// handles turning on the pad
//-------------------------------------------------------------------------------
teleport_core_think( index )
{
	trigger_name = "trigger_teleport_pad_" + index;
	active = false;
	user = undefined;

	trigger = getent( trigger_name, "targetname" );

	trigger setcursorhint( "HINT_NOICON" );

	//do the start fx
	teleport_start_exploder(0);

	trigger sethintstring( "" );
	trigger maps\zombie_theater_magic_box::turnLightGreen("teleporter_indicator_light1", true );
	//wait(30);

	core = getent( trigger_name, "targetname" );
	pad = getent( core.target, "targetname" );

	if ( isdefined( trigger ) )
	{
		while ( !active )
		{
			flag_wait( "teleporter_linked" );

			trigger maps\zombie_theater_magic_box::turnLightGreen("teleporter_indicator_light1", true );

			trigger sethintstring( &"ZOMBIE_THEATER_USE_TELEPORTER" );

			trigger waittill( "trigger", user );

			if ( is_player_valid( user ) && user.score >= level.teleport_cost )
			{
				active = true;

				//turn the light red
				trigger maps\zombie_theater_magic_box::turnLightRed("teleporter_indicator_light1", true );

				//trigger hide();
				trigger sethintstring( "" );

				//user maps\_zombiemode_score::minus_to_player_score( level.teleport_cost );

				trigger player_teleporting (index, user);

				//trigger waittill ("teleporter_done");
				if(IsDefined(level.link_cable_on) && IsDefined(level.link_cable_off))
				{
					level.link_cable_on Hide();
					level.link_cable_off Show();
				}

				trigger sethintstring( &"ZOMBIE_TELEPORT_COOLDOWN" );
				wait (90);
				active = false;
				//trigger show();
				//trigger sethintstring( &"ZOMBIE_THEATER_USE_TELEPORTER" );

				flag_clear( "teleporter_linked" );
				flag_clear( "core_linked" );

				//turn the light green
				trigger maps\zombie_theater_magic_box::turnLightGreen("teleporter_indicator_light1", true );

				pad SetHintString( &"REIMAGINED_START_CORE" );
			}
		}
	}
}

//-------------------------------------------------------------------------------
// handles linking the core
//-------------------------------------------------------------------------------
teleport_link_think()
{
	trigger_name = "trigger_teleport_pad_0";
	core = getent( trigger_name, "targetname" );
	user = undefined;

	// wait for link
	while ( 1 )
	{
		if ( !flag( "core_linked" ) )
		{
			if(level.gamemode == "survival")
			{
				core sethintstring( &"ZOMBIE_THEATER_LINK_CORE" );
				core waittill( "trigger", user );
			}

            core PlaySound( "evt_teleporter_activate_start" );

			flag_set( "core_linked" );
			core sethintstring( "" );

			pad = getent( core.target, "targetname" );
			pad sethintstring( &"ZOMBIE_THEATER_LINK_PAD" );
		}
		wait_network_frame();
	}
}

teleport_pad_hide_use()
{
	trigger_name = "trigger_teleport_pad_0";
	core = getent( trigger_name, "targetname" );
	pad = getent( core.target, "targetname" );
	pad setcursorhint( "HINT_NOICON" );

	level.link_cable_off = GetEnt("teleporter_link_cable_off","targetname");
	level.link_cable_on = GetEnt("teleporter_link_cable_on","targetname");
	if(IsDefined(level.link_cable_on))
	{
		level.link_cable_on Hide();
	}

	// ww: pad should work like Der Rise, so it gets the "power on first" hint string
	//pad SetHintString( &"ZOMBIE_NEED_POWER" );
	flag_wait( "power_on" );
	pad SetHintString( &"REIMAGINED_START_CORE" );

}

//-------------------------------------------------------------------------------
// handles linking the pad
//-------------------------------------------------------------------------------
teleport_pad_think()
{
	trigger_name = "trigger_teleport_pad_0";
	core = getent( trigger_name, "targetname" );
	pad = getent( core.target, "targetname" );
	user = undefined;

	while ( 1 )
	{
		if ( !flag( "teleporter_linked" ) && flag( "core_linked" ) )
		{
			if(level.gamemode == "survival")
			{
				pad waittill( "trigger", user );
            	pad PlaySound( "evt_teleporter_activate_finish" );
			}

			pad sethintstring( "" );

			flag_set( "teleporter_linked" );

			if(IsDefined(level.link_cable_on) && IsDefined(level.link_cable_off))
			{
				level.link_cable_off Hide();
				level.link_cable_on Show();
			}
		}
		wait_network_frame();
	}
}

//-------------------------------------------------------------------------------
// starts the exploder for the teleport pad fx
//-------------------------------------------------------------------------------
teleport_start_exploder( index )
{
	switch ( index )
	{
	case 0:
		exploder( 102 );
		break;
	}
}

//-------------------------------------------------------------------------------
// handles moving the players and fx, etc...moved out so it can be threaded
//-------------------------------------------------------------------------------
player_teleporting( index, user )
{
	level endon("round_restarted");

	self thread cleanup_on_round_restart();

	players_in_proj_room = [];

	// begin the teleport
	// add 3rd person fx
	teleport_pad_start_exploder( index );

	// start fps fx
	self thread teleport_pad_player_fx(undefined );

	//AUDIO
	self thread teleport_2d_audio();

	// Activate the TP zombie kill effect
	self thread teleport_nuke( undefined, 300, user);	// Max range 300

	//DCS: fading to Black and White with film grain hud element.
	//get_players()[0] thread film_grain_init();

	// wait a bit
	wait( level.teleport_delay );

	// end fps fx
	self notify( "fx_done" );

	// add 3rd person beam fx - threading this now so it plays the return fx
	self thread teleport_pad_end_exploder(0);

	// teleport the players
	players_in_proj_room = self teleport_players(players_in_proj_room, "projroom");

	if (!IsDefined(players_in_proj_room) || (IsDefined(players_in_proj_room) && players_in_proj_room.size < 1))
	{
		level notify("teleporter_end");
		return;
	}

	//DCS: Add return trigger system here.
	//level thread movie_graveyard_return();
	//level waittill("return_from_graveyard");
	wait(30);

	// DCS: extracam shut down.
	level.extracam_screen Hide();
	clientnotify("camera_stop");

	if ( randomint( 100 ) > 24 && !IsDefined( level.eeroomsinuse ) && level.radio_egg_counter == 2 && level.gamemode == "survival" ) // ww: chaning the frequency to 75%
	{
		loc = "eerooms";
		level.eeroomsinuse = true;

		if( RandomInt( 100 ) > 65  ) // 30% chance a powerup will spawn
		{
			level thread eeroom_powerup_drop();
		}
	}
	else
	{
		loc = "theater";
		exploder (301);
	}

	// start fps fx
	self thread teleport_pad_player_fx( players_in_proj_room );

	self thread teleport_2d_audio_specialroom_start( players_in_proj_room );

	// wait a bit
	wait( level.teleport_delay );

	waited_for_weapon = false;
	while(flag("pack_machine_in_use"))
	{
		wait .05;
		waited_for_weapon = true;
	}

	if(waited_for_weapon)
	{
		vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
		for(i=0;i<vending_weapon_upgrade_trigger.size;i++)
			vending_weapon_upgrade_trigger[i] disable_trigger();
		wait .5;
		for(i=0;i<vending_weapon_upgrade_trigger.size;i++)
			vending_weapon_upgrade_trigger[i] enable_trigger();
	}

	// end fps fx
	self notify( "fx_done" );

	self thread teleport_2d_audio_specialroom_go( players_in_proj_room );
	self teleport_players(players_in_proj_room, loc, user);

	if (IsDefined(loc) && loc == "eerooms")
	{
		//SetSavedDvar( "r_enableFlashlight","1" );

		loc = "theater";

		wait( 4 ); // ww: original tiem was 2.5

		//SetSavedDvar( "r_enableFlashlight","0" );

		self thread teleport_2d_audio_specialroom_start( players_in_proj_room );
		exploder (301);

		// start fps fx
		self thread teleport_pad_player_fx( players_in_proj_room );


		// wait a bit
		wait( level.teleport_delay );

		// end fps fx
		self notify( "fx_done" );

	    self thread teleport_2d_audio_specialroom_go( players_in_proj_room );
		self teleport_players(players_in_proj_room, loc, user);
	}

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
// checks if player is touching the trigger
//-------------------------------------------------------------------------------
player_is_near_pad( player)
{
	if ( player IsTouching (self) )
	{
		return true;
	}

	return false;
}

//-------------------------------------------------------------------------------
// this is the 1st person effect seen when touching the teleport pad
//-------------------------------------------------------------------------------

teleport_pad_player_fx( players )
{
	self endon( "fx_done" );

	inprojroom = false;

	if (!IsDefined(players))
		players = getplayers();
	else
		inprojroom = true;

// DCS: commenting out for integration of code function.


	while ( 1 )
	{
		for ( i = 0; i < players.size; i++ )
		{
			if ( isdefined( players[i] ) )
			{
				if ( self player_is_near_pad( players[i] ) || inprojroom)
				{
					players[i] SetTransported( level.teleport_delay );
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
// send players back to the projection room and then back out into the map
//-------------------------------------------------------------------------------
teleport_players(players_in_proj_room, loc, user)
{
	player_radius = 16;
	dest_room = [];
	all_players = get_players();
	slot = undefined;
	start = undefined;

	level.black_box_start_set = false;

	if (loc == "projroom")
		players = all_players;
	else
		players = players_in_proj_room;

	dest_room = get_array_spots("teleport_room_", dest_room);
	initialize_occupied_flag(dest_room);
	check_for_occupied_spots(dest_room, all_players, player_radius);

	prone_offset = (0, 0, 49);
	crouch_offset = (0, 0, 20);
	stand_offset = (0, 0, 0);

	// send players to a black room to flash images for a few seconds
	for ( i = 0; i < players.size; i++ )
	{
		if ( isdefined( players[i] ) )
		{
			if ( loc == "projroom" && (self player_is_near_pad( players[i]) == false))
				continue;
			else if ( loc == "projroom" && self player_is_near_pad( players[i]) )
				players_in_proj_room = array_add(players_in_proj_room, players[i]);

			// find a free space at the projection room
			slot = i;
			start = 0;
			while ( dest_room[slot].occupied && start < 4 )
			{
				start++;
				slot++;
				if ( slot >= 4 )
				{
					slot = 0;
				}
			}

			dest_room[slot].occupied = true;
			players[i].inteleportation = true;	//shouldn't matter if we set this to true multiple times

			// DCS: commenting out for integration of code function.
			//players[i] settransported( 0 );		// turn off the fps fx in case it was still playing

			players[i] disableOffhandWeapons();
			players[i] disableweapons();

			if( players[i] getstance() == "prone" )
			{
				desired_origin = dest_room[i].origin + prone_offset;
			}
			else if( players[i] getstance() == "crouch" )
			{
				desired_origin = dest_room[i].origin + crouch_offset;
			}
			else
			{
				desired_origin = dest_room[i].origin + stand_offset;
			}


			players[i].teleport_origin = spawn( "script_origin", players[i].origin );
			players[i].teleport_origin.angles = players[i].angles;
			players[i] linkto( players[i].teleport_origin );
			players[i].teleport_origin.origin = desired_origin;

			players[i] FreezeControls( true );
			wait_network_frame();
			setClientSysState( "levelNotify", "black_box_start", players[i] );
			players[i].teleport_origin.angles = dest_room[i].angles;
		}
	}

	level.black_box_start_set = true;

	// everybody left the pad before they actually teleported
	if (!IsDefined(players_in_proj_room) || (IsDefined(players_in_proj_room) && players_in_proj_room.size < 1))
		return;

	wait(2);

	dest_room = [];
	if (loc == "projroom")
	{
		dest_room = get_array_spots("projroom_teleport_player", dest_room);
	}
	else if (loc == "eerooms")
	{
		level.eeroomsinuse = true;
		dest_room = get_array_spots("ee_teleport_player", dest_room);
	}
	else if (loc == "theater")
	{
		if (IsDefined(self.target))
		{
			ent = getent(self.target, "targetname");
			self thread teleport_nuke( undefined, 20, user);
		}
		dest_room = get_array_spots("theater_teleport_player", dest_room);
	}

	initialize_occupied_flag(dest_room);
	check_for_occupied_spots(dest_room, all_players, player_radius);

	for ( i = 0; i < players_in_proj_room.size; i++ )
	{
		slot = randomintrange(0, 4);
		start = 0;
		while ( dest_room[slot].occupied && start < 4 )
		{
			start++;
			slot++;
			if ( slot >= 4 )
			{
				slot = 0;
			}
		}

		dest_room[slot].occupied = true;
		setClientSysState( "levelNotify", "black_box_end", players_in_proj_room[i] );

		// remove script orgin we used in teleporting to black room
		assert( IsDefined( players_in_proj_room[i].teleport_origin ) );
		players_in_proj_room[i].teleport_origin delete();
		players_in_proj_room[i].teleport_origin = undefined;

		players_in_proj_room[i] setorigin( dest_room[slot].origin );
		players_in_proj_room[i] setplayerangles( dest_room[slot].angles );

		if (loc != "eerooms")
		{
			players_in_proj_room[i] enableweapons();
			players_in_proj_room[i] enableoffhandweapons();
			players_in_proj_room[i] FreezeControls( false );

			// DCS: error missing vox?
			//players_in_proj_room[i] thread teleporter_vo_play( "vox_tele_sick", 2 );
		}
		else // in special rooms can now move.
		{
			players_in_proj_room[i] FreezeControls( false );
		}

		setClientSysState("levelNotify", "t2bfx", players_in_proj_room[i]);
		players_in_proj_room[i] teleport_aftereffects();

		if (loc == "projroom")
		{
			//DCS: commented out, now trigger to return.
			// players_in_proj_room[i] thread maps\_zombiemode_timer::start_timer( 31, undefined );
			level.second_hand thread start_wall_clock();
			thread extra_cam_startup();
		}
		else if (loc == "theater")
			players_in_proj_room[i].inteleportation = false;
	}

	if (loc == "projroom")
	{
		return players_in_proj_room;
	}
	else if (loc == "theater")
	{
		level.eeroomsinuse = undefined;
		exploder (302);
	}
}

cleanup_on_round_restart()
{
	level endon("teleporter_end");

	level waittill( "round_restarted" );

	level.eeroomsinuse = undefined;

	self notify( "fx_done" );

	level.extracam_screen Hide();
	clientnotify("camera_stop");

	vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	for(i=0;i<vending_weapon_upgrade_trigger.size;i++)
	{
		vending_weapon_upgrade_trigger[i] enable_trigger();
	}

	flag_waitopen("round_restarting");

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		setClientSysState( "levelNotify", "black_box_end", players[i] );

		if(IsDefined(players[i].teleport_origin))
		{
			players[i].teleport_origin delete();
			players[i].teleport_origin = undefined;
		}

		players[i].inteleportation = false;
	}
}

// DCS: extracam startup.
extra_cam_startup()
{
	// error drawing with teleporter effects, wait to turn on.
	wait(2.0);
	level.extracam_screen Show();

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		setClientSysState( "levelNotify", "camera_start", players[i] );
	}
}

get_array_spots(sname, spots)
{
	for (i = 0; i < 4; i++)
	{
		spots[i] = getent(sname + i, "targetname");
	}

	return spots;
}

initialize_occupied_flag(spots)
{
	for ( i = 0; i < spots.size; i++ )
	{
		spots[i].occupied = false;
	}
}

check_for_occupied_spots(dest, players, player_radius)
{
	for ( i = 0; i < players.size; i++ )
	{
		if ( isdefined( players[i] ) )
		{
			for ( j = 0; j < dest.size; j++ )
			{
				if ( !dest[j].occupied )
				{
					dist = Distance2D( dest[j].origin, players[i].origin );
					if ( dist < player_radius )
					{
						dest[j].occupied = true;
					}
				}
			}
		}
	}
}

teleport_2d_audio()
{
	self endon( "fx_done" );
	clientnotify( "tpa" );

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

teleport_2d_audio_nopad( player )
{
	self endon( "fx_done" );

	for ( i = 0; i < player.size; i++ )
	{
		if ( isdefined( player[i] ) )
		{
			setClientSysState("levelNotify", "t2dn", player[i]);
		}
	}
}

teleport_2d_audio_specialroom_start( player )
{
    self endon( "fx_done" );

	for ( i = 0; i < player.size; i++ )
	{
		if ( isdefined( player[i] ) )
		{
			setClientSysState("levelNotify", "tss", player[i]);
		}
	}
}

teleport_2d_audio_specialroom_go( player )
{
    self endon( "fx_done" );

	for ( i = 0; i < player.size; i++ )
	{
		if ( isdefined( player[i] ) )
		{
			setClientSysState("levelNotify", "tsg", player[i]);
		}
	}
}


//	Kill anything near the teleport
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

// 		if( is_magic_bullet_shield_enabled( zombies[i] ) )
// 		{
// 			continue;
// 		}

		if( isDefined( zombies[i].animname ) &&
			( zombies[i].animname != "boss_zombie" && zombies[i].animname != "ape_zombie" && zombies[i].animname != "zombie_dog" ) &&
			zombies[i].health < 5000)
		{
			zombies[i] maps\_zombiemode_spawner::zombie_head_gib();
		}

		zombies[i].trap_death = true;
		zombies[i].no_powerups = true;
		zombies[i] dodamage( zombies[i].health + 100, zombies[i].origin, user );
		playsoundatposition( "nuked", zombies[i].origin );
	}
}

teleporter_vo_play( vox_type, pre_wait )
{
	if(!isdefined( pre_wait ))
	{
		pre_wait = 0;
	}
	index = maps\_zombiemode_weapons::get_player_index(self);
	plr = "plr_" + index + "_";
	wait(pre_wait);
	self maps\_zombiemode_audio::create_and_play_dialog( plr, vox_type, 0.25 );
}

///////////////////////////////////////////////////
// Aftereffects from teleportation
///////////////////////////////////////////////////

// Teleporter Aftereffects
teleport_aftereffects()
{
	if( GetDvar( #"theaterAftereffectOverride" ) == "-1" )
	{
		self thread [[ level.teleport_ae_funcs[RandomInt(level.teleport_ae_funcs.size)] ]]();
	}
	else
	{
		self thread [[ level.teleport_ae_funcs[int(GetDvar( #"theaterAftereffectOverride" ))] ]]();
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

teleport_aftereffect_fov()
{
	setClientSysState( "levelNotify", "teleport_ae_start", self );
}

teleport_aftereffect_bw_vision( localClientNum )
{
	setClientSysState( "levelNotify", "teleport_ae_start", self );
}

teleport_aftereffect_red_vision( localClientNum )
{
	setClientSysState( "levelNotify", "teleport_ae_start", self );
}

teleport_aftereffect_flashy_vision( localClientNum )
{
	setClientSysState( "levelNotify", "teleport_ae_start", self );
}

teleport_aftereffect_flare_vision( localClientNum )
{
	setClientSysState( "levelNotify", "teleport_ae_start", self );
}

//It was requested that we use the poi functionality to set the "wait" point while all players
//are in the process of teleportation. It should not intefere with the monkey.  The way it should work is, if all players are in teleportation,
//zombies should go and wait at the stage, but if there is a valid player not in teleportation, they should go to him
zombieTheaterTeleporterSeekLogic()
{
	inteleportcount = 0;
	nonteleportinvalidcount = 0;
	poi1 = getent("teleporter_poi1", "targetname");
	poi2 = getent("teleporter_poi2", "targetname");

	players = getplayers();

	for(i=0; i < players.size; i++)
	{
		//JV tally up the total players in teleportation
		if (IsDefined(players[i].inteleportation) && players[i].inteleportation == true)
			inteleportcount++;

		//JV need to count how many players are not valid that are not in teleportation(i.e. laststand)
		if (!is_player_valid( players[i]) && (!IsDefined(players[i].inteleportation) || players[i].inteleportation == false))
			nonteleportinvalidcount++;
	}

	//JV if all the players are in teleportation and there is no poi defined, they should wait in the theater
	if (inteleportcount > 0 && (inteleportcount == players.size || (inteleportcount + nonteleportinvalidcount == players.size)))
	{
		if (!poi1.poi_active && !poi2.poi_active)
		{
			poi1 activate_zombie_point_of_interest();
			poi2 activate_zombie_point_of_interest();
		}

	}
	//JV if there are players not teleporting, zombies should ignore the ones who are and only pick their targets from the ones not
	else if (inteleportcount != players.size)
	{
		if (poi1.poi_active && poi2.poi_active)
		{
			if(isDefined(poi1.attractor_array))
			{
				poi1 deactivate_zombie_point_of_interest();
			}

			if(isDefined(poi2.attractor_array))
			{
				poi2 deactivate_zombie_point_of_interest();
			}
		}

		if (inteleportcount > 0)
		{
			for(i=0; i < players.size; i++)
			{
				if ((IsDefined(players[i].inteleportation) && players[i].inteleportation == true))
					self.ignore_player = array_add(self.ignore_player, players[i]);
			}
		}
	}
}

zombies_goto_position(position)
{
	self endon( "death" );
	self endon( "bad_path" );

	orig_radius = self.goalradius;
	self.ignoreall = true;
	self.goalradius = 128;
	/#
	IPrintLnBold("zombie goal radius ", orig_radius);
	#/
	self SetGoalPos(position.origin + (RandomFloatRange(-40,40), RandomFloatRange(-40,40), 0));

	self waittill( "goal" );
	self.ignoreall = false;
	self.goalradius = orig_radius;

	self OrientMode( "face point", level.extracam_screen.origin );
}
//-------------------------------------------------------------------------------
// DCS: pack a punch wall clock
//-------------------------------------------------------------------------------
start_wall_clock()
{
	// setup second hand start position to 6.
	self RotatePitch( 180, 0.05 );
	self waittill( "rotatedone" );

	// ticking clock movement
	clocktime = 0;
	while(clocktime !=30)
	{
		self RotatePitch( 6, 0.1 );
		wait(1);
		clocktime++;
	}

	// smooth clock movement
	//self RotatePitch( 180, 30 );
	//self waittill( "rotatedone" );

	//wait then reset. failsafe for reset at start as well.
	wait(5.0);
	self RotateTo( level.second_hand_angles, 0.05 );

}
//-------------------------------------------------------------------------------
// Graveyard return
//-------------------------------------------------------------------------------
movie_graveyard_return()
{
	trigger = getent("teleporter_exit_graveyard", "targetname");

	trigger setcursorhint( "HINT_NOICON" );
	trigger sethintstring( &"ZOMBIE_USE_TELEPORTER" , level.teleport_cost);

	if ( isdefined( trigger ) )
	{
		while ( 1 )
		{
			trigger waittill( "trigger", user );

			trigger sethintstring( "" );
			level notify("return_from_graveyard");
			wait (60);
			trigger sethintstring( &"ZOMBIE_USE_TELEPORTER", level.teleport_cost );
		}
	}
}

film_grain_init()
{

	grain = newClientHudElem( self );
	grain.x = 0;
	grain.y = 0;
	grain.alignX = "left";
	grain.alignY = "top";
	grain.horzAlign = "fullscreen";
	grain.vertAlign = "fullscreen";
	grain.foreground = true;
	grain setshader ("ac130_overlay_grain", 640, 480);
	grain.alpha = 0.5;

	VisionSetNaked( "cheat_bw", 0.5 );
	level waittill("return_from_graveyard");
	VisionSetNaked( "default", 0 );
	grain Destroy();

}


//-------------------------------------------------------------------------------
// ww: random power up drop for the eerooms
// currently set at 30% chance it will drop
//-------------------------------------------------------------------------------
eeroom_powerup_drop()
{
	struct_array = getstructarray( "struct_random_powerup_post_teleport", "targetname" );

	powerup_array = [];
	powerup_array[ powerup_array.size ] = "nuke";
	powerup_array[ powerup_array.size ] = "insta_kill";
	powerup_array[ powerup_array.size ] = "double_points";
	powerup_array[ powerup_array.size ] = "carpenter";
	powerup_array[ powerup_array.size ] = "fire_sale";
	powerup_array[ powerup_array.size ] = "full_ammo";
	powerup_array[ powerup_array.size ] = "minigun";

	// randomize
	struct_array = array_randomize( struct_array );
	powerup_array = array_randomize( powerup_array );


	level thread maps\_zombiemode_powerups::specific_powerup_drop( powerup_array[0], struct_array[0].origin );
}

theater_fly_me_to_the_moon_init()
{
	funny_trigger = GetEnt( "trigger_jump", "targetname" );
	to_the_moon_alice_trigger = GetEnt( "trigger_fly_me_to_the_moon", "targetname" );

	funny_trigger thread theater_player_jumps();

	to_the_moon_alice_trigger thread theater_fly_me_to_the_moon();
}

theater_player_jumps()
{
	while( IsDefined( self ) )
	{
		self waittill( "trigger", who );

		if( !IsDefined( who._moon_jumps ) )
		{
			who._moon_jumps = 0;
		}

		self trigger_thread( who, ::theater_moon_jumps, ::theater_moon_jumps_clear );

	}

}

theater_moon_jumps( guy, str_endon )
{
	self endon( str_endon );

	while( true )
	{
		if( guy JumpButtonPressed() )
		{
			guy._moon_jumps = guy._moon_jumps + 1;
			wait( 0.9 );
		}

		wait( 0.1 );
	}
}

theater_moon_jumps_clear( guy )
{
	if( guy._moon_jumps < 5 )
	{
		guy._moon_jumps = 0;
	}

}

theater_fly_me_to_the_moon()
{
	self SetHintString( "" );
	self SetCursorHint( "HINT_NOICON" );

	while( IsDefined( self ) )
	{
		self waittill( "trigger", who );

		if( !IsDefined( who._moon_jumps )
				|| who._moon_jumps < 5 )
		{
			wait( 0.1 );
			continue;
		}

		if( IsDefined( who._moon_jumps ) && who._moon_jumps >= 5 )
		{
			level theater_moon_jump_go();

			who._moon_jumps = 0;
		}
	}
}

theater_moon_jump_go()
{
	ship = GetEnt( "model_zombie_rocket", "targetname" );
	blast_off_fx = level._effect["fx_mp_pipe_steam"];
	ship_base_origin = ship.origin;
	ship.fx_spot = Spawn( "script_model", ship.origin + ( 0, 0, -19 ) );
	ship.fx_spot SetModel( "tag_origin" );
	ship.fx_spot.angles = ( 90, 0, 0 );
	ship.fx_spot LinkTo( ship );
	wait( 0.1 );

	PlayFXOnTag( blast_off_fx, ship.fx_spot, "tag_origin" );

	ship MoveZ( 120, 3.0, 0.7, 0 );
	ship waittill( "movedone" );

	// clean up
	ship.fx_spot Unlink();
	ship.fx_spot Delete();

	ship Hide();
	ship MoveTo( ship_base_origin, 0.1 );
	ship waittill( "movedone" );
	ship Show();

}
