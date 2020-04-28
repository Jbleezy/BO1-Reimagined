
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager; 
//#include maps\_zombiemode_protips;

main()
{
	level thread maps\zombie_cosmodrome_ffotd::main_start();
	
	// viewmodel arms for the level
	PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen

	// Light model cacheing for Gantry

	PreCacheModel("p_rus_rb_lab_warning_light_01");
  	PreCacheModel("p_rus_rb_lab_warning_light_01_off");
  	PreCacheModel("p_rus_rb_lab_light_core_on");
  	PreCacheModel("p_rus_rb_lab_light_core_off");

	//needs to be first for create fx
	maps\zombie_cosmodrome_fx::main();
	maps\zombie_cosmodrome_amb::main();

	PreCacheModel("zombie_lander_crashed");
	cosmodrome_precache();

	//DCS 110210: precache on screen for lander control.
	PreCacheModel("p_zom_cosmo_lunar_control_panel_dlc_on");

	//maps\_zombiemode_powercell::powercell_precache();

	PrecacheString(&"REIMAGINED_DOOR_CLOSED");

	if(GetDvarInt( #"artist") > 0)
	{
		return;
	}

	//test stuff, etc...
	//precachemodel("t5_veh_jet_mig17");
	precachemodel("tag_origin");

	level.player_out_of_playable_area_monitor = true;
	level.player_out_of_playable_area_monitor_callback = ::zombie_cosmodrome_player_out_of_playable_area_monitor_callback;
	maps\zombie_cosmodrome_ai_monkey::init();

	// Setup global_funcs
	maps\zombie_cosmodrome_traps::init_funcs();

	// Set pay turret cost
	level.pay_turret_cost = 1000;
	level.lander_cost	= 250;


	level.random_pandora_box_start = false;

	level thread maps\_callbacksetup::SetupCallbacks();
	
	level.quad_move_speed = 35;

	level.dog_spawn_func = maps\_zombiemode_ai_dogs::dog_spawn_factory_logic;

	// Special zombie types, engineer and quads.
	level.custom_ai_type = [];
	level.custom_ai_type = array_add( level.custom_ai_type, maps\_zombiemode_ai_monkey::init );

	level.door_dialog_function = maps\_zombiemode::play_door_dialog;

	include_weapons();
	include_powerups();

	level.use_zombie_heroes = true;
	level.zombiemode_using_marathon_perk = true;
	level.zombiemode_using_divetonuke_perk = true;

	// Jluyties(02/22/10) added new lunar landing for intro of level.
	// MMaestas - this needs to be defined about _zombiemode::main
	if(GetDvar("zm_gamemode") == "survival")
	{
		level.round_prestart_func = maps\zombie_cosmodrome_lander::new_lander_intro;
	}
	else
	{
		level thread maps\zombie_cosmodrome_lander::skip_new_lander_intro();
	}

	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;
	level.register_offhand_weapons_for_level_defaults_override = ::cosmodrome_offhand_weapon_overrride;
	level.zombiemode_offhand_weapon_give_override = ::offhand_weapon_give_override;

	level.monkey_prespawn = maps\zombie_cosmodrome_ai_monkey::monkey_cosmodrome_prespawn;
	level.monkey_zombie_failsafe = maps\zombie_cosmodrome_ai_monkey::monkey_cosmodrome_failsafe;
	level.max_perks = 5;
	level.max_solo_lives = 3;
	
	// WW (01/14/11) - Start introscreen client notify
	level thread cosmodrome_fade_in_notify();

	// DO ACTUAL ZOMBIEMODE INIT
	maps\_zombiemode::main();
	
	maps\_zombiemode_weap_sickle::init();
	maps\_zombiemode_weap_black_hole_bomb::init();
	maps\_zombiemode_weap_nesting_dolls::init();
	
	// Turn off generic battlechatter - Steve G
	battlechatter_off("allies");
	battlechatter_off("axis");


	level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_MONKEY_LANDER_FX = 12;

	// Init tv screens
	level maps\zombie_cosmodrome_magic_box::magic_box_init();

	// Setup the levels Zombie Zone Volumes

	level.zone_manager_init_func = ::cosmodrome_zone_init;
	init_zones[0] = "centrifuge_zone";
	init_zones[1] = "centrifuge_zone2";
	
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	level thread electric_switch();
	level thread maps\_zombiemode_auto_turret::init();
	level thread maps\zombie_cosmodrome_lander::init();
	level thread maps\zombie_cosmodrome_traps::init_traps();
	level thread setup_water_physics();
	level thread centrifuge_jumpup_fix();
	level thread centrifuge_jumpdown_fix();
	level thread centrifuge_init();
	
	// -- WWILLIAMS: CONTROLS THE PACK A PUNCH RISING SITUATION
	level thread maps\zombie_cosmodrome_pack_a_punch::pack_a_punch_main();

	level thread maps\zombie_cosmodrome_achievement::init();

	level thread maps\zombie_cosmodrome_eggs::init();

	// Set the CosmoDrome Vision Set
	level.zombie_visionset = "zombie_cosmodrome_nopower";
	level thread fx_for_power_path();
	
	level thread spawn_life_brushes();
	level thread spawn_kill_brushes();

	init_sounds();

	level thread maps\zombie_cosmodrome_ffotd::main_end();
}


spawn_life_brushes()
{
	// the rubble by the entrance to the platform lander
	maps\_zombiemode::spawn_life_brush( (-1415, 1540, 0), 180, 100 ); // centrifuge
}


spawn_kill_brushes()
{
	// inside the two walls in the corner by the box on the lander platform
	maps\_zombiemode::spawn_kill_brush( (-1800, 2116, -60), 15, 100 );
	maps\_zombiemode::spawn_kill_brush( (-1872, 2156, -20), 15, 100 );

	// under the 4 landers positions
	maps\_zombiemode::spawn_kill_brush( (-672, -152, -552), 110, 55 ); // centrifuge
	maps\_zombiemode::spawn_kill_brush( (-2272, 1768, -136), 110, 55 ); // platform
	maps\_zombiemode::spawn_kill_brush( (160, -2320, -136), 110, 55 ); // storage
	maps\_zombiemode::spawn_kill_brush( (1760, 1256, 280), 110, 55 ); // catwalk

	// above the 4 landers positions
	maps\_zombiemode::spawn_kill_brush( (-672, -152, 0), 200, 1000 ); // centrifuge
	maps\_zombiemode::spawn_kill_brush( (-2272, 1768, 130), 200, 1000 ); // platform
	maps\_zombiemode::spawn_kill_brush( (160, -2320, 50), 400, 1000 ); // storage
	maps\_zombiemode::spawn_kill_brush( (1760, 1256, 490), 400, 1000 ); // catwalk


// These have been replaced by the "above the 4 lander positions,
// since if we kill the player before the lander starts moving laterally,
// they have no way to fall off onto inaccessible rooftops
//	// low roof by the storage area door (opposite staminup)
//	maps\_zombiemode::spawn_kill_brush( (0, -425, -10), 400, 100 );
//
//	// glass roof of power building
//	maps\_zombiemode::spawn_kill_brush( (-532, 1200, 382), 500, 100 );
//
//	// roof next to railing next to spawn closet on small catwalk above the lander platform
//	maps\_zombiemode::spawn_kill_brush( (-1600, 1200, 25), 30, 100 );
//
//	// small overhang crossing above the entrance to the lander platform
//	maps\_zombiemode::spawn_kill_brush( (-1820, 1815, 130), 330, 100 );
}


zombie_cosmodrome_player_out_of_playable_area_monitor_callback()
{
	if ( is_true( self.lander ) || is_true( self.on_lander_last_stand ) )
	{
		return false;
	}

	return true;
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
fx_for_power_path()
{
	self endon ("power_on");

	// trying out an fx at the end of the cable
	while( 1 )
	{
		PlayFX(level._effect["dangling_wire"], ( -1066, 1024, -72), (0, 0, 1)  ); // first 
		wait (0.3 + RandomFloat(0.5));	
		PlayFX(level._effect["dangling_wire"], ( -900, 1446, -96), (0, 0, 1)  ); // second, perfect 
		wait (0.3 + RandomFloat(0.5));	
		PlayFX(level._effect["dangling_wire"], ( -895, 1442, -52), (0, 0, 1)  ); // second, perfect 
		wait (0.3 + RandomFloat(0.5));	
		//wait (0.3 + RandomFloat(1.5));
	}
	
}
//------------------------------------------------------------------------------
centrifuge_jumpup_fix()
{
	jumpblocker = GetEnt("centrifuge_jumpup", "targetname");
	
	if(!IsDefined(jumpblocker))
	return;
	
	jump_pos = jumpblocker.origin;
	centrifuge_occupied = false;
	
	while(true)
	{
		if(level.zones["centrifuge_zone"].is_occupied && centrifuge_occupied == false)
		{
			jumpblocker MoveX(jump_pos[0] + 64, 0.1);
			jumpblocker DisconnectPaths();
			centrifuge_occupied = true;
		}
		else if(!level.zones["centrifuge_zone"].is_occupied && centrifuge_occupied == true)
		{
			jumpblocker MoveTo(jump_pos, 0.1);
			jumpblocker ConnectPaths();
			centrifuge_occupied = false;
		}		
		wait(1);
	}	
}	
centrifuge_jumpdown_fix()
{
	jumpblocker = GetEnt("centrifuge_jumpdown", "targetname");
	
	if(!IsDefined(jumpblocker))
	return;
	
	jump_pos = jumpblocker.origin;
	centrifuge2_occupied = true;

	while(true)
	{
		if(level.zones["centrifuge_zone2"].is_occupied && centrifuge2_occupied == false)
		{
			jumpblocker MoveX(jump_pos[0] + 64, 0.1);
			jumpblocker DisconnectPaths();
			centrifuge2_occupied = true;
		}
		else if(!level.zones["centrifuge_zone2"].is_occupied && centrifuge2_occupied == true)
		{
			jumpblocker MoveTo(jump_pos, 0.1);
			jumpblocker ConnectPaths();
			centrifuge2_occupied = false;
		}		
		wait(1);
	}	
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
	include_weapon( "zombie_black_hole_bomb", true, false );
	include_weapon( "zombie_nesting_dolls", true, false );
	include_weapon( "ray_gun_zm" );
	include_weapon( "ray_gun_upgraded_zm", false );
	include_weapon( "thundergun_zm" );
	include_weapon( "thundergun_upgraded_zm", false );
	include_weapon( "crossbow_explosive_zm" );
	include_weapon( "crossbow_explosive_upgraded_zm", false );

	include_weapon( "knife_ballistic_zm", true );
	include_weapon( "knife_ballistic_upgraded_zm", false );
	include_weapon( "knife_ballistic_sickle_zm", false );
	include_weapon( "knife_ballistic_sickle_upgraded_zm", false );
	level._uses_retrievable_ballisitic_knives = true;

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "m1911_zm", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "thundergun_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "crossbow_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "knife_ballistic_zm", 1 );
	//maps\_zombiemode_weapons::add_limited_weapon( "zombie_nesting_dolls", 1 );

	precacheItem( "explosive_bolt_zm" );
	precacheItem( "explosive_bolt_upgraded_zm" );
	
	// get the sickle into the collector achievement list
	level.collector_achievement_weapons = array_add( level.collector_achievement_weapons, "sickle_knife_zm" );
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
	
	// minigun
	PreCacheItem( "minigun_zm" );
	
	include_powerup( "minigun" );
	include_powerup( "free_perk" );
}


//
//	ZOMBIEMODE OVERRIDES
//
magic_box_override()
{
	flag_wait( "all_players_connected" );

	players = get_players();
	level.chest_min_move_usage = players.size;

	chest = level.chests[level.chest_index];
	while ( level.chest_accessed < level.chest_min_move_usage )
	{
		chest waittill( "chest_accessed" );
	}

	// Okay it's been accessed, now we need to fake move it.
	chest disable_trigger();

	// SAMANTHA IS BACK!
	chest.chest_lid maps\_zombiemode_weapons::treasure_chest_lid_open();
//	self.chest_user thread maps\_zombiemode_weapons::treasure_chest_move_vo();
	chest thread maps\_zombiemode_weapons::treasure_chest_move();

	wait 0.5;	// we need a wait here before this notify
	level notify("weapon_fly_away_start");
	wait 2;
// 	model MoveZ(500, 4, 3);
// 	model waittill("movedone");
// 	model delete();
	chest notify( "box_moving" );
	level notify("weapon_fly_away_end");
	level.chest_min_move_usage = undefined;
}


//*****************************************************************************
// ZONE INIT
//*****************************************************************************
cosmodrome_zone_init()
{
	// Set flags here for your starting zone if there are any zones that need to be connected from the beginning.
	// For instance, if your 
	flag_init( "centrifuge" );
	flag_set( "centrifuge" );

	// Special init for the graveyard
	//add_adjacent_zone( "graveyard_zone",	"graveyard_lander",	"no_mans_land" );


	//############################################
	// GROUPS: Defining self-contained areas that will always connect when activated
	//	Do not put zones that connect through doorways here.
	//	YOU SHOULD NOT BE CALLING add_zone_flags in this section.
	//############################################

	// Base entrance lander
	add_adjacent_zone( "access_tunnel_zone",	"base_entry_zone",			"base_entry_group" );

	// Storage area
	add_adjacent_zone( "storage_zone",			"storage_zone2",			"storage_group" );

	// Power Building
	add_adjacent_zone( "power_building",		"base_entry_zone2",			"power_group" );

	// Drop-off connection - top of stairs in north path (one way drop)
	add_adjacent_zone( "north_path_zone",  "roof_connector_zone",			"roof_connector_dropoff" );
	
	// open blast doors. 
	add_adjacent_zone( "north_path_zone",		"under_rocket_zone",		"rocket_group" );
	add_adjacent_zone( "control_room_zone",		"under_rocket_zone",		"rocket_group" );
	
	//############################################
	//	Now set the connections that need to be made based on doors being open
	//	Use add_zone_flags to connect any zones defined above.
	//############################################
	add_adjacent_zone( "centrifuge_zone",	"centrifuge_zone2",		"centrifuge" );

	// Centrifuge door 1st floor towards power
	add_adjacent_zone( "centrifuge_zone",	"centrifuge2power_zone",		"centrifuge2power" );
	//add_adjacent_zone( "centrifuge_zone2",	"centrifuge2power_zone",		"centrifuge2power" );


	// Door at 1st floor of power building
	add_adjacent_zone( "base_entry_zone2",	"centrifuge2power_zone",		"power2centrifuge" );
	add_zone_flags(	"power2centrifuge",										"power_group" );

	// Side Tunnel to Centrifuge
	add_adjacent_zone( "access_tunnel_zone",	"centrifuge_zone2",			"tunnel_centrifuge_entry" );
	add_zone_flags(	"tunnel_centrifuge_entry",								"base_entry_group" );

	// Base Entrance
	add_adjacent_zone( "base_entry_zone",		"base_entry_zone2",			"base_entry_2_power" );
	add_zone_flags(	"base_entry_2_power",									"base_entry_group" );
	add_zone_flags(	"base_entry_2_power",									"power_group" );

	// Power Building
 	add_adjacent_zone( "power_building",		"power_building_roof",		"power_interior_2_roof" );
	add_zone_flags(	"power_interior_2_roof",								"power_group" );

	// Door from catwalks to connector zone
	add_adjacent_zone( "north_catwalk_zone3",	"roof_connector_zone",		"catwalks_2_shed" );
	add_zone_flags(	"catwalks_2_shed",										"roof_connector_dropoff" );

	// Tunnel to Storage
	add_adjacent_zone( "access_tunnel_zone",	"storage_zone",				"base_entry_2_storage" );
	add_adjacent_zone( "access_tunnel_zone",	"storage_zone2",			"base_entry_2_storage" );
	add_zone_flags(	"base_entry_2_storage",									"storage_group" );
	add_zone_flags(	"base_entry_2_storage",									"base_entry_group" );

	// Storage Lander
	add_adjacent_zone( "storage_lander_zone",	"storage_zone",				"storage_lander_area" );
	add_adjacent_zone( "storage_lander_zone",	"storage_zone2",			"storage_lander_area" );
	//add_adjacent_zone( "storage_lander_zone",	"access_tunnel_zone",		"storage_lander_area" );

	// Northern passageway to rocket
	add_adjacent_zone( "north_path_zone",		"base_entry_zone2",			"base_entry_2_north_path" );
	add_zone_flags(	"base_entry_2_north_path",								"power_group" );
	add_zone_flags(	"base_entry_2_north_path",								"roof_connector_dropoff" );
	//add_zone_flags(	"base_entry_2_north_path",								"control_room" );

	// Power Building to Catwalks
	add_adjacent_zone( "power_building_roof",	"roof_connector_zone",		"power_catwalk_access" );
	add_zone_flags(	"power_catwalk_access",									"roof_connector_dropoff" );

}

//
////*****************************************************************************
//// PRO TIPS INIT
////*****************************************************************************
//
//protips_init()
//{
////	addProTipTime(	1, 8, "zm_pt_zombie_breakout" );
//
////	AddProTipFlag(	1, 2, "no_mans_land_pro_tip", "zm_pt_enter_nml" );
//
////	addProTipFunction(  1, 2, ::power_cell_pickup, "zm_pt_power_cells" );
////	addProTipPosAngle( 2, 1, (-359, -820, 0), 0.4, 42*5, "zm_pt_facility_entrance" );
////	addProTipPosAngle( 2, 1, (-498, 1838, -107), 0.0, 42*8, "zm_pt_base_entry_zone2" );
//}
//
//
////*****************************************************************************
//// POWERCELL INIT
////*****************************************************************************
//
//powercell_init()
//{
//// 	pack_trigger = GetEnt( "zombie_vending_upgrade", "targetname" );
//// 	pack_trigger trigger_off();
//// 
//// 	// hide the batteries
//// 	for ( i = 1; i <= 4; i++ )
//// 	{
//// 		battery = GetEnt( "pack_battery_0" + i, "targetname" );
//// 		battery hide();
//// 	}
//// 
//// 	level.packBattery = 0;
//// 
//// 	//MM - Pack on power on
//// 	flag_wait( "power_on" );
//// 
//// 	level notify( "powercell_done" );
//// 	level notify( "Pack_A_Punch_on" );
//// 
//// 	door_r = GetEnt( "pack_door_r", "targetname" );
//// 	door_l = GetEnt( "pack_door_l", "targetname" );
//// 
//// 	door_r RotateYaw( 160, 5, 0 );
//// 	door_l RotateYaw( -160, 5, 0 );
//// 
//// 	pack_trigger = GetEnt( "zombie_vending_upgrade", "targetname" );
//// 	pack_trigger trigger_on();
//}

//*****************************************************************************
// POWERCELL DROPOFF
//*****************************************************************************

powercell_dropoff()
{
	level.packBattery++;
	battery = GetEnt( "pack_battery_0" + level.packBattery, "targetname" );
	battery show();

	battery.fx = Spawn( "script_model", battery.origin );
	battery.fx.angles = battery.angles;
	battery.fx SetModel( "tag_origin" );

	playfxontag(level._effect["powercell"],battery.fx,"tag_origin");

// 	if ( level.packBattery == 4 )
// 	{
// 		level notify( "powercell_done" );
// 		level notify( "Pack_A_Punch_on" );
// 
// 		door_r = GetEnt( "pack_door_r", "targetname" );
// 		door_l = GetEnt( "pack_door_l", "targetname" );
// 
// 		door_r RotateYaw( 160, 5, 0 );
// 		door_l RotateYaw( -160, 5, 0 );
// 
// 		pack_trigger = GetEnt( "zombie_vending_upgrade", "targetname" );
// 		pack_trigger trigger_on();
// 	}
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
	
	playsoundatposition( "zmb_poweron_front", (0,0,0) );
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

	level thread maps\zombie_cosmodrome_amb::play_cosmo_announcer_vox( "vox_ann_power_switch" );

	master_switch rotateroll(-90,.3);
	master_switch playsound("zmb_switch_flip");

	flag_set( "lander_power" );


	// Set Perk Machine Notifys
	level notify("revive_on");
	level notify("juggernog_on");
	level notify("sleight_on");
	level notify("doubletap_on");
	level notify("divetonuke_on");
	level notify("marathon_on");
	level notify("Pack_A_Punch_on" );

//	clientnotify( "power_on" );	

	clientnotify("ZPO");	 // Zombie Power On.
	
	//FX associated with turning on the power
	exploder(5401);	


	// Swap to the "power on" vision set
	// level.zombie_visionset = "zombie_cosmodrome";
	// VisionSetNaked( level.zombie_visionset, 2 );
	
	master_switch waittill("rotatedone");
	playfx(level._effect["switch_sparks"] ,getstruct("elec_switch_fx","targetname").origin);
	
	//Sound - Shawn J  - adding temp sound to looping sparks & turning on power sources
	//master_switch playloopsound("amb_sparks_loop");
	master_switch playsound("zmb_turn_on");
	thread maps\zombie_cosmodrome_amb::power_clangs();
}

////////////////////////////////////////////////////////////////////////////

custom_pandora_show_func( anchor, anchorTarget, pieces )
{
	level.pandora_light.angles = (-90, anchorTarget.angles[1] + 180, 0);
	level.pandora_light moveto(anchorTarget.origin, 0.05);
	wait(1);	
	playfx( level._effect["lght_marker_flare"],level.pandora_light.origin );
}

custom_pandora_fx_func()
{
	// Hacked to get it to the start location. DCS
	start_chest = GetEnt("start_chest", "script_noteworthy");
	anchor = GetEnt(start_chest.target, "targetname");
	anchorTarget = GetEnt(anchor.target, "targetname");

	level.pandora_light = Spawn( "script_model", anchorTarget.origin );
	level.pandora_light.angles = anchorTarget.angles + (-90, 0, 0);
	level.pandora_light SetModel( "tag_origin" );
	playfxontag(level._effect["lght_marker"], level.pandora_light, "tag_origin");
}

//*****************************************************************************
// rotating centrifuge (will cause damage later)
//*****************************************************************************
centrifuge_init()
{
	centrifuge = GetEnt("centrifuge", "targetname");
	if(IsDefined(centrifuge))
	{
		//centrifuge link_centrifuge_pieces(); //currently no attachments
		centrifuge centrifuge_rotate();
	}
}	

link_centrifuge_pieces()
{
	pieces = getentarray( self.target, "targetname" );
	if(IsDefined(pieces))
	{
		for ( i = 0; i < pieces.size; i++ )
		{
			pieces[i] linkto( self );
		}
	}
	self thread centrifuge_rotate();
}

centrifuge_rotate()
{
	while(true)
	{
		self rotateyaw( 360, 20 );
		self waittill("rotatedone");
	}	
}

cosmodrome_precache()
{
	PreCacheModel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	
	// ww: therse pieces are used for the magic box televisions. the models are changed in csc
	PreCacheModel( "p_zom_monitor_csm" );
	PreCacheModel( "p_zom_monitor_csm_screen_catwalk" );
	PreCacheModel( "p_zom_monitor_csm_screen_centrifuge" );
	PreCacheModel( "p_zom_monitor_csm_screen_enter" );
	PreCacheModel( "p_zom_monitor_csm_screen_fsale1" );
	PreCacheModel( "p_zom_monitor_csm_screen_fsale2" );
	PreCacheModel( "p_zom_monitor_csm_screen_labs" );
	PreCacheModel( "p_zom_monitor_csm_screen_logo" );
	PreCacheModel( "p_zom_monitor_csm_screen_obsdeck" );
	PreCacheModel( "p_zom_monitor_csm_screen_off" );
	PreCacheModel( "p_zom_monitor_csm_screen_on" );
	PreCacheModel( "p_zom_monitor_csm_screen_warehouse" );
	PreCacheModel( "p_zom_monitor_csm_screen_storage" );
	PreCacheModel( "p_zom_monitor_csm_screen_topack" );
	
	//DCS; screens for rocket launch
	PreCacheModel("p_zom_key_console_01");
	PreCacheModel("p_zom_rocket_sign_02");
	PreCacheModel("p_zom_rocket_sign_03");
	PreCacheModel("p_zom_rocket_sign_04");
	
	PreCacheRumble( "damage_heavy" ); // rumble for centrifuge
}	

precache_player_model_override()
{
	mptype\player_t5_zm_cosmodrome::precache();
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
			character\c_usa_dempsey_dlc2::main();// Dempsy
			break;
		case 1:
			character\c_rus_nikolai_dlc2::main();// Nikolai
			break;
		case 2:
			character\c_jap_takeo_dlc2::main();// Takeo
			break;
		case 3:
			character\c_ger_richtofen_dlc2::main();// Richtofen
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
// -- Offhand weapon override for cosmodrome
cosmodrome_offhand_weapon_overrride()
{
	register_lethal_grenade_for_level( "frag_grenade_zm" );
	level.zombie_lethal_grenade_player_init = "frag_grenade_zm";

	register_tactical_grenade_for_level( "zombie_black_hole_bomb" );
	register_tactical_grenade_for_level( "zombie_nesting_dolls" );
	level.zombie_tactical_grenade_player_init = undefined;

	register_placeable_mine_for_level( "claymore_zm" );
	level.zombie_placeable_mine_player_init = undefined;

	register_melee_weapon_for_level( "knife_zm" );
	register_melee_weapon_for_level( "sickle_knife_zm" );
	level.zombie_melee_weapon_player_init = "knife_zm";
}

// -- gives the player a black hole bomb when it comes out of the box
offhand_weapon_give_override( str_weapon )
{
	self endon( "death" );
	
	if( is_tactical_grenade( str_weapon ) && IsDefined( self get_player_tactical_grenade() ) && !self is_player_tactical_grenade( str_weapon ) )
	{
		self SetWeaponAmmoClip( self get_player_tactical_grenade(), 0 );
		self TakeWeapon( self get_player_tactical_grenade() );
	}
	
	if( str_weapon == "zombie_black_hole_bomb" )
	{
		self maps\_zombiemode_weap_black_hole_bomb::player_give_black_hole_bomb();
		//self maps\_zombiemode_weapons::play_weapon_vo( str_weapon ); // ww: need to figure out how we will get the sound here
		return true;
	}
	
	if( str_weapon == "zombie_nesting_dolls" )
	{
		self maps\_zombiemode_weap_nesting_dolls::player_give_nesting_dolls();
		//self maps\_zombiemode_weapons::play_weapon_vo( str_weapon ); // ww: need to figure out how we will get the sound here
		return true;
	}

	return false;
}


init_sounds()
{
	maps\_zombiemode_utility::add_sound( "electric_metal_big", "zmb_heavy_door_open" );
	maps\_zombiemode_utility::add_sound( "gate_swing", "zmb_door_fence_open" );
	maps\_zombiemode_utility::add_sound( "electric_metal_small", "zmb_lab_door_slide" );
	maps\_zombiemode_utility::add_sound( "gate_slide", "zmb_cosmo_gate_slide" );
	maps\_zombiemode_utility::add_sound( "door_swing", "zmb_cosmo_door_swing" );
}

// WW (01/14/11): Watches for notify of screen fade in from _zombiemode_until. After recieving the notify from server a clientnotify is
// broadcast so the slients know when to start changing their beginning vision set
cosmodrome_fade_in_notify()
{
	// wait for fade_in function to finish
	level waittill("fade_in_complete");
	
	// notify client -- "Zombie Introscreen Done"
	level ClientNotify( "ZID" );
	
	wait_network_frame();
}