/* zombie_temple_sq_std.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 5.
 *						Spike the Dikes
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

	PrecacheModel("p_ztem_spikemore_spike");

	declare_sidequest_stage("sq", "StD", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "StD", 5 * 60);	// 5 minute limit.
//	declare_stage_title("sq", "StD", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_5_TITLE");
	declare_stage_asset_from_struct("sq", "StD", "sq_sad", ::target_thread);

	flag_init("std_target_1");
	flag_init("std_target_2");
	flag_init("std_target_3");
	flag_init("std_target_4");
	flag_init("std_plot_vo_done");
}

init_stage()
{
	clientnotify("SR");
	flag_clear("std_target_1");
	flag_clear("std_target_2");
	flag_clear("std_target_3");
	flag_clear("std_target_4");
	flag_clear("std_plot_vo_done");
	
	level thread delayed_start_skit();
	level thread play_waterthrash_loop();
	maps\zombie_temple_sq_brock::delete_radio();
}

delayed_start_skit()
{
	wait(.5);
	level thread maps\zombie_temple_sq_skits::start_skit("tt5");
}

play_waterthrash_loop()
{
	level endon( "sq_StD_over" );
	
	struct = getstruct( "sq_location_std", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}
	
	level._std_sound_waterthrash_ent = spawn( "script_origin", struct.origin );
	level._std_sound_waterthrash_ent playloopsound( "evt_sq_std_waterthrash_loop", 2 );
	
	level waittill( "sq_std_story_vox_begun" );
	
	level._std_sound_waterthrash_ent stoploopsound( 5 );
	wait(5);
	
	level._std_sound_waterthrash_ent delete();
	level._std_sound_waterthrash_ent = undefined;
}

target_debug()
{
	self endon("death");
	self endon("spiked");
	
	while(1)
	{
		Print3d(self.origin, "+", (0, 255, 0), 1);
		wait(0.1);
	}
}

target_thread()
{
	maps\_zombiemode_spikemore::add_spikeable_object(self);
	self thread target_debug();
	self thread begin_std_story_vox();
	self thread player_hint_line();
	self thread player_first_success();
	
	self playsound( "evt_sq_std_spray_start" );
	self playloopsound( "evt_sq_std_spray_loop", 1 );
	
	self waittill("spiked");
	
	self stoploopsound( 1 );
	self playsound( "evt_sq_std_spray_stop" );
	
	flag_set("std_target_" + self.script_int);
	
	clientnotify("S" + self.script_int);
	
//	IPrintLnBold("StD target " + self.script_int + " spiked!");
	
	maps\_zombiemode_spikemore::remove_spikeable_object(self);
	
}

player_first_success()
{
	self endon( "death" );
	level endon( "sq_std_first" );
	
	self waittill( "spiked", who );
	
	who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 1 );
	level notify( "sq_std_first" );
}

player_hint_line()
{
	self endon( "death" );
	level endon( "sq_std_hint_given" );
	
	level waittill( "sq_std_hint_line" );
	
	while(1)
	{
		players = get_players();
		
		for(i=0;i<players.size;i++)
		{
			if( (isdefined( self.origin ) ) && distancesquared( self.origin, players[i].origin ) <= 100 * 100 )
			{
				players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 0 );
				level notify( "sq_std_hint_given" );
				return;
			}
		}
		
		wait(.1);
	}
}

begin_std_story_vox()
{
	self endon( "death" );
	level endon( "sq_std_story_vox_begun" );
	
	while(1)
	{
		players = get_players();
		
		for(i=0;i<players.size;i++)
		{
			if( distancesquared( self.origin, players[i].origin ) <= 100 * 100 )
			{
				level thread std_story_vox( players[i] );
				level notify( "sq_std_story_vox_begun" );
				return;
			}
		}
		
		wait(.1);
	}
}

stage_logic()
{
	
	flag_wait("std_target_1");
	flag_wait("std_target_2");
	flag_wait("std_target_3");
	flag_wait("std_target_4");
	
	players = get_players();
	players[randomintrange(0,players.size)] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 2 );

	level waittill("waterfall");
	
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if( isdefined( players[i].used_waterfall ) && players[i].used_waterfall == true )
		{
			players[i] thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest5", undefined, 3 );
		}
	}

	level notify( "suspend_timer" );
	level notify("raise_crystal_1");
	level notify("raise_crystal_2");
	level notify("raise_crystal_3");
	level notify("raise_crystal_4");
	level notify("raise_crystal_5", true);
	level waittill("raised_crystal_5");	
	
	flag_wait("std_plot_vo_done");
	wait(5.0);
	
	stage_completed("sq", "StD");
	
}

exit_stage(success)
{
	targs = GetEntArray("sq_sad", "targetname");
	
	for(i = 0; i < targs.size; i ++)
	{
		maps\_zombiemode_spikemore::remove_spikeable_object(targs[i]);
	}
	
	clientnotify("ksd");
	
	flag_clear("std_target_1");
	flag_clear("std_target_2");
	flag_clear("std_target_3");
	flag_clear("std_target_4");
	
	if(success)
	{
		maps\zombie_temple_sq_brock::create_radio(6);
		maps\zombie_temple_sq::spawn_skel();
	}
	else
	{
		maps\zombie_temple_sq_brock::create_radio(5);
		level thread maps\zombie_temple_sq_skits::fail_skit();		
	}
	
	if( isdefined( level._std_sound_ent ) )
	{
		level._std_sound_ent delete();
		level._std_sound_ent = undefined;
	}
	
	if( isdefined( level._std_sound_waterthrash_ent ) )
	{
		level._std_sound_waterthrash_ent delete();
		level._std_sound_waterthrash_ent = undefined;
	}
}

std_story_vox( player )
{
	level endon("sq_StD_over");
	
	struct = getstruct( "sq_location_std", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}
	
	level._std_sound_ent = spawn( "script_origin", struct.origin );
	
	level thread std_story_vox_wait_for_finish();
	
	level._std_sound_ent playsound( "vox_egg_story_4_0", "sounddone" );
	level._std_sound_ent waittill( "sounddone" );
	
	if( isdefined( player ) )
	{
		level.skit_vox_override = true;
		player playsound( "vox_egg_story_4_1" + maps\zombie_temple_sq::get_variant_from_entity_num( player.entity_num ), "vox_egg_sounddone" );
		player waittill( "vox_egg_sounddone" );
		level.skit_vox_override = false;
	}
	
	level notify( "sq_std_hint_line" );
}

std_story_vox_wait_for_finish()
{
	level endon("sq_StD_over");
	count = 0;
	
	while(1)
	{
		level waittill("waterfall");
		{
			if( !flag("std_target_1") || !flag("std_target_2") || !flag("std_target_3") || !flag("std_target_4") )
			{
				if( count < 1 )
				{
					level._std_sound_ent playsound( "vox_egg_story_4_2", "sounddone" );
					level._std_sound_ent waittill( "sounddone" );
					count++;
				}
			}
			else
			{
				level._std_sound_ent playsound( "vox_egg_story_4_3", "sounddone" );
				level._std_sound_ent waittill( "sounddone" );
				break;
			}
		}
	}
	
	flag_set("std_plot_vo_done");
	
	level._std_sound_ent delete();
	level._std_sound_ent = undefined;
}