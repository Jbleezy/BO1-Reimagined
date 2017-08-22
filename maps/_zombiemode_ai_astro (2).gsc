#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

//-----------------------------------------------------------------
// setup level related items
//-----------------------------------------------------------------
init()
{
	PrecacheRumble( "explosion_generic" );

	init_astro_zombie_anims();
	init_astro_zombie_fx();
	
	if ( !isDefined( level.astro_zombie_enter_level ) )
	{
		level.astro_zombie_enter_level = ::astro_zombie_default_enter_level;
	}

	// Number of current active astro zombies
	level.num_astro_zombies = 0;

	level.astro_zombie_spawners = GetEntArray( "astronaut_zombie", "targetname" );
	array_thread( level.astro_zombie_spawners, ::add_spawn_function, maps\_zombiemode_ai_astro::astro_prespawn );

	// Counters and timers used by the astro, can be overloaded on a level by level basis
	level.max_astro_zombies = 1;
	level.astro_zombie_health_mult = 4;

	level.min_astro_round_wait = 1;
	level.max_astro_round_wait = 2;
	level.astro_round_start = 1;
	level.next_astro_round = level.astro_round_start + RandomIntRange( 0, level.max_astro_round_wait + 1 );

	level.zombies_left_before_astro_spawn = 1;

	level.zombie_left_before_spawn = 0;
	level.astro_explode_radius = 400;
	level.astro_explode_blast_radius = 150;

	level.astro_explode_pulse_min = 100;
	level.astro_explode_pulse_max = 300;

	level.astro_headbutt_delay = 2000;
	level.astro_headbutt_radius_sqr = 64 * 64;

	level.zombie_total_update = false;
	level.zombie_total_set_func = ::astro_zombie_total_update;

	maps\_zombiemode_spawner::register_zombie_damage_callback( ::astro_damage_callback );
}

//-----------------------------------------------------------------
// setup astro zombie
//-----------------------------------------------------------------
#using_animtree( "generic_human" );
astro_prespawn()
{
	self.animname = "astro_zombie";
	
	self.custom_idle_setup = ::astro_zombie_idle_setup;
	
	self.a.idleAnimOverrideArray = [];
	self.a.idleAnimOverrideArray["stand"] = [];
	self.a.idleAnimOverrideWeights["stand"] = [];
	self.a.idleAnimOverrideArray["stand"][0][0] 	= %ai_zombie_idle_v1_delta;
	self.a.idleAnimOverrideWeights["stand"][0][0] 	= 10;
	self.a.idleAnimOverrideArray["stand"][0][1] 	= %ai_zombie_idle_v1_delta;
	self.a.idleAnimOverrideWeights["stand"][0][1] 	= 10;

	self.ignoreall = true; 
	self.allowdeath = true; 			// allows death during animscripted calls
	self.is_zombie = true; 			// needed for melee.gsc in the animscripts
	self.has_legs = true; 			// Sumeet - This tells the zombie that he is allowed to stand anymore or not, gibbing can take 
															// out both legs and then the only allowed stance should be prone.
	self allowedStances( "stand" ); 

	self.gibbed = false; 
	self.head_gibbed = false;
	
	// might need this so co-op zombie players cant block zombie pathing
	//self PushPlayer( true ); 

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

	self.dropweapon = false; 
	self thread maps\_zombiemode_spawner::zombie_damage_failsafe();

	self maps\_zombiemode_spawner::set_zombie_run_cycle( "walk" );

	self thread maps\_zombiemode_spawner::delayed_zombie_eye_glow();	// delayed eye glow for ground crawlers (the eyes floated above the ground before the anim started)
	self.flame_damage_time = 0;
	self.meleeDamage = 50;
	self.no_powerups = true;
	self.no_gib = true;
	self.ignorelocationaldamage = true;

	self.actor_damage_func = ::astro_actor_damage;
	self.nuke_damage_func = ::astro_nuke_damage;
	self.custom_damage_func = ::astro_custom_damage;
	self.microwavegun_sizzle_func = ::astro_microwavegun_sizzle;

	//self.noChangeDuringMelee = true;

	self setTeamForEntity( "axis" );

	self.ignore_distance_tracking = true;
	self.ignore_enemy_count = true;
	self.ignore_gravity = true;
	self.ignore_devgui_death = true;
	self.ignore_nml_delete = true;
	self.ignore_round_spawn_failsafe = true;

	self.ignore_poi_targetname = [];
	self.ignore_poi_targetname[ self.ignore_poi_targetname.size ] = "zm_bhb";

	self notify( "zombie_init_done" );
}

//-----------------------------------------------------------------
// setup idles
//-----------------------------------------------------------------
astro_zombie_idle_setup()
{
	self.a.array["turn_left_45"] = %exposed_tracking_turn45L;
	self.a.array["turn_left_90"] = %exposed_tracking_turn90L;
	self.a.array["turn_left_135"] = %exposed_tracking_turn135L;
	self.a.array["turn_left_180"] = %exposed_tracking_turn180L;
	self.a.array["turn_right_45"] = %exposed_tracking_turn45R;
	self.a.array["turn_right_90"] = %exposed_tracking_turn90R;
	self.a.array["turn_right_135"] = %exposed_tracking_turn135R;
	self.a.array["turn_right_180"] = %exposed_tracking_turn180L;
	self.a.array["exposed_idle"] = array( %ai_zombie_idle_v1_delta, %ai_zombie_idle_v1_delta );
	self.a.array["straight_level"] = %ai_zombie_idle_v1_delta;
	self.a.array["stand_2_crouch"] = %ai_zombie_shot_leg_right_2_crawl;
}

//-----------------------------------------------------------------
// override anims
//-----------------------------------------------------------------
init_astro_zombie_anims()
{
	// deaths
	level.scr_anim["astro_zombie"]["death1"] 	= %ai_zombie_napalm_death_01;
	level.scr_anim["astro_zombie"]["death2"] 	= %ai_zombie_napalm_death_02;
	level.scr_anim["astro_zombie"]["death3"] 	= %ai_zombie_napalm_death_03;

	// run cycles
	level.scr_anim["astro_zombie"]["walk1"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["walk2"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["walk3"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["walk4"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["walk5"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["walk6"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["walk7"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["walk8"] 	= %ai_zombie_astro_walk_moon_v1;

	level.scr_anim["astro_zombie"]["run1"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["run2"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["run3"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["run4"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["run5"] 	= %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["run6"] 	= %ai_zombie_astro_walk_moon_v1;

	level.scr_anim["astro_zombie"]["sprint1"] = %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["sprint2"] = %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["sprint3"] = %ai_zombie_astro_walk_moon_v1;
	level.scr_anim["astro_zombie"]["sprint4"] = %ai_zombie_astro_walk_moon_v1;

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
	level._zombie_melee["astro_zombie"] = [];
	level._zombie_walk_melee["astro_zombie"] = [];
	level._zombie_run_melee["astro_zombie"] = [];

	level._zombie_melee["astro_zombie"][0] 				= %ai_zombie_attack_v2; 
	level._zombie_melee["astro_zombie"][1] 				= %ai_zombie_attack_v4; 
	level._zombie_melee["astro_zombie"][2] 				= %ai_zombie_attack_v6; 

	if( isDefined( level.astro_zombie_anim_override ) )
	{
		[[ level.astro_zombie_anim_override ]]();
	}

	// deaths
	if( !isDefined( level._zombie_deaths ) )
	{
		level._zombie_deaths = [];
	}
	level._zombie_deaths["astro_zombie"] = [];
	level._zombie_deaths["astro_zombie"][0] = %ai_zombie_napalm_death_01;
	level._zombie_deaths["astro_zombie"][1] = %ai_zombie_napalm_death_02;
	level._zombie_deaths["astro_zombie"][2] = %ai_zombie_napalm_death_03;

	//taunts
	if( !isDefined( level._zombie_run_taunt ) )
	{
		level._zombie_run_taunt = [];
	}
	if( !isDefined( level._zombie_board_taunt ) )
	{
		level._zombie_board_taunt = [];
	}
	
	level._zombie_run_taunt["astro_zombie"] = [];
	level._zombie_board_taunt["astro_zombie"] = [];
	
	level._zombie_board_taunt["astro_zombie"][0] = %ai_zombie_taunts_4;
	level._zombie_board_taunt["astro_zombie"][1] = %ai_zombie_taunts_7;
	level._zombie_board_taunt["astro_zombie"][2] = %ai_zombie_taunts_9;
	level._zombie_board_taunt["astro_zombie"][3] = %ai_zombie_taunts_5b;
	level._zombie_board_taunt["astro_zombie"][4] = %ai_zombie_taunts_5c;
	level._zombie_board_taunt["astro_zombie"][5] = %ai_zombie_taunts_5d;
	level._zombie_board_taunt["astro_zombie"][6] = %ai_zombie_taunts_5e;
	level._zombie_board_taunt["astro_zombie"][7] = %ai_zombie_taunts_5f;
}

//-----------------------------------------------------------------
// load fx
//-----------------------------------------------------------------
init_astro_zombie_fx()
{
	level._effect[ "astro_spawn" ] = loadfx( "maps/zombie/fx_zombie_boss_spawn" );
	level._effect[ "astro_explosion" ] = loadfx( "maps/zombie_moon/fx_moon_qbomb_explo_distort" );
}

//-----------------------------------------------------------------
// spawn an astro zombie
//-----------------------------------------------------------------
astro_zombie_spawn()
{
	self.script_moveoverride = true; 
	
	if( !isDefined( level.num_astro_zombies ) )
	{
		level.num_astro_zombies = 0;
	}
	level.num_astro_zombies++;
	
	astro_zombie = self maps\_zombiemode_net::network_safe_stalingrad_spawn( "astro_zombie_spawn", 1 );

	self.count = 100;
	
	if( !spawn_failed( astro_zombie ) ) 
	{ 
		astro_zombie.script_noteworthy = self.script_noteworthy;
		astro_zombie.targetname = self.targetname + "_ai";
		astro_zombie.target = self.target;
		astro_zombie.deathFunction = ::astro_zombie_die;
		astro_zombie.animname = "astro_zombie";
	
		astro_zombie thread astro_zombie_think();

		_debug_astro_print( "astro spawned in " + level.round_number );
	}
	else
	{
		level.num_astro_zombies--;
	}
	return astro_zombie;
}

//-----------------------------------------------------------------
// check if astro is allowed
//-----------------------------------------------------------------
astro_zombie_can_spawn()
{
	if ( !is_true( level.zombie_total_update ) )
	{
		return false;
	}

	if ( level.zombie_total > level.zombies_left_before_astro_spawn )
	{
		return false;
	}

	return true;
}

//-----------------------------------------------------------------
// handles when to spawn an astro
//-----------------------------------------------------------------
astro_zombie_manager()
{
	self notify( "astro_manager_end" );
	self endon( "astro_manager_end" );

	flag_wait( "all_players_connected" );

	spawner = getent( "astronaut_zombie", "targetname" );

	while ( true )
	{
		if ( !is_true( level.on_the_moon ) )
		{
			wait( 0.5 );
			continue;
		}

		if ( astro_zombie_can_spawn() )
		{
			astro = spawner astro_zombie_spawn();
			if ( !spawn_failed( astro ) )
			{
				break;
			}
			wait_network_frame();
		}

		wait( 0.5 );
	}
}

//-----------------------------------------------------------------
// how many zombies spawn before an astro
//-----------------------------------------------------------------
astro_zombie_total_update()
{
	level.zombie_total_update = true;
	level.zombies_left_before_astro_spawn = RandomIntRange( int( level.zombie_total * 0.25 ), int( level.zombie_total * 0.75 ) );

	if ( level.round_number >= level.next_astro_round && level.num_astro_zombies < level.max_astro_zombies )
	{
		level thread astro_zombie_manager();
	}

	_debug_astro_print( "next astro round = " + level.next_astro_round );
	_debug_astro_print( "zombies to kill = " +  ( level.zombie_total - level.zombies_left_before_astro_spawn ) );
}

//-----------------------------------------------------------------
// main update func
//-----------------------------------------------------------------
astro_zombie_think()
{
	self endon( "death" );
	
	self.entered_level = false;
	
	//self.goalradius = 128; 
	self.ignoreall = false;
	self.pathEnemyFightDist = 64;
	self.meleeAttackDist = 64;

	self.maxhealth = level.zombie_health * GetPlayers().size * level.astro_zombie_health_mult;
	self.health = self.maxhealth;
	
	//try to prevent always turning towards the enemy
	self.maxsightdistsqrd = 96 * 96;
	
	self.zombie_move_speed = "walk";

	self thread [[ level.astro_zombie_enter_level ]]();

	if ( isDefined( level.astro_zombie_custom_think ) )
	{
		self thread [[ level.astro_zombie_custom_think ]]();
	}

	self thread astro_zombie_headbutt_think();

	while( true )
	{
		if ( !self.entered_level )
		{
			wait_network_frame();
			continue;
		}
		else if ( is_true( self.custom_think ) )
		{
			wait_network_frame();
			continue;
		}
		else if( !isDefined( self.following_player ) || !self.following_player ) 
		{
			self thread maps\_zombiemode_spawner::find_flesh();
			self.following_player = true;
		}
		wait( 1 );
	}
}

//-----------------------------------------------------------------
// uses headbutt to teleport player away
//-----------------------------------------------------------------
astro_zombie_headbutt_think()
{
	self endon( "death" );

	self.is_headbutt = false;
	self.next_headbutt_time = GetTime() + level.astro_headbutt_delay;

	self thread astro_zombie_headbutt_watcher( "headbutt_anim" );
	self thread astro_zombie_headbutt_release_watcher( "headbutt_anim" );

	while ( 1 )
	{
		if ( !isdefined( self.enemy ) )
		{
			wait_network_frame();
			continue;
		}

		if ( !self.is_headbutt && GetTime() > self.next_headbutt_time )
		{
			origin = self GetEye();
			test_origin = self.enemy GetEye();
			dist_sqr = DistanceSquared( origin, test_origin );

			if ( dist_sqr > level.astro_headbutt_radius_sqr )
			{
				wait_network_frame();
				continue;
			}

			yaw = GetYawToOrigin( self.enemy.origin );
			if ( abs( yaw ) > 45 )
			{
				wait_network_frame();
				continue;
			}

			if ( !BulletTracePassed( origin, test_origin, false, undefined ) )
			{
				wait_network_frame();
				continue;
			}

			self.is_headbutt = true;

			self thread astro_turn_player();

			//_debug_astro_print( "try headbutt" );		
			headbutt_anim = %ai_zombie_astro_headbutt;
			time = getAnimLength( headbutt_anim );
			self animscripted( "headbutt_anim", self.origin, self.angles, headbutt_anim, "normal", %body, 1, 0.1 );
			self.player_to_headbutt thread astro_restore_move_speed( time );
			wait( time );

			self.next_headbutt_time = GetTime() + level.astro_headbutt_delay;
			self.is_headbutt = false;
		}

		wait_network_frame();
	}
}

astro_restore_move_speed( time )
{
	self endon( "disconnect" );
	
	wait( time );
	self AllowJump( true );
	self AllowProne( true );
	self AllowCrouch( true );
	self SetMoveSpeedScale( 1 );
}

astro_turn_player()
{
	self endon( "death" );

	self.player_to_headbutt = self.enemy;
	player = self.player_to_headbutt;

	up = player.origin + ( 0, 0, 10 );
	facing_astro = VectorToAngles( self.origin - up );

	player thread astro_watch_controls( self );
	if ( self.health > 0 )	// in case somehow this thread was still running when thief died
	{
		player FreezeControls( true );
	}
	_debug_astro_print( player.playername + " locked" );

	lerp_time = 0.2;

	enemy_to_player = VectorNormalize( player.origin - self.origin );
	link_org = self.origin + ( 40 * enemy_to_player );

	// make sure to unlink player if the thief dies during the lerp
	player lerp_player_view_to_position( link_org, facing_astro, lerp_time, 1 );
	wait( lerp_time );

	player FreezeControls( false );
	player AllowJump( false );
	player AllowStand( true );
	player AllowProne( false );
	player AllowCrouch( false );
	player SetMoveSpeedScale( 0.1 );
	player notify( "released" );

	dist = Distance( self.origin, player.origin );
	_debug_astro_print( "grab dist = " + dist );
}

astro_watch_controls( astro )
{
	self endon( "released" );
	self endon( "disconnect" );

	zombie_attack = %ai_zombie_astro_headbutt;
	animLen = getAnimLength( zombie_attack );
	time = 0.5 + animLen;
	astro waittill_notify_or_timeout( "death", time );
	self FreezeControls( false );
	_debug_astro_print( self.playername + " released from watch" );
}

//-----------------------------------------------------------------
// wait for notify to see if enemy should teleport
//-----------------------------------------------------------------
astro_zombie_headbutt_watcher( animname )
{
	self endon( "death" );

	while ( 1 )
	{
		self waittillmatch( animname, "fire" );

		if ( !isdefined( self.player_to_headbutt ) || !is_player_valid( self.player_to_headbutt ) )
		{
			continue;
		}

		//_debug_astro_print( "teleport enemy" );
		self thread astro_zombie_attack();
		self thread astro_zombie_teleport_enemy();
	}
}

//-----------------------------------------------------------------
// player got away
//-----------------------------------------------------------------
astro_zombie_headbutt_release_watcher( animname )
{
	self endon( "death" );

	_RELEASE_DIST = 59.0;

	while ( 1 )
	{
		self waittillmatch( animname, "headbutt_start" );

		player = self.player_to_headbutt;
		if ( !isdefined( player ) || !isalive( player ) )
		{
			continue;
		}

		dist = Distance( player.origin, self.origin );
		_debug_astro_print( "distance before headbutt = " + dist );

		if ( dist < _RELEASE_DIST )
		{
			continue;
		}

		player AllowJump( true );
		player AllowProne( true );
		player AllowCrouch( true );
		player SetMoveSpeedScale( 1 );

		release_anim = %ai_zombie_astro_headbutt_release;
		time = getAnimLength( release_anim );
		self animscripted( "release_anim", self.origin, self.angles, release_anim, "normal", %body, 1, 0.1 );
		wait( time );
	}
}

//-----------------------------------------------------------------
// take a perk and damage the player
//-----------------------------------------------------------------
astro_zombie_attack()
{
	self endon( "death" );

	if ( !isdefined( self.player_to_headbutt ) )
	{
		return;
	}

	player = self.player_to_headbutt;

	// take a perk
	perk_list = [];
	vending_triggers = getentarray( "zombie_vending", "targetname" );
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		perk = vending_triggers[i].script_noteworthy;
		if ( player HasPerk( perk ) )
		{
			perk_list[ perk_list.size ] = perk;
		}
	}

	take_perk = false;

	if ( perk_list.size > 0 && !IsDefined(player._retain_perks))
	{
		take_perk = true;
		perk_list = array_randomize( perk_list );
		perk = perk_list[0];
		perk_str = perk + "_stop";
		player notify( perk_str );

		if ( flag( "solo_game" ) && perk == "specialty_quickrevive" )
		{
			player.lives--;
		}

		player thread astro_headbutt_damage( self, self.origin );
	}

	if ( !take_perk )
	{
		damage = player.health - 1;
		player DoDamage( damage, self.origin, self );
	}
}

astro_headbutt_damage( astro, org )
{
	self endon( "disconnect" );

	self waittill( "perk_lost" );

	damage = self.health - 1;

	if ( isdefined( astro ) )
	{
		self DoDamage( damage, astro.origin, astro );
	}
	else
	{
		self DoDamage( damage, org );
	}
}

//-----------------------------------------------------------------
// teleport enemy to a low gravity zone
//-----------------------------------------------------------------
astro_zombie_teleport_enemy()
{
	self endon( "death" );

	player = self.player_to_headbutt;

	// grab all the structs
	black_hole_teleport_structs = getstructarray( "struct_black_hole_teleport", "targetname" );
	chosen_spot = undefined;
	
	if ( isDefined( level._special_blackhole_bomb_structs ) )
	{
		black_hole_teleport_structs = [[level._special_blackhole_bomb_structs]]();
	}

	player_current_zone = player get_current_zone();
	if ( !IsDefined( black_hole_teleport_structs ) || black_hole_teleport_structs.size == 0 || !IsDefined( player_current_zone ) )
	{
		// no structs so no teleport
		return;
	}

	// randomize the array
	black_hole_teleport_structs = array_randomize( black_hole_teleport_structs );

	// decide which struct to move the player to
	for ( i = 0; i < black_hole_teleport_structs.size; i++ )
	{
		volume = level.zones[ black_hole_teleport_structs[i].script_string ].volumes[0];
		
		active_zone = check_point_in_active_zone( black_hole_teleport_structs[i].origin );

		if ( check_point_in_active_zone( black_hole_teleport_structs[i].origin ) && 
				( player_current_zone != black_hole_teleport_structs[i].script_string )	)
		{
			if ( !flag( "power_on" ) || volume.script_string == "lowgravity" )
			{
				chosen_spot = black_hole_teleport_structs[i];
				break;
			}
			else
			{
				chosen_spot = black_hole_teleport_structs[i];
			}
		}
		else if ( active_zone )
		{
			chosen_spot = black_hole_teleport_structs[i];
		}
	}

	if ( IsDefined( chosen_spot ) )
	{
		player thread astro_zombie_teleport( chosen_spot );
	}	
}

//-----------------------------------------------------------------
// does the actually teleport of the player
//-----------------------------------------------------------------
astro_zombie_teleport( struct_dest )
{
	self endon( "death" );
	
	if( !IsDefined( struct_dest ) )
	{
		return;
	}
	
	prone_offset = (0, 0, 49);
	crouch_offset = (0, 0, 20);
	stand_offset = (0, 0, 0);
	destination = undefined;
	
	// figure out the player's stance
	if( self GetStance() == "prone" )
	{
		destination = struct_dest.origin + prone_offset;
	}
	else if( self GetStance() == "crouch" )
	{
		destination = struct_dest.origin + crouch_offset;
	}
	else
	{
		destination = struct_dest.origin + stand_offset;
	}
	
	// override
	if( IsDefined( level._black_hole_teleport_override ) )
	{
		level [[ level._black_hole_teleport_override ]]( self );
	}

	// don't allow any funny biz
	self FreezeControls( true );
	self DisableOffhandWeapons();
	self DisableWeapons();
	
	// so the player doesn't show up while moving
	self DontInterpolate();
	self SetOrigin( destination );
	self SetPlayerAngles( struct_dest.angles );
	
	// allow the funny biz
	self EnableOffhandWeapons();
	self EnableWeapons();
	self FreezeControls( false );

	Earthquake( 0.8, 0.75, self.origin, 1000, self );
	PlayRumbleOnPosition("explosion_generic", self.origin);
	self playsoundtoplayer( "zmb_gersh_teleporter_go_2d", self );

	//if ( self maps\_zombiemode_equipment::is_equipment_active( "equip_gasmask_zm" ) )
	//{
	//	self notify( "equip_gasmask_zm_deactivate" );
	//}
}

//-----------------------------------------------------------------
// death func
//-----------------------------------------------------------------
astro_zombie_die()
{
	PlayFxOnTag( level._effect[ "astro_explosion" ], self, "J_SpineLower" );
	self stoploopsound( 1 );
	self playsound( "evt_astro_zombie_explo" );

	self thread astro_delay_delete();
	self thread astro_player_pulse();

	level.num_astro_zombies--;

	level.next_astro_round = level.round_number + RandomIntRange( level.min_astro_round_wait, level.max_astro_round_wait + 1 );
	level.zombie_total_update = false;

	_debug_astro_print( "astro killed in " + level.round_number );

	return self maps\_zombiemode_spawner::zombie_death_animscript();
}

astro_delay_delete()
{
	self endon( "death" );

	self SetPlayerCollision( 0 );
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();
	wait_network_frame();
	self Hide();
}

//-----------------------------------------------------------------
// players are pushed based on distance to astro
//-----------------------------------------------------------------
astro_player_pulse()
{
	eye_org = self GetEye();
	foot_org = self.origin + ( 0, 0, 8 );
	mid_org = ( foot_org[0], foot_org[1], ( foot_org[2] + eye_org[2] ) / 2 );
	astro_org = self.origin;

	if ( isdefined( self.player_to_headbutt ) )
	{
		self.player_to_headbutt AllowJump( true );
		self.player_to_headbutt AllowProne( true );
		self.player_to_headbutt AllowCrouch( true );
		self.player_to_headbutt Unlink();
		wait_network_frame();
		wait_network_frame();
	}

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( !is_player_valid( player ) )
		{
			continue;
		}

		test_org = player GetEye();
		explode_radius = level.astro_explode_radius;

		if ( DistanceSquared( eye_org, test_org ) > explode_radius * explode_radius )
		{
			continue;
		}

		test_org_foot = player.origin + ( 0, 0, 8 );
		test_org_mid = ( test_org_foot[0], test_org_foot[1], ( test_org_foot[2] + test_org[2] ) / 2 );

		if ( !BulletTracePassed( eye_org, test_org, false, undefined ) )
		{
			if ( !BulletTracePassed( mid_org, test_org_mid, false, undefined ) )
			{
				if ( !BulletTracePassed( foot_org, test_org_foot, false, undefined ) )
				{
					continue;
				}
			}
		}

		dist = distance( eye_org, test_org );

		scale = 1.0 - ( dist / explode_radius );
		if ( scale < 0 )
		{
			scale = 0;
		}

		bonus = ( level.astro_explode_pulse_max - level.astro_explode_pulse_min ) * scale;
		pulse = level.astro_explode_pulse_min + bonus;

		dir = ( player.origin[0] - astro_org[0], player.origin[1] - astro_org[1], 0 );
		dir = VectorNormalize( dir );
		dir += ( 0, 0, 1 );
		dir *= pulse;

		player SetOrigin( player.origin + ( 0, 0, 1 ) );

		player_velocity = dir;
		//boost_velocity = player_velocity + ( 0, 0, 100 );
		player SetVelocity( player_velocity );
		
		if( isdefined( level.ai_astro_explode ) )
		{
			player thread [[ level.ai_astro_explode ]]( mid_org );
		}
	}
}

//-----------------------------------------------------------------
// override damage from players
//-----------------------------------------------------------------
astro_actor_damage( weapon, damage, attacker )
{
	self endon( "death" );

	switch( weapon )
	{
	case "microwavegundw_zm":
	case "microwavegundw_upgraded_zm":
		damage = 0;
		break;
	}

	return damage;
}

//-----------------------------------------------------------------
// override nuke affects
//-----------------------------------------------------------------
astro_nuke_damage()
{
	self endon( "death" );
}

//-----------------------------------------------------------------
// headbutt will leave player with 1 health
//-----------------------------------------------------------------
astro_custom_damage( player )
{
	damage = self.meleeDamage;

	if ( self.is_headbutt )
	{
		damage = player.health - 1;
	}

	_debug_astro_print( "astro damage = " + damage );

	return damage;
}

//-----------------------------------------------------------------
// doesn't affect astro
//-----------------------------------------------------------------
astro_microwavegun_sizzle( player )
{
	_debug_astro_print( "astro sizzle" );
}

//-----------------------------------------------------------------
// fx and sounds during spawn
//-----------------------------------------------------------------
astro_zombie_default_enter_level()
{
	Playfx( level._effect["astro_spawn"], self.origin );
	playsoundatposition( "zmb_bolt", self.origin );
	PlayRumbleOnPosition("explosion_generic", self.origin);
	
	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "astro_spawn" );

	self.entered_level = true;
}

//-----------------------------------------------------------------
// fx and sounds during spawn
//-----------------------------------------------------------------
astro_damage_callback( mod, hit_location, hit_origin, player, amount )
{
	if ( isdefined( self.animname ) && self.animname == "astro_zombie" )
	{
		return true;
	}

	return false;
}

//-----------------------------------------------------------------
// debug funcs
//-----------------------------------------------------------------
_debug_astro_health_watch()
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

_debug_astro_print( str )
{
	/#
	if ( is_true( level.debug_astro ) )
	{
		iprintln( str );
	}
	#/
}

