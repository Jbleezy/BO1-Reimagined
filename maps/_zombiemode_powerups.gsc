#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;


//
init()
{
	PrecacheShader( "specialty_doublepoints_zombies" );
	PrecacheShader( "specialty_instakill_zombies" );
	PrecacheShader( "specialty_firesale_zombies");
	PrecacheShader( "zom_icon_bonfire" );
	PrecacheShader( "zom_icon_minigun" );
	PrecacheShader( "specialty_lightningbolt_zombies" );

	PrecacheShader( "black" );
	// powerup Vars
	set_zombie_var( "zombie_insta_kill", 				0 );
	set_zombie_var( "zombie_damage_scalar", 			1 );
	set_zombie_var( "zombie_point_scalar", 				1 );
	set_zombie_var( "zombie_drop_item", 				0 );
	set_zombie_var( "zombie_timer_offset", 				350 );	// hud offsets
	set_zombie_var( "zombie_timer_offset_interval", 	30 );
	set_zombie_var( "zombie_powerup_fire_sale_on", 	false );
	set_zombie_var( "zombie_powerup_fire_sale_time", 30 );
	set_zombie_var( "zombie_powerup_bonfire_sale_on", 	false );
	set_zombie_var( "zombie_powerup_bonfire_sale_time", 30 );
	/*set_zombie_var( "zombie_powerup_insta_kill_on", 	false );
	set_zombie_var( "zombie_powerup_insta_kill_time", 	30 );	// length of insta kill
	set_zombie_var( "zombie_powerup_point_doubler_on", 	false );
	set_zombie_var( "zombie_powerup_point_doubler_time", 30 );	// length of point doubler*/
//	Modify by the percentage of points that the player gets
	set_zombie_var( "zombie_powerup_drop_increment", 	2000 );	// lower this to make drop happen more often
	set_zombie_var( "zombie_powerup_drop_max_per_round", 4 );	// raise this to make drop happen more often

	// special vars for individual power ups
	thread init_player_zombie_vars();

	// powerups
	level._effect["powerup_on"] 					= loadfx( "misc/fx_zombie_powerup_on" );
	level._effect["powerup_grabbed"] 				= loadfx( "misc/fx_zombie_powerup_grab" );
	level._effect["powerup_grabbed_wave"] 			= loadfx( "misc/fx_zombie_powerup_wave" );

	level._effect["powerup_on_red"] 				= loadfx( "misc/fx_zombie_powerup_on_red" );
	level._effect["powerup_grabbed_red"] 			= loadfx( "misc/fx_zombie_powerup_red_grab" );
	level._effect["powerup_grabbed_wave_red"] 		= loadfx( "misc/fx_zombie_powerup_red_wave" );

	level._effect["powerup_on_solo"]				= LoadFX( "misc/fx_zombie_powerup_solo_on" );
	level._effect["powerup_grabbed_solo"]			= LoadFX( "misc/fx_zombie_powerup_solo_grab" );
	level._effect["powerup_grabbed_wave_solo"] 		= loadfx( "misc/fx_zombie_powerup_solo_wave" );
	level._effect["powerup_on_caution"]				= LoadFX( "misc/fx_zombie_powerup_caution_on" );
	level._effect["powerup_grabbed_caution"]		= LoadFX( "misc/fx_zombie_powerup_caution_grab" );
	level._effect["powerup_grabbed_wave_caution"] 	= loadfx( "misc/fx_zombie_powerup_caution_wave" );

	if( level.mutators["mutator_noPowerups"] )
	{
		return;
	}

	level.powerups = [];

	init_powerups();

	thread watch_for_drop();
	thread setup_firesale_audio();
	thread setup_bonfiresale_audio();

	level.use_new_carpenter_func = maps\_zombiemode_powerups::start_carpenter_new;
	level.board_repair_distance_squared = 750*750;

	level.powerup_chance_kills = 0;
	level.powerup_chance_kills_max_default = 100;
	level.powerup_chance_kills_half_default = int(level.powerup_chance_kills_max_default / 2);
	level.powerup_chance_kills_max = level.powerup_chance_kills_half_default;
	level.powerup_chance_kills_half = level.powerup_chance_kills_half_default;
	level.powerup_chance_default = 2;
	level.powerup_chance = level.powerup_chance_default;
	level.powerup_chance_increment_default = level.powerup_chance / level.powerup_chance_kills_max;
	level.powerup_chance_increment = level.powerup_chance_increment_default;
	level.powerup_chance_increment_multiplier = 2;

	level.last_powerup = false;
	level.powerup_overrides = [];

	level thread remove_carpenter();
	level thread add_powerup_later("fire_sale");
	level thread add_powerup_later("minigun");
}

//
init_powerups()
{
	flag_init( "zombie_drop_powerups" );	// As long as it's set, powerups will be able to spawn
	flag_set( "zombie_drop_powerups" );

	if( !IsDefined( level.zombie_powerup_array ) )
	{
		level.zombie_powerup_array = [];
	}
	if ( !IsDefined( level.zombie_special_drop_array ) )
	{
		level.zombie_special_drop_array = [];
	}

	// Random Drops
	add_zombie_powerup( "nuke", 		"zombie_bomb",		&"ZOMBIE_POWERUP_NUKE", false, false, false, 			"misc/fx_zombie_mini_nuke_hotness" );
//	add_zombie_powerup( "nuke", 		"zombie_bomb",		&"ZOMBIE_POWERUP_NUKE", false, false, false, 			"misc/fx_zombie_mini_nuke_hotness" );
	add_zombie_powerup( "insta_kill", 	"zombie_skull",		&"ZOMBIE_POWERUP_INSTA_KILL", false, false, false );
	add_zombie_powerup( "double_points","zombie_x2_icon",	&"ZOMBIE_POWERUP_DOUBLE_POINTS", false, false, false );
	add_zombie_powerup( "full_ammo",  	"zombie_ammocan",	&"ZOMBIE_POWERUP_MAX_AMMO", false, false, false );

	/*if( !level.mutators["mutator_noBoards"] )
	{
		add_zombie_powerup( "carpenter",  	"zombie_carpenter",	&"ZOMBIE_POWERUP_MAX_AMMO", false, false, false );
	}*/

	//GZheng - Temp VO
	//add the correct VO for firesale in the 3rd parameter of this function.
	if( !level.mutators["mutator_noMagicBox"] )
	{
		add_zombie_powerup( "fire_sale",  	"zombie_firesale",	&"ZOMBIE_POWERUP_MAX_AMMO", false, false, false );
	}

	add_zombie_powerup( "bonfire_sale",  	"zombie_pickup_bonfire",	&"ZOMBIE_POWERUP_MAX_AMMO", false, false, false );

	//PI ESM - Temp VO
	//TODO add the correct VO for revive all in the 3rd parameter of this function.
	add_zombie_powerup( "all_revive",  	"zombie_revive",	&"ZOMBIE_POWERUP_MAX_AMMO", false, false, false );

	//	add_zombie_special_powerup( "monkey" );

	// additional special "drops"
//	add_zombie_special_drop( "nothing" );
	add_zombie_special_drop( "dog" );

	// minigun
	add_zombie_powerup( "minigun",	"zombie_pickup_minigun", &"ZOMBIE_POWERUP_MINIGUN", true, false, false );

	// free perk
	add_zombie_powerup( "free_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_FREE_PERK", false, false, false );

	// tesla
	add_zombie_powerup( "tesla", "lightning_bolt", &"ZOMBIE_POWERUP_MINIGUN", true, false, false );

	// random weapon
	add_zombie_powerup( "random_weapon", "zombie_pickup_minigun", &"ZOMBIE_POWERUP_MAX_AMMO", true, false, false );

	// bonus points
	add_zombie_powerup( "bonus_points_player", "zombie_z_money_icon", &"REIMAGINED_BONUS_POINTS", true, false, false );
	add_zombie_powerup( "bonus_points_team", "zombie_z_money_icon", &"REIMAGINED_BONUS_POINTS", false, false, false );
	add_zombie_powerup( "lose_points_team", "zombie_z_money_icon", &"ZOMBIE_POWERUP_LOSE_POINTS", false, false, true );

	// lose perk
	add_zombie_powerup( "lose_perk", "zombie_pickup_perk_bottle", &"ZOMBIE_POWERUP_MAX_AMMO", false, false, true );

	// empty clip
	add_zombie_powerup( "empty_clip", "zombie_ammocan", &"ZOMBIE_POWERUP_MAX_AMMO", false, false, true );

	// grief powerups
	add_zombie_powerup( "meat", GetWeaponModel("meat_zm"), &"REIMAGINED_CLIP_UNLOAD", true, false, false );
	add_zombie_powerup( "upgrade_weapon", "zombie_pickup_bonfire", &"REIMAGINED_CLIP_UNLOAD", true, false, false );

	// Randomize the order
	randomize_powerups();
	level.zombie_powerup_index = 0;
	randomize_powerups();

	// Rare powerups
	level.rare_powerups_active = 0;

	//AUDIO: Prevents the long firesale vox from playing more than once
	level.firesale_vox_firstime = false;

	level thread powerup_hud_overlay();

	if ( isdefined( level.quantum_bomb_register_result_func ) )
	{
		[[level.quantum_bomb_register_result_func]]( "random_powerup", ::quantum_bomb_random_powerup_result, 100, ::quantum_bomb_random_powerup_validation );
		//[[level.quantum_bomb_register_result_func]]( "random_zombie_grab_powerup", ::quantum_bomb_random_zombie_grab_powerup_result, 5, level.quantum_bomb_in_playable_area_validation_func );
		[[level.quantum_bomb_register_result_func]]( "random_weapon_powerup", ::quantum_bomb_random_weapon_powerup_result, 0, ::quantum_bomb_random_powerup_validation );
		[[level.quantum_bomb_register_result_func]]( "random_bonus_points_powerup", ::quantum_bomb_random_bonus_or_lose_points_powerup_result, 0, ::quantum_bomb_random_powerup_validation );
	}
}


//	Creates zombie_vars that need to be tracked on an individual basis rather than as
//	a group.
init_player_zombie_vars()
{
	flag_wait( "all_players_connected" );

	players = get_players();
	for( p = 0; p < players.size; p++ )
	{
		players[p].zombie_vars[ "zombie_powerup_minigun_on" ] = false; // minigun
		players[p].zombie_vars[ "zombie_powerup_minigun_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_tesla_on" ] = false; // tesla
		players[p].zombie_vars[ "zombie_powerup_tesla_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_insta_kill_on" ] = false; // insta
		players[p].zombie_vars[ "zombie_powerup_insta_kill_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_point_doubler_on" ] = false; // double
		players[p].zombie_vars[ "zombie_powerup_point_doubler_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_fire_sale_on" ] = false; // fire
		players[p].zombie_vars[ "zombie_powerup_fire_sale_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_bonfire_sale_on" ] = false; // bonfire
		players[p].zombie_vars[ "zombie_powerup_bonfire_sale_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_insta_kill_round_on" ] = false; // insta kill round
		players[p].zombie_vars[ "zombie_powerup_insta_kill_round_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_half_points_on" ] = false; // half points
		players[p].zombie_vars[ "zombie_powerup_half_points_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_half_damage_on" ] = false; // half damage
		players[p].zombie_vars[ "zombie_powerup_half_damage_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_slow_down_on" ] = false; // slow down
		players[p].zombie_vars[ "zombie_powerup_slow_down_time" ] = 0;

		players[p].zombie_vars[ "zombie_powerup_upgrade_weapon_on" ] = false; // upgrade weapon
		players[p].zombie_vars[ "zombie_powerup_upgrade_weapon_time" ] = 0;

		players[p].zombie_vars["zombie_point_scalar"] = 1;
		players[p].zombie_vars["zombie_damage_scalar"] = 1;
	}
}

hud_move_over_time(new_pos)
{
	self notify("hud_moving");
	self endon("hud_moving");

	current_pos = self.x;
	time = .5;
	iterations = time / .05;
	distance = (new_pos - current_pos) / iterations;

	for(i=0;i<iterations;i++)
	{
		self.x += distance;
		wait .05;
	}

	self.x = new_pos;

	//doesnt work, starts at top left corner
	//self MoveOverTime(.5);
	//self.x = new_pos;
}


//powerup hud
powerup_hud_overlay()
{
	level endon ("disconnect");

	flag_wait( "all_players_connected" );
	wait( 0.1 );  // wait for solo zombie_vars to be initialized in init_player_zombie_vars

	players = get_players();
	for( p = 0; p < players.size; p++ )
	{
		players[p].powerup_hud_array = [];
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // minigun
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // tesla
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // insta
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // double
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // fire
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // bonfire

		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // insta kill round

		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // half points
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // half damage
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // slow down
		players[p].powerup_hud_array[ players[p].powerup_hud_array.size ] = true; // upgrade weapon

		players[p].powerup_hud = [];
		players[p].powerup_hud_cover = [];

		for(i = 0; i < players[p].powerup_hud_array.size; i++)
		{
			players[p].powerup_hud[i] = create_simple_hud( players[p] );
			players[p].powerup_hud[i].foreground = true;
			players[p].powerup_hud[i].sort = 2;
			players[p].powerup_hud[i].hidewheninmenu = false;
			players[p].powerup_hud[i].alignX = "center";
			players[p].powerup_hud[i].alignY = "bottom";
			players[p].powerup_hud[i].horzAlign = "user_center";
			players[p].powerup_hud[i].vertAlign = "user_bottom";
			players[p].powerup_hud[i].x = 0;
			players[p].powerup_hud[i].y -= 5; // ww: used to offset by - 78
			players[p].powerup_hud[i].alpha = 0.8;
		}

		players[p].active_powerup_hud = [];

		players[p] thread power_up_hud( "zom_icon_minigun", players[p].powerup_hud[0], "zombie_powerup_minigun_time", "zombie_powerup_minigun_on" );
		players[p] thread power_up_hud( "specialty_lightningbolt_zombies", players[p].powerup_hud[1], "zombie_powerup_tesla_time", "zombie_powerup_tesla_on" );
		players[p] thread power_up_hud( "specialty_doublepoints_zombies", players[p].powerup_hud[2], "zombie_powerup_point_doubler_time", "zombie_powerup_point_doubler_on" );
		players[p] thread power_up_hud( "specialty_instakill_zombies", players[p].powerup_hud[3], "zombie_powerup_insta_kill_time", "zombie_powerup_insta_kill_on" );
		players[p] thread power_up_hud( "specialty_firesale_zombies", players[p].powerup_hud[4], "zombie_powerup_fire_sale_time", "zombie_powerup_fire_sale_on" );
		players[p] thread power_up_hud( "zom_icon_bonfire", players[p].powerup_hud[5], "zombie_powerup_bonfire_sale_time", "zombie_powerup_bonfire_sale_on" );

		players[p] thread power_up_hud( "specialty_instakill_zombies", players[p].powerup_hud[6], "zombie_powerup_insta_kill_round_time", "zombie_powerup_insta_kill_round_on", false, true );

		players[p] thread power_up_hud( "specialty_doublepoints_zombies", players[p].powerup_hud[7], "zombie_powerup_half_points_time", "zombie_powerup_half_points_on", true );
		players[p] thread power_up_hud( "specialty_instakill_zombies", players[p].powerup_hud[8], "zombie_powerup_half_damage_time", "zombie_powerup_half_damage_on", true );
		players[p] thread power_up_hud( "specialty_slowdown_zombies", players[p].powerup_hud[9], "zombie_powerup_slow_down_time", "zombie_powerup_slow_down_on", true );
		players[p] thread power_up_hud( "zom_icon_bonfire", players[p].powerup_hud[10], "zombie_powerup_upgrade_weapon_time", "zombie_powerup_upgrade_weapon_on" );
	}
}


//
power_up_hud( Shader, PowerUp_Hud, PowerUp_timer, PowerUp_Var, red, yellow )
{
	self endon( "disconnect" );

	if(!IsDefined(red))
	{
		red = false;
	}

	if(!IsDefined(yellow))
	{
		yellow = false;
	}

	while(true)
	{
		if(PowerUp_Var == "zombie_powerup_insta_kill_round_on")
		{
			if(flag("insta_kill_round"))
			{
				self.zombie_vars[PowerUp_Var] = true;
				self.zombie_vars[PowerUp_timer] = 30;
			}
			else
			{
				self.zombie_vars[PowerUp_Var] = false;
				self.zombie_vars[PowerUp_timer] = 0;
			}
		}

		if(self.zombie_vars[PowerUp_timer] < 5 ) //&& ( IsDefined( self._show_solo_hud ) && self._show_solo_hud == true )
		{
			wait(0.1);
			PowerUp_Hud FadeOverTime( 0.1 );
			PowerUp_Hud.alpha = 0;
			wait(0.1);
		}
		else if(self.zombie_vars[PowerUp_timer] < 10 ) //&& ( IsDefined( self._show_solo_hud ) && self._show_solo_hud == true )
		{
			wait(0.2);
			PowerUp_Hud FadeOverTime( 0.2 );
			PowerUp_Hud.alpha = 0;
			wait(0.2);
		}

		if( self.zombie_vars[PowerUp_Var] == true ) //&& ( IsDefined( self._show_solo_hud ) && self._show_solo_hud == true )
		{
			if(red)
			{
				PowerUp_Hud.color = (.6,0,0);
			}
			else if(yellow)
			{
				PowerUp_Hud.color = (1,1,0);
			}
			else
			{
				PowerUp_Hud.color = (1,1,1);
			}

			if(self.zombie_vars[PowerUp_timer] < 5)
				PowerUp_Hud FadeOverTime( 0.1 );
			else if(self.zombie_vars[PowerUp_timer] < 10)
				PowerUp_Hud FadeOverTime( 0.2 );
			else
				PowerUp_Hud FadeOverTime( 0.5 );

			PowerUp_Hud.alpha = 1;
			PowerUp_Hud setshader(Shader, 32, 32);

			if(!is_in_array(self.active_powerup_hud, PowerUp_Hud))
			{
				self.active_powerup_hud[self.active_powerup_hud.size] = PowerUp_Hud;
				for(i=0;i<self.active_powerup_hud.size;i++)
				{
					if(self.active_powerup_hud.size % 2 == 1) //odd
					{
						self.active_powerup_hud[i] thread hud_move_over_time(((int(self.active_powerup_hud.size / 2)) * -40) + (i * 40));
					}
					else //even
					{
						self.active_powerup_hud[i] thread hud_move_over_time(((int(self.active_powerup_hud.size / 2)) * -20) + (i * 40));
					}
				}
			}
		}
		else
		{
			PowerUp_Hud FadeOverTime( 0.1 );
			PowerUp_Hud.alpha = 0;
			PowerUp_Hud.x = 0;
			if(is_in_array(self.active_powerup_hud, PowerUp_Hud))
			{
				self.active_powerup_hud = array_remove(self.active_powerup_hud, PowerUp_Hud);
				for(i=0;i<self.active_powerup_hud.size;i++)
				{
					if(self.active_powerup_hud.size % 2 == 1) //odd
					{
						self.active_powerup_hud[i] thread hud_move_over_time(((int(self.active_powerup_hud.size / 2)) * -40) + (i * 40));
					}
					else //even
					{
						self.active_powerup_hud[i] thread hud_move_over_time(((int(self.active_powerup_hud.size / 2)) * -20) + (i * 40));
					}
				}
			}
		}

		wait( 0.05 );
	}
}
//** solo hud


randomize_powerups()
{
	level.zombie_powerup_array = array_randomize( level.zombie_powerup_array );
}

//
// Get the next powerup in the list
//
get_next_powerup()
{
	powerup = level.zombie_powerup_array[ level.zombie_powerup_index ];

	/*for(i=level.zombie_powerup_index;i<level.zombie_powerup_array.size;i++)
	{
		iprintln(level.zombie_powerup_array[i]);
	}*/

	while(1)
	{
		level.zombie_powerup_index++;

		if( level.zombie_powerup_index >= level.zombie_powerup_array.size )
		{
			level.zombie_powerup_index = 0;
			randomize_powerups();
			level.last_powerup = true;
		}

		if(is_valid_powerup(level.zombie_powerup_array[level.zombie_powerup_index]))
		{
			break;
		}
	}

	return powerup;
}


//
// Figure out what the next powerup drop is
//
// Powerup Rules:
//   "carpenter": Needs at least 5 windows destroyed
//   "fire_sale": Needs the box to have moved
//
//
get_valid_powerup()
{
/#
	if( isdefined( level.zombie_devgui_power ) && level.zombie_devgui_power == 1 )
		return level.zombie_powerup_array[ level.zombie_powerup_index ];
#/

	if ( isdefined( level.zombie_powerup_boss ) )
	{
		i = level.zombie_powerup_boss;
		level.zombie_powerup_boss = undefined;
		return level.zombie_powerup_array[ i ];
	}

	if ( isdefined( level.zombie_powerup_ape ) )
	{
		powerup = level.zombie_powerup_ape;
		level.zombie_powerup_ape = undefined;
		return powerup;
	}

	powerup = get_next_powerup();
	while( 1 )
	{
		if(!is_valid_powerup(powerup))
		{
			powerup = get_next_powerup();
		}
		else
		{
			return( powerup );
		}
	}
}

is_valid_powerup(powerup_name)
{
	// Carpenter needs 5 destroyed windows
	if( powerup_name == "carpenter" ) //&& get_num_window_destroyed() < 5
	{
		return false;
	}
	// Don't bring up fire_sale if the box hasn't moved
	else if( powerup_name == "fire_sale" &&( level.chest_moves < 1 ) ) //level.zombie_vars["zombie_powerup_fire_sale_on"] == true ||
	{
		return false;
	}
	else if( powerup_name == "all_revive" )
	{
		if ( !maps\_laststand::player_num_in_laststand() ) //PI ESM - at least one player have to be down for this power-up to appear
		{
			return false;
		}
	}
	else if ( powerup_name == "bonfire_sale" )	// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "minigun" && minigun_no_drop() ) // don't drop unless life bought in solo, or power has been turned on
	{
		return false;
	}
	else if ( powerup_name == "free_perk" )		// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "tesla" )					// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "random_weapon" )					// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "bonus_points_player" )					// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "bonus_points_team" && level.gamemode == "survival" )					// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "lose_points_team" )					// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "lose_perk" )					// never drops with regular powerups
	{
		return false;
	}
	else if( powerup_name == "empty_clip" )					// never drops with regular powerups
	{
		return false;
	}
	
	return true;
}

//gets random powerup without effecting the current powerup cycle
get_random_valid_powerup()
{
	powerups = array_randomize(level.zombie_powerup_array);
	i = 0;
	powerup = powerups[i];
	while(!is_valid_powerup(powerup))
	{
		i++;
		if(i >= powerups.size)
		{
			break;
		}
		powerup = powerups[i];
	}
	return powerup;
}

minigun_no_drop()
{
	/*players = GetPlayers();
	for ( i=0; i<players.size; i++ )
	{
		if( players[i].zombie_vars[ "zombie_powerup_minigun_on" ] == true )
		{
			return true;
		}
	}*/

	if( !flag( "power_on" ) ) // if power is not on check for solo
	{
		if( flag( "solo_game" ) ) // if it is a solo game then perform another check
		{
			if( level.solo_lives_given == 0 ) // the power isn't on, it is a solo game, has the player purchased a life/revive?
			{
				return true; // no drop because the player has no bought a life/revive
			}
		}
		else
		{
			return true; // not a solo game, powerup is invalid
		}
	}

	return false;
}



get_num_window_destroyed()
{
	num = 0;
	for( i = 0; i < level.exterior_goals.size; i++ )
	{
		/*targets = getentarray(level.exterior_goals[i].target, "targetname");

		barrier_chunks = [];
		for( j = 0; j < targets.size; j++ )
		{
			if( IsDefined( targets[j].script_noteworthy ) )
			{
				if( targets[j].script_noteworthy == "clip" )
				{
					continue;
				}
			}

			barrier_chunks[barrier_chunks.size] = targets[j];
		}*/


		if( all_chunks_destroyed( level.exterior_goals[i].barrier_chunks ) )
		{
			num += 1;
		}

	}

	return num;
}

// initial drop amounts:
// 1p - 2500
// 2p - 3500
// 3p - 4500
// 4p - 5500
watch_for_drop()
{
	flag_wait( "begin_spawning" );

	players = get_players();
	level.zombie_vars["zombie_powerup_drop_increment"] = ((players.size - 1) * 1000) + 2500;
	score_to_drop = level.zombie_vars["zombie_powerup_drop_increment"];

	while (1)
	{
		flag_wait( "zombie_drop_powerups" );

		players = get_players();
		curr_total_score = 0;
		for (i = 0; i < players.size; i++)
		{
			curr_total_score += players[i].score_total;
		}

		if (curr_total_score >= score_to_drop)
		{
			level.zombie_vars["zombie_drop_item"] = 1;
			while(curr_total_score >= score_to_drop)
			{
				level.zombie_vars["zombie_powerup_drop_increment"] *= 1.1;
				score_to_drop += level.zombie_vars["zombie_powerup_drop_increment"];
			}
		}

		wait( 0.5 );
	}
}

add_zombie_powerup( powerup_name, model_name, hint, solo, caution, zombie_grabbable, fx )
{
	if( IsDefined( level.zombie_include_powerups ) && !IsDefined( level.zombie_include_powerups[powerup_name] ) )
	{
		return;
	}

	PrecacheModel( model_name );
	PrecacheString( hint );

	struct = SpawnStruct();

	if( !IsDefined( level.zombie_powerups ) )
	{
		level.zombie_powerups = [];
	}

	struct.powerup_name = powerup_name;
	struct.model_name = model_name;
	struct.weapon_classname = "script_model";
	struct.hint = hint;
	struct.solo = solo;
	struct.caution = caution;
	struct.zombie_grabbable = zombie_grabbable;

	if( IsDefined( fx ) )
	{
		struct.fx = LoadFx( fx );
	}

	level.zombie_powerups[powerup_name] = struct;
	level.zombie_powerup_array[level.zombie_powerup_array.size] = powerup_name;
	add_zombie_special_drop( powerup_name );
}


// special powerup list for the teleporter drop
add_zombie_special_drop( powerup_name )
{
	level.zombie_special_drop_array[ level.zombie_special_drop_array.size ] = powerup_name;
}

include_zombie_powerup( powerup_name )
{
	if( "1" == GetDvar( #"mutator_noPowerups") )
	{
		return;
	}
	if( !IsDefined( level.zombie_include_powerups ) )
	{
		level.zombie_include_powerups = [];
	}

	level.zombie_include_powerups[powerup_name] = true;
}

powerup_round_start()
{
	level.powerup_drop_count = 0;
}

powerup_drop(drop_point, player, zombie)
{
	if( level.mutators["mutator_noPowerups"] )
	{
		return;
	}

	type = "";
	powerup_override = undefined;

	if(level.powerup_overrides.size > 0)
	{
		powerup_override = level.powerup_overrides[0];
		if(!IsDefined(powerup_override.player) || powerup_override.player == player)
		{
			type = "override";
		}

		if(IsDefined(powerup_override.player))
		{
			powerup_override.player.gg_wep_dropped = true;
		}
	}

	if( type != "override" && level.powerup_drop_count >= level.zombie_vars["zombie_powerup_drop_max_per_round"] )
	{
		/#
		println( "^3POWERUP DROP EXCEEDED THE MAX PER ROUND!" );
		#/
		return;
	}

	if( !isDefined(level.zombie_include_powerups) || level.zombie_include_powerups.size == 0 )
	{
		return;
	}

	// some guys randomly drop, but most of the time they check for the drop flag
	rand_drop = RandomFloat(100);

	if(type != "override")
	{
		if(level.zombie_vars["zombie_drop_item"])
		{
			type = "score";
		}
		else if(rand_drop <= level.powerup_chance)
		{
			type = "random";
		}
		else
		{
			incremenet_powerup_chance();
			return;
		}
	}

	// This needs to go above the network_safe_spawn because that has a wait.
	// Otherwise, multiple threads could attempt to drop powerups.
	if(type != "override")
	{
		level.powerup_drop_count++;
	}

	powerup = maps\_zombiemode_net::network_safe_spawn( "powerup", 1, "script_model", drop_point + (0,0,40));

	// Never drop unless in the playable area
	valid_drop = false;
	playable_area = getentarray("player_volume","script_noteworthy");
	for (i = 0; i < playable_area.size; i++)
	{
		if (powerup istouching(playable_area[i]))
		{
			valid_drop = true;
		}
	}

	// If a valid drop
	// We will rarely override the drop with a "rare drop"  (MikeA 3/23/10)
	if( valid_drop && level.rare_powerups_active )
	{
		pos = ( drop_point[0], drop_point[1], drop_point[2] + 42 );
		if( check_for_rare_drop_override( pos ) )
		{
			level.zombie_vars["zombie_drop_item"] = 0;
			valid_drop = 0;
		}
	}

	// If not a valid drop, allow another spawn to be attempted
	if( !valid_drop )
	{
		if(type == "override" && IsDefined(powerup_override.player))
		{
			powerup_override.player.gg_wep_dropped = undefined;
		}

		if(type == "random")
		{
			incremenet_powerup_chance();
		}

		if(type != "override")
		{
			level.powerup_drop_count--;
		}
		powerup delete();
		return;
	}

	if(type == "override")
	{
		powerup.gg_powerup = powerup_override.gg_powerup;
		powerup.player = powerup_override.player;
		powerup.powerup_notify = powerup_override.powerup_notify;
		powerup powerup_setup(powerup_override.powerup_name);

		if(IsDefined(powerup.player))
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				if(players[i] != powerup.player)
				{
					powerup SetInvisibleToPlayer(players[i], true);
				}
			}
		}

		if(IsDefined(powerup.gg_powerup))
		{
			powerup thread timeout_on_down();
			powerup thread timeout_on_grabbed();
		}

		if(IsDefined(powerup.powerup_notify))
		{
			level notify( powerup.powerup_notify );
		}

		level.powerup_overrides = array_remove_nokeys(level.powerup_overrides, powerup_override);
	}
	else
	{
		powerup powerup_setup();

		if(level.last_powerup)
		{
			if(powerup.solo)
			{
				PlayFX( level._effect["powerup_grabbed_solo"], powerup.origin );
			}
			else
			{
				PlayFX( level._effect["powerup_grabbed"], powerup.origin );
			}

			level.last_powerup = false;
		}

		if(type == "score")
		{
			level.zombie_vars["zombie_drop_item"] = 0;
		}

		reset_powerup_chance();
	}

	print_powerup_drop( powerup.powerup_name, type );

	powerup thread powerup_timeout();
	powerup thread powerup_wobble();
	powerup thread powerup_grab();

	// RAVEN BEGIN bhackbarth: let the level know that a powerup has been dropped
	level notify("powerup_dropped", powerup);
	// RAVEN END
}

incremenet_powerup_chance()
{
	level.powerup_chance_kills++;
	if(level.powerup_chance_kills >= level.powerup_chance_kills_max_default)
	{
		level.powerup_chance = 100;
	}
	else
	{
		if(level.powerup_chance_kills >= level.powerup_chance_kills_max)
		{
			level.powerup_chance_kills_half = int(level.powerup_chance_kills_half / 2);
			level.powerup_chance_kills_max += level.powerup_chance_kills_half;
			level.powerup_chance_increment *= level.powerup_chance_increment_multiplier;
		}
		level.powerup_chance += level.powerup_chance_increment;
	}
}

reset_powerup_chance()
{
	level.powerup_chance_kills = 0;
	level.powerup_chance_kills_half = level.powerup_chance_kills_half_default;
	level.powerup_chance_kills_max = level.powerup_chance_kills_half_default;
	level.powerup_chance = level.powerup_chance_default;
	level.powerup_chance_increment = level.powerup_chance_increment_default;
}

//
//	Drop the specified powerup
specific_powerup_drop( powerup_name, drop_spot, permament, weapon )
{
	if(!IsDefined(permament))
		permament = false;

	powerup = maps\_zombiemode_net::network_safe_spawn( "powerup", 1, "script_model", drop_spot + (0,0,40));

	if(IsDefined(weapon))
	{
		powerup.weapon = weapon;
	}

	level notify("powerup_dropped", powerup);

	if ( IsDefined(powerup) )
	{
		powerup powerup_setup( powerup_name );

		if(!permament)
			powerup thread powerup_timeout();
		powerup thread powerup_wobble();
		powerup thread powerup_grab();
	}
}


quantum_bomb_random_powerup_result( position )
{
	keys = array("full_ammo", "double_points", "insta_kill", "nuke", "fire_sale", "free_perk", "bonus_points_team", "random_weapon");

	while ( keys.size )
	{
		index = RandomInt( keys.size );
		if ( !level.zombie_powerups[keys[index]].zombie_grabbable )
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
			[[level.quantum_bomb_play_player_effect_at_position_func]]( position );
			level specific_powerup_drop( keys[index], position );
			return;
		}
		else
		{
			keys = array_remove_nokeys( keys, keys[index] );
		}
	}
}


quantum_bomb_random_zombie_grab_powerup_result( position )
{
	if( !isDefined( level.zombie_include_powerups ) || !level.zombie_include_powerups.size )
	{
		return;
	}

	keys = GetArrayKeys( level.zombie_include_powerups );
	while ( keys.size )
	{
		index = RandomInt( keys.size );
		if ( level.zombie_powerups[keys[index]].zombie_grabbable )
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_bad" );
			[[level.quantum_bomb_play_player_effect_at_position_func]]( position );
			level specific_powerup_drop( keys[index], position );
			return;
		}
		else
		{
			keys = array_remove_nokeys( keys, keys[index] );
		}
	}
}


quantum_bomb_random_weapon_powerup_result( position )
{
	self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );

	[[level.quantum_bomb_play_player_effect_at_position_func]]( position );
	level specific_powerup_drop( "random_weapon", position );
}


quantum_bomb_random_bonus_or_lose_points_powerup_result( position )
{
	//rand = RandomInt( 10 );
	powerup = "bonus_points_team";

	[[level.quantum_bomb_play_player_effect_at_position_func]]( position );
	level specific_powerup_drop( powerup, position );
}


//
//	Special power up drop - done outside of the powerup system.
special_powerup_drop(drop_point, is_powerup, permament)
{
// 	if( level.powerup_drop_count == level.zombie_vars["zombie_powerup_drop_max_per_round"] )
// 	{
// 		println( "^3POWERUP DROP EXCEEDED THE MAX PER ROUND!" );
// 		return;
// 	}

	if( !isDefined(level.zombie_include_powerups) || level.zombie_include_powerups.size == 0 )
	{
		return;
	}

	if(!IsDefined(is_powerup))
		is_powerup = true;

	if(!IsDefined(permament))
		permament = false;

	powerup = spawn ("script_model", drop_point + (0,0,40));

	// never drop unless in the playable area
	playable_area = getentarray("player_volume","script_noteworthy");
	//chris_p - fixed bug where you could not have more than 1 playable area trigger for the whole map
	valid_drop = false;
	for (i = 0; i < playable_area.size; i++)
	{
		if (powerup istouching(playable_area[i]))
		{
			valid_drop = true;
			break;
		}
	}

	if(!valid_drop)
	{
		powerup Delete();
		return;
	}

	powerup special_drop_setup(is_powerup, permament);
}


cleanup_random_weapon_list()
{
	self waittill( "death" );

	level.random_weapon_powerups = array_remove_nokeys( level.random_weapon_powerups, self );
}


//
//	Pick the next powerup in the list
powerup_setup( powerup_override )
{
	powerup = undefined;

	if ( !IsDefined( powerup_override ) )
	{
		powerup = get_valid_powerup();
		//iprintln(powerup);
		//TODO - check for next valid powerup here to see if cycle resets
	}
	else
	{
		powerup = powerup_override;

		/*if ( "tesla" == powerup )
		{
			// only one tesla at a time, give a minigun instead
			powerup = "minigun";
		}*/
	}

	struct = level.zombie_powerups[powerup];

	if ( powerup == "random_weapon" )
	{
		if(IsDefined(self.gg_powerup))
		{
			self.weapon = level.gg_weps[self.player.gg_wep_num + 1];
			self.base_weapon = self.weapon;
		}
		else
		{
			// select the weapon for this instance of random_weapon
			if(!IsDefined(self.weapon))
			{
				self.weapon = maps\_zombiemode_weapons::treasure_chest_ChooseWeightedRandomWeapon();
			}

			/#
			weapon = GetDvar( #"scr_force_weapon" );
			if ( weapon != "" && IsDefined( level.zombie_weapons[ weapon ] ) )
			{
				self.weapon = weapon;
				SetDvar( "scr_force_weapon", "" );
			}
			#/

			self.base_weapon = self.weapon;
			if ( !isdefined( level.random_weapon_powerups ) )
			{
				level.random_weapon_powerups = [];
			}
			level.random_weapon_powerups[level.random_weapon_powerups.size] = self;
			self thread cleanup_random_weapon_list();

			if ( IsDefined( level.zombie_weapons[self.weapon].upgrade_name ) && !RandomInt( 4 ) ) // 25% chance
			{
				self.unupgrade_weapon = self.weapon;
				self.weapon = level.zombie_weapons[self.weapon].upgrade_name;
			}
		}

		if(self.weapon == "none")
		{
			self SetModel( "void" );
		}
		else
		{
			self SetModel( GetWeaponModel( self.weapon ) );
			self useweaponhidetags( self.weapon );

			offsetdw = ( 3, 3, 3 );
			self.worldgundw = undefined;
			if ( maps\_zombiemode_weapons::weapon_is_dual_wield( self.weapon ) )
			{
				self.worldgundw = spawn( "script_model", self.origin + offsetdw );
				self.worldgundw.angles  = self.angles;
				self.worldgundw setModel( maps\_zombiemode_weapons::get_left_hand_weapon_model_name( self.weapon ) );
				self.worldgundw useweaponhidetags( self.weapon );
				self.worldgundw LinkTo( self, "tag_weapon", offsetdw, (0, 0, 0) );
			}
		}

		if(!IsDefined(self.gg_powerup))
		{
			trigger = spawn( "trigger_radius_use", self.origin - (0,0,40), 0, 64, 72 );
			trigger enablelinkto();
			trigger linkto( self );
			trigger SetCursorHint( "HINT_NOICON" );
			if(is_tactical_grenade(self.weapon))
			{
				trigger sethintstring( &"REIMAGINED_TRADE_EQUIPMENT" );
			}
			else
			{
				trigger sethintstring( &"ZOMBIE_TRADE_WEAPONS" );
			}
			trigger thread random_weapon_powerup_hintstring_think(self.weapon);
			trigger thread random_weapon_powerup_think(self);
			self thread powerup_weapon_trigger_cleanup(trigger);
		}
	}
	else
	{
		self SetModel( struct.model_name );
	}

	if(powerup == "tesla")
	{
		if(IsDefined(level.upgraded_tesla_reward) && level.upgraded_tesla_reward)
		{
			self.weapon = "tesla_gun_powerup_upgraded_zm";
		}
		else
		{
			self.weapon = "tesla_gun_powerup_zm";
		}

		self.base_weapon = self.weapon;
		struct.weapon = self.weapon;
	}

	//TUEY Spawn Powerup
	playsoundatposition("zmb_spawn_powerup", self.origin);

	self.powerup_name 		= struct.powerup_name;
	self.hint 				= struct.hint;
	self.solo 				= struct.solo;
	self.caution 			= struct.caution;
	self.zombie_grabbable 	= struct.zombie_grabbable;

	if( IsDefined( struct.fx ) )
	{
		self.fx = struct.fx;
	}

	self PlayLoopSound("zmb_spawn_powerup_loop");
}

random_weapon_powerup_think(powerup)
{
	self endon("death");

	while(1)
	{
		self waittill("trigger", who);
		if( level random_weapon_powerup(powerup, who) )
		{
			break;
		}
	}
}

random_weapon_powerup_hintstring_think(powerup_weapon)
{
	self endon("death");

	while(1)
	{
		players = get_players();
		for ( i = 0; i < players.size; i++ )
		{
			current_weapon = players[i] GetCurrentWeapon();
			primaryWeapons = players[i] GetWeaponsListPrimaries();
			if(players[i] HasWeapon(powerup_weapon))
			{
				self SetInvisibleToPlayer( players[i], false );
			}
			else if(is_melee_weapon(current_weapon) && primaryWeapons.size > 0)
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else if(players[i] maps\_zombiemode_weapons::can_buy_weapon())
			{
				self SetInvisibleToPlayer( players[i], false );
			}
			else
			{
				self SetInvisibleToPlayer( players[i], true );
			}
		}
		wait_network_frame();
	}
}

//
//	Get the special teleporter drop
special_drop_setup(is_powerup, permament)
{
	powerup = undefined;

	if(is_powerup)
	{
		if(!IsDefined(powerup))
		{
			powerup = get_random_valid_powerup();
		}
	}
	else
	{
		is_powerup = false;
		powerup = "nothing";
	}

	Playfx( level._effect["lightning_dog_spawn"], self.origin );
	playsoundatposition( "pre_spawn", self.origin );
	wait( 1.5 );
	playsoundatposition( "zmb_bolt", self.origin );

	Earthquake( 0.5, 0.75, self.origin, 1000);
	PlayRumbleOnPosition("explosion_generic", self.origin);
	playsoundatposition( "spawn", self.origin );

	if( is_powerup )
	{
		self powerup_setup( powerup );

		if(!permament)
		{
			self thread powerup_timeout();
		}
		else
		{
			level notify("new_special_powerup");
			self thread powerup_timeout_on_next_powerup();
		}

		self thread powerup_wobble();
		self thread powerup_grab();
	}
	else
	{
		self Delete();
	}
}

powerup_timeout_on_next_powerup()
{
	self endon("death");

	level waittill("new_special_powerup");

	self notify( "powerup_timedout" );

	if ( isdefined( self.worldgundw ) )
	{
		self.worldgundw delete();
	}
	if( IsDefined(self) )
	{
		self delete();
	}
}

powerup_zombie_grab_trigger_cleanup( trigger )
{
	self waittill_any( "powerup_timedout", "powerup_grabbed", "hacked" );

	trigger delete();
}

powerup_zombie_grab()
{
	self endon( "powerup_timedout" );
	self endon( "powerup_grabbed" );
	self endon( "hacked" );

	spawnflags = 1; // SF_TOUCH_AI_AXIS
	zombie_grab_trigger = spawn( "trigger_radius", self.origin - (0,0,40), spawnflags, 32, 72 );
	zombie_grab_trigger enablelinkto();
	zombie_grab_trigger linkto( self );

	self thread powerup_zombie_grab_trigger_cleanup( zombie_grab_trigger );
	zombie_grab_trigger create_zombie_point_of_interest( 300, 2, 0, true );


	while ( isdefined( self ) )
	{
		zombie_grab_trigger waittill( "trigger", who );
		if ( !isdefined( who ) || !IsAI( who ) )
		{
			continue;
		}

		playfx( level._effect["powerup_grabbed_red"], self.origin );
		playfx( level._effect["powerup_grabbed_wave_red"], self.origin );

		switch ( self.powerup_name )
		{
		case "lose_points_team":
			level thread lose_points_team_powerup( self );

			players = get_players();
			players[randomintrange(0,players.size)] thread powerup_vo( "lose_points" ); // TODO: Audio should uncomment this once the sounds have been set up
			break;

		case "lose_perk":
			level thread lose_perk_powerup( self );

//			players = get_players();
//			players[randomintrange(0,players.size)] thread powerup_vo( "lose_perk" ); // TODO: Audio should uncomment this once the sounds have been set up
			break;

		case "empty_clip":
			level thread empty_clip_powerup( self );

//			players = get_players();
//			players[randomintrange(0,players.size)] thread powerup_vo( "empty_clip" ); // TODO: Audio should uncomment this once the sounds have been set up
			break;

		default:
			if ( IsDefined( level._zombiemode_powerup_zombie_grab ) )
			{
				level thread [[ level._zombiemode_powerup_zombie_grab ]]( self );
			}
			// RAVEN END
			else
			{
				println("Unrecognized poweup.");
			}

			break;
		}

		level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"][self.powerup_name] );

		wait( 0.1 );

		playsoundatposition( "zmb_powerup_grabbed", self.origin );
		self stoploopsound();

		if ( isdefined( self.worldgundw ) )
		{
			self.worldgundw delete();
		}
		self delete();
		self notify( "powerup_grabbed" );
	}
}

powerup_grab()
{
	if ( isdefined( self ) && self.zombie_grabbable )
	{
		self thread powerup_zombie_grab();
		return;
	}

	self endon ("powerup_timedout");
	self endon ("powerup_grabbed");
	self endon( "powerup_end" );

	range_squared = 64 * 64;
	while (isdefined(self))
	{
		players = get_players();

		for (i = 0; i < players.size; i++)
		{
			//spectators should not be able to pick up powerups
			if(players[i].sessionstate == "spectator")
			{
				continue;
			}

			// Don't let them grab the minigun, tesla, or random weapon if they're downed or reviving
			//	due to weapon switching issues.
			if ( (self.powerup_name == "minigun" || self.powerup_name == "tesla" || self.powerup_name == "random_weapon" || self.powerup_name == "upgrade_weapon" || 
				self.powerup_name == "meat") &&
				( players[i] maps\_laststand::player_is_in_laststand() || ( players[i] UseButtonPressed() && players[i] in_revive_trigger() ) ) )
			{
				continue;
			}

			//no picking up death machine if waffe is active
			if(self.powerup_name == "minigum" && IsDefined(players[i].has_tesla) && players[i].has_tesla)
				continue;

			//no picking up unupgraded waffe if upgraded waffe is active
			if(self.powerup_name == "tesla" && IsDefined(players[i].has_tesla) && players[i].has_tesla && players[i] GetCurrentWeapon() == "tesla_gun_powerup_upgraded_zm" && self.weapon == "tesla_gun_powerup_zm")
				continue;

			//no picking up qed random weapon powerup if player the hasn't triggered it
			if(self.powerup_name == "random_weapon" && !IsDefined(self.gg_powerup) && !is_true(self.weapon_powerup_grabbed))
				continue;

			//no picking up meat if the player already has meat powerup
			if(self.powerup_name == "meat" && is_true(players[i].has_meat))
			{
				continue;
			}

			// QED random weapon only needs to be triggered, does not need player within distance
			if ( DistanceSquared( players[i].origin, self.origin ) < range_squared || ( self.powerup_name == "random_weapon" && !IsDefined(self.gg_powerup) ) )
			{
				if( IsDefined( level.zombie_powerup_grab_func ) )
				{
					level thread [[level.zombie_powerup_grab_func]]();
				}
				else
				{
					switch (self.powerup_name)
					{
					case "nuke":
						level thread nuke_powerup( self, players[i] );

						//chrisp - adding powerup VO sounds
						players[i] thread powerup_vo("nuke");
						zombies = getaiarray("axis");
						players[i].zombie_nuked = get_array_of_closest( self.origin, zombies );
						players[i] notify("nuke_triggered");
						break;

					case "full_ammo":
						level thread full_ammo_powerup( self, players[i] );
						players[i] thread powerup_vo("full_ammo");
						break;

					case "double_points":
						level thread double_points_powerup( self, players[i] );
						players[i] thread powerup_vo("double_points");
						break;

					case "insta_kill":
						level thread insta_kill_powerup( self, players[i] );
						players[i] thread powerup_vo("insta_kill");
						break;

					case "carpenter":
						if(isDefined(level.use_new_carpenter_func))
						{
							level thread [[level.use_new_carpenter_func]](self.origin);
						}
						else
						{
							level thread start_carpenter( self.origin );
						}
						players[i] thread powerup_vo("carpenter");
						break;

					case "fire_sale":
						level thread start_fire_sale( self );
						players[i] thread powerup_vo("firesale");
						break;

					case "bonfire_sale":
						level thread start_bonfire_sale( self );
						players[i] thread powerup_vo("firesale");
						break;

					case "minigun":
						level thread minigun_weapon_powerup( players[i] );
						players[i] thread powerup_vo( "minigun" );
						break;

					case "free_perk":
						level thread free_perk_powerup( self, players[i] );
						//players[i] thread powerup_vo( "insta_kill" );
						break;

					case "all_revive":
						level thread start_revive_all( self );
						players[i] thread powerup_vo("revive");
						break;

					case "tesla":
						level thread tesla_weapon_powerup( players[i], self );
						players[i] thread powerup_vo( "tesla" ); // TODO: Audio should uncomment this once the sounds have been set up
						break;

					//done in its own function because it has a use trigger
					case "random_weapon":
						if ( IsDefined(self.gg_powerup) && !level random_weapon_powerup( self, players[i] ) )
						{
							continue;
						}
						//players[i] thread powerup_vo( "random_weapon" ); // TODO: Audio should uncomment this once the sounds have been set up
						break;
						
					case "bonus_points_player":
						level thread bonus_points_player_powerup( self, players[i] );
						players[i] thread powerup_vo( "bonus_points_solo" ); // TODO: Audio should uncomment this once the sounds have been set up
						break;

					case "bonus_points_team":
						level thread bonus_points_team_powerup( self, players[i] );
						players[i] thread powerup_vo( "bonus_points_team" ); // TODO: Audio should uncomment this once the sounds have been set up
						break;

					case "lose_points_team":
						level thread lose_points_team_powerup( self, players[i] );
						break;

					case "empty_clip":
						level thread empty_clip_powerup( self, players[i] );
						break;

					case "meat":
						level thread meat_powerup( self, players[i] );
						break;

					case "upgrade_weapon":
						level thread upgrade_weapon_powerup( self, players[i] );
						break;

					default:
						// RAVEN BEGIN bhackbarth: callback for level specific powerups
						if ( IsDefined( level._zombiemode_powerup_grab ) )
						{
							level thread [[ level._zombiemode_powerup_grab ]]( self );
						}
						// RAVEN END
						else
						{
							println ("Unrecognized poweup.");
						}

						break;
					}
				}

				if ( self.solo )
				{
					playfx( level._effect["powerup_grabbed_solo"], self.origin );
					playfx( level._effect["powerup_grabbed_wave_solo"], self.origin );
				}
				else if ( self.caution )
				{
					//playfx( level._effect["powerup_grabbed_caution"], self.origin );
					//playfx( level._effect["powerup_grabbed_wave_caution"], self.origin );
					playfx( level._effect["powerup_grabbed_red"], self.origin );
					playfx( level._effect["powerup_grabbed_wave_red"], self.origin );
				}
				else
				{
					playfx( level._effect["powerup_grabbed"], self.origin );
					playfx( level._effect["powerup_grabbed_wave"], self.origin );
				}

				if ( is_true( self.stolen ) )
				{
					level notify( "monkey_see_monkey_dont_achieved" );
				}

				// RAVEN BEGIN bhackbarth: since there is a wait here, flag the powerup as being taken
				self.claimed = true;
				self.power_up_grab_player = players[i]; //Player who grabbed the power up
				// RAVEN END

				wait( 0.1 );

				playsoundatposition("zmb_powerup_grabbed", self.origin);
				self stoploopsound();

				//Preventing the line from playing AGAIN if fire sale becomes active before it runs out
				if( self.powerup_name != "fire_sale" && !IsDefined(self.gg_powerup) )
				{
				    level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"][self.powerup_name], players[i] );
				}

				if ( isdefined( self.worldgundw ) )
				{
					self.worldgundw delete();
				}
				self delete();
				self notify ("powerup_grabbed");
			}
		}
		wait 0.1;
	}
}

//PI ESM - revive all players in last stand on the map
start_revive_all( item )
{
	players = get_players();
	reviver = players[0];

	for ( i = 0; i < players.size; i++ )
	{
		if ( !players[i] maps\_laststand::player_is_in_laststand() )
		{
			reviver = players[i];
			break;
		}
	}

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] maps\_laststand::player_is_in_laststand() )
		{
			players[i] maps\_laststand::revive_force_revive( reviver );
			players[i] notify ( "zombified" );
		}
	}
}

start_fire_sale( item )
{
	level notify ("powerup fire sale");
	level endon ("powerup fire sale");
	
	level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["fire_sale_short"] );

	players = get_players();
	if(level.zombie_vars["zombie_powerup_fire_sale_on"])
	{
		level.zombie_vars["zombie_powerup_fire_sale_time"] += 30;
		for(i = 0; i < players.size; i++)
		{
			players[i].zombie_vars["zombie_powerup_fire_sale_time"] += 30;
		}
	}
	else
	{
		level notify("fire_sale_on");
		level.zombie_vars["zombie_powerup_fire_sale_time"] = 30;
		for(i = 0; i < players.size; i++)
		{
			players[i].zombie_vars["zombie_powerup_fire_sale_time"] = 30;
		}
	}
    
	level.zombie_vars["zombie_powerup_fire_sale_on"] = true;

	for(i = 0; i < players.size; i++)
	{
		players[i].zombie_vars["zombie_powerup_fire_sale_on"] = true;
	}
	level thread toggle_fire_sale_on();

	while ( level.zombie_vars["zombie_powerup_fire_sale_time"] > 0)
	{
		wait(0.1);
		level.zombie_vars["zombie_powerup_fire_sale_time"] -= 0.1;
		players = get_players();
		for(i = 0; i < players.size; i++)
		{
			players[i].zombie_vars["zombie_powerup_fire_sale_time"] -= 0.1;
		}
	}

	level.zombie_vars["zombie_powerup_fire_sale_on"] = false;

	for(i = 0; i < players.size; i++)
	{
		players[i].zombie_vars["zombie_powerup_fire_sale_on"] = false;
	}
	level notify ( "fire_sale_off" );
}

start_bonfire_sale( item )
{
	level notify ("powerup bonfire sale");
	level endon ("powerup bonfire sale");
	
	temp_ent = spawn("script_origin", (0,0,0));
	temp_ent playloopsound ("zmb_double_point_loop");
	level thread delete_on_bonfire_sale(temp_ent);

	players = get_players();
	if(level.zombie_vars["zombie_powerup_bonfire_sale_on"])
	{
		level.zombie_vars["zombie_powerup_bonfire_sale_time"] += 30;
		for(i = 0; i < players.size; i++)
		{
			players[i].zombie_vars["zombie_powerup_bonfire_sale_time"] += 30;
		}
	}
	else
	{
		level.zombie_vars["zombie_powerup_bonfire_sale_time"] = 30;
		for(i = 0; i < players.size; i++)
		{
			players[i].zombie_vars["zombie_powerup_bonfire_sale_time"] = 30;
		}
	}

	level.zombie_vars["zombie_powerup_bonfire_sale_on"] = true;
	for(i = 0; i < players.size; i++)
	{
		players[i].zombie_vars["zombie_powerup_bonfire_sale_on"] = true;
	}
	level thread toggle_bonfire_sale_on();

	while ( level.zombie_vars["zombie_powerup_bonfire_sale_time"] > 0)
	{
		wait(0.1);
		level.zombie_vars["zombie_powerup_bonfire_sale_time"] -= 0.1;
		players = get_players();
		for(i = 0; i < players.size; i++)
		{
			players[i].zombie_vars["zombie_powerup_bonfire_sale_time"] -= 0.1;
		}
	}

	level.zombie_vars["zombie_powerup_bonfire_sale_on"] = false;
	for(i = 0; i < players.size; i++)
	{
		players[i].zombie_vars["zombie_powerup_bonfire_sale_on"] = false;
	}
	level notify ( "bonfire_sale_off" );
	
	for (i = 0; i < players.size; i++)
	{
		players[i] playsound("zmb_points_loop_off");
	}
	
	if(IsDefined(temp_ent))
		temp_ent Delete();
}

delete_on_bonfire_sale(temp_ent)
{
	level endon("bonfire_sale_off");

	self waittill("powerup bonfire sale");

	if(IsDefined(temp_ent))
		temp_ent Delete();
}


start_carpenter( origin )
{

	//level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["carpenter"] );
	window_boards = getstructarray( "exterior_goal", "targetname" );
	total = level.exterior_goals.size;

	//COLLIN
	carp_ent = spawn("script_origin", (0,0,0));
	carp_ent playloopsound( "evt_carpenter" );

	while(true)
	{
		windows = get_closest_window_repair(window_boards, origin);
		if( !IsDefined( windows ) )
		{
			carp_ent stoploopsound( 1 );
			carp_ent playsound( "evt_carpenter_end", "sound_done" );
			carp_ent waittill( "sound_done" );
			break;
		}

		else
			window_boards = array_remove(window_boards, windows);


		while(1)
		{
			if( all_chunks_intact( windows.barrier_chunks ) )
			{
				break;
			}

			chunk = get_random_destroyed_chunk( windows.barrier_chunks );

			if( !IsDefined( chunk ) )
				break;

			windows thread maps\_zombiemode_blockers::replace_chunk( chunk, undefined, true );
			windows.clip enable_trigger();
			windows.clip DisconnectPaths();
			wait_network_frame();
			wait(0.05);
		}

		wait_network_frame();
	}

	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		players[i] maps\_zombiemode_score::player_add_points( "carpenter_powerup", 200 );
	}

	carp_ent delete();

}



get_closest_window_repair( windows, origin )
{
	current_window = undefined;
	shortest_distance = undefined;
	for( i = 0; i < windows.size; i++ )
	{
		if( all_chunks_intact(windows[i].barrier_chunks ) )
			continue;

		if( !IsDefined( current_window ) )
		{
			current_window = windows[i];
			shortest_distance = DistanceSquared( current_window.origin, origin );

		}
		else
		{
			if( DistanceSquared(windows[i].origin, origin) < shortest_distance )
			{

				current_window = windows[i];
				shortest_distance =  DistanceSquared( windows[i].origin, origin );
			}

		}

	}

	return current_window;


}

//SELF = Player
powerup_vo( type )
{
	self endon("death");
	self endon("disconnect");

	wait(randomfloatrange(4.5,5.5));

    if( type == "tesla" )
    {
        self maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", type );
    }
    else
    {
	    self maps\_zombiemode_audio::create_and_play_dialog( "powerup", type );
	}
}

powerup_wobble()
{
	self endon( "powerup_grabbed" );
	self endon( "powerup_timedout" );
	self endon( "powerup_end" );

	self thread powerup_add_to_array();

	if ( isdefined( self ) )
	{
		if( isDefined(level.powerup_fx_func) )
		{
			self thread [[level.powerup_fx_func]]();
		}
		else if( self.solo )
		{
			playfxontag( level._effect["powerup_on_solo"], self, "tag_origin" );
		}
		else if( self.caution )
		{
			//playfxontag( level._effect["powerup_on_caution"], self, "tag_origin" );
			PlayFXOnTag( level._effect[ "powerup_on_red" ], self, "tag_origin" );
		}
		else if( self.zombie_grabbable )
		{
			PlayFXOnTag( level._effect[ "powerup_on_red" ], self, "tag_origin" );
		}
		else
		{
			playfxontag( level._effect["powerup_on"], self, "tag_origin" );
		}
	}

	while ( isdefined( self ) )
	{
		waittime = randomfloatrange( 2.5, 5 );
		yaw = RandomInt( 360 );
		if( yaw > 300 )
		{
			yaw = 300;
		}
		else if( yaw < 60 )
		{
			yaw = 60;
		}
		yaw = self.angles[1] + yaw;
		new_angles = (-60 + randomint( 120 ), yaw, -45 + randomint( 90 ));
		self rotateto( new_angles, waittime, waittime * 0.5, waittime * 0.5 );
		if ( isdefined( self.worldgundw ) )
		{
			self.worldgundw rotateto( new_angles, waittime, waittime * 0.5, waittime * 0.5 );
		}
		wait randomfloat( waittime - 0.1 );
	}
}

powerup_add_to_array()
{
	level.powerups[level.powerups.size] = self;

	self waittill_any("powerup_grabbed", "powerup_timedout", "powerup_end", "death");

	level.powerups = array_remove(level.powerups, self);
}

powerup_timeout()
{
	self endon( "powerup_grabbed" );
	self endon( "death" );
	self endon( "powerup_end" );

	wait 15;

	for ( i = 0; i < 60; i++ )
	{
		// hide and show
		if ( i % 2 )
		{
			self hide();
			if ( isdefined( self.worldgundw ) )
			{
				self.worldgundw hide();
			}
		}
		else
		{
			self show();
			if ( isdefined( self.worldgundw ) )
			{
				self.worldgundw show();
			}
		}
		//add 3.5 seconds
		if ( i < 15 )
		{
			wait( 0.5 );
		}
		else if ( i < 35 )
		{
			wait( 0.25 );
		}
		else
		{
			wait( 0.1 );
		}
	}

	if(IsDefined(self.gg_powerup))
	{
		self.player.gg_wep_dropped = undefined;
	}

	self notify( "powerup_timedout" );

	if ( isdefined( self.worldgundw ) )
	{
		self.worldgundw delete();
	}
	self delete();
}

// kill them all!
nuke_powerup( drop_item, grabber )
{
	zombies = getaispeciesarray("axis");
	location = drop_item.origin;

	PlayFx( drop_item.fx, location );
	level thread nuke_flash();

	wait( 0.5 );

	zombies = get_array_of_closest( location, zombies );
	zombies_nuked = [];

	// Mark them for death
	for (i = 0; i < zombies.size; i++)
	{
		// already going to die
		if ( IsDefined(zombies[i].marked_for_death) && zombies[i].marked_for_death )
		{
			continue;
		}

		// check for custom damage func
		if ( IsDefined(zombies[i].nuke_damage_func) )
		{
 			zombies[i] thread [[ zombies[i].nuke_damage_func ]]();
			continue;
		}

		if( is_magic_bullet_shield_enabled( zombies[i] ) )
		{
			continue;
		}

		zombies[i].marked_for_death = true;
		zombies[i].nuked = true;
		zombies_nuked[ zombies_nuked.size ] = zombies[i];
	}

 	for (i = 0; i < zombies_nuked.size; i++)
  	{
 		if( !IsDefined( zombies_nuked[i] ) )
 		{
 			continue;
 		}

 		if( is_magic_bullet_shield_enabled( zombies_nuked[i] ) )
 		{
 			continue;
 		}

 		if( i < 5 && !( zombies_nuked[i].isdog ) )
 		{
 			zombies_nuked[i] thread animscripts\zombie_death::flame_death_fx();
 		}

 		if( !( zombies_nuked[i].isdog ) )
 		{
			if ( !is_true( zombies_nuked[i].no_gib ) )
			{
	 			zombies_nuked[i] maps\_zombiemode_spawner::zombie_head_gib();
	 		}
 			zombies_nuked[i] playsound ("evt_nuked");
 		}

 		zombies_nuked[i] dodamage( zombies_nuked[i].health + 666, zombies_nuked[i].origin, grabber );
 	}

	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam != grabber.vsteam)
		{
			continue;
		}

		players[i] maps\_zombiemode_score::player_add_points( "nuke_powerup", 400 );
	}

	if(level.gamemode != "survival")
	{
		level thread hurt_players_powerup( drop_item, grabber );
	}
}

nuke_flash()
{
	players = getplayers();
	for(i=0; i<players.size; i ++)
	{
		players[i] play_sound_2d("evt_nuke_flash");
	}
	level thread devil_dialog_delay();

	fadetowhite = newhudelem();

	fadetowhite.x = 0;
	fadetowhite.y = 0;
	fadetowhite.alpha = 0;

	fadetowhite.horzAlign = "fullscreen";
	fadetowhite.vertAlign = "fullscreen";
	fadetowhite.foreground = true;
	fadetowhite SetShader( "white", 640, 480 );

	// Fade into white
	fadetowhite FadeOverTime( 0.2 );
	fadetowhite.alpha = 0.8;

	wait 0.5;
	fadetowhite FadeOverTime( 1.0 );
	fadetowhite.alpha = 0;

	wait 1.1;
	fadetowhite destroy();
}

nuke_flash_player()
{
	fadetowhite = newclienthudelem(self);

	fadetowhite.x = 0;
	fadetowhite.y = 0;
	fadetowhite.alpha = 0;

	fadetowhite.horzAlign = "fullscreen";
	fadetowhite.vertAlign = "fullscreen";
	fadetowhite.foreground = true;
	fadetowhite SetShader( "white", 640, 480 );

	// Fade into white
	fadetowhite FadeOverTime( 0.2 );
	fadetowhite.alpha = 0.8;

	wait 0.5;
	fadetowhite FadeOverTime( 1.0 );
	fadetowhite.alpha = 0;

	wait 1.1;
	fadetowhite destroy();
}

double_points_powerup( drop_item, player )
{
	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam != player.vsteam)
		{
			continue;
		}

		players[i] thread double_points_powerup_player( drop_item );
	}

	if(level.gamemode != "survival")
	{
		level thread half_points_powerup( drop_item, player );
	}
}

// double the points
double_points_powerup_player( drop_item )
{
	self notify ("powerup points scaled");
	self endon ("powerup points scaled");
	self endon("disconnect");

	//	players = get_players();
	//	array_thread(level,::point_doubler_on_hud, drop_item);
	//self thread point_doubler_on_hud( drop_item );

	self thread powerup_shader_on_hud( drop_item, "zombie_powerup_point_doubler_on", "zombie_powerup_point_doubler_time", "zmb_points_loop_off", "zmb_double_point_loop" );

	self.zombie_vars["zombie_point_scalar"] = 2;

	wait self.zombie_vars["zombie_powerup_point_doubler_time"];

	self.zombie_vars["zombie_point_scalar"] = 1;
}

full_ammo_powerup( drop_item, player )
{
	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam != player.vsteam)
		{
			continue;
		}
		
		// skip players in last stand
		if ( players[i] maps\_laststand::player_is_in_laststand() )
		{
			return;
		}

		primary_weapons = players[i] GetWeaponsList();

		players[i] notify( "zmb_max_ammo" );
		players[i] notify( "zmb_lost_knife" );
		players[i] notify( "zmb_disable_claymore_prompt" );
		players[i] notify( "zmb_disable_spikemore_prompt" );
		players[i] notify( "zmb_disable_betty_prompt" );
		for( x = 0; x < primary_weapons.size; x++ )
		{
			// Fill the clip
			//players[i] SetWeaponAmmoClip( primary_weapons[x], WeaponClipSize( primary_weapons[x] ) );

			// weapon only uses clip ammo, so GiveMaxAmmo won't work
			if(WeaponMaxAmmo(primary_weapons[x]) == 0)
			{
				players[i] SetWeaponAmmoClip(primary_weapons[x], WeaponClipSize(primary_weapons[x]));
				continue;
			}

			players[i] maps\_zombiemode_weapons::give_max_ammo(primary_weapons[x]);

			// fix for grenade ammo
			if(is_lethal_grenade(primary_weapons[x]) || is_tactical_grenade(primary_weapons[x]))
			{
				ammo = 0;
				if(is_lethal_grenade(primary_weapons[x]))
				{
					ammo = 4;
				}
				else if(is_tactical_grenade(primary_weapons[x]))
				{
					ammo = 3;
				}

				/*if(players[i] HasPerk("specialty_stockpile"))
				{
					ammo += 1;
				}*/

				players[i] SetWeaponAmmoClip(primary_weapons[x], ammo);
			}
		}

		players[i] thread powerup_hint_on_hud(drop_item);
	}

	if(level.gamemode != "survival")
	{
		item = SpawnStruct();
		item.caution = true;
		item.hint = &"REIMAGINED_CLIP_UNLOAD";
		level thread empty_clip_powerup( item, player );
	}

	//array_thread (players, ::full_ammo_on_hud, drop_item);
	//level thread full_ammo_on_hud( drop_item );
}

insta_kill_powerup( drop_item, player )
{
	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam != player.vsteam)
		{
			continue;
		}

		players[i] thread insta_kill_powerup_player( drop_item );
	}

	if(level.gamemode != "survival")
	{
		level thread half_damage_powerup( drop_item, player );
	}
}

insta_kill_powerup_player( drop_item )
{
	self notify( "powerup instakill" );
	self endon( "powerup instakill" );
	self endon ("disconnect");

	//	array_thread (players, ::insta_kill_on_hud, drop_item);
	//self thread insta_kill_on_hud( drop_item );

	self thread powerup_shader_on_hud( drop_item, "zombie_powerup_insta_kill_on", "zombie_powerup_insta_kill_time", "zmb_insta_kill", "zmb_insta_kill_loop" );

	self.powerup_instakill = true;

	wait self.zombie_vars["zombie_powerup_insta_kill_time"];

	self.powerup_instakill = false;

	self notify("insta_kill_over");
}

check_for_instakill( player, mod, hit_location )
{
	if( level.mutators["mutator_noPowerups"] )
	{
		return;
	}
	if( IsDefined( player ) && IsAlive( player ) && (level.zombie_vars["zombie_insta_kill"] || is_true( player.personal_instakill )) )
	{
		if( is_magic_bullet_shield_enabled( self ) )
		{
			return;
		}

		if ( IsDefined( self.instakill_func ) )
		{
			self thread [[ self.instakill_func ]]();
			return;
		}

		if(player.use_weapon_type == "MOD_MELEE")
		{
			player.last_kill_method = "MOD_MELEE";
		}
		else
		{
			player.last_kill_method = "MOD_UNKNOWN";

		}

		modName = remove_mod_from_methodofdeath( mod );
		if( flag( "dog_round" ) )
		{
			self DoDamage( self.health * 10, self.origin, player, undefined, modName, hit_location );
			player notify("zombie_killed");
		}
		else
		{
			if ( !is_true( self.no_gib ) )
			{
				self maps\_zombiemode_spawner::zombie_head_gib();
			}
			self DoDamage( self.health * 10, self.origin, player, undefined, modName, hit_location );
			player notify("zombie_killed");

		}
	}
}

insta_kill_on_hud( drop_item )
{
	self endon ("disconnect");

	// check to see if this is on or not
	if ( self.zombie_vars["zombie_powerup_insta_kill_on"] )
	{
		// reset the time and keep going
		self.zombie_vars["zombie_powerup_insta_kill_time"] += 30;
		return;
	}
	else
	{
		self.zombie_vars["zombie_powerup_insta_kill_time"] = 30;
	}

	self.zombie_vars["zombie_powerup_insta_kill_on"] = true;

	// set up the hudelem
	//hudelem = maps\_hud_util::createFontString( "objective", 2 );
	//hudelem maps\_hud_util::setPoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] + level.zombie_vars["zombie_timer_offset_interval"]);
	//hudelem.sort = 0.5;
	//hudelem.alpha = 0;
	//hudelem fadeovertime(0.5);
	//hudelem.alpha = 1;
	//hudelem.label = drop_item.hint;

	// set time remaining for insta kill
	self thread time_remaning_on_insta_kill_powerup();

	// offset in case we get another powerup
	//level.zombie_timer_offset -= level.zombie_timer_offset_interval;
}

time_remaning_on_insta_kill_powerup()
{
	self endon ("disconnect");
	//self setvalue( level.zombie_vars["zombie_powerup_insta_kill_time"] );
	//level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["instakill"] );
	temp_enta = undefined;
	players = get_players();
	if(self == players[0])
	{
		temp_enta = spawn("script_origin", (0,0,0));
		temp_enta playloopsound("zmb_insta_kill_loop");
	}

	/*
	players = get_players();
	for (i = 0; i < players.size; i++)
	{
	players[i] playloopsound ("zmb_insta_kill_loop");
	}
	*/


	// time it down!
	while ( self.zombie_vars["zombie_powerup_insta_kill_time"] >= 0)
	{
		wait 0.1;
		self.zombie_vars["zombie_powerup_insta_kill_time"] -= 0.1;
	//	self setvalue( level.zombie_vars["zombie_powerup_insta_kill_time"] );
	}

	self playsound("zmb_insta_kill");

	if(IsDefined(temp_enta))
		temp_enta stoploopsound(2);
	// turn off the timer
	self.zombie_vars["zombie_powerup_insta_kill_on"] = false;

	// remove the offset to make room for new powerups, reset timer for next time
	self.zombie_vars["zombie_powerup_insta_kill_time"] = 30;
	//level.zombie_timer_offset += level.zombie_timer_offset_interval;
	//self destroy();
	if(IsDefined(temp_enta))
		temp_enta delete();
}

point_doubler_on_hud( drop_item )
{
	self endon ("disconnect");

	// check to see if this is on or not
	if ( self.zombie_vars["zombie_powerup_point_doubler_on"] )
	{
		// reset the time and keep going
		self.zombie_vars["zombie_powerup_point_doubler_time"] += 30;
		return;
	}
	else
	{
		self.zombie_vars["zombie_powerup_point_doubler_time"] = 30;
	}

	self.zombie_vars["zombie_powerup_point_doubler_on"] = true;
	//level.powerup_hud_array[0] = true;
	// set up the hudelem
	//hudelem = maps\_hud_util::createFontString( "objective", 2 );
	//hudelem maps\_hud_util::setPoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] );
	//hudelem.sort = 0.5;
	//hudelem.alpha = 0;
	//hudelem fadeovertime( 0.5 );
	//hudelem.alpha = 1;
	//hudelem.label = drop_item.hint;

	// set time remaining for point doubler
	self thread time_remaining_on_point_doubler_powerup();

	// offset in case we get another powerup
	//level.zombie_timer_offset -= level.zombie_timer_offset_interval;
}

time_remaining_on_point_doubler_powerup()
{
	//self setvalue( level.zombie_vars["zombie_powerup_point_doubler_time"] );
	temp_ent = undefined;
	players = get_players();
	if(self == players[0])
	{
		temp_ent = spawn("script_origin", (0,0,0));
		temp_ent playloopsound ("zmb_double_point_loop");
	}

	//level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["doublepoints"] );


	// time it down!
	while ( self.zombie_vars["zombie_powerup_point_doubler_time"] >= 0)
	{
		wait 0.1;
		self.zombie_vars["zombie_powerup_point_doubler_time"] = self.zombie_vars["zombie_powerup_point_doubler_time"] - 0.1;
		//self setvalue( level.zombie_vars["zombie_powerup_point_doubler_time"] );
	}

	// turn off the timer
	self.zombie_vars["zombie_powerup_point_doubler_on"] = false;

	self playsound("zmb_points_loop_off");
	if(IsDefined(temp_ent))
		temp_ent stoploopsound(2);


	// remove the offset to make room for new powerups, reset timer for next time
	self.zombie_vars["zombie_powerup_point_doubler_time"] = 30;
	//level.zombie_timer_offset += level.zombie_timer_offset_interval;
	//self destroy();
	if(IsDefined(temp_ent))
		temp_ent delete();
}
toggle_bonfire_sale_on()
{
	level endon ("powerup bonfire sale");

	if( !isdefined ( level.zombie_vars["zombie_powerup_bonfire_sale_on"] ) )
	{
		return;
	}

	if( level.zombie_vars["zombie_powerup_bonfire_sale_on"] )
	{
		if ( isdefined( level.bonfire_init_func ) )
		{
			level thread [[ level.bonfire_init_func ]]();
		}
		level waittill( "bonfire_sale_off" );
	}
}
toggle_fire_sale_on()
{
	level endon ("powerup fire sale");

	if( !isdefined ( level.zombie_vars["zombie_powerup_fire_sale_on"] ) )
	{
		return;
	}

	if( level.zombie_vars["zombie_powerup_fire_sale_on"] )
	{
		for( i = 0; i < level.chests.size; i++ )
		{
			show_firesale_box = level.chests[i] [[level._zombiemode_check_firesale_loc_valid_func]]();

			if(show_firesale_box)
			{
				level.chests[i].zombie_cost = 10;
				level.chests[i] SetHintString(&"REIMAGINED_MYSTERY_BOX", level.chests[i].zombie_cost);

				if( level.chest_index != i )
				{
					level.chests[i].was_temp = true;
					level.chests[i] thread maps\_zombiemode_weapons::treasure_chest_fly_away(false, true);
					//level.chests[i] thread maps\_zombiemode_weapons::hide_rubble();
					//level.chests[i] thread maps\_zombiemode_weapons::show_chest();
					//wait_network_frame();
				}
			}
		}

		level waittill( "fire_sale_off" );

		for( i = 0; i < level.chests.size; i++ )
		{
			show_firesale_box = level.chests[i] [[level._zombiemode_check_firesale_loc_valid_func]]();

			if(show_firesale_box)
			{
				if( level.chest_index != i && IsDefined(level.chests[i].was_temp))
				{
					level.chests[i].was_temp = undefined;
					level thread remove_temp_chest( i );
				}

				if(IsDefined(level.chests[i].grab_weapon_hint) && (level.chests[i].grab_weapon_hint == true))
				{
					level.chests[i] thread fire_sale_weapon_wait();
				}
				else
				{
					level.chests[i].zombie_cost = level.chests[i].old_cost;
					//level.chests[i] set_hint_string( level.chests[i] , "default_treasure_chest_" + level.chests[i].zombie_cost );
					level.chests[i] SetHintString(&"REIMAGINED_MYSTERY_BOX", level.chests[i].zombie_cost);
				}
			}
		}

	}

}
//-------------------------------------------------------------------------------
//	DCS: Adding check if box is open to grab weapon when fire sale ends.
//-------------------------------------------------------------------------------
fire_sale_weapon_wait()
{
	self.zombie_cost = self.old_cost;
	while( isdefined( self.chest_user ) )
	{
		wait_network_frame();
	}
	//self set_hint_string( self , "default_treasure_chest_" + self.zombie_cost );
	self SetHintString(&"REIMAGINED_MYSTERY_BOX", self.zombie_cost);
}

//
//	Bring the chests back to normal.
remove_temp_chest( chest_index )
{
	while( isdefined( level.chests[chest_index].chest_user ) || (IsDefined(level.chests[chest_index]._box_open) && level.chests[chest_index]._box_open == true))
	{
		wait_network_frame();
	}

	if(level.zombie_vars["zombie_powerup_fire_sale_on"])
	{
		return;
	}

	level.chests[chest_index] thread maps\_zombiemode_weapons::treasure_chest_fly_away(true, true);
	//playfx(level._effect["poltergeist"], level.chests[chest_index].orig_origin);
	//level.chests[chest_index] playsound ( "zmb_box_poof_land" );
	//level.chests[chest_index] playsound( "zmb_couch_slam" );
	//level.chests[chest_index] maps\_zombiemode_weapons::hide_chest();
	//level.chests[chest_index] maps\_zombiemode_weapons::show_rubble();
}


devil_dialog_delay()
{
	wait(1.0);
	//level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["nuke"] );
}

full_ammo_on_hud( drop_item )
{
	self endon ("disconnect");

	// set up the hudelem
	hudelem = maps\_hud_util::createFontString( "objective", 2 );
	hudelem maps\_hud_util::setPoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	hudelem.sort = 0.5;
	hudelem.alpha = 0;
	hudelem fadeovertime(0.5);
	hudelem.alpha = 1;
	hudelem.label = drop_item.hint;

	// set time remaining for insta kill
	hudelem thread full_ammo_move_hud();

	// offset in case we get another powerup
	//level.zombie_timer_offset -= level.zombie_timer_offset_interval;
}

full_ammo_move_hud()
{

	players = get_players();
	//level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["maxammo"] );
	for (i = 0; i < players.size; i++)
	{
		players[i] playsound ("zmb_full_ammo");

	}
	wait 0.5;
	move_fade_time = 1.5;

	self FadeOverTime( move_fade_time );
	self MoveOverTime( move_fade_time );
	self.y = 270;
	self.alpha = 0;

	wait move_fade_time;

	self destroy();
}


//*****************************************************************************
// Here we have a selection of special case rare powerups that may get dropped
// by the random powerup generator
//*****************************************************************************
check_for_rare_drop_override( pos )
{
	if( IsDefined(flag("ape_round")) && flag("ape_round") )
	{
		return( 0 );
	}

	return( 0 );
}
setup_firesale_audio()
{
	wait(2);

	intercom = getentarray ("intercom", "targetname");
	while(1)
	{
		while( level.zombie_vars["zombie_powerup_fire_sale_on"] == false)
		{
			wait(0.2);
		}
		for(i=0;i<intercom.size;i++)
		{
			intercom[i] thread play_firesale_audio();
			//PlaySoundatposition( "zmb_vox_ann_firesale", intercom[i].origin );
		}
		while( level.zombie_vars["zombie_powerup_fire_sale_on"] == true)
		{
			wait (0.1);
		}
		level notify ("firesale_over");
	}
}
play_firesale_audio()
{
	if( is_true(level.player_4_vox_override ))
	{
		self playloopsound ("mus_fire_sale_rich");
	}
	else
	{
		self playloopsound ("mus_fire_sale");
	}

	level waittill ("firesale_over");
	self stoploopsound ();

}

setup_bonfiresale_audio()
{
	wait(2);

	intercom = getentarray ("intercom", "targetname");
	while(1)
	{
		while( level.zombie_vars["zombie_powerup_fire_sale_on"] == false)
		{
			wait(0.2);
		}
		for(i=0;i<intercom.size;i++)
		{
			intercom[i] thread play_bonfiresale_audio();
			//PlaySoundatposition( "zmb_vox_ann_firesale", intercom[i].origin );
		}
		while( level.zombie_vars["zombie_powerup_fire_sale_on"] == true)
		{
			wait (0.1);
		}
		level notify ("firesale_over");
	}
}
play_bonfiresale_audio()
{
	if( is_true( level.player_4_vox_override ))
	{
		self playloopsound ("mus_fire_sale_rich");
	}
	else
	{
		self playloopsound ("mus_fire_sale");
	}

	level waittill ("firesale_over");
	self stoploopsound ();

}

//******************************************************************************
// free perk powerup
//******************************************************************************
free_perk_powerup( item, player )
{
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if(level.gamemode != "survival" && players[i].vsteam != player.vsteam)
		{
			continue;
		}

		if ( !players[i] maps\_laststand::player_is_in_laststand() && !(players[i].sessionstate == "spectator") )
		{
			players[i] maps\_zombiemode_perks::give_random_perk();
		}
	}

	if(level.gamemode != "survival")
	{
		level thread lose_perk_powerup( item, player );
	}
}

//******************************************************************************
// random weapon powerup
//******************************************************************************
random_weapon_powerup_throttle()
{
	self.random_weapon_powerup_throttle = true;
	wait( 0.25 );
	self.random_weapon_powerup_throttle = false;
}


random_weapon_powerup( item, player )
{
	if ( player.sessionstate == "spectator" || player maps\_laststand::player_is_in_laststand() )
	{
		return false;
	}

	if(IsDefined(item.gg_powerup))
	{
		if(player != item.player)
		{
			return false;
		}
		else
		{
			player.gg_wep_num++;
			player.gg_kill_count = 0;
			player.gg_wep_dropped = undefined;

			if(player.gg_wep_num == 20)
			{
				if(player maps\_zombiemode_grief::get_number_of_valid_friendly_players() == 1)
				{
					level.vs_winning_team = player.vsteam;
					level notify("end_game");
				}
				else
				{
					player thread maps\_zombiemode::spawnSpectator();
				}

				return true;
			}

			player maps\_zombiemode_grief::update_gungame_weapon();
			return true;
		}
	}

	if ( is_true( player.random_weapon_powerup_throttle ) || player is_drinking() || !player UseButtonPressed() )
	{
		return false;
	}

	weapon_unupgraded_string = undefined;

	//store the unupgraded name
	if(IsDefined(item.unupgrade_weapon))
	{
		weapon_unupgraded_string = item.unupgrade_weapon;
	}

	current_weapon = player GetCurrentWeapon();
	current_weapon_type = WeaponInventoryType( current_weapon );
	if ( !is_tactical_grenade( item.weapon ) )
	{
		if ( "primary" != current_weapon_type && "altmode" != current_weapon_type )
		{
			return false;
		}

		if ( !isdefined( level.zombie_weapons[current_weapon] ) && !maps\_zombiemode_weapons::is_weapon_upgraded( current_weapon ) && "altmode" != current_weapon_type )
		{
			return false;
		}
	}

	player thread random_weapon_powerup_throttle();

	weapon_string = item.weapon;
	if ( player HasWeapon( "bowie_knife_zm" ) )
	{
		if ( weapon_string == "knife_ballistic_zm" )
		{
			weapon_string = "knife_ballistic_bowie_zm";
		}
		else if ( weapon_string == "knife_ballistic_upgraded_zm" )
		{
			weapon_string = "knife_ballistic_bowie_upgraded_zm";
		}
	}
	else if ( player HasWeapon( "sickle_knife_zm" ) )
	{
		if ( weapon_string == "knife_ballistic_zm" )
		{
			weapon_string = "knife_ballistic_sickle_zm";
		}
		else if ( weapon_string == "knife_ballistic_upgraded_zm" )
		{
			weapon_string = "knife_ballistic_sickle_upgraded_zm";
		}
	}

	player thread maps\_zombiemode_weapons::weapon_give( weapon_string, weapon_unupgraded_string );
	item.weapon_powerup_grabbed = true;
	return true;
}

//******************************************************************************
// bonus points powerups
//******************************************************************************
bonus_points_player_powerup( item, player )
{
	points = RandomIntRange( 1, 25 ) * 100;

	if ( !player maps\_laststand::player_is_in_laststand() && !(player.sessionstate == "spectator") )
	{
		player maps\_zombiemode_score::player_add_points( "bonus_points_powerup", points );
	}
}

bonus_points_team_powerup( item, player )
{
	points = RandomIntRange( 5, 25 ) * 100;

	if(item.powerup_name == "bonus_points_team")
	{
		level thread maps\_zombiemode_audio::do_announcer_playvox( level.devil_vox["powerup"]["bonus_points_team"], player );
	}

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if(level.gamemode != "survival" && players[i].vsteam != player.vsteam)
		{
			continue;
		}

		if ( !players[i] maps\_laststand::player_is_in_laststand() && !(players[i].sessionstate == "spectator") )
		{
			players[i] maps\_zombiemode_score::player_add_points( "bonus_points_powerup", points );
		}

		players[i] thread powerup_hint_on_hud(item);
	}

	if(level.gamemode != "survival")
	{
		item = SpawnStruct();
		item.caution = true;
		item.hint = &"REIMAGINED_LOSE_POINTS";
		level thread lose_points_team_powerup( item, player, points );
	}
}

lose_points_team_powerup( item, player, points )
{
	points = RandomIntRange( 5, 25 ) * 100;

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if(level.gamemode != "survival" && players[i].vsteam == player.vsteam)
		{
			continue;
		}

		if ( !players[i] maps\_laststand::player_is_in_laststand() && !(players[i].sessionstate == "spectator") )
		{
			if ( 0 > (players[i].score - points) )
			{
				players[i] maps\_zombiemode_score::minus_to_player_score( players[i].score );
			}
			else
			{
				players[i] maps\_zombiemode_score::minus_to_player_score( points );
			}

			players[i] thread powerup_hint_on_hud(item);
		}
	}
}

//******************************************************************************
// lose perk powerup
//******************************************************************************
lose_perk_powerup( item, player )
{
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if(level.gamemode != "survival" && players[i].vsteam == player.vsteam)
		{
			continue;
		}

		if ( !players[i] maps\_laststand::player_is_in_laststand() && !(players[i].sessionstate == "spectator") )
		{
			players[i] maps\_zombiemode_perks::lose_random_perk();
		}
	}
}

//******************************************************************************
// empty clip powerup
//******************************************************************************
empty_clip_powerup( item, player )
{
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if(level.gamemode != "survival" && players[i].vsteam == player.vsteam)
		{
			continue;
		}

		if ( !players[i] maps\_laststand::player_is_in_laststand() && players[i].sessionstate != "spectator" )
		{
			players[i] thread powerup_hint_on_hud(item);

			primaryWeapons = players[i] GetWeaponsListPrimaries();
			for ( j = 0; j < primaryWeapons.size; j++ )
			{
				players[i] SetWeaponAmmoClip( primaryWeapons[j], 0 );

				dual_wield_name = WeaponDualWieldWeaponName( primaryWeapons[j] );
				if( dual_wield_name != "none" )
				{
					players[i] SetWeaponAmmoClip( dual_wield_name, 0 );
				}

				alt_name = WeaponAltWeaponName( primaryWeapons[j] );
				if( alt_name != "none" )
				{
					players[i] SetWeaponAmmoClip( alt_name, 0 );
				}
			}
		}
	}
}

//******************************************************************************
// Minigun powerup
//******************************************************************************
minigun_weapon_powerup( ent_player, time )
{
	ent_player endon( "disconnect" );
	ent_player endon( "death" );
	ent_player endon( "player_downed" );

	if ( !IsDefined( time ) )
	{
		if( IsDefined(level.longer_minigun_reward) && level.longer_minigun_reward )
			time = 90;
		else
			time = 30;
	}
	/*if( !IsDefined(time) && IsDefined(level.longer_minigun_reward) && level.longer_minigun_reward )
	{
		time = 90;
	}*/

	// Just replenish the time if it's already active
	if ( ent_player.zombie_vars[ "zombie_powerup_minigun_on" ] &&
		 ("minigun_zm" == ent_player GetCurrentWeapon() || (IsDefined(ent_player.has_minigun) && ent_player.has_minigun) ))
	{
		ent_player.zombie_vars["zombie_powerup_minigun_time"] += time;
		return;
	}

	ent_player notify( "replace_weapon_powerup" );
	ent_player._show_solo_hud = true;

	// make sure weapons are replaced properly if the player is downed
	level._zombie_minigun_powerup_last_stand_func = ::minigun_watch_gunner_downed;
	ent_player.has_minigun = true;
	ent_player.has_powerup_weapon = true;

	ent_player increment_is_drinking();
	ent_player._zombie_gun_before_minigun = ent_player GetCurrentWeapon();

	// give player a minigun
	ent_player GiveWeapon( "minigun_zm" );
	ent_player SwitchToWeapon( "minigun_zm" );

	ent_player.zombie_vars[ "zombie_powerup_minigun_on" ] = true;

	level thread minigun_weapon_powerup_countdown( ent_player, "minigun_time_over", time );
	level thread minigun_weapon_powerup_replace( ent_player, "minigun_time_over" );
	level thread minigun_weapon_powerup_weapon_change( ent_player, "minigun_time_over" );
}

minigun_weapon_powerup_countdown( ent_player, str_gun_return_notify, time )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( "player_downed" );
	ent_player endon( str_gun_return_notify );
	ent_player endon( "replace_weapon_powerup" );

	//AUDIO: Starting powerup loop on ONLY this player
	setClientSysState( "levelNotify", "minis", ent_player );

	ent_player.zombie_vars["zombie_powerup_minigun_time"] = time;
	while ( ent_player.zombie_vars["zombie_powerup_minigun_time"] > 0)
	{
		wait(1.0);
		ent_player.zombie_vars["zombie_powerup_minigun_time"]--;
	}

	//AUDIO: Ending powerup loop on ONLY this player
	setClientSysState( "levelNotify", "minie", ent_player );

	level thread minigun_weapon_powerup_remove( ent_player, str_gun_return_notify );

}


minigun_weapon_powerup_replace( ent_player, str_gun_return_notify )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( "player_downed" );
	ent_player endon( str_gun_return_notify );

	ent_player waittill( "replace_weapon_powerup" );

	ent_player TakeWeapon( "minigun_zm" );

	ent_player.zombie_vars[ "zombie_powerup_minigun_on" ] = false;

	ent_player.has_minigun = false;

	ent_player decrement_is_drinking();
}


minigun_weapon_powerup_remove( ent_player, str_gun_return_notify, weapon_swap )
{
	ent_player endon( "death" );
	ent_player endon( "player_downed" );

	if(!IsDefined(weapon_swap))
	{
		weapon_swap = true;
	}

	ent_player.zombie_vars[ "zombie_powerup_minigun_on" ] = false;
	ent_player._show_solo_hud = false;

	if(weapon_swap)
	{
		primaryWeapons = ent_player GetWeaponsListPrimaries();
		if( IsDefined( ent_player._zombie_gun_before_minigun ) && ent_player HasWeapon(ent_player._zombie_gun_before_minigun) )
		{
			ent_player SwitchToWeapon( ent_player._zombie_gun_before_minigun );
		}
		else if( primaryWeapons.size > 0 )
		{
			ent_player SwitchToWeapon( primaryWeapons[0] );
		}
		else
		{
			ent_player SwitchToWeapon("combat_" + ent_player get_player_melee_weapon());
		}

		ent_player waittill("weapon_change");
	}

	ent_player TakeWeapon( "minigun_zm" );

	ent_player.has_minigun = false;
	ent_player.has_powerup_weapon = false;

	ent_player notify( str_gun_return_notify );

	ent_player decrement_is_drinking();
}

minigun_weapon_powerup_weapon_change( ent_player, str_gun_return_notify )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( "player_downed" );
	ent_player endon( str_gun_return_notify );
	ent_player endon( "replace_weapon_powerup" );

	ent_player EnableWeaponCycling();

	// if the player is currently switching a weapon when they grab the powerup, the weapon won't switch back correctly without waiting
	wait_network_frame();

	while(1)
	{
		// "weapon_switch_complete" is for if the player switches back to their normal weapon before the "weapon_change" notify of the powerup weapon
		ent_player waittill_any("weapon_change", "weapon_change_complete", "weapon_switch_complete");

		if(ent_player GetCurrentWeapon() == "minigun_zm" || is_true(ent_player.is_ziplining))
		{
			continue;
		}

		break;
	}

	level thread minigun_weapon_powerup_remove( ent_player, str_gun_return_notify, false );
}

minigun_weapon_powerup_off()
{
	self.zombie_vars["zombie_powerup_minigun_time"] = 0;
}

minigun_watch_gunner_downed()
{
	if ( !is_true( self.has_minigun ) )
	{
		return;
	}

	if(self HasWeapon("minigun_zm"))
	{
		self TakeWeapon( "minigun_zm" );
	}

	// self decrement_is_drinking();

	// this gives the player back their weapons
	self notify( "minigun_time_over" );
	self.zombie_vars[ "zombie_powerup_minigun_on" ] = false;
	self._show_solo_hud = false;

	// wait a frame to let last stand finish initializing so that
	// the wholethe system knows we went into last stand with a powerup weapon
	wait( 0.05 );
	self.has_minigun = false;
	self.has_powerup_weapon = false;
}



//******************************************************************************
// Tesla powerup
//		players[p].zombie_vars[ "zombie_powerup_tesla_on" ] = false; // tesla
//		players[p].zombie_vars[ "zombie_powerup_tesla_time" ] = 0;
//******************************************************************************
tesla_weapon_powerup( ent_player, powerup, time )
{
	ent_player endon( "disconnect" );
	ent_player endon( "death" );
	ent_player endon( "player_downed" );

	weapon = powerup.weapon;

	if ( !IsDefined( time ) )
	{
		time = 11; // no blink
	}

	// Just replenish the time if it's already active
	if ( ent_player.zombie_vars[ "zombie_powerup_tesla_on" ] && (weapon == ent_player GetCurrentWeapon() && (IsDefined(ent_player.has_tesla) && ent_player.has_tesla) ))
	{
		ent_player maps\_zombiemode_weapons::give_max_ammo(weapon);

		if ( ent_player.zombie_vars[ "zombie_powerup_tesla_time" ] < time )
		{
			ent_player.zombie_vars[ "zombie_powerup_tesla_time" ] = time;
		}
		return;
	}

	ent_player notify( "replace_weapon_powerup" );
	ent_player._show_solo_hud = true;

	wait_network_frame();

	// make sure weapons are replaced properly if the player is downed
	level._zombie_tesla_powerup_last_stand_func = ::tesla_watch_gunner_downed;
	ent_player.has_tesla = true;
	ent_player.has_powerup_weapon = true;

	ent_player increment_is_drinking();
	ent_player._zombie_gun_before_tesla = ent_player GetCurrentWeapon();

	// give player a tesla
	ent_player GiveWeapon( weapon, 0, ent_player maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( weapon ) );
	ent_player maps\_zombiemode_weapons::give_max_ammo(weapon);
	ent_player SwitchToWeapon( weapon );

	if(weapon == "tesla_gun_powerup_upgraded_zm" && ent_player HasWeapon("tesla_gun_powerup_zm"))
	{
		ent_player TakeWeapon("tesla_gun_powerup_zm");
	}

	ent_player.zombie_vars[ "zombie_powerup_tesla_on" ] = true;

	level thread tesla_weapon_powerup_countdown( ent_player, "tesla_time_over", weapon, time );
	level thread tesla_weapon_powerup_replace( ent_player, "tesla_time_over", weapon );
	level thread tesla_weapon_powerup_weapon_change( ent_player, "tesla_time_over", weapon );
}

tesla_weapon_powerup_countdown( ent_player, str_gun_return_notify, weapon, time )
{
	ent_player endon( "death" );
	ent_player endon( "player_downed" );
	ent_player endon( str_gun_return_notify );
	ent_player endon( "replace_weapon_powerup" );

	//AUDIO: Starting powerup loop on ONLY this player
	setClientSysState( "levelNotify", "minis", ent_player );

	ent_player.zombie_vars[ "zombie_powerup_tesla_time" ] = time;
	while ( true )
	{
		ent_player waittill_any( "weapon_fired", "reload", "zmb_max_ammo" );

		if ( !ent_player GetWeaponAmmoStock( weapon ) )
		{
			clip_count = ent_player GetWeaponAmmoClip( weapon );

			if ( !clip_count )
			{
				break; // powerup now ends
			}
			else if ( 1 == clip_count )
			{
				ent_player.zombie_vars[ "zombie_powerup_tesla_time" ] = 1; // blink fast
			}
			else if ( 6 >= clip_count )
			{
				ent_player.zombie_vars[ "zombie_powerup_tesla_time" ] = 6; // blink
			}
		}
		else
		{
			ent_player.zombie_vars[ "zombie_powerup_tesla_time" ] = 11; // no blink
		}
	}

	//AUDIO: Ending powerup loop on ONLY this player
	setClientSysState( "levelNotify", "minie", ent_player ); // TODO: need a new sound for the tesla

	level thread tesla_weapon_powerup_remove( ent_player, str_gun_return_notify, weapon );

}


tesla_weapon_powerup_replace( ent_player, str_gun_return_notify, weapon )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( "player_downed" );
	ent_player endon( str_gun_return_notify );

	ent_player waittill( "replace_weapon_powerup" );

	ent_player TakeWeapon( weapon );

	ent_player.zombie_vars[ "zombie_powerup_tesla_on" ] = false;

	ent_player.has_tesla = false;

	ent_player decrement_is_drinking();
}


tesla_weapon_powerup_remove( ent_player, str_gun_return_notify, weapon, weapon_swap )
{
	ent_player endon( "death" );
	ent_player endon( "player_downed" );

	if(!IsDefined(weapon_swap))
	{
		weapon_swap = true;
	}

	ent_player.zombie_vars[ "zombie_powerup_tesla_on" ] = false;
	ent_player._show_solo_hud = false;

	if(weapon_swap)
	{
		primaryWeapons = ent_player GetWeaponsListPrimaries();
		if( IsDefined( ent_player._zombie_gun_before_tesla ) && ent_player HasWeapon(ent_player._zombie_gun_before_tesla) )
		{
			ent_player SwitchToWeapon( ent_player._zombie_gun_before_tesla );
		}
		else if( primaryWeapons.size > 0 )
		{
			ent_player SwitchToWeapon( primaryWeapons[0] );
		}
		else
		{
			ent_player SwitchToWeapon("combat_" + ent_player get_player_melee_weapon());
		}

		ent_player waittill("weapon_change");
	}

	ent_player TakeWeapon( weapon );

	ent_player.has_tesla = false;
	ent_player.has_powerup_weapon = false;

	// this gives the player back their weapons
	ent_player notify( str_gun_return_notify );

	ent_player decrement_is_drinking();

}

tesla_weapon_powerup_weapon_change( ent_player, str_gun_return_notify, weapon )
{
	ent_player endon( "death" );
	ent_player endon( "disconnect" );
	ent_player endon( "player_downed" );
	ent_player endon( str_gun_return_notify );
	ent_player endon( "replace_weapon_powerup" );

	ent_player EnableWeaponCycling();

	// if the player is currently switching a weapon when they grab the powerup, the weapon won't switch back correctly without waiting
	wait_network_frame();

	while(1)
	{
		// "weapon_switch_complete" is for if the player switches back to their normal weapon before the "weapon_change" notify of the powerup weapon
		ent_player waittill_any("weapon_change", "weapon_change_complete", "weapon_switch_complete");

		if(ent_player GetCurrentWeapon() == weapon || is_true(ent_player.is_ziplining))
		{
			continue;
		}

		break;
	}

	level thread tesla_weapon_powerup_remove( ent_player, str_gun_return_notify, weapon, false );
}

tesla_weapon_powerup_off()
{
	self.zombie_vars[ "zombie_powerup_tesla_time" ] = 0;
}

tesla_watch_gunner_downed()
{
	if ( !is_true( self.has_tesla ) )
	{
		return;
	}

	primaryWeapons = self GetWeaponsListPrimaries();

	if(self HasWeapon("tesla_gun_powerup_zm"))
	{
		self TakeWeapon( "tesla_gun_powerup_zm" );
	}

	if(self HasWeapon("tesla_gun_powerup_upgraded_zm"))
	{
		self TakeWeapon( "tesla_gun_powerup_upgraded_zm" );
	}

	// self decrement_is_drinking();

	// this gives the player back their weapons
	self notify( "tesla_time_over" );
	self.zombie_vars[ "zombie_powerup_tesla_on" ] = false;
	self._show_solo_hud = false;

	// wait a frame to let last stand finish initializing so that
	// the wholethe system knows we went into last stand with a powerup weapon
	wait( 0.05 );
	self.has_tesla = false;
	self.has_powerup_weapon = false;
}


tesla_powerup_active()
{
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i].zombie_vars[ "zombie_powerup_tesla_on" ] )
		{
			return true;
		}
	}

	return false;
}


//******************************************************************************
//
// DEBUG
//
print_powerup_drop( powerup, type )
{
	/#
		if( !IsDefined( level.powerup_drop_time ) )
		{
			level.powerup_drop_time = 0;
			level.powerup_random_count = 0;
			level.powerup_score_count = 0;
		}

		time = ( GetTime() - level.powerup_drop_time ) * 0.001;
		level.powerup_drop_time = GetTime();

		if( type == "random" )
		{
			level.powerup_random_count++;
		}
		else
		{
			level.powerup_score_count++;
		}

		println( "========== POWER UP DROPPED ==========" );
		println( "DROPPED: " + powerup );
		println( "HOW IT DROPPED: " + type );
		println( "--------------------" );
		println( "Drop Time: " + time );
		println( "Random Powerup Count: " + level.powerup_random_count );
		println( "Random Powerup Count: " + level.powerup_score_count );
		println( "======================================" );
#/
}





start_carpenter_new( origin )
{

	window_boards = getstructarray( "exterior_goal", "targetname" );

	//COLLIN
	carp_ent = spawn("script_origin", (0,0,0));
	carp_ent playloopsound( "evt_carpenter" );

	boards_near_players = get_near_boards(window_boards);
	boards_far_from_players = get_far_boards(window_boards);

	//instantly repair all 'far' boards
	level repair_far_boards(boards_far_from_players);

	for(i=0;i<boards_near_players.size;i++)
	{
		window = boards_near_players[i];

		num_chunks_checked = 0;

		last_repaired_chunk = undefined;

		while(1)
		{
			if( all_chunks_intact( window.barrier_chunks ) )
			{
				break;
			}

			chunk = get_random_destroyed_chunk( window.barrier_chunks );

			if( !IsDefined( chunk ) )
				break;

			window thread maps\_zombiemode_blockers::replace_chunk( chunk, undefined, true );

			last_repaired_chunk = chunk;

			window.clip enable_trigger();
			window.clip DisconnectPaths();
			wait_network_frame();

			num_chunks_checked++;

			if(num_chunks_checked >= 20)
			{
				break;	// Avoid staying in this while loop forever....
			}
		}

		//wait for the last window board to be repaired


		while((IsDefined(last_repaired_chunk)) && (last_repaired_chunk.state == "mid_repair"))
		{
			wait(.05);
		}
	}

	carp_ent stoploopsound( 1 );
	carp_ent playsound( "evt_carpenter_end", "sound_done" );
	carp_ent waittill( "sound_done" );

	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		players[i] maps\_zombiemode_score::player_add_points( "carpenter_powerup", 200 );
	}

	carp_ent delete();
}


get_near_boards(windows)
{
	// get all boards that are farther than 500 units away from any player and put them into a list
	players = get_players();
	boards_near_players = [];

	for(j =0;j<windows.size;j++)
	{
		close = false;
		for(i=0;i<players.size;i++)
		{
			if( distancesquared(players[i].origin,windows[j].origin) <= level.board_repair_distance_squared  )
			{
				close = true;
			}
		}
		if(close)
		{
			boards_near_players[boards_near_players.size] = windows[j];
		}
	}
	return boards_near_players;
}

get_far_boards(windows)
{
	// get all boards that are farther than 500 units away from any player and put them into a list
	players = get_players();
	boards_far_from_players = [];

	for(j =0;j<windows.size;j++)
	{
		close = false;
		for(i=0;i<players.size;i++)
		{
			if( distancesquared(players[i].origin,windows[j].origin) >= level.board_repair_distance_squared  )
			{
				close = true;
			}
		}
		if(close)
		{
			boards_far_from_players[boards_far_from_players.size] = windows[j];
		}
	}
	return boards_far_from_players;
}

repair_far_boards(barriers)
{
	for(i=0;i<barriers.size;i++)
	{
		barrier = barriers[i];
		if( all_chunks_intact( barrier.barrier_chunks ) )
		{
			continue;
		}

		for(x=0;x<barrier.barrier_chunks.size;x++)
		{

			chunk = barrier.barrier_chunks[x];
			chunk dontinterpolate();
			barrier maps\_zombiemode_blockers::replace_chunk_instant( chunk);

		}

		barrier.clip enable_trigger();
		barrier.clip DisconnectPaths();

		wait_network_frame();
		wait_network_frame();
		wait_network_frame();
	}
}

remove_carpenter()
{
	level.zombie_powerup_array = array_remove (level.zombie_powerup_array, "carpenter");
}

powerup_weapon_trigger_cleanup(trigger)
{
	self waittill_any( "powerup_timedout", "powerup_grabbed", "hacked" );

	trigger delete();
}

quantum_bomb_random_powerup_validation(position)
{
	if(![[level.quantum_bomb_in_playable_area_validation_func]](position))
	{
		return false;
	}

	return true;

	/*range_squared = 180 * 180;
	for(i=0;i<level.powerups.size;i++)
	{
		if(DistanceSquared(level.powerups[i].origin, position) < range_squared)
		{
			return true;
		}
	}
	return false;*/
}

quantum_bomb_random_weapon_powerup_validation(position)
{
	if(![[level.quantum_bomb_in_playable_area_validation_func]](position))
	{
		return false;
	}

	return true;

	/*range_squared = 180 * 180;

	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" );
	for(i = 0; i < weapon_spawns.size; i++)
	{
		if(DistanceSquared(weapon_spawns[i].origin, position) < range_squared)
		{
			return true;
		}
	}

	return false;*/
}

powerup_shader_on_hud( item, powerup_on_var, powerup_time_var, sound, loop_sound, time )
{
	self endon ("disconnect");

	if(!IsDefined(time))
	{
		time = 30;
	}

	// check to see if this is on or not
	if ( self.zombie_vars[powerup_on_var] )
	{
		// reset the time and keep going
		self.zombie_vars[powerup_time_var] += time;
		return;
	}
	else
	{
		self.zombie_vars[powerup_on_var] = true;
		self.zombie_vars[powerup_time_var] = time;
	}

	temp_ent = undefined;
	if(IsDefined(loop_sound))
	{
		temp_ent = spawn("script_origin", (0,0,0));
		temp_ent playloopsound(loop_sound);
	}

	// time it down!
	while ( self.zombie_vars[powerup_time_var] >= 0)
	{
		wait 0.1;
		self.zombie_vars[powerup_time_var] = self.zombie_vars[powerup_time_var] - 0.1;
	}

	self.zombie_vars[powerup_on_var] = false;

	if(IsDefined(sound))
	{
		self PlaySoundToPlayer(sound, self);
	}

	if(IsDefined(temp_ent))
	{
		temp_ent stoploopsound(2);
		temp_ent delete();
	}
}

powerup_hint_on_hud( item )
{
	self endon ("disconnect");

	// set up the hudelem
	hudelem = maps\_hud_util::createFontString( "objective", 2, self );
	hudelem maps\_hud_util::setPoint( "TOP", undefined, 0, level.zombie_vars["zombie_timer_offset"] - (level.zombie_vars["zombie_timer_offset_interval"] * 2));
	hudelem.sort = 0.5;
	hudelem.alpha = 0;

	if(item.caution)
	{
		hudelem.color = (.6,0,0);
	}
	
	hudelem fadeovertime(0.5);
	hudelem.alpha = 1;
	hudelem.label = item.hint;

	// set time remaining for insta kill
	hudelem thread powerup_hint_move_hud();		

	// offset in case we get another powerup
	//level.zombie_timer_offset -= level.zombie_timer_offset_interval;
}

powerup_hint_move_hud()
{
	wait 0.5;
	move_fade_time = 1.5;

	self FadeOverTime( move_fade_time ); 
	self MoveOverTime( move_fade_time );
	self.y = 270;
	self.alpha = 0;

	wait move_fade_time;

	self destroy();
}

//add powerup into current cycle when it becomes available
add_powerup_later(powerup_name)
{
	if( IsDefined( level.zombie_include_powerups ) && !IsDefined( level.zombie_include_powerups[powerup_name] ) )
	{
		return;
	}

	if(level.gamemode != "survival")
	{
		return;
	}

	wait_network_frame();

	while(!is_valid_powerup(powerup_name))
	{
		wait_network_frame();
	}

	//if powerup is already in some index of the rest of the current array, then we're good
	for(i=level.zombie_powerup_index;i<level.zombie_powerup_array.size;i++)
	{
		if(level.zombie_powerup_array[i] == powerup_name)
		{
			return;
		}
	}

	//if not, then remove the original powerup from the array and add the powerup randomly into the rest of the current array
	level.zombie_powerup_array = array_remove_nokeys(level.zombie_powerup_array, powerup_name);
	level.zombie_powerup_index--;
	index = RandomIntRange(level.zombie_powerup_index, level.zombie_powerup_array.size);
	level.zombie_powerup_array = array_insert(level.zombie_powerup_array, powerup_name, index);
}

half_points_powerup( drop_item, player )
{
	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam == player.vsteam)
		{
			continue;
		}

		players[i] thread half_points_powerup_player( drop_item );
	}
}

half_points_powerup_player( drop_item )
{
	self notify ("grief powerup points scaled");
	self endon ("grief powerup points scaled");
	self endon ("disconnect");

	self thread powerup_shader_on_hud( drop_item, "zombie_powerup_half_points_on", "zombie_powerup_half_points_time", "zmb_insta_kill", "zmb_insta_kill_loop" );

	self.zombie_vars["zombie_point_scalar"] = .5;

	wait self.zombie_vars["zombie_powerup_half_points_time"];

	self.zombie_vars["zombie_point_scalar"] = 1;
}

half_damage_powerup( drop_item, player )
{
	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam == player.vsteam)
		{
			continue;
		}

		players[i] thread half_damage_powerup_player( drop_item );
	}
}

half_damage_powerup_player( drop_item )
{
	self notify( "powerup half damage" );
	self endon( "powerup half damage" );
	self endon ("disconnect");

	self thread powerup_shader_on_hud( drop_item, "zombie_powerup_half_damage_on", "zombie_powerup_half_damage_time", "zmb_insta_kill", "zmb_insta_kill_loop" );

	self.zombie_vars["zombie_damage_scalar"] = .5;

	wait self.zombie_vars["zombie_powerup_half_damage_time"];

	self.zombie_vars["zombie_damage_scalar"] = 1;
}

hurt_players_powerup( drop_item, player )
{
	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam == player.vsteam)
		{
			continue;
		}

		if(players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator")
		{
			continue;
		}

		players[i] notify("grief_damage", "none", "MOD_UNKNOWN", player);

		RadiusDamage(players[i].origin, 10, 80, 80, undefined, "MOD_UNKNOWN");
	}
}

slow_down_powerup( drop_item, player )
{
	players = get_players();
	for(i = 0; i < players.size; i++)
	{
		if(level.gamemode != "survival" && players[i].vsteam == player.vsteam)
		{
			continue;
		}

		players[i] thread slow_down_powerup_player( drop_item );
	}
}

slow_down_powerup_player( drop_item )
{
	self notify( "powerup half damage" );
	self endon( "powerup half damage" );
	self endon ("disconnect");

	self thread powerup_shader_on_hud( drop_item, "zombie_powerup_slow_down_on", "zombie_powerup_slow_down_time", "zmb_insta_kill", "zmb_insta_kill_loop" );

	while(self.zombie_vars["zombie_powerup_slow_down_on"])
	{
		if(!is_true(self.slowdown_wait) && self.move_speed > .7)
		{
			self.move_speed = .7;
			self SetMoveSpeedScale(.7);
		}
		wait .1;
	}
	self.move_speed = 1;
	self SetMoveSpeedScale(1);
}

meat_powerup( drop_item, player )
{
	player endon("disconnect");
	player endon("death");
	player endon("player_downed");
	player endon("meat_time_over");

	player notify("replace_weapon_powerup");

	level._zombie_meat_powerup_last_stand_func = ::meat_watch_gunner_downed;
	player.has_meat = true;
	player.has_powerup_weapon = true;

	player increment_is_drinking();
	player._zombie_gun_before_meat = player GetCurrentWeapon();

	player GiveWeapon("meat_zm");
	player GiveMaxAmmo("meat_zm");
	player SwitchToWeapon("meat_zm");

	level thread meat_powerup_replace(player, "meat_time_over");
	level thread meat_powerup_weapon_change(player);

	while(1)
	{
		player waittill("grenade_fire", grenade, weapon);

		if(weapon == "meat_zm")
		{
			grenade.angles = (0, grenade.angles[1], 0);

			grenade thread meat_powerup_create_meat_stink(player);

			grenade thread meat_powerup_create_meat_stink_player(player);

			if(is_true(player.has_meat))
			{
				wait(WeaponFireTime("meat_zm"));

				player meat_powerup_take_weapon();

				break;
			}
		}
	}
}

meat_powerup_replace(player, str_gun_return_notify)
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "player_downed" );
	player endon( str_gun_return_notify );

	player waittill( "replace_weapon_powerup" );

	player TakeWeapon( "meat_zm" );

	player.has_meat = false;

	player decrement_is_drinking();
}

meat_powerup_weapon_change(player)
{
	player endon("disconnect");
	player endon("meat_time_over");
	player endon("player_downed");

	player EnableWeaponCycling();

	// if the player is currently switching a weapon when they grab the powerup, the weapon won't switch back correctly without waiting
	wait_network_frame();

	while(1)
	{
		// "weapon_switch_complete" is for if the player switches back to their normal weapon before the "weapon_change" notify of the powerup weapon
		player waittill_any("weapon_change", "weapon_change_complete", "weapon_switch_complete");

		if(player GetCurrentWeapon() == "meat_zm" || is_true(player.is_ziplining))
		{
			continue;
		}

		break;
	}
	
	player meat_powerup_take_weapon(false);
}

meat_powerup_take_weapon(weapon_swap)
{
	if(!IsDefined(weapon_swap))
	{
		weapon_swap = true;
	}

	if(weapon_swap)
	{
		weps = self GetWeaponsListPrimaries();
		if(IsDefined(self._zombie_gun_before_meat) && self HasWeapon(self._zombie_gun_before_meat))
		{
			self SwitchToWeapon(self._zombie_gun_before_meat);
		}
		else if(weps.size > 0)
		{
			self SwitchToWeapon(weps[0]);
		}
		else
		{
			self SwitchToWeapon("combat_" + self get_player_melee_weapon());
		}
	}

	self TakeWeapon("meat_zm");

	self decrement_is_drinking();
	self.has_powerup_weapon = false;
	self.has_meat = false;
	self notify("meat_time_over");
}

meat_watch_gunner_downed()
{
	if(!is_true(self.has_meat))
	{
		return;
	}

	if(self HasWeapon("meat_zm"))
	{
		self TakeWeapon( "meat_zm" );
	}

	//self decrement_is_drinking();

	// this gives the player back their weapons
	self notify("meat_time_over");

	// wait a frame to let last stand finish initializing
	wait(0.05);
	self.has_meat = false;
	self.has_powerup_weapon = false;
}

meat_powerup_create_meat_stink_player(player)
{
	self endon("stationary");

	player_stuck = undefined;

	wait_network_frame();

	while(1)
	{
		players = get_players();
		for(i=0;i<players.size;i++)
		{
			if(is_player_valid(players[i]) && self IsTouching(players[i]))
			{
				player_stuck = players[i];
				break;
			}
		}

		if(IsDefined(player_stuck))
		{
			break;
		}

		wait_network_frame();
	}

	self notify("player_meat");
	self Delete();

	PlayFX( level._effect[ "meat_impact" ], self.origin );
	fx = Spawn("script_model", player_stuck.origin);
	fx.angles = player_stuck GetPlayerAngles();
	fx SetModel("tag_origin");
	fx LinkTo(player_stuck);
	PlayFXOnTag(level._effect["meat_stink"], fx, "tag_origin");
	fx PlaySound("zmb_meat_land");
	fx PlayLoopSound( "zmb_meat_flies" );

	player_stuck meat_powerup_activate_meat_on_player(15);

	if(IsDefined(fx))
	{
		fx Delete();
	}
}

meat_powerup_create_meat_stink(player)
{
	self endon("player_meat");

	self waittill( "stationary", endpos, normal, angles, attacker, prey, bone );

	model = Spawn("script_model", self.origin);
	model.angles = self.angles;
	model SetModel("tag_origin");
	model LinkTo(self);

	origin = self.origin;
	angles = self.angles;

	valid_poi = check_point_in_active_zone( origin );

	if(!valid_poi)
	{
		valid_poi = check_point_in_playable_area( origin );
	}

	PlayFX( level._effect[ "meat_impact" ], self.origin );
	PlayFXOnTag(level._effect["meat_stink"], model, "tag_origin");
	model PlaySound("zmb_meat_land");
	model PlayLoopSound( "zmb_meat_flies" );

	if(valid_poi)
	{
		attract_dist_diff = 45;
		num_attractors = 96;
		max_attract_dist = 1536;

		self create_zombie_point_of_interest(max_attract_dist, num_attractors, 0);

		level notify("attractor_positions_generated");
	}

	wait 15;

	if(valid_poi)
	{
		level notify("attractor_positions_generated");
	}

	if(IsDefined(model))
	{
		model Delete();
	}

	if(IsDefined(self))
	{
		self Delete();
	}
}

meat_powerup_activate_meat_on_player(time)
{
	self notify("meat_active");
	self endon("meat_active");
	self endon("disconnect");

	self.meat_stink_active = true;
	level notify("meat_powerup_active");
	level notify("attractor_positions_generated");

	self waittill_any_or_timeout(time, "player_downed", "round_restarted");

	self.meat_stink_active = undefined;
	level notify("attractor_positions_generated");
}

timeout_on_down()
{
	self endon( "powerup_grabbed" );
	self endon( "death" );
	self endon( "powerup_timedout" ); 

	self.player waittill("player_downed");

	self.player.gg_wep_dropped = undefined;

	self notify( "powerup_end" );

	self delete();
}

timeout_on_grabbed()
{
	self endon( "death" );
	self endon( "powerup_timedout" );
	self endon( "powerup_end" );

	self waittill("powerup_grabbed");

	self.player.gg_wep_dropped = undefined;

	self notify( "powerup_end" );

	self delete();
}

upgrade_weapon_powerup( drop_item, player )
{
	player notify( "powerup upgrade weapon" );
	player endon( "powerup upgrade weapon" );
	player endon ("disconnect");

	current_wep = player GetWeaponsListPrimaries();

	already_active = false;
	if(IsDefined(player.player_bought_pack))
	{
		already_active = true;
	}
	else if(maps\_zombiemode_weapons::is_weapon_upgraded(current_wep[0]) && !player.zombie_vars["zombie_powerup_upgrade_weapon_on"])
	{
		player.player_bought_pack = true;
		already_active = true;
	}
	else if(player.zombie_vars["zombie_powerup_upgrade_weapon_on"])
	{
		already_active = true;
	}

	player thread powerup_shader_on_hud( drop_item, "zombie_powerup_upgrade_weapon_on", "zombie_powerup_upgrade_weapon_time", "zmb_insta_kill", "zmb_insta_kill_loop" );

	if(!already_active)
	{
		player maps\_zombiemode_grief::update_gungame_weapon(false, true);
	}

	player waittill_any_or_timeout(player.zombie_vars["zombie_powerup_upgrade_weapon_time"], "player_downed", "spawned_spectator");

	if(player.zombie_vars["zombie_powerup_upgrade_weapon_on"])
	{
		player.zombie_vars["zombie_powerup_upgrade_weapon_on"] = false;
		player.zombie_vars["zombie_powerup_upgrade_weapon_time"] = 0;
	}

	if(player maps\_laststand::player_is_in_laststand() || player.sessionstate == "spectator" || IsDefined(player.player_bought_pack))
	{
		return;
	}

	player maps\_zombiemode_grief::update_gungame_weapon(false, true);
}