#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager; 

main()
{	
	// first for createFX (why?)
	maps\zombie_cod5_prototype_fx::main();

	// viewmodel arms for the level
	//PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	//PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	//PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	//PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen
	PreCacheModel( "t4_viewhands_usa_marine" );

	level thread maps\_callbacksetup::SetupCallbacks();
	//maps\_waw_destructible_opel_blitz::init_blitz();
	level.startInvulnerableTime = GetDvarInt( "player_deathInvulnerableTime" );

	include_weapons();
	include_powerups();
	
	level.zones = [];

	level._effect["zombie_grain"]			= LoadFx( "misc/fx_zombie_grain_cloud" );

	maps\_waw_zombiemode_radio::init();	

	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;
	level.register_offhand_weapons_for_level_defaults_override = ::register_offhand_weapons_for_level_defaults_override;

	level.use_zombie_heroes = true;
	
	//DCS: no perk machines so need to init here.
	flag_init( "_start_zm_pistol_rank" );

	SetDvar( "magic_chest_movable", "0" );

	maps\_zombiemode::main();
	
	level.zone_manager_init_func = ::prototype_zone_init;
	init_zones[0] = "start_zone";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	init_sounds();
	
	//thread bad_area_fixes();

	thread above_couches_death();
	thread above_roof_death();
	thread below_ground_death();
		
	level thread zombie_collision_patch();

	// If you want to modify/add to the weapons table, please copy over the _zombiemode_weapons init_weapons() and paste it here.
	// I recommend putting it in it's own function...
	// If not a MOD, you may need to provide new localized strings to reflect the proper cost.

	// Set the color vision set back
	level.zombie_visionset = "zombie_prototype";

	// bhackbarth: bring this down here (rather than be called in zombie_cod5_prototype_fx::main), so we actually have clients to send fog settings to
	maps\createart\zombie_cod5_prototype_art::main();

	// need to set the "solo_game" flag here, since there are no vending machines
	level thread check_solo_game();
	
	// DCS: Only seems to be used in prototype.
	level thread setup_weapon_cabinet();
	level thread maps\_interactive_objects::main(); 
	
	// TUEY new eggs
	level thread prototype_eggs();
	level thread time_to_play();

	level thread pistol_rank_setup();

	level.has_pack_a_punch = false;
}

precache_player_model_override()
{
	mptype\player_t4_zm_asylum::precache();
}

give_player_model_override( entity_num )
{
	if( IsDefined( self.zm_random_char ) )
	{
		entity_num = self.zm_random_char;
	}

	switch( entity_num )
	{
		case 0:
			character\c_usa_marine1_dlc5::main();// Dempsey
			break;
		case 1:
			character\c_usa_marine2_dlc5::main();// John
			break;
		case 2:
			character\c_usa_marine3_dlc5::main();// Smokey
			break;
		case 3:
			character\c_usa_marine4_dlc5::main();// Marine4
			break;	
	}
}

player_set_viewmodel_override( entity_num )
{
	switch( self.entity_num )
	{
		case 0:
			// Dempsey
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;
		case 1:
			// Nikolai
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;
		case 2:
			// Takeo
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;
		case 3:
			// Richtofen
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;		
	}
}

register_offhand_weapons_for_level_defaults_override()
{
	register_lethal_grenade_for_level( "stielhandgranate" );
	level.zombie_lethal_grenade_player_init = "stielhandgranate";

	register_tactical_grenade_for_level( "zombie_cymbal_monkey" );
	level.zombie_tactical_grenade_player_init = undefined;

	register_placeable_mine_for_level( "mine_bouncing_betty" );
	level.zombie_placeable_mine_player_init = undefined;

	register_melee_weapon_for_level( "knife_zm" );
	level.zombie_melee_weapon_player_init = "knife_zm";
}


//-------------------------------------------------------------------------------
// weapon cabinets which open on use
//-------------------------------------------------------------------------------
setup_weapon_cabinet()
{
	// the triggers which are targeted at doors
	weapon_cabs = GetEntArray( "weapon_cabinet_use", "targetname" ); 

	for( i = 0; i < weapon_cabs.size; i++ )
	{
		weapon_cabs[i] SetHintString( &"ZOMBIE_CABINET_OPEN_1500" ); 
		weapon_cabs[i] setCursorHint( "HINT_NOICON" ); 
		weapon_cabs[i] UseTriggerRequireLookAt();
	}

	array_thread( weapon_cabs, ::weapon_cabinet_think ); 
}
weapon_cabinet_think()
{
	weapons = getentarray( "cabinet_weapon", "targetname" ); 

	doors = getentarray( self.target, "targetname" );
	for( i = 0; i < doors.size; i++ )
	{
		doors[i] NotSolid();
	}

	self.has_been_used_once = false;

	self.zombie_weapon_cabinet = true;

	self thread maps\_zombiemode_weapons::decide_hide_show_hint();

	while( 1 )
	{
		self waittill( "trigger", player );

		if( !player maps\_zombiemode_weapons::can_buy_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		current_wep = player GetCurrentWeapon();
		primaries = player GetWeaponsListPrimaries();
		weapon_limit = 2;

		if ( player HasPerk( "specialty_additionalprimaryweapon" ) )
	 	{
	 		weapon_limit = 3;
	 	}

	 	if(!player maps\_zombiemode_weapons::has_weapon_or_upgrade(self.zombie_weapon_upgrade))
	 	{
	 		if( is_melee_weapon(current_wep) || is_placeable_mine(current_wep) )
			{
				if(IsDefined(primaries) && primaries.size >= weapon_limit)
				{
					if(IsDefined(player.last_held_primary_weapon) && player HasWeapon(player.last_held_primary_weapon))
					{
						player SwitchToWeapon(player.last_held_primary_weapon);
					}
					else
					{
						player SwitchToWeapon(primaries[0]);
					}
					wait( 0.1 );
					continue;
				}
			}
	 	}

		cost = 1500;
		if( self.has_been_used_once )
		{
			cost = maps\_zombiemode_weapons::get_weapon_cost( self.zombie_weapon_upgrade );
		}
		else
		{
			if( IsDefined( self.zombie_cost ) )
			{
				cost = self.zombie_cost;
			}
		}

		ammo_cost = maps\_zombiemode_weapons::get_ammo_cost( self.zombie_weapon_upgrade );

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( self.has_been_used_once )
		{
			player_has_weapon = player maps\_zombiemode_weapons::has_weapon_or_upgrade( self.zombie_weapon_upgrade );

			if( !player_has_weapon )
			{
				if( player.score >= cost )
				{
					self play_sound_on_ent( "purchase" );
					player maps\_zombiemode_score::minus_to_player_score( cost ); 
					player maps\_zombiemode_weapons::weapon_give( self.zombie_weapon_upgrade ); 
					player maps\_zombiemode_weapons::check_collector_achievement( self.zombie_weapon_upgrade );
				}
				else // not enough money
				{
					play_sound_on_ent( "no_purchase" );
					player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money" );
				}			
			}
			else if ( player.score >= ammo_cost )
			{
				ammo_given = player maps\_zombiemode_weapons::ammo_give( self.zombie_weapon_upgrade ); 
				if( ammo_given )
				{
					self play_sound_on_ent( "purchase" );
					player maps\_zombiemode_score::minus_to_player_score( ammo_cost ); // this give him ammo to early
				}
			}
			else // not enough money
			{
				play_sound_on_ent( "no_purchase" );
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money" );
			}
		}
		else if( player.score >= cost ) // First time the player opens the cabinet
		{
			self.has_been_used_once = true;

			self play_sound_on_ent( "purchase" ); 

			self SetHintString( &"REIMAGINED_WEAPONCOSTAMMO", cost, ammo_cost ); 
			self setCursorHint( "HINT_NOICON" ); 
			player maps\_zombiemode_score::minus_to_player_score( self.zombie_cost ); 

			doors = getentarray( self.target, "targetname" ); 

			for( i = 0; i < doors.size; i++ )
			{
				if( doors[i].model == "dest_test_cabinet_ldoor_dmg0" )
				{
					doors[i] thread weapon_cabinet_door_open( "left" ); 
				}
				else if( doors[i].model == "dest_test_cabinet_rdoor_dmg0" )
				{
					doors[i] thread weapon_cabinet_door_open( "right" ); 
				}
			}

			player_has_weapon = player maps\_zombiemode_weapons::has_weapon_or_upgrade( self.zombie_weapon_upgrade ); 

			if( !player_has_weapon )
			{
				player maps\_zombiemode_weapons::weapon_give( self.zombie_weapon_upgrade ); 
				player maps\_zombiemode_weapons::check_collector_achievement( self.zombie_weapon_upgrade );
			}
			else
			{
				if( player maps\_zombiemode_weapons::has_upgrade( self.zombie_weapon_upgrade ) )
				{
					player maps\_zombiemode_weapons::ammo_give( self.zombie_weapon_upgrade+"_upgraded" ); 
				}
				else
				{
					player maps\_zombiemode_weapons::ammo_give( self.zombie_weapon_upgrade ); 
				}
			}	
		}
		else // not enough money
		{
			play_sound_on_ent( "no_purchase" );
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money" );
		}		
	}
}
weapon_cabinet_door_open( left_or_right )
{
	if( left_or_right == "left" )
	{
		self rotateyaw( 120, 0.3, 0.2, 0.1 ); 	
	}
	else if( left_or_right == "right" )
	{
		self rotateyaw( -120, 0.3, 0.2, 0.1 ); 	
	}	
}
//-------------------------------------------------------------------------------

bad_area_fixes()
{
	thread disable_stances_in_zones();
}


// do point->distance checks and volume checks
disable_stances_in_zones()
{ 	
 	players = get_players();
 	
 	for (i = 0; i < players.size; i++)
 	{
 		players[i] thread fix_hax();
		players[i] thread fix_couch_stuckspot();
 		//players[i] thread in_bad_zone_watcher();	
 		players[i] thread out_of_bounds_watcher();
 	}
}




//Chris_P - added additional checks for some hax/exploits on the stairs, by the grenade bag and on one of the columns/pillars
fix_hax()
{
	self endon("disconnect");
	self endon("death");
	
	check = 15;
	check1 = 10;
	
	while(1)
	{
	
		//stairs
		wait(.5);
		if( distance2d(self.origin,( 101, -100, 40)) < check )
		{
			self setorigin ( (101, -90, self.origin[2]));
		}
		
		//crates/boxes
		else if( distance2d(self.origin, ( 816, 645, 12) ) < check )
		{
			self setorigin ( (816, 666, self.origin[2]) );
		
		}
		
		else if( distance2d( self.origin, (376, 643, 184) ) < check )
		{
			self setorigin( (376, 665, self.origin[2]) );
		}
		
		//by grandfather clock
		else	if(distance2d(self.origin,(519 ,765, 155)) < check1) 
		{
			self setorigin( (516, 793,self.origin[2]) );
		}
		
		//broken pillar
		else if( distance2d(self.origin,(315 ,346, 79))<check1)
		{
			self setorigin( (317, 360, self.origin[2]) );
		}
	
		//rubble by pillar
		else if( distance2d(self.origin,(199, 133, 18))<check)
		{
			self setorigin( (172, 123, self.origin[2]) );
		}
		
		//nook in curved stairs
		else if( distance2d(self.origin,(142 ,-100 ,91))<check1)
		{
			self setorigin( (139 ,-87, self.origin[2]) );
		}
		
		//by sawed off shotty				
		else if( distance2d(self.origin,(192, 369 ,185))<check1)
		{
			self setorigin( (195, 400 ,self.origin[2]) );
		}
		
		//rubble pile in the corner
		else if( distance2d(self.origin,(-210, 641, 247)) < check)
		{
			self setorigin( (-173 ,677,self.origin[2] ) );
		}

	}
		
}



fix_couch_stuckspot()
{
	self endon("disconnect");
	self endon("death");
	level endon("upstairs_blocker_purchased");

	while(1)
	{
		wait(.5);

		if( distance2d(self.origin, ( 181, 161, 206) ) < 10 )
		{
			self setorigin ( (175, 175 , self.origin[2]) );
		
		}		
		
	}

}




in_bad_zone_watcher()
{
	self endon ("disconnect");
	level endon ("fake_death");
	
	no_prone_and_crouch_zones = [];
 	
 	// grenade wall
 	no_prone_and_crouch_zones[0]["min"] = (-205, -128, 144);
 	no_prone_and_crouch_zones[0]["max"] = (-89, -90, 269);
 
  	no_prone_zones = [];
  	
  	// grenade wall
  	no_prone_zones[0]["min"] = (-205, -128, 144);
 	no_prone_zones[0]["max"] = (-55, 30, 269);

	// near the sawed off
  	no_prone_zones[1]["min"] = (88, 305, 144);
 	no_prone_zones[1]["max"] = (245, 405, 269);
 	
	while (1)
 	{	
		array_check = 0;
		
		if ( no_prone_and_crouch_zones.size > no_prone_zones.size)
		{
			array_check = no_prone_and_crouch_zones.size;
		}
		else
		{
			array_check = no_prone_zones.size;
		}
		
 		for(i = 0; i < array_check; i++)
 		{
 			if (isdefined(no_prone_and_crouch_zones[i]) && 
 				self is_within_volume(no_prone_and_crouch_zones[i]["min"][0], no_prone_and_crouch_zones[i]["max"][0], 
 											no_prone_and_crouch_zones[i]["min"][1], no_prone_and_crouch_zones[i]["max"][1],
 											no_prone_and_crouch_zones[i]["min"][2], no_prone_and_crouch_zones[i]["max"][2]))
 			{
 				self allowprone(false);
 				self allowcrouch(false);	
 				break;
 			}
 			else if (isdefined(no_prone_zones[i]) && 
 				self is_within_volume(no_prone_zones[i]["min"][0], no_prone_zones[i]["max"][0], 
 											no_prone_zones[i]["min"][1], no_prone_zones[i]["max"][1],
 											no_prone_zones[i]["min"][2], no_prone_zones[i]["max"][2]))
 			{
 				self allowprone(false);
 				break;
 			}
 			else
 			{
 				self allowprone(true);
 				self allowcrouch(true);
 			}
 			
 			
 		}		
 		wait 0.05;
 	}	
}


is_within_volume(min_x, max_x, min_y, max_y, min_z, max_z)
{
	if (self.origin[0] > max_x || self.origin[0] < min_x)
	{
		return false;
	}
	else if (self.origin[1] > max_y || self.origin[1] < min_y)
	{
		return false;
	}
	else if (self.origin[2] > max_z || self.origin[2] < min_z)
	{
		return false;
	}	
	
	return true;
}




init_sounds()
{
	maps\_zombiemode_utility::add_sound( "break_stone", "break_stone" );
}

// Include the weapons that are only inr your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
include_weapons()
{
	include_weapon( "m1911_zm", false );						// colt
	include_weapon("python_zm");
	include_weapon("cz75_zm");
	include_weapon("g11_lps_zm");
	include_weapon("famas_zm");
	include_weapon("spectre_zm");
	include_weapon("cz75dw_zm");
	include_weapon("spas_zm");
	include_weapon("hs10_zm");
	include_weapon("aug_acog_zm");
	include_weapon("galil_zm");
	include_weapon("commando_zm");
	include_weapon("fnfal_zm");
	include_weapon("dragunov_zm");
	include_weapon("l96a1_zm");
	include_weapon("rpk_zm");
	include_weapon("hk21_zm");
	include_weapon("m72_law_zm");
	include_weapon("china_lake_zm");
	include_weapon("zombie_cymbal_monkey");
	include_weapon("ray_gun_zm");
	include_weapon("crossbow_explosive_zm");
	include_weapon("knife_ballistic_zm");
	
	include_weapon( "zombie_m1carbine", false, true );
	include_weapon( "zombie_thompson", false, true );
	include_weapon( "zombie_kar98k", false, true );
	include_weapon( "kar98k_scoped_zombie", false, true );
	include_weapon( "stielhandgranate", false, true );
	include_weapon( "zombie_doublebarrel", false, true );
	include_weapon( "zombie_doublebarrel_sawed", false, true );
	include_weapon( "zombie_shotgun", false, true );
	include_weapon( "zombie_bar", false, true );

	include_weapon( "zombie_cymbal_monkey");

	include_weapon( "ray_gun_zm" );
	include_weapon( "thundergun_zm" );
	include_weapon( "m1911_upgraded_zm", false );

	level._uses_retrievable_ballisitic_knives = true;

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "m1911_zm", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "thundergun_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "crossbow_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "knife_ballistic_zm", 1 );

	precacheItem( "explosive_bolt_zm" );
	precacheItem( "explosive_bolt_upgraded_zm" );



	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_kar98k", "zombie_kar98k_upgraded", 						&"WAW_ZOMBIE_WEAPON_KAR98K_200", 				200,	"rifle");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_type99_rifle", "",					&"WAW_ZOMBIE_WEAPON_TYPE99_200", 			    200,	"rifle" );

	// Semi Auto                                        		
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_gewehr43", "zombie_gewehr43_upgraded",						&"WAW_ZOMBIE_WEAPON_GEWEHR43_600", 				600,	"rifle" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_m1carbine","zombie_m1carbine_upgraded",						&"WAW_ZOMBIE_WEAPON_M1CARBINE_600",				600,	"rifle" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_m1garand", "zombie_m1garand_upgraded" ,						&"WAW_ZOMBIE_WEAPON_M1GARAND_600", 				600,	"rifle" );

	maps\_zombiemode_weapons::add_zombie_weapon( "stielhandgranate", "", 						&"WAW_ZOMBIE_WEAPON_STIELHANDGRANATE_250", 		250,	"grenade", "", 250 );
	maps\_zombiemode_weapons::add_zombie_weapon( "mine_bouncing_betty", "", &"WAW_ZOMBIE_WEAPON_SATCHEL_2000", 2000 );		
	// Scoped
	maps\_zombiemode_weapons::add_zombie_weapon( "kar98k_scoped_zombie", "", 					&"WAW_ZOMBIE_WEAPON_KAR98K_S_750", 				1500,	"sniper");

	// Full Auto                                                                                	
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_stg44", "zombie_stg44_upgraded", 							    &"WAW_ZOMBIE_WEAPON_STG44_1200", 				1200, "mg" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_thompson", "zombie_thompson_upgraded", 							&"WAW_ZOMBIE_WEAPON_THOMPSON_1200", 			1200, "mg" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_type100_smg", "zombie_type100_smg_upgraded", 						&"WAW_ZOMBIE_WEAPON_TYPE100_1000", 				1000, "mg" );

	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_fg42", "zombie_fg42_upgraded", 							&"WAW_ZOMBIE_WEAPON_FG42_1500", 				1500,	"mg" ); 


	// Shotguns                                         	
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_doublebarrel", "zombie_doublebarrel_upgraded", 						&"WAW_ZOMBIE_WEAPON_DOUBLEBARREL_1200", 		1200, "shotgun");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_doublebarrel_sawed", "", 			    &"REIMAGINED_WEAPON_DOUBLEBARREL_SAWED", 	1200, "shotgun");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_shotgun", "zombie_shotgun_upgraded",							&"WAW_ZOMBIE_WEAPON_SHOTGUN_1500", 				1500, "shotgun");

	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_bar", "zombie_bar_upgraded", 						&"WAW_ZOMBIE_WEAPON_BAR_1800", 					1800,	"mg" );

	// Bipods                               				
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_bar_bipod", 	"",					&"WAW_ZOMBIE_WEAPON_BAR_BIPOD_2500", 			2500,	"mg" ); 
}

include_powerups()
{
	include_powerup( "nuke" );
	include_powerup( "insta_kill" );
	include_powerup( "double_points" );
	include_powerup( "full_ammo" );
	include_powerup( "carpenter" );
}

above_couches_death()
{
	level endon ("junk purchased");
	
	while (1)
	{
		wait 0.2;
				
		players = get_players();
		
		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] > 145)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
			}
		}
	}
}

above_roof_death()
{
	while (1)
	{
		wait 0.2;
		
		players = get_players();
		
		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] > 235)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
			}
		}
	}
}

below_ground_death()
{
	while (1)
	{
		wait 0.2;
		
		players = get_players();
		
		for (i = 0; i < players.size; i++)
		{
			if (players[i].origin[2] < -11)
			{
				setsaveddvar("player_deathInvulnerableTime", 0);
				players[i] DoDamage( players[i].health + 1000, players[i].origin, undefined, undefined, "riflebullet" );
				setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
			}
		}
	}
}


out_of_bounds_watcher()
{
	self endon ("disconnect");
	
	outside_of_map = [];
 	
 	outside_of_map[0]["min"] = (361, 591, -11);
 	outside_of_map[0]["max"] = (1068, 1031, 235);
 	
 	outside_of_map[1]["min"] = (-288, 591, -11);
 	outside_of_map[1]["max"] = (361, 1160, 235);
 	
 	outside_of_map[2]["min"] = (-272, 120, -11);
 	outside_of_map[2]["max"] = (370, 591, 235);

 	outside_of_map[3]["min"] = (-272, -912, -11);
 	outside_of_map[3]["max"] = (273, 120, 235);
 	 	
	while (1)
 	{	
		array_check = outside_of_map.size;
		
		kill_player = true;
 		for(i = 0; i < array_check; i++)
 		{
 			if (self is_within_volume(	outside_of_map[i]["min"][0], outside_of_map[i]["max"][0], 
 										outside_of_map[i]["min"][1], outside_of_map[i]["max"][1],
 										outside_of_map[i]["min"][2], outside_of_map[i]["max"][2]))
 			{
 				kill_player = false;

 			} 			
 		}		
 		
 		if (kill_player)
 		{
 			setsaveddvar("player_deathInvulnerableTime", 0);
			self DoDamage( self.health + 1000, self.origin, undefined, undefined, "riflebullet" );
			setsaveddvar("player_deathInvulnerableTime", level.startInvulnerableTime);	
 		}
 		
 		wait 0.2;
 	}	

}

check_solo_game()
{
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	if ( players.size == 1 )
	{
		flag_set( "solo_game" );
		level.solo_lives_given = 0;
		players[0].lives = 0;
		if(level.gamemode == "survival")
		{
			players[0].lives = 3;
		}
	}
}
//*****************************************************************************
// ZONE INIT
//*****************************************************************************
prototype_zone_init()
{
	flag_init( "always_on" );
	flag_set( "always_on" );

	zone_volume = Spawn( "trigger_radius", (321, 356, 10), 0, 256, 128 );
	zone_volume.targetname = "start_zone";
	zone_volume.script_noteworthy = "player_volume";

	// foyer_zone
	add_adjacent_zone( "start_zone", "box_zone", "start_2_box" );	
	add_adjacent_zone( "start_zone", "upstairs_zone", "start_2_upstairs" );	
	add_adjacent_zone( "box_zone", "upstairs_zone", "box_2_upstairs" );	
}	

prototype_eggs()
{
	trigs = getentarray ("evt_egg_killme", "targetname");
	for(i=0;i<trigs.size;i++)
	{
		trigs[i] thread check_for_egg_damage();
	}	
}

check_for_egg_damage()
{
	if(!IsDefined (level.egg_damage_counter))
	{
		level.egg_damage_counter = 0;		
	}
	self waittill ("damage");
	level.egg_damage_counter = level.egg_damage_counter + 1;
//	iprintlnbold ("ouch");	
}

time_to_play()
{
	if(level.gamemode != "survival")
	{
		return;
	}

	if(!IsDefined (level.egg_damage_counter))
	{
		level.egg_damage_counter = 0;		
	}

	while(level.egg_damage_counter < 3)
	{ 
		wait(0.5);
	}
	
	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "egg" );
	
	wait(4);
/*	
	if( IsDefined( player ) )
	{
	    player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "music_activate" );
	}
*/

	wait(223);	
	level.music_override = false;
	level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

}

pistol_rank_setup()
{
	flag_init( "_start_zm_pistol_rank" );

	flag_wait( "all_players_connected" );
	players = GetPlayers();
	if ( players.size == 1 )
	{
		solo = true;
		flag_set( "solo_game" );
		level.solo_lives_given = 0;
		players[0].lives = 0;
		level maps\_zombiemode::zombiemode_solo_last_stand_pistol();
	}

	flag_set( "_start_zm_pistol_rank" );
}

zombie_collision_patch()
{
	PreCacheModel("collision_geo_32x32x128");
	
	collision = spawn("script_model", (518, 756, 209));
	collision setmodel("collision_geo_32x32x128");
	collision.angles = (0, 0, 0);
	collision Hide();
}