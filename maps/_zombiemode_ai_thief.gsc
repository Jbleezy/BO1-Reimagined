#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

init()
{
	PrecacheRumble( "explosion_generic" );
	PrecacheItem( "zombie_gunstolen" );

	init_thief_zombie_anims();

	level._effect["ape_spawn"] = loadfx("maps/zombie/fx_zombie_ape_spawn_dust");
	level._effect["tech_trail"] = loadfx("maps/zombie/fx_zombie_tech_trail");

	if ( GetDvar( #"scr_thief_health_pregame" ) == "" )
	{
		SetDvar( "scr_thief_health_pregame", "15000" );
	}

	if ( GetDvar( #"scr_thief_health_endgame" ) == "" )
	{
		SetDvar( "scr_thief_health_endgame", "15000" );
	}

	if ( GetDvar( #"scr_thief_speed_damage" ) == "" )
	{
		SetDvar( "scr_thief_speed_damage", "2000" );
	}

	if ( GetDvar( #"scr_thief_health_max" ) == "" )
	{
		SetDvar( "scr_thief_health_max", "40000" );
	}

	// Function that will be used to calculate the value of different spawners when choosing which to use when spawning new ape
	// Functions that overload this, should return an int, with a higher value indicating a better spawner
	if( !isDefined( level.thief_zombie_spawn_heuristic ) )
	{
		level.thief_zombie_spawn_heuristic = maps\_zombiemode_ai_thief::thief_zombie_default_spawn_heuristic;
	}

	if ( !isDefined( level.thief_zombie_enter_level ) )
	{
		level.thief_zombie_enter_level = maps\_zombiemode_ai_thief::thief_zombie_default_enter_level;
	}

	precacheshellshock( "electrocution" );

	// Number of current active thief zombies
	level.num_thief_zombies = 0;

	level.thief_zombie_spawners = GetEntArray( "thief_zombie_spawner", "targetname" );
	array_thread( level.thief_zombie_spawners, ::add_spawn_function, maps\_zombiemode_ai_thief::thief_prespawn );

	if( !isDefined( level.max_thief_zombies ) )
	{
		level.max_thief_zombies = 1;
	}
	if( !isDefined( level.thief_thundergun_damage ) )
	{
		level.thief_thundergun_damage = 250;
	}
	if ( !isDefined( level.max_thief_portals ) )
	{
		level.max_thief_portals = 5;
	}
	if ( !isDefined( level.thief_health_multiplier ) )
	{
		level.thief_health_multiplier = 1000;
	}
	if ( !isDefined( level.max_thief_health ) )
	{
		level.max_thief_health = 30000;
	}

	level.thief_debug = true;
	level.thief_info = true;

	level.thief_intermission = false;
	flag_init( "thief_round" );
	flag_clear( "thief_round" );
	flag_init( "tgun_react" );
	flag_clear( "tgun_react" );
	flag_init( "last_thief_down" );
	flag_clear( "last_thief_down" );
	flag_init( "death_in_pre_game" ); // ww: flag for pre game death

	level thread thief_round_tracker();

	level thread thief_init_portals();

	thief_init_trap_clips();
}

thief_init_trap_clips()
{
	nh_clip = getent( "trap_quickrevive_clip", "targetname" );
	sh_clip = getent( "trap_elevator_clip", "targetname" );

	nh_clip.realorigin = nh_clip.origin;
	sh_clip.realorigin = sh_clip.origin;

	nh_clip.origin += ( 0, 0, 10000 );
	nh_clip connectpaths();

	sh_clip.origin += ( 0, 0, 10000 );
	sh_clip connectpaths();
}

#using_animtree( "generic_human" );
thief_prespawn()
{
	self.animname = "thief_zombie";

	self.custom_idle_setup = maps\_zombiemode_ai_thief::thief_zombie_idle_setup;

	self.a.idleAnimOverrideArray = [];
	self.a.idleAnimOverrideArray["stand"] = [];
	self.a.idleAnimOverrideWeights["stand"] = [];
	self.a.idleAnimOverrideArray["stand"][0][0] 	= %ai_zombie_tech_idle_base;
	self.a.idleAnimOverrideWeights["stand"][0][0] 	= 10;
	self.a.idleAnimOverrideArray["stand"][0][1] 	= %ai_zombie_tech_idle_base;
	self.a.idleAnimOverrideWeights["stand"][0][1] 	= 10;

	rand = randomIntRange( 1, 5 );
	self.deathanim = level.scr_anim["thief_zombie"]["death"+rand];

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

	if ( isdefined( level.user_ryan_thief ) )
	{
		self thread maps\_zombiemode_ai_thief::thief_health_watch();
	}

	self.freezegun_damage = 0;

	self.dropweapon = false;
	self thread maps\_zombiemode_spawner::zombie_damage_failsafe();

	self thread maps\_zombiemode_spawner::delayed_zombie_eye_glow();	// delayed eye glow for ground crawlers (the eyes floated above the ground before the anim started)
	self.meleeDamage = 1;

	self.entered_level = false;
	self.taken = false;
	self.no_powerups = true;
	self.blink = false;
	self.bonfire = true;

	self setTeamForEntity( "axis" );

	self.actor_damage_func = ::thief_actor_damage;
	self.freezegun_damage_response_func = ::thief_freezegun_damage_response;
	self.deathanimscript = ::thief_post_death;
	self.zombie_damage_claymore_func = ::thief_damage_claymore;
	self.nuke_damage_func = ::thief_nuke_damage;

	self.pregame_damage = 0;
	self.endgame_damage = 0;
	self.speed_damage = 0;

	self.ignore_solo_last_stand = 1;

	self.light = [];
	for ( i = 0; i < 5; i++ )
	{
		self.light[i] = 0;
	}

	self thread maps\_zombiemode_spawner::play_ambient_zombie_vocals();

	self notify( "zombie_init_done" );
}

thief_health_watch()
{
	self endon( "death" );

	while ( 1 )
	{
		/#
		iprintln( "health = " + self.health );
		#/

		wait( 1 );
	}
}

thief_zombie_idle_setup()
{
	self.a.array["turn_left_45"] = %exposed_tracking_turn45L;
	self.a.array["turn_left_90"] = %exposed_tracking_turn90L;
	self.a.array["turn_left_135"] = %exposed_tracking_turn135L;
	self.a.array["turn_left_180"] = %exposed_tracking_turn180L;
	self.a.array["turn_right_45"] = %exposed_tracking_turn45R;
	self.a.array["turn_right_90"] = %exposed_tracking_turn90R;
	self.a.array["turn_right_135"] = %exposed_tracking_turn135R;
	self.a.array["turn_right_180"] = %exposed_tracking_turn180L;
	self.a.array["exposed_idle"] = array( %ai_zombie_tech_idle_base, %ai_zombie_tech_idle_base );
	self.a.array["straight_level"] = %ai_zombie_tech_idle_base;
	self.a.array["stand_2_crouch"] = %ai_zombie_shot_leg_right_2_crawl;
}

init_thief_zombie_anims()
{
	// deaths
	level.scr_anim["thief_zombie"]["death1"] 	= %ai_zombie_tech_death_fallbackward;
	level.scr_anim["thief_zombie"]["death2"] 	= %ai_zombie_tech_death_fallforward;
	level.scr_anim["thief_zombie"]["death3"] 	= %ai_zombie_tech_death_fallbackward;
	level.scr_anim["thief_zombie"]["death4"] 	= %ai_zombie_tech_death_fallforward;

	// run cycles

	level.scr_anim["thief_zombie"]["walk1"] 	= %ai_zombie_electrician_walk;
	level.scr_anim["thief_zombie"]["walk2"] 	= %ai_zombie_electrician_walk;
	level.scr_anim["thief_zombie"]["walk3"] 	= %ai_zombie_electrician_walk;
	level.scr_anim["thief_zombie"]["walk4"] 	= %ai_zombie_electrician_walk;
	level.scr_anim["thief_zombie"]["walk5"] 	= %ai_zombie_electrician_walk;
	level.scr_anim["thief_zombie"]["walk6"] 	= %ai_zombie_electrician_walk;
	level.scr_anim["thief_zombie"]["walk7"] 	= %ai_zombie_electrician_walk;
	level.scr_anim["thief_zombie"]["walk8"] 	= %ai_zombie_electrician_walk;

	level.scr_anim["thief_zombie"]["run1"] 	= %ai_zombie_simianaut_run_man;
	level.scr_anim["thief_zombie"]["run2"] 	= %ai_zombie_electrician_run_v2;
	level.scr_anim["thief_zombie"]["run3"] 	= %ai_zombie_simianaut_run_man;
	level.scr_anim["thief_zombie"]["run4"] 	= %ai_zombie_simianaut_run_man;
	level.scr_anim["thief_zombie"]["run5"] 	= %ai_zombie_simianaut_run_man;
	level.scr_anim["thief_zombie"]["run6"] 	= %ai_zombie_simianaut_run_man;

	level.scr_anim["thief_zombie"]["sprint1"] = %ai_zombie_electrician_run;
	level.scr_anim["thief_zombie"]["sprint2"] = %ai_zombie_electrician_run;
	level.scr_anim["thief_zombie"]["sprint3"] = %ai_zombie_electrician_run;
	level.scr_anim["thief_zombie"]["sprint4"] = %ai_zombie_electrician_run;

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
	level._zombie_melee["thief_zombie"] = [];
	level._zombie_walk_melee["thief_zombie"] = [];
	level._zombie_run_melee["thief_zombie"] = [];

	level._zombie_melee["thief_zombie"][0] 				= %ai_zombie_tech_grab;
	level._zombie_melee["thief_zombie"][1] 				= %ai_zombie_tech_grab;
	level._zombie_melee["thief_zombie"][2] 				= %ai_zombie_tech_grab;
	level._zombie_melee["thief_zombie"][3] 				= %ai_zombie_tech_grab;
	//level._zombie_melee["thief_zombie"][3] 				= %ai_zombie_tech_grab;

	//level._zombie_walk_melee["thief_zombie"][0]			= %ai_zombie_boss_walk_headhit;

	level._zombie_run_melee["thief_zombie"][0]				=	%ai_zombie_tech_grab;
	level._zombie_run_melee["thief_zombie"][1]				=	%ai_zombie_tech_grab;
	level._zombie_run_melee["thief_zombie"][2]				=	%ai_zombie_tech_grab;

	// deaths
	if( !isDefined( level._zombie_deaths ) )
	{
		level._zombie_deaths = [];
	}
	level._zombie_deaths["thief_zombie"] = [];
	level._zombie_deaths["thief_zombie"][0] = %ai_zombie_tech_death_fallbackward;
	level._zombie_deaths["thief_zombie"][1] = %ai_zombie_tech_death_fallforward;
	level._zombie_deaths["thief_zombie"][2] = %ai_zombie_tech_death_fallbackward;
	level._zombie_deaths["thief_zombie"][3] = %ai_zombie_tech_death_fallforward;

	//taunts
	if( !isDefined( level._zombie_run_taunt ) )
	{
		level._zombie_run_taunt = [];
	}
	if( !isDefined( level._zombie_board_taunt ) )
	{
		level._zombie_board_taunt = [];
	}

	level._zombie_run_taunt["thief_zombie"] = [];
	level._zombie_board_taunt["thief_zombie"] = [];

	level._zombie_board_taunt["thief_zombie"][0] = %ai_zombie_tech_taunt_a;
	level._zombie_board_taunt["thief_zombie"][1] = %ai_zombie_tech_taunt_b;
}

thief_zombie_spawn()
{
	self.script_moveoverride = true;

	if( !isDefined( level.num_thief_zombies ) )
	{
		level.num_thief_zombies = 0;
	}
	level.num_thief_zombies++;

	thief_zombie = self maps\_zombiemode_net::network_safe_stalingrad_spawn( "thief_zombie_spawn", 1 );

	self.count = 666;

	self.last_spawn_time = GetTime();

	if( !spawn_failed( thief_zombie ) )
	{
		thief_zombie.script_noteworthy = self.script_noteworthy;
		thief_zombie.targetname = self.targetname;
		thief_zombie.target = self.target;
		thief_zombie.deathFunction = maps\_zombiemode_ai_thief::thief_zombie_die;
		thief_zombie.animname = "thief_zombie";

		thief_zombie.exit_origin = thief_zombie.origin;

		thief_zombie Hide();
		thief_zombie thief_teleport(level.portal_power);
		thief_zombie Show();

		thief_zombie thread thief_zombie_think();
	}
	else
	{
		level.num_thief_zombies--;
	}
}

thief_round_spawning()
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

	level.thief_intermission = true;
	level thread thief_round_aftermath();
	max = 1;
	level.zombie_total = max;

	count = 0;
	while( count < max )
	{
		spawner = thief_zombie_pick_best_spawner();
		if ( isdefined( spawner ) )
		{
			spawner thief_zombie_spawn();
			level.zombie_total--;
			count++;
			break;
		}
	}
}

// Waits for the time and the ai to die
thief_round_wait()
{
/#
	if ( GetDvarInt( #"zombie_cheat" ) == 2 || GetDvarInt( #"zombie_cheat" ) >= 4 )
	{
		level waittill("forever");
	}
#/

	wait( 1 );

	if ( flag( "thief_round" ) )
	{
		wait( 7 );
		while ( level.thief_intermission )
		{
			wait( 0.5 );
		}
	}
}

thief_round_aftermath()
{
	flag_wait( "last_thief_down" );

    level thread maps\_zombiemode_audio::change_zombie_music( "dog_end" );
    level notify( "stop_thief_alarms" );
	level.round_spawn_func = level.thief_save_spawn_func;
	level.round_wait_func = level.thief_save_wait_func;

	wait( 6 );
	level.thief_intermission = false;
}

thief_round_tracker()
{
	flag_wait( "power_on" );

	level.thief_save_spawn_func = level.round_spawn_func;
	level.thief_save_wait_func = level.round_wait_func;

	level.next_thief_round = level.round_number + randomintrange( 1, 3 );
	level.prev_thief_round = level.next_thief_round;

	if(level.next_thief_round - level.round_number == 1)
	{
		level.prev_thief_round_amount = 4;
	}
	else
	{
		level.prev_thief_round_amount = 5;
	}

	while ( 1 )
	{
		level waittill( "between_round_over" );

		if ( level.round_number >= level.next_thief_round )
		{
			level.music_round_override = true;
			level.thief_save_spawn_func = level.round_spawn_func;
			level.thief_save_wait_func = level.round_wait_func;

			thief_round_start();

			level.round_spawn_func = ::thief_round_spawning;
			level.round_wait_func = ::thief_round_wait;

			if(!IsDefined(level.prev_thief_round_amount))
			{
				level.prev_thief_round = level.next_thief_round;
				level.prev_thief_round_amount = RandomIntRange( 4, 6 );
				level.next_thief_round = level.round_number + level.prev_thief_round_amount;
			}
			else
			{
				if(level.prev_thief_round_amount == 4)
				{
					level.prev_thief_round = level.next_thief_round;
					level.next_thief_round = level.round_number + 5;
					level.prev_thief_round_amount = undefined;
				}
				else
				{
					level.prev_thief_round = level.next_thief_round;
					level.next_thief_round = level.round_number + 4;
					level.prev_thief_round_amount = undefined;
				}
			}

			//level.prev_thief_round = level.next_thief_round;
			//level.next_thief_round = level.round_number + randomintrange( 4, 6 );
		}
		else if ( level.prev_thief_round == level.round_number )
		{
			level.music_round_override = true;
			thief_round_start();
		}
		else if ( flag( "thief_round" ) )
		{
			thief_round_stop();
			level.music_round_override = false;
		}
	}
}

thief_round_start()
{
	flag_set( "thief_round" );

	//AUDIO: Got rid of typical announcer vox
	level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_thiefstart" );
	level thread play_looping_alarms( 7 );
	level thread maps\_zombiemode_audio::change_zombie_music( "dog_start" );

	if ( isDefined( level.thief_round_start ) )
	{
		level thread [[ level.thief_round_start ]]();
	}

	level thread thief_round_vision();

	self thread thief_trap_watcher();

	// turn lights off
	clientnotify( "TLF" );
}

thief_round_vision()
{
	// wait for audio before changing vision set
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		//players[i] VisionSetNaked( "zombie_pentagon_electrician", 1.0 );
		setClientSysState( "levelNotify", "vis4", players[i] );
		wait_network_frame();
	}
}
thief_round_stop()
{
	flag_clear( "thief_round" );
	flag_clear( "last_thief_down" );

	//play_sound_2D( "mus_zombie_dog_end" );

	if ( isDefined( level.thief_round_stop ) )
	{
		level thread [[ level.thief_round_stop ]]();
	}

	level thread maps\zombie_pentagon::change_pentagon_vision();

	self notify( "thief_trap_stop" );

	// turn lights on
	clientnotify( "TLO" );
}


//-----------------------------------------------------------------
// setup trap watch
//-----------------------------------------------------------------
thief_trap_watcher()
{
	traps = getentarray( "zombie_trap", "targetname" );
	sh_found = false;
	nh_found = false;
	for ( i = 0; i < traps.size; i++ )
	{
		if ( traps[i].target == "trap_elevator" && !sh_found )
		{
			sh_found = true;
			self thread thief_trap_watch( traps[i] );
		}
		if ( traps[i].target == "trap_quickrevive" && !nh_found )
		{
			nh_found = true;
			self thread thief_trap_watch( traps[i] );
		}
	}
}


//-----------------------------------------------------------------
// cut paths when the electric trap is turned on so he walks around
//-----------------------------------------------------------------
thief_trap_watch( trig )
{
	self endon( "death" );
	self endon( "thief_trap_stop" );

	clip = getent( trig.target + "_clip", "targetname" );
	clip.dis = false;

	self thread thief_trap_stop_watch(trig);

	while ( 1 )
	{
		if ( trig._trap_in_use == 1 && trig._trap_cooling_down == 0 && !clip.dis )
		{
			thief_print( "blocking " + trig.target );

			// block path
			clip.origin = clip.realorigin;
			clip disconnectpaths();
			clip.dis = true;
		}
		else if ( (trig._trap_in_use == 0 || trig._trap_cooling_down == 1) && clip.dis )
		{
			thief_print( "unblocking " + trig.target );

			clip.origin += ( 0, 0, 10000 );
			clip connectpaths();
			clip.dis = false;
		}

		wait_network_frame();
	}
}

thief_trap_stop_watch(trig)
{
	self endon( "death" );

	clip = getent( trig.target + "_clip", "targetname" );

	self waittill( "thief_trap_stop" );

	if(clip.dis)
	{
		thief_print( "unblocking " + trig.target );

		clip.origin += ( 0, 0, 10000 );
		clip connectpaths();
		clip.dis = false;
	}
}

thief_zombie_pick_best_spawner()
{
	best_spawner = undefined;
	best_score = -1;
	for( i = 0; i < level.thief_zombie_spawners.size; i++ )
	{
		score = [[ level.thief_zombie_spawn_heuristic ]]( level.thief_zombie_spawners[i] );
		if( score > best_score )
		{
			best_spawner = level.thief_zombie_spawners[i];
			best_score = score;
		}
	}
	return best_spawner;
}

thief_scale_health( health )
{
	players = getplayers();

	if ( players.size == 3 )
	{
		health = int( health * 0.8 );
	}
	else if ( players.size == 2 )
	{
		health = int( health * 0.6 );
	}
	else if ( players.size == 1 )
	{
		health = int( health * 0.3 );
	}

	return health;
}

thief_zombie_think()
{
	self endon( "death" );

	self thief_set_state( "stalking" );

	// ww: set the flag for pregame death
	flag_set( "death_in_pre_game" );

	self thread thief_zombie_choose_run();

	self.goalradius = 32;
	self.ignoreall = false;
	self.pathEnemyFightDist = 64;
	self.meleeAttackDist = 64;

	start_health = level.round_number * level.thief_health_multiplier;
	if ( start_health > level.max_thief_health )
	{
		start_health = level.max_thief_health;
	}
	//start_health = thief_scale_health( start_health );
	//pregame_health = thief_scale_health( GetDvarInt( #"scr_thief_health_pregame" ) );
	self.maxhealth = start_health;
	self.health = start_health;

	self thief_print( "start_health = " + start_health );

	if ( isdefined( level.user_ryan_thief_health ) )
	{
		self.maxhealth = 1;
		self.health = 1;
	}

	//try to prevent always turning towards the enemy
	self.maxsightdistsqrd = 96 * 96;

	self.zombie_move_speed = "walk";


	//self thread [[ level.thief_zombie_enter_level ]]();

	self thief_zombie_setup_victims();

	self.fx_org = spawn( "script_model", self.origin );
	self.fx_org SetModel( "tag_origin" );
	self.fx_org.angles = self.angles;
	self.fx_org linkto( self );
	PlayFxOnTag( level._effect["tech_trail"], self.fx_org, "tag_origin" );

	self thread thief_zombie_hunt();
}

thief_zombie_hunt()
{
	self endon( "death" );
	self endon( "end_hunt" );


	while ( 1 )
	{
		self thread thief_zombie_victim_disconnect();
		self thief_zombie_set_visibility();
		self thief_portal_to_victim();

		self thread thief_check_vision();
		self thread thief_try_steal();
		self thread thief_chasing();

		self waittill( "next_victim" );
	}
}

thief_zombie_victim_disconnect()
{
	self endon( "death" );
	self endon( "victim_done" );

	player = self.victims.current;
	if ( isDefined( player ) )
	{
		player waittill( "disconnect" );
	}

	self notify( "end_hunt" );
	if ( self thief_get_next_victim() )
	{
		wait_network_frame();
		self thread thief_zombie_hunt();
	}
}

thief_zombie_default_spawn_heuristic( spawner )
{
	score = 0;

	players = get_players();

	for( i = 0; i < players.size; i++ )
	{
		score = int( distanceSquared( spawner.origin, players[i].origin ) );
	}

	return score;
}

thief_zombie_choose_run()
{
	self endon( "death" );

	while( true )
	{
		if( self.thief_speed == "sprint" )
		{
			self.zombie_move_speed = "sprint";
			rand = randomIntRange( 1, 4 );
			rand = 1;
			self set_run_anim( "sprint"+rand );
			self.run_combatanim = level.scr_anim[self.animname]["sprint"+rand];
			self.crouchRunAnim = level.scr_anim[self.animname]["sprint"+rand];
			self.crouchrun_combatanim = level.scr_anim[self.animname]["sprint"+rand];
		}
		else if ( self.thief_speed == "run2" )
		{
			self.zombie_move_speed = "run";
			self set_run_anim( "run2" );
			self.run_combatanim = level.scr_anim[self.animname]["run2"];
			self.crouchRunAnim = level.scr_anim[self.animname]["run2"];
			self.crouchrun_combatanim = level.scr_anim[self.animname]["run2"];
		}
		else if ( self.thief_speed == "run" )
		{
			self.zombie_move_speed = "run";
			self set_run_anim( "run1" );
			self.run_combatanim = level.scr_anim[self.animname]["run1"];
			self.crouchRunAnim = level.scr_anim[self.animname]["run1"];
			self.crouchrun_combatanim = level.scr_anim[self.animname]["run1"];
		}
		else if ( self.thief_speed == "walk" )
		{
			self.zombie_move_speed = "walk";
			self set_run_anim( "walk1" );
			self.run_combatanim = level.scr_anim[self.animname]["walk1"];
			self.crouchRunAnim = level.scr_anim[self.animname]["walk1"];
			self.crouchrun_combatanim = level.scr_anim[self.animname]["walk1"];
		}
		self.needs_run_update = true;
		wait( 0.05 );
	}
}

thief_zombie_die()
{
	self maps\_zombiemode_spawner::reset_attack_spot();
	self unlink();

	self.grenadeAmmo = 0;

	if ( isdefined( self.worldgun ) )
	{
		self.worldgun unlink();
		wait_network_frame();
		self.worldgun delete();
	}

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] FreezeControls( false );
		players[i] EnableOffhandWeapons();
		players[i] EnableWeaponCycling();

		players[i] AllowLean( true );
		players[i] AllowAds( true );
		players[i] AllowSprint( true );
		players[i] AllowProne( true );
		players[i] AllowMelee( true );

		players[i] Unlink();
	}

	// ww: check to see if he died during the pregame
	if( flag( "death_in_pre_game" ) )
	{
		players = getplayers();
		for ( i = 0; i < players.size; i++ )
		{
			if ( isDefined( players[i].thief_damage ) && players[i].thief_damage )
			{
				players[i] giveachievement_wrapper( "SP_ZOM_TRAPS" );
			}
		}

		if ( self.bonfire )
		{
			// drop bonfire sale
			level thread maps\_zombiemode_powerups::specific_powerup_drop( "bonfire_sale", self.origin );
		}
	}
	else
	{
		level thread maps\_zombiemode_powerups::specific_powerup_drop( "fire_sale", self.origin );
	}

	forward = VectorNormalize( AnglesToForward( self.angles ) );
	endPos = self.origin - vector_scale( forward, 32 );

	level thread maps\_zombiemode_powerups::specific_powerup_drop( "full_ammo", endPos );

    self thread maps\_zombiemode_audio::do_zombies_playvocals( "death", self.animname );

	// Give attacker points

	//ChrisP - 12/8/08 - added additional 'self' argument
	level maps\_zombiemode_spawner::zombie_death_points( self.origin, self.damagemod, self.damagelocation, self.attacker,self );

	if( self.damagemod == "MOD_BURNED" )
	{
		self thread animscripts\zombie_death::flame_death_fx();
	}

	self thief_return_loot();
	self thief_shutdown_lights();
	self thief_clear_portals();

	flag_set( "last_thief_down" );
	level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_thiefend_good" );

	return false;
}


//-----------------------------------------------------------------
// cleanup fx
//-----------------------------------------------------------------
thief_post_death()
{
	if ( IsDefined( self.fx_org ) )
	{
		self.fx_org delete();
	}
}


//-----------------------------------------------------------------
// force player to look at the thief
//-----------------------------------------------------------------
thief_turn_player()
{
	self endon( "death" );

	player = self.victims.current;

	facingThief = VectorToAngles( self.origin - player.origin );

	player thread thief_watch_controls( self );
	if ( self.health > 0 )	// in case somehow this thread was still running when thief died
	{
		player FreezeControls( true );
	}
	thief_print( player.playername + " locked" );

	//player SetPlayerAngles( facingThief );

	lerp_time = 0.25;

	// make sure to unlink player if the thief dies during the lerp
	player lerp_player_view_to_position( player.origin, facingThief, lerp_time, 1 );
	wait( lerp_time );

	dist = Distance( self.origin, player.origin );
	thief_print( "grab dist = " + dist );

}


//-----------------------------------------------------------------
// give back control if thief dies during player lock
//-----------------------------------------------------------------
thief_watch_controls( thief )
{
	self endon( "released" );
	self endon( "disconnect" );

	zombie_attack = %ai_zombie_tech_grab;
	animLen = getAnimLength( zombie_attack );
	time = 0.5 + animLen;
	thief waittill_notify_or_timeout( "death", time );
	self FreezeControls( false );
	thief_print( self.playername + " released from watch" );
}


//-----------------------------------------------------------------
// take money, weapons, or perks, don't take claymores
//-----------------------------------------------------------------
thief_take_loot()
{
	player = self.victims.current;

	//self.victim_score = self.victims.current.score;
	//self.victims.current maps\_zombiemode_score::minus_to_player_score( self.victim_score );

	//ammo = self.victims.current GetWeaponAmmoStock( weapon );
	//self.victim_ammo = ammo;

	// take ammo
	//self.victim SetWeaponAmmoStock( weapon, 0 );

	weapon = player GetCurrentWeapon();

	is_laststand = player maps\_laststand::player_is_in_laststand();

	// don't take these items...choose random primary instead
	if ( is_offhand_weapon( weapon ) || weapon == "zombie_bowie_flourish" || weapon == "none" || isSubStr( weapon, "zombie_perk_bottle" ) || is_laststand || weapon == "zombie_knuckle_crack" )
	{
		primaries = player GetWeaponsListPrimaries();
		if( isDefined( primaries ) )
		{
			// don't take last stand pistol
			if ( is_laststand && primaries.size > 1 )
			{
				for ( i = 0; i < primaries.size; i++ )
				{
					if ( primaries[i] == weapon )
					{
						primaries = array_remove( primaries, primaries[i] );
						break;
					}
				}
			}

			if ( primaries.size > 0 )
			{
				pick = RandomInt(100) % primaries.size;
				weapon = primaries[ pick ];
			}
			else
			{
				weapon = undefined;
			}
		}
	}

	if ( isDefined( weapon ) && weapon != "none")
	{
		// spawn weapon in hand
		model = GetWeaponModel( weapon );
		pos = self GetTagOrigin( "TAG_WEAPON_RIGHT" );
		self.worldgun = spawn( "script_model", pos );
		self.worldgun.angles = self GetTagAngles( "TAG_WEAPON_RIGHT" );
		self.worldgun setModel( model );
		self.worldgun linkto( self, "TAG_WEAPON_RIGHT" );

		// take weapon
		player.weapons_list = player GetWeaponsList();
		if( is_weapon_attachment( weapon ) )
		{
			weapon = player get_baseweapon_for_attachment( weapon );
		}

		player TakeWeapon( weapon );
		thief_print( "taking " + weapon );

		if ( isDefined( player.lastActiveWeapon ) && player.lastActiveWeapon == weapon )
		{
			player.lastActiveWeapon = "none";
		}

		// don't give minigun powerup back
		if ( weapon == "minigun_zm" )
		{
			player maps\_zombiemode_powerups::minigun_weapon_powerup_off();
			weapon = undefined;
		}
	}

	self.victims.weapon[ self.victims.current_idx ] = weapon;

	player thread player_do_knuckle_crack();
}


//-----------------------------------------------------------------
// give back whatever was taken
//-----------------------------------------------------------------
thief_return_loot()
{
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		for ( j = 0; j < self.victims.player.size; j++ )
		{
			if ( players[i] == self.victims.player[j] )
			{
				if ( isDefined( self.victims.weapon[j] ) )
				{
					// more than weapon_limit...take one and return the thief's
					weapon_limit = 2;
					if ( players[i] HasPerk( "specialty_additionalprimaryweapon" ) )
					{
						weapon_limit = 3;
					}

					primaries = players[i] GetWeaponsListPrimaries();
					if ( isDefined( primaries ) && primaries.size >= weapon_limit )
					{
						weapon = players[i] GetCurrentWeapon();

						// don't take these items...choose random primary instead
						if ( is_offhand_weapon( weapon ) || weapon == "zombie_bowie_flourish" || isSubStr( weapon, "zombie_perk_bottle" ) )
						{
							weapon = primaries[weapon_limit - 1];
						}

						// player got the weapon the thief stole
						if ( players[i] HasWeapon( self.victims.weapon[j] ) )
						{
							weapon = self.victims.weapon[j];
						}

						// player has non-upgrade version of what the thief stole
						for ( k = 0; k < primaries.size; k++ )
						{
							if ( !maps\_zombiemode_weapons::is_weapon_upgraded( primaries[k] ) )
							{
								weapon_upgraded = level.zombie_weapons[ primaries[k] ].upgrade_name;
								if ( weapon_upgraded == self.victims.weapon[j] )
								{
									weapon = primaries[k];
									break;
								}
							}
						}

						players[i] TakeWeapon( weapon );
						primaries = players[i] GetWeaponsListPrimaries();
					}

					if ( isDefined( primaries ) && primaries.size < weapon_limit )
					{
						players[i] GiveWeapon( self.victims.weapon[j], 0, players[i] maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( self.victims.weapon[j] ) );
						players[i] SwitchToWeapon( self.victims.weapon[j] );
					}
				}
			}
		}
	}
}


//-----------------------------------------------------------------
// make sure all the lights are out when thief dies
//-----------------------------------------------------------------
thief_shutdown_lights()
{
	for ( i = 0; i < self.light.size; i++ )
	{
		if ( isDefined( self.light[i] ) && self.light[i] )
		{
			light = "por" + i;
			clientnotify( light );
		}
	}
}


//-----------------------------------------------------------------
// what happens when thief spawns
//-----------------------------------------------------------------
thief_zombie_default_enter_level()
{
	Playfx( level._effect["ape_spawn"], self.origin );
	playsoundatposition( "zmb_bolt", self.origin );
	PlayRumbleOnPosition("explosion_generic", self.origin);

	self.entered_level = true;
}


//-----------------------------------------------------------------
// checks if ent is in the pack room
//-----------------------------------------------------------------
thief_is_packing()
{
	zone = level.zones[ "conference_level2" ];
	for ( i = 0; i < zone.volumes.size; i++ )
	{
		if ( self isTouching( zone.volumes[i] ) )
		{
			return true;
		}
	}

	trig = getent( "pack_room_trigger", "targetname" );
	if ( self isTouching( trig ) )
	{
		return true;
	}

	return false;
}


//-----------------------------------------------------------------
// use portals to track down victim
//-----------------------------------------------------------------
thief_chasing()
{
	self endon( "stop_thief_chasing" );
	self endon( "death" );
	self.victims.current endon( "disconnect" );

	player = self.victims.current;

	//self thread thief_elevator_watch();

	while ( 1 )
	{
		if ( flag( "defcon_active" ) )
		{
			packing_self = self thief_is_packing();
			packing_player = player thief_is_packing();

			// get player in pack room
			if ( packing_player != packing_self )
			{
				floor_self = thief_check_floor( self );
				portal = self thief_find_nearest_portal( floor_self );
				thief_print( "running to " + portal.script_string );
				self thief_enter_portal( portal );

				floor_player = thief_check_floor( player );
				portal = player thief_find_nearest_portal( floor_player );
				self thief_teleport( portal );
				thief_print( "portal to " + portal.script_string );
			}
		}

		floor_self = thief_check_floor( self );
		floor_player = thief_check_floor( player );

		if ( floor_self != floor_player )
		{
			thief_print( "player portal or elevator" );
			portal = self thief_find_nearest_portal( floor_self );

			if ( IsDefined( portal ) )
			{
				thief_print( "running to " + portal.script_string );
				self thief_enter_portal( portal );

				if ( IsDefined( player.end_portal ) )
				{
					portal = player.end_portal;
				}
				else
				{
					portal = player thief_find_nearest_portal( floor_player );
				}
				self thief_teleport( portal );
				thief_print( "portal to " + portal.script_string );
			}
		}
		if ( IsDefined( player ) )
		{
			self.ignoreall = true;
			self OrientMode( "face default" );
			self SetGoalPos( player.origin );
		}

		wait_network_frame();
	}
}


//-----------------------------------------------------------------
// get portal closest to current location
//-----------------------------------------------------------------
thief_find_nearest_portal( floor )
{
	portal = undefined;

	if ( floor == 1 )
	{
		return level.portal_top;
	}
	else if ( floor == 2 )
	{
		if ( self thief_is_packing() )
		{
			return level.portal_pack;
		}

		return level.portal_mid;
	}
	else if ( floor == 3 )
	{
		portal = level.portal_power;
		max = DistanceSquared( self.origin, level.portal_power.origin );
		for ( i = 0; i < level.portal_bottom.size; i++ )
		{
			distSq = DistanceSquared( self.origin, level.portal_bottom[i].origin );
			if ( distSq < max )
			{
				max = distSq;
				portal = level.portal_bottom[i];
			}
		}
	}

	return portal;
}


//-----------------------------------------------------------------
// endgame health becomes lower
//-----------------------------------------------------------------
thief_adjust_health()
{
	thief_info( "Pregame damage = " + self.pregame_damage );

	// lower health during the chase
	if ( self.health > GetDvarInt( #"scr_thief_health_endgame" ) )
	{
		players = getplayers();
		if ( players.size == 4 )
		{
			self.health = GetDvarInt( #"scr_thief_health_endgame" );
		}
		else if ( players.size == 3 )
		{
			self.health = int( GetDvarInt( #"scr_thief_health_endgame" ) * .75 );
		}
		else if ( players.size == 2 )
		{
			self.health = int( GetDvarInt( #"scr_thief_health_endgame" ) * .5 );
		}
		else
		{
			self.health = int( GetDvarInt( #"scr_thief_health_endgame" ) * .25 );
		}
	}
}


//-----------------------------------------------------------------
// play a "steal" anim
//-----------------------------------------------------------------
thief_steal()
{
	self endon( "death" );
	self.victims.current endon( "disconnect" );

	self.state = "stealing";

	self notify( "stop_thief_chasing" );
	self notify( "stop_watch_chase_speed" );

	self SetVisibleToAll();

	self thief_turn_player();
	self thief_take_loot();

	thief_print( "starting grab anim" );

	zombie_attack = %ai_zombie_tech_grab;

	self thread maps\_zombiemode_audio::do_zombies_playvocals( "steal", self.animname );

	//self SetFlaggedAnimKnobAllRestart("meleeanim", zombie_attack, %body, 1, .2, 1);
	time = getAnimLength( zombie_attack );
	self animscripted( "meleeanim", self.origin, self.angles, zombie_attack, "normal", %body, 1 );
	//animscripts\traverse\zombie_shared::wait_anim_length(zombie_attack, .02);
	wait( time );

	// pregame is over after the 1st steal
	if ( flag( "death_in_pre_game" ) )
	{
		// ww: clear pre game death flag
		flag_clear( "death_in_pre_game" );
	}

	self thief_take_player();
}


//-----------------------------------------------------------------
// get close enough to steal from victim
//-----------------------------------------------------------------
thief_try_steal()
{
	self endon( "death" );
	self.victims.current endon( "disconnect" );

	STEAL_DIST = 64;
	STEAL_DIST2 = STEAL_DIST * STEAL_DIST;

	player = self.victims.current;

	while ( 1 )
	{
		if ( IsDefined( player.teleporting ) && player.teleporting )
		{
			wait_network_frame();
			continue;
		}

		if ( DistanceSquared( self.origin, player.origin ) < STEAL_DIST2 )
		{
			self SetGoalPos( self.origin );
			break;
		}
		wait_network_frame();
	}

	self thread thief_steal();
}


//-----------------------------------------------------------------
// decide order that players will be picked
//-----------------------------------------------------------------
thief_zombie_setup_victims()
{
	players = get_players();

	self.victims = spawnstruct();
	self.victims.max = players.size;
	self.victims.player = [];
	self.victims.weapon = [];

	self.victims.seen = false;

	// get players and mix them up
	for ( i = 0; i < players.size; i++ )
	{
		players[i].victim = false;
		self.victims.player[i] = players[i];
		self.victims.player[i].thief_damage = false;
	}

	if ( !isDefined( level.user_ryan_thief_victim ) )
	{
		self.victims.player = array_randomize( self.victims.player );
	}
	self.victims.current_idx = 0;
	self.victims.current = self.victims.player[ self.victims.current_idx ];
}

//-----------------------------------------------------------------
// get the next victim in the list
//-----------------------------------------------------------------
thief_get_next_victim()
{
	self.victims.current_idx++;

	if ( self.victims.current_idx >= self.victims.max )
	{
		self thread thief_end_game();
		return 0;
	}
	else
	{
		self thief_set_state( "stalking" );

		self.victims.current = self.victims.player[ self.victims.current_idx ];
		self notify( "next_victim" );
		thief_print( self.victims.current.playername + " is next" );
	}

	return 1;
}


//-----------------------------------------------------------------
// update speed based on the state
//-----------------------------------------------------------------
thief_set_state( state )
{
	if ( isDefined( self.state ) && self.state == state )
	{
		thief_print( "already in " + state );
		return;
	}

	self.state = state;

	if ( state == "stalking" )
	{
		self.thief_speed = "walk";
	}
	else if ( state == "chasing" )
	{
		self.thief_speed = "run2";
		self.chase_damage = self.maxhealth * 0.15;
	}
	else if ( state == "sprinting" )
	{
		self.thief_speed = "sprint";
	}

	thief_print( self.state );
}


//-----------------------------------------------------------------
// set invisible to victims that haven't been hit
//-----------------------------------------------------------------
thief_zombie_set_visibility()
{
	self SetVisibleToAll();

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		if ( i > self.victims.current_idx )
		{
			self SetInvisibleToPlayer( self.victims.player[i] );
		}
	}
}


//-----------------------------------------------------------------
// portal to victim's floor
//-----------------------------------------------------------------
thief_portal_to_victim()
{
	self thief_set_state( "stalking" );

	// portal to victim's floor
	floor_victim = thief_check_floor( self.victims.current );
	floor_self = thief_check_floor( self );

	if ( floor_victim != floor_self )
	{
		self thief_goto_portal( floor_self );
		self thief_portal_to_portal( floor_victim );
	}
}


//-----------------------------------------------------------------
// run to the portal on this floor
//-----------------------------------------------------------------
thief_goto_portal( floor )
{
	self endon( "death" );

	if ( self.victims.current_idx == 0 )
	{
		// sprint to first portal in "stalking" state
		self.thief_speed = "sprint";
	}

	if ( floor == 1 )
	{
		thief_print( "goto_portal 1" );
		self thief_enter_portal( level.portal_top );
	}
	else if ( floor == 2 )
	{
		if ( self thief_is_packing() )
		{
			thief_print( "goto_portal pack" );
			self thief_enter_portal( level.portal_pack );
		}
		else
		{
			thief_print( "goto_portal 2" );
			self thief_enter_portal( level.portal_mid );
		}
	}
	else if ( floor == 3 )
	{
		portal = RandomIntRange( 0, level.portal_bottom.size );
		thief_print( "goto_portal bottom " + portal );
		self thief_enter_portal( level.portal_bottom[portal] );
	}
}


//-----------------------------------------------------------------
// do the actual teleport
//-----------------------------------------------------------------
thief_portal_to_portal( floor )
{
	self endon( "death" );

	if ( self.state == "stalking" )
	{
		self.thief_speed = "walk";
	}

	if ( floor == 1 )
	{
		thief_print( "portal to top" );
		self thief_teleport( level.portal_top );
	}
	else if ( floor == 2 )
	{
		if ( self.victims.current thief_is_packing() )
		{
			thief_print( "portal to pack" );
			self thief_teleport( level.portal_pack );
		}
		else
		{
			thief_print( "portal to war room" );
			self thief_teleport( level.portal_mid );
		}
	}
	else if ( floor == 3 )
	{
		portal = RandomIntRange( 0, level.portal_bottom.size );
		thief_print( "portal to bottom" );
		self thief_teleport( level.portal_bottom[portal] );
	}
}


//-----------------------------------------------------------------
// used if portal on the victim's floor is disabled
//-----------------------------------------------------------------
thief_run_to_floor()
{
	self endon( "death" );

	while ( 1 )
	{
		floor_victim = thief_check_floor( self.victim );
		floor = thief_check_floor( self );

		if ( floor_victim != floor )
		{
			self.is_activated = true;
		}
		else
		{
			break;
		}

		wait_network_frame();
	}

	self.is_activated = false;
}

//-----------------------------------------------------------------
// become visible when shot
//-----------------------------------------------------------------
thief_blink( attacker )
{
	self endon( "death" );
	self endon( "restart_blink" );
	attacker endon( "restart_blink_player" );

	if ( !IsPlayer( attacker ) )
	{
		return;
	}

	if ( self.blink )
	{
		return;
	}

	if ( self.state == "exiting" )
	{
		return;
	}

	self.blink = true;

	// visible to everyone
	self SetVisibleToAll();
	wait( 0.2 );

	if ( self.state != "exiting" )
	{
		players = getplayers();
		for ( i = 0; i < players.size; i++ )
		{
			if ( i > self.victims.current_idx )
			{
				self SetInvisibleToPlayer( self.victims.player[i] );
			}
		}

		wait( 0.2 );
	}

	self.blink = false;
}

//-----------------------------------------------------------------
// damage override, track some stats
//-----------------------------------------------------------------
thief_actor_damage( weapon, damage, attacker )
{
	//self thread thief_blink( attacker );

	if ( isdefined( attacker ) )
	{
		thief_info( attacker.playername + " " + weapon + " " + damage );
		attacker.thief_damage = true;
	}

	if ( self.state == "exiting" )
	{
		self.endgame_damage += damage;
	}
	else
	{
		self.pregame_damage += damage;
	}

	if ( weapon != "freezegun_zm" && weapon != "freezegun_upgraded_zm" )
	{
		self.speed_damage += damage;
	}

	if ( self.state == "stalking" )
	{
		self thief_set_state( "chasing" );
	}
	else if ( self.state == "chasing" )
	{
		if ( isDefined( self.chase_damage ) )
		{
			self.chase_damage -= damage;
			if ( self.chase_damage <= 0 )
			{
				thief_print( "chase_damage exceeded...sprint" );
				self thief_set_state( "sprinting" );
			}
		}
	}

	// disable bonfire if player used insta-kill
	if ( level.zombie_vars["zombie_insta_kill"] )
	{
		self.bonfire = false;
	}

	return damage;
}

//-----------------------------------------------------------------
// setup the portals for thief use
//-----------------------------------------------------------------
thief_init_portals()
{
	level.portal_pack = undefined;
	level.portal_power = undefined;
	level.portal_top = undefined;
	level.portal_mid = undefined;
	level.portal_bottom = [];

	pos = getstructarray( "zombie_pos", "script_noteworthy" );
	for ( i = 0; i < pos.size; i++ )
	{
		if ( pos[i].script_string == "bottom_floor_5" )
		{
			level.portal_power = pos[i];
		}
		else if ( pos[i].script_string == "top_floor_1" )
		{
			level.portal_top = pos[i];
		}
		else if ( pos[i].script_string == "mid_floor_1" )
		{
			level.portal_mid = pos[i];
		}
		else if ( pos[i].script_string == "mid_floor_2" )
		{
			level.portal_pack = pos[i];
		}
		else if ( pos[i].script_string == "bottom_floor_1" )
		{
			level.portal_bottom[0] = pos[i];
		}
		else if ( pos[i].script_string == "bottom_floor_2" )
		{
			level.portal_bottom[1] = pos[i];
		}
		else if ( pos[i].script_string == "bottom_floor_3" )
		{
			level.portal_bottom[2] = pos[i];
		}
		else if ( pos[i].script_string == "bottom_floor_4" )
		{
			level.portal_bottom[3] = pos[i];
		}
	}
}

//-----------------------------------------------------------------
// tells what floor entity is on
//-----------------------------------------------------------------
thief_check_floor( ent )
{
	floor1 = getent( "thief_floor_1", "targetname" );
	floor2 = getent( "thief_floor_2", "targetname" );
	floor3 = getent( "thief_floor_3", "targetname" );

	if ( ent IsTouching( floor1 ) )
	{
		return 1;
	}
	else if ( ent IsTouching( floor2 ) )
	{
		return 2;
	}
	else if ( ent IsTouching( floor3 ) )
	{
		return 3;
	}

	return 0;
}


//-----------------------------------------------------------------
// portal with the player to the power room
//-----------------------------------------------------------------
thief_take_player()
{
	self endon( "death" );

	player = self.victims.current;
	player thief_cooldown_power_room();

	player_pos = getstructarray( "player_pos", "script_noteworthy" );
	dest = undefined;
	for ( i = 0; i < player_pos.size; i++ )
	{
		if ( isdefined( player_pos[i].script_string ) && player_pos[i].script_string == "thief_player_pos" )
		{
			dest = player_pos[i];
		}
	}
	thief_pos = getstruct( "thief_start", "targetname" );

	PlayFX(level._effect["transporter_start"], self.origin);
	PlayFX(level._effect["transporter_start"], player.origin);

	playsoundatposition( "evt_teleporter_out", player.origin );

	if ( isdefined( self.worldgun ) )
	{
		self.worldgun unlink();
		wait_network_frame();
		self.worldgun delete();
	}

	wait_network_frame();

	self thread thief_teleport( thief_pos );

	if ( self.health > 0 && isDefined( dest ) )
	{
		player SetOrigin( dest.origin );
		player SetPlayerAngles( dest.angles );
	}

	playsoundatposition( "evt_teleporter_go", player.origin );

	wait_network_frame();

	//self thief_reaction();

	self.can_speed_up = true;

	player FreezeControls( false );
	player notify( "released" );

	self notify( "victim_done" );
	self thief_get_next_victim();
}


//-----------------------------------------------------------------
// cool down the power room portal for the player
//-----------------------------------------------------------------
thief_cooldown_power_room()
{
	trig = undefined;

	for ( i = 0; i < level.portal_trig.size; i++ )
	{
		zombie_dest = getstructarray( level.portal_trig[i].target, "targetname" );
		for ( j = 0; j < zombie_dest.size; j++ )
		{
			if ( isdefined( zombie_dest[j].script_noteworthy ) && zombie_dest[j].script_noteworthy == "zombie_pos" )
			{
				if ( zombie_dest[j].script_string == "bottom_floor_5" )
				{
					trig = level.portal_trig[i];
				}
			}
		}
	}

	if ( isdefined( trig ) )
	{
		trig thread maps\zombie_pentagon_teleporter::cooldown_portal_timer( self );
	}
}


//-----------------------------------------------------------------
// player anim to show something was stolen
//-----------------------------------------------------------------
player_knuckle_crack_begin()
{
	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowCrouch(true);
	self AllowProne( false );
	self AllowMelee( false );

	self.holding = self GetCurrentWeapon();

	weapon = "zombie_gunstolen";
	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	self DisableOffhandWeapons();
	self DisableWeaponCycling();
}

player_do_knuckle_crack()
{
	if(self HasPerk("specialty_fastreload"))
	{
		self UnSetPerk("specialty_fastswitch");
	}

	self player_knuckle_crack_begin();

	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );

	if(self HasPerk("specialty_fastreload"))
	{
		self SetPerk("specialty_fastswitch");
	}

	self player_knuckle_crack_end();
}

player_knuckle_crack_end()
{
	self EnableOffhandWeapons();
	self EnableWeaponCycling();

	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );
	self AllowMelee( true );
	weapon = "zombie_gunstolen";

	self TakeWeapon(weapon);
	primaries = self GetWeaponsListPrimaries();
	if ( isDefined( self.holding ) && self HasWeapon( self.holding ) )
	{
		self SwitchToWeapon( self.holding );
	}
	else if( isDefined( primaries ) && primaries.size > 0 )
	{
		self SwitchToWeapon( primaries[0] );
	}
}


//-----------------------------------------------------------------
// goto the bottom floor, will only happen on the last victim disconnecting
//-----------------------------------------------------------------
thief_goto_bottom()
{
	self endon( "death" );

	floor_self = thief_check_floor( self );

	if ( floor_self != 3 )
	{
		thief_print( "not on floor 3" );

		self thief_goto_portal( floor_self );

		thief_pos = getstruct( "thief_start", "targetname" );
		self thief_teleport( thief_pos );
	}
}


//-----------------------------------------------------------------
// run through portals in order (4-3-2-1) before exiting at power
//-----------------------------------------------------------------
thief_end_game()
{
	self endon( "death" );

	self thief_goto_bottom();

	//self thief_adjust_health();

	self SetVisibleToAll();
	PlayFxOnTag( level._effect["elec_torso"], self, "J_SpineLower" );

	//thief_print( "begin end game" );

	portal_count = level.max_thief_portals - 1;
	portal_current = 0;

	portal_order = [];
	portal_order[0] = 3;
	portal_order[1] = 2;
	portal_order[2] = 1;
	portal_order[3] = 0;

	portal_start = -1;
	portal_last = -1;
	portal_end = -1;

	self.state = "exiting";

	self thread thief_watch_speed_damage();

	// portal 4 light on
	thief_light( 4, 1 );

	while ( 1 )
	{
		// run to a portal
		idx = portal_order[ portal_current ];
		portal_start = idx;

		self thief_enter_portal( level.portal_bottom[idx] );

		portal_current++;
		idx_next = undefined;
		if ( portal_current < 4 )
		{
			idx_next = portal_order[ portal_current ];
		}

		// portal to random
		portal_end = RandomIntRange( 0, 4 );
		playsoundatposition( "evt_teleporter_out", self.origin );

		// don't portal to start
		if ( portal_end == portal_start )
		{
			portal_end = thief_get_next_portal( portal_end );
			if ( isdefined( idx_next ) && portal_end == idx_next )
			{
				portal_end = thief_get_next_portal( portal_end );
			}
		}
		// don't portal to next
		if ( isdefined( idx_next ) && portal_end == idx_next )
		{
			portal_end = thief_get_next_portal( portal_end );
			if ( portal_end == portal_start )
			{
				portal_end = thief_get_next_portal( portal_end );
			}
		}

		self thief_teleport( level.portal_bottom[portal_end] );

		self.speed_damage = 0;
		self.thief_speed = "run2";
		self.can_speed_up = true;
		self notify( "stop_check_walk" );

		thief_light( portal_count, 0 );

		portal_count--;
		if ( portal_count == 0 )
		{
			break;
		}

		thief_light( portal_count, 1 );

		wait_network_frame();
		playsoundatposition( "evt_teleporter_go", self.origin );
	}

	self thief_exit_level();
}


//-----------------------------------------------------------------
// flip lights near portals
//-----------------------------------------------------------------
thief_light( index, on )
{
	self.light[ index ] = on;
	light = "por" + index;
	clientnotify( light );
}


//-----------------------------------------------------------------
// run to power room and portal out
//-----------------------------------------------------------------
thief_exit_level()
{
	self endon( "death" );

	// power room light on
	thief_light( 0, 1 );

	self.portal_pos = level.portal_power.origin;
	self thief_enter_portal( level.portal_power );

	drop_pos = getstruct( "thief_start", "targetname" );
	level thread maps\_zombiemode_powerups::specific_powerup_drop( "full_ammo", drop_pos.origin );

	// power room light off
	thief_light( 0, 0 );

	thief_info( "Endgame damage = " + self.endgame_damage );

	flag_set( "last_thief_down" );
	level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_thiefend_bad" );

	if ( IsDefined( self.fx_org ) )
	{
		self.fx_org delete();
	}

	self delete();
}

//-----------------------------------------------------------------
// wrap portal index
//-----------------------------------------------------------------
thief_get_next_portal( portal )
{
	portal++;
	if ( portal >= 4 )
	{
		return 0;
	}
	return portal;
}


//-----------------------------------------------------------------
// as thief takes damage, he slows down
//-----------------------------------------------------------------
thief_watch_speed_damage()
{
	self endon( "death" );

	self.speed_damage = 0;

	max = GetDvarInt( #"scr_thief_speed_damage" );
	while ( 1 )
	{
		if ( self.speed_damage > max )
		{
			self.speed_damage = 0;

			if ( self.thief_speed == "run2" )
			{
				self.thief_speed = "run";
				self notify( "stop_thief_freeze_countdown" );
				self.can_speed_up = false;
			}
			else if ( self.thief_speed == "run" )
			{
				self thread thief_check_walk();
			}
		}
		wait_network_frame();
	}
}


//-----------------------------------------------------------------
// how close thief is to the portal
//-----------------------------------------------------------------
thief_check_walk()
{
	self endon( "death" );
	self endon( "stop_check_walk" );

	while ( 1 )
	{
		if ( isDefined( self.portal_pos ) )
		{
			portal_distance = DistanceSquared( self.origin, self.portal_pos );
			if ( portal_distance < 128 * 128 )
			{
				self.thief_speed = "walk";
				break;
			}
		}

		wait_network_frame();
	}
}


//-----------------------------------------------------------------
// react to seeing player and start chasing
//-----------------------------------------------------------------
thief_check_vision()
{
	self endon( "death" );
	self.victims.current endon( "disconnect" );

	VISION_DIST = 12 * 75;
	VISION_DIST2 = VISION_DIST * VISION_DIST;
	VISION_ANGLE = .766;	// 40 degrees

	time_seen = 0;

	while ( 1 )
	{
		if ( self.state != "stalking" )
		{
			break;
		}

		player = self.victims.current;
		if ( !IsDefined( player ) )
		{
			break;
		}

		floor_self = thief_check_floor( self );
		floor_player = thief_check_floor( player );

		if ( floor_self != floor_player )
		{
			wait_network_frame();
			continue;
		}

		org = self geteye();
		player_org = player geteye();

		dist2 = DistanceSquared( org, player_org );
		if ( dist2 > VISION_DIST2 )
		{
			wait_network_frame();
			continue;
		}

		forward = VectorNormalize( AnglesToForward( self.angles ) );
		toPlayer = VectorNormalize( player_org - org );
		cosAngle = VectorDot( forward, toPlayer );

		if ( cosAngle < VISION_ANGLE )
		{
			wait_network_frame();
			continue;
		}

		if ( BulletTracePassed( org, player_org, false, undefined ) )
		{
			time_seen += 0.05;
		}

		if ( time_seen >= 0.5 )
		{
			self OrientMode("face enemy");
			thief_print( "see victim" );

			self.victims.seen = true;

			if ( self.state == "stalking" )
			{
				self thief_reaction();
				self thief_set_state( "chasing" );
			}

			self OrientMode("face default");
			break;
		}

		wait( 0.1 );
	}

	self.thief_speed = "run2";
	self.can_speed_up = true;
	self thread thief_watch_chase_speed();
}


//-----------------------------------------------------------------
// switch to sprinting if can't get to victim in 5 seconds
//-----------------------------------------------------------------
thief_watch_chase_speed()
{
	self endon( "death" );
	self endon( "stop_watch_chase_speed" );

	wait( 5 );

	self thief_set_state( "sprinting" );
}


//-----------------------------------------------------------------
// play a random taunt anim
//-----------------------------------------------------------------
thief_reaction()
{
	// play taunt / reaction
	index = RandomIntRange( 0, 2 );
	zombie_taunt = level._zombie_board_taunt[self.animname][index];

	self thread maps\_zombiemode_audio::do_zombies_playvocals( "anger", self.animname );

	time = getAnimLength( zombie_taunt ) / 1.5;
	self animscripted( "reactanim", self.origin, self.angles, zombie_taunt, "normal", %body, 1.5 );
	wait( time );
}


//-----------------------------------------------------------------
// slow thief down when hit by freeze gun
//-----------------------------------------------------------------
thief_freezegun_damage_response( player, amount )
{
	self.freezegun_damage += amount;

	if ( self.thief_speed == "run2" )
	{
		self.thief_speed = "run";
		thief_print( "going to run" );
	}
	else if ( self.thief_speed == "run" )
	{
		self notify( "stop_thief_freeze_countdown" );
		thief_print( "5 more secs" );
	}

	self thread thief_freeze_countdown( 5 );
	self thread maps\_zombiemode_weap_freezegun::freezegun_set_extremity_damage_fx();

	return 1;
}


//-----------------------------------------------------------------
// scale down damage from claymore
//-----------------------------------------------------------------
thief_damage_claymore( mod, hit_location, hit_origin, player )
{
	bonus_damage = level.round_number * randomintrange( 50, 100 );
	if ( bonus_damage > 2000 )
	{
		bonus_damage = 2000;
	}

	if ( isdefined( player ) && isalive( player ) )
	{
		self DoDamage( bonus_damage, self.origin, player);
	}
	else
	{
		self DoDamage( bonus_damage, self.origin, undefined );
	}
}


//-----------------------------------------------------------------
// no bonfire if killed by nuke
//-----------------------------------------------------------------
thief_nuke_damage()
{
	self endon( "death" );

	return;

	/*self.bonfire = false;

	self thread animscripts\zombie_death::flame_death_fx();
	self playsound ("evt_nuked");
	self dodamage( self.health + 666, self.origin );*/
}


//-----------------------------------------------------------------
// how long before thief can speed back up
//-----------------------------------------------------------------
thief_freeze_countdown( time )
{
	self endon( "death" );
	self endon( "stop_thief_freeze_countdown" );

	wait( time );

	if ( self.can_speed_up == true )
	{
		self.thief_speed = "run2";
	}

	self thread maps\_zombiemode_weap_freezegun::freezegun_clear_extremity_damage_fx();
	self thread maps\_zombiemode_weap_freezegun::freezegun_clear_torso_damage_fx();
}


//-----------------------------------------------------------------
// go to a portal and play fx
//-----------------------------------------------------------------
thief_enter_portal( portal )
{
	self endon( "death" );

	self.portal_pos = portal.origin;
	self setgoalpos( portal.origin );
	self waittill( "goal" );

	PlayFX(level._effect["transporter_start"], self.origin);
	playsoundatposition( "evt_teleporter_out", self.origin);

	for ( i = 0; i < level.portal_trig.size; i++ )
	{
		if ( self IsTouching( level.portal_trig[i] ) )
		{
			/#
			zombie_dest = getstructarray( level.portal_trig[i].target, "targetname" );
			for ( j = 0; j < zombie_dest.size; j++ )
			{
				if ( isdefined( zombie_dest[j].script_noteworthy ) && zombie_dest[j].script_noteworthy == "zombie_pos" )
				{
					thief_print( "touch enter " + zombie_dest[j].script_string );
				}
			}
			#/

			self.portal_trig_enter = level.portal_trig[i];
			break;
		}
	}
}

//-----------------------------------------------------------------
// coming out of a portal
//-----------------------------------------------------------------
thief_teleport( portal )
{
	self endon( "death" );

	so = spawn( "script_origin", self.origin );
	so.angles = self.angles;
	self linkto( so );
	so.origin = portal.origin;
	so.angles = portal.angles;
	wait_network_frame();
	self unlink();
	so delete();
	PlayFX(level._effect["transporter_beam"], self.origin);
	playsoundatposition( "evt_teleporter_go", self.origin);

	for ( i = 0; i < level.portal_trig.size; i++ )
	{
		if ( self IsTouching( level.portal_trig[i] ) )
		{
			/#
			zombie_dest = getstructarray( level.portal_trig[i].target, "targetname" );
			for ( j = 0; j < zombie_dest.size; j++ )
			{
				if ( isdefined( zombie_dest[j].script_noteworthy ) && zombie_dest[j].script_noteworthy == "zombie_pos" )
				{
					thief_print( "touch exit " + zombie_dest[j].script_string );
				}
			}
			#/

			self.portal_trig_exit = i;

			self thread thief_override_portal();
			break;
		}
	}
}


//-----------------------------------------------------------------
// allow player to follow thief through portal
//-----------------------------------------------------------------
thief_override_portal()
{
	self endon( "death" );

	if ( isDefined( self.portal_trig_exit ) )
	{
		self.portal_trig_enter.thief_override = self.portal_trig_exit;
	}

	wait( 3 );

	self.portal_trig_enter.thief_override = undefined;
}


//-----------------------------------------------------------------
// clear overrides
//-----------------------------------------------------------------
thief_clear_portals()
{
	for ( i = 0; i < level.portal_trig.size; i++ )
	{
		level.portal_trig[i].thief_override = undefined;
	}
}


//-----------------------------------------------------------------
// debug helpers
//-----------------------------------------------------------------
thief_print( str )
{
	/#
	if ( isdefined( level.thief_debug ) && level.thief_debug == true )
	{
		iprintln( str );
	}
	#/
}

thief_info( str )
{
	/#
	if ( isdefined( level.thief_info ) && level.thief_info == true )
	{
		iprintln( str );
	}
	#/
}

thief_ship_cheat_round_2()
{
	wait( 1 );
	flag_set( "power_on" );
	wait( 1 );
	level.next_thief_round = 2;
	/#
	iprintlnbold( "thief cheat active" );
	#/
}

//AUDIO SECTION
play_looping_alarms( wait_time )
{
	level endon( "stop_thief_alarms" );

	if(is_true(level.playing_looping_alarms))
	{
		return;
	}

	level.playing_looping_alarms = true;

	if(IsDefined(wait_time))
	{
		wait( wait_time );
	}

    structs = getstructarray( "defcon_alarms", "targetname" );
    sound_ent = [];

    for(i=0;i<structs.size;i++)
    {
        sound_ent[i] = Spawn( "script_origin", structs[i].origin );
        sound_ent[i] PlayLoopSound( "evt_thief_alarm_looper", .25 );
    }

    level thread stop_looping_alarms(sound_ent);
}

stop_looping_alarms(sound_ent)
{
	level waittill( "stop_thief_alarms" );

	level.playing_looping_alarms = undefined;

    for(i=0;i<sound_ent.size;i++)
    {
        sound_ent[i] StopLoopSound( .5 );
    }

    wait(1);

    array_delete( sound_ent );
}

thief_elevator_watch()
{
	self endon( "death" );

	player = self.victims.current;

	while ( 1 )
	{
		if ( isDefined( player.elevator ) )
		{
			thief_print( "player in " + player.elevator_riding );
			break;
		}
		wait_network_frame();
	}

	epoints = getentarray( player.elevator_riding, "targetname" );
	dest = undefined;
	players = getplayers();
	too_close = false;
	index = -1;
	for ( i = 0; i < epoints.size; i++ )
	{
		for ( j = 0; j < players.size; j++ )
		{
			if ( Distance2DSquared( epoints.origin, players[i].origin ) > 30*30 )
			{
				too_close = true;
				break;
			}
		}
		if ( !too_close )
		{
			index = i;
			break;
		}
	}

	if ( index != -1 )
	{
		thief_print( "found elevator loc" );

		// portal to elevator
		so = spawn( "script_origin", self.origin );
		so.angles = self.angles;
		self linkto( so );
		so.origin = epoints[index].origin;
		so.angles = epoints[index].angles;
		wait_network_frame();
		self unlink();
		so delete();
	}
}
