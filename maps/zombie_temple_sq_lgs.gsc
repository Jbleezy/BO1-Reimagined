/* zombie_temple_sq_lgs.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 3.
 *						Let's Get Small.
 *		
 * 
 * Author : 	Dan L
 * 
 */



#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility; 
#include maps\_zombiemode_sidequests;

#using_animtree("fxanim_props_dlc4");

init()
{
	PrecacheVehicle("misc_freefall");
	PreCacheModel("p_ztem_glyphs_00");
	PreCacheModel("fxanim_zom_ztem_crystal_small_mod");
	PreCacheModel("p_ztem_crystal");
	
	flag_init("meteor_impact");
	
	level.scr_anim["crystal"]["spin"][0] = %fxanim_zom_ztem_crystal_small_anim;
	
	declare_sidequest_stage("sq", "LGS", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "LGS", 5 * 60);	// 5 minute limit.
//	declare_stage_title("sq", "LGS", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_3_TITLE");
	declare_stage_asset_from_struct("sq", "LGS", "sq_lgs_crystal", ::lgs_crystal);
}

init_stage()
{
	maps\zombie_temple_sq_brock::delete_radio();
	
	flag_clear("meteor_impact");
		
	level thread lgs_intro();
	
	/#
	
	if(get_players().size == 1)
	{
		get_players()[0] GiveWeapon("shrink_ray_upgraded_zm");
	}
	
	
	#/	
	
}

lgs_intro()
{
	exploder(600);
	wait(4.0);
	level thread play_intro_audio();
	exploder(601);
	level thread maps\zombie_temple_sq_skits::start_skit("tt3");
	level thread play_nikolai_farting();
	wait(2.0);

	
	wait(1.5);
	Earthquake(1, 0.8, get_players()[0].origin, 200);
	wait(1.0);
	flag_set("meteor_impact");
	
	
}

play_nikolai_farting()
{
	level endon( "sq_LGS_over" );
	
	wait(2);
	
	players = get_players();
	
	for(i=0;i<players.size;i++)
	{
		if( players[i].entity_num == 1 )
		{
			players[i] playsound( "evt_sq_lgs_fart" );
			return;
		}
	}
}

play_intro_audio()
{
	playsoundatposition( "evt_sq_lgs_meteor_incoming", ( -1680, -780, 147 ) );
	wait(3.3);
	playsoundatposition( "evt_sq_lgs_meteor_impact", ( -1229, -1642, 198 ) );
}

first_damage()
{
	self endon("death");
	self endon("first_damage_done");
	
	while(1)
	{
		self waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );
		if( isplayer( attacker ) && ( 	dmg_type == "MOD_PROJECTILE" || dmg_type == "MOD_PROJECTILE_SPLASH" 
																|| 	dmg_type == "MOD_EXPLOSIVE" || dmg_type == "MOD_EXPLOSIVE_SPLASH" 
																|| 	dmg_type == "MOD_GRENADE" || dmg_type == "MOD_GRENADE_SPLASH" ) )
		{
			self.owner_ent notify("triggered");
			attacker thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 1 );
			return;
		}
		
		if( isPlayer( attacker ) )
		{
			attacker thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 2 );
		}
	}
}

wait_for_player_to_get_close()
{
	self endon( "death" );
	self endon( "first_damage_done" );
	
	while(1)
	{
		players = get_players();
		
		for(i=0;i<players.size;i++)
		{
			if( distancesquared( self.origin, players[i].origin ) <= 500 * 500 )
			{
				players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 0 );
				return;
			}
		}
		
		wait(.1);
	}
}

report_melee_early()
{
	self endon("death");
	self endon("shrunk");
	
	while(1)
	{
		self waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );

		if( isplayer( attacker ) && dmg_type == "MOD_MELEE")
		{
			attacker thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 3 );
			wait(5.0);
		} 				
	}
}

wait_for_melee()
{
	self endon("death");
	
	while(1)
	{
		self waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );

		if( isplayer( attacker ) && dmg_type == "MOD_MELEE")
		{
			self.owner_ent notify("triggered");
			attacker thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 6 );
			return;
		} 				
	}
}


check_for_closed_slide(ent) // self == vehicle
{
	if(!flag("waterslide_open"))
	{
		self endon("death");
		self endon("reached_end_node");
		
		while(1)
		{
			self waittill("reached_node", node);
			
			if(IsDefined(node.script_noteworthy) && node.script_noteworthy == "pre_gate")
			{
				if(!flag("waterslide_open"))
				{
					players = get_players();
					for(i=0;i<players.size;i++)
					{
						if( distancesquared( self.origin, players[i].origin ) <= 500 * 500 )
						{
							players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 7 );
						}
					}
					
					self._crystal StopAnimScripted();					
					
					while(!flag("waterslide_open"))
					{
						self SetSpeedImmediate(0);
						wait(0.05);			
					}

					wait(0.5);
					
					self._origin_animate thread maps\_anim::anim_loop_aligned (self._crystal, "spin", "tag_origin_animate_jnt");
					self ResumeSpeed(12);
					return;
				}
			}
		}
	}
}

water_trail(ent)
{
	self endon("death");
	
	while(1)
	{
		self waittill("reached_node", node);
		
		if(IsDefined(node.script_int))
		{
			if(node.script_int == 1)
			{
				ent setclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_WATER_TRAIL);
			}
			else if(node.script_int == 0)
			{
				ent clearclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_WATER_TRAIL);
			}
		}
	}
}

lgs_crystal()
{
	self endon("death");
	
	self Hide();
	
	flag_wait("meteor_impact");
	
	self Show();
		
	self.trigger = Spawn("trigger_damage", self.origin, 0, 32, 72);	// Will be cleaned up by the stage tear down.
	self.trigger.owner_ent = self;
	
	self.trigger thread first_damage();
	self.trigger thread wait_for_player_to_get_close();
	
	exploder(602);
	//self Solid();
	
	self waittill("triggered");
	self.trigger notify("first_damage_done");
	
	stop_exploder(602);
	
	self playsound( "evt_sq_lgs_crystal_pry" );
	
	target = self.target;
	
	while(IsDefined(target))
	{
		struct = getstruct(target, "targetname");
		
		time = struct.script_float;
		
		if(!IsDefined(time))
		{
			time = 1.0;
		}
		
		self moveto(struct.origin, time, time/10);
		self waittill("movedone");
		self playsound( "evt_sq_lgs_crystal_hit1" );
		target = struct.target;
	}
	
	self playsound( "evt_sq_lgs_crystal_land" );
	
	self.trigger.origin = self.origin;
	self.trigger thread report_melee_early();
	maps\_zombiemode_weap_shrink_ray::add_shrinkable_object(self);
	self waittill("shrunk");
	
	//Grabbing which player fired the shot and playing a line on him
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		currentweapon = players[i] GetCurrentWeapon();
		if( ( currentweapon == "shrink_ray_zm" ) || ( currentweapon == "shrink_ray_upgraded_zm" ) )
		{
			players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 4 );
		}
	}
	
	self playsound( "evt_sq_lgs_crystal_shrink" );
	
	self SetModel("fxanim_zom_ztem_crystal_small_mod");
	
	vn = getvehiclenode("sq_lgs_node_start","targetname");
	
	self.origin = vn.origin;
	
	self.trigger notify("shrunk");
	maps\_zombiemode_weap_shrink_ray::remove_shrinkable_object(self);

	self.trigger thread wait_for_melee();
	self waittill("triggered");
	
	self playsound( "evt_sq_lgs_crystal_knife" );
	self playloopsound( "evt_sq_lgs_crystal_roll", 2 );
	
	self.trigger trigger_off();
	self NotSolid();
	
	self UseAnimTree(#animtree);
	self.animname = "crystal";
	
	vehicle = SpawnVehicle("p_ztem_glyphs_00", "crystal_mover", "misc_freefall", self.origin, self.angles);
	vehicle Hide();
	vehicle._crystal = self;
	
	level._lgs_veh = vehicle;
	
	wait_network_frame();
	
	origin_animate = Spawn( "script_model", vehicle.origin );
	origin_animate SetModel( "tag_origin_animate" );
//		origin_animate.animname = actor.name;
//  	origin_animate UseAnimTree( level._actors[actor.name].tree );
	self LinkTo( origin_animate, "origin_animate_jnt", (0,0,0), (90,0,0) );
	
	origin_animate LinkTo(vehicle);
	
	origin_animate thread maps\_anim::anim_loop_aligned (self, "spin", "tag_origin_animate_jnt");
	
	vehicle attachpath( getvehiclenode("sq_lgs_node_start","targetname"));	
	
	vehicle startpath();
	vehicle._origin_animate = origin_animate;
		
	vehicle thread water_trail(self);
	vehicle thread check_for_closed_slide(self);
	
	vehicle waittill("reached_end_node");	
	self StopAnimScripted();
	self Unlink();
	self thread crystal_bobble();
	
	vehicle Delete();
	origin_animate Delete();
	
	flag_wait("minecart_geyser_active");
	self notify("kill_bobble");
	
	self setclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_WATER_TRAIL);
	self moveto(self.origin + (0,0,4000), 2, 0.1);
	
	level notify( "suspend_timer" );
	level notify("raise_crystal_1");
	level notify("raise_crystal_2");
	level notify("raise_crystal_3", true);
	level waittill("raised_crystal_3");
	self clearclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_WATER_TRAIL);
	wait(2);
	
	holder = GetEnt("empty_holder", "script_noteworthy");
	
	self.origin = (holder.origin[0], holder.origin[1], self.origin[2]);
	self SetModel("p_ztem_crystal");
	
	playsoundatposition( "evt_sq_lgs_crystal_incoming", (holder.origin[0], holder.origin[1], holder.origin[2] + 134) );
	self moveto((holder.origin[0], holder.origin[1], holder.origin[2] + 134), 2);
	
	self waittill("movedone");
	
	self stoploopsound( 1 );
	self playsound( "evt_sq_lgs_crystal_landinholder" );
	
	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest3", undefined, 8 );
	
	level notify("crystal_dropped");
	self Hide();
		
	wait(5.0);
	
	stage_completed("sq", "LGS");
}

crystal_spin()
{
	self endon( "death" );
	self endon( "kill_bobble" );
	
	while(1)
	{
		t = RandomFloatRange(0.2,0.8);
		self RotateTo((180+RandomFloat(180), 300 + RandomFloat(60), 180+RandomFloat(180)), t);
		wait t;
	}
}

crystal_bobble()
{
	self endon( "death" );
	self endon( "kill_bobble" );
	
	self thread crystal_spin();
	
	node = GetVehicleNode("crystal_end", "script_noteworthy");
	
	bottom_pos = node.origin + (0,0,4);
	top_pos = bottom_pos + (0,0,3);
	
	while(1)
	{
		self moveto(top_pos + (0,0,RandomFloat(3)), 0.2 + RandomFloat(0.1), 0.1);
		self waittill("movedone");
		self moveto(bottom_pos + (0,0,RandomFloat(5)), 0.05 + RandomFloat(0.07),0,0.03);
		self waittill("movedone");
	}
}

stage_logic()
{
}

exit_stage(success)
{
	if(IsDefined(level._lgs_veh))
	{
		if(IsDefined(level._lgs_veh._origin_animate))
		{
			level._lgs_veh._origin_animate Delete();
		}
		level._lgs_veh Delete();
	}
	
	level._lgs_veh = undefined;
	
	if(success)
	{
		maps\zombie_temple_sq_brock::create_radio(4, maps\zombie_temple_sq_brock::radio4_override);
	}
	else
	{
		maps\zombie_temple_sq_brock::create_radio(3);
		level thread maps\zombie_temple_sq_skits::fail_skit();		
	}
}