#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;
#include maps\zombie_pentagon_teleporter; 
 
//#include maps\_zombiemode_protips;

main()
{
	level thread maps\zombie_pentagon_ffotd::main_start();

	maps\zombie_pentagon_fx::main();
	maps\zombie_pentagon_amb::main();
	maps\zombie_pentagon_anim::main();

	// ww: this was getting big, made a preacache function
	level pentagon_precache();
	
	PrecacheShader( "zom_icon_trap_switch_handle" ); // ww: hud icon for battery
	
	level.dogs_enabled = false;	
	level.random_pandora_box_start = false;
	
	level thread maps\_callbacksetup::SetupCallbacks();

	level.quad_move_speed = 35;
	//level.quad_traverse_death_fx = ::quad_traverse_death_fx;
	level.quad_explode = true;
	
	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;

	// Special zombie types.
	level.custom_ai_type = [];
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_dogs::init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_quad::init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_thief::init );

	level.door_dialog_function = maps\_zombiemode::play_door_dialog;

	include_weapons();
	include_powerups();

	level.use_zombie_heroes = true;
	level.disable_protips = 1;

	level.delete_when_in_createfx = ::delete_in_createfx;

	// DO ACTUAL ZOMBIEMODE INIT
	maps\_zombiemode::main();
	
	// Init tv screens
	level maps\zombie_pentagon_magic_box::magic_box_init();

	// Turn off generic battlechatter - Steve G
	battlechatter_off("allies");
	battlechatter_off("axis");

	// Setup the levels Zombie Zone Volumes
	maps\_compass::setupMiniMap("menu_map_zombie_pentagon"); 
	level.zone_manager_init_func = ::pentagon_zone_init;
	init_zones[0] = "conference_level1";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	// DCS: check to setup random spawing per zone.
	level.random_spawners = true;

	// Init traps
	level maps\zombie_pentagon_traps::init_traps();
	level thread maps\_zombiemode_auto_turret::init();
	level thread maps\zombie_pentagon_elevators::init();
	level thread electric_switch();
	level thread enable_zone_elevators_init();
	level thread maps\zombie_pentagon_teleporter::pentagon_packapunch_init();
	level thread maps\zombie_pentagon_teleporter::pack_door_init();
	level thread maps\zombie_pentagon_teleporter::teleporter_power_cable();
	//level thread zombie_pathing_init();
	level thread vision_set_init();
	level thread laststand_bleedout_init();
	level thread lab_shutters_init();
	level thread pentagon_brush_lights_init();
	level thread zombie_warroom_barricade_fix();
	level thread barricade_glitch_fix();

	
	//bonfire_init
	level.bonfire_init_func = ::pentagon_bonfire_init;

	level.validate_enemy_path_length = ::pentagon_validate_enemy_path_length;

	init_sounds();
	init_pentagon_client_flags();

	level thread play_starting_vox();

	level thread maps\zombie_pentagon_ffotd::main_end();
}
//-------------------------------------------------------------------------------
// DCS 091510: init pentagon client flags.
//-------------------------------------------------------------------------------
init_pentagon_client_flags()
{
	level.ZOMBIE_PENTAGON_PLAYER_PORTALFX = 5;
	level.ZOMBIE_PENTAGON_PLAYER_PORTALFX_COOL = 6;
}
//-------------------------------------------------------------------------------

delete_in_createfx()
{
	if ( GetDvar( #"createfx" ) != "" )
	{
		exterior_goals = getstructarray( "exterior_goal", "targetname" );
		for( i = 0; i < exterior_goals.size; i++ )
		{
			if( !IsDefined( exterior_goals[i].target ) ) // If the exterior_goal entity has no targets defined then return
			{
				continue;
			}
			targets = GetEntArray( exterior_goals[i].target, "targetname" ); // Grab all the pieces that are targeted by the exterior_goal

			for( j = 0; j < targets.size; j++ ) // count total targets of exterior_goal
			{
				if( IsDefined( targets[j].script_parameters ) && targets[j].script_parameters == "repair_board" )
				{
					unbroken_section = GetEnt( targets[j].target,"targetname" );
					if ( IsDefined( unbroken_section ) )
					{
						unbroken_section self_delete();
					}	
				}
				
				targets[j] self_delete();	
			}
		}
		return;
	}
}

// *****************************************************************************
// Zone management
// *****************************************************************************
pentagon_zone_init()
{
	flag_init( "always_on" );
	flag_set( "always_on" );
	

	//Level 1
	add_adjacent_zone( "conference_level1", "hallway_level1", "conf1_hall1" );	
	add_adjacent_zone( "hallway3_level1", "hallway_level1", "conf1_hall1" );	

	// Only used between pack room and war room (special one way) 
	add_adjacent_zone( "conference_level2", "war_room_zone_south", "war_room_entry", true );
	add_adjacent_zone( "conference_level2", "war_room_zone_north", "war_room_special", true );

	
	// Level 2
	add_adjacent_zone( "war_room_zone_top", "war_room_zone_south", "war_room_stair" );	
	add_adjacent_zone( "war_room_zone_top", "war_room_zone_north", "war_room_stair" );
	add_adjacent_zone( "war_room_zone_south", "war_room_zone_north", "war_room_stair" );	
	add_adjacent_zone( "war_room_zone_south", "war_room_zone_north", "war_room_west" );	

	//special elevator spawns
	add_adjacent_zone( "war_room_zone_north", "war_room_zone_elevator", "war_room_elevator" );	
	
	//level 3
	add_adjacent_zone( "labs_elevator", "labs_hallway1", "labs_enabled" );	
	add_adjacent_zone( "labs_hallway1", "labs_hallway2", "labs_enabled" );	
	
	add_adjacent_zone( "labs_hallway2", "labs_zone1", "lab1_level3" );	
	add_adjacent_zone( "labs_hallway1", "labs_zone2", "lab2_level3" );
	add_adjacent_zone( "labs_hallway2", "labs_zone2", "lab2_level3" );	
	add_adjacent_zone( "labs_hallway1", "labs_zone3", "lab3_level3" );	
	
	// DCS: if random spawner set to true, reduce randomly to this number of active spawners.
	level.zones["conference_level1"].num_spawners = 4;
	level.zones["hallway_level1"].num_spawners = 4;
	//level.zones["hallway2_level1"].num_spawners = 2;	
}

//-------------------------------------------------------------------------------
// zone enable through elevators
//-------------------------------------------------------------------------------
enable_zone_elevators_init()
{
	elev_zone_trig = GetEnt( "elevator1_down_riders", "targetname" );
	elev_zone_trig thread maps\zombie_pentagon_teleporter::enable_zone_portals();

	elev_zone_trig2 = GetEnt( "elevator2_down_riders", "targetname" );
	elev_zone_trig2 thread maps\zombie_pentagon_teleporter::enable_zone_portals();	
}

//*****************************************************************************
// WEAPON FUNCTIONS
//
// Include the weapons that are only in your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
// Copy all include_weapon lines over to the level.csc file too - removing the weighting funcs...
//*****************************************************************************

include_weapons()
{
	include_weapon( "frag_grenade_zm", false, true );
	include_weapon( "claymore_zm", false, true );

	//	Weapons - Pistols
	include_weapon( "m1911_zm", false );						// colt
	include_weapon( "m1911_upgraded_zm", false );
	include_weapon( "python_zm" );						// 357
	include_weapon( "python_upgraded_zm", false );
  	include_weapon( "cz75_zm" );
  	include_weapon( "cz75_upgraded_zm", false );

	//	Weapons - Semi-Auto Rifles
	include_weapon( "m14_zm", false, true );							// gewehr43
	include_weapon( "m14_upgraded_zm", false );

	//	Weapons - Burst Rifles
	include_weapon( "m16_zm", false, true );						
	include_weapon( "m16_gl_upgraded_zm", false );
	include_weapon( "g11_lps_zm" );
	include_weapon( "g11_lps_upgraded_zm", false );
	include_weapon( "famas_zm" );
	include_weapon( "famas_upgraded_zm", false );

	//	Weapons - SMGs
	include_weapon( "ak74u_zm", false, true );						// thompson, mp40, bar
	include_weapon( "ak74u_upgraded_zm", false );
	include_weapon( "mp5k_zm", false, true );
	include_weapon( "mp5k_upgraded_zm", false );
	include_weapon( "mpl_zm", false, true );
	include_weapon( "mpl_upgraded_zm", false );
	include_weapon( "pm63_zm", false, true );
	include_weapon( "pm63_upgraded_zm", false );
	include_weapon( "spectre_zm" );
	include_weapon( "spectre_upgraded_zm", false );

	//	Weapons - Dual Wield
  	include_weapon( "cz75dw_zm" );
  	include_weapon( "cz75dw_upgraded_zm", false );

	//	Weapons - Shotguns
	include_weapon( "ithaca_zm", false, true );						// shotgun
	include_weapon( "ithaca_upgraded_zm", false );
	include_weapon( "rottweil72_zm", false, true );
	include_weapon( "rottweil72_upgraded_zm", false );
	include_weapon( "spas_zm" );						// 
	include_weapon( "spas_upgraded_zm", false );
	include_weapon( "hs10_zm" );
	include_weapon( "hs10_upgraded_zm", false );

	//	Weapons - Assault Rifles
	include_weapon( "aug_acog_zm" );
	include_weapon( "aug_acog_mk_upgraded_zm", false );
	include_weapon( "galil_zm" );
	include_weapon( "galil_upgraded_zm", false );
	include_weapon( "commando_zm" );
	include_weapon( "commando_upgraded_zm", false );
	include_weapon( "fnfal_zm" );
	include_weapon( "fnfal_upgraded_zm", false );

	//	Weapons - Sniper Rifles
	include_weapon( "dragunov_zm" );					// ptrs41
	include_weapon( "dragunov_upgraded_zm", false );
	include_weapon( "l96a1_zm" );
	include_weapon( "l96a1_upgraded_zm", false );

	//	Weapons - Machineguns
	include_weapon( "rpk_zm" );							// mg42, 30 cal, ppsh
	include_weapon( "rpk_upgraded_zm", false );
	include_weapon( "hk21_zm" );
	include_weapon( "hk21_upgraded_zm", false );

	//	Weapons - Misc
	include_weapon( "m72_law_zm" );
	include_weapon( "m72_law_upgraded_zm", false );
	include_weapon( "china_lake_zm" );
	include_weapon( "china_lake_upgraded_zm", false );

	//	Weapons - Special
	include_weapon( "zombie_cymbal_monkey" );
	include_weapon( "ray_gun_zm" );
	include_weapon( "ray_gun_upgraded_zm", false );
	include_weapon( "freezegun_zm" );
	include_weapon( "freezegun_upgraded_zm", false );
	include_weapon( "crossbow_explosive_zm" );
	include_weapon( "crossbow_explosive_upgraded_zm", false );

	include_weapon( "knife_ballistic_zm", true );
	include_weapon( "knife_ballistic_upgraded_zm", false );
	include_weapon( "knife_ballistic_bowie_zm", false );
	include_weapon( "knife_ballistic_bowie_upgraded_zm", false );
	level._uses_retrievable_ballisitic_knives = true;

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "m1911_zm", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "freezegun_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "crossbow_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "knife_ballistic_zm", 1 );

	precacheItem( "explosive_bolt_zm" );
	precacheItem( "explosive_bolt_upgraded_zm" );
	
	// get the bowie into the collector achievement list
	level.collector_achievement_weapons = array_add( level.collector_achievement_weapons, "bowie_knife_zm" );
}


//*****************************************************************************
// POWERUP FUNCTIONS
//*****************************************************************************

include_powerups()
{
	include_powerup( "nuke" );
	include_powerup( "insta_kill" );
	include_powerup( "double_points" );
	include_powerup( "full_ammo" );
	include_powerup( "carpenter" );
	include_powerup( "fire_sale" );
	include_powerup( "bonfire_sale" );
	
	// minigun
	PreCacheItem( "minigun_zm" );
	
	include_powerup( "minigun" );
}

//*****************************************************************************
// ELECTRIC SWITCH
// once this is used, it activates other objects in the map
// and makes them available to use
//*****************************************************************************
electric_switch()
{
	trig = getent("use_elec_switch","targetname");
	trig sethintstring(&"ZOMBIE_ELECTRIC_SWITCH");
	trig setcursorhint( "HINT_NOICON" );

	level thread wait_for_power();

	trig waittill("trigger",user);

	trig delete();	
	flag_set( "power_on" );
	Objective_State(8,"done");
}


//
//	Wait for the power_on flag to be set.  This is needed to work in conjunction with
//		the devgui cheat.
//
wait_for_power()
{
	master_switch = getent("elec_switch","targetname");	
	master_switch notsolid();

	flag_wait( "power_on" );

	exploder(3500);

	//light_exploders.
	stop_exploder(2000);
	exploder(2001);

	level thread regular_portal_fx_on();
	level thread maps\zombie_pentagon::change_pentagon_vision();

	master_switch rotateroll(-90,.3);
	master_switch playsound("zmb_switch_flip");

	// Set Perk Machine Notifys
	level notify("revive_on");
	level notify("juggernog_on");
	level notify("sleight_on");
	level notify("doubletap_on");
	level notify("Pack_A_Punch_on" );
	
	// DSL - putting these together into 1 single client notify - redispatching them all as level notifies on the client.
	
/*	clientnotify( "power_on" );	

	clientnotify("revive_on");
	clientnotify("middle_door_open");
	clientnotify("fast_reload_on");
	clientnotify("doubletap_on");
	clientnotify("jugger_on");	*/
	
	clientnotify("ZPO");	 // Zombie Power On.
	
	//get the teleporter ready
	maps\zombie_pentagon_teleporter::teleporter_init();		
	
	master_switch waittill("rotatedone");
	playfx(level._effect["switch_sparks"] ,getstruct("elec_switch_fx","targetname").origin);
	
	//Sound - Shawn J  - adding temp sound to looping sparks & turning on power sources
	master_switch playsound("zmb_turn_on");
	
	level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_poweron" );
}

//*****************************************************************************
//AUDIO
//*****************************************************************************

init_sounds()
{
	maps\_zombiemode_utility::add_sound( "wood_door_fall", "zmb_wooden_door_fall" );
	maps\_zombiemode_utility::add_sound( "window_grate", "zmb_window_grate_slide" );
	maps\_zombiemode_utility::add_sound( "lab_door", "zmb_lab_door_slide" );
	maps\_zombiemode_utility::add_sound( "lab_door_swing", "zmb_door_wood_open" );
}

//*****************************************************************************
// Quad death copied from theater
//*****************************************************************************

quad_traverse_death_fx()
{
	self endon("quad_end_traverse_anim");
	self waittill( "death" );

	playfx(level._effect["quad_grnd_dust_spwnr"], self.origin);
}
//-------------------------------------------------------------------------------
// DCS 082410: cleanup path zombies from floor to floor.
//-------------------------------------------------------------------------------
zombie_pathing_init()
{
	cleanup_trig = GetEntArray( "zombie_movement_cleanup", "targetname" );
	for ( i = 0; i < cleanup_trig.size; i++ )
	{
		cleanup_trig[i] thread zombie_pathing_cleanup();
	}
}	
zombie_pathing_cleanup()
{
	
	while(true)
	{
		self waittill("trigger", who);
		
		if(IsDefined(who.animname) && who.animname == "thief_zombie")
		{
			continue;
		}
		else if(who.team == "axis")
		{
			//IPrintLnBold("zombie triggered death!");
		
			level.zombie_total++;
			who DoDamage(who.health + 100, who.origin);
		}	
	}
}	
//-------------------------------------------------------------------------------
// DCS: Vision set init and setup
//-------------------------------------------------------------------------------
vision_set_init()
{
	level waittill( "start_of_round" );
	
	exploder(2000);
	
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] VisionSetNaked("zombie_pentagon", 0.5);
	}	
}

change_pentagon_vision()
{
	// don't change during thief round. thief script will handle change afterwards.
	if(flag("thief_round"))
	{
		return;
	}
	
	players = get_players();	
	for ( i = 0; i < players.size; i++ )
	{
		players[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( players[i] );
		setClientSysState( "levelNotify", "vis" + players[i].floor, players[i] );
		wait_network_frame();			
	}	
}	

//-------------------------------------------------------------------------------
// DCS 090310: wait for last stand, check floors for zombie movement.
//-------------------------------------------------------------------------------
laststand_bleedout_init()
{
	flag_wait( "all_players_connected" ); 
	players = get_players();
	if(players.size > 1)
	{
		for ( i = 0; i < players.size; i++ )
		{
			players[i] thread wait_for_laststand_notify();
			players[i] thread bleedout_listener();
		}
	}	
}	
	
wait_for_laststand_notify()
{
	self endon("disconnect");

	while(true)
	{
		num_on_floor = 0;		
		num_floor_laststand = 0;
		
		self waittill( "player_downed" );
		
		while(self maps\_laststand::player_is_in_laststand())
		{
			self.floor = maps\_zombiemode_ai_thief::thief_check_floor( self );
			current_floor = self.floor;		
	
			players = get_players();
			for ( i = 0; i < players.size; i++ )
			{
				players[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( players[i] );
				if(players[i].floor == current_floor)
				{
					num_on_floor++;
					if(players[i] maps\_laststand::player_is_in_laststand())
					{
						num_floor_laststand++;
					}	
				}
			}
			
			wait_network_frame();
			if(players.size > 1 && num_on_floor == num_floor_laststand)
			{
				self thread maps\zombie_pentagon_elevators::laststand_elev_zombies_away();
			}
			wait(5);
		}		
	}
}
//-------------------------------------------------------------------------------
// DCS 092510: Bleedout listener, to cleanup floors when a player bleeds out.
//-------------------------------------------------------------------------------
bleedout_listener()
{
	while(true)
	{	
		self waittill( "spawned_spectator" );
		self thread bleedout_respawn_listener();
		
		wait(2);

		level thread check_if_empty_floors();
		
		wait(1);
	}
}

bleedout_respawn_listener()
{
	self waittill("spawned_player");
	
	self.floor = maps\_zombiemode_ai_thief::thief_check_floor( self );
	setClientSysState( "levelNotify", "vis" + self.floor, self );
}	
//-------------------------------------------------------------------------------
// DCS 091310:	Bonfire powerup init
//-------------------------------------------------------------------------------		
pentagon_bonfire_init()
{
	// portals already available, and no one entered pack room yet.
	if(flag("defcon_active") && level.defcon_activated == false)
	{
		return;		
	}
	else if(flag("defcon_active") && level.defcon_activated == true) // if someone in room reset countdown
	{
		level.defcon_countdown_time = 30;
		level.defcon_level = 5;
		return;
	}		

	current_defcon_level = level.defcon_level;
	punch_switches = GetEntArray("punch_switch","targetname");
	signs = GetEntArray("defcon_sign", "targetname");
	pack_door_slam = GetEnt("slam_pack_door","targetname");

	flag_set("bonfire_reset");

	//----------------------
	//force reset.
	level.defcon_level = 1;
	level notify("pack_room_reset");
	
	wait(0.1);

	if(IsDefined(punch_switches))
	{
		for ( i = 0; i < punch_switches.size; i++ )
		{
			punch_switches[i] notify( "trigger" );
			wait( 0.5 );
		}
	}
	//----------------------

	if(level.zones["conference_level2"].is_occupied)
	{
		//level notify("defcon_reset");

		wait(1);
		level thread start_defcon_countdown();
	}

	level waittill( "bonfire_sale_off" );
	
	//someone entered pack room or is currently in the pack room.
	if(	level.defcon_activated == true || level.zones["conference_level2"].is_occupied)
	{
		return;
	}
	else // otherwise reset pack room and portals, times up!
	{
		flag_clear("defcon_active");
		
		level thread regular_portal_fx_on();

		level.defcon_level = 1;
		level notify("pack_room_reset");

		level thread defcon_sign_lights();
	}	
	flag_clear("bonfire_reset");
}

//-------------------------------------------------------------------------------
// player should be within a couple feet of enemy	
//-------------------------------------------------------------------------------
pentagon_validate_enemy_path_length( player )
{
	max_dist = 1296;

	d = DistanceSquared( self.origin, player.origin );
	if ( d <= max_dist )
	{
		return true;
	}

	return false;
}
	
//-------------------------------------------------------------------------------
// DCS 090710:	setup shutter to work independent of doors.	
//							close shutters for tech round.
//-------------------------------------------------------------------------------
lab_shutters_init()
{
	shutters = GetEntArray("lab_shutter","script_noteworthy");
	if(IsDefined(shutters))
	{
		for ( i = 0; i < shutters.size; i++ )
		{
			shutters[i] thread lab_shutters_think();
		}	
	}	
}	
lab_shutters_think()
{
	door_pos = self.origin;
	time = 1;	
	scale = 1;
			
	if(IsDefined(self.script_flag) && !flag(self.script_flag))
	{
		flag_wait(self.script_flag);
		if(flag("thief_round"))
		{
				while(flag("thief_round"))
				{
					wait(0.5);
				}	
		}
		
		if(isDefined(self.script_vector))
		{
			vector = vector_scale( self.script_vector, scale );
			thief_vector = vector_scale( self.script_vector, .2 );
			while(true)
			{
				self MoveTo( door_pos + vector, time, time * 0.25, time * 0.25 ); 
				self thread maps\_zombiemode_blockers::door_solid_thread();
			
				flag_wait("thief_round");
				//IPrintLnBold("start_thief_round");
				self MoveTo( door_pos + thief_vector, time, time * 0.25, time * 0.25 ); 
				self thread maps\_zombiemode_blockers::door_solid_thread(); 
	
				while(flag("thief_round"))
				{
					wait(0.5);
				}	
	
				//level waittill( "between_round_over" );
				//IPrintLnBold("end_thief_round");
			}
		}
	}		
}	

play_starting_vox()
{
    flag_wait( "all_players_connected" );
    level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_levelstart" );
}

// WW: script brush model lights for the office floor
pentagon_brush_lights_init()
{
	// sbrush lights
	sbrush_office_ceiling_lights_off = GetEntArray( "sbrushmodel_interior_office_lights", "targetname" );
	
	if( IsDefined( sbrush_office_ceiling_lights_off ) && sbrush_office_ceiling_lights_off.size > 0 )
	{
		array_thread( sbrush_office_ceiling_lights_off, ::pentagon_brush_lights );	
	}
}

// WW: switches the on version for the off version when power hits
pentagon_brush_lights()
{
	if( !IsDefined( self.target ) )
	{
		return;
	}
	
	self.off_version = GetEnt( self.target, "targetname" );
	
	self.off_version Hide();
	
	flag_wait( "power_on" );
	
	self Hide();
	self.off_version Show();
	
}

//******************************************************************************
// PRECACHE FUNCTION
//******************************************************************************
pentagon_precache()
{
	// models for the old school electric trap
	PreCacheModel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	
	// shell shock when walking through an active electric trap
	PreCacheShellShock( "electrocution" );
	
	// ww: temp viewmodel arms for pentagon until we get the right ones
	PreCacheModel( "viewmodel_usa_pow_arms" ); // TEMP
	// TODO: PUT THE REAL VIEWMODEL ARMS IN FOR PENTAGON
	// ww: these pieces are used for the death-con switches
	PreCacheModel( "zombie_trap_switch" );
	PreCacheModel( "zombie_trap_switch_light" );
	PreCacheModel( "zombie_trap_switch_light_on_green" );
	PreCacheModel( "zombie_trap_switch_light_on_red" );
	PreCacheModel( "zombie_trap_switch_handle" );
	
	// ww: therse pieces are used for the magic box televisions. the models are changed in csc
	PreCacheModel( "p_zom_monitor_screen_fsale1" );
	PreCacheModel( "p_zom_monitor_screen_fsale2" );
	PreCacheModel( "p_zom_monitor_screen_labs0" );
	PreCacheModel( "p_zom_monitor_screen_labs1" );
	PreCacheModel( "p_zom_monitor_screen_labs2" );
	PreCacheModel( "p_zom_monitor_screen_labs3" );
	PreCacheModel( "p_zom_monitor_screen_lobby0" );
	PreCacheModel( "p_zom_monitor_screen_lobby1" );
	PreCacheModel( "p_zom_monitor_screen_lobby2" );
	PreCacheModel( "p_zom_monitor_screen_logo" );
	PreCacheModel( "p_zom_monitor_screen_off" );
	PreCacheModel( "p_zom_monitor_screen_on" );
	PreCacheModel( "p_zom_monitor_screen_warroom0" );
	PreCacheModel( "p_zom_monitor_screen_warroom1" );
	
	// WW: light models for the "power_on" swap. actual swap is in .csc
	PreCacheModel( "p_pent_light_ceiling" );
	PreCacheModel( "p_pent_light_tinhat_off" );
	// DSM: spinning lights in the labs
	PreCacheModel( "p_rus_rb_lab_warning_light_01" );
	PreCacheModel( "p_rus_rb_lab_warning_light_01_off" );
	PreCacheModel( "p_rus_rb_lab_light_core_on" );
	PreCacheModel( "p_rus_rb_lab_light_core_off" );
	
	
	//defcon sign models
	PreCacheModel( "p_zom_pent_defcon_sign_02" );
	PreCacheModel( "p_zom_pent_defcon_sign_03" );
	PreCacheModel( "p_zom_pent_defcon_sign_04" );
	PreCacheModel( "p_zom_pent_defcon_sign_05" );

}

zombie_warroom_barricade_fix()
{
	PreCacheModel("collision_wall_128x128x10");
	
	wait(1);
	
	collision = spawn("script_model", (-1219, 2039, -241));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();

	flag_wait("war_room_stair");
	collision Delete();
	
}

barricade_glitch_fix()
{
	PreCacheModel("collision_wall_64x64x10");
	PreCacheModel("collision_geo_64x64x64");
	
	// table glitch in start room
	collision = spawn("script_model", (-270, 2318, 184));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	
	// Other barricade near table, for good measure.
	collision = spawn("script_model", (-270, 2712, 184));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	
	// labs glitch near bowie
	collision = spawn("script_model", (-1215, 3426, -547));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	
	// pack room
	collision = spawn("script_model", (-2361, 1871, -347));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();
	
	// labs hall sw
	collision = spawn("script_model", (-1675, 3754, -547));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	
	// labs hall near elevator 
	collision = spawn("script_model", (-875, 3395, -579));
	collision setmodel("collision_wall_64x64x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	
	
	//War room railing DTP fix.
	collision = spawn("script_model", (-644, 1960, -448));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	
	collision = spawn("script_model", (-794, 1801, -449));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();
	
	collision = spawn("script_model", (-959, 1801, -449));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();
	
	// upper war room clip.
	collision = spawn("script_model", (-640, 1324, -211));
	collision setmodel("collision_geo_64x64x64");
	collision.angles = (0, 342.6, 0);
	collision Hide();
	
	collision = spawn("script_model", (-774, 1390, -189));
	collision setmodel("collision_geo_64x64x64");
	collision.angles = (0, 341.6, 0);
	collision Hide();	
	
	// pack room glitch, jump while hit.
	collision = spawn("script_model", (-1763, 2212, -449));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	
	// labs: 72337
	collision = spawn("script_model", (-381, 4988, -545));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();	
	
	//War room railing: 73288, 73979.
	collision = spawn("script_model", (-644, 1960, -448));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 90, 0);
	collision Hide();
	collision2 = spawn("script_model", (-653, 1987, -480));
	collision2 setmodel("collision_wall_128x128x10");
	collision2.angles = (0, 90, 0);
	collision2 Hide();
	collision3 = spawn("script_model", (-493, 2037, -448));
	collision3 setmodel("collision_wall_128x128x10");
	collision3.angles = (0, 0, 0);
	collision3 Hide();
	
	//Pack room: 72655.
	collision = spawn("script_model", (-2116, 2300, -347));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();	
	
	//labs (north west barricade door): 74595			
	collision = spawn("script_model", (-568, 5354, -648));
	collision setmodel("collision_wall_128x128x10");
	collision.angles = (0, 0, 0);
	collision Hide();	
	
	// Zombie head jumping glitch.
	collision2 = spawn("script_model", (-1100, 2243, -407));
	collision2 setmodel("collision_wall_64x64x10");
	collision2.angles = (0, 0, 0);
	collision2 Hide();
	
	collision3 = spawn("script_model", (-1063, 2271, -407));
	collision3 setmodel("collision_wall_64x64x10");
	collision3.angles = (0, 60.8, 0);
	collision3 Hide();
	
	collision4 = spawn("script_model", (-1019, 2300, -407));
	collision4 setmodel("collision_wall_64x64x10");
	collision4.angles = (0, 6.19994, 0);
	collision4 Hide();		
}		