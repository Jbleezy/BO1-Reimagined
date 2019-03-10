#include maps\_utility; 
#include common_scripts\utility;

main()
{
	footsteps(); 
	scriptedFX();
	precacheFX();
	level thread wind_settings();
	maps\createfx\zombie_cod5_sumpf_fx::main();


/////////////////////////////////////////	
	// Austin - comment out for now until we can clientside
	//level thread post_lights();
///////////////////////////////////////

}

footsteps()
{
	animscripts\utility::setFootstepEffect( "asphalt",    LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "brick",      LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "carpet",     LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "cloth",      LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "concrete",   LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "dirt",       LoadFx( "bio/player/fx_footstep_sand" ) );
	animscripts\utility::setFootstepEffect( "foliage",    LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "gravel",     LoadFx( "bio/player/fx_footstep_sand" ) );
	animscripts\utility::setFootstepEffect( "grass",      LoadFx( "bio/player/fx_footstep_sand" ) );
	animscripts\utility::setFootstepEffect( "metal",      LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "mud",        LoadFx( "bio/player/fx_footstep_mud" ) );
	animscripts\utility::setFootstepEffect( "paper",      LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "plaster",    LoadFx( "bio/player/fx_footstep_dust" ) );
	animscripts\utility::setFootstepEffect( "rock",       LoadFx( "bio/player/fx_footstep_sand" ) );
	animscripts\utility::setFootstepEffect( "sand",       LoadFx( "bio/player/fx_footstep_sand" ) );
	animscripts\utility::setFootstepEffect( "water",      LoadFx( "bio/player/fx_footstep_water" ) );
	animscripts\utility::setFootstepEffect( "wood",       LoadFx( "bio/player/fx_footstep_dust" ) );
}

scriptedFX()
{

////////////////////////////////////////////////////	
	//light 
	level._effect["hanging_light_fx"] = loadfx("env/light/fx_glow_hanginglamp");

	level._effect["large_ceiling_dust"]		= LoadFx( "env/dirt/fx_dust_ceiling_impact_lg_mdbrown" );
	level._effect["poltergeist"]			= LoadFx( "maps/zombie/fx_zombie_debris_removal" );
	
	level._effect["lght_marker_old"] 		= Loadfx("maps/zombie/fx_zombie_factory_marker");
	level._effect["lght_marker"]			= Loadfx("maps/zombie/fx_zombie_factory_marker");
	level._effect["lght_marker_flare"]		= Loadfx("maps/zombie/fx_zombie_factory_marker_fl");
	
  level._effect["betty_explode"]			= loadfx("weapon/bouncing_betty/fx_explosion_betty_generic");
	level._effect["betty_trail"]				= loadfx("weapon/bouncing_betty/fx_betty_trail");
	//level._effect["trap_fire"]			= Loadfx("maps/zombie/fx_zombie_fire_trp");
	level._effect["trap_log"]		= Loadfx("maps/zombie/fx_zombie_log_trp");
	//level._effect["trap_blade"]		= Loadfx("maps/zombie/fx_zombie_chopper_trp");
  //level._effect["dog_entrance_start"]			= Loadfx("maps/zombie/fx_zombie_dog_gate_start");
	//level._effect["dog_entrance_looping"]			= Loadfx("maps/zombie/fx_zombie_dog_gate_looping");
	//level._effect["dog_entrance_ending"]  = Loadfx("maps/zombie/fx_zombie_dog_gate_end");
	level._effect["stub"]               = loadfx("misc/fx_zombie_perk_lottery");
	level._effect["zombie_perk_start"] = Loadfx("misc/fx_zombie_perk_lottery_start");
	level._effect["zombie_perk_flash"] = Loadfx("misc/fx_zombie_perk_lottery_flash");
	level._effect["zombie_perk_end"] = Loadfx("misc/fx_zombie_perk_lottery_end");
	level._effect["zombie_perk_4th"] = Loadfx("misc/fx_zombie_perk_lottery_4");

	//level._effect["chopper_blur"]	                = loadfx("maps/zombie/fx_zombie_chopper_trp_blur");
}
// Global Wind Settings
wind_settings()
{
	// These values are supposed to be in inches per second.
	SetSavedDvar( "wind_global_vector", "171 -140 0" ); // (171, -140) = 13.3 mph w/ a normal of -0.9 at hi_altitude
	SetSavedDvar( "wind_global_low_altitude", 40 );
	SetSavedDvar( "wind_global_hi_altitude", 940 );
	SetSavedDvar( "wind_global_low_strength_percent", 0.05 ); //.3 is 4mph at low altitude

	// Add a while loop to vary the strength of the wind over time.
}

precacheFX()
{
	level._effect["mp_fire_small_detail"]						    = loadfx("maps/mp_maps/fx_mp_fire_small_detail");	
	level._effect["mp_fire_small"]							        = loadfx("maps/mp_maps/fx_mp_fire_small");
	level._effect["mp_fire_medium"]							        = loadfx("maps/mp_maps/fx_mp_fire_medium");	
	level._effect["mp_fire_large"]							        = loadfx("maps/mp_maps/fx_mp_fire_large");
	level._effect["mp_light_glow_lantern"]		          = loadfx("maps/mp_maps/fx_mp_light_glow_lantern");
	level._effect["mp_smoke_ambiance_indoor"]					  = loadfx("maps/mp_maps/fx_mp_smoke_ambiance_indoor");
	level._effect["mp_smoke_ambiance_indoor_misty"]	    = loadfx("maps/mp_maps/fx_mp_smoke_ambiance_indoor_misty");	
	level._effect["mp_smoke_ambiance_indoor_sm"]	      = loadfx("maps/mp_maps/fx_mp_smoke_ambiance_indoor_sm");	
  level._effect["fx_fog_low_floor_sm"]			          = loadfx("env/smoke/fx_fog_low_floor_sm");	
	level._effect["mp_smoke_column_tall"]					      = loadfx("maps/mp_maps/fx_mp_smoke_column_tall");	
	level._effect["mp_smoke_column_short"]						  = loadfx("maps/mp_maps/fx_mp_smoke_column_short");	
	level._effect["mp_fog_rolling_large"]					      = loadfx("maps/mp_maps/fx_mp_fog_rolling_thick_large_area");	
	level._effect["mp_fog_rolling_small"]					      = loadfx("maps/mp_maps/fx_mp_fog_rolling_thick_small_area");
	level._effect["mp_flies_carcass"]                   = loadfx("maps/mp_maps/fx_mp_flies_carcass");	
	level._effect["mp_insects_swarm"]							      = loadfx("maps/mp_maps/fx_mp_insect_swarm");
	level._effect["mp_insects_lantern"]							    = loadfx("maps/mp_maps/fx_mp_insects_lantern");
	level._effect["mp_firefly_ambient"]						  	  = loadfx("maps/mp_maps/fx_mp_firefly_ambient");
	level._effect["mp_firefly_swarm"]							      = loadfx("maps/mp_maps/fx_mp_firefly_swarm");
	level._effect["mp_maggots"]						  	          = loadfx("maps/mp_maps/fx_mp_maggots");
	level._effect["mp_falling_leaves_elm"]				      = loadfx("maps/mp_maps/fx_mp_falling_leaves_elm");
  level._effect["god_rays_dust_motes"]			          = loadfx("env/light/fx_light_god_rays_dust_motes");
  level._effect["light_ceiling_dspot"]			          = loadfx("env/light/fx_ray_ceiling_amber_dim_sm");
  level._effect["fx_bats_circling"]			              = loadfx("bio/animals/fx_bats_circling");
  level._effect["fx_bats_ambient"]							      = loadfx("maps/mp_maps/fx_bats_ambient");
  level._effect["mp_fire_torch"]							        = loadfx("maps/mp_maps/fx_mp_fire_torch");
	level._effect["mp_dragonflies"]                     = loadfx("bio/insects/fx_insects_dragonflies_ambient");
	level._effect["fx_mp_ray_moon_xsm_near"]            = loadfx("maps/mp_maps/fx_mp_ray_moon_xsm_near");  	   
	level._effect["fx_meteor_ambient"]							    = loadfx("maps/zombie/fx_meteor_ambient");
	level._effect["fx_meteor_flash"]							      = loadfx("maps/zombie/fx_meteor_flash");
	level._effect["fx_meteor_flash_spawn"]							= loadfx("maps/zombie/fx_meteor_flash_spawn");	 
  level._effect["fx_meteor_hotspot"]						    	= loadfx("maps/zombie/fx_meteor_hotspot");

	
	level._effect["zapper"]							= loadfx("misc/fx_zombie_electric_trap");
	
	level._effect["zapper_light_ready"] = loadfx("misc/fx_zombie_zapper_light_green");
	level._effect["zapper_light_notready"] = loadfx("misc/fx_zombie_zapper_light_red");
	level._effect["switch_sparks"]			= loadfx("env/electrical/fx_elec_wire_spark_burst");
	
	level._effect["elec_md"] 			= loadfx("env/electrical/fx_elec_player_md");
	level._effect["elec_sm"] 			= loadfx("env/electrical/fx_elec_player_sm");
	level._effect["elec_torso"] 		= loadfx("env/electrical/fx_elec_player_torso");	
	
	//Special water rise fx
	level._effect["rise_burst_water_swmp"]		  	= LoadFX("maps/zombie/fx_zombie_body_wtr_burst_smpf");
	level._effect["rise_billow_water_swmp"]			= LoadFX("maps/zombie/fx_zombie_body_wtr_billow_smpf");
	
	//broken
	level._effect["fx_light_god_ray_sm_sumpf_warm_v1"] 		= loadfx("env/light/fx_light_god_ray_sm_sumpf_warm_v1");

}


/*------------------------------------
swinging lamp on post
------------------------------------*/
post_lights()
{
	//grab the lantern models
	lanterns = getentarray("post_lamp","targetname");
	
	array_thread(lanterns,::swing_lanterns);	



}

swing_lanterns()
{
	org_angles = self.angles;
	org_pos = self.origin;
	
	while(1)
	{
		self rotateto(self.angles + (randomintrange(-5,5),randomintrange(-5,5),0),randomfloatrange(.5,1));
		self waittill("rotatedone");
		self rotateto(org_angles,randomfloatrange(.5,1));
		self waittill("rotatedone");
			
		
		//self physicslaunch ( self.origin, (randomintrange(-20,20),randomintrange(-20,20),randomintrange(-20,20)) );
	}
}
