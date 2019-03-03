/* zombie_temple_sq.gsc
 *
 * Purpose : 	Sidequest declaration and global side-quest logic for zombie_temple.
 *
 *
 * Author : 	Dan L
 *
 */



#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_sidequests;

/*delete_sq_ents(name)
{
	ents = GetEntArray(name, "targetname");

	for(i = 0; i < ents.size; i ++)
	{
		ents[i] Delete();
	}
}*/

init()
{
	PreCacheModel("p_ztem_skeleton");
	PreCacheModel("p_ztem_meteorite_small");
	PreCacheModel("p_ztem_meteorite");

	flag_init("pap_override");
	flag_init("radio_9_played");
	flag_init("gongs_resonating");
	flag_init("trap_destroyed");
	flag_init("radio_7_played");
	flag_init("meteorite_shrunk");
	flag_init("doing_bounce_around");

//	SetDvar("sidequest", 1);

/*	if(GetDvarInt("sidequest") == 0)
	{
		delete_sq_ents("sq_sundial");
		delete_sq_ents("sq_sundial_button");
		delete_sq_ents("sq_ptt_dial");
		delete_sq_ents("sq_bttp2_dial");
		delete_sq_ents("sq_spiketrap");
		delete_sq_ents("sq_gong");
		delete_sq_ents("sq_dgcwf_trig");
		delete_sq_ents("sq_wall");
		delete_sq_ents("sq_altar");
		delete_sq_ents("sq_anti_115");
		delete_sq_ents("sq_meteorite");
		return;
	} */

	level._crystal_bounce_paths = [];

	level._crystal_bounce_paths[1] = array(2,4,3,5,6, "R");
	level._crystal_bounce_paths[2] = array(1,2,3,4,1, "R");
	level._crystal_bounce_paths[3] = array(4,3,1,3,5, "R");
	level._crystal_bounce_paths[4] = array(1,3,2,6,5, "R");
	level._crystal_bounce_paths[5] = array(6,5,6,1,3,5, "R");
	level._crystal_bounce_paths[6] = array(5,6,1,4,2,1,3, "M");

	PreCacheModel("p_ztem_crystal_and_holder");
	PreCacheModel("p_ztem_crystal_holder");
	PreCacheModel("p_ztem_dynamite");
	PreCacheModel("p_ztem_temple_wall_broken");
	PreCacheModel("p_ztem_temple_wall_solid");

	maps\zombie_temple_sq_brock::init();

	maps\zombie_temple_sq_skits::init_skits();

	declare_sidequest("sq", ::init_sidequest, undefined, ::complete_sidequest, ::generic_stage_start, ::generic_stage_complete);
//	sidequest_uses_teleportation("sq");
	declare_sidequest_asset("sq", "sq_sundial", ::sundial_monitor);
	declare_sidequest_asset("sq", "sq_sundial_button", ::sundial_button);
	declare_sidequest_asset("sq", "sq_ptt_dial", ::ptt_dial_handler);
	declare_sidequest_asset("sq", "sq_bttp2_dial", ::bttp2_dial_handler);
	declare_sidequest_asset("sq", "sq_spiketrap");
	declare_sidequest_asset_from_struct("sq", "sq_crystals", ::crystal_handler);
	declare_sidequest_asset("sq", "sq_gong", ::gong_handler, ::gong_trigger_handler);
	declare_sidequest_icon("sq", "vril", "zom_hud_icon_vril");
	declare_sidequest_icon( "sq", "dynamite", "zom_hud_icon_dynamite" );
	declare_sidequest_icon( "sq", "anti115", "zom_hud_icon_meteor" );

	maps\zombie_temple_sq_oafc::init();	// Done.
	maps\zombie_temple_sq_dgcwf::init();	// Done
	maps\zombie_temple_sq_lgs::init();	// Done
	maps\zombie_temple_sq_ptt::init();		// Done
	maps\zombie_temple_sq_std::init();		// Done
	maps\zombie_temple_sq_bttp::init();		// Done
	maps\zombie_temple_sq_bttp2::init();		// Done
	maps\zombie_temple_sq_bag::init();		// Done

	level._num_gongs = 0;

	randomize_gongs();

	precache_sidequest_assets();

	trig = GetEnt("sq_dgcwf_trig", "targetname");
	trig trigger_off();

	/#
	level thread force_eclipse_watcher();
	#/

	//level thread raise_all_crystals();

	level thread gong_watcher();

	level._sq_perk_array = array("specialty_armorvest","specialty_quickrevive","specialty_fastreload","specialty_rof","specialty_endurance","specialty_flakjacket","specialty_deadshot");

	if ( isdefined( level.zombie_additionalprimaryweapon_machine_origin ) )
	{
		level._sq_perk_array = array_add( level._sq_perk_array, "specialty_additionalprimaryweapon" );
	}
}

randomize_gongs()
{
	gongs = GetEntArray("sq_gong", "targetname");

	gongs = array_randomize(gongs);

	for(i = 0; i < gongs.size; i ++)
	{
		if(i < 4)
		{
			gongs[i].right_gong = true;
		}
		else
		{
			gongs[i].right_gong = false;
		}
	}
}

watch_for_respawn()
{
	self endon("disconnect");

	while(1)
	{
		self waittill_either( "spawned_player", "player_revived" );
		waittillframeend;	// Let the other spawn threads do their thing.

		self SetMaxHealth( level.zombie_vars["zombie_perk_juggernaut_health"] );

	}
}

reward()
{

	level notify("temple_sidequest_achieved");

	//self add_sidequest_icon("sq", "anti115");

	for(i = 0; i < level._sq_perk_array.size; i ++)
	{
		if(!self HasPerk(level._sq_perk_array[i]))
		{
			self playsound( "evt_sq_bag_gain_perks" );
			self maps\_zombiemode_perks::give_perk(level._sq_perk_array[i]);
			wait(0.25);
		}
	}

	self._retain_perks = true;
	self thread watch_for_respawn();
}

raise_all_crystals()
{
	/*while(0 == GetDvarInt(#"scr_raise_crystals"))
	{
		wait(0.1);
	}*/

	flag_wait("power_on");

	level notify("raise_crystal_1");
	level notify("raise_crystal_2");
	level notify("raise_crystal_3");
	level notify("raise_crystal_4");
	level notify("raise_crystal_5");
	level notify("raise_crystal_6");
}

gong_watcher()
{
	if(IsDefined(level._gong_watcher_running))
	{
		return;
	}

	level._gong_watcher_running = true;

	level thread watch_for_gongs_gone_bad();

	while(1)
	{
		flag_wait("gongs_resonating");

		for(i = 0; i < level._raised_crystals.size; i ++)
		{
			if(level._raised_crystals[i])
			{
				exploder(500 + i + 1);
				wait_network_frame();
			}
		}

		while(flag("gongs_resonating"))
		{
			wait(0.1);
		}

		for(i = 0; i < level._raised_crystals.size; i ++)
		{
			stop_exploder(500 + i + 1);
			wait_network_frame();
		}
	}
}

watch_for_gongs_gone_bad()
{
	while(1)
	{
		level waittill("wrong_gong");

		for(i = 0; i < level._raised_crystals.size; i ++)
		{
			if(level._raised_crystals[i])
			{
				exploder(510 + i + 1);
				wait_network_frame();
			}
		}

		wait 1.0;

		flag_clear("gongs_resonating");

		wait 6;

		for(i = 0; i < level._raised_crystals.size; i ++)
		{
			stop_exploder(510 + i + 1);
			wait_network_frame();
		}

	}
}

force_eclipse_watcher()
{
	while(1)
	{
		while(0 == GetDvarInt(#"scr_force_eclipse"))
		{
			wait(0.1);
		}

		back_to_the_eclipse();
		reveal_meteor();

		while(1 == GetDvarInt(#"scr_force_eclipse"))
		{
			wait(0.1);
		}

		back_to_the_future();
		hide_meteor();

	}
}

gong_trigger_handler()
{
	while(1)
	{
		self waittill("damage", amount, attacker, dir, point, mod);

		if(isplayer( attacker ) && mod == "MOD_MELEE")
		{
			self.owner_ent notify("triggered", attacker);
		}
	}
}

gong_handler()
{
	self thread maps\zombie_temple_sq_bag::dud_gong_handler();
}

ptt_dial_handler()
{
	self thread maps\zombie_temple_sq_ptt::dud_dial_handler();
}

bttp2_dial_handler()
{
	self thread maps\zombie_temple_sq_bttp2::dud_dial_handler();
}

start_temple_sidequest()
{
/*	if(GetDvarInt("sidequest") == 0)
	{
		return;
	} */

	hide_meteor();		// Meteor starts off hidden.

	flag_wait("all_players_connected");

	sidequest_start("sq");
}

// Sundial thread will be auto re-set up by the monitor - this notify is sent in the exit stage logic for each stage.

restart_sundial_monitor()
{
	level endon("kill_sundial_monitor");
	level waittill("reset_sundial");

	wait(0.1);

	self thread sundial_monitor();
}

spin_dial(duration, multiplier)
{
	if(!IsDefined(duration))
	{
		duration = 2.0;
	}

	if(!IsDefined(multiplier))
	{
		multiplier = 1.3;
	}

	spin_time = 0.1;

	while(spin_time < duration)
	{
		self playloopsound( "evt_sq_gen_sundial_spin", .5 );
		self RotatePitch( 180, spin_time );
		wait(spin_time * 0.95);
		spin_time *= multiplier;
	}

	self stoploopsound( 2 );
}

short_dial_spin()
{
	spin_dial(1.0, 1.6);
}

sundial_monitor()
{
//	level endon("sidequest_sq_complete");
	level endon("reset_sundial");
	level endon( "end_game" );

	self.dont_rethread = true;
	self thread restart_sundial_monitor();

	if(!IsDefined(self.original_pos))
	{
		self.original_pos = self.origin - AnglesToUp(self.angles);
		self.off_pos = self.original_pos - (AnglesToUp(self.angles) * 34);
	}

	self.origin = self.off_pos;


	level._sundial_buttons_pressed = 0;

	level._stage_active = false;
	level._sundial_active = false;

	flag_wait("power_on");

	level notify("kill_buttons");

	wait(0.05);

	buttons = GetEntArray("sq_sundial_button", "targetname");

	array_thread(buttons, ::sundial_button);

	if(level.gamemode != "survival")
	{
		return;
	}

	while(1)
	{
		while(level._sundial_buttons_pressed < 4)	// Wait for all 4 buttons to be pressed.
		{
			wait(0.1);
		}

		// Raise sundial.

		level._sundial_active = true;

		self playsound( "evt_sq_gen_transition_start" );

		//if the sundial gets activated after the sidequest has been completed, then they stay in permament eclipse mode
		if(IsDefined(level._zombie_sidequests["sq"].sidequest_completed) && level._zombie_sidequests["sq"].sidequest_completed)
		{
			back_to_the_eclipse();
			return;
		}

		self playsound( "evt_sq_gen_sundial_emerge" );
		self moveto(self.original_pos, 0.25);
		self waittill("movedone");

		// Wait for movement to be done.

		self thread spin_dial();

		wait(0.5);

		stage = sidequest_start_next_stage("sq");

		level notify("stage_starting");

		// Sink sundial model down over stage.time_limit seconds, or over a default if stage.time_limit == 0

		amount = 34/4;

		level waittill("timed_stage_75_percent");

		self playsound( "evt_sq_gen_sundial_timer" );
		self moveto(self.origin - (AnglesToUp(self.angles) * amount), 1);
		self thread short_dial_spin();

		level waittill("timed_stage_50_percent");

		self playsound( "evt_sq_gen_sundial_timer" );
		self moveto(self.origin - (AnglesToUp(self.angles) * amount), 1);
		self thread short_dial_spin();

		level waittill("timed_stage_25_percent");

		self playsound( "evt_sq_gen_sundial_timer" );
		self moveto(self.origin - (AnglesToUp(self.angles) * amount), 1);
		self thread short_dial_spin();

		level waittill("timed_stage_10_seconds_to_go");

		self thread play_one_second_increments();
		self moveto(self.origin - (AnglesToUp(self.angles) * amount), 10);
		self thread spin_dial();
		self waittill("movedone");

		level._sundial_active = false;

		wait(0.1);
	}
}

play_one_second_increments()
{
	level endon("sidequest_sq_complete");
	level endon("reset_sundial");

	while( level._sundial_active == true )
	{
		self playsound( "evt_sq_gen_sundial_timer" );
		wait(1);
	}
}

sundial_button_already_pressed_by(who, buttons)
{
	/#

	if(get_players().size < 4)
	{
		return false;
	}

	#/

	for(i = 0; i < buttons.size; i ++)
	{
		if(IsDefined(buttons[i].triggering_player) && buttons[i].triggering_player == who)
		{
			return true;
		}
	}

	return false;
}

/*
debug_sundial_button_triggers(parent)
{
	self endon("death");
	/#
	sidequest = level._zombie_sidequests["sq"];

	col = undefined;

	offset = 0;

	switch(sidequest.num_reps)
	{
		case 0:
			col = (255,0,0);
			offset = 5;
			break;
		case 1:
			col = (0,255,0);
			offset = 10;
			break;
		case 2:
			col = (0,0,255);
			offset = 15;
			break;
		case 3:
			col = (0,255,255);
			offset = 20;
			break;
	}

	pos = self.origin + (AnglesToUp(parent.angles) * offset);

	while(1)
	{
		Print3d(pos, "+", col, 1);
		wait(0.1);
	}
	#/
}

debug_sundial_buttons()
{
	level endon("kill_buttons");
	/#
	sidequest = level._zombie_sidequests["sq"];

	col = undefined;

	offset = 0;

	switch(sidequest.num_reps)
	{
		case 0:
			col = (255,0,0);
			offset = 5;
			break;
		case 1:
			col = (0,255,0);
			offset = 10;
			break;
		case 2:
			col = (0,0,255);
			offset = 15;
			break;
		case 3:
			col = (0,255,255);
			offset = 20;
			break;
	}

	pos = self.origin + (AnglesToUp(self.angles) * offset);

	while(1)
	{
		Print3d(pos, "O", col, 1);
		wait(0.1);
	}
	#/
}
*/

sundial_button()
{
//	level endon("sidequest_sq_complete");

	level endon("stage_starting");
	level endon("kill_buttons");

	if(!IsDefined(self.dont_rethread))
	{
		self.dont_rethread = true;
		self.on_pos = self.origin - AnglesToUp(self.angles);
		self.off_pos = self.on_pos - (AnglesToUp(self.angles) * 5.5);

		self moveto(self.off_pos,0.01);
	}


	if(IsDefined(self.trigger))
	{
		self.trigger Delete();
		self.trigger = undefined;
	}


//	self.trigger trigger_off();

	self.triggering_player = undefined;

	flag_wait("power_on");

	// Move button forwards, out of surrounding wall.

	self moveto(self.on_pos, 0.25);
	self waittill("movedone");

	buttons = GetEntArray("sq_sundial_button", "targetname");

	offset = (AnglesToForward(self.angles) * 5) - (0,0,16);

	self.trigger = Spawn( "trigger_radius_use", self.on_pos + offset, 0, 48, 32 );
	self.trigger SetCursorHint( "HINT_NOICON" );
	self.trigger.radius = 48;


//	self.trigger thread debug_sundial_button_triggers(self);
//	self thread debug_sundial_buttons();

	while(1)
	{
		self.trigger waittill("trigger", who);

		/*if(sundial_button_already_pressed_by(who, buttons))
		{
			continue;
		}*/


		if(!level._stage_active)
		{
			self.triggering_player = who;

			level._sundial_buttons_pressed ++;

			self playsound( "evt_sq_gen_button" );
			self moveto(self.off_pos, 0.25);

			delay = 5;

			/#

			if(get_players().size == 1)
			{
				delay = 10;
			}

			#/

			wait(delay);

			while(level._sundial_active)
			{
				wait(0.1);
			}

			self.triggering_player = undefined;
			self moveto(self.on_pos, 0.25);

			if(level._sundial_buttons_pressed > 0)
			{
				level._sundial_buttons_pressed --;
			}
		}
	}
}

#using_animtree("fxanim_props_dlc4");

init_gongs()
{
	gongs = GetEntArray("sq_gong", "targetname");
	gongs = array_randomize(gongs);

	for(i = 0; i < gongs.size; i ++)
	{
		gongs[i] UseAnimTree(#animtree);

		name = "gong" + i;

		gongs[i].animname = name;
		level.scr_anim[name]["ring"] = %viewmodel_fxanim_zom_ztem_gong_anim;

	}
}

init_sidequest()
{
	level._buttons_can_reset = true;

	if(!IsDefined(level._sidequest_firsttime))
	{
		back_to_the_future();
		level._sidequest_firsttime = false;
	}

	players = get_players();

	for(i = 0; i < players.size; i ++)
	{
		entnum = players[i] GetEntityNumber();

		if( IsDefined( players[i].zm_random_char ) )
		{
			entnum = players[i].zm_random_char;
		}

		if((entnum == 3))
		{
			players[i] add_sidequest_icon("sq", "vril");
			break;
		}
	}

	if(level.gamemode == "survival")
	{
		maps\zombie_temple_sq_brock::create_radio(1);
	}

	init_gongs();

	wall = GetEnt("sq_wall", "targetname");
	wall SetModel("p_ztem_temple_wall_solid");
	//wall Solid();


	crystals = GetEntArray("sq_crystals", "targetname");

	level._raised_crystals = [];

	for(i = 0; i < crystals.size; i ++)
	{
		level._raised_crystals[i] = 0;
	}

	trap = GetEnt("sq_spiketrap", "targetname");
	trap Show();

	flag_clear("radio_4_played");
	flag_clear("radio_7_played");
	flag_clear("radio_9_played");
	flag_clear("meteorite_shrunk");

	meteorite = GetEnt("sq_meteorite", "targetname");
	meteorite SetModel("p_ztem_meteorite");
	meteorite Hide();

	if(!IsDefined(meteorite.original_origin))
	{
		meteorite.original_origin = meteorite.origin;
		meteorite.original_angles = meteorite.angles;
	}

	meteorite.origin = meteorite.original_origin;
	meteorite.angles = meteorite.original_angles;

	anti115 = GetEnt("sq_anti_115", "targetname");
	anti115 Show();

	level thread pap_watcher();
}

pap_watcher()
{
	level notify("only_one_pap_watcher");
	level endon("only_one_pap_watcher");

	while(1)
	{
		flag_wait("pap_override");

		while(flag("pack_machine_in_use"))
		{
			wait(0.1);
		}

		level thread pack_a_punch_hide();

		while(flag("pap_override"))
		{
			wait(0.1);
		}

		level thread pack_a_punch_show();
	}
}

cheat_complete_stage()
{
	level endon("reset_sundial");

	while(1)
	{
		if(GetDvar("cheat_sq") != "")
		{
			if(IsDefined(level._last_stage_started ))
			{
				SetDvar("cheat_sq", "");
				stage_completed("sq", level._last_stage_started);
			}
		}
		wait(0.1);
	}
}

generic_stage_start()
{
	/#
	level thread cheat_complete_stage();
	#/

	level._stage_active = true;
	back_to_the_eclipse();
	reveal_meteor();
}

generic_stage_complete()
{
	level notify("reset_sundial");
	level._stage_active = false;
	back_to_the_future();
	hide_meteor();
}

complete_sidequest()
{
	level notify("reset_sundial");

	level thread sidequest_done();
}

spin_115()
{
	self endon("picked_up");

	while(1)
	{
		self RotateYaw(180,0.4);
		wait(0.4);
	}
}

sidequest_done()
{
	wall = GetEnt("sq_wall", "targetname");
	wall SetModel("p_ztem_temple_wall_broken");
	wall NotSolid();

	anti115 = GetEnt("sq_anti_115", "targetname");
	anti115 thread spin_115();
	anti115 PlayLoopSound( "zmb_meteor_loop" );

	exploder(520);

	trigger = Spawn( "trigger_radius_use", anti115.origin, 0, 32, 72 );
	trigger SetCursorHint( "HINT_NOICON" );
	trigger.radius = 48;
	trigger.height = 72;

	players = get_players();

	while(1)
	{
		trigger waittill("trigger", who);

		if( IsPlayer(who) && !IsDefined(who._has_anti115))
		{
			who._has_anti115 = true;

			who PlaySound( "zmb_meteor_activate" );
			for(i = 0; i < players.size; i ++)
			{
				players[i] thread reward();
			}
			who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 7 );
			//who thread delayed_loser_response();
			break;
		}
		else if(IsPlayer(who))
		{
			who playsound( "zmb_no_cha_ching" );
		}
	}

	maps\zombie_temple_pack_a_punch::_pap_force_reset();

	trigger Delete();
	anti115 stoploopsound( 1 );
	anti115 notify("picked_up");
	level notify("picked_up");
	anti115 Hide();
	stop_exploder(520);

	/*players_far = 0;

	while(players_far < players.size)
	{
		players_far = 0;

		for(i = 0; i < players.size; i ++)
		{
			if(distance2dsquared(players[i].origin, wall.origin) > 360 * 360)
			{
				players_far ++;
			}
		}
		wait(0.1);

		players = get_players();
	}*/

	flag_clear("pap_override");
	level.egg_complete = true;

	//level thread reset_sidequest();
}

delayed_loser_response()
{
	wait(5);

	losers = get_players();
	losers = array_remove( losers, self );

	if( losers.size >= 1 )
	{
		losers[randomintrange(0,losers.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 8 );
	}
}

reset_sidequest()
{
	sidequest = level._zombie_sidequests["sq"];

	if(sidequest.num_reps >= 3)
	{
		return;
	}

	sidequest.num_reps ++;

	flag_wait("radio_9_played");

	while(flag("doing_bounce_around"))
	{
		wait(0.1);
	}

	// First handle the container logic


	stage_names = GetArrayKeys(sidequest.stages);

	for(i = 0; i < stage_names.size; i ++)
	{
		sidequest.stages[stage_names[i]].completed = false;
	}

	sidequest.last_completed_stage = -1;
	sidequest.active_stage = -1;	// No stage active.

	flag_clear("radio_7_played");
	flag_clear("radio_9_played");
	flag_clear("trap_destroyed");

	randomize_gongs();

	crystals = GetEntArray("sq_crystals", "targetname");

	for(i = 0; i < crystals.size; i ++)
	{
		if(IsDefined(crystals[i].trigger))
		{
			crystals[i].trigger Delete();
			crystals[i] Delete();
		}
	}

	dynamite = GetEnt("dynamite", "targetname");
	dynamite Delete();

	buttons = GetEntArray("sq_sundial_button", "targetname");

	for(i = 0; i < buttons.size; i ++)
	{
		if(IsDefined(buttons[i].trigger))
		{
			buttons[i].trigger Delete();
			buttons[i].trigger = undefined;
		}
	}

	start_temple_sidequest();

	dial = GetEnt("sq_sundial", "targetname");
	dial thread sundial_monitor();

	//maps\zombie_temple_sq_brock::create_radio(1);

}

back_to_the_eclipse()
{
	clientnotify("ec");		// Eclipse.
}

back_to_the_future()
{
	clientnotify("db");		// Daybreak.
}

reveal_meteor()
{
	ent = GetEnt("sq_meteorite", "targetname");

	if(IsDefined(ent))
	{
		ent Show();
		exploder(518);
	}
}

hide_meteor()
{
	ent = GetEnt("sq_meteorite", "targetname");
	if(IsDefined(ent))
	{
		ent Hide();
		stop_exploder(518);
	}
}

spawn_skel()
{
	if(!IsDefined(level._sq_skel))
	{
		ent = GetEnt("sq_spiketrap", "targetname");

		if(IsDefined(ent))
		{
			sb = Spawn("script_model", ent.origin);
			sb.angles = ent.angles;
			sb SetModel("p_ztem_skeleton");

			level._sq_skel = sb;
		}
	}
}

remove_skel()
{
	if(IsDefined(level._sq_skel))
	{
		level._sq_skel Delete();
		level._sq_skel = undefined;
	}
}

reset_dynamite()
{
	dynamite = GetEnt("dynamite", "targetname");
	dynamite.angles = dynamite.original_angles;
	dynamite.origin = dynamite.original_origin;
	dynamite Unlink();
	dynamite LinkTo(dynamite.owner_ent, "", dynamite.origin - dynamite.owner_ent.origin, dynamite.angles - dynamite.owner_ent.angles);
	dynamite.dropped = undefined;
	dynamite Show();
}

delay_kill_loop_sound_and_delete()
{
	self stoploopsound( .5 );
	wait(0.5);
	self Delete();
}


crystal_handler()
{
	if(IsDefined(self.trigger))
	{
		maps\_zombiemode_weap_shrink_ray::remove_shrinkable_object(self.trigger);
		self.trigger thread delay_kill_loop_sound_and_delete();
		self.trigger = undefined;
	}

	if(IsDefined(self.script_noteworthy) && self.script_noteworthy == "dynamite" && !IsDefined(self.dynamite))
	{
		dyn_pos = getstruct(self.target, "targetname");

		dynamite = Spawn("script_model", dyn_pos.origin);
		dynamite.angles = dyn_pos.angles;

		dynamite SetModel("p_ztem_dynamite");
		dynamite.targetname = "dynamite";
		dynamite.target = dyn_pos.target;
		dynamite.original_origin = dynamite.origin;
		dynamite.original_angles = dynamite.angles;
		dynamite.owner_ent = self;

		dynamite LinkTo(self, "", dynamite.origin - self.origin, dynamite.angles - self.angles);
		self.dynamite = dynamite;
	}

	if(!IsDefined(self.original_origin))
	{
		self.original_origin = self.origin;
	}

	self DontInterpolate();
	self.origin = self.original_origin - (0,0,154);

	self Hide();

	level waittill("raise_crystal_" + self.script_int, actual_stage);
	if ( actual_stage )
	{
		level notify( "suspend_timer" );
	}
	self Show();

	self playsound( "evt_sq_gen_crystal_start" );
	self playloopsound( "evt_sq_gen_crystal_loop", 2 );

	self moveto(self.origin + (0,0,154), 4.0, 0.8, 0.4);

	self waittill("movedone");

	self stoploopsound( 1 );
	self playsound( "evt_sq_gen_crystal_end" );

	level notify("raised_crystal_" + self.script_int);

	if(IsDefined(self.script_noteworthy) && self.script_noteworthy == "empty_holder")
	{
		if(IsDefined(actual_stage) && actual_stage)
		{
			level waittill("crystal_dropped");
		}

		self SetModel("p_ztem_crystal_and_holder");
	}

	trigger = Spawn( "trigger_damage", self.origin + (0,0,134), 0, 32, 32 );
	trigger.radius = 32;
	trigger.height = 32;

	trigger thread crystal_trigger_thread();
	trigger.owner_ent = self;
	maps\_zombiemode_weap_shrink_ray::add_shrinkable_object(trigger);

	self.trigger = trigger;
	self thread play_loopsound_while_resonating();
	self thread force_stoploopsound_end();

	level._raised_crystals[self.script_int - 1] = 1;
}

/*
crystal_debug()
{
	self endon("death");
	while(1)
	{
		Print3d(self.origin + (0,0,158), self.script_int, (255,255,255), 1);
		wait(0.1);
	}
}*/

play_loopsound_while_resonating()
{
	self.trigger endon( "death" );

//	self thread crystal_debug();

	while(1)
	{
		flag_wait("gongs_resonating");

		self playloopsound( "evt_sq_bag_crystal_loop", 2 );

		while(flag("gongs_resonating"))
		{
			wait(0.1);
		}

		self stoploopsound( .5 );
	}
}

get_crystal_from_script_int(num)
{
	sq = GetEntArray("sq_crystals", "targetname");

	for(i = 0; i < sq.size; i ++)
	{
		if(sq[i].script_int == num)
		{
			return sq[i];
		}
	}
}

is_crystal_raised(i)
{
	if(IsDefined(level._raised_crystals[i - 1]) && level._raised_crystals[i - 1] == 1)
	{
		return 1;
	}

	return 0;
}

bounce_from_a_to_b(a,b,hotsauce)
{

	if(hotsauce)
	{
		a setclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_HOTSAUCE_START);
	}
	else
	{
		a setclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_WEAKSAUCE_START);
	}

	b setclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_SAUCE_END);

	wait_network_frame();
	wait_network_frame();
	wait_network_frame();

	if(IsDefined(a))
	{
		a clearclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_HOTSAUCE_START);
		a clearclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_WEAKSAUCE_START);
	}

	if(IsDefined(b))
	{
		b clearclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_SAUCE_END);
	}
}

do_bounce_off(start, hotsauce)
{
	if(!IsDefined(level._bounce_off_ent))
	{
		level._bounce_off_ent = Spawn("script_model", (0,0,0) );
		level._bounce_off_ent SetModel("p_ztem_glyphs_00");
		level._bounce_off_ent Hide();
	}

	yaw = randomFloat( 360 );
	r = randomFloatRange( 100, 200);

	amntx = cos( yaw ) * r;
	amnty = sin( yaw ) * r;


	level._bounce_off_ent.origin = start.origin + (amntx, amnty, RandomInt(60));

	level thread bounce_from_a_to_b(start, level._bounce_off_ent, hotsauce);

}

shrink_time()
{
	wait 1.0;

	clientnotify( "mts" );
	self playsound( "evt_sq_bag_shrink_meteor" );
	//self SetModel("p_ztem_meteorite_small");
	exploder(519);
	wait(0.1);
	stop_exploder(518);
	self Hide();

	wait 0.25;

	flag_set("meteorite_shrunk");

	level thread shut_off_all_looping_sounds();
	self playsound( "evt_sq_bag_silence" );
	self playsound( "evt_sq_bag_meteor_fall" );
	self moveto(self.origin - (0,0,120), 2.0, 0.5);

	self waittill("movedone");

	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 4 );
}

crystal_shrink_logic(hotsauce)
{
	level._crystal_shrink_logic_running = true;

	flag_set("doing_bounce_around");

	bounce_path = level._crystal_bounce_paths[self.script_int];

	start = self;
	end = undefined;

	if(IsDefined(bounce_path))
	{
		for(i = 0; i < bounce_path.size; i ++)
		{
			if(string(bounce_path[i]) == "M")
			{
				if(sidequest_stage_active("sq", "BaG") && !flag("meteorite_shrunk"))
				{
					ent = GetEnt("sq_meteorite", "targetname");

					//level thread bounce_from_a_to_b(start, ent, hotsauce);

					if(hotsauce)
					{
						start playsound( "evt_sq_bag_crystal_bounce_correct" );
						exploder(509);
						ent thread shrink_time();
					}
					else
					{
						start playsound( "evt_sq_bag_crystal_bounce_fail" );
						exploder(529);
						players = get_players();
						players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 3 );
					}
				}
				else
				{
					start playsound( "evt_sq_bag_crystal_bounce_fail" );
					//do_bounce_off(start, hotsauce);
					exploder(529);
				}
			}
			else if(string(bounce_path[i]) == "R")
			{
				start playsound( "evt_sq_bag_crystal_bounce_fail" );
				do_bounce_off(start, hotsauce);
				break;
			}
			else if(is_crystal_raised(bounce_path[i]))
			{
				end = get_crystal_from_script_int(bounce_path[i]);
				start playsound( "evt_sq_bag_crystal_bounce_correct" );
				level thread bounce_from_a_to_b(start, end, hotsauce);
				start = end;
			}
			else
			{
				start playsound( "evt_sq_bag_crystal_bounce_fail" );
				do_bounce_off(start, hotsauce);
				break;
			}

			wait(0.5);	// Travel time;

			end playsound( "evt_sq_bag_crystal_hit_" + i );

			if(hotsauce && IsDefined(end) && IsDefined(end.dynamite) && !IsDefined(end.dynamite.dropped) && sidequest_stage_active("sq", "BaG"))
			{
				end.dynamite thread maps\zombie_temple_sq_bag::fire_in_the_hole();
			}

			end playsound( "evt_sq_bag_crystal_charge" );
			if(hotsauce)
			{
				exploder(end.script_int + 520);
			}
			else
			{
				exploder(end.script_int + 530);
			}
			wait(0.5);	// Charge time

		}
	}

	level._crystal_shrink_logic_running = undefined;
	flag_clear("doing_bounce_around");
}

crystal_shrink_thread()
{
	self endon("death");

	while(1)
	{
		self waittill("shrunk", hotsauce);

		if(!flag("gongs_resonating"))
		{
			hotsauce = false;
		}

		if(!IsDefined(level._crystal_shrink_logic_running))
		{
			self.owner_ent thread crystal_shrink_logic(hotsauce);
		}
	}
}

crystal_trigger_thread()
{
	self endon("death");
	self thread crystal_shrink_thread();

	while(1)
	{
		self waittill("damage", amount, attacker, dir, point, type);

	}
}

pack_a_punch_hide()
{
	if(!IsDefined(level._pap_hidden))
	{
		level._pap_hidden = 0;
		pap_machine_trig = getent("zombie_vending_upgrade","targetname");
		pap_machine_trig enablelinkto();
	}

	if(level._pap_hidden)
	{
		return;
	}

	level._pap_hidden = 1;

	pap_clip = getent("zombie_vending_upgrade_clip","targetname");
	pap_clip notsolid();
	pap_clip ConnectPaths();

	pap_machine_trig = getent("zombie_vending_upgrade","targetname");
	pap_pieces = getentarray(pap_machine_trig.target,"targetname");

	pap_jingle_struct = getstruct("pack_jingle_struct","script_noteworthy");

	if(!IsDefined(pap_jingle_struct.original_origin))
	{
		pap_jingle_struct.original_origin = pap_jingle_struct.origin;
		pap_machine_trig.original_origin = pap_machine_trig.origin;
	}

	link_ent = spawn("script_origin",pap_machine_trig.origin);
	link_ent.angles = pap_jingle_struct.angles;
	pap_machine_trig linkto(link_ent);

	level._original_pap_spot = pap_machine_trig.origin;

	pap_clip linkto(link_ent);

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") linkto(link_ent);
		}
		pap_pieces[i] linkto(link_ent);
	}

	link_ent moveto(link_ent.origin + (0,0,-350) ,5);
	link_ent waittill("movedone");

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") hide();
		}
		pap_pieces[i] hide();
	}

	pap_machine_trig unlink();

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") unlink();
		}

		pap_pieces[i] unlink();
	}
	pap_jingle_struct.origin = pap_jingle_struct.original_origin;
	pap_jingle_struct.angles = link_ent.angles;

	pap_clip unlink();
	link_ent delete();

	level._pap_hidden = 2;
}

pack_a_punch_show()
{
	if(!IsDefined(level._pap_hidden) || level._pap_hidden == 0)
	{
		return;
	}

	if(level._pap_hidden == 1)	// pap still in the process of being hidden...
	{
		while(level._pap_hidden != 2)
		{
			wait(1);
		}
	}

	pap_clip = getent("zombie_vending_upgrade_clip","targetname");
	pap_clip Solid();
	pap_clip ConnectPaths();

	pap_machine_trig = getent("zombie_vending_upgrade","targetname");	//the trigger that the player uses
	pap_pieces = getentarray(pap_machine_trig.target,"targetname");	//the pieces for the machine

	pap_jingle_struct = getstruct("pack_jingle_struct","script_noteworthy");	//struct where the jingle plays from

	link_ent = spawn("script_origin",pap_machine_trig.origin);
	link_ent.angles = pap_jingle_struct.angles;

	pap_machine_trig linkto(link_ent);
	pap_clip linkto(link_ent);

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") linkto(link_ent);
			getent(pap_pieces[i].target,"targetname") hide();

		}
		pap_pieces[i] linkto(link_ent);
		pap_pieces[i] hide();
	}

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") show();
		}
		pap_pieces[i] show();
	}

	link_ent moveto(level._original_pap_spot,5);
	link_ent waittill("movedone");
	pap_machine_trig unlink();

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") unlink();
		}
		pap_pieces[i] unlink();
	}

	//reset the jingle struct
	pap_jingle_struct.origin = pap_jingle_struct.original_origin;
	pap_jingle_struct.angles = link_ent.angles;

	pap_clip unlink();
	link_ent delete();

	level._pap_hidden = 0; // pap is fully shown.

}

get_variant_from_entity_num( player_number )
{
	if(!IsDefined(player_number))
	{
		player_number = 0;
	}

	post_fix = "a";

	switch(player_number)
	{
		case 0:
			post_fix = "a";
			break;
		case 1:
			post_fix = "b";
			break;
		case 2:
			post_fix = "c";
			break;
		case 3:
			post_fix = "d";
			break;
	}

	return post_fix;
}

shut_off_all_looping_sounds()
{
	gongs = GetEntArray("sq_gong", "targetname");

	for(i = 0; i < gongs.size; i ++)
	{
		if(gongs[i].right_gong)
		{
			if(gongs[i].ringing)
			{
				if(level._num_gongs >= 0)
				{
					level._num_gongs --;
				}

				gongs[i] stoploopsound( .5 );
			}
		}

		gongs[i].ringing = false;
	}

	level notify( "force_stoploopsound_end" );
	level notify("kill_resonate");
}

force_stoploopsound_end()
{
	self.trigger endon( "death" );

	level waittill( "force_stoploopsound_end" );
	self stoploopsound( .5 );
}
