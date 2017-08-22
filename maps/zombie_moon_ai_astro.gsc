#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

//-----------------------------------------------------------------
// setup astro for moon
//-----------------------------------------------------------------
init()
{
	level.astro_zombie_enter_level = ::moon_astro_enter_level;
}

zombie_set_fake_playername()
{
	self SetHUDWarningType( "zombie_friend" );
	self setzombiename( "SpaceZom" );
}


//-----------------------------------------------------------------
// teleport astro to struct after spawning in
//-----------------------------------------------------------------
moon_astro_enter_level()
{
	self endon( "death" );

	self Hide();

	self.entered_level = true;

	astro_struct = self moon_astro_get_spawn_struct();

	if ( isdefined( astro_struct ) )
	{
		self ForceTeleport( astro_struct.origin, astro_struct.angles );
		wait_network_frame();
	}

	Playfx( level._effect["astro_spawn"], self.origin );
	self playsound( "zmb_hellhound_bolt" );
	self playsound( "zmb_hellhound_spawn" );
	PlayRumbleOnPosition("explosion_generic", self.origin);
	self playloopsound( "zmb_zombie_astronaut_loop", 1 );
	
	self thread play_line_if_player_can_see();
	self zombie_set_fake_playername();

	wait_network_frame();

	self Show();
}

play_line_if_player_can_see()
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if( distancesquared( self.origin, players[i].origin ) <= 800*800 )
		{
			cansee = self maps\zombie_moon_distance_tracking::player_can_see_me( players[i] );
			if( cansee )
			{
				players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "astro_spawn" );
				return;
			}
		}
	}	
}

//-----------------------------------------------------------------
// spawn astro in an occupied or adjacent zone
//-----------------------------------------------------------------
moon_astro_get_spawn_struct()
{
	keys = GetArrayKeys( level.zones );

	for ( i = 0; i < level.zones.size; i++ )
	{
		if ( keys[i] == "nml_zone" )
		{
			continue;
		}

		if ( level.zones[ keys[i] ].is_occupied )
		{
			locs = getstructarray( level.zones[ keys[i] ].volumes[0].target + "_astro", "targetname" );
			if ( isdefined( locs ) && locs.size > 0 )
			{
				locs = array_randomize( locs );
				return locs[0];
			}
		}
	}

	// no structs in occupied zones try adjacent
	for ( i = 0; i < level.zones.size; i++ )
	{
		if ( keys[i] == "nml_zone" )
		{
			continue;
		}

		if ( level.zones[ keys[i] ].is_active )
		{
			locs = getstructarray( level.zones[ keys[i] ].volumes[0].target + "_astro", "targetname" );
			if ( isdefined( locs ) && locs.size > 0 )
			{
				locs = array_randomize( locs );
				return locs[0];
			}
		}
	}


	maps\_zombiemode_ai_astro::_debug_astro_print( "no astro structs found" );

	return undefined;
}

