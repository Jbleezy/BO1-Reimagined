#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

hack_boards()
{
	windows = getstructarray( "exterior_goal", "targetname" );

	for(i = 0; i < windows.size; i ++)
	{
		window = windows[i];

		struct = SpawnStruct();

		spot = window;

		if(IsDefined(window.trigger_location))
		{
			spot = window.trigger_location;
		}

		org = groundpos( spot.origin ) + ( 0, 0, 4 );

		r = 96;
		h = 96;

		if(IsDefined(spot.radius))
		{
			r = spot.radius;
		}

		if(IsDefined(spot.height))
		{
			h = spot.height;
		}

		struct.origin = org + (0,0,48);; // window.origin;// + (AnglesToForward(window.angles) * 54);// + (0,0,24);
		struct.radius = r;
		struct.height = h;
		struct.script_float = 2;
		struct.script_int = 0;
		struct.window = window;
		struct.no_bullet_trace = true;
		struct.no_sight_check = true;
		struct.dot_limit = 0.7;
		struct.no_touch_check = true;
		struct.last_hacked_round = 0;
		struct.num_hacks = 0;

		maps\_zombiemode_equip_hacker::register_pooled_hackable_struct(struct, ::board_hack, ::board_qualifier);
	}
}

board_hack(hacker)
{
	maps\_zombiemode_equip_hacker::deregister_hackable_struct(self);

	num_chunks_checked = 0;

	last_repaired_chunk = undefined;

	if(self.last_hacked_round != level.round_number)
	{
		self.last_hacked_round = level.round_number;
		self.num_hacks = 0;
	}

	self.num_hacks ++;

	if(self.num_hacks < 3)
	{
		hacker maps\_zombiemode_score::add_to_player_score( 100 );
	}
	/*else
	{
		cost = Int(min(300, hacker.score));

		if(cost)
		{
			hacker maps\_zombiemode_score::minus_to_player_score( cost );
		}
	}*/

	while(1)
	{
		if( all_chunks_intact( self.window.barrier_chunks ) )
		{
			break;
		}

		chunk = get_random_destroyed_chunk( self.window.barrier_chunks );

		if( !IsDefined( chunk ) )
			break;

		self.window thread maps\_zombiemode_blockers::replace_chunk( chunk, undefined, true );

		last_repaired_chunk = chunk;

		self.window.clip enable_trigger();
		self.window.clip DisconnectPaths();
		wait_network_frame();

		num_chunks_checked++;

		if(num_chunks_checked >= 20)
		{
			break;	// Avoid staying in this while loop forever....
		}
	}

	//wait for the last window board to be repaired

	while((IsDefined(last_repaired_chunk)) && (last_repaired_chunk.state == "mid_repair"))
	{
		wait(.05);
	}

	maps\_zombiemode_equip_hacker::register_pooled_hackable_struct(self, ::board_hack, ::board_qualifier);
}

board_qualifier(player)
{

	if( all_chunks_intact( self.window.barrier_chunks ) || no_valid_repairable_boards( self.window.barrier_chunks ))
	{
		return false;
	}

	return true;
}
