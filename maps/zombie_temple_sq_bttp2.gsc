/* zombie_temple_sq_bttp2.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 7.
 *						Backer to the pasterer.
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
	declare_sidequest_stage("sq", "bttp2", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "bttp2", 5 * 60, ::bttp2_timer_func);	// 5 minute limit.
//	declare_stage_title("sq", "bttp2", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_7_TITLE");
}

init_stage()
{
	level notify ("bttp2_start");

	level._num_dials_correct = 0;

	dials = GetEntArray("sq_bttp2_dial", "targetname");

	level._num_dials_to_match = dials.size;

	array_thread(dials, ::dial_handler);
	maps\zombie_temple_sq_brock::delete_radio();

	if(flag("radio_7_played"))
	{
		level thread delayed_start_skit("tt7a");
	}
	else
	{
		level thread delayed_start_skit("tt7b");
	}

	level thread bolt_from_the_blue();

}

delayed_start_skit( skit )
{
	wait(.5);
	level thread maps\zombie_temple_sq_skits::start_skit(skit);
}

bolt_from_the_blue()
{
	wait(25);
	a_struct = getstruct("sq_bttp2_bolt_from_the_blue_a", "targetname");
	b_struct = getstruct("sq_bttp2_bolt_from_the_blue_b", "targetname");

	a = Spawn("script_model", a_struct.origin );
	a SetModel("p_ztem_glyphs_00");
	a Hide();
	wait_network_frame();

	b = Spawn("script_model", b_struct.origin );
	b SetModel("p_ztem_glyphs_00");
	b Hide();
	wait_network_frame();

	original_origin = a.origin;

	for(i = 0; i < 7; i ++)
	{

		yaw = randomFloat( 360 );
		r = randomFloatRange( 500, 1000);

		amntx = cos( yaw ) * r;
		amnty = sin( yaw ) * r;


		a.origin = original_origin + (amntx, amnty, 0);

		maps\zombie_temple_sq::bounce_from_a_to_b(a,b,false);

		wait(0.55);
	}

	wait(5);

	a.origin = original_origin;

	maps\zombie_temple_sq::bounce_from_a_to_b(b,a,true);

	wait(1);

	a Delete();
	b Delete();
}

bttp2_timer_func()
{
	/*if(flag("radio_7_played"))
	{
		return 5 * 60;
	}
	else
	{
		return 60;	// If radio not listened to, stage lasts 1 minute.
	}*/

	return 60;
}

stage_logic()
{
	while(level._num_dials_correct != level._num_dials_to_match)
	{
		wait(0.1);
	}

	level notify("raise_crystal_1");
	level notify("raise_crystal_2");
	level notify("raise_crystal_3");
	level notify("raise_crystal_4");
	level notify("raise_crystal_5");
	level notify("raise_crystal_6", true);
	level waittill("raised_crystal_6");

	wait(5.0);

	stage_completed("sq", "bttp2");
}

exit_stage(success)
{
	dials = GetEntArray("sq_bttp2_dial", "targetname");
	array_thread(dials, ::dud_dial_handler);

	if(success)
	{
		maps\zombie_temple_sq_brock::create_radio(8);
	}
	else
	{
		maps\zombie_temple_sq_brock::create_radio(7, maps\zombie_temple_sq_brock::radio7_override);
		level thread maps\zombie_temple_sq_skits::fail_skit();
	}
}

dial_trigger()
{
	level endon("bttp2_start");
	level endon("sq_bttp2_over");

	while(1)
	{
		self waittill("triggered", who);
		self.owner_ent notify("triggered", who);
	}
}

dial_handler()
{
	/*if(!flag("radio_7_played"))
	{
		self thread dud_dial_handler("We don't know what we're doing.");
	}*/

	level endon("sq_bttp2_over");

	self.angles = self.original_angles;

	pos = RandomIntRange(0,3);

	if(pos == self.script_int)
	{
		pos = (pos + 1) % 4;
	}

	self RotatePitch(90 * pos, 0.01);

	correct = false;

	while(1)
	{
		self waittill("triggered", who);

		self playsound( "evt_sq_bttp2_wheel_turn" );
		self RotatePitch(90, 0.25);
		self waittill("rotatedone");

		pos = (pos + 1) % 4;

		if(pos == self.script_int)
		{
			level._num_dials_correct ++;
			Print3d(self.origin, "+", (0,255,0), 10);
			correct = true;
			//self playsound( "evt_sq_bttp2_wheel_correct" );

			if( isdefined( who ) && isPlayer( who ) )
			{
				if( level._num_dials_correct == level._num_dials_to_match )
				{
					who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest7", undefined, 0 );
				}
			}
		}
		else
		{
			if(correct)
			{
				correct = false;
				level._num_dials_correct --;
			}
		}

		wait(0.1);
	}
}

dud_dial_handler(dont_know_alias)
{
	level endon("bttp2_start");
	self.trigger thread dial_trigger();

	if(!IsDefined(self.original_angles))
	{
		self.original_angles = self.angles;
	}

	self.angles = self.original_angles;

	rot = RandomIntRange(0,3);

	self RotatePitch(rot * 90, 0.01);

	while(1)
	{
		self waittill("triggered");

		self playsound( "evt_sq_bttp2_wheel_turn" );

		if(IsDefined(dont_know_alias))
		{
/#
			IPrintLnBold("Temp player vox : " + dont_know_alias);
	#/
		}

		self RotatePitch(90, 0.25);
		self waittill("rotatedone");
	}
}
