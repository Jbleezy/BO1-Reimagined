#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;
#include maps\_zombiemode_spawner;
#include maps\_zombiemode_net;

#using_animtree( "generic_human" ); 

napalm_zombie_init()
{
	init_napalm_fx();

	level.napalmZombiesEnabled			= true;
	level.napalmZombieMinRoundWait      = 1;
	level.napalmZombieMaxRoundWait      = 2;
	level.napalmZombieRoundRequirement	= 5;
	level.nextNapalmSpawnRound          = level.napalmZombieRoundRequirement + RandomIntRange(0, level.napalmZombieMaxRoundWait+1);
	level.napalmZombieDamageRadius		= 250;
	level.napalmExplodeRadius			= 90.0;//radius at which the napalm zombie is triggered to start the explode sequence

	level.napalmExplodeKillRadiusJugs	= 90.0;		//Players inside this radius with jug will die
	level.napalmExplodeKillRadius		= 150.0;	//Players inside this radius without jug will die
	//If changed update napalmPlayerWarningRadiusSqr in _zombiemode_ai_napalm.csc
	level.napalmExplodeDamageRadius		= 400.0;	//Any player in this radius will receive at least napalmExplodeDamageMin
	level.napalmExplodeDamageRadiusWet	= 250.0;	//Smaller radius when wet
	level.napalmExplodeDamageMin		= 50;		//The min damage a player will receive if in the napalmExplodeDamageRadius
	
	level.napalmHealthMultiplier        = 4;

	level.napalm_zombie_spawners = GetEntArray( "napalm_zombie_spawner", "script_noteworthy" ); 
	
	if ( GetDvar("zombiemode_debug_napalm") == "" ) 
	{
		SetDvar("zombiemode_debug_napalm", "0");
	}
	
	flag_init("zombie_napalm_force_spawn");

	array_thread(level.napalm_zombie_spawners, ::add_spawn_function, ::napalm_zombie_spawn);
	array_thread(level.napalm_zombie_spawners, ::add_spawn_function, maps\_zombiemode::round_spawn_failsafe);

	// add a damage callback for the napalm zombie to lower the score given to players
	maps\_zombiemode_spawner::register_zombie_damage_callback( ::_napalm_damage_callback );

	_napalm_InitAnims();
	_napalm_InitSounds();
	thread _napalm_InitSpawners();
}

_napalm_InitAnims()
{
	level.scr_anim["napalm_zombie"]["death1"] 	= %ai_zombie_napalm_death_01;
	level.scr_anim["napalm_zombie"]["death2"] 	= %ai_zombie_napalm_death_02;
	level.scr_anim["napalm_zombie"]["death3"] 	= %ai_zombie_napalm_death_03;
	level.scr_anim["napalm_zombie"]["death4"] 	= %ai_zombie_napalm_death_01;

	// run cycles
	level.scr_anim["napalm_zombie"]["walk1"] 	= %ai_zombie_napalm_run_01; 	
	level.scr_anim["napalm_zombie"]["walk2"] 	= %ai_zombie_napalm_run_02;
	level.scr_anim["napalm_zombie"]["walk3"] 	= %ai_zombie_napalm_run_03;
	level.scr_anim["napalm_zombie"]["walk4"] 	= %ai_zombie_napalm_run_01;
	level.scr_anim["napalm_zombie"]["walk5"] 	= %ai_zombie_napalm_run_02;
	level.scr_anim["napalm_zombie"]["walk6"] 	= %ai_zombie_napalm_run_03;
	level.scr_anim["napalm_zombie"]["walk7"] 	= %ai_zombie_napalm_run_01;
	level.scr_anim["napalm_zombie"]["walk8"] 	= %ai_zombie_napalm_run_02;

	// run cycles in prone
	level.scr_anim["napalm_zombie"]["crawl1"] 	= %ai_zombie_crawl;
	level.scr_anim["napalm_zombie"]["crawl2"] 	= %ai_zombie_crawl_v1;
	level.scr_anim["napalm_zombie"]["crawl3"] 	= %ai_zombie_crawl_v2;
	level.scr_anim["napalm_zombie"]["crawl4"] 	= %ai_zombie_crawl_v3;
	level.scr_anim["napalm_zombie"]["crawl5"] 	= %ai_zombie_crawl_v4;
	level.scr_anim["napalm_zombie"]["crawl6"] 	= %ai_zombie_crawl_v5;
	level.scr_anim["napalm_zombie"]["crawl_hand_1"] = %ai_zombie_walk_on_hands_a;
	level.scr_anim["napalm_zombie"]["crawl_hand_2"] = %ai_zombie_walk_on_hands_b;

	level.scr_anim["napalm_zombie"]["crawl_sprint1"] 	= %ai_zombie_crawl_sprint;
	level.scr_anim["napalm_zombie"]["crawl_sprint2"] 	= %ai_zombie_crawl_sprint_1;
	level.scr_anim["napalm_zombie"]["crawl_sprint3"] 	= %ai_zombie_crawl_sprint_2;
	
	level.scr_anim["napalm_zombie"]["sprint1"] 	= %ai_zombie_sprint_v1;
	level.scr_anim["napalm_zombie"]["sprint2"] 	= %ai_zombie_sprint_v2;
	level.scr_anim["napalm_zombie"]["sprint3"] 	= %ai_zombie_sprint_v1;
	level.scr_anim["napalm_zombie"]["sprint4"] 	= %ai_zombie_sprint_v2;

	// do we want to use the anims below?
	level._zombie_melee["napalm_zombie"] = level._zombie_melee["zombie"];
	level._zombie_run_melee["napalm_zombie"] = level._zombie_run_melee["zombie"];
	level._zombie_walk_melee["napalm_zombie"] = level._zombie_walk_melee["zombie"];
	
	level._zombie_knockdowns["napalm_zombie"] = [];
	level._zombie_knockdowns["napalm_zombie"]["front"] = [];

	level._zombie_knockdowns["napalm_zombie"]["front"]["no_legs"] = [];
	level._zombie_knockdowns["napalm_zombie"]["front"]["no_legs"][0] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["napalm_zombie"]["front"]["no_legs"][1] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["napalm_zombie"]["front"]["no_legs"][2] = %ai_zombie_thundergun_hit_forwardtoface;

	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"] = [];

	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][0] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][1] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][2] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][3] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][4] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][5] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][6] = %ai_zombie_thundergun_hit_stumblefall;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][7] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][8] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][9] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][10] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][11] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][12] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][13] = %ai_zombie_thundergun_hit_deadfallknee;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][14] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][15] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][16] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][17] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][18] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][19] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["napalm_zombie"]["front"]["has_legs"][20] = %ai_zombie_thundergun_hit_flatonback;

	level._zombie_knockdowns["napalm_zombie"]["left"] = [];
	level._zombie_knockdowns["napalm_zombie"]["left"][0] = %ai_zombie_thundergun_hit_legsout_right;

	level._zombie_knockdowns["napalm_zombie"]["right"] = [];
	level._zombie_knockdowns["napalm_zombie"]["right"][0] = %ai_zombie_thundergun_hit_legsout_left;

	level._zombie_knockdowns["napalm_zombie"]["back"] = [];
	level._zombie_knockdowns["napalm_zombie"]["back"][0] = %ai_zombie_thundergun_hit_faceplant;


	level._zombie_getups["napalm_zombie"] = [];
	level._zombie_getups["napalm_zombie"]["back"] = [];

	level._zombie_getups["napalm_zombie"]["back"]["early"] = [];
	level._zombie_getups["napalm_zombie"]["back"]["early"][0] = %ai_zombie_thundergun_getup_b;
	level._zombie_getups["napalm_zombie"]["back"]["early"][1] = %ai_zombie_thundergun_getup_c;

	level._zombie_getups["napalm_zombie"]["back"]["late"] = [];
	level._zombie_getups["napalm_zombie"]["back"]["late"][0] = %ai_zombie_thundergun_getup_b;
	level._zombie_getups["napalm_zombie"]["back"]["late"][1] = %ai_zombie_thundergun_getup_c;
	level._zombie_getups["napalm_zombie"]["back"]["late"][2] = %ai_zombie_thundergun_getup_quick_b;
	level._zombie_getups["napalm_zombie"]["back"]["late"][3] = %ai_zombie_thundergun_getup_quick_c;

	level._zombie_getups["napalm_zombie"]["belly"] = [];

	level._zombie_getups["napalm_zombie"]["belly"]["early"] = [];
	level._zombie_getups["napalm_zombie"]["belly"]["early"][0] = %ai_zombie_thundergun_getup_a;

	level._zombie_getups["napalm_zombie"]["belly"]["late"] = [];
	level._zombie_getups["napalm_zombie"]["belly"]["late"][0] = %ai_zombie_thundergun_getup_a;
	level._zombie_getups["napalm_zombie"]["belly"]["late"][1] = %ai_zombie_thundergun_getup_quick_a;
	
	
	

	//level._zombie_melee["napalm_zombie"] = [];
	//level._zombie_melee["napalm_zombie"][0] = %ai_zombie_napalm_attack_01;
	//level._zombie_melee["napalm_zombie"][1] = %ai_zombie_napalm_attack_02;
	//level._zombie_melee["napalm_zombie"][2] = %ai_zombie_napalm_attack_03;

	//level._zombie_run_melee["napalm_zombie"] = [];
	//level._zombie_run_melee["napalm_zombie"][0] = %ai_zombie_napalm_attack_01;
	//level._zombie_run_melee["napalm_zombie"][1] = %ai_zombie_napalm_attack_02;
	//level._zombie_run_melee["napalm_zombie"][2] = %ai_zombie_napalm_attack_03;

	//level._zombie_walk_melee["napalm_zombie"] = [];
	//level._zombie_walk_melee["napalm_zombie"][0] = %ai_zombie_napalm_attack_01;
	//level._zombie_walk_melee["napalm_zombie"][1] = %ai_zombie_napalm_attack_02;
	//level._zombie_walk_melee["napalm_zombie"][2] = %ai_zombie_napalm_attack_03;

	level._zombie_melee_crawl["napalm_zombie"] = level._zombie_melee_crawl["zombie"];
	level._zombie_stumpy_melee["napalm_zombie"] = level._zombie_stumpy_melee["zombie"];
	level._zombie_tesla_death["napalm_zombie"] = level._zombie_tesla_death["zombie"];
	level._zombie_tesla_crawl_death["napalm_zombie"] = level._zombie_tesla_crawl_death["zombie"];
	
	level._zombie_deaths["napalm_zombie"] = [];
	level._zombie_deaths["napalm_zombie"][0] = %ai_zombie_napalm_death_01;
	level._zombie_deaths["napalm_zombie"][1] = %ai_zombie_napalm_death_02;
	level._zombie_deaths["napalm_zombie"][2] = %ai_zombie_napalm_death_03;

	level._zombie_board_taunt["napalm_zombie"] = level._zombie_board_taunt["zombie"];
}

_napalm_InitSounds()
{
	level.zmb_vox["napalm_zombie"]					=   [];
	level.zmb_vox["napalm_zombie"]["ambient"]     	=   "napalm_ambient";
	level.zmb_vox["napalm_zombie"]["sprint"]		=   "napalm_ambient";
	level.zmb_vox["napalm_zombie"]["attack"]		=   "napalm_attack";
	level.zmb_vox["napalm_zombie"]["teardown"]		=   "napalm_attack";
	level.zmb_vox["napalm_zombie"]["taunt"]			=   "napalm_ambient";
	level.zmb_vox["napalm_zombie"]["behind"]		=   "napalm_ambient";
	level.zmb_vox["napalm_zombie"]["death"]			=   "napalm_explode";
	level.zmb_vox["napalm_zombie"]["crawler"]		=   "napalm_ambient";
}

_napalm_InitSpawners()
{
	flag_wait("zones_initialized");

	testOrigin = Spawn("script_model", (0,0,0));
	testOrigin SetModel("tag_origin");

	zkeys = GetArrayKeys(level.zones);
	for ( z = 0; z < zkeys.size; z++ )
	{
		zoneName = zkeys[z];
		zone = level.zones[zoneName];
		zone.napalm_spawn_locations = [];
	}

	spawnPoints = GetStructArray("special_zombie_spawn", "targetname");
	for ( i = 0; i < spawnPoints.size; i++ )
	{
		s = spawnPoints[i];
		testOrigin.origin = s.origin + (0,0,50);

		for ( z = 0; z < zkeys.size; z++ )
		{
			zoneName = zkeys[z];
			zone = level.zones[zoneName];

			inZone = testOrigin _entity_in_zone(zone);
			
			if ( inZone ) 
			{
				s.zoneName = zoneName;
				zone.napalm_spawn_locations = array_add(zone.napalm_spawn_locations, s);
			}
		}
	}
}

_entity_in_zone(zone)
{
	// Okay check to see if an entity is in one of the zone volumes
	for (i = 0; i < zone.volumes.size; i++)
	{
		if ( self IsTouching( zone.volumes[i] ) )
		{
			return true;
		}
	}
	return false;
}

init_napalm_fx()
{
	level._effect["napalm_fire_forearm"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_forearm" );
	level._effect["napalm_fire_torso"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_torso" );
	level._effect["napalm_fire_ground"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_ground2" );

	//TODO: larger
	level._effect["napalm_explosion"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_exp" );
	
	//TODO: fire is too bright and washed out, use darker, richer fire graphics
	level._effect["napalm_fire_trigger"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_end2" );//"env/fire/fx_fire_player_torso"
	
	//small residual fire
	//NOTE: just using nuke fx for now
	//level._effect["napalm_fire_trigger_small"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_killed" );
	
	//a funnel shooting up into the air - like a fire tornado
	level._effect["napalm_spawn"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_spawn7");

	//NOTE: now done with an override - see fx/maps/zombie_temple/zombie_temple_impacts.csv
	//level._effect["napalm_impact"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_impact2");

	level._effect["napalm_distortion"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_heat" );

	//explosion wind up fx
	level._effect["napalm_fire_forearm_end"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_torso_end" );
	level._effect["napalm_fire_torso_end"] = LoadFX( "maps/zombie_temple/fx_ztem_napalm_zombie_forearm_end" );
	
	//Steam FX when napalm walks under water
	level._effect["napalm_steam"]				= LoadFX( "maps/zombie_temple/fx_ztem_zombie_torso_steam_runner" );
	level._effect["napalm_feet_steam"]			= LoadFX( "maps/zombie_temple/fx_ztem_zombie_torso_steam_runner" );
}

/*
napalm_zombie_impact_fx()
{
	self endon( "death" );
	while (1)
	{
		self waittill("damage", amount, attacker, dir, p, type);
		playfx( level._effect["napalm_impact"], p, dir*-1 );
	}
}
*/
	
napalm_zombie_spawn( animname_set )
{
	zombie_spawn_init( animname_set );

	self.animname = "napalm_zombie";
	self thread napalm_zombie_client_flag();
	self.napalm_zombie_glowing = false;

	self.maxhealth *= (GetPlayers().size * level.napalmHealthMultiplier);
	self.health = self.maxhealth;
	self.no_gib = true;
	self.rising = true;
	self.no_damage_points = true;
	
	self.explosive_volume = 0;
	
	//Napalm zombie can carry over to the next round
	self.ignore_enemy_count = true;

	self.deathFunction = ::napalm_zombie_death;
	self.actor_full_damage_func = ::_napalm_zombie_damage;
	
	self.nuke_damage_func = ::_napalm_nuke_damage;
	self.instakill_func = undefined; //::_napalm_instakill_func;

	self._zombie_shrink_callback = ::_napalm_Shrink;
	self._zombie_unshrink_callback = ::_napalm_Unshrink;
	
	self.water_trigger_func = ::napalm_enter_water_trigger;

	self maps\_zombiemode_spawner::set_zombie_run_cycle("walk");
	
	self.custom_damage_func = ::napalm_custom_damage;
	self.thundergun_knockdown_func = maps\_zombiemode_spawner::zombie_knockdown;
	self.monkey_bolt_taunts = ::napalm_monkey_bolt_taunts;

	//self thread _zombie_RunEffects();			//Moved client side
	self thread _zombie_WatchStopEffects();
	self thread _zombie_ExplodeNearPlayers();
	
	self thread napalm_watch_for_sliding();
	
	//TODO: run a thread that checks for water and plays a bubbling, steaming effect on the water's surface and plays a bubbling/sizzling sound?
	//self thread _zombie_WatchForWater();
	
	self thread napalm_zombie_count_watch();
	//self thread napalm_zombie_impact_fx();
	
	old_origin = self.origin;
	
	// find the closeset player and face him
	closest = GetClosest(self.origin, GetPlayers());
	angles = VectorToAngles(closest.origin - self.origin);

	anchor = Spawn("script_origin", self.origin);
	anchor.angles = angles;
	self linkto(anchor);
	self Hide();
	
	self.a.disablepain = true; 
	
	// make invulnerable for now....
	self magic_bullet_shield();

	anim_org = self.origin + (0, 0, -45);	// start the animation 45 units below the ground

	anchor MoveTo(anim_org, 0.05);
	anchor waittill("movedone");

	anchor RotateTo(angles, 0.05);
	anchor waittill("rotatedone");

	self Unlink();
	anchor Delete();

	self thread maps\_zombiemode_spawner::hide_pop();

	//Damage trigger around spawn location for a short period
	level thread napalm_fire_trigger( self, 80, 6, true );
	
	//play spawn sound, fx, anim - NOTE: all temp
	self PlaySound( "zmb_ignite" );
	self playsound( "evt_napalm_zombie_spawn" );
	fwd = anglestoforward( self.angles );
	playfx( level._effect["napalm_spawn"], old_origin, fwd, (0,0,1) );
	
	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "napalm_spawn" );

	speed = "run";
	spawn_anim = random(level._zombie_rise_anims["zombie"][1][speed]);
	time = getanimlength(spawn_anim);
	self animscripted("napalm_spawn", self.origin, self.angles, spawn_anim, "normal");
	wait( time );

	self.rising = false;
	self stop_magic_bullet_shield();
	self.a.disablepain = true;
	self BloodImpact( "hero" );

	self PlaySound( level.zmb_vox["napalm_zombie"]["ambient"] );
}

napalm_zombie_client_flag()
{
	if(isdefined(level._CF_ACTOR_IS_NAPALM_ZOMBIE))
	{
		self SetClientFlag(level._CF_ACTOR_IS_NAPALM_ZOMBIE);
		self waittill("death");
		self clearclientflag(level._CF_ACTOR_IS_NAPALM_ZOMBIE);
		napalm_clear_radius_fx_all_players();
	}
}

_napalm_nuke_damage()
{
	//Start running
//	var = randomintrange(1, 4);
//	self.needs_run_update = true;
//	self set_run_anim( "sprint" + var );                       
//	self.run_combatanim = level.scr_anim[self.animname]["sprint" + var];
}
_napalm_instakill_func()
{
	//Do Nothing
}
napalm_custom_damage( player )
{
	damage = self.meleeDamage;

	if ( isDefined( self.overrideDeathDamage ) )
	{
		damage = int( self.overrideDeathDamage );
	}

	return damage;
}

_zombie_RunExplosionWindupEffects()
{
	fx = [];
	fx["J_Elbow_LE"] = "napalm_fire_forearm_end";
	fx["J_Elbow_RI"] = "napalm_fire_forearm_end";
	fx["J_Clavicle_RI"] = "napalm_fire_forearm_end";
	fx["J_Clavicle_LE"] = "napalm_fire_forearm_end";
	fx["J_SpineLower"] = "napalm_fire_torso_end";

	offsets["J_SpineLower"] = (0.0, 10.0, 0.0);

	watch = [];

	keys = GetArrayKeys(fx);
	for ( i = 0; i < keys.size; i++ )
	{
		jointName = keys[i];
		fxName = fx[jointName];
		offset = offsets[jointName];
		effectEnt = self _zombie_SetupFXOnJoint(jointName, fxName, offset);
		watch[i] = effectEnt;
	}

	self waittill( "stop_fx" );

	if ( !IsDefined(self) )
	{
		return;
	}

	for ( i = 0; i < watch.size; i++ )
	{
		watch[i] Delete();
	}
}


_zombie_WatchStopEffects()
{
	self waittill("death");
	self notify("stop_fx");
}

_zombie_ExplodeNearPlayers()
{
	self endon("death");
	
	if(level.napalmExplodeRadius<=0)
	{
		return;
	}

	//Dont explode right away
	self.canExplodeTime = gettime() + 2000;
	//If changed update napalmPlayerWarningRadiusSqr in _zombiemode_ai_napalm.csc
	napalmExplodeRadiusSqr = level.napalmExplodeRadius*level.napalmExplodeRadius;
	napalmPlayerWarningRadius = level.napalmExplodeDamageRadius;
	napalmPlayerWarningRadiusSqr = napalmPlayerWarningRadius * napalmPlayerWarningRadius;
	while(1)
	{
		wait .1;
		
		if(is_true(self.is_traversing))
		{
			continue;
		}
		
		players = get_players();
		for(i=0;i<players.size;i++)
		{
			player = players[i];
			
			if(!is_player_valid(player))
			{
				continue;
			}
			
			//proximity heat warning - restarts every second?
			//NOTE: there is no LOS check here...
			//NOTE: assumes only ever 1 napalm zombie in the map at a time
			if(distance2dsquared(player.origin,self.origin) < napalmPlayerWarningRadiusSqr)
			{
				if ( !isdefined( player.napalmRadiusWarningTime ) || player.napalmRadiusWarningTime <= gettime() - 0.1 )
				{
					//level thread napalm_radius_overlay_on();
					player SetBurn( 10 );
					//player clientnotify( "napalm_radius_overlay_on" );
					player playloopsound( "chr_burning_loop", 1 );//zmb_sizzle" );//"chr_body_burn_sizzle" );//"chr_burning_loop" );
					player.napalmRadiusWarningTime = gettime() + 10000;
				}
			}
			else
			{
				if ( isdefined( player.napalmRadiusWarningTime ) && player.napalmRadiusWarningTime > gettime() )
				{
					player exit_napalm_radius();
				}
				continue;
			}
			
				//Wait to aquire enemy
			if( !isDefined(self.favoriteenemy) || !isPlayer(self.favoriteenemy))
			{
				continue;
			}
			
			if ( self.rising )
			{
				continue;
			}
			
			//can I actually explode yet?
			if ( self.canExplodeTime > gettime() )
			{
				continue;
			}
			
			//z check
			if( abs(player.origin[2] - self.origin[2]) > 50 )
			{
				continue;
			}
			
			//2d radius
			if(distance2dsquared(player.origin,self.origin) > napalmExplodeRadiusSqr)
			{
				continue;
			}
			
			if(isdefined(level._CF_ACTOR_NAPALM_ZOMBIE_EXPLODE))
			{
				self SetClientFlag(level._CF_ACTOR_NAPALM_ZOMBIE_EXPLODE);
			}
			//self thread _zombie_RunExplosionWindupEffects(); //Moved client side
			
			self playsound( "evt_napalm_zombie_charge" );
			explode_wind_up = %ai_zombie_napalm_attack_01;
			time = getanimlength(explode_wind_up);
			animScale = 2.0;
			self animscripted("napalm_explode", self.origin, self.angles, explode_wind_up, "normal", undefined, animScale);
			wait time/animScale;
	
			napalm_clear_radius_fx_all_players();
			
			//Kill self if close to player
			self.killed_self = true;
			self dodamage(self.health + 666, self.origin);
			return;
		}
	}
}

napalm_zombie_death()
{
	zombies_axis	= get_array_of_closest( self.origin, GetAiSpeciesArray( "axis", "all" ),			 undefined, undefined, level.napalmZombieDamageRadius );
	dogs			= get_array_of_closest( self.origin, GetAiSpeciesArray( "allies", "zombie_dog" ), undefined, undefined, level.napalmZombieDamageRadius );
	zombies			= array_combine( zombies_axis, dogs );

	// explosion effect
	if( IsDefined( level._effect["napalm_explosion"] ) )
	{
		PlayFxOnTag( level._effect["napalm_explosion"], self, "J_SpineLower" );
	}
	
	self playsound( "evt_napalm_zombie_explo" );
	
	if( isdefined( self.attacker ) && isPlayer( self.attacker ) )
	{
		self.attacker thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "napalm" );
	}
	
	level notify("napalm_death", self.explosive_volume);

	self thread napalm_delay_delete();

	if(!self napalm_standing_in_water(true))
	{
		level thread napalm_fire_trigger( self, 80, 20, false );
	}

	self thread _napalm_damage_zombies(zombies);
	napalm_clear_radius_fx_all_players();
	self _napalm_damage_players();
	
	//Reward players if the napalm was shot to death
	//(No reward if the napalm explodes himself or if he is shrunk)
	if( isDefined(self.attacker) && isPlayer(self.attacker) && !is_true(self.killed_self) && !is_true(self.shrinked) )
	{
		players = get_players();
		for(i=0;i<players.size;i++)
		{
			player = players[i];
			if(is_player_valid(player))
			{
				player maps\_zombiemode_score::player_add_points( "thundergun_fling", 300, (0,0,0), false );
			}
		}
	}
 	
	return self zombie_death_animscript();
}

napalm_delay_delete()
{
	self endon("death");
	
	self SetPlayerCollision(0);
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();
	wait_network_frame();
	self Hide();
	//self delete();
}

_napalm_damage_zombies(zombies)
{
	eyeOrigin = self GetEye();

	if ( !IsDefined(zombies) )
	{
		return;
	}

	damageOrigin = self.origin;
	standingInWater = self napalm_standing_in_water();
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

		if ( !BulletTracePassed( eyeOrigin, test_origin, false, undefined ) )
		{
			continue;
		}

		//Don't hurt other napalms or self
		if ( zombies[i].animname == "napalm_zombie" )
		{
			continue;
		}

		if(!standingInWater)
		{
			zombies[i] thread animscripts\zombie_death::flame_death_fx();
			//level thread napalm_fire_trigger( zombies[i], 24, 20, false );
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

		zombies[i] DoDamage( zombies[i].health + 666, damageOrigin);
		wait_network_frame();
	}

}

_napalm_damage_players()
{
	eyeOrigin = self GetEye();
	footOrigin = self.origin+(0,0,8);
	midOrigin = (footOrigin[0], footOrigin[1], (footOrigin[2] + eyeOrigin[2])/2);

	players_damaged_by_explosion = false;

	players = GetPlayers();
	for( i = 0; i < players.size; i++ )
 	{
 		if ( !is_player_valid( players[i] ) )
 		{
 			continue;
 		}
 
 		test_origin = players[i] GetEye();
		damageRadius = level.napalmExplodeDamageRadius;
		if(is_true(self.wet))
		{
			damageRadius = level.napalmExplodeDamageRadiusWet;
		}

		if( distanceSquared( eyeOrigin, test_origin ) > damageRadius * damageRadius )
 		{
 			continue;
 		}
 		
 		test_origin_foot = players[i].origin+(0,0,8);
		test_origin_mid = (test_origin_foot[0], test_origin_foot[1], (test_origin_foot[2] + test_origin[2])/2 );

		if ( !BulletTracePassed( eyeOrigin, test_origin, false, undefined ) )
 		{
			if ( !BulletTracePassed( midOrigin, test_origin_mid, false, undefined ) )
	 		{
				if ( !BulletTracePassed( footOrigin, test_origin_foot, false, undefined ) )
		 		{
	 				continue;
				}
			}
 		}
		
		players_damaged_by_explosion = true;

		// residual fire effect
		if( IsDefined( level._effect["player_fire_death_napalm"] ) )
		{
			PlayFxOnTag( level._effect["player_fire_death_napalm"], players[i], "J_SpineLower" );
		}

		//Scale Damage based on distnce	
		dist = distance( eyeOrigin, test_origin );
	
		killPlayerDamage = 100;
		killJusgsPlayerDamage = 250;
		
		shellShockMinTime = 1.5;
		shellShockMaxTime = 3.0;
		
		damage = level.napalmExplodeDamageMin;
		shellShockTime = shellShockMaxTime;
		if(dist<level.napalmExplodeKillRadiusJugs)
		{
			damage = killJusgsPlayerDamage;
		}
		else if (dist<level.napalmExplodeKillRadius)
		{
			damage = killPlayerDamage;
		}
		else
		{
			scale = (level.napalmExplodeDamageRadius - dist) / (level.napalmExplodeDamageRadius - level.napalmExplodeKillRadius);
			shellShockTime = scale * (shellShockMaxTime - shellShockMinTime) + shellShockMinTime;
			damage = scale * (killPlayerDamage - level.napalmExplodeDamageMin) + level.napalmExplodeDamageMin;
		}
		
		if(is_true(self.shrinked))
		{
			damage *= .25;
			shellshockTime *= .25;
		}
		
		if(is_true(self.wet))
		{
			damage *= .25;
			shellshockTime *= .25;
		}

		// make the penalty high for letting a napalm zombie get close
		//Damage passed into DoDamage doesn't matter only self.overrideDeathDamage is used (see napalm_custom_damage())
		self.overrideDeathDamage = damage;
		players[i]  DoDamage( damage, self.origin, self );
		players[i] shellshock( "explosion", shellshockTime );
		players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "napalm" );
 	}

	if ( !players_damaged_by_explosion )
	{
		level notify( "zomb_disposal_achieved" );
	}
}

napalm_fire_trigger( ai, radius, time, spawnFire )
{
	aiIsNapalm = ai.animname == "napalm_zombie";
	if(!aiIsNapalm)
	{
		radius = radius/2;
	}
	
	trigger = spawn( "trigger_radius", ai.origin, level.SPAWNFLAG_TRIGGER_AI_AXIS, radius, 70 );
	sound_ent = undefined;
	
	if(!isDefined(trigger))
	{
		return;
	}
	
	//effectEnt = undefined;
	if ( aiIsNapalm )
	{
		if(spawnFire)
		{
			trigger.napalm_fire_damage = 10; //Dont want spawn fire to kill the player, it feels cheap
		}
		else
		{
			trigger.napalm_fire_damage = 40;
		}
	
		trigger.napalm_fire_damage_type = "burned";
		if(!spawnFire && IsDefined( level._effect["napalm_fire_trigger"]))
		{
			sound_ent = spawn( "script_origin", ai.origin );
			sound_ent playloopsound( "evt_napalm_fire", 1 );
			PlayFX( level._effect["napalm_fire_trigger"], ai.origin );
		}
	}
	else
	{
		trigger.napalm_fire_damage = 10;
		trigger.napalm_fire_damage_type = "triggerhurt";
		if(spawnFire)
		{
			ai thread animscripts\zombie_death::flame_death_fx();
		}
	}
	
	trigger thread triggerDamage();
	
	wait(time);
	trigger notify("end_fire_effect");
	trigger Delete();
	
	if( isdefined( sound_ent ) )
	{
		sound_ent stoploopsound( 1 );
		wait(1);
		sound_ent delete();
	}
}

triggerDamage()
{
	self endon("end_fire_effect");
	
	while(1)
	{
		self waittill( "trigger", guy );
		if(isplayer(guy))
		{
			if(is_player_valid(guy))
			{
				debounce = 500;
				if(!isDefined(guy.last_napalm_fire_damage))
				{
					guy.last_napalm_fire_damage = -1 * debounce;
				}
				if(guy.last_napalm_fire_damage + debounce < GetTime())
				{
					guy DoDamage( self.napalm_fire_damage, guy.origin, undefined, undefined, self.napalm_fire_damage_type );//"triggerhurt"
					guy.last_napalm_fire_damage = GetTime();
				}
			}
		}
		else if(guy.animname != "napalm_zombie")
		{	
			guy thread kill_with_fire(self.napalm_fire_damage_type);
		}
	}
}

kill_with_fire(damageType)
{
	self endon("death");
	
	if(isdefined(self.marked_for_death))
	{
		return;
	}
	
	self.marked_for_death = true;
	if ( self.animname == "monkey_zombie" )
	{
		//Nothing
	}
	else
	{
		//a max of 6 burning zombs can be going at once
		if( (level.burning_zombies.size < 6) )
		{
			level.burning_zombies[level.burning_zombies.size] = self;
			self thread zombie_flame_watch();
			self playsound("evt_zombie_ignite");
			self thread animscripts\zombie_death::flame_death_fx();
			wait( randomfloat(1.25) );
		}
	}

	self dodamage(self.health + 666, self.origin, undefined, undefined, damageType);
}

zombie_flame_watch()
{
	if( level.mutators["mutator_noTraps"] )
	{
		return;
	}
	self waittill("death");
	if(isdefined(self))
	{
		self stoploopsound();
		level.burning_zombies = array_remove_nokeys(level.burning_zombies,self);
	}
	else
	{
		level.burning_zombies = array_removeUndefined(level.burning_zombies);
	}
}

_zombie_SetupFXOnJoint(jointName, fxName, offset)
{
	origin = self GetTagOrigin(jointName);
	effectEnt = Spawn("script_model", origin);
	effectEnt SetModel("tag_origin");
	effectEnt.angles = self GetTagAngles(jointName);
	if ( !IsDefined(offset) )
	{
		offset = (0,0,0);
	}
	effectEnt LinkTo(self, jointName, offset);

	PlayFXOnTag( level._effect[fxName], effectEnt, "tag_origin" );

	return effectEnt;
}

_napalm_Shrink()
{
	//self notify("stop_fx");
	//self.deathFunction = ::zombie_death_animscript;

}

_napalm_Unshrink()
{
	//self thread _zombie_RunEffects();
	//self.deathFunction = ::napalm_zombie_death;
}

_napalm_damage_callback( mod, hit_location, hit_origin, player, amount )
{
	//Don't give points as often as normal zombies
	if ( self.classname == "actor_zombie_napalm" )
	{
		//Napalm only give points if killed by bullets
//		if(!isDefined(self.damageCount))
//		{
//			self.damageCount = 0;
//		}
//		
//		if(self.damageCount % (GetPlayers().size * level.napalmHealthMultiplier) == 0)
//		{
//			player maps\_zombiemode_score::player_add_points( "thundergun_fling", 10, hit_location, self.isdog );
//		}
//		
//		self.damageCount++;
//		
		return true;
	}

	return false;
}

_napalm_zombie_damage( inflictor, attacker, damage, flags, meansofdeath, weapon, vpoint, vdir, sHitLoc, modelIndex, psOffsetTime )
{
	if ( level.zombie_vars["zombie_insta_kill"] )
	{
		damage *= 2;
	}
	
	//Vulnerable when wet
	if(is_true(self.wet))
	{
		damage *= 5;
	}
	else if (self napalm_standing_in_water())
	{
		damage *= 2;
	}
	
	switch ( weapon )
	{
		// rsh060211 - jimmy asked to take this out
	//case "ray_gun_zm":
	//case "ray_gun_upgraded_zm":
	//	damage /= 2;
	//	break;

	case "spikemore_zm":
		damage = 0;
		break;
	}
	

	return damage;
}

napalm_zombie_count_watch()
{
	if(!isDefined(level.napalmZombieCount))
	{
		level.napalmZombieCount=0;
	}
	level.napalmZombieCount++;
	self waittill("death");
	level.napalmZombieCount--;
	
	if(is_true(self.shrinked))
	{
		//Will spawn next round if killed with shrink ray
		level.nextNapalmSpawnRound = level.round_number + 1;
	}
	else
	{
		level.nextNapalmSpawnRound = level.round_number + RandomIntRange(level.napalmZombieMinRoundWait, level.napalmZombieMaxRoundWait + 1);
	}
}

napalm_clear_radius_fx_all_players()
{
	players = get_players();
	//stop radius fx/sound for all players
	for(j=0;j<players.size;j++)
	{
		player_to_clear = players[j];
		
		if(!IsDefined( player_to_clear ))
		{
			continue;
		}
		player_to_clear exit_napalm_radius();
	}
}
			
exit_napalm_radius()
{
	//level thread napalm_radius_overlay_off();
	//self clientnotify( "napalm_radius_overlay_off" );
	self SetBurn( 0 );
	self stoploopsound( 2 );//zmb_sizzle" );//"chr_body_burn_sizzle" );//"chr_burning_loop" );
	self.napalmRadiusWarningTime = gettime();
}

napalm_radius_overlay_on()
{
	self endon("napalm_radius_overlay_off");
	self notify("napalm_radius_overlay_on");

	screen_overlay = "flamethrowerfx_color_distort_overlay_bloom";
	
	if(!IsDefined(self.napalm_radius_overlay))
	{
		self.napalm_radius_overlay = NewHudElem(); 
		self.napalm_radius_overlay.x = 0; 
		self.napalm_radius_overlay.y = 0; 
		self.napalm_radius_overlay.horzAlign = "fullscreen"; 
		self.napalm_radius_overlay.vertAlign = "fullscreen"; 
		self.napalm_radius_overlay.foreground = true;
		self.napalm_radius_overlay SetShader( screen_overlay, 640, 480 );
		self.napalm_radius_overlay.alpha = 0.0;
		self.napalm_radius_overlay FadeOverTime( 1 ); 
		self.napalm_radius_overlay.alpha = 1.0;
	}
}

napalm_radius_overlay_off()
{
	self endon("napalm_radius_overlay_on");
	self notify("napalm_radius_overlay_off");
	if(IsDefined(self.napalm_radius_overlay))
	{
		self.napalm_radius_overlay FadeOverTime( 0.5 ); 
		self.napalm_radius_overlay.alpha = 0.0;
		wait(0.5);
		self.napalm_radius_overlay Destroy();
	}
}

napalm_enter_water_trigger(trigger)
{
	self endon("death");
	
	self thread napalm_add_wet_time(4);
}

napalm_add_wet_time(time)
{
	self endon("death");
	wetTime = time*1000;
	self.wet_time = GetTime() + wetTime;
	
	if(is_true(self.wet))
	{
		return;
	}
	
	self.wet = true;
	
	self thread napalm_start_wet_fx();
	while(self.wet_time>GetTime())
	{
		wait .1;
	}

	self thread napalm_end_wet_fx();
	self.wet = false;	
}

napalm_watch_for_sliding()
{
	self endon("death");
	
	while(1)
	{
		if(is_true(self.sliding))
		{
			self thread napalm_add_wet_time(4);
		}
		
		wait 1;
	}
}

napalm_start_wet_fx()
{
	self setclientflag(level._CF_ACTOR_NAPALM_ZOMBIE_WET);
}
napalm_end_wet_fx()
{
	self clearclientflag(level._CF_ACTOR_NAPALM_ZOMBIE_WET);
}

napalm_standing_in_water(forceCheck)
{
	doTrace = !isDefined(self.standing_in_water_debounce);
	doTrace = doTrace || self.standing_in_water_debounce<GetTime();
	doTrace = doTrace || is_true(forceCheck);
	if(doTrace)
	{
		self.standing_in_water_debounce = GetTime() + 500;
		waterheight = getwaterHeight(self.origin);
		self.standing_in_water = waterHeight>self.origin[2];
	}
	
	return self.standing_in_water;
}

napalm_monkey_bolt_taunts(monkey_bolt)
{
	//Napalm doesn't care
	return true;
}
