//
// file: zombie_theater_teleporter.csc
// description: clientside post-teleport effects
// scripter: seibert
//

#include clientscripts\_utility;
#include clientscripts\_music;

main()
{
	level thread setup_teleport_aftereffects();
	level thread wait_for_black_box();
	level thread wait_for_teleport_aftereffect();
	level thread setup_teleporter_screen();
	level thread pack_clock_init();
}

//	DCS: extra_cam system for portals.
setup_teleporter_screen()
{
	waitforclient( 0 );

	level.extraCamActive = false;
	level thread start_extra_cam();
	level thread stop_extra_cam();
	wait(.5);
	level notify("camera_stop");
}

setup_teleport_aftereffects()
{
	waitforclient( 0 );

	level.teleport_ae_funcs = [];
	/*if( getlocalplayers().size == 1 )
	{
		level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_theater_teleporter::teleport_aftereffect_fov;
	}*/
	//level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_theater_teleporter::teleport_aftereffect_shellshock;
	//level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_theater_teleporter::teleport_aftereffect_shellshock_electric;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_theater_teleporter::teleport_aftereffect_bw_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_theater_teleporter::teleport_aftereffect_red_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_theater_teleporter::teleport_aftereffect_flashy_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_theater_teleporter::teleport_aftereffect_flare_vision;
}

wait_for_black_box()
{
	secondClientNum = -1;
	while( true )
	{
		level waittill( "black_box_start", localClientNum );
		assert( isDefined( localClientNum ) );
		savedVis = GetVisionSetNaked( localClientNum );
		VisionSetNaked( localClientNum, "default", 0 );
		while( secondClientNum != localClientNum )
		{
			level waittill( "black_box_end", secondClientNum );
		}
		VisionSetNaked( localClientNum, savedVis, 0 );
	}
}

wait_for_teleport_aftereffect()
{
	while( true )
	{
		level waittill( "teleport_ae_start", localClientNum );
		if( GetDvar( #"theaterAftereffectOverride" ) == "-1" )
		{
			self thread [[ level.teleport_ae_funcs[RandomInt(level.teleport_ae_funcs.size)] ]]( localClientNum );
		}
		else
		{
			self thread [[ level.teleport_ae_funcs[int(GetDvar( #"theaterAftereffectOverride" ))] ]]( localClientNum );
		}
	}
}

teleport_aftereffect_shellshock( localClientNum )
{
	wait( 0.05 );
}

teleport_aftereffect_shellshock_electric( localClientNum )
{
	wait( 0.05 );
}

teleport_aftereffect_fov( localClientNum )
{
	println( "***FOV Aftereffect***\n" );

	start_fov = 30;
	end_fov = 65;
	duration = 0.5;

	for( i = 0; i < duration; i += 0.017 )
	{
		fov = start_fov + (end_fov - start_fov)*(i/duration);
		SetClientDvar( "cg_fov", fov );
		realwait( 0.017 );
	}
}

teleport_aftereffect_bw_vision( localClientNum )
{
	println( "***B&W Aftereffect***\n" );
	savedVis = GetVisionSetNaked( localClientNum );
	VisionSetNaked( localClientNum, "cheat_bw_invert_contrast", 0.4 );
	realwait( 1.25 );
	VisionSetNaked( localClientNum, savedVis, 1 );
}

teleport_aftereffect_red_vision( localClientNum )
{
	println( "***Red Aftereffect***\n" );
	savedVis = GetVisionSetNaked( localClientNum );
	VisionSetNaked( localClientNum, "zombie_turned", 0.4 );
	realwait( 1.25 );
	VisionSetNaked( localClientNum, savedVis, 1 );
}

teleport_aftereffect_flashy_vision( localClientNum )
{
	println( "***Flashy Aftereffect***\n" );
	savedVis = GetVisionSetNaked( localClientNum );
	VisionSetNaked( localClientNum, "cheat_bw_invert_contrast", 0.1 );
	realwait( 0.4 );
	VisionSetNaked( localClientNum, "cheat_bw_contrast", 0.1 );
	realwait( 0.4 );
	VisionSetNaked( localClientNum, "cheat_invert_contrast", 0.1 );
	realwait( 0.4 );
	VisionSetNaked( localClientNum, "cheat_contrast", 0.1 );
	realwait( 0.4 );
	VisionSetNaked( localClientNum, savedVis, 5 );
}

teleport_aftereffect_flare_vision( localClientNum )
{
	println( "***Flare Aftereffect***\n" );
	savedVis = GetVisionSetNaked( localClientNum );
	VisionSetNaked( localClientNum, "flare", 0.4 );
	realwait( 1.25 );
	VisionSetNaked( localClientNum, savedVis, 1 );
}

//-------------------------------------------------------------------------------
//	DCS: EXTRA CAM for portal jumping
//	to show where going to.
//-------------------------------------------------------------------------------

start_extra_cam()
{
	while(1)
	{
		level waittill("camera_start", localClientNum);
		if( level.extraCamActive == false )
		{
			level.extraCamActive = true;
			level.cameraEnt = GetEnt( localClientNum, "theater_extracam", "targetname" );
			level.cameraEnt isExtraCam( 0 );

			level.cam_corona = Spawn( localClientNum, level.cameraEnt.origin + (0, 1, 0), "script_model" );
			level.cam_corona SetModel( "tag_origin" );
			level.cam_corona.angles = level.cameraEnt.angles;

			PlayFxOnTag( localClientNum, level._effect["fx_mp_light_lamp"], level.cam_corona, "tag_origin" );

			//mp_light_lamp
			//zombie_theater_projector_beam
		}
	}
}

stop_extra_cam()
{
	while(1)
	{
		level waittill("camera_stop");

		if( level.extraCamActive == true && isdefined( level.cameraEnt ) )
		{
			stopextracam( 0 );
			level.extraCamActive = false;
			if(IsDefined(level.cam_corona))
			{
				level.cam_corona Delete();
			}
		}
	}
}

//-------------------------------------------------------------------------------
//	DCS: pack a punch clock set to actual time
//	ripped most from _ambient.csc, no second hand that is the timer handled
//	on the server for accuracy.
//-------------------------------------------------------------------------------

pack_clock_init()
{

	level waittill( "pack_clock_start", clientNum );

	// the format should be an array (hour, min, sec), military time
	//	if we pass in a 1 then we'll get GMT 0 London time, else we get the local time on the kit
	curr_time = GetSystemTime();

	// put the hands in the right place
	hours = curr_time[0];
	if( hours > 12 )
	{
		hours -= 12;
	}
	if( hours == 0 )
	{
		hours = 12;
	}
	minutes = curr_time[1];
	seconds = curr_time[2];

	// set the starting time
	// hoping that all of the hands start pointing straight up at 12
	// each hour is 30 degrees of rotation ...
	//	it should also rotate a little bit each time the minute hand moves
	//	the math is 30 degrees of rotations in 3600 seconds (1 hour)

	hour_hand = GetEnt(clientNum, "zom_clock_hour_hand", "targetname");
	hour_values = [];
	hour_values["hand_time"] = hours;
	hour_values["rotate"] = 30;
	hour_values["rotate_bit"] = 30 / 3600;
	// we need to do the first rotation based on the beginning time, if we don't do this the time will look like it's off a little bit
	hour_values["first_rotate"] = ((minutes * 60) + seconds) * hour_values["rotate_bit"];

	// each minute is 6 degrees of rotation ...
	//	it should also rotate a little bit each time the second hand moves
	//	the math is 6 degrees of rotations in 60 seconds (1 minute)

	minute_hand = GetEnt(clientNum, "zom_clock_minute_hand", "targetname");
	minute_values = [];
	minute_values["hand_time"] = minutes;
	minute_values["rotate"] = 6;
	minute_values["rotate_bit"] = 6 / 60;
	// we need to do the first rotation based on the beginning time, if we don't do this the time will look like it's off a little bit
	minute_values["first_rotate"] = seconds * minute_values["rotate_bit"];

	if( IsDefined(hour_hand) )
	{
		hour_hand thread pack_clock_run( hour_values );

	}
	if( IsDefined(minute_hand) )
	{
		minute_hand thread pack_clock_run( minute_values );
	}
}

pack_clock_run(time_values) // self == either hour hand, minute hand, or second hand
{
	self endon("entityshutdown");

	self RotatePitch(time_values["hand_time"] * time_values["rotate"] *-1, 0.05);
	self waittill("rotatedone");

	if( IsDefined(time_values["first_rotate"]) )
	{
		self RotatePitch(time_values["first_rotate"] *-1, 0.05);
		self waittill("rotatedone");
	}

	prev_time = GetSystemTime();

	while(true)
	{
		curr_time = GetSystemTime();
		if( prev_time != curr_time )
		{
			self RotatePitch(time_values["rotate_bit"] *-1, 0.05);

			prev_time = curr_time;
		}

		wait(1.0);
	}
}
