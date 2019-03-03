#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

init()
{
	PrecacheRumble( "explosion_generic" );

	init_monkey_zombie_anims();

	level._effect["monkey_groundhit"] = loadfx("maps/zombie/fx_zmb_monkey_ground_hit");
	level._effect["monkey_death"] = loadfx("maps/zombie/fx_zmb_monkey_death");
	level._effect["monkey_spawn"] =		loadfx("maps/zombie/fx_zombie_ape_spawn_dust");
	level._effect["monkey_eye_glow"] =	LoadFx( "maps/zombie/fx_zmb_monkey_eyes" );

	// Function that will be used to calculate the value of different spawners when choosing which to use when spawning new monkey
	// Functions that overload this, should return an int, with a higher value indicating a better spawner
	if( !isDefined( level.monkey_zombie_spawn_heuristic ) )
	{
		level.monkey_zombie_spawn_heuristic = maps\_zombiemode_ai_monkey::monkey_zombie_default_spawn_heuristic;
	}

	if ( !isDefined( level.monkey_zombie_enter_level ) )
	{
		level.monkey_zombie_enter_level = ::monkey_zombie_default_enter_level;
	}

	precacheshellshock( "electrocution" );

	// Number of current active monkey zombies
	level.num_monkey_zombies = 0;

	level.monkey_zombie_spawners = GetEntArray( "monkey_zombie_spawner", "targetname" );
	array_thread( level.monkey_zombie_spawners, ::add_spawn_function, maps\_zombiemode_ai_monkey::monkey_prespawn );

	// Counters and timers used by the monkey, can be overloaded on a level by level basis
	if ( !isDefined( level.max_monkey_zombies ) )
	{
		level.max_monkey_zombies = 1;
	}
	if ( !isDefined( level.monkey_zombie_min_health ) )
	{
		level.monkey_zombie_min_health = 150;
	}
	if ( !isDefined( level.monkey_zombie_groundhit_damage ) )
	{
		level.monkey_zombie_groundhit_damage = 100;
	}
	if ( !isDefined( level.monkey_zombie_groundhit_trigger_radius ) )
	{
		level.monkey_zombie_groundhit_trigger_radius = 96;
	}
	if ( !isDefined( level.monkey_zombie_groundhit_damage_radius ) )
	{
		level.monkey_zombie_groundhit_damage_radius = 280;
	}
	if ( !isDefined( level.monkey_ground_attack_delay ) )
	{
		level.monkey_ground_attack_delay = 5000;
	}

	if ( !isdefined( level.monkeys_per_pack ) )
	{
		level.monkeys_per_pack = 3;
	}
	if ( !isDefined( level.monkey_pack_max ) )
	{
		level.monkey_pack_max = 1;
	}
	if ( !isdefined( level.monkey_pack ) )
	{
		level.monkey_pack = [];
	}
	if ( !isdefined( level.machine_health_max ) )
	{
		level.machine_health_max = 100;
	}
	if ( !isdefined( level.machine_damage_min ) )
	{
		level.machine_damage_min = 5;		// damage monkey does when player isn't around
	}
	if ( !isdefined( level.machine_damage_max ) )
	{
		level.machine_damage_max = 10;		// damage monkey does once player enters the zone
	}
	if ( !isdefined( level.ground_hit_delay ) )
	{
		level.ground_hit_delay = RandomFloatRange( 4.5, 6.5 ) * 1000;
	}

	//level thread monkey_zombie_manager();
	level.monkey_death = 0;
	level.monkey_death_total = 0;
	level.monkey_packs_killed = 0;

	level.monkey_encounters = 1;

	level.monkey_intermission = false;
	flag_init( "monkey_round" );
	flag_init( "last_monkey_down" );
	flag_init( "monkey_pack_down" );
	flag_init( "perk_bought" );
	flag_init( "monkey_free_perk" );

	level thread monkey_round_tracker();

	level.perk_lost_func = ::monkey_perk_lost;
	level.perk_bought_func = ::monkey_perk_bought;
	level.revive_solo_fx_func = ::monkey_revive_solo_fx;
}

#using_animtree( "generic_human" );
monkey_prespawn()
{
	self.animname = "monkey_zombie";

	self.custom_idle_setup = maps\_zombiemode_ai_monkey::monkey_zombie_idle_setup;

	self.a.idleAnimOverrideArray = [];
	self.a.idleAnimOverrideArray["stand"] = [];
	self.a.idleAnimOverrideWeights["stand"] = [];
	self.a.idleAnimOverrideArray["stand"][0][0] 	= %ai_zombie_monkey_idle_01;
	self.a.idleAnimOverrideWeights["stand"][0][0] 	= 10;
	self.a.idleAnimOverrideArray["stand"][0][1] 	= %ai_zombie_monkey_idle_01;
	self.a.idleAnimOverrideWeights["stand"][0][1] 	= 10;

	rand = randomIntRange( 1, 4 );
	self.deathanim = level.scr_anim["monkey_zombie"]["death"+rand];

	self.ignorelocationaldamage = true;
	self.ignoreall = true;
	self.allowdeath = true; 			// allows death during animscripted calls
	self.is_zombie = true; 			// needed for melee.gsc in the animscripts
	self.has_legs = true; 			// Sumeet - This tells the zombie that he is allowed to stand anymore or not, gibbing can take
															// out both legs and then the only allowed stance should be prone.
	self allowedStances( "stand" );

	self.gibbed = false;
	self.head_gibbed = false;

	// might need this so co-op zombie players cant block zombie pathing
	self PushPlayer( true );

	self.disableArrivals = true;
	self.disableExits = true;
	self.grenadeawareness = 0;
	self.badplaceawareness = 0;

	self.ignoreSuppression = true;
	self.suppressionThreshold = 1;
	self.noDodgeMove = true;
	self.dontShootWhileMoving = true;
	self.pathenemylookahead = 0;

	self.badplaceawareness = 0;
	self.chatInitialized = false;

	self.a.disablePain = true;
	self disable_react(); // SUMEET - zombies dont use react feature.

	self.freezegun_damage = 0;

	self.dropweapon = false;
	self thread maps\_zombiemode_spawner::zombie_damage_failsafe();

	self thread maps\_zombiemode_spawner::delayed_zombie_eye_glow();	// delayed eye glow for ground crawlers (the eyes floated above the ground before the anim started)
	self.flame_damage_time = 0;
	self.meleeDamage = 40;
	self.no_powerups = true;
	self.no_gib = 1;

	self.custom_damage_func = ::monkey_custom_damage;

	self.chest_beat = false;
	self.machine_damage = level.machine_damage_min;

	self setPhysParams( 24, 0, 24 );
	self.dropped = true;

	self setTeamForEntity( "axis" );

	self AllowPitchAngle( 1 );

	self.thundergun_fling_func = ::monkey_fling;

	self monkey_zombie_set_state( "default" );
	self.noChangeDuringMelee = true;

	if ( isDefined( level.monkey_prespawn ) )
	{
		self [[ level.monkey_prespawn ]]();
	}

	self notify( "zombie_init_done" );
}

//-----------------------------------------------------------------
// setup idles
//-----------------------------------------------------------------
monkey_zombie_idle_setup()
{
	self.a.array["turn_left_45"] = %exposed_tracking_turn45L;
	self.a.array["turn_left_90"] = %exposed_tracking_turn90L;
	self.a.array["turn_left_135"] = %exposed_tracking_turn135L;
	self.a.array["turn_left_180"] = %exposed_tracking_turn180L;
	self.a.array["turn_right_45"] = %exposed_tracking_turn45R;
	self.a.array["turn_right_90"] = %exposed_tracking_turn90R;
	self.a.array["turn_right_135"] = %exposed_tracking_turn135R;
	self.a.array["turn_right_180"] = %exposed_tracking_turn180L;
	self.a.array["exposed_idle"] = array( %ai_zombie_monkey_idle_01, %ai_zombie_monkey_idle_01 );
	self.a.array["straight_level"] = %ai_zombie_monkey_idle_01;
	self.a.array["stand_2_crouch"] = %ai_zombie_shot_leg_right_2_crawl;
}

init_monkey_specific_zombie_anims()
{
	// deaths
	level.scr_anim["monkey_zombie"]["death1"] 	= %ai_zombie_monkey_death_01;
	level.scr_anim["monkey_zombie"]["death2"] 	= %ai_zombie_monkey_death_02;
	level.scr_anim["monkey_zombie"]["death3"] 	= %ai_zombie_monkey_death_03;

	// run cycles
	level.scr_anim["monkey_zombie"]["walk1"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["walk2"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["walk3"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["walk4"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["walk5"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["walk6"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["walk7"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["walk8"] 	= %ai_zombie_monkey_run_01;

	level.scr_anim["monkey_zombie"]["run1"] 	= %ai_zombie_monkey_run_01;
	level.scr_anim["monkey_zombie"]["run2"] 	= %ai_zombie_monkey_run_02;

	level.scr_anim["monkey_zombie"]["sprint1"] = %ai_zombie_monkey_sprint_01;
	level.scr_anim["monkey_zombie"]["sprint2"] = %ai_zombie_monkey_sprint_02;
	level.scr_anim["monkey_zombie"]["sprint3"] = %ai_zombie_monkey_sprint_03;
	level.scr_anim["monkey_zombie"]["sprint4"] = %ai_zombie_monkey_sprint_04;

	level._zombie_melee["monkey_zombie"][0] 				= %ai_zombie_monkey_attack_01;
	level._zombie_melee["monkey_zombie"][1] 				= %ai_zombie_monkey_attack_02;
	level._zombie_melee["monkey_zombie"][2] 				= %ai_zombie_monkey_attack_03;
	level._zombie_melee["monkey_zombie"][3] 				= %ai_zombie_monkey_attack_04;
	level._zombie_melee["monkey_zombie"][4] 				= %ai_zombie_monkey_attack_05;
	level._zombie_melee["monkey_zombie"][5] 				= %ai_zombie_monkey_attack_06;
	level._zombie_melee["monkey_zombie"][6] 				= %ai_zombie_monkey_attack_07;

	level._zombie_run_melee["monkey_zombie"][0]				=	%ai_zombie_monkey_attack_01;
	level._zombie_run_melee["monkey_zombie"][1]				=	%ai_zombie_monkey_attack_02;
	level._zombie_run_melee["monkey_zombie"][2]				=	%ai_zombie_monkey_attack_03;

	level._zombie_deaths["monkey_zombie"] = [];
	level._zombie_deaths["monkey_zombie"][0] = %ai_zombie_monkey_death_01;
	level._zombie_deaths["monkey_zombie"][1] = %ai_zombie_monkey_death_02;
	level._zombie_deaths["monkey_zombie"][2] = %ai_zombie_monkey_death_03;

	level._zombie_board_taunt["monkey_zombie"][0] = %ai_zombie_monkey_taunt_01;
	level._zombie_board_taunt["monkey_zombie"][1] = %ai_zombie_monkey_taunt_02;
	level._zombie_board_taunt["monkey_zombie"][2] = %ai_zombie_monkey_taunt_03;
	level._zombie_board_taunt["monkey_zombie"][3] = %ai_zombie_monkey_taunt_04;
	level._zombie_board_taunt["monkey_zombie"][4] = %ai_zombie_monkey_taunt_05;

	level.monkey_groundpound_anims[0] = %ai_zombie_monkey_groundpound_01;
	level.monkey_groundpound_anims[1] = %ai_zombie_monkey_groundpound_02;
	level.monkey_groundpound_anims[2] = %ai_zombie_monkey_groundpound_03;
	level.monkey_groundpound_anims[3] = %ai_zombie_monkey_groundpound_04;

	level.monkey_perk_attack_anims[0] =	%ai_zombie_monkey_attack_perks_front;
	level.monkey_perk_attack_anims[1] =	%ai_zombie_monkey_attack_perks_left;
	level.monkey_perk_attack_anims[2] =	%ai_zombie_monkey_attack_perks_left_top;
	level.monkey_perk_attack_anims[3] =	%ai_zombie_monkey_attack_perks_right;
	level.monkey_perk_attack_anims[4] =	%ai_zombie_monkey_attack_perks_right_top;

	level.monkey_perk_attack_anims["specialty_armorvest"]["left_top"]		=	%ai_zombie_monkey_attack_perks_left_top_jugg;
	level.monkey_perk_attack_anims["specialty_armorvest"]["right_top"]		=	%ai_zombie_monkey_attack_perks_right_top_jugg;

	level.monkey_perk_attack_anims["specialty_endurance"]["left_top"]	=	%ai_zombie_monkey_attack_perks_left_top_marathon;
	level.monkey_perk_attack_anims["specialty_endurance"]["right_top"]	=	%ai_zombie_monkey_attack_perks_right_top_marathon;

	level.monkey_perk_attack_anims["specialty_quickrevive"]["left_top"]		=	%ai_zombie_monkey_attack_perks_left_top_revive;
	level.monkey_perk_attack_anims["specialty_quickrevive"]["right_top"]	=	%ai_zombie_monkey_attack_perks_right_top_revive;

	level.monkey_perk_attack_anims["specialty_fastreload"]["left_top"]		=	%ai_zombie_monkey_attack_perks_left_top_speed;
	level.monkey_perk_attack_anims["specialty_fastreload"]["right_top"]		=	%ai_zombie_monkey_attack_perks_right_top_speed;

	level.monkey_thundergun_roll_anims[0] = %ai_zombie_monkey_thundergun_roll_01;
	level.monkey_thundergun_roll_anims[1] = %ai_zombie_monkey_thundergun_roll_02;
	level.monkey_thundergun_roll_anims[2] = %ai_zombie_monkey_thundergun_roll_03;
	level.monkey_thundergun_roll_anims[3] = %ai_zombie_monkey_thundergun_roll_04;
}

#using_animtree( "generic_human" );
//-----------------------------------------------------------------
// setup anim tables
//-----------------------------------------------------------------
init_monkey_zombie_anims()
{
	// run cycles in prone
	level.scr_anim["monkey_zombie"]["crawl1"] 	= %ai_zombie_crawl;
	level.scr_anim["monkey_zombie"]["crawl2"] 	= %ai_zombie_crawl_v1;
	level.scr_anim["monkey_zombie"]["crawl3"] 	= %ai_zombie_crawl_v2;
	level.scr_anim["monkey_zombie"]["crawl4"] 	= %ai_zombie_crawl_v3;
	level.scr_anim["monkey_zombie"]["crawl5"] 	= %ai_zombie_crawl_v4;
	level.scr_anim["monkey_zombie"]["crawl6"] 	= %ai_zombie_crawl_v5;
	level.scr_anim["monkey_zombie"]["crawl_hand_1"] = %ai_zombie_walk_on_hands_a;
	level.scr_anim["monkey_zombie"]["crawl_hand_2"] = %ai_zombie_walk_on_hands_b;

	level.scr_anim["monkey_zombie"]["crawl_sprint1"] 	= %ai_zombie_crawl_sprint;
	level.scr_anim["monkey_zombie"]["crawl_sprint2"] 	= %ai_zombie_crawl_sprint_1;
	level.scr_anim["monkey_zombie"]["crawl_sprint3"] 	= %ai_zombie_crawl_sprint_2;

	if( !isDefined( level._zombie_melee ) )
	{
		level._zombie_melee = [];
	}
	if( !isDefined( level._zombie_walk_melee ) )
	{
		level._zombie_walk_melee = [];
	}
	if( !isDefined( level._zombie_run_melee ) )
	{
		level._zombie_run_melee = [];
	}
	level._zombie_melee["monkey_zombie"] = [];
	level._zombie_walk_melee["monkey_zombie"] = [];
	level._zombie_run_melee["monkey_zombie"] = [];

	if( isDefined( level.monkey_zombie_anim_override ) )
	{
		[[ level.monkey_zombie_anim_override ]]();
	}

	//level._zombie_walk_melee["monkey_zombie"][0]			= %ai_zombie_boss_walk_headhit;

	// melee in crawl
	if( !isDefined( level._zombie_melee_crawl ) )
	{
		level._zombie_melee_crawl = [];
	}
	level._zombie_melee_crawl["monkey_zombie"] = [];
	level._zombie_melee_crawl["monkey_zombie"][0] 		= %ai_zombie_attack_crawl;
	level._zombie_melee_crawl["monkey_zombie"][1] 		= %ai_zombie_attack_crawl_lunge;

	if( !isDefined( level._zombie_stumpy_melee ) )
	{
		level._zombie_stumpy_melee = [];
	}
	level._zombie_stumpy_melee["monkey_zombie"] = [];
	level._monkey_zombie_stumpy_melee["monkey_zombie"][0] = %ai_zombie_walk_on_hands_shot_a;
	level._monkey_zombie_stumpy_melee["monkey_zombie"][1] = %ai_zombie_walk_on_hands_shot_b;

	// tesla deaths
	if( !isDefined( level._zombie_tesla_deaths ) )
	{
		level._zombie_tesla_deaths = [];
	}
	level._zombie_tesla_death["monkey_zombie"] = [];
	level._zombie_tesla_death["monkey_zombie"][0] = %ai_zombie_boss_tesla_death_a;
	level._zombie_tesla_death["monkey_zombie"][1] = %ai_zombie_boss_tesla_death_a;
	level._zombie_tesla_death["monkey_zombie"][2] = %ai_zombie_boss_tesla_death_a;
	level._zombie_tesla_death["monkey_zombie"][3] = %ai_zombie_boss_tesla_death_a;
	level._zombie_tesla_death["monkey_zombie"][4] = %ai_zombie_boss_tesla_death_a;

	if( !isDefined( level._zombie_tesla_crawl_death ) )
	{
		level._zombie_tesla_crawl_death = [];
	}
	level._zombie_tesla_crawl_death["monkey_zombie"] = [];
	level._zombie_tesla_crawl_death["monkey_zombie"][0] = %ai_zombie_tesla_crawl_death_a;
	level._zombie_tesla_crawl_death["monkey_zombie"][1] = %ai_zombie_tesla_crawl_death_b;

	// deaths
	if( !isDefined( level._zombie_deaths ) )
	{
		level._zombie_deaths = [];
	}

	/*
	ground crawl
	*/

	// set up the arrays
	if( !isDefined( level._zombie_rise_anims ) )
	{
		level._zombie_rise_anims = [];
	}

	level._zombie_rise_anims["monkey_zombie"] = [];
	level._zombie_rise_anims["monkey_zombie"][1]["walk"][0]		= %ai_zombie_traverse_ground_v1_walk;
	level._zombie_rise_anims["monkey_zombie"][1]["run"][0]		= %ai_zombie_traverse_ground_v1_run;
	level._zombie_rise_anims["monkey_zombie"][1]["sprint"][0]	= %ai_zombie_traverse_ground_climbout_fast;
	level._zombie_rise_anims["monkey_zombie"][2]["walk"][0]		= %ai_zombie_traverse_ground_v2_walk_altA;

	// ground crawl death
	if( !isDefined( level._zombie_rise_death_anims ) )
	{
		level._zombie_rise_death_anims = [];
	}
	level._zombie_rise_death_anims["monkey_zombie"] = [];

	level._zombie_rise_death_anims["monkey_zombie"][1]["in"][0]		= %ai_zombie_traverse_ground_v1_deathinside;
	level._zombie_rise_death_anims["monkey_zombie"][1]["in"][1]		= %ai_zombie_traverse_ground_v1_deathinside_alt;

	level._zombie_rise_death_anims["monkey_zombie"][1]["out"][0]		= %ai_zombie_traverse_ground_v1_deathoutside;
	level._zombie_rise_death_anims["monkey_zombie"][1]["out"][1]		= %ai_zombie_traverse_ground_v1_deathoutside_alt;

	level._zombie_rise_death_anims["monkey_zombie"][2]["in"][0]		= %ai_zombie_traverse_ground_v2_death_low;
	level._zombie_rise_death_anims["monkey_zombie"][2]["in"][1]		= %ai_zombie_traverse_ground_v2_death_low_alt;

	level._zombie_rise_death_anims["monkey_zombie"][2]["out"][0]		= %ai_zombie_traverse_ground_v2_death_high;
	level._zombie_rise_death_anims["monkey_zombie"][2]["out"][1]		= %ai_zombie_traverse_ground_v2_death_high_alt;

	//taunts
	if( !isDefined( level._zombie_run_taunt ) )
	{
		level._zombie_run_taunt = [];
	}
	if( !isDefined( level._zombie_board_taunt ) )
	{
		level._zombie_board_taunt = [];
	}

	level._zombie_run_taunt["monkey_zombie"] = [];
	level._zombie_board_taunt["monkey_zombie"] = [];

	init_monkey_specific_zombie_anims();
}

//-----------------------------------------------------------------
// spawn the zombie
//-----------------------------------------------------------------
monkey_zombie_spawn( pack )
{
	self.script_moveoverride = true;

	if( !isDefined( level.num_monkey_zombies ) )
	{
		level.num_monkey_zombies = 0;
	}
	level.num_monkey_zombies++;

	monkey_zombie = self maps\_zombiemode_net::network_safe_stalingrad_spawn( "monkey_zombie_spawn", 1 );

	self.count = 666;

	self.last_spawn_time = GetTime();

	if( !spawn_failed( monkey_zombie ) )
	{
		monkey_zombie.script_noteworthy = self.script_noteworthy;
		monkey_zombie.targetname = self.targetname;
		monkey_zombie.target = self.target;
		monkey_zombie.deathFunction = maps\_zombiemode_ai_monkey::monkey_zombie_die;
		monkey_zombie.animname = "monkey_zombie";

		monkey_zombie.pack = pack;
		monkey_zombie.perk = pack.perk;
		monkey_zombie.ground_hit_time = pack.ground_hit_time;

		monkey_zombie.spawn_origin = self.origin;
		monkey_zombie.spawn_angles = self.angles;

		monkey_zombie thread monkey_zombie_think();
	}
	else
	{
		level.num_monkey_zombies--;
	}

	return monkey_zombie;
}

//-----------------------------------------------------------------
// handles spawning monkeys during the round
//-----------------------------------------------------------------
monkey_round_spawning()
{
	level endon( "intermission" );
	level endon( "end_of_round" );
	level endon( "restart_round" );

/#
	level endon( "kill_round" );

	if ( GetDvarInt( #"zombie_cheat" ) == 2 || GetDvarInt( #"zombie_cheat" ) >= 4 )
	{
		return;
	}
#/

	if ( level.intermission )
	{
		return;
	}

	level.monkey_intermission = true;
	level thread monkey_round_aftermath();

/*
	max = 1;
	level.zombie_total = max;

	count = 0;
	while( count < max )
	{
		spawner = monkey_zombie_pick_best_spawner();
		if ( isdefined( spawner ) )
		{
			spawner monkey_zombie_spawn();
			level.zombie_total--;
			count++;
			break;
		}
	}
*/
	pack_idx = 0;

	while ( 1 )
	{
		// spawn just 1 pack for now
		level monkey_pack_spawn();

		pack_idx++;
		if ( pack_idx >= level.monkey_pack_max )
		{
			break;
		}

		//flag_wait( "monkey_pack_down" );
		time = RandomFloatRange( 3.2, 4.4 );
		wait( time );

		wait_network_frame();
	}
}

monkey_setup_packs()
{
	level.monkey_packs_killed = 0;

	players = getplayers();

	if ( players.size > level.monkey_encounters )
	{
		level.monkey_pack_max = players.size + level.monkey_encounters;
	}
	else
	{
		level.monkey_pack_max = players.size * 2;
	}

	level.monkey_encounters++;
}

//-----------------------------------------------------------------
// increase half after each encounter
//-----------------------------------------------------------------
monkey_setup_health()
{
	if( level.monkey_encounters == 1 )
	{
		level.monkey_zombie_health = level.monkey_zombie_min_health;
	}
	else if( level.monkey_encounters == 2 )
	{
		level.monkey_zombie_health = 400;
	}
	else if( level.monkey_encounters == 3 )
	{
		level.monkey_zombie_health = 800;
	}
	else if( level.monkey_encounters == 4 )
	{
		level.monkey_zombie_health = 1200;
	}
	else if( level.monkey_encounters == 5 )
	{
		level.monkey_zombie_health = 1600;
	}

	if( level.monkey_zombie_health > 1600 )
	{
		level.monkey_zombie_health = 1600;
	}

	/*switch( level.monkey_encounters )
	{
	case 1:
		level.monkey_zombie_health = level.zombie_health * 0.25;
		break;

	case 2:
		level.monkey_zombie_health = level.zombie_health * 0.5;
		break;

	case 3:
		level.monkey_zombie_health = level.zombie_health * 0.75;
		break;

	default:
		level.monkey_zombie_health = level.zombie_health;
		break;
	}*/

	monkey_print( "monkey health = " + level.monkey_zombie_health );
}

//-----------------------------------------------------------------
// grab the spawners in enabled zones and randomize them
//-----------------------------------------------------------------
monkey_setup_spawners()
{
	level.current_monkey_spawners = [];
	for ( i = 0; i < level.monkey_zombie_spawners.size; i++ )
	{
		if ( level.zones[ level.monkey_zombie_spawners[i].script_noteworthy ].is_enabled )
		{
			level.current_monkey_spawners[ level.current_monkey_spawners.size ] = level.monkey_zombie_spawners[i];
		}
	}

	level.current_monkey_spawners = array_randomize( level.current_monkey_spawners );
	level.monkey_spawner_idx = 0;
}

//-----------------------------------------------------------------
//
//-----------------------------------------------------------------
monkey_get_next_spawner()
{
	spawner = level.current_monkey_spawners[ level.monkey_spawner_idx ];
	assertex( isdefined( spawner ), "no monkey spawner found" );

	if ( isdefined( spawner ) )
	{
		level.monkey_spawner_idx++;
		if ( level.monkey_spawner_idx == level.current_monkey_spawners.size )
		{
			level monkey_setup_spawners();
		}
	}

	return spawner;
}

//-----------------------------------------------------------------
// find spawners that are in enabled zones
//-----------------------------------------------------------------
monkey_get_available_spawners()
{
	spawners = [];
	for ( i = 0; i < level.monkey_zombie_spawners.size; i++ )
	{
		if ( level.zones[ level.monkey_zombie_spawners[i].script_noteworthy ].is_enabled )
		{
			spawners[ spawners.size ] = level.monkey_zombie_spawners[i];
		}
	}

	spawners = array_randomize( spawners );

	return spawners;
}

monkey_pack_man_setup_perks()
{
	level.monkey_perks = [];

	vending_triggers = getentarray( "zombie_vending", "targetname" );
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		if ( vending_triggers[i].targeted )
		{
			continue;
		}

		// if any player has the perk, add it
		players = getplayers();
		for ( j = 0; j < players.size; j++ )
		{
			perk = vending_triggers[i].script_noteworthy;
			org = vending_triggers[i].origin;
			if ( isdefined( vending_triggers[i].realorigin ) )
			{
				org = vending_triggers[i].realorigin;
			}
			zone_enabled = check_point_in_active_zone( org );

			if ( players[j] HasPerk( perk ) && zone_enabled )
			{
				level.monkey_perks[ level.monkey_perks.size ] = vending_triggers[i];
				break;
			}
		}
	}

	if ( level.monkey_perks.size > 1 )
	{
		level.monkey_perks = array_randomize( level.monkey_perks );
	}

	level.monkey_perk_idx = 0;
}

monkey_pack_man_get_next_perk()
{
	if ( level.monkey_perks.size == 0 )
	{
		self.perk = undefined;
		return;
	}

	perk = level.monkey_perks[ level.monkey_perk_idx ];
	perk.targeted = 1;

	level.monkey_perk_idx++;
	if ( level.monkey_perk_idx == level.monkey_perks.size )
	{
		level monkey_pack_man_setup_perks();
	}

	self.perk = perk;
}

//-----------------------------------------------------------------
// spawn a pack of monkeys
//-----------------------------------------------------------------
monkey_pack_spawn()
{
	monkey_print( "spawning pack" );

	pack = SpawnStruct();
	pack.monkeys = [];
	pack.attack = [];
	pack.target = undefined;

	level.monkey_pack[ level.monkey_pack.size ] = pack;

	pack thread monkey_pack_think();
}

//-----------------------------------------------------------------
// spawns the monkeys, chooses initial enemy
//-----------------------------------------------------------------
monkey_pack_think()
{
	self.ground_hit_time = GetTime();

	self monkey_pack_man_get_next_perk();
	self monkey_pack_set_machine();

	self monkey_pack_choose_enemy();

	self.spawning_done = false;

	// pick random spawner for now
	for ( i = 0; i < level.monkeys_per_pack; i++ )
	{
		spawner = monkey_get_next_spawner();
		if ( isdefined( spawner ) )
		{
			monkey = spawner monkey_zombie_spawn( self );

			self.monkeys[ self.monkeys.size ] = monkey;
		}

		if ( i < (level.monkeys_per_pack-1) )
		{
			time = RandomFloatRange( 2.2, 4.4 );
			wait( time );
		}
	}

	self.spawning_done = true;

	self thread monkey_pack_update_enemy();
	self thread monkey_pack_update_perk();
}

//-----------------------------------------------------------------
// chooses the next perk to go after
//-----------------------------------------------------------------
monkey_pack_update_perk()
{
	while ( 1 )
	{
		if ( !isdefined( self.perk ) )
		{
			break;
		}

		// machine is destroyed, move on
		if ( self.machine.monkey_health == 0 )
		{
			monkey_print( "pack destroyed " + self.machine.targetname );

			self monkey_pack_take_perk();

			// need to wait for the perk to actually be taken from the player
			wait_network_frame();

			// clear the attack points
			self monkey_pack_clear_perk_pos();

			self monkey_pack_man_get_next_perk();
			self monkey_pack_set_machine();

			for ( i = 0; i < self.monkeys.size; i++ )
			{
				// only for monkeys not committed to players
				if ( !self.monkeys[i].charge_player )
				{
					self.monkeys[i].perk = self.perk;
					self.monkeys[i] notify( "stop_perk_attack" );
				}
			}
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// returns the perk most owned by players
//-----------------------------------------------------------------
monkey_pack_next_perk()
{
	perk = undefined;
	perk_idx = -1;
	num_perks = 0;
	keys = getarraykeys( level.monkey_perks );

	for ( i = 0; i < keys.size; i++ )
	{
		if ( level.monkey_perks[ keys[i] ] > num_perks )
		{
			num_perks = level.monkey_perks[ keys[i] ];
			perk_idx = i;
		}
	}

	if ( perk_idx >= 0 )
	{
		perk = keys[ perk_idx ];
	}


	if ( isdefined( perk ) )
	{
		monkey_print( "perk is " + perk );
	}
	else
	{
		monkey_print( "no more perks" );
	}

	self.perk = perk;
}

//-----------------------------------------------------------------
// find the actual machine to attack
//-----------------------------------------------------------------
monkey_pack_set_machine()
{
	self.machine = undefined;

	if ( !isdefined( self.perk ) )
	{
		return;
	}

	targets = getentarray( self.perk.target, "targetname" );
	for ( j = 0; j < targets.size; j++ )
	{
		if ( targets[j].classname == "script_model" )
		{
			self.machine = targets[j];
		}
	}
}

//-----------------------------------------------------------------
// choose an enemy based on spawn positions
//-----------------------------------------------------------------
monkey_pack_choose_enemy()
{
	monkey_enemy = [];
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if ( !is_player_valid( players[i] ) )
		{
			continue;
		}

		monkey_enemy[ monkey_enemy.size ] = players[i];
	}

	monkey_enemy = array_randomize( monkey_enemy );

	if ( monkey_enemy.size > 0 )
	{
		self.enemy = monkey_enemy[0];
	}
	else
	{
		self.enemy = players[0];
	}
}

//-----------------------------------------------------------------
// figures out an enemy for the pack, not an individual
//-----------------------------------------------------------------
monkey_pack_update_enemy()
{
	while ( self.monkeys.size > 0 )
	{
		players = getplayers();

		total_dist = 1000000;

		player_idx = 0;

		// find valid player closest to the pack
		for ( i = 0; i < players.size; i++ )
		{
			if ( !is_player_valid( players[i] ) )
			{
				continue;
			}

			dist = 0;
			for ( j = 0; j < self.monkeys.size; j++ )
			{
				if ( !isdefined( self.monkeys[j] ) )
				{
					continue;
				}

				dist += Distance( players[i].origin, self.monkeys[j].origin );
			}
			if ( dist < total_dist )
			{
				total_dist = dist;
				player_idx = i;
			}
		}

		if ( isdefined( players ) )
		{
			if ( isdefined( self.enemy ) )
			{
				if ( self.enemy != players[ player_idx ] )
				{
					monkey_print( "pack enemy is " + self.enemy.playername );
				}
			}
			else
			{
				monkey_print( "pack enemy is " + players[ player_idx ].playername );
			}

			self.enemy = players[ player_idx ];
		}

		wait( 0.2 );
	}
}

//-----------------------------------------------------------------
// check if ground pound is available
//-----------------------------------------------------------------
monkey_zombie_check_ground_hit()
{
	if ( GetTime() >= self.ground_hit_time )
	{
		return true;
	}

	return false;
}

//-----------------------------------------------------------------
// delay between ground hits
//-----------------------------------------------------------------
monkey_pack_update_ground_hit( hitter )
{
	self.ground_hit_time = GetTime() + level.ground_hit_delay;
	level.ground_hit_delay = RandomFloatRange( 4.5, 6.5 ) * 1000;

	for ( i = 0; i < self.monkeys.size; i++ )
	{
		if ( isDefined( self.monkeys[i] ) )
		{
			self.monkeys[i].ground_hit_time = self.ground_hit_time;
		}
	}

	groundpound_reset = level.monkey_zombie_groundhit_trigger_radius * 2;
	groundpound_reset_sq = groundpound_reset * groundpound_reset;

	for ( i = 0; i < level.monkey_pack.size; i++ )
	{
		pack = level.monkey_pack[i];
		if ( self == pack )
		{
			continue;
		}

		for ( j = 0; j < pack.monkeys.size; j++ )
		{
			monkey = pack.monkeys[j];
			if ( !isDefined( monkey ) )
			{
				continue;
			}
			if ( hitter == monkey )
			{
				continue;
			}

			dist_sq = DistanceSquared( hitter.origin, monkey.origin );
			if ( dist_sq <= groundpound_reset_sq )
			{
				monkey.ground_hit_time = self.ground_hit_time;
			}
		}
	}

	monkey_print( "next ground hit in " + level.ground_hit_delay );
}

//-----------------------------------------------------------------
// waits for the time and the ai to die
//-----------------------------------------------------------------
monkey_round_wait()
{
/#
	if ( GetDvarInt( #"zombie_cheat" ) == 2 || GetDvarInt( #"zombie_cheat" ) >= 4 )
	{
		level waittill("forever");
	}
#/

	wait( 1 );

	if ( flag( "monkey_round" ) )
	{
		wait( 7 );
		while ( level.monkey_intermission )
		{
			wait( 0.5 );
		}
	}
}

//-----------------------------------------------------------------
// round is finished
//-----------------------------------------------------------------
monkey_round_aftermath()
{
	flag_wait( "last_monkey_down" );

	level thread maps\_zombiemode_audio::change_zombie_music( "dog_end" );

	level.round_spawn_func = level.monkey_save_spawn_func;
	level.round_wait_func = level.monkey_save_wait_func;

	wait( 6 );
	level.monkey_intermission = false;
}

//-----------------------------------------------------------------
// when to start a monkey round
//-----------------------------------------------------------------
monkey_round_tracker()
{
	flag_wait( "power_on" );
	flag_wait( "perk_bought" );

	level.monkey_save_spawn_func = level.round_spawn_func;
	level.monkey_save_wait_func = level.round_wait_func;

	level.next_monkey_round = level.round_number + randomintrange( 1, 3 );
	level.prev_monkey_round = level.next_monkey_round;

	if(level.next_monkey_round - level.round_number == 1)
	{
		level.prev_monkey_round_amount = 4;
	}
	else
	{
		level.prev_monkey_round_amount = 5;
	}

	while ( 1 )
	{
		level waittill( "between_round_over" );

		if ( level.round_number == level.next_monkey_round )
		{
			// only allow round change if someone has a perk
			if ( !monkey_player_has_perk() )
			{
				level.next_monkey_round++;
				monkey_print( "next monkey round at " + level.next_monkey_round );
				continue;
			}

			level.music_round_override = true;
			level.monkey_save_spawn_func = level.round_spawn_func;
			level.monkey_save_wait_func = level.round_wait_func;

			monkey_round_start();

			level.round_spawn_func = ::monkey_round_spawning;
			level.round_wait_func = ::monkey_round_wait;

			if(!IsDefined(level.prev_monkey_round_amount))
			{
				level.prev_monkey_round = level.next_monkey_round;
				level.prev_monkey_round_amount = RandomIntRange( 4, 6 );
				level.next_monkey_round = level.round_number + level.prev_monkey_round_amount;
			}
			else
			{
				if(level.prev_monkey_round_amount == 4)
				{
					level.prev_monkey_round = level.next_monkey_round;
					level.next_monkey_round = level.round_number + 5;
					level.prev_monkey_round_amount = undefined;
				}
				else
				{
					level.prev_monkey_round = level.next_monkey_round;
					level.next_monkey_round = level.round_number + 4;
					level.prev_monkey_round_amount = undefined;
				}
			}

			monkey_print( "next monkey round at " + level.next_monkey_round );
		}
		else if ( flag( "monkey_round" ) )
		{
			monkey_round_stop();
			level.music_round_override = false;
		}
	}
}

//-----------------------------------------------------------------
// monkey round begins
//-----------------------------------------------------------------
monkey_round_start()
{
	flag_set( "monkey_round" );
	flag_set( "monkey_free_perk" );

	if ( isDefined( level.monkey_round_start ) )
	{
		level thread [[ level.monkey_round_start ]]();
	}

	level thread monkey_zombie_setup_perks();

	level monkey_setup_health();
	level monkey_setup_spawners();
	level monkey_setup_packs();
	level monkey_pack_man_setup_perks();

	level thread monkey_grenade_watcher();

	//level thread maps\_zombiemode_audio::change_zombie_music( "dog_start" );
	clientnotify( "monkey_start" );
	level thread play_delayed_player_vox();
}

play_delayed_player_vox()
{
    wait(8);
    players = getplayers();
	players[RandomIntRange(0,players.size)] maps\_zombiemode_audio::create_and_play_dialog( "general", "monkey_spawn" );
}

//-----------------------------------------------------------------
// monkey round ends
//-----------------------------------------------------------------
monkey_round_stop()
{
	flag_clear( "monkey_round" );
	flag_clear( "last_monkey_down" );

	if ( isDefined( level.monkey_round_stop ) )
	{
		level thread [[ level.monkey_round_stop ]]();
	}

	clientnotify( "monkey_stop" );
	level notify( "grenade_watcher_stop" );
}

//-----------------------------------------------------------------
// checks if any player has a perk
//-----------------------------------------------------------------
monkey_player_has_perk()
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		players = getplayers();
		for ( j = 0; j < players.size; j++ )
		{
			perk = vending_triggers[i].script_noteworthy;
			org = vending_triggers[i].origin;
			if ( isdefined( vending_triggers[i].realorigin ) )
			{
				org = vending_triggers[i].realorigin;
			}
			zone_enabled = check_point_in_active_zone( org );

			if ( players[j] HasPerk( perk ) && zone_enabled )
			{
				return true;
			}
		}
	}

	return false;
}

//-----------------------------------------------------------------
// handles spawning packs of monkeys
//-----------------------------------------------------------------
monkey_zombie_manager()
{
	while( true )
	{
		AssertEx( isDefined( level.num_monkey_zombies ) && isDefined( level.max_monkey_zombies ), "Either max_monkey_zombies or num_monkey_zombies not defined, this should never be the case!" );
		while( level.num_monkey_zombies < level.max_monkey_zombies )
		{
			spawner = monkey_zombie_pick_best_spawner();
			if( isDefined( spawner ) )
			{
				spawner monkey_zombie_spawn();
			}
			wait( 10 );
		}
		wait( 10 );
	}
}

//-----------------------------------------------------------------
// figure out which spawner to use
//-----------------------------------------------------------------
monkey_zombie_pick_best_spawner()
{
	best_spawner = undefined;
	best_score = -1;
	for( i = 0; i < level.monkey_zombie_spawners.size; i++ )
	{
		score = [[ level.monkey_zombie_spawn_heuristic ]]( level.monkey_zombie_spawners[i] );
		if( score > best_score )
		{
			best_spawner = level.monkey_zombie_spawners[i];
			best_score = score;
		}
	}
	return best_spawner;
}

//-----------------------------------------------------------------
// pick a random run
//-----------------------------------------------------------------
monkey_zombie_choose_run()
{
	self endon( "death" );

	rand = randomIntRange( 1, 3 );
	self set_run_anim( "run"+rand );
	self.run_combatanim = level.scr_anim["monkey_zombie"]["run"+rand];
	self.crouchRunAnim = level.scr_anim["monkey_zombie"]["run"+rand];
	self.crouchrun_combatanim = level.scr_anim["monkey_zombie"]["run"+rand];

	self.zombie_move_speed = "run";

	self waittill( "speed_up" );

	rand = randomIntRange( 1, 5 );
	self set_run_anim( "sprint"+rand );
	self.run_combatanim = level.scr_anim["monkey_zombie"]["sprint"+rand];
	self.crouchRunAnim = level.scr_anim["monkey_zombie"]["sprint"+rand];
	self.crouchrun_combatanim = level.scr_anim["monkey_zombie"]["sprint"+rand];

	self.zombie_move_speed = "sprint";
}

//-----------------------------------------------------------------
// base ai of the monkey
//-----------------------------------------------------------------
monkey_zombie_think()
{
	self endon( "death" );

	self thread play_random_monkey_vox();

	self.goalradius = 32;
	//self.ignoreall = false;
	self.pathEnemyFightDist = 64;
	self.meleeAttackDist = 64;

	self.charge_player = false;

	level.monkey_zombie_min_health = int( level.monkey_zombie_health );

	if( self.maxhealth < level.monkey_zombie_min_health )
	{
		self.maxhealth = level.monkey_zombie_min_health;
		self.health = level.monkey_zombie_min_health;
	}

	if ( isdefined( level.user_ryan_monkey_health ) )
	{
		self.maxhealth = 1;
		self.health = 1;
	}

	self thread monkey_zombie_choose_run();

	//try to prevent always turning towards the enemy
	self.maxsightdistsqrd = 96 * 96;

	self [[ level.monkey_zombie_enter_level ]]();

	if ( isDefined( level.monkey_zombie_custom_think ) )
	{
		self thread [[ level.monkey_zombie_custom_think ]]();
	}

	self thread monkey_zombie_ground_hit_think();
	self thread monkey_zombie_grenade_watcher();
	self thread monkey_zombie_bhb_watcher();
	self thread monkey_zombie_speed_watcher();
	self thread monkey_zombie_fling_watcher();

	self thread monkey_zombie_update();
	//self thread monkey_zombie_debug();

	if ( isDefined( level.monkey_zombie_failsafe ) )
	{
		self thread [[ level.monkey_zombie_failsafe ]]();
	}
}

monkey_zombie_debug()
{
	self endon( "death" );

	while( true )
	{
		forward = VectorNormalize( AnglesToForward( self.angles ) );
		end_pos = self.origin - vector_scale( forward, 120 );

		recordLine( self.origin, end_pos, (.5,1,0), "Script", self );

		wait_network_frame();
	}
}


monkey_zombie_update()
{
	self endon( "death" );
	self endon( "monkey_update_stop" );

	self animmode( "none" );

	while( true )
	{
		if ( isDefined( self.custom_think ) && self.custom_think )
		{
			wait_network_frame();
			continue;
		}
		else if ( self.state == "bhb_response" || self.state == "grenade_response" )
		{
			wait_network_frame();
			continue;
		}
		else if ( isDefined( self.perk ) )
		{
			self thread monkey_zombie_destroy_perk();
			self waittill( "stop_perk_attack" );
			//self waittill_any( "next_perk", "stop_perk_attack" );
			wait_network_frame();
			continue;
		}
		else if ( isDefined( self.ground_hit ) && self.ground_hit )
		{
			wait_network_frame();
			continue;
		}
		else if( !isDefined( self.following_player ) || !self.following_player )
		{
			self thread maps\_zombiemode_ai_monkey::monkey_find_flesh();
			self.following_player = true;
			self monkey_zombie_set_state( "charge_player" );
		}
		wait( 1 );
	}
}

//-----------------------------------------------------------------
// reserve a position at the vending machine to attack from
//-----------------------------------------------------------------
monkey_zombie_get_perk_pos()
{
	points = getstructarray( self.pack.machine.target, "targetname" );
	for ( i = 0; i < points.size; i++ )
	{
		if ( isdefined( self.pack.attack[i] ) )
		{
			continue;
		}

		self.pack.attack[i] = self;
		self.attack = points[i];
		break;
	}
}

//-----------------------------------------------------------------
// clears the attack points at the machine
//-----------------------------------------------------------------
monkey_pack_clear_perk_pos()
{
	self.attack = [];
}

//-----------------------------------------------------------------
// monkey only chases player after losing some health
//-----------------------------------------------------------------
monkey_zombie_health_watcher()
{
	self endon( "death" );

	health_limit = self.health * 0.75;

	while ( 1 )
	{
		if ( self.health <= health_limit )
		{
			self StopAnimScripted();
			wait_network_frame();

			self notify( "stop_perk_attack" );
			self monkey_zombie_set_state( "charge_player" );
			self.charge_player = true;
			self.perk = undefined;
			break;
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// monkey doesn't need thundergun fling override after losing too much health
//-----------------------------------------------------------------
monkey_zombie_fling_watcher()
{
	self endon( "death" );

	half_health = level.monkey_zombie_health * 0.5;

	while ( 1 )
	{
		if ( self.health <= half_health )
		{
			self.thundergun_fling_func = undefined;
			break;
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// switch to sprint after taking damage
//-----------------------------------------------------------------
monkey_zombie_speed_watcher()
{
	self endon( "death" );

	while ( 1 )
	{
		if ( self.health < self.maxhealth )
		{
			break;
		}

		wait_network_frame();
	}

	self notify( "speed_up" );
}

//-----------------------------------------------------------------
// setup grenade watchers on players
//-----------------------------------------------------------------
monkey_grenade_watcher()
{
	self endon( "death" );

	level.monkey_grenades = [];
	level.monkey_bhbs = [];

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] thread monkey_grenade_watch();
	}
}

//-----------------------------------------------------------------
// wait for player to toss a grenade and build a list
//-----------------------------------------------------------------
monkey_grenade_watch()
{
	self endon( "death" );
	level endon( "grenade_watcher_stop" );

	while ( true )
	{
		self waittill( "grenade_fire", grenade, weapName );

		if ( is_lethal_grenade( weapName ) )
		{
			grenade thread monkey_grenade_wait();
			grenade.thrower = self;
			level.monkey_grenades[ level.monkey_grenades.size ] = grenade;

		}

		if ( weapName == "zombie_black_hole_bomb" )
		{
			grenade thread monkey_bhb_wait();
			level.monkey_bhbs[ level.monkey_bhbs.size ] = grenade;
		}

		monkey_print( "thrown from " + weapName );
	}
}

//-----------------------------------------------------------------
// remove grenade after it blows
//-----------------------------------------------------------------
monkey_grenade_wait()
{
	self waittill( "death" );

	level.monkey_grenades = array_remove( level.monkey_grenades, self );

	monkey_print( "remove grenade from level" );
}

//-----------------------------------------------------------------
// remove black hole bomb after it blows
//-----------------------------------------------------------------
monkey_bhb_wait()
{
	self waittill( "death" );

	level.monkey_bhbs = array_remove( level.monkey_bhbs, self );

	monkey_print( "remove bhb from level" );
}

//-----------------------------------------------------------------
// wait for anim notetrack to throw a grenade
//-----------------------------------------------------------------
monkey_zombie_grenade_throw_watcher( target, animname )
{
	self endon( "death" );

	self waittillmatch( animname, "grenade_throw" );

	throw_angle = RandomIntRange( 20, 30 );

	dir = VectorToAngles( target.origin - self.origin );
	dir = ( dir[0] - throw_angle, dir[1], dir[2] );
	dir = AnglesToForward( dir );

	velocity = dir * 550;

	fuse = RandomFloatRange( 1, 2 );
	hand_pos = self GetTagOrigin( "TAG_WEAPON_RIGHT" );

	grenade_type = target get_player_lethal_grenade();
	target MagicGrenadeType( grenade_type, hand_pos, velocity, fuse );
}

//-----------------------------------------------------------------
// plays a throw anim followed by a taunt anim
//-----------------------------------------------------------------
monkey_zombie_grenade_throw( target )
{
	self endon( "death" );

	throw_anim = [];

	forward = VectorNormalize( AnglesToForward( self.angles ) );
	end_pos = self.origin + vector_scale( forward, 96 );

	if ( BulletTracePassed( self.origin, end_pos, false, undefined ) )
	{
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_01;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_02;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_03;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_run_04;
	}
	else
	{
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_01;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_02;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_03;
		throw_anim[ throw_anim.size ] = %ai_zombie_monkey_grenade_throw_back_still_04;
	}

	throw_back_anim = throw_anim[ RandomInt( throw_anim.size ) ];
	//self SetFlaggedAnimKnobAllRestart( "throw_back_anim", throw_back_anim, %body, 1, .1, 1 );
	self animscripted( "throw_back_anim", self.origin, self.angles, throw_back_anim );
	self thread monkey_zombie_grenade_throw_watcher( target, "throw_back_anim" );
	animscripts\traverse\zombie_shared::wait_anim_length( throw_back_anim, .02 );

	choose = RandomInt( level._zombie_board_taunt["monkey_zombie"].size );
	taunt_anim = level._zombie_board_taunt["monkey_zombie"][ choose ];
	//self SetFlaggedAnimKnobAllRestart( "taunt_anim", taunt_anim, %body, 1, .1, 1 );
	self animscripted( "taunt_anim", self.origin, self.angles, taunt_anim );
	animscripts\traverse\zombie_shared::wait_anim_length( taunt_anim, .02 );

	self notify( "throw_done" );
}

//-----------------------------------------------------------------
// changes the damage amount when player enters the same zone
//		or shoots the monkey
//-----------------------------------------------------------------
monkey_zombie_watch_machine_damage()
{
	self endon( "death" );
	self endon( "stop_perk_attack" );
	self endon( "stop_machine_watch" );

	machine = self.pack.machine;
	machine waittill( "attacked" );

	while ( 1 )
	{
		monkey_zone = self monkey_get_zone();
		if ( isdefined( monkey_zone ) )
		{
			if ( monkey_zone.is_occupied )
			{
				monkey_print( "player is here, go crazy" );
				self.machine_damage = level.machine_damage_max;
				break;
			}
		}

		wait_network_frame();
	}
}

monkey_zombie_set_state( state )
{
	self.state = state;

	monkey_print( "set state to " + state );
/#
	if ( !isDefined( self.state_history ) )
	{
		self.state_history = [];
	}
	if ( !isDefined( self.state_history_idx ) )
	{
		self.state_history_idx = 0;
	}

	self.state_history[ self.state_history_idx ] = state;
	self.state_history_idx++;
	if ( self.state_history_idx > 100 )
	{
		self.state_history_idx = 0;
	}
#/
}

monkey_zombie_get_state()
{
	if ( isdefined( self.state ) )
	{
		return self.state;
	}

	return undefined;
}

//-----------------------------------------------------------------
// attack machine until it's destroyed
//-----------------------------------------------------------------
monkey_zombie_attack_perk()
{
	self endon( "death" );
	self endon( "stop_perk_attack" );
	self endon( "next_perk" );

	if ( !isdefined( self.perk ) )
	{
		return;
	}

	flag_clear( "monkey_free_perk" );

	self.following_player = false;

	//self thread monkey_zombie_health_watcher();
	self monkey_zombie_set_state( "attack_perk" );

	//C. Ayers: Adding in player dialogue stating that their perk is being taken
    level thread play_player_perk_theft_vox( self.perk.script_noteworthy, self );

	spot = self.attack.script_int;

	// try this to align
	self Teleport( self.attack.origin, self.attack.angles );

	monkey_print( "attack " + self.perk.script_noteworthy + " from " + spot );

	choose = 0;
	if ( spot == 1 )
	{
		if(self.perk.script_noteworthy != "specialty_rof")
		{
			choose = RandomIntRange( 1, 3 );
		}
		else
		{
			choose = 1;
		}
	}
	else if ( spot == 3 )
	{
		if(self.perk.script_noteworthy != "specialty_rof")
		{
			choose = RandomIntRange( 3, 5 );
		}
		else
		{
			choose = 3;
		}
	}

	perk_attack_anim = undefined;

	// check for machine specific attacks
	if ( choose == 2 )
	{
		if ( isdefined( level.monkey_perk_attack_anims[ self.perk.script_noteworthy ] ) )
		{
			perk_attack_anim = level.monkey_perk_attack_anims[ self.perk.script_noteworthy ][ "left_top" ];
		}
	}
	else if ( choose == 4 )
	{
		if ( isdefined( level.monkey_perk_attack_anims[ self.perk.script_noteworthy ] ) )
		{
			perk_attack_anim = level.monkey_perk_attack_anims[ self.perk.script_noteworthy ][ "right_top" ];
		}
	}

	if ( !isdefined( perk_attack_anim ) )
	{
		perk_attack_anim = level.monkey_perk_attack_anims[ choose ];
	}

	//perk_attack_anim = animscripts\zombie_melee::pick_zombie_melee_anim( self );
	time = getAnimLength( perk_attack_anim );

	self thread monkey_wait_to_drop();

	machine = self.pack.machine;
	machine notify( "attacked" );

	while ( 1 )
	{
		monkey_pack_flash_perk( self.perk.script_noteworthy, self.machine_damage );

		self animscripted( "perk_attack_anim", self.attack.origin, self.attack.angles, perk_attack_anim, "normal", %body, 1, 0.2 );
		//self animscripted( "perk_attack_anim", self.origin, self.angles, perk_attack_anim, "normal", %body, 1 );
		//self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );
		self thread play_attack_impacts( time );

		if ( self monkey_zombie_perk_damage( self.machine_damage ) )
		{
			//self monkey_pack_take_perk();
			break;
		}

		wait( time );
	}

	self notify( "stop_machine_watch" );
	self monkey_zombie_set_state( "attack_perk_done" );
}

monkey_wait_to_drop()
{
	self endon( "death" );

	wait( 0.2 );

	self.dropped = false;

	self.perk_attack_origin = self.attack.origin;

	while ( true )
	{
		diff = abs( self.perk_attack_origin[2] - self.origin[2] );

		if ( diff < 8 )
		{
			break;
		}

		wait_network_frame();
	}

	self.dropped = true;

	monkey_print( "close to ground" );
}

play_player_perk_theft_vox( perk, monkey )
{
    force_quit = 0;

    if( !IsDefined( level.perk_theft_vox ) )
        level.perk_theft_vox = [];

    if( !IsDefined( level.perk_theft_vox[perk] ) )
        level.perk_theft_vox[perk] = false;

    if( level.perk_theft_vox[perk] )
        return;

    level.perk_theft_vox[perk] = true;

    while(1)
    {
        player = getplayers();
        rand = RandomIntRange(0, player.size );

        if ( monkey.pack.machine.monkey_health == 0 )
	    {
		    level.perk_theft_vox[perk] = false;
		    return;
	    }

        if( ( IsAlive( player[rand] ) ) && ( !player[rand] maps\_laststand::player_is_in_laststand() ) && ( player[rand] HasPerk( perk ) ) )
        {
            player[rand] maps\_zombiemode_audio::create_and_play_dialog( "perk", "steal_" + perk );
            break;
        }
        else if( force_quit >= 6 )
        {
            break;
        }

        force_quit ++;
        wait(.05);
    }

	while( IsDefined(monkey) && IsDefined(monkey.pack) && IsDefined(monkey.pack.machine) && IsDefined(monkey.pack.machine.monkey_health) && 
		monkey.pack.machine.monkey_health != 0 )
	{
	    wait(1);
	}

	level.perk_theft_vox[perk] = false;
}

play_attack_impacts( time )
{
    self endon( "death" );

    for(i=0;i<time;i++)
    {
        if( RandomIntRange(0,100) >= 41 )
            self PlaySound( "zmb_monkey_attack_machine" );

        wait(RandomFloatRange(.7,1.1));
    }
}

//-----------------------------------------------------------------
// run to a machine and attack it til it's destroyed
//-----------------------------------------------------------------
monkey_zombie_destroy_perk()
{
	self endon( "death" );
	self endon( "stop_perk_attack" );

	if ( isdefined( self.perk ) )
	{
		self monkey_zombie_set_state( "destroy_perk" );

		monkey_print( "goto " + self.perk.script_noteworthy );

		self monkey_zombie_get_perk_pos();
		if ( isdefined( self.attack ) )
		{
			self SetGoalPos( self.attack.origin );
			self waittill( "goal" );
			self SetGoalPos( self.origin );

			//self thread monkey_zombie_watch_machine_damage();
			self thread monkey_zombie_attack_perk();
		}
	}
}

//-----------------------------------------------------------------
// zone needs to be enabled for spawning
//-----------------------------------------------------------------
monkey_zombie_default_spawn_heuristic( spawner )
{
	if( !isDefined( spawner.script_noteworthy ) )
	{
		return -1;
	}

	if( !isDefined( level.zones ) || !isDefined( level.zones[ spawner.script_noteworthy ] ) || !level.zones[ spawner.script_noteworthy ].is_enabled )
	{
		return -1;
	}

	score = 0;

	// if we don't have a position, give score relative to player positions, farther is better
	players = get_players();

	for( i = 0; i < players.size; i++ )
	{
		score = int( distanceSquared( spawner.origin, players[i].origin ) );
	}

	return score;
}

//-----------------------------------------------------------------
// handles monkey ground pound
//-----------------------------------------------------------------
monkey_zombie_ground_hit()
{
	self endon( "death" );

	if ( self.ground_hit )
	{
		return;
	}

	self monkey_zombie_set_state( "ground_pound" );

	//self notify( "stop_finding_flesh" );
	//self.following_player = false;
	self.ground_hit = true;

	self thread groundhit_watcher( "groundhit_anim" );

	//self thread maps\_zombiemode_audio::do_zombies_playvocals( "attack", self.animname );

	choose = RandomInt( level.monkey_groundpound_anims.size );
	groundpound_anim = level.monkey_groundpound_anims[ choose ];

	self animscripted( "groundhit_anim", self.origin, self.angles, groundpound_anim );
	//self SetFlaggedAnimKnobAllRestart( "groundhit_anim", %ai_zombie_simianaut_ground_pound, %body, 1, .1, 1 );

	animscripts\traverse\zombie_shared::wait_anim_length(groundpound_anim, .02);

	self.ground_hit = false;

	self monkey_zombie_set_state( "ground_pound_done" );

	self.nextGroundHit = GetTime() + level.monkey_ground_attack_delay;

	if ( self.chest_beat )
	{
		//self monkey_zombie_set_state( "ground_pound_taunt" );
		choose = RandomInt( level._zombie_board_taunt["monkey_zombie"].size );
		taunt_anim = level._zombie_board_taunt["monkey_zombie"][ choose ];
		self animscripted( "taunt_anim", self.origin, self.angles, taunt_anim );
		time = getAnimLength( taunt_anim );
		wait( time );
		//self monkey_zombie_set_state( "ground_pound_taunt_done" );
		self.chest_beat = false;
	}

	self thread animscripts\zombie_combat::main();
}

//-----------------------------------------------------------------
// check if the claymore is already going to be destroyed by someone else in the pack
//-----------------------------------------------------------------
monkey_pack_ready_to_detonate( claymore )
{
	for ( i = 0; i < self.monkeys.size; i++ )
	{
		if ( self.monkeys[i] == self )
		{
			continue;
		}

		ready = self.monkeys[i].force_detonate;
		if ( isdefined( ready ) )
		{
			for ( j = 0; j < ready.size; j++ )
			{
				if ( claymore == ready[j] )
				{
					return true;
				}
			}
		}
	}

	return false;
}

//-----------------------------------------------------------------
// ground pound to destroy claymores
//-----------------------------------------------------------------
monkey_zombie_force_groundhit()
{
	if ( !isdefined( level.claymores ) )
	{
		return false;
	}

	claymore_dist = 216*216;
	height_max = 12;

	self.force_detonate = [];

	for ( i = 0; i < level.claymores.size; i++ )
	{
		if ( self.pack monkey_pack_ready_to_detonate( level.claymores[i] ) )
		{
			continue;
		}

		height_diff = abs( self.origin[2] - level.claymores[i].origin[2] );
		if ( height_diff < height_max )
		{
			if ( DistanceSquared( self.origin, level.claymores[i].origin ) < claymore_dist )
			{
				self.force_detonate[ self.force_detonate.size ] = level.claymores[i];
			}
		}
	}

	return self.force_detonate.size > 0;
}

//-----------------------------------------------------------------
// checks for when a ground pound is allowed
//-----------------------------------------------------------------
monkey_zombie_ground_hit_think()
{
	self endon( "death" );

	self.ground_hit = false;
	self.nextGroundHit = GetTime() + level.monkey_ground_attack_delay;

	while( 1 )
	{
		if ( self.state == "attack_perk" )
		{
			wait_network_frame();
			continue;
		}

		if ( !self.dropped )
		{
			wait( 1 );
			continue;
		}

		// force a ground hit when claymores are nearby
		if ( !self.ground_hit && self monkey_zombie_force_groundhit() )
		{
			self.pack monkey_pack_update_ground_hit( self );
			self animcustom( ::monkey_zombie_ground_hit );
		}
		else if ( !self.ground_hit && self monkey_zombie_check_ground_hit() )
		{
			players = GetPlayers();
			closeEnough = false;
			origin = self GetEye();

			for ( i = 0; i < players.size; i++ )
			{
				if ( players[i] maps\_laststand::player_is_in_laststand() )
				{
					continue;
				}

				test_origin = players[i] GetEye();
				d = DistanceSquared( origin, test_origin );

				if ( d > level.monkey_zombie_groundhit_trigger_radius * level.monkey_zombie_groundhit_trigger_radius )
				{
					continue;
				}

				if ( !BulletTracePassed( origin, test_origin, false, undefined ) )
				{
					continue;
				}

				closeEnough = true;
				break;
			}

			if ( closeEnough )
			{
				self.pack monkey_pack_update_ground_hit( self );
				self animcustom( ::monkey_zombie_ground_hit );
			}
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// waits for notetrack to do ground pound damage
//-----------------------------------------------------------------
groundhit_watcher( animname )
{
	self endon( "death" );

	self waittillmatch( animname, "fire" );

	playfxontag( level._effect["monkey_groundhit"], self, "tag_origin" );
	//self PlaySound( "zmb_monkey_groundpound" );

	//origin = self GetEye();
	origin = self.origin + ( 0, 0, 40 );
	zombies_axis = get_array_of_closest( origin, GetAiSpeciesArray( "axis", "all" ), undefined, undefined, level.monkey_zombie_groundhit_damage_radius );
	dogs = get_array_of_closest( origin, GetAiSpeciesArray( "allies", "zombie_dog" ), undefined, undefined, level.monkey_zombie_groundhit_damage_radius );
	zombies = array_combine( zombies_axis, dogs );

	//dist = Distance( self.origin, self.favoriteenemy.origin );
	//iprintln( "dist = " + dist );

	if ( IsDefined( zombies ) )
	{
		for ( i = 0; i < zombies.size; i++ )
		{
			if ( !IsDefined( zombies[i] ) )
			{
				continue;
			}

			if ( is_magic_bullet_shield_enabled( zombies[i] ) )
			{
				continue;
			}

			test_origin = zombies[i] GetEye();

			if ( !BulletTracePassed( origin, test_origin, false, undefined ) )
			{
				continue;
			}

			if ( zombies[i] == self )
			{
				continue;
			}

			if ( zombies[i].animname == "monkey_zombie" )
			{
				continue;
			}

			refs = [];
			refs[refs.size] = "guts";
			refs[refs.size] = "right_arm";
			refs[refs.size] = "left_arm";
			refs[refs.size] = "right_leg";
			refs[refs.size] = "left_leg";
			refs[refs.size] = "no_legs";
			refs[refs.size] = "head";

			if( refs.size )
			{
				zombies[i].a.gib_ref = random( refs );
			}

			zombies[i] DoDamage( zombies[i].health * 10, self.origin, self );
		}
	}

	players = get_players();
	affected_players = [];
	for( i = 0; i < players.size; i++ )
	{
		if ( !is_player_valid( players[i] ) )
		{
			continue;
		}

		test_origin = players[i] GetEye();
		if( distanceSquared( origin, test_origin ) > level.monkey_zombie_groundhit_damage_radius * level.monkey_zombie_groundhit_damage_radius )
		{
			continue;
		}
		if ( !BulletTracePassed( origin, test_origin, false, undefined ) )
		{
			continue;
		}

		affected_players = array_add( affected_players, players[i] );
	}
	self.chest_beat = false;
	for( i = 0; i < affected_players.size; i++ )
	{
		self.chest_beat = true;

		player = affected_players[i];
		if ( player IsOnGround() )
		{
			damage = player.maxhealth * 0.5;
			player ShellShock( "electrocution", 1.5, true );
			player DoDamage( damage, self.origin, self );
		}

		/*
		if ( players.size > 1 )
		{
			if ( i == 0 )
			{
				player = affected_players[i];
				if ( player IsOnGround() )
				{
					damage = player.health;
					if ( player HasPerk( "specialty_armorvest" ) )
					{
						damage = player.maxhealth * 0.5;
						player ShellShock( "electrocution", 1.5, true );
					}
					player DoDamage( damage, player.origin, self );
				}

				self.favoriteenemy = player;
			}
			else
			{
				affected_players[i] ShellShock( "electrocution", 1.5, true );
			}
		}
		else
		{
			if ( affected_players[i] IsOnGround() )
			{
				affected_players[i] ShellShock( "electrocution", 1.5, true );
			}
		}
		*/
	}

	if ( isdefined( self.force_detonate ) )
	{
		for ( i = 0; i < self.force_detonate.size; i++ )
		{
			if ( isdefined( self.force_detonate[i] ) )
			{
				self.force_detonate[i] detonate( undefined );
			}
		}
	}
}

monkey_zombie_grenade_pickup()
{
	self endon( "death" );

	pickup_dist_sq = 32*32;
	picked_up = false;

	while ( isdefined( self.monkey_grenade ) )
	{
		self SetGoalPos( self.monkey_grenade.origin );

		grenade_dist_sq = DistanceSquared( self.origin, self.monkey_grenade.origin );
		if ( grenade_dist_sq <= pickup_dist_sq )
		{
			self.monkey_thrower = self.monkey_grenade.thrower;
			self.monkey_grenade delete();
			self.monkey_grenade = undefined;
			picked_up = true;
			monkey_print( "deleting grenade" );
		}

		wait_network_frame();
	}

	if ( picked_up )
	{
		while ( 1 )
		{
			self SetGoalPos( self.monkey_thrower.origin );
			target_dir = self.monkey_thrower.origin - self.origin;
			monkey_dir = AnglesToForward( self.angles );

			dot = VectorDot( VectorNormalize( target_dir ), VectorNormalize( monkey_dir ) );
			if ( dot >= 0.5 )
			{
				break;
			}

			wait_network_frame();
		}

		self thread monkey_zombie_grenade_throw( self.monkey_thrower );
		self waittill( "throw_done" );
	}
}

//-----------------------------------------------------------------
// checks if grenade is close enough to go after
//-----------------------------------------------------------------
monkey_zombie_grenade_response()
{
	self endon( "death" );

	monkey_print( "go for grenade" );

	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );
	self notify( "monkey_update_stop" );
	self notify( "stop_perk_attack" );

	self.following_player = false;

	self monkey_zombie_set_state( "grenade_response" );

	self monkey_zombie_clear_attack_pos();

	self monkey_zombie_grenade_pickup();

	self thread monkey_zombie_update();

	self monkey_zombie_set_state( "grenade_response_done" );
}

//-----------------------------------------------------------------
// checks if grenade is close enough to go after
//-----------------------------------------------------------------
monkey_zombie_grenade_watcher()
{
	self endon( "death" );

	grenade_respond_dist_sq = 120 * 120;

	while ( 1 )
	{
		if ( self.state == "default" )
		{
			wait_network_frame();
			continue;
		}

		if ( is_true( self.ground_hit ) )
		{
			wait_network_frame();
			continue;
		}

		if ( is_true( self.monkey_grenade ) )
		{
			wait_network_frame();
			continue;
		}

		if ( level.monkey_grenades.size > 0 )
		{
			for ( i = 0; i < level.monkey_grenades.size; i++ )
			{
				grenade = level.monkey_grenades[i];
				if ( !isdefined( grenade ) || isdefined( grenade.monkey ) )	// monkey already responding
				{
					wait_network_frame();
					continue;
				}

				grenade_dist_sq = DistanceSquared( self.origin, grenade.origin );
				if ( grenade_dist_sq <= grenade_respond_dist_sq )
				{
					grenade.monkey = self;
					self.monkey_grenade = grenade;
					self monkey_zombie_grenade_response();
					break;
				}
			}
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// sends monkey to bhb teleport location
//-----------------------------------------------------------------
monkey_zombie_bhb_teleport()
{
	self endon( "death" );

	monkey_print( "bhb teleport" );

	black_hole_teleport = getstructarray( "struct_black_hole_teleport", "targetname" );

	assertex( black_hole_teleport.size > 0, "struct_black_hole_teleport not found" );

	zone_name = self get_current_zone();

	locations = [];

	for ( i = 0; i < black_hole_teleport.size; i++ )
	{
		bhb_zone_name = black_hole_teleport[i].script_string;

		if ( !isDefined( bhb_zone_name ) || !isDefined( zone_name ) )
		{
			continue;
		}

		if ( bhb_zone_name == zone_name )
		{
			continue;
		}

		if ( !level.zones[ bhb_zone_name ].is_enabled )
		{
			continue;
		}

		locations[ locations.size ] = black_hole_teleport[i];
	}


	self StopAnimScripted();
	wait_network_frame();

	so = spawn( "script_origin", self.origin );
	so.angles = self.angles;
	self linkto( so );

	if ( locations.size > 0 )
	{
		locations = array_randomize( locations );
		so.origin = locations[0].origin;
		so.angles = locations[0].angles;
	}
	else
	{
		so.origin = self.spawn_origin;
		so.angles = self.spawn_angles;
	}

	wait_network_frame();
	self unlink();
	so delete();

	maps\_zombiemode_weap_black_hole_bomb::black_hole_bomb_create_exit_portal( self.origin );
}

monkey_zombie_bhb_failsafe()
{
	self endon( "death" );
	self endon( "bhb_old_failsafe" );

	prev_origin = self.origin;
	min_movement = 16*16;

	while ( true )
	{
		wait( 1 );

		dist = DistanceSquared( prev_origin, self.origin );
		if ( dist < min_movement )
		{
			break;
		}
		prev_origin = self.origin;
	}

	if ( self.state == "ground_pound" )
	{
		return;
	}

	//monkey_print( "hasn't moved enough" );

	self.safeToChangeScript = true;
	self animmode( "none" );
}

//-----------------------------------------------------------------
// run and jump into bhb
//-----------------------------------------------------------------
monkey_zombie_bhb_run()
{
	self endon( "death" );

	jump_dist_sq = 64*64;
	jump = false;

	wait_network_frame();

	if ( !isdefined( self.monkey_bhb ) || !isdefined( self.monkey_bhb.origin ) )
	{
		return;
	}

	self.safeToChangeScript = false;

	self SetGoalPos( self.monkey_bhb.origin );

	while ( isdefined( self.monkey_bhb ) )
	{
		bhb_dist_sq = DistanceSquared( self.origin, self.monkey_bhb.origin );
		if ( bhb_dist_sq <= jump_dist_sq )
		{
			jump = true;
			break;
		}

		wait_network_frame();
	}

	if ( jump )
	{
		//self monkey_zombie_set_state( "bhb_jump" );
		jump_anim = %ai_zombie_monkey_portal_jump_01;

		self animscripted( "jump_anim", self.origin, self.angles, jump_anim );
		//animscripts\traverse\zombie_shared::wait_anim_length( jump_anim, .02 );
		jump_length = getanimlength( jump_anim );
		pre_jump = jump_length * 0.625;
		post_jump = jump_length * 0.375;

		wait( pre_jump );
		self stopanimscripted();
		wait_network_frame();

		//self animcustom( ::monkey_zombie_bhb_teleport );

		self monkey_zombie_bhb_teleport();
		//wait( post_jump );
		//self monkey_zombie_set_state( "bhb_jump_done" );
	}

	wait_network_frame();
	self.safeToChangeScript = true;

	self SetGoalPos( self.origin );
	self waittill_any_or_timeout( 0.5, "goal" );

	self notify( "bhb_old_failsafe" );
	wait_network_frame();
	self thread monkey_zombie_bhb_failsafe();
}

//-----------------------------------------------------------------
// release the reserved spot at the perk machine
//-----------------------------------------------------------------
monkey_zombie_clear_attack_pos()
{
	if ( isDefined( self.attack ) )
	{
		if ( isDefined( self.pack.attack ) )
		{
			for ( i = 0; i < self.pack.attack.size; i++ )
			{
				if ( self == self.pack.attack[i] )
				{
					self.pack.attack = array_remove( self.pack.attack, self );
					self.attack = undefined;
					return;
				}
			}
		}
	}
}

//-----------------------------------------------------------------
// stop and run for bhb
//-----------------------------------------------------------------
monkey_zombie_bhb_response()
{
	self endon( "death" );

	monkey_print( "bhb response" );

	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );
	self notify( "monkey_update_stop" );
	self notify( "stop_perk_attack" );

	self.following_player = false;

	self monkey_zombie_set_state( "bhb_response" );

	self monkey_zombie_clear_attack_pos();

	self monkey_zombie_bhb_run();

	self thread monkey_zombie_update();

	self monkey_zombie_set_state( "bhb_response_done" );
}

//-----------------------------------------------------------------
// checks if bhb is close
//-----------------------------------------------------------------
monkey_zombie_bhb_watcher()
{
	self endon( "death" );

	bhb_respond_dist_sq = 512 * 512;

	while ( 1 )
	{
		if ( self.state == "default" ||
			 self.state == "ground_pound" || self.state == "ground_pound_taunt" ||
			 self.state == "grenade_reponse" || self.state == "bhb_response" ||
			 self.state == "attack_perk" || !self.dropped )
		{
			wait_network_frame();
			continue;
		}

		if ( level.monkey_bhbs.size > 0 )
		{
			for ( i = 0; i < level.monkey_bhbs.size; i++ )
			{
				bhb = level.monkey_bhbs[i];

				if ( is_true( bhb.is_valid ) )
				{
					if ( !isDefined( bhb ) || !isDefined( bhb.origin ) || !isDefined( self.origin ) )
					{
						continue;
					}

					bhb_dist_sq = DistanceSquared( self.origin, bhb.origin );
					if ( bhb_dist_sq <= bhb_respond_dist_sq )
					{
						self.monkey_bhb = bhb;
						self monkey_zombie_bhb_response();
					}
				}
			}
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// takes monkey out of the pack
//-----------------------------------------------------------------
monkey_remove_from_pack()
{
	for ( i = 0; i < level.monkey_pack.size; i++ )
	{
		pack = level.monkey_pack[i];

		for ( j = 0; j < pack.monkeys.size; j++ )
		{
			if ( self == pack.monkeys[j] )
			{
				pack.monkeys = array_remove( pack.monkeys, self );
				if ( pack.monkeys.size == 0 && pack.spawning_done )
				{
					if ( isdefined( pack.perk ) )
					{
						pack.perk.targeted = 0;
					}

					level.monkey_packs_killed++;
					flag_set( "monkey_pack_down" );
					level.monkey_pack = array_remove( level.monkey_pack, pack );
				}
			}
		}
	}

	if ( level.monkey_packs_killed >= level.monkey_pack_max )
	{
		flag_set( "last_monkey_down" );

		if ( flag( "monkey_free_perk" ) )
		{
			forward = VectorNormalize( AnglesToForward( self.angles ) );
			end_pos = self.origin - vector_scale( forward, 32 );

			level thread maps\_zombiemode_powerups::specific_powerup_drop( "free_perk", end_pos );
		}

		drop_pos = self.origin;

		if ( self.state == "attack_perk" || !self.dropped )
		{
			drop_pos = self.attack.origin;
		}

		level thread maps\_zombiemode_powerups::specific_powerup_drop( "full_ammo", drop_pos );
	}
}

monkey_zombie_can_drop_free_perk()
{
	if ( !flag( "monkey_free_perk" ) )
	{
		return false;
	}

	max_perks = level.max_perks;

	// if player has used all lives in solo, there is 1 less perk available
	if ( flag( "solo_game" ) )
	{
		if ( level.solo_lives_given >= level.max_solo_lives )
		{
			players = getplayers();
			if ( !players[0] HasPerk( "specialty_quickrevive" ) )
			{
				max_perks--;
			}
		}
	}

	// if all players have max perks, powerup will not drop
	players = getplayers();
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	for ( i = 0; i < players.size; i++ )
	{
		num_perks = 0;
		for ( j = 0; j < vending_triggers.size; j++ )
		{
			perk = vending_triggers[j].script_noteworthy;
			if ( players[i] HasPerk( perk ) )
			{
				num_perks++;
			}
		}
		if ( num_perks < max_perks )
		{
			return true;
		}
	}

	return false;
}

//-----------------------------------------------------------------
// handles monkey death
//-----------------------------------------------------------------
monkey_zombie_die()
{
	self maps\_zombiemode_spawner::reset_attack_spot();

	self.grenadeAmmo = 0;

	self thread maps\_zombiemode_audio::do_zombies_playvocals( "death", self.animname );
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();

	PlayFX( level._effect["monkey_death"], self.origin );

	// Give attacker points

	//ChrisP - 12/8/08 - added additional 'self' argument
	level maps\_zombiemode_spawner::zombie_death_points( self.origin, self.damagemod, self.damagelocation, self.attacker,self );

    //C. Ayers: Adding in player dialog for successfully killing a monkey
    if( RandomIntRange(0,100) >= 75 )
    {
        if( IsDefined( self.attacker ) && IsPlayer( self.attacker ) )
            self.attacker maps\_zombiemode_audio::create_and_play_dialog( "kill", "space_monkey" );
    }

	if( self.damagemod == "MOD_BURNED" )
	{
		self thread animscripts\zombie_death::flame_death_fx();
	}

	level.monkey_death++;
	level.monkey_death_total++;

	self monkey_remove_from_pack();

	return false;
}

//-----------------------------------------------------------------
// handles different types of damage
//-----------------------------------------------------------------
monkey_custom_damage( player )
{
	self endon( "death" );

	damage = self.meleeDamage;

	if ( isDefined( self.ground_hit ) && self.ground_hit )
	{
		damage = int( player.maxhealth * 0.25 );
	}

	return damage;
}

//-----------------------------------------------------------------
// default entrance after spawning, should usually override
//-----------------------------------------------------------------
monkey_zombie_default_enter_level()
{
	Playfx( level._effect["monkey_spawn"], self.origin );
	playsoundatposition( "zmb_bolt", self.origin );
	PlayRumbleOnPosition("explosion_generic", self.origin);
}

//-----------------------------------------------------------------
// alternate to regular zombie pathing
//-----------------------------------------------------------------
monkey_pathing()
{
	self endon( "death" );

	while ( 1 )
	{
		if( IsDefined( self.favoriteenemy ) )
		{
			self.ignoreall = false;
			self OrientMode( "face default" );
			self SetGoalPos( self.favoriteenemy.origin );
		}

		wait_network_frame();
	}
}

//-----------------------------------------------------------------
// alternate to zombie find flesh
//-----------------------------------------------------------------
monkey_find_flesh()
{
	self endon( "death" );
	level endon( "intermission" );
	self endon( "stop_find_flesh" );

	if( level.intermission )
	{
		return;
	}

	self maps\_zombiemode_spawner::zombie_history( "monkey find flesh -> start" );

	self.goalradius = 48;

	players = getplayers();
	self.ignore_player = [];

	player = get_closest_valid_player( self.origin, self.ignore_player );
	if( !isDefined( player ) )
	{
		self maps\_zombiemode_spawner::zombie_history( "monkey find flesh -> can't find player, continue" );
		//wait( 1 );
		//continue;
	}

	self.favoriteenemy = player;

	while( 1 )
	{
		// update enemy based on the pack
		if ( isdefined( self.pack ) && isdefined( self.pack.enemy ) )
		{
			if ( !isdefined( self.favoriteenemy ) || self.favoriteenemy != self.pack.enemy )
			{
				self.favoriteenemy = self.pack.enemy;
			}
		}

		if ( isdefined( level.user_ryan_monkey_pathing ) )
		{
			self thread maps\_zombiemode_ai_monkey::monkey_pathing();
		}
		else
		{
			self thread maps\_zombiemode_spawner::zombie_pathing();
		}

		self.zombie_path_timer = GetTime() + ( RandomFloatRange( 1, 3 ) * 1000 );
		while( GetTime() < self.zombie_path_timer )
		{
			wait( 0.1 );
		}

		self maps\_zombiemode_spawner::zombie_history( "monkey find flesh -> bottom of loop" );

		debug_print( "Zombie is re-acquiring enemy, ending breadcrumb search" );
		self notify( "zombie_acquire_enemy" );
	}
}

//-----------------------------------------------------------------
// TEMP - just a way to give perks health for now
//-----------------------------------------------------------------
monkey_zombie_setup_perks()
{
	vending_triggers = getentarray( "zombie_vending", "targetname" );

	for ( i = 0; i < vending_triggers.size; i++ )
	{
		vending_triggers[i] monkey_zombie_perk_init();
	}
}

monkey_zombie_perk_init()
{
	self.targeted = 0;

	machine = undefined;

	targets = getentarray( self.target, "targetname" );
	for ( i = 0; i < targets.size; i++ )
	{
		if ( targets[i].classname == "script_model" )
		{
			machine = targets[i];
			break;
		}
	}

	assertex( isdefined( machine ), "no machine found for " + self.target );
	if ( isdefined( machine ) )
	{
		machine.monkey_health = 100;
	}
}

monkey_zombie_perk_damage( amount )
{
	if ( !isdefined( self.perk ) )
	{
		return true;
	}

	machine = self.pack.machine;
	machine.monkey_health -= amount;

	if ( machine.monkey_health < 0 )
	{
		machine.monkey_health = 0;
	}

	//monkey_print( self.perk.script_noteworthy + " damage " + amount + " health " + machine.monkey_health );

	return machine.monkey_health == 0;
}

monkey_pack_take_perk()
{
	players = getplayers();

	self.perk.targeted = 0;
	perk = self.perk.script_noteworthy;

	for ( i = 0; i < players.size; i++ )
	{
		if ( players[i] HasPerk( perk ) )
		{
			//iprintln("taking perk " + perk);
			perk_str = perk + "_stop";
			players[i] notify( perk_str );

			/*if ( flag( "solo_game" ) && perk == "specialty_quickrevive" )
			{
				players[i].lives--;
				level.solo_lives_given--;
			}*/
		}
	}
	//iprintln("took perk");
}

monkey_perk_lost( perk )
{
	if ( perk == "specialty_armorvest" )
	{
		if ( self.health > self.maxhealth )
		{
			self.health = self.maxhealth;
		}
	}

	self maps\_zombiemode_perks::update_perk_hud();
}

monkey_perk_bought( perk )
{
	flag_set( "perk_bought" );
	level.perk_bought_func = undefined;
}

//-----------------------------------------------------------------
// start flashing the perk icon
//-----------------------------------------------------------------
monkey_pack_flash_perk( perk, damage )
{
	if ( !isdefined( perk ) )
	{
		return;
	}

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] maps\_zombiemode_perks::perk_hud_start_flash( perk, damage );
	}
}

//-----------------------------------------------------------------
// stop flashing the perk icon
//-----------------------------------------------------------------
monkey_pack_stop_flash( perk, taken )
{
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] maps\_zombiemode_perks::perk_hud_stop_flash( perk, taken );
	}
}

//-----------------------------------------------------------------
// returns the zone that the monkey is in
//-----------------------------------------------------------------
monkey_get_zone()
{
	zone = undefined;
	keys = getarraykeys( level.zones );

	for ( i = 0; i < keys.size; i++ )
	{
		zone = level.zones[ keys[i] ];
		for ( j = 0; j < zone.volumes.size; j++ )
		{
			if ( self isTouching( zone.volumes[j] ) )
			{
				return zone;
			}
		}
	}

	assertex( isdefined( zone ), "monkey is NOT in a zone" );
	return zone;
}

//-----------------------------------------------------------------
// override for getting hit by thundergun
//-----------------------------------------------------------------
monkey_fling( player )
{
	monkey_print( "fling monkey damage" );

	damage = int( level.monkey_zombie_health * 0.5 );
	self DoDamage( damage, self.origin, self );

	// might do rollback anim here...
	forward = VectorNormalize( AnglesToForward( self.angles ) );
	attack_dir = VectorNormalize( self.origin - player.origin );
	dot = VectorDot( attack_dir, forward );
	if ( dot < 0 )
	{
		end_pos = self.origin - vector_scale( forward, 120 );

		if ( sightTracePassed( self.origin, end_pos, false, self ) )
		{
			recordLine( self.origin, end_pos, (0,1,0), "Script", self );
			roll_anim = [];
			roll_anim[ roll_anim.size ] = %ai_zombie_monkey_thundergun_roll_01;
			roll_anim[ roll_anim.size ] = %ai_zombie_monkey_thundergun_roll_02;
			roll_anim[ roll_anim.size ] = %ai_zombie_monkey_thundergun_roll_03;
			roll_anim[ roll_anim.size ] = %ai_zombie_monkey_thundergun_roll_04;

			rollback_anim = roll_anim[ RandomInt( roll_anim.size ) ];
			//self SetFlaggedAnimKnobAllRestart( "throw_back_anim", throw_back_anim, %body, 1, .1, 1 );
			self animscripted( "rollback_anim", self.origin, self.angles, rollback_anim );
			animscripts\traverse\zombie_shared::wait_anim_length( rollback_anim, .02 );
		}
		else
		{
			recordLine( self.origin, end_pos, (1,0,0), "Script", self );
		}
	}

	self.thundergun_fling_func = undefined;
}

monkey_revive_solo_fx()
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

//-----------------------------------------------------------------
// debug
//-----------------------------------------------------------------
monkey_print( str )
{
/#
	if ( is_true( level.debug_monkey ) )
	{
		iprintln( str + "\n" );
	}
#/
}

play_random_monkey_vox()
{
    self endon( "death" );

    while(1)
    {
        self thread maps\_zombiemode_audio::do_zombies_playvocals( "ambient", "monkey_zombie" );

		wait(RandomFloatRange(1.25,3));
    }
}
