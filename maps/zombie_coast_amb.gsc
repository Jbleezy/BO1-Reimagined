#include common_scripts\utility; 
#include maps\_utility;

main()
{
    level._audio_custom_weapon_check = ::weapon_type_check_custom;
    level._audio_custom_response_line = ::setup_response_line_custom;
    level._audio_director_vox = ::director_vox_init;
    level._audio_director_vox_play = ::do_director_playvox;
    
    //SKITS
    level.AUDIO_last_d = undefined;
    level.AUDIO_current_character = undefined;
    level.door_trig = GetEnt( "trig_start_voices", "targetname" );
    level.skit_vox_override = false;
    
    level thread power_clangs();
    
    //EASTER EGG SCRIPTS
    level thread radio_easter_eggs();
    level thread setup_music_egg();
}

power_clangs()
{
	wait(5);
	flag_wait( "power_on" );
	
	clangs = getstructarray("amb_power_clang", "targetname");
	
	if( !IsDefined( clangs ) )
	    return;
	
	for (i=0; i < clangs.size; i++) 
	{
		playsoundatposition ("zmb_circuit", clangs[i].origin);
		wait ( RandomFloatrange( 0.25, 0.7 ));
	}
}

//START Coast VO Overrides
weapon_type_check_custom(weapon)
{
    if( !IsDefined( self.entity_num ) )
        return "crappy";    
    
    switch(self.entity_num)
    {
        case 0:   //SARAH'S FAVORITE WEAPON: SPECTRE SMG UPGRADED: SPECTRE SMG
            if( weapon == "spectre_zm" )
                return "favorite";
            else if( weapon == "spectre_upgraded_zm" )
                return "favorite_upgrade";   
            break;
            
        case 1:   //ENGLUND'S FAVORITE WEAPON: FNFAL UPGRADED: HK21
            if( weapon == "rpk_zm" )
                return "favorite";
            else if( weapon == "rpk_upgraded_zm" )
                return "favorite_upgrade";   
            break;
            
        case 2:   //TREJO'S FAVORITE WEAPON: MP40 UPGRADED: CROSSBOW
            if( weapon == "ak74u_zm" )
                return "favorite";
            else if( weapon == "ak74u_upgraded_zm" )
                return "favorite_upgrade";   
            break; 
        
        case 3:   //ROOKER'S FAVORITE WEAPON: M202 UPGRADED: THUNDERGUN
            if( weapon == "ithaca_zm" )
                return "favorite";
            else if( weapon == "ithaca_upgraded_zm" )
                return "favorite_upgrade";   
            break;               
    }
    
    if( IsSubStr( weapon, "upgraded" ) )
        return "upgrade";
    else
        return level.zombie_weapons[weapon].vox;
}

setup_response_line_custom( player, index, category, type )
{
	Sarah = 0;
	Englund = 1;
	Rooker = 3;
	Trejo = 2;
	
	switch( player.entity_num )
	{
		case 0:
			level maps\_zombiemode_audio::setup_hero_rival( player, Trejo, Rooker, category, type );
		break;
		
		case 1:
			level maps\_zombiemode_audio::setup_hero_rival( player, Rooker, Trejo, category, type );
		break;
		
		case 2:
			level maps\_zombiemode_audio::setup_hero_rival( player, Sarah, Englund, category, type );
		break;
		
		case 3:
			level maps\_zombiemode_audio::setup_hero_rival( player, Englund, Sarah, category, type );
		break;
	}
	return;
}
//END Coast VO Overrides

//START Director Vox

//SELF == Director Zombie
director_vox_init()
{
    self thread director_intro_vox();
}

director_vox_futz()
{
    self endon( "death" );
    level endon( "director_submerging_audio" );
    
    while( !is_true( self.defeated ) )
    {
        level clientNotify( "dclm" );
        self waittill( "director_activated" );
        level clientNotify( "dmad" );
        self waittill( "director_calmed" );
    }
}

director_intro_vox()
{
    self endon( "death" );
	level endon( "end_game" );

    while(1)
    {
        level waittill( "audio_begin_director_vox" );
        
        wait(RandomFloatRange(1,3) );
    
        self create_and_play_director_vox( "start", 0 );
        wait(2);
        self create_and_play_director_vox( "start", 1 );
        wait(2);
        self create_and_play_director_vox( "start", 2 );
        
        self thread director_ambient_vox();
        self thread wait_for_anger();
        self thread wait_for_calm();
        self thread init_director_behind_vox();
        self thread wait_for_submerge();
        //self thread director_vox_futz();
    }
}

wait_for_submerge()
{
	self endon( "death" );

    level waittill( "director_submerging_audio" );
    
    wait(9);
        
    self create_and_play_director_vox( "lucid" );
}

wait_for_anger()
{
    self endon( "death" );
    level endon( "director_submerging_audio" );
	level endon( "end_game" );
    
    while( !is_true( self.defeated ) )
    {
        self waittill( "director_activated" );
        self thread director_angry_vox();
    }
}

wait_for_calm()
{
    self endon( "death" );
    level endon( "director_submerging_audio" );
	level endon( "end_game" );
    
    while( !is_true( self.defeated ) )
    {
        self waittill( "director_calmed" );
        
        if( IsDefined( self.damageweapon ) && ( self.damageweapon == "humangun_upgraded_zm" || self.damageweapon == "humangun_zm" ) )
        {
            self create_and_play_director_vox( "human" );
        }
        else
        {
            self create_and_play_director_vox( "water" );
        }
        
        self thread director_ambient_vox();
    }
}

director_ambient_vox()
{
    self notify( "director_ambient_vox" );
    self endon( "death" );
    self endon( "director_activated" );
    self endon( "director_ambient_vox" );
    level endon( "director_submerging_audio" );
	level endon( "end_game" );
    
    while( !is_true( self.defeated ) )
    {
        wait( RandomIntRange( 25, 70 ) );
        
        players = getplayers();
        for(i=0;i<players.size;i++)
        {
            if( DistanceSquared( self.origin, players[i].origin ) <= 500*500 )
            {
                self create_and_play_director_vox( "find" );
                continue;
            }
        }
        
        rand = RandomIntRange(0,100);
        
        if( rand <= 25 )
        {
            self create_and_play_director_vox( "search" );
        }
        else
        {
            self create_and_play_director_vox( "taunt" );
        }
    }
}

director_angry_vox()
{
    self notify( "director_angry_vox" );
    self endon( "death" );
    self endon( "director_calmed" );
    self endon( "director_angry_vox" );
    level endon( "director_submerging_audio" );
	level endon( "end_game" );
    
    while( !is_true( self.defeated ) )
    {
        wait( RandomIntRange( 10, 25 ) );
        
        rand = RandomIntRange( 0, 100 );
        if( rand <= 34 )
        {
            self create_and_play_director_vox( "react" );
        }
        else
        {
            self create_and_play_director_vox( "angry" );
        }
    }
}

init_director_behind_vox()
{
	players = get_players(); 
	for( i = 0; i < players.size; i++ )
	{
		players[i] thread director_behind_vox( self );
	}
}

//Plays a specific Zombie vocal when they are close behind the player
//Self is the Player(s)
director_behind_vox( director )
{
	self endon("disconnect");
	self endon("death");
	level endon( "director_submerging_audio" );
	self endon( "_zombie_game_over" );
	level endon( "end_game" );
	
	dist = 350;
	
	while( !is_true( self.defeated ) )
	{
		wait(4);		
					
		if(DistanceSquared(director.origin,self.origin) < dist * dist )
		{				
			yaw = self animscripts\utility::GetYawToSpot(director.origin );
			z_diff = self.origin[2] - director.origin[2];
			if( (yaw < -95 || yaw > 95) && abs( z_diff ) < 50 )
			{
		        if( IsDefined( level._audio_director_vox_play ) )
	            {
	                if( director.is_activated )
	                    director thread [[ level._audio_director_vox_play ]]( "vox_director_slam" );
	                else    
	                    director thread [[ level._audio_director_vox_play ]]( "vox_director_behind_you" );
	            }
			}			
		}	
	}
}

create_and_play_director_vox( type, force_variant )
{              
	waittime = .25;
	
	alias = "vox_romero_" + type;
	
	if( !IsDefined ( self.sound_dialog ) )
	{
		self.sound_dialog = [];
		self.sound_dialog_available = [];
	}
				
	if ( !IsDefined ( self.sound_dialog[ alias ] ) )
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants( alias );      
		
		//TOOK OUT THE ASSERT AND ADDED THIS CHECK FOR LOCS
		if( num_variants <= 0 )
		{
		    /#
		    if( GetDvarInt( #"debug_audio" ) > 0 )
		        PrintLn( "DIALOG DEBUGGER: No variants found for - " + alias );
		    #/
		    return;
		}     
		
		/#      
		//assertex( num_variants > 0, "No dialog variants found for category: " + alias_suffix );
		#/
		
		for( i = 0; i < num_variants; i++ )
		{
			self.sound_dialog[ alias ][ i ] = i;     
		}	
		
		self.sound_dialog_available[ alias ] = [];
	}
	
	if ( self.sound_dialog_available[ alias ].size <= 0 )
	{
		self.sound_dialog_available[ alias ] = self.sound_dialog[ alias ];
	}
  
	variation = random( self.sound_dialog_available[ alias ] );
	self.sound_dialog_available[ alias ] = array_remove( self.sound_dialog_available[ alias ], variation );
    
    if( IsDefined( force_variant ) )
    {
        variation = force_variant;
    }
    
	sound_to_play = alias + "_" + variation;
	
	self thread do_director_playvox( sound_to_play, waittime );
}

do_director_playvox( sound_to_play, waittime, override )
{
	if( !IsDefined( level.director_is_speaking ) )
	{
		level.director_is_speaking = 0;	
	}
	
	if( !IsDefined( waittime ) )
	{
	    waittime = .25;
	}
	
	if( level.director_is_speaking != 1 || is_true( override ) )
	{
		level.director_is_speaking = 1;
		self playsound( sound_to_play, "sound_done" + sound_to_play );			
		self waittill( "sound_done" + sound_to_play );
		wait( waittime );		
		level.director_is_speaking = 0;
	}
}
//END Director Vox

//*********************************
//  EASTER EGG SCRIPTS
//      Radio, Music, and any other Easter Egg Audio scripts
//*********************************

//START Radio Easter Eggs
radio_easter_eggs()
{
    wait(3);
    
    //Check to see if this has been BSP'd yet
    teststruct = getstruct( "radio_egg_0", "targetname" );
    
    if( !IsDefined( teststruct ) )
    {
        return;
    }
    
    for(i=0;i<5;i++)
    {
        ent[i] = getstruct( "radio_egg_" + i, "targetname" );
        ent[i] thread activate_radio_egg( i );
    }
}

//SELF == Radio
activate_radio_egg( num )
{
    radio_trig = Spawn( "trigger_radius", self.origin - (0,0,200), 0, 75, 400 );
    radio_trig.completed = false;

    if(level.gamemode != "survival")
    {
        return;
    }
    
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
    playsoundatposition( "vox_radio_egg_" + num, self.origin );
}
//END Radio Easter Eggs

//START Music Easter Egg
setup_music_egg()
{ 
    wait(3);

    if(level.gamemode != "survival")
    {
        return;
    }

    level.meteor_counter = 0;
    level.music_override = false;
    array_thread( getstructarray( "mus_easteregg", "targetname" ), ::music_egg );
}

music_egg()
{
    if( !isdefined( self ) )
	{
		return;
	}	
    
    temp_ent = Spawn( "script_origin", self.origin );
	temp_ent PlayLoopSound( "zmb_meteor_loop" );
		
	player = self music_egg_wait();
	
	temp_ent StopLoopSound( 1 );
	player PlaySound( "zmb_meteor_activate" );
	
	player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "meteors", undefined, level.meteor_counter );
		
	level.meteor_counter = level.meteor_counter + 1;
	
	if( level.meteor_counter == 3 )
	{ 
	    level thread play_music_egg( player );
	}
	
	wait(1.5);
	temp_ent Delete();
}

music_egg_wait()
{
    music_egg_trig = Spawn( "trigger_radius", self.origin - (0,0,200), 0, 50, 400 );
    music_egg_trig.completed = false;
    
    while(1)
    {
        music_egg_trig waittill( "trigger", who );
        
        while( who IsTouching( music_egg_trig ) )
        {
            if( who UseButtonPressed() )
            {
                music_egg_trig.completed = true;
                break;
            }
            
            wait(.05);
        }
        
        if( music_egg_trig.completed == true )
            break;
    }
    music_egg_trig Delete();
    return who;
}

play_music_egg( player )
{
	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "egg" );
	
	wait(4);
	
	if( IsDefined( player ) )
	{
	    player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "music_activate" );
	}
	
	//LENGTH OF SONG
	wait(420);	
	level.music_override = false;
	
	if( level.music_round_override == false )
	    level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

    level thread setup_music_egg();
}
//END Music Easter Egg


//START Skits and One-Liners
skit_start_reminder( ent )
{   
    while( !flag( "fuse_fun_start" ) )
    {
        rand = RandomIntRange( 0, 3 );
        ent PlaySound( "vox_chr_" + rand + "_egg_response_0" );
        wait(RandomIntRange( 10, 35 ));
    }
}

play_characters_skits_etc( player, ent, a, b, c, d )
{
    if( !IsDefined( level.door_knock_vox_occurring ) )
    {
        level.door_knock_vox_occurring = false;
    }
    
    if( is_true( level.door_knock_vox_occurring ) )
    {
        while( level.door_knock_vox_occurring )
        {
            wait(.5);
        }
    }
    
    if( !level.door_knock_vox_occurring )
    {
        level.door_knock_vox_occurring = true;
        level.skit_vox_override = true;
        
        if( IsDefined( a ) && IsDefined( player ) )
        {
            if( IsDefined( level.door_trig ) && player IsTouching( level.door_trig ) )
            {
               // player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "coast_response", undefined, a, true );
               // player waittill( "sound_done" + "egg_response_" + a );
                
                player play_sound_on_ent_and_wait( "coast_response", a, true, "sound_done" + "egg_response_" + a );
            }
        }
        
        if( IsDefined( b ) && IsDefined( player ) )
        {
            if( IsDefined( level.door_trig ) && player IsTouching( level.door_trig ) )
            {
                ent PlaySound( "vox_egg_skit_" + b, "sounddone_skit" );
                ent waittill( "sounddone_skit" );
            }
        }
        
        if( IsDefined( c ) && IsDefined( player ) )
        {
            if( IsDefined( level.door_trig ) && player IsTouching( level.door_trig ) )
            {
                //player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "coast_response", undefined, c, true );
                //player waittill( "sound_done" + "egg_response_" + c );
                
                player play_sound_on_ent_and_wait( "coast_response", c, true, "sound_done" + "egg_response_" + c );
            }
        }
        
        level.skit_vox_override = false;
        
        if( IsDefined( d ) )
        {
            char = get_character( d );
                
            if( !IsDefined( char ) )
            {
                level.door_knock_vox_occurring = false;
                return;
            }  
                
            ent PlaySound( "vox_chr_" + char + "_egg_response_" + d, "sounddone_oneliner" );
            
            ent waittill( "sounddone_oneliner" );
            
        }
        
        level.door_knock_vox_occurring = false;
    }
}

play_sound_on_ent_and_wait( str_soundalias, str_force_variant, bool_override, str_waittill )
{
  self create_and_play_dialog_egg( "eggs", "coast_response", undefined, str_force_variant, bool_override );
}


create_and_play_dialog_egg( category, type, response, force_variant, override )
{              
	waittime = .25;
	
	/#
	//if( GetDvarInt( #"debug_audio" ) > 0 )
	//    level thread dialog_debugger( category, type );
	#/
	
	if( !IsDefined( level.plr_vox[category][type] ) )
	{
		//IPrintLnBold( "No Category: " + category + " and Type: " + type );
		return;
	}
	
	//Preventing the player from spouting off a bunch of crap in laststand
	if( self maps\_laststand::player_is_in_laststand() && ( type != "revive_down" || type != "revive_up" ) )
	{
	    return;
	}
	
	alias_suffix = level.plr_vox[category][type];
	
	if( IsDefined( response ) )
	    alias_suffix = response + alias_suffix;
	    
	index = maps\_zombiemode_weapons::get_player_index(self);
	prefix = level.plr_vox["prefix"] + index + "_";
	
	if( !IsDefined ( self.sound_dialog ) )
	{
		self.sound_dialog = [];
		self.sound_dialog_available = [];
	}
				
	if ( !IsDefined ( self.sound_dialog[ alias_suffix ] ) )
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants( prefix + alias_suffix );      
		
		//TOOK OUT THE ASSERT AND ADDED THIS CHECK FOR LOCS
		if( num_variants <= 0 )
		{
		    /#
		    if( GetDvarInt( #"debug_audio" ) > 0 )
		        PrintLn( "DIALOG DEBUGGER: No variants found for - " + prefix + alias_suffix );
		    #/
		    return;
		}     
		
		/#      
		//assertex( num_variants > 0, "No dialog variants found for category: " + alias_suffix );
		#/
		
		for( i = 0; i < num_variants; i++ )
		{
			self.sound_dialog[ alias_suffix ][ i ] = i;     
		}	
		
		self.sound_dialog_available[ alias_suffix ] = [];
	}
	
	if ( self.sound_dialog_available[ alias_suffix ].size <= 0 )
	{
		self.sound_dialog_available[ alias_suffix ] = self.sound_dialog[ alias_suffix ];
	}
  
	variation = random( self.sound_dialog_available[ alias_suffix ] );
	self.sound_dialog_available[ alias_suffix ] = array_remove( self.sound_dialog_available[ alias_suffix ], variation );
    
    if( IsDefined( force_variant ) )
    {
        variation = force_variant;
    }
    
    if( !IsDefined( override ) )
    {
        override = false;
    }
    
	sound_to_play = alias_suffix + "_" + variation;
	
//	self thread do_player_playvox_egg( prefix, index, sound_to_play, waittime, category, type, override );

	self do_player_playvox_egg( prefix, index, sound_to_play, waittime, category, type, override );

}

do_player_playvox_egg( prefix, index, sound_to_play, waittime, category, type, override )
{
	players = getplayers();
	if( !IsDefined( level.player_is_speaking ) )
	{
		level.player_is_speaking = 0;	
	}
	
	if( is_true(level.skit_vox_override) && !override )
	    return;
	
	if( level.player_is_speaking != 1 )
	{
		level.player_is_speaking = 1;
		self playsound( prefix + sound_to_play, "sound_done" + sound_to_play );			
		self waittill( "sound_done" + sound_to_play );
		wait( waittime );		
		level.player_is_speaking = 0;
	
	}
}

get_character( current_d )
{
    if( !IsDefined( level.AUDIO_last_d ) )
    {
        level.AUDIO_last_d = 80;
    }
        
    if( !IsDefined( level.AUDIO_current_character ) )
    {
        level.AUDIO_current_character = 0;
    }
        
    if( current_d != level.AUDIO_last_d )
    {
        level.AUDIO_last_d = current_d;
        level.AUDIO_current_character = 0;
        return level.AUDIO_current_character;
    }
    else
    {
        level.AUDIO_current_character++;
        
        if( level.AUDIO_current_character >= 3 )
        {
            return undefined;
        }
        
        return level.AUDIO_current_character;
    }
}