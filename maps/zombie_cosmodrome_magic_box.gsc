#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;

//************************************************************************************
//
//	Magic Box TV location system.
//	originally developed for Pentagon by Walter Williams.
//************************************************************************************

magic_box_init()
{
	// Array must match array in zombie_cosmodrome.csc

	level._cosmodrome_no_power = "n";
	level._cosmodrome_fire_sale = "f";

	level._box_locations = array(	"start_chest", // power building roof - 0
																"chest1", // roof_connector_zone - 1
																"chest2", // centrifuge room - 2
																"base_entry_chest", // 3
																"storage_area_chest", //4
																"chest5", // catwalks - 5
																"chest6", // north pass to pack - 6
																"warehouse_lander_chest"); // 7

	level thread magic_box_update();
	level thread cosmodrome_collision_fix();
	level thread cosmodrome_maintenance_respawn_fix();
	
	SetSavedDvar( "zombiemode_path_minz_bias", 28 );
}

get_location_from_chest_index( chest_index )
{
	if( IsDefined( level.chests[ chest_index ] ) )
	{
		chest_loc = level.chests[ chest_index ].script_noteworthy;
		
		for(i = 0; i < level._box_locations.size; i ++)
		{
			if( level._box_locations[i] == chest_loc )
			{
				return i;
			}
		}
	}
	
	
	/#
	AssertMsg("Unknown chest location - " + chest_index );
	#/
}

magic_box_update()
{
	level waittill("fade_introblack");

	if(level.gamemode == "gg")
	{
		return;
	}

	// Let the level startup
	wait(1);
	
	//setclientsysstate( "box_indicator", level._cosmodrome_no_power ); // "no_power"

	box_mode = "no_power";
	
	while( 1 )
	{		
		// check where the box is
		if( ( !flag( "power_on" ) || flag( "moving_chest_now" ) )
				&& level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 0 ) //
		{
			box_mode = "no_power";
		}
		else if( IsDefined( level.zombie_vars["zombie_powerup_fire_sale_on"] ) 
						&& level.zombie_vars["zombie_powerup_fire_sale_on"] == 1 )
		{
			box_mode = "fire_sale";
		}
		else
		{
			box_mode = "box_available";
		}
		
		switch( box_mode )
		{
			case "no_power":
				setclientsysstate( "box_indicator", level._cosmodrome_no_power );	// "no_power"
				while( !flag( "power_on" )
								&& level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 0 )
				{
					wait( 0.1 );
				}
				break;
				
			case "fire_sale":
				setclientsysstate( "box_indicator", level._cosmodrome_fire_sale );	// "fire sale"
				while ( level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 1 )
				{
					wait( 0.1 );
				}
				break;
				
			case "box_available":
				setclientsysstate( "box_indicator", get_location_from_chest_index( level.chest_index ) );
				while( !flag( "moving_chest_now" ) 
								&& level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 0
								&& !flag( "launch_activated" ) )
				{
					wait( 0.1 );
				}
				break;
				
			default:
				setclientsysstate( "box_indicator", level._cosmodrome_no_power );	// "no_power"
				break;
				
				
		}

		wait( 1.0 );
	}
}

cosmodrome_collision_fix()
{
	PreCacheModel("collision_geo_256x256x256");
	PreCacheModel("collision_geo_256x256x10");
	PreCacheModel("collision_geo_64x64x256");

	collision = spawn("script_model", (-1692, 2116, -96));
	collision setmodel("collision_geo_256x256x256");
	collision.angles = (0, 0, 0);
	collision Hide();
	
	collision2 = spawn("script_model", (-1948, 2028, -197));
	collision2 setmodel("collision_geo_256x256x256");
	collision2.angles = (0, 0, 0);
	collision2 Hide();
	
	collision3 = spawn("script_model", (1033, 575, -216));
	collision3 setmodel("collision_wall_256x256x10");
	collision3.angles = (0, 90, 0);
	collision3 Hide();	

	collision4 = spawn("script_model", (1033, 202, -216));
	collision4 setmodel("collision_wall_256x256x10");
	collision4.angles = (0, 90, 0);
	collision4 Hide();	
	
	collision5 = spawn("script_model", (-2115, 1699, 153));
	collision5 setmodel("collision_geo_64x64x256");
	collision5.angles = (0, 0, 0);
	collision5 Hide();	
			
}

cosmodrome_maintenance_respawn_fix()
{
	respawn_points = GetStructArray("player_respawn_point", "targetname");
	for( i = 0; i < respawn_points.size; i++ )
	{
		if ( respawn_points[i].script_noteworthy == "storage_lander_zone" )
		{
			respawn_positions = GetStructArray(respawn_points[i].target, "targetname");
			for( j = 0; j < respawn_positions.size; j++ )
			{
				if(IsDefined(respawn_positions[j].script_int) && respawn_positions[j].script_int == 1 && respawn_positions[j].origin[0] == -159.5)
				{
					respawn_positions[j].origin = (-159.5, -1292.7, -119);
				}		
			}	
		}
	}
}		