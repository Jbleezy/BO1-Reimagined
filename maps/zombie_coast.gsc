#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;
//#include maps\_zombiemode_protips;

main()
{
	level thread maps\zombie_coast_ffotd::main_start();

	//for clientsiding the riser fx
	level.riser_type = "snow";
	level.use_new_riser_water = 1;
	level.riser_fx_on_client  = 1;
	level.use_clientside_rock_tearin_fx = 1;
	level.use_clientside_board_fx = 1;


	//needs to be first for create fx
	maps\zombie_coast_fx::main();


	init_fx_anims();

	//create points of interest underwater if needed
	level.poi_positioning_func = ::zombie_coast_poi_positioning_func;

	//moved environ anims to the client
	//maps\zombie_coast_environmental::main();

	//precachemodel("zombie_zapper_cagelight_red");
	//precachemodel("zombie_zapper_cagelight_green");

	// viewmodel arms for the level
	PreCacheModel( "viewmodel_zom_gellar_arms" );
	PreCacheModel( "viewmodel_zom_englund_arms" );
	PreCacheModel( "viewmodel_zom_rooker_arms" );
	PreCacheModel( "viewmodel_zom_trejo_arms" );

	level._zombie_custom_add_weapons = ::custom_add_weapons;

	//clientflag variables
	level._CF_PLAYER_ZIPLINE_RUMBLE_QUAKE = 0;
	level._CF_PLAYER_ZIPLINE_FAKE_PLAYER_SETUP = 1;

	level._COAST_FOG_BLIZZARD = 2;
	level._CF_PLAYER_FLINGER_FAKE_PLAYER_SETUP_PRONE =3;
	level._CF_PLAYER_FLINGER_FAKE_PLAYER_SETUP_STAND =4;

	level._CF_PLAYER_WATER_FROST = 5; // WW: Player flag for water frost
	level._CF_PLAYER_WATER_FREEZE = 6;
	level._CF_PLAYER_WATER_FROST_REMOVE = 7; // Forcibly remove the frost at spectator

	level._CF_PLAYER_ELECTRIFIED = 8;	// Player hit by director or electric zombie

	level._ZOMBIE_ACTOR_FLAG_ELECTRIFIED = 2;	// 1 is being used for facial anim...might be able to remove it
	level._ZOMBIE_ACTOR_FLAG_DIRECTOR_LIGHT = 3;	// controls the prop light fx
	level._ZOMBIE_ACTOR_FLAG_DIRECTORS_STEPS = 4; // proper footsteps for the director
	level._ZOMBIE_ACTOR_FLAG_DIRECTOR_DEATH = 5;	// controls the "death" fx
	level._ZOMBIE_ACTOR_FLAG_LAUNCH_RAGDOLL = 0; //LAUNCHES THE RAGDOLLS FROM THE FLINGER

	if(GetDvarInt( #"artist") > 0)
	{
		return;
	}

	level.player_out_of_playable_area_monitor = true;
	level.player_out_of_playable_area_monitor_callback = ::zombie_coast_player_out_of_playable_area_monitor_callback;

	level.zombie_anim_override = maps\zombie_coast::anim_override_func;
	level.player_intersection_tracker_override = ::zombie_coast_player_intersection_tracker_override;
	maps\_zombiemode::register_player_damage_callback( ::zombie_coast_player_damage_level_override );

	level.delete_monkey_bolt_on_zombie_holder_death = ::zombie_coast_delete_monkey_bolt_on_zombie_holder_death;

	level._func_humangun_check = ::func_humangun_check;
	level.check_for_alternate_poi = ::check_for_alternate_poi;

	// Set pay turret cost
	level.pay_turret_cost = 850;
	level.plankB_cost = 1000;
	//level.zipline_cost	= 1000;

	level.random_pandora_box_start = true;

	level.zombie_coast_visionset = "zombie_coast";

	//DCS (022211): anims from black hole bomb for cave slide, init before zombiemode.
	level thread maps\zombie_coast_cave_slide::cave_slide_anim_init();

	level thread maps\_callbacksetup::SetupCallbacks();

	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;

	//setup function pointers
	maps\zombie_coast_flinger::main();

	level.dogs_enabled = false;

	// Special zombie types, director.
	level.custom_ai_type = [];
	//level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_dogs::init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_director::init );
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_faller::faller_init );

	maps\zombie_coast_ai_director::init();
	maps\zombie_coast_lighthouse::init(); // WW (02-02-11): Moving the light house scripts in to their own file
	maps\zombie_coast_water::init();
	maps\zombie_coast_eggs::init();

	level.door_dialog_function = maps\_zombiemode::play_door_dialog;

	include_weapons();
	include_powerups();
	level.use_zombie_heroes = true;
	level.zombiemode_using_marathon_perk = true;
	level.zombiemode_using_divetonuke_perk = true;
	level.zombiemode_using_deadshot_perk = true;

	// used for the water hazard
	level.use_freezegun_features = true;
	level.uses_tesla_powerup = true;

	// WW (01-24-11): Custom model loadouts for coast
	level.zombiemode_precache_player_model_override = ::coast_precache_custom_models;
	level.zombiemode_give_player_model_override = ::coast_custom_third_person_override;
	level.zombiemode_player_set_viewmodel_override = ::coast_custom_viewmodel_override;

	level.register_offhand_weapons_for_level_defaults_override = ::coast_offhand_weapon_overrride;
	level.zombiemode_offhand_weapon_give_override = ::coast_offhand_weapon_give_override;
	level.max_perks = 5;
	level.max_solo_lives = 3;

	level.revive_solo_fx_func = ::coast_revive_solo_fx;

	override_blocker_prices();
	override_box_locations();

	// Setting it up like this, means no references to maps\_zombiemode_animated_intro outside of this file.
	//level.zombiemode_anim_intro_scenes = maps\zombie_coast_animated_intro::declare_scenes;
	//level.zombiemode_animated_intro = maps\_zombiemode_animated_intro::precache_scene_assets;
	// DO ACTUAL ZOMBIEMODE INIT
	maps\_zombiemode::main();

	maps\_sticky_grenade::init();
	maps\_zombiemode_weap_sickle::init();
	maps\_zombiemode_weap_humangun::init();
	maps\_zombiemode_weap_sniper_explosive::init();
	maps\_zombiemode_weap_nesting_dolls::init();

	level thread maps\_zombiemode::register_sidequest( "COTD", "ZOMBIE_COAST_EGG_SOLO", 43, "ZOMBIE_COAST_EGG_COOP", 44 );
	level.director_should_drop_special_powerup = ::coast_director_should_drop_special_powerup;

	// Turn off generic battlechatter - Steve G
	battlechatter_off("allies");
	battlechatter_off("axis");

	// Setup the levels Zombie Zone Volumes
	//maps\_compass::setupMiniMap("menu_map_zombie_coast");
	level.zone_manager_init_func = ::coast_zone_init;
	init_zones[0] = "beach_zone";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	level thread stairs_blocker_buyable();

	//setup generator switch
	level thread electric_switch();
	level thread electric_door_function();
	level thread maps\_zombiemode_auto_turret::init();

	level thread maps\zombie_coast_achievement::init();
	//level thread maps\zombie_coast_zipline::init();

	//VisionSetNaked( "zombie_coast_2", 6 );

	level thread maps\zombie_coast_ai_director::coast_director_start();

	// WW (02/17/11) - Introscreen fade
	level thread coast_fade_in_notify();

	//DCS(022211): triggered zombie slide.
	level thread maps\zombie_coast_cave_slide::zombie_cave_slide_init();

	//player zipline
	maps\_zombiemode_player_zipline::main();

	level thread setup_water_physics();
	level thread setup_zcoast_water();
	//level thread maps\_zombiemode_spawner::zombie_tracking_init();

	// fix for pathing below player at drop offs.
	SetSavedDvar( "zombiemode_path_minz_bias", 17 );

	//init the flinger trap/transport
	maps\zombie_coast_flinger::init_flinger();
	init_sounds();
	level thread maps\zombie_coast_amb::main();

	// WW: Temp sun direction change
	// TODO: Get it working then hand off to Laufer so he can transfer it to csc
	level thread coast_power_on_lighthouse_react();

	level thread coast_spawn_init_delay();

	level thread maps\zombie_coast_fx:: manage_blizzard();

	//level thread rock_wall_barricade();

	// KEEP AT END!!! DCS
	if(GetDvarInt( #"zombie_unlock_all") > 0)
	{
		level thread zombie_unlock_all();
	}

	level thread maps\zombie_coast_ffotd::main_end();
	level thread check_to_set_play_outro_movie();
}

check_to_set_play_outro_movie()
{
	flag_wait( "all_players_connected" );

	if ( !level.onlineGame && !level.systemlink )
	{
		SetDvar("ui_playCoastOutroMovie", 1);
	}
}

zombie_coast_player_out_of_playable_area_monitor_callback()
{
	if ( is_true( self._being_flung ) || is_true( self.is_ziplining ) )
	{
		return false;
	}

	return true;
}


zombie_unlock_all()
{
	flag_wait( "begin_spawning" );
	players = GetPlayers();

	flag_set( "power_on" );
	zombie_doors = GetEntArray( "zombie_door", "targetname" );
	for ( i = 0; i < zombie_doors.size; i++ )
	{
		zombie_doors[i] notify("trigger", players[0]);
	}
	zombie_debris = GetEntArray( "zombie_debris", "targetname" );
	for ( i = 0; i < zombie_debris.size; i++ )
	{
		zombie_debris[i] notify("trigger", players[0]);
	}
}

custom_add_weapons()
{
 	maps\_zombiemode_weapons::add_zombie_weapon( "humangun_zm",				"humangun_upgraded_zm",					&"ZOMBIE_WEAPON_HUMANGUN", 				10,		"human",			"",		undefined );
	maps\_zombiemode_weapons::add_zombie_weapon( "sniper_explosive_zm",		"sniper_explosive_upgraded_zm",			&"ZOMBIE_WEAPON_SNIPER_EXPLOSIVE",		2500,	"ubersniper",		"",		undefined );
	maps\_zombiemode_weapons::add_zombie_weapon( "tesla_gun_powerup_zm",			"tesla_gun_powerup_upgraded_zm",			&"ZOMBIE_WEAPON_TESLA", 				10,		"tesla",			"",		undefined, true ); //true - adds weapon without including it
}

coast_spawn_init_delay(director)
{
	flag_wait( "begin_spawning" );
	flag_clear( "spawn_zombies");
	director_zomb = undefined;

	while(!IsDefined(director_zomb))
	{
		zombs = GetAIArray ("axis");
		for ( i = 0; i < zombs.size; i++ )
		{
			if(IsDefined(zombs[i].animname) && zombs[i].animname == "director_zombie")
			{
				director_zomb = zombs[i];
			}
		}
		wait_network_frame();
	}

	//director_zomb waittill_notify_or_timeout( "director_spawn_zombies", 30 );
	//wait(30.0);

	flag_set( "spawn_zombies");
}


// ------------------------------------------------------------------------------------------------
#using_animtree( "generic_human" );
anim_override_func()
{
	level.scr_anim["zombie"]["walk3"] 	= %ai_zombie_walk_v2;	// DCS 030111: overwritten per bug # 76590
	level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v2;
}

// ------------------------------------------------------------------------------------------------
coast_zone_init()
{
	flag_init( "always_on" );
	flag_set( "always_on" );

	zone_volume = Spawn( "trigger_radius", (-900, 700, 450), 0, 128, 128 );
	zone_volume.targetname = "residence_roof_zone";
	zone_volume.script_noteworthy = "player_volume";

	// exit through lighthouse to beach facing ship.
	add_adjacent_zone( "start_zone", "lighthouse1_zone", "lighthouse_enter" );
	add_zone_flags(	"lighthouse_enter",									"start_beach_group" );

	// exit through lighthouse to cave.
	add_adjacent_zone( "start_cave_zone", "lighthouse1_zone", "lighthouse_lagoon_enter" );
	add_adjacent_zone( "start_cave_zone", "rear_lagoon_zone", "lighthouse_lagoon_enter" );
	add_zone_flags(	"lighthouse_lagoon_enter",									"start_beach_group" );

	// GROUP: always connected: start beach zone group.
	add_adjacent_zone( "start_zone", "start_beach_zone", "start_beach_group" );
	add_adjacent_zone( "start_beach_zone", "start_cave_zone", "start_beach_group", true ); // one way connection cave -> beach.

	// Ship front bottom
	add_adjacent_zone( "start_zone", "shipfront_bottom_zone", "enter_shipfront_bottom" );
	add_zone_flags(	"enter_shipfront_bottom",									"start_beach_group" );

	// Shipfront zones always connected because of drop down.
	add_adjacent_zone( "shipfront_bottom_zone", "shipfront_near_zone", "enter_shipfront_bottom" );
	add_adjacent_zone( "shipfront_bottom_zone", "shipfront_near_zone", "plankA_enter" );

	add_adjacent_zone( "shipfront_bottom_zone", "shipfront_near_zone", "shipfront_far_enter" );
	add_adjacent_zone( "shipfront_bottom_zone", "shipfront_near_zone", "shipfront_bottom_storage" );

	// Ship front far
	add_adjacent_zone( "shipfront_near_zone", "shipfront_far_zone", "shipfront_far_enter" );

	// New connector zone, ship front to start beach
	add_adjacent_zone( "shipfront_near_zone", "shipfront_2_beach_zone", "enter_shipfront_bottom" );
	add_adjacent_zone( "shipfront_near_zone", "shipfront_2_beach_zone", "plankA_enter" );

	add_adjacent_zone( "shipfront_near_zone", "shipfront_2_beach_zone", "shipfront_far_enter" );
	add_adjacent_zone( "shipfront_near_zone", "shipfront_2_beach_zone", "shipfront_bottom_storage" );

	add_adjacent_zone( "shipfront_2_beach_zone", "beach_zone", "enter_shipfront_bottom", true ); // one way connection
	add_adjacent_zone( "shipfront_2_beach_zone", "beach_zone", "plankA_enter", true ); // one way connection
	add_adjacent_zone( "shipfront_2_beach_zone", "beach_zone", "shipfront_far_enter", true ); // one way connection
	add_adjacent_zone( "shipfront_2_beach_zone", "beach_zone", "shipfront_bottom_storage", true ); // one way connection

	// Ship front under deck
	add_adjacent_zone( "shipfront_storage_zone", "shipfront_far_zone", "shipfront_deck_storage" );
	add_adjacent_zone( "shipfront_bottom_zone", "shipfront_storage_zone", "shipfront_bottom_storage" );

	// Plank A
	add_adjacent_zone( "shipfront_near_zone", "shipback_near_zone", "plankA_enter" );

	// Ship back far
	add_adjacent_zone( "shipback_near_zone", "shipback_far_zone", "shipback_far_enter" );

	// Stairs to 2 deck house level
	add_adjacent_zone( "shipback_near_zone", "shipback_near2_zone", "shipback_level2_enter" );

	// Ship back level 3
	add_adjacent_zone( "shipback_near2_zone", "shipback_level3_zone", "ship_house3" );

	// GROUP: always connected: residence, residence roof, beach 1 & 2 (to ship back)
	add_adjacent_zone( "residence1_zone", "residence_roof_zone", "residence_beach_group" );
	add_adjacent_zone( "residence_roof_zone", "beach_zone2", "residence_beach_group" );

	// debris at side beach to residence.
	add_adjacent_zone( "beach_zone2", "beach_zone", "side_beach_debris" );
	add_zone_flags(	"side_beach_debris",									"residence_beach_group" );

	// Plank B, from ship back to beach debris
	add_adjacent_zone( "shipback_near_zone", "beach_zone", "plankB_enter" );

	// Balcony - door from residence roof to lighthouse
	add_adjacent_zone( "residence_roof_zone", "lighthouse2_zone", "balcony_enter" );
	add_zone_flags(	"balcony_enter",									"residence_beach_group" );

	// lighthouse to residence interior
	add_adjacent_zone( "residence1_zone", "lighthouse1_zone", "res_2_lighthouse1" );
	add_zone_flags(	"res_2_lighthouse1",									"residence_beach_group" );

	// Resident front door
	add_adjacent_zone( "start_zone", "residence1_zone", "lighthouse_residence_front" );
	add_zone_flags(	"lighthouse_residence_front",									"residence_beach_group" );
	add_zone_flags(	"lighthouse_residence_front",									"start_beach_group" );

	// Lighthouse 2
	add_adjacent_zone( "lighthouse1_zone", "lighthouse2_zone", "lighthouse2_enter" );

	// Catwalk
	add_adjacent_zone( "catwalk_zone", "lighthouse2_zone", "catwalk_enter" );
	add_zone_flags(	"catwalk_enter", "start_beach_group" );

	level thread enable_shipfront_far_zone();
}

enable_shipfront_far_zone()
{
	flag_wait("catwalk_enter");

	maps\_zombiemode_zone_manager::enable_zone("shipfront_far_zone");
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
	//include_weapon( "frag_grenade_zm", false );
	include_weapon( "sticky_grenade_zm", false, true );
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
	include_weapon( "mp40_zm", false );
	include_weapon( "mp40_upgraded_zm", false );

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
	include_weapon( "ray_gun_zm" );
	include_weapon( "ray_gun_upgraded_zm", false );
	include_weapon( "crossbow_explosive_zm" );
	include_weapon( "crossbow_explosive_upgraded_zm", false );

	include_weapon( "humangun_zm", true, false );
	include_weapon( "humangun_upgraded_zm", false );
	include_weapon( "sniper_explosive_zm", true );
	include_weapon( "sniper_explosive_upgraded_zm", false );
	include_weapon( "zombie_nesting_dolls", true, false );

	include_weapon( "knife_ballistic_zm", true );
	include_weapon( "knife_ballistic_upgraded_zm", false );
	include_weapon( "knife_ballistic_sickle_zm", false );
	include_weapon( "knife_ballistic_sickle_upgraded_zm", false );
	level._uses_retrievable_ballisitic_knives = true;

	include_weapon( "tesla_gun_powerup_zm", false );
	include_weapon( "tesla_gun_powerup_upgraded_zm", false );

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "m1911_zm", 0 );
	//maps\_zombiemode_weapons::add_limited_weapon( "tesla_gun_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "humangun_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "sniper_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "crossbow_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "knife_ballistic_zm", 1 );
	//maps\_zombiemode_weapons::add_limited_weapon( "zombie_nesting_dolls", 1 );

	precacheItem( "explosive_bolt_zm" );
	precacheItem( "explosive_bolt_upgraded_zm" );
	precacheItem( "sniper_explosive_bolt_zm" );
	precacheItem( "sniper_explosive_bolt_upgraded_zm" );

	// get the sickle into the collector achievement list
	level.collector_achievement_weapons = array_add( level.collector_achievement_weapons, "sickle_knife_zm" );
}

coast_director_should_drop_special_powerup()
{
	return maps\_zombiemode::is_sidequest_previously_completed("COTD");
}

// -- Offhand weapon override for cosmodrome
coast_offhand_weapon_overrride()
{
	//register_lethal_grenade_for_level( "frag_grenade_zm" );
	register_lethal_grenade_for_level( "sticky_grenade_zm" );
	level.zombie_lethal_grenade_player_init = "sticky_grenade_zm";

	register_tactical_grenade_for_level( "zombie_nesting_dolls" );
	level.zombie_tactical_grenade_player_init = undefined;

	register_placeable_mine_for_level( "claymore_zm" );
	level.zombie_placeable_mine_player_init = undefined;

	register_melee_weapon_for_level( "knife_zm" );
	register_melee_weapon_for_level( "sickle_knife_zm" );
	level.zombie_melee_weapon_player_init = "knife_zm";
}


coast_offhand_weapon_give_override( str_weapon )
{
	self endon( "death" );

	if( is_tactical_grenade( str_weapon ) && IsDefined( self get_player_tactical_grenade() ) && !self is_player_tactical_grenade( str_weapon ) )
	{
		self SetWeaponAmmoClip( self get_player_tactical_grenade(), 0 );
		self TakeWeapon( self get_player_tactical_grenade() );
	}

	if( str_weapon == "zombie_nesting_dolls" )
	{
		self maps\_zombiemode_weap_nesting_dolls::player_give_nesting_dolls();
		//self maps\_zombiemode_weapons::play_weapon_vo( str_weapon ); // ww: need to figure out how we will get the sound here
		return true;
	}

	return false;
}


zombie_coast_player_intersection_tracker_override( other_player )
{
	if ( is_true( self._being_flung ) || is_true( self.is_ziplining ) )
	{
		return true;
	}

	if ( is_true( other_player._being_flung ) || is_true( other_player.is_ziplining ) )
	{
		return true;
	}

	return false;
}


zombie_coast_player_damage_level_override( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, modelIndex, psOffsetTime )
{
	if ( is_true( self._being_flung ) || is_true( self.is_ziplining ) )
	{
		return 0;
	}

	return -1; // did nothing
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

	// WW (02-04-11): Added minigun
	PreCacheItem( "minigun_zm" );
	include_powerup( "minigun" );

	// WW (03-14-11): Added Tesla
	//PreCacheItem( "tesla_gun_powerup_zm" );
	//PrecacheItem( "tesla_gun_powerup_upgraded_zm" );
	include_powerup( "tesla" );

	include_powerup( "free_perk" );

	include_powerup( "random_weapon" );
}

//*****************************************************************************
// AUDIO
//*****************************************************************************

init_sounds()
{
	maps\_zombiemode_utility::add_sound( "break_stone", "break_stone" );
	maps\_zombiemode_utility::add_sound( "lighthouse_double_door", "zmb_lighthouse_double_door" );
	maps\_zombiemode_utility::add_sound( "ship_door", "zmb_ship_door" );
	maps\_zombiemode_utility::add_sound( "ship_container_door", "zmb_ship_container_door" );
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

wait_for_power()
{
	master_switch = getent("elec_switch","targetname");
	master_switch notsolid();

	flag_wait( "power_on" );

	master_switch rotateroll(-90,.3);
	master_switch playsound("zmb_switch_flip");

	// Set Perk Machine Notifys
	level notify("revive_on");
	wait_network_frame();
	level notify("juggernog_on");
	wait_network_frame();
	level notify("sleight_on");
	wait_network_frame();
	level notify("doubletap_on");
	wait_network_frame();
	level notify("divetonuke_on");
	wait_network_frame();
	level notify("marathon_on");
	wait_network_frame();
	level notify("deadshot_on");
	wait_network_frame();
	level notify("Pack_A_Punch_on" );
	wait_network_frame();

	// Set Electric Door Notify
	level notify("electric_door");

	clientnotify("ZPO");	 // Zombie Power On.

	master_switch waittill("rotatedone");
	playfx(level._effect["switch_sparks"] ,getstruct("elec_switch_fx","targetname").origin);

	master_switch playsound("zmb_turn_on");
}

//*****************************************************************************
// ELECTRIC DOOR
//*****************************************************************************

// Turn off the buyable door triggers for electric doors
electric_door_function()
{
	door_trigs = getentarray( "electric_door", "script_noteworthy" );

	// Shows hintstring
	//door_trigs[0] sethintstring(&"ZOMBIE_FLAMES_UNAVAILABLE");
	//door_trigs[0] UseTriggerRequireLookAt();
	array_thread( door_trigs, ::set_door_unusable );
	array_thread( door_trigs, ::play_door_dialog );

	// Wait for the Electric Switch Activation
	level waittill( "electric_door" );

	array_thread( door_trigs, ::trigger_off );

	thread open_electric_doors( door_trigs );

	//flag_set( "zipline_power" );
}


// Electric Doors are Unuseable
set_door_unusable()
{
	self sethintstring(&"ZOMBIE_NEED_POWER");
	self UseTriggerRequireLookAt();
}


// This opens the doors once the electric swtich is activated
// MM - this is basically a copy of the door open script
open_electric_doors( door_trigs )
{
	time = 1;

	for(i=0;i<door_trigs.size;i++)
	{
		doors = getentarray(door_trigs[i].target,"targetname");

		for ( j=0; j<doors.size; j++ )
		{
			doors[j] NotSolid();

			time = 1;
			if( IsDefined( doors[j].script_transition_time ) )
			{
				time = doors[j].script_transition_time;
			}

			doors[j] connectpaths();

			if( door_trigs[i].type == "rotate" )
			{
				doors[j] NotSolid();

				time = 1;
				if( IsDefined( doors[j].script_transition_time ) )
				{
					time = doors[j].script_transition_time;
				}

				play_sound_at_pos( "door_rotate_open", doors[j].origin );

				doors[j] RotateTo( doors[j].script_angles, time, 0, 0 );
				doors[j] thread maps\_zombiemode_blockers::door_solid_thread();
				doors[j] playsound ("door_slide_open");
			}
			else if( door_trigs[i].type == "move" || door_trigs[i].type == "slide_apart" )
			{
				doors[j] NotSolid();

				time = 1;
				if( IsDefined( doors[j].script_transition_time ) )
				{
					time = doors[j].script_transition_time;
				}

				play_sound_at_pos( "door_slide_open", doors[j].origin );

				doors[j] MoveTo( doors[j].origin + doors[j].script_vector, time, time * 0.25, time * 0.25 );
				doors[j] thread maps\_zombiemode_blockers::door_solid_thread();
				doors[j] playsound ("door_slide_open");
			}
			wait(randomfloat(.15));
		}
	}
}


play_door_dialog()
{
	self endon ("warning_dialog");
	timer = 0;
	while(1)
	{
		wait(0.05);
		players = get_players();
		for(i = 0; i < players.size; i++)
		{
			dist = distancesquared(players[i].origin, self.origin );
			if(dist > 70*70)
			{
				timer =0;
				continue;
			}
			while(dist < 70*70 && timer < 3)
			{
				wait(0.5);
				timer++;
			}
			if(dist > 70*70 && timer >= 3)
			{
				self playsound("door_deny");
				players[i] thread do_player_vo("vox_start", 5);
				wait(3);
				self notify ("warning_dialog");
				//iprintlnbold("warning_given");
			}
		}
	}
}


//-------------------------------------------------------------------------
// handles building the plank between the residence and shipback
//-------------------------------------------------------------------------
check_plankB( from, forward )
{
	trigger = getent( from, "targetname" );
	trigger sethintstring( &"ZOMBIE_BUILD_BRIDGE" );
	trigger setcursorhint( "HINT_NOICON" );

	trigger endon( "plankB_done" );

	user = undefined;
	done = false;

	while ( !done )
	{
		trigger waittill( "trigger", user );

		if ( is_player_valid( user ) && user.score >= level.plankB_cost )
		{
			user maps\_zombiemode_score::minus_to_player_score( level.plankB_cost );

			// get rid of the trigger on the opposite side of the bridge
			other = getent( trigger.target, "targetname" );
			other notify( "plankB_done" );
			other delete();

			trigger delete();

			// remove clip and connect paths
			clip = getent( "plankB_clip", "targetname" );
			clip connectpaths();
			clip delete();

			// construct it
			if ( forward == true )
			{
				for ( i = 1; i <= 4; i++ )
				{
					bridge = getent( "residence2ship_walk" + i, "targetname" );
					bridge show();

					wait( 0.5 );
				}
			}
			else
			{
				for ( i = 4; i >= 1; i-- )
				{
					bridge = getent( "residence2ship_walk" + i, "targetname" );
					bridge show();

					wait( 0.5 );
				}
			}

			done = true;
			flag_set( "plankB_enter" );
		}

		wait( .05 );
	}
}


//-------------------------------------------------------------------------
// waits for zone to be enabled before unlocking
//-------------------------------------------------------------------------
wait_for_respawn()
{
	zone_name = self.script_noteworthy;
	if ( isDefined( level.zones[ zone_name ] ) )
	{
		while ( !level.zones[ zone_name ].is_enabled )
		{
			wait( 0.5 );
		}

		self.locked = false;
	}
}

//-------------------------------------------------------------------------
// Special Buyable stairs
//-------------------------------------------------------------------------

stairs_blocker_buyable()
{
	trigger = getentarray("buyable_stairs", "targetname");

	for ( i = 0; i < trigger.size; i++ )
	{
		trigger[i] thread stairs_init();
	}
}

stairs_init()
{

	cost = 1000;
	if( IsDefined( self.zombie_cost ) )
	{
		cost = self.zombie_cost;
	}

	self set_hint_string( self, "default_buy_debris_" + cost );
	self SetCursorHint( "HINT_NOICON" );

	if( isdefined (self.script_flag)  && !IsDefined( level.flag[self.script_flag] ) )
	{
		flag_init( self.script_flag );
	}

	self UseTriggerRequireLookAt();

	clip = undefined;
	debris = undefined;
	planks = getentarray( self.target, "targetname" );

	for( i = 0; i < planks.size; i++ )
	{
		if( IsDefined( planks[i].script_noteworthy ) )
		{
			if( planks[i].script_noteworthy == "clip")
			{
				clip = planks[i];
				planks = array_remove(planks, clip);
				i--;
				continue;
			}
			else if( planks[i].script_noteworthy == "debris_blocker" )
			{
				debris = planks[i];
				planks = array_remove(planks, debris);
				i--;
				continue;
			}
			else
			{
				//planks[i] hide();
			}
		}
	}

	wait_network_frame();
	self thread stairs_think(planks, debris, clip);
}

stairs_think(planks, debris, clip)
{
	while( 1 )
	{
		self waittill( "trigger", who );

		if( !who UseButtonPressed() )
		{
			continue;
		}

		if( who in_revive_trigger() )
		{
			continue;
		}

		if( is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{
				// set the score
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );

				bbPrint( "zombie_uses: playername %s playerscore %d round %d cost %d name %s x %f y %f z %f type debris", who.playername, who.score, level.round_number, self.zombie_cost, self.target, self.origin );


				if( IsDefined( self.script_flag ) )
				{
					flag_set( self.script_flag );
				}

				play_sound_at_pos( "purchase", self.origin );
				level notify ("junk purchased");
				level.stairs_pieces = 0;
/*
				//iprintlnbold("How many planks ", planks.size);
				for( i = 0; i < planks.size; i++ )
				{

					if( IsDefined( planks[i].script_linkTo ) )
					{
						planks_struct = getstruct( planks[i].script_linkTo, "script_linkname" );
						if( IsDefined( planks_struct ) )
						{
							planks[i] thread stairs_move( planks_struct, planks, self );
						}
					}
					else
					{
						planks[i] show();
					}
				}
*/
				self set_hint_string( self, "" );
//				self waittill("stairs_complete");

				if( IsDefined( debris.script_linkTo ) )
				{
					debris_struct = getstruct( debris.script_linkTo, "script_linkname" );
					if( IsDefined( debris_struct ))
					{
						debris thread special_debris_move(debris_struct);
					}
				}

				if(IsDefined(clip))
				{
					clip moveto(clip.origin + (0, 0, -1000), 0.1);
					wait(0.1);
					clip connectpaths();
					clip delete();
				}

				self delete();
			}
			else
			{
				play_sound_at_pos( "no_purchase", self.origin );
			}
		}
	}
}


stairs_move( struct, planks, trigger )
{
	self script_delay();

	self notsolid();

	selfpos = self.origin;
	selfang = self.angles;

	self moveto(struct.origin, 0.1);

	wait(randomfloatrange(1.0, 10.0));

	self show();
	self play_sound_on_ent( "debris_move" );
	playsoundatposition ("lightning_l", self.origin);
	if( IsDefined( self.script_firefx ) )
	{
		PlayFX( level._effect[self.script_firefx], self.origin );
	}

	// Do a little jiggle, then move.
	if( IsDefined( self.script_noteworthy ) )
	{
		if( self.script_noteworthy == "jiggle" )
		{
			num = RandomIntRange( 3, 5 );
			og_angles = self.angles;
			for( i = 0; i < num; i++ )
			{
				angles = og_angles + ( -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ) );
				time = RandomFloatRange( 0.1, 0.4 );
				self Rotateto( angles, time );
				wait( time - 0.05 );
			}
		}
	}

	time = 0.5;
	if( IsDefined( self.script_transition_time ) )
	{
		time = self.script_transition_time;
	}

	self MoveTo( selfpos, time, time * 0.5 );
	self RotateTo( selfang, time * 0.75 );

	self waittill( "movedone" );

	level.stairs_pieces++;
	if(level.stairs_pieces >= planks.size)
	{
		trigger notify("stairs_complete");
	}

	//Z2 commented out missing sound, wouldn't go past.
	//self play_sound_on_entity ("couch_slam");
	if( IsDefined( self.script_fxid ) )
	{
		PlayFX( level._effect[self.script_fxid], self.origin );
		playsoundatposition("zombie_spawn", self.origin); //just playing the zombie_spawn sound when it deletes the blocker because it matches the particle.
	}


}

special_debris_move( struct )
{
	self script_delay();
	self notsolid();

	self play_sound_on_ent( "debris_move" );
	playsoundatposition ("lightning_l", self.origin);
	if( IsDefined( self.script_firefx ) )
	{
		PlayFX( level._effect[self.script_firefx], self.origin );
	}

	num = RandomIntRange( 3, 5 );
	og_angles = self.angles;
	for( i = 0; i < num; i++ )
	{
		angles = og_angles + ( -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ) );
		time = RandomFloatRange( 0.1, 0.4 );
		self Rotateto( angles, time );
		wait( time - 0.05 );
	}

	time = 0.5;

	self MoveTo( struct.origin, time, time * 0.5 );
	self RotateTo( struct.angles, time * 0.75 );

	self waittill( "movedone" );

	//Z2 commented out missing sound, wouldn't go past.
	//self play_sound_on_entity ("couch_slam");

	if( IsDefined( self.script_fxid ) )
	{
		PlayFX( level._effect[self.script_fxid], self.origin );
		playsoundatposition("zombie_spawn", self.origin); //just playing the zombie_spawn sound when it deletes the blocker because it matches the particle.
	}
	self Delete();
}


zombie_coast_delete_monkey_bolt_on_zombie_holder_death()
{
	if ( is_true( self.is_ziplining ) )
	{
		return true;
	}
	else
	{
		return false;
	}
}


//////////////////////////////////////////////////////////////////////////////////////////
// Custom load out for Coast
//////////////////////////////////////////////////////////////////////////////////////////

// WW (01-24-11): Precache special models for coast
coast_precache_custom_models()
{
	mptype\player_t5_zm_coast::precache(); // this precaches all the custom characters
}

// WW (01-24-11): Set special third person models for coast
coast_custom_third_person_override( entity_num )
{
	if( IsDefined( self.zm_random_char ) )
	{
		entity_num = self.zm_random_char;
	}

	switch( entity_num )
	{
	case 0:
		character\c_zom_sarah_michelle_gellar_player::main();
		break;
	case 1:
		character\c_zom_robert_englund_player::main();
		break;
	case 2:
		character\c_zom_danny_trejo_player::main();
		break;
	case 3:
		character\c_zom_michael_rooker_player::main();
		break;
	}
}

// WW (01-24-11): Set the special first person model for coast
coast_custom_viewmodel_override( entity_num )
{
	switch( self.entity_num )
	{
	case 0:
		self SetViewModel( "viewmodel_zom_gellar_arms" );
		break;
	case 1:
		self SetViewModel( "viewmodel_zom_englund_arms" );
		break;
	case 2:
		self SetViewModel( "viewmodel_zom_trejo_arms" );
		break;
	case 3:
		self SetViewModel( "viewmodel_zom_rooker_arms" );
		break;
	}
}


//------------------------------------------------------------------------------
setup_water_physics()
{
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	for (i = 0; i < players.size; i++)
  {
		players[i] SetClientDvars("phys_buoyancy",1);
	}
}

//------------------------------------------------------------------------------
setup_zcoast_water()
{
// setup water
SetDvar( "r_waterWaveAngle", "0 45 90 180" );
SetDvar( "r_waterWaveWavelength", "350 150 450 650" );
SetDvar( "r_waterWaveAmplitude", "6 4 8 2" );
SetDvar( "r_waterWavePhase", "0 0 0 0" );
SetDvar( "r_waterWaveSteepness", "0.25 0.25 0.25 0.25" );
SetDvar( "r_waterWaveSpeed", "1 0.5 1 0.5" );
}

//------------------------------------------------------------------------------
// WW (02/17/11): When the introscreen fades this sends a client notify for the csc to set the vision
// Looks like the vision is being set too early and is not being activated properly
coast_fade_in_notify()
{
	level waittill( "fade_in_complete" );

	wait_network_frame();

	level ClientNotify( "ZID" ); // "Zombie Introscreen Done"
}

// WW (03-08-11): Activates the lightouse exploder
coast_power_on_lighthouse_react()
{

	// wait for power
	flag_wait( "power_on" );

	// exploder for the lighthouse going nuts
	exploder( 301 );

}
//------------------------------------------------------------------------------
rock_wall_barricade()
{
	rock_wall = getstruct("special_rock_wall", "script_noteworthy");
	boards = GetEntArray(rock_wall.target, "targetname");
	rock = undefined;

	for (i = 0; i < boards.size; i++)
	{
		if(IsDefined(boards[i].target))
		{
			rock = GetEnt(boards[i].target, "targetname");
			if(IsDefined(rock))
			{
				rock LinkTo(boards[i]);
			}
		}
	}
}

//------------------------------------------------------------------------------
coast_revive_solo_fx()
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


/*------------------------------------
this handles an electrified zombie being
hit with the humangun still ahving the electrified FX
------------------------------------*/
func_humangun_check()
{
	self notify("stop_melee_watch");
	if ( is_true( self.electrified ) )
	{
		maps\_zombiemode_ai_director::zombie_clear_electric_buff();
	}
}


/*------------------------------------
make sure the zombies don't get their
point of interest reset when they are following a player or a humanized zombie on the zipline
------------------------------------*/
check_for_alternate_poi()
{
	if(!is_true(self.following_human_zombie) && !is_true(self.following_player_zipline))
	{
		return false;
	}

	return true;
}


#using_animtree("fxanim_props_dlc3");
init_fx_anims()
{
	level.fxanims = [];
	level.fxanims["hook_anim"]		= %fxanim_zom_ship_crane01_hook_anim;
	level.fxanims["boat_anim"]		= %fxanim_zom_ship_lifeboat_anim;

}


///*------------------------------------
//for creating points of interest
//underwater
//------------------------------------*/
zombie_coast_poi_positioning_func(origin, forward)
{
	return maps\_zombiemode_server_throttle::server_safe_ground_trace_ignore_water( "poi_trace", 10, self.origin + forward + ( 0, 0, 10 ) );
}

override_blocker_prices()
{
	zombie_debris = GetEntArray( "zombie_debris", "targetname" );
	for( i = 0; i < zombie_debris.size; i++ )
	{
		if( IsDefined( zombie_debris[i].script_flag ) )
		{
			tokens = Strtok( zombie_debris[i].script_flag, "," );
			for ( j=0; j<tokens.size; j++ )
			{
				if(tokens[j] == "enter_shipfront_bottom")
				{
					zombie_debris[i].zombie_cost = 1000;
					break;
				}
			}
		}
	}
}

override_box_locations()
{
	PrecacheModel("p_glo_cinder_block_large");
	PrecacheModel("p_jun_wood_plank_large01");

	level.override_place_treasure_chest_bottom = ::zombie_coast_place_treasure_chest_bottom;

	origin = (-2701, -1415, 369);
	angles = (0, 275.625, 0);
	maps\_zombiemode_weapons::place_treasure_chest("shipback_far_chest", origin, angles);
}

zombie_coast_place_treasure_chest_bottom(origin, angles)
{
	forward = AnglesToForward(angles);
	right = AnglesToRight(angles);
	up = AnglesToUp(angles);

	block_model = "p_glo_cinder_block_large";
	top_model = "p_jun_wood_plank_large01";

	block1 = Spawn( "script_model", origin + (forward * 34.5) + (up * 2.2) );
	block1.angles = angles + (0, 45, 0);
	block1 SetModel( block_model );

	block2 = Spawn( "script_model", origin + (forward * 11.5) + (up * 2.2) );
	block2.angles = angles + (0, 90, 0);
	block2 SetModel( block_model );

	block3 = Spawn( "script_model", origin + (forward * -11.5) + (up * 2.2) );
	block3.angles = angles + (0, 135, 0);
	block3 SetModel( block_model );

	block4 = Spawn( "script_model", origin + (forward * -34.5) + (up * 2.2) );
	block4.angles = angles + (0, 90, 0);
	block4 SetModel( block_model );

	top1 = Spawn( "script_model", origin + (forward * -48) + (right * -8) + (up * 11.25) );
	top1.angles = angles + (0, 90, 90);
	top1 SetModel( top_model );

	top2 = Spawn( "script_model", origin + (forward * -48) + (right * 0) + (up * 11.25) );
	top2.angles = angles + (0, 90, 90);
	top2 SetModel( top_model );

	top3 = Spawn( "script_model", origin + (forward * -48) + (right * 8) + (up * 11.25) );
	top3.angles = angles + (0, 90, 90);
	top3 SetModel( top_model );

	return 14.25;
}