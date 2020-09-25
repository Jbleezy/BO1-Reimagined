/* zombie_moon_sq_sc.gsc
 *
 * Purpose : 	Sidequest stage logic for zombie_moon - sam chamber reveal.
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
	level._active_tanks = [];

	PreCacheModel("c_zom_moon_frozen_girl");

	flag_init("sam_switch_thrown");

	declare_sidequest_stage("sq", "sc", ::init_stage, ::stage_logic, ::exit_stage);
	declare_stage_asset("sq", "sc", "sq_knife_switch", ::sq_sc_switch );
}

init_2()
{
	flag_init("cvg_placed");
	declare_sidequest_stage("sq", "sc2", ::init_stage_2, ::stage_logic_2, ::exit_stage_2);
}

init_stage_2()
{
	level thread place_cvg();
}

stage_logic_2()
{
	flag_wait("second_tanks_drained");
	flag_wait("soul_swap_done");
	wait(1.0);

	stage_completed("sq", "sc2");
}

exit_stage_2(success)
{
}

init_stage()
{
}

wall_move()
{
	level thread wall_move_rumble();
	exploder(410);
	self moveto(self.origin - (0,0,4), 0.1, 0.01);
	self waittill("movedone");
	Earthquake(1, 1.3, self.origin, 2000);
	exploder(420);
	self RotateTo(self.script_angles, 3.5, 0.3, 0.5);
	self waittill("rotatedone");
	clientnotify("sm");
	wait(0.1);

	struct = getstruct("pyramid_walls_retract", "targetname");

	vec = VectorNormalize((struct.origin + (0,0,48)) - self.origin);

	pos = self.origin + (vec * 200);
	self moveto(pos, 2, 0.1, 0.1);

	level notify("walls_down");
}

wall_move_rumble()
{
	level clientnotify("p_r");
	level waittill("walls_down");
	level clientnotify("s_r");
}

reveal_music()
{
	wait(1.5);
	level.music_override = true;
	level thread maps\_zombiemode_audio::change_zombie_music( "sam_reveal" );
	wait(40);
	level.music_override = false;

	if( level.music_round_override == false )
	{
		level thread maps\_zombiemode_audio::change_zombie_music( "wave_loop" );
	}
}

stage_logic()
{
	flag_wait("first_tanks_drained");
	walls = GetEntArray("sq_pyramid_walls", "targetname");
	array_thread(walls, ::wall_move);

	level thread playsound_on_players_in_zone();
	level thread reveal_music();
	level thread sam_reveal_richtofen_vox();

	level waittill("walls_down");
	wait(1.0);

	players = get_players();
	array_thread(players, ::room_sweeper);

	stage_completed("sq", "sc");
}

playsound_on_players_in_zone()
{
	zone = level.zones[ "generator_zone" ];

	players = get_players();
	for (i = 0; i < zone.volumes.size; i++)
	{
		for (j = 0; j < players.size; j++)
		{
			if ( players[j] IsTouching(zone.volumes[i]) && !(players[j].sessionstate == "spectator"))
			{
				players[j] playsoundtoplayer( "evt_pyramid_open", players[j] );
			}
		}
	}
}

sam_reveal_richtofen_vox()
{
	wait(8);

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		index = maps\_zombiemode_weapons::get_player_index(players[i]);

		if( index == 3 )
		{
			players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest4", undefined, 3, true );
		}
	}
}

room_sweeper()
{
	while ( !is_player_valid( self ) ||
			( self UseButtonPressed() && self in_revive_trigger() ) )
	{
		wait( 1.0 );
	}

	level thread maps\_zombiemode_powerups::minigun_weapon_powerup( self, 90 );
	level.longer_minigun_reward = true;

	level thread dempsey_gersh_vox();

	level notify("moon_sidequest_reveal_achieved");
}

dempsey_gersh_vox()
{
	wait(5);

	player = maps\zombie_moon_sq::get_specific_player( 0 );

	if( isdefined( player ) )
	{
		player playsound( "vox_plr_0_stupid_gersh" );
	}
}

exit_stage(success)
{
}

sq_sc_switch()
{
	flag_wait("first_tanks_charged");

	self waittill("triggered");

	self rotateroll(-90,.3);
	self playsound("zmb_switch_flip");

	self waittill("rotatedone");
	PlayFX(level._effect["switch_sparks"] ,getstruct("sq_knife_switch_fx","targetname").origin);

	wait(1);

	flag_set("sam_switch_thrown");
}

do_soul_swap(who)
{
	maps\zombie_moon_amb::player_4_override();

	if(IsDefined(who))
	{
		if(level.richtofen_in_game)
		{
			who setclientflag(level._CLIENTFLAG_PLAYER_SOUL_SWAP);
		}

		//who maps\zombie_moon_sq::give_perk_reward();
	}

	wait(2.0);

	if(IsDefined(who))
	{
		if(level.richtofen_in_game)
		{
			who clearclientflag(level._CLIENTFLAG_PLAYER_SOUL_SWAP);
		}
	}

	level notify("moon_sidequest_swap_achieved");
}

place_qualifier()
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

	/*if(ent_num == 3)
	{
		return true;
	}*/

	return false;
}

richtofen_sam_vo()
{
	level endon("ss_done");

	level.skit_vox_override = true;

	players = get_players();

	richtofen = undefined;

	for(i = 0; i < players.size; i ++)
	{
		ent_num = players[i] GetEntityNumber();

		if(IsDefined(players[i].zm_random_char))
		{
			ent_num = players[i].zm_random_char;
		}

		if(ent_num == 3)
		{
			richtofen = players[i];
			break;
		}
	}

	if(!IsDefined(richtofen))
	{
		return;
	}

	richtofen PlaySound("vox_plr_3_quest_step6_7", "line_spoken");
	richtofen waittill("line_spoken");

	targ = getstruct("sq_sam", "targetname");
	targ = getstruct(targ.target, "targetname");

	play_sound_in_space("vox_plr_4_quest_step6_10", targ.origin);

	if(IsDefined(richtofen))
	{
		richtofen PlaySound("vox_plr_3_quest_step6_8", "line_spoken");
		richtofen waittill("line_spoken");
	}

	//play_sound_in_space("vox_plr_4_quest_step6_12", targ.origin);

	level.skit_vox_override = false;

}

place_cvg()
{
	flag_wait("second_tanks_charged");

	if(level.richtofen_in_game)
	{
		level thread richtofen_sam_vo();
	}

	s = getstruct("sq_vg_final", "targetname");

	s thread fake_use("placed_cvg", ::place_qualifier);
	s waittill("placed_cvg", who);
	flag_set("cvg_placed");
	clientnotify("vg");
	who remove_sidequest_icon("sq", "cgenerator");

	flag_wait("second_tanks_drained");

	level notify("ss_done");

	level thread do_soul_swap(who);

	flag_set("soul_swap_done");

	if(level.richtofen_in_game)
	{
		level thread play_sam_then_response_line();
	}

	level.skit_vox_override = false;
}

play_sam_then_response_line()
{
	wait(1);
	sam = undefined;
	players = get_players();
	for(i = 0; i < players.size; i ++)
	{
		ent_num = players[i] GetEntityNumber();

		if(IsDefined(players[i].zm_random_char))
		{
			ent_num = players[i].zm_random_char;
		}

		if(ent_num == 3)
		{
			sam = players[i];
			break;
		}
	}

	sam playsound( "vox_plr_4_quest_step6_12", "linedone" );
	sam waittill( "linedone" );

	if( !isdefined( sam ) )
	{
		return;
	}

	players = get_players();
	player = [];
	for(i=0;i<players.size;i++)
	{
		if( players[i] != sam )
		{
			player[i] = players[i];
		}
	}

	if( player.size <= 0 )
	{
		return;
	}

	player[randomintrange(0,player.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest6", undefined, 13, true );
}
