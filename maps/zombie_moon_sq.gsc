/* zombie_moon_sq.gsc
 *
 * Purpose : 	Sidequest declaration and global side-quest logic for zombie_moon.
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
	PreCacheModel("p_zom_moon_py_collector_fill");
	PreCacheModel("p_zom_moon_py_collector");
	PreCacheModel("p_zom_moon_py_capacitor");
	PreCacheModel("p_glo_data_recorder01_static_reel");

	//declare_stage_asset_from_struct("sq", "ss1", "sq_ss_button", ::sq_ss_button_thread );

	ss_buttons = GetEntArray("sq_ss_button", "targetname");

	for(i = 0; i < ss_buttons.size; i ++)
	{
		ss_buttons[i] UseTriggerRequireLookAt();
		ss_buttons[i] SetHintString("");
		ss_buttons[i] SetCursorHint("HINT_NOICON");
	}

	// SQ flags

	flag_init("first_tanks_charged");
	flag_init("second_tanks_charged");
	flag_init("first_tanks_drained");
	flag_init("second_tanks_drained");
	flag_init("c_built");
	flag_init("vg_charged");
	flag_init("switch_done");
	flag_init("be2");
	flag_init("ss1");
	flag_init("soul_swap_done");

	// Main sidequest.
	declare_sidequest("sq", ::init_sidequest, ::sidequest_logic, ::complete_sidequest, ::generic_stage_start, ::generic_stage_complete);

	declare_sidequest_icon(	"sq", "vril", "zom_hud_icon_vril");
	declare_sidequest_icon( "sq", "anti115", "zom_hud_icon_meteor" );
	declare_sidequest_icon( "sq", "generator", "hud_icon_vril_combo" );
	declare_sidequest_icon( "sq", "cgenerator", "hud_icon_vril_combo_select" );
	declare_sidequest_icon( "sq", "wire", "hud_icon_wire" );
	declare_sidequest_icon( "sq", "datalog", "zom_icon_theater_reel");

	// Stage inits here.

	maps\zombie_moon_sq_ss::init_1();
	maps\zombie_moon_sq_ss::init_2();
	maps\zombie_moon_sq_osc::init();
	maps\zombie_moon_sq_sc::init();
	maps\zombie_moon_sq_sc::init_2();

//	maps\zombie_moon_sq_ss::init_2();



	// Sub sidequests

	declare_sidequest("tanks", undefined, undefined, undefined, undefined, undefined);
	maps\zombie_moon_sq_ctt::init_1();
	maps\zombie_moon_sq_ctt::init_2();

	declare_sidequest("ctvg", undefined, undefined, undefined, undefined, undefined);
	maps\zombie_moon_sq_ctvg::init();

	declare_sidequest("be", undefined, undefined, undefined, undefined, undefined);
	maps\zombie_moon_sq_be::init();

	precache_sidequest_assets();
}

reward()
{
	level notify("moon_sidequest_achieved");

	players = get_players();

	array_thread(players, ::give_perk_reward);
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

give_perk_reward()
{

	if(IsDefined(self._retain_perks))
	{
		return;
	}

	if(!IsDefined(level._sq_perk_array))
	{
		level._sq_perk_array = [];

		machines = GetEntArray( "zombie_vending", "targetname" );

		for(i = 0; i < machines.size; i ++)
		{
			level._sq_perk_array[level._sq_perk_array.size] = machines[i].script_noteworthy;
		}
	}

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


start_moon_sidequest()
{
	flag_wait( "all_players_spawned" );

	/*while(level._num_overriden_models < (GetNumExpectedPlayers()))
	{
		wait(0.1);
	}*/

	sidequest_start("sq");
}

init_sidequest()
{
	players = get_players();

	level._all_previous_done = true;

	level._zombiemode_sidequest_icon_offset = -32;

	level.richtofen_in_game = false;

	entnums = [];

	for(i = 0; i < players.size; i ++)
	{
		entnum = players[i] GetEntityNumber();

		if( IsDefined( players[i].zm_random_char ) )
		{
			entnum = players[i].zm_random_char;
		}

		if(entnum == 3)
		{
			level.richtofen_in_game = true;
			break;
		}

		entnums[i] = entnum;
	}

	level.random_entnum = undefined;
	if(!level.richtofen_in_game)
	{
		level.random_entnum = entnums[RandomInt(entnums.size)];
	}

	if(level.gamemode == "survival")
	{
		for(i = 0; i < players.size; i ++)
		{
			entnum = players[i] GetEntityNumber();
			PrintLn("**** entnum " + entnum);

			if( IsDefined( players[i].zm_random_char ) )
			{
				entnum = players[i].zm_random_char;
			}

			if((level.richtofen_in_game && entnum == 3) || (!level.richtofen_in_game && entnum == level.random_entnum))
			{
				players[i] thread wait_add_sidequest_icon("sq", "generator");
				break;
			}
		}
	}

	level thread tanks();
	level thread cassimir();
	level thread be();

	level thread maps\zombie_moon_sq_datalogs::init();

	//if( 1 == GetDvarInt(#"scr_debug_launch"))
	//{
	//level thread rocket_test();
	//}

	level thread rocket_raise();
}

wait_add_sidequest_icon(p1, p2)
{
	level waittill("fade_introblack");
	self add_sidequest_icon(p1, p2);
}

rocket_test()
{
	flag_wait("power_on");

	wait(5);

	level notify("rl");

	wait(2);

	level notify("rl");

	wait(2);

	level notify("rl");

	level thread do_launch();
}

rocket_raise(player_num)
{
	rockets = GetEntArray("vista_rocket","targetname");

	array_thread(rockets, ::nml_show_hide);

	for(i = 0; i < rockets.size; i ++)
	{
		level waittill("rl");

		level clientnotify("R_R");

		rockets[i] playsound( "evt_rocket_move_up" );

		s = getstruct(rockets[i].target, "targetname");

		rockets[i] MoveTo(s.origin ,4);
		rockets[i] RotateTo( (0,0,0), 4);
	}

	level waittill("rl");

	array_thread(rockets, ::launch);
}

nml_show_hide()
{
	level endon("intermission");
	self endon("death");

	while(1)
	{
		flag_wait("enter_nml");
		self Hide(); //hide the rockets when back on earth
		flag_waitopen("enter_nml");
		self Show(); // show the rockets when back on moon
	}
}

launch()
{
	level clientnotify("R_L");
	wait(RandomFloatRange(0.1,1));

	self playsound( "evt_rocket_launch" );

	if(!IsDefined(level._n_rockets))
	{
		level._n_rockets = 0;
	}

	self.rocket_num = level._n_rockets;
	level._n_rockets ++;

	PrintLn("Rocket " + self.rocket_num + " launching!");
	PrintLn("Rocket " + self.rocket_num + " target : " + self.target);

	s = getstruct(self.target, "targetname");	// launch position.

	PrintLn("Rocket " + self.rocket_num + " target's target : " + s.target);

	if(IsDefined(s.target))
	{
		start = GetVehicleNode(s.target, "targetname");

		if(!IsDefined(start))
		{
			return;
		}

		origin_animate = Spawn( "script_model", start.origin );
		origin_animate SetModel( "tag_origin_animate" );
		self LinkTo( origin_animate, "origin_animate_jnt", ( 0, 0, 0 ), ( 0, 0, 0 ) );

		PlayFXOnTag( level._effect["rocket_booster"], self, "tag_origin" );

		vehicle = SpawnVehicle( "tag_origin", "rocket_mover", "misc_freefall", start.origin, start.angles );

		origin_animate LinkTo( vehicle );

		vehicle maps\_vehicle::getonpath( start );

		vehicle thread maps\_vehicle::gopath();

		vehicle waittill("reached_end_node");

		self Unlink();
		self delete();
		vehicle Delete();
		origin_animate Delete();
	}

}

sidequest_logic()
{
	level thread sq_flatcard_logic();
	flag_wait("power_on");

	stage_start("sq", "ss1");

	flag_wait("ss1");

	stage_start("sq", "osc");
	level waittill("sq_osc_over");
	flag_wait("complete_be_1");
	wait(4.0);
	stage_start("sq", "sc");
	level waittill("sq_sc_over");

	// This is as far as you can go, without having done the previous 2 sidequests.

	flag_wait("vg_charged");
	stage_start("sq", "sc2");

	level waittill("sq_sc2_over");

	wait(5.0);

	level thread maxis_story_vox();

	level waittill("sq_ss2_over");

	flag_wait("be2");

	level thread do_launch();
}

do_launch()
{
	level notify("start_launch");

	// launch logic here.
	play_sound_2d( "vox_xcomp_quest_step8_4" );
	wait(10);

	level notify("rl");

	wait(30);
	play_sound_2d( "vox_xcomp_quest_step8_5" );
	wait(30);

	play_sound_2d( "evt_earth_explode" );

	clientnotify("dte");
	wait_network_frame();
	wait_network_frame();
	exploder( 2012 );
	wait(2);
	if( !flag( "enter_nml" ) )
	{
		level clientnotify("H_E");
		level clientnotify("SDE");
	}

	level._dte_done = true;
	level notify("moon_sidequest_big_bang_achieved");

	play_sound_2d( "vox_xcomp_quest_laugh" );
	level thread play_end_lines_in_order();

	reward();
}

play_end_lines_in_order()
{
	level.skit_vox_override = true;

	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 7, true );

	wait(12);

	player = get_specific_player( 0 );
	if( isdefined( player ) )
	{
		player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 9, true );
		wait(5);
	}

	player = get_specific_player( 1 );
	if( isdefined( player ) )
	{
		player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 9, true );
		wait(5);
	}

	player = get_specific_player( 2 );
	if( isdefined( player ) )
	{
		player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 9, true );
		wait(5);
	}

	player = get_specific_player( 3 );
	if( isdefined( player ) )
	{
		player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 9, true );
		wait(5);
	}

	player = get_specific_player( 3 );
	if( isdefined( player ) )
	{
		player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 10, true );
	}

	level.skit_vox_override = false;
}

get_specific_player( num )
{
	players = get_players();
	for(i = 0; i < players.size; i ++)
	{
		ent_num = players[i] GetEntityNumber();

		if(IsDefined(players[i].zm_random_char))
		{
			ent_num = players[i].zm_random_char;
		}

		if(ent_num == num)
		{
			return players[i];
		}
	}

	return undefined;
}

maxis_story_vox()
{
	// Do announcement here...
	s = getstruct("sq_vg_final", "targetname");
	level.skit_vox_override = true;
	play_sound_in_space("vox_plr_3_quest_step6_9", s.origin);
	wait(2.3);
	play_sound_in_space("vox_plr_3_quest_step6_11", s.origin);
	wait(10.5);
	play_sound_in_space("vox_xcomp_quest_step6_14", s.origin);
	level.skit_vox_override = false;

	stage_start("sq", "ss2");
}

be()
{
	stage_start("be", "stage_one");
	level waittill("sq_sc2_over");
	wait(2.0);
	stage_start("be", "stage_two");
}

tanks()
{
	flag_wait("complete_be_1");
	wait(4.0);
	stage_start("tanks", "ctt1");

	level waittill("sq_sc_over");

	flag_wait("vg_charged");

	stage_start("tanks", "ctt2");

}

cassimir()
{
	stage_start("ctvg", "build");
	level waittill("ctvg_build_over");
	wait(5.0);
	stage_start("ctvg", "charge");
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
}

generic_stage_complete()
{
	level._stage_active = false;
}

complete_sidequest()
{
	level thread sidequest_done();
}

sidequest_done()
{
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


// hides earth when in nml
sq_flatcard_logic()
{
	//level endon( "end_game" );

	nml_set = false;


	while( true )
	{
		// watch for the nml flag
		if( flag( "enter_nml" ) && !nml_set )
		{
			// hide the exploders
			// need to check to see which one should be active
			if(!IsDefined(level._dte_done))
			{
				level clientnotify("H_E");
				//stop_exploder( 2011 );
			}
			else
			{
				level clientnotify("HDE");
				stop_exploder( 2012 );
			}

			SetSavedDvar("r_zombieDisableEarthEffect", 1);
			//stop_exploder( 2012 );

			// else
			// stop_exploder( 2012 );

			nml_set = true;
		}
		else if( !flag( "enter_nml" ) && nml_set )
		{
			// show the exploder
			// check to see which one should be showing
			if(!IsDefined(level._dte_done))
			{
				level clientnotify("S_E");
				//exploder( 2011 );
			}
			else
			{
				level clientnotify("SDE");
				exploder( 2012 );
			}


			SetSavedDvar("r_zombieDisableEarthEffect", 0);

			nml_set = false;
		}

		wait( 0.1 );

	}





}
