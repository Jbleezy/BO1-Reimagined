
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" ); 

//-----------------------------------------------------------------------
// setup coast director
//-----------------------------------------------------------------------
init()
{
	PreCacheRumble( "damage_heavy" );

	level.max_director_zombies = 0;
	level.director_zombie_min_health = 7500;

	level.director_zombie_spawn_heuristic = ::coast_spawn_heuristic;
	level.director_init_done = ::coast_director_init;
	level.director_zombie_enter_level = ::coast_director_enter_level;

	level.director_reenter_level = ::coast_director_reenter_level;
	level.director_exit_level = ::coast_director_exit_level;
	level.director_find_exit = ::coast_director_find_exit;

	level.scr_anim[ "director_zombie" ][ "slide" ] = %ai_zombie_boss_caveslide_traverse_coast;
	level.scr_anim[ "director_zombie" ][ "zipline_traverse_lighthouse" ] = %ai_zombie_boss_zipline_traverse_lighthouse;
	level.scr_anim[ "director_zombie" ][ "zipline_traverse_ship" ] = %ai_zombie_boss_zipline_traverse_ship;

	level._effect[ "director_water_burst" ] = loadfx( "maps/zombie/fx_zmb_coast_director_water_burst" );
	level._effect[ "director_water_burst_sm" ] = loadfx( "maps/zombie/fx_zmb_coast_director_water_burst_sm" );
	level._effect[ "director_water_trail" ] = loadfx( "maps/zombie/fx_zmb_coast_director_water_trail" );

	level._effect[ "director_glow_docile" ] = loadfx( "maps/zombie/fx_zmb_director_glow_docile" );

	level thread coast_director_fx();
}

//-----------------------------------------------------------------------
// this pos can't be pathed to 
//-----------------------------------------------------------------------
FIX_bad_dog_location()
{
	locations = getstructarray( "shipback_near_zone_spawners_dog" );
	bad_org = ( -1800.2, -1613, 344.1 );
	new_org = ( -1792.2, -1581, 344.1 );

	for ( i = 0; i < locations.size; i++ )
	{
		if ( locations[i].origin == bad_org )
		{
			locations[i].origin = new_org;
			return;
		}
	}
}

//-----------------------------------------------------------------------
// water fx before the director shows up
//-----------------------------------------------------------------------
coast_director_fx()
{
	level waittill( "fade_introblack" );

	level thread FIX_bad_dog_location();

	exploder( 900 );
}

//-----------------------------------------------------------------------
// Weight the spawner based on the position where a director_zombie died
//-----------------------------------------------------------------------
coast_spawn_heuristic( spawner )
{
	if( isDefined( spawner.last_spawn_time ) && (GetTime() - spawner.last_spawn_time < 30000) )
	{
		return -1;
	}
	
	if( !isDefined( spawner.script_noteworthy ) )
	{
		return -1;
	}

	if( !isDefined( level.zones ) || !isDefined( level.zones[ spawner.script_noteworthy ] ) || !level.zones[ spawner.script_noteworthy ].is_enabled )
	{
		return -1;
	}
	
	score = 0;
	
	players = get_players();

	score = int( distanceSquared( spawner.origin, players[0].origin ) );
	
	for( i = 1; i < players.size; i++ )
	{
		// send the distance of the closest player
		player_score = int( distanceSquared( spawner.origin, players[i].origin ) );
		if ( player_score < score )
		{
			score = player_score;
		}
	}
	
	return score;
}

//--------------------------------------------------------------
// WW (01/18/11): Starts the director for coast (TEMP)
//--------------------------------------------------------------
coast_director_start()
{
	level waittill("fade_in_complete");
	
	wait( 6.0 );
	
	level.max_director_zombies = 1;
}

//--------------------------------------------------------------
// how director reacts to water
//--------------------------------------------------------------
coast_director_init()
{
	self endon( "death" );
	
	if( IsDefined( level._audio_director_vox ) )
	{
	    self [[ level._audio_director_vox ]]();
	}

	self.in_water = true;

	self.zombie_entered_water = ::coast_director_entered_water;
	self.zombie_exited_water = ::coast_director_exited_water;

	self thread maps\zombie_coast_water::zombie_water_out();

	self.zombie_sliding = ::coast_director_sliding;
	self.choose_run = ::coast_director_choose_run;
	self.find_exit_point = ::coast_director_find_exit_point;

	//self thread coast_director_failsafe();
}

coast_director_entered_water( trigger )
{
	self endon( "death" );

	self.water_trigger = trigger;

	if ( is_true( self.is_sliding ) )
	{
		self.is_sliding = undefined;
	}

	self notify( "disable_activation" );
	self thread maps\_zombiemode_ai_director::director_calmed();
	self thread check_for_close_players();
}

coast_director_exited_water()
{
	self endon( "death" );

	if ( !is_true( self.defeated ) )
	{
		self thread maps\_zombiemode_ai_director::director_zombie_check_for_activation();
	}
	else
	{
		if ( !isDefined( self.water_trigger.target ) )
		{
			self.is_activated = true;
		}
	}

	self.water_trigger = undefined;
}


//--------------------------------------------------------------
// director rises out of the water
//--------------------------------------------------------------
coast_director_enter_level()
{
	self endon( "death" );

	self coast_director_water_rise( self.angles, self.origin );
}

coast_director_water_rise_fx( angles, fx_pos, anim_time )
{
	self endon( "death" );

	ENTER_DIST = 295;

	offset = fx_pos[2];
	if ( isDefined( self.water_trigger ) )
	{
		point = getstruct( self.water_trigger.target, "targetname" );
		offset = point.origin[2];
	}

	org = ( fx_pos[0], fx_pos[1], offset );

	level thread coast_director_water_on_screen();

	Playfx( level._effect["director_water_burst"], org );
	
	trail = Spawn( "script_model", org );
	trail.angles = angles;
	trail SetModel( "tag_origin" );

	playfxontag( level._effect["director_water_trail"], trail, "tag_origin" );

	forward = VectorNormalize( AnglesToForward( angles ) );
	end = org + vector_scale( forward, ENTER_DIST );

	trail moveto( end, anim_time );
	trail waittill( "movedone" );

	trail delete();

}

coast_director_water_on_screen()
{
	wait( 0.5 );
	
	players = GetPlayers();
	
	for( i = 0; i < players.size; i++ )
	{
		if( is_true( players[i]._in_coast_water ) )
		{
			players[i] SetWaterSheeting( 1, 7.0 );
		}
		else
		{
			players[i] thread coast_director_water_drops_on_screen();
		}
		
		wait_network_frame();
	}
	
}

coast_director_water_drops_on_screen()
{
	self endon( "disconnect" );
	
	self SetWaterDrops( 50 );
	
	wait( 10.0 );
	
	self SetWaterDrops( 0 );
}

coast_director_water_rise( angles, origin )
{
	self endon( "death" );

	ENTER_HEIGHT = 82;
	ENTER_DIST = 295;

	emerge_anim = %ai_zombie_boss_emerge_from_water;
	time = getAnimLength( emerge_anim );

	forward = VectorNormalize( AnglesToForward( angles ) );

	fx_pos = origin - vector_scale( forward, ENTER_DIST );

	offset = fx_pos[2];
	if ( isDefined( self.water_trigger ) )
	{
		point = getstruct( self.water_trigger.target, "targetname" );
		offset = point.origin[2];
	}

	org = ( fx_pos[0], fx_pos[1], offset );
	Playfx( level._effect["director_glow_docile"], org );
	wait( 1 );

	playsoundatposition( "zmb_director_bubble_effect", fx_pos );
	//PlayRumbleOnPosition("explosion_generic", fx_pos);

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] PlayRumbleOnEntity( "explosion_generic" );
	}

	water_pos = origin - ( 0, 0, ENTER_HEIGHT );
	water_pos -= vector_scale( forward, ENTER_DIST );

	so = spawn( "script_origin", self.origin );
	so.angles = self.angles;
	self linkto( so );
	so.origin = water_pos;
	so rotateto( angles, 0.1 );
	so waittill( "rotatedone" );
	self unlink();
	so delete();

	self thread coast_director_water_rise_fx( self.angles, fx_pos, time );
	self Show();

	self thread coast_director_delay_weapon();
	self SetPlayerCollision( 1 );

	self PlaySound("zmb_director_exit_water" );
	level notify( "director_emerging_audio" );
	self animscripted( "emerge_anim", self.origin, self.angles, emerge_anim, "normal", %body, 1, 0.1 );
	wait( time );

	self.goalradius = 90;
	self.on_break = undefined;
}

//--------------------------------------------------------------
// add the director's weapon model
//--------------------------------------------------------------
coast_director_delay_weapon()
{
	self endon( "death" );

	if ( is_true( self.has_weapon ) )
	{
		self maps\_zombiemode_ai_director::director_flip_light_flag();
		return;
	}

	wait( 0.25 );

	self maps\_zombiemode_ai_director::director_add_weapon();
	self.has_weapon = true;
}

//--------------------------------------------------------------
// picks a random point for director to return from
//--------------------------------------------------------------
coast_director_get_reentry_point()
{
	location = [];

	for ( i = 0; i < level.water.size; i++ )
	{
		if ( isDefined( level.water[i].target ) )
		{
			//if ( level.zones[ level.water[i].script_noteworthy ].is_enabled )

			point = getstruct( level.water[i].target, "targetname" );
			zone_enabled = check_point_in_active_zone( point.origin );
			if ( zone_enabled )
			{
				location = array_add( location, point );
			}
		}
	}

	// pick random water to come back from
	location = array_randomize( location );
	
	return location[0];
}

//--------------------------------------------------------------
// director leaves through the water
//--------------------------------------------------------------
coast_director_reenter_level()
{
	self endon( "death" );

	point = coast_director_get_reentry_point();

	angles = point.angles + ( 0, 180, 0 );
	self coast_director_water_rise( angles, point.origin );
}

//--------------------------------------------------------------
// director leaves through the water
//--------------------------------------------------------------
coast_director_exit_level( exit, calm )
{
	self endon( "death" );
	self endon( "stop_exit" );

	ENTER_HEIGHT = 82;

	self.exit = exit;
	self.calm = calm;
	self.on_break = true;

	if ( is_true( calm ) )
	{
		self.is_activated = false;
		self notify( "director_calmed" );
	}
	else
	{
		self.is_activated = true;
	}

	self.goalradius = 32;
	self SetGoalPos( exit.origin );
	self waittill( "goal" );

	self OrientMode( "face angle", exit.angles[1] );
	time = 0;
	while ( 1 )
	{
		diff = abs( self.exit.angles[1] - self.angles[1] );
		if ( diff < 5 )
		{
			maps\_zombiemode_ai_director::director_print( "facing exit" );
			break;
		}
		time += 0.1;
		if ( time >= 1 )
		{
			maps\_zombiemode_ai_director::director_print( "facing timeout" );
			break;
		}
		wait( 0.1 );
	}
	//wait( 0.4 );

	return_anim = %ai_zombie_boss_return_to_water;
	time = getAnimLength( return_anim );
	
	playsoundatposition( "zmb_director_bubble_effect", exit.origin );

	self thread coast_director_exit_fx( time );

	self PlaySound("zmb_director_enter_water" );
	self animscripted( "return_anim", self.origin, self.angles, return_anim, "normal", %body, 1, 0.1 );
	wait( time );

	self OrientMode( "face default" );
	self SetPlayerCollision( 0 );

	self clearclientflag( level._ZOMBIE_ACTOR_FLAG_DIRECTOR_DEATH );
	
	//AUDIO: Play a director exit line on a random player
	players = getplayers();
	rand = RandomIntRange(0,players.size);
	players[rand] thread maps\_zombiemode_audio::create_and_play_dialog( "director", "exit" );

	so = spawn( "script_origin", self.origin );
	so.angles = self.angles;
	self linkto( so );
	so.origin = self.origin - ( 0, 0, 120 );
	wait_network_frame();
	self unlink();
	so delete();

	self.is_activated = false;
	self hide();
	self SetGoalPos( self.origin );

	self.exit = undefined;
	self.calm = undefined;
}

//--------------------------------------------------------------
// play some fx on exit
//--------------------------------------------------------------
coast_director_exit_fx( anim_time )
{
	self endon( "death" );

	EXIT_DIST = 295;

	PlayRumbleOnPosition( "explosion_generic", self.origin );

	Playfx( level._effect["rise_burst_water"], self.origin );

	trail = Spawn( "script_model", self.origin );
	trail.angles = self.angles;
	trail SetModel( "tag_origin" );

	playfxontag( level._effect["director_water_trail"], trail, "tag_origin" );

	forward = VectorNormalize( AnglesToForward( self.angles ) );
	end = self.origin + vector_scale( forward, EXIT_DIST );

	trail moveto( end, anim_time );
	trail waittill( "movedone" );

	trail delete();
}

//--------------------------------------------------------------
// find the nearest exit point
//--------------------------------------------------------------
coast_director_find_exit()
{
	location = undefined;
	dist = 1000000;

	for ( i = 0; i < level.water.size; i++ )
	{
		if ( isDefined( level.water[i].target ) )
		{
			//if ( level.zones[ level.water[i].script_noteworthy ].is_enabled )

			point = getstruct( level.water[i].target, "targetname" );
			zone_enabled = check_point_in_active_zone( point.origin );
			if ( zone_enabled )
			{
				exit_dist = Distance( self.origin, point.origin );
				if ( exit_dist < dist )
				{
					dist = exit_dist;
					location = point;
				}
			}
		}
	}

	return location;
}

//--------------------------------------------------------------
// switch anim when pathing down the slide
//--------------------------------------------------------------
coast_director_sliding( slide_node )
{
	self endon( "death" );

	if ( is_true( self.is_sliding ) )
	{
		return;
	}

	if ( isDefined( self.exit ) )
	{
		self notify( "stop_exit" );
	}

	self.is_sliding = true;

	self.is_traversing = true;
	self notify("zombie_start_traverse");

	self thread maps\zombie_coast_cave_slide::play_zombie_slide_looper();

	self notify( "disable_activation" );
	self notify( "disable_buff" );
	self notify( "director_run_change" );

	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );

	self.ignoreall = true;

	self.goalradius = 32;
	self SetGoalPos( slide_node.origin );

	while(Distance(self.origin, slide_node.origin) > self.goalradius)
	{
		wait(0.01);
	}			
	//self waittill( "goal" );
	self.goalradius = 90;

	maps\_zombiemode_ai_director::director_zombie_update_next_groundhit();

	self.is_sliding = undefined;
	self.is_traversing = false;
	self notify("zombie_end_traverse");

	self thread coast_director_delay_transition( 3 );

	if ( isDefined( self.exit ) )
	{
		self thread coast_director_exit_level( self.exit, self.calm );
	}
	else
	{
		self.following_player = false;
	}
}

coast_director_delay_transition( time )
{
	self.ignore_transition = true;
	wait( time );
	self.ignore_transition = undefined;
}

coast_director_choose_run()
{
	if ( is_true( self.is_sliding ) )
	{
		self set_run_anim( "slide" );
		self.run_combatanim = level.scr_anim["director_zombie"]["slide"];
		self.crouchRunAnim = level.scr_anim["director_zombie"]["slide"];
		self.crouchrun_combatanim = level.scr_anim["director_zombie"]["slide"];
		self.needs_run_update = true;

		return true;
	}

	return false;
}

//SELF == Director Zombie
check_for_close_players()
{
    players = GetPlayers();
    
    for(i=0;i<players.size;i++)
    {
        if( DistanceSquared( self.origin, players[i].origin ) <= 600*600 )
        {
            players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "director", "water" );
            break;
        }
    }
}

coast_director_find_exit_point()
{
	self endon( "death" );
	self endon( "director_exit" );

	// already going to water, no need to do this
	if ( is_true( self.defeated ) )
	{
		return;
	}

	maps\_zombiemode_ai_director::director_print( "going to exit point" );

	self.solo_last_stand = true;

	player = getplayers()[0];

	dist_zombie = 0;
	dist_player = 0;
	dest = 0;

	away = VectorNormalize( self.origin - player.origin );
	endPos = self.origin + vector_scale( away, 600 );

	locs = array_randomize( level.enemy_dog_locations );

	for ( i = 0; i < locs.size; i++ )
	{
		dist_zombie = DistanceSquared( locs[i].origin, endPos );
		dist_player = DistanceSquared( locs[i].origin, player.origin );

		if ( dist_zombie < dist_player )
		{
			dest = i;
			break;
		}
	}

	//self notify( "disable_activation" );
	self notify( "disable_buff" );
	self notify( "director_run_change" );

	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );

	self.ignoreall = true;

	self.goalradius = 32;
	self setgoalpos( locs[dest].origin );

	while ( 1 )
	{
		if ( !flag( "wait_and_revive" ) )
		{
			break;
		}
		wait_network_frame();
	}
	
	self.goalradius = 90;

	maps\_zombiemode_ai_director::director_zombie_update_next_groundhit();
	self.following_player = false;

	if ( !isDefined( self.exit ) )
	{
		self thread maps\_zombiemode_ai_director::director_zombie_check_for_buff();

		if ( !is_true( self.is_activated ) && !is_true( self.in_water ) )
		{
			self thread maps\_zombiemode_ai_director::director_zombie_check_for_activation();
		}
	}

	self.solo_last_stand = undefined;
}

coast_director_failsafe()
{
	self endon ("death");

	_MIN_DIST = 16*16;
	self.failsafe = 0;

	while ( 1 )
	{
		old_org = self.origin;
		wait( 1 );
		d = DistanceSquared( old_org, self.origin );
		if ( d < _MIN_DIST )
		{
			self.failsafe++;
		}
		else
		{
			self.failsafe = 0;
		}

		if ( is_true( self.performing_activation ) || is_true( self.finish_anim ) || is_true( self.on_break ) ||
			 is_true( self.is_traversing ) || is_true( self.nuke_react ) || is_true( self.leaving_level ) ||
			 is_true( self.entering_level ) || is_true( self.defeated ) || is_true( self.is_sliding ) || is_true( self.water_scream ) )
		{
			self.failsafe = 0;
			continue;
		}

		all_players_ignored = true;
		players = get_players();
		for (i = 0; i < players.size; i++)
		{
			if(!(IsDefined(players[i].humangun_player_ignored_timer) && players[i].humangun_player_ignored_timer > 0))
			{
				all_players_ignored = false;
				break;
			}
		}

		if(all_players_ignored)
		{
			self.failsafe = 0;
			continue;
		}

		if ( self.failsafe >= 10 )
		{
			// hasn't moved enough
			so = spawn( "script_origin", self.origin );
			so.angles = self.angles;
			self linkto( so );
			point = coast_director_get_reentry_point();
			so.origin = point.origin;
			wait_network_frame();
			self unlink();
			so delete();
			self.failsafe = 0;

			players = getplayers();
			for ( i = 0; i < players.size; i++ )
			{
				players[i] playlocalsound( "zmb_laugh_child" );	
			}
		}
	}
}


