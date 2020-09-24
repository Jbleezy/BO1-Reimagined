/* zombie_moon_sq_ctvg.gsc
 *
 * Purpose : 	Sidequest stage logic for zombie_moon - charge the vrill generator.
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
	flag_init("w_placed");
	flag_init("vg_placed");
	flag_init("cvg_picked_up");

	declare_sidequest_stage("ctvg", "build", ::build_init, ::build_stage_logic, ::build_exit_stage);
	declare_stage_asset_from_struct("ctvg", "build", "sq_cassimir_plates", ::plate_thread);
	declare_sidequest_stage("ctvg", "charge", ::charge_init, ::charge_stage_logic, ::charge_exit_stage);
	PreCacheModel("p_zom_moon_vril_complete");
	PreCacheModel("zombie_magic_box_wire");
}

plate_thread()
{
	level waittill("stage_1");

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
		self RotateTo(struct.angles, time, time/10);
		self waittill("movedone");
		playsoundatposition( "evt_clank", self.origin );
		target = struct.target;
	}

	level notify("stage_1_done");
}

build_init()
{
}

plates()
{
	plates = GetEntArray("sq_cassimir_plates", "targetname");

	trig = Spawn("trigger_damage", ((plates[0].origin + plates[1].origin) / 2) - (0,0,100), 0, 64, 120);

	while(1)
	{
		trig waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );
		if( isplayer( attacker ) && ( 	dmg_type == "MOD_PROJECTILE" || dmg_type == "MOD_PROJECTILE_SPLASH"
																|| 	dmg_type == "MOD_EXPLOSIVE" || dmg_type == "MOD_EXPLOSIVE_SPLASH"
																|| 	dmg_type == "MOD_GRENADE" || dmg_type == "MOD_GRENADE_SPLASH" ) )
		{
			attacker thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, randomintrange(0,2), true );
			break;
		}
	}

	trig Delete();

	level notify("stage_1");
	level waittill("stage_1_done");

	// Trigger for bomb distance check - lowered the origin so the hit detection pics up all ground levels
	level.teleport_target_trigger = Spawn( "trigger_radius", plates[0].origin + (0,0,-70), 0, 125, 100 );	// flags, radius, height

	// Function override in _zombiemode_weap_black_hole_bomb, make the bomb check to see
	//	if it's in our trigger
	level.black_hole_bomb_loc_check_func = ::bhb_teleport_loc_check;

	level waittill("ctvg_tp_done");

	level.black_hole_bomb_loc_check_func = undefined;

	level waittill( "restart_round" );

	targs = getstructarray("sq_ctvg_tp2", "targetname");

	for(i = 0; i < plates.size; i ++)
	{
		plates[i] DontInterpolate();
		plates[i].origin = targs[i].origin;
		plates[i].angles = targs[i].angles;
	}

	maps\_zombiemode_weap_quantum_bomb::quantum_bomb_register_result( "ctvg", ::ctvg_result, 100, ::ctvg_validation );
	level._ctvg_pos = targs[0].origin;
	level waittill("ctvg_validation");
	maps\_zombiemode_weap_quantum_bomb::quantum_bomb_deregister_result("ctvg");

	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, randomintrange(4,6), true );

	for(i = 0; i < plates.size; i ++)
	{
		plates[i] Hide();
	}

	clientnotify("cp");
	flag_set("c_built");
}

wire_qualifier()
{
	if(IsDefined(self._has_wire) && self._has_wire)
	{
		return true;
	}

	return false;
}

monitor_wire_disconnect()
{
	level endon("w_placed");
	self waittill("disconnect");
	level notify("wire_restart");
	level thread wire();
}

wire()
{
	/*
	level endon("wire_restart");
	wires = getstructarray("sq_wire_pos", "targetname");
	wires = array_randomize(wires);
	wire_struct = wires[0];

	wire = Spawn("script_model", wire_struct.origin);
	if(IsDefined(wire_struct.angles))
	{
		wire.angles = wire_struct.angles;
	}
	wire SetModel("zombie_magic_box_wire");
	wire thread fake_use("pickedup_wire");

	wire waittill("pickedup_wire", who);

	who thread monitor_wire_disconnect();

	who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 7, true );
	who playsound( "evt_grab_wire" );

	who._has_wire = true;
	wire Delete();
	who add_sidequest_icon("sq", "wire");

	flag_wait("c_built");

	wire_struct = getstruct("sq_wire_final", "targetname");
	wire_struct thread fake_use("placed_wire", ::wire_qualifier);
	wire_struct waittill("placed_wire", who);

	who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 8, true );
	who playsound( "evt_casimir_charge" );
	who playsound( "evt_sq_rbs_light_on" );

	who._has_wire = undefined;
	who remove_sidequest_icon("sq", "wire");
	*/

	clientnotify("wp");

	flag_wait("c_built");

	flag_set("w_placed");
}

vg_qualifier()
{
	num = self GetEntityNumber();

	if(IsDefined(self.zm_random_char))
	{
		num = self.zm_random_char;
	}

	if(level.richtofen_in_game)
	{
		return( (num == 3) && level._all_previous_done);
	}
	else
	{
		return( (num == level.random_entnum) && level._all_previous_done);
	}
}

vg()
{
	flag_wait("w_placed");
	flag_wait("power_on");
	vg_struct = getstruct("sq_charge_vg_pos", "targetname");
	vg_struct thread fake_use("vg_placed", ::vg_qualifier);
	vg_struct waittill("vg_placed", who);

	if(level.richtofen_in_game)
	{
		who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 9, true );
	}

	level.vg_struct_sound = spawn( "script_origin", vg_struct.origin );
	level.vg_struct_sound playsound( "evt_vril_connect" );
	level.vg_struct_sound playloopsound( "evt_vril_loop_lvl1", 1 );
	who remove_sidequest_icon("sq", "generator");
	clientnotify("vg");
	flag_set("vg_placed");
}

build_stage_logic()
{

	level thread plates();
	level thread wire();
	level thread vg();

	flag_wait("c_built");
	flag_wait("w_placed");
	flag_wait("vg_placed");

	stage_completed("ctvg", "build");
}

ctvg_validation( position )
{
	if(DistanceSquared(level._ctvg_pos, position) < (128 * 128))
	{
		return true;
	}

	return false;
}

ctvg_result( position )
{
	[[level.quantum_bomb_play_mystery_effect_func]]( position );

	level notify("ctvg_validation");
}

delete_soon()
{
	wait(4.5);
	self Delete();
}

bhb_teleport_loc_check( grenade, model, info )
{
	if( IsDefined( level.teleport_target_trigger ) && grenade IsTouching( level.teleport_target_trigger ) )
	{
		//spot = Spawn("script_model", plates[0].origin);
		//spot SetModel("tag_origin");

		model SetClientFlag( level._SCRIPTMOVER_CLIENT_FLAG_BLACKHOLE );
		//spot thread delete_soon();

		grenade thread maps\_zombiemode_weap_black_hole_bomb::do_black_hole_bomb_sound( model, info ); // WW: This might not work if it is based on the model

		level thread teleport_target( grenade, model );

		return true;
	}

	return false;
}


//
//	Move the device into position
teleport_target( grenade, model )
{
  	level.teleport_target_trigger Delete();
	level.teleport_target_trigger = undefined;

	// move into the vortex
	wait( 1.0 );	// pacing pause

	time = 3.0;
	plates = GetEntArray("sq_cassimir_plates", "targetname");
	for(i = 0; i < plates.size; i ++)
	{
		plates[i] MoveTo( grenade.origin + (0,0,50), time, time - 0.05 );
	}

	wait( time );

	// Zap it to the new spot
	teleport_targets = getstructarray( "sq_ctvg_tp", "targetname" );

	// "Teleport" the object to the new location

	for(i = 0; i < plates.size; i ++)
	{
		plates[i] Hide();
	}

	playsoundatposition( "zmb_gersh_teleporter_out", grenade.origin + (0,0,50) );

	wait( 0.5 );

	for(i = 0; i < plates.size; i ++)
	{
		plates[i] DontInterpolate();
		plates[i].angles = teleport_targets[i].angles;
		plates[i].origin = teleport_targets[i].origin;
		plates[i] StopLoopSound( 1 );
	}

	wait( 0.5 );

  	for(i = 0; i < plates.size; i ++)
  	{
		plates[i] Show();
	}

  	PlayFXOnTag( level._effect[ "black_hole_bomb_event_horizon" ], plates[0], "tag_origin" );

  	plates[0] PlaySound( "zmb_gersh_teleporter_go" );
	plates[0] playsound( "evt_clank" );
	wait( 2.0 );

	model Delete();
	level notify("ctvg_tp_done");
}

build_exit_stage(success)
{
}

build_charge_stage(num_presses, lines)
{
	stage = SpawnStruct();
	stage.num_presses = num_presses;

	stage.lines = [];

	for(i = 0; i < lines.size; i += 2)
	{
		l = SpawnStruct();
		l.who = lines[i];
		l.what = lines[i + 1];
		stage.lines[stage.lines.size] = l;
	}

	return stage;
}

speak_charge_lines(lines)
{
	level.skit_vox_override = true;

	for(i = 0; i < lines.size; i ++)
	{
		l = lines[i];

		sound_ent = undefined;

		switch(l.who)
		{
			case "rictofen":

				players = get_players();
				for(j = 0; j < players.size; j ++)
				{
					ent_num = players[j] GetEntityNumber();

					if(IsDefined(players[j].zm_random_char))
					{
						ent_num = players[j].zm_random_char;
					}

					if(!level.richtofen_in_game)
					{
						sound_ent = level._charge_sound_ent;
						break;
					}
					else if(level.richtofen_in_game && ent_num == 3)
					{
						sound_ent = players[j];
						break;
					}
				}
				break;
			case "maxis":
			case "computer":
				sound_ent = level._charge_sound_ent;
				break;
		}

		if(l.what == "vox_mcomp_quest_step5_15" || l.what == "vox_mcomp_quest_step5_26")
		{
			level._charge_terminal SetModel("p_zom_moon_magic_box_com_green");
		}
		else if(l.what == "vox_xcomp_quest_step5_16")
		{
			level._charge_terminal SetModel("p_zom_moon_magic_box_com_red");
		}

		if( is_player_valid( sound_ent ) && sound_ent maps\_zombiemode_equipment::is_equipment_active("equip_gasmask_zm") )
		{
			sound_ent PlaySound(l.what + "_f", "line_spoken" );
		}
		else
		{
			sound_ent PlaySound(l.what, "line_spoken");
		}
		sound_ent waittill("line_spoken");

	}

	level._charge_sound_ent StopLoopSound();
	level.skit_vox_override = false;
}

charge_init()
{
	level._charge_stages = array(	build_charge_stage(1, 	array ( "rictofen", "vox_plr_3_quest_step5_12" )),
																build_charge_stage(15, 	array( 	"computer", "vox_mcomp_quest_step5_13",
																																"rictofen", "vox_plr_3_quest_step5_14")),
																build_charge_stage(15, 	array(	"computer", "vox_mcomp_quest_step5_15",
																																"maxis", 		"vox_xcomp_quest_step5_16",
																																"rictofen",	"vox_plr_3_quest_step5_17")),
																build_charge_stage(10, 	array(	"maxis",		"vox_xcomp_quest_step5_18",
																																"rictofen", "vox_plr_3_quest_step5_19")),
																build_charge_stage(15, 	array(	"maxis",		"vox_xcomp_quest_step5_20",
																																"rictofen",	"vox_plr_3_quest_step5_21",
																																"maxis",		"vox_xcomp_quest_step5_22",
																																"rictofen",	"vox_plr_3_quest_step5_23")),
																build_charge_stage(10, 	array(	"maxis",		"vox_xcomp_quest_step5_24",
																																"rictofen", "vox_plr_3_quest_step5_25",
																																"computer",	"vox_mcomp_quest_step5_26")));

	sound_struct = getstruct("sq_charge_terminal", "targetname");
	level._charge_sound_ent = Spawn("script_origin", sound_struct.origin);
	level._charge_terminal = GetEnt("sq_ctvg_terminal", "targetname");

	level._charge_terminal SetModel("p_zom_moon_magic_box_com_red");
}

bucket_qualifier()
{
	ent_num = self GetEntityNumber();

	if(IsDefined(self.zm_random_char))
	{
		ent_num = self.zm_random_char;
	}

	if(level.richtofen_in_game && ent_num == 3)
	{
		return true;
	}
	else if(!level.richtofen_in_game && ent_num == level.random_entnum)
	{
		return true;
	}

	return false;
}

wrong_press_qualifier()
{
	ent_num = self GetEntityNumber();

	if(IsDefined(self.zm_random_char))
	{
		ent_num = self.zm_random_char;
	}

	if(level.richtofen_in_game && ent_num != 3)
	{
		return true;
	}
	else if(!level.richtofen_in_game && ent_num != level.random_entnum)
	{
		return true;
	}

	return false;
}

typing_sound_thread()
{
	level endon("kill_typing_thread");

	level._charge_sound_ent PlayLoopSound("evt_typing_loop");

	typing = true;

	level._typing_time = GetTime();

	while(1)
	{
		if(typing)
		{
			if((GetTime() - level._typing_time) > 250)
			{
				typing = false;
				level._charge_sound_ent StopLoopSound();
			}
		}
		else
		{
			if((GetTime() - level._typing_time) < 100)
			{
				typing = true;
				level._charge_sound_ent PlayLoopSound("evt_typing_loop");
			}
		}
		wait(0.1);
	}
}

do_bucket_fill(target)
{
	presses = 0;

	players = get_players();

	richtofen = undefined;

	level thread typing_sound_thread();

	for(i = 0; i < players.size; i ++)
	{
		player = players[i];

		ent_num = player GetEntityNumber();

		if(IsDefined(player.zm_random_char))
		{
			ent_num = player.zm_random_char;
		}

		if(level.richtofen_in_game && ent_num == 3)
		{
			richtofen = players[i];
			break;
		}
		else if(!level.richtofen_in_game && ent_num == level.random_entnum)
		{
			richtofen = players[i];
			break;
		}
	}

	while(presses < target)
	{
		level._charge_sound_ent thread maps\_zombiemode_sidequests::fake_use("press", ::bucket_qualifier);
		level._charge_sound_ent waittill("press");
		presses ++;

		level._typing_time = GetTime();

		while(IsDefined(richtofen) && richtofen UseButtonPressed())
		{
			wait 0.05;
		}
	}

	level notify("kill_typing_thread");
}

wrong_presser_thread()
{
	level endon("kill_press_monitor");

	while(1)
	{
		if(IsDefined(level._charge_sound_ent))
		{
			level._charge_sound_ent thread maps\_zombiemode_sidequests::fake_use("wrong_press", ::wrong_press_qualifier);
			level._charge_sound_ent waittill("wrong_press", who);
			who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 11, true );
		}

		wait(1.0);

	}
}

wrong_collector()
{
	level endon("collected");

	while(1)
	{
		self thread maps\_zombiemode_sidequests::fake_use("wrong_collector", ::wrong_press_qualifier);
		self waittill("wrong_collector", who);

		who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 27, true );

		wait(1.0);

	}
}

charge_stage_logic()
{
	stage_index = 0;

	level thread wrong_presser_thread();
	level thread prevent_other_vox_while_here();

	while(stage_index < level._charge_stages.size)
	{
		stage = level._charge_stages[stage_index];
		do_bucket_fill(stage.num_presses);
		speak_charge_lines(stage.lines);

		stage_index ++;
	}

	clientnotify("vg");	// play charge effect on client.

	level.vg_struct_sound playsound( "evt_extra_charge" );
	level.vg_struct_sound playloopsound( "evt_vril_loop_lvl2", 1 );

	level thread start_player_vox_again();

	vg = getstruct("sq_charge_vg_pos", "targetname");
	level notify("kill_press_monitor");
	vg thread wrong_collector();
	vg thread maps\_zombiemode_sidequests::fake_use("collect", ::bucket_qualifier);
	vg waittill("collect", who);

	if(level.richtofen_in_game)
	{
		who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 27, true );
	}

	who playsound( "evt_vril_remove" );
	level.vg_struct_sound delete();
	level.vg_struct_sound = undefined;
	clientnotify("vg");	// delete vrill generator on client.
	who add_sidequest_icon("sq","cgenerator");
	level notify("collected");
	stage_completed("ctvg", "charge");
}

charge_exit_stage(success)
{
	level._charge_sound_ent Delete();
	level._charge_sound_ent = undefined;
	flag_set("vg_charged");
}

prevent_other_vox_while_here()
{
	level endon( "start_player_vox_again" );

	while(1)
	{
		while( level.zones["bridge_zone"].is_occupied )
		{
			level.skit_vox_override = true;
			wait(1);
		}

		level.skit_vox_override = false;
		wait(1);
	}
}

start_player_vox_again()
{
	level notify( "start_player_vox_again" );

	wait(1);

	level.skit_vox_override = false;
}
