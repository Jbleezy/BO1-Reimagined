#include clientscripts\_utility;
#include clientscripts\_music;
#include clientscripts\_zombiemode_weapons;


main()
{
	level._uses_crossbow = true;

	level thread clientscripts\zombie_moon_ffotd::main_start();

	include_weapons();
	include_equipment_for_level();

	level._no_water_risers = 1;
	level.riser_fx_on_client = 1;
	level.risers_use_low_gravity_fx = 1;
	level.use_clientside_board_fx = 1;


	level.override_board_repair_sound = "evt_vent_slat_repair";
	level.override_board_teardown_sound = "evt_vent_slat_remove";


	// _load!
	clientscripts\_zombiemode::main();

	clientscripts\_zombiemode_equip_gasmask::init();
	clientscripts\_zombiemode_equip_hacker::init();

	clientscripts\zombie_moon_fx::main();
	thread clientscripts\zombie_moon_amb::main();


	// weapons
	clientscripts\_sticky_grenade::main();

	clientscripts\_zombiemode_weap_black_hole_bomb::init();
	level._visionset_black_hole_bomb = "zombie_moon_black_hole";		//OVERRIDE FOR MOON

	clientscripts\_zombiemode_weap_microwavegun::init();
	clientscripts\_zombiemode_weap_quantum_bomb::init();

	clientscripts\_zombiemode_deathcard::init();

	register_zombie_types();

	// on player connect
	OnPlayerConnect_Callback( ::moon_player_connect );

	register_client_flags();
	register_clientflag_callbacks();

	// This needs to be called after all systems have been registered.
	thread waitforclient(0);

	level._moon_exterior_vision_set = "zombie_moon";
	level._moon_exterior_vision_set_priority = 5;

	level._moon_interior_vision_set = "zombie_moonInterior";
	level._moon_interior_vision_set_priority = 5;

	level._moon_biodome_vision_set = "zombie_moonBioDome";
	level._moon_biodome_vision_set_priority = 5;

	level._moon_tunnels_vision_set = "zombie_moonTunnels";
	level._moon_tunnels_vision_set_priority = 5;

	level._moon_hanger18_vision_set = "zombie_moonHanger18";
	level._moon_hanger18_vision_set_priority = 5;

	level._moon_hellEarth_vision_set = "zombie_moon_hellEarth";
	level._moon_hellEarth_vision_set_priority = 5;

	level thread clientscripts\zombie_moon_digger::main();

	level._dte_vision_set = "zombie_coast_powerOn";
	level._dte_vision_set_priority = 7;

	// gravity
	clientscripts\zombie_moon_gravity::init();

	level thread clientscripts\zombie_moon_ffotd::main_end();
	level thread radar_dish_init();

	//activate the jump pads when power comes on
	level thread jump_pad_activate();


	//sky transitions
	level thread no_mans_land_sky();
	level thread moon_sky();


	// Charge the tank sidequest stages.

	level thread clientscripts\zombie_moon_sq::ctt_cleanup();
	level thread clientscripts\zombie_moon_sq::ctt1_init();
	level thread clientscripts\zombie_moon_sq::ctt2_init();
	level thread clientscripts\zombie_moon_sq::cp_init();
	level thread clientscripts\zombie_moon_sq::wp_init();
	level thread clientscripts\zombie_moon_sq::vg_init();
	level thread clientscripts\zombie_moon_sq::sam_init();
	level thread clientscripts\zombie_moon_sq::rocket_test();
	level thread clientscripts\zombie_moon_sq::dte_watcher();
	level thread clientscripts\zombie_moon_sq::sr_rumble();
	level thread clientscripts\zombie_moon_sq::sam_vo_rumble();
	level thread clientscripts\zombie_moon_sq::r_r();
	level thread clientscripts\zombie_moon_sq::r_l();
	level thread clientscripts\zombie_moon_sq::d_e();

	//hiding and showing the earth
	level thread hide_earth();
	level thread show_earth();
	level thread hide_destroyed_earth();
	level thread show_destroyed_earth();




	level thread receiving_bay_doors_init();

	level thread game_over_fog_and_vision_fix();
}


register_zombie_types()
{
	character\clientscripts\c_zom_moon_tech_zombie_1::register_gibs();
	character\clientscripts\c_zom_moon_tech_zombie_1_2::register_gibs();
	character\clientscripts\c_zom_moon_tech_zombie_1_3::register_gibs();
	character\clientscripts\c_zom_moon_tech_zombie_2::register_gibs();
	character\clientscripts\c_zom_moon_tech_zombie_2_2::register_gibs();
	character\clientscripts\c_zom_moon_tech_zombie_3::register_gibs();
	character\clientscripts\c_zom_moon_tech_zombie_3_2::register_gibs();
	character\clientscripts\c_zom_moon_tech_zombie_3_3::register_gibs();
	character\clientscripts\c_zom_moon_zombie_militarypolice::register_gibs();
}

register_client_flags()
{
	level._CLIENTFLAG_SCRIPTMOVER_DIGGER_MOVING_EARTHQUAKE_RUMBLE = 0;
	level._CLIENTFLAG_SCRIPTMOVER_DIGGER_DIGGING_EARTHQUAKE_RUMBLE = 1;
	level._CLIENTFLAG_SCRIPTMOVER_DIGGER_ARM_FX = 2;
	level._CLIENTFLAG_SCRIPTMOVER_DOME_MALFUNCTION_PAD = 3;

	level._CLIENTFLAG_PLAYER_SKY_TRANSITION = 0;
	level._CLIENTFLAG_PLAYER_SOUL_SWAP = 1;
	level._CLIENTFLAG_PLAYER_GASP_RUMBLE = 2;


	level._ZOMBIE_ACTOR_FLAG_LOW_GRAVITY = 0;
	level._CF_ACTOR_CLIENT_FLAG_CTT = 2;
}

register_clientflag_callbacks()
{
	register_clientflag_callback("scriptmover",level._CLIENTFLAG_SCRIPTMOVER_DIGGER_MOVING_EARTHQUAKE_RUMBLE, clientscripts\zombie_moon_digger::digger_moving_earthquake_rumble);
	register_clientflag_callback("scriptmover",level._CLIENTFLAG_SCRIPTMOVER_DIGGER_DIGGING_EARTHQUAKE_RUMBLE, clientscripts\zombie_moon_digger::digger_digging_earthquake_rumble);
	register_clientflag_callback("scriptmover",level._CLIENTFLAG_SCRIPTMOVER_DIGGER_ARM_FX, clientscripts\zombie_moon_digger::digger_arm_fx);
	register_clientflag_callback("scriptmover",level._CLIENTFLAG_SCRIPTMOVER_DOME_MALFUNCTION_PAD, ::dome_malfunction_pad );


	register_clientflag_callback("player",level._CLIENTFLAG_PLAYER_SKY_TRANSITION, ::moon_nml_transition );
	register_clientflag_callback("player",level._CLIENTFLAG_PLAYER_SOUL_SWAP, clientscripts\zombie_moon_sq::soul_swap);

	register_clientflag_callback("player",level._CLIENTFLAG_PLAYER_GASP_RUMBLE, ::player_gasp_rumble);


	register_clientflag_callback( "actor", level._ZOMBIE_ACTOR_FLAG_LOW_GRAVITY, clientscripts\zombie_moon_gravity::zombie_low_gravity );
	register_clientflag_callback( "actor", level._CF_ACTOR_CLIENT_FLAG_CTT, clientscripts\zombie_moon_sq::zombie_release_soul );

}

include_weapons()
{
	include_weapon( "frag_grenade_zm", false );
	include_weapon( "sticky_grenade_zm", false );
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
	include_weapon( "knife_ballistic_zm", true );
	include_weapon( "knife_ballistic_upgraded_zm", false );
	include_weapon( "knife_ballistic_bowie_zm", false );
	include_weapon( "knife_ballistic_bowie_upgraded_zm", false );

	//	Weapons - Special
	include_weapon( "zombie_black_hole_bomb" );
	include_weapon( "ray_gun_zm" );
	include_weapon( "ray_gun_upgraded_zm", false );
	include_weapon( "zombie_quantum_bomb" );
	include_weapon( "microwavegundw_zm" );
	include_weapon( "microwavegundw_upgraded_zm", false );
}

include_equipment_for_level()
{
	clientscripts\_zombiemode_equipment::include_equipment( "equip_gasmask_zm" );
	clientscripts\_zombiemode_equipment::include_equipment( "equip_hacker_zm" );
}

disable_deadshot( i_local_client_num )
{
	// Wait until all the rendered objects are setup
	while ( !self hasdobj( i_local_client_num ) )
	{
		wait( 0.05 );
	}

	players = GetLocalPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		if ( self == players[i] )
		{
			self clearalternateaimparams();
		}
	}
}

moon_player_connect( i_local_client_num )
{
	self endon( "disconnect" );

	// make sure the client has a snapshot from the server before continuing
	while( !ClientHasSnapshot( i_local_client_num ) )
	{
		wait( 0.05 );
	}

	while ( !self hasdobj( i_local_client_num ) )
	{
		wait( 0.05 );
	}

	// only client 0 works on this part
	if( i_local_client_num != 0 )
	{
		return;
	}

	self thread disable_deadshot(i_local_client_num);
}

//*****************************************************************************
// rotating background radar dishes (need to clientside)
//*****************************************************************************
radar_dish_init()
{
	radar_dish = GetEntArray(0, "zombie_cosmodrome_radar_dish", "targetname");
	if(IsDefined(radar_dish))
	{
		for ( i = 0; i < radar_dish.size; i++ )
		{
			radar_dish[i] thread radar_dish_rotate();
		}
	}
}

radar_dish_rotate()
{
	wait(0.1);

	while(true)
	{
		self rotateyaw( 360,  RandomFloatRange(60,120) );
		self waittill("rotatedone");
	}
}

//*****************************************************************************
// recieving bay doors.
//*****************************************************************************
receiving_bay_doors_init()
{
	waitforallclients();

	players = getlocalplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] thread receiving_bay_doors(i);
		players[i] thread computer_screens_power(i);
	}
}
receiving_bay_doors(localClientNum)
{
	level waittill("power_on");

	doors = GetEntArray(localClientNum, "receiving_bay_doors", "targetname");
	for( i = 0; i < doors.size; i++ )
	{
		if(isDefined(doors[i].script_vector))
		{

			doors[i] playsound( 0, "evt_loading_door_start" );
			doors[i] playloopsound( "evt_loading_door_loop", .5 );
			doors[i] MoveTo( doors[i].origin + doors[i].script_vector, 3 );
			doors[i] thread stop_loop_play_end();
		}
	}
}
stop_loop_play_end()
{
	wait(2.6);
	self stoploopsound( .5 );
	self playsound( 0, "evt_loading_door_end" );
}
computer_screens_power(localClientNum)
{
	screens = GetEntArray(localClientNum, "moon_comp_screens", "targetname");
	for( i = 0; i < screens.size; i++ )
	{
		screens[i] Hide();
	}

	level waittill("power_on");

	for( i = 0; i < screens.size; i++ )
	{
		screens[i] Show();
	}
}

jump_pad_activate()
{
	level.power_on = false;
	level waittill("ZPO");
	level.power_on = true;

	for( i = 0; i < level._num_local_players; i++ )
	{
		jump_pad_start_fx( i );
	}

}


no_mans_land_sky()
{
	while(1)
	{
		level waittill("NMS",lcn);
		if( IsDefined( lcn ) && lcn != 0 )
		{
			continue;
		}

		if(IsDefined(level._dte_done))
		{
			continue;
		}

		SetSavedDvar( "r_skyTransition", 1 );
	}
}


moon_sky()
{
	while(1)
	{
		level waittill("MMS",lcn);
		if( IsDefined( lcn ) && lcn != 0 )
		{
			continue;
		}

		SetSavedDvar( "r_skyTransition", 0 );
	}
}

// starts all the fxs for the jump pads when the power is hit, runs for each local player
jump_pad_start_fx( int_local_player_num )
{
	player = GetLocalPlayers()[int_local_player_num];
	if( !isDefined( player ) )
	{
		return;
	}

	moon_jump_pads = GetEntArray( int_local_player_num, "jump_pads", "targetname" );

	if( IsDefined( moon_jump_pads ) && moon_jump_pads.size > 0 )
	{
		for( i = 0; i < moon_jump_pads.size; i++ )
		{
			moon_jump_pads[i]._fx = Spawn( int_local_player_num, moon_jump_pads[i].origin, "script_model" );
			moon_jump_pads[i]._fx.angles = moon_jump_pads[i].angles;
			moon_jump_pads[i]._fx SetModel( "tag_origin" );

			moon_jump_pads[i]._glow = PlayFXOnTag( int_local_player_num, level._effect["jump_pad_active"], moon_jump_pads[i]._fx, "tag_origin" );
		}
	}

}

// toggles the effects for the jump pad that malfunction in the dome
dome_malfunction_pad( local_client_num, int_set, ent_new )
{
	if( local_client_num != 0 )
	{
		return;
	}

	if( int_set ) // turn off the fx on the pad closest to the model
	{
		player = GetLocalPlayers()[local_client_num];
		if( !isDefined( player ) )
		{
			return;
		}

		for( x = 0; x < level._num_local_players; x++ )
		{
			mal_pad = undefined;
			closest = 999999;
			jump_pads = GetEntArray( x, "jump_pads", "targetname" );

			for( i = 0; i< jump_pads.size; i++ )
			{
				pad = jump_pads[i];

				dist = Distance2D( self.origin, pad.origin ); // get the distance between the model and the pad

				if( dist < closest ) // if the pad dist is closest then set the mal_pad
				{
					mal_pad = pad;
					closest = dist;
				}
			}

			// should now have the closest pad, remove the effects
			if( IsDefined( mal_pad._fx ) )
			{
				rand = randomintrange(4,7);
				for(i=0;i< rand;i++)
				{
					StopFX( x, mal_pad._glow );
					wait(randomfloatrange(.05,.15));
					mal_pad playsound( 0, "evt_electrical_surge" );
					mal_pad._glow = PlayFXOnTag( x, level._effect["jump_pad_active"], mal_pad._fx, "tag_origin" );
					wait(randomfloatrange(.05,.15));
				}
				StopFX( x, mal_pad._glow );
			}
		}

	}
	else // turn the closest pad back on
	{
		player = GetLocalPlayers()[local_client_num];
		if( !isDefined( player ) )
		{
			return;
		}

		for( x = 0; x < level._num_local_players; x++ )
		{
			mal_pad = undefined;
			closest = 999999;
			jump_pads = GetEntArray( x, "jump_pads", "targetname" );

			for( i = 0; i< jump_pads.size; i++ )
			{
				pad = jump_pads[i];

				dist = Distance2D( self.origin, pad.origin ); // get the distance between the model and the pad

				if( dist < closest ) // if the pad dist is closest then set the mal_pad
				{
					mal_pad = pad;
					closest = dist;
				}
			}

			if( IsDefined( mal_pad._fx ) )
			{
				rand = randomintrange(4,7);
				for(i=0;i< rand;i++)
				{
					mal_pad playsound( 0, "evt_electrical_surge" );
					mal_pad._glow = PlayFXOnTag( x, level._effect["jump_pad_active"], mal_pad._fx, "tag_origin" );
					wait(randomfloatrange(.05,.15));
					StopFX( x, mal_pad._glow );
					wait(randomfloatrange(.05,.15));
				}
							// spawn the new fx spot
				mal_pad._glow = PlayFXOnTag( x, level._effect["jump_pad_active"], mal_pad._fx, "tag_origin" );

			}

		}

	}

}


//------------------------------------------------------------------------------
// fog settings, move to client.
//------------------------------------------------------------------------------
moon_nml_transition(localClientNum, set,newEnt)
{
	if(!self isLocalPlayer() )
	{
		return;
	}

	if(!isDefined(self GetLocalClientNumber() ))
	{
		return;
	}

	if(set)
	{

	// No Man's Land Fog/Sun settings

		new_vision = "";
		pv = "";

		if(IsDefined(level._dte_done))
		{
			start_dist = 2146.77;
			half_dist = 14890.1;
			half_height = 99.8105;
			base_height = -294.011;
			fog_r = 0.819608;
			fog_g = 0.34902;
			fog_b = 0.176471;
			fog_scale = 3.97095;
			sun_col_r = 0.666667;
			sun_col_g = 0.321569;
			sun_col_b = 0.141176;
			sun_dir_x = 0.804298;
			sun_dir_y = 0.433214;
			sun_dir_z = 0.406731;
			sun_start_ang = 0;
			sun_stop_ang = 58.1887;
			time = 0;
			max_fog_opacity = 0.72;


			sunlight = 5;
			sundirection = (-16, 56.06, 0);
			suncolor = (.905, .203, 0);

			SetSavedDvar("sm_sunSampleSizeNear", "1.18");
			SetSavedDvar( "r_skyColorTemp", (6400));

			new_vision = "zmhe"; // zombie_moonHellEarth
			pv = "zmhe";

		}
		else
		{
			start_dist = 1662.13;
			half_dist = 18604.1;
			half_height = 2618.86;
			base_height = -5373.56;
			fog_r = 0.764706;
			fog_g = 0.505882;
			fog_b = 0.231373;
			fog_scale = 5;
			sun_col_r = 0.8;
			sun_col_g = 0.435294;
			sun_col_b = 0.101961;
			sun_dir_x = 0.796421;
			sun_dir_y = 0.425854;
			sun_dir_z = 0.429374;
			sun_start_ang = 0;
			sun_stop_ang = 45.87;
			time = 0;
			max_fog_opacity = 0.72;


			sunlight = 5;
			sundirection = (-16, 56.06, 0);
			suncolor = (.924, .775, .651);

			SetSavedDvar("sm_sunSampleSizeNear", "1.18");
			SetSavedDvar( "r_skyColorTemp", (6400));

			new_vision = "zmh"; // zombie_moonHanger18
			pv = "zmh";
		}

		players = GetLocalPlayers();
		ent_player = players[localClientNum];

		if( !IsDefined( ent_player._previous_vision ) )
		{
			ent_player._previous_vision = pv;
		}

		ent_player clientscripts\zombie_moon_fx::moon_vision_set( ent_player._previous_vision, new_vision, localClientNum, 0 );

		ent_player._previous_vision = pv;


		// VisionSetNaked(localClientNum,"zombie_moonHanger18", 0);

	}
	else
	{

		// Moon Fog/Sun settings

		start_dist = 2098.71;
		half_dist = 1740.12;
		half_height = 1332.23;
		base_height = 576.887;
		fog_r = 0.0196078;
		fog_g = 0.0235294;
		fog_b = 0.0352941;
		fog_scale = 4.1367;
		sun_col_r = 0.247;
		sun_col_g = 0.235;
		sun_col_b = 0.160;
		sun_dir_x = 0.796421;
		sun_dir_y = 0.425854;
		sun_dir_z = 0.429374;
		sun_start_ang = 0;
		sun_stop_ang = 55;
		time = 0;
		max_fog_opacity = 0.95;


	/*


		start_dist = 2098.71;
		half_dist = 1740.12;
		half_height = 1332.23;
		base_height = 576.887;
		fog_r = 0.0196078;
		fog_g = 0.0235294;
		fog_b = 0.0352941;
		fog_scale = 4.1367;
		sun_col_r = 0.247;
		sun_col_g = 0.235;
		sun_col_b = 0.160;
		sun_dir_x = 0.796421;
		sun_dir_y = 0.425854;
		sun_dir_z = 0.429374;
		sun_start_ang = 0;
		sun_stop_ang = 55;
		time = 0;
		max_fog_opacity = 0.95;


		*/


		sunlight = 8;
		sundirection = (-16.28, 56.06, 0);
		suncolor = (0.655, 0.768, 0.817);

		SetSavedDvar("sm_sunSampleSizeNear", "1.8");
		SetSavedDvar( "r_lightGridEnableTweaks", 1 );
		SetSavedDvar( "r_lightGridIntensity", 2 );
		SetSavedDvar( "r_lightGridContrast", .4 );

		players = GetLocalPlayers();
		ent_player = players[localClientNum];

		if( !IsDefined( ent_player._previous_vision ) )
		{
			ent_player._previous_vision = "zme";
		}

		new_vision = "zme"; // zombie_moonHanger18

		ent_player clientscripts\zombie_moon_fx::moon_vision_set( ent_player._previous_vision, new_vision, localClientNum, 0 );

		ent_player._previous_vision = "zme";

		// VisionSetNaked(localClientNum,"zombie_moon", 0);
	}

	setVolFogForClient(localClientNum,start_dist, half_dist, half_height, base_height, fog_r, fog_g, fog_b, fog_scale,
	sun_col_r, sun_col_g, sun_col_b, sun_dir_x, sun_dir_y, sun_dir_z, sun_start_ang,
	sun_stop_ang, time, max_fog_opacity);

	setClientDvar( "r_lightTweakSunLight", sunlight);
	setClientDvar(	"r_lightTweakSunColor", suncolor);
	setClientDvar(	"r_lightTweakSunDirection", sundirection);


}

game_over_fog_and_vision_fix()
{
	level waittill( "ZEG", client );

	if( client != 0 )
	{
		return; // only have one of the local clients fix this issue
	}

	// wherever client 0 died will tell us what area to use
	players = GetLocalPlayers();

	if( !IsDefined( players[client]._previous_vision ) )
	{
		PrintLn( "$$$$ Missing _previous_vision $$$$" );
	}

	switch( players[client]._previous_vision )
	{
		case "zme":
		case "zmi":
		case "zmb":
		case "zmt":
			players[client] thread clientscripts\zombie_moon_fx::Moon_Exterior_Fog_Change( players[client] );
			break;

		case "zmh":
		default:

			players[client] thread clientscripts\zombie_moon_fx::moon_nml_fog_change( players[client] );
			break;
	}

}

player_gasp_rumble(localClientNum, set,newEnt)
{
	if(!self isLocalPlayer() )
	{
		return;
	}

	if(!isDefined(self GetLocalClientNumber() ))
	{
		return;
	}

	if(set)
	{
		if(randomint(100) > 70)
		{
			self PlayRumbleOnEntity(LocalClientNum, "damage_light" );
		}
		else
		{
			self PlayRumbleOnEntity(LocalClientNum, "damage_heavy" );
		}
	}

}


moon_vision_set_choice( str_vision )
{
	if( !IsDefined( str_vision ) )
	{
		return;
	}

	visionset_info = [];

	switch( str_vision )
	{

		case "zme": // "zombie_moon"

			visionset_info[0] = level._moon_exterior_vision_set;
			visionset_info[1] = level._moon_exterior_vision_set_priority;
			break;

		case "zmi": // "zombie_moonInterior"

			visionset_info[0] = level._moon_interior_vision_set;
			visionset_info[1] = level._moon_interior_vision_set_priority;
			break;

		case "zmb": // "zombie_moonBioDome"

			visionset_info[0] = level._moon_biodome_vision_set;
			visionset_info[1] = level._moon_biodome_vision_set_priority;
			break;

		case "zmt": // "zombie_moonTunnels"

			visionset_info[0] = level._moon_tunnels_vision_set;
			visionset_info[1] = level._moon_tunnels_vision_set_priority;
			break;

		case "zmh": // "zombie_moonHanger18"

			visionset_info[0] = level._moon_hanger18_vision_set;
			visionset_info[1] = level._moon_hanger18_vision_set_priority;
			break;

		case "zmhe": // "zombie_moon_hellEarth"

			visionset_info[0] = level._moon_hellEarth_vision_set;
			visionset_info[1] = level._moon_hellEarth_vision_set_priority;
			break;

		case "dte":
			visionset_info[0] = level._dte_vision_set;
			visionset_info[1] = level._dte_vision_set_priority;
			break;
	}

	return visionset_info;

}


show_earth()
{
	while(1)
	{
		level waittill("S_E");
		level thread do_show_earth();
	}
}

do_show_earth()
{

	for(i=0;i<level._num_local_players;i++)
	{
		player = getlocalplayers()[i];

		if(!isDefined(player))
		{
			continue;
		}

		player._earth = spawn(i,( -22060.8, -121800, 34463.4 ),"script_model");
		player._earth.angles = ( 18, 78, 22 );
		player._earth setmodel("p_zom_moon_earth");

	}

}

hide_earth()
{
	while(1)
	{
		level waittill("H_E");
		level thread do_hide_earth();
	}

}

do_hide_earth()
{
	for(i=0;i<level._num_local_players;i++)
	{
		player = getlocalplayers()[i];

		if(!isDefined(player))
		{
			continue;
		}

		if(isDefined(player._earth))
		{
			player._earth delete();
  		}
  	}
}



show_destroyed_earth()
{
	while(1)
	{
		level waittill("SDE");
		level thread do_show_destroyed_earth();
	}
}

do_show_destroyed_earth()
{

	for(i=0;i<level._num_local_players;i++)
	{
		player = getlocalplayers()[i];

		if(!isDefined(player))
		{
			continue;
		}

		player._destroyed_earth = spawn(i,( -22060.8, -121800, 34463.4 ),"script_model");
		player._destroyed_earth.angles = ( 18, 78, 22 );
		player._destroyed_earth setmodel("p_zom_moon_earth_dest");

	}

}

hide_destroyed_earth()
{
	while(1)
	{
		level waittill("HDE");
		level thread do_hide_destroyed_earth();
	}

}

do_hide_destroyed_earth()
{
	for(i=0;i<level._num_local_players;i++)
	{
		player = getlocalplayers()[i];

		if(!isDefined(player))
		{
			continue;
		}

		if(isDefined(player._destroyed_earth))
		{
			player._destroyed_earth delete();
  	}
  }
}
