/* zombie_moon_sq_ss.gsc
 *
 * Purpose : 	Sidequest stage logic for zombie_moon - Sam Says 1 & 2.
 *		
 * 
 * Author : 	Dan L
 * 
 */

#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility; 
#include maps\_zombiemode_sidequests;

ss_debug()
{
/#
	level endon("sq_ss1_over"); // Kill logic func if it's still running.
	level endon("sq_ss2_over"); // Kill logic func if it's still running.

	if(!IsDefined(level._debug_ss))
	{
		level._debug_ss = true;
		
		level.ss_val = NewDebugHudElem();
		level.ss_val.location = 0;
		level.ss_val.alignX = "left";
		level.ss_val.alignY = "middle";
		level.ss_val.foreground = 1;
		level.ss_val.fontScale = 1.3;
		level.ss_val.sort = 20;
		level.ss_val.x = 10;
		level.ss_val.y = 240;
		level.ss_val.og_scale = 1;
		level.ss_val.color = (255,255,255);
		level.ss_val.alpha = 1;		
		
		level.ss_val_text = NewDebugHudElem();
		level.ss_val_text.location = 0;
		level.ss_val_text.alignX = "right";
		level.ss_val_text.alignY = "middle";
		level.ss_val_text.foreground = 1;
		level.ss_val_text.fontScale = 1.3;
		level.ss_val_text.sort = 20;
		level.ss_val_text.x = 0;
		level.ss_val_text.y = 240;
		level.ss_val_text.og_scale = 1;
		level.ss_val_text.color = (255, 255,255);
		level.ss_val_text.alpha = 1;
		level.ss_val_text SetText("Seq : ");		
		
		level.ss_user_val = NewDebugHudElem();
		level.ss_user_val.location = 0;
		level.ss_user_val.alignX = "left";
		level.ss_user_val.alignY = "middle";
		level.ss_user_val.foreground = 1;
		level.ss_user_val.fontScale = 1.3;
		level.ss_user_val.sort = 20;
		level.ss_user_val.x = 10;
		level.ss_user_val.y = 270;
		level.ss_user_val.og_scale = 1;
		level.ss_user_val.color = (255,255,255);
		level.ss_user_val.alpha = 1;		
		
		level.ss_user_val_text = NewDebugHudElem();
		level.ss_user_val_text.location = 0;
		level.ss_user_val_text.alignX = "right";
		level.ss_user_val_text.alignY = "middle";
		level.ss_user_val_text.foreground = 1;
		level.ss_user_val_text.fontScale = 1.3;
		level.ss_user_val_text.sort = 20;
		level.ss_user_val_text.x = 0;
		level.ss_user_val_text.y = 270;
		level.ss_user_val_text.og_scale = 1;
		level.ss_user_val_text.color = (255, 255,255);
		level.ss_user_val_text.alpha = 1;
		level.ss_user_val_text SetText("User Seq : ");				
	}
	
	while(1)
	{
		if(IsDefined(level._ss_user_seq))
		{
			str = "";
			
			for(i = 0; i < level._ss_user_seq.size; i ++)
			{
				str += level._ss_user_seq[i];
			}			
			
			level.ss_user_val SetText(str);
		}
		else
		{
			level.ss_user_val SetText("");
		}
		wait(0.1);
	}
#/
}

init_1()
{
	flag_init("displays_active");
	flag_init("wait_for_hack");

	PreCacheModel("p_zom_moon_magic_box_com_red");
	PreCacheModel("p_zom_moon_magic_box_com_green");
	PreCacheModel("p_zom_moon_magic_box_com_blue");
	PreCacheModel("p_zom_moon_magic_box_com_yellow");

	declare_sidequest_stage("sq", "ss1", ::init_stage_1, ::stage_logic, ::exit_stage_1);
	
	buttons = GetEntArray("sq_ss_button", "targetname");
	
	for(i = 0; i < buttons.size; i ++)
	{
		ent = GetEnt(buttons[i].target, "targetname");
		buttons[i].terminal_model = ent;
	}
	
	level._ss_buttons = buttons;
}

init_2()
{
	declare_sidequest_stage("sq", "ss2", ::init_stage_2, ::stage_logic, ::exit_stage_2);
	//declare_stage_asset_from_struct("sq", "ss2", "sq_ss_button", ::sq_ss_button_thread );
}

init_stage_1()
{
	flag_clear("wait_for_hack");
	level._ss_stage = 1;
}

init_stage_2()
{
	//flag_set("wait_for_hack");
	level._ss_stage = 2;
/*	level._ss_hacks = [];
	
	buttons = level._ss_buttons;
	
	for(i = 0; i < buttons.size; i ++)
	{
		struct = SpawnStruct();
		struct.origin = buttons[i].origin;
		struct.radius = 48;
		struct.height = 48;
		struct.script_float = 2;
		struct.script_int = 0;
		maps\_zombiemode_equip_hacker::register_pooled_hackable_struct(struct, ::ss2_hack);
		level._ss_hacks[level._ss_hacks.size] = struct;
	} */
}

ss2_hack(hacker)
{
	flag_clear("wait_for_hack");
}

stage_logic()
{
	
/*	while(flag("wait_for_hack"))
	{
		wait(0.1);
	} */
	
	buttons = level._ss_buttons;
	array_thread(buttons, ::sq_ss_button_thread);
	
	if(IsDefined(level._ss_hacks))
	{
		for(i = 0; i < level._ss_hacks.size; i ++)
		{
			maps\_zombiemode_equip_hacker::deregister_hackable_struct(level._ss_hacks[i]);
		}
	}

	if(level.gamemode != "survival")
	{
		return;
	}
	
//	level thread ss_debug();
	if(level._ss_stage == 1)
	{
		do_ss1_logic();
	}
	else
	{
		do_ss2_logic();
	}
	
//	IPrintLn("Stage complete.");
	
	stage_completed("sq", "ss"+level._ss_stage);
}

do_ss1_logic()
{
	ss_logic(6, 1);
}

do_ss2_logic()
{
	level.ss_comp_vox_count = 0;
	ss_logic(6,  3);
	wait(2);
	level notify("rl");
	ss_logic(7,  4);
	wait(2);
	level notify("rl");
	ss_logic(8,  5);
	wait(2);
	level notify("rl");
}

generate_sequence(seq_length)
{
	seq = [];
	
	for(i = 0; i < seq_length; i ++)
	{
		seq[seq.size] = RandomIntRange(0,4);
	}
	
	last = -1;
	num_reps = 0;
	for(i = 0; i < seq_length; i ++)
	{
		if(seq[i] == last)
		{
			num_reps ++;
			
			if(num_reps >= 2)
			{
				while(seq[i] == last)
				{
					seq[i] = RandomIntRange(0,4);
				}
				
				num_reps = 0;
				last = seq[i];
			}
		}
		else
		{
			last = seq[i];
			num_reps = 0;
		}
	}
	
	/#
	if(IsDefined(level.ss_val))
	{
		str = "";
		
		for(i = 0; i < seq.size; i ++)
		{
			str += seq[i];
		}
		
		level.ss_val settext(str);
		
	}
	#/
	
	if( 1 == GetDvarInt(#"scr_debug_ss"))
	{
		for(i = 0; i < seq.size; i ++)
		{
			seq[i] = 0;
		}
	}
	
	return(seq);
}

kill_debug()
{
	/#
	if(IsDefined(level.ss_val))
	{
		level.ss_val Destroy();
		level.ss_val = undefined;

		level.ss_val_text Destroy();
		level.ss_val_text = undefined;
		
		level.ss_user_val Destroy();		
		level.ss_user_val = undefined;		
		
		level.ss_user_val_text Destroy();		
		level.ss_user_val_text = undefined;		
		
		level._debug_ss = undefined;

	}	
	#/
}

exit_stage_1(success)
{
	kill_debug();
	flag_set("ss1");
	array_thread(level._ss_buttons, ::sq_ss_button_dud_thread);
}

exit_stage_2(success)
{
	kill_debug();
}

sq_ss_button_dud_thread()
{
	self endon("ss_kill_button_thread");

	self thread sq_ss_button_thread(true);
	
}

sq_ss_button_debug()
{
	level endon("ss_kill_button_thread");
	level endon("sq_ss1_over");
	level endon("sq_ss2_over");
	
	while(1)
	{
		Print3d(self.origin + (0,0,12), self.script_int, (0,255,0), 1);
		wait(0.1);
	}
}

do_attract()
{
	flag_set("displays_active");
	
	buttons = level._ss_buttons;
	
	for(i = 0; i < buttons.size; i ++)
	{
		ent = buttons[i].terminal_model;
		
		ent SetModel("p_zom_moon_magic_box_com");
	}
	
	for(i = 0; i < buttons.size; i ++)
	{
		button = undefined;
		
		for(j = 0; j < buttons.size; j ++)
		{
			if(buttons[j].script_int == i)
			{
				button = buttons[j];
			}
		}
		
		if(IsDefined(button))
		{
			ent = button.terminal_model;
			
			model = get_console_model(button.script_int);
			
			ent SetModel(model);
			
			ent playsound(color_sound_selector(button.script_int));
			
			wait(0.6);
			
			ent SetModel("p_zom_moon_magic_box_com");
		}
	}
	
	level thread do_ss_start_vox( level._ss_stage );

	for(i = buttons.size - 1; i >= 0; i --)
	{
		button = undefined;
		
		for(j = 0; j < buttons.size; j ++)
		{
			if(buttons[j].script_int == i)
			{
				button = buttons[j];
			}
		}
		
		if(IsDefined(button))
		{
			ent = button.terminal_model;
			
			model = get_console_model(button.script_int);
			
			ent SetModel(model);
			
			ent playsound(color_sound_selector(button.script_int));
			
			wait(0.6);
			
			ent SetModel("p_zom_moon_magic_box_com");
		}
	}
	
	wait(0.5);
	
	flag_clear("displays_active");
}

sq_ss_button_thread(dud)
{
	level endon("sq_ss1_over");
	level endon("sq_ss2_over");
	
	if(!IsDefined(dud))
	{
		self notify("ss_kill_button_thread");
	}
	
	pos = self.origin;
	pressed = self.origin - (AnglesToRight(self.angles) * 0.25);
	
	//self thread sq_ss_button_debug();
	
	targ_model = self.terminal_model;
	
	while(1)
	{
		self waittill("trigger");
		
		if(!flag("displays_active"))
		{
			if(!IsDefined(dud))
			{
				if(IsDefined(level._ss_user_seq))
				{
					level._ss_user_seq[level._ss_user_seq.size] = self.script_int;
				}
			}
			
			model = get_console_model(self.script_int);
			
			targ_model playsound(color_sound_selector(self.script_int));
			targ_model SetModel(model);			
			
		}		
		wait(0.3);
		
		targ_model SetModel("p_zom_moon_magic_box_com");
	}
}

get_console_model(num)
{
		model = "p_zom_moon_magic_box_com";
		
		switch(num)
		{
			case 0:
				model = "p_zom_moon_magic_box_com_red";
				break;
			case 1:
				model = "p_zom_moon_magic_box_com_green";
				break;
			case 2:
				model = "p_zom_moon_magic_box_com_blue";
				break;
			case 3:
				model = "p_zom_moon_magic_box_com_yellow";
				break;
		}

	return model;	
}

ss_logic(seq_length, seq_start_length)
{
	seq = generate_sequence(seq_length);
	level._ss_user_seq = [];
	
	level._ss_sequence_matched = false;
	
	fails = 0;
	
	while(!level._ss_sequence_matched)
	{
		wait(0.5);
		self thread ss_logic_internal(seq, seq_length, seq_start_length);
		self waittill_either("ss_won", "ss_failed");
		if(level._ss_sequence_matched)
		{
			display_success(seq);
		}
		else
		{
			display_fail();
			fails ++;
			if(fails == 4)
			{
				seq = generate_sequence(seq_length);
				fails = 0;
			}
		}
	}
}

ss_logic_internal(seq, seq_length, seq_start_length)
{
	self endon("ss_won");
	self endon("ss_failed");
	
	do_attract();
	
	pos = seq_start_length;
	
	buttons = level._ss_buttons;
	
	for( i = pos; i <= seq_length; i ++)
	{
		// display the sequence up to it's current length.

		level._ss_user_seq = [];

		display_seq(buttons, seq, i);
		
		wait(1.0);
		
		validate_input(seq, i);
		
		wait(1.0);
	}
	
//	IPrintLn("Sequence matched.");
	level._ss_sequence_matched = true;
	self notify("ss_won");
}

user_input_timeout(len)
{
	self endon("correct_input");
	self endon("ss_failed");
	self endon("ss_won");
	wait(len * 4);
//	IPrintLn("Fail - timeout.");
	self notify("ss_failed");
}

validate_input(sequence, len)
{
	self thread user_input_timeout(len);
	
	while(level._ss_user_seq.size < len)
	{
		for(i = 0; i < level._ss_user_seq.size; i ++)
		{
			if(level._ss_user_seq[i] != sequence[i])
			{
//				IPrintLn("Incorrect entry - fail");
				self notify("ss_failed");
			}
		}
		wait(0.05);
	}
	
	for(i = 0; i < level._ss_user_seq.size; i ++)
	{
		if(level._ss_user_seq[i] != sequence[i])
		{
//				IPrintLn("Incorrect entry - fail");
			self notify("ss_failed");
		}
	}
	
	level._ss_user_seq = [];
	
	self notify("correct_input");
}

display_fail()
{
	flag_set("displays_active");
	
	buttons = level._ss_buttons;
	
	level thread do_ss_failure_vox( level._ss_stage );
	
	all_screens_black = false;
	
	while(!all_screens_black)
	{
		all_screens_black = true;
		
		for(i = 0; i < buttons.size; i ++)
		{
			ent = buttons[i].terminal_model;
			if(ent.model != "p_zom_moon_magic_box_com")
			{
				all_screens_black = false;
				break;
			}
		}
		wait(0.1);
	}
	
		level thread Play_Sound_In_Space("evt_ss_wrong",( -1006.3, 294.2, -93.7)); 
	
	for(i = 0; i < 5; i ++)
	{
		for(j = 0; j < buttons.size; j ++)
		{
			ent = buttons[j].terminal_model;
			ent SetModel("p_zom_moon_magic_box_com_red");
		}
		
		wait(0.2);

		for(j = 0; j < buttons.size; j ++)
		{
			ent = buttons[j].terminal_model;
			ent SetModel("p_zom_moon_magic_box_com");
		}
		
		wait(0.05);
	}
	
	flag_clear("displays_active");
}

play_win_seq(seq)
{
	for(i = 0; i < seq.size; i ++)
	{
		level thread Play_Sound_In_Space(color_sound_selector(seq[i]),( -1006.3, 294.2, -93.7)); 
		wait(0.2);
	}
	
}

display_success(seq)
{
	flag_set("displays_active");
	
	buttons = level._ss_buttons;
	
	level thread do_ss_success_vox( level._ss_stage );

	all_screens_black = false;
	
	while(!all_screens_black)
	{
		all_screens_black = true;
		
		for(i = 0; i < buttons.size; i ++)
		{
			ent = buttons[i].terminal_model;
			if(ent.model != "p_zom_moon_magic_box_com")
			{
				all_screens_black = false;
				break;
			}
		}
		wait(0.1);
	}
	
	level thread play_win_seq(seq);
	
	for(i = 0; i < 5; i ++)
	{
		for(j = 0; j < buttons.size; j ++)
		{
			ent = buttons[j].terminal_model;
			ent SetModel("p_zom_moon_magic_box_com_green");
		}
		
		wait(0.2);

		for(j = 0; j < buttons.size; j ++)
		{
			ent = buttons[j].terminal_model;
			ent SetModel("p_zom_moon_magic_box_com");
		}
		wait(0.05);
	}
	
	flag_clear("displays_active");
}

display_seq(buttons, seq, index)
{
	flag_set("displays_active");
	
	for(i = 0; i < index; i ++)
	{
		print_duration = 1;
		wait_duration = 0.4;
		
		if(i < (index - 1))
		{
			print_duration /= 2;
			wait_duration /= 2;
		}
		
		for(j = 0; j < buttons.size; j ++)
		{
			//Print3d(displays[j].origin, seq[i], (255,255,255), 1, 1, Int(print_duration));
			ent = buttons[j].terminal_model;
			
			model = get_console_model(seq[i]);
			
			level thread Play_Sound_In_Space(color_sound_selector(seq[i]),( -1006.3, 294.2, -93.7));
			
			ent SetModel(model);
		}
		
		
		wait(print_duration);
		
		for(j = 0; j < buttons.size; j ++)
		{
			ent = buttons[j].terminal_model;
			
			ent SetModel("p_zom_moon_magic_box_com");
		}
		
		wait(wait_duration);
	}
	
	flag_clear("displays_active");
}

color_sound_selector(index)
{
	switch(index)
	{
		case 0: 
			return "evt_ss_e";
		case 1: 
			return "evt_ss_d";
		case 2: 
			return "evt_ss_c";
		case 3: 
			return "evt_ss_lo_g";	
	}
}

//***AUDIO VOX FUNCS***\\
do_ss_start_vox(stage)
{
	playon = level._ss_buttons[1].terminal_model;
	
	if( stage == 1 )
	{
		player = is_player_close_enough( playon );
		
		if( isdefined( player ) )
		{
			playon playsound( "vox_mcomp_quest_step1_0", "mcomp_done0" );
			playon waittill( "mcomp_done0" );
			
			if( isdefined( player ) )
				player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 0 );
		}
	}
	else
	{
		if( level.ss_comp_vox_count == 0 )
		{
			playon playsound( "vox_mcomp_quest_step7_0", "mcomp_done1" );
		}
	}
}

do_ss_failure_vox(stage)
{
	playon = level._ss_buttons[1].terminal_model;
	
	if( stage == 1 )
	{
		player = is_player_close_enough( playon );
		
		if( isdefined( player ) )
		{
			playon playsound( "vox_mcomp_quest_step1_1", "mcomp_done2" );
			playon waittill( "mcomp_done2" );
			
			if( isdefined( player ) )
				player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 1 );
		}
	}
	else
	{
		player = is_player_close_enough( playon );
		
		if( isdefined( player ) )
		{
			switch( level.ss_comp_vox_count )
			{
				case 0:
					player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 1 );
					break;
				case 1:
					player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest7", undefined, 1 );
					break;
				case 2:
					player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest7", undefined, 3 );
					break;
			}
		}
	}
}

do_ss_success_vox(stage)
{
	playon = level._ss_buttons[1].terminal_model;
	
	if( stage == 1 )
	{
		player = is_player_close_enough( playon );
		
		if( isdefined( player ) )
		{
			playon playsound( "vox_mcomp_quest_step1_2", "mcomp_done3" );
			playon waittill( "mcomp_done3" );
			
			if( isdefined( player ) )
				player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 2 );
		}
	}
	else
	{
		switch( level.ss_comp_vox_count )
		{
			case 0:
				playon playsound( "vox_mcomp_quest_step7_2", "mcomp_done4" );
				level.ss_comp_vox_count++;
				break;
			case 1:
				playon playsound( "vox_mcomp_hack_success", "mcomp_done5" );
				level.ss_comp_vox_count++;
				break;
			case 2:
				playon playsound( "vox_mcomp_quest_step7_4", "mcomp_done6" );
				playon waittill( "mcomp_done6" );
				if( !flag("be2") )
				{
					playon playsound( "vox_xcomp_quest_step7_5", "xcomp_done7" );
				}
				break;
		}
	}
}

is_player_close_enough( org )
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if( distancesquared( org.origin, players[i].origin ) <= 75*75 )
		{
			return players[i];
		}
	}
	
	return undefined;
}