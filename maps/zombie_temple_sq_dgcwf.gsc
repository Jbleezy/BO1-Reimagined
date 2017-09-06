/* zombie_temple_sq_dgcwf.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 2.
 *						Don't Go Chasing Waterfalls.
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

	flag_init("dgcwf_on_plate");
	flag_init("dgcwf_sw1_pressed");
	flag_init("dgcwf_plot_vo_done");

	level._on_plate = 0;

	declare_sidequest_stage("sq", "DgCWf", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "DgCWf", 5 * 60);	// 5 minute limit.
//	declare_stage_title("sq", "DgCWf", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_2_TITLE");
	declare_stage_asset_from_struct("sq", "DgCWf", "sq_dgcwf_sw1", ::sw1_thread, ::sw1_press);
	declare_stage_asset("sq", "DgCWf", "sq_dgcwf_trig", ::plate_trigger);

}

plate_counter()
{
	self endon("death");

	while(1)
	{
		if(level._on_plate >= 3 && !flag("dgcwf_on_plate"))
		{
			flag_set("dgcwf_on_plate");
		}
		else
		{
			if(flag("dgcwf_on_plate") && level._on_plate < 3)
			{
				flag_clear("dgcwf_on_plate");
			}
		}

		wait(0.05);
	}
}

plate_debug()
{
	level endon("sq_DgCWf_over"); // Kill logic func if it's still running.

	if(!IsDefined(level._debug_plate))
	{
		level._debug_plate = true;

		level.on_plate_val = NewDebugHudElem();
		level.on_plate_val.location = 0;
		level.on_plate_val.alignX = "left";
		level.on_plate_val.alignY = "middle";
		level.on_plate_val.foreground = 1;
		level.on_plate_val.fontScale = 1.3;
		level.on_plate_val.sort = 20;
		level.on_plate_val.x = 10;
		level.on_plate_val.y = 240;
		level.on_plate_val.og_scale = 1;
		level.on_plate_val.color = (255,255,255);
		level.on_plate_val.alpha = 1;

		level.on_plate_text = NewDebugHudElem();
		level.on_plate_text.location = 0;
		level.on_plate_text.alignX = "right";
		level.on_plate_text.alignY = "middle";
		level.on_plate_text.foreground = 1;
		level.on_plate_text.fontScale = 1.3;
		level.on_plate_text.sort = 20;
		level.on_plate_text.x = 0;
		level.on_plate_text.y = 240;
		level.on_plate_text.og_scale = 1;
		level.on_plate_text.color = (255, 255,255);
		level.on_plate_text.alpha = 1;
		level.on_plate_text SetText("Plate : ");
	}

	while(1)
	{
		if(IsDefined(level._on_plate))
		{
			level.on_plate_val SetValue(level._on_plate);
		}
		wait(0.1);
	}
}

restart_plate_mon(trig)
{
	trig endon("death");
	level endon("sq_DgCWf_over");

	self waittill("spawned_player");

	self thread plate_monitor(trig);
}

plate_monitor(trig)
{
	self endon("disconnect");
	trig endon("death");
	level endon("sq_DgCWf_over");

	while(1)
	{
		while(!self IsTouching(trig))
		{
			wait(0.1);
		}

		if(level._on_plate < 4)
		{
			level._on_plate ++;
		}

		trig playsound( "evt_sq_dgcwf_plate_" + level._on_plate );

		if( level._on_plate <= 2 && !flag( "dgcwf_sw1_pressed" ) )
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest2", undefined, 0 );
		}
		else
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest2", undefined, 1 );
		}

		while(self IsTouching(trig) && self.sessionstate != "spectator")
		{
			wait(0.05);
		}

		if(level._on_plate >= 0)
		{
			level._on_plate --;
		}

		if(self.sessionstate == "spectator")
		{
			self thread restart_plate_mon(trig);
			return;
		}

		if( level._on_plate < 3 && !flag( "dgcwf_sw1_pressed" ) )
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest2", undefined, 2 );
		}
	}
}

plate_trigger()
{
	self endon("death");

	self thread play_success_audio();
	self thread begin_dgcwf_vox();

	self playloopsound( "evt_sq_dgcwf_waterthrash_loop", 2 );

	flag_set("dgcwf_on_plate");
	/*return;

	/#
	level thread plate_debug();
	#/

	self thread plate_counter();

	players = get_players();

	for(i = 0; i < players.size; i ++)
	{
		players[i] thread plate_monitor(self);
	}*/
}

begin_dgcwf_vox()
{
	self endon("death");

	while(1)
	{
		self waittill( "trigger", who );
		if( isPlayer(who) )
		{
			self stoploopsound( 1 );
			who thread dgcwf_story_vox();
			return;
		}

		wait(0.05);
	}
}

sw1_press()
{
	self endon("death");

	while(1)
	{
		self waittill("trigger", who );
		who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest2", undefined, 3 );
		self.owner_ent.pressed = true;
	}
}

sw1_thread()
{
	self endon("death");

	self.on_pos = self.origin;
	self.off_pos = self.on_pos - (AnglesToRight(self.angles) * 36);

	self.origin = self.off_pos;

	self.trigger trigger_off();

	self.pressed = false;

	while(1)
	{
		if(flag("dgcwf_on_plate"))
		{
			self.pressed = false;
			self moveto(self.on_pos, 0.25);
			self playsound( "evt_sq_dgcwf_lever_kachunk" );
			self waittill("movedone");

			self.trigger trigger_on();

			while(flag("dgcwf_on_plate"))
			{
				if(self.pressed)
				{
					self playsound( "evt_sq_dgcwf_lever_success" );
					self RotateRoll(75, 0.15);
					self.trigger trigger_off();
					flag_set("dgcwf_sw1_pressed");

					return;
				}
				wait(0.05);
			}
		}
		else
		{
			self.pressed = false;
			self.trigger trigger_off();
			self playsound( "evt_sq_dgcwf_lever_dechunk" );
			self moveto(self.off_pos, 0.25);
			self waittill("movedone");

			while(!flag("dgcwf_on_plate"))
			{
				wait(0.05);
			}
		}

		wait(0.05);
	}

}

init_stage()
{

	level._on_plate = 0;

	/*if(get_players().size > 1)
	{
		flag_clear("dgcwf_on_plate");
	}*/

	flag_clear("dgcwf_sw1_pressed");
	flag_clear("dgcwf_plot_vo_done");

	trig = GetEnt("sq_dgcwf_trig", "targetname");

	trig trigger_on();

	maps\zombie_temple_sq_brock::delete_radio();

	level thread delayed_start_skit();
}

delayed_start_skit()
{
	wait(.5);
	level thread maps\zombie_temple_sq_skits::start_skit("tt2");
}

stage_logic()
{
	level endon("sq_DgCWf_over");

	flag_wait("dgcwf_on_plate");
	flag_wait("dgcwf_sw1_pressed");

	level notify( "suspend_timer" );
	level notify("raise_crystal_1");
	level notify("raise_crystal_2", true);

	level thread slightly_delayed_player_response();

	level waittill("raised_crystal_2");

	flag_wait("dgcwf_plot_vo_done");
	wait(5);

	level thread stage_completed("sq", "DgCWf");
}

slightly_delayed_player_response()
{
	wait(2.5);

	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest2", undefined, 4 );
}

play_success_audio()
{
	level endon("sq_DgCWf_over");

	flag_wait("dgcwf_on_plate");
	flag_wait("dgcwf_sw1_pressed");

	self playsound( "evt_sq_dgcwf_gears" );
}

exit_stage(success)
{
	if(IsDefined(level._debug_plate))
	{
		level._debug_plate = undefined;

		level.on_plate_val Destroy();
		level.on_plate_val = undefined;

		level.on_plate_text Destroy();
		level.on_plate_text = undefined;
	}

	trig = GetEnt("sq_dgcwf_trig", "targetname");
	trig trigger_off();

	if(success)
	{
		maps\zombie_temple_sq_brock::create_radio(3);
	}
	else
	{
		maps\zombie_temple_sq_brock::create_radio(2, maps\zombie_temple_sq_brock::radio2_override);
		level thread maps\zombie_temple_sq_skits::fail_skit();
	}

	level.skit_vox_override = false;
	if( isdefined( level._dgcwf_sound_ent ) )
	{
		level._dgcwf_sound_ent delete();
		level._dgcwf_sound_ent = undefined;
	}
}

dgcwf_story_vox()
{
	level endon("sq_DgCWf_over");

	struct = getstruct( "sq_location_dgcwf", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}

	level._dgcwf_sound_ent = spawn( "script_origin", struct.origin );

	if(!flag("dgcwf_sw1_pressed"))
	{
		if( isdefined( self ) )
		{
			level.skit_vox_override = true;
			self playsound( "vox_egg_story_2_0" + maps\zombie_temple_sq::get_variant_from_entity_num( self.entity_num ), "vox_egg_sounddone" );
			self waittill( "vox_egg_sounddone" );
			level.skit_vox_override = false;
		}

		level._dgcwf_sound_ent playsound( "vox_egg_story_2_1", "sounddone" );
		level._dgcwf_sound_ent waittill( "sounddone" );

		if( isdefined( self ) )
		{
			level.skit_vox_override = true;
			self playsound( "vox_egg_story_2_2" + maps\zombie_temple_sq::get_variant_from_entity_num( self.entity_num ), "vox_egg_sounddone" );
			self waittill( "vox_egg_sounddone" );
			level.skit_vox_override = false;
		}
	}

	flag_wait("dgcwf_sw1_pressed");

	level._dgcwf_sound_ent playsound( "vox_egg_story_2_3", "sounddone" );
	level._dgcwf_sound_ent waittill( "sounddone" );

	flag_set("dgcwf_plot_vo_done");

	level._dgcwf_sound_ent delete();
	level._dgcwf_sound_ent = undefined;
}
