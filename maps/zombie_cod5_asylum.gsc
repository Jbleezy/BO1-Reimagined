#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;
#include maps\_music;
//#include maps\_anim;


#using_animtree("generic_human");

main()
{
	maps\zombie_cod5_asylum_fx::main();

	// viewmodel arms for the level
	//PreCacheModel( "viewmodel_usa_pow_arms" ); // Dempsey
	//PreCacheModel( "viewmodel_rus_prisoner_arms" ); // Nikolai
	//PreCacheModel( "viewmodel_vtn_nva_standard_arms" );// Takeo
	//PreCacheModel( "viewmodel_usa_hazmat_arms" );// Richtofen
	PreCacheModel( "t4_viewhands_usa_marine" );

	// DCS: not mature settings models without blood or gore.
	PreCacheModel( "zombie_asylum_chair_nogore" );
	PreCacheModel( "zombie_power_lever_handle" );

	level thread maps\_callbacksetup::SetupCallbacks();

	level.dogs_enabled = false;

	level.zones = [];

//	maps\_waw_destructible_opel_blitz::init_blitz();
	precacheshellshock("electrocution");

	level.door_dialog_function = maps\_zombiemode::play_door_dialog;
	level.custom_zombie_vox = ::setup_custom_vox;
	//level.exit_level_func = ::asylum_exit_level;

	precachemodel("tag_origin");
	precachemodel("zombie_zapper_power_box");
	precachemodel("zombie_zapper_power_box_on");
	precachemodel("zombie_zapper_cagelight_red");
	precachemodel("zombie_zapper_cagelight_green");
	precachemodel("lights_tinhatlamp_off");
	precachemodel("lights_tinhatlamp_on");
	precachemodel("lights_indlight_on");
	precachemodel("lights_indlight");

	level.valve_hint_north = (&"WAW_ZOMBIE_BUTTON_NORTH_FLAMES");
	level.valve_hint_south = (&"WAW_ZOMBIE_BUTTON_NORTH_FLAMES");

	precachestring(level.valve_hint_north);
	precachestring(level.valve_hint_south);
	precachestring(&"WAW_ZOMBIE_BETTY_ALREADY_PURCHASED");
	precachestring(&"WAW_ZOMBIE_BETTY_HOWTO");
	precachestring(&"WAW_ZOMBIE_FLAMES_UNAVAILABLE");
	precachestring(&"WAW_ZOMBIE_USE_AUTO_TURRET");
	precachestring(&"ZOMBIE_ELECTRIC_SWITCH");
	precachestring(&"WAW_ZOMBIE_INTRO_ASYLUM_LEVEL_BERLIN");
	precachestring(&"WAW_ZOMBIE_INTRO_ASYLUM_LEVEL_HIMMLER");
	precachestring(&"WAW_ZOMBIE_INTRO_ASYLUM_LEVEL_SEPTEMBER");

	PrecacheString(&"ZOMBIE_BUTTON_BUY_TRAP");
	PrecacheString(&"REIMAGINED_TRAP_ACTIVE");
	PrecacheString(&"REIMAGINED_TRAP_COOLDOWN");

	include_weapons();
	include_powerups();

	if(getdvar("light_mode") != "")
	{
		return;
	}

	level._effect["zombie_grain"]			= LoadFx( "misc/fx_zombie_grain_cloud" );

	maps\_waw_zombiemode_radio::init();

	level.Player_Spawn_func = ::spawn_point_override;
	level.zombiemode_precache_player_model_override = ::precache_player_model_override;
	level.zombiemode_give_player_model_override = ::give_player_model_override;
	level.zombiemode_player_set_viewmodel_override = ::player_set_viewmodel_override;
	level.register_offhand_weapons_for_level_defaults_override = ::register_offhand_weapons_for_level_defaults_override;

	level.use_zombie_heroes = true;

	override_blocker_prices();
	override_box_locations();

	//init the perk machines
	maps\_zombiemode::main();

	level.zone_manager_init_func = ::asylum_zone_init;
	init_zones[0] = "west_downstairs_zone";
	init_zones[1] = "west2_downstairs_zone";
	level thread maps\_zombiemode_zone_manager::manage_zones( init_zones );

	// eschmidt: _waw_zombiemode sets level.flag
	//level thread maps\zombie_cod5_asylum_fx::chair_light();

	level.burning_zombies = [];
	level.electrocuted_zombies = [];

	init_sounds();

	//the electric switch in the control room
	level thread master_electric_switch();

//	thread maps\_zombiemode_audio::level_start_vox("level", "power");

	//zombie asylum custom stuff
	init_zombie_asylum();

	//level thread intro_screen();
	//level thread debug_health();
	level thread toilet_useage();
	level thread chair_useage();
	level thread magic_box_light();
	level thread mature_settings_changes();

	//DCS: get betties working.
	maps\_zombiemode_betty::init();

	// If you want to modify/add to the weapons table, please copy over the _zombiemode_weapons init_weapons() and paste it here.
	// I recommend putting it in it's own function...
	// If not a MOD, you may need to provide new localized strings to reflect the proper cost.

	// Set the color vision set back
	level.zombie_visionset = "zombie_asylum";

	maps\createart\zombie_cod5_asylum_art::main();

	level.has_pack_a_punch = false;

	level thread fix_zombie_pathing();

	// added for zombie speed buff
	level.scr_anim["zombie"]["sprint5"] = %ai_zombie_fast_sprint_01;
	level.scr_anim["zombie"]["sprint6"] = %ai_zombie_fast_sprint_02;
}

//*****************************************************************************
// ZONE INIT
//*****************************************************************************
asylum_zone_init()
{
	flag_init( "always_on" );
	flag_set( "always_on" );

	zone_volume = Spawn( "trigger_radius", (-2, -648, 252), 0, 64, 64 );
	zone_volume.targetname = "south_upstairs_zone";
	zone_volume.script_noteworthy = "player_volume";

	add_adjacent_zone( "west_downstairs_zone", "west2_downstairs_zone", "power_on" );

	//path north to power
	add_adjacent_zone( "west2_downstairs_zone", "north_downstairs_zone", "north_door1" );
	add_adjacent_zone( "north_downstairs_zone", "north_upstairs_zone", "north_upstairs_blocker" );
	add_adjacent_zone( "north_upstairs_zone", "north2_upstairs_zone", "upstairs_north_door1" );
	add_adjacent_zone( "north2_upstairs_zone", "kitchen_upstairs_zone", "upstairs_north_door2" );
	add_adjacent_zone( "kitchen_upstairs_zone", "power_upstairs_zone", "magic_box_north" );


	// path south to power
	add_adjacent_zone( "west_downstairs_zone", "south_upstairs_zone", "south_upstairs_blocker" );
	add_adjacent_zone( "south_upstairs_zone", "south2_upstairs_zone", "south_access_1" );
	add_adjacent_zone( "south2_upstairs_zone", "power_upstairs_zone", "magic_box_south" );

}

precache_player_model_override()
{
	mptype\player_t4_zm_asylum::precache();
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
			character\c_usa_marine1_dlc5::main();// Dempsey
			break;
		case 1:
			character\c_usa_marine2_dlc5::main();// John
			break;
		case 2:
			character\c_usa_marine3_dlc5::main();// Smokey
			break;
		case 3:
			character\c_usa_marine4_dlc5::main();// Marine4
			break;	
	}
}

player_set_viewmodel_override( entity_num )
{
	switch( self.entity_num )
	{
		case 0:
			// Dempsey
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;
		case 1:
			// Nikolai
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;
		case 2:
			// Takeo
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;
		case 3:
			// Richtofen
			self SetViewModel( "t4_viewhands_usa_marine" );
			break;		
	}
}

register_offhand_weapons_for_level_defaults_override()
{
	register_lethal_grenade_for_level( "stielhandgranate" );
	level.zombie_lethal_grenade_player_init = "stielhandgranate";

	register_tactical_grenade_for_level( "molotov_zm" );
	level.zombie_tactical_grenade_player_init = undefined;

	register_placeable_mine_for_level( "mine_bouncing_betty" );
	level.zombie_placeable_mine_player_init = undefined;

	register_melee_weapon_for_level( "knife_zm" );
	level.zombie_melee_weapon_player_init = "knife_zm";
}

player_zombie_awareness()
{
	self endon("disconnect");
	self endon("death");

	while(1)
	{
		wait(1);

		zombie = get_closest_ai(self.origin,"axis");

		if(!isDefined(zombie) || !isDefined(zombie.zombie_move_speed) )
		{
			continue;
		}

		dist = 200;

		switch(zombie.zombie_move_speed)
		{
			case "walk": dist = 200;break;
			case "run": dist = 250; break;
			case "sprint": dist = 275;break;
		}

		if(distance2d(zombie.origin,self.origin) < dist)
		{
			yaw = self animscripts\zombie_utility::GetYawToSpot(zombie.origin );

			//check to see if he's actually behind the player
			if(yaw < -95 || yaw > 95)
			{
				zombie playsound ("behind_vocals");
			}
		}
	}
}

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


	level.intro_hud[0] settext(&"WAW_ZOMBIE_INTRO_ASYLUM_LEVEL_BERLIN");
	level.intro_hud[1] settext(&"WAW_ZOMBIE_INTRO_ASYLUM_LEVEL_HIMMLER");
	level.intro_hud[2] settext(&"WAW_ZOMBIE_INTRO_ASYLUM_LEVEL_SEPTEMBER");

	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] FadeOverTime( 1.5 );
		level.intro_hud[i].alpha = 1;
		wait(1.5);


	}
	wait(1.5);
	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] FadeOverTime( 1.5 );
		level.intro_hud[i].alpha = 0;
		wait(1.5);


	}
	for(i = 0 ; i < 3; i++)
	{
		level.intro_hud[i] destroy();

	}


	level thread magic_box_limit_location_init();

}

/* Moved sound to the loudspeaker */
play_pa_system()
{
	clientnotify("switch_flipped_generator");
	speakerA = getstruct("loudspeaker", "targetname");
	playsoundatposition("alarm", speakerA.origin);

	level thread play_comp_sounds();

	generator_arc = getent("generator_arc", "targetname");
	generator_arc playloopsound("gen_arc_loop");

	wait(4.0);
	generator = getent("generator_origin", "targetname");
	generator playloopsound("generator_loop");


	wait(8.0);
	playsoundatposition ("amb_pa_system", speakerA.origin);

}
play_comp_sounds()
{
	computer = getent("comp", "targetname");
	computer playsound ("comp_start");
	wait(6);
	computer playloopsound("comp_loop");
}

/*------------------------------------
Zombie Asylum special sauce
------------------------------------*/
init_zombie_asylum()
{
	level.magic_box_uses = 1;

	//flags
	flag_init("both_doors_opened");			//keeps track of the players opening the 'magic box' room doors
	flag_init("electric_switch_used");	//when the players use the electric switch in the control room

	flag_set("spawn_point_override");

	//electric traps
	level thread init_elec_trap_trigs();

	level thread init_lights();

	//water sheeting triggers
	water_trigs = getentarray("waterfall","targetname");
	array_thread(water_trigs,::watersheet_on_trigger);
}

init_lights()
{

	tinhats = [];
	arms = [];

	ents = getentarray("elect_light_model","targetname");
	for(i=0;i<ents.size;i++)
	{
		if( issubstr(ents[i].model, "tinhat"))
		{
			tinhats[tinhats.size] = ents[i];
		}
		if(issubstr(ents[i].model,"indlight"))
		{
			arms[arms.size] = ents[i];
		}
	}

	for(i = 0;i<tinhats.size;i++)
	{
		wait_network_frame();
		tinhats[i] setmodel("lights_tinhatlamp_off");
	}
	for(i = 0;i<arms.size;i++)
	{
		wait_network_frame();
		arms[i] setmodel("lights_indlight");
	}

	flag_wait("electric_switch_used");

	for(i = 0;i<tinhats.size;i++)
	{
		wait_network_frame();
		tinhats[i] setmodel("lights_tinhatlamp_on");
	}
	for(i = 0;i<arms.size;i++)
	{
		wait_network_frame();
		arms[i] setmodel("lights_indlight_on");
	}

	//shut off magic box light
	//open_light = getent("opened_chest_light", "script_noteworthy");
	//hallway_light = getent("magic_box_hallway_light", "script_noteworthy");

	//open_light setLightIntensity(0.01);
	//hallway_light setLightIntensity(0.01);


	//open_light_model = getent("opened_chest_model", "script_noteworthy");
	//hallway_light_model = getent("magic_box_hallway_model", "script_noteworthy");

	//open_light_model setmodel("lights_tinhatlamp_off");
	//hallway_light_model setmodel("lights_tinhatlamp_off");


}
//-------------------------------------------------------------------------------
init_sounds()
{
	maps\_zombiemode_utility::add_sound( "break_stone", "break_stone" );
	maps\_zombiemode_utility::add_sound( "zmb_couch_slam", "couch_slam" );

	// override the default slide with the buzz slide
	maps\_zombiemode_utility::add_sound("door_slide_open", "door_slide_open");

}

//-------------------------------------------------------------------------------
// Include the weapons that are only inr your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
//-------------------------------------------------------------------------------
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
	include_weapon( "ray_gun_zm" );
	include_weapon("crossbow_explosive_zm");
	include_weapon("knife_ballistic_zm");

	// Bolt Action
	include_weapon( "zombie_springfield", false, true );
	include_weapon( "zombie_kar98k", false, true );
	include_weapon( "stielhandgranate", false, true );
	include_weapon( "zombie_gewehr43", false, true );
	include_weapon( "zombie_m1garand", false, true );
	include_weapon( "zombie_thompson", false, true );
	include_weapon( "zombie_shotgun", false, true );
	include_weapon( "mp40_zm", false, true );
	include_weapon( "zombie_bar_bipod", false, true );
	include_weapon( "zombie_stg44", false, true );
	include_weapon( "zombie_doublebarrel", false, true );
	include_weapon( "zombie_doublebarrel_sawed", false, true );
	include_weapon( "zombie_bar", false, true );

	include_weapon( "zombie_cymbal_monkey");

	// Special
	include_weapon( "freezegun_zm" );
	include_weapon( "m1911_upgraded_zm", false );

	//bouncing betties
	include_weapon("mine_bouncing_betty", false, true);

	// limited weapons
	maps\_zombiemode_weapons::add_limited_weapon( "m1911_zm", 0 );
	maps\_zombiemode_weapons::add_limited_weapon( "freezegun_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "crossbow_explosive_zm", 1 );
	maps\_zombiemode_weapons::add_limited_weapon( "knife_ballistic_zm", 1 );

	level._uses_retrievable_ballisitic_knives = true;

	precacheItem( "explosive_bolt_zm" );
	precacheItem( "explosive_bolt_upgraded_zm" );

	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_springfield", "", 						&"WAW_ZOMBIE_WEAPON_SPRINGFIELD_200", 			200,	"rifle");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_kar98k", "zombie_kar98k_upgraded", 	&"WAW_ZOMBIE_WEAPON_KAR98K_200", 				200,	"rifle");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_type99_rifle", "",						&"WAW_ZOMBIE_WEAPON_TYPE99_200", 			    200,	"rifle" );

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
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_doublebarrel_sawed", "", 			    &"REIMAGINED_WEAPON_DOUBLEBARREL_SAWED", 	1200, "shotgun");
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_shotgun", "zombie_shotgun_upgraded",							&"WAW_ZOMBIE_WEAPON_SHOTGUN_1500", 				1500, "shotgun");

	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_bar", "zombie_bar_upgraded", 						&"WAW_ZOMBIE_WEAPON_BAR_1800", 					1800,	"mg" );

	// Bipods
	maps\_zombiemode_weapons::add_zombie_weapon( "zombie_bar_bipod", 	"",					&"WAW_ZOMBIE_WEAPON_BAR_BIPOD_2500", 			2500,	"mg" );
}

//-------------------------------------------------------------------------------
include_powerups()
{
	include_powerup( "nuke" );
	include_powerup( "insta_kill" );
	include_powerup( "double_points" );
	include_powerup( "full_ammo" );
	include_powerup( "carpenter" );
}

/*------------------------------------
	FIRE TRAPS

- players can activate
	gas valves that enable a wall of fire for a few seconds

	NOT!
	it's been changed to electricity

	need to update the relevant function names/variables and such to reflect the change
------------------------------------*/
init_elec_trap_trigs()
{
	trap_trigs = getentarray("gas_access","targetname");

	array_thread (trap_trigs,::electric_trap_think);
	array_thread (trap_trigs,::electric_trap_dialog);
}

toilet_useage()
{
	toilet_counter = 0;
	toilet_trig = getent("toilet", "targetname");
	toilet_trig SetCursorHint( "HINT_NOICON" );
	toilet_trig UseTriggerRequireLookAt();

	players = getplayers();
	if(!IsDefined (level.music_override))
	{
		level.music_override = false;
	}
	while(1)
	{
		//wait(0.5);

		toilet_trig waittill("trigger");
		toilet_trig playsound("toilet_flush", "sound_done");
		toilet_trig waittill("sound_done");

		toilet_counter++;

		if(toilet_counter == 3 && level.gamemode == "survival")
		{
			toilet_counter = 0;
			//playsoundatposition ("zmb_cha_ching", toilet_trig.origin);
			play_music_easter_egg();
		}
	}

}

//-------------------------------------------------------------------------------
play_music_easter_egg(player)
{
	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "egg" );

	wait(245);

	level.music_override = false;
	level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );
}

//-------------------------------------------------------------------------------
chair_useage()
{
	wait(2);
	chair_counter = 0;
	chair_trig = getent("dentist_chair", "targetname");
	chair_trig SetCursorHint( "HINT_NOICON" );
	chair_trig UseTriggerRequireLookAt();

	//players = getplayers();
	while (1)
	{
		chair_trig waittill("trigger");
		playsoundatposition ("chair", chair_trig.origin);
		wait 30;
	}

}

//-------------------------------------------------------------------------------
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

				//players[i] thread do_player_vo("vox_start", 5);
				wait(3);
				self notify("warning_dialog");
				//iprintlnbold("warning_given");
			}
		}
	}
}


hint_string( string )
{
	self SetHintString( string );
	self SetCursorHint( "HINT_NOICON" );
}


/*------------------------------------
self = use trigger associated with the gas valve
------------------------------------*/
electric_trap_think()
{
	self.is_available = undefined;
	self.zombie_cost = 1000;
	self.in_use = 0;

	self sethintstring( &"ZOMBIE_NEED_POWER" );
	self SetCursorHint( "HINT_NOICON" );
	flag_wait( "power_on" );

	//triggers = getentarray(self.script_noteworthy ,"script_noteworthy");

	while(1)
	{

		self sethintstring( &"ZOMBIE_BUTTON_BUY_TRAP", self.zombie_cost );

		//array_thread(triggers, ::hint_string, &"WAW_ZOMBIE_ACTIVATE_TRAP" );

		//wait until someone uses the valve
		self waittill("trigger",who);
		if( who in_revive_trigger() )
		{
			continue;
		}

		if(!isDefined(self.is_available))
		{
			continue;
		}

		if( is_player_valid( who ) )
		{
			if( who.score >= self.zombie_cost )
			{
				if(!self.in_use)
				{
					self.in_use = 1;
					play_sound_at_pos( "purchase", who.origin );
					self sethintstring( &"REIMAGINED_TRAP_ACTIVE" );
					self thread electric_trap_move_switch(self);
					
					//set the score
					who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );

					//need to play a 'woosh' sound here, like a gas furnace starting up
					self waittill("switch_activated");

					//turn off the valve triggers associated with this valve until the gas is available again
					//array_thread (valve_trigs,::trigger_off);
					//array_thread(triggers, ::hint_string, &"ZOMBIE_TRAP_ACTIVE" );


					//this trigger detects zombies walking thru the flames
					self.zombie_dmg_trig = getent(self.target,"targetname");
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


					//turn the damage detection trigger off until the flames are used again
			 		self.zombie_dmg_trig trigger_off();
					//array_thread(triggers, ::hint_string, &"ZOMBIE_TRAP_COOLDOWN" );
					self sethintstring( &"REIMAGINED_TRAP_COOLDOWN" );

					wait(25);

					//Play the 'alarm' sound to alert players that the traps are available again (playing on a temp ent in case the PA is already in use.
					speakerA = getstruct("loudspeaker", "targetname");
					playsoundatposition("warning", speakera.origin);
					self notify("available");

					self.in_use = 0;
				}
			}
		}
	}
}

//-------------------------------------------------------------------------------
//	this used to be a gas valve, now it's a throw switch
//-------------------------------------------------------------------------------
electric_trap_move_switch(parent)
{
	tswitch = getent(parent.script_linkto,"script_linkname");
	if(tswitch.script_linkname == "4")
	{
		//turn the light above the door red
		north_zapper_light_red();
		//machine = getent("zap_machine_north","targetname");

		extra_time = tswitch maps\_zombiemode_traps::move_trap_handle(180, 180, true);

		tswitch playsound("amb_sparks_l_b");
		tswitch waittill("rotatedone");

		if(extra_time > 0)
		{
			wait(extra_time);
		}

		self notify("switch_activated");
		self waittill("available");

		tswitch rotatepitch(180,.5);

		//turn the light back green once the trap is available again
		north_zapper_light_green();

		tswitch waittill("rotatedone");
	}
	else
	{
		south_zapper_light_red();

		extra_time = tswitch thread maps\_zombiemode_traps::move_trap_handle(180);

		tswitch playsound("amb_sparks_l_b");
		tswitch waittill("rotatedone");

		if(extra_time > 0)
		{
			wait(extra_time);
		}

		self notify("switch_activated");
		self waittill("available");

		tswitch rotatepitch(-180,.5);

		south_zapper_light_green();

		tswitch waittill("rotatedone");
	}
}

activate_electric_trap(who)
{
	//the trap on the north side is kinda busted, so it has a sparky wire.
	if(isDefined(self.script_string) && self.script_string == "north")
	{

		machine = getent("zap_machine_north","targetname");
		machine setmodel("zombie_zapper_power_box_on");
		clientnotify("north");
	}
	else
	{

		machine = getent("zap_machine_south","targetname");
		machine setmodel("zombie_zapper_power_box_on");
		clientnotify("south");
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
	machine setmodel("zombie_zapper_power_box");
}


electric_trap_fx(notify_ent)
{
	self.tag_origin = spawn("script_model",self.origin);
	//self.tag_origin setmodel("tag_origin");

	//playfxontag(level._effect["zapper"],self.tag_origin,"tag_origin");

	if(isDefined(self.script_sound))
	{
		self.tag_origin playsound("zmb_elec_start");
		self.tag_origin playloopsound("zmb_elec_loop");
		self thread play_electrical_sound();
	}
	wait(25);

	if(isDefined(self.script_sound))
	{
		self.tag_origin stoploopsound();
	}
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

		//player is standing flames, dumbass
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
		self playsound("zmb_ignite");
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
		if(randomint(100) > 40 )
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
}

zombie_flame_watch()
{
	self waittill("death");
	self stoploopsound();
	level.burning_zombies = array_remove_nokeys(level.burning_zombies,self);
}


/*------------------------------------
	SPAWN POINT OVERRIDE

- special asylum spawning hotness
------------------------------------*/
spawn_point_override()
{
	// eschmidt: changed so we're guaranteed that the zombiemode spawn function goes first
	flag_wait( "all_players_connected" );

	players = get_players();

	//spawn points are split, so grab them both seperately
	north_structs = getstructarray("north_spawn","script_noteworthy");
	south_structs = getstructarray("south_spawn","script_noteworthy");

	side1 = north_structs;
	side2 = south_structs;
	if(GetDvar("asylum_start_room") == "random" || level.gamemode != "survival")
	{
		if(RandomIntRange(0, 2) == 0)
		{
			side1 = south_structs;
			side2 = north_structs;
		}
	}
	else if(GetDvar("asylum_start_room") == "jug")
	{
		side1 = south_structs;
		side2 = north_structs;
	}

	//spawn players on a specific side, but randomize it up a bit
	for( i = 0; i < players.size; i++ )
	{

		if(i<2)
		{
			players[i] setorigin( side1[i].origin );
			players[i] setplayerangles( side1[i].angles );
			players[i].respawn_point = side1[i];
			players[i].spawn_side = side1[i].script_noteworthy;
			players[i].spectator_respawn = side1[i];
		}
		else
		{
			players[i] setorigin( side2[i].origin);
			players[i] setplayerangles( side2[i].angles);
			players[i].respawn_point = side2[i];
			players[i].spawn_side = side2[i].script_noteworthy;
			players[i].spectator_respawn = side2[i];
		}
	}
}

disable_bump_trigger(triggername)
{
	triggers = GetEntArray( "audio_bump_trigger", "targetname");
	if(IsDefined (triggers))
	{
		for(i=0;i<triggers.size;i++)
		{
			if (IsDefined (triggers[i].script_label) && triggers[i].script_label == triggername)
			{
				triggers[i].script_activated =0;
			}

		}
	}

}


//-------------------------------------------------------------------------------
//	the electric switch in the control room
//	once this is used, it activates other objects in the map
//	and makes them available to use
//-------------------------------------------------------------------------------
master_electric_switch()
{

	trig = getent("use_master_switch","targetname");
	master_switch = getent("master_switch","targetname");
	master_switch notsolid();
	//master_switch rotatepitch(90,1);
	trig sethintstring(&"ZOMBIE_ELECTRIC_SWITCH");
	trig SetCursorHint( "HINT_NOICON" );

	//turn off the buyable door triggers downstairs
	fx_org = spawn("script_model", (-674.922, -300.473, 284.125));
	fx_org setmodel("tag_origin");
	fx_org.angles = (0, 90, 0);
	playfxontag(level._effect["electric_power_gen_idle"], fx_org, "tag_origin");



	cheat = false;

/#
	if( GetDvarInt( "zombie_cheat" ) >= 3 )
	{
		wait( 5 );
		cheat = true;
	}
#/

	if ( cheat != true )
	{
		trig waittill("trigger",user);
	}

	trig delete();

	master_switch rotateroll(-90,.3);

	//TO DO (TUEY) - kick off a 'switch' on client script here that operates similiarly to Berlin2 subway.
	master_switch playsound("zmb_switch_flip");

	//level thread electric_current_open_middle_door();
	//level thread electric_current_revive_machine();
	//level thread electric_current_reload_machine();
	//level thread electric_current_doubletap_machine();
	//level thread electric_current_juggernog_machine();


	flag_set("power_on");
	//clientnotify("revive_on");
	//clientnotify("middle_door_open");
	//clientnotify("fast_reload_on");
	//clientnotify("doubletap_on");
	//clientnotify("jugger_on");

	clientnotify("ZPO");	 // Zombie Power On.


	level notify("switch_flipped");
	disable_bump_trigger("switch_door_trig");
	level thread play_the_numbers();
	left_org = getent("audio_swtch_left", "targetname");
	right_org = getent("audio_swtch_right", "targetname");
	left_org_b = getent("audio_swtch_b_left", "targetname");
	right_org_b = getent("audio_swtch_b_right", "targetname");

	if( isdefined (left_org))
	{
		left_org playsound("amb_sparks_l");
	}
	if( isdefined (left_org_b))
	{
		left_org playsound("amb_sparks_l_b");
	}
	if( isdefined (right_org))
	{
		right_org playsound("amb_sparks_r");
	}
	if( isdefined (right_org_b))
	{
		right_org playsound("amb_sparks_r_b");
	}
	// TUEY - Sets the "ON" state for all electrical systems via client scripts
	SetClientSysState("levelNotify","start_lights");
	level thread play_pa_system();

	flag_set("electric_switch_used");

	//enable the electric traps
	traps = getentarray("gas_access","targetname");
	for(i=0;i<traps.size;i++)
	{
		//traps[i] sethintstring(&"WAW_ZOMBIE_BUTTON_NORTH_FLAMES");
		//traps[i] SetCursorHint( "HINT_NOICON" );

		traps[i].is_available = true;
	}

	master_switch waittill("rotatedone");
	playfx(level._effect["switch_sparks"] ,getstruct("switch_fx","targetname").origin);

	//activate perks-a-cola
	level notify( "master_switch_activated" );
	fx_org delete();

	fx_org = spawn("script_model", (-675.021, -300.906, 283.724));
	fx_org setmodel("tag_origin");
	fx_org.angles = (0, 90, 0);
	playfxontag(level._effect["electric_power_gen_on"], fx_org, "tag_origin");
	fx_org playloopsound("zmb_elec_current_loop");

	//elec room fx on
	//playfx(level._effect["elec_room_on"], (-440, -208, 8));

	//turn on green lights above the zapper trap doors
	level thread north_zapper_light_green();
	level thread south_zapper_light_green();

	//speed up zombies that should be sped up
	zombs = GetAiSpeciesArray("axis");
	for(i=0;i<zombs.size;i++)
	{
		if(!zombs[i] maps\_zombiemode_weap_freezegun::enemy_damaged_by_freezegun())
		{
			zombs[i] maps\_zombiemode_spawner::set_zombie_run_cycle();
		}
	}

	level notify ("sleight_on");
	level notify ("revive_on");
	level notify ("doubletap_on");
	level notify ("juggernog_on");

	wait(6);
	fx_org stoploopsound();

	exploder(101);
	//exploder(201);

	//This wait is to time out the SFX properly
	wait(8);
	playsoundatposition ("amb_sparks_l_end", left_org.origin);
	playsoundatposition ("amb_sparks_r_end", right_org.origin);

}

/*------------------------------------
electrical current FX once the traps are activated on the north side
------------------------------------*/
electric_trap_wire_sparks(side)
{
	self endon("elec_done");

	while(1)
	{
		sparks = getstruct("trap_wire_sparks_"+ side,"targetname");
		self.fx_org = spawn("script_model",sparks.origin);
		self.fx_org setmodel("tag_origin");
		self.fx_org.angles = sparks.angles;
		playfxontag(level._effect["electric_current"],self.fx_org,"tag_origin");

		targ = getstruct(sparks.target,"targetname");
		while(isDefined(targ))
		{
			self.fx_org moveto(targ.origin,.15);


		// Kevin adding playloop on electrical fx
			self.fx_org playloopsound("zmb_elec_current_loop",.1);
			self.fx_org waittill("movedone");
			self.fx_org stoploopsound(.1);

			if(isDefined(targ.target))
			{
				targ = getstruct(targ.target,"targetname");
			}
			else
			{
				targ = undefined;
			}
		}
		playfxontag(level._effect["electric_short_oneshot"],self.fx_org,"tag_origin");
		wait(randomintrange(3,9));
		self.fx_org delete();
	}
}

//electric current to open the middle door
electric_current_open_middle_door()
{

		sparks = getstruct("electric_middle_door","targetname");
		fx_org = spawn("script_model",sparks.origin);
		fx_org setmodel("tag_origin");
		fx_org.angles = sparks.angles;
		playfxontag(level._effect["electric_current"], fx_org,"tag_origin");

		targ = getstruct(sparks.target,"targetname");
		while(isDefined(targ))
		{
			fx_org moveto(targ.origin,.075);
			//Kevin adding playloop on electrical fx
			if(isdefined(targ.script_noteworthy) && (targ.script_noteworthy == "junction_boxs" || targ.script_noteworthy == "electric_end"))
			{
				playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
			}

			fx_org playloopsound("zmb_elec_current_loop",.1);
			fx_org waittill("movedone");
			fx_org stoploopsound(.1);
			if(isDefined(targ.target))
			{
				targ = getstruct(targ.target,"targetname");
			}
			else
			{
				targ = undefined;
			}
		}
		level notify ("electric_on_middle_door");
		playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
		wait(randomintrange(3,9));
		fx_org delete();



}

electric_current_revive_machine()
{

		sparks = getstruct("revive_electric_wire","targetname");
		fx_org = spawn("script_model",sparks.origin);
		fx_org setmodel("tag_origin");
		fx_org.angles = sparks.angles;
		playfxontag(level._effect["electric_current"], fx_org,"tag_origin");

		targ = getstruct(sparks.target,"targetname");
		wait(0.2);
		while(isDefined(targ))
		{
			fx_org moveto(targ.origin,.075);
			//Kevin adding playloop on electrical fx
			if(isdefined(targ.script_noteworthy) && targ.script_noteworthy == "junction_revive")
			{
				playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
			}

			fx_org playloopsound("zmb_elec_current_loop",.1);
			fx_org waittill("movedone");
			fx_org stoploopsound(.1);
			if(isDefined(targ.target))
			{
				targ = getstruct(targ.target,"targetname");
			}
			else
			{
				targ = undefined;
			}
		}
		level notify("revive_on");
		playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
		wait(randomintrange(3,9));
		fx_org delete();



}

electric_current_reload_machine()
{

		sparks = getstruct("electric_fast_reload","targetname");
		fx_org = spawn("script_model",sparks.origin);
		fx_org setmodel("tag_origin");
		fx_org.angles = sparks.angles;
		playfxontag(level._effect["electric_current"], fx_org,"tag_origin");

		targ = getstruct(sparks.target,"targetname");
		while(isDefined(targ))
		{
			fx_org moveto(targ.origin,.075);
			//Kevin adding playloop on electrical fx
			if(isdefined(targ.script_noteworthy) && targ.script_noteworthy == "reload_junction")
			{
				playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
			}

			fx_org playloopsound("zmb_elec_current_loop",.1);
			fx_org waittill("movedone");
			fx_org stoploopsound(.1);
			if(isDefined(targ.target))
			{
				targ = getstruct(targ.target,"targetname");
			}
			else
			{
				targ = undefined;
			}
		}
		level notify ("sleight_on");
		playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
		wait(randomintrange(3,9));
		fx_org delete();



}
electric_current_doubletap_machine()
{

		sparks = getstruct("electric_double_tap","targetname");
		fx_org = spawn("script_model",sparks.origin);
		fx_org setmodel("tag_origin");
		fx_org.angles = sparks.angles;
		playfxontag(level._effect["electric_current"], fx_org,"tag_origin");

		targ = getstruct(sparks.target,"targetname");
		while(isDefined(targ))
		{
			fx_org moveto(targ.origin,.075);
			//Kevin adding playloop on electrical fx
			if(isdefined(targ.script_noteworthy) && targ.script_noteworthy == "double_tap_junction")
			{
				playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
			}

			fx_org playloopsound("zmb_elec_current_loop",.1);
			fx_org waittill("movedone");
			fx_org stoploopsound(.1);
			if(isDefined(targ.target))
			{
				targ = getstruct(targ.target,"targetname");
			}
			else
			{
				targ = undefined;
			}
		}
		level notify ("doubletap_on");
		playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
		wait(randomintrange(3,9));
		fx_org delete();



}
electric_current_juggernog_machine()
{

		sparks = getstruct("electric_juggernog","targetname");
		fx_org = spawn("script_model",sparks.origin);
		fx_org setmodel("tag_origin");
		fx_org.angles = sparks.angles;
		playfxontag(level._effect["electric_current"], fx_org,"tag_origin");

		targ = getstruct(sparks.target,"targetname");
		while(isDefined(targ))
		{
			fx_org moveto(targ.origin,.075);
			//Kevin adding playloop on electrical fx

			fx_org playloopsound("zmb_elec_current_loop",.1);
			fx_org waittill("movedone");
			fx_org stoploopsound(.1);
			if(isDefined(targ.target))
			{
				targ = getstruct(targ.target,"targetname");
			}
			else
			{
				targ = undefined;
			}
		}
		level notify ("juggernog_on");
		playfxontag(level._effect["electric_short_oneshot"], fx_org,"tag_origin");
		wait(randomintrange(3,9));
		fx_org delete();



}

north_zapper_light_red()
{
	zapper_lights = getentarray("zapper_light_north","targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_red");
	}

	if(isDefined(level.north_light))
	{
		level.north_light delete();
	}

	level.north_light = spawn("script_model",(366, 476 ,329));
	level.north_light setmodel("tag_origin");
	level.north_light.angles = (0,270,0);
	playfxontag(level._effect["zapper_light_notready"],level.north_light,"tag_origin");
}

north_zapper_light_green()
{
	zapper_lights = getentarray("zapper_light_north","targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_green");
	}

	if(isDefined(level.north_light))
	{
		level.north_light delete();
	}

	level.north_light = spawn("script_model",(366, 476 ,329));
	level.north_light setmodel("tag_origin");
	level.north_light.angles = (0,270,0);
	playfxontag(level._effect["zapper_light_ready"],level.north_light,"tag_origin");

}

south_zapper_light_red()
{
	zapper_lights = getentarray("zapper_light_south","targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_red");
	}

	if(isDefined(level.south_light))
	{
		level.south_light delete();
	}
	level.south_light = spawn("script_model",(168, -404, 330));
	level.south_light setmodel("tag_origin");
	level.south_light.angles = (0,90,0);
	playfxontag(level._effect["zapper_light_notready"],level.south_light,"tag_origin");
}

south_zapper_light_green()
{

	zapper_lights = getentarray("zapper_light_south","targetname");
	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_zapper_cagelight_green");
	}
	if(isDefined(level.south_light))
	{
		level.south_light delete();
	}

	level.south_light = spawn("script_model",(168, -404, 330));
	level.south_light setmodel("tag_origin");
	level.south_light.angles = (0,270,0);
	playfxontag(level._effect["zapper_light_ready"],level.south_light,"tag_origin");

}



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
	self playsound ("zmb_elec_jib_zombie");

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
play_the_numbers()
{
	while(1)
	{
		wait(randomintrange(15,20));
		playsoundatposition("the_numbers", (-608, -336, 304));
		wait(randomintrange(15,20));

	}

}
magic_box_limit_location_init()
{

	level.open_chest_location = [];
	level.open_chest_location[0] = undefined;
	level.open_chest_location[1] = undefined;
	level.open_chest_location[2] = undefined;
	level.open_chest_location[3] = "opened_chest";
	level.open_chest_location[4] = "start_chest";


		level thread waitfor_flag_open_chest_location("magic_box_south");
		level thread waitfor_flag_open_chest_location("south_access_1");
		level thread waitfor_flag_open_chest_location("north_door1");
		level thread waitfor_flag_open_chest_location("north_upstairs_blocker");
		level thread waitfor_flag_open_chest_location("south_upstairs_blocker");

}

waitfor_flag_open_chest_location(which)
{

	wait(3);

	switch(which)
	{
	case "magic_box_south":
		flag_wait("magic_box_south");
		level.open_chest_location[0] = "magic_box_south";
		break;

	case "south_access_1":
		flag_wait("south_access_1");
		level.open_chest_location[0] = "magic_box_south";
		level.open_chest_location[1] = "magic_box_bathroom";
		break;

	case "north_door1":
		flag_wait("north_door1");
		level.open_chest_location[2] = "magic_box_hallway";
		break;

	case "north_upstairs_blocker":
		flag_wait("north_upstairs_blocker");
		level.open_chest_location[2] = "magic_box_hallway";
		break;

	case "south_upstairs_blocker":
		flag_wait("south_upstairs_blocker");
		level.open_chest_location[1] = "magic_box_bathroom";
		break;

	default:
		return;

	}

}
magic_box_light()
{
	open_light = getent("opened_chest_light", "script_noteworthy");
	hallway_light = getent("magic_box_hallway_light", "script_noteworthy");

	open_light_model = getent("opened_chest_model", "script_noteworthy");
	hallway_light_model = getent("magic_box_hallway_model", "script_noteworthy");



	while(true)
	{
		level waittill("magic_box_light_switch");
		open_light setLightIntensity(0);
		hallway_light setLightIntensity(0);

		open_light_model setmodel("lights_tinhatlamp_off");
		hallway_light_model setmodel("lights_tinhatlamp_off");

		if(level.chests[level.chest_index].script_noteworthy == "opened_chest")
		{
				open_light setLightIntensity(1);
				open_light_model setmodel("lights_tinhatlamp_on");
		}
		else if(level.chests[level.chest_index].script_noteworthy == "magic_box_hallway")
		{
			hallway_light setLightIntensity(1);
			hallway_light_model setmodel("lights_tinhatlamp_on");
		}

	}

}


//water sheeting FX

// plays a water on the camera effect when you pass under a waterfall
watersheet_on_trigger( )
{

	while( 1 )
	{
		self waittill( "trigger", who );

		if( isDefined(who) && isplayer(who) && isAlive(who) && who.sessionstate != "spectator" )
		{
			if( !who maps\_laststand::player_is_in_laststand() )
			{
				who setwatersheeting(true, 3);
				wait( 0.1 );
			}
		}
	}
}



setup_custom_vox()
{
	level.plr_vox["level"]["power"] = "power";
}

//-------------------------------------------------------------------------------
// Solo Revive zombie exit points.
//-------------------------------------------------------------------------------
asylum_exit_level()
{
	zombies = GetAiArray( "axis" );
	for ( i = 0; i < zombies.size; i++ )
	{
		zombies[i] thread asylum_find_exit_point();
	}
}
asylum_find_exit_point()
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
		master_switch = getent("master_switch","targetname");
		if(IsDefined(master_switch))
		{
			master_switch SetModel("zombie_power_lever_handle");
		}

		// level specific
		asylum_chair_mature = GetEnt("asylum_chair_mature", "targetname");
		if(IsDefined(asylum_chair_mature))
		{
			asylum_chair_mature SetModel("zombie_asylum_chair_nogore");
		}
	}
}

move_speed_cola()
{
	machine = getentarray("vending_sleight", "targetname");

	speed_machine = undefined;

	for( i = 0; i < machine.size; i++ )
	{
		speed_machine = machine[i];
	}

	angles = AnglesToForward(speed_machine.angles);
	speed_machine MoveTo(speed_machine.origin + (angles * 16), .05);
	speed_machine waittill("movedone");

	vending_triggers = GetEntArray( "zombie_vending", "targetname" );
	for( i = 0; i < vending_triggers.size; i++ )
	{
		if(vending_triggers[i].script_noteworthy == "specialty_fastreload" || vending_triggers[i].script_noteworthy == "specialty_fastreload_upgrade")
		{
			vending_triggers[i].origin += angles * 16;
		}
	}
}

fix_zombie_pathing()
{
	speed_machine = getent("vending_sleight", "targetname");

	angles_right = AnglesToForward(speed_machine.angles);
	angles_forward = AnglesToRight(speed_machine.angles);
	bad_spot = (-635.308, 726.692, 226.125);
	good_spot = bad_spot - (angles_right * 32) - (angles_forward * 64);

	while(1)
	{
		zombs = GetAiSpeciesArray( "axis", "all" );
		for(i = 0; i < zombs.size; i++)
		{
			if(IsDefined(zombs[i].recalculating) && zombs[i].recalculating)
			{
				continue;
			}
			if(int(DistanceSquared(bad_spot, zombs[i].origin)) < 24*24)
			{
				zombs[i].recalculating = true;
				zombs[i] thread recalculate_pathing(good_spot);
			}
		}
		wait .05;
	}
}

recalculate_pathing(good_spot)
{
	self SetGoalPos(good_spot);
	wait .2;
	self.recalculating = false;
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
				if(tokens[j] == "upstairs_north_door2")
				{
					zombie_doors[i].zombie_cost = 750;
					break;
				}
			}
		}
	}
}

override_box_locations()
{
	level.treasure_box_bottom = false;
	level.treasure_box_rubble_model = "zombie_treasure_box_rubble";
	level.treasure_box_rubble_use_alternate_origin = true;

	origin = (826, 425.5, 228);
	angles = (0, 90, 0);
	maps\_zombiemode_weapons::place_treasure_chest("north_balcony_chest", origin, angles);

	level.treasure_box_use_alternate_clip = true;
	level.treasure_box_use_alternate_trigger = true;

	origin = (-548, 458, 228);
	angles = (0, 180, 0);
	maps\_zombiemode_weapons::place_treasure_chest("kitchen_chest", origin, angles);
}