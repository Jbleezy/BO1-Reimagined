#include maps\_ambientpackage;
#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

main()
{
	level._audio_custom_weapon_check = ::weapon_type_check_custom;
	level._audio_custom_player_playvox = ::do_player_playvox_custom;
	level._custom_intro_vox = ::no_intro_vox;
	level._audio_alias_override = ::audio_alias_override;
	level.player_4_vox_override = false;
	level.been_to_moon_before = false;
	
	level.audio_zones_breached 			= [];
	level.audio_zones_breached["1"] 	= false;
	level.audio_zones_breached["2a"] 	= false;
	level.audio_zones_breached["2b"] 	= false;
	level.audio_zones_breached["3a"] 	= false;
	level.audio_zones_breached["3b"] 	= false;
	level.audio_zones_breached["4a"] 	= false;
	level.audio_zones_breached["4b"] 	= false;
	level.audio_zones_breached["5"] 	= false;
	
	level thread setup_music_egg();
	//level thread force_player4_override();
	level thread waitfor_forest_zone_entry();
	//level thread door_vox();
	level thread poweron_vox();
	level thread setup_moon_visit_vox();
	level thread intro_vox_or_skit();
	level thread eight_bit_easteregg();
	level thread radio_setup();
}

radio_setup()
{
	wait_network_frame();
	if(level.gamemode != "survival")
	{
		return;
	}

	wait(5);
	level.radio_egg_counter = 0;
	level.radio_waittime = [];
	level.radio_waittime[1] = 78;
	level.radio_waittime[2] = 125;
	level.radio_waittime[3] = 164;
	level.radio_waittime[4] = 62;
	level.radio_waittime[5] = 124;
	array_thread( getstructarray( "egg_radios", "targetname" ), ::play_radio_eastereggs );
}

play_radio_eastereggs()
{
	if( !isdefined( self ) )
	{
		return;
	}
	
	while(1)
	{
		self thread maps\_zombiemode_sidequests::fake_use( "radio_activate" );
		self waittill( "radio_activate" );
		
		if( isdefined( self.script_noteworthy ) )
		{
			breakout = self checkfor_radio_override();
			if( breakout )
			{
				break;
			}
		}
		else
		{
			break;
		}
		
		wait(.1);
	}
	
	level.radio_egg_counter++;
	sound_ent = spawn( "script_origin", self.origin );
	sound_ent playsound( "vox_story_1_log_" + level.radio_egg_counter );
	sound_ent playloopsound( "vox_radio_egg_snapshot", 1 );
	wait( level.radio_waittime[level.radio_egg_counter] );
	sound_ent stoploopsound( 1 );
	wait(1);
	sound_ent delete();
}

checkfor_radio_override()
{
	if( !isdefined( level.glass ) )
	{
		return true;
	}
	
	for( i=0; i<level.glass.size; i++ )
	{
		if( level.glass[i].damage_state == 1 ) //no damage yet
		{	
			for( j=0; j<level.glass[i].fxpos_array.size; j++ )
			{
				glass_origin = level.glass[i].fxpos_array[j].origin;
				
				if( DistanceSquared( glass_origin, self.origin ) < 50*50 )
				{
					return true;
				}
			}
		}
	}
	
	return false;
}

eight_bit_easteregg()
{
	wait_network_frame();
	if(level.gamemode != "survival")
	{
		return;
	}

	wait(5);
	structs = getstructarray( "8bitsongs", "targetname" );
	array_thread( structs, ::waitfor_eightbit_use );
}

waitfor_eightbit_use()
{
	flag_wait( "power_on" );
	
	self thread maps\_zombiemode_sidequests::fake_use( "bit_hit", ::waitfor_override );
	
	self waittill( "bit_hit" );
	
	playsoundatposition( "mus_8bit_notice", self.origin );
	wait(4);
	playsoundatposition( self.script_string, self.origin );
}

no_intro_vox()
{
}

intro_vox_or_skit()
{
	wait(1);
	flag_wait( "all_players_connected" );
	
	playsoundatposition( "evt_warp_in", (0,0,0) );
	
	wait(3);
	players = get_players();
	
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "start" );
}

poweron_vox()
{
	wait(3);
	flag_wait( "power_on" );

	if(level.gamemode == "survival")
	{
		level thread maps\zombie_moon_amb::play_mooncomp_vox( "vox_mcomp_power" );
	}
	
	/*
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if( players[i] maps\_zombiemode_equip_gasmask::gasmask_active() )
		{
			players[i] playsoundtoplayer( "vox_mcomp_power_f", players[i] );
		}
	}
	*/
}


door_vox()
{
	wait(5);
	array_thread( ( getstructarray( "door_vox", "targetname" ) ), ::track_door_entry_exit );
	
	//One of a kind doorway between two different pressurized areas
	struct = getstruct( "door_vox_special", "targetname" );
	struct thread track_door_entry_exit( 1 );
}

track_door_entry_exit( special )
{	
	self.special = false;
	
	if( is_true( special ) )
	{
		self.special = true;
	}
	
	while(1)
	{
		array_thread( getentarray( self.target, "targetname" ), ::waitfor_door_open, self );
		self waittill( "trigger", where, player, ent );

		zone = player get_current_zone();

		if(!IsSubStr(zone, "airlock_"))
		{
			if( where == "outside" && !level.audio_zones_breached[self.script_noteworthy] )
			{
				
				//iprintlnbold( "Entering Area " + self.script_int );
				
				ent PlaySoundToPlayer("vox_mcomp_enter_" + self.script_int, player);
				//playsoundatposition( "vox_mcomp_enter_" + self.script_int, self.origin );
			}
			else
			{
				if( self.special && !level.audio_zones_breached["4b"] && where == "inside" )
				{
					if(zone == "forest_zone")
					{
						ent PlaySoundToPlayer("vox_mcomp_enter_3", player);
						//playsoundatposition( "vox_mcomp_enter_3", self.origin );
					}
					else if(zone == "enter_forest_east_zone")
					{
						ent PlaySoundToPlayer("vox_mcomp_enter_4", player);
						//playsoundatposition( "vox_mcomp_enter_4", self.origin );
					}
					//iprintlnbold( "Entering Area 3" );
				}
				else
				{
					/#
					iprintlnbold( "Entering Airless Environment" );
					#/
					//playsoundatposition( "vox_mcomp_enter_5", self.origin );
				}
			}
		}
		
		wait(3.5);
	}
}

waitfor_door_open( struct )
{
	struct endon( "other_door_opened" );
	
	while(1)
	{
		self waittill( "trigger", who );
		
		if( isplayer( who ) )
		{
			where = self.script_string;
			
			if( struct.special )
			{
				if( self.target == "pf17_auto347" )
				{
					where = "outside";
				}
				else
				{
					where = "inside";
				}
			}
			
			struct notify( "trigger", where, who, self );
			struct notify( "other_door_opened" );
			return;
		}
		
		wait(.05);
	}
}

audio_alias_override()
{
	level.plr_vox["kill"]["explosive"]										=		"kill_explosive";		//PLAYER KILLS A ZOMBIE USING EXPLOSIVES
	level.plr_vox["kill"]["explosive_response"]								=		undefined;				//RESPONSE TO ABOVE
	
	//NEW LINES FOR MOON
//	level.plr_vox["general"]["moonbase"]									=		"enter_moonbase";
//	level.plr_vox["general"]["moonbase_response"]							=		undefined;
	level.plr_vox["weapon_pickup"]["microwave"]								=		"wpck_microwave";
	level.plr_vox["weapon_pickup"]["microwave_response"]					=		undefined;
	level.plr_vox["weapon_pickup"]["quantum"]								=		"wpck_quantum";
	level.plr_vox["weapon_pickup"]["quantum_response"]						=		undefined;
	level.plr_vox["weapon_pickup"]["gasmask"]								=		"wpck_gasmask";
	level.plr_vox["weapon_pickup"]["gasmask_response"]						=		undefined;
	level.plr_vox["weapon_pickup"]["hacker"]								=		"wpck_hacker";
	level.plr_vox["weapon_pickup"]["hacker_response"]						=		undefined;
	level.plr_vox["kill"]["micro_dual"]										=		"kill_micro_dual";
	level.plr_vox["kill"]["micro_dual_response"]							=		undefined;
	level.plr_vox["kill"]["micro_single"]									=		"kill_micro_single";
	level.plr_vox["kill"]["micro_single_response"]							=		undefined;
	level.plr_vox["kill"]["quant_good"]										=		"kill_quant_good";
	level.plr_vox["kill"]["quant_good_response"]							=		undefined;
	level.plr_vox["kill"]["quant_bad"]										=		"kill_quant_bad";
	level.plr_vox["kill"]["quant_bad_response"]								=		undefined;
	level.plr_vox["digger"]													=		[];
	level.plr_vox["digger"]["incoming"]										=		"digger_incoming";
	level.plr_vox["digger"]["incoming_response"]							=		undefined;
	level.plr_vox["digger"]["breach"]										=		"digger_breach";
	level.plr_vox["digger"]["breach_response"]								=		undefined;
	level.plr_vox["digger"]["hacked"]										=		"digger_hacked";
	level.plr_vox["digger"]["hacked_response"]								=		undefined;
	level.plr_vox["general"]["astro_spawn"]									=		"spawn_astro";
	level.plr_vox["general"]["astro_spawn_response"]						=		undefined;
	level.plr_vox["kill"]["astro"]											=		"kill_astro";
	level.plr_vox["kill"]["astro_response"]									=		undefined;
	level.plr_vox["general"]["biodome"]										=		"location_biodome";
	level.plr_vox["general"]["biodome_response"]							=		undefined;
	level.plr_vox["general"]["jumppad"]										=		"jumppad";
	level.plr_vox["general"]["jumppad_response"]							=		undefined;
	level.plr_vox["general"]["teleporter"]									=		"teleporter";
	level.plr_vox["general"]["teleporter_response"]							=		undefined;
	level.plr_vox["perk"]["specialty_additionalprimaryweapon"]				=		"perk_arsenal";
	level.plr_vox["perk"]["specialty_additionalprimaryweapon_response"]		=		undefined;
	level.plr_vox["powerup"]["bonus_points_solo"]							=		"powerup_pts_solo";	
	level.plr_vox["powerup"]["bonus_points_solo_response"]					=		undefined;	
	level.plr_vox["powerup"]["bonus_points_team"]							=		"powerup_pts_team";
	level.plr_vox["powerup"]["bonus_points_team_response"]					=		undefined;
	level.plr_vox["powerup"]["lose_points"]									=		"powerup_antipts_zmb";
	level.plr_vox["powerup"]["lose_points_response"]						=		undefined;
	level.plr_vox["general"]["hack_plr"]									=		"hack_plr";
	level.plr_vox["general"]["hack_plr_response"]							=		undefined;
	level.plr_vox["general"]["hack_vox"]									=		"hack_vox";
	level.plr_vox["general"]["hack_vox_response"]							=		undefined;
	level.plr_vox["general"]["airless"]										=		"location_airless";
	level.plr_vox["general"]["airless_response"]							=		undefined;
	level.plr_vox["general"]["moonjump"]									=		"moonjump";
	level.plr_vox["general"]["moonjump_response"]							=		undefined;
	level.plr_vox["weapon_pickup"]["grenade"]								=		"wpck_launcher";
	level.plr_vox["weapon_pickup"]["grenade_response"]						=		undefined;
		
}

force_player4_override()
{
	wait(5);
	iprintlnbold( "Player 4 Override in 5 seconds!" );
	wait(5);
	level thread player_4_override();
}

player_4_override()
{
	level.player_4_vox_override = true;
	level.devil_vox["prefix"] = "zmb_vox_rich_";
	
	//Change response lines so they are now Samantha response lines, if needed
	level.plr_vox["general"]["crawl_spawn_response"]				=		"resp_s_spawn_crawl";
	level.plr_vox["general"]["oh_shit_response"]					=		"resp_s_ohshit";
	level.plr_vox["kill"]["headshot_response"]						=		"resp_s_kill_headshot";
	level.plr_vox["weapon_pickup"]["monkey_response"]				=		"resp_s_wpck_monkey";
}

do_player_playvox_custom( prefix, index, sound_to_play, waittime, category, type, override )
{
	players = getplayers();
	if( !IsDefined( level.player_is_speaking ) )
	{
		level.player_is_speaking = 0;	
	}
	
	if( is_true(level.skit_vox_override) && !override )
	    return;
		
	if ( is_true( self.in_low_gravity ) && !self maps\_zombiemode_equip_gasmask::gasmask_active() )
	{
		return;
	}
	
	if( level.player_is_speaking != 1 )
	{
		level.player_is_speaking = 1;
		self play_futz_or_not_moonvox( prefix, sound_to_play );
		wait( waittime );		
		level.player_is_speaking = 0;
		
		if( !flag( "solo_game" ) && ( isdefined (level.plr_vox[category][type + "_response"] )))
		{
			if ( isDefined( level._audio_custom_response_line ) )
	        {
		        level thread [[ level._audio_custom_response_line ]]( self, index, category, type );
	        }
			else
			{
			    level thread maps\_zombiemode_audio::setup_response_line( self, index, category, type ); 
			}
		}
	}
}

//SELF = Player Saying the Line
play_futz_or_not_moonvox( prefix, sound_to_play )
{
	players = get_players();
	
	if( self.sessionstate == "spectator" )
	{
		return;
	}
	
	for(i=0;i<players.size;i++)
	{
		if( self maps\_zombiemode_equipment::is_equipment_active("equip_gasmask_zm") )
		{
			if( self == players[i] )
			{
				self playsound( prefix + sound_to_play + "_f", "sound_done" + sound_to_play );
			}
			else if( players[i] maps\_zombiemode_equipment::is_equipment_active("equip_gasmask_zm") )
			{
				players[i] playsoundtoplayer( prefix + sound_to_play + "_f", players[i] );
			}
		}
		else
		{
			if( self == players[i] )
			{
				self playsound( prefix + sound_to_play, "sound_done" + sound_to_play );
			}
		}
	}
	
	self waittill( "sound_done" + sound_to_play );
}

//START Temple VO Overrides
weapon_type_check_custom(weapon)
{
    if( !IsDefined( self.entity_num ) )
        return "crappy";    
    
    switch(self.entity_num)
    {
        case 0:   //DEMPSEY'S FAVORITE WEAPON: M16 UPGRADED: M16
            if( weapon == "m16_zm" )
                return "favorite";
            else if( weapon == "m16_gl_upgraded_zm" )
                return "favorite_upgrade";   
            break;
            
        case 1:   //NIKOLAI'S FAVORITE WEAPON: FNFAL UPGRADED: HK21
            if( weapon == "fnfal_zm" )
                return "favorite";
            else if( weapon == "hk21_upgraded_zm" )
                return "favorite_upgrade";   
            break;
            
        case 2:   //TAKEO'S FAVORITE WEAPON: AK74U UPGRADED: M14
            if( weapon == "ak74u_zm" )
                return "favorite";
            else if( weapon == "m14_upgraded_zm" )
                return "favorite_upgrade";   
            break; 
        
        case 3:   //RICHTOFEN'S FAVORITE WEAPON: SPECTRE UPGRADED: G11
            if( !is_true( level.player_4_vox_override ) )
			{
				if( weapon == "spectre_zm" )
                	return "favorite";
            	else if( weapon == "g11_lps_upgraded_zm" )
                	return "favorite_upgrade";   
			}
			else
			{
				if( weapon == "spas_zm" )
                	return "favorite";
            	else if( weapon == "mp40_upgraded_zm" )
                	return "favorite_upgrade";
			}
            break;               
    }
    
    if( IsSubStr( weapon, "upgraded" ) )
        return "upgrade";
    else
        return level.zombie_weapons[weapon].vox;
}

//START Music Easter Egg
setup_music_egg()
{
	wait_network_frame();
	if(level.gamemode != "survival")
	{
		return;
	}

    wait(3);
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
		
	self thread maps\_zombiemode_sidequests::fake_use( "main_music_egg_hit", ::waitfor_override );
	self waittill( "main_music_egg_hit", player);
	
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

waitfor_override()
{
	if( is_true( level.music_override ) )
	{
		return false;
	}
	
	return true;
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
	wait(199);	
	level.music_override = false;
	
	if( level.music_round_override == false )
		level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

	level thread setup_music_egg();
}
//END Music Easter Egg

play_mooncomp_vox( alias, digger )
{
	if( !IsDefined( alias ) )
		return;
		
	if( !level.on_the_moon )
		return;
		
	num = 0;
	
	if( isdefined( digger ) )
	{
		switch( digger )
		{
			case "hangar":
				num = 1;
				break;
			case "teleporter":
				num = 0;
				break;
			case "biodome":
				num = 2;
				break;	
		}
	}
	else
	{
		num = "";
	}
	
	if( !IsDefined( level.mooncomp_is_speaking ) )
	{
		level.mooncomp_is_speaking = 0;
	}
	
	if( level.mooncomp_is_speaking == 0 )
	{
		level.mooncomp_is_speaking = 1;
		level do_mooncomp_vox( alias + num );
		level.mooncomp_is_speaking =0;
	}
}

do_mooncomp_vox( alias )
{
	level thread play_sound_2D( alias );
	
	players = get_players();
	
	for(i=0;i<players.size;i++)
	{
		if( players[i] maps\_zombiemode_equipment::is_equipment_active("equip_gasmask_zm") || is_true( players[i].in_low_gravity ) )
		{
			players[i] playsoundtoplayer( alias + "_f", players[i] );
		}
	}
}

waitfor_forest_zone_entry()
{
	level waittill( "forest_zone" );
	
	while(1)
	{
		zone = level.zones[ "forest_zone" ];

		players = get_players();
		for (i = 0; i < zone.volumes.size; i++)
		{
			for (j = 0; j < players.size; j++)
			{
				if ( players[j] IsTouching(zone.volumes[i]) && !(players[j].sessionstate == "spectator"))
				{
					players[j] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "biodome" );
					return;
				}
			}
		}
		wait(.5);
	}
}

setup_moon_visit_vox()
{
	wait(5);
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] thread play_delayed_first_time_vox();
	}
	
	level thread waitfor_first_player();
}

play_delayed_first_time_vox()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	self waittill( "equip_gasmask_zm_activate" );
	self waittill( "weapon_change_complete" );

	self playsoundtoplayer( "vox_mcomp_suit_on", self );
	wait(1.5);
	
	self playsoundtoplayer( "vox_mcomp_start", self );
	wait( 7 );

	self thread play_maskon_vox();
	self thread play_warning_vox();
	
	level notify( "first_player_vox", self );
}

waitfor_first_player()
{
	level waittill( "first_player_vox", who );
	
	who thread maps\_zombiemode_audio::create_and_play_dialog( "general", "teleporter", undefined, undefined, true );
}

play_maskon_vox()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	while(1)
	{
		self waittill( "equip_gasmask_zm_activate" );
		self waittill( "weapon_change_complete" );
		self stopsounds();
		wait(.05);
		self playsoundtoplayer( "vox_mcomp_suit_on", self );
	}
}

play_warning_vox()
{
	self endon( "death" );
	self endon( "disconnect" );
	
	while(1)
	{
		while( !self.in_low_gravity )
		{
			wait(.1);
		}
		
		if( is_true( self.in_low_gravity && self HasWeapon( "equip_gasmask_zm" ) && !self maps\_zombiemode_equip_gasmask::gasmask_active() ) )
		{
			self stopsounds();
			wait(.05);

			self playsoundtoplayer( "vox_mcomp_suit_reminder", self );
			
			while( self.in_low_gravity )
			{
				if( self maps\_zombiemode_equip_gasmask::gasmask_active() )
				{
					break;
				}
				
				wait(.1);
			}
		}
		
		wait(8);
	}
}