#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

#using_animtree( "generic_human" );

//----------------------------------------------------------------------------------------------
// setup gravity triggers and callbacks
//----------------------------------------------------------------------------------------------
init()
{
	//PreCacheModel( "fx_axis_createfx" );

	level.zombie_init_done = ::zombie_moon_init_done;

	level thread init_low_gravity_anims();
	level thread init_low_gravity_fx();

	//level.gravity_triggers = getentarray( "low_gravity_zone", "targetname" );

	//if ( isdefined( level.gravity_triggers ) )
	//{
	//	for ( i = 0; i < level.gravity_triggers.size; i++ )
	//	{
	//		level.gravity_triggers[i] thread gravity_trigger();
	//	}
	//}

	maps\_zombiemode_spawner::register_zombie_death_animscript_callback( ::gravity_zombie_death_response );

	level._ZOMBIE_ACTOR_FLAG_LOW_GRAVITY = 0;

	level thread check_player_gravity();

	level thread update_zombie_locomotion();
	level thread update_low_gravity_fx();
	level thread update_zombie_gravity_transition();

	level thread watch_player_grenades();
}

//----------------------------------------------------------------------------------------------
// setup low gravity anims
//----------------------------------------------------------------------------------------------
init_low_gravity_anims()
{
	level.scr_anim["zombie"]["walk_moon1"] = %ai_zombie_walk_moon_v1;

	level.num_anim["zombie"]["walk"] = 1;

	level.scr_anim["zombie"]["run_moon1"] = %ai_zombie_run_moon_v1;
	level.scr_anim["zombie"]["run_moon2"] = %ai_zombie_run_moon_v2;
	level.scr_anim["zombie"]["run_moon3"] = %ai_zombie_run_moon_v3;
	level.scr_anim["zombie"]["run_moon4"] = %ai_zombie_run_moon_v4;

	level.num_anim["zombie"]["run"] = 4;

	level.scr_anim["zombie"]["sprint_moon1"] = %ai_zombie_sprint_moon_v1;
	level.scr_anim["zombie"]["sprint_moon2"] = %ai_zombie_sprint_moon_v2;
	level.scr_anim["zombie"]["sprint_moon3"] = %ai_zombie_sprint_moon_v3;
	level.scr_anim["zombie"]["sprint_moon4"] = %ai_zombie_sprint_moon_v4;

	level.num_anim["zombie"]["sprint"] = 4;

	level.scr_anim["zombie"]["crawl_moon1"] = %ai_zombie_crawl_moon_v1;
	level.scr_anim["zombie"]["crawl_moon2"] = %ai_zombie_crawl_moon_v2;
	level.scr_anim["zombie"]["crawl_moon3"] = %ai_zombie_crawl_moon_v3;

	level.num_anim["zombie"]["crawl"] = 3;

	level.scr_anim["quad_zombie"]["walk_moon1"] = %ai_zombie_quad_crawl_moon;
	level.scr_anim["quad_zombie"]["walk_moon2"] = %ai_zombie_quad_crawl_moon_01;

	level.num_anim["quad_zombie"]["walk"] = 2;

	level.scr_anim["quad_zombie"]["run_moon1"] = %ai_zombie_quad_crawl_run_moon;
	level.scr_anim["quad_zombie"]["run_moon2"] = %ai_zombie_quad_crawl_run_moon_2;
	level.scr_anim["quad_zombie"]["run_moon3"] = %ai_zombie_quad_crawl_run_moon_3;
	level.scr_anim["quad_zombie"]["run_moon4"] = %ai_zombie_quad_crawl_run_moon_4;
	level.scr_anim["quad_zombie"]["run_moon5"] = %ai_zombie_quad_crawl_run_moon_5;

	level.num_anim["quad_zombie"]["run"] = 5;

	level.scr_anim["quad_zombie"]["sprint_moon1"] = %ai_zombie_quad_crawl_sprint_moon;
	level.scr_anim["quad_zombie"]["sprint_moon2"] = %ai_zombie_quad_crawl_sprint_moon_2;
	level.scr_anim["quad_zombie"]["sprint_moon3"] = %ai_zombie_quad_crawl_sprint_moon_3;

	level.num_anim["quad_zombie"]["sprint"] = 3;
}

//----------------------------------------------------------------------------------------------
// setup for impact fx
//----------------------------------------------------------------------------------------------
init_low_gravity_fx()
{
	keys = GetArrayKeys( level.zones );

	for ( i = 0; i < level.zones.size; i++ )
	{
		if ( keys[i] == "nml_zone" )
		{
			continue;
		}

		ZeroGravityVolumeOn( keys[i] );
	}
}

//----------------------------------------------------------------------------------------------
// gravity trigger thread
//----------------------------------------------------------------------------------------------
gravity_trigger()
{
	while ( 1 )
	{
		self waittill( "trigger", who );

		if ( !isplayer( who ) )
		{
			self thread trigger_thread( who, ::gravity_zombie_in, ::gravity_zombie_out );
		}
		else
		{
			self thread trigger_thread( who, ::gravity_player_in, ::gravity_player_out );
		}
	}
}

//----------------------------------------------------------------------------------------------
// zombie entered gravity zone
//----------------------------------------------------------------------------------------------
gravity_zombie_in( ent, endon_condition )
{
	if ( !isdefined( ent.in_low_gravity ) )
	{
		ent.in_low_gravity = 0;
	}

	ent.in_low_gravity++;

	ent SetClientFlag( level._ZOMBIE_ACTOR_FLAG_LOW_GRAVITY );
}

//----------------------------------------------------------------------------------------------
// zombie exited gravity zone
//----------------------------------------------------------------------------------------------
gravity_zombie_out( ent )
{
	if ( ent.in_low_gravity > 0 )
	{
		ent.in_low_gravity--;

		if ( ent.in_low_gravity == 0 )
		{
			ent ClearClientFlag( level._ZOMBIE_ACTOR_FLAG_LOW_GRAVITY );
		}
	}
}

//----------------------------------------------------------------------------------------------
// player entered gravity zone
//----------------------------------------------------------------------------------------------
gravity_player_in( ent, endon_condition )
{
	ent setplayergravity( 136 );
}

//----------------------------------------------------------------------------------------------
// player exited gravity zone
//----------------------------------------------------------------------------------------------
gravity_player_out( ent )
{
	ent clearplayergravity();
}

//----------------------------------------------------------------------------------------------
// update gravity setting and cf
//----------------------------------------------------------------------------------------------
gravity_zombie_update( low_gravity, force_update )
{
	if ( !isdefined( self.animname ) )
	{
		return;
	}

	if ( is_true( self.ignore_gravity ) )
	{
		return;
	}

	if ( !is_true( self.completed_emerging_into_playable_area ) )
	{
		return;
	}

	if ( isdefined( self.in_low_gravity ) && self.in_low_gravity == low_gravity && !is_true( force_update ) )
	{
		return;
	}

	self.in_low_gravity = low_gravity;

	if ( low_gravity )
	{
		self SetClientFlag( level._ZOMBIE_ACTOR_FLAG_LOW_GRAVITY );
		self thread zombie_low_gravity_locomotion();
		self.script_noteworthy = "moon_gravity";
	}
	else
	{
		self.nogravity = undefined;
		self.script_noteworthy = undefined;
		self AnimMode( "none" );
		wait_network_frame();

		if ( isdefined( self ) )
		{
			self ClearClientFlag( level._ZOMBIE_ACTOR_FLAG_LOW_GRAVITY );
			self thread reset_zombie_anim();
		}
	}
}

//----------------------------------------------------------------------------------------------
// launch zombie ragdoll in low gravity
//----------------------------------------------------------------------------------------------
gravity_zombie_death_response()
{
	if ( !isdefined( self.in_low_gravity ) || self.in_low_gravity == 0 )
	{
		return false;
	}

	self StartRagdoll();

	rag_x = RandomIntRange( -50, 50 );
	rag_y = RandomIntRange( -50, 50 );
	rag_z = RandomIntRange( 25, 45 );

	force_min = 75;
	force_max = 100;

	if ( self.damagemod == "MOD_MELEE" )
	{
		force_min = 40;
		force_max = 50;
		rag_z = 15;
	}
	else if ( self.damageweapon == "m1911_zm" )
	{
		force_min = 60;
		force_max = 75;
		rag_z = 20;
	}
	else if ( self.damageweapon == "ithaca_zm" || self.damageweapon == "ithaca_upgraded_zm" ||
			  self.damageweapon == "rottweil72_zm" || self.damageweapon == "rottweil72_upgraded_zm" ||
			  self.damageweapon == "spas_zm" || self.damageweapon == "spas_upgraded_zm" ||
			  self.damageweapon == "hs10_zm" || self.damageweapon == "hs10_upgraded_zm" )
	{
		force_min = 100;
		force_max = 150;
	}

	scale = RandomIntRange( force_min, force_max );

	rag_x = self.damagedir[0] * scale;
	rag_y = self.damagedir[1] * scale;

	dir = ( rag_x, rag_y, rag_z );
	self LaunchRagdoll( dir );

	return false;
}

//----------------------------------------------------------------------------------------------
// checks if zombie is in a low gravity zone
//----------------------------------------------------------------------------------------------
zombie_moon_is_low_gravity_zone( zone_name )
{
	zone = getentarray( zone_name, "targetname" );
	if ( isdefined( zone[0].script_string ) && zone[0].script_string == "lowgravity" )
	{
		return true;
	}

	return false;
}

zombie_moon_check_zone()
{
	self endon( "death" );

	wait_network_frame();

	if ( !isdefined( self ) )
	{
		return;
	}

	if ( is_true( self.ignore_gravity ) )
	{
		return;
	}

	if ( self.zone_name == "nml_zone_spawners" || self.zone_name == "nml_area1_spawners" || self.zone_name == "nml_area2_spawners" )
	{
		return;
	}

	// wait til zombie is in the map before gravity updates
	if ( !is_true( self.completed_emerging_into_playable_area ) )
	{
		self waittill( "completed_emerging_into_playable_area" );
	}

	if ( is_true( level.on_the_moon ) && ( !flag( "power_on" ) || zombie_moon_is_low_gravity_zone( self.zone_name ) ) )
	{
		self gravity_zombie_update( 1 );
	}
	else
	{
		self gravity_zombie_update( 0 );
	}
}

zombie_moon_init_done()
{
	self.crawl_anim_override = ::zombie_moon_crawl_anim_override;

	self thread zombie_moon_check_zone();
	self thread zombie_watch_nogravity();
	self thread zombie_watch_run_notetracks();
}

//----------------------------------------------------------------------------------------------
// switch to low gravity locomotion
//----------------------------------------------------------------------------------------------
zombie_low_gravity_locomotion()
{
	self endon( "death" );

	gravity_str = undefined;

	if ( !self.has_legs )
	{
		max = level.num_anim[self.animname]["crawl"] + 1;
		rand = randomIntRange( 1, max );
		gravity_str = "crawl_moon" + rand;
	}
	else if ( self.zombie_move_speed == "walk" || self.zombie_move_speed == "run" || self.zombie_move_speed == "sprint" )
	{
		max = level.num_anim[self.animname][self.zombie_move_speed] + 1;
		rand = randomIntRange( 1, max );
		gravity_str = self.zombie_move_speed + "_moon" + rand;
	}

	if ( isdefined( gravity_str ) )
	{
		gravity_anim = level.scr_anim[self.animname][gravity_str];

		self set_run_anim( gravity_str );
		self.run_combatanim = gravity_anim;
		self.crouchRunAnim = gravity_anim;
		self.crouchrun_combatanim = gravity_anim;
		self.needs_run_update = true;
	}

	//fxaxis = Spawn( "script_model", self GetTagOrigin( "tag_origin" ) );
	//fxaxis.angles = self GetTagAngles( "tag_origin" );
	//fxaxis SetModel( "fx_axis_createfx" );
	//fxaxis LinkTo( self, "tag_origin" );
}

//----------------------------------------------------------------------------------------------
// stop no gravity if zombies get too far off the ground (stairs, etc)
//----------------------------------------------------------------------------------------------
zombie_watch_nogravity()
{
	self endon( "death" );

	_OFF_GROUND_MAX = 32;

	while ( 1 )
	{
		if ( is_true( self.nogravity ) )
		{
			ground = self groundpos( self.origin );
			dist = self.origin[2] - ground[2];
			if ( dist > _OFF_GROUND_MAX )
			{
				self AnimMode( "none" );
				wait_network_frame();
				self.nogravity = undefined;
			}
		}
		wait( 0.2 );
	}
}

//----------------------------------------------------------------------------------------------
// handle gravity notetracks
//----------------------------------------------------------------------------------------------
zombie_watch_run_notetracks()
{
	self endon( "death" );

	while ( 1 )
	{
		self waittill( "runanim", note );

		if ( !isdefined( self.script_noteworthy ) || self.script_noteworthy != "moon_gravity" )
		{
			continue;
		}

		if ( note == "gravity off" )
		{
			self AnimMode( "nogravity" );
			self.nogravity = true;
		}
		else if ( note == "gravity code" )
		{
			self AnimMode( "none" );
			self.nogravity = undefined;
		}
	}
}

//----------------------------------------------------------------------------------------------
// back to regular locomotion
//----------------------------------------------------------------------------------------------
reset_zombie_anim()
{
	self endon( "death" );

	theanim = undefined;
	if( self.has_legs )
	{
		if(IsDefined(self.preslide_death))
		{
			self.deathanim = self.preslide_death;
		}
		switch(self.zombie_move_speed)
		{
			case "walk":
				theanim = "walk" + randomintrange(1, 8);
				break;
			case "run":
				theanim = "run" + randomintrange(1, 6);
				break;
			case "sprint":
				theanim = "sprint" + randomintrange(1, 4);
				break;
		}
	}
	else
	{
		// walk - there are four legless walk animations
		legless_walk_anims = [];
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl1", false );
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl5", false );
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl_hand_1", false );
		legless_walk_anims = add_to_array( legless_walk_anims, "crawl_hand_2", false );
		rand_walk_anim = RandomInt( legless_walk_anims.size );

		// run
		// there is only one legless run animations, so there is no point in randomizing an array

		// sprint
		// there are three legless sprint animations
		legless_sprint_anims = [];
		legless_sprint_anims = add_to_array( legless_sprint_anims, "crawl2", false );
		legless_sprint_anims = add_to_array( legless_sprint_anims, "crawl3", false );
		legless_sprint_anims = add_to_array( legless_sprint_anims, "crawl_sprint1", false );
		rand_sprint_anim = RandomInt( legless_sprint_anims.size );

		switch(self.zombie_move_speed)
		{
			case "walk":
				theanim = legless_walk_anims[ rand_walk_anim ];
				break;
			case "run":
				theanim = "crawl4";
				break;
			case "sprint":
				theanim = legless_sprint_anims[ rand_sprint_anim ];
				break;
			default:
				theanim = "crawl4";
				break;

		}
	}

	if ( isDefined(level.scr_anim[self.animname][theanim]) )
	{
		self clear_run_anim();
		wait_network_frame();

		self set_run_anim( theanim );
		self.run_combatanim = level.scr_anim[self.animname][theanim];
		self.walk_combatanim = level.scr_anim[self.animname][theanim];
		self.crouchRunAnim = level.scr_anim[self.animname][theanim];
		self.crouchrun_combatanim = level.scr_anim[self.animname][theanim];
		self.needs_run_update = true;
		return;
	}
	else
	{
		//try again.
		self thread reset_zombie_anim();
	}
}

// --------------------------------------------------------------------------------------
// update players gravity settings
// --------------------------------------------------------------------------------------
zombie_moon_update_player_gravity()
{
	flag_wait( "all_players_connected" );

	LOW_G = 136;

	player_zones = getentarray( "player_volume", "script_noteworthy" );

	while ( 1 )
	{
		players = getplayers();

		for ( i = 0; i < player_zones.size; i++ )
		{
			volume = player_zones[i];
			zone = undefined;
			if ( isdefined( volume.targetname ) )
			{
				zone = level.zones[ volume.targetname ];
			}

			if ( isdefined( zone ) && is_true( zone.is_enabled ) )
			{
				for ( j = 0; j < players.size; j++ )
				{
					player = players[j];
					if ( is_player_valid( player ) && player istouching( volume ) )
					{
						if ( is_true( level.on_the_moon ) && !flag( "power_on" ) )
						{
							player setplayergravity( LOW_G );
							player.in_low_gravity = true;
						}
						else if ( isdefined( volume.script_string ) && volume.script_string == "lowgravity" )
						{
							player setplayergravity( LOW_G );
							player.in_low_gravity = true;
						}
						else
						{
							player clearplayergravity();
							player.in_low_gravity = false;
						}
					}
				}
			}
		}

		wait_network_frame();
		//wait( 0.5 );
	}
}

// --------------------------------------------------------------------------------------
// update players floatiness when sprinting in low g
// --------------------------------------------------------------------------------------
zombie_moon_update_player_float()
{
	flag_wait( "all_players_connected" );

	players = getplayers();

	for ( i = 0; i < players.size; i++ )
	{
		players[i] thread zombie_moon_player_float();
	}
}

zombie_moon_player_float()
{
	self endon( "death" );
	self endon( "disconnect" );

	boost_chance = 40;

	while ( 1 )
	{
		if ( is_player_valid( self ) && is_true( self.in_low_gravity ) && self IsOnGround() && self IsSprinting() )
		{
			boost = RandomInt( 100 );
			if ( boost < boost_chance )
			{
				time = RandomFloatRange( 0.75, 1.25 );
				wait( time );

				if ( is_true( self.in_low_gravity ) && self IsOnGround() && self IsSprinting() )
				{
					self SetOrigin( self.origin + ( 0, 0, 1 ) );

					player_velocity = self GetVelocity();
					boost_velocity = player_velocity + ( 0, 0, 100 );
					self SetVelocity( boost_velocity );

					if( randomintrange( 0, 100 ) <= 15 )
					{
						self thread maps\_zombiemode_audio::create_and_play_dialog( "general", "moonjump" );
					}

					boost_chance = 40;

					wait( 2 );
				}
				else
				{
					boost_chance += 10;
				}
			}
			else
			{
				wait( 2 );
			}
		}

		wait_network_frame();
	}
}

//----------------------------------------------------------------------------------------------
// setup player gravity watch
//----------------------------------------------------------------------------------------------
check_player_gravity()
{
	flag_wait( "all_players_connected" );

	if(level.gamemode != "survival")
	{
		return;
	}

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] thread low_gravity_watch();
	}
}

low_gravity_watch()
{
	self endon( "death" );
	self endon( "disconnect" );

	self notify("low_gravity_watch_start");	// Make sure that there's only one of these...
 	self endon("low_gravity_watch_start");

 	self.airless_vox_in_progess = false;

	time_in_low_gravity = 0;
	time_to_death = 0;
	time_to_death_default = 15000;
	time_to_death_jug = 17000;
	time_til_damage = 0;

	blur_level = 0;
	blur_level_max = 7;

	blur_occur = [];
	blur_occur[0] = 1000;
	blur_occur[1] = 1250;
	blur_occur[2] = 1250;
	blur_occur[3] = 1500;

	blur_occur[4] = 1500;
	blur_occur[5] = 1750;
	blur_occur[6] = 2250;
	blur_occur[7] = 2500;

	blur_intensity = [];
	blur_intensity[0] = 1;
	blur_intensity[1] = 2;
	blur_intensity[2] = 3;
	blur_intensity[3] = 5;

	blur_intensity[4] = 7;
	blur_intensity[5] = 8;
	blur_intensity[6] = 9;
	blur_intensity[7] = 10;

	blur_duration = [];
	blur_duration[0] = 0.2;
	blur_duration[1] = 0.25;
	blur_duration[2] = 0.25;
	blur_duration[3] = 0.5;

	blur_duration[4] = 0.5;
	blur_duration[5] = 0.75;
	blur_duration[6] = 0.75;
	blur_duration[7] = 1;

	if ( is_true( level.debug_low_gravity ) )
	{
		time_to_death = 3000;
	}

	startTime = GetTime();
	nextTime = GetTime();

	while ( 1 )
	{
		diff = nextTime - startTime;
		//iprintln( "time in low gravity = " + time_in_low_gravity );

		if ( IsGodMode( self ) )
		{
			time_in_low_gravity = 0;
			blur_level = 0;
			wait( 1 );
			continue;
		}

		if ( !is_player_valid( self ) || !is_true( level.on_the_moon ) )
		{
			time_in_low_gravity = 0;
			blur_level = 0;
			wait_network_frame();
			continue;
		}

		if ( ( !flag( "power_on" ) || is_true( self.in_low_gravity ) ) && !self maps\_zombiemode_equip_gasmask::gasmask_active() )
		{
			if(level.gamemode == "survival" && GetDvarInt("character_dialog"))
			{
				self thread airless_vox_without_repeat();
			}

			time_til_damage += diff;
			time_in_low_gravity += diff;

			if ( self HasPerk( "specialty_armorvest" ) )
			{
				time_to_death = time_to_death_jug;
			}
			else
			{
				time_to_death = time_to_death_default;
			}

			if ( time_in_low_gravity > time_to_death )
			{
				self playsoundtoplayer( "evt_suffocate_whump", self );
				self DoDamage( self.health * 10, self.origin );
				//iprintln( "low g too long" );
				self SetBlur( 0, 0.1 );
			}
			else if ( blur_level < blur_occur.size && time_til_damage > blur_occur[ blur_level ] )
			{
				self setclientflag(level._CLIENTFLAG_PLAYER_GASP_RUMBLE);
				self playsoundtoplayer( "evt_suffocate_whump", self );
				self SetBlur( blur_intensity[ blur_level ], 0.1 );
				self thread remove_blur( blur_duration[ blur_level ] );
				blur_level++;
				if ( blur_level > blur_level_max )
				{
					blur_level = blur_level_max;
				}
				//dmg = self.health * 0.5;
				//self DoDamage( dmg, self.origin );
				time_til_damage = 0;
				//iprintln( "low g tick" );
			}
		}
		else
		{
			if ( time_in_low_gravity > 0 )
			{
				time_in_low_gravity = 0;
				time_til_damage = 0;
				blur_level = 0;
			}
		}

		startTime = GetTime();
		wait(0.1);
		nextTime = GetTime();
	}
}

remove_blur( time )
{
	self endon( "disconnect" );

	wait( time );
	self SetBlur( 0, 0.1 );
	self clearclientflag(level._CLIENTFLAG_PLAYER_GASP_RUMBLE);
}

airless_vox_without_repeat()
{
	self endon( "death" );
	self endon( "disconnect" );

	entity_num = self GetEntityNumber();

	if( isdefined( self.zm_random_char ) )
	{
		entity_num = self.zm_random_char;
	}

	if( entity_num == 3 && is_true( level.player_4_vox_override ) )
	{
		entity_num = 4;
	}

	if( !self.airless_vox_in_progess )
	{
		self.airless_vox_in_progess = true;
		wait(2);

		if( isdefined( self ) && is_true( self.in_low_gravity ) )
		{
			level.player_is_speaking = 1;
			self playsoundtoplayer( "vox_plr_" + entity_num + "_location_airless_" + randomintrange(0,5), self );
			wait(10);
			level.player_is_speaking = 0;
		}

		wait(.1);
		self.airless_vox_in_progess = false;
	}
}

//----------------------------------------------------------------------------------------------
// update zombie locomotion after power is turned on
//----------------------------------------------------------------------------------------------
update_zombie_locomotion()
{
	flag_wait( "power_on" );

	player_zones = getentarray( "player_volume", "script_noteworthy" );
	zombies = GetAIArray( "axis" );

	for ( i = 0; i < player_zones.size; i++ )
	{
		volume = player_zones[i];
		zone = undefined;
		if ( isdefined( volume.targetname ) )
		{
			zone = level.zones[ volume.targetname ];
		}

		if ( isdefined( zone ) && is_true( zone.is_enabled ) )
		{
			if ( isdefined( volume.script_string ) && volume.script_string == "gravity" )
			{
				for ( j = 0; j < zombies.size; j++ )
				{
					zombie = zombies[j];
					if ( zombie istouching( volume ) )
					{
						zombie gravity_zombie_update( 0 );
					}
				}
			}
		}
	}
}

//----------------------------------------------------------------------------------------------
// update impact fx after power is turned on
//----------------------------------------------------------------------------------------------
update_low_gravity_fx()
{
	flag_wait( "power_on" );

	keys = GetArrayKeys( level.zones );

	for ( i = 0; i < level.zones.size; i++ )
	{
		if ( keys[i] == "nml_zone" )
		{
			continue;
		}

		volume = level.zones[ keys[i] ].volumes[0];
		if ( isdefined( volume.script_string ) && volume.script_string == "gravity" )
		{
			ZeroGravityVolumeOff( keys[i] );
		}
	}
}

//----------------------------------------------------------------------------------------------
// check gravity for grenades
//----------------------------------------------------------------------------------------------
watch_player_grenades()
{
	flag_wait( "all_players_connected" );

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] thread player_throw_grenade();
	}
}

player_throw_grenade()
{
	self endon( "disconnect" );

	while ( 1 )
	{
		self waittill( "grenade_fire", grenade, weapName );
		grenade thread watch_grenade_gravity();
	}
}

watch_grenade_gravity()
{
	self endon( "death" );
	self endon( "explode" );

	player_zones = getentarray( "player_volume", "script_noteworthy" );

	while ( 1 )
	{
		if ( is_true( level.on_the_moon ) && !flag( "power_on" ) )
		{
			if( isdefined( self ) && isalive( self ) )
			{
				self.script_noteworthy = "moon_gravity";
				self SetEntGravityTrajectory( 1 );
			}
			wait( 0.25 );
			continue;
		}

		for ( i = 0; i < player_zones.size; i++ )
		{
			volume = player_zones[i];
			zone = undefined;
			if ( isdefined( volume.targetname ) )
			{
				zone = level.zones[ volume.targetname ];
			}

			if ( isdefined( zone ) && is_true( zone.is_enabled ) )
			{
				if ( isdefined( volume.script_string ) && volume.script_string == "lowgravity" )
				{
					if ( isdefined( self ) && isalive( self ) && self istouching( volume ) )
					{
						if ( volume.script_string == "lowgravity" )
						{
							self.script_noteworthy = "moon_gravity";
							self SetEntGravityTrajectory( 1 );
						}
						else if ( volume.script_string == "gravity" )
						{
							self.script_noteworthy = undefined;
							self SetEntGravityTrajectory( 0 );
						}
					}
				}
			}
		}
		wait( 0.25 );
	}
}

//----------------------------------------------------------------------------------------------
// update gravity settings when zombies pass through airlocks
//----------------------------------------------------------------------------------------------
update_zombie_gravity_transition()
{
	airlock_doors = GetEntArray("zombie_door_airlock", "script_noteworthy");
	for( i = 0; i < airlock_doors.size; i++ )
	{
		airlock_doors[i] thread zombie_airlock_think();
	}
}

zombie_airlock_think()
{
	while ( 1 )
	{
		self waittill( "trigger", who );

		if ( isplayer( who ) )
		{
			continue;
		}

		if ( !flag( "power_on" ) )
		{
			continue;
		}

		if ( isdefined( self.script_parameters ) )
		{
			zone = getentarray( self.script_parameters, "targetname" );
			in_airlock = false;
			for ( i = 0; i < zone.size; i++ )
			{
				if ( who istouching( zone[i] ) )
				{
					who maps\zombie_moon_gravity::gravity_zombie_update( 0 );
					in_airlock = true;
					break;
				}
			}
			if ( in_airlock )
			{
				continue;
			}
		}

		if(self.script_string == "inside")
		{
			//adding check if zone originally set for inside has breached.
			if(IsDefined(self.doors[0].script_noteworthy))
			{
				_zones = getentarray(self.doors[0].script_noteworthy,"targetname");

				if(_zones[0].script_string == "lowgravity" )
				{
					who maps\zombie_moon_gravity::gravity_zombie_update( 1 );
					self.script_string = "outside";
				}
				else //not breached
				{
					who maps\zombie_moon_gravity::gravity_zombie_update( 0 );
				}
			}
			else
			{
				who maps\zombie_moon_gravity::gravity_zombie_update( 0 );
			}
		}
		else
		{
			who maps\zombie_moon_gravity::gravity_zombie_update( 1 );
		}
	}
}

//----------------------------------------------------------------------------------------------
// update gravity settings when zone breaches
//----------------------------------------------------------------------------------------------
zone_breached( zone_name )
{
	zones = getentarray( zone_name, "targetname" );
	zombies = GetAIArray( "axis" );
	throttle = 0;

	for ( i = 0; i < zombies.size; i++ )
	{
		zombie = zombies[i];
		if ( isdefined( zombie ) )
		{
			for ( j = 0; j < zones.size; j++ )
			{
				if ( zombie istouching( zones[j] ) )
				{
					zombie gravity_zombie_update( 1 );
					throttle++;
				}
			}
		}
		if ( throttle && !(throttle % 10) )
		{
			wait_network_frame();
			wait_network_frame();
			wait_network_frame();
		}
	}
}

//----------------------------------------------------------------------------------------------
// check zone's gravity when creating a crawler
//----------------------------------------------------------------------------------------------
zombie_moon_crawl_anim_override()
{
	player_volumes = getentarray( "player_volume", "script_noteworthy" );

	if ( !is_true( level.on_the_moon ) )
	{
		return;
	}

	if ( !flag( "power_on" ) )
	{
		self gravity_zombie_update( 1, true );
	}
	else
	{
		for ( i = 0; i < player_volumes.size; i++ )
		{
			volume = player_volumes[i];
			zone = undefined;
			if ( isdefined( volume.targetname ) )
			{
				zone = level.zones[ volume.targetname ];
			}

			if ( isdefined( zone ) && is_true( zone.is_enabled ) )
			{
				if ( self istouching( volume ) )
				{
					if ( isdefined( volume.script_string ) && volume.script_string == "lowgravity" )
					{
						self gravity_zombie_update( 1, true );
					}
				}
			}
		}
	}
}
