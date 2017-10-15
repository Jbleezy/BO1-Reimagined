//
// file: zombie_pentagon_amb.gsc
// description: level ambience script for zombie_pentagon
// scripter: 
//

#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;
#include maps\_ambientpackage;


main()
{
	level thread setup_phone_audio();
}
//-------------------------------------------------------------------------------
// base function for easter egg phones in zombie pentagon.
//-------------------------------------------------------------------------------
setup_phone_audio()
{
    wait(1);
    level.phone_counter = 0;
    array_thread( GetEntArray( "secret_phone_trig", "targetname" ), ::phone_egg );
}
phone_egg()
{
	if( !isdefined( self ) )
	{
		return;
	}

	self UseTriggerRequireLookAt();
	self SetCursorHint( "HINT_NOICON" );

	if(level.gamemode != "survival")
	{
		return;
	}

	phone = GetEnt(self.target, "targetname");
	if(IsDefined(phone))
	{
		blinky = PlayFXOnTag( level._effect["fx_zombie_light_glow_telephone"], phone, "tag_light" );
	}

	self PlayLoopSound( "zmb_egg_phone_loop" );
		
	self waittill( "trigger", player );
	
	self StopLoopSound( 1 );
	player PlaySound( "zmb_egg_phone_activate" );
		
	level.phone_counter = level.phone_counter + 1;
	
	if( level.phone_counter == 3 )
	{ 
		level pentagon_unlock_doa();
	    playsoundatposition( "evt_doa_unlock", (0,0,0) );
	    wait(5);
	    level thread play_music_easter_egg();
	}
}
play_music_easter_egg()
{
	level.music_override = true;
	
	if( is_mature() )
	{
	    level thread maps\_zombiemode_audio::change_zombie_music( "egg" );
	}
	else
	{
	    //UNTIL WE GET THE SAFE VERSION OF THE SONG, THIS EASTER EGG WILL DO NOTHING FOR PEOPLE IN SAFE MODE
	    level.music_override = false;
	    return;
	    //level thread maps\_zombiemode_audio::change_zombie_music( "egg_safe" );
	}
	
	wait(265);	
	level.music_override = false;
	level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

	level thread setup_phone_audio();
}
//-------------------------------------------------------------------------------

play_pentagon_announcer_vox( alias, defcon_level )
{
	if( !IsDefined( alias ) )
		return;
	
	if( !IsDefined( level.pentann_is_speaking ) )
	{
		level.pentann_is_speaking = 0;
	}
	
	if( IsDefined( defcon_level ) )
	    alias = alias + "_" + defcon_level;
	
	if( level.pentann_is_speaking == 0 )
	{
		level.pentann_is_speaking = 1;
		level play_initial_alarm();
		level play_sound_2D( alias );
		level.pentann_is_speaking =0;
	}
}

play_initial_alarm()
{
    structs = getstructarray( "defcon_alarms", "targetname" );
    
    for(i=0;i<structs.size;i++)
    {
        playsoundatposition( "evt_thief_alarm_single", structs[i].origin );
    }
    
    wait(.5);
}

// ww: unlocks doa for all players upon finding the easter egg
pentagon_unlock_doa()
{
	level.ZOMBIE_PENTAGON_PLAYER_CF_UPDATEPROFILE = 0;
	
	players = get_players();
	
	array_thread( players, ::pentagon_delay_update );
}

// ww: updates gamer profile
pentagon_delay_update()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	self SetClientDvars( "zombietron_discovered", 1 );
	
	wait( 0.2 );
	
	self SetClientFlag( level.ZOMBIE_PENTAGON_PLAYER_CF_UPDATEPROFILE );
}