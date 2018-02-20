#include clientscripts\_utility;
#include clientscripts\_music;
#include clientscripts\_zombiemode_weapons;

main()
{
	level._uses_crossbow = true;
	level._power_on = false;
	
	// ww: thundergun init happens in _zombiemode.csc so the weapons need to be setup before _zombiemode::main is
	include_weapons();

	// _load!
	clientscripts\_zombiemode::main();
	clientscripts\zombie_pentagon_fx::main();

	clientscripts\zombie_pentagon_teleporter::main();
	thread clientscripts\zombie_pentagon_amb::main();

	clientscripts\_zombiemode_deathcard::init();

	// Setup the magic box screens	
	level init_pentagon_box_screens();

	// This needs to be called after all systems have been registered.
	thread waitforclient(0);	
	
	register_zombie_types();
	pentagon_client_flags();

	// Waits for power before starting the screens	
	level thread pentagon_ZPO_listener();
	level thread pentagon_TLO_listener();
	level thread set_visionset_office();
	level thread set_visionset_warroom();
	level thread set_visionset_lab();
	level thread set_visionset_tech();
	
	level thread pentagon_office_light_model_swap_init();
}

register_zombie_types()
{
	character\clientscripts\c_usa_pent_zombie_officeworker::register_gibs();
	character\clientscripts\c_usa_pent_zombie_militarypolice::register_gibs();
	character\clientscripts\c_usa_pent_zombie_scientist::register_gibs();
	
	character\clientscripts\c_zom_quad::register_gibs();	
}

include_weapons()
{
	include_weapon( "frag_grenade_zm", false );
	include_weapon( "claymore_zm", false );

	//	Weapons - Pistols
	include_weapon( "m1911_zm", false );						// colt
	include_weapon( "m1911_upgraded_zm", false );
	include_weapon( "python_zm" );						// 357
	include_weapon( "python_upgraded_zm", false );
  	include_weapon( "cz75_zm" );
  	include_weapon( "cz75_upgraded_zm", false );

	//	Weapons - Semi-Auto Rifles
	include_weapon( "m14_zm", false );							// gewehr43
	include_weapon( "m14_upgraded_zm", false );

	//	Weapons - Burst Rifles
	include_weapon( "m16_zm", false );						
	include_weapon( "m16_gl_upgraded_zm", false );
	include_weapon( "g11_lps_zm" );
	include_weapon( "g11_lps_upgraded_zm", false );
	include_weapon( "famas_zm" );
	include_weapon( "famas_upgraded_zm", false );

	//	Weapons - SMGs
	include_weapon( "ak74u_zm", false );						// thompson, mp40, bar
	include_weapon( "ak74u_upgraded_zm", false );
	include_weapon( "mp5k_zm", false );
	include_weapon( "mp5k_upgraded_zm", false );
	include_weapon( "mp40_zm", false );
	include_weapon( "mp40_upgraded_zm", false );
	include_weapon( "mpl_zm", false );
	include_weapon( "mpl_upgraded_zm", false );
	include_weapon( "pm63_zm", false );
	include_weapon( "pm63_upgraded_zm", false );
	include_weapon( "spectre_zm" );
	include_weapon( "spectre_upgraded_zm", false );

	//	Weapons - Dual Wield
  	include_weapon( "cz75dw_zm" );
  	include_weapon( "cz75dw_upgraded_zm", false );

	//	Weapons - Shotguns
	include_weapon( "ithaca_zm", false );						// shotgun
	include_weapon( "ithaca_upgraded_zm", false );
	include_weapon( "rottweil72_zm", false );
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
	include_weapon( "zombie_cymbal_monkey" );
	include_weapon( "ray_gun_zm" );
	include_weapon( "ray_gun_upgraded_zm", false );
	include_weapon( "freezegun_zm" );
	include_weapon( "freezegun_upgraded_zm", false );
	include_weapon( "crossbow_explosive_zm" );
	include_weapon( "crossbow_explosive_upgraded_zm", false );

	include_weapon( "knife_ballistic_zm", true );
	include_weapon( "knife_ballistic_upgraded_zm", false );
	include_weapon( "knife_ballistic_bowie_zm", false );
	include_weapon( "knife_ballistic_bowie_upgraded_zm", false );

}
//------------------------------------------------------------------------------
// DCS 090210: clientsided vision set changes 
//------------------------------------------------------------------------------
set_visionset_office()
{
	while(true)
	{
		level waittill( "vis1", ClientNum );
		if(level._power_on == true)
		{
			//VisionSetNaked(ClientNum, "zombie_pentagon_offices_poweroff", 0.0);
			VisionSetNaked(ClientNum, "zombie_pentagon", 0.0);
		}
		else
		{
			//VisionSetNaked(ClientNum, "zombie_pentagon", 0.0);
			VisionSetNaked(ClientNum, "zombie_pentagon_offices_poweroff", 0.0);
		}
	}	
}	
set_visionset_warroom()
{
	while(true)
	{	
		level waittill( "vis2", ClientNum );
		VisionSetNaked(ClientNum, "zombie_pentagon_warroom", 2.0);
	}	
}

set_visionset_lab()
{
	while(true)
	{
		level waittill( "vis3", ClientNum );
		VisionSetNaked(ClientNum, "zombie_pentagon_lab", 2.0);
	}	
}
set_visionset_tech()
{
	while(true)
	{
		level waittill( "vis4", ClientNum );
		VisionSetNaked(ClientNum, "zombie_pentagon_electrician", 1.0);
	}	
}


//------------------------------------------------------------------------------
// Pentagon video tracking for the magic box
//------------------------------------------------------------------------------
init_pentagon_box_screens()
{
	// logic is written to deal with arrays!
	level._pentagon_fire_sale = array( "p_zom_monitor_screen_fsale1", "p_zom_monitor_screen_fsale2" );
	level.magic_box_tv_off = array( "p_zom_monitor_screen_off" );
	level.magic_box_tv_on = array( "p_zom_monitor_screen_on" );																
	
	level.magic_box_tv_lobby_1 = array( "p_zom_monitor_screen_lobby0", "p_zom_monitor_screen_lobby1" );
	level.magic_box_tv_lobby_2 = array( "p_zom_monitor_screen_lobby0", "p_zom_monitor_screen_lobby2" );
	
	level.magic_box_tv_warroom_1 = array( "p_zom_monitor_screen_warroom0", "p_zom_monitor_screen_warroom1" );
	
	level.magic_box_tv_labs_1 = array( "p_zom_monitor_screen_labs0", "p_zom_monitor_screen_labs1" );
	level.magic_box_tv_labs_2 = array( "p_zom_monitor_screen_labs0", "p_zom_monitor_screen_labs2" );
	level.magic_box_tv_labs_3 = array( "p_zom_monitor_screen_labs0", "p_zom_monitor_screen_labs3" );
	
	level.magic_box_tv_random = array( "p_zom_monitor_screen_logo" );	
	
	// the array of models match up with the box script_noteworthy. noteworthy values found in comments
	level._box_locations = array(	level.magic_box_tv_lobby_1, //"level1_chest"
																level.magic_box_tv_lobby_2, //"level1_chest2"
																level.magic_box_tv_warroom_1, //"level2_chest"
																level.magic_box_tv_labs_1, //"start_chest"
																level.magic_box_tv_labs_2, //"start_chest2"
																level.magic_box_tv_labs_3 ); //"start_chest3"

	level._custom_box_monitor = ::pentagon_screen_switch;															
}


pentagon_ZPO_listener()
{
	// 

	while(1)
	{
		level waittill("ZPO");	// Zombie power on.
		level._power_on = true;

		// level notify( "threeprimaries_on" );

		// power lights
		level notify( "TLO" );
	}
}


pentagon_TLO_listener()
{
	while ( 1 )
	{
		level waittill( "TLO" );

		level notify( "por0" );
		level notify( "por1" );
		level notify( "por2" );
		level notify( "por3" );
		level notify( "por4" );

		level waittill( "TLF" );

		level notify( "por0" );
		level notify( "por1" );
		level notify( "por2" );
		level notify( "por3" );
		level notify( "por4" );
	}
}


pentagon_tv_init( client_num )
{
	if ( !isdefined( level.pentagon_tvs ) )
	{
		level.pentagon_tvs = [];
	}

	if ( isdefined( level.pentagon_tvs[client_num] ) )
	{
		return;
	}

	level.pentagon_tvs[client_num] = GetEntArray( client_num, "model_pentagon_box_screens", "targetname" );

	// set up tag origin models to play the fx off of
	for( i = 0; i < level.pentagon_tvs[client_num].size; i++ )
	{
		tele = level.pentagon_tvs[client_num][i];
		
		tele SetModel( level.magic_box_tv_off[0] );
		
		wait( 0.1 );
	}
}

// this is what it runs after changing state in the zombie_pentagon_magic_box.gsc
// 
pentagon_screen_switch( client_num, state, oldState )
{
	pentagon_tv_init( client_num );

	if( state == "n" ) // "n" can mean no power or undefined spot
	{
		if( level._power_on == false )
		{
			screen_to_display = level.magic_box_tv_off;
		}
		else
		{
			screen_to_display = level.magic_box_tv_on;
		}
	}
	else if( state == "f" ) // a state of "f" means "fire_sale"
	{
		screen_to_display = level._pentagon_fire_sale;
	}
	else // the state was a number that matches a spot in level._box_locations
	{
		// client info is sent as a string, this is a number i need
		array_number = Int( state );

		// which spot in the array is the box? this string matches the fx to play
		screen_to_display = level._box_locations[ array_number ];
	}
	
	stop_notify = "stop_tv_swap";


	// play the correct fx on each screen
	for( i = 0; i < level.pentagon_tvs[client_num].size; i++ )
	{
		tele = level.pentagon_tvs[client_num][i];		
		tele notify( stop_notify );
		wait( 0.2 );
		tele thread magic_box_screen_swap( screen_to_display, "stop_tv_swap" ); 
		tele thread play_magic_box_tv_audio( state );
	}

}

// changes the model (self) through the array of models passed in
// this will also check to see if level.magic_box_tv_random is defined and throw in a surprise
magic_box_screen_swap( model_array, endon_notify )
{
	self endon( endon_notify );
	
	while( true )
	{
		for( i = 0; i < model_array.size; i++ )
		{
			self SetModel( model_array[i] );
			wait( 3.0 );
		}
		
		if( 6 > RandomInt( 100 ) && IsDefined( level.magic_box_tv_random ) )
		{
			self SetModel( level.magic_box_tv_random[ RandomInt( level.magic_box_tv_random.size ) ] );
			wait( 2.0 );
		}
		
		wait( 1.0 );
	}
	
}

// ww: init the lights that swap when the power is turned on
pentagon_office_light_model_swap_init()
{
	// lights
	players = getlocalplayers();
	
	for( i = 0; i < players.size; i++ )
	{
		office_light_models = GetEntArray( i,  "model_interior_office_lights", "targetname" );
	
		if( IsDefined( office_light_models ) && office_light_models.size > 0 )
		{
			array_thread( office_light_models, ::pentagon_office_light_model_swap );
		}
	}
	

}

// ww: swap a model light with the off version when the power is switched
pentagon_office_light_model_swap()
{
	level waittill( "ZPO" );
	
	if( self.model == "p_pent_light_ceiling_on" )
	{
		self SetModel( "p_pent_light_ceiling" );
	}
	else if( self.model == "p_pent_light_tinhat_on" )
	{
		self SetModel( "p_pent_light_tinhat_off" );
	}
}

play_magic_box_tv_audio( state )
{
    alias = "amb_tv_static";
    
    if( state == "n" )
	{
		if( level._power_on == false )
		{
		    alias = undefined;
		}
		else
		{
		    alias = "amb_tv_static";
		}
	}
	else if( state == "f" )
	{
	    alias = "mus_fire_sale";
	}
	else
	{
	    alias = "amb_tv_static";
	}
	
	if( !IsDefined(alias) )
	{
	    self stoploopsound( .5 );
	}
	else
	{
	    self PlayLoopSound( alias, .5 );
	}
}

//-------------------------------------------------------------------------------
// DCS 091510: setting up client flags for vision sets and efx.
//-------------------------------------------------------------------------------
pentagon_client_flags()
{
	// Client flags for the player
	level.ZOMBIE_PENTAGON_PLAYER_PORTALFX = 5;
	level.ZOMBIE_PENTAGON_PLAYER_PORTALFX_COOL = 6;
	level.ZOMBIE_PENTAGON_PLAYER_CF_UPDATEPROFILE	 = 0;

	// Callbacks for players
	
	register_clientflag_callback("player", level.ZOMBIE_PENTAGON_PLAYER_PORTALFX, clientscripts\zombie_pentagon_teleporter::teleporter_fx_init);
	register_clientflag_callback("player", level.ZOMBIE_PENTAGON_PLAYER_CF_UPDATEPROFILE, ::update_player_profile);
}

// ww: handles the unlocking of doa from the batphones
update_player_profile(localClientNum, set, newEnt)
{
	UpdateGamerProfile(localClientNum);
}