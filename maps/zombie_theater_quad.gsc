#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;

init_roofs()
{
	flag_wait( "curtains_done" );

	level thread quad_stage_roof_break();
	level thread quad_lobby_roof_break();
	level thread quad_dining_roof_break();

	level thread quad_roof_fx();	
}

////////////////////////////////////////////////////
// QUAD FX
////////////////////////////////////////////////////
quad_roof_crumble_fx()
{
	quad_crumble_triggers = GetEntArray("quad_roof_crumble_fx_trigger", "targetname");
	array_thread(quad_crumble_triggers, ::quad_roof_crumble_fx_play);
}

quad_roof_crumble_fx_play()
{
	//if ( !IsDefined( no_trigger ) )
	//{
	//	self waittill( "trigger", who );
	//}
	
	play_quad_first_sounds();
	
	roof_parts = getEntArray(self.target, "targetname");

	if(isDefined(roof_parts))
	{
		for(i=0; i<roof_parts.size;i++)
		{
			roof_parts[i] delete();
		}
	}
	
	fx = getStruct(self.target, "targetname");	
	
	if(isDefined(fx))
	{		
		//playfx(level._effect["quad_roof_break"], fx.origin);
		//playsoundatposition( "zmb_quad_roof_break", fx.origin );
		//thread play_wood_land_sound( fx.origin );
		
		// Rumble 		
		thread rumble_all_players( "damage_heavy" );
	}

	// Trigger Light entrance
	if(isDefined(self.script_noteworthy))
	{		
		clientnotify(self.script_noteworthy);
		//iprintlnbold("GSC - Turning Power Light On:  " + self.script_noteworthy);
	}	
	
	if (IsDefined(self.script_int))
	{
		exploder(self.script_int);
	}		
}

play_quad_first_sounds()
{
	if(level.script != "survival")
	{
		if(!IsDefined(level.quad_sounds_called))
		{
			level.quad_sounds_called = 0;
		}

		level.quad_sounds_called++;
	}

	location = getstruct(self.target, "targetname" );

	if(level.script == "survival" || (IsDefined(level.quad_sounds_called) && level.quad_sounds_called > 14))
	{
    	self PlaySound( "zmb_vocals_quad_spawn", "sounddone" );
    	self waittill( "sounddone" );
	}

    self PlaySound( "zmb_quad_roof_hit" );
    thread play_wood_land_sound( location.origin );
}

play_wood_land_sound( origin )
{
    wait(1);
    playsoundatposition( "zmb_quad_roof_break_land", origin - (0,0,150) );
}

rumble_all_players(high_rumble_string, low_rumble_string, rumble_org, high_rumble_range, low_rumble_range)
{
	players = get_players();
	
	for (i = 0; i < players.size; i++)
	{
		if (isdefined (high_rumble_range) && isdefined (low_rumble_range) && isdefined(rumble_org))
		{
			if (distance (players[i].origin, rumble_org) < high_rumble_range)
			{
				players[i] playrumbleonentity(high_rumble_string);
			}
			else if (distance (players[i].origin, rumble_org) < low_rumble_range)
			{
				players[i] playrumbleonentity(low_rumble_string);
			}
		}
		else
		{
			players[i] playrumbleonentity(high_rumble_string);
		}
	}
}

quad_roof_fx()
{
	quad_roof_triggers = GetEntArray("quad_roof_dust_effect_trigger", "targetname");
	array_thread(quad_roof_triggers, ::quad_roof_fx_play);
}

quad_roof_fx_play()
{
	while( 1 )
	{
		self waittill( "trigger", who );

		if ( is_true( who.triggered ) )
		{
			continue;
		}
		else
		{
			who.triggered = true;
		}

		//dust_origin = GetStruct(self.target, "targetname");
		//playfx(level._effect["quad_dust_roof"], dust_origin.origin);
		exploder( self.script_int );
	}
}

quad_traverse_death_fx()
{
	self endon("quad_end_traverse_anim");
	self waittill( "death" );

	playfx(level._effect["quad_grnd_dust_spwnr"], self.origin);
}

////////////////////////////////////////////////////
// QUAD INTRODUCTION ROUNDS
// 	This initial quad round first spawns quads, then mixes between quads and regular zombies
////////////////////////////////////////////////////

begin_quad_introduction(quad_round_name)
{	
	//handle dog cases
	if(flag("dog_round"))
	{
		flag_clear("dog_round");
	}
	if (level.next_dog_round == (level.round_number + 1))
		level.next_dog_round++;
		
	level.zombie_total = 0;
	
	// Remember the last round number for when we return
	level.quad_round_name = quad_round_name;
}

Theater_Quad_Round()
{
	level.zombie_health = level.zombie_vars["zombie_health_start"]; 

	old_round = level.round_number;

	level.zombie_total = 0;

	// calculate zombie health
	level.zombie_health = 100 * old_round;

	//kill all active zombies
	kill_all_zombies();
	
	level.round_number = old_round;
}

spawn_second_wave_quads(second_wave_targetname)
{
	second_wave_spawners = [];
	second_wave_spawners = GetEntArray(second_wave_targetname,"targetname");
	
	if( second_wave_spawners.size < 1 )
	{
		ASSERTMSG( "No second wave quad spawners in spawner array." ); 
		return; 
	}	

	//iprintlnbold("Quad Zombie Second Wave...");
	
	for(i=0; i<second_wave_spawners.size; i++)
	{
		ai = spawn_zombie(second_wave_spawners[i]);
		if( IsDefined( ai ) )
		{	
			ai thread maps\_zombiemode::round_spawn_failsafe();
			ai thread quad_traverse_death_fx();
		}
		
		wait(RandomInt(10,45));		
	}
	
	wait_network_frame();
}

spawn_a_quad_zombie(spawn_array)
{	
	spawn_point = spawn_array[RandomInt( spawn_array.size )]; 

	ai = spawn_zombie( spawn_point ); 
	if( IsDefined( ai ) )
	{	
		ai thread maps\_zombiemode::round_spawn_failsafe();
		ai thread quad_traverse_death_fx();
	}
	
	wait( level.zombie_vars["zombie_spawn_delay"] ); 
	//wait(RandomInt(10,45));
	
	//iprintlnbold("Spawn a Quad Zombie...");
	wait_network_frame();
}

kill_all_zombies()
{
	zombies = GetAiSpeciesArray( "axis", "all" );

	if ( IsDefined( zombies ) )
	{
		for (i = 0; i < zombies.size; i++)
		{
			if( !IsDefined( zombies[i] ) )
			{
				continue;
			}		

			zombies[i] dodamage(zombies[i].health + 666, zombies[i].origin);
			wait_network_frame();
		}
	}	
}

// This is used to prevent the round from ending when we are pacing the quad spawners.  It's possible to end 
//	the round if we kill a delayed quad spawner and there are no other zombies in the map.
prevent_round_ending()
{
	level endon("quad_round_can_end");
	
	while( 1 )
	{
		if(level.zombie_total < 1)
		{
			level.zombie_total = 1;
		}
		
		wait(0.5);
	}
}

Intro_Quad_Spawn()
{	
	timer = GetTime();
	spawned = 0;
	
	previous_spawn_delay = level.zombie_vars["zombie_spawn_delay"];
	
	thread prevent_round_ending();
	///////////////////////////////////////////////////////
	// initial wave of quads
	///////////////////////////////////////////////////////

	//iprintlnbold("Quad Zombie Initial Wave...");
	
	//try to spawn a zombie.
	initial_spawners = [];
	
	switch(level.quad_round_name)
	{
		case "initial_round":
			initial_spawners = GetEntArray("initial_first_round_quad_spawner","targetname");
			break;
		
		case "theater_round":
			initial_spawners = GetEntArray("initial_theater_round_quad_spawner","targetname");
			break;
		
		default:
			ASSERTMSG( "No round specified for introducing quad round." ); 
			return;
	}
	
	if( initial_spawners.size < 1 )
	{
		ASSERTMSG( "No initial quad spawners in spawner array." ); 
		return; 
	}	
			
	while(1)
	{
		// gradually introduce the quads by adjusting the delay between quad spawns
		if(isDefined(level.delay_spawners))
			manage_zombie_spawn_delay( timer );
			
		level.delay_spawners = true;	
		
		spawn_a_quad_zombie(initial_spawners);

		wait(0.2);
		spawned++;
		if (spawned > level.quads_per_round)
		{
			break;
		}
	}
	
	///////////////////////////////////////////////////////
	// second wave of quads
	///////////////////////////////////////////////////////
		
	//iprintlnbold("Quad Zombie Second Wave...");
	
	spawned = 0;

	second_spawners = [];

	switch(level.quad_round_name)
	{
		case "initial_round":
			second_spawners = GetEntArray("initial_first_round_quad_spawner_second_wave","targetname");
			break;
		
		case "theater_round":
		
			second_spawners = GetEntArray("theater_round_quad_spawner_second_wave","targetname");
			break;
		
		default:
			ASSERTMSG( "No round specified for second quad wave." ); 
			return;
	}
	
	if( second_spawners.size < 1 )
	{
		ASSERTMSG( "No second quad spawners in spawner array." ); 
		return; 
	}
	
	while(1)
	{
		// gradually introduce the quads by adjusting the delay between quad spawns
		manage_zombie_spawn_delay( timer );
		
		spawn_a_quad_zombie(second_spawners);

		wait(0.2);
		spawned++;
		if (spawned > level.quads_per_round * 2)
		{
			break;
		}
	}	
	
	// restore previous spawn delay
	level.zombie_vars["zombie_spawn_delay"] = previous_spawn_delay;
	
	level.zombie_health = level.zombie_vars["zombie_health_start"]; 
	//level.round_number = 1;
	level.zombie_total = 0;

	///////////////////////////////////////////////////////
	// mixed wave of quads and zombies
	///////////////////////////////////////////////////////
	
	//iprintlnbold("Mixed Zombie Wave...");
	
	level.round_spawn_func = maps\_zombiemode::round_spawning;
	level thread [[level.round_spawn_func]]();
		
	wait(2);	
	
	level notify("quad_round_can_end");
	level.delay_spawners = undefined;
}

manage_zombie_spawn_delay( start_timer )
{
	// quads will start to slowly spawn and then gradually spawn faster
	if(GetTime() - start_timer < 15000 )
	{		
		level.zombie_vars["zombie_spawn_delay"] = RandomInt(30,45);
	}
	else if(GetTime() - start_timer < 25000 )
	{		
		level.zombie_vars["zombie_spawn_delay"] = RandomInt(15,30);
	}
	else if(GetTime() - start_timer < 35000 )
	{		
		level.zombie_vars["zombie_spawn_delay"] = RandomInt(10,15);
	}
	else if(GetTime() - start_timer < 50000 )
	{		
		level.zombie_vars["zombie_spawn_delay"] = RandomInt(5,10);
	}
}

quad_lobby_roof_break()
{
	zone = level.zones[ "foyer_zone" ];

	while ( 1 )
	{
		if ( zone.is_occupied )
		{
			flag_set( "lobby_occupied" );
			break;
		}
		wait_network_frame();
	}

	quad_stage_roof_break_single( 5 );
	wait( .4 );
	quad_stage_roof_break_single( 6 );
	wait( 2 );
	quad_stage_roof_break_single( 7 );
	wait( 1 );
	quad_stage_roof_break_single( 8 );

	maps\_zombiemode_zone_manager::reinit_zone_spawners();
}

quad_dining_roof_break()
{
	trigger = getent( "dining_first_floor", "targetname" );
	trigger waittill( "trigger" );

	flag_set( "dining_occupied" );

	quad_stage_roof_break_single( 9 );
	wait( 1 );
	quad_stage_roof_break_single( 10 );

	maps\_zombiemode_zone_manager::reinit_zone_spawners();
}

quad_stage_roof_break()
{
	level thread play_quad_start_vo();

	quad_stage_roof_break_single( 1 );
	wait( 2 );
	quad_stage_roof_break_single( 3 );
	wait( .33 );
	quad_stage_roof_break_single( 2 );
	wait( 1 );
	quad_stage_roof_break_single( 0 );
	wait( .45 );
	quad_stage_roof_break_single( 4 );

	// stage piece
	wait( .33 );
	quad_stage_roof_break_single( 15 );

	// non quad pieces last
	wait( .4 );
	quad_stage_roof_break_single( 11 );
	wait( .45 );
	quad_stage_roof_break_single( 12 );
	wait( .3 );
	quad_stage_roof_break_single( 13 );
	wait( .35 );
	quad_stage_roof_break_single( 14 );

	maps\_zombiemode_zone_manager::reinit_zone_spawners();
}

quad_stage_roof_break_single( index )
{
	trigger = getent( "quad_roof_crumble_fx_origin_" + index, "target" );
	trigger thread quad_roof_crumble_fx_play();
}

play_quad_start_vo()
{
    wait(3);
    players = getplayers();
    player = players[RandomIntRange(0,players.size)];
    
    player maps\_zombiemode_audio::create_and_play_dialog( "general", "quad_spawn" );
}


