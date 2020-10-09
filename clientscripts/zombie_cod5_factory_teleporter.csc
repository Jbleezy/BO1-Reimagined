//
// file: zombie_cod5_factory_teleporter.csc
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
}

setup_teleport_aftereffects()
{
	waitforclient( 0 );

	level.teleport_ae_funcs = [];
	/*if( getlocalplayers().size == 1 )
	{
		level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_cod5_factory_teleporter::teleport_aftereffect_fov;
	}*/
	//level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_cod5_factory_teleporter::teleport_aftereffect_shellshock;
	//level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_cod5_factory_teleporter::teleport_aftereffect_shellshock_electric;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_cod5_factory_teleporter::teleport_aftereffect_bw_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_cod5_factory_teleporter::teleport_aftereffect_red_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_cod5_factory_teleporter::teleport_aftereffect_flashy_vision;
	level.teleport_ae_funcs[level.teleport_ae_funcs.size] = clientscripts\zombie_cod5_factory_teleporter::teleport_aftereffect_flare_vision;
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
		level waittill( "tae", localClientNum );
		if( GetDvar( "factoryAftereffectOverride" ) == "-1" )
		{
			self thread [[ level.teleport_ae_funcs[RandomInt(level.teleport_ae_funcs.size)] ]]( localClientNum );
		}
		else
		{
			self thread [[ level.teleport_ae_funcs[int(GetDvar( "factoryAftereffectOverride" ))] ]]( localClientNum );
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
