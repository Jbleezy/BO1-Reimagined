// For the  black hole bomb
#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

init()
{
	if( !black_hole_bomb_exists() )
	{
		return;
	}

	// setup the anims // this needs to run before _load
	level black_hole_bomb_anim_init();

	// ww: black hole bomb effect
	level._effect[ "black_hole_bomb_portal" ]						= LoadFX( "maps/zombie/fx_zmb_blackhole_looping" );
	level._effect[ "black_hole_bomb_portal_exit" ]			= LoadFX( "maps/zombie/fx_zmb_blackhole_exit" );
	level._effect[ "black_hole_bomb_zombie_soul" ]			= LoadFX( "maps/zombie/fx_zmb_blackhole_zombie_death" );
	level._effect[ "black_hole_bomb_zombie_destroy" ]		= LoadFX( "maps/zombie/fx_zmb_blackhole_zombie_flare" );
	level._effect[ "black_hole_bomb_zombie_gib" ]				= LoadFX( "maps/zombie/fx_zombie_dog_explosion" );
	level._effect[ "black_hole_bomb_event_horizon" ] 		= LoadFX( "maps/zombie/fx_zmb_blackhole_implode" );
	level._effect[ "black_hole_samantha_steal" ] 				= LoadFX( "maps/zombie/fx_zmb_blackhole_trap_end" );
	level._effect[ "black_hole_bomb_zombie_pull" ]			= LoadFX( "maps/zombie/fx_blackhole_zombie_breakup" );
	level._effect[ "black_hole_bomb_marker_flare" ] 		= LoadFX( "maps/zombie/fx_zmb_blackhole_flare_marker" );

	// black hole bomb model
	PreCacheModel( "t5_bh_bomb_world" );

/#
	level.zombiemode_devgui_black_hole_bomb_give = ::player_give_black_hole_bomb;
#/

	// client flags
	level._SCRIPTMOVER_CLIENT_FLAG_BLACKHOLE = 10;
	level._ACTOR_CLIENT_FLAG_BLACKHOLE = 10;

	// override for animscript death
	level.zombie_death_animscript_override = ::black_hole_bomb_corpse_hide;

	// ww: setup the initial_attract_func and arrival_attract_func overrides
	level.black_hole_bomb_poi_initial_attract_func = ::black_hole_bomb_initial_attract_func;
	level.black_hole_bomb_poi_arrival_attract_func = ::black_hole_bomb_arrival_attract_func;

	level._black_hole_bomb_zombies_anim_change = []; // array needed for anim change throttling
	flag_init( "bhb_anim_change_allowed" ); // flag to control when ai can add themselves to the array
	level thread black_hole_bomb_throttle_anim_changes(); // throttling function
	flag_set( "bhb_anim_change_allowed" );
}

player_give_black_hole_bomb()
{
	self giveweapon( "zombie_black_hole_bomb" );
	self set_player_tactical_grenade( "zombie_black_hole_bomb" );
	self thread player_handle_black_hole_bomb();
}

#using_animtree( "zombie_cymbal_monkey" ); // WW: A new animtree or should we just use generic human's throw?
player_handle_black_hole_bomb()
{
	//self notify( "starting_black_hole_bomb" );
	self endon( "disconnect" );
	//self endon( "starting_black_hole_bomb" );

	// Min distance to attract positions
	attract_dist_diff = level.black_hole_attract_dist_diff;
	if( !isDefined( attract_dist_diff ) )
	{
		attract_dist_diff = 10;
	}

	num_attractors = level.num_black_hole_bomb_attractors;
	if( !isDefined( num_attractors ) )
	{
		num_attractors = 15; // WW: not using attractors!
	}

	max_attract_dist = level.black_hole_bomb_attract_dist;
	if( !isDefined( max_attract_dist ) )
	{
		max_attract_dist = 2056; // WW: controls the pull distance
	}

	grenade = get_thrown_black_hole_bomb();

	self thread player_handle_black_hole_bomb();

	if( IsDefined( grenade ) )
	{
		if( self maps\_laststand::player_is_in_laststand() || is_true( self.intermission ) )
		{
			grenade delete();
			return;
		}

		grenade hide();
		grenade.angles = (0, grenade.angles[1], 0);

		model = spawn( "script_model", grenade.origin );
		model.angles = grenade.angles;
		model SetModel( "t5_bh_bomb_world" );
		model linkTo( grenade );

		info = spawnStruct();
		info.sound_attractors = [];
		grenade thread monitor_zombie_groans( info ); // WW: this might need to change
		velocitySq = 10000*10000;
		oldPos = grenade.origin;

		while( velocitySq != 0 )
		{
			wait( 0.1 );

			if( !isDefined( grenade ) )
			{
				return;
			}

			velocitySq = distanceSquared( grenade.origin, oldPos );
			oldPos = grenade.origin;
			grenade.angles = (grenade.angles[0], grenade.angles[1], 0);
		}

		if( isDefined( grenade ) )
		{
			model._black_hole_bomb_player = self; // saves who threw the grenade, used to assign the damage when zombies die
			model.targetname = "zm_bhb";
			model._new_ground_trace = true;

			grenade resetmissiledetonationtime();

			if ( IsDefined( level.black_hole_bomb_loc_check_func ) )
			{
				if ( [[ level.black_hole_bomb_loc_check_func ]]( grenade, model, info ) )
				{
					return;
				}
			}

			if ( IsDefined( level._blackhole_bomb_valid_area_check ) )
			{
				if ( [[ level._blackhole_bomb_valid_area_check ]]( grenade, model, self ) )
				{
					return;
				}
			}

			valid_poi = check_point_in_active_zone( grenade.origin );
			// ww: There used to be a second check here for check_point_in_playable_area which was from the cymbal monkey.
			// This second check was removed because the black hole bomb has a reaction if it is tossed somewhere that can't
			// be accessed. Something similar could be done for the cymbal monkey as well.


			if(valid_poi)
			{
				self thread black_hole_bomb_kill_counter( model );
				level thread black_hole_bomb_cleanup( grenade, model );

				if( IsDefined( level._black_hole_bomb_poi_override ) ) // allows pois to be ignored immediately by ai
				{
					model thread [[level._black_hole_bomb_poi_override]]();
				}

				model create_zombie_point_of_interest( max_attract_dist, num_attractors, 0, true, level.black_hole_bomb_poi_initial_attract_func, level.black_hole_bomb_poi_arrival_attract_func );
				model SetClientFlag( level._SCRIPTMOVER_CLIENT_FLAG_BLACKHOLE );
				grenade thread do_black_hole_bomb_sound( model, info ); // WW: This might not work if it is based on the model
				level thread black_hole_bomb_teleport_init( grenade );
				grenade.is_valid = true;
				level notify("attractor_positions_generated");
			}
			else
			{
				self.script_noteworthy = undefined;
				level thread maps\_zombiemode_weapons::entity_stolen_by_sam( self, model );
			}
		}
		else
		{
			self.script_noteworthy = undefined;
			level thread maps\_zombiemode_weapons::entity_stolen_by_sam( self, model );
		}
	}
}

wait_for_attractor_positions_complete()
{
	self waittill( "attractor_positions_generated" );

	self.attract_to_origin = false;
}

black_hole_bomb_cleanup( parent, model )
{
	model endon( "sam_stole_it" );

	// pass this in to the corpse collector for corpse deleting
	grenade_org = parent.origin;

	while( true )
	{
		if( !IsDefined( parent ) )
		{
			if( IsDefined( model ) )
			{
				model Delete();

				level notify("attractor_positions_generated");

				//level thread anims_test();

				wait_network_frame();
			}
			break;
		}

		wait( 0.05 );
	}

	level thread black_hole_bomb_corpse_collect( grenade_org );
}

anims_test()
{
	wait 1;

	zombs = GetAiSpeciesArray("axis");
	for(i=0;i<zombs.size;i++)
	{
		if(IsSubStr(zombs[i] black_hole_bomb_store_movement_anim(), "fast_pull"))
		{
			iprintln("anim didnt switch");
		}
	}
}

black_hole_bomb_corpse_collect( vec_origin )
{
	wait( 0.1 );

	// clean up the zombies
	corpse_array = GetCorpseArray();
	for( i = 0; i < corpse_array.size; i++ )
	{
		if( DistanceSquared( corpse_array[i].origin, vec_origin ) < 192*192 ) // 128*128 is the pulled in distance from black_hole_bomb_initial_attract_func
		{
			corpse_array[i] thread black_hole_bomb_corpse_delete();
		}
	}
}

// -- deletes the invisible corpse
black_hole_bomb_corpse_delete()
{
	self Delete();
}

do_black_hole_bomb_sound( model, info )
{
	monk_scream_vox = false;

	if( level.music_override == false )
	{
		monk_scream_vox = false;
		//self playsound( "zmb_monkey_song" );
	}
	self playsound ("wpn_gersh_device_exp");
	self playloopsound ("wpn_gersh_device_loop_close");
//	sound_ent = spawn ("script_origin", self.origin);

	fakeorigin = self.origin;

	self waittill( "explode", position );

	playsoundatposition ("wpn_gersh_device_implode", fakeorigin);

	if( isDefined( model ) )
	{
		// model ClearAnim( %o_monkey_bomb, 0.2 );
	}

	for( i = 0; i < info.sound_attractors.size; i++ )
	{
		if( isDefined( info.sound_attractors[i] ) )
		{
			info.sound_attractors[i] notify( "black_hole_bomb_blown_up" );
		}
	}

	if( !monk_scream_vox )
	{
		play_sound_in_space( "zmb_vox_monkey_explode", position );
	}

}

get_thrown_black_hole_bomb()
{
	self endon( "disconnect" );
	self endon( "starting_black_hole_bomb" );

	while( true )
	{
		self waittill( "grenade_fire", grenade, weapName );
		if( weapName == "zombie_black_hole_bomb" )
		{
			return grenade;
		}

		wait( 0.05 );
	}
}

monitor_zombie_groans( info )
{
	self endon( "explode" );

	while( true )
	{
		if( !isDefined( self ) )
		{
			return;
		}

		if( !isDefined( self.attractor_array ) )
		{
			wait( 0.05 );
			continue;
		}

		for( i = 0; i < self.attractor_array.size; i++ )
		{
			if( array_check_for_dupes( info.sound_attractors, self.attractor_array[i] ) )
			{
				if ( isDefined( self.origin ) && isDefined( self.attractor_array[i].origin ) )
				{
					if( distanceSquared( self.origin, self.attractor_array[i].origin ) < 500 * 500 )
					{
						info.sound_attractors = array_add( info.sound_attractors, self.attractor_array[i] );
						self.attractor_array[i] thread play_zombie_groans();
					}
				}
			}
		}
		wait( 0.05 );
	}
}

play_zombie_groans()
{
	self endon( "death" );
	self endon( "black_hole_bomb_blown_up" );

	while(1)
	{
		if( isdefined ( self ) )
		{
			self playsound( "zmb_vox_zombie_groan" );
			wait randomfloatrange( 2, 3 );
		}
		else
		{
			return;
		}
	}
}

black_hole_bomb_exists()
{
	return IsDefined( level.zombie_weapons["zombie_black_hole_bomb"] );
}

// -- causes the zombie to react to the black hole, controls walk cycles, marks zombie for black hole death
black_hole_bomb_initial_attract_func( ent_poi )
{
	self endon( "death" );
	//self endon( "zombie_acquire_enemy" );
	//self endon( "bad_path" );
	//self endon( "path_timer_done" );

	if( IsDefined( self.pre_black_hole_bomb_run_combatanim ) )
	{
		return;
	}

	if(self.animname == "astro_zombie")
	{
		return;
	}

	if( IsDefined( self.script_string ) && self.script_string == "riser" )
	{
		while( is_true( self.in_the_ground ) )
		{
			wait( 0.05 );
		}
	}

	soul_spark_end = ent_poi.origin;

	soul_burst_range = 50*50;
	pulled_in_range = 128*128;
	inner_range = 1024*1024;
	outer_edge = 2056*2056;
	distance_to_black_hole = 100000*100000;

	self._distance_to_black_hole = 100000*100000; // set default dist
	self._black_hole_bomb_collapse_death = 0; // am i supposed to die when the bhb collapses
	self._black_hole_attract_walk = 0; // have I been given a random walk yet?
	self._black_hole_attract_run = 0; // have I been given a random run yet?
	self._current_black_hole_bomb_origin = ent_poi.origin; // where is the black hole i'm going to?
	self._normal_run_blend_time = 0.2; // hard coded in the zombie_run.gsc, need to store it for resetting
	self._black_hole_bomb_tosser = ent_poi._black_hole_bomb_player; // the player who threw the weapon, damage awards points properly
	self._black_hole_bomb_being_pulled_in_fx = 0;
	self.deathanim = self black_hole_bomb_death_while_attracted(); // the special death anim for when being pulled backwards
	if( !IsDefined( self._bhb_ent_flag_init ) )
	{
		self ent_flag_init( "bhb_anim_change" ); // have i been told to change my movement anim?
		self._bhb_ent_flag_init = 1;
	}

	// save original movement animation
	if( !IsDefined( self.pre_black_hole_bomb_run_combatanim ) )
	{
		self.pre_black_hole_bomb_run_combatanim = self black_hole_bomb_store_movement_anim();
	}

	if( IsDefined( level._black_hole_attract_override ) )
	{
		level [ [ level._black_hole_attract_override ] ]();
	}

	while( IsDefined( ent_poi ) )
	{
		self._distance_to_black_hole = DistanceSquared( self.origin, self._current_black_hole_bomb_origin );

		// on the ouside of the pull go slow -- walk
		if( self._black_hole_attract_walk == 0 && ( self._distance_to_black_hole < outer_edge && self._distance_to_black_hole > inner_range ) )
		{
			if( IsDefined( self._bhb_walk_attract ) )
			{
				self [[ self._bhb_walk_attract ]]();
			}
			else
			{
				self black_hole_bomb_attract_walk();
			}

		}

		// inside the inner range cause the pull the be greater -- run
		if( self._black_hole_attract_run == 0 && ( self._distance_to_black_hole < inner_range && self._distance_to_black_hole > pulled_in_range ) )
		{
			if( IsDefined( self._bhb_run_attract ) )
			{
				self [[ self._bhb_run_attract ]]();
			}
			else
			{
				self black_hole_bomb_attract_run();
			}

		}

		if( ( self._distance_to_black_hole < pulled_in_range ) && ( self._distance_to_black_hole > soul_burst_range ) ) // middle point, change to no feet on ground pull
		{
			self._black_hole_bomb_collapse_death = 1;
			if( IsDefined( self._bhb_horizon_death ) )
			{
				self [[ self._bhb_horizon_death ]]( self._current_black_hole_bomb_origin, ent_poi );
			}
			else
			{
				self black_hole_bomb_event_horizon_death( self._current_black_hole_bomb_origin, ent_poi );
			}

		}

		if( self._distance_to_black_hole < soul_burst_range ) // too close, time to die
		{
			self._black_hole_bomb_collapse_death = 1;
			if( IsDefined( self._bhb_horizon_death ) )
			{
				self [[ self._bhb_horizon_death ]]( self._current_black_hole_bomb_origin, ent_poi );
			}
			else
			{
				self black_hole_bomb_event_horizon_death( self._current_black_hole_bomb_origin, ent_poi );
			}
		}

		wait( 0.05 );
	}

	// zombie wasn't sucked in to the hole before it collapsed, put him back to normal.
	self thread black_hole_bomb_escaped_zombie_reset();
}

// -- store and return the current zombie movement anim
black_hole_bomb_store_movement_anim()
{
	self endon( "death" );

	current_anim = self.run_combatanim;
	anim_keys = GetArrayKeys( level.scr_anim[self.animname] );

	for( j = 0; j < anim_keys.size; j++ )
	{
		if( level.scr_anim[ self.animname ][ anim_keys[j] ] == current_anim )
		{
			return anim_keys[j];
		}
	}

	AssertMsg( "couldn't find zombie run anim in the array keys" );

}

// -- start the fx on the zombie's back
black_hole_bomb_being_pulled_fx()
{
	self endon( "death" );

	wait_network_frame();

	// start the effect on the back of the zombie
	self SetClientFlag( level._ACTOR_CLIENT_FLAG_BLACKHOLE );
	self._black_hole_bomb_being_pulled_in_fx = 1;
}

// -- decides which pulled in anim should be played
black_hole_bomb_attract_walk()
{
	self endon( "death" );

	//flag_wait( "bhb_anim_change_allowed" );  // permission for adding to the array
	//level._black_hole_bomb_zombies_anim_change = add_to_array( level._black_hole_bomb_zombies_anim_change, self, false ); // no dupes allowed

	// wait for permission to change anim
	//self ent_flag_wait( "bhb_anim_change" );

	self.a.runBlendTime = 0.9;
	self clear_run_anim();

	if( self.has_legs )
	{
		rand =  RandomIntRange( 1, 4 );

		self.needs_run_update = true;
		self._had_legs = true;

		self set_run_anim( "slow_pull_"+rand );
		self.run_combatanim = level.scr_anim["zombie"]["slow_pull_"+rand];
		self.crouchRunAnim = level.scr_anim["zombie"]["slow_pull_"+rand];
		self.crouchrun_combatanim = level.scr_anim["zombie"]["slow_pull_"+rand];
	}
	else // if they have no legs then they are a crawler
	{
		rand = RandomIntRange( 1, 3 );

		self.needs_run_update = true;
		self._had_legs = false;

		self set_run_anim( "crawler_slow_pull_"+rand );
		self.run_combatanim = level.scr_anim["zombie"]["crawler_slow_pull_"+rand];
		self.crouchRunAnim = level.scr_anim["zombie"]["crawler_slow_pull_"+rand];
		self.crouchrun_combatanim = level.scr_anim["zombie"]["crawler_slow_pull_"+rand];
	}

	if ( is_true( self.nogravity ) )
	{
		self AnimMode( "none" );
		self.nogravity = undefined;
	}

	self._black_hole_attract_walk = 1;
	self._bhb_change_anim_notified = 1;
	self.a.runBlendTime = self._normal_run_blend_time;
}

// chance that zombies will suddenly be pulled in faster, that way they aren't all going the same speed
black_hole_bomb_attract_run()
{
	self endon( "death" );

	// there are three fast pulls for zombies and legless so this random can happen here
	rand = RandomIntRange( 1, 4 );

	//flag_wait( "bhb_anim_change_allowed" ); // permission for adding to the array
	//level._black_hole_bomb_zombies_anim_change = add_to_array( level._black_hole_bomb_zombies_anim_change, self, false ); // no dupes allowed

	// wait for permission to change anim
	//self ent_flag_wait( "bhb_anim_change" );

	self.a.runBlendTime = 0.9;
	self clear_run_anim();

	if( self.has_legs )
	{
		self.needs_run_update = true;

		self set_run_anim( "fast_pull_" + rand );
		self.run_combatanim = level.scr_anim["zombie"]["fast_pull_" + rand];
		self.crouchRunAnim = level.scr_anim["zombie"]["fast_pull_" + rand];
		self.crouchrun_combatanim = level.scr_anim["zombie"]["fast_pull_" + rand];
	}
	else
	{
		self.needs_run_update = true;

		self set_run_anim( "crawler_fast_pull_" + rand );
		self.run_combatanim = level.scr_anim["zombie"]["crawler_fast_pull_" + rand];
		self.crouchRunAnim = level.scr_anim["zombie"]["crawler_fast_pull_" + rand];
		self.crouchrun_combatanim = level.scr_anim["zombie"]["crawler_fast_pull_" + rand];
	}

	if ( is_true( self.nogravity ) )
	{
		self AnimMode( "none" );
		self.nogravity = undefined;
	}

	self._black_hole_attract_run = 1;
	self._bhb_change_anim_notified = 1;
	self.a.runBlendTime = self._normal_run_blend_time;
}


// plays the animation of the zombie being pulled in
black_hole_bomb_death_anim()
{
	self endon( "death" );

	flt_moveto_time = 0.7;

	rand = RandomIntRange( 1, 4 );

	if( self.has_legs )
	{
		death_animation = level.scr_anim[ self.animname ][ "black_hole_death_"+rand ];
	}
	else // this is a crawler since it has no legs
	{
		death_animation = level.scr_anim[ self.animname ][ "crawler_black_hole_death_"+rand ];
	}

	return death_animation;
}

// -- special anims to play if the zombie is shot and killed while being pulled in
black_hole_bomb_death_while_attracted()
{
	self endon( "death" );

	death_animation = undefined;

	rand = RandomIntRange( 1, 5 );

	if( self.has_legs )
	{
		death_animation = level.scr_anim[ self.animname ][ "attracted_death_" + rand ];
	}

	return death_animation;
}

// -- causes death once the ai reaches goal
black_hole_bomb_arrival_attract_func( ent_poi )
{
	self endon( "death" );
	self endon( "zombie_acquire_enemy" );
	//self endon( "bad_path" );
	self endon( "path_timer_done" );

	if(self.animname == "astro_zombie")
	{
		return;
	}

	soul_spark_end = ent_poi.origin;

	// once goal hits the ai is at their poi and should die
	self waittill( "goal" );

	/*if(!IsDefined(ent_poi))
	{
		return;
	}*/

	self._black_hole_bomb_collapse_death = 1;
	if( IsDefined( self._bhb_horizon_death ) )
	{
		self [[ self._bhb_horizon_death ]]( self._current_black_hole_bomb_origin, ent_poi );
	}
	else
	{
		self black_hole_bomb_event_horizon_death( self._current_black_hole_bomb_origin, ent_poi );
	}

}

// -- special marked for event horizon collapse death
black_hole_bomb_event_horizon_death( vec_black_hole_org, grenade )
{
	self endon( "death" );

	if(!IsDefined(grenade))
	{
		level notify("attractor_positions_generated");
		return;
	}

	self maps\_zombiemode_spawner::zombie_eye_glow_stop();
	self playsound ("wpn_gersh_device_kill");

	//self ClearClientFlag( level._ACTOR_CLIENT_FLAG_BLACKHOLE );
	//wait_network_frame();

	pulled_in_anim = black_hole_bomb_death_anim();

	// self.deathanim = black_hole_bomb_death_anim();
	self AnimScripted( "pulled_in_complete", self.origin, self.angles, pulled_in_anim );
	self waittill_either( "bhb_burst", "pulled_in_complete" );

	// soul destroy fx
	PlayFXOnTag( level._effect[ "black_hole_bomb_zombie_destroy" ], self, "tag_origin" );

	grenade notify( "black_hole_bomb_kill" );

	self DoDamage( self.health + 50, self.origin + ( 0, 0, 50 ), self._black_hole_bomb_tosser, undefined, "crush" );
}

// -- hide the corpse after death
black_hole_bomb_corpse_hide()
{
	if( IsDefined( self._black_hole_bomb_collapse_death ) && self._black_hole_bomb_collapse_death == 1 )
	{
		// need the new fx before running these functions again
		// self ClearClientFlag( level._ACTOR_CLIENT_FLAG_BLACKHOLE );
		// wait_network_frame();
		PlayFXOnTag( level._effect[ "black_hole_bomb_zombie_gib" ], self, "tag_origin" );
		self Hide();
	}

	if( IsDefined( self._black_hole_bomb_being_pulled_in_fx ) && self._black_hole_bomb_being_pulled_in_fx == 1 )
	{
		// need the new fx before running these functions again
		// self ClearClientFlag( level._ACTOR_CLIENT_FLAG_BLACKHOLE );
		// wait_network_frame();
	}

}

// -- zombies that don't get caught in the event horizon go back to normal
black_hole_bomb_escaped_zombie_reset()
{
	self endon( "death" );

	//flag_wait( "bhb_anim_change_allowed" );  // permission for adding to the array
	//level._black_hole_bomb_zombies_anim_change = add_to_array( level._black_hole_bomb_zombies_anim_change, self, false ); // no dupes allowed

	// wait for permission to change anim
	//self ent_flag_wait( "bhb_anim_change" );

	// need the new fx before running these functions again
	// clear the flag that causes the back sparks
	//self ClearClientFlag( level._ACTOR_CLIENT_FLAG_BLACKHOLE );
	//wait_network_frame();

	// set a high blend time to switch back to the right run cycle
	self.a.runBlendTime = 0.9;
	self clear_run_anim();

	self.needs_run_update = true;

	// reset the right run anim
	// Zombies can turn in to crawlers while being pulled in, the variable on the zombie "._had_legs" will tell you if they had them when the
	// pull in started and the animation changed. In this situation if they get away from the bomb they need to take on a new crawler animation
	if( !self.has_legs ) // if the zombie had legs then lost them during pull in but still escaped
	{
		// WW (01/17/11): Issue 75171 - Legless zombies play quad animations after black hole bomb. Due to the different legless animation
		// naming I grabbed anims that should play on quads or should no longer be called in game. JZ has shown me which anims are correct and
		// their proper speeds, now each movement speed will create a quick array of acceptable animations.
		// pick a new random crawler movement for the legless zombie

		// walk - there are four legless walk animations
		legless_walk_anims = [];
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl1", false );
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl5", false );
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl_hand_1", false );
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl_hand_2", false );
		rand_walk_anim = RandomInt( legless_walk_anims.size );

		// run
		// there is only one legless run animations, so there is no point in randomizing an array

		// sprint
		// there are three legless sprint animations
		legless_sprint_anims = [];
		legless_sprint_anims = add_to_array( legless_sprint_anims, "crawl2", false );
		legless_sprint_anims = add_to_array( legless_sprint_anims, "crawl3", false );
		legless_sprint_anims = add_to_array( legless_sprint_anims, "crawl_sprint1", false );
		rand_sprint_anim = RandomInt( legless_sprint_anims.size );

		if( self.zombie_move_speed == "walk" )
		{
			self set_run_anim( legless_walk_anims[ rand_walk_anim ] );
			self.run_combatanim = level.scr_anim[ self.animname ][ legless_walk_anims[ rand_walk_anim ] ];
			self.crouchRunAnim = level.scr_anim[ self.animname ][ legless_walk_anims[ rand_walk_anim ] ];
			self.crouchrun_combatanim = level.scr_anim[ self.animname ][ legless_walk_anims[ rand_walk_anim ] ];
		}
		else if( self.zombie_move_speed == "run" )
		{
			// run
			// there is only one legless zombie run
			self set_run_anim( "crawl4" );
			self.run_combatanim = level.scr_anim[ self.animname ][ "crawl4" ];
			self.crouchRunAnim = level.scr_anim[ self.animname ][ "crawl4" ];
			self.crouchrun_combatanim = level.scr_anim[ self.animname ][ "crawl4" ];
		}
		else if( self.zombie_move_speed == "sprint" )
		{
			self set_run_anim( legless_sprint_anims[ rand_sprint_anim ] );
			self.run_combatanim = level.scr_anim[ self.animname ][ legless_sprint_anims[ rand_sprint_anim ] ];
			self.crouchRunAnim = level.scr_anim[ self.animname ][ legless_sprint_anims[ rand_sprint_anim ] ];
			self.crouchrun_combatanim = level.scr_anim[ self.animname ][ legless_sprint_anims[ rand_sprint_anim ] ];
		}
		else // in this case the self.zombie_move_speed was not working for some reason
		{
			// run - default in case there is an issue figuring out the movement speed
			self set_run_anim( "crawl4" );
			self.run_combatanim = level.scr_anim[ self.animname ][ "crawl4" ];
			self.crouchRunAnim = level.scr_anim[ self.animname ][ "crawl4" ];
			self.crouchrun_combatanim = level.scr_anim[ self.animname ][ "crawl4" ];
		}
	}
	else // the zombie was either a crawler or a walker before the pull in animation change, the anim stored on them should still be valid
	{
		self set_run_anim( self.pre_black_hole_bomb_run_combatanim );
		self.run_combatanim = level.scr_anim[ self.animname ][ self.pre_black_hole_bomb_run_combatanim ];
		self.crouchRunAnim = level.scr_anim[ self.animname ][ self.pre_black_hole_bomb_run_combatanim ];
		self.crouchrun_combatanim = level.scr_anim[ self.animname ][ self.pre_black_hole_bomb_run_combatanim ];
	}

	// reset all variables for the black hole in case this zombie gets attracted again
	self.pre_black_hole_bomb_run_combatanim = undefined;
	self._black_hole_attract_walk = 0;
	self._black_hole_attract_run = 0;
	self._bhb_change_anim_notified = 1;
	self._black_hole_bomb_being_pulled_in_fx = 0;
	self.a.runBlendTime = self._normal_run_blend_time;

	which_anim = RandomInt( 10 ); // random number for choosing which death anim to use
	if( self.has_legs ) // if the zombie has legs apply one of the two leg deaths
	{
		if( which_anim > 5 ) // greater than 5 means this anim
		{
			self.deathanim = level.scr_anim[self.animname]["death1"];
		}
		else // less than 5
		{
			self.deathanim = level.scr_anim[self.animname]["death2"];
		}
	}
	else // legless zombies will use these anims for death after escaping
	{
		if( which_anim > 5 ) // great than 5 means first anim
		{
			self.deathanim = level.scr_anim[self.animname]["death3"];
		}
		else // less than 5 means second anim
		{
			self.deathanim = level.scr_anim[self.animname]["death4"];
		}
	}

	self._had_legs = undefined;
	self._bhb_ent_flag_init = 0;

	// run anim doesn't always switch for some reason, if we keep setting self.needs_run_update to true it will eventually change
	for(i=0;i<30;i++)
	{
		wait_network_frame();
		self.needs_run_update = true;
	}
}

// -- black hole bomb anim change throttling
black_hole_bomb_throttle_anim_changes()
{
	if( !IsDefined( level._black_hole_bomb_zombies_anim_change ) )
	{
		level._black_hole_bomb_zombies_anim_change = [];
	}

	int_max_num_zombies_per_frame = 7; // how many guys it can allow at a time
	array_zombies_allowed_to_switch = [];

	// loop through the array
	while( IsDefined( level._black_hole_bomb_zombies_anim_change ) )
	{
		if( level._black_hole_bomb_zombies_anim_change.size == 0 )
		{
			wait( 0.1 );
			continue;
		}

		array_zombies_allowed_to_switch = level._black_hole_bomb_zombies_anim_change;

		for( i = 0; i < array_zombies_allowed_to_switch.size; i++  )
		{
			if( IsDefined( array_zombies_allowed_to_switch[i] ) &&
					IsAlive( array_zombies_allowed_to_switch[i] ) )
					{
						array_zombies_allowed_to_switch[i] ent_flag_set( "bhb_anim_change" );
					}

			if( i >= int_max_num_zombies_per_frame )
			{
				break; // no more zombies should be allowed to change until the next server frame
			}
		}

		flag_clear( "bhb_anim_change_allowed" );

		// now clean out those that were allowed to change
		for( i = 0; i < array_zombies_allowed_to_switch.size; i++ )
		{
			if( !IsDefined( array_zombies_allowed_to_switch[i]._bhb_ent_flag_init ) )
			{
				array_zombies_allowed_to_switch[i] ent_flag_init( "bhb_anim_change" ); // have i been told to change my movement anim?
				array_zombies_allowed_to_switch[i]._bhb_ent_flag_init = 1;
			}

			if( array_zombies_allowed_to_switch[i] ent_flag( "bhb_anim_change" ) )
			{
				// remove this one from the level array
				level._black_hole_bomb_zombies_anim_change = array_remove( level._black_hole_bomb_zombies_anim_change, array_zombies_allowed_to_switch[i] );
			}
		}

		// clean any dead or undefined from the main array
		level._black_hole_bomb_zombies_anim_change = array_removedead( level._black_hole_bomb_zombies_anim_change );
		level._black_hole_bomb_zombies_anim_change = array_removeundefined( level._black_hole_bomb_zombies_anim_change );

		flag_set( "bhb_anim_change_allowed" );

		wait_network_frame();
		wait( 0.1 );

	}

}

// ww: players who stand in the black hole bomb for a moment will teleport to a random spot on the map
black_hole_bomb_teleport_init( ent_grenade )
{
	if( !IsDefined( ent_grenade ) )
	{
		return;
	}

	// spawn a script origin at the spot where the grenade is
	teleport_trigger = Spawn( "trigger_radius", ent_grenade.origin, 0, 64, 70 );

	// monitor players hitting the trigger
	ent_grenade thread black_hole_bomb_trigger_monitor( teleport_trigger );

	// wait for grenade to explode
	ent_grenade waittill( "explode" );

	// grenade is gone, delete the trigger
	teleport_trigger notify( "black_hole_complete" );
	wait( 0.1 );
	teleport_trigger Delete();

}

// watches the trigger to be hit, cleans it up if teleporting isn't used
black_hole_bomb_trigger_monitor( ent_trigger )
{

	ent_trigger endon( "black_hole_complete" );

	while( 1 )
	{
		ent_trigger waittill( "trigger", ent_player );

		if( IsPlayer( ent_player ) && !ent_player IsOnGround() && !is_true( ent_player.lander ) )
		{
			ent_trigger thread black_hole_teleport_trigger_thread( ent_player, ::black_hole_time_before_teleport, ::black_hole_teleport_cancel );
		}

		wait( 0.1 );
	}

}

// watches for the player to stay in the trigger for X amt of time, then teleport.
// function ends if the player steps out of the trigger
black_hole_time_before_teleport( ent_player, str_endon )
{
	ent_player endon( str_endon );

	// check to see make sure no collision is in the way
	if( !BulletTracePassed( ent_player GetEye(), self.origin + ( 0, 0, 65 ) , false, ent_player ) )
	{
		return;
	}

	// grab all the structs
	black_hole_teleport_structs = getstructarray( "struct_black_hole_teleport", "targetname" );
	chosen_spot = undefined;

	if(isDefined(level._special_blackhole_bomb_structs))
	{
		black_hole_teleport_structs = [[level._special_blackhole_bomb_structs]]();
	}


	if( !IsDefined( black_hole_teleport_structs ) || black_hole_teleport_structs.size == 0 )
	{
		// no structs so no teleport
		return;
	}

	// randomize the array
	black_hole_teleport_structs = array_randomize( black_hole_teleport_structs );

	if(isDefined(level._override_blackhole_destination_logic))
	{
		chosen_spot = [[level._override_blackhole_destination_logic]](black_hole_teleport_structs,ent_player);
	}
	else
	{

		// decide which struct to move the player to
		for( i = 0; i < black_hole_teleport_structs.size; i++ )
		{
			if( check_point_in_active_zone( black_hole_teleport_structs[i].origin ) &&
					( ent_player get_current_zone() != black_hole_teleport_structs[i].script_string ) )
			{
				chosen_spot = black_hole_teleport_structs[i];
				break;
			}
		}
	}

	//ent_player SetTransported(1.5);

		// teleport the player
	if( IsDefined( chosen_spot ) )
	{
		self PlaySound( "zmb_gersh_teleporter_out" );
		ent_player thread black_hole_teleport( chosen_spot );
	}

}

// functions runs when the player exits the teleport trigger
black_hole_teleport_cancel( ent_player )
{
	//ent_player SetTransported( 0 );
}

// teleports the player to a new position
// override included, runs before the player is moved this way anything that needs to be done for the teleport
// SELF == PLAYER
black_hole_teleport( struct_dest )
{
	self endon( "death" );

	if( !IsDefined( struct_dest ) )
	{
		return;
	}

	prone_offset = (0, 0, 49);
	crouch_offset = (0, 0, 20);
	stand_offset = (0, 0, 0);
	destination = undefined;

	// figure out the player's stance
	if( self GetStance() == "prone" )
	{
		destination = struct_dest.origin + prone_offset;
	}
	else if( self GetStance() == "crouch" )
	{
		destination = struct_dest.origin + crouch_offset;
	}
	else
	{
		destination = struct_dest.origin + stand_offset;
	}

	// override
	if( IsDefined( level._black_hole_teleport_override ) )
	{
		level [[ level._black_hole_teleport_override ]]( self );
	}

	// create the exit portal
	black_hole_bomb_create_exit_portal( struct_dest.origin );

	// don't allow any funny biz
	self FreezeControls( true );
	self DisableOffhandWeapons();
	self DisableWeapons();

	// so the player doesn't show up while moving
	self DontInterpolate();
	self SetOrigin( destination );
	self SetPlayerAngles( struct_dest.angles );

	// allow the funny biz
	self EnableOffhandWeapons();
	self EnableWeapons();
	self FreezeControls( false );

	self thread slightly_delayed_player_response();
}

slightly_delayed_player_response()
{
    wait(1);
    self maps\_zombiemode_audio::create_and_play_dialog( "general", "teleport_gersh" );
}


// borrowed from _utility, written by DLaufer
// black hole trigger thread
black_hole_teleport_trigger_thread( ent, on_enter_payload, on_exit_payload )	// Self == The trigger.
{
	ent endon("death");
	self endon( "black_hole_complete" );

	if( ent black_hole_teleport_ent_already_in_trigger( self ) )
	{
		return;
	}

	self black_hole_teleport_add_trigger_to_ent( ent );

//	iprintlnbold("Trigger " + self.targetname + " hit by ent " + ent getentitynumber());

	endon_condition = "leave_trigger_" + self GetEntityNumber();

	if( IsDefined( on_enter_payload ) )
	{
		self thread [[ on_enter_payload ]]( ent, endon_condition );
	}

	while( IsDefined( ent ) && ent IsTouching( self ) && IsDefined( self ) )
	{
		wait( 0.01 );
	}

	ent notify( endon_condition );

//	iprintlnbold(ent getentitynumber() + " leaves trigger " + self.targetname + ".");

	if( IsDefined( ent ) && IsDefined( on_exit_payload ) )
	{
		self thread [[on_exit_payload]]( ent );
	}

	if( IsDefined( ent ) )
	{
		self black_hole_teleport_remove_trigger_from_ent( ent );
	}

}

black_hole_teleport_add_trigger_to_ent(ent) // Self == The trigger volume
{
	if(!IsDefined(ent._triggers))
	{
		ent._triggers = [];
	}

	ent._triggers[self GetEntityNumber()] = 1;
}

black_hole_teleport_remove_trigger_from_ent(ent)	// Self == The trigger volume.
{
	if(!IsDefined(ent._triggers))
		return;

	if(!IsDefined(ent._triggers[self GetEntityNumber()]))
		return;

	ent._triggers[self GetEntityNumber()] = 0;
}

black_hole_teleport_ent_already_in_trigger(trig)	// Self == The entity in the trigger volume.
{
	if(!IsDefined(self._triggers))
		return false;

	if(!IsDefined(self._triggers[trig GetEntityNumber()]))
		return false;

	if(!self._triggers[trig GetEntityNumber()])
		return false;

	return true;	// We're already in this trigger volume.
}

black_hole_bomb_kill_counter( ent_poi )
{
	self endon( "death" );
	ent_poi endon( "death" );

	kill_count = 0;
	for ( ;; )
	{
		ent_poi waittill( "black_hole_bomb_kill" );

		kill_count++;

		//C. Ayers: Adding in Player dialog for when 4 zombies are killed with Gersh Device
		if( kill_count == 4 )
		{
		    self maps\_zombiemode_audio::create_and_play_dialog( "kill", "gersh_device" );
		}

		if ( 5 <= kill_count )
		{
			self notify( "black_hole_kills_achievement" );
		}
	}
}

black_hole_bomb_create_exit_portal( pos )
{
	exit_portal_fx_spot = Spawn( "script_model", pos );
	exit_portal_fx_spot SetModel( "tag_origin" );
	PlayFXOnTag( level._effect[ "black_hole_bomb_portal_exit" ], exit_portal_fx_spot, "tag_origin" );
	exit_portal_fx_spot thread black_hole_bomb_exit_clean_up();
	exit_portal_fx_spot PlaySound( "zmb_gersh_teleporter_go" );
}

black_hole_bomb_exit_clean_up()
{
	// gib spewing happens heree

	wait( 4.0 );

	self Delete();
}

// if the player throws it to an unplayable area samantha steals it
black_hole_bomb_stolen_by_sam( ent_grenade, ent_model )
{
	if( !IsDefined( ent_model ) )
	{
		return;
	}

	//ent_grenade notify( "sam_stole_it" );

	ent_model UnLink();

	if(IsDefined(ent_grenade))
	{
		ent_grenade resetmissiledetonationtime();
	}

	direction = ent_model.origin;
	direction = (direction[1], direction[0], 0);

	if(direction[1] < 0 || (direction[0] > 0 && direction[1] > 0))
	{
		direction = (direction[0], direction[1] * -1, 0);
	}
	else if(direction[0] < 0)
	{
		direction = (direction[0] * -1, direction[1], 0);
	}

	if( is_true( level.player_4_vox_override ) )
	{
		ent_model playsound( "zmb_laugh_rich" );
	}
	else
	{
		ent_model playsound( "zmb_laugh_child" );
	}

	// play the fx on the model
	PlayFXOnTag( level._effect[ "black_hole_samantha_steal" ], ent_model, "tag_origin" );

	// raise the model
	ent_model MoveZ( 60, 1.0, 0.25, 0.25 );

	// spin it
	ent_model Vibrate( direction, 1.5,  2.5, 1.0 );
	ent_model waittill( "movedone" );

	// delete it
	ent_model Delete();

}

// setup anims needed for the black hole bomb
#using_animtree( "generic_human" );
black_hole_bomb_anim_init()
{

	if(isDefined(level._use_extra_blackhole_anims))
	{
		[[level._use_extra_blackhole_anims]]();
	}

	// black hole specific animations
	level.scr_anim["zombie"]["slow_pull_1"] 	= %ai_zombie_blackhole_walk_slow_v1;
	level.scr_anim["zombie"]["slow_pull_2"] 	= %ai_zombie_blackhole_walk_slow_v2;
	level.scr_anim["zombie"]["slow_pull_3"] 	= %ai_zombie_blackhole_walk_slow_v3;

	level.scr_anim["zombie"]["fast_pull_1"] 	= %ai_zombie_blackhole_walk_fast_v1;
	level.scr_anim["zombie"]["fast_pull_2"] 	= %ai_zombie_blackhole_walk_fast_v2;
	level.scr_anim["zombie"]["fast_pull_3"] 	= %ai_zombie_blackhole_walk_fast_v3;

	// all deaths have a "bhb_burst" notetrack for when the anim finishes playing,
	// this is one of the ways to decide if the zombie is ready for soul burst
	level.scr_anim["zombie"]["black_hole_death_1"] 	= %ai_zombie_blackhole_death_v1;
	level.scr_anim["zombie"]["black_hole_death_2"] 	= %ai_zombie_blackhole_death_v2;
	level.scr_anim["zombie"]["black_hole_death_3"] 	= %ai_zombie_blackhole_death_v3;

	// for zombies with no legs
	level.scr_anim["zombie"]["crawler_slow_pull_1"] 	= %ai_zombie_blackhole_crawl_slow_v1;
	level.scr_anim["zombie"]["crawler_slow_pull_2"] 	= %ai_zombie_blackhole_crawl_slow_v2;

	level.scr_anim["zombie"]["crawler_fast_pull_1"] 	= %ai_zombie_blackhole_crawl_fast_v1;
	level.scr_anim["zombie"]["crawler_fast_pull_2"] 	= %ai_zombie_blackhole_crawl_fast_v2;
	level.scr_anim["zombie"]["crawler_fast_pull_3"] 	= %ai_zombie_blackhole_crawl_fast_v3;

	level.scr_anim["zombie"]["crawler_black_hole_death_1"]	=%ai_zombie_blackhole_crawl_death_v1;
	level.scr_anim["zombie"]["crawler_black_hole_death_2"]	=%ai_zombie_blackhole_crawl_death_v2;
	level.scr_anim["zombie"]["crawler_black_hole_death_3"]	=%ai_zombie_blackhole_crawl_death_v3;

	// death anims for zombies killed while be attracted
	level.scr_anim[ "zombie" ][ "attracted_death_1" ] = %ai_zombie_blackhole_death_preburst_v1;
	level.scr_anim[ "zombie" ][ "attracted_death_2" ] = %ai_zombie_blackhole_death_preburst_v2;
	level.scr_anim[ "zombie" ][ "attracted_death_3" ] = %ai_zombie_blackhole_death_preburst_v3;
	level.scr_anim[ "zombie" ][ "attracted_death_4" ] = %ai_zombie_blackhole_death_preburst_v4;

}
