#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;

init()
{
	level.water = getentarray( "waterdamage", "targetname" );
	level.water_zombie_damage_max = 650;
	level.water_zombie_time = 5;
	level.water_zombie_damage = level.water_zombie_damage_max / level.water_zombie_time;

	level.water_zombie_percent_max = 0.5;
	level.water_zombie_percent_min = 0.05;
	level.water_zombie_percent_dec = 0.05;
	level.water_zombie_percent = level.water_zombie_percent_max;

	level thread zombie_coast_adjust_percent();

	level.zombie_init_done = ::zombie_check_riser;
	
	level.deathcard_spawn_func = ::water_frost_bleed_out_reset;

	level thread check_water();
	level thread check_player_freeze();
}

zombie_coast_adjust_percent()
{
	while ( 1 )
	{
		level waittill( "between_round_over" );

		if ( level.water_zombie_percent > level.water_zombie_percent_min )
		{
			level.water_zombie_percent -= level.water_zombie_percent_dec;

			if ( level.water_zombie_percent <= level.water_zombie_percent_min )
			{
				level.water_zombie_percent = level.water_zombie_percent_min;
				break;
			}
		}
	}
}

//----------------------------------------------------------------------------------------------
// wait til riser is done before checking for water
//----------------------------------------------------------------------------------------------
zombie_check_riser()
{
	self endon( "death" );

	if ( isDefined( self.script_string ) && self.script_string == "riser" )
	{
		self waittill( "risen" );
	}

	self thread zombie_water_out();
}

//----------------------------------------------------------------------------------------------
// zombie is outside of the water
//----------------------------------------------------------------------------------------------
zombie_water_out()
{
	self endon( "death" );

	while ( 1 )
	{
		for ( i = 0; i < level.water.size; i++ )
		{
			if ( self isTouching( level.water[i] ) )
			{
				self zombie_entered_water( level.water[i] );
				return;
			}
		}

		wait_network_frame();
	}
}

//----------------------------------------------------------------------------------------------
// zombie stepped in water
//----------------------------------------------------------------------------------------------
zombie_entered_water( trigger )
{
	self endon( "death" );

	self.in_water = true;

	if ( isDefined( self.zombie_entered_water ) )
	{
		self thread [[ self.zombie_entered_water ]]( trigger );
	}
	else
	{
		self zombie_water_move_slow();
	}

	self thread zombie_water_in();
}

//----------------------------------------------------------------------------------------------
// change run speed in water
//----------------------------------------------------------------------------------------------
zombie_water_move_slow()
{
	if ( is_true( self.speed_buff ) )
	{
		var = randomintrange( 1, 5 );
		self set_run_anim( "sprint" + var );
		self.run_combatanim = level.scr_anim[ self.animname ][ "sprint" + var ];
	}
	else
	{
		switch( self.zombie_move_speed )
		{
		case "walk":
			break;

		case "run":
			var = randomintrange( 1, 9 );
			self set_run_anim( "walk" + var );
			self.run_combatanim = level.scr_anim[ self.animname ][ "walk" + var ];
			break;

		case "sprint":
			var = randomintrange( 1, 7 );
			self set_run_anim( "run" + var );
			self.run_combatanim = level.scr_anim[ self.animname ][ "run" + var ];
			break;
		}
	}

	self.needs_run_update = true;
}

//----------------------------------------------------------------------------------------------
// zombie is inside of the water
//----------------------------------------------------------------------------------------------
zombie_water_in()
{
	self endon( "death" );

	while ( 1 )
	{
		in_water = false;
		for ( i = 0; i < level.water.size; i++ )
		{
			if ( self isTouching( level.water[i] ) )
			{
				self thread water_damage_zombie();
				in_water = true;
				break;
			}
		}

		if ( !in_water )
		{
			self zombie_exited_water();
			return;
		}

		wait_network_frame();
	}
}

//----------------------------------------------------------------------------------------------
// zombie stepped out of water
//----------------------------------------------------------------------------------------------
zombie_exited_water()
{
	self endon( "death" );

	self.in_water = false;
	self.is_freezing = undefined;

	if ( isDefined( self.zombie_exited_water ) )
	{
		self thread [[ self.zombie_exited_water ]]();
	}
	else
	{
		self zombie_water_move_normal();
	}

	self thread zombie_water_out();
}

//----------------------------------------------------------------------------------------------
// back to previous move speed
//----------------------------------------------------------------------------------------------
zombie_water_move_normal()
{
	if ( is_true( self.speed_buff ) )
	{
		fast_sprint = "sprint5";
		if ( RandomInt( 100 ) < 50 )
		{
			fast_sprint = "sprint6";
		}

		self set_run_anim( fast_sprint );
		self.run_combatanim = level.scr_anim[ self.animname ][ fast_sprint ];
	}
	else
	{
		switch( self.zombie_move_speed )
		{
		case "walk":
			var = randomintrange( 1, 9 );
			self set_run_anim( "walk" + var );
			self.run_combatanim = level.scr_anim[ self.animname ][ "walk" + var ];
			break;

		case "run":
			var = randomintrange( 1, 7 );
			self set_run_anim( "run" + var );
			self.run_combatanim = level.scr_anim[ self.animname ][ "run" + var ];
			break;

		case "sprint":
			var = randomintrange( 1, 5 );
			self set_run_anim( "sprint" + var );
			self.run_combatanim = level.scr_anim[ self.animname ][ "sprint" + var ];
			break;
		}
	}

	self.needs_run_update = true;
}


//----------------------------------------------------------------------------------------------
// setup trigger threads
//----------------------------------------------------------------------------------------------
check_water()
{
	for ( i = 0; i < level.water.size; i++ )
	{
		level.water[i] thread water_trigger();
		level.water[i] thread wade_trigger();
	}
}

//----------------------------------------------------------------------------------------------
// setup player water watch
//----------------------------------------------------------------------------------------------
check_player_freeze()
{
	level waittill( "all_players_connected" );

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] thread water_watch_freeze();
	}
}

//----------------------------------------------------------------------------------------------
// check for player in water
//----------------------------------------------------------------------------------------------
water_trigger()
{
	self endon( "death" );

	while ( 1 )
	{
		self waittill( "trigger", who );
		
		if ( IsPlayer( who ) && who.sessionstate != "spectator")
		{
	
			self thread trigger_thread( who, ::water_player_in, ::water_player_out );
			
			//who thread water_damage_player();
		}
		//else 
		//{
		//	who thread water_damage_zombie();
		//}
	}
}

//----------------------------------------------------------------------------------------------
// player has entered the water
//----------------------------------------------------------------------------------------------

update_hud_elem(player)
{
	player endon("disconnect");
	player endon("death");
	
	while(1)
	{
		wait(0.1);
		player notify("update_frost_state");
	}
}

water_debug_hud_elem_thread(player)
{
	player endon("disconnect");
	player endon("death");
	self thread update_hud_elem(player);
	while(1)
	{
		if(IsDefined(player._in_coast_water))
		{
			self SetValue(player._in_coast_water);
			PrintLn("player " + player GetEntityNumber() + " updates hud");
		}
		player waittill("update_frost_state");
	}
}

water_player_in( e_player, endon_condition )
{
	if( !IsDefined( e_player._in_coast_water ) || e_player._in_coast_water == 0)
	{
		e_player._in_coast_water = 0;
		e_player thread water_watch_player_frost_state();
		
/*		if(!IsDefined(e_player._water_debug_hudelem))
		{
			e_player._water_debug_hudelem = NewDebugHudElem();
			e_player._water_debug_hudelem.alignX = "center";
			e_player._water_debug_hudelem.alignY = "middle";
			e_player._water_debug_hudelem.horzAlign = "center";
			e_player._water_debug_hudelem.vertAlign = "middle";
			e_player._water_debug_hudelem.x = -100 + (e_player GetEntityNumber() * 64);
			e_player._water_debug_hudelem.y = 16;
			e_player._water_debug_hudelem.sort = 2;
			e_player._water_debug_hudelem thread water_debug_hud_elem_thread(e_player);
		}*/
	}
	
	// entered a trigger
	e_player._in_coast_water++;
	
//	e_player thread play_cold_dialog_while_inwater();
}

//----------------------------------------------------------------------------------------------
// frost stop player out water
//----------------------------------------------------------------------------------------------
water_player_out( e_player )
{
	
	// left a trigger
	if(e_player._in_coast_water > 0)
	{
		e_player._in_coast_water--;
	}
}

//----------------------------------------------------------------------------------------------
// watches for the _in_coast_water number and has cSc start or stop frost accordingly
//----------------------------------------------------------------------------------------------
water_watch_player_frost_state()
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "spawned_spectator" );

	frost = 0;
	
//	PrintLn("S: ccf pwf : " + self GetEntityNumber() + " " + self.team + " " + self.sessionteam + " " + self.sessionstate);
	self ClearClientFlag( level._CF_PLAYER_WATER_FROST );
	
	self thread play_cold_dialog_while_inwater();
	
	while( IsDefined( self ) && IsAlive( self ) )
	{
		if( frost )
		{
			// check to see if frost should be off
			if( IsDefined( self._in_coast_water ) && self._in_coast_water < 1 )
			{
				// turn off reset function
				self notify( "frost_reset_off" );
				
				// turn off frost
//				PrintLn("S: ccf pwf2 : " + self GetEntityNumber()+ " " + self.team + " " + self.sessionteam + " " + self.sessionstate);
				self ClearClientFlag( level._CF_PLAYER_WATER_FROST );
				frost = 0;
				
//				IPrintLn( self GetEntityNumber() + " FROST CLEARED %%%" );
				return;
			}
		}
		else
		{
			// check to see if frost should be on
			if( IsDefined( self._in_coast_water ) && self._in_coast_water > 0 )
			{
				// thread function to clear frost if the player bleeds out
				// self thread water_frost_bleed_out_reset();
				
				// turn on frost
//				PrintLn("S: scf pwf : " + self GetEntityNumber() + " " + self.team + " " + self.sessionteam + " " + self.sessionstate);
				self SetClientFlag( level._CF_PLAYER_WATER_FROST );
				frost = 1;
				
//				IPrintLn( self GetEntityNumber() + " FROST SET %%%" );
			}
		}
		self wait_to_update_frost_state();
	}
}

wait_to_update_frost_state()
{
	self endon("disconnect");
	self endon("update_frost_state");
	
	wait(0.1);
}

//----------------------------------------------------------------------------------------------
// a player that bleeds out should have the frost removed from their screen
//----------------------------------------------------------------------------------------------
water_frost_bleed_out_reset()
{
//	PrintLn("S: scf pwfr : " + self GetEntityNumber() + " " + self.team + " " + self.sessionteam + " " + self.sessionstate);
	self SetClientFlag( level._CF_PLAYER_WATER_FROST_REMOVE );
	wait_network_frame();
	self._in_coast_water = 0;
	self notify("update_frost_state");
	wait_network_frame();
//	PrintLn("S: ccf pwfr : " + self GetEntityNumber() + " " + self.team + " " + self.sessionteam + " " + self.sessionstate);
	self ClearClientFlag( level._CF_PLAYER_WATER_FROST_REMOVE );
	
	wait_network_frame();
	wait_network_frame();
}


//----------------------------------------------------------------------------------------------
// damage zombie in water
//----------------------------------------------------------------------------------------------
water_damage_zombie()
{
	self endon( "death" );

	if ( is_true( self.ignore_water_damage ) )
	{
		return;
	}

	// the water damage comes from a player to prevent the freeze shatter damage indicator
	players = getplayers();

	if( !isDefined( self.is_freezing ) )
	{
		self.is_freezing = 1;

		wait( 3 );

		if ( isDefined( self.is_freezing ) )
		{
			freeze_health = level.zombie_health * level.water_zombie_percent;

			if ( self.health <= freeze_health )
			{
				self.water_damage = true;

				if ( players.size > 0 )
				{
					self dodamage( freeze_health, self.origin, players[0] );
				}
				else
				{
					self dodamage( freeze_health, self.origin );
				}
			}

			self.is_freezing = undefined;
		}

		/*
		if ( self.health > level.water_zombie_damage )
		{
			self dodamage( level.water_zombie_damage, self.origin );
		}
		else
		{
			// back in queue
			level.zombie_total++;

			self.water_damage = true;
			if ( players.size > 0 )
			{
				self dodamage( level.water_zombie_damage, self.origin, players[0] );
			}
			else
			{
				self dodamage( level.water_zombie_damage, self.origin );
			}
		}

		wait( 1 );
		self.is_freezing = undefined;
		*/
	}
}

wade_trigger()
{
	//self endon( "death" );

	while(1)
	{
		self waittill( "trigger", who );

		if ( isplayer( who ) && ( !IsDefined( who._wading_active ) || !who._wading_active ) )
		{
			who thread wade_audio( self );
		}
	}
}

wade_audio( trigger )
{
  self endon( "death" );
	self endon( "disconnect" );
	
	if( !IsDefined( self._wading_active ) || !self._wading_active )
	{
	    self._wading_active = true;
	    self.is_wading = true;
	    
	    ent1 = Spawn( "script_origin", self.origin );
	    ent2 = Spawn( "script_origin", self.origin );
	    ent1 LinkTo( self );
	    ent2 LinkTo( self );

	    self thread monitor_player_movement();
	    
	    while( self IsTouching( trigger ) )
	    {
	        if( self.is_wading )
	        {
	            ent2 StopLoopSound( 1 );
	            ent1 PlayLoopSound( "zmb_wade", 1 );
	        }
	        else
	        {
	            ent1 StopLoopSound( 1 );
	            ent2 PlayLoopSound( "zmb_wade_idle", 1 );
	        }
	        
	        wait(.1);
	    }
	    
	    self._wading_active = false;
	    ent1 StopLoopSound( 1 );
	    ent2 StopLoopSound( 1 );
	    wait(1);
	    ent1 Delete();
	    ent2 Delete();
	}
}

monitor_player_movement()
{
	self endon( "disconnect" );
	self endon( "death" );

	while( self._wading_active )
	{
		org_1 = self.origin;
		wait(.1);
		org_2 = self.origin;
		distancemoved = distanceSquared( org_1, org_2 );
		if(distancemoved > 2*2)
		{
			self.is_wading = true;	
		} 
		else
		{
			self.is_wading = false;	
		}	
	}		
}

play_cold_dialog_while_inwater()
{
  self notify( "audio_coldwater_dupe" );
  self endon( "audio_coldwater_dupe" );
  self endon( "disconnect" );
	self endon( "death" );
	self endon( "spawned_spectator" );
	self endon( "joined_spectators" );
    
    wait(RandomIntRange(2,5));
    
    while( IsDefined( self._in_coast_water ) && self._in_coast_water > 0 )
    {   
        while( is_true( self.is_frozen ) )
        {
            wait(1);
        }
        
        rand = RandomIntRange(0,101);
        
        if( !IsAlive( self ) || ( IsDefined( self.sessionstate ) && is_true( self.sessionstate == "spectator" ) ) )
        {
            return;
        }
        
        if( rand >= 25 )
        {
            self maps\_zombiemode_audio::create_and_play_dialog( "general", "water_damage" );
        }
        
        wait(RandomIntRange(15,30));
    }
}

water_watch_freeze()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	self notify("water_watch_freeze_start");	// Make sure that there's only one of these...
 	self endon("water_watch_freeze_start");
 	
 
	time_in_water = 0;
	time_to_freeze = 30000;

	if ( is_true( level.debug_water ) )
	{
		time_to_freeze = 3000;
	}

	startTime = GetTime();
	nextTime = GetTime();

	while ( 1 )
	{
		if ( isDefined( self._in_coast_water ) )
		{
			diff = nextTime - startTime;
			if ( self._in_coast_water > 0 )
			{
				time_in_water += diff;
				if ( time_in_water > time_to_freeze )
				{
					self PlayLoopSound("zmb_ice_effect_loop" , 2);
					self thread water_player_freeze();
					return;
				}
			}
			else
			{
				if ( time_in_water > 0 )
				{
					time_in_water -= diff;
					if ( time_in_water < 0 )
					{
						self StopLoopSound(2);
						time_in_water = 0;
					}
				}
			}
		}

		startTime = GetTime();
		wait(0.1);
		nextTime = GetTime();
	}
}

water_player_freeze()
{
	self endon( "death" );
	self endon( "disconnect" );
    
	self.is_frozen = true;
	self EnableInvulnerability();
	self FreezeControls( true );
	
	self StopLoopSound(2);
	ice_trigger = spawn( "trigger_damage", self.origin, 0, 15, 72 );
	ice_trigger enablelinkto();
	ice_trigger linkto( self );

	self.ice_trigger = ice_trigger;

//	PrintLn("S: scf pwfreeze : " + self GetEntityNumber());
	self SetClientFlag( level._CF_PLAYER_WATER_FREEZE );
	
	self thread maps\_zombiemode_audio::create_and_play_dialog( "general", "water_frozen" );

	self thread water_player_free( ice_trigger );
}

water_player_free( ice_trigger )
{
	self endon( "death" );
	self endon( "disconnect" );

	ice_trigger waittill( "damage" );
	
	self PlaySound("zmb_ice_shatter");

	self.is_frozen = false;
	self DisableInvulnerability();
	self FreezeControls( false );

	if ( isDefined( self.ice_trigger ) )
	{
		self.ice_trigger delete();
		self.ice_trigger = undefined;
	}

//	PrintLn("S: ccf pwfreeze : " + self GetEntityNumber());
	self ClearClientFlag( level._CF_PLAYER_WATER_FREEZE );

	self thread water_watch_freeze();
}






