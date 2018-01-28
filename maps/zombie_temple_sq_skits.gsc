/* zombie_temple_sq_skits.gsc
 *
 * Purpose : 	Temple sidequest skit logic
 *		
 * 
 * Author : 	Dan L
 * 
 */

#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility; 


build_skit_entry(character, vo)
{
	entry = SpawnStruct();
	
	switch(character)
	{
		case "dempsey":
			entry.character = 0;// Dempsy
			break;
		case "nikolai":
			entry.character = 1;// Nikolai
			break;
		case "takeo":
			entry.character = 2;// Takeo
			break;
		case "richtofen":
			entry.character = 3;// Richtofen
			break;			
	}
	
	entry.vo = vo;
	
	return entry;
}

init_skits()
{
	if(!IsDefined(level._skit_data))
	{
		level._skit_data = [];
		
		// Time travel skit 1
		
		level._skit_data["tt1"] 	= array(build_skit_entry("dempsey", 	"vox_egg_skit_travel_1_0"), 
																			build_skit_entry("nikolai", 	"vox_egg_skit_travel_1_1"),
																			build_skit_entry("takeo", 		"vox_egg_skit_travel_1_2"),
																			build_skit_entry("richtofen", 	"vox_egg_skit_travel_1_3"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_1_4"));

		// Time travel skit 2

		level._skit_data["tt2"] 	= array(build_skit_entry("takeo", 		"vox_egg_skit_travel_2_0"), 
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_2_1"),
																			build_skit_entry("richtofen", "vox_egg_skit_travel_2_2"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_2_3"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_2_4"));

		// Time travel skit 3

		level._skit_data["tt3"] 	= array(build_skit_entry("dempsey",		"vox_egg_skit_travel_3_0"), 
																			build_skit_entry("takeo",			"vox_egg_skit_travel_3_1"),
																			build_skit_entry("richtofen", "vox_egg_skit_travel_3_2"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_3_3"),
																			build_skit_entry("richtofen",		"vox_egg_skit_travel_3_3a"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_3_4"));
																			
		// Time travel skit 4a

		level._skit_data["tt4a"] 	= array(build_skit_entry("takeo",			"vox_egg_skit_travel_4a_0"), 
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_4a_1"),
																			build_skit_entry("richtofen", "vox_egg_skit_travel_4a_2"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_4a_3"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_4a_4"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_4a_5"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_4a_6"),
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_4a_7"));

		// Time travel skit 4b

		level._skit_data["tt4b"]	= array(build_skit_entry("richtofen",	"vox_egg_skit_travel_4b_0"), 
					 														build_skit_entry("dempsey",		"vox_egg_skit_travel_4b_1"),
																			build_skit_entry("richtofen", "vox_egg_skit_travel_4b_2"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_4b_3"),
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_4b_4"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_4b_5"),
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_4b_6"));
																			
		// Time travel skit 5

		level._skit_data["tt5"]		= array(build_skit_entry("richtofen",	"vox_egg_skit_travel_5_0"), 
																			build_skit_entry("takeo"	,		"vox_egg_skit_travel_5_1"),
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_5_2"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_5_3"),
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_5_4"));
																			
		// Time travel skit 6

		level._skit_data["tt6"] 	= array(build_skit_entry("dempsey",		"vox_egg_skit_travel_6_0"), 
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_6_1"),
																			build_skit_entry("richtofen", "vox_egg_skit_travel_6_2"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_6_3"),
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_6_4"),
																			build_skit_entry("takeo",			"vox_egg_skit_travel_6_5"),
																			build_skit_entry("takeo",			"vox_egg_skit_travel_6_6"));
																						
		// Time travel skit 7a

		level._skit_data["tt7a"] 	= array(build_skit_entry("dempsey",		"vox_egg_skit_travel_7a_0"), 
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_7a_1"),
																			build_skit_entry("dempsey", 	"vox_egg_skit_travel_7a_2"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_7a_3"),
																			build_skit_entry("takeo",			"vox_egg_skit_travel_7a_4"));																																									

		// Time travel skit 7b

		level._skit_data["tt7b"] 	= array(build_skit_entry("dempsey",		"vox_egg_skit_travel_7b_0"), 
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_7b_1"),
																			build_skit_entry("nikolai", 	"vox_egg_skit_travel_7b_2"),
																			build_skit_entry("takeo",			"vox_egg_skit_travel_7b_3"),
																			build_skit_entry("takeo",			"vox_egg_skit_travel_7b_4"));		
																						
		// Time travel skit 8

		level._skit_data["tt8"] 	= array(build_skit_entry("richtofen",	"vox_egg_skit_travel_8_0"), 
																			build_skit_entry("dempsey",		"vox_egg_skit_travel_8_1"),
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_8_2"),
																			build_skit_entry("nikolai",		"vox_egg_skit_travel_8_3"),
																			build_skit_entry("richtofen",	"vox_egg_skit_travel_8_4"));	
																			
		level._skit_data["fail1"]	=	array(build_skit_entry("dempsey",		"vox_egg_skit_fail_0_0"),
																			build_skit_entry("nikolai",		"vox_egg_skit_fail_0_1"),																														
																			build_skit_entry("takeo",			"vox_egg_skit_fail_0_2"),	
																			build_skit_entry("richtofen",	"vox_egg_skit_fail_0_3"));
															
		level._skit_data["fail2"]	=	array(build_skit_entry("dempsey",		"vox_egg_skit_fail_1_0"),
																			build_skit_entry("nikolai",		"vox_egg_skit_fail_2_1"),																														
																			build_skit_entry("takeo",			"vox_egg_skit_fail_3_2"),	
																			build_skit_entry("richtofen",	"vox_egg_skit_fail_4_3"));

		level._skit_data["fail3"]	=	array(build_skit_entry("dempsey",		"vox_egg_skit_fail_0_0"),
																			build_skit_entry("nikolai",		"vox_egg_skit_fail_1_1"),																														
																			build_skit_entry("takeo",			"vox_egg_skit_fail_2_2"),	
																			build_skit_entry("richtofen",	"vox_egg_skit_fail_3_3"));

		level._skit_data["fail4"]	=	array(build_skit_entry("dempsey",		"vox_egg_skit_fail_0_0"),
																			build_skit_entry("nikolai",		"vox_egg_skit_fail_1_1"),																														
																			build_skit_entry("takeo",			"vox_egg_skit_fail_2_2"),	
																			build_skit_entry("richtofen",	"vox_egg_skit_fail_3_3"));
																			
		level._skit_data["start0"]	=	array(build_skit_entry("dempsey",		"vox_egg_skit_start_0_0"),
																			build_skit_entry("nikolai",		"vox_egg_skit_start_0_1"),																														
																			build_skit_entry("takeo",		"vox_egg_skit_start_0_2"),	
																			build_skit_entry("richtofen",	"vox_egg_skit_start_0_2a"),	
																			build_skit_entry("nikolai",		"vox_egg_skit_start_0_3"),
																			build_skit_entry("richtofen",	"vox_egg_skit_start_0_4"),
																			build_skit_entry("richtofen",   "vox_egg_skit_start_0_5"));	
																			
		level._skit_data["start1"]	=	array(build_skit_entry("takeo",		"vox_egg_skit_start_1_0"),
																			build_skit_entry("richtofen",	"vox_egg_skit_start_1_1"),																														
																			build_skit_entry("nikolai",		"vox_egg_skit_start_1_2"),	
																			build_skit_entry("nikolai",		"vox_egg_skit_start_1_3"),
																			build_skit_entry("takeo",		"vox_egg_skit_start_1_4"),
																			build_skit_entry("nikolai",		"vox_egg_skit_start_1_5"),
																			build_skit_entry("dempsey",		"vox_egg_skit_start_1_6"),	
																			build_skit_entry("dempsey",   	"vox_egg_skit_start_1_7"));
	}
}

skit_interupt(fail_pos, group)
{
	level endon("start_skit_done");
	
	if(!IsDefined(level._start_skit_pos))
	{
		buttons = GetEntArray("sq_sundial_button", "targetname");
		
		pos = (0,0,0);
		
		for(i = 0; i < buttons.size; i ++)
		{
			pos += buttons[i].origin;
		}
		
		pos /= buttons.size;
		
		level._start_skit_pos = pos;
	}
	
	if(!IsDefined(fail_pos))
	{
		fail_pos = level._start_skit_pos;
	}
	
	while(1)
	{
		players = get_players();
		
		if(IsDefined(group))
		{
			players = group;
		}
		
		max_dist_squared = 0;

		check_pos = level._start_skit_pos;

		if(IsDefined(group))
		{
			check_pos = (0,0,0);
			
			num_group = 0;
			
			for(i = 0; i < group.size; i ++)
			{
				if(IsDefined(group[i]))
				{
					check_pos += group[i].origin;
					num_group ++;
				}
			}
			
			if(num_group)
			{
				check_pos /= num_group;
			}
		}

		
		for(i = 0; i < players.size; i ++)
		{
			if(!IsDefined(players[i]))	// passed in player has disconnected...
			{
				break;
			}
			
			dist_squared = distance2dsquared(players[i].origin, check_pos);
			
			if(IsDefined(dist_squared))
			{
				max_dist_squared = max(max_dist_squared, dist_squared);
			}
		}
		
		if(max_dist_squared > 720 * 720) // a player is more than 30 feet away...
		{
			break;
		}
		wait(0.1);
	}
	
	// play fail line.
	
	level notify("skit_interupt");

	speaker = get_players()[0];
	
	if(IsDefined(level._last_skit_line_speaker))
	{
		speaker = level._last_skit_line_speaker;
	}
	
	if(IsDefined(speaker.speaking_line) && speaker.speaking_line)
	{
		while(speaker.speaking_line)
		{
			wait(0.2);
		}
	}
	
	character = speaker GetEntityNumber();
	
	if(IsDefined(speaker.zm_random_char))
	{
		character = speaker.zm_random_char;
	}
	
	num = 5;
	
	if(character == 3)	// Richtofen
	{
		num = 8;
	}
	
	snd = "vox_plr_" + character + "_safety_" + RandomIntRange(0, num);
	
/#
	IPrintLn(character + " : " + snd);
#/

	speaker PlaySound(snd, "line_done");
	speaker waittill("line_done");
	
	level.skit_vox_override = 0;
}

do_skit_line(script_line)
{
	players = get_players();
	
	speaking_player = players[0];
	
	for(i = 0; i < players.size; i ++)
	{
		if(IsDefined(players[i].zm_random_char))
		{
			if(players[i].zm_random_char == script_line.character)
			{
				speaking_player = players[i];
				break;
			}
		}
		else
		{
			if(players[i] GetEntityNumber() == script_line.character)
			{
				speaking_player = players[i];
				break;
			}
		}
	}
	
	speaking_player.speaking_line = true;
	level._last_skit_line_speaker = speaking_player;

/#
	IPrintLn(speaking_player GetEntityNumber() + " : " + script_line.vo);
	#/
	
	speaking_player PlaySound(script_line.vo, "line_done");
	speaking_player waittill("line_done");
	speaking_player.speaking_line = false;
	level notify("line_spoken");	
}

start_skit(skit_name, group)
{
	level endon("skit_interupt");
	
	script = level._skit_data[skit_name];
	
	level.skit_vox_override = 1;
	
	level thread skit_interupt(undefined, group);
	
	for(i = 0; i < script.size; i ++)
	{
		character_in_game = false;
		players = get_players();
		for(j=0;j<players.size;j++)
		{
			if(players[j].entity_num == script[i].character)
			{
				character_in_game = true;
				break;
			}
		}

		if(i == script.size - 1)
		{
			level notify("start_skit_done");			
		}

		if(!character_in_game)
		{
			continue;
		}
		
		level thread do_skit_line(script[i]);
		level waittill("line_spoken");
	}
	
	level.skit_vox_override = 0;
}

fail_skit(first_time)
{
	fail_skits = undefined;
	
	if(IsDefined(first_time) && first_time)
	{
		fail_skits = array(level._skit_data["fail1"]);
	}
	else
	{
		fail_skits = array(level._skit_data["fail2"], level._skit_data["fail3"], level._skit_data["fail4"]);
	}
	
	players = get_players();
	player_index = 0;
	
	proposed_group = undefined;
	
	while(player_index != players.size)
	{
		proposed_group = [];
		for(i = 0; i < players.size; i ++)
		{
			if(i == player_index)
			{
				continue;
			}
			
			if(distance2dsquared(players[player_index].origin, players[i].origin) < 360 * 360)
			{
				proposed_group[proposed_group.size] = players[i];
			}
		}
		
		player_index ++;
		
		if(proposed_group.size > 0)
		{
			break;
		}
	}
	
	level.skit_vox_override = 1;

	skit = fail_skits[RandomIntRange(0, fail_skits.size)];
	
	if(proposed_group.size > 0)
	{
		
		pos = (0,0,0);
		
		for(i = 0; i < proposed_group.size; i ++)
		{
			pos += proposed_group[i].origin;
		}
		
		pos /= proposed_group.size;
		
		level endon("skit_interupt");
		
		level thread skit_interupt(pos, proposed_group);		
		
		for(i = 0; i < proposed_group.size; i ++)
		{
			level thread do_skit_line(skit[proposed_group[i].entity_num]);
			level waittill("line_spoken");			
		}
	}
	else
	{
		player = players[RandomIntRange(0, players.size)];
		
		level thread do_skit_line(skit[player.entity_num]);
		level waittill("line_spoken");
	}

	level.skit_vox_override = 0;

}