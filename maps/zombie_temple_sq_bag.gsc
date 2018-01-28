/* zombie_temple_sq_bag.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 8.
 *						Bang a Gong.
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

	flag_init("given_dynamite");
	flag_init("dynamite_chat");

	declare_sidequest_stage("sq", "BaG", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "BaG", 5 * 60);	// 5 minute limit.
	//declare_stage_title("sq", "BaG", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_8_TITLE");

}

bag_debug()
{
//	level endon("sq_BaG_over"); // Kill logic func if it's still running.

	if(IsDefined(level._debug_bag))
	{
		return;
	}

	if(!IsDefined(level._debug_bag))
	{
		level._debug_bag = true;

		level._hud_gongs = NewDebugHudElem();
		level._hud_gongs.location = 0;
		level._hud_gongs.alignX = "left";
		level._hud_gongs.alignY = "middle";
		level._hud_gongs.foreground = 1;
		level._hud_gongs.fontScale = 1.3;
		level._hud_gongs.sort = 20;
		level._hud_gongs.x = 10;
		level._hud_gongs.y = 240;
		level._hud_gongs.og_scale = 1;
		level._hud_gongs.color = (255,255,255);
		level._hud_gongs.alpha = 1;

		level._hud_gongs_label = NewDebugHudElem();
		level._hud_gongs_label.location = 0;
		level._hud_gongs_label.alignX = "right";
		level._hud_gongs_label.alignY = "middle";
		level._hud_gongs_label.foreground = 1;
		level._hud_gongs_label.fontScale = 1.3;
		level._hud_gongs_label.sort = 20;
		level._hud_gongs_label.x = 0;
		level._hud_gongs_label.y = 240;
		level._hud_gongs_label.og_scale = 1;
		level._hud_gongs_label.color = (255, 255,255);
		level._hud_gongs_label.alpha = 1;
		level._hud_gongs_label SetText("Gongs: ");

		level._ringing = NewDebugHudElem();
		level._ringing.location = 0;
		level._ringing.alignX = "left";
		level._ringing.alignY = "middle";
		level._ringing.foreground = 1;
		level._ringing.fontScale = 1.3;
		level._ringing.sort = 20;
		level._ringing.x = 10;
		level._ringing.y = 270;
		level._ringing.og_scale = 1;
		level._ringing.color = (255,255,255);
		level._ringing.alpha = 1;

		level._ringing_label = NewDebugHudElem();
		level._ringing_label.location = 0;
		level._ringing_label.alignX = "right";
		level._ringing_label.alignY = "middle";
		level._ringing_label.foreground = 1;
		level._ringing_label.fontScale = 1.3;
		level._ringing_label.sort = 20;
		level._ringing_label.x = 0;
		level._ringing_label.y = 270;
		level._ringing_label.og_scale = 1;
		level._ringing_label.color = (255, 255,255);
		level._ringing_label.alpha = 1;
		level._ringing_label SetText("Ringing: ");

		level._resonating = NewDebugHudElem();
		level._resonating.location = 0;
		level._resonating.alignX = "left";
		level._resonating.alignY = "middle";
		level._resonating.foreground = 1;
		level._resonating.fontScale = 1.3;
		level._resonating.sort = 20;
		level._resonating.x = 10;
		level._resonating.y = 300;
		level._resonating.og_scale = 1;
		level._resonating.color = (255,255,255);
		level._resonating.alpha = 1;

		level._resonating_label = NewDebugHudElem();
		level._resonating_label.location = 0;
		level._resonating_label.alignX = "right";
		level._resonating_label.alignY = "middle";
		level._resonating_label.foreground = 1;
		level._resonating_label.fontScale = 1.3;
		level._resonating_label.sort = 20;
		level._resonating_label.x = 0;
		level._resonating_label.y = 300;
		level._resonating_label.og_scale = 1;
		level._resonating_label.color = (255, 255,255);
		level._resonating_label.alpha = 1;
		level._resonating_label SetText("Rezanating: ");
	}

	gongs = GetEntArray("sq_gong", "targetname");

	while(1)
	{
		if(IsDefined(level._num_gongs))
		{
			level._hud_gongs SetValue(level._num_gongs);
		}
		else
		{
			level.selected_tile1 SetValue("-1");
		}

		gong_text = "";

		for(i = 0; i < gongs.size; i ++)
		{
			if(IsDefined(gongs[i].ringing) && gongs[i].ringing)
			{
				gong_text += "x";
			}
			else
			{
				gong_text += "o";
			}
		}

		level._ringing SetText(gong_text);

		if(flag("gongs_resonating"))
		{
			level._resonating_label SetText("Yes");
		}
		else
		{
			level._resonating_label SetText("No");
		}

		wait(0.05);
	}
}

init_stage()
{
	maps\zombie_temple_sq_brock::delete_radio();
	level notify("bag_start");

	flag_clear("given_dynamite");
	flag_clear("dynamite_chat");

//	level._num_gongs = 0;

	gongs = GetEntArray("sq_gong", "targetname");
	array_thread(gongs, ::gong_handler);

	level thread give_me_the_boom_stick();

	maps\zombie_temple_sq::reset_dynamite();

	level thread delayed_start_skit();
}

delayed_start_skit()
{
	wait(.5);
	level thread maps\zombie_temple_sq_skits::start_skit("tt8");
}

dynamite_debug()
{
	self endon("caught");

	while(1)
	{
		Print3d(self.origin, "+", (0,255,0), 2);
		wait(0.1);
	}
}

fire_in_the_hole()
{
	self endon("caught");
	self.dropped = true;
	self Unlink();

	dest = getstruct(self.target, "targetname");

	level.catch_trig = Spawn( "trigger_radius", self.origin, 0, 24, 10 );
	level.catch_trig EnableLinkTo();
	level.catch_trig LinkTo( self );
	level.catch_trig.owner_ent = self;
	level.catch_trig thread butter_fingers();

	/#
	self thread dynamite_debug();
	#/

	self NotSolid();
	self MoveTo( dest.origin, 1.4, 0.2, 0 );
	self waittill("movedone");

//	if(get_players().size > 1)
//	{
		players = get_players();
		players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 5 );
		playsoundatposition( "evt_sq_bag_dynamite_explosion", dest.origin );
		level.catch_trig notify("boom");
		level.catch_trig Delete();
		level.catch_trig = undefined;
		stage_failed("sq", "BaG");
//	}
//	else
//	{
		//IPrintLn("Dynamite would have exploded...");
//	}
}

butter_fingers()
{
	self endon("boom");
	self endon("death");

	while(1)
	{
		self waittill("trigger", who);

		if(IsDefined(who) && is_player_valid(who))
		{
			who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 6 );
			who playsound( "evt_sq_bag_dynamite_catch" );
			who._has_dynamite = true;
			self.owner_ent notify("caught");
			self.owner_ent Hide();
			who add_sidequest_icon("sq", "dynamite");
			self Delete();
			break;
		}
	}
}

give_me_the_boom_stick()
{
	level endon("sq_BaG_over");
	wall = GetEnt("sq_wall", "targetname");
	//wall Solid();

	flag_wait("meteorite_shrunk");

	player_close = false;
	player = undefined;

	while(!player_close)
	{
		players = get_players();

		for(i = 0; i < players.size; i ++)
		{
			if(distance2dsquared(players[i].origin, wall.origin) < 240 * 240)
			{
				player_close = true;
				player = players[i];
				break;
			}
		}
		wait(0.1);
	}

	level bag_story_vox_pt1( player );

	flag_set("dynamite_chat");

	level._give_trig = Spawn("trigger_radius_use", wall.origin, 0, 56, 72);

	level._give_trig SetCursorHint( "HINT_NOICON" );
	level._give_trig.radius = 48;
	level._give_trig.height = 72;

	not_given = true;

	while(not_given)
	{
		level._give_trig waittill("trigger", who);

		if(IsPlayer(who) && is_player_valid(who) && IsDefined(who._has_dynamite) && who._has_dynamite)
		{
			who._has_dynamite = undefined;
			who remove_sidequest_icon("sq", "dynamite");
			not_given = false;
		}
	}

	level notify("suspend_timer");

	level._give_trig Delete();
	level._give_trig = undefined;

	level bag_story_vox_pt2();

	players_far = 0;

	players = get_players();

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
	}

	flag_set("given_dynamite");

}

stage_logic()
{

	flag_wait("meteorite_shrunk");

	flag_set("pap_override");

	flag_wait("dynamite_chat");

	flag_wait("given_dynamite");

	wait(5.0);

	stage_completed("sq", "BaG");

}

exit_stage(success)
{
	if(success)
	{
		maps\zombie_temple_sq_brock::create_radio(9, maps\zombie_temple_sq_brock::radio9_override);
		level._buttons_can_reset = false;
	}
	else
	{
		maps\zombie_temple_sq_brock::create_radio(8);

		flag_clear("meteorite_shrunk");
		ent = GetEnt("sq_meteorite", "targetname");
		ent.origin = ent.original_origin;
		ent.angles = ent.original_angles;
		ent SetModel("p_ztem_meteorite");

		maps\zombie_temple_sq::reset_dynamite();
		flag_clear("pap_override");
		level thread maps\zombie_temple_sq_skits::fail_skit();
	}

	if(IsDefined(level.catch_trig))
	{
		level.catch_trig Delete();
		level.catch_trig = undefined;
	}

	players = get_players();

	for(i = 0; i < players.size; i ++)
	{
		if(IsDefined(players[i]._has_dynamite))
		{
			players[i]._has_dynamite = undefined;
			players[i] remove_sidequest_icon("sq", "dynamite");

		}
	}

	if(IsDefined(level._give_trig))
	{
		level._give_trig Delete();
	}

	gongs = GetEntArray("sq_gong", "targetname");

	array_thread(gongs, ::dud_gong_handler);

	if( isdefined( level._bag_sound_ent ) )
	{
		level._bag_sound_ent delete();
		level._bag_sound_ent = undefined;
	}

	level.skit_vox_override = false;
}

resonate_runner()
{
	if(!IsDefined(level._resonate_time) || level._resonate_time == 0)
	{
		level._resonate_time = 60;
	}
	else
	{
		level._resonate_time += 60;
		return;
	}

	level endon("wrong_gong");
	flag_set("gongs_resonating");

	while(level._resonate_time)
	{
		level._resonate_time --;
		wait(1.0);
	}

	flag_clear("gongs_resonating");
}

gong_resonate( player )
{
	level endon("kill_resonate");

	if(level.gamemode != "survival")
	{
		return;
	}

	self.ringing = true;

	if( is_true( self.right_gong ) )
	{
		self playloopsound( "evt_sq_bag_gong_correct_loop_" + level._num_gongs, 5 );
	}
	else
	{
		self playsound( "evt_sq_bag_gong_incorrect" );
	}

	if(level._num_gongs == 4)
	{
		level thread resonate_runner();
	}

	if( isdefined( player ) && isPlayer( player ) )
	{
		if( self.right_gong && level._num_gongs == 1 )
		{
			player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 1 );
		}
		else if( self.right_gong && flag("gongs_resonating") )
		{
			player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 2 );
		}
		else if( !self.right_gong )
		{
			player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest8", undefined, 0 );
		}
	}

	if(self.right_gong == false)
	{
		level notify("wrong_gong");
		level._resonate_time = 0;

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

					gongs[i] stoploopsound( 5 );
				}
			}

			gongs[i].ringing = false;
		}

//		flag_clear("gongs_resonating");

		level notify("kill_resonate");

	}

	wait(60);

	if(self.right_gong && level._num_gongs >= 0)
	{
		level._num_gongs --;
	}


	self.ringing = false;

	self stoploopsound( 5 );
}

gong_goes_bong(in_stage, player)
{
	if(self.right_gong && level._num_gongs < 4)
	{
		level._num_gongs ++;
	}

	self thread gong_resonate( player );

}

gong_handler()
{
	level endon("sq_BaG_over");

	if(!IsDefined(self.ringing))
	{
		self.ringing = false;
	}

	self thread debug_gong();


	while(1)
	{
		self waittill("triggered", who);

		if(!self.ringing)
		{
			self playsound( "evt_sq_bag_gong_hit" );
			self gong_goes_bong(true, who);
		}
	}
}

debug_gong()
{
	level endon("bag_start");
	level endon("sq_BaG_over");

	while(1)
	{
		if(!self.ringing && self.right_gong)
		{
			Print3d(self.origin + (0,0,64), "+", (0,255,0), 1);
		}
		wait(0.1);
	}
}

gong_wobble()
{
	if(IsDefined(self.wobble_threaded))
	{
		return;
	}

	self.wobble_threaded = true;

	while(1)
	{
		self waittill("triggered");
		self playsound( "evt_sq_bag_gong_hit" );
		self thread maps\_anim::anim_single(self, "ring");
	}
}

dud_gong_handler()
{
	level endon("bag_start");

//	level thread bag_debug();

	self thread gong_wobble();

	if(!IsDefined(self.ringing))
	{
		self.ringing = false;
	}

	self thread debug_gong();

	while(1)
	{
		self waittill("triggered");

		if(!self.ringing)
		{
			self gong_goes_bong(false);
		}
	}
}

bag_story_vox_pt1( player )
{
	level endon("sq_StD_over");

	struct = getstruct( "sq_location_bag", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}

	level._bag_sound_ent = spawn( "script_origin", struct.origin );

	level._bag_sound_ent playsound( "vox_egg_story_5_0", "sounddone" );
	level._bag_sound_ent waittill( "sounddone" );

	level._bag_sound_ent playsound( "vox_egg_story_5_1", "sounddone" );
	level._bag_sound_ent waittill( "sounddone" );

	level._bag_sound_ent playsound( "vox_egg_story_5_2", "sounddone" );
	level._bag_sound_ent waittill( "sounddone" );

	if( isdefined( player ) )
	{
		level.skit_vox_override = true;
		player playsound( "vox_egg_story_5_3" + maps\zombie_temple_sq::get_variant_from_entity_num( player.entity_num ), "vox_egg_sounddone" );
		player waittill( "vox_egg_sounddone" );
		level.skit_vox_override = false;
	}

	level._bag_sound_ent playsound( "vox_egg_story_5_4", "sounddone" );
	level._bag_sound_ent waittill( "sounddone" );

	level._bag_sound_ent playsound( "vox_egg_story_5_5", "sounddone" );
	level._bag_sound_ent waittill( "sounddone" );

	level._bag_sound_ent delete();
	level._bag_sound_ent = undefined;
}

bag_story_vox_pt2()
{
	level endon("sq_StD_over");

	struct = getstruct( "sq_location_bag", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}

	level._bag_sound_ent = spawn( "script_origin", struct.origin );

	level._bag_sound_ent playsound( "vox_egg_story_5_7", "sounddone" );
	level._bag_sound_ent waittill( "sounddone" );

	level._bag_sound_ent playsound( "vox_egg_story_5_8", "sounddone" );
	level._bag_sound_ent waittill( "sounddone" );

	level._bag_sound_ent delete();
	level._bag_sound_ent = undefined;
}
