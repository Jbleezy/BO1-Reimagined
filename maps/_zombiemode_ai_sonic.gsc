#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;
#include maps\_zombiemode_spawner;
#include maps\_zombiemode_net;

#using_animtree( "generic_human" ); 

sonic_zombie_init()
{

	level.sonicZombiesEnabled			= true;
	level.sonicZombieMinRoundWait      	= 1;
	level.sonicZombieMaxRoundWait      	= 3;
	level.sonicZombieRoundRequirement	= 4;
	level.nextSonicSpawnRound          	= level.sonicZombieRoundRequirement + RandomIntRange(0, level.sonicZombieMaxRoundWait+1);

	level.sonicPlayerDamage				= 10;
	
	level.sonicScreamDamageRadius		= 300;	//25 feet
	level.sonicScreamAttackRadius		= 240;	//20 feet
	level.sonicScreamAttackDebounceMin	= 3;	//Min deboucne time between screams globally
	level.sonicScreamAttackDebounceMax	= 9;	//Max deboucne time between screams globally
 	level.sonicScreamAttackNext			= 0;	//Next any sonic zombie can do scream attack
		
	level.sonicHealthMultiplier        	= 2.5;

	level.sonic_zombie_spawners = GetEntArray( "sonic_zombie_spawner", "script_noteworthy" ); 
	
	if ( GetDvar("zombiemode_debug_sonic") == "" ) 
	{
		SetDvar("zombiemode_debug_sonic", "0");
	}
	
	//Copied from Thunder GUN
	set_zombie_var( "thundergun_knockdown_damage",		15 );

	level.thundergun_gib_refs = []; 
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "guts"; 
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "right_arm"; 
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "left_arm";
	//

	array_thread(level.sonic_zombie_spawners, ::add_spawn_function, ::sonic_zombie_spawn);
	array_thread(level.sonic_zombie_spawners, ::add_spawn_function, maps\_zombiemode::round_spawn_failsafe);

	maps\_zombiemode_spawner::register_zombie_damage_callback( ::_sonic_damage_callback );
	
	_sonic_InitFX();
	_sonic_InitAnims();
	_sonic_InitSounds();
	thread _sonic_InitSpawners();

} 

_sonic_InitFX()
{
	level._effect["sonic_explosion"] = LoadFX( "maps/zombie_temple/fx_ztem_sonic_zombie" );
	level._effect["sonic_spawn"] = LoadFX( "maps/zombie_temple/fx_ztem_sonic_zombie_spawn" );
	level._effect["sonic_attack"] = LoadFX( "maps/zombie_temple/fx_ztem_sonic_zombie_attack" );

//	level._effect["thundergun_knockdown_ground"]	= loadfx( "weapon/thunder_gun/fx_thundergun_knockback_ground" );
}

_sonic_InitAnims()
{
	level.scr_anim["sonic_zombie"]["death1"] 	= %ai_zombie_sonic_death_03;
	level.scr_anim["sonic_zombie"]["death2"] 	= %ai_zombie_sonic_death_02;
	level.scr_anim["sonic_zombie"]["death3"] 	= %ai_zombie_sonic_death_03;
	level.scr_anim["sonic_zombie"]["death4"] 	= %ai_zombie_sonic_death_02;
	
	level.scream_attack_death					= %ai_zombie_sonic_death_01; //Amim 01 is standing still anim

	// run cycles
	level.scr_anim["sonic_zombie"]["walk1"] 	= %ai_zombie_sonic_run_01;
	level.scr_anim["sonic_zombie"]["walk2"] 	= %ai_zombie_sonic_run_02;
	level.scr_anim["sonic_zombie"]["walk3"] 	= %ai_zombie_sonic_run_03;
	level.scr_anim["sonic_zombie"]["walk4"] 	= %ai_zombie_sonic_run_01;
	level.scr_anim["sonic_zombie"]["walk5"] 	= %ai_zombie_sonic_run_02;
	level.scr_anim["sonic_zombie"]["walk6"] 	= %ai_zombie_sonic_run_03;
	level.scr_anim["sonic_zombie"]["walk7"] 	= %ai_zombie_sonic_run_01;
	level.scr_anim["sonic_zombie"]["walk8"] 	= %ai_zombie_sonic_run_02;

	level.scr_anim["sonic_zombie"]["run1"] 	= %ai_zombie_sonic_run_01;
	level.scr_anim["sonic_zombie"]["run2"] 	= %ai_zombie_sonic_run_02;
	level.scr_anim["sonic_zombie"]["run3"] 	= %ai_zombie_sonic_run_03;
	level.scr_anim["sonic_zombie"]["run4"] 	= %ai_zombie_sonic_run_01;
	level.scr_anim["sonic_zombie"]["run5"] 	= %ai_zombie_sonic_run_02;
	level.scr_anim["sonic_zombie"]["run6"] 	= %ai_zombie_sonic_run_03;
	//level.scr_anim["zombie"]["run4"] 	= %ai_zombie_run_v1;
	//level.scr_anim["zombie"]["run6"] 	= %ai_zombie_run_v4;

	level.scr_anim["sonic_zombie"]["sprint1"] = %ai_zombie_sonic_run_01;
	level.scr_anim["sonic_zombie"]["sprint2"] = %ai_zombie_sonic_run_02;
	level.scr_anim["sonic_zombie"]["sprint3"] = %ai_zombie_sonic_run_03;
	level.scr_anim["sonic_zombie"]["sprint4"] = %ai_zombie_sonic_run_01;
	//level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v3;
	//level.scr_anim["zombie"]["sprint3"] = %ai_zombie_sprint_v4;
	//level.scr_anim["zombie"]["sprint4"] = %ai_zombie_sprint_v5;


	// run cycles in prone
	level.scr_anim["sonic_zombie"]["crawl1"] 	= %ai_zombie_crawl;
	level.scr_anim["sonic_zombie"]["crawl2"] 	= %ai_zombie_crawl_v1;
	level.scr_anim["sonic_zombie"]["crawl3"] 	= %ai_zombie_crawl_v2;
	level.scr_anim["sonic_zombie"]["crawl4"] 	= %ai_zombie_crawl_v3;
	level.scr_anim["sonic_zombie"]["crawl5"] 	= %ai_zombie_crawl_v4;
	level.scr_anim["sonic_zombie"]["crawl6"] 	= %ai_zombie_crawl_v5;
	level.scr_anim["sonic_zombie"]["crawl_hand_1"] = %ai_zombie_walk_on_hands_a;
	level.scr_anim["sonic_zombie"]["crawl_hand_2"] = %ai_zombie_walk_on_hands_b;

	level.scr_anim["sonic_zombie"]["crawl_sprint1"] 	= %ai_zombie_crawl_sprint;
	level.scr_anim["sonic_zombie"]["crawl_sprint2"] 	= %ai_zombie_crawl_sprint_1;
	level.scr_anim["sonic_zombie"]["crawl_sprint3"] 	= %ai_zombie_crawl_sprint_2;

	level.scr_anim["sonic_zombie"]["scream"] = [];
	level.scr_anim["sonic_zombie"]["scream"][0] = %ai_zombie_sonic_attack_01;
	level.scr_anim["sonic_zombie"]["scream"][1] = %ai_zombie_sonic_attack_02;
	level.scr_anim["sonic_zombie"]["scream"][2] = %ai_zombie_sonic_attack_03;

	// do we want to use the anims below?
	level._zombie_melee["sonic_zombie"] = level._zombie_melee["zombie"];
	level._zombie_run_melee["sonic_zombie"] = level._zombie_run_melee["zombie"];
	level._zombie_walk_melee["sonic_zombie"] = level._zombie_walk_melee["zombie"];


	//level._zombie_melee["sonic_zombie"] = [];
	//level._zombie_melee["sonic_zombie"][0] = %ai_zombie_sonic_attack_01;
	//level._zombie_melee["sonic_zombie"][1] = %ai_zombie_sonic_attack_02;
	//level._zombie_melee["sonic_zombie"][2] = %ai_zombie_sonic_attack_03;

	//level._zombie_run_melee["sonic_zombie"] = [];
	//level._zombie_run_melee["sonic_zombie"][0] = %ai_zombie_sonic_attack_01;
	//level._zombie_run_melee["sonic_zombie"][1] = %ai_zombie_sonic_attack_02;
	//level._zombie_run_melee["sonic_zombie"][2] = %ai_zombie_sonic_attack_03;

	//level._zombie_walk_melee["sonic_zombie"] = [];
	//level._zombie_walk_melee["sonic_zombie"][0] = %ai_zombie_sonic_attack_01;
	//level._zombie_walk_melee["sonic_zombie"][1] = %ai_zombie_sonic_attack_02;
	//level._zombie_walk_melee["sonic_zombie"][2] = %ai_zombie_sonic_attack_03;

	level._zombie_melee_crawl["sonic_zombie"] = level._zombie_melee_crawl["zombie"];
	level._zombie_stumpy_melee["sonic_zombie"] = level._zombie_stumpy_melee["zombie"];
	level._zombie_tesla_death["sonic_zombie"] = level._zombie_tesla_death["zombie"];
	level._zombie_tesla_crawl_death["sonic_zombie"] = level._zombie_tesla_crawl_death["zombie"];
	//level._zombie_knockdowns["sonic_zombie"] = level._zombie_knockdowns["zombie"];
	//level._zombie_getups["sonic_zombie"] = level._zombie_getups["zombie"];
	
	level._zombie_knockdowns["sonic_zombie"] = [];
	level._zombie_knockdowns["sonic_zombie"]["front"] = [];

	level._zombie_knockdowns["sonic_zombie"]["front"]["no_legs"] = [];
	level._zombie_knockdowns["sonic_zombie"]["front"]["no_legs"][0] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["sonic_zombie"]["front"]["no_legs"][1] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["sonic_zombie"]["front"]["no_legs"][2] = %ai_zombie_thundergun_hit_forwardtoface;

	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"] = [];

	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][0] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][1] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][2] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][3] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][4] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][5] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][6] = %ai_zombie_thundergun_hit_stumblefall;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][7] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][8] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][9] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][10] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][11] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][12] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][13] = %ai_zombie_thundergun_hit_deadfallknee;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][14] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][15] = %ai_zombie_thundergun_hit_doublebounce;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][16] = %ai_zombie_thundergun_hit_upontoback;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][17] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][18] = %ai_zombie_thundergun_hit_armslegsforward;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][19] = %ai_zombie_thundergun_hit_forwardtoface;
	level._zombie_knockdowns["sonic_zombie"]["front"]["has_legs"][20] = %ai_zombie_thundergun_hit_flatonback;

	level._zombie_knockdowns["sonic_zombie"]["left"] = [];
	level._zombie_knockdowns["sonic_zombie"]["left"][0] = %ai_zombie_thundergun_hit_legsout_right;

	level._zombie_knockdowns["sonic_zombie"]["right"] = [];
	level._zombie_knockdowns["sonic_zombie"]["right"][0] = %ai_zombie_thundergun_hit_legsout_left;

	level._zombie_knockdowns["sonic_zombie"]["back"] = [];
	level._zombie_knockdowns["sonic_zombie"]["back"][0] = %ai_zombie_thundergun_hit_faceplant;


	level._zombie_getups["sonic_zombie"] = [];
	level._zombie_getups["sonic_zombie"]["back"] = [];

	level._zombie_getups["sonic_zombie"]["back"]["early"] = [];
	level._zombie_getups["sonic_zombie"]["back"]["early"][0] = %ai_zombie_thundergun_getup_b;
	level._zombie_getups["sonic_zombie"]["back"]["early"][1] = %ai_zombie_thundergun_getup_c;

	level._zombie_getups["sonic_zombie"]["back"]["late"][0] = %ai_zombie_thundergun_getup_b;
	level._zombie_getups["sonic_zombie"]["back"]["late"] = [];
	level._zombie_getups["sonic_zombie"]["back"]["late"][1] = %ai_zombie_thundergun_getup_c;
	level._zombie_getups["sonic_zombie"]["back"]["late"][2] = %ai_zombie_thundergun_getup_quick_b;
	level._zombie_getups["sonic_zombie"]["back"]["late"][3] = %ai_zombie_thundergun_getup_quick_c;

	level._zombie_getups["sonic_zombie"]["belly"] = [];

	level._zombie_getups["sonic_zombie"]["belly"]["early"] = [];
	level._zombie_getups["sonic_zombie"]["belly"]["early"][0] = %ai_zombie_thundergun_getup_a;

	level._zombie_getups["sonic_zombie"]["belly"]["late"] = [];
	level._zombie_getups["sonic_zombie"]["belly"]["late"][0] = %ai_zombie_thundergun_getup_a;
	level._zombie_getups["sonic_zombie"]["belly"]["late"][1] = %ai_zombie_thundergun_getup_quick_a;
		
	

	level._zombie_deaths["sonic_zombie"] = [];
	level._zombie_deaths["sonic_zombie"][0] = %ai_zombie_sonic_death_01;
	level._zombie_deaths["sonic_zombie"][1] = %ai_zombie_sonic_death_02;
	level._zombie_deaths["sonic_zombie"][2] = %ai_zombie_sonic_death_03;

	level._zombie_board_taunt["sonic_zombie"] = level._zombie_board_taunt["zombie"];

}

_sonic_InitSounds()
{
	
	level.zmb_vox["sonic_zombie"]					=   [];
	level.zmb_vox["sonic_zombie"]["ambient"]     	=   "sonic_ambient";
	level.zmb_vox["sonic_zombie"]["sprint"]			=   "sonic_ambient";
	level.zmb_vox["sonic_zombie"]["attack"]			=   "sonic_attack";
	level.zmb_vox["sonic_zombie"]["teardown"]		=   "sonic_attack";
	level.zmb_vox["sonic_zombie"]["taunt"]			=   "sonic_ambient";
	level.zmb_vox["sonic_zombie"]["behind"]			=   "sonic_ambient";
	level.zmb_vox["sonic_zombie"]["death"]			=   "sonic_explode"; //"zmb_sonic_death";
	level.zmb_vox["sonic_zombie"]["crawler"]		=   "sonic_ambient";
	level.zmb_vox["sonic_zombie"]["scream"]			=   "sonic_scream";

}

_sonic_InitSpawners()
{
	flag_wait("zones_initialized");

	testOrigin = Spawn("script_model", (0,0,0));
	testOrigin SetModel("tag_origin");

	zkeys = GetArrayKeys(level.zones);
	for ( z = 0; z < zkeys.size; z++ )
	{
		zoneName = zkeys[z];
		zone = level.zones[zoneName];
		zone.sonic_spawn_locations = [];
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
				zone.sonic_spawn_locations = array_add(zone.sonic_spawn_locations, s);
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


sonic_zombie_spawn( animname_set )
{
	zombie_spawn_init( animname_set );


	self.animname = "sonic_zombie";
	
	if(isdefined(level._CF_ACTOR_IS_SONIC_ZOMBIE))
	{
		self SetClientFlag(level._CF_ACTOR_IS_SONIC_ZOMBIE);
	}

	//self.maxhealth = int(self.maxhealth * GetPlayers().size * level.sonicHealthMultiplier);
	self.maxhealth = int(self.maxhealth * level.sonicHealthMultiplier);
	self.health = self.maxhealth;
	
	//hack to prevent gibbing for now
	self.gibbed = true;
	
	//Sonic zombie can carry over to the next round
	self.ignore_enemy_count = true;

	self.sonicScreamAttackDebounceMin = 6;
	self.sonicScreamAttackDebounceMax = 10;
	
	self.death_knockdown_range = 480; //40 feet
	self.death_gib_range = 360; //30 feet
	self.death_fling_range = 240; //20 feet
	
	self.death_scream_range = 480;
	
	self _updateNextScreamTime();

	self.deathFunction = ::sonic_zombie_death;

	self._zombie_shrink_callback = ::_sonic_Shrink;
	self._zombie_unshrink_callback = ::_sonic_Unshrink;
	self.thundergun_knockdown_func = maps\_zombiemode_spawner::zombie_knockdown;
	self.monkey_bolt_taunts = ::sonic_monkey_bolt_taunts;
	
	self maps\_zombiemode_spawner::set_zombie_run_cycle( "sprint");
	
	self thread _zombie_screamAttackThink();
	
	//moved client side
	//self thread _zombie_ambient_sounds();

	self thread _zombie_RunEffects();
	
	self thread _zombie_InitSideStep();
	
	self thread _zombie_death_watch();
	
	//Track if sonic zombie is alive
	self thread sonic_zombie_count_watch();

	// find the closeset player and face him
	closest = GetClosest(self.origin, GetPlayers());
	angles = VectorToAngles(closest.origin - self.origin);

	anchor = Spawn("script_origin", self.origin);
	anchor.angles = (0,angles[1],0);
	self linkto(anchor);
	self Hide();
	
	self.a.disablepain = true; 
	self.rising = true;
	
	// make invulnerable for now....
	self magic_bullet_shield();

	anim_org = self.origin + (0, 0, -45);	// start the animation 45 units below the ground

	anchor MoveTo(anim_org, 0.05);
	anchor waittill("movedone");

	anchor RotateTo((0,angles[1],0), 0.05);
	anchor waittill("rotatedone");

	self Unlink();
	anchor Delete();

	self thread maps\_zombiemode_spawner::hide_pop();

	self playsound( "evt_sonic_spawn" );
	
	//Play a spawn response line on a random player
	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "general", "sonic_spawn" );
	
	speed = "sprint";
	spawn_anim = random(level._zombie_rise_anims["zombie"][1][speed]);
	time = getanimlength(spawn_anim);
	speedUp = 1.5;
	self animscripted("sonic_spawn", self.origin, self.angles, spawn_anim, "normal", %root, speedUp);

	fxWait = 0.3;
	wait(fxWait);
	self PlaySound( "zmb_vocals_sonic_scream" );
	PlayFX( level._effect["sonic_spawn"], self.origin, (0,0,1) );

	wait( Max(0, time/speedUp - fxWait) );

	self.rising = false;
	self stop_magic_bullet_shield();
	self.a.disablepain = true;
}

_zombie_InitSideStep()
{
	self.zombie_can_sidestep = true;
	self.sideStepAnims["step_left"]	= array( %ai_zombie_sonic_sidestep_left_a, %ai_zombie_sonic_sidestep_left_b );
	self.sideStepAnims["step_right"]	= array( %ai_zombie_sonic_sidestep_right_a, %ai_zombie_sonic_sidestep_right_b );

	self.sideStepAnims["roll_forward"]	= array( %ai_zombie_sonic_duck_a, %ai_zombie_sonic_duck_b, %ai_zombie_sonic_duck_c );
}

_zombie_death_watch()
{
	self waittill("death");
	
	if(isdefined(level._CF_ACTOR_IS_SONIC_ZOMBIE))
	{
		self ClearClientFlag(level._CF_ACTOR_IS_SONIC_ZOMBIE);
	}
}

_zombie_ambient_sounds()
{
	self endon("death");
	
	while(1)
	{
		self maps\_zombiemode_audio::do_zombies_playvocals( "ambient", "sonic_zombie" );
	}
}

//Self is zombie or level
_updateNextScreamTime()
{
	self.sonicScreamAttackNext	= GetTime();
	self.sonicScreamAttackNext	+= randomIntRange(self.sonicScreamAttackDebounceMin*1000, self.sonicScreamAttackDebounceMax*1000);	
}

_canScreamNow()
{
	if(GetTime() > self.sonicScreamAttackNext)
	{
		return true;
	}
	
	return false;
}

_zombie_screamAttackThink()
{
	self endon("death");

	thinkDebounce = .1;
	
	//Wait to aquire enemy
	while( !isDefined(self.favoriteenemy) || !isPlayer(self.favoriteenemy))
	{
		wait thinkDebounce;
	}
	
	while(true)
	{
		//Check scream attack debounce timers
		hasHead = !is_true(self.head_gibbed);
		notMini = !is_true(self.shrinked);
		screamTime = level _canScreamNow() && self _canScreamNow();
		if( screamTime && !self.ignoreAll && !is_true(self.is_traversing) && hasHead && notMini)
		{
			blurPlayers = self _zombie_any_players_in_blur_area();
			
			if(blurPlayers)
			{
				self _zombie_screamAttackAnim();
			}
		}

		wait thinkDebounce;	
	}	
}

_zombie_getNearByPlayers()
{
	nearByPlayers = [];

	radiusSqr = level.sonicScreamAttackRadius * level.sonicScreamAttackRadius;
	
	players = get_players();
	for(i=0; i<players.size; i++)
	{
		if(!is_player_valid(players[i]))
		{
			continue;
		}
		
		playerOrigin = players[i].origin;
		
		
		if( abs(playerOrigin[2] - self.origin[2]) > 70 )
		{
			continue;
		}
		
		if( distance2dsquared(playerOrigin, self.origin) > radiusSqr )
		{
			continue;
		}
		
		nearByPlayers[nearByPlayers.size] = players[i];
	}
	
	return nearByPlayers;
}

_zombie_screamAttackAnim()
{
	level _updateNextScreamTime();
	self _updateNextScreamTime();
	
	//Override death anim while screaming
	self.deathanim = level.scream_attack_death;
	
	scream_attack_anim =  random(level.scr_anim["sonic_zombie"]["scream"]);
	time = getAnimLength( scream_attack_anim );
	
	//NOTE: for some reason, addNotetrack_customFunction doesn't work with these anims, so I'm checking for the notetrack and manually doing the delay...
	scream_attack_times = getnotetracktimes( scream_attack_anim, "fire" );
	self thread _zombie_screamAttack( scream_attack_times[0] * time );

	self animscripted( "sonic_zombie_scream", self.origin, self.angles, scream_attack_anim);
	self _zombie_screamAttackAnim_wait(time);
	self stopanimscripted(.5);
	self _zombie_scream_attack_done(); 
	
	//put death anim back
	death_anims = level._zombie_deaths[self.animname];
	self.deathanim = random(death_anims);
}

_zombie_screamAttackAnim_wait(time)
{
	self endon("death");
	
	endTime = GetTime() + (time*1000);
	while(GetTime()<endTime)
	{
		if(!self _zombie_any_players_in_blur_area())
		{
			break;
		}
		
		if(is_true(self.shrinked))
		{
			break;
		}
		
		if(is_true(self.head_gibbed))
		{
			break;
		}
		
		wait .1;
	}
}

_zombie_screamAttack( delay )
{
	self endon( "death" );
	self endon("scream_attack_done");
	
	wait(delay);

	self PlaySound("zmb_vocals_sonic_scream");
	//self thread maps\_zombiemode_audio::do_zombies_playvocals( "scream", self.animname );
	
	self thread _zombie_playscreamfx();
	
	players = GetPlayers();
	array_thread( players, ::_player_ScreamAttackWatch, self );
	
	wait (2.0);
	
	self thread _zombie_scream_attack_done();
}

_zombie_scream_attack_done()
{
	players = GetPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] notify("scream_watch_done");
	}
	
	//self stopsound("zmb_vocals_sonic_scream");
	self notify("scream_attack_done");
}

_zombie_playScreamFX()
{
	if(isDefined(self.screamFX))
	{
		self.screamFX Delete();
	}
	
	tag = "TAG_EYE";
	origin = self GetTagOrigin(tag);
	self.screamFX = Spawn("script_model", origin);
	self.screamFX SetModel("tag_origin");
	self.screamFX.angles = self GetTagAngles(tag);
	self.screamFX LinkTo(self, tag);
	PlayFXOnTag( level._effect["sonic_attack"], self.screamFX, "tag_origin" );
	self waittill_any("death", "scream_attack_done", "shrink");
	self.screamFX Delete();
	
	//PlayFXOnTag( level._effect["sonic_attack"], self, "tag_eye" );
}

_player_ScreamAttackWatch( sonic_zombie )
{
	self endon("death");
	self endon("scream_watch_done");
	sonic_zombie endon("death");

	self.screamAttackBlur = false;

	while ( true )
	{
		if(self _player_in_blur_area(sonic_zombie))
		{
			break;	
		}

		wait( 0.1 );
	}

	self thread _player_SonicBlurVision(sonic_zombie);
	self thread maps\_zombiemode_audio::create_and_play_dialog( "general", "sonic_hit" );
}

_player_in_blur_area(sonic_zombie)
{
	// check if we are close enough to the sonic zombie to start the blur
	if( abs(self.origin[2] - sonic_zombie.origin[2]) > 70 )
	{
		return false;
	}
	
	radiusSqr = level.sonicScreamDamageRadius * level.sonicScreamDamageRadius;
	if( distance2dsquared(self.origin, sonic_zombie.origin) > radiusSqr )
	{
		return false;
	}
	
	//Sonic scream is directional
	dirToPlayer = self.origin - sonic_zombie.origin;
	dirToPlayer = vectornormalize(dirToPlayer);
	sonicDir = anglestoforward(sonic_zombie.angles);
	
	dot = vectordot(dirToPlayer, sonicDir);
	if(dot<.4)
	{
		return false;
	}
	
	return true;
}

_zombie_any_players_in_blur_area()
{
	if(is_true(level.intermission))
	{
		return false;
	}
	
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		player = players[i];
		if(is_player_valid(player) && player _player_in_blur_area(self))
		{
			return true;
		}
	}
	return false;
}

_player_SonicBlurVision(zombie)
{
	self endon("disconnect");
	level endon("intermission");

	if ( !self.screamAttackBlur )
	{
		mini = isDefined(zombie) && is_true(zombie.shrinked);
		self.screamAttackBlur = true;
		
		if(mini)
		{
			self _player_screamAttackDamage(1.0, 2, 0.2, "damage_light", zombie );
		}
		else
		{
			self _player_screamAttackDamage(4.0, 5, 0.2, "damage_heavy", zombie );
		}
		self.screamAttackBlur = false;
	}
}

_player_screamAttackDamage(time, blurScale, earthquakeScale, rumble, attacker)
{
	self thread _player_blurFailsafe();

	Earthquake( earthquakeScale, 3, attacker.origin, level.sonicScreamDamageRadius, self );
	self SetBlur(blurScale, 0.2);
	self PlayRumbleOnEntity(rumble);

	self _player_screamAttack_wait(time);

	self SetBlur(0,0.5);
	self notify( "blur_cleared" );
	self stoprumble(rumble);
}

_player_blurFailsafe()
{
	self endon( "disconnect" );
	self endon( "blur_cleared" );

	level waittill( "intermission" );

	self SetBlur( 0, 0.5 );
}

_player_screamAttack_wait(time)
{
	self endon("disconnect");
	level endon("intermission");
	
	wait(time);
}

_player_sonicZombieDeath_DoubleVision()
{
	self SetDoubleVision( 10, 3 );
}

_zombie_RunEffects()
{
//	fx = [];
//	fx["J_Wrist_RI"] = "napalm_fire_forearm";
//	fx["J_Wrist_LE"] = "napalm_fire_forearm";
//	fx["J_SpineLower"] = "napalm_fire_torso";

//	watch = [];

//	keys = GetArrayKeys(fx);
//	for ( i = 0; i < keys.size; i++ )
//	{
//		jointName = keys[i];
//		fxName = fx[jointName];
//		effectEnt = self _zombie_SetupFXOnJoint(jointName, fxName);
//		watch[i] = effectEnt;
//	}

//	self waittill( "death" );

//	if ( !IsDefined(self) )
//	{
//		return;
//	}

//	for ( i = 0; i < watch.size; i++ )
//	{
//		watch[i] Delete();
//	}
}
_zombie_SetupFXOnJoint(jointName, fxName)
{
	origin = self GetTagOrigin(jointName);
	effectEnt = Spawn("script_model", origin);
	effectEnt SetModel("tag_origin");
	effectEnt.angles = self GetTagAngles(jointName);
	effectEnt LinkTo(self, jointName);

	PlayFXOnTag( level._effect[fxName], effectEnt, "tag_origin" );

	return effectEnt;
}

sonic_zombie_death()
{
	self playsound( "evt_sonic_explode" );
	// explosion effect
	if( IsDefined( level._effect["sonic_explosion"] ) )
	{
		PlayFxOnTag( level._effect["sonic_explosion"], self, "J_SpineLower" );
	}
	
	if(isDefined(self.attacker) && isPlayer(self.attacker))
	{
		self.attacker thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "sonic" );
	}
	
	//Zombies head explode
	self thread _sonic_zombie_death_scream(self.attacker);
	
//	//Push Zombies
//	_sonic_zombie_death_explode(self.attacker);
//		
//	//Double Vision on Players
//	nearByPlayers = _zombie_getNearByPlayers();
//	for(i=0; i<nearByPlayers.size; i++)
//	{
//		//TODO: Fix double vision
//		//nearByPlayers[i] thread _player_sonicZombieDeath_DoubleVision();
//		nearByPlayers[i] thread _player_screamAttack_blurVision();
//	}
 	
	return self zombie_death_animscript();
}

zombie_sonic_scream_death(attacker)
{
	self endon("death");
	
	//Small random so everyone isn't in sync
	randomWait = randomfloatrange(0, 1.0);
	wait randomWait;
	
	if(self.has_legs)
	{
		zombie_anim =  %ai_zombie_taunts_9;
		time = getAnimLength( zombie_anim );
		self notify("stop_find_flesh");
		self animscripted("zombie_react", self.origin, self.angles, zombie_anim, "normal", %body, 1, 0.2);
		
		time = time * randomfloatrange(0.75, 1);	//Radom death time offset so every one doesn't die at the same time
		wait(time);
	}

	// don't let these zombies drop powerups
	self.no_powerups = true;
	
	self maps\_zombiemode_spawner::zombie_eye_glow_stop();

	self playsound( "evt_zombies_head_explode" );
	
	// kill the zombie (pop his head off)
	self maps\_zombiemode_spawner::zombie_head_gib();
	self dodamage(self.health + 666, self.origin, attacker);
}


_sonic_zombie_death_scream(attacker)
{
	zombies = _sonic_zombie_get_enemies_in_scream_range();
	
	for(i=0;i<zombies.size;i++)
	{
		if ( !IsDefined( zombies[i] ) )
		{
			continue;
		}

		if ( is_magic_bullet_shield_enabled( zombies[i] ) )
		{
			continue;
		}
		
		if ( self.animname == "monkey_zombie" )
		{
			continue;
		}
		
		zombies[i] thread zombie_sonic_scream_death(attacker);
	}
}

_sonic_zombie_death_explode(attacker)
{
	// ww: physics hit when firing
	PhysicsExplosionCylinder( self.origin, 600, 240, 1 );
	
	if ( !IsDefined( level.sonicZombie_knockdown_enemies ) )
	{
		level.sonicZombie_knockdown_enemies = [];
		level.sonicZombie_knockdown_gib = [];
		level.sonicZombie_fling_enemies = [];
		level.sonicZombie_fling_vecs = [];
	}

	self _sonic_zombie_get_enemies_in_range();

	level.sonic_zombie_network_choke_count = 0;
	
	for ( i = 0; i < level.sonicZombie_fling_enemies.size; i++ )
	{
		_sonic_zombie_network_choke();
		level.sonicZombie_fling_enemies[i] thread _sonicZombie_fling_zombie( attacker, level.sonicZombie_fling_vecs[i], i );
	}
	for ( i = 0; i < level.sonicZombie_knockdown_enemies.size; i++ )
	{
		_sonic_zombie_network_choke();
		level.sonicZombie_knockdown_enemies[i] thread _sonicZombie_knockdown_zombie( attacker, level.sonicZombie_knockdown_gib[i] );
	}

	level.sonicZombie_knockdown_enemies = [];
	level.sonicZombie_knockdown_gib = [];
	level.sonicZombie_fling_enemies = [];
	level.sonicZombie_fling_vecs = [];
}

_sonic_zombie_network_choke()
{
	level.sonic_zombie_network_choke_count++;
	
	if ( !(level.sonic_zombie_network_choke_count % 10) )
	{
		wait_network_frame();
		wait_network_frame();
		wait_network_frame();
	}
}

_sonic_zombie_get_enemies_in_scream_range()
{
	return_zombies = [];
	center = self getcentroid();
	
	zombies = get_array_of_closest( center, GetAiSpeciesArray( "axis", "all" ), undefined, undefined, self.death_scream_range );
	if ( isDefined( zombies ) )
	{
		for ( i = 0; i < zombies.size; i++ )
		{
			if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
			{
				// guy died on us
				continue;
			}

			test_origin = zombies[i] getcentroid();
			if ( !BulletTracePassed( center, test_origin, false, undefined ) )
	 		{
	 			continue;
	 		}

			return_zombies[return_zombies.size] = zombies[i];
		}
	}
	
	return return_zombies;
	
}

_sonic_zombie_get_enemies_in_range()
{
	center = self getcentroid();
	
	zombies = get_array_of_closest( center, GetAiSpeciesArray( "axis", "all" ), undefined, undefined, self.death_knockdown_range );
	if ( !isDefined( zombies ) )
	{
		return;
	}

	knockdown_range_squared = self.death_knockdown_range * self.death_knockdown_range;
	gib_range_squared = self.death_gib_range * self.death_gib_range;
	fling_range_squared = self.death_fling_range * self.death_fling_range;

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		test_origin = zombies[i] getcentroid();
		test_range_squared = DistanceSquared( center, test_origin );
		if ( test_range_squared > knockdown_range_squared )
		{
			return; // everything else in the list will be out of range
		}

		if ( !BulletTracePassed( center, test_origin, false, undefined ) )
 		{
 			continue;
 		}

		if ( test_range_squared < fling_range_squared )
		{
			level.sonicZombie_fling_enemies[level.sonicZombie_fling_enemies.size] = zombies[i];

			// the closer they are, the harder they get flung
			dist_mult = (fling_range_squared - test_range_squared) / fling_range_squared;
			fling_vec = VectorNormalize( test_origin - center );

			fling_vec = (fling_vec[0], fling_vec[1], abs( fling_vec[2] ));
			fling_vec = vector_scale( fling_vec, 100 + 100 * dist_mult );
			level.sonicZombie_fling_vecs[level.sonicZombie_fling_vecs.size] = fling_vec;

			//zombies[i] thread setup_thundergun_vox( self, true, false, false );
		}
		else if ( test_range_squared < gib_range_squared )
		{
			level.sonicZombie_knockdown_enemies[level.sonicZombie_knockdown_enemies.size] = zombies[i];
			level.sonicZombie_knockdown_gib[level.sonicZombie_knockdown_gib.size] = true;

			//zombies[i] thread setup_thundergun_vox( self, false, true, false );
		}
		else
		{
			level.sonicZombie_knockdown_enemies[level.sonicZombie_knockdown_enemies.size] = zombies[i];
			level.sonicZombie_knockdown_gib[level.sonicZombie_knockdown_gib.size] = false;

			//zombies[i] thread setup_thundergun_vox( self, false, false, true );
		}
	}
}

_sonicZombie_fling_zombie( player, fling_vec, index )
{
	if( !IsDefined( self ) || !IsAlive( self ) )
	{
		// guy died on us 
		return;
	}

//	if ( IsDefined( self.thundergun_fling_func ) )
//	{
//		self [[ self.thundergun_fling_func ]]( player );
//		return;
//	}
	
	self DoDamage( self.health + 666, player.origin, player );

	if ( self.health <= 0 )
	{
		points = 10;
		if ( !index )
		{
			points = maps\_zombiemode_score::get_zombie_death_player_points();
		}
		else if ( 1 == index )
		{
			points = 30;
		}
		player maps\_zombiemode_score::player_add_points( "thundergun_fling", points );
		
		self StartRagdoll();
		self LaunchRagdoll( fling_vec );
	}
}


_sonicZombie_knockdown_zombie( player, gib )
{
	self endon( "death" );
	//playsoundatposition ("vox_thundergun_forcehit", self.origin);
	//playsoundatposition ("wpn_thundergun_proj_impact", self.origin);


	if( !IsDefined( self ) || !IsAlive( self ) )
	{
		// guy died on us 
		return;
	}

	if ( IsDefined( self.thundergun_knockdown_func ) )
	{
		self.lander_knockdown = 1; //Hack to get knock down anims
		self [[ self.thundergun_knockdown_func ]]( player, gib );
	}
	else
	{
		if ( gib )
		{
			self.a.gib_ref = random( level.thundergun_gib_refs );
			self thread animscripts\zombie_death::do_gib();
		}

	//	self playsound( "thundergun_impact" );
		self.thundergun_handle_pain_notetracks = maps\_zombiemode_weap_thundergun::handle_thundergun_pain_notetracks;
		self DoDamage( 20, player.origin, player );
		//self playsound( "fly_thundergun_forcehit" );	
	}
}

_sonic_Shrink()
{
	//self notify("stop_scream_attack");
	//self.deathFunction = ::zombie_death_animscript;
}

_sonic_Unshrink()
{
	//self thread _zombie_screamAttackThink();
	//self.deathFunction = ::sonic_zombie_death;
}

sonic_zombie_count_watch()
{
	if(!isDefined(level.sonicZombieCount))
	{
		level.sonicZombieCount=0;
	}
	level.sonicZombieCount++;
	self waittill("death");
	level.sonicZombieCount--;
	
	//Update next spawn time
	if(is_true(self.shrinked))
	{
		//Will spawn next round if killed with shrink ray
		level.nextSonicSpawnRound = level.round_number + 1;
	}
	else
	{		
		level.nextSonicSpawnRound = level.round_number + RandomIntRange(level.sonicZombieMinRoundWait, level.sonicZombieMaxRoundWait + 1);
	}

	attacker = self.attacker;
	if ( isdefined( attacker ) && isplayer( attacker ) && is_true( attacker.screamAttackBlur ) )
	{
		attacker notify( "blinded_by_the_fright_achieved" );
	}
}

_sonic_damage_callback( mod, hit_location, hit_origin, player, amount )
{
	if(is_true(self.lander_knockdown))
	{
		return false;
	}
	//Don't give points as often as normal zombies
	if ( self.classname == "actor_zombie_sonic" )
	{
		if(!isDefined(self.damageCount))
		{
			self.damageCount = 0;
		}
		
		if(self.damageCount % int(GetPlayers().size * level.sonicHealthMultiplier) == 0)
		{
			player maps\_zombiemode_score::player_add_points( "thundergun_fling", 10, hit_location, self.isdog );
		}
		
		self.damageCount++;
		
		self thread maps\_zombiemode_powerups::check_for_instakill( player, mod, hit_location );
		
		return true;
	}

	return false;
}

sonic_monkey_bolt_taunts(monkey_bolt)
{
	//Dont taunt while rising
	return is_true(self.rising);
}
