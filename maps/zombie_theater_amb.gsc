//
// file: zombie_pentagon_amb.gsc
// description: level ambience script for zombie_pentagon
// scripter: 
//
#include common_scripts\utility;
#include maps\_utility;
#include maps\_ambientpackage;
#include maps\_music; 
#include maps\_zombiemode_utility; 
#include maps\_busing;


main()
{	
	level thread setup_power_on_sfx();
	level thread play_projecter_loop();
	level thread play_projecter_soundtrack();
	level thread setup_meteor_audio();
	level thread setup_radio_egg_audio();
	array_thread( GetEntArray( "portrait_egg", "targetname" ), ::portrait_egg_vox );
	array_thread( GetEntArray( "location_egg", "targetname" ), ::location_egg_vox );
}

setup_power_on_sfx()
{
	wait(5);
	sound_emitters = getstructarray ("amb_power", "targetname");
	flag_wait("power_on");

	if(level.gamemode != "survival")
	{
		level thread play_evil_generator_audio();
	}
	
	for(i=0;i<sound_emitters.size;i++)
	{
		sound_emitters[i] thread play_emitter();	
	}	
}

play_emitter()
{
	wait (randomfloatrange (0.1, 1));
	playsoundatposition ("amb_circuit", self.origin);
	wait (randomfloatrange (0.05, 0.5));
	soundloop = spawn ("script_origin", self.origin);
	soundloop playloopsound (self.script_sound);	
}

play_evil_generator_audio()
{
	playsoundatposition ("evt_flip_sparks_left", (-544, 1320, 32));
	playsoundatposition ("evt_flip_sparks_right", (-400, 1320, 32));
	
	wait(2);
	
	playsoundatposition ("evt_crazy_power_left", (-304, 1120, 344));
	playsoundatposition ("evt_crazy_power_right", (408, 1136, 344));

	wait(13);
	
	playsoundatposition ("evt_crazy_power_left_end", (-304, 1120, 344));
	playsoundatposition ("evt_crazy_power_right_end", (408, 1136, 344));	
	playsoundatposition ("evt_flip_switch_laugh_left", (-536, 1336, 704));
	playsoundatposition ("evt_flip_switch_laugh_right", (576, 1336, 704));
	
	level notify("generator_done");
}

play_projecter_soundtrack()
{
	/*if(GetDvar("zm_gamemode") != "survival")
	{
		return;
	}*/
	level waittill("generator_done");
	wait(20);
	//TEMP 
	speaker = spawn ("script_origin", (32, 1216, 592));
	speaker playloopsound ("amb_projecter_soundtrack");	
}

play_projecter_loop()
{
	/*if(GetDvar("zm_gamemode") != "survival")
	{
		return;
	}*/
	level waittill("generator_done");
	projecter = spawn ("script_origin", (-72, -144, 384));
	projecter playloopsound ("amb_projecter");
}

setup_meteor_audio()
{
    wait(1);
    level.meteor_counter = 0;
    level.music_override = false;
    array_thread( GetEntArray( "meteor_egg_trigger", "targetname" ), ::meteor_egg );
}

play_music_easter_egg( player )
{
	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "egg" );
	
	wait(4);
	
	if( IsDefined( player ) )
	{
	    player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "music_activate" );
	}
	
	wait(236);	
	level.music_override = false;
	level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

	level thread setup_meteor_audio();
}

meteor_egg()
{
	if( !isdefined( self ) )
	{
		return;
	}	
	
	self UseTriggerRequireLookAt();
	self SetCursorHint( "HINT_NOICON" );

	if(GetDvar("zm_gamemode") != "survival")
	{
		return;
	}

	self PlayLoopSound( "zmb_meteor_loop" );
		
	self waittill( "trigger", player );
	
	self StopLoopSound( 1 );
	player PlaySound( "zmb_meteor_activate" );
	
	player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "meteors", undefined, level.meteor_counter );
		
	level.meteor_counter++;
	
	if( level.meteor_counter == 3 )
	{ 
	    level thread play_music_easter_egg( player );
	}
}

portrait_egg_vox()
{
    if( !isdefined( self ) )
	{
		return;
	}	
	
	self UseTriggerRequireLookAt();
	self SetCursorHint( "HINT_NOICON" );

	if(GetDvar("zm_gamemode") != "survival")
	{
		return;
	}
		
	self waittill( "trigger", player );
	
	type = "portrait_" + self.script_noteworthy;
	
	player maps\_zombiemode_audio::create_and_play_dialog( "eggs", type );
}

location_egg_vox()
{
	if(GetDvar("zm_gamemode") != "survival")
	{
		return;
	}

    self waittill( "trigger", player );
    
    if( RandomIntRange(0,101) >= 90 )
    {
        type = "room_" + self.script_noteworthy;
        player maps\_zombiemode_audio::create_and_play_dialog( "eggs", type );
    }
}

play_radio_egg( delay )
{
    if( IsDefined( delay ) )
    {
        wait( delay );
    }
    
    if( !IsDefined( self ) )
        return;
    
    self PlaySound( "vox_zmb_egg_0" + level.radio_egg_counter );
    level.radio_egg_counter++;
}

setup_radio_egg_audio()
{
    wait(1);
    level.radio_egg_counter = 0;
    array_thread( GetEntArray( "audio_egg_radio", "targetname" ), ::radio_egg_trigger );
}

radio_egg_trigger()
{
    if( !IsDefined( self ) )
        return;

	if(level.gamemode != "survival")
	{
		return;
	} 
    
    self waittill( "trigger", who );
    who thread play_radio_egg();
}