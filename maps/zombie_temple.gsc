#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_utility_raven;
#include maps\_zombiemode_zone_manager;
#include maps\zombie_temple_elevators;
#include maps\zombie_temple_traps;
#include maps\zombie_temple_power;
#include maps\zombie_temple_spawning;
#include maps\zombie_temple_pack_a_punch;


main()
{
	SetDvar("ai_alternateSightLatency", 200);
	SetDvar("ai_useCheapSight", 1);
	level._use_choke_weapon_hints = 1;
	level._use_choke_blockers = 1;
	
	level thread maps\zombie_temple_ffotd::main_start();

	// set excludes on chests so we can have a random start
	level.random_pandora_box_start = true;

	level._zombie_custom_add_weapons = ::custom_add_weapons;

	level.riser_fx_on_client  = 1;
	level.use_clientside_rock_tearin_fx = 1;	
	level.use_clientside_board_fx = 1;
	init_client_flags();
	level.check_for_alternate_poi = ::check_if_should_avoid_poi;
	level._dontInitNotifyMessage = 1;
	
	precache_assets();
	
	init_sounds();
	maps\zombie_temple_fx::main();
	maps\zombie_temple_amb::main();
	maps\createart\zombie_temple_art::main();

	//MCG (042811): anims from black hole bomb for cave slide, init before zombiemode.
	level thread maps\zombie_temple_waterslide::cave_slide_anim_init();

	level thread maps\_callbacksetup::SetupCallbacks();
	
	include_weapons();
	include_powerups();
	
	level.zombiemode_using_marathon_perk = true;	
	level.zombiemode_using_divetonuke_perk = true;
	level.zombiemode_using_deadshot_perk = true;

	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;
	level.exit_level_func = ::temple_exit_level;
	level.zombiemode_cross_bow_fired = ::zombiemode_cross_bow_fired_temple;
	level.player_intersection_tracker_override = ::zombie_temple_player_intersection_tracker_override;
	level.deathcard_spawn_func = ::temple_death_screen_cleanup;
	level.check_valid_spawn_override = ::temple_check_valid_spawn;
	level.revive_solo_fx_func = ::temple_revive_solo_fx;

	// Special zombie types
	level.custom_ai_type = [];
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_napalm::napalm_zombie_init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\zombie_temple_ai_monkey::init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_sonic::sonic_zombie_init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_faller::faller_init );
	
	level.max_perks = 4;
	level.max_solo_lives = 3;

	level.register_offhand_weapons_for_level_defaults_override = ::temple_offhand_weapon_overrride;
	
	level.player_out_of_playable_area_monitor = true;
	level.player_out_of_playable_area_monitor_callback = ::zombie_temple_player_out_of_playable_area_monitor_callback;

	// leave spikemore init local here, so as to not include it in all the other maps
	maps\_zombiemode_spikemore::init();

	
	//Init random perk machines (must be called before _zombiemode::main()
	init_random_perk_machines();
	
	level.zombiemode_sidequest_init = ::temple_sidequest_of_awesome;

	maps\_zombiemode::main();
	
	level thread maps\_zombiemode::register_sidequest( "COTD", "ZOMBIE_COAST_EGG_SOLO", 43, "ZOMBIE_COAST_EGG_COOP", 44 );
	level thread maps\_zombiemode::register_sidequest( "EOA", undefined, undefined, "ZOMBIE_TEMPLE_SIDEQUEST", undefined );
	
	level thread init_electric_switch();
	
	// including sticky grenade
	maps\_sticky_grenade::init();
	
	// Setup the magic box maps
	thread maps\zombie_temple_magic_box::magic_box_init();
	
	//Shrink Ray Init
	level.shrink_ray_model_mapping_func = ::temple_shrink_ray_model_mapping_func;
	maps\_zombiemode_weap_shrink_ray::init();


	// custom spawning logic for napalm zombies
	level.ignore_spawner_func 		= ::temple_ignore_spawner;
	level.create_spawner_list_func	= ::temple_create_spawner_list;
	level.round_prestart_func       = ::temple_round_prestart;
	level.round_spawn_func 			= ::temple_round_spawning;
	level.round_wait_func           = ::temple_round_wait;
	level.poi_positioning_func		= ::temple_poi_positioning_func;
	level.powerup_fx_func			= ::temple_powerup_fx_func;
	level.playerlaststand_func		= ::player_laststand_temple;
	
	//waterfall should just knock zombies down and not kill them
	level.override_thundergun_damage_func = maps\zombie_temple_traps::override_thundergun_damage_func;

	maps\zombie_temple_powerups::init();
	
	level.zone_manager_init_func 	= ::local_zone_init;
	init_zones[0] = "temple_start_zone";
	
	// don't enable these zones until you hit the elevator button
	//init_zones[1] = "waterfall_upper_zone";
	//init_zones[2] = "waterfall_lower_zone";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );
	
	level thread maps\zombie_temple_achievement::init();
	
 	level thread add_powerups_after_round_1();
	level thread maps\zombie_temple_elevators::init_elevator();
	level thread maps\zombie_temple_minecart::minecart_main();
	level thread maps\zombie_temple_waterslide::waterslide_main();
	level thread setup_water_physics();

	//exploder(20); // waterfall body w/o trap
	
	level thread start_sparks();
	// makes the box spawn randomly between the start box choices
	level.random_pandora_box_start = false;
	
	level thread init_temple_traps();
	level thread init_pack_a_punch();
	
	level thread double_door_fx();
	level thread init_rolling_doors();
	
	level thread init_random_paths();
	
	level thread maps\zombie_temple_triggers::main();
	
	level thread maps\zombie_temple_spawning::zombie_tracking_init();
		
	level thread maps\zombie_temple_debug::main();
	
	//OnPlayerConnect_Callback( ::temple_player_connect );
	
	level thread maps\zombie_temple_ffotd::main_end();
	
	level thread maps\zombie_temple_sq::start_temple_sidequest();

}

init_client_flags()
{
	level._CF_ACTOR_IS_NAPALM_ZOMBIE = 0;
	level._CF_ACTOR_DO_NOT_USE = 1; //Someone is native code is setting this flag :(
	level._CF_ACTOR_NAPALM_ZOMBIE_EXPLODE = 2;
	level._CF_ACTOR_IS_SONIC_ZOMBIE = 3;
	level._CF_ACTOR_NAPALM_ZOMBIE_WET = 4;
	level._CF_ACTOR_CLIENT_FLAG_SPIKEMORE = 5;
	level._CF_ACTOR_RAGDOLL_IMPACT_GIB = 6;
	
	level._CF_PLAYER_GEYSER_FAKE_PLAYER_SETUP_PRONE = 0;
	level._CF_PLAYER_GEYSER_FAKE_PLAYER_SETUP_STAND = 1;
	level._CF_PLAYER_MAZE_FLOOR_RUMBLE = 3;
	level.CF_PLAYER_UNDERWATER = 15; //TODO: Move to zombiemode_load
	
	level._CF_SCRIPTMOVER_CLIENT_FLAG_SPIKES = 3;
	level._CF_SCRIPTMOVER_CLIENT_FLAG_MAZE_WALL = 4;
	level._CF_SCRIPTMOVER_CLIENT_FLAG_SPIKEMORE = 5;
	
	level._CF_SCRIPTMOVER_CLIENT_FLAG_WEAKSAUCE_START = 6;
	level._CF_SCRIPTMOVER_CLIENT_FLAG_HOTSAUCE_START = 7;
	level._CF_SCRIPTMOVER_CLIENT_FLAG_SAUCE_END = 8;
	level._CF_SCRIPTMOVER_CLIENT_FLAG_WATER_TRAIL = 9;
	
}

//temple_player_connect()
//{
//	self SetClientDvar( "player_disableWeaponsInWater", 0 );
//}

temple_sidequest_of_awesome()
{
	maps\zombie_temple_sq::init();
}

start_sparks()
{
	wait(2);
	exploder( 25 ); // Sparks0
	exploder( 26 ); // Sparks0
}

init_sounds()
{
	maps\_zombiemode_utility::add_sound( "door_stone_disc", "zmb_door_stone_disc" );
	maps\_zombiemode_utility::add_sound( "door_wood", "zmb_door_wood" );
	maps\_zombiemode_utility::add_sound( "door_spike", "zmb_door_spike" );
}

custom_add_weapons()
{
	maps\_zombiemode_weapons::add_zombie_weapon( "shrink_ray_zm",	"shrink_ray_upgraded_zm", 				&"ZOMBIE_TEMPLE_SHRINK_RAY", 			2000, 	"shrink",	"", 	undefined );
	maps\_zombiemode_weapons::add_zombie_weapon( "blow_gun_zm",		"blow_gun_upgraded_zm", 				&"ZOMBIE_TEMPLE_BLOW_GUN", 				2000, 	"darts", 		"", 	undefined );
	maps\_zombiemode_weapons::add_zombie_weapon( "spikemore_zm",	undefined,								&"ZOMBIE_TEMPLE_SPIKEMORE_PURCHASE",	1000,	"spikemore",		"",		undefined );
}

precache_assets()
{
	// RB: viewmodel arms for the level
	PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen
	
	maps\zombie_temple_minecart::precache_assets();
	maps\zombie_temple_waterslide::precache_assets();

	//Light models for trap switch
	PreCacheModel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");

	// light models for when power comes on
	PrecacheModel("p_ztem_power_hanging_light");
	PrecacheModel("p_lights_cagelight02_on");

	PreCacheShader("flamethrowerfx_color_distort_overlay_bloom");
}

//*****************************************************************************
// ZONE INIT
//*****************************************************************************

local_zone_init()
{
   //flag_init( "always_on" );
   //flag_set( "always_on" );


	// Temple_zone
	add_adjacent_zone( "temple_start_zone", "pressure_plate_zone", "start_to_pressure" );
	add_adjacent_zone( "temple_start_zone", "waterfall_upper1_zone", "start_to_waterfall_upper" );

	// Minecart to Caves
	add_adjacent_zone( "pressure_plate_zone","cave_tunnel_zone", "pressure_to_cave01");
	add_adjacent_zone( "caves1_zone","cave_tunnel_zone", "pressure_to_cave01");

	// Waterfall side
	add_adjacent_zone( "waterfall_lower_zone","waterfall_tunnel_zone", "waterfall_to_tunnel");
	add_adjacent_zone( "waterfall_tunnel_zone","waterfall_tunnel_a_zone", "waterfall_to_tunnel");
	add_adjacent_zone( "waterfall_tunnel_a_zone","waterfall_upper_zone", "waterfall_to_tunnel");

	add_adjacent_zone( "waterfall_upper1_zone", "waterfall_upper_zone", "start_to_waterfall_upper" );
	add_adjacent_zone( "waterfall_upper1_zone", "waterfall_upper_zone", "waterfall_to_tunnel" );

	
	//**************************
	// when the main door is opened the lower and upper waterfall will be connected.zombies will spawn 
	// even if the elevator isn't purchased 
	//add_adjacent_zone( "waterfall_upper_zone", "waterfall_lower_zone", "start_to_waterfall_upper" );
	//**************************

	// Caves
	
    add_adjacent_zone( "caves1_zone", "caves2_zone", "cave01_to_cave02" );
	

	add_adjacent_zone( "caves3_zone", "power_room_zone", "cave03_to_power" );

	add_adjacent_zone( "caves_water_zone", "power_room_zone", "cave_water_to_power" );
	add_adjacent_zone( "caves_water_zone", "waterfall_lower_zone", "cave_water_to_waterfall" );
	
	add_adjacent_zone( "caves2_zone", "caves3_zone", "cave01_to_cave02" );
	add_adjacent_zone( "caves2_zone", "caves3_zone", "cave02_to_cave_water" );
	add_adjacent_zone( "caves2_zone", "caves3_zone", "cave03_to_power" );
	

	// setup the script_struct spawn locations
	temple_init_zone_spawn_locations();
}



//*****************************************************************************
// WEAPON FUNCTIONS
//
// Include the weapons that are only in your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
//*****************************************************************************
include_weapons()
{
	include_weapon( "frag_grenade_zm", false );
	include_weapon( "sticky_grenade_zm", false, true );
	include_weapon( "spikemore_zm", false, true );

	//	Weapons - Pistols
	include_weapon( "m1911_zm", false );						// colt
	include_weapon( "m1911_upgraded_zm", false );
	include_weapon( "python_zm" );								// 357
	include_weapon( "python_upgraded_zm", false );
	include_weapon( "cz75_zm" );                                                                               
    include_weapon( "cz75_upgraded_zm", false );        

	//	Weapons - Semi-Auto Rifles
	include_weapon( "m14_zm", false, true );					// gewehr43
	include_weapon( "m14_upgraded_zm", false );

	//	Weapons - Burst Rifles
	include_weapon( "m16_zm", false, true );						
	include_weapon( "m16_gl_upgraded_zm", false );
	include_weapon( "g11_lps_zm" );
	include_weapon( "g11_lps_upgraded_zm", false );
	include_weapon( "famas_zm" );
	include_weapon( "famas_upgraded_zm", false );

	//	Weapons - SMGs
	include_weapon( "ak74u_zm", false, true );					// thompson, mp40, bar
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
	include_weapon( "ithaca_zm", false, true );					// shotgun
	include_weapon( "ithaca_upgraded_zm", false );
	include_weapon( "rottweil72_zm", false, true );
	include_weapon( "rottweil72_upgraded_zm", false );
	include_weapon( "spas_zm" );						
	include_weapon( "spas_upgraded_zm", false );
	include_weapon( "hs10_zm" );
	include_weapon( "hs10_upgraded_zm", false );

	//	Weapons - Assault Rifles
	include_weapon( "aug_acog_zm", true );
	include_weapon( "aug_acog_mk_upgraded_zm", false );
	include_weapon( "galil_zm" );
	include_weapon( "galil_upgraded_zm", false );
	include_weapon( "commando_zm" );
	include_weapon( "commando_upgraded_zm", false );
	include_weapon( "fnfal_zm" );
	include_weapon( "fnfal_upgraded_zm", false );

	//	Weapons - Sniper Rifles
	include_weapon( "dragunov_zm" );							// ptrs41
	include_weapon( "dragunov_upgraded_zm", false );
	include_weapon( "l96a1_zm" );
	include_weapon( "l96a1_upgraded_zm", false );

	//	Weapons - Machineguns
	include_weapon( "rpk_zm" );									// mg42, 30 cal, ppsh
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
	include_weapon( "shrink_ray_zm" );
	include_weapon( "shrink_ray_upgraded_zm", false );
	
	include_weapon( "crossbow_explosive_zm" );
	include_weapon( "crossbow_explosive_upgraded_zm", false );
	include_weapon( "knife_ballistic_zm", true );
	include_weapon( "knife_ballistic_upgraded_zm", false );
	include_weapon( "knife_ballistic_bowie_zm", false );
	include_weapon( "knife_ballistic_bowie_upgraded_zm", false );
	level._uses_retrievable_ballisitic_knives = true;

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "m1911_zm", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "crossbow_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "knife_ballistic_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "shrink_ray_zm", 1 );

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
	include_powerup( "free_perk" );
}

add_powerups_after_round_1()
{
/#
	// allow powerups when cheating
	if ( GetDvarInt("zombie_cheat") > 0 )
	{
		return;
	}
#/

	//want to precache all the stuff for these powerups, but we don't want them to be available in the first round
	level.zombie_powerup_array = array_remove (level.zombie_powerup_array, "nuke"); 
	level.zombie_powerup_array = array_remove (level.zombie_powerup_array, "fire_sale");

	while (1)
	{
		if (level.round_number > 1)
		{
			level.zombie_powerup_array = array_add(level.zombie_powerup_array, "nuke");
			level.zombie_powerup_array = array_add(level.zombie_powerup_array, "fire_sale");
			break;
		}
		wait (1);
	}
}

//-------------------------------------
// name: 	init_weapons_locker
// self: 	level
// return:	nothing
// desc:	sets up the weapons locker
//--------------------------------------
init_weapons_locker()
{
	trigger = getEnt("weapons_locker", "targetname");
	// trigger SetHintString( "" ); // No longer a valid feature, removing hint string being set
	trigger SetCursorHint( "HINT_NOICON" );
	
	wallModel = getEnt(trigger.target, "targetname");

	trigger thread triggerWeaponsLockerWatch(wallModel);
}

//-------------------------------------
setup_water_physics()
{
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	for (i = 0; i < players.size; i++)
	{
		players[i] SetClientDvars("phys_buoyancy",1);
	}
}

mergeSort(current_list, less_than)
{
	if (current_list.size <= 1)
	{
		return current_list;
	}
		
	left = [];
	right = [];
	
	middle = current_list.size / 2;
	for (x = 0; x < middle; x++)
	{
		left = add_to_array(left, current_list[x]);
	}
	for (; x < current_list.size; x++)
	{
		right = add_to_array(right, current_list[x]);
	}
	
	left = mergeSort(left, less_than);
	right = mergeSort(right, less_than);
	
	result = merge(left, right, less_than);

	return result;	
}

merge(left, right, less_than)
{
	result = [];

	li = 0;
	ri = 0;
	while ( li < left.size && ri < right.size )
	{
		if ( [[less_than]](left[li], right[ri]) )
		{
			result[result.size] = left[li];
			li++;
		}
		else
		{
			result[result.size] = right[ri];
			ri++;
		}
	}

	while ( li < left.size )
	{
		result[result.size] = left[li];
		li++;
	}

	while ( ri < right.size )
	{
		result[result.size] = right[ri];
		ri++;
	}

	return result;
}

double_door_fx()
{
	flag_wait( "cave01_to_cave02" );
	door_ents = getentarray( "cave01_to_cave02_door", "targetname" );
	doors_x = 0;
	doors_y = 0;
	doors_z = 0;
	for( i=0;i<door_ents.size;i++ )
	{
		doors_x += door_ents[i].origin[0];
		doors_y += door_ents[i].origin[1];
		doors_z += door_ents[i].origin[2];
	}
	doors_x /= door_ents.size;
	doors_y /= door_ents.size;
	doors_z /= door_ents.size;
	door_origin = (doors_x, doors_y, doors_z );
	PlayFX( level._effect["square_door_open"], door_origin );
}

// Rolling rock doors
init_rolling_doors()
{
	rollingDoors = GetEntArray("rolling_door","targetname");
	array_thread(rollingDoors, ::rolling_door_think);
}

rolling_door_think()
{
	self.door_moveDir = AnglesToForward(self.angles);
	self.door_moveDist = self.script_float;
	self.door_moveTime = self.script_timer;
	self.door_radius = self.script_radius;
	self.door_wait = self.script_string;
		
	flag_wait(self.door_wait);
	PlaySoundAtPosition( "evt_door_stone_disc", self.origin );
	self play_sound_on_ent("purchase");

	PlayFX( level._effect["rolling_door_open"], self.origin );
	
	pi = 3.1415926;
	endOrigin = self.origin + (self.door_moveDir * self.door_moveDist);
	self moveto(endOrigin,self.door_moveTime, 0.1, 0.1);
	
	cir = 2*pi*self.door_radius;
	rotate = (self.door_moveDist / cir) * 360.0;
	
//	x=self.script_angles[1];
//	a = Cos(x);
//	b = 0;
//	c = -1 * Sin(x);
	self rotateTo(self.angles + (rotate,0,0),self.door_moveTime, 0.1, 0.1);
	self connectpaths();
}

player_laststand_temple( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration )
{
	if(is_true(self.riding_geyser))
	{
		self unlink();
	}
	self maps\_zombiemode::player_laststand( eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration );
}

temple_poi_positioning_func(origin, forward)
{
	return maps\_zombiemode_server_throttle::server_safe_ground_trace_ignore_water( "poi_trace", 10, self.origin + forward + ( 0, 0, 10 ) );
}

temple_powerup_fx_func()
{
	self delete_powerup_fx();
	
	self.fx_green = maps\_zombiemode_net::network_safe_spawn( "powerup_fx", 2, "script_model", self.origin );
	self.fx_green setmodel("tag_origin");
	self.fx_green LinkTo(self);
	playfxontag(level._effect["powerup_on"],self.fx_green,"tag_origin");
	self thread delete_powerup_fx_wait();
}
delete_powerup_fx_wait()
{
	self waittill("death");
	self delete_powerup_fx();
}
delete_powerup_fx()
{
	if(isDefined(self.fx_green))
	{
		self.fx_green Unlink();
		self.fx_green delete();
		self.fx_green = undefined;
	}
}

init_random_perk_machines()
{
	randMachines = [];
	randMachines = _add_machine(randMachines, "vending_jugg", "mus_perks_jugganog_sting", "specialty_armorvest", "mus_perks_jugganog_jingle", "jugg_perk", "zombie_vending_jugg");
	randMachines = _add_machine(randMachines, "vending_marathon", "mus_perks_stamin_sting", "specialty_longersprint", "mus_perks_stamin_jingle", "marathon_perk", "zombie_vending_marathon");
	randMachines = _add_machine(randMachines, "vending_divetonuke", "mus_perks_phd_sting", "specialty_flakjacket", "mus_perks_phd_jingle", "divetonuke_perk", "zombie_vending_nuke");
	randMachines = _add_machine(randMachines, "vending_deadshot", "mus_perks_deadshot_sting", "specialty_deadshot", "mus_perks_deadshot_jingle", "tap_deadshot", "zombie_vending_ads");
	randMachines = _add_machine(randMachines, "vending_sleight", "mus_perks_speed_sting", "specialty_fastreload", "mus_perks_speed_jingle", "speedcola_perk", "zombie_vending_sleight");
	randMachines = _add_machine(randMachines, "vending_doubletap", "mus_perks_doubletap_sting", "specialty_rof", "mus_perks_doubletap_jingle", "tap_perk", "zombie_vending_doubletap");
	
	machines = getEntArray("zombie_vending_random","targetname");
	
	//Parse what machines are allowed
	for(i=0;i<machines.size;i++)
	{
		machine = machines[i];
		machine.allowed = [];
		if(isdefined(machine.script_parameters))
		{
			machine.allowed = strtok(machine.script_parameters, ",");
		}
		if(machine.allowed.size==0)
		{
			//allow all
			machine.allowed = array("jugg_perk","marathon_perk","divetonuke_perk","tap_deadshot","speedcola_perk","tap_perk");
		}
		
		machine.allowed = array_randomize(machine.allowed);
	}
	
	//Sort machines by the one with the least options gets first pick of vending machines
	machines = mergeSort(machines, ::perk_machines_compare_func);
	
	for(i=0;i<machines.size;i++)
	{
		machine = machines[i];
		
		
		//Pick a machine
		randMachine = undefined;
		for(j=0;j<machine.allowed.size;j++)
		{
			index = _rand_perk_index(randMachines, machine.allowed[j]);
			if(isdefined(index))
			{
				randMachine = randMachines[index];
				randMachines = array_remove_index(randMachines, index);
				break;
			}
		}
		
		AssertEx(IsDefined(randMachine), "Random Perk could not be assigned to machine.");
		
		machine.script_label = randMachine.script_label;
		machine.script_noteworthy = randMachine.script_noteworthy;
		machine.script_sound = randMachine.script_sound;
		machine.script_string = randMachine.script_string;
		machine.targetname = randMachine.targetname;
		
		machine_model = undefined;
		clip = undefined; //All the clip code is special case for the quick revive machine. Blah!
		targets = getEntArray(machine.target,"targetname");
		for(j=0;j<targets.size;j++)
		{
			noteworthy = targets[j].script_noteworthy;
			if(isdefined(noteworthy) && noteworthy == "clip")
			{
				clip = targets[j];
			}
			else
			{
				machine_model = targets[j];
			}
		}
		
		machine.target = randMachine.target;
		
		if(isdefined(machine_model))
		{
			machine_model setModel(randMachine.model);
			machine_model.targetname = randMachine.target;
			machine_model.script_string = randMachine.script_string;
		}
		
		if(isDefined(clip))
		{
			clip.targetname = randMachine.target;
		}
	}
}
_rand_perk_index(randMachines, name)
{
	for(i=0;i<randMachines.size;i++)
	{
		if(randMachines[i].script_string == name)
		{
			return i;
		}
	}
	return undefined;
}
perk_machines_compare_func(m1,m2)
{
	return m1.allowed.size < m2.allowed.size;
}

_add_machine(machines, target, script_label, script_noteworthy, script_sound, script_string, model)
{
	s = spawnstruct();
	s.target = target;
	s.script_label = script_label;
	s.script_noteworthy = script_noteworthy;
	s.script_sound = script_sound;
	s.script_string = script_string;
	s.targetname = "zombie_vending";
	s.model = model;
	
	precacheModel(model);
	
	machines[machines.size] = s;
	return machines;
}


precache_player_model_override()
{
	mptype\player_t5_zm_theater::precache();
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
			character\c_usa_dempsey_zt::main();// Dempsy
			break;
		case 1:
			character\c_rus_nikolai_zt::main();// Nikolai
			break;
		case 2:
			character\c_jap_takeo_zt::main();// Takeo
			break;
		case 3:
			character\c_ger_richtofen_zt::main();// Richtofen
			break;	
	}
}

//Order needs to match client scripts
player_set_viewmodel_override( entity_num )
{
	switch( self.entity_num )	//this is not GetEntityNumber() it can be randomized
	{
		case 0:
			// Dempsey
			self SetViewModel( "viewmodel_usa_pow_arms" );
			break;
		case 1:
			// Nikolai
			self SetViewModel( "viewmodel_rus_prisoner_arms" );
			break;
		case 2:
			// Takeo
			self SetViewModel( "viewmodel_vtn_nva_standard_arms" );
			break;
		case 3:
			// Richtofen
			self SetViewModel( "viewmodel_usa_hazmat_arms" );
			break;		
	}
}

init_random_paths()
{
	nodes = GetNodeArray("random_toggle_node", "script_noteworthy");
	for(i=0;i<nodes.size;i++)
	{
		nodes[i] thread random_node_toggle(10,20,10,20);
	}
}

random_node_toggle(minOn, maxOn, minOff, maxOff)
{
	target = GetNode(self.target, "targetname");
	if(!isDefined(target))
	{
		return;
	}
	
	while(1)
	{
		wait randomfloatrange(minOn, maxOff);
		unlinknodes(self, target);
		wait randomfloatrange(minOff, maxOff);
		linknodes(self, target);
	}
}

temple_exit_level()
{
	zombies = GetAiArray( "axis" );
	for ( i = 0; i < zombies.size; i++ )
	{

		if ( is_true( zombies[i].ignore_solo_last_stand ) )
		{
			continue;
		}

		if ( isDefined( zombies[i].find_exit_point ) )
		{
			zombies[i] thread [[ zombies[i].find_exit_point ]]();
			continue;
		}

		if ( zombies[i].ignoreme )
		{
			zombies[i] thread temple_delayed_exit();
		}
		else
		{
			zombies[i] thread temple_find_exit_point();
		}
	}
}

temple_delayed_exit()
{
	self endon( "death" );

	while ( 1 )
	{
		if ( !flag( "wait_and_revive" ) )
		{
			return;
		}

		// broke through the barricade, find an exit point
		if ( !self.ignoreme )
		{
			break;
		}
		wait_network_frame();
	}

	self thread temple_find_exit_point();
}

temple_find_exit_point()
{
	self endon( "death" );
	
	while(is_true(self.sliding))
	{
		wait(.1);		
	}

	min_distance_squared = 1024 * 1024;
	player = getplayers()[0];
	dest = 0;
	dist_far = 0;
	
	locs = array_randomize( level.enemy_dog_locations );

	for( i = 0; i < locs.size; i++ )
	{
		dist_zombie = DistanceSquared( locs[i].origin, self.origin );
		dist_player = DistanceSquared( locs[i].origin, player.origin );
		
		//Track the furthest away node that will be used if the criteria below if not met
		if(dist_player > dist_far)
		{
			dest = i;
			dist_far = dist_player;
		}

		if( ( dist_zombie < dist_player ) && ( dist_player > min_distance_squared ) )
		{
			dest = i;
			break;
		}
	}

	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );

	self setgoalpos( locs[dest].origin );

	while ( 1 )
	{
		if ( !flag( "wait_and_revive" ) )
		{
			break;
		}
		wait_network_frame();
	}
	
	self thread maps\_zombiemode_spawner::find_flesh();
}

temple_offhand_weapon_overrride()
{
	register_lethal_grenade_for_level( "frag_grenade_zm" );
	register_lethal_grenade_for_level( "sticky_grenade_zm" );
	level.zombie_lethal_grenade_player_init = "frag_grenade_zm";

	register_tactical_grenade_for_level( "zombie_cymbal_monkey" );
	level.zombie_tactical_grenade_player_init = undefined;

	register_placeable_mine_for_level( "claymore_zm" );
	level.zombie_placeable_mine_player_init = undefined;

	register_melee_weapon_for_level( "knife_zm" );
	register_melee_weapon_for_level( "bowie_knife_zm" );
	level.zombie_melee_weapon_player_init = "knife_zm";
}

temple_shrink_ray_model_mapping_func()
{
	//Mapping normal -> mini
	level.shrink_models["c_viet_zombie_female"]					= "c_viet_zombie_female_mini";
	level.shrink_models["c_viet_zombie_female_head"]			= "c_viet_zombie_female_head_mini";
	level.shrink_models["c_viet_zombie_nva1_body"]				= "c_viet_zombie_nva1_body_m";
	level.shrink_models["c_viet_zombie_nva1_head1"]				= "c_viet_zombie_nva1_head_m";
	level.shrink_models["c_viet_zombie_napalm"]					= "c_viet_zombie_napalm_m";
	level.shrink_models["c_viet_zombie_napalm_head"]			= "c_viet_zombie_napalm_head_m";
	level.shrink_models["c_viet_zombie_sonic_body"]				= "c_viet_zombie_sonic_body_m";
	level.shrink_models["c_viet_zombie_sonic_head"]				= "c_viet_zombie_sonic_head_m";
	level.shrink_models["c_viet_zombie_nva_body_alt"]			= "c_viet_zombie_nva_body_alt_m";
	level.shrink_models["c_viet_zombie_female_alt"]				= "c_viet_zombie_female_mini_alt";
	level.shrink_models["c_viet_zombie_vc_grunt_head"]			= "c_viet_zombie_vc_grunt_head_m";
	level.shrink_models["c_viet_zombie_vc_grunt"]				= "c_viet_zombie_vc_grunt_m";
		
	//Attachments
	//level.shrink_models["c_viet_zombie_nohat"]				= "c_viet_zombie_nohat_mini";
	//level.shrink_models["c_viet_zombie_sonic_shirt"]			= "c_viet_zombie_sonic_shirt_m";
	level.shrink_models["c_viet_zombie_sonic_bandanna"]			= "c_viet_zombie_sonic_bandanna_m";
	level.shrink_models["c_viet_zombie_nva1_gasmask"]			= "c_viet_zombie_nva1_gasmask_m";
	
	//Gib Mappings
	level.shrink_models["c_viet_zombie_female_g_barmsoff"]		= "c_viet_zombie_female_g_barmsoff_mini";	
	level.shrink_models["c_viet_zombie_female_g_headoff"]		= "c_viet_zombie_female_g_headoff_mini";
	level.shrink_models["c_viet_zombie_female_g_legsoff"]		= "c_viet_zombie_female_g_legsoff_mini";
	level.shrink_models["c_viet_zombie_female_g_llegoff"]		= "c_viet_zombie_female_g_llegoff_mini";
	level.shrink_models["c_viet_zombie_female_g_lowclean"]		= "c_viet_zombie_female_g_lowclean_mini";
	level.shrink_models["c_viet_zombie_female_g_rarmoff"]		= "c_viet_zombie_female_g_rarmoff_mini";
	level.shrink_models["c_viet_zombie_female_g_rlegoff"]		= "c_viet_zombie_female_g_rlegoff_mini";
	level.shrink_models["c_viet_zombie_female_g_upclean"]		= "c_viet_zombie_female_g_upclean_mini";
	level.shrink_models["c_viet_zombie_female_g_larmoff"]		= "c_viet_zombie_female_g_larmoff_mini";
	
	level.shrink_models["c_viet_zombie_female_g_barmsoff_alt"]	= "c_viet_zombie_female_g_barmsoff_alt_mini";	
	//level.shrink_models["c_viet_zombie_female_g_headoff_alt"]	= "c_viet_zombie_female_g_headoff_alt_mini"; //Uses c_viet_zombie_female_g_headoff
	level.shrink_models["c_viet_zombie_female_g_legsoff_alt"]	= "c_viet_zombie_female_g_legsoff_alt_mini";
	level.shrink_models["c_viet_zombie_female_g_llegoff_alt"]	= "c_viet_zombie_female_g_llegoff_alt_mini";
	level.shrink_models["c_viet_zombie_female_g_lowclean_alt"]	= "c_viet_zombie_female_g_lowclean_alt_mini";
	level.shrink_models["c_viet_zombie_female_g_rarmoff_alt"]	= "c_viet_zombie_female_g_rarmoff_alt_mini";
	level.shrink_models["c_viet_zombie_female_g_rlegoff_alt"]	= "c_viet_zombie_female_g_rlegoff_alt_mini";
	level.shrink_models["c_viet_zombie_female_g_upclean_alt"]	= "c_viet_zombie_female_g_upclean_alt_mini";
	level.shrink_models["c_viet_zombie_female_g_larmoff_alt"]	= "c_viet_zombie_female_g_larmoff_alt_mini";
	
	level.shrink_models["c_viet_zombie_nva1_g_barmsoff"]		= "c_viet_zombie_nva1_g_barmsoff_m";	
	level.shrink_models["c_viet_zombie_nva1_g_headoff"]			= "c_viet_zombie_nva1_g_headoff_m";
	level.shrink_models["c_viet_zombie_nva1_g_legsoff"]			= "c_viet_zombie_nva1_g_legsoff_m";
	level.shrink_models["c_viet_zombie_nva1_g_llegoff"]			= "c_viet_zombie_nva1_g_llegoff_m";
	level.shrink_models["c_viet_zombie_nva1_g_lowclean"]		= "c_viet_zombie_nva1_g_lowclean_m";
	level.shrink_models["c_viet_zombie_nva1_g_rarmoff"]			= "c_viet_zombie_nva1_g_rarmoff_m";
	level.shrink_models["c_viet_zombie_nva1_g_rlegoff"]			= "c_viet_zombie_nva1_g_rlegoff_m";
	level.shrink_models["c_viet_zombie_nva1_g_upclean"]			= "c_viet_zombie_nva1_g_upclean_m";
	level.shrink_models["c_viet_zombie_nva1_g_larmoff"]			= "c_viet_zombie_nva1_g_larmoff_m";
	
	level.shrink_models["c_viet_zombie_nva1_g_barmsoff_alt"]	= "c_viet_zombie_nva1_g_barmsoff_alt_m";	
	//level.shrink_models["c_viet_zombie_nva1_g_headoff_alt"]		= "c_viet_zombie_nva1_g_headoff_alt_m"; //Uses c_viet_zombie_nva1_g_headoff
	level.shrink_models["c_viet_zombie_nva1_g_legsoff_alt"]		= "c_viet_zombie_nva1_g_legsoff_alt_m";
	level.shrink_models["c_viet_zombie_nva1_g_llegoff_alt"]		= "c_viet_zombie_nva1_g_llegoff_alt_m";
	level.shrink_models["c_viet_zombie_nva1_g_lowclean_alt"]	= "c_viet_zombie_nva1_g_lowclean_alt_m";
	level.shrink_models["c_viet_zombie_nva1_g_rarmoff_alt"]		= "c_viet_zombie_nva1_g_rarmoff_alt_m";
	level.shrink_models["c_viet_zombie_nva1_g_rlegoff_alt"]		= "c_viet_zombie_nva1_g_rlegoff_alt_m";
	level.shrink_models["c_viet_zombie_nva1_g_upclean_alt"]		= "c_viet_zombie_nva1_g_upclean_alt_m";
	level.shrink_models["c_viet_zombie_nva1_g_larmoff_alt"]		= "c_viet_zombie_nva1_g_larmoff_alt_m";
	
	level.shrink_models["c_viet_zombie_vc_grunt_g_barmsoff"]	= "c_viet_zombie_vc_grunt_g_barmsoff_m";	
	level.shrink_models["c_viet_zombie_vc_grunt_g_headoff"]		= "c_viet_zombie_vc_grunt_g_headoff_m";
	level.shrink_models["c_viet_zombie_vc_grunt_g_legsoff"]		= "c_viet_zombie_vc_grunt_g_legsoff_m";
	level.shrink_models["c_viet_zombie_vc_grunt_g_llegoff"]		= "c_viet_zombie_vc_grunt_g_llegoff_m";
	level.shrink_models["c_viet_zombie_vc_grunt_g_lowclean"]	= "c_viet_zombie_vc_grunt_g_lowclean_m";
	level.shrink_models["c_viet_zombie_vc_grunt_g_rarmoff"]		= "c_viet_zombie_vc_grunt_g_rarmoff_m";
	level.shrink_models["c_viet_zombie_vc_grunt_g_rlegoff"]		= "c_viet_zombie_vc_grunt_g_rlegoff_m";
	level.shrink_models["c_viet_zombie_vc_grunt_g_upclean"]		= "c_viet_zombie_vc_grunt_g_upclean_m";
	level.shrink_models["c_viet_zombie_vc_grunt_g_larmoff"]		= "c_viet_zombie_vc_grunt_g_larmoff_m";
}


/*------------------------------------
we don't want the zombies to stop sliding
down the waterslide if someone throws a cymbol monkey down the slide
------------------------------------*/
check_if_should_avoid_poi()
{
	
	if(is_true(self.sliding))
	{
		return true; 
	}
	else
	{
		return false;
	}
	
}

zombiemode_cross_bow_fired_temple(grenade, weaponName, parent, player)
{
	if(!isDefined(level.cross_bow_bolts))
	{
		level.cross_bow_bolts = [];
	}
	
	level.cross_bow_bolts[level.cross_bow_bolts.size] = grenade;
	level.cross_bow_bolts = array_removeUndefined(level.cross_bow_bolts);
}

// Override for intersection fix, keeps players who happen to land on each other a moment before checking for intersection cheats
zombie_temple_player_intersection_tracker_override( other_player )
{
	if ( is_true( self.riding_geyser ) )
	{
		return true;
	}

	if ( is_true( other_player.riding_geyser ) )
	{
		return true;
	}

	return false;
}

zombie_temple_player_out_of_playable_area_monitor_callback()
{
	if ( is_true( self.on_slide ) )
	{
		return false;
	}

	if ( is_true( self.riding_geyser ) )
	{
		return false;
	}

	if ( is_true( self.is_on_minecart ) )
	{
		return false;
	}

	return true;
}

temple_death_screen_cleanup()
{
	self ClearClientFlag( level._CF_PLAYER_MAZE_FLOOR_RUMBLE );
	
	wait_network_frame();
	wait_network_frame();
	
	self SetBlur( 0, 0.1 );
}

temple_check_valid_spawn( revivee )
{
	// try to respawn in the same zone as another player
	spawn_points = getstructarray( "player_respawn_point", "targetname" );

	zkeys = GetArrayKeys( level.zones );

	for ( z = 0; z < zkeys.size; z++ )
	{
		zone_str = zkeys[z];
		if ( level.zones[ zone_str ].is_occupied )
		{
			for ( i = 0; i < spawn_points.size; i++ )
			{
				if ( spawn_points[i].script_noteworthy == zone_str )
				{
					spawn_array = getstructarray( spawn_points[i].target, "targetname" );
					for ( j = 0; j < spawn_array.size; j++ )
					{
						if ( spawn_array[j].script_int == ( revivee.entity_num + 1 ) )
						{
							return spawn_array[j].origin;
						}
					}
					return spawn_array[0].origin;
				}
			}
		}
	}

	return undefined;
}

temple_revive_solo_fx()
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		if ( vending_triggers[i].script_noteworthy == "specialty_quickrevive" )
		{
			vending_triggers[i] delete();
			break;
		}
	}
}
