#include animscripts\zombie_utility;
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_ambientpackage;
#include maps\_music;
#include maps\_busing;
#include maps\_zombiemode_audio;

//###########################
// Description of Easter Eggs
//###########################

//
//	Easter eggs must be performed in sequence.
//	1) Teleport the Device - throw a black hole bomb at the target to move it.
//		Generator is located at -1606 2686 -193 outside of the base entrance.
//		If successful, the bomb will activate and the generator will be teleported
//		To the top of a building in the storage lander area.  Follow the red power
//		line to the makeshift console.
//	2) Reroute Power - now that the power's on, the terminal at (613 -1366 -147)
//		will turn on (static screen).  Just go up and hit "use" and it will
//		change to the logo screen.
//	3) Syncronized buttons - release security locks by pressing a button at four
//		separate locations at the same time.  Buttons are located near each Perk
//		machine (except Quick Revive) and are only visible during monkey rounds.
//		4 players must push the button within 0.5 seconds of one another.
//	4) Pressure Plate - All players must stand in one area for 120 seconds.
//		Area is the rocket pad (1378 381 -332).  A clock on the wall will appear
//		to show you your progress.
//	5) Lander Words - someone must ride the lander as it's called to spell out the
//		key phrase.  Letters appear only when the lander is called, but someone must
//		be on the lander to grab them.
//		Centrifuge to Storage (L), then back to Centrifuge (U), then Catwalks (N), then back to
//		Storage (A)
//	6) Use all weapons in combination @ the focal point (-18 -1366 -173)
//		Throw a black hole bomb there, then shoot the portal with an upgraded ray gun,
//		an upgraded Thundergun and explode a doll near it before it disappears.
//
init()
{
//	NOTE:  Uncomment this to do Solo testing for the easter egg. (and any section which checks the variable)
//		You will automatically be given a black hole bomb and an upgraded thundergun
//		You still need to hit all four switches, but you're given 35 seconds
//		Step 5: You need to call the lander and then no clip up to the letter
//		On the last step, you only need to use the black hole bomb and thundergun
//xxx	THIS LINE MUST BE COMMENTED OUT WHEN YOU CHECK IN
//	level.sp_egg_testing = 1;

	PreCacheModel( "p_glo_electrical_transformer" );
	PreCacheModel( "p_zom_monitor_csm_screen_on" );
	PreCacheModel( "p_zom_monitor_csm_screen_logo" );
	PreCacheModel( "p_rus_electric_switch_stop" );
	PreCacheModel( "p_rus_clock_lrg" );

	flag_init( "target_teleported" );
	flag_init( "rerouted_power" );
	flag_init( "switches_synced" );
	flag_init( "pressure_sustained" );
	flag_init( "passkey_confirmed" );
	flag_init( "weapons_combined" );

	level.casimir_lights = [];

	// Get the physical letters that will float
	level.lander_letters[ "a" ] = GetEnt( "letter_a", "targetname" );
	level.lander_letters[ "e" ] = GetEnt( "letter_e", "targetname" );
	level.lander_letters[ "h" ] = GetEnt( "letter_h", "targetname" );
	level.lander_letters[ "i" ] = GetEnt( "letter_i", "targetname" );
	level.lander_letters[ "l" ] = GetEnt( "letter_l", "targetname" );
	level.lander_letters[ "m" ] = GetEnt( "letter_m", "targetname" );
	level.lander_letters[ "n" ] = GetEnt( "letter_n", "targetname" );
	level.lander_letters[ "r" ] = GetEnt( "letter_r", "targetname" );
	level.lander_letters[ "s" ] = GetEnt( "letter_s", "targetname" );
	level.lander_letters[ "t" ] = GetEnt( "letter_t", "targetname" );
	level.lander_letters[ "u" ] = GetEnt( "letter_u", "targetname" );
	level.lander_letters[ "y" ] = GetEnt( "letter_y", "targetname" );

	l_pos = GetEnt( "zipline_door_n_pos", "script_noteworthy" );
	level.lander_letters[ "n" ] moveto( level.lander_letters[ "e" ].origin, .5 );
	level.lander_letters[ "a" ] moveto( level.lander_letters[ "i" ].origin, .5 );
	level.lander_letters[ "l" ] moveto( l_pos.origin, .5 );

	keys = GetArrayKeys( level.lander_letters );
	for ( i=0; i<keys.size; i++ )
	{
		level.lander_letters[ keys[i] ] Hide();
	}

/*
	// SP Testing give weapons
	if ( IsDefined( level.sp_egg_testing ) )
	{
		wait( 10 );
		players = GetPlayers();
		players[0] maps\_zombiemode_weap_black_hole_bomb::player_give_black_hole_bomb();
		players[0] GiveWeapon( "thundergun_upgraded_zm" );
		players[0] GiveWeapon( "ray_gun_upgraded_zm" );

// 		// Give reward!
// 		wait(15);
// 		players = GetPlayers();
// 		for ( i=0; i<players.size; i++ )
// 		{
// 			players[i] thread reward_wait();
// 		}
 	}
*/

	if(level.gamemode != "survival")
    {
        return;
    }

	teleport_target_event();	// Teleport the device hub
	reroute_power_event();		// Attempts to activate the Casimir Device
	sync_switch_event();		// Removes Security Lockdown
	pressure_plate_event();		// Increases energy
	lander_passkey_event();		// Activation Password
 	weapon_combo_event();		// Create Event

	level notify( "help_found" );

	monitor = GetEnt( "casimir_monitor", "targetname" );
	monitor SetModel( "p_zom_monitor_csm_screen_off" );
}


//
//
play_easter_egg_audio( alias, sound_ent, text )
{
    if( alias == undefined )
    {
        /#
        IPrintLnBold( text );
        #/
        return;
    }

    sound_ent PlaySound( alias, "sounddone" );
    sound_ent waittill( "sounddone" );
}


//
//	Turn on light effect for Casimir Device
activate_casimir_light( num )
{
	spot = GetStruct( "casimir_light_"+num, "targetname" );

	if ( IsDefined( spot ) )
	{
		light = Spawn( "script_model", spot.origin );
		light SetModel( "tag_origin" );
		light.angles = spot.angles;
		fx = PlayFXOnTag( level._effect["fx_zmb_light_floodlight_bright"], light, "tag_origin" );

		level.casimir_lights[ level.casimir_lights.size ] = light;
	}
}

//#####################################################################
//	Player must throw a Black Hole bomb near the device to be transported
//#####################################################################
teleport_target_event()
{
	teleport_target_start = getstruct( "teleport_target_start", "targetname" );
	teleport_target_spark = getstruct( "teleport_target_spark", "targetname" );

	// Spawn in the thing to be transported
	level.teleport_target = Spawn( "script_model", teleport_target_start.origin );
	level.teleport_target SetModel( "p_glo_electrical_transformer" );
	level.teleport_target.angles = teleport_target_start.angles;
	level.teleport_target PlayLoopSound( "zmb_egg_notifier", 1 );

	teleport_target_spark = Spawn( "script_model", teleport_target_spark.origin );
	teleport_target_spark SetModel( "tag_origin" );
	teleport_target_spark LinkTo( level.teleport_target );
	PlayFXOnTag( level._effect["switch_sparks"], teleport_target_spark, "tag_origin" );

	// Trigger for bomb distance check - lowered the origin so the hit detection pics up all ground levels
	level.teleport_target_trigger = Spawn( "trigger_radius", teleport_target_start.origin + (0,0,-70), 0, 125, 100 );	// flags, radius, height

	// Function override in _zombiemode_weap_black_hole_bomb, make the bomb check to see
	//	if it's in our trigger
	level.black_hole_bomb_loc_check_func = ::bhb_teleport_loc_check;
	flag_wait( "target_teleported" );

	teleport_target_spark Delete();
	level.black_hole_bomb_loc_check_func = undefined;

    level thread play_egg_vox( "vox_ann_egg1_success", "vox_gersh_egg1", 1 );
}


//
//	Black hole bomb valid loc check
bhb_teleport_loc_check( grenade, model, info )
{
	if( IsDefined( level.teleport_target_trigger ) && grenade IsTouching( level.teleport_target_trigger ) )
	{
		model SetClientFlag( level._SCRIPTMOVER_CLIENT_FLAG_BLACKHOLE );
		grenade thread maps\_zombiemode_weap_black_hole_bomb::do_black_hole_bomb_sound( model, info ); // WW: This might not work if it is based on the model
		level thread teleport_target( grenade, model );
		return true;
	}

	return false;
}


//
//	Move the device into position
teleport_target( grenade, model )
{
    level.teleport_target_trigger Delete();
	level.teleport_target_trigger = undefined;

	// move into the vortex
	wait( 1.0 );	// pacing pause

	time = 3.0;
	level.teleport_target MoveTo( grenade.origin + (0,0,50), time, time - 0.05 );
	wait( time );

	// Zap it to the new spot
	teleport_target_end = getstruct( "teleport_target_end", "targetname" );

	// "Teleport" the object to the new location
	level.teleport_target Hide();
	playsoundatposition( "zmb_gersh_teleporter_out", grenade.origin + (0,0,50) );
	wait( 0.5 );
	level.teleport_target.angles = teleport_target_end.angles;
	level.teleport_target MoveTo( teleport_target_end.origin, 0.05 );
	level.teleport_target StopLoopSound( 1 );
	wait( 0.5 );

	level.teleport_target Show();
    PlayFXOnTag( level._effect[ "black_hole_bomb_event_horizon" ], level.teleport_target, "tag_origin" );
    level.teleport_target PlaySound( "zmb_gersh_teleporter_go" );
	wait( 2.0 );

	model Delete();
	flag_set( "target_teleported" );
}



//#####################################################################
//	This event Simply requires players to use the terminal in the Storage area
//	Now that power has been restored, you can use the terminal
//#####################################################################
reroute_power_event()
{
	monitor = GetEnt( "casimir_monitor", "targetname" );
	location = GetStruct( "casimir_monitor_struct", "targetname" );
	monitor PlayLoopSound( "zmb_egg_notifier", 1 );

	monitor SetModel( "p_zom_monitor_csm_screen_on" );
	trig = Spawn( "trigger_radius", location.origin, 0, 32, 60 );
	trig wait_for_use( monitor );
	trig delete();

	flag_set( "rerouted_power" );
	monitor SetModel( "p_zom_monitor_csm_screen_logo" );
	monitor StopLoopSound( 1 );

    level thread play_egg_vox( "vox_ann_egg2_success", "vox_gersh_egg2", 2 );
	level thread activate_casimir_light( 1 );
}


//
//	Wait for a player to hit the use button
wait_for_use( monitor )
{
	while(1)
	{
		self waittill( "trigger", who );

		while( IsPlayer(who) && who IsTouching( self ) )
		{
			if( who UseButtonPressed() )
			{
				flag_set( "rerouted_power" );
				monitor PlaySound( "zmb_comp_activate" );
				return;
			}

			wait(.05);
		}
	}
}


//#####################################################################
//	This event involves requiring the players to press buttons at almost the same time.
//#####################################################################
//	self is level
sync_switch_event()
{
	switches = GetStructArray( "sync_switch_start", "targetname" );
	success = false;
	while ( !flag( "switches_synced" ) )
	{
		// wait for a monkey round
		flag_wait( "monkey_round" );

		array_thread( switches, ::reveal_switch );
		self thread switch_watcher();

		// wait for monkey round end
		level waittill_either( "between_round_over", "switches_synced" );
	}

	level thread play_egg_vox( "vox_ann_egg3_success", "vox_gersh_egg3", 3 );
	level thread activate_casimir_light( 2 );
}

//
//	Reveal switches and then remove them when the round is over
//	self is a switch script_struct
reveal_switch()
{
	button = Spawn( "script_model", self.origin );
	button SetModel( "p_rus_electric_switch_stop" );
	button.angles = self.angles + (0,90,0);	// switch is rotated
	button PlayLoopSound( "zmb_egg_notifier", 1 );

	offset = AnglesToForward(self.angles) * 8;
	time = 1;
	button MoveTo( button.origin + offset, 1 );
	wait( 1 );

	// Make sure the monkey round didn't end during this wait
	if ( flag( "monkey_round" ) )
	{
		trig = Spawn( "trigger_radius", button.origin, 0, 32, 72 );
		trig thread wait_for_sync_use( self );
		level waittill_either( "between_round_over", "switches_synced" );

		trig delete();
	}

    button StopLoopSound( 1 );
	button MoveTo( self.origin, time );
	wait( time );

	button delete();
}


//
//	Wait for the player to hit the use button, a bit of a hacky way to simulate a use
//	self is a trigger
//	ss is the parent script_struct
wait_for_sync_use( ss )
{
	level endon( "between_round_over" );
	level endon( "switches_synced" );

	ss.pressed = 0;
	while(1)
	{
		self waittill( "trigger", who );

		while( IsPlayer(who) && who IsTouching( self ) )
		{
			if( who UseButtonPressed() )
			{
				level notify( "sync_button_pressed" );
				playsoundatposition( "zmb_push_button", ss.origin );
				ss.pressed = 1;
			}

			wait(.05);
		}
	}
}


//
//	Monitor switch uses.  When a button is pressed, start a timer.  If all buttons
//	are pressed within the time limit, then success!
switch_watcher()
{
	level endon( "between_round_over" );

	pressed = 0;	// scope declaration
	switches = GetStructArray( "sync_switch_start", "targetname" );
	while (1)
	{
		level waittill( "sync_button_pressed" );

		//timeout = GetTime() + 500;	// in milliseconds
/*
		if ( IsDefined( level.sp_egg_testing ) )
		{
			timeout += 100000;	// Longer timeout
		}
*/
		//while ( GetTime() < timeout )
		//{
		pressed = 0;
		for ( i=0; i<switches.size; i++ )
		{
			if ( IsDefined( switches[i].pressed ) && switches[i].pressed )
			{
				pressed++;
			}
		}
		// If everyone pressed it in time
		if ( pressed == 4 )
		{
			flag_set( "switches_synced" );

			for ( i=0; i<switches.size; i++ )
		    {
                playsoundatposition( "zmb_misc_activate", switches[i].origin );
			}

			return;
		}
		//	wait( 0.05 );
		//}

		// All buttons were not pressed.  Check pressed if you want to know how many
		//	were pressed this time.
		/*switch( pressed )
		{
		case 1:
		case 2:
		case 3:
			for ( i=0; i<switches.size; i++ )
			{
                playsoundatposition( "zmb_deny", switches[i].origin );
		    }
			break;
		}

		// Reset buttons
		for ( i=0; i<switches.size; i++ )
		{
			switches[i].pressed = 0;
		}*/
	}
}


//###################################################################
//	Players must stay within the designated area for a period of time
//	If one person leaves, the timer will be reset.
//###################################################################
pressure_plate_event()
{
	area = GetStruct( "pressure_pad", "targetname" );
	trig = Spawn( "trigger_radius", area.origin, 0, 300, 100 );
	trig area_timer( 120 );	// Blocking call

	trig Delete();

	level thread play_egg_vox( "vox_ann_egg4_success", "vox_gersh_egg4", 4 );
	level thread activate_casimir_light( 3 );
}


//
//	activate once all people are within the area, stop if anyone leaves
area_timer( time )
{
	// setup the clock
	clock_loc = GetStruct( "pressure_timer", "targetname" );
	clock = Spawn( "script_model", clock_loc.origin );
	clock SetModel( "p_rus_clock_lrg" );
	clock.angles = clock_loc.angles;
	clock PlayLoopSound( "zmb_egg_notifier", 1 );

	timer_hand_angles_init = ( 270, 90, 0 );
	timer_hand = Spawn( "script_model", clock_loc.origin + ( -1, 0, 12 ) );	// manual offset adjustment so it lines up with the center of the clock
	timer_hand SetModel( "t5_weapon_ballistic_knife_blade" );
	timer_hand.angles = timer_hand_angles_init;

	step = 1.0;
	while ( !flag( "pressure_sustained" ) )
	{
		self waittill( "trigger" );

		/*stop_timer = false;
		// check to see if all players are inside
		players = get_players();
		for ( i=0; i<players.size; i++ )
		{
			if ( !players[i] IsTouching( self ) )
			{
				wait( step );
				stop_timer = true;
			}
		}
		if ( stop_timer )
		{
			continue;
		}*/

        self PlaySound( "zmb_pressure_plate_trigger" );

		// Start the countdown
		time_remaining = time;
		timer_hand RotatePitch( 360, time );
		while ( time_remaining )
		{
			stop_timer = true;
			// check to see if all players are inside
			players = get_players();
			for ( i=0; i<players.size; i++ )
			{
				// abort if no one inside
				if ( players[i] IsTouching( self ) )
				{
					stop_timer = false;
					break;
				}
			}
			wait( step );
			if ( stop_timer )
			{
				time_remaining = time;
				timer_hand RotateTo( timer_hand_angles_init, 0.5 );
				timer_hand PlaySound( "zmb_deny" );
				wait( 0.5 );
				break;
			}
			time_remaining -= step;
			timer_hand PlaySound( "zmb_egg_timer_oneshot" );
		}

		// Times up
		if ( time_remaining <= 0 )
		{
			flag_set( "pressure_sustained" );

			// Need an .fx entry for my nuke kluge, but just in case someone is
			//	actually using this field, save it.
			players = get_players();
			temp_fx = undefined;
			if ( IsDefined( players[0].fx ) )
			{
				temp_fx = players[0].fx;
			}

			// DING!  BOOM!
			timer_hand playsound( "zmb_perks_packa_ready" );
			players[0].fx = level.zombie_powerups[ "nuke" ].fx;
			level thread maps\_zombiemode_powerups::nuke_powerup( players[0] );
			clock StopLoopSound( 1 );
			wait( 1.0 );

			// cleanup
			if ( IsDefined( temp_fx ) )
			{
				players[0].fx = temp_fx;
			}
			else
			{
				players[0].fx = undefined;
			}
			clock Delete();
			timer_hand Delete();

			return;
		}
	}
}


//###################################################################
//	Spell out the passkey using lander calls
//
//###################################################################
lander_passkey_event()
{
	flag_init( "letter_acquired" );

	// lander_station1 = base entry, 3 = catwalk, 4 = storage, 5 = centrifuge
	//	(Easier to visualize by drawing a directional graph)
	level.lander_key = [];
	level.lander_key[ "lander_station1" ][ "lander_station3" ] = "s";
	level.lander_key[ "lander_station1" ][ "lander_station4" ] = "i";
	level.lander_key[ "lander_station3" ][ "lander_station1" ] = "y";
	level.lander_key[ "lander_station3" ][ "lander_station4" ] = "e";
	level.lander_key[ "lander_station4" ][ "lander_station1" ] = "m";
	level.lander_key[ "lander_station4" ][ "lander_station3" ] = "h";

	level.lander_key[ "lander_station5" ][ "lander_station1" ] = "l";
	level.lander_key[ "lander_station5" ][ "lander_station3" ] = "l";
	level.lander_key[ "lander_station5" ][ "lander_station4" ] = "l";
	level.lander_key[ "lander_station4" ][ "lander_station5" ] = "u";
	level.lander_key[ "lander_station1" ][ "lander_station5" ] = "n";
	level.lander_key[ "lander_station3" ][ "lander_station5" ] = "a";

	//l

	level.passkey = array( "l", "u", "n", "a" );
	level.passkey_progress = 0;
	level.secret1 = array( "s", "a", "m" );
	level.secret1_progress = 0;
	level.secret2 = array( "h", "y", "e", "n", "a" );
	level.secret2_progress = 0;

	thread lander_monitor();

	flag_wait( "passkey_confirmed" );
	level.lander_audio_ent StopLoopSound( 1 );
    level thread play_egg_vox( "vox_ann_egg5_success", "vox_gersh_egg5", 5 );
	level thread activate_casimir_light( 4 );
    wait(1);
    level.lander_audio_ent Delete();
}


//
//
lander_monitor()
{
	lander = getent( "lander", "targetname" );
	level.lander_audio_ent = Spawn( "script_origin", lander.origin );
	level.lander_audio_ent LinkTo( lander );
	level.lander_audio_ent PlayLoopSound( "zmb_egg_notifier", 1 );

	while ( !flag( "passkey_confirmed" ) )
	{
		level waittill("lander_launched");

		// Display letters and spawn trigger only if called
		//	If used as an escape, no dice
		//if ( lander.called )
		//{
			// Calculate letter
		start = lander.depart_station;
		dest = lander.station;
		letter = level.lander_key[ start ][ dest ];
		model = level.lander_letters[ letter ];
		model Show();
		model PlaySound( "zmb_spawn_powerup" );
		model thread spin_letter();
		model PlayLoopSound( "zmb_spawn_powerup_loop", .5 );

		// Spawn trigger
		trig = Spawn( "trigger_radius", model.origin, 0, 200, 150 );
		trig thread letter_grab( letter, model );
		flag_wait("lander_grounded");

		// No letter taken
		/*if ( !flag( "letter_acquired" ) )
		{
			level.passkey_progress = 0;
			level.secret1_progress = 0;
			level.secret2_progress = 0;
		}
		else*/
		//{
		flag_clear( "letter_acquired" );
		//}
		trig delete();
		model Hide();
		model StopLoopSound( .5 );
		//}
	}
}


// rotate while we're showing
spin_letter()
{
	level endon( "lander_grounded" );
	level endon( "letter_acquired" );

	while (1)
	{
		self RotateYaw( 90, 5 );
		wait( 5 );
	}
}


//
//	Wait for someone to hit the trigger so the letter is taken
letter_grab( letter, model )
{
	level endon("lander_grounded");

	self waittill( "trigger" );

	flag_set( "letter_acquired" );
	playsoundatposition("zmb_powerup_grabbed", model.origin);
	model Hide();

	// Are we there yet?
	if ( letter == level.passkey[ level.passkey_progress ] )
	{
		level.passkey_progress++;
		if ( level.passkey_progress == level.passkey.size )
		{
			flag_set( "passkey_confirmed" );
		}
	}
	else
	{
		level.passkey_progress = 0;
	}

	// Secret word check
	if ( letter == level.secret1[ level.secret1_progress ] )
	{
		level.secret1_progress++;
		if ( level.secret1_progress == level.secret1.size )
		{
			// Don't hit Sam!
//			iPrintLnBold( "That's not very nice!" );	// replace with audio
		}
	}
	else
	{
		level.secret1_progress = 0;
	}

	if ( letter == level.secret2[ level.secret2_progress ] )
	{
		level.secret2_progress++;
		if ( level.secret2_progress == level.secret2.size )
		{
//			iPrintLnBold( "7.3.1.!" );	// replace with audio
		}
	}
	else
	{
		level.secret2_progress = 0;
	}
}


//###################################################################
//
//	Player needs to throw down a black hole bomb near the target spot
//	in the storage area, next to the device (-18 -1366 -173)
//	Then the player needs to shoot an upgraded ray gun, upgraded Thundergun
//	and a doll at it
//###################################################################
weapon_combo_event()
{
	flag_init( "thundergun_hit" );
	flag_init( "doll_hit" );
	flag_init( "bow_hit" );
	flag_init( "ray_gun_hit" );

	// Spawn the target location indicator
	weapon_combo_spot = GetStruct( "weapon_combo_spot", "targetname" );
	focal_point = Spawn( "script_model", weapon_combo_spot.origin );
	focal_point SetModel( "tag_origin" );
	focal_point PlayLoopSound( "zmb_egg_notifier", 1 );
	fx = PlayFXOnTag( level._effect["gersh_spark"], focal_point, "tag_origin" );

	// Now wait for a black hole bomb to be thrown near the target spot.
	level.black_hold_bomb_target_trig	= Spawn( "trigger_radius", weapon_combo_spot.origin, 0, 50, 72 );
	level.black_hole_bomb_loc_check_func = ::bhb_combo_loc_check;
	flag_wait( "weapons_combined" );

	// Success!  Now clean up.
	level.black_hold_bomb_target_trig Delete();
	level.black_hole_bomb_loc_check_func = undefined;
	focal_point Delete();

	for ( i=0; i<level.casimir_lights.size; i++ )
	{
		level.casimir_lights[i] Delete();
	}

	//level thread play_egg_vox( "vox_ann_egg6_success", "vox_gersh_egg6_success", 9 );
}


//
//	See if the bomb hit the target area
bhb_combo_loc_check( grenade, model, info )
{
	if ( IsDefined( level.black_hold_bomb_target_trig ) &&
		 grenade IsTouching( level.black_hold_bomb_target_trig ) )
	{
		trig = Spawn( "trigger_damage", grenade.origin, 0, 15, 72 );
		grenade thread wait_for_combo( trig );
	}

	return false;
}


//
//	Get the weapon combo before the bomb disappears!
//	Attack the portal with an upgraded ray gun, dolls and upgraded thundergun
//	self is the grenade model
//	trig is a trigger_damage centered around the bomb
wait_for_combo( trig )
{
	self endon( "death" );

	self thread kill_trig_on_death( trig );

	weapon_combo_spot = GetStruct( "weapon_combo_spot", "targetname" );
	ray_gun_hit = false;
	doll_hit	= false;
	crossbow_hit = false;

/*
	if ( IsDefined( level.sp_egg_testing ) )	// Comment out before checking in
	{
		ray_gun_hit = true;
		doll_hit	= true;
//		crossbow_hit = true;
	}
*/

	players = get_players();
	array_thread( players, ::thundergun_check, self, trig, weapon_combo_spot );
	array_thread( players, ::ray_gun_check, self, weapon_combo_spot );
	array_thread( players, ::bow_check, self, weapon_combo_spot );
	array_thread( players, ::doll_check, self, weapon_combo_spot );

	while ( 1 )
	{
		/*trig waittill( "damage", amount, attacker, dir, org, mod );

		if ( isDefined( attacker ) )
		{
			if ( mod == "MOD_PROJECTILE_SPLASH" && (attacker GetCurrentWeapon() == "ray_gun_upgraded_zm" ) )
			{
				ray_gun_hit = true;
			}
			else if ( mod == "MOD_GRENADE_SPLASH" )
			{
				if ( amount >= 90000 )	// assume this is a doll explosion
				{
					doll_hit = true;
				}
				else if ( attacker GetCurrentWeapon() == "crossbow_explosive_upgraded_zm" )
				{
					crossbow_hit = true;
				}
			}*/

		wait_network_frame();

		if ( flag( "thundergun_hit" ) && (flag( "ray_gun_hit" ) || flag( "bow_hit" ) || flag( "doll_hit" )) )
		{
			flag_set( "weapons_combined" );
			level thread soul_release( self, trig.origin );
			return;
		}
		//}
	}
}


//
//	Check to see if the player shot the trigger with the thundergun
//	self is a player
thundergun_check( model, trig, weapon_combo_spot )
{
	model endon( "death" );

	while (1)
	{
		self waittill( "weapon_fired" );

		if ( self GetCurrentWeapon() == "thundergun_upgraded_zm" )
		{
			// Player should be near it
			if ( DistanceSquared( self.origin, weapon_combo_spot.origin ) < 90000 )
			{
				// Shoot towards the center of the portal
				vector_to_spot = VectorNormalize( weapon_combo_spot.origin - self GetWeaponMuzzlePoint() );
				vector_player_facing = self GetWeaponForwardDir();
				angle_diff = acos( VectorDot( vector_to_spot, vector_player_facing ) );

				if ( angle_diff <= 10 )
				{
					flag_set( "thundergun_hit" );

					// This triggers the trigger so it can do an evaluation
					//	in case this is the last piece of the weapon puzzle
					//RadiusDamage( trig.origin, 5, 1, 1, self );
				}
			}
		}
	}
}


//TODO
ray_gun_check( model, weapon_combo_spot )
{
	model endon( "death" );

	while (1)
	{
		self waittill( "missile_fire", missile, name );

		if(name != "ray_gun_upgraded_zm")
			continue;

		self thread wait_for_ray_gun_explode( model, weapon_combo_spot );
	}
}

wait_for_ray_gun_explode( model, weapon_combo_spot )
{
	model endon( "death" );

	self waittill( "projectile_impact", weapon_name, position );

	if(DistanceSquared(position, weapon_combo_spot.origin) < 64*64)
	{
		flag_set("ray_gun_hit");
	}
}

//TODO
bow_check( model, weapon_combo_spot )
{
	model endon( "death" );

	while (1)
	{
		self waittill( "missile_fire", missile, name );

		if(name != "crossbow_explosive_upgraded_zm")
			continue;

		self thread wait_for_bow_explode( model, weapon_combo_spot, missile );
	}
}

wait_for_bow_explode( model, weapon_combo_spot, missile )
{
	model endon( "death" );

	missile_origin = missile.origin;
	while(IsDefined(missile))
	{
		missile_origin = missile.origin;
		wait_network_frame();
	}

	if(DistanceSquared(missile_origin, weapon_combo_spot.origin) < 256*256)
	{
		flag_set("bow_hit");
	}
}

doll_check( model, weapon_combo_spot )
{
	model endon( "death" );

	while (1)
	{
		self waittill("grenade_fire", grenade, weapname);

		if(weapname != "zombie_nesting_dolls")
			continue;

		grenade thread wait_for_doll_explode(model, weapon_combo_spot);
	}
}

// self is grenade
wait_for_doll_explode( model, weapon_combo_spot )
{
	model endon( "death" );

	self waittill( "explode", grenade_origin );

	if(DistanceSquared(grenade_origin, weapon_combo_spot.origin) < 256*256)
	{
		flag_set("doll_hit");
	}
}


//
kill_trig_on_death( trig )
{
	self waittill( "death" );

	trig delete();

	if( flag( "thundergun_hit" ) && !flag( "weapons_combined" ) )
	{
	    level thread play_egg_vox( "vox_ann_egg6p1_success", "vox_gersh_egg6_fail2", 7 );
	}
	else if( !flag( "weapons_combined" ) )
	{
	    level thread play_egg_vox( undefined, "vox_gersh_egg6_fail1", 6 );
	}

	flag_clear( "thundergun_hit" );
	flag_clear( "doll_hit" );
	flag_clear( "bow_hit" );
	flag_clear( "ray_gun_hit" );
}


//
// Gersh is freed!!
soul_release( model, origin )
{
	soul = Spawn( "script_model", origin );
	soul SetModel( "tag_origin" );
	soul PlayLoopSound( "zmb_egg_soul" );

	fx = PlayFXOnTag( level._effect["gersh_spark"], soul, "tag_origin" );

	time = 20;

	model waittill( "death" );

	level thread play_egg_vox( "vox_ann_egg6_success", "vox_gersh_egg6_success", 9 );
	level thread wait_for_gersh_vox();

	soul MoveZ( 2500, time, time - 1 );
	wait( time );

	soul Delete();

	wait(2);
	level thread samantha_is_angry();
	//level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["minigun"] );
}

wait_for_gersh_vox()
{
    wait(12.5);

	// Give reward!
	players = GetPlayers();
	for ( i=0; i<players.size; i++ )
	{
		players[i] thread reward_wait();
	}
}


// Don't give them the minigun if they're downed, spectatin or reviving
//	due to weapon switching issues
reward_wait()
{
	while ( !is_player_valid( self ) ||
			( self UseButtonPressed() && self in_revive_trigger() ) )
	{
		wait( 1.0 );
	}

	level thread maps\_zombiemode_powerups::minigun_weapon_powerup( self, 90 );
	level.longer_minigun_reward = true;
	//self thread maps\_zombiemode_powerups::powerup_vo( "insta_kill" );
	//playsoundatposition("zmb_powerup_grabbed", self.origin);
}


play_egg_vox( ann_alias, gersh_alias, plr_num )
{
    if( IsDefined( ann_alias ) )
    {
        level maps\zombie_cosmodrome_amb::play_cosmo_announcer_vox( ann_alias );
    }

    if( IsDefined( gersh_alias ) )
    {
        level maps\zombie_cosmodrome_amb::play_gersh_vox( gersh_alias );
    }

    if( IsDefined( plr_num ) )
    {
        players = get_players();
        rand = RandomIntRange( 0, players.size );

        players[rand] maps\_zombiemode_audio::create_and_play_dialog( "eggs", "gersh_response", undefined, plr_num );
    }
}

samantha_is_angry()
{
    playsoundatposition( "zmb_samantha_earthquake", (0,0,0) );
    playsoundatposition( "zmb_samantha_whispers", (0,0,0) );
    wait(6);
    level clientnotify( "sia" );
    playsoundatposition( "zmb_samantha_scream", (0,0,0) );
}

/*check_for_grenade_throw()
{
	while(1)
	{
		self waittill("grenade_fire", grenade, weapname);

		//if ( weapname != "frag_grenade" )
		//	continue;

		iprintln(weapname);

		if(weapname != "zombie_nesting_dolls")
			continue;

		grenade thread wait_for_grenade_explode( self );
		self thread wait_for_projectile_impact( grenade );
	}
}


// self is player
wait_for_projectile_impact( grenade )
{
	grenade endon( "explode" );

	self waittill( "projectile_impact", weapon_name, position );
	self thread check_for_grenade_damage_on_window( position );
}*/
