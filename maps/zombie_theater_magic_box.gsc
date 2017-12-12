#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;

//************************************************************************************
//
//	Changes lights of Map for location
//
//************************************************************************************

magic_box_init()
{
	// Array must match array in zombie_theater.csc
	// Start at 'start_chest' then order clockwise - finishing in the middle.
	
	// DCS: added to fix non-attacking dogs in alley, placed here because smallest theater specific script file.
	level.dog_melee_range = 120;	
	
	level._BOX_INDICATOR_NO_LIGHTS = -1;
	level._BOX_INDICATOR_FLASH_LIGHTS_MOVING = 99;
	level._BOX_INDICATOR_FLASH_LIGHTS_FIRE_SALE = 98;	
	
	level._box_locations = array(	"start_chest",
																"foyer_chest",
																"crematorium_chest",
																"alleyway_chest",
																"control_chest",
																"stage_chest",
																"dressing_chest",
																"dining_chest",
																"theater_chest");
																
	
	level thread magic_box_update();
	level thread watch_fire_sale();
}

get_location_from_chest_index(chest_index)
{
	chest_loc = level.chests[ chest_index ].script_noteworthy;
	
	for(i = 0; i < level._box_locations.size; i ++)
	{
		if(level._box_locations[i] == chest_loc)
		{
			return i;
		}
	}
	
	AssertMsg("Unknown chest location - " + chest_loc);
}

magic_box_update()
{
	// Let the level startup
	wait(2);

	if(level.gamemode == "gg")
	{
		return;
	}

	flag_wait( "power_on" );

	// Setup
	box_mode = "Box Available";
	
	// Tell client 
	
	setclientsysstate( "box_indicator", get_location_from_chest_index(level.chest_index) );
	
	while( 1 )
	{
		switch( box_mode )
		{
			// Waiting for the Box to Move
			case "Box Available":
				if( flag("moving_chest_now") )
				{
				
					// Tell client 
					
					setclientsysstate( "box_indicator", level._BOX_INDICATOR_FLASH_LIGHTS_MOVING);	// flash everything.
				
					// Next Mode
					box_mode = "Box is Moving";
				}
			break;


			case "Box is Moving":
				// Waiting for the box to finish its move
				while( flag("moving_chest_now") )
				{
					wait(0.1);
				}

				// Tell client 
				setclientsysstate( "box_indicator", get_location_from_chest_index(level.chest_index));

				box_mode = "Box Available";

				break;
		}

		wait( 0.5 );
	}
}

watch_fire_sale()
{
	while ( 1 )
	{
		level waittill( "powerup fire sale" );
		setclientsysstate( "box_indicator", level._BOX_INDICATOR_FLASH_LIGHTS_FIRE_SALE );	// flash everything. 

		while ( level.zombie_vars["zombie_powerup_fire_sale_time"] > 0)
		{
			wait( 0.1 );
		}
				
		setclientsysstate( "box_indicator", get_location_from_chest_index(level.chest_index));
	}
}



//ESM - added for green light/red light functionality for magic box
turnLightGreen(name, playfx)
{
	zapper_lights = getentarray( name, "script_noteworthy" );
	
	for(i=0;i<zapper_lights.size;i++)
	{
		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}
		
		if ( isDefined( playfx ) && playfx )
		{
			zapper_lights[i] setmodel("zombie_zapper_cagelight_green");	
			zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_green", 2, "script_model", ( zapper_lights[i].origin[0], zapper_lights[i].origin[1], zapper_lights[i].origin[2] - 10 ) );
			zapper_lights[i].fx setmodel("tag_origin");
			zapper_lights[i].fx.angles = zapper_lights[i].angles;
			playfxontag(level._effect["boxlight_light_ready"],zapper_lights[i].fx,"tag_origin");
		}
		else
			zapper_lights[i] setmodel("zombie_zapper_cagelight");	
	}
}

turnLightRed(name, playfx)
{	
	zapper_lights = getentarray( name, "script_noteworthy" );

	for(i=0;i<zapper_lights.size;i++)
	{
		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}
		
		if ( isDefined( playfx ) && playfx )
		{
			zapper_lights[i] setmodel("zombie_zapper_cagelight_red");	
			zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_red", 2, "script_model", ( zapper_lights[i].origin[0], zapper_lights[i].origin[1], zapper_lights[i].origin[2] - 10 ) );
			zapper_lights[i].fx setmodel("tag_origin");
			zapper_lights[i].fx.angles = zapper_lights[i].angles;
			playfxontag(level._effect["boxlight_light_notready"],zapper_lights[i].fx,"tag_origin");
		}
		else
			zapper_lights[i] setmodel("zombie_zapper_cagelight");
	}
}