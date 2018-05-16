#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombietron_utility; 
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
main()
{
	init_sounds();
	init_fx();		
	PrecacheModel( "zombie_meteor_chunk_lrg" );
	PrecacheModel( "fxanim_zombies_crow_mod");
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
init_text()
{
	level.fate1_msg 					= NewHudElem( level );
	level.fate1_msg.alignX = "center";
	level.fate1_msg.alignY = "middle";
	level.fate1_msg.horzAlign = "center";
	level.fate1_msg.vertAlign = "middle";
	level.fate1_msg.foreground = true;
	level.fate1_msg.fontScale = 2;
	level.fate1_msg.color = ( 1.0, 0.84, 0.0 );
	level.fate1_msg.alpha = 0;
	level.fate1_msg SetText( &"ZOMBIETRON_FATE_FORTUNE");
	level.fate1_msg.hidewheninmenu = true;
	
	level.fate2_msg 					= NewHudElem( level );
	level.fate2_msg.alignX = "center";
	level.fate2_msg.alignY = "middle";
	level.fate2_msg.horzAlign = "center";
	level.fate2_msg.vertAlign = "middle";
	level.fate2_msg.y += 20;
	level.fate2_msg.foreground = true;
	level.fate2_msg.fontScale = 2;
	level.fate2_msg.color = ( 1.0, 0.84, 0.0 );
	level.fate2_msg.alpha = 0;
	level.fate2_msg SetText( &"ZOMBIETRON_FATE_FIREPOWER");
	level.fate2_msg.hidewheninmenu = true;
	
	level.fate3_msg 					= NewHudElem( level );
	level.fate3_msg.alignX = "center";
	level.fate3_msg.alignY = "middle";
	level.fate3_msg.horzAlign = "center";
	level.fate3_msg.vertAlign = "middle";
	level.fate3_msg.y += 40;
	level.fate3_msg.foreground = true;
	level.fate3_msg.fontScale = 2;
	level.fate3_msg.color = ( 1.0, 0.84, 0.0 );
	level.fate3_msg.alpha = 0;
	level.fate3_msg SetText( &"ZOMBIETRON_FATE_FRIENDSHIP");
	level.fate3_msg.hidewheninmenu = true;
	
	level.fate4_msg 					= NewHudElem( level );
	level.fate4_msg.alignX = "center";
	level.fate4_msg.alignY = "middle";
	level.fate4_msg.horzAlign = "center";
	level.fate4_msg.vertAlign = "middle";
	level.fate4_msg.y += 60;
	level.fate4_msg.foreground = true;
	level.fate4_msg.fontScale = 2;
	level.fate4_msg.color = ( 1.0, 0.84, 0.0 );
	level.fate4_msg.alpha = 0;
	level.fate4_msg SetText( &"ZOMBIETRON_FATE_FURIOUS_FEET");
	level.fate4_msg.hidewheninmenu = true;
	
	level.fate_title1			= NewHudElem( level );
	level.fate_title1.alignX 			= "center";
	level.fate_title1.alignY 			= "middle";
	level.fate_title1.horzAlign 	= "center";
	level.fate_title1.vertAlign 	= "middle";
	level.fate_title1.foreground 	= true;
	level.fate_title1.fontScale 	= 3;
	level.fate_title1.y -= 70;
	level.fate_title1.color 			= ( 1.0, 0.84, 0.0 );
	level.fate_title1.alpha 			= 0;
	level.fate_title1 SetText( &"ZOMBIETRON_FATE_INTRO");
	level.fate_title1.hidewheninmenu = true;
	
	level.fate_title2 						= NewHudElem( level );
	level.fate_title2.alignX 			= "center";
	level.fate_title2.alignY 			= "middle";
	level.fate_title2.horzAlign 	= "center";
	level.fate_title2.vertAlign 	= "middle";
	level.fate_title2.foreground 	= true;
	level.fate_title2.y -= 40;
	level.fate_title2.fontScale 	= 2;
	level.fate_title2.color 			= ( 1.0, 0.84, 0.0 );
	level.fate_title2.alpha 			= 0;
	level.fate_title2 SetText( &"ZOMBIETRON_FATE_INTRO2");
	level.fate_title2.hidewheninmenu = true;
}

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
init_sounds()
{
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
init_fx()
{
	level._effect[ "furious_feet" ]	= LoadFx( "maps/zombie/fx_zombie_dog_lightning_buildup" );
	level._effect[ "fortune" ]			= LoadFx( "maps/zombie/fx_zombie_dog_lightning_buildup" );
	level._effect[ "firepower" ]		= LoadFx( "maps/zombie/fx_zombie_dog_lightning_buildup" );
	level._effect[ "friendship" ]		= LoadFx( "maps/zombie/fx_zombie_dog_lightning_buildup" );
	level._effect[ "rock_glow"]			= loadfx( "maps/zombie/fx_zmbtron_elec_player_trail" );
	
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
time_to_choose_fate()
{
	if (level.round_number < level.zombie_vars["fate_level_min"])
	{
		return false;
	}
	if ( level.fates_have_been_chosen )
	{
		return false;
	}
	if (level.round_number > level.zombie_vars["fate_level_max"])
	{
		return true;
	}
	if ( RandomInt(100) > level.zombie_vars["fate_level_chance"] )
	{
		return false;
	}
	return true;
}
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
choose_fate_round()
{
	//ok lets do it
	init_text();

	//fake out the 'system'
	lastArena = level.current_arena;
	level.current_arena = maps\_zombietron_main::arena_findIndexByName("temple");
	maps\_zombietron_main::move_players_to_start();
	
	maps\_zombietron_scenes::hide_temple_props( "none" );
	
	//set the mood overrides
	if( IsDefined( level.weatherFx ) )
	{
		for( i = 0; i < level.weatherFx.size; i++ )
		{
			level.weatherFx[i] Delete();
		}
	}
	level.weatherFx = [];
	fog = getentarray( "fog_fx", "targetname" );
	for( i = 0; i < fog.size; i++ )
	{
		level.weatherFx[level.weatherFx.size] = SpawnFx( level._effect[ "fog_amb" ], fog[i].origin );
		TriggerFx( level.weatherFx[level.weatherFx.size-1] );
	}	

	VisionSetNaked( "huey_city", 0 );
	dir = "-30 80 0";
	color = ".30 .36 .39"; //purple .27 .25 .93
	light = "3";
	exposure = "0.63";
	players = get_players();
	for (i = 0; i < players.size; i++)
	{
		players[i] setClientDvars( 
			"r_lightTweakSunLight", light,
			"r_lightTweakSunColor", color, 
			"r_lightTweakSunDirection", dir,
			"r_exposureTweak", 1,
			"r_exposureValue", exposure
			);
	}
		
	//initialize triggers
	the_fates[0] = GetEnt("fate_trigger3","targetname");
	the_fates[1] = GetEnt("fate_trigger4","targetname");
	the_fates[2] = GetEnt("fate_trigger1","targetname");
	the_fates[3] = GetEnt("fate_trigger2","targetname");

	the_fates[0] thread fate_of_fortune();
	the_fates[1] thread fate_of_firepower();
	the_fates[2] thread fate_of_friendship();
	the_fates[3] thread fate_of_furious_feet();
	
	array_thread(the_fates, ::trigger_off);
	array_thread(the_fates, maps\_zombietron_fate::spawnRocks);

	//move player to chamber
	players = GetPlayers();
	for (i=0;i<players.size;i++)
	{
		target= "fate_player_spawn" + (i+1);
		moveLoc = GetEnt(target,"targetname");
		
		players[i].oldLocation = players[i].origin;
		players[i].oldAngles = players[i].angles;

		players[i] SetOrigin( moveLoc.origin ); 
		players[i] SetPlayerAngles(moveLoc.angles);
		if ( !isAlive(players[i])  )
		{
			maps\_zombietron_pickups::directed_pickup_award_to(players[i],"extra_life",level.extra_life_model);
		}
	}
	
	playsoundatposition( "zmb_fate_spawn", (0,0,0) );

	maps\_zombietron_pickups::clear_mines();

	//fade up
	fade_in();
	
	//put up Text
	level.fate_title1 FadeOverTime( 2 );
	level.fate_title1.alpha 			= 1;
	wait 1;
	level.fate_title2  FadeOverTime( 2 );
	level.fate_title2.alpha 			= 1;
	wait 3;
	level.fate_title1 FadeOverTime( 1 );
	level.fate_title2 FadeOverTime( 1 );
	level.fate_title1.alpha 			= 0;
	level.fate_title2.alpha 			= 0;
	wait 1;
	
	//level thread maps\createart\zombietron_art::do_lightning_loop();

	
	
	//turn on all the fate triggers
	array_thread(the_fates, ::trigger_on);
	level thread add_objectives(the_fates);

	//wait or time out.	
	timeLeft 	= GetTime() + (level.zombie_vars["fate_wait"]*1000);
	msgUp 		= false;
	diff 			= timeLeft - GetTime();
	while (diff>0)
	{
		if ( diff < 8000  && !msgUp )
		{
			msgUp = true;
			level.fate_title2 SetText( &"ZOMBIETRON_FATE_HURRY");
			level.fate_title2 FadeOverTime( 2 );
			level.fate_title2.alpha = 1;
			wait 3;
			level.fate_title2 FadeOverTime( 2 );
			level.fate_title2.alpha = 0;
			wait 2;
		}
		diff 			= timeLeft - GetTime();
		players 	= GetPlayers();
		allFated 	= true;
		for ( i=0;i<players.size;i++)
		{
			if ( !isDefined(players[i].fate) )
			{
				allFated = false;
				break;
			}
		}
		if (allFated)
		{
			break;
		}
		wait 0.05;
	}	
	
	//all done
	//put up Text
	wait 5;
	level notify("the_fates_have_been_decided");
	
	playsoundatposition( "zmb_fate_decided", (0,0,0) );
	
	level.fate1_msg FadeOverTime( 1 );
	level.fate2_msg FadeOverTime( 1 );
	level.fate3_msg FadeOverTime( 1 );
	level.fate4_msg FadeOverTime( 1 );
	level.fate1_msg.alpha = 0;
	level.fate2_msg.alpha = 0;
	level.fate3_msg.alpha = 0;
	level.fate4_msg.alpha = 0;

	level.fate_title1 SetText( &"ZOMBIETRON_FATE_EXIT");
	level.fate_title1 FadeOverTime( 2 );
	level.fate_title1.alpha = 1;
	wait 5;
	level.fate_title1 FadeOverTime( 1 );
	level.fate_title1.alpha = 0;
	//fade down
	fade_out();
	maps\_zombietron_scenes::hide_temple_props( "none" );

	//cleanup
	DestroyHudElem(level.fate_title1);
	DestroyHudElem(level.fate_title2);
	DestroyHudElem(level.fate1_msg);
	DestroyHudElem(level.fate2_msg);
	DestroyHudElem(level.fate3_msg);
	DestroyHudElem(level.fate4_msg);
	for (i=0;i<the_fates.size;i++)
	{
		if ( isDefined(the_fates[i].rock) )
		{
			the_fates[i].rock Delete();
		}
		the_fates[i] Delete();
	}

	//resume game
	level.fates_have_been_chosen = true;
	level.current_arena	= lastArena;
	players = GetPlayers();
	for (i=0;i<players.size;i++)
	{
		players[i] SetOrigin( players[i].oldLocation ); 
		players[i] SetPlayerAngles(players[i].oldAngles);
	}
}

spawnRocks()
{
	loc = GetEnt(self.target,"targetname");
	self.rock = Spawn( "script_model", loc.origin );
	self.rock SetModel( "zombie_meteor_chunk_lrg" );
	yaw = RandomInt( 360 );
	self.rock.angles = ( 0, yaw, 0 );
	playfxontag (level._effect["rock_glow"], self.rock, "tag_origin");
}

fate_show_msg(fate)
{
	level endon("the_fates_have_been_decided");
	switch(fate)
	{
		case "fortune":
			level.fate1_msg FadeOverTime( 1 );
			level.fate1_msg.alpha = 1;
			wait 8;
			level.fate1_msg FadeOverTime( 1 );
			level.fate1_msg.alpha = 0;
		break;
		case "firepower":
			level.fate2_msg FadeOverTime( 1 );
			level.fate2_msg.alpha = 1;
			wait 8;
			level.fate2_msg FadeOverTime( 1 );
			level.fate2_msg.alpha = 0;
		break;
		case "friendship":
			level.fate3_msg FadeOverTime( 1 );
			level.fate3_msg.alpha = 1;
			wait 8;
			level.fate3_msg FadeOverTime( 1 );
			level.fate3_msg.alpha = 0;
		break;
		case "furious_feet":
			level.fate4_msg FadeOverTime( 1 );
			level.fate4_msg.alpha = 1;
			wait 8;
			level.fate4_msg FadeOverTime( 1 );
			level.fate4_msg.alpha = 0;
		break;
	}
}


directed_fate_to(player,model,modelscale, fate_cb)
{
	player endon ("disconnect");

	assertex(isDefined(player),"valid player not specified");
	assertex(isDefined(model),"valid model not specified");
	if( !isDefined(modelscale))
	{
		modelscale = 1;
	}
	
	
	origin = player.origin + (0,0,800);
	object = Spawn( "script_model", origin );
	yaw = RandomInt( 360 );
	object.angles = ( 0, yaw, 0 );
	object SetModel( model );
	object SetScale(modelscale);
	
	while(1)
	{
		if ( object.origin[2] < player.origin[2] )//wtf
		{
			object.origin = player.origin;
			break;
		}
		modz =(player.origin[0],player.origin[1],object.origin[2]-32);
		object.origin = modz;
		wait 0.05;
	}	
	
	Playfx( level._effect["fate_explode"], object.origin );
	player PlayRumbleOnEntity( "artillery_rumble");
	object Delete();
	player [[fate_cb]]();
}


fortune_fate()
{
	self.fate = "fortune";
	self.fate_fortune = 1;
	
	self maps\_zombietron_score::update_multiplier_bar( level.zombie_vars["max_prize_inc_range"]+1 );//fated players start with 2x so give this guy a tickle
	self maps\_zombietron_score::update_hud();
	
	maps\_zombietron_pickups::spawn_prize_glob();
	maps\_zombietron_pickups::spawn_prize_glob();
	maps\_zombietron_pickups::spawn_prize_glob();
}
fate_of_fortune()
{
	level endon("the_fates_have_been_decided");
	while(1)
	{
		self waittill("trigger",guy);
		if ( isDefined(guy.fate) )
		{
			continue;
		}
		
		guy.fate = "fortune";
		level thread directed_fate_to(guy,"zombietron_ruby",5, ::fortune_fate);
		
		//play some fx
		Playfx( level._effect["fortune"], self.rock.origin );
		//play some audio
		playsoundatposition( "zmb_fate_choose", self.rock.origin );
		//put some text up?
		level thread fate_show_msg("fortune");
		//PlaySoundAtPosition( "zmb_cha_ching", guy.origin + (0,0,650) );
		self.rock Delete();	
		self notify("opened");
		return;
	}
}
firepower_fate()
{
	//upgrade this dudes shit
	self.fate = "firepower";
	self TakeAllWeapons();
	self GiveWeapon( "minigun_zt" );
	self SwitchToWeapon( "minigun_zt" );
	self.default_weap = "minigun_zt";
	self.headshots = 0;  // reset the hack weapon meter
}
fate_of_firepower()
{
	level endon("the_fates_have_been_decided");
	while(1)
	{
		self waittill("trigger",guy);
		if ( isDefined(guy.fate) )
		{
			continue;
		}
		guy.fate = "firepower";
		level thread directed_fate_to(guy,GetWeaponModel( "minigun_zt", 0 ),2, ::firepower_fate);

		//play some fx
		Playfx( level._effect["firepower"], self.rock.origin );
		//play some audio
		playsoundatposition( "zmb_fate_choose", self.rock.origin );
			//put some text up?
		level thread fate_show_msg("firepower");
		self.rock Delete();	
		self notify("opened");
		return;
	}
}
friendship_fate()
{
	self.fate = "friendship";
	self thread maps\_zombietron_pickups::fated_double_shot_update("fxanim_zombies_crow_mod");
}
fate_of_friendship()
{
	level endon("the_fates_have_been_decided");
	while(1)
	{
		self waittill("trigger",guy);
		if ( isDefined(guy.fate) )
		{
			continue;
		}
	
		guy.fate = "friendship";
		level directed_fate_to(guy,"fxanim_zombies_crow_mod",4, ::friendship_fate);
	
		//play some fx
		Playfx( level._effect["friendship"], self.rock.origin );
		//play some audio
		playsoundatposition( "zmb_fate_choose", self.rock.origin );
	
		//put some text up?
		level thread fate_show_msg("friendship");
		self.rock Delete();	
		self notify("opened");
		return;
	}
}
furious_feet_fate()
{
	self.fate = "furious_feet";
	self.default_movespeed = level.zombie_vars["player_speed"];
	self SetMoveSpeedScale( self.default_movespeed );
}
fate_of_furious_feet()
{
	level endon("the_fates_have_been_decided");
	while(1)
	{
		self waittill("trigger",guy);
		if ( isDefined(guy.fate) )
		{
			continue;
		}
	
		guy.fate = "furious_feet";
		level thread directed_fate_to(guy,"zombietron_lightning_bolt",1.75, ::furious_feet_fate);
		wait 1;
		level directed_fate_to(guy,"p_rus_boots",4, ::furious_feet_fate);
		
		// Guy with the boots fate gets more boosters
		if ( guy.boosters < 3 )
		{
			guy.boosters = 3;
			guy maps\_zombietron_score::update_hud();
		}
		
		//play some fx
		Playfx( level._effect["furious_feet"], self.rock.origin );
		//play some audio
		playsoundatposition( "zmb_fate_choose", self.rock.origin );
		//put some text up?
		level thread fate_show_msg("furious_feet");
		self.rock Delete();	
		self notify("opened");
		return;
	}
}

open_cleanup()
{
	self endon("opened");
	level waittill("the_fates_have_been_decided");
	self notify("opened");
}

open_exit( trigger, objective_id )
{
	trigger thread open_cleanup();
	objective_add( objective_id, "active", &"EXIT", trigger.origin );
	objective_set3d( objective_id, true, "default","*" );
	objective_current( objective_id );
	trigger waittill( "opened" );
	objective_delete( objective_id );
	wait 0.1;
}

add_objectives(the_triggers)
{
	for( i = 0; i < the_triggers.size; i++ )
	{
		level thread open_exit( the_triggers[i], i );
		PlaySoundAtPosition( "zmb_exit_open", the_triggers[i].origin );
		wait .2;
	}
}
	
