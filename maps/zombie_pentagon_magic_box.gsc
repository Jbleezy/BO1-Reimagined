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
	// Array must match array in zombie_pentagon.csc
	// Start at the first floor, war room then the labs

	level._pentagon_no_power = "n";
	level._pentagon_fire_sale = "f";

	level._box_locations = array(	"level1_chest", //0 
																"level1_chest2", // 1
																"level2_chest", // 2
																"start_chest", // 3
																"start_chest2", // 4
																"start_chest3" ); // 5

																
	level thread magic_box_update();
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
	
	//setclientsysstate( "box_indicator", level._pentagon_no_power ); // "no_power"

	// flag_wait( "power_on" );

	// Setup
	//box_mode = "Box Available";
	box_mode = "no_power";
	
	//"no_power";
	//"fire_sale";
	//"box_available";
	
	// Tell client 
	
	// setclientsysstate( "box_indicator", get_location_from_chest_index( level.chest_index ) );
	
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
				setclientsysstate( "box_indicator", level._pentagon_no_power );	// "no_power"
				while( !flag( "power_on" )
								&& level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 0 )
				{
					wait( 0.1 );
				}
				break;
				
			case "fire_sale":
				setclientsysstate( "box_indicator", level._pentagon_fire_sale );	// "fire sale"
				while ( level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 1 )
				{
					wait( 0.1 );
				}
				
				break;
				
			case "box_available":
				setclientsysstate( "box_indicator", get_location_from_chest_index( level.chest_index ) );
				while( !flag( "moving_chest_now" ) 
								&& level.zombie_vars[ "zombie_powerup_fire_sale_on" ] == 0 )
				{
					wait( 0.1 );
				}
				break;
				
			default:
				setclientsysstate( "box_indicator", level._pentagon_no_power );	// "no_power"
				break;
				
				
		}

		wait( 1.0 );
	}
}