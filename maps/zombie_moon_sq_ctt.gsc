/* zombie_moon_sq_ctt.gsc
 *
 * Purpose : 	Sidequest stage logic for zombie_moon - charge the tank 1 & 2.
 *
 *
 * Author : 	Dan L
 *
 */

#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_sidequests;

init_1()
{
	level._active_tanks = [];
	maps\_zombiemode_spawner::add_cusom_zombie_spawn_logic(::tank_volume_death_check);

	declare_sidequest_stage("tanks", "ctt1", ::init_stage_1, ::stage_logic, ::exit_stage_1);
}

init_stage_1()
{
	level._active_tanks = [];
	level._cur_stage_name = "ctt1";
	level._ctt_pause_flag = "sam_switch_thrown";
	level._charge_flag = "first_tanks_charged";

	add_tank("sq_first_tank");
	clientnotify("ctt1");

	level thread setup_and_play_ctt1_vox();
}

exit_stage_1(success)
{
	kill_tanks();
}

init_2()
{
	declare_sidequest_stage("tanks", "ctt2", ::init_stage_2, ::stage_logic, ::exit_stage_2);
}

init_stage_2()
{
	level._active_tanks = [];
	level._cur_stage_name = "ctt2";
	level._ctt_pause_flag = "cvg_placed";
	level._charge_flag = "second_tanks_charged";
}

exit_stage_2(success)
{
	flag_set("second_tanks_charged");

	kill_tanks();
}

stage_logic()
{
	// Wait for richtofen to get close

	if(level._cur_stage_name == "ctt2")
	{
		s = getstruct("sq_vg_final", "targetname");

		r_close = false;

		while(!r_close)
		{
			players = get_players();

			for(i = 0; i < players.size; i ++)
			{
				ent_num = players[i] GetEntityNumber();

				if(IsDefined(players[i].zm_random_char))
				{
					ent_num = players[i].zm_random_char;
				}

				if((level.richtofen_in_game && ent_num == 3) || (!level.richtofen_in_game && ent_num == level.random_entnum))
				{
					d = DistanceSquared(players[i].origin, s.origin);

					if(d < 240 * 240)
					{
						r_close = true;
						players[i] PlaySound("vox_plr_3_quest_step6_0");
						break;
					}
				}
			}

			wait(0.1);
		}

		add_tank("sq_first_tank", "sq_second_tank");
		clientnotify("ctt2");

		level thread setup_and_play_ctt2_vox();
		level thread hit_sam();
	}

	while(1)
	{
		if(all_tanks_full())
		{
			//GS add full sound onbe shot
			Play_Sound_In_Space ("evt_souls_full", (0,0,0));
			level notify( "ctt_aud_note" );
			break;
		}
		wait 0.1;
	}

	clientnotify("ctto");

	flag_set(level._charge_flag);

	flag_wait(level._ctt_pause_flag);

	drain_tanks();


	for(i = 0; i < level._active_tanks.size; i ++)
	{
		tank = level._active_tanks[i];

		tank.capacitor moveto(tank.capacitor.origin + (0,0,12), 2);
		tank.tank moveto(tank.tank.origin - (0,0,57.156), 2);
		tank.tank playsound( "evt_tube_move_down" );
		tank.tank thread play_delayed_stop_sound( 2 );
		tank trigger_off();
	}

	wait(2.0);

	if(level._cur_stage_name == "ctt2")
	{
		flag_set("second_tanks_drained");
	}
	else
	{
		flag_set("first_tanks_drained");
	}

	stage_completed("tanks", level._cur_stage_name);
}

play_delayed_stop_sound( time )
{
	wait(time);
	self playsound( "evt_tube_stop" );
}

build_sam_stage(percent, l)
{
	s = SpawnStruct();

	s.percent = percent;
	s.line = l;

	return s;
}

percent_full()
{
	max_fill = 0;
	fill = 0;

	for(i = 0; i < level._active_tanks.size; i ++)
	{
		max_fill += level._active_tanks[i].max_fill;
		fill += level._active_tanks[i].fill;
	}

	return fill/max_fill;
}

hit_sam()
{
	level endon("tanks_ctt2_over");

	stages = array( build_sam_stage(0.1, "vox_plr_4_quest_step6_1"),
									build_sam_stage(0.2, "vox_plr_4_quest_step6_1a"),
									build_sam_stage(0.3, "vox_plr_4_quest_step6_2"),
									build_sam_stage(0.4, "vox_plr_4_quest_step6_2a"),
									build_sam_stage(0.5, "vox_plr_4_quest_step6_3"),
									build_sam_stage(0.6, "vox_plr_4_quest_step6_3a"),
									build_sam_stage(0.7, "vox_plr_4_quest_step6_4"),
									build_sam_stage(0.9, "vox_plr_4_quest_step6_5"));

	index = 0;

	targ = getstruct("sq_sam", "targetname");
	targ = getstruct(targ.target, "targetname");


	while(index < stages.size)
	{
		stage = stages[index];

		while(percent_full() < stage.percent)
		{
			wait 0.1;
		}

		level.skit_vox_override = true;

		level thread play_sam_vo(stage.line, targ.origin,index);

		level.skit_vox_override = false;

		index ++;
	}
}

play_sam_vo(_line,origin,index)
{
	level clientnotify("st1");
	snd_ent = spawn("script_origin",origin);
	snd_ent playsound(_line, index + "_snddone");
	snd_ent waittill(index + "_snddone");
	level clientnotify("sp1");
	snd_ent delete();

}


drain_tanks()
{
	for(i = 0; i < level._active_tanks.size; i ++)
	{
		tank = level._active_tanks[i];

		tank.fill_model moveto(tank.fill_model.origin - (0,0,65) , 1.5, 0.1, 0.1);
		tank.tank stoploopsound( 1 );
		tank.tank playsound( "evt_souls_flush" );
		tank.fill_model thread delay_hide();
		tank.fill = 0;
	}

	wait(2);
}

delay_hide()
{
	wait(2);
	self Hide();
}

all_tanks_full()
{
	if(level._active_tanks.size == 0)
	{
		return false;
	}

	for( i = 0; i < level._active_tanks.size; i ++)
	{
		tank = level._active_tanks[i];

		if(tank.fill < tank.max_fill)
		{
			return false;
		}
	}
	return true;
}

kill_tanks()
{
	clientnotify("ctto");

	tanks = GetEntArray("ctt_tank", "script_noteworthy");

	for(i = 0; i < tanks.size; i ++)
	{
		tank = tanks[i];

		tank.capacitor Delete();
		tank.capacitor = undefined;

		tank.tank = undefined;

		tank.fill_model Delete();
		tank.fill_model = undefined;

		tank Delete();
	}
}

movetopos(pos)
{
	self moveto(pos, 1);
}

add_tank(tank_name, other_tank_name)
{
	tanks = getstructarray(tank_name, "targetname");

	if(IsDefined(other_tank_name))
	{
		tanks = array_merge(tanks, getstructarray(other_tank_name, "targetname"));
	}

	for(i = 0; i < tanks.size; i ++)
	{
		tank = tanks[i];

		radius = 32;

		if(IsDefined(tank.radius))
		{
			radius = tank.radius;
		}

		height = 72;

		if(IsDefined(tank.height))
		{
			height = tank.height;
		}

		tank_trigger = Spawn( "trigger_radius", tank.origin, 1, radius, height );

		tank_trigger.script_noteworthy = "ctt_tank";

		capacitor_struct = getstruct(tank.target, "targetname");

		capacitor_model = spawn( "script_model", capacitor_struct.origin + (0,0,18) );
		capacitor_model.angles = capacitor_struct.angles;
		capacitor_model SetModel(capacitor_struct.model);

		capacitor_model thread movetopos(capacitor_struct.origin);

		tank_trigger.capacitor = capacitor_model;

		tank_model = GetEnt(capacitor_struct.target, "targetname");
		tank_model thread movetopos(tank_model.origin + (0,0,57.156));
		tank_model playsound( "evt_tube_move_up" );
		tank_model thread play_delayed_stop_sound( 1 );

		tank_trigger.tank = tank_model;
		tank_trigger.fill = 0;

		scalar = 1.0;

		scalar += ((get_players().size - 1) * 0.33);

		tank_trigger.max_fill = Int(tank_model.script_int * scalar);
		max_fill = getstruct(tank_model.target, "targetname");

		tank_trigger.tank.fill_step = ((max_fill.origin[2] - (tank_model.origin[2] + 56)) / tank_trigger.max_fill);

		tank_fill_model = Spawn("script_model", tank_trigger.tank.origin + (0,0,56));
		//tank_fill_model.angles = max_fill.angles;
		tank_fill_model SetModel(max_fill.model);

		tank_fill_model.base_level = tank_trigger.tank.origin + (0,0,56);
		tank_fill_model Hide();
//		tank_fill_model movetopos(tank_trigger.tank.origin);

		tank_trigger.fill_model = tank_fill_model;

		level._active_tanks[level._active_tanks.size] = tank_trigger;
	}
}

do_tank_fill(actor, tank)
{
	// Do effect from actor to tank capacitor.

	if(tank.fill >= tank.max_fill)
	{
		tank.tank playloopsound( "evt_souls_full_loop", 1 );
		return;
	}

	actor setclientflag(level._CF_ACTOR_CLIENT_FLAG_CTT);

	wait(0.5);

	// Then fill tank.

	if( tank.fill <= 0 )
	{
		level notify( "ctt_first_kill" );
	}

	if(IsDefined(tank) && tank.fill < tank.max_fill)
	{
		tank.fill ++;

		tank.fill_model.origin += (0,0,tank.tank.fill_step);
		tank.fill_model Show();
	}
}

tank_volume_death_check()
{
	self waittill("death");

	if(!IsDefined(self))
	{
		return;
	}

	for(i = 0; i < level._active_tanks.size; i ++)
	{
		if(IsDefined(level._active_tanks[i]))
		{
			if(self IsTouching(level._active_tanks[i]))
			{
				level thread do_tank_fill(self, level._active_tanks[i]);
				return;
			}
		}
	}
}

setup_and_play_ctt1_vox()
{
	level thread ctt1_first_kill_vox();
	level thread ctt1_full_vox();
	level thread vox_override_while_near_tank();
	level thread ctt1_fifty_percent_vox();
}

ctt1_first_kill_vox()
{
	level waittill( "ctt_first_kill" );

	for(i = 0; i < level._active_tanks.size; i ++)
	{
		player = get_closest_player( level._active_tanks[i].origin );

		if( isdefined( player ) )
		{
			player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest4", undefined, 0, true );
			return;
		}
	}
}

ctt1_fifty_percent_vox()
{
	while(percent_full() < .5 )
	{
		wait(.5);
	}

	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest4", undefined, 1, true );
}

ctt1_full_vox()
{
	level waittill( "ctt_aud_note" );

	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest4", undefined, 2, true );
}

vox_override_while_near_tank()
{
	while( !flag( "sam_switch_thrown" ) )
	{
		while( level.zones["generator_zone"].is_occupied )
		{
			level.skit_vox_override = true;

			if( flag( "sam_switch_thrown" ) )
			{
				break;
			}

			wait(1);
		}

		level.skit_vox_override = false;
		wait(1);
	}

	level.skit_vox_override = true;
	wait(10);
	level.skit_vox_override = false;
}

setup_and_play_ctt2_vox()
{
	//level thread ctt2_full_vox();
	level thread vox_override_while_near_tank2();
}

ctt2_full_vox()
{
	level waittill( "ctt_aud_note" );

	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest6", undefined, 6, true );
}

vox_override_while_near_tank2()
{
	while( !flag( "cvg_placed" ) )
	{
		while( level.zones["generator_zone"].is_occupied )
		{
			level.skit_vox_override = true;

			if( flag( "cvg_placed" ) )
			{
				break;
			}

			wait(1);
		}

		level.skit_vox_override = false;
		wait(1);
	}

	level.skit_vox_override = true;
	wait(10);
	level.skit_vox_override = false;
}
