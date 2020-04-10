#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;
#include maps\_ambientpackage; 


main()
{
    level thread monkey_round_announcer();
    level thread radio_easter_eggs();
    level thread setup_teddybear_audio();
    level thread init_redphone_eggs();
    level thread init_doll_eggs();
}

power_clangs()
{
	clangs = getstructarray("amb_power_clang", "targetname");
	
	if(clangs.size)
	{
	   //playsoundatposition ("zmb_ann_vox_laugh_l", clangs[0].origin);
	}
	for (i=0; i < clangs.size; i++) 
	{
		playsoundatposition ("zmb_circuit", clangs[i].origin);
		wait ( RandomFloatrange( 0.25, 0.7 ));
	}
}

play_cosmo_announcer_vox( alias, alarm_override, wait_override )
{
	if( !IsDefined( alias ) )
		return;

    if(level.gamemode != "survival")
    {
        return;
    }
	
	if( !IsDefined( level.cosmann_is_speaking ) )
	{
		level.cosmann_is_speaking = 0;
	}
	
	if( !IsDefined( alarm_override ) )
	    alarm_override = false;
	    
	if( !IsDefined( wait_override ) )
	    wait_override = false;    
	
	if( (level.cosmann_is_speaking == 0) && (wait_override == false) )
	{
		level.cosmann_is_speaking = 1;
		
		if( !alarm_override )
		    level play_initial_alarm();
		
		level really_play_2D_sound( alias );
		level.cosmann_is_speaking =0;
	}
	else if( wait_override == true )
	{
	    level really_play_2D_sound( alias );
	}
}

play_gersh_vox( alias )
{
    if( !IsDefined( alias ) )
		return;
	
	if( !IsDefined( level.gersh_is_speaking ) )
	{
		level.gersh_is_speaking = 0;
	}
	
	if( level.gersh_is_speaking == 0 )
	{
		level.gersh_is_speaking = 1;
		level really_play_2D_sound( alias );
		level.gersh_is_speaking =0;
	}
}

play_initial_alarm()
{
    structs = getstructarray( "amb_warning_siren", "targetname" );
    
    for(i=0;i<structs.size;i++)
    {
        playsoundatposition( "evt_cosmo_alarm_single", structs[i].origin );
    }
    
    wait(.5);
}

monkey_round_announcer()
{
    wait(3);
    
    while(1)
    {
        flag_wait( "monkey_round" );
        
        level thread play_cosmo_announcer_vox( "vox_ann_monkey_begin" );
        
        //flag_wait( "last_monkey_down" );
        level waittill ( "between_round_over" );
        
        level thread play_cosmo_announcer_vox( "vox_ann_monkey_end" );
        
        wait(10);
    }
}

radio_easter_eggs()
{
    wait(3);
    
    //Check to see if this has been BSP'd yet
    testent = GetEnt( "radio_egg_1", "targetname" );
    
    if( !IsDefined( testent ) )
        return;
    
    for(i=1;i<7;i++)
    {
        ent[i] = GetEnt( "radio_egg_" + i, "targetname" );
        ent[i] Hide();
    }

    if(level.gamemode != "survival")
    {
        return;
    }
    
    level thread activate_radio_egg( 1 );
}

activate_radio_egg( num )
{
    radio = GetEnt( "radio_egg_" + num, "targetname" );
    radio Show();
    radio_trig = Spawn( "trigger_radius", radio.origin - (0,0,200), 0, 75, 400 );
    radio_trig.completed = false;
    
    while(1)
    {
        radio_trig waittill( "trigger", who );
        
        while( who IsTouching( radio_trig ) )
        {
            if( who UseButtonPressed() )
            {
                radio_trig.completed = true;
                break;
            }
            
            wait(.05);
        }
        
        if( radio_trig.completed == true )
            break;
    }
    
    radio_trig Delete();
    radio PlaySound( "vox_radio_egg_" + num );
    
    if( num == 6 )
    {
        return;
    }
    
    level thread activate_radio_egg( num + 1 );
}

setup_teddybear_audio()
{
    wait(3);
    level.teddybear_counter = 0;
    level.music_override = false;
    array_thread( GetEntArray( "mus_teddybear", "targetname" ), ::teddybear_egg );
    //Make the Teddy Bear Dance in this function
    //array_thread( GetEntArray( "mus_teddybear", "targetname" ), ::dancing_teddy_bear );
}

teddybear_egg()
{
    if( !isdefined( self ) )
	{
		return;
	}

    if(level.gamemode != "survival")
    {
        return;
    }
	
	self PlayLoopSound( "zmb_meteor_loop" );
		
	player = self teddybear_egg_wait();
	
	self StopLoopSound( 1 );
	player PlaySound( "zmb_meteor_activate" );
	
	player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "meteors", undefined, level.meteor_counter );
		
	level.teddybear_counter++;
	
	if( level.teddybear_counter == 3 )
	{ 
	    level thread play_music_easter_egg( player );
	    level notify( "teddybear_music_started" );
	}
}

teddybear_egg_wait()
{
    teddybear_trig = Spawn( "trigger_radius", self.origin - (0,0,200), 0, 50, 400 );
    teddybear_trig.completed = false;
    
    while(1)
    {
        teddybear_trig waittill( "trigger", who );
        
        while( who IsTouching( teddybear_trig ) )
        {
            if( who UseButtonPressed() )
            {
                teddybear_trig.completed = true;
                break;
            }
            
            wait(.05);
        }
        
        if( teddybear_trig.completed == true )
            break;
    }
    
    teddybear_trig Delete();
    
    return who;
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
	
	wait(367);	
	level.music_override = false;
	
	if( level.monkey_intermission == false && level.music_round_override == false )
	    level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

    level thread setup_teddybear_audio();
}

dancing_teddy_bear()
{
    level waittill( "teddybear_music_started" );
    self moveto( self.origin + (0,0,50), 2 );
    self waittill("movedone");

    angles = self.angles;
    self RotateVelocity( (20,45,35), 369 );

    wait(369);

    self RotateTo(angles, 1);
    self waittill("rotatedone");
    self moveto( self.origin - (0,0,50), 2 );
    self waittill("movedone");
}

init_redphone_eggs()
{
    if(GetDvar("zm_gamemode") != "survival")
    {
        return;
    }

    wait(10);
    
    redphone_egg_array = [];
    
    for(i=0;i<3;i++)
    {
        redphone_egg_array[i] = getstruct( "egg_phone_" + i, "targetname" );
        redphone_egg_array[i].num = i;
    }
    
    level thread redphone_egg( redphone_egg_array );
}

redphone_egg( array )
{
    wait_min = 120;
    wait_max = 300;
    ring_time = 10;
    activation = undefined;
    
    wait( RandomIntRange( wait_min, wait_max ) );
    
    while( array.size > 0 )
    {
        phone = random( array );
        
        if( IsDefined( phone ) )
        {
            activation = phone wait_for_redphone_trigger( ring_time );
        }
        
        if( !activation )
        {
            wait( RandomIntRange( wait_min, wait_max ) );
        }
        else if( activation )
        {
            playsoundatposition( "vox_redphone_egg_" + phone.num, phone.origin );
            array = array_remove( array, phone );
        }
    }
}

wait_for_redphone_trigger( ring_time )
{
    redphone_trig = Spawn( "trigger_radius", self.origin - (0,0,200), 0, 75, 400 );
    redphone_trig.failsafe = false;
    looper = Spawn( "script_origin", self.origin );
    looper PlayLoopSound( "zmb_egg_phone_loop", .05 );
    redphone_trig thread redphone_timeout_failsafe( ring_time );
    
    while(1)
    {
        redphone_trig waittill( "trigger", who );
        
        if( !IsDefined( who ) ) 
        {
            level notify( "redphone_egg_end_failsafe" );
            redphone_trig Delete();
            looper Delete();
            return false;
        }
        
        while( who IsTouching( redphone_trig ) )
        {   
            if( who UseButtonPressed() )
            {
                level notify( "redphone_egg_end_failsafe" );
                redphone_trig Delete();
                looper Delete();
                return true;
            }
            
            wait(.05);
            
            if( redphone_trig.failsafe == true )
            {
                redphone_trig Delete();
                looper Delete();
                return false;
            }
        }
    }
}

redphone_timeout_failsafe( time )
{
    level endon( "redphone_egg_end_failsafe" );
    
    wait(time);
    self notify( "trigger", undefined );
    self.failsafe = true;
}

init_doll_eggs()
{
    wait(10);
    
    for(i=0;i<4;i++)
    {
        ent = GetEnt( "doll_egg_" + i, "targetname" );
        
        if( !IsDefined( ent ) )
            return;
        
        ent thread doll_egg( i );
    }
}

doll_egg( num )
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

	alias = undefined;
    
    while(1)
    {
        self waittill( "trigger", player );
        
        switch( player.entity_num )
        {
            case 0:
                alias = "vox_egg_doll_response_" + num + "_0";
                break;
            case 1:
                alias = "vox_egg_doll_response_" + num + "_1";
                break;
            case 2:
                alias = "vox_egg_doll_response_" + num + "_2";
                break;
            case 3:
                alias = "vox_egg_doll_response_" + num + "_3";
                break;
        }
        
        self PlaySound( alias, "sounddone" + alias );
        self waittill( "sounddone" + alias );
        
        player maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", "dolls" );
        
        wait( 8 );
    }
}