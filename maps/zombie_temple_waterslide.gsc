//*****************************************************************************
// WATERSLIDE
//
//
//*****************************************************************************
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_utility_raven;


precache_assets()
{
	level._effect["fx_slide_wake"] 					= LoadFX("bio/player/fx_player_water_swim_wake");	// looping
	level._effect["fx_slide_splash"]				= LoadFX("bio/player/fx_player_water_splash");		// one-shot
	level._effect["fx_slide_splash_2"]				= LoadFX("env/water/fx_water_splash_fountain_lg");	// looping
	level._effect["fx_slide_splash_3"] 				= LoadFX("maps/pow/fx_pow_cave_water_splash");		// looping
	level._effect["fx_slide_water_fall"]			= LoadFX("maps/pow/fx_pow_cave_water_fall");		// looping
}

//-----------------------------------------
// waterslide_main
//-----------------------------------------
waterslide_main()
{
	flag_init("waterslide_open");
	//MCG(042811): triggered zombie slide.
	zombie_cave_slide_init();

	//Wait till exit is open and power is on
	if ( GetDvar("waterslide_debug") == "" )
	{
		SetDvar("waterslide_debug", "0");
	}
	
	messageTrigger = GetEnt("waterslide_message_trigger", "targetname");
	if(isDefined(messageTrigger))
	{
		messageTrigger setcursorhint( "HINT_NOICON" );
	}

	cheat = false;
	/#
	cheat = GetDvarInt("waterslide_debug") > 0;
    #/

	if ( !cheat )
	{
		if(isDefined(messageTrigger))
		{
			messageTrigger SetHintString( &"ZOMBIE_NEED_POWER" );
		}
		flag_wait("power_on");
		
		if(isDefined(messageTrigger))
		{
			messageTrigger SetHintString( &"ZOMBIE_TEMPLE_DESTINATION_NOT_OPEN" );
		}
		flag_wait_any("cave01_to_cave02", "pressure_to_cave01");
		
	}
	
	flag_set("waterslide_open");
	
	//
	if(isDefined(messageTrigger))
	{
		messageTrigger SetHintString( "" );
	}
		
	waterSlideBlocker = getEnt("water_slide_blocker", "targetname");
	if( isDefined(waterSlideBlocker) )
	{
		waterSlideBlocker ConnectPaths();
		waterSlideBlocker movez(128,1);
	}
		
	level notify( "slide_open" );
}

/*
//-----------------------------------------
// waterslide_think
//-----------------------------------------
waterslide_think()
{
	start_node = getvehiclenode( self.target, "targetname" );
	
	// Find the end direction on the path
	end_node = undefined;
	prev_node = undefined;
	cur_node = start_node;
	while( IsDefined( cur_node ) )
	{
		prev_node = end_node;
		end_node = cur_node;
		
		if( IsDefined( cur_node.target ) )
		{
			cur_node = getvehiclenode( cur_node.target, "targetname" );
		}
		else
		{
			break;
		}
	}
	
	end_dir = (0,0,0);
	if( IsDefined( end_node ) && IsDefined( prev_node ) )
	{
		end_dir = vectornormalize( end_node.origin - prev_node.origin );
	}
	
	// Setup Data
	//------------
	self.drivepath      = false;
	self.moving			= false;
	self.accel 			= 50;
	self.decel 			= 100;
	self.maxSpeed		= 50;
	
	// Init Vehicle Spline
	//---------------------
	self SetVehMaxSpeed( self.maxSpeed );
	self SetSpeed( 0, self.accel, self.decel );
	
	self.view_car SetVehMaxSpeed( self.maxSpeed );
	self.view_car SetSpeed( 0, self.accel, self.decel );
	
	// Main Start & Stop Loop
	//------------------------
	while (1)
	{
		// Get the vehicle into the starting position
		self maps\_vehicle::getonpath( start_node );
		self thread maps\_vehicle::gopath();
	
		self.view_car maps\_vehicle::getonpath( start_node );
		self.view_car thread maps\_vehicle::gopath();
		
		// Allow the view car to skip ahead for a time
		self.view_car ResumeSpeed( self.accel );
		wait( 1.5 );
		self.view_car SetSpeed( 0, self.accel, self.decel );
		
		self waittill( "start_moving" );
		wait_network_frame();
		
		self waittill( "stop_lookahead" );
		
		players = GetPlayers();
		assert( self.player_index < 4 );
		player = players[ self.player_index ];
		if( IsDefined( player ) )
		{
			player CameraActivate(false);
		}
	
		self waittill( "reached_stop_point" );
		waterslide_stop( end_dir );
		wait_network_frame();
	}

}

//-----------------------------------------
// waterslide_stop
//-----------------------------------------
waterslide_stop( end_dir )
{
	self.moving = false;
	self SetSpeed( 0, self.accel, self.decel );	
	self notify( "stop_moving" );

	self.view_car SetSpeed( 0, self.accel, self.decel );
	self.view_car notify( "stop_moving" );

	self.clip Unlink();
	self.clip.origin = self.clip.saved_origin;
	
	// Unlock the attached player
	players = GetPlayers();
	assert( self.player_index < 4 );
	player = players[ self.player_index ];
	if( IsDefined( player ) )
	{
		player unlink();
		player.is_on_waterslide = undefined;
		player disableinvulnerability();
		
		player FreezeControls( false );

		if ( level.waterslide_viewlock ) 
		{
			player CameraActivate(false);
			//player ClearViewLockEnt();
		}
		
		player SetVelocity( vector_scale( end_dir, 500.0 ) );
	}
}

*/

////-----------------------------------------
//// waterslide_start
////-----------------------------------------
//waterslide_start( player )
//{
//	// Attach the player to the vehicle
//	view_fraction 	= 1.0;
//	
//
//	//player FreezeControls( true );
//	
//	player enableinvulnerability();	
//	
//	viewClamp = level.waterslide_viewclamp;
//
//	player StartCameraTween( 0.2, false );
//	player PlayerLinkTo( self, "", view_fraction, viewClamp, viewClamp, 0.0, 30.0, true );
//	wait_network_frame();
//	
//	player StartCameraTween( 1.0, false );
//	
//	// Send it on its way
//	self.moving = true;
//	self ResumeSpeed( self.accel );
//	self notify( "start_moving" );
//	
//	wait( 1.0 );
//
//	// Kick off threads to play effects and sounds
//	player thread waterslide_fx( self );
//	//player thread waterslide_look_at_update(self.view_car);
//
//	// bind the player clip to the player
//	self.clip.saved_origin = self.clip.origin;
//	self.clip.origin = player.origin;
//	self.clip LinkTo(player);
//
//	player notify( "stop_look_at_update" );
//	
//	if ( IsDefined( level.waterslide_viewlock ) && level.waterslide_viewlock )
//	{
//		//player SetViewLockEnt( self.view_car );
//		player CameraSetPosition( self );
//		player CameraSetLookAt( self.view_car );
//		player CameraActivate( true );
//	}
//
//	self.view_car ResumeSpeed( self.accel );
//	self.view_car notify( "start_moving" );
//}
//
//waterslide_look_at_update( target_ent )
//{
//	self endon( "stop_look_at_update" );
//	
//	while( 1 )
//	{
//		player_eye_pos = self get_eye();
//		vec_to_target = target_ent.origin - player_eye_pos;
//		self SetPlayerAngles( VectorToAngles( vec_to_target ) );	
//		wait( 0.05 );
//	}
//}
//
//waterslide_fx( vehicle )
//{
//	self thread waterslide_looping_fx( vehicle );
//	self thread waterslide_oneshot_fx( vehicle );
//}
//
//waterslide_looping_fx( vehicle )
//{
//	// Play looping fx under the vehicle at an offset
//	fx_origin_offset = (60,0,0);
//	fx_angles_offset = (0,0,0);
//	fx_ent = Spawn( "script_model", vehicle.origin );
//	fx_ent SetModel( "tag_origin" );
//	fx_ent LinkTo( vehicle, "tag_origin", fx_origin_offset, fx_angles_offset );
//
//	while( vehicle.moving )
//	{
//		PlayFXOnTag( level._effect["fx_slide_splash"], fx_ent, "tag_origin" );
//		wait( 0.05 );
//	}
//	
//	// Delete the looping fx under the vehicle
//	fx_ent delete();
//}
//
//waterslide_oneshot_fx( vehicle )
//{
//	fx_origin_offset_left = (72,30,0);
//	fx_origin_offset_right = (72,-30,0);
//	fx_angles_offset = (0,0,0);
//	
//	fx_ent_left = Spawn( "script_model", vehicle.origin );
//	fx_ent_right = Spawn( "script_model", vehicle.origin );
//	fx_ent_left SetModel( "tag_origin" );
//	fx_ent_right SetModel( "tag_origin" );
//	fx_ent_left LinkTo( vehicle, "tag_origin", fx_origin_offset_left, fx_angles_offset );
//	fx_ent_right LinkTo( vehicle, "tag_origin", fx_origin_offset_right, fx_angles_offset );
//	
//	fx_ent_left thread waterslide_oneshot_fx_thread();
//	fx_ent_right thread waterslide_oneshot_fx_thread();
//	
//	while( vehicle.moving )
//	{
//		wait( 0.05 );	
//	}
//	
//	fx_ent_left notify( "stop_fx" );
//	fx_ent_right notify( "stop_fx" );
//	wait_network_frame();
//	
//	fx_ent_left delete();
//	fx_ent_right delete();
//}
//
//waterslide_oneshot_fx_thread()
//{
//	self endon( "stop_fx" );
//	
//	while( 1 )
//	{
//		fx_time = RandomFloatRange( 0.05, 0.25 );
//		wait( fx_time );
//		PlayFXOnTag( level._effect["fx_slide_splash"], self, "tag_origin" );
//	}
//}

////-----------------------------------------
//// waterslide_trigger_think
////-----------------------------------------
//waterslide_trigger_think()
//{
////	flag_wait("power_on");
////	wait(1.0);
//	
//	while( 1 )
//	{
//		self waittill( "trigger", player );
//		if( IsDefined( player ) )
//		{
//			if( IsDefined( player.is_on_waterslide ) && player.is_on_waterslide )
//			{
//				continue;
//			}
//			
//			if(player maps\_laststand::player_is_in_laststand())
//			{
//				continue;
//			}
//			
//			// Determine which player index just hit the trigger
//			player_index 	= -1;
//			players 		= GetPlayers();
//			for( i = 0; i < players.size; i++ )
//			{
//				if( players[i] == player )
//				{
//					player_index = i;
//					break;
//				}
//			}
//
//			if( player_index == -1 )
//			{
//				continue;
//			}
//	
//			// Disable the trigger until we send this guy on his way
//			//self trigger_off();
//			
//			player.is_on_waterslide = true;
//			
//			// Retrieve this client's personal vehicle
//			assert( player_index < 4 );
//			waterslide_car = level.waterslide_cars[ player_index ];
//			assert( waterslide_car.player_index == player_index );
//			
//			// Start the waterslide for the player
//			waterslide_car waterslide_start( player );
//			
//			// Re-enable the trigger
//			//wait( 0.2 );
//			//self trigger_on();
//		}
//	}
//}


// ------------------------------------------------------------------------------------------------
// Zombie sliding in cave setup
// MCG: 04/28/11
// ------------------------------------------------------------------------------------------------
zombie_cave_slide_init()
{
	flag_init( "slide_anim_change_allowed" );
	level.zombies_slide_anim_change = []; // array needed for anim change throttling 
	level thread slide_anim_change_throttle(); // throttling function
	flag_set( "slide_anim_change_allowed" );
	
	slide_trigs = GetEntArray("zombie_cave_slide","targetname");
	array_thread(slide_trigs,::slide_trig_watch);
	
	level thread slide_player_enter_watch();
	level thread slide_player_exit_watch();
	level thread zombie_caveslide_anim_failsafe();
}

zombie_caveslide_anim_failsafe()
{
	trig = getent("zombie_cave_slide_failsafe","targetname");
	if(isDefined(trig))
	{
		while(1)
		{
			trig waittill("trigger",who);
			if(is_true(who.sliding))
			{
				who.sliding = false;
				who thread reset_zombie_anim();
			}
		}
	}
}

slide_trig_watch()
{
	slide_node = GetNode(self.target, "targetname");

	if(!IsDefined(slide_node))
	{
		return;
	}	
	
	self trigger_off();
	level waittill( "slide_open" );
	self trigger_on();

	while(true)
	{
		self waittill("trigger", who);
		if(who.animname == "zombie" || who.animname == "sonic_zombie" || who.animname == "napalm_zombie")
		{
			if(IsDefined(who.sliding) && who.sliding == true)
			{
				continue;
			}
			else
			{
				who thread zombie_sliding(slide_node);
			}	
		}
		else if ( isDefined( who.zombie_sliding ) )
		{
			who thread [[ who.zombie_sliding ]]( slide_node );
		}
	}	
}	

// ------------------------------------------------------------------------------------------------
#using_animtree( "generic_human" );
cave_slide_anim_init()
{	
	//level.scr_anim["zombie"]["fast_pull_1"] 	= %ai_zombie_blackhole_walk_fast_v1;
	//level.scr_anim["zombie"]["fast_pull_2"] 	= %ai_zombie_blackhole_walk_fast_v2;
	//level.scr_anim["zombie"]["fast_pull_3"] 	= %ai_zombie_blackhole_walk_fast_v3;
	level.scr_anim["zombie"]["fast_pull_4"] 	= %ai_zombie_caveslide_traverse;
	level.scr_anim["napalm_zombie"]["fast_pull_4"] 	= %ai_zombie_caveslide_traverse;
	level.scr_anim["sonic_zombie"]["fast_pull_4"] 	= %ai_zombie_caveslide_traverse;
	
	
	level.scr_anim[ "zombie" ][ "attracted_death_1" ] = %ai_zombie_blackhole_death_preburst_v1;
	level.scr_anim[ "zombie" ][ "attracted_death_2" ] = %ai_zombie_blackhole_death_preburst_v2;
	level.scr_anim[ "zombie" ][ "attracted_death_3" ] = %ai_zombie_blackhole_death_preburst_v3;
	level.scr_anim[ "zombie" ][ "attracted_death_4" ] = %ai_zombie_blackhole_death_preburst_v4;

	level.scr_anim[ "napalm_zombie" ][ "attracted_death_1" ] = %ai_zombie_blackhole_death_preburst_v1;
	level.scr_anim[ "napalm_zombie" ][ "attracted_death_2" ] = %ai_zombie_blackhole_death_preburst_v2;
	level.scr_anim[ "napalm_zombie" ][ "attracted_death_3" ] = %ai_zombie_blackhole_death_preburst_v3;
	level.scr_anim[ "napalm_zombie" ][ "attracted_death_4" ] = %ai_zombie_blackhole_death_preburst_v4;


	level.scr_anim[ "sonic_zombie" ][ "attracted_death_1" ] = %ai_zombie_blackhole_death_preburst_v1;
	level.scr_anim[ "sonic_zombie" ][ "attracted_death_2" ] = %ai_zombie_blackhole_death_preburst_v2;
	level.scr_anim[ "sonic_zombie" ][ "attracted_death_3" ] = %ai_zombie_blackhole_death_preburst_v3;
	level.scr_anim[ "sonic_zombie" ][ "attracted_death_4" ] = %ai_zombie_blackhole_death_preburst_v4;



	//level.scr_anim["zombie"]["crawler_fast_pull_1"] 	= %ai_zombie_blackhole_crawl_fast_v1;
	//level.scr_anim["zombie"]["crawler_fast_pull_2"] 	= %ai_zombie_blackhole_crawl_fast_v2;
	//level.scr_anim["zombie"]["crawler_fast_pull_3"] 	= %ai_zombie_blackhole_crawl_fast_v3;

}

//----------------------------------------------------------------------------
zombie_sliding(slide_node)
{
	self endon( "death" );
	level endon( "intermission" );

	if( !IsDefined( self.cave_slide_flag_init ) )
	{
		self ent_flag_init( "slide_anim_change" ); // have i been told to change my movement anim?
		self.cave_slide_flag_init = 1;
	}

	self.is_traversing = true;
	self notify("zombie_start_traverse");
	self thread zombie_slide_watch();
	
	self thread play_zombie_slide_looper();
	
	self.sliding = true;
	self.ignoreall = true;
	
	// adding check to see if gibbed during slide
	self thread gibbed_while_sliding();
	
	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );
	
	self thread set_zombie_slide_anim();
	
	self SetGoalNode(slide_node);
	check_dist_squared = 60*60;
	while(Distancesquared(self.origin, slide_node.origin) > check_dist_squared )//self.goalradius)
	{
		wait(0.01);
	}			
	//self waittill("goal");

	self thread reset_zombie_anim();
	
	self notify("water_slide_exit");
	self.sliding = false;
	self.is_traversing = false;
	self notify("zombie_end_traverse");
	self.ignoreall = false;
	self thread maps\_zombiemode_spawner::find_flesh();	
}

play_zombie_slide_looper()
{
	self endon( "death" );
	level endon( "intermission" );
		
    self PlayLoopSound( "fly_dtp_slide_loop_npc_snow", .5 );
    
    self waittill_any( "zombie_end_traverse", "death" );
    
    self StopLoopSound( .5 );
}


// ------------------------------------------------------------------------------------------------
set_zombie_slide_anim()
{
	self endon( "death" );
	
	rand = RandomIntRange( 1, 4 );

	// permission for adding to the array
	//flag_wait( "slide_anim_change_allowed" );  
	level.zombies_slide_anim_change = add_to_array( level.zombies_slide_anim_change, self, false ); // no dupes allowed

	// wait for permission to change anim
	self ent_flag_wait( "slide_anim_change" );

	self clear_run_anim();

	if( self.has_legs )
	{
		//rand = RandomIntRange( 1, 5 );
		self._had_legs = true;
		
		self.preslide_death = self.deathanim;
		self.deathanim = death_while_sliding();

		// just to test the new anim.
		self set_run_anim( "fast_pull_4");		
		self.run_combatanim = level.scr_anim[self.animname]["fast_pull_4"];
		self.crouchRunAnim = level.scr_anim[self.animname]["fast_pull_4"];
		self.crouchrun_combatanim = level.scr_anim[self.animname]["fast_pull_4"];

		//self set_run_anim( "fast_pull_" + rand );		
		//self.run_combatanim = level.scr_anim["zombie"]["fast_pull_" + rand];
		//self.crouchRunAnim = level.scr_anim["zombie"]["fast_pull_" + rand];
		//self.crouchrun_combatanim = level.scr_anim["zombie"]["fast_pull_" + rand];
		
		self.needs_run_update = true;
	}
	else
	{
		self._had_legs = false;
		
		// just to test the new anim.
		self set_run_anim( "fast_pull_4");		
		self.run_combatanim = level.scr_anim[self.animname]["fast_pull_4"];
		self.crouchRunAnim = level.scr_anim[self.animname]["fast_pull_4"];
		self.crouchrun_combatanim = level.scr_anim[self.animname]["fast_pull_4"];


		//self set_run_anim( "crawler_fast_pull_" + rand );		
		//self.run_combatanim = level.scr_anim["zombie"]["crawler_fast_pull_" + rand];
		//self.crouchRunAnim = level.scr_anim["zombie"]["crawler_fast_pull_" + rand];
		//self.crouchrun_combatanim = level.scr_anim["zombie"]["crawler_fast_pull_" + rand];
		
		self.needs_run_update = true;
	}
	
}

// ------------------------------------------------------------------------------------------------
reset_zombie_anim()
{
	self endon( "death" );
	
	// permission for adding to the array
	//flag_wait( "slide_anim_change_allowed" );  
	level.zombies_slide_anim_change = add_to_array( level.zombies_slide_anim_change, self, false ); // no dupes allowed
	
	// wait for permission to change anim
	self ent_flag_wait( "slide_anim_change" );

	//IPrintLnBold("zombie speed is ", self.zombie_move_speed);
	
	theanim = undefined;
	if( self.has_legs )
	{
		if(IsDefined(self.preslide_death))
		{
			self.deathanim = self.preslide_death;
		}	
		switch(self.zombie_move_speed)
		{
			case "walk":
				theanim = "walk" + randomintrange(1, 8);  
				break;
			case "run":                                
				theanim = "run" + randomintrange(1, 6);  
				break;
			case "sprint":                             
				theanim = "sprint" + randomintrange(1, 4);  
				break;
		}
	}
	else
	{
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
		
		switch(self.zombie_move_speed)
		{
			case "walk":
				theanim = legless_walk_anims[ rand_walk_anim ];  
				break;
			case "run":                                
				theanim = "crawl4";  
				break;
			case "sprint":                             
				theanim = legless_sprint_anims[ rand_sprint_anim ];  
				break;
			default:                             
				theanim = "crawl4";  
				break;				
				
		}
	}		

	if ( isDefined(level.scr_anim[self.animname][theanim]) )
	{
		self clear_run_anim();
		wait_network_frame();
				
		self set_run_anim( theanim );                         
		self.run_combatanim = level.scr_anim[self.animname][theanim];
		self.walk_combatanim = level.scr_anim[self.animname][theanim];
		self.crouchRunAnim = level.scr_anim[self.animname][theanim];
		self.crouchrun_combatanim = level.scr_anim[self.animname][theanim];
		self.needs_run_update = true;
		return;
	}
	else
	{
		//try again.
		self thread reset_zombie_anim();
	}	
}

// ------------------------------------------------------------------------------------------------
death_while_sliding()
{
	self endon( "death" );
	
	if(self.animname == "sonic_zombie" || self.animname == "napalm_zombie")
	{
		return self.deathanim;
	}
	
	death_animation = undefined;
	
	rand = RandomIntRange( 1, 5 );
	
	if( self.has_legs )
	{
		death_animation = level.scr_anim[ self.animname ][ "attracted_death_" + rand ];
	}
	
	return death_animation;
}

gibbed_while_sliding()
{
	self endon("death");
	
	if(self.animname == "sonic_zombie" || self.animname == "napalm_zombie")
	{
		return ;
	}
	
	// not needed, already a crawler.
	if(!self.has_legs)
	{
		return;
	}
		
	while(self.sliding)
	{
		if( !self.has_legs && self._had_legs == true)
		{
			self thread set_zombie_slide_anim();
			return;
		}
		wait(0.1);	
	}		 
}		
// ------------------------------------------------------------------------------------------------
//		Stolen from 
// -- black hole bomb anim change throttling
// ------------------------------------------------------------------------------------------------
slide_anim_change_throttle()
{
	if( !IsDefined( level.zombies_slide_anim_change ) )
	{
		level.zombies_slide_anim_change = [];
	}
	
	int_max_num_zombies_per_frame = 7; // how many guys it can allow at a time
	array_zombies_allowed_to_switch = [];
	
	// loop through the array
	while( IsDefined( level.zombies_slide_anim_change ) )
	{
		if( level.zombies_slide_anim_change.size == 0 )
		{
			wait( 0.1 );
			continue;
		}
		
		array_zombies_allowed_to_switch = level.zombies_slide_anim_change;
		
		for( i = 0; i < array_zombies_allowed_to_switch.size; i++  )
		{
			if( IsDefined( array_zombies_allowed_to_switch[i] ) &&
					IsAlive( array_zombies_allowed_to_switch[i] ) )
					{
						array_zombies_allowed_to_switch[i] ent_flag_set( "slide_anim_change" );
					}
					
			if( i >= int_max_num_zombies_per_frame )
			{
				break; // no more zombies should be allowed to change until the next server frame
			}
		}
		
		flag_clear( "slide_anim_change_allowed" );
		
		// now clean out those that were allowed to change
		for( i = 0; i < array_zombies_allowed_to_switch.size; i++ )
		{
			if( array_zombies_allowed_to_switch[i] ent_flag( "slide_anim_change" ) )
			{
				// remove this one from the level array
				level.zombies_slide_anim_change = array_remove( level.zombies_slide_anim_change, array_zombies_allowed_to_switch[i] );
			}
		}
		
		// clean any dead or undefined from the main array
		level.zombies_slide_anim_change = array_removedead( level.zombies_slide_anim_change );
		level.zombies_slide_anim_change = array_removeundefined( level.zombies_slide_anim_change );
		
		flag_set( "slide_anim_change_allowed" );
		
		wait_network_frame();
		wait( 0.1 );
	}
}	

slide_player_enter_watch()
{
	level endon("fake_death");
	
	trig = GetEnt("cave_slide_force_crouch", "targetname");
	
	while(true)
	{
		trig waittill("trigger", who);
		if(isDefined(who) && isPlayer(who) && who.sessionstate != "spectator" && !is_true(who.on_slide) )
		{
			who.on_slide = true;
			who thread player_slide_watch();
			who thread maps\_zombiemode_audio::create_and_play_dialog( "general", "slide" );
		}	
	}
}

slide_player_exit_watch()
{
	trig = GetEnt("cave_slide_force_stand", "targetname");
	
	while(true)
	{
		trig waittill("trigger", who);
		if(isDefined(who) && isPlayer(who) && who.sessionstate != "spectator" && is_true(who.on_slide) )
		{
			who.on_slide=false;
 			who notify("water_slide_exit");
		}	
	}	
}

player_slide_watch()
{
	self thread on_player_enter_slide();
	self thread player_slide_fake_death_watch();

	self waittill_any("water_slide_exit", "death", "disconnect");
	if ( isdefined( self ) )
	{
		self thread on_player_exit_slide();
	}
}

player_slide_fake_death_watch()
{
	self endon("death");
	self endon("disconnect");
	self endon("water_slide_exit");
	
	self waittill("fake_death");
	self allowstand(true);
	self AllowProne(true);
}

//self = player
on_player_enter_slide()
{
	self endon("death");
	self endon("disconnect");
	self endon("water_slide_exit");
	self thread play_loop_sound_on_entity("evt_slideloop");
	
	while(self maps\_laststand::player_is_in_laststand()  )
	{
		wait .1;
	}
	
	while(is_true(self.divetoprone))
	{
		wait(.1);
	}
	
	self AllowStand(false);
	self AllowProne(false);
	self SetStance("crouch");
	
}
//self = player
on_player_exit_slide()
{
	self endon( "death" );
	self endon( "disconnect" );
	self AllowStand(true);
	self AllowProne(true);
	
	if(!self maps\_laststand::player_is_in_laststand() )
	{
		self SetStance("stand");
	}
	
	self thread stop_loop_sound_on_entity("evt_slideloop");
}

//self = zombie
zombie_slide_watch()
{
	self thread on_zombie_enter_slide();
	self waittill_any("water_slide_exit", "death");
	self thread on_zombie_exit_slide();
}

//self = zombie
on_zombie_enter_slide()
{
	self thread play_loop_sound_on_entity("evt_slideloop");
}
//self = zombie
on_zombie_exit_slide()
{
	self thread stop_loop_sound_on_entity("evt_slideloop");
}
