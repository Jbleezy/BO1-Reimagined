#include clientscripts\_utility;
#include clientscripts\_music;
#include clientscripts\_zombiemode_weapons;

main()
{
	level._uses_crossbow = true;
	
	// ww: thundergun init happens in _zombiemode.csc so the weapons need to be setup before _zombiemode::main is
	include_weapons();

	// _load!
	clientscripts\_zombiemode::main();

	clientscripts\zombie_theater_teleporter::main();
	clientscripts\zombie_theater_fx::main();
	thread clientscripts\zombie_theater_amb::main();

	
	clientscripts\_zombiemode_deathcard::init();
	
	init_theater_box_indicator();
	
	
	// This needs to be called after all systems have been registered.
	thread waitforclient(0);	
	
	level._power_on = false;
	
	level thread theatre_ZPO_listener();
	
	level thread eeroom_visionset_init();
	// DSM: Call for light_swap
	level thread theater_light_model_swap_init();
	
	register_zombie_types();
}

register_zombie_types()
{
	character\clientscripts\c_ger_honorguard_zt::register_gibs();	
	character\clientscripts\c_zom_quad::register_gibs();
}	

/*****************************************************************************
// WEAPON FUNCTIONS
//
// Include the weapons that are only in your level so that the cost/hints are accurate
// Also adds these weapons to the random treasure chest.
//***************************************************************************** */

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

	include_weapon( "thundergun_zm", true );
	include_weapon( "thundergun_upgraded_zm", false );
	include_weapon( "crossbow_explosive_zm" );
	include_weapon( "crossbow_explosive_upgraded_zm", false );
}

init_theater_box_indicator()
{
	level._custom_box_monitor = ::theater_box_monitor;
	
	level._box_locations = array(	"start_chest_loc",
																"foyer_chest_loc",
																"crematorium_chest_loc",
																"alleyway_chest_loc",
																"control_chest_loc",
																"stage_chest_loc",
																"dressing_chest_loc",
																"dining_chest_loc",
																"theater_chest_loc");	
																
	OnPlayerConnect_Callback( ::init_board_lights);
}

init_board_lights(clientNum)
{
//	PrintLn("**** IBL Connected : " + clientNum);

	structs = getstructarray("magic_box_loc_light", "targetname");
	
	for(j = 0; j <structs.size; j ++)
	{
//		PrintLn("*** IBL - creating light " + j + " for client " + clientNum);
		
		s = structs[j];
		
		if(!IsDefined(s.lights))
		{
			s.lights = [];
		}
		
		if(IsDefined(s.lights[clientNum]))
		{
			if(IsDefined(s.lights[clientNum].fx))
			{
				s.lights[clientNum].fx Delete();
				s.lights[clientNum].fx = undefined;
			}
			s.lights[clientNum] Delete();
			s.lights[clientNum] = undefined;
		}
		
		s.lights[clientNum] = spawn( clientNum, s.origin, "script_model");
		s.lights[clientNum].angles = s.angles;
		s.lights[clientNum] setmodel("zombie_zapper_cagelight");
	}
}

get_lights(clientNum, name)
{
	structs = getstructarray(name, "script_noteworthy");
	
	lights = [];
	
	for(i = 0; i < structs.size; i ++)
	{
		lights[lights.size] = structs[i].lights[clientNum];
	}
	
	return(lights);

}

turn_off_all_box_lights(clientNum)
{
	level notify("kill_box_light_threads_"+clientNum);
	
	for(i = 0; i < level._box_locations.size; i ++)
	{
		turn_off_light(clientNum, i);
	}
}

flash_lights(clientNum,period)
{
	level notify("kill_box_light_threads_"+clientNum);
	level endon("kill_box_light_threads_"+clientNum);
	while(1)
	{
		realwait(period);
		for(i = 0; i < level._box_locations.size; i ++)
		{
			turn_light_green(clientNum, i);
		}		
		realwait(period);
		for(i = 0; i < level._box_locations.size; i ++)
		{
			turn_off_light(clientNum, i, true);
		}		
	}
}

turn_light_red(clientNum,light_num, play_fx)
{

	if(light_num == level._BOX_INDICATOR_NO_LIGHTS)
	{
		return;
	}

	name = level._box_locations[light_num];
	
	lights = get_lights(clientNum, name);
	
	for(i = 0; i < lights.size; i ++)
	{
		if (isDefined(lights[i].fx))
		{
			lights[i].fx Delete();
			lights[i].fx = undefined;
		}
				
		if(IsDefined(play_fx) && play_fx)
		{
			lights[i] setmodel("zombie_zapper_cagelight_red");	
			lights[i].fx = spawn( clientNum, ( lights[i].origin[0], lights[i].origin[1], lights[i].origin[2] - 10 ) , "script_model");
			lights[i].fx setmodel("tag_origin");
			lights[i].fx.angles = lights[i].angles;
			playfxontag(clientNum, level._effect["boxlight_light_ready"],lights[i].fx,"tag_origin");
		}
		else
		{
			lights[i] setmodel("zombie_zapper_cagelight_red");	
		}
	}

}

turn_light_green(clientNum,light_num, play_fx)
{
	if(light_num == level._BOX_INDICATOR_NO_LIGHTS)
	{
		return;
	}
	
	name = level._box_locations[light_num];
	
	lights = get_lights(clientNum, name);
	
	for(i = 0; i < lights.size; i ++)
	{
		if (isDefined(lights[i].fx))
		{
			lights[i].fx Delete();
			lights[i].fx = undefined;
		}		
		
		if(IsDefined(play_fx) && play_fx)
		{
			lights[i] setmodel("zombie_zapper_cagelight_green");	
			lights[i].fx = spawn( clientNum, ( lights[i].origin[0], lights[i].origin[1], lights[i].origin[2] - 10 ) , "script_model");
			lights[i].fx setmodel("tag_origin");
			lights[i].fx.angles = lights[i].angles;
			playfxontag(clientNum, level._effect["boxlight_light_ready"],lights[i].fx,"tag_origin");
		}
		else
		{
			lights[i] setmodel("zombie_zapper_cagelight_green");	
		}
	}
		
}

turn_off_light(clientNum,light_num,dont_kill_threads)
{
	if(!IsDefined(dont_kill_threads))
	{
		level notify("kill_box_light_threads_"+clientNum);
	}
	
	if(light_num == level._BOX_INDICATOR_NO_LIGHTS)
	{
		return;
	}

	name = level._box_locations[light_num];
	
	lights = get_lights(clientNum, name);
	for(i=0;i<lights.size;i++)
	{
		if (isDefined(lights[i].fx))
		{
			lights[i].fx Delete();
			lights[i].fx = undefined;
		}
		
		lights[i] setmodel("zombie_zapper_cagelight");			
	}

}


theater_box_monitor(clientNum, state, oldState)
{
	s = Int(state);
	
//	PrintLn("**** TBM - got " + state + " for client " + clientNum);
	
	if(s == level._BOX_INDICATOR_NO_LIGHTS)
	{
		turn_off_all_box_lights(clientNum);
	}
	else if(s == level._BOX_INDICATOR_FLASH_LIGHTS_MOVING)
	{
		level thread flash_lights(clientNum,0.25);			
	}
	else if(s == level._BOX_INDICATOR_FLASH_LIGHTS_FIRE_SALE)
	{
		level thread flash_lights(clientNum,0.3);
	}
	else
	{			
		if(s < 0 || s > level._box_locations.size)
		{
			return;
		}

		level notify("kill_box_light_threads_"+clientNum);
			
		turn_off_all_box_lights(clientNum);
		
		level._box_indicator = s;
		
		if(level._power_on)
		{
			turn_light_green(clientNum,level._box_indicator, true);
		}
	}
}

theatre_ZPO_listener()
{
	while(1)
	{
		level waittill("ZPO");	// Zombie power on.
		level._power_on = true;
		if(level._box_indicator != level._BOX_INDICATOR_NO_LIGHTS)
		{
			for(i = 0; i < getlocalplayers().size; i ++)
			{
				theater_box_monitor(i, level._box_indicator);
			}
		}
		level notify("threeprimaries_on");
		level notify( "pl1" );  // power lights on	
	}
}

// WW: vision sets for the eerooms
eeroom_visionset_init()
{
	eeroom_visionset_triggers = GetEntArray( 0, "trigger_eeroom_visionset", "targetname" );
	
	if( !IsDefined( eeroom_visionset_triggers ) )
	{
		return;
	}
	
	array_thread( eeroom_visionset_triggers, ::theater_player_in_eeroom );
	
}

theater_player_in_eeroom()
{
	while( 1 )
	{
		self waittill( "trigger", ent_player );
		
		if(ent_player IsLocalPlayer())
		{
			self thread trigger_thread( ent_player, ::eeroom_visionset_on, ::eeroom_visionset_off );
		}
	}
}

eeroom_visionset_on( ent_player )
{
	if( !IsDefined( self.script_string ) )
	{
		return;
	}
	
	wait( 1.0 );
	
	switch( self.script_string )
	{
		case "asylum_room":
			VisionSetNaked( ent_player GetLocalClientNumber(), "zombie_theater_eroom_asylum", 0 );
			break;
		
		case "pentagon_room":
			VisionSetNaked( ent_player GetLocalClientNumber(), "zombie_theater_erooms_pentagon", 0 );
			break;
		
		case "girls_new_room":
			VisionSetNaked( ent_player GetLocalClientNumber(), "zombie_theater_eroom_girlnew", 0 );
			break;
			
		case "girls_old_room":
			VisionSetNaked( ent_player GetLocalClientNumber(), "zombie_theater_eroom_girlold", 0 );
			break;
			
		default:
			VisionSetNaked( ent_player GetLocalClientNumber(), "zombie_theater", 0 );
			break;	
	}

}

eeroom_visionset_off( ent_player )
{
	VisionSetNaked( ent_player GetLocalClientNumber(), "zombie_theater", 0 );
}

// DSM: init the lights that swap when the power is turned on
theater_light_model_swap_init()
{
	// lights
	players = getlocalplayers();
	
	for( i = 0; i < players.size; i++ )
	{
		theater_light_models = GetEntArray( i,  "model_lights_on", "targetname" );
	
		if( IsDefined( theater_light_models ) && theater_light_models.size > 0 )
		{
			array_thread( theater_light_models, ::theater_light_model_swap );
		}
	}
	

}

// DSM: swap a model light with the on version when the power is switched
theater_light_model_swap()
{
	level waittill( "ZPO" );
	
	if( self.model == "lights_hang_single" )
	{
		self SetModel( "lights_hang_single_on_nonflkr" );
	}
	else if( self.model == "zombie_zapper_cagelight" )
	{
		self SetModel( "zombie_zapper_cagelight_on" );
	}

}

