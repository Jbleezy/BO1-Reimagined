#include animscripts\zombie_utility;
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_ambientpackage;
#include maps\_music;
#include maps\_busing;
#include maps\_zombiemode_audio;
#include maps\_zombiemode_sidequests;

/*
// Egg descriptions

// STEPS

// -- SHARED -- //
1. Fuse Fun - Find the fuse box with a blown fuse. Retrieve fuse and replace in fuse box.
2. Holy Grenade - Find four power sources and toss a grenade inside each one.

// -- SOLO -- //
3. Bring up the Sub - A lighthouse in the distance flashes Morse code to the players. Code tells the players which way to turn the wheel and
which way to set the EOT. The sound of a lever being moved fills the air right before the ship blows its horn. A submarine surfaces and sounds
its hoen. Solo players jump straight to step 7 after this

// -- COOP -- //
3. Drink Up - Find the bottle of Vodka and free it. One player must melee it so it falls while the second player ctaches the object. Deliver this
to the Russian behind the door.
4. Art Critic - Four portraits can be found in the level which display a place in the level. All four players must each stand in one of the
spots displayed. Once all pressure plates are activated a light house in the distance starts to flash.
5. Musical Chairs - A distant lighthouse flashes a Morse code at the players. The message informs the players to turn the ship wheel and EOT
to a certain angle. When this is complete the ship sounds its horn and a submarine surfaces and responds with another four horn blasts.
The sub's horn blasts tell the players which sounds to activate from the Sound Beacons in the lighthouse.
6. Pure Harmony - A shaft of light stands vertically in the interior of the lighthouse. Each floor has a dial on it which needs to be set to the right numbers.
These numbers can be found on the pieces of Vrill map found around the level. These dials can affect others so the proper way to activate them
is needed.

// -- SHARED -- //
7. Sacrifical Resurrection - With the shaft of light in the center of the lighthouse a player must lure a zombie in to it then use the
human gun to change them back. The human rises up through the shaft of light the player must shoot the human in the air which "kills" it.
Then use the upgraded ballistic knife to resurrct the human. When the human reaches the top of the lighthouse there is a flash of light
before an Artifact falls to the ground. Deliver this Artifact to the group behind the door
8. Damn Machines - The teleporter on the other side of the door is powered up but suddenly powers down. The player must melee the
fuse box to restart the power to it. After that the heroes escape from coast.

*/


init()
{
	// setup flags for the eggs
	level c_flags();

	level c_anims();

	level mic_test();

	// egg control
	level thread c_overseer();

	declare_sidequest("sq");

	declare_sidequest_icon( "sq", "zom_hud_icon_fuse", "zom_hud_icon_fuse" );
	declare_sidequest_icon( "sq", "zom_hud_icon_bottle", "zom_hud_icon_bottle" );
	declare_sidequest_icon(	"sq", "zom_hud_icon_vril", "zom_hud_icon_vril");
}

// -- Flags for egg completion
c_flags()
{
	flag_init( "ffs" );
	flag_init( "ffd" );

	flag_init( "hgs" );
	flag_init( "hg0" );
	flag_init( "hg1" );
	flag_init( "hg2" );
	flag_init( "hg3" );
	flag_init( "hgd" );

	flag_init( "bs" );
	flag_init( "bd" );

	flag_init( "ke" );
	flag_init( "aca" );

	flag_init( "shs" );
	flag_init( "sr" );
	flag_init( "bp" );
	flag_init( "mcs" );

	flag_init( "hn" );
	flag_init( "mm" );

	flag_init( "ss" );
	flag_init( "re" );
	flag_init( "sa" );
	flag_init( "s_s" );

	flag_init( "sdm" );
	flag_init( "dmf" );

}

#using_animtree ( "generic_human" );
c_anims()
{
	level.scr_anim[ "dancer" ][ "breakdown" ] = %ai_zombie_flinger_flail;
	level.scr_anim[ "dancer" ][ "spin" ] = %ai_zombie_dying_back_idle;
}

beat_break( str_anim )
{
	self endon( "death" );
	self endon( "switch" );

	self.ignoreall = true;
	self.ignoreme = true;

	while( IsDefined( self ) && IsAlive( self ) )
	{
		dance_anim = str_anim;
		self SetFlaggedAnimKnobAllRestart( "dance_anim", dance_anim, %body, 1, .1, 1 );
		animscripts\traverse\zombie_shared::wait_anim_length( dance_anim, .02 );
	}
}

mic_test()
{
	PreCacheModel( "p_zom_vril_device" );
	PreCacheModel( "p_zom_vodka_bottle" );
	PreCacheModel( "p_zom_fuse" );
	PreCacheModel( "p_zom_ice_chunk_03" );
	PreCacheModel( "p_zom_minisub" );
	PreCacheShader( "zom_hud_icon_fuse" );
	PreCacheShader( "zom_hud_icon_bottle" );
	PreCacheShader( "zom_hud_icon_vril" );
}

summon_the_shamans()
{
	level.beginning = getstruct( "cheaters_never_prosper", "targetname" );

	rough_note = StrTok( level.beginning.script_parameters, " " );
	balance = StrTok( level.beginning.script_noteworthy, " " );
	level.trials = StrTok( level.beginning.script_waittill, " " );
	level.contact = StrTok( level.beginning.script_string, " " );

	level.mermaid = [];
	level.together_again = [];

	for( i = 0; i < rough_note.size; i++ )
	{
		temp = Int( rough_note[i] );

		level.mermaid = add_to_array( level.mermaid, temp, false );
	}

	for( i = 0; i < balance.size; i++ )
	{
		temp = Int( balance[i] );

		level.together_again = add_to_array( level.together_again, temp, false );
	}

	that_one = GetEnt( "trig_mine", "targetname" );
	that_one SetCursorHint( "HINT_NOICON" );
	that_one SetHintString( "" );
}

// -- Egg control
c_overseer()
{
	wait( 0.2 );

	// wait for all players
	flag_wait( "all_players_connected" );

	/*players = GetPlayers();
	if( players.size > 1 )
	{
		level._e_group = true;
	}
	else
	{
		level._e_group = false;
	}*/
	level._e_group = true;

	level summon_the_shamans();

	level thread knock_on_door();
	level thread engage();
	level thread noisemakers();
	level thread rotary_styles();

	// check to see how many players there are
	players = GetPlayers();

	// -- GLOBAL EGG (happens no matter the amount of players) -- //
	level thread cancer();
	level thread aries();
	level thread pisces(); // Musical Chairs
	level thread leo(); // Sacrificial Resurrection
	level thread capricorn(); // Damn Machines

	if( level._e_group ) // set up coop eggs
	{
		// Drink Up
		level thread virgo();

		// Art Critic
		level thread denlo();

		// Pure Harmony
		level thread libra();

	}

}


// -- TRANSPORTER DOOR -- //

knock_on_door()
{
	if(level.gamemode != "survival")
    {
        return;
    }

	level endon( "scrambled" );

	knock_trig = GetEnt( "e_gargoyle", "targetname" );

	if( !IsDefined( knock_trig ) )
	{
		return;
	}

	flag_wait( "power_on" );

	pneumatic_tube = GetEnt( "trig_deliver", "targetname" );
	pneumatic_tube PlayLoopSound( "zmb_whooooosh_loop", 2 );
	level.egg_sound_ent = GetEnt( "ent_loop_door_sounds", "targetname" );
	knock_trig PlaySound( "zmb_haxorz_suxorz" );

	level thread gargoyle_speaks( knock_trig ); // after power is hit anyone who walks by this will hear the guys behind the door
	level.door_knock_vox_occurring = false;

	while( 1 )
	{
		knock_trig waittill( "damage", i_amt, e_inflictor, vec_direction, vec_point, mod_type );

		if( level.door_knock_vox_occurring )
		{
			wait( 1.0 );
			continue;
		}

		if( is_player_valid( e_inflictor ) && mod_type == level.trials[2] )
		{
			// successful knock

			if( !flag( "ffs" ) )
			{
				level notify("end_door_intro");

				if(IsDefined(knock_trig.introvox))
				{
					knock_trig.introvox = undefined;
					knock_trig StopSounds();
					wait_network_frame();
				}

				level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, 1, 0, undefined );

				flag_set( "ffs" );

				wait( 1.0 ); // This needs to wait the lenght of the sound playing
				continue;
			}

			if( flag( "ffs" ) && !flag( "ffd" ) && !IsDefined( e_inflictor._fuse_acquired ) )
			{
				level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 1 );


				wait( 1.0 ); // This needs to wait the lenght of the sound playing
				continue;
			}
			else if( flag( "ffs" ) && !flag( "ffd" ) && IsDefined( e_inflictor._fuse_acquired ) && e_inflictor._fuse_acquired == 1 )
			{
				level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 1 );


				wait( 1.0 ); // This needs to wait the lenght of the sound playing
				continue;
			}


			if( flag( "ffd" ) && flag( "hgs" ) && !flag( "hgd" ) )
			{
				level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 2 );

				wait( 1.0 ); // This needs to wait the lenght of the sound playing
				continue;
			}

			if( level._e_group ) // CHECK COOP SPECIFIC FLAGS
			{
				if( flag( "ffd" ) && flag( "hgd" ) && !flag( "bs" ) )
				{
					level.egg_sound_ent StopLoopSound( 1.5 );
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, 4, 3, 5, undefined );
					level.egg_sound_ent PlayLoopSound( "zmb_fantastical_worlds_loop", 1.5 );
					flag_set( "bs" );

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bs" ) && !flag( "bd" ) && !is_true( e_inflictor._bottle_acquired ) )
				{
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 3 );


					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}
				else if( flag( "ffd" ) && flag( "hgd" ) && flag( "bs" ) && !flag( "bd" ) && is_true( e_inflictor._bottle_acquired ) )
				{
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 4 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Drink Up You Have It %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Drink Up You Have It %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && !flag( "ke" ) )
				{
					flag_set( "ke" );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Art Critic Start %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Art Critic Start %%%%%%%%%%%%%" );
					}
					#/

					level.egg_sound_ent StopLoopSound( 1.5 );
					level thread delayed_song_loop();
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, 8, 4, 9, undefined );

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && !flag( "aca" ) )
				{
					level.egg_sound_ent StopLoopSound( 1 );
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 5 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Art Critic Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Art Critic Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && flag( "aca" ) && !flag( "mcs" ) )
				{
					level.egg_sound_ent StopLoopSound( 1.5 );
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 6 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Musical Chairs Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Musical Chairs Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && flag( "aca" )
				&& flag( "mcs" ) && !flag( "mm" ) )
				{
					level.egg_sound_ent StopLoopSound( 1.5 );
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 7 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Musician Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Musician Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && flag( "aca" )
				&& flag( "mcs" ) && flag( "mm" ) && !flag( "s_s" ) )
				{
					level.egg_sound_ent StopLoopSound( 1.5 );
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 8 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Sacrifice Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Sacrifice Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && flag( "aca" )
				&& flag( "mcs" ) && flag( "mm" ) && flag( "s_s" ) && !flag( "sdm" ) )
				{
					//flag_set( "sdm" );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Damn Machine Start %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Damn Machine Start %%%%%%%%%%%%%" );
					}
					#/

					level.egg_sound_ent StopLoopSound( 1.5 );
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, 13, 5, 14, undefined );
					level.egg_sound_ent PlayLoopSound( "zmb_fantastical_worlds_loop", 1.5 );

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && flag( "aca" )
				&& flag( "mcs" ) && flag( "mm" ) && flag( "s_s" ) && flag( "sdm" )
				&& !flag( "dmf" ) )
				{
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 9 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Damn Machine Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Damn Machine Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "bd" ) && flag( "aca" )
				&& flag( "mcs" ) && flag( "mm" ) && flag( "s_s" ) && flag( "dmf" ) )
				{
					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Egg Scrambled %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Egg Scrambled %%%%%%%%%%%%%" );
					}
					#/

					level.egg_sound_ent StopLoopSound( 1.5 );
					// level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, 15, 6, undefined, undefined );

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;



					return;
				}

			}
			else // solo flag checks
			{

				if( flag( "ffd" ) && flag( "hgd" ) && !flag( "aca" ) )
				{
					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Bring Up The Sub Start %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Bring Up The Sub Start %%%%%%%%%%%%%" );
					}
					#/

					level.egg_sound_ent StopLoopSound( 1.5 );
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, 4, "3b", 9, undefined );

					flag_set( "aca" );

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "aca" ) && !flag( "mcs" ) )
				{
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 3 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Bring Up The Sub Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Bring Up The Sub Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "mcs" ) && !flag( "ss" ) )
				{
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 8 );
					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Resurrection Sacrifice Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Resurrection Sacrifice Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "mcs" ) && flag( "s_s" )
				&& flag( "sdm" ) && !flag( "dmf" ) )
				{
					level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, undefined, undefined, undefined, 9 );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Damn Machines Active %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Damn Machines Active %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;
				}

				if( flag( "ffd" ) && flag( "hgd" ) && flag( "mcs" ) && flag( "s_s" )
				&& flag( "dmf" ) )
				{
					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( "%%%%%%%%%%%%% Egg Scrambled %%%%%%%%%%%%%" );
						IPrintLn( "%%%%%%%%%%%%% Egg Scrambled %%%%%%%%%%%%%" );
					}
					#/

					wait( 1.0 ); // This needs to wait the lenght of the sound playing
					continue;

					return;
				}

			}

		}

	}

}

force_wait_for_forcefield_looper()
{
    wait(21.5);
    flag_set( "hgs" );
    level.egg_sound_ent PlayLoopSound( "zmb_wizzybizzy_home_loop", 1.5 );
}

delayed_song_loop()
{
    wait(27);
    level.egg_sound_ent PlayLoopSound( "vox_egg_skit_song", 1 );
}

gargoyle_speaks( knock_trig )
{
	level endon( "end_door_intro" );

	// objects
	trig = GetEnt( "trig_start_voices", "targetname" );
	listener = undefined;

	if( !IsDefined( trig ) )
	{
		return;
	}

	trig.spoken_word = 0;
	speak_limit = 3;
	level._end_door_intro = false;
	chr = 0;

	level thread gargoyle_watch_early_door_hit();

	while( !level._end_door_intro )
	{
		trig waittill( "trigger", listener );

		if( is_player_valid( listener ) )
		{
			if( chr >= 3 )
			{
			    chr = 0;
			}
			//level maps\zombie_coast_amb::play_characters_skits_etc( listener, knock_trig, undefined, undefined, undefined, 0 );
			knock_trig.introvox = true;
			knock_trig PlaySound( "vox_chr_" + chr + "_egg_response_0", "sounddone_introvox" );
			knock_trig waittill( "sounddone_introvox" );
			knock_trig.introvox = undefined;

			/#
			if ( GetDvarInt( #"scr_coast_egg_debug" ) )
			{
				IPrintLnBold( "%%%%%%%%%%% Intro Dialogue  %%%%%%%%%%%" );
			}
			#/

			wait( 1.0 );

			trig.spoken_word++;
			chr++;

			if( trig.spoken_word >= speak_limit )
			{
				level notify( "stop_watching_early_knock" );
				while(1)
				{
				    knock_trig waittill( "trigger", knocker );
				    if( is_player_valid( knocker ) )
		            {
			            level._end_door_intro = true;
			            break;
		            }

		        	wait(.05);
				}
			}

		}
	}

	//level notify( "stop_watching_early_knock" );

	//level maps\zombie_coast_amb::play_characters_skits_etc( listener, knock_trig, undefined, 1, 0, undefined );

	//flag_set( "ffs" );
}

// stop the intro dialogue if the player knocks on the gargoyle early
gargoyle_watch_early_door_hit()
{
	level endon( "stop_watching_early_knock" );

	knock_trig = GetEnt( "e_gargoyle", "targetname" );

	hit = false;

	while( !hit )
	{
		knock_trig waittill( "trigger", impatient_player );

		if( is_player_valid( impatient_player ) )
		{
			level._end_door_intro = true;
		}

		/#
		if( GetDvarInt( #"scr_coast_egg_debug" ) )
		{
			PrintLn( "%%%%%%%%%%%%% Intro Interrupted %%%%%%%%%%%%%" );
			IPrintLn( "%%%%%%%%%%%%% Intro Interrupted %%%%%%%%%%%%%" );
		}
		#/
	}


}

// -- INTERACTION OBJECTS -- //
engage()
{
	// wheel
	ship_wheel = GetEnt( "sm_ship_wheel", "targetname" );
	wheel_turn_right = GetEnt( "t_rotate_wheel_right", "targetname" );
	wheel_turn_left = GetEnt( "t_rotate_wheel_left", "targetname" );

	ship_wheel.spot = 0;

	wheel_turn_right thread press_the_button( 1 );
	wheel_turn_left thread press_the_button( 0 );

	// EOT
	right_lever_trigger = GetEnt( "trig_eot_right_switch", "targetname" );
	left_lever_trigger = GetEnt( "trig_eot_left_switch", "targetname" );

	right_lever = GetEnt( right_lever_trigger.target, "targetname" );
	right_lever.spot = 0;
	left_lever = GetEnt( left_lever_trigger.target, "targetname" );
	left_lever.spot = 0;

	right_lever_trigger thread egg_drop_soup();
	left_lever_trigger thread egg_drop_soup();

	level thread eyes_on_the_wall( ship_wheel, right_lever, left_lever );

}

press_the_button( i_direction )
{
	level endon( "shs" );

	self UseTriggerRequireLookAt();
	self SetHintString( "" );
	wheel = GetEnt( self.target, "targetname" );

	flag_wait( "power_on" );

	while( !flag( "shs" ) )
	{
		self waittill( "trigger" );

		if( i_direction == 0 )
		{
			// rotate left (positive)
			wheel RotateRoll( 60, 0.2, 0, 0 );
			wheel PlaySound( "zmb_galactic_rose" );
			wheel waittill( "rotatedone" );
			wheel.spot = wheel.spot - 1;

			if( wheel.spot < 0 )
			{
				wheel.spot = 5;
			}

		}
		else
		{
			// rotate right (negative)
			wheel RotateRoll( -60, 0.2, 0, 0 );
			wheel PlaySound( "zmb_galactic_rose" );
			wheel waittill( "rotatedone" );
			wheel.spot = wheel.spot + 1;

			if( wheel.spot > 5 )
			{
				wheel.spot = 0;
			}

		}
	}
}

egg_drop_soup()
{
	level endon( "shs" );

	self UseTriggerRequireLookAt();
	self SetHintString( "" );
	lever = GetEnt( self.target, "targetname" );

	flag_wait( "power_on" );

	while( !flag( "shs" ) )
	{
		self waittill( "trigger" );

		if( lever.spot == 4 )
		{
			lever RotateRoll( -100, 0.2 );
			lever.spot = 0;
			lever PlaySound( "zmb_transatlantic_rose" );
			lever waittill( "rotatedone" );

		}
		else
		{
			lever RotateRoll( 25, 0.2 );
			lever.spot = lever.spot + 1;
			lever PlaySound( "zmb_transatlantic_rose" );
			lever waittill( "rotatedone" );
		}

	}

}





// -- INTERACTION OBJECTS -- //
// -- FUSE FUN  --//
// -- Power isn't flowing, find a new fuse and fix the fuse box.
cancer()
{
	level thread coast_egg_fuse_controller();
	level thread coast_egg_fuse_box_think();

}

coast_egg_fuse_box_think()
{
	// objects
	fuse_box_trigger = GetEnt( "trig_fuse_replace", "targetname" );
	fuse_box = GetEnt( "ent_fuse_box", "targetname" );

	// until the prefab is in the map for sure
	if( !IsDefined( fuse_box_trigger ) )
	{
		return;
	}

	// setup the use trigger
	fuse_box_trigger SetCursorHint( "HINT_NOICON" );
	fuse_box_trigger SetHintString( "" );
	fuse_box_trigger UseTriggerRequireLookAt();

	if(level.gamemode != "survival")
    {
        return;
    }

	// wait for the start
	flag_wait( "ffs" );

	while( !flag( "ffd" ) )
	{
		fuse_box_trigger waittill( "trigger", who );

		if( IsDefined( who._fuse_acquired ) && who._fuse_acquired == 1 )
		{
			// remove the fuse from the hud
			who._fuse_acquired = undefined;

			if( IsDefined( fuse_box ) )
			{
				spawn_spot = fuse_box GetTagOrigin( "tag_fuse" );
				if( IsDefined( spawn_spot ) )
				{
					fuse_attached = Spawn( "script_model", spawn_spot );
					fuse_attached.angles = fuse_box GetTagAngles( "tag_fuse" );
					fuse_attached SetModel( "p_zom_fuse" );
					fuse_attached PlaySound( "zmb_winepull" );
					level.egg_sound_ent PlaySound( "zmb_craziness_supreme" );
					exploder( 780 ); // spark
				}
			}

			who thread coast_remove_eggs_hud("zom_hud_icon_fuse");

			// spawn model and attach to fuse box model
			fuse_placed = true;

			// set flag for fus fun
			flag_set( "ffd" );

			level thread coast_egg_fuse_starts_holy( who );
		}
		else
		{
			// fail sound
			wait( 0.1 );
		}

	}

	/#
	if ( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		IPrintLnBold( "%%%%%%%%%%%%%%%%%%%%%%%%% Fuse Fun done %%%%%%%%%%%%%%%%%%%%%%%%%" );
	}
	#/

}

coast_egg_fuse_controller()
{
	if(level.gamemode != "survival")
    {
        return;
    }
	
	// objects
	fuse_array = getstructarray( "struct_ep", "targetname" );
	fuse_delivered = undefined;

	// randomize the fuse array
	fuse_array = array_randomize( fuse_array );

	//flag_wait( "ffs" );

	// watch for the fuse to be delivered or lost
	while( !flag( "ffd" ) )
	{
		for( i = 0; i < fuse_array.size; i++ )
		{
			fuse_array[i].object = Spawn( "script_model", fuse_array[i].origin );
			fuse_array[i].object.angles = fuse_array[i].angles;
			fuse_array[i].object SetModel( fuse_array[i].script_parameters );

			fuse_array[i].object.starter = GetEnt( fuse_array[i].target, "targetname" );
			fuse_array[i].object.starter UseTriggerRequireLookAt();
			fuse_array[i].object.starter SetCursorHint( "HINT_NOICON" );
			fuse_array[i].object.starter EnableLinkTo();
			fuse_array[i].object.starter LinkTo( fuse_array[i].object );

			fuse_array[i].object coast_egg_fuse_think();

			fuse_delivered = coast_egg_fuse_lost( "fuse_lost", "ffd" );

			if( IsDefined( fuse_delivered ) && is_true( fuse_delivered ) )
			{
				// end function
				return;
			}
		}

		wait( 1.0 );

	}

	// clean up
	for( i = 0; i < fuse_array.size; i++ )
	{
		if( !IsDefined( fuse_array[i].object.starter ) )
		{
			fuse_array[i].object.starter = GetEnt( fuse_array[i].target, "targetname" );
		}

		fuse_array[i].starter Delete();

		if( IsDefined( fuse_array[i].object ) )
		{
			fuse_array[i].object Delete();
		}
	}

	array_delete( fuse_array );

}

coast_egg_fuse_lost( str_endon, str_waittill )
{
	level endon( str_endon );

	level waittill( str_waittill );

	return true;
}

// -- Runs on each fuse, removing it from the world or setting it up
coast_egg_fuse_think()
{
	// self.starter trigger_on();
	//self trigger_on();
	//self Show();

	// wait for the fuse to be replaced
	fuse_found = false;
	while( !fuse_found )
	{
		self.starter waittill( "trigger", who );

		if( IsDefined( who ) && is_player_valid( who ) )
		{
			who._fuse_acquired = 1;

			who PlaySound( "zmb_grabit_wontyou" );
			who maps\_zombiemode_audio::create_and_play_dialog( "eggs", "coast_response", undefined, 1 );

			// set hud element on the player
			who thread coast_eggs_hud( "zom_hud_icon_fuse", "ffd" );

			who thread coast_egg_clear_fuse_on_death();

			fuse_found = true;
		}
	}

	// remove trigger and model
	self trigger_off();
	self Hide();

}

coast_egg_clear_fuse_on_death()
{
	self endon( "disconnect" );
	level endon( "ffd" );

	level thread coast_egg_clear_fuse_on_disconnect( self );

	self waittill_any( "death", "_zombie_game_over", "spawned_spectator" );

	// clear the setting on the guy
	if( IsDefined( self ) )
	{
		self._fuse_acquired = undefined;
	}

	level notify( "fuse_lost" );
}

coast_egg_clear_fuse_on_disconnect( ent_ply )
{
	level endon( "ffd" );
	level endon( "fuse_lost" );
	ent_ply endon( "death" );


	ent_ply waittill( "disconnect" );

	level notify( "fuse_lost" );
}


// -- FUSE FUN --//


// -- HOLY GRENADE -- //
coast_egg_fuse_starts_holy( ent_player )
{
	knock_trig = GetEnt( "e_gargoyle", "targetname" );

	players = GetPlayers();

	level thread force_wait_for_forcefield_looper();
	level maps\zombie_coast_amb::play_characters_skits_etc( ent_player, knock_trig, 2, 2, 3, undefined );
}

aries()
{
	flag_wait( "hgs" );

	// objects
	enta_made_the_shot_trigger = GetEntArray( "trig_holy_g_damage", "targetname" );
	metal_door = GetEnt( "ent_metal_door", "targetname" );

	/#
	if( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		IPrintLnBold( "Holy Grenade start" );
	}
	#/

	// if the level hasn't been rebuilt yet
	if( !IsDefined( enta_made_the_shot_trigger ) )
	{
		return;
	}

	// door has field spilling out from the sides
	exploder( 770 );

	// thread off each trigger to set a flag when the player has destroyed the source
	for( i = 0; i < enta_made_the_shot_trigger.size; i++ )
	{
		if( level flag_exists( "hg" + i ) )
		{
			enta_made_the_shot_trigger[i] thread coast_egg_power_source_react( "hg" + i );
		}
		else
		{
			PrintLn( "***************************** more triggers than flags set up! *********************************************" );
		}
	}

	// fire off function to watch for all sources to be destroyed
	level thread coast_egg_holy_grenade_watcher();

	flag_wait( "hgd" );

	stop_exploder( 770 );

}

// Runs on each source trigger, reacts once the proper type of damage hits
coast_egg_power_source_react( str_flag )
{
	/#
	Assert( IsDefined( str_flag ) );
	#/

	rtg = getstruct( self.target, "targetname" );
	field = undefined;

	if( IsDefined( rtg ) )
	{
		// fx
		field = Spawn( "script_model", rtg.origin );
		field.angles = rtg.angles;
		field SetModel( "tag_origin" );
		field PlayLoopSound( "zmb_wizzybizzy_loop", 1 );

		PlayFXOnTag( level._effect[ "rtg_field" ], field, "tag_origin" );
	}

	// move damage trigger slightly up, checks explosion more accurately
	self.origin = self.origin + (0, 0, 32);

	// wait for damage
	self._source_damaged = false;
	while( !self._source_damaged )
	{
		self waittill( "damage", i_amount, e_attacker, v_direction, vec_position, i_dmg_type, str_model_name, str_tagname );

		// only grenade damage
		if( is_player_valid( e_attacker ) && ( i_dmg_type == level.trials[0] || i_dmg_type == level.trials[1] || i_dmg_type == "MOD_PROJECTILE" || i_dmg_type == "MOD_PROJECTILE_SPLASH" ) )
		{
			/#
			if( GetDvarInt( #"scr_coast_egg_debug" ) )
			{
				IPrintLnBold( "power source destroyed" );
			}
			#/

			flag_set( str_flag );
			self._source_damaged = true;
			field StopLoopSound( .1 );
			field PlaySound( "zmb_wizzybizzy_explo" );
		}
	}

	// clean up
	if( IsDefined( field ) )
	{
		field Delete();
	}
	self trigger_off();
	self Delete();
}

// waits for all the sources to be destroyed before finishing HG
coast_egg_holy_grenade_watcher()
{
	// wait for all the sources
	flag_wait_all( "hg0", "hg1", "hg2", "hg3" );

	/#
	if ( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		IPrintLnBold( "Holy Grenade done" );
	}
	#/

	flag_set( "hgd" );
}
// -- HOLY GRENADE -- //

// -- COOP EGGS -- //

// -- DRINK UP -- //
virgo()
{
	if(level.gamemode != "survival")
    {
        return;
    }
	
	// objects
	enta_egg_ice_break_trigger = GetEntArray( "trig_egg_break_ice", "targetname" );
	ice_blocks = GetEntArray( "ent_bartender", "targetname" );
	holsters = getstructarray( "struct_that_thing", "targetname" );

	if( !IsDefined( enta_egg_ice_break_trigger ) )
	{
		return;
	}

	if( !IsDefined( ice_blocks ) )
	{
		return;
	}

	if( !IsDefined( holsters ) )
	{
		return;
	}

	// randomize
	holsters = array_randomize( holsters );

	level thread coast_egg_bartender( holsters );

	flag_wait( "bs" );

	// setup the delivery trigger
	level thread coast_egg_bottle_delivered();
}

coast_egg_bartender( structs )
{
	level endon( "bd" );

	while( !flag( "bd" ) )
	{
		for( i = 0; i < structs.size; i++ )
		{
			wait( 0.1 );
			another = structs[i] coast_egg_bottle_think();

			if( IsDefined( another ) && another )
			{
				level waittill_either( "butterfingers", "bd" );

			}
		}

		wait( 0.1 );
		structs = array_randomize( structs );
	}

}


// runs on all the triggers and waits to be activated. if one bottle is successfully returned then all shut down
coast_egg_bottle_think()
{
	/#
	Assert( IsDefined( self.target ) );
	#/

	// endons
	level endon( "bd" );

	// objects
	second_spot = getstruct( self.target, "targetname" );
	dropper = undefined;

	//e_ice_block = GetEnt( self.target, "targetname" );
	//e_ice_block = self;
	e_ice_block = Spawn( "script_model", self.origin );
	e_ice_block.angles = self.angles;
	e_ice_block SetModel( "p_zom_ice_chunk_03" );


	//e_bottle = GetEnt( e_ice_block.target, "targetname" );
	e_bottle = Spawn( "script_model", second_spot.origin );
	e_bottle.angles = second_spot.angles;
	e_bottle SetModel( "p_zom_vodka_bottle" );

	e_icebreaker = Spawn( "trigger_damage", self.origin, 0, 11, 13 ); // org, flags, radius, height
	//e_catch_trig = Spawn( "trigger_radius", e_bottle.origin, 0, 10, 10 );
	e_inflictor = undefined;

	Assert( IsDefined( e_icebreaker ) );
	Assert( IsDefined( e_bottle ) );
	//Assert( IsDefined( e_catch_trig ) );

	// link the trigger to the bottle
	//e_catch_trig EnableLinkTo();
	//e_catch_trig LinkTo( e_bottle );

	e_icebreaker EnableLinkTo();
	e_icebreaker LinkTo( e_ice_block );

	//bottle_end = e_bottle.origin + ( 0, 0, -500 );


	/#
	if ( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		e_bottle thread coast_egg_debug_print3d( "E" );
	}
	#/

	//flag_wait( "bs" );

	ice_solid = true;
	player_caught = undefined;
	while( ice_solid )
	{
		// watch for the trigger to take the right damage from a player
		e_icebreaker waittill( "damage", i_amt, e_inflictor, vec_direction, vec_point, mod_type );

		if( is_player_valid( e_inflictor ) && mod_type == level.trials[2] )
		{
			ice_solid = false;
			player_caught = e_inflictor;
		}
	}

	// play fx, hide ice, remove damage trigger
	e_ice_block Delete();
	e_icebreaker Delete();

	/*// figure out where the bottle falls
	end_point = PhysicsTrace( e_bottle.origin, bottle_end );
	// should figure out the speed here

	/#
	if ( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		e_catch_trig notify( "stop_egg_debug" );

		e_bottle thread coast_egg_debug_print3d( "E" );
	}
	#/

	// move the bottle down
	e_bottle NotSolid();
	e_bottle MoveTo( end_point, 1.4, 0.2, 0 );

	// watch to see if the bottle is caught
	player_caught = e_bottle coast_egg_bottle_caught( e_catch_trig );

	level notify( "stop_egg_debug" );*/

	if( IsDefined( player_caught ) && is_player_valid( player_caught ) )
	{
		/#
		if ( GetDvarInt( #"scr_coast_egg_debug" ) )
		{
			IPrintLnBold( "Bottle Caught" );
		}
		#/

		// display the material on the player's screen that caught it
		player_caught PlaySound( "zmb_worf_speed" );
		player_caught maps\_zombiemode_audio::create_and_play_dialog( "eggs", "coast_response", undefined, 7 );

		player_caught._bottle_acquired = 1;
		player_caught thread coast_egg_clear_bottle_on_death();

		player_caught thread coast_eggs_hud( "zom_hud_icon_bottle", "bd" );

		// clean up the bottle and trigger
		//e_catch_trig Unlink();
		//e_catch_trig Delete();

		e_bottle Hide();
		e_bottle Delete();

		return true;

	}
	else // if the variable is undefined the bottle was not caught
	{
		/#
		if ( GetDvarInt( #"scr_coast_egg_debug" ) )
		{
			IPrintLnBold( "Bottle Break" );
		}
		#/

		if( IsDefined( e_inflictor ) )
		{
		    e_inflictor maps\_zombiemode_audio::create_and_play_dialog( "eggs", "coast_response", undefined, 6 );
		}
		e_bottle PlaySound( "zmb_worf_speed_fail" );

		//e_catch_trig Unlink();
		//e_catch_trig Delete();

		e_bottle Hide();
		e_bottle Delete();

		return false;
	}
}

// returns if bottle is caught, returns undefined if it hit the ground
coast_egg_bottle_caught( e_trigger )
{
	self endon( "movedone" );

	while( IsDefined( e_trigger ) )
	{
		e_trigger waittill( "trigger", who );
		if( is_player_valid( who ) )
		{
			return who;
		}
	}

}

coast_egg_clear_bottle_on_death()
{
	self endon( "disconnect" );
	level endon( "bd" );

	level thread coast_egg_clear_bottle_on_disconnect( self );

	self waittill_any( "death", "_zombie_game_over", "spawned_spectator" );

	// clear the setting on the guy
	if( IsDefined( self ) )
	{
		self._bottle_acquired = undefined;
	}

	level notify( "butterfingers" );
}

coast_egg_clear_bottle_on_disconnect( ent_ply )
{
	level endon( "bd" );
	level endon( "butterfingers" );
	ent_ply endon( "death" );

	ent_ply waittill( "disconnect" );

	level notify( "butterfingers" );
}

// watches that the bottle was delivered
coast_egg_bottle_delivered()
{
	// endon


	// objects
	e_delivery_trigger = GetEnt( "trig_deliver", "targetname" );
	delivery_tube = GetEnt( e_delivery_trigger.target, "targetname" );
	knock_trig = GetEnt( "e_gargoyle", "targetname" );

	if( !IsDefined( e_delivery_trigger ) )
	{
		return;
	}

	// turn on the hint string
	e_delivery_trigger SetHintString( "" );
	player = undefined;

	while( IsDefined( e_delivery_trigger ) )
	{
		e_delivery_trigger waittill( "trigger", who );

		if( IsDefined( who._bottle_acquired ) && who._bottle_acquired == 1 )
		{
			/#
			if ( GetDvarInt( #"scr_coast_egg_debug" ) )
			{
				// player has delivered the object
				IPrintLnBold( "Vodka delivered" );
			}
			#/

			player = who;

			// remove hud material
			who thread coast_remove_eggs_hud("zom_hud_icon_bottle");

			who._bottle_acquired = 0;

			// show object in the chute then move up and away
			if( IsDefined( delivery_tube ) )
			{
				spawn_point = delivery_tube GetTagOrigin( "tag_tube" );
				device = Spawn( "script_model", spawn_point );
				device.angles = delivery_tube GetTagAngles( "tag_tube" );
				device SetModel( "p_zom_vodka_bottle" );
				device PlaySound( "zmb_whooooosh" );

				device MoveZ( 40, 1.0 );
				device waittill( "movedone" );
				device Delete();
			}

			break;
		}

	}

	// done
	flag_set( "bd" );

	flag_set( "ke" );

	level.egg_sound_ent StopLoopSound( 1.5 );
	level thread delayed_song_loop();
	level maps\zombie_coast_amb::play_characters_skits_etc( player, knock_trig, 8, 4, 9, undefined );
}


// remove all the script elements for the bottle
coast_egg_bottle_cleanup()
{
	// objects
	e_bottle = GetEnt( self.target, "targetname" );

	// clean up
	if( IsDefined( e_bottle ) )
	{
		e_bottle Delete();
	}

	self Delete();
}
// -- DRINK UP -- //

// -- ART CRITIC -- //
denlo()
{
	// objects
	radios = GetEntArray( "hello_world", "targetname" );

	for( i = 0; i < radios.size; i++ )
	{
		radios[i] SetCursorHint( "HINT_NOICON" );
		radios[i] SetHintString( "" );
		radios[i] UseTriggerRequireLookAt();

		radios[i] thread coast_egg_art_critic_message();
	}
}

coast_egg_art_critic_message()
{
	level endon( "aca" );

	/#
	Assert( IsDefined( self.script_parameters ) );
	Assert( IsDefined( self.script_string ) );
	#/

	// WW (4-18-11): Issue 82048 - Radios give no feedback and make is difficult for a player to know when they've input a sequence
	self ent_flag_init( "sequence_incorrect" );


	if( !IsDefined( self.script_special ) )
	{
		return;
	}

	if( !IsDefined( self.script_string ) )
	{
		return;
	}

	flag_wait( "power_on" );

	while( !flag( "aca" ) )
	{
		self waittill( "trigger", dj );

		if( is_player_valid( dj ) )
		{

			if( !flag( "ke" ) ) //ent_flag( "sequence_incorrect" )
			{
				self PlaySound( "zmb_radio_morse_static", "sound_done" );
				self waittill("sound_done");
			}

			if( flag( "ke" ) )
			{
				// SOUND: PLAY SOUND FROM STRING
				self PlaySound( self.script_string, "sound_done" );
				self waittill("sound_done");

				// add special to array
				if( !IsDefined( level._reach ) )
				{
					level._reach = [];
				}

				heard = level call_out( self.script_parameters );

				if( IsDefined( heard ) && heard )
				{
					wait( 1.0 );

					flag_set( "aca" );
				}
				else if( IsDefined( heard ) && !heard )
				{
					self PlaySound("zmb_box_move", "sound_done");
					self waittill("sound_done");
				}
			}

		}

	}

}

call_out( str_message )
{
	level endon( "aca" );

	level._reach = add_to_array( level._reach, str_message );

	for( i = 0; i < level._reach.size; i++ )
	{
		if( level._reach[i] != level.contact[i] )
		{
			level._reach = undefined;

			return false;
		}
	}

	if( level._reach.size == level.contact.size )
	{
		return true;
	}
}

// WW (4-18-11): Issue 82048 - Radios give no feedback and make is difficult for a player to know when they've input a sequence
// clears the ent flag after a fixed amount of time on the radios
call_out_wrong_clear()
{
	wait( 4.0 );

	self ent_flag_clear( "sequence_incorrect" );
}


// -- ART CRITIC -- //

// -- MUSICAL CHAIRS -- //
pisces()
{
	flag_wait( "aca" );

	level._serenade = [];

	ClientNotify( "lmc" ); // Lighthouse Morse Code

	level thread metal_horse();

	flag_wait( "bp" );
	flag_set( "mcs" );
}


eyes_on_the_wall( spinner, starboard, port )
{
	Assert( IsDefined( spinner.spot ) );
	Assert( IsDefined( starboard.spot ) );
	Assert( IsDefined( port.spot ) );

	flag_wait( "aca" );

	while( 1 )
	{
		if( spinner.spot == level.mermaid[0] && starboard.spot == level.mermaid[2] && port.spot == level.mermaid[1] )
		{
			playsoundatposition( "zmb_ship_horn_poweron", (-694, -990, 1025 ) );

			flag_set( "shs" );

			/#
			if( GetDvarInt( #"scr_coast_egg_debug" ) )
			{
				PrintLn( " ########################### SHIP HORN SOUNDS ########################### " );
			}
			#/

			// end this function
			// ship horn has sounded, stop the code
			ClientNotify( "slc" ); // stop lighthouse code
			return;

		}

		wait( 0.1 );

	}


}

metal_horse()
{
	horse_struct = getstruct( "struct_thunder", "targetname" );

	flag_wait( "shs" );

	wait( 2.0 );

	horse = Spawn( "script_model", horse_struct.origin );
	horse.angles = horse_struct.angles;
	horse SetModel( "p_zom_minisub" );
	horse NotSolid();

	horse PlaySound( "zmb_forward_march" );
	horse MoveZ( 325, 5.0 );
	horse waittill( "movedone" );

	flag_set( "sr" );

	if( level._e_group )
	{
		while( !flag( "bp" ) )
		{
			// play the sub's song
			for( i = 0; i < level.mermaid.size; i++ )
			{
				sound = "zmb_sub_tone_" + level.mermaid[i];
				horse PlaySound( sound );
				wait( 2.0 );
			}

			level.can_play_beacon_sounds = true;


			// sub blows horn
			/#
			if( GetDvarInt( #"scr_coast_egg_debug" ) )
			{
				PrintLn( " ########################### SUBMARINE HORN SOUNDS ########################### " );

				// wait( 300 ); // allows me to accomplish this on one kit
			}
			#/

			// flag_wait_or_timeout( "bp", 180 );
			song = coast_egg_fuse_lost( "can_not_sing", "bp" );

			if( is_true( song ) )
			{
				//start fx

				break;
			}
			else
			{
				/*horse MoveZ( -325, 5.0 );
				horse waittill( "movedone" );
				flag_clear( "sr" );

				level waittill( "between_round_over" );

				wait( 5.0 );

				horse PlaySound( "zmb_forward_march" );
				horse MoveZ( 325, 10.0 );
				horse waittill( "movedone" );
				flag_set( "sr" );*/

				level.can_play_beacon_sounds = false;
				horse PlaySound( "zmb_forward_march", "sound_done" );
				horse waittill( "sound_done" );
			}
		}
	}
	else
	{
			// play the sub's song
			for( i = 0; i < level.mermaid.size; i++ )
			{
				sound = "zmb_sub_tone_" + level.mermaid[i];
				horse PlaySound( sound );
				wait( 2.0 );
			}

			flag_set( "bp" );
			flag_set( "ss" );
	}

	// light from sub and the light in the lighthouse
	exploder( 750 );

	if( !level._e_group )
	{
		exploder( 755 );
	}

	flag_wait( "re" );

	stop_exploder( 750 );

	horse MoveZ( -325, 2.0 );
	horse waittill( "movedone" );
	horse Delete();

}

noisemakers()
{
	// grab the beacons
	enta_sound_beacon_triggers = GetEntArray( "trig_use_sound_beacon", "targetname" );

	array_thread( enta_sound_beacon_triggers, ::coast_egg_musical_chairs_beach_beacon_used );
}

coast_egg_musical_chairs_beach_beacon_used()
{
	self UseTriggerRequireLookAt();
	self SetHintString( "" );

	level.can_play_beacon_sounds = true;

	while( 1 )
	{
		self waittill( "trigger", who );

		if(!level.can_play_beacon_sounds)
		{
			continue;
		}

		// play the note for the beacon, the string that references what tone should be listed on the object
		// PlaySound( self.script_string );

		// if the sub is up then check this
		if( is_player_valid( who ) )
		{
			if( flag( "power_on" ) )
			{
				// add the note number to serenade
				sound = "zmb_sub_tone_" + self.script_int;
				self PlaySound( sound );
			}


			if( flag( "sr" ) )
			{
				if( !IsDefined( level._serenade ) )
				{
					level._serenade = [];
				}

				/#
				if( GetDvarInt( #"scr_coast_egg_debug" ) )
				{
					PrintLn( " ########################### BEACON " + self.script_int + " ########################### " );
				}
				#/

				level._serenade[ level._serenade.size ] = self.script_int;

				if( coast_egg_musical_check() )
				{
					if( level._serenade.size == level.mermaid.size )
					{
						flag_set( "bp" );
					}
				}
				else
				{
					level notify( "can_not_sing" );
					level._serenade = undefined;
					level._serenade = [];
				}
			}
		}
	}
}

coast_egg_musical_check()
{
	Assert( IsDefined( level._serenade ) );
	Assert( IsDefined( level.mermaid ) );

	for( i = 0; i < level._serenade.size; i++ )
	{
		if( level._serenade[i] != level.mermaid[i] )
		{
			return false;
		}
	}

	return true;

}




// -- MUSICAL CHAIRS -- //


// -- PURE HARMONY -- //

libra()
{
	flag_wait( "mcs" );

	flag_set( "hn" );

	// WW (4-18-11): Issue 82044: Dials pre set before sub light doesn't activate properly
	match = coast_egg_dials_in_harmony();
	if( is_true( match ) )
	{
		flag_set( "mm" );
		exploder( 755 );
	}

	flag_wait( "mm" );

	flag_set( "ss" );

}

rotary_styles()
{
	// objects
	enta_harmony_triggers = GetEntArray( "trig_pure_harmony", "targetname" );

	if( !IsDefined( enta_harmony_triggers ) )
	{
		return;
	}

	level._dials = [];
	level._dials[0] = -1;
	level._dials[1] = -1;
	level._dials[2] = -1;
	level._dials[3] = -1;

	for( i = 0; i < enta_harmony_triggers.size; i++ )
	{
		rand = RandomInt( 9 );
		enta_harmony_triggers[i] coast_egg_dial_setup( rand );
	}

	// run main rotate function
	for( i = 0; i < enta_harmony_triggers.size; i++ )
	{
		enta_harmony_triggers[i] thread coast_egg_dial_think();
	}

}

// -- waits for the trigger to be hit then rotates the dial
coast_egg_dial_setup( int_start_spot )
{
	// objects
	dial = GetEnt( self.target, "targetname" );
	dial.pos = 0;
	dial ent_flag_init( "rotating" );

	level._dials[self.script_special] = dial;
	// level._dials = add_to_array( level._dials, dial, false );

	if( IsDefined( int_start_spot ) )
	{
		for( i = 0; i < int_start_spot; i++ )
		{
			// if the dial is at the right spot stop rotating it
			if( dial.pos == int_start_spot )
			{
				return;
			}
			level coast_egg_dial_rotate( dial ); // rotate dial
		}
	}
}

// -- WW: runs on the trigger and rotates the dial when the trigger is hit
coast_egg_dial_think()
{
	level endon( "mm" );

	// objects
	dial = GetEnt( self.target, "targetname" );
	partners = self.script_vector;

	self SetHintString( "" );
	self SetCursorHint( "HINT_NOICON" );

	/#
	if( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		dial notify( "stop_egg_debug" );
		str_text = "" + dial.pos;
		dial thread coast_egg_debug_print3d( str_text );
	}
	#/

	flag_wait( "power_on" );

	// play sound based on spot
	sound = "zmb_harmonizer_tone_" + dial.pos;

	dial PlayLoopSound( sound );

	while(1)
	{
		self waittill( "trigger", who );

		while( dial ent_flag( "rotating" ) )
		{
			wait( 0.05 );
		}

		if( is_player_valid( who ) )
		{
			level thread coast_egg_dial_rotate( dial ); // rotate dial

			/#
			if( GetDvarInt( #"scr_coast_egg_debug" ) )
			{
				dial notify( "stop_egg_debug" );
				str_text = "" + dial.pos;
				dial thread coast_egg_debug_print3d( str_text );
			}
			#/


			/*if( GetDvarInt( #"scr_coast_egg_debug" ) )
			{
				/#
					IPrintLn( "Testing purpose: Don't turn other dials" );
				#/
			}
			else
			{
				// rotate the others that are influenced
				other_dials = GetEntArray( self.targetname, "targetname" );
				for( i = 0; i < other_dials.size; i++ )
				{
					if( other_dials[i].script_special == partners[0] )
					{
						partner_dial = GetEnt( other_dials[i].target, "targetname" );
						if( IsDefined( partner_dial ) )
						{
							level thread coast_egg_dial_rotate( partner_dial );
						}
						else
						{
							/#
							if( GetDvarInt( #"scr_coast_egg_debug" ) )
							{
								PrintLn( "############################## The partner dial should not be undefined! ###################################" );
							}
							#/
						}

					}
					else if( other_dials[i].script_special == partners[1] )
					{
						partner_dial = GetEnt( other_dials[i].target, "targetname" );
						if( IsDefined( partner_dial ) )
						{
							level thread coast_egg_dial_rotate( partner_dial );
						}
						else
						{
							/#
							if( GetDvarInt( #"scr_coast_egg_debug" ) )
							{
								PrintLn( "############################## The partner dial should not be undefined! ###################################" );
							}
							#/
						}
					}
					else if( other_dials[i].script_special == partners[2] )
					{
						partner_dial = GetEnt( other_dials[i].target, "targetname" );
						if( IsDefined( partner_dial ) )
						{
							level thread coast_egg_dial_rotate( partner_dial );
						}
						else
						{
							/#
							if( GetDvarInt( #"scr_coast_egg_debug" ) )
							{
								PrintLn( "############################## The partner dial should not be undefined! ###################################" );
							}
							#/
						}
					}
				}
			}*/

			// check all the dials to see if they are set to the correct spot
			if( flag( "hn" ) && !flag( "mm" ) ) // WW (4-18-11): Issue 82044: dials preset before the sub light doesn't activate properly
			{
				if( coast_egg_dials_in_harmony() )
				{
					// if you got here then the dials matach the harmony requested
					exploder( 755 );
					flag_set( "mm" );

					/#
					if( GetDvarInt( #"scr_coast_egg_debug" ) )
					{
						PrintLn( " ########################### master_musician ########################### " );
					}
					#/
				}
			}
		}

		wait .05;
	}
}

// -- WW: rotates the dial passed in
coast_egg_dial_rotate( ent_dial )
{
	if( !IsDefined( ent_dial.pos ) )
	{
		ent_dial.pos = 0;
	}

	ent_dial.pos++;
	// the dial turns nine times before getting back to zero
	if( ent_dial.pos > 9 )
	{
		ent_dial.pos = 0;
	}

	// wait for the ent flag to be off before trying to rotate it
	while( ent_dial ent_flag( "rotating" ) )
	{
		wait( 0.1 );
	}

	// set ent flag
	ent_dial ent_flag_set( "rotating" );

	// rotate
	ent_dial RotatePitch( 36, 0.2 );
	ent_dial waittill( "rotatedone" );

	// play sound based on spot
	sound = "zmb_harmonizer_tone_" + ent_dial.pos;


	if( flag( "power_on" ) )
	{
		ent_dial PlayLoopSound( sound );
	}


	/#
	if( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		ent_dial notify( "stop_egg_debug" );
		str_text = "" + ent_dial.pos;
		ent_dial thread coast_egg_debug_print3d( str_text );
	}
	#/

	// clear ent flag
	ent_dial ent_flag_clear( "rotating" );
}


// checks the dials to see if they are set properly
coast_egg_dials_in_harmony()
{
	Assert( IsDefined( level._dials ) );
	Assert( IsDefined( level.together_again ) );

	match = true;

	for( i = 0; i < level.together_again.size; i++ )
	{
		if( level._dials[i].pos != level.together_again[i] )
		{
			match = false;
		}
	}

	return match;
}




// -- PURE HARMONY -- //



// -- SACRIFICAL RESURRECTION -- //
leo()
{
	flag_wait( "ss" );

	level thread coast_egg_sacrifice_spot_start();
	level thread coast_egg_device_delivered();

	flag_wait( "re" );

	/#
	if( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		PrintLn( "############################# VRIL DEVICE GIVEN #############################" );
	}
	#/

	flag_wait( "s_s" );

	/#
	if( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		PrintLn( "############################# SACRIFICIAL RESURRECTION COMPLETE #############################" );
	}
	#/
}


coast_egg_sacrifice_spot_start()
{
	// objects
	level._humangun_escape_override = getstruct( "struct_sacrifice_grabbed_by_light", "targetname" );
	middle_of_the_light = getstruct( "struct_middle_of_light", "targetname" );
	top_of_the_house = getstruct( "struct_top_of_the_house", "targetname" );
	trig_reached_light = GetEnt( "trig_human_into_the_light", "targetname" );
	trig_gotcha = GetEnt( "trig_mine", "targetname" );
	reward = undefined;
	light_mover = undefined;
	who = undefined;
	move_dist = undefined;
	fx_spot = undefined;

	if( !IsDefined( level._humangun_escape_override ) )
	{
		return;
	}

	trig_reached_light PlaySound( "zmb_varoooooom" );
	trig_reached_light PlayLoopSound( "zmb_varoooooom_loop", 3 );

	while( !flag( "re" ) )
	{
		while( !flag( "sa" ) )
		{

			trig_reached_light waittill( "trigger", who );

			if( IsDefined( who ) && IsAlive( who ) && !IsPlayer( who ) && who.animname == "human_zombie" )
			{
				light_mover = Spawn( "script_model", who.origin );
				light_mover.angles = who.angles;
				light_mover SetModel( "tag_origin" );
				who LinkTo( light_mover );

				// anim on the guy
				who.animname = "dancer";
				who thread beat_break( %ai_zombie_flinger_flail );

				light_mover thread watch_for_death( who );
				light_mover thread rotate_while_moving();

				// grab the human and move them in to the light
				who.ignoreme = true;
				who disable_pain();
				who._lighthouse_owned = true;
				who thread magic_bullet_shield(); // make sure this is turned off if anything goes wrong

				// make sure this ai is no longer part of the humangun stuff
				level._zombie_human_array = array_remove( level._zombie_human_array, who );
				who.humangun_zombie_1st_hit_was_upgraded = undefined;
				who clearclientflag( level._ZOMBIE_ACTOR_FLAG_HUMANGUN_HIT_RESPONSE );
				who clearclientflag( level._ZOMBIE_ACTOR_FLAG_HUMANGUN_UPGRADED_HIT_RESPONSE );

				level._humangun_escape_override = undefined;

				// watch the guy
				who thread rising_watch( light_mover );

				// move the guy in to the middle of the light
				light_mover MoveTo( middle_of_the_light.origin, 2.0 );
				light_mover waittill_notify_or_timeout( "movedone", 2.0 );

				if( IsDefined( who ) && IsAlive( who ) )
				{
					// guy has been accepted
					flag_set( "sa" );
				}

				if( !IsDefined( light_mover ) )
				{
					continue;
				}

			}
		}

		// rise in to the air
		if( IsDefined( light_mover ) )
		{
			move_dist = top_of_the_house.origin[2] - middle_of_the_light.origin[2];
			light_mover MoveZ( move_dist, 25 );
			light_mover waittill_notify_or_timeout( "movedone", 25.0 );

			if( !IsDefined( light_mover ) )
			{
				continue;
			}

			light_mover notify( "completed" );

			fx_spot = Spawn( "script_model", light_mover.origin + ( 0, 0, -60 ) );
			fx_spot SetModel( "tag_origin" );

			fx_spot PlaySound( "zmb_northern_lights" );
			PlayFXOnTag( level._effect[ "fx_zmb_coast_sacrifice_flash" ], fx_spot, "tag_origin" );

			fx_spot thread rotate_while_moving();
		}

		// kill the guy and remove the script origin
		if( IsDefined( who ) )
		{
			if( is_true( who._light_accept ) )
			{
				// spawn out the item
				reward = Spawn( "script_model", light_mover.origin );
				reward.angles = light_mover.angles;
				reward SetModel( "p_zom_vril_device" );
				reward PlayLoopSound( "zmb_shimmer_sweetly_loop" );
			}

			who._lighthouse_owned = undefined;
			who thread stop_magic_bullet_shield();
			who Unlink();
			who Hide();
			who DoDamage( who.health + 10, who.origin, who.owner );
		}

		if( IsDefined( light_mover ) )
		{
			if( IsDefined( reward ) )
			{
				reward LinkTo( light_mover );

				// move the object back down
				back_down = ( move_dist - 45 ) * -1;
				light_mover thread rotate_while_moving();
				light_mover MoveZ( back_down, 5.0 );
				light_mover waittill( "movedone" );


				grabbed = false;

				while( !grabbed )
				{
					trig_gotcha waittill( "trigger", grabber );

					if( is_player_valid( grabber ) )
					{
						level thread device_return_from_death( reward.origin );
						grabber thread device_replace_on_death();

						fx_spot notify( "completed" );
						light_mover notify( "completed" );

						fx_spot Delete();

						// place material on this player
						reward StopLoopSound( .1 );
						reward PlaySound( "zmb_tingling_sensation" );
						grabber thread coast_eggs_hud( "zom_hud_icon_vril", "s_s" );

						reward Unlink();
						reward Delete();

						grabber._has_device = true;

						grabber maps\_zombiemode_audio::create_and_play_dialog( "eggs", "coast_response", undefined, 12 );

						grabbed = true;

						level._humangun_escape_override = undefined;

						flag_set( "re" );
						stop_exploder( 755 );
					}
				}

			}
			else
			{
				level._humangun_escape_override = getstruct( "struct_sacrifice_grabbed_by_light", "targetname" ); // make the human come back to the right spot
				flag_clear( "sa" );
			}

			light_mover Delete();
		}

		wait( 0.1 );
	}
}

device_return_from_death( vec_spot )
{
	level endon( "s_s" );

	trig_gotcha = GetEnt( "trig_mine", "targetname" );

	while( !flag( "s_s" ) )
	{
		level waittill( "device_lost" );

		device = Spawn( "script_model", vec_spot );
		device thread rotate_while_moving();
		device SetModel( "p_zom_vril_device" );
		device PlayLoopSound( "zmb_shimmer_sweetly_loop" );

		grabbed = false;
		while( !grabbed )
		{
			trig_gotcha waittill( "trigger", who );

			if( is_player_valid( who ) )
			{
				device notify( "completed" );

				// place material on this player
				device StopLoopSound( .1 );
				device PlaySound( "zmb_tingling_sensation" );
				who thread coast_eggs_hud( "zom_hud_icon_vril", "s_s" );

				device Delete();

				who._has_device = true;

				who maps\_zombiemode_audio::create_and_play_dialog( "eggs", "coast_response", undefined, 12 );

				grabbed = true;
			}
		}

	}

}


watch_for_death( ent_guy )
{
	self endon( "completed" );
	// ent_guy endon( "humangun_zombie_2nd_hit_response" );

	ent_guy waittill( "death" );

	if( IsDefined( ent_guy ) )
	{
		ent_guy Unlink();
	}

	flag_clear( "sa" );
	level._humangun_escape_override = getstruct( "struct_sacrifice_grabbed_by_light", "targetname" );

	self Delete();
}

rotate_while_moving()
{
	self endon( "completed" );

	while( IsDefined( self ) )
	{
		self RotateYaw( 360, 4.0 );
		self waittill( "rotatedone" );
	}

}

device_replace_on_death()
{
	self endon( "disconnect" );
	level endon( "s_s" );

	level thread lost_salvation( self );

	self waittill_any( "death", "_zombie_game_over", "spawned_spectator" );

	// clear the setting on the guy
	if( IsDefined( self ) )
	{
		self._has_device = undefined;
	}

	level notify( "device_lost" );
}


lost_salvation( ent_ply )
{
	level endon( "s_s" );
	ent_ply endon( "death" );

	ent_ply waittill( "disconnect" );

	level notify( "device_lost" );
}


rising_watch( org_mover )
{
	self endon( "death" );
	org_mover endon( "completed" );

	/#
	if( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		self thread coast_egg_debug_print3d( "ALIVE" );
	}
	#/

	players = GetPlayers();
	self.essance = 10000;
	self.maxhealth = self.essance;

	while( self.essance > 0 )
	{
		self waittill( "damage", i_amount, e_inflictor );

		self.essance = self.essance - i_amount;
	}

	// human down
	// change anim
	self notify( "switch" );

	self thread beat_break( %ai_zombie_dying_back_idle );

	self notify( "lighthouse_owned" );

	/#
	if( GetDvarInt( #"scr_coast_egg_debug" ) )
	{
		self notify( "stop_egg_debug" );
		self thread coast_egg_debug_print3d( "DEAD" );
	}
	#/

	self._light_accept = true;

	// done with the guy, just drop out

}

// watch for the device to get there
coast_egg_device_delivered()
{
	delivery_trig = GetEnt( "trig_deliver", "targetname" );
	delivery_tube = GetEnt( delivery_trig.target, "targetname" );
	knock_trig = GetEnt( "e_gargoyle", "targetname" );

	if( !IsDefined( delivery_trig ) )
	{
		return;
	}

	flag_wait( "re" );

	delivered = false;

	while( !delivered )
	{
		delivery_trig waittill( "trigger", shorts_man );

		if( is_player_valid( shorts_man ) && IsDefined( shorts_man._has_device ) && shorts_man._has_device == true )
		{
			// delivered the device
			delivered = true;
			shorts_man._has_device = false;

			shorts_man thread coast_remove_eggs_hud("zom_hud_icon_vril");

			// show object in the chute then move up and away
			if( IsDefined( delivery_tube ) )
			{
				spawn_point = delivery_tube GetTagOrigin( "tag_tube" );
				device = Spawn( "script_model", spawn_point );
				device.angles = delivery_tube GetTagAngles( "tag_tube" );
				device SetModel( "p_zom_vril_device" );
				device PlaySound( "zmb_whooooosh" );

				device MoveZ( 40, 1.0 );
				device waittill( "movedone" );
				device Delete();
			}

			flag_set( "s_s" );

			level.egg_sound_ent StopLoopSound( 1.5 );
			level maps\zombie_coast_amb::play_characters_skits_etc( shorts_man, knock_trig, 13, 5, 14, undefined );
			level.egg_sound_ent PlayLoopSound( "zmb_fantastical_worlds_loop", 1.5 );

			flag_set( "sdm" );
		}
	}

}





// -- SACRIFICAL RESURRECTION -- //

// -- DAMN MACHINES -- //

capricorn()
{
	trig_hit = GetEnt( "trig_fix_tv", "targetname" );
	fuse_box = GetEnt( "ent_fuse_box", "targetname" );
	knock_trig = GetEnt( "e_gargoyle", "targetname" );
	fixed = false;


	if( !IsDefined( trig_hit ) )
	{
		return;
	}

	flag_wait( "sdm" );

	// start sparking effect
	level thread coast_egg_broken_spark( fuse_box );

	while( !fixed )
	{
		trig_hit waittill( "damage", i_amount, e_inflictor, v_direction, v_point, mod_type );

		if( is_player_valid( e_inflictor ) && mod_type == level.trials[2] )
		{
			fuse_box PlaySound( "zmb_wizzybizzy_explo" );
			level.egg_sound_ent PlaySound( "zmb_craziness_supreme" );

			// stop sparking effect
			level notify( "stop_spark" );

			level maps\zombie_coast_amb::play_characters_skits_etc( e_inflictor, knock_trig, 15, 6, undefined, undefined );

			fixed = true;
		}
	}

	flag_set( "dmf" );

	level notify( "scrambled" );

	// SCRIPT: AWARD THE ACHIEVEMENT AND STUFF
	level notify( "coast_easter_egg_achieved" );

	level.upgraded_tesla_reward = true;

	level thread consequences_will_never_be_the_same();

}

coast_egg_broken_spark( fuse_box )
{
	level endon( "stop_spark" );

	while( IsDefined( self ) )
	{
		exploder( 780 ); // spark
		fuse_box PlaySound( "zmb_jumping_jacks" );

		wait( RandomFloatRange( 0.5, 1.2 ) );
	}
}

consequences_will_never_be_the_same()
{
	struct = getstruct( "consequence", "targetname" );

	if( IsDefined( struct ) )
	{
		level thread maps\_zombiemode_powerups::specific_powerup_drop( "tesla", struct.origin );
	}

}

// -- DAMN MACHINES -- //


// WW: hud element for any coast egg item the player needs to know they have
coast_eggs_hud( str_shader, str_endon )
{
	/*self.eggHud = create_simple_hud( self );

	self.eggHud.foreground = true;
	self.eggHud.sort = 2;
	self.eggHud.hidewheninmenu = false;
	self.eggHud.alignX = "center";
	self.eggHud.alignY = "bottom";
	self.eggHud.horzAlign = "user_right";
	self.eggHud.vertAlign = "user_bottom";
	self.eggHud.x = -225;
	self.eggHud.y = 0;

	self.eggHud.alpha = 1;
	self.eggHud setshader( str_shader, 32, 32 );*/

	self add_sidequest_icon("sq", str_shader);

	self thread	coast_eggs_hud_remove_on_death( str_shader, str_endon );

}

// WW: remove the egg hud element
coast_remove_eggs_hud(str_shader)
{
	/*self endon( "death" );

	if( IsDefined( self.eggHud ) )
	{
		self.eggHud Destroy();
	}*/

	self remove_sidequest_icon("sq", str_shader);
}

// WW: removes hud element if player dies
coast_eggs_hud_remove_on_death( str_shader, str_endon )
{
	level endon( str_endon ); // the flag is set when the bottle is delivered

	self waittill_any( "death", "_zombie_game_over", "spawned_spectator" );

	self thread coast_remove_eggs_hud(str_shader);
}

coast_egg_debug_print3d( str_text )
{
	self endon( "stop_egg_debug" );
	self endon( "death" );

	while( IsDefined( self ) )
	{
		Print3d( self.origin, str_text, ( 0.9, 0.9, 0.9 ), 1, 1, 10 );
		wait( 0.5 );
	}

}

coast_egg_play_anim( str_anim, str_notify, str_endon )
{
	self endon( str_endon );
	self endon( "death" );

	while( IsDefined( self ) && IsAlive( self ) )
	{
		time = getAnimLength( str_anim );
		self animscripted( str_notify, self.origin, self.angles, str_anim );
		wait( time );
	}
}
