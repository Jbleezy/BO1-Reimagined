#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;
#include maps\zombie_cod5_factory_teleporter;
#include maps\_music;
//

main()
{
	// This has to be first for CreateFX -- Dale
	maps\zombie_cod5_factory_fx::main();

	// viewmodel arms for the level
	PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen

	// used to modify the percentages of pulls of ray gun and tesla gun in magic box
	level.pulls_since_last_ray_gun = 0;
	level.pulls_since_last_tesla_gun = 0;
	level.player_drops_tesla_gun = false;

	level.mixed_rounds_enabled = true;	// MM added support for mixed crawlers and dogs
	level.burning_zombies = [];		//JV max number of zombies that can be on fire
	level.zombie_rise_spawners = [];	// Zombie riser control
	level.max_barrier_search_dist_override = 400;

	level.door_dialog_function = maps\_zombiemode::play_door_dialog;
	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;

	// Animations needed for door initialization
	script_anims_init();

	level thread maps\_callbacksetup::SetupCallbacks();

	level.zombie_anim_override = maps\zombie_cod5_factory::anim_override_func;
	//level.exit_level_func = ::factory_exit_level;

	//level.custom_zombie_vox = ::setup_custom_vox;

	SetDvar( "perk_altMeleeDamage", 1000 ); // adjusts how much melee damage a player with the perk will do, needs only be set once

	precachestring(&"WAW_ZOMBIE_FLAMES_UNAVAILABLE");
	precachestring(&"ZOMBIE_ELECTRIC_SWITCH");

	precachestring(&"WAW_ZOMBIE_POWER_UP_TPAD");
	precachestring(&"WAW_ZOMBIE_TELEPORT_TO_CORE");
	precachestring(&"WAW_ZOMBIE_LINK_TPAD");
	precachestring(&"WAW_ZOMBIE_LINK_ACTIVE");
	precachestring(&"WAW_ZOMBIE_INACTIVE_TPAD");
	precachestring(&"WAW_ZOMBIE_START_TPAD");

	precacheshellshock("electrocution");
	precachemodel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	precacheModel("lights_indlight_on" );
	precacheModel("lights_milit_lamp_single_int_on" );
	precacheModel("lights_tinhatlamp_on" );
	precacheModel("lights_berlin_subway_hat_0" );
	precacheModel("lights_berlin_subway_hat_50" );
	precacheModel("lights_berlin_subway_hat_100" );

	PreCacheModel("collision_geo_512x512x512");
	PreCacheModel("collision_geo_128x128x128");

	// DCS: not mature settings models without blood or gore.
	PreCacheModel( "zombie_power_lever_handle" );

	precachestring(&"WAW_ZOMBIE_BETTY_ALREADY_PURCHASED");
	precachestring(&"WAW_ZOMBIE_BETTY_HOWTO");

	PrecacheString(&"REIMAGINED_POWER_UP_TPAD");
	PrecacheString(&"REIMAGINED_TELEPORT_TO_CORE");
	PrecacheString(&"REIMAGINED_LINK_TPAD");

	PrecacheString(&"REIMAGINED_TRAP_BRIDGE_EE");
	PrecacheString(&"REIMAGINED_DOOR_CLOSED");

	PrecacheString(&"ZOMBIE_BUTTON_BUY_TRAP");
	PrecacheString(&"REIMAGINED_TRAP_ACTIVE");
	PrecacheString(&"REIMAGINED_TRAP_COOLDOWN");

	include_weapons();
	include_powerups();

	level._effect["zombie_grain"]			= LoadFx( "misc/fx_zombie_grain_cloud" );

	maps\_waw_zombiemode_radio::init();

	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;
	level.register_offhand_weapons_for_level_defaults_override = ::register_offhand_weapons_for_level_defaults_override;

	// Special zombie types, dogs.
	level.dogs_enabled = true;
	level.custom_ai_type = [];
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_dogs::init );
	maps\_zombiemode_ai_dogs::enable_dog_rounds();

	level.use_zombie_heroes = true;

	override_blocker_prices();
	override_box_locations();

	maps\_zombiemode::main();

	init_sounds();
	init_achievement();
	level thread power_electric_switch();

	level thread magic_box_init();

	//DCS: get betties working.
	maps\_zombiemode_betty::init();

	//DCS: need stop watch setup
	maps\_zombiemode_timer::init();

	//ESM - time for electrocuting
	thread init_elec_trap_trigs();

	level.zone_manager_init_func = ::factory_zone_init;
	init_zones[0] = "receiver_zone";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	teleporter_init();

	//level thread intro_screen();

	//level thread jump_from_bridge();
	level lock_additional_player_spawner();

	level thread bridge_init();

	//AUDIO EASTER EGGS
	level thread phono_egg_init( "phono_one", "phono_one_origin" );
	level thread phono_egg_init( "phono_two", "phono_two_origin" );
	level thread phono_egg_init( "phono_three", "phono_three_origin" );

    level.meteor_counter = 0;
	level thread meteor_egg( "meteor_one" );
	level thread meteor_egg( "meteor_two" );
	level thread meteor_egg( "meteor_three" );
	level thread radio_egg_init( "radio_one", "radio_one_origin" );
	level thread radio_egg_init( "radio_two", "radio_two_origin" );
	level thread radio_egg_init( "radio_three", "radio_three_origin" );
	level thread radio_egg_init( "radio_four", "radio_four_origin" );
	level thread radio_egg_init( "radio_five", "radio_five_origin" );
	//level thread radio_egg_hanging_init( "radio_five", "radio_five_origin" );
	level.monk_scream_trig = getent( "monk_scream_trig", "targetname" );
	level thread play_giant_mythos_lines();
	level thread play_level_easteregg_vox( "vox_corkboard_1" );
	level thread play_level_easteregg_vox( "vox_corkboard_2" );
	level thread play_level_easteregg_vox( "vox_corkboard_3" );
	level thread play_level_easteregg_vox( "vox_teddy" );
	level thread play_level_easteregg_vox( "vox_fieldop" );
	level thread play_level_easteregg_vox( "vox_telemap" );
	level thread play_level_easteregg_vox( "vox_maxis" );
	level thread play_level_easteregg_vox( "vox_illumi_1" );
	level thread play_level_easteregg_vox( "vox_illumi_2" );
	level thread setup_custom_vox();

	// DCS: mature and german safe settings.
	level thread factory_german_safe();
	level thread mature_settings_changes();

	// Special level specific settings
	set_zombie_var( "zombie_powerup_drop_max_per_round", 3 );	// lower this to make drop happen more often

	// Check under the machines for change
	trigs = GetEntArray( "audio_bump_trigger", "targetname" );
	for ( i=0; i<trigs.size; i++ )
	{
		if ( IsDefined(trigs[i].script_sound) && trigs[i].script_sound == "fly_bump_bottle" )
		{
			trigs[i] thread check_for_change();
		}
	}

	trigs = GetEntArray( "trig_ee", "targetname" );
	array_thread( trigs, ::extra_events);

	level thread flytrap();

	// Set the color vision set back
	level.zombie_visionset = "zombie_factory";


	VisionSetNaked( "zombie_factory", 0 );
	SetSavedDvar( "r_lightGridEnableTweaks", 1 );
	SetSavedDvar( "r_lightGridIntensity", 1.45 );
	SetSavedDvar( "r_lightGridContrast", 0.15 );

	maps\createart\zombie_cod5_factory_art::main();

	level thread curbs_fix();
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

player_set_viewmodel_override( entity_num )
{
	switch( self.entity_num )
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

register_offhand_weapons_for_level_defaults_override()
{
	register_lethal_grenade_for_level( "stielhandgranate" );
	level.zombie_lethal_grenade_player_init = "stielhandgranate";

	register_tactical_grenade_for_level( "zombie_cymbal_monkey" );
	register_tactical_grenade_for_level( "molotov_zm" );
	level.zombie_tactical_grenade_player_init = undefined;

	register_placeable_mine_for_level( "mine_bouncing_betty" );
	level.zombie_placeable_mine_player_init = undefined;

	register_melee_weapon_for_level( "knife_zm" );
	register_melee_weapon_for_level( "bowie_knife_zm" );
	level.zombie_melee_weapon_player_init = "knife_zm";
}

init_achievement()
{
	//include_achievement( "achievement_shiny" );
	//include_achievement( "achievement_monkey_see" );
	//include_achievement( "achievement_frequent_flyer" );
	//include_achievement( "achievement_this_is_a_knife" );
	//include_achievement( "achievement_martian_weapon" );
	//include_achievement( "achievement_double_whammy" );
	//include_achievement( "achievement_perkaholic" );
	//include_achievement( "achievement_secret_weapon", "zombie_kar98k_upgraded" );
	//include_achievement( "achievement_no_more_door" );
	//include_achievement( "achievement_back_to_future" );

}

//-------------------------------------------------------------------------------
//	Create the zone information for zombie spawning
//-------------------------------------------------------------------------------
factory_zone_init()
{
	// Note this setup is based on a flag-centric view of setting up your zones.  A brief
	//	zone-centric example exists below in comments

	// Outside East Door
	add_adjacent_zone( "receiver_zone",		"outside_east_zone",	"enter_outside_east" );

	// Outside West Door
	add_adjacent_zone( "receiver_zone",		"outside_west_zone",	"enter_outside_west" );

	// Wnuen building ground floor
	add_adjacent_zone( "wnuen_zone",		"outside_east_zone",	"enter_wnuen_building" );

	// Wnuen stairway
	add_adjacent_zone( "wnuen_zone",		"wnuen_bridge_zone",	"enter_wnuen_loading_dock" );

	// Warehouse bottom
	add_adjacent_zone( "warehouse_bottom_zone", "outside_west_zone",	"enter_warehouse_building" );

	// Warehosue top
	add_adjacent_zone( "warehouse_bottom_zone", "warehouse_top_zone",	"enter_warehouse_second_floor" );
	add_adjacent_zone( "warehouse_top_zone",	"bridge_zone",			"enter_south_zone", true );

	// TP East
	add_adjacent_zone( "tp_east_zone",			"wnuen_zone",			"enter_tp_east" );

	//add_adjacent_zone( "tp_east_zone",			"outside_east_zone",	"enter_tp_east",			true );

	// TP South
	add_adjacent_zone( "tp_south_zone",			"outside_south_zone",	"enter_tp_south" );

	// TP West
	add_adjacent_zone( "tp_west_zone",			"warehouse_top_zone",	"enter_tp_west" );

	//add_adjacent_zone( "tp_west_zone",			"warehouse_bottom_zone", "enter_tp_west",		true );
	//add_zone_flags(	"enter_tp_west",										"enter_warehouse_second_floor" );

	add_adjacent_zone( "outside_south_zone", "bridge_zone", "enter_south_zone", true );
	add_adjacent_zone( "outside_south_zone", "wnuen_bridge_zone", "enter_south_zone", true );

	add_adjacent_zone( "tp_south_zone", "bridge_zone", "enter_tp_south", true );
	add_adjacent_zone( "tp_south_zone", "wnuen_bridge_zone", "enter_tp_south", true );

	add_zone_flags(	"enter_warehouse_second_floor", "enter_south_zone" );
	add_zone_flags(	"enter_wnuen_loading_dock", "enter_south_zone" );

	//level thread link_zones_after_door_is_opened();
}

link_zones_after_door_is_opened()
{
	flag_wait("enter_wnuen_building");
	add_zone_flags(	"enter_tp_east", "enter_wnuen_building" );
}


//
//	Intro Chyron!
intro_screen()
{

	flag_wait( "all_players_connected" );
	wait(2);
	level.intro_hud = [];
	for(i = 0;  i < 3; i++)
	{
		level.intro_hud[i] = newHudElem();
		level.intro_hud[i].x = 0;
		level.intro_hud[i].y = 0;
		level.intro_hud[i].alignX = "left";
		level.intro_hud[i].alignY = "bottom";
		level.intro_hud[i].horzAlign = "left";
		level.intro_hud[i].vertAlign = "bottom";
		level.intro_hud[i].foreground = true;

		if ( level.splitscreen && !level.hidef )
		{
			level.intro_hud[i].fontScale = 2.75;
		}
		else
		{
			level.intro_hud[i].fontScale = 1.75;
		}
		level.intro_hud[i].alpha = 0.0;
		level.intro_hud[i].color = (1, 1, 1);
		level.intro_hud[i].inuse = false;
	}
	level.intro_hud[0].y = -110;
	level.intro_hud[1].y = -90;
	level.intro_hud[2].y = -70;


	level.intro_hud[0] settext(&"WAW_ZOMBIE_INTRO_FACTORY_LEVEL_PLACE");
	level.intro_hud[1] settext("");
	level.intro_hud[2] settext("");
//	level.intro_hud[1] settext(&"WAW_ZOMBIE_INTRO_FACTORY_LEVEL_TIME");
//	level.intro_hud[2] settext(&"WAW_ZOMBIE_INTRO_FACTORY_LEVEL_DATE");

	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] FadeOverTime( 3.5 );
		level.intro_hud[i].alpha = 1;
		wait(1.5);
	}
	wait(1.5);
	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] FadeOverTime( 3.5 );
		level.intro_hud[i].alpha = 0;
		wait(1.5);
	}
	//wait(1.5);
	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] destroy();
	}
}


//-------------------------------------------------------------------
//	Animation functions - need to be specified separately in order to use different animtrees
//-------------------------------------------------------------------
#using_animtree( "waw_zombie_factory" );
script_anims_init()
{
	level.scr_anim[ "half_gate" ]			= %o_zombie_lattice_gate_half;
	level.scr_anim[ "full_gate" ]			= %o_zombie_lattice_gate_full;
	level.scr_anim[ "difference_engine" ]	= %o_zombie_difference_engine_ani;

	level.blocker_anim_func = ::factory_playanim;
}

factory_playanim( animname )
{
	self UseAnimTree(#animtree);
	self animscripted("door_anim", self.origin, self.angles, level.scr_anim[animname] );
}


#using_animtree( "generic_human" );
anim_override_func()
{
		level._zombie_melee[0] 				= %ai_zombie_attack_forward_v1;
		level._zombie_melee[1] 				= %ai_zombie_attack_forward_v2;
		level._zombie_melee[2] 				= %ai_zombie_attack_v1;
		level._zombie_melee[3] 				= %ai_zombie_attack_v2;
		level._zombie_melee[4]				= %ai_zombie_attack_v1;
		level._zombie_melee[5]				= %ai_zombie_attack_v4;
		level._zombie_melee[6]				= %ai_zombie_attack_v6;

		level._zombie_run_melee[0]				=	%ai_zombie_run_attack_v1;
		level._zombie_run_melee[1]				=	%ai_zombie_run_attack_v2;
		level._zombie_run_melee[2]				=	%ai_zombie_run_attack_v3;

		level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v2;
		level.scr_anim["zombie"]["run5"] 	= %ai_zombie_run_v4;
		level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v3;

		level.scr_anim["zombie"]["walk5"] 	= %ai_zombie_walk_v6;
		level.scr_anim["zombie"]["walk6"] 	= %ai_zombie_walk_v7;
		level.scr_anim["zombie"]["walk7"] 	= %ai_zombie_walk_v8;
		level.scr_anim["zombie"]["walk8"] 	= %ai_zombie_walk_v9;
}

lock_additional_player_spawner()
{

	spawn_points = getstructarray("player_respawn_point", "targetname");
	for( i = 0; i < spawn_points.size; i++ )
	{

			spawn_points[i].locked = true;

	}
}

//-------------------------------------------------------------------------------
// handles lowering the bridge when power is turned on
//-------------------------------------------------------------------------------
bridge_init()
{
	flag_init( "bridge_down" );
	// raise bridge
	wnuen_bridge = getent( "wnuen_bridge", "targetname" );
	wnuen_bridge_coils = GetEntArray( "wnuen_bridge_coils", "targetname" );
	for ( i=0; i<wnuen_bridge_coils.size; i++ )
	{
		wnuen_bridge_coils[i] LinkTo( wnuen_bridge );
	}

	if(level.gamemode == "survival")
	{
		wnuen_bridge rotatepitch( 90, 1, .5, .5 );
	}

	warehouse_bridge = getent( "warehouse_bridge", "targetname" );
	warehouse_bridge_coils = GetEntArray( "warehouse_bridge_coils", "targetname" );
	for ( i=0; i<warehouse_bridge_coils.size; i++ )
	{
		warehouse_bridge_coils[i] LinkTo( warehouse_bridge );
	}

	if(level.gamemode == "survival")
	{
		warehouse_bridge rotatepitch( -90, 1, .5, .5 );
	}

	bridge_audio = getstruct( "bridge_audio", "targetname" );

	// wait for power
	flag_wait( "power_on" );

	// lower bridge
	if(level.gamemode == "survival")
	{
		wnuen_bridge rotatepitch( -90, 4, .5, 1.5 );
		warehouse_bridge rotatepitch( 90, 4, .5, 1.5 );
	}

	if(isdefined( bridge_audio ) )
		playsoundatposition( "bridge_lower", bridge_audio.origin );

	wnuen_bridge connectpaths();
	warehouse_bridge connectpaths();

	exploder( 500 );

	// wait until the bridges are down.
	if(level.gamemode == "survival")
	{
		wnuen_bridge waittill( "rotatedone" );
	}

	flag_set( "bridge_down" );
	if(isdefined( bridge_audio ) )
		playsoundatposition( "bridge_hit", bridge_audio.origin );

	wnuen_bridge_clip = getent( "wnuen_bridge_clip", "targetname" );
	wnuen_bridge_clip delete();

	warehouse_bridge_clip = getent( "warehouse_bridge_clip", "targetname" );
	warehouse_bridge_clip delete();

	maps\_zombiemode_zone_manager::connect_zones( "wnuen_bridge_zone", "bridge_zone" );
	//maps\_zombiemode_zone_manager::connect_zones( "warehouse_top_zone", "bridge_zone" );
}

jump_from_bridge()
{
	trig = GetEnt( "trig_outside_south_zone", "targetname" );
	trig waittill( "trigger" );

	maps\_zombiemode_zone_manager::connect_zones( "outside_south_zone", "bridge_zone", true );
	maps\_zombiemode_zone_manager::connect_zones( "outside_south_zone", "wnuen_bridge_zone", true );
}

init_sounds()
{
	maps\_zombiemode_utility::add_sound( "break_stone", "break_stone" );
	maps\_zombiemode_utility::add_sound( "gate_door",	"zmb_gate_slide_open" );
	maps\_zombiemode_utility::add_sound( "heavy_door",	"zmb_heavy_door_open" );

	// override the default slide with the buzz slide
	maps\_zombiemode_utility::add_sound("door_slide_open", "door_slide_open");
}

// Include the weapons that are only inr your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
include_weapons()
{
	include_weapon("m1911_zm", false);
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
	include_weapon("crossbow_explosive_zm");
	include_weapon("knife_ballistic_zm");
	include_weapon("knife_ballistic_bowie_zm", false);

	include_weapon("m1911_upgraded_zm", false);
	include_weapon("python_upgraded_zm", false);
	include_weapon("cz75_upgraded_zm", false);
	include_weapon("g11_lps_upgraded_zm", false);
	include_weapon("famas_upgraded_zm", false);
	include_weapon("spectre_upgraded_zm", false);
	include_weapon("cz75dw_upgraded_zm", false);
	include_weapon("spas_upgraded_zm", false);
	include_weapon("hs10_upgraded_zm", false);
	include_weapon("aug_acog_mk_upgraded_zm", false);
	include_weapon("galil_upgraded_zm", false);
	include_weapon("commando_upgraded_zm", false);
	include_weapon("fnfal_upgraded_zm", false);
	include_weapon("dragunov_upgraded_zm", false);
	include_weapon("l96a1_upgraded_zm", false);
	include_weapon("rpk_upgraded_zm", false);
	include_weapon("hk21_upgraded_zm", false);
	include_weapon("m72_law_upgraded_zm", false);
	include_weapon("china_lake_upgraded_zm", false);
	include_weapon("crossbow_explosive_upgraded_zm", false);
	include_weapon("knife_ballistic_upgraded_zm", false);
	include_weapon("knife_ballistic_bowie_upgraded_zm", false);


	// Bolt Action
	include_weapon( "zombie_kar98k", false, true );
	include_weapon( "zombie_kar98k_upgraded", false );

	// Semi Auto
	include_weapon( "zombie_m1carbine", false, true );
	include_weapon( "zombie_m1carbine_upgraded", false );
	include_weapon( "zombie_gewehr43", false, true );
	include_weapon( "zombie_gewehr43_upgraded", false );

	// Full Auto
	include_weapon( "zombie_stg44", false, true );
	include_weapon( "zombie_stg44_upgraded", false );
	include_weapon( "zombie_thompson", false, true );
	include_weapon( "zombie_thompson_upgraded", false );
	include_weapon( "mp40_zm", false, true );
	include_weapon( "mp40_upgraded_zm", false );
	include_weapon( "zombie_type100_smg", false, true );
	include_weapon( "zombie_type100_smg_upgraded", false );

	// Grenade
	include_weapon( "stielhandgranate", false, true );

	// Shotgun
	include_weapon( "zombie_doublebarrel", false, true );
	include_weapon( "zombie_doublebarrel_upgraded", false );
	include_weapon( "zombie_shotgun", false, true );
	include_weapon( "zombie_shotgun_upgraded", false );

	include_weapon( "zombie_fg42", false, true );
	include_weapon( "zombie_fg42_upgraded", false );

	// Special
	include_weapon( "ray_gun_zm", true, false, ::factory_ray_gun_weighting_func );
	include_weapon( "ray_gun_upgraded_zm", false );
	include_weapon( "tesla_gun_zm", true );
	include_weapon( "tesla_gun_upgraded_zm", false );
	include_weapon( "zombie_cymbal_monkey", true, false, ::factory_cymbal_monkey_weighting_func );

	//bouncing betties
	include_weapon("mine_bouncing_betty", false, true);

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "m1911_zm", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "tesla_gun_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "crossbow_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "knife_ballistic_zm", 1 );

	level._uses_retrievable_ballisitic_knives = true;

	precacheItem( "explosive_bolt_zm" );
	precacheItem( "explosive_bolt_upgraded_zm" );

	// get the bowie into the collector achievement list
	level.collector_achievement_weapons = array_add( level.collector_achievement_weapons, "bowie_knife_zm" );



	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_kar98k", "zombie_kar98k_upgraded", 						&"WAW_ZOMBIE_WEAPON_KAR98K_200", 				200,	"rifle");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_type99_rifle", "",					&"WAW_ZOMBIE_WEAPON_TYPE99_200", 			    200,	"rifle" );

	// Semi Auto
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_gewehr43", "zombie_gewehr43_upgraded",						&"WAW_ZOMBIE_WEAPON_GEWEHR43_600", 				600,	"rifle" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_m1carbine","zombie_m1carbine_upgraded",						&"WAW_ZOMBIE_WEAPON_M1CARBINE_600",				600,	"rifle" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_m1garand", "zombie_m1garand_upgraded" ,						&"WAW_ZOMBIE_WEAPON_M1GARAND_600", 				600,	"rifle" );

	maps\_zombiemode_weapons::add_zombie_weapon( "stielhandgranate", "", 						&"WAW_ZOMBIE_WEAPON_STIELHANDGRANATE_250", 		250,	"grenade", "", 250 );
	maps\_zombiemode_weapons::add_zombie_weapon( "mine_bouncing_betty", "", &"WAW_ZOMBIE_WEAPON_SATCHEL_2000", 2000 );
	// Scoped
	maps\_zombiemode_weapons::add_zombie_weapon( "kar98k_scoped_zombie", "", 					&"WAW_ZOMBIE_WEAPON_KAR98K_S_750", 				750,	"sniper");

	// Full Auto
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_stg44", "zombie_stg44_upgraded", 							    &"WAW_ZOMBIE_WEAPON_STG44_1200", 				1200, "mg" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_thompson", "zombie_thompson_upgraded", 							&"WAW_ZOMBIE_WEAPON_THOMPSON_1200", 			1200, "mg" );
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_type100_smg", "zombie_type100_smg_upgraded", 						&"WAW_ZOMBIE_WEAPON_TYPE100_1000", 				1000, "mg" );

	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_fg42", "zombie_fg42_upgraded", 							&"WAW_ZOMBIE_WEAPON_FG42_1500", 				1500,	"mg" );


	// Shotguns
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_doublebarrel", "zombie_doublebarrel_upgraded", 						&"WAW_ZOMBIE_WEAPON_DOUBLEBARREL_1200", 		1200, "shotgun");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_doublebarrel_sawed", "", 			    &"WAW_ZOMBIE_WEAPON_DOUBLEBARREL_SAWED_1200", 	1200, "shotgun");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_shotgun", "zombie_shotgun_upgraded",							&"WAW_ZOMBIE_WEAPON_SHOTGUN_1500", 				1500, "shotgun");

	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_bar", "zombie_bar_upgraded", 						&"WAW_ZOMBIE_WEAPON_BAR_1800", 					1800,	"mg" );

	// Bipods
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_bar_bipod", 	"",					&"WAW_ZOMBIE_WEAPON_BAR_BIPOD_2500", 			2500,	"mg" );
}


factory_ray_gun_weighting_func()
{
	if( level.chest_moves > 0 )
	{
		num_to_add = 1;
		// increase the percentage of ray gun
		if( isDefined( level.pulls_since_last_ray_gun ) )
		{
			// after 12 pulls the ray gun percentage increases to 15%
			if( level.pulls_since_last_ray_gun > 11 )
			{
				num_to_add += int(level.zombie_include_weapons.size*0.1);
			}
			// after 8 pulls the Ray Gun percentage increases to 10%
			else if( level.pulls_since_last_ray_gun > 7 )
			{
				num_to_add += int(.05 * level.zombie_include_weapons.size);
			}
		}
		return num_to_add;
	}
	else
	{
		return 0;
	}
}


//
//	Slightly elevate the chance to get it until someone has it, then make it even
factory_cymbal_monkey_weighting_func()
{
	players = get_players();
	count = 0;
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] maps\_zombiemode_weapons::has_weapon_or_upgrade( "zombie_cymbal_monkey" ) )
		{
			count++;
		}
	}
	if ( count > 0 )
	{
		return 1;
	}
	else
	{
		if( level.round_number < 10 )
		{
			return 3;
		}
		else
		{
			return 5;
		}
	}
}


include_powerups()
{
	include_powerup( "nuke" );
	include_powerup( "insta_kill" );
	include_powerup( "double_points" );
	include_powerup( "full_ammo" );
	include_powerup( "carpenter" );
}



////turn on all of the perk machines
//activate_vending_machines()
//{
//	//activate perks-a-cola
//	//level notify( "master_switch_activated" );
//
//	//level notify( "specialty_armorvest_power_on" );
//	//level notify( "specialty_rof_power_on" );
//	//level notify( "specialty_quickrevive_power_on" );
//	//level notify( "specialty_fastreload_power_on" );
//
//	//clientnotify("revive_on");
//	//clientnotify("middle_door_open");
//	//clientnotify("fast_reload_on");
//	//clientnotify("doubletap_on");
//	//clientnotify("jugger_on");
//
//}
//
//
//#using_animtree( "generic_human" );
//force_zombie_crawler()
//{
//	if( !IsDefined( self ) )
//	{
//		return;
//	}
//
//	if( !self.gibbed )
//	{
//		refs = [];
//
//		refs[refs.size] = "no_legs";
//
//		if( refs.size )
//		{
//			self.a.gib_ref = animscripts\death::get_random( refs );
//
//			// Don't stand if a leg is gone
//			self.has_legs = false;
//			self AllowedStances( "crouch" );
//
//			which_anim = RandomInt( 5 );
//
//			if( which_anim == 0 )
//			{
//				self.deathanim = %ai_zombie_crawl_death_v1;
//				self set_run_anim( "death3" );
//				self.run_combatanim = level.scr_anim["zombie"]["crawl1"];
//				self.crouchRunAnim = level.scr_anim["zombie"]["crawl1"];
//				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl1"];
//			}
//			else if( which_anim == 1 )
//			{
//				self.deathanim = %ai_zombie_crawl_death_v2;
//				self set_run_anim( "death4" );
//				self.run_combatanim = level.scr_anim["zombie"]["crawl2"];
//				self.crouchRunAnim = level.scr_anim["zombie"]["crawl2"];
//				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl2"];
//			}
//			else if( which_anim == 2 )
//			{
//				self.deathanim = %ai_zombie_crawl_death_v1;
//				self set_run_anim( "death3" );
//				self.run_combatanim = level.scr_anim["zombie"]["crawl3"];
//				self.crouchRunAnim = level.scr_anim["zombie"]["crawl3"];
//				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl3"];
//			}
//			else if( which_anim == 3 )
//			{
//				self.deathanim = %ai_zombie_crawl_death_v2;
//				self set_run_anim( "death4" );
//				self.run_combatanim = level.scr_anim["zombie"]["crawl4"];
//				self.crouchRunAnim = level.scr_anim["zombie"]["crawl4"];
//				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl4"];
//			}
//			else if( which_anim == 4 )
//			{
//				self.deathanim = %ai_zombie_crawl_death_v1;
//				self set_run_anim( "death3" );
//				self.run_combatanim = level.scr_anim["zombie"]["crawl5"];
//				self.crouchRunAnim = level.scr_anim["zombie"]["crawl5"];
//				self.crouchrun_combatanim = level.scr_anim["zombie"]["crawl5"];
//			}
//		}
//
//		if( self.health > 50 )
//		{
//			self.health = 50;
//
//			// force gibbing if the zombie is still alive
//			self thread animscripts\death::do_gib();
//		}
//	}
//}
//
//
//
//	This initialitze the box spawn locations
//	You can disable boxes from appearing by not adding their script_noteworthy ID to the list
//
magic_box_init()
{
	//MM - all locations are valid.  If it goes somewhere you haven't opened, you need to open it.
	level.open_chest_location = [];
	level.open_chest_location[0] = "chest1";	// TP East
	level.open_chest_location[1] = "chest2";	// TP West
	level.open_chest_location[2] = "chest3";	// TP South
	level.open_chest_location[3] = "chest4";	// WNUEN
	level.open_chest_location[4] = "chest5";	// Warehouse bottom
	level.open_chest_location[5] = "start_chest";
}


/*------------------------------------
the electric switch under the bridge
once this is used, it activates other objects in the map
and makes them available to use
------------------------------------*/
power_electric_switch()
{
	trig = getent("use_power_switch","targetname");
	master_switch = getent("power_switch","targetname");
	master_switch notsolid();
	//master_switch rotatepitch(90,1);
	trig sethintstring(&"ZOMBIE_ELECTRIC_SWITCH");
	trig SetCursorHint( "HINT_NOICON" );

	//turn off the buyable door triggers for electric doors
// 	door_trigs = getentarray("electric_door","script_noteworthy");
// 	array_thread(door_trigs,::set_door_unusable);
// 	array_thread(door_trigs,::play_door_dialog);

	cheat = false;

/#
	if( GetDvarInt( "zombie_cheat" ) >= 3 )
	{
		wait( 5 );
		cheat = true;
	}
#/

	user = undefined;
	if ( cheat != true )
	{
		trig waittill("trigger",user);
	}

	// MM - turning on the power powers the entire map
// 	if ( IsDefined(user) )	// only send a notify if we weren't originally triggered through script
// 	{
// 		other_trig = getent("use_warehouse_switch","targetname");
// 		other_trig notify( "trigger", undefined );
//
// 		wuen_trig = getent("use_wuen_switch", "targetname" );
// 		wuen_trig notify( "trigger", undefined );
// 	}

	trig delete();

	master_switch rotateroll(-90,.3);

	//TO DO (TUEY) - kick off a 'switch' on client script here that operates similiarly to Berlin2 subway.
	master_switch playsound("zmb_switch_flip");
	flag_set( "power_on" );
	wait_network_frame();
	level notify( "sleight_on" );
	wait_network_frame();
	level notify( "revive_on" );
	wait_network_frame();
	level notify( "doubletap_on" );
	wait_network_frame();
	level notify( "juggernog_on" );
	wait_network_frame();
	level notify( "Pack_A_Punch_on" );
	wait_network_frame();
	level notify( "specialty_armorvest_power_on" );
	wait_network_frame();
	level notify( "specialty_rof_power_on" );
	wait_network_frame();
	level notify( "specialty_quickrevive_power_on" );
	wait_network_frame();
	level notify( "specialty_fastreload_power_on" );
	wait_network_frame();

//	clientnotify( "power_on" );
	clientnotify("ZPO");	// Zombie Power On!
	wait_network_frame();
	exploder(600);

	playfx(level._effect["switch_sparks"] ,getstruct("power_switch_fx","targetname").origin);

	// Don't want east or west to spawn when in south zone, but vice versa is okay
	flag_wait_any("enter_outside_east", "enter_outside_west");
	maps\_zombiemode_zone_manager::connect_zones( "outside_east_zone", "outside_south_zone" );
	maps\_zombiemode_zone_manager::connect_zones( "outside_west_zone", "outside_south_zone" );
}


/**********************
Electrical trap
**********************/
init_elec_trap_trigs()
{
	//trap_trigs = getentarray("gas_access","targetname");
	//array_thread (trap_trigs,::electric_trap_think);
	//array_thread (trap_trigs,::electric_trap_dialog);
	if ( level.mutators["mutator_noTraps"] )
	{
		maps\_zombiemode_traps::disable_traps(getentarray("warehouse_electric_trap",	"targetname"));
		maps\_zombiemode_traps::disable_traps(getentarray("wuen_electric_trap",	"targetname"));
		maps\_zombiemode_traps::disable_traps(getentarray("bridge_electric_trap",	"targetname"));
	}
	else
	{
		// MM - traps disabled for now
		array_thread( getentarray("warehouse_electric_trap",	"targetname"), ::electric_trap_think, "enter_warehouse_building" );
		array_thread( getentarray("wuen_electric_trap",			"targetname"), ::electric_trap_think, "enter_wnuen_building" );
		array_thread( getentarray("bridge_electric_trap",		"targetname"), ::electric_trap_think, "bridge_down" );
	}

}

electric_trap_dialog()
{

	self endon ("warning_dialog");
	level endon("switch_flipped");
	timer =0;
	while(1)
	{
		wait(0.5);
		players = get_players();
		for(i = 0; i < players.size; i++)
		{
			dist = distancesquared(players[i].origin, self.origin );
			if(dist > 70*70)
			{
				timer = 0;
				continue;
			}
			if(dist < 70*70 && timer < 3)
			{
				wait(0.5);
				timer ++;
			}
			if(dist < 70*70 && timer == 3)
			{
				players[i] maps\_zombiemode_audio::create_and_play_dialog( "general", "intro" );
				wait(3);
				self notify ("warning_dialog");
				//iprintlnbold("warning_given");
			}
		}
	}
}


hint_string( string, i )
{
	if(IsDefined(i))
	{
		self SetHintString( string, i );
	}
	else
	{
		self SetHintString( string );
	}
	//self SetCursorHint( "HINT_NOICON" );

}


/*------------------------------------
	This controls the electric traps in the level
		self = use trigger associated with the trap
------------------------------------*/
electric_trap_think( enable_flag )
{
	self sethintstring(&"ZOMBIE_NEED_POWER");
	self SetCursorHint( "HINT_NOICON" );

	self.zombie_cost = 1000;

	self thread electric_trap_dialog();

	// get a list of all of the other triggers with the same name
	triggers = getentarray( self.targetname, "targetname" );
	flag_wait( "power_on" );

	// Get the damage trigger.  This is the unifying element to let us know it's been activated.
	self.zombie_dmg_trig = getent(self.target,"targetname");
	self.zombie_dmg_trig.in_use = 0;

	// Set buy string
	self sethintstring( &"ZOMBIE_BUTTON_BUY_TRAP", self.zombie_cost );
	self SetCursorHint( "HINT_NOICON" );

	// Getting the light that's related is a little esoteric, but there isn't
	// a better way at the moment.  It uses linknames, which are really dodgy.
	light_name = "";	// scope declaration
	tswitch = getent(self.script_linkto,"script_linkname");
	switch ( tswitch.script_linkname )
	{
	case "10":	// wnuen
	case "11":
		light_name = "zapper_light_wuen";
		break;

	case "20":	// warehouse
	case "21":
		light_name = "zapper_light_warehouse";
		break;

	case "30":	// Bridge
	case "31":
		light_name = "zapper_light_bridge";
		break;
	}

	// The power is now on, but keep it disabled until a certain condition is met
	//	such as opening the door it is blocking or waiting for the bridge to lower.
	if ( !flag( enable_flag ) )
	{
		if(enable_flag == "bridge_down")
		{
			self sethintstring( &"REIMAGINED_TRAP_BRIDGE_EE" );
		}
		else
		{
			self sethintstring( &"REIMAGINED_DOOR_CLOSED" );
		}

		zapper_light_red( light_name );
		flag_wait( enable_flag );
	}

	self sethintstring(&"ZOMBIE_BUTTON_BUY_TRAP", self.zombie_cost );

	// Open for business!
	zapper_light_green( light_name );

	while(1)
	{
		//valve_trigs = getentarray(self.script_noteworthy ,"script_noteworthy");

		//wait until someone uses the valve
		self waittill("trigger",who);
		if( who in_revive_trigger() )
		{
			continue;
		}

		if( is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{
				if(!self.zombie_dmg_trig.in_use)
				{
					self.zombie_dmg_trig.in_use = 1;

					//turn off the valve triggers associated with this trap until available again
					//array_thread (triggers, ::trigger_off);

					array_thread( triggers, ::hint_string, &"REIMAGINED_TRAP_ACTIVE");

					play_sound_at_pos( "purchase", who.origin );
					self thread electric_trap_move_switch(self);

					//set the score
					who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );

					//need to play a 'woosh' sound here, like a gas furnace starting up
					self waittill("switch_activated");

					//this trigger detects zombies walking thru the flames
					self.zombie_dmg_trig trigger_on();

					//play the flame FX and do the actual damage
					self thread activate_electric_trap(who);

					//wait until done and then re-enable the valve for purchase again
					self waittill("elec_done");

					clientnotify(self.script_string +"off");

					//delete any FX ents
					if(isDefined(self.fx_org))
					{
						self.fx_org delete();
					}
					if(isDefined(self.zapper_fx_org))
					{
						self.zapper_fx_org delete();
					}
					if(isDefined(self.zapper_fx_switch_org))
					{
						self.zapper_fx_switch_org delete();
					}

					array_thread(triggers, ::hint_string, &"REIMAGINED_TRAP_COOLDOWN");

					//turn the damage detection trigger off until the flames are used again
			 		self.zombie_dmg_trig trigger_off();
					wait(25);

					// Set buy string
					array_thread(triggers, ::hint_string, &"ZOMBIE_BUTTON_BUY_TRAP", self.zombie_cost );

					//array_thread (triggers, ::trigger_on);

					//COLLIN: Play the 'alarm' sound to alert players that the traps are available again (playing on a temp ent in case the PA is already in use.
					//speakerA = getstruct("loudspeaker", "targetname");
					//playsoundatposition("warning", speakera.origin);
					self notify("available");

					self.zombie_dmg_trig.in_use = 0;
				}
			}
		}
	}
}

//  it's a throw switch
electric_trap_move_switch(parent)
{
	light_name = "";	// scope declaration
	tswitch = getent(parent.script_linkto,"script_linkname");
	switch ( tswitch.script_linkname )
	{
	case "10":	// wnuen
	case "11":
		light_name = "zapper_light_wuen";
		break;

	case "20":	// warehouse
	case "21":
		light_name = "zapper_light_warehouse";
		break;

	case "30":
	case "31":
		light_name = "zapper_light_bridge";
		break;
	}

	//turn the light above the door red
	zapper_light_red( light_name );
	extra_time = tswitch maps\_zombiemode_traps::move_trap_handle(180);
	tswitch playsound("amb_sparks_l_b");
	tswitch waittill("rotatedone");
	if(extra_time > 0)
	{
		wait(extra_time);
	}

	self notify("switch_activated");
	self waittill("available");
	tswitch rotatepitch(-180,.5);
	//turn the light back green once the trap is available again
	zapper_light_green( light_name );
	tswitch waittill("rotatedone");
}

activate_electric_trap(who)
{
	if(isDefined(self.script_string) && self.script_string == "warehouse")
	{
		clientnotify("warehouse");
	}
	else if(isDefined(self.script_string) && self.script_string == "wuen")
	{
		clientnotify("wuen");
	}
	else
	{
		clientnotify("bridge");
	}

	clientnotify(self.target);

	fire_points = getstructarray(self.target,"targetname");

	for(i=0;i<fire_points.size;i++)
	{
		wait_network_frame();
		fire_points[i] thread electric_trap_fx(self);
	}

	//do the damage
	self.zombie_dmg_trig thread elec_barrier_damage(self, who);

	// reset the zapper model
	level waittill("arc_done");
}

electric_trap_fx(notify_ent)
{
	self.tag_origin = spawn("script_model",self.origin);
	//self.tag_origin setmodel("tag_origin");

	//playfxontag(level._effect["zapper"],self.tag_origin,"tag_origin");

	self.tag_origin playsound("zmb_elec_start");
	self.tag_origin playloopsound("zmb_elec_loop");
	self thread play_electrical_sound();

	wait(25);

	self.tag_origin stoploopsound();

	self.tag_origin delete();
	notify_ent notify("elec_done");
	level notify ("arc_done");
}

play_electrical_sound()
{
	level endon ("arc_done");
	while(1)
	{
		wait(randomfloatrange(0.1, 0.5));
		playsoundatposition("zmb_elec_arc", self.origin);
	}


}

elec_barrier_damage(trap, who)
{
	trap endon("elec_done");
	
	while(1)
	{
		self waittill("trigger",ent);

		//player is standing electricity, dumbass
		if(isplayer(ent) )
		{
			ent thread player_elec_damage();
		}
		else
		{
			if(!isDefined(ent.marked_for_death))
			{
				ent.marked_for_death = true;
				ent thread zombie_elec_death( randomint(100), who );
			}
		}
	}
}
play_elec_vocals()
{
	if(IsDefined (self))
	{
		org = self.origin;
		wait(0.15);
		playsoundatposition("zmb_elec_vocals", org);
		playsoundatposition("zmb_zombie_arc", org);
		playsoundatposition("zmb_exp_jib_zombie", org);
	}
}
player_elec_damage()
{
	self endon("death");
	self endon("disconnect");

	if(!IsDefined (level.elec_loop))
	{
		level.elec_loop = 0;
	}

	if( !isDefined(self.is_burning) && !self maps\_laststand::player_is_in_laststand() && self.sessionstate != "spectator" )
	{
		self.is_burning = 1;
		self setelectrified(1.25);
		shocktime = 1.5;
		//Changed Shellshock to Electrocution so we can have different bus volumes.
		self shellshock("electrocution", shocktime);

		if(level.elec_loop == 0)
		{
			elec_loop = 1;
			//self playloopsound ("electrocution");
			self playsound("zmb_zombie_arc");
		}
		
		damage = 0;
		if(!self hasperk("specialty_armorvest"))
		{
			damage = self.health + 100;
		}
		else
		{
			damage = 25;
		}

		radiusdamage(self.origin + (0, 0, 5), 10, damage, damage, undefined, "MOD_UNKNOWN");
		wait 0.1;
		self.is_burning = undefined;
	}
}

zombie_elec_death(flame_chance, who)
{
	self endon("death");

	//10% chance the zombie will burn, a max of 6 burning zombs can be goign at once
	//otherwise the zombie just gibs and dies
	if(flame_chance > 90 && level.burning_zombies.size < 6)
	{
		level.burning_zombies[level.burning_zombies.size] = self;
		self thread zombie_flame_watch();
		self playsound("ignite");
		self thread animscripts\zombie_death::flame_death_fx();
		//wait(randomfloat(1.25));
	}
	else
	{

		refs[0] = "guts";
		refs[1] = "right_arm";
		refs[2] = "left_arm";
		refs[3] = "right_leg";
		refs[4] = "left_leg";
		refs[5] = "no_legs";
		refs[6] = "head";
		self.a.gib_ref = refs[randomint(refs.size)];

		playsoundatposition("zmb_zombie_arc", self.origin);
		if( !self.isdog && randomint(100) > 40 )
		{
			self thread electroctute_death_fx();
			self thread play_elec_vocals();
		}
		//wait(randomfloat(1.25));
		self playsound("zmb_zombie_arc");
	}
	

	self.trap_death = true;
	self.no_powerups = true;
	self dodamage(self.health + 666, self.origin, who);
	//iprintlnbold("should be damaged");
}

zombie_flame_watch()
{
	self waittill("death");
	self stoploopsound();
	level.burning_zombies = array_remove_nokeys(level.burning_zombies,self);
}


//
//	Swaps a cage light model to the red one.
zapper_light_red( lightname )
{
	zapper_lights = getentarray( lightname, "targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_red");

		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}

		//zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_red", 2, "script_model", zapper_lights[i].origin );
		zapper_lights[i].fx = Spawn("script_model", zapper_lights[i].origin);
		zapper_lights[i].fx setmodel("tag_origin");
		zapper_lights[i].fx.angles = zapper_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_notready"],zapper_lights[i].fx,"tag_origin");
	}
}


//
//	Swaps a cage light model to the green one.
zapper_light_green( lightname )
{
	zapper_lights = getentarray( lightname, "targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_green");

		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}

		//zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_green", 2, "script_model", zapper_lights[i].origin );
		zapper_lights[i].fx = Spawn("script_model", zapper_lights[i].origin);
		zapper_lights[i].fx setmodel("tag_origin");
		zapper_lights[i].fx.angles = zapper_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_ready"],zapper_lights[i].fx,"tag_origin");
	}
}


//
//
electroctute_death_fx()
{
	self endon( "death" );


	if (isdefined(self.is_electrocuted) && self.is_electrocuted )
	{
		return;
	}

	self.is_electrocuted = true;

	self thread electrocute_timeout();

	// JamesS - this will darken the burning body
	//self StartTanning();

	if(self.team == "axis")
	{
		level.bcOnFireTime = gettime();
		level.bcOnFireOrg = self.origin;
	}


	PlayFxOnTag( level._effect["elec_torso"], self, "J_SpineLower" );
	self playsound ("zmb_elec_jib_zombie");
	wait 1;

	tagArray = [];
	tagArray[0] = "J_Elbow_LE";
	tagArray[1] = "J_Elbow_RI";
	tagArray[2] = "J_Knee_RI";
	tagArray[3] = "J_Knee_LE";
	tagArray = array_randomize( tagArray );

	PlayFxOnTag( level._effect["elec_md"], self, tagArray[0] );
	self playsound ("elec_jib_zombie");

	wait 1;
	self playsound ("zmb_elec_jib_zombie");

	tagArray[0] = "J_Wrist_RI";
	tagArray[1] = "J_Wrist_LE";
	if( !IsDefined( self.a.gib_ref ) || self.a.gib_ref != "no_legs" )
	{
		tagArray[2] = "J_Ankle_RI";
		tagArray[3] = "J_Ankle_LE";
	}
	tagArray = array_randomize( tagArray );

	PlayFxOnTag( level._effect["elec_sm"], self, tagArray[0] );
	PlayFxOnTag( level._effect["elec_sm"], self, tagArray[1] );

}

electrocute_timeout()
{
	self endon ("death");
	self playloopsound("amb_fire_manager_0");
	// about the length of the flame fx
	wait 12;
	self stoploopsound();
	if (isdefined(self) && isalive(self))
	{
		self.is_electrocuted = false;
		self notify ("stop_flame_damage");
	}

}

//*** AUDIO SECTION ***

check_for_change()
{
	while (1)
	{
		self waittill( "trigger", player );

		if ( player GetStance() == "prone" )
		{
			player maps\_zombiemode_score::add_to_player_score( 25 );
			play_sound_at_pos( "purchase", player.origin );
			break;
		}

		wait(0.1);
	}
}

extra_events()
{
	self UseTriggerRequireLookAt();
	self SetCursorHint( "HINT_NOICON" );
	self waittill( "trigger" );

	targ = GetEnt( self.target, "targetname" );
	if ( IsDefined(targ) )
	{
		targ MoveZ( -10, 5 );
	}
}


//
//	Activate the flytrap!
flytrap()
{
	flag_init( "hide_and_seek" );
	level.flytrap_counter = 0;

	// Hide Easter Eggs...
	// Explosive Monkey
	level thread hide_and_seek_target( "ee_exp_monkey" );
	wait_network_frame();
	level thread hide_and_seek_target( "ee_bowie_bear" );
	wait_network_frame();
	level thread hide_and_seek_target( "ee_perk_bear" );
	wait_network_frame();

	if(level.gamemode != "survival")
	{
		return;
	}

	trig_control_panel = GetEnt( "trig_ee_flytrap", "targetname" );

	// Wait for it to be hit by an upgraded weapon
	upgrade_hit = false;
	while ( !upgrade_hit )
	{
		trig_control_panel waittill( "damage", amount, inflictor, direction, point, type );

		weapon = inflictor getcurrentweapon();
		if ( maps\_zombiemode_weapons::is_weapon_upgraded( weapon ) )
		{
			upgrade_hit = true;
		}
	}

	trig_control_panel playsound( "flytrap_hit" );
	playsoundatposition( "flytrap_creeper", trig_control_panel.origin );
	thread play_sound_2d( "sam_fly_laugh" );
	//iprintlnbold( "Samantha Sez: Hahahahahaha" );

	// Float the objects
//	level achievement_notify("DLC3_ZOMBIE_ANTI_GRAVITY");
	level ClientNotify( "ag1" );	// Anti Gravity ON
	wait(9.0);
	thread play_sound_2d( "sam_fly_act_0" );
	wait(6.0);

	thread play_sound_2d( "sam_fly_act_1" );
	//iprintlnbold( "Samantha Sez: Let's play Hide and Seek!" );

	//	Now find them!
	flag_set( "hide_and_seek" );

	flag_wait( "ee_exp_monkey" );
	flag_wait( "ee_bowie_bear" );
	flag_wait( "ee_perk_bear" );

	level.teleporter_powerups_reward = true;
	wait( 4.0 );

	ss = getstruct( "teleporter_powerup", "targetname" );
	ss thread maps\_zombiemode_powerups::special_powerup_drop(ss.origin, true, true);

	// Colin, play music here.
//	println( "Still Alive" );
}


//
//	Controls hide and seek object and trigger
hide_and_seek_target( target_name )
{
	flag_init( target_name );

	obj_array = GetEntArray( target_name, "targetname" );
	for ( i=0; i<obj_array.size; i++ )
	{
		obj_array[i] Hide();
	}

	trig = GetEnt( "trig_"+target_name, "targetname" );
	trig trigger_off();

	if(level.gamemode != "survival")
	{
		return;
	}

	flag_wait( "hide_and_seek" );

	// Show yourself
	for ( i=0; i<obj_array.size; i++ )
	{
		obj_array[i] Show();
	}
	trig trigger_on();
	trig waittill( "trigger" );

	level.flytrap_counter = level.flytrap_counter + 1;
	thread flytrap_samantha_vox();
	trig playsound( "object_hit" );

	for ( i=0; i<obj_array.size; i++ )
	{
		obj_array[i] Hide();
	}
	flag_set( target_name );
}

phono_egg_init( trigger_name, origin_name )
{
	if(!IsDefined (level.phono_counter))
	{
		level.phono_counter = 0;
	}
	players = getplayers();
	phono_trig = getent ( trigger_name, "targetname");
	phono_origin = getent( origin_name, "targetname");

	if( ( !isdefined( phono_trig ) ) || ( !isdefined( phono_origin ) ) )
	{
		return;
	}

	phono_trig UseTriggerRequireLookAt();
	phono_trig SetCursorHint( "HINT_NOICON" );

	if(level.gamemode != "survival")
	{
		return;
	}

	for(i=0;i<players.size;i++)
	{
		phono_trig waittill( "trigger", players);
		level.phono_counter = level.phono_counter + 1;
		phono_origin play_phono_egg();
	}
}

play_phono_egg()
{
	if(!IsDefined (level.phono_counter))
	{
		level.phono_counter = 0;
	}

	if( level.phono_counter == 1 )
	{
		//iprintlnbold( "Phono Egg One Activated!" );
		self playsound( "phono_one" );
	}
	if( level.phono_counter == 2 )
	{
		//iprintlnbold( "Phono Egg Two Activated!" );
		self playsound( "phono_two" );
	}
	if( level.phono_counter == 3 )
	{
		//iprintlnbold( "Phono Egg Three Activated!" );
		self playsound( "phono_three" );
	}
}

radio_egg_init( trigger_name, origin_name )
{
	players = getplayers();
	radio_trig = getent( trigger_name, "targetname");
	radio_origin = getent( origin_name, "targetname");

	if( ( !isdefined( radio_trig ) ) || ( !isdefined( radio_origin ) ) )
	{
		return;
	}

	radio_trig UseTriggerRequireLookAt();
	radio_trig SetCursorHint( "HINT_NOICON" );

	if(level.gamemode != "survival")
	{
		return;
	}

	radio_origin playloopsound( "radio_static" );

	for(i=0;i<players.size;i++)
	{
		radio_trig waittill( "trigger", players);
		radio_origin stoploopsound( .1 );
		//iprintlnbold( "You activated " + trigger_name + ", playing off " + origin_name );
		radio_origin playsound( trigger_name );
	}
}

play_music_easter_egg(player)
{
	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "egg" );

	wait(4);

	if( IsDefined( player ) )
	{
	    player maps\_zombiemode_audio::create_and_play_dialog( "eggs", "music_activate" );
	}

	wait(260);
	level.music_override = false;
	level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );

	level thread meteor_egg( "meteor_one" );
	level thread meteor_egg( "meteor_two" );
	level thread meteor_egg( "meteor_three" );
}

meteor_egg(trigger_name)
{
	meteor_trig = getent ( trigger_name, "targetname");

	meteor_trig UseTriggerRequireLookAt();
	meteor_trig SetCursorHint( "HINT_NOICON" );

	if(level.gamemode != "survival")
	{
		return;
	}

	meteor_trig PlayLoopSound( "zmb_meteor_loop" );

	meteor_trig waittill( "trigger", player );

	meteor_trig StopLoopSound( 1 );
	player PlaySound( "zmb_meteor_activate" );

	// no meterors in this level
	//player maps\_waw_zombiemode_audio::create_and_play_dialog( "eggs", "meteors", undefined, level.meteor_counter );

	level.meteor_counter = level.meteor_counter + 1;

	if( level.meteor_counter == 3 )
	{
		level.meteor_counter = 0;
	    level thread play_music_easter_egg( player );
	}
}

flytrap_samantha_vox()
{
	if(!IsDefined (level.flytrap_counter))
	{
		level.flytrap_counter = 0;
	}

	if( level.flytrap_counter == 1 )
	{
		//iprintlnbold( "Samantha Sez: Way to go!" );
		thread play_sound_2d( "sam_fly_first" );
	}
	if( level.flytrap_counter == 2 )
	{
		//iprintlnbold( "Samantha Sez: Two? WOW!" );
		thread play_sound_2d( "sam_fly_second" );
	}
	if( level.flytrap_counter == 3 )
	{
		//iprintlnbold( "Samantha Sez: And GAME OVER!" );
		thread play_sound_2d( "sam_fly_last" );
		return;
	}
	wait(0.05);
}

play_giant_mythos_lines()
{
	round = 5;

	wait(10);
	while(1)
	{
		vox_rand = randomintrange(1,100);

		if( level.round_number <= round )
		{
			if( vox_rand <= 2 )
			{
				players = get_players();
				p = randomint(players.size);
				players[p] thread maps\_zombiemode_audio::create_and_play_dialog( "level", "gen_giant" );
				//iprintlnbold( "Just played Gen Giant line off of player " + p );
			}
		}
		else if (level.round_number > round )
		{
			return;
		}
		wait(randomintrange(60,240));
	}
}

play_level_easteregg_vox( object )
{
	percent = 35;

	trig = getent( object, "targetname" );
//	iprintlnbold ("trig = " + trig.targetname);
	if(!isdefined( trig ) )
	{
		return;
	}

	trig UseTriggerRequireLookAt();
	trig SetCursorHint( "HINT_NOICON" );

	if(object == "vox_corkboard_3")
	{
		trig disable_trigger();
		return;
	}

	while(1)
	{
		trig waittill( "trigger", who );

		vox_rand = randomintrange(1,100);

		if( vox_rand <= percent )
		{

			index = maps\_zombiemode_weapons::get_player_index(who);

			switch( object )
			{
				case "vox_corkboard_1":
	//				iprintlnbold( "Inside trigger " + object );
					who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "corkboard_1" );
					break;
				case "vox_corkboard_2":
	//				iprintlnbold( "Inside trigger " + object );
					who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "corkboard_2" );
					break;
				case "vox_corkboard_3":
	//				iprintlnbold( "Inside trigger " + object );
					who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "corkboard_3" );
					break;
				case "vox_teddy":
					if( index != 2 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "teddy" );
					}
					break;
				case "vox_fieldop":
					if( (index != 1) && (index != 3) )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "fieldop" );
					}
					break;
				case "vox_maxis":
					if( index == 3 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "maxis" );
					}
					break;
				case "vox_illumi_1":
					if( index == 3 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "maxis" );
					}
					break;
				case "vox_illumi_2":
					if( index == 3 )
					{
						//iprintlnbold( "Inside trigger " + object );
						who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "maxis" );
					}
					break;
				default:
					return;
			}
		}
		else
		{
			who thread maps\_zombiemode_audio::create_and_play_dialog( "level", "gen_sigh" );
		}
		wait(15);
	}
}

setup_custom_vox()
{
	wait(1);
//	iprintlnbold ("setting up custom vox");

	level.plr_vox["level"]["corkboard_1"] = "resp_corkmap";
	level.plr_vox["level"]["corkboard_2"] = "resp_corkmap";
	level.plr_vox["level"]["corkboard_3"] = "resp_corkmap";
	level.plr_vox["level"]["teddy"] = "resp_teddy";
	level.plr_vox["level"]["fieldop"] = "resp_fieldop";
	level.plr_vox["level"]["maxis"] = "resp_maxis";
	level.plr_vox["level"]["illumi_1"] = "resp_maxis";
	level.plr_vox["level"]["illumi_2"] = "resp_maxis";
	level.plr_vox["level"]["gen_sigh"] = "gen_sigh";
	level.plr_vox["level"]["gen_giant"] = "gen_giant";
	//level.plr_vox["level"]["audio_secret"] = "audio_secret";
	level.plr_vox["level"]["tele_linkall"] = "tele_linkall";
	level.plr_vox["level"]["tele_count"] = "tele_count";
	level.plr_vox["level"]["tele_help"] = "tele_help";
	level.plr_vox["level"]["perk_packa_see"] = "perk_packa_see";
	level.plr_vox["prefix"]	=	"vox_plr_";
}

//-------------------------------------------------------------------------------
// Solo Revive zombie exit points.
//-------------------------------------------------------------------------------
factory_exit_level()
{
	zombies = GetAiArray( "axis" );
	for ( i = 0; i < zombies.size; i++ )
	{
		zombies[i] thread factory_find_exit_point();
	}
}
factory_find_exit_point()
{
	self endon( "death" );

	player = getplayers()[0];

	dist_zombie = 0;
	dist_player = 0;
	dest = 0;

	away = VectorNormalize( self.origin - player.origin );
	endPos = self.origin + vector_scale( away, 600 );

	locs = array_randomize( level.enemy_dog_locations );

	for ( i = 0; i < locs.size; i++ )
	{
		dist_zombie = DistanceSquared( locs[i].origin, endPos );
		dist_player = DistanceSquared( locs[i].origin, player.origin );

		if ( dist_zombie < dist_player )
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

//-------------------------------------------------------------------------------
//	DCS: necessary changes for mature blood settings.
//-------------------------------------------------------------------------------
mature_settings_changes()
{
	if(!is_mature())
	{
		master_switch = getent("power_switch","targetname");
		if(IsDefined(master_switch))
		{
			master_switch SetModel("zombie_power_lever_handle");
		}
	}
}
factory_german_safe()
{
	if(is_german_build())
	{
		dead_guy = GetEnt("hanging_dead_guy","targetname");
		dead_guy Hide();
	}
}

curbs_fix()
{
	collision = spawn("script_model", (-65.359, -1215.74, -192.5));
	collision setmodel("collision_geo_512x512x512");
	collision.angles = (0, 0, 0);
	collision Hide();

	collision2 = spawn("script_model", (393.273, -2099.36, -192.5));
	collision2 setmodel("collision_geo_512x512x512");
	collision2.angles = (0, 0, 0);
	collision2 Hide();

	collision3 = spawn("script_model", (-120, -1129.359, -192.5));
	collision3 setmodel("collision_geo_512x512x512");
	collision3.angles = (0, 0, 0);
	collision3 Hide();

	collision4 = spawn("script_model", (117.604, -1588.69, -1.5));
	collision4 setmodel("collision_geo_128x128x128");
	collision4.angles = (0, 46.5, 0);
	collision4 Hide();

	collision5 = spawn("script_model", (435.5, -1502.5, -0.25));
	collision5 setmodel("collision_geo_128x128x128");
	collision5.angles = (0, 0, 0);
	collision5 Hide();

	collision6 = spawn("script_model", (627.5, -1184.359, -192.5));
	collision6 setmodel("collision_geo_512x512x512");
	collision6.angles = (0, 0, 0);
	collision6 Hide();
}

override_blocker_prices()
{
	zombie_doors = GetEntArray( "zombie_door", "targetname" );
	for( i = 0; i < zombie_doors.size; i++ )
	{
		if( IsDefined( zombie_doors[i].script_flag ) )
		{
			tokens = Strtok( zombie_doors[i].script_flag, "," );
			for ( j=0; j<tokens.size; j++ )
			{
				if(tokens[j] == "enter_warehouse_building" || tokens[j] == "enter_wnuen_building")
				{
					zombie_doors[i].zombie_cost = 1000;
					break;
				}
				else if(tokens[j] == "enter_tp_west")
				{
					zombie_doors[i].zombie_cost = 1250;
					break;
				}
			}
		}
	}

	zombie_debris = GetEntArray( "zombie_debris", "targetname" );
	for( i = 0; i < zombie_debris.size; i++ )
	{
		if( IsDefined( zombie_debris[i].script_flag ) )
		{
			tokens = Strtok( zombie_debris[i].script_flag, "," );
			for ( j=0; j<tokens.size; j++ )
			{
				if(tokens[j] == "enter_warehouse_second_floor" || tokens[j] == "enter_wnuen_loading_dock")
				{
					zombie_debris[i].zombie_cost = 1250;
					break;
				}
			}
		}
	}
}

override_box_locations()
{
	PrecacheModel("p_jun_wood_plank_large01");
	
	level.override_place_treasure_chest_bottom = ::zombie_cod5_factory_place_treasure_chest_bottom;
	level.treasure_box_rubble_model = "zombie_factory_bearpile";

	origin = (-576, 537, 1);
	angles = (0, 270, 0);
	maps\_zombiemode_weapons::place_treasure_chest("mainframe_chest", origin, angles);
}

zombie_cod5_factory_place_treasure_chest_bottom(origin, angles)
{
	forward = AnglesToForward(angles);
	right = AnglesToRight(angles);
	up = AnglesToUp(angles);

	block_model = "zombie_pile_wood_box";
	top_model = "p_jun_wood_plank_large01";

	block1 = Spawn( "script_model", origin + (forward * 35) + (up * -4.25) );
	block1.angles = angles;
	block1 SetModel( block_model );

	block2 = Spawn( "script_model", origin + (forward * 10) + (up * -4.25) );
	block2.angles = angles + (0, 337.5, 0);
	block2 SetModel( block_model );

	block3 = Spawn( "script_model", origin + (forward * -15) + (up * -4.25) );
	block3.angles = angles + (0, 348.75, 0);
	block3 SetModel( block_model );

	block4 = Spawn( "script_model", origin + (forward * -40) + (up * -4.25) );
	block4.angles = angles + (0, 45, 0);
	block4 SetModel( block_model );

	top1 = Spawn( "script_model", origin + (forward * -48) + (right * -8) + (up * 10.5) );
	top1.angles = angles + (0, 90, 90);
	top1 SetModel( top_model );

	top2 = Spawn( "script_model", origin + (forward * -48) + (right * 0) + (up * 10.5) );
	top2.angles = angles + (0, 90, 90);
	top2 SetModel( top_model );

	top3 = Spawn( "script_model", origin + (forward * -48) + (right * 8) + (up * 10.5) );
	top3.angles = angles + (0, 90, 90);
	top3 SetModel( top_model );

	return 13.25;
}