#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;


main_start()
{
	SetSavedDvar( "sm_sunShadowSmallScriptPS3OnlyEnable", true );

	PreCacheModel("collision_wall_512x512x10");
	PreCacheModel("collision_geo_64x64x256");
}


main_end()
{
	// fix for pathing below player at drop offs.
	SetSavedDvar( "zombiemode_path_minz_bias", 40 );
	
	// kill brushes under stairs.
	maps\_zombiemode::spawn_kill_brush( (-866, 634, -219), 100, 60 );
	maps\_zombiemode::spawn_kill_brush( (-686, 634, -219), 100, 128 );
	
	maps\_zombiemode::spawn_kill_brush( (846, 634, -219), 100, 60 );
	maps\_zombiemode::spawn_kill_brush( (676, 634, -219), 100, 128 );

	//cliff hanging kill brush.
	maps\_zombiemode::spawn_kill_brush( (-866, -19, -380), 128, 64 );

	// above ceiling of biodome:
	maps\_zombiemode::spawn_kill_brush( (-232, 7120, 1536), 2048, 1024 );
	
	biodome_clip1 = spawn("script_model", (-646, 6427, 1277));
	biodome_clip1 setmodel("collision_wall_512x512x10");
	biodome_clip1.angles = (0, 71.2, 0);
	biodome_clip1 Hide();
	
	biodome_clip2 = spawn("script_model", (-102, 5745, 1277));
	biodome_clip2 setmodel("collision_wall_512x512x10");
	biodome_clip2.angles = (0, 322.4, 0);
	biodome_clip2 Hide();		
	
	// teleporter area collision fix.
	collision = spawn("script_model", (377, 3464, 244));
	collision setmodel("collision_wall_512x512x10");
	collision.angles = (0, 298, 0);
	collision Hide();

	collision2 = spawn("script_model", (1231, 4536, 186));
	collision2 setmodel("collision_geo_64x64x256");
	collision2.angles = (0, 0, 0);
	collision2 Hide();	
	
	level thread force_player_move_init();
	level thread force_not_prone_init();
}

force_player_move_init()
{
	trig_radius = 32;
	trig_height = 128;
	
	moveit_trig1 = Spawn( "trigger_radius", (530, 7433, 135), 0, trig_radius, trig_height );
	moveit_trig1 thread force_player_move();

	moveit_trig2 = Spawn( "trigger_radius", (-8, 6735, 166), 0, trig_radius, trig_height );
	moveit_trig2 thread force_player_move();

	moveit_trig3 = Spawn( "trigger_radius", (1.2, 5548.6, 171), 0, trig_radius, trig_height );
	moveit_trig3 thread force_player_move();	
}
	
force_player_move()
{
	while(true)
	{
		self waittill("trigger",who);
		
		if(IsPlayer(who))
		{
			who setorigin( self.origin + (-40, -40, 0));
		}	
		wait(2);
	}	
}	

force_not_prone_init()
{
	moveit_trig1 = Spawn( "trigger_radius", (44, 3725, -464), 0, 96, 128 );
	moveit_trig1 thread force_not_prone();

	moveit_trig2 = Spawn( "trigger_radius", (-794, 7672, 132), 0, 128, 128 );
	moveit_trig2 thread force_not_prone();
}
	
force_not_prone()
{
	while(true)
	{
		self waittill("trigger",who);
		
		if(IsPlayer(who))
		{
			if( who getstance() == "prone")
			{ 
				who SetStance("crouch");
			}	
			//who setorigin( self.origin + (0, -80, 0));
		}
		
		wait .1;
	}	
}	
