/* zombie_temple_sq_ptt.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 4.
 *						Pass the Torch
 *		
 * 
 * Author : 	Dan L
 * 
 */



#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility; 
#include maps\_zombiemode_sidequests;


init()
{
	flag_init("sq_ptt_dial_dialed");
	flag_init("sq_ptt_level_pulled");
	flag_init("ptt_plot_vo_done");
	
	declare_sidequest_stage("sq", "PtT", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "PtT", 5 * 60);	// 5 minute limit.
	declare_stage_asset_from_struct("sq", "PtT", "sq_ptt_trig", ::gas_volume, ::volume_trigger_thread);
	
//	declare_stage_title("sq", "PtT", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_4_TITLE");
}

debug_jet()
{
	self endon("death");
	
	struct = getstruct(self.target, "targetname");
	
	dir = AnglesToForward(struct.angles);
	
	while(1)
	{
		scale = 0.1;
		
		offset = (0,0,0);
		
		for(i = 0; i < 5; i ++)
		{
			Print3d(struct.origin + offset, "+", self.jet_color, 1, scale, 10);
			scale *= 1.7;
			offset += dir * 6;
		}
		
		wait(1);
	}
}

ignite_jet()
{
	self playsound( "evt_sq_ptt_gas_ignite" );
	exploder(self.script_int + 10);
	wait(1.0);
	stop_exploder(self.script_int);
}

gas_volume()
{
	self endon("death");
	
	self.jet_color = (0,255,0);
	
	flag_wait("sq_ptt_dial_dialed");
	
	//self thread debug_jet();
	
	self playloopsound( "evt_sq_ptt_gas_loop", 1 );
	
	exploder(self.script_int);
	
	while(1)
	{
		level waittill("napalm_death", volume);
		
		if(volume == self.script_int)
		{
			self.trigger notify("lit");
			level notify("lit");
			//self.jet_color = (255,0, 0);
			self thread ignite_jet();
			self thread play_line_on_nearby_player();
			self playloopsound( "evt_sq_ptt_gas_loop_flame", 1 );
			level._ptt_num_lit ++;
			return;
		}
	}
}

play_line_on_nearby_player()
{
	players = get_players();
	
	for(i=0;i<players.size;i++)
	{
		if( distancesquared( self.origin, players[i].origin ) <= 250*250 )
		{
			players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest4", undefined, randomintrange(2,5) );
			return;
		}
	}
}

volume_trigger_thread()
{
	self endon("death");
	self endon("lit");
	
	flag_wait("sq_ptt_dial_dialed");
	
	self thread player_line_thread();
	
	while(1)
	{
		self waittill("trigger", who);
		
		if(IsAI(who) && who.animname == "napalm_zombie")
		{
			//who.explosive_volume = self.owner_ent.script_int;
			
			level notify("napalm_death", self.owner_ent.script_int);
			return;
		}
	}
}

player_line_thread()
{
	self endon("death");
	self endon("lit");
	
	while(1)
	{
		self waittill("trigger", who);
		
		if( isPlayer( who ) )
		{
			who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest4", undefined, randomintrange(0,2) );
			return;
		}
	}
}

init_stage()
{
	level notify ("ptt_start");
	flag_clear("sq_ptt_dial_dialed");
	dial = GetEnt("sq_ptt_dial", "targetname");
	
	dial thread ptt_dial();
	
	jets = GetEntArray("sq_ptt_trig", "targetname");
	
	level._ptt_jets = jets.size;
	
	level._ptt_num_lit = 0;
	
	maps\zombie_temple_sq_brock::delete_radio();
	
	if(flag("radio_4_played"))
	{
		level thread delayed_start_skit("tt4a");
	}
	else
	{
		level thread delayed_start_skit("tt4b");
	}
	
	level thread play_choking_loop();
}

play_choking_loop()
{
	level endon("sq_PtT_over");
	
	struct = getstruct( "sq_location_ptt", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}
	
	level._ptt_sound_choking_ent = spawn( "script_origin", struct.origin );
	level._ptt_sound_choking_ent playloopsound( "evt_sq_ptt_choking_loop", 2 );
	
	flag_wait("sq_ptt_dial_dialed");
	
	level._ptt_sound_choking_ent stoploopsound( 1 );
	
	wait(1);
	
	level._ptt_sound_choking_ent delete();
	level._ptt_sound_choking_ent = undefined;
}

delayed_start_skit(skit)
{
	level thread maps\zombie_temple_sq_skits::start_skit(skit);
}

ptt_lever()
{
	level endon("sq_PtT_over");
	
	flag_clear("sq_ptt_level_pulled");
	
	if(!IsDefined(self.original_angles))
	{
		self.original_angles = self.angles;
	}
	
	self.angles = self.original_angles;
	
	while(level._ptt_num_lit < level._ptt_jets)
	{
		level waittill("lit");
		self playsound( "evt_sq_ptt_lever_ratchet" );
		self RotateRoll(-25,0.25);
		self waittill("rotatedone");
	}
	
	use_trigger = Spawn( "trigger_radius_use", self.origin, 0, 32, 72);
	use_trigger SetCursorHint( "HINT_NOICON" );	
	
	use_trigger waittill("trigger", who);
	
	use_trigger Delete();
	
	self playsound( "evt_sq_ptt_lever_pull" );
	self RotateRoll(100, 0.25);
	self waittill("rotatedone");
	
	if( isdefined( who ) )
	{
		//who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest4", undefined, 5 );
	}
	
	flag_set("sq_ptt_level_pulled");
}

ptt_story_vox( player )
{
	level endon("sq_PtT_over");
	
	struct = getstruct( "sq_location_ptt", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}
	
	level._ptt_sound_ent = spawn( "script_origin", struct.origin );
	level._ptt_sound_ent_trash = spawn( "script_origin", struct.origin );
	
	level._ptt_sound_ent playsound( "vox_egg_story_3_0", "sounddone" );
	level._ptt_sound_ent waittill( "sounddone" );
	
	//Start trash compactor sounds
	level._ptt_sound_ent_trash playsound( "evt_sq_ptt_trash_start" );
	level._ptt_sound_ent_trash playloopsound( "evt_sq_ptt_trash_loop" );
	
	level._ptt_sound_ent playsound( "vox_egg_story_3_1", "sounddone" );
	level._ptt_sound_ent waittill( "sounddone" );
	
	level._ptt_sound_ent playsound( "vox_egg_story_3_2", "sounddone" );
	level._ptt_sound_ent waittill( "sounddone" );
	
	if( isdefined( player ) )
	{
		level.skit_vox_override = true;
		player playsound( "vox_egg_story_3_3" + maps\zombie_temple_sq::get_variant_from_entity_num( player.entity_num ), "vox_egg_sounddone" );
		player waittill( "vox_egg_sounddone" );
		level.skit_vox_override = false;
	}
	
	//Reminder lines every 45 seconds until they pull the lever
	level thread ptt_story_reminder_vox( 45 );
	
	flag_wait("sq_ptt_level_pulled");
	
	level._ptt_sound_ent_trash stoploopsound( 2 );
	level._ptt_sound_ent_trash playsound( "evt_sq_ptt_trash_end" );
	
	level._ptt_sound_ent playsound( "vox_egg_story_3_8", "sounddone" );
	level._ptt_sound_ent waittill( "sounddone" );
	
	level._ptt_sound_ent playsound( "vox_egg_story_3_9", "sounddone" );
	level._ptt_sound_ent waittill( "sounddone" );
	
	flag_set("ptt_plot_vo_done");
	
	level._ptt_sound_ent_trash delete();
	level._ptt_sound_ent_trash = undefined;
	level._ptt_sound_ent delete();
	level._ptt_sound_ent = undefined;
}

ptt_story_reminder_vox( waittime )
{
	level endon("sq_PtT_over");
	
	wait( waittime );
	
	count = 4;
	
	while( !flag("sq_ptt_level_pulled") && count <= 7 )
	{
		level._ptt_sound_ent playsound( "vox_egg_story_3_" + count, "sounddone" );
		level._ptt_sound_ent waittill( "sounddone" );
		count ++;
		wait( waittime );
	}
}

stage_logic()
{
	flag_wait("sq_ptt_dial_dialed");
	
	while(level._ptt_num_lit < level._ptt_jets)
	{
		wait(0.1);
	}

	flag_wait("sq_ptt_level_pulled");
	level notify( "suspend_timer" );

	wait(5.0);
	
	level notify("raise_crystal_1");
	level notify("raise_crystal_2");
	level notify("raise_crystal_3");
	level notify("raise_crystal_4", true);
	level waittill("raised_crystal_4");	
	
	flag_wait("ptt_plot_vo_done");
	wait(5.0);
	
	stage_completed("sq", "PtT");
}

remove_exploders()
{
	stop_exploder(100);
	stop_exploder(101);
	stop_exploder(102);
	stop_exploder(103);
	
	wait_network_frame();
	
	stop_exploder(110);
	stop_exploder(111);
	stop_exploder(112);
	stop_exploder(113);
}

exit_stage(success)
{
	flag_clear("sq_ptt_dial_dialed");
	flag_clear("ptt_plot_vo_done");
	dial = GetEnt("sq_ptt_dial", "targetname");
	dial thread dud_dial_handler();
	
	ents = GetAIArray("axis");
	
	for(i = 0; i < ents.size; i ++)
	{
		if(IsDefined(ents[i].explosive_volume))
		{
			ents[i].explosive_volume = 0;
		}
	}
	
	level thread remove_exploders();
	
	if(success)
	{
		maps\zombie_temple_sq_brock::create_radio(5);
	}
	else
	{
		maps\zombie_temple_sq_brock::create_radio(4, maps\zombie_temple_sq_brock::radio4_override);
		level thread maps\zombie_temple_sq_skits::fail_skit();		
	}
	
	level.skit_vox_override = false;
	if( isdefined( level._ptt_sound_ent ) )
	{
		level._ptt_sound_ent delete();
		level._ptt_sound_ent = undefined;
	}
	
	if( isdefined( level._ptt_sound_ent_trash ) )
	{
		level._ptt_sound_ent_trash delete();
		level._ptt_sound_ent_trash = undefined;
	}
	
	if( isdefined( level._ptt_sound_choking_ent ) )
	{
		level._ptt_sound_choking_ent delete();
		level._ptt_sound_choking_ent = undefined;
	}
}

dial_trigger()
{
	level endon("ptt_start");
	level endon("sq_PtT_over");
	
	while(1)
	{
		self waittill("triggered", who);
		self.owner_ent notify("triggered", who);
	}
}

ptt_dial()
{
	level endon("sq_PtT_over");
	
	num_turned = 0;
	who = undefined;
	
	self.trigger thread dial_trigger();
	
	while(num_turned < 4)
	{
		self waittill("triggered", who);
		self playsound( "evt_sq_ptt_valve" );
		self RotateRoll(90, 0.25);
		self waittill("rotatedone");
		num_turned ++;
	}
	
	level thread ptt_story_vox( who );

	self playsound( "evt_sq_ptt_gas_release" );
	
	lever = GetEnt("sq_ptt_lever", "targetname");
	lever thread ptt_lever();
	
	flag_set("sq_ptt_dial_dialed");
}

dud_dial_handler()
{
	level endon("ptt_start");
	
	self.trigger thread dial_trigger();
	
	while(1)
	{
		self waittill("triggered");
		self playsound( "evt_sq_ptt_valve" );
		self RotateRoll(90, 0.25);
	}
}