#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_utility_raven;


main()
{
	level thread init_code_triggers();
	level thread init_corpse_triggers();
	level thread init_water_drop_triggers();
	level thread init_slow_trigger();
	level thread init_code_structs();
}

//
//Code Triggers - Players must enter a button combination while standing in the trigger.

init_code_triggers()
{
	triggers = getEntArray("code_trigger", "targetname");
	array_thread(triggers, ::trigger_code);
}

trigger_code()
{
	code = self.script_noteworthy;
	if(!isDefined(code))
	{
		code = "DPAD_UP DPAD_UP DPAD_DOWN DPAD_DOWN DPAD_LEFT DPAD_RIGHT DPAD_LEFT DPAD_RIGHT BUTTON_B BUTTON_A";
	}
	
	if(!isDefined(self.script_string))
	{
		self.script_string = "cash";
	}
	
	self.players = [];
	while(1)
	{
		self waittill("trigger", who);
		
		//PLayer may already be in trigger
		//Or player may have already completed code
		if(is_in_array(self.players, who))
		{
			continue;
		}
		
		who thread watch_for_code_touching_trigger(code, self);
	}
}

watch_for_code_touching_trigger(code, trigger)
{
	trigger.players = array_add(trigger.players, self);
	self thread watch_for_code(code);
	self thread touching_trigger(trigger);
	
	returnNotify = self waittill_any_return("code_correct", "stopped_touching_trigger", "death");
	
	self notify("code_trigger_end");
	
	if(returnNotify == "code_correct")
	{
		trigger code_trigger_activated(self);
	}
	else
	{
		//Allow player to try again
		trigger.players = array_remove(trigger.players, self);
	}
}

code_trigger_activated(who)
{
	switch( self.script_string )
	{
		case "cash":
			who maps\_zombiemode_score::add_to_player_score(100);
			break;
		default:
	}	
}

touching_trigger(trigger)
{
	self endon("code_trigger_end");
	while(self isTouching(trigger))
	{
		wait .1;
	}
	self notify("stopped_touching_trigger");
}

watch_for_code(code)
{
	self endon("code_trigger_end");
	codes = strTok(code, " ");
	while(1)
	{
		for(i=0; i<codes.size;i++)
		{
			button = codes[i];
			
			//wait for button to be pressed or start over
			if(!self button_pressed(button,.3))
			{
				break;
			}
			
			//wait for button to not be pressed
			if( !self button_not_pressed(button, .3) )
			{
				break;
			}
			if(i==codes.size-1)
			{
				self notify("code_correct");
				return;
			}
		}
		wait .1;
	}
}

button_not_pressed(button, time)
{
	endTime = gettime() + time*1000;
	while(getTime() < endTime)
	{
		if(!self buttonpressed(button))
		{
			return true;
		}
		wait .01;
	}
	return false;	
}

button_pressed(button, time)
{
	endTime = gettime() + time*1000;
	while(getTime() < endTime)
	{
		if(self buttonpressed(button))
		{
			return true;
		}
		wait .01;
	}
	return false;
}
//End code Triggers

//MCG 031011: Find all triggers that are supposed to slow down players inside them and start threads on them to detect the players
init_slow_trigger()
{
	flag_wait( "all_players_connected" );
	
	players = get_players();
	for(p=0;p<players.size;p++)
	{
		players[p].moveSpeedScale = 1.0;
	}
	
	slowTriggers = getEntArray("slow_trigger", "targetname");
	for ( t = 0; t < slowTriggers.size; t++ )
	{
		trig = slowTriggers[t];
		if ( !IsDefined( trig.script_float ) )
		{
			//move speed scale - can be set in map
			trig.script_float = 0.5;
		}
		
		trig.inturp_time = 1.0;
		trig.inturp_rate = trig.script_float / trig.inturp_time;
		
		trig thread trigger_slow_touched_wait();
	}
}

trigger_slow_touched_wait()
{
	while(1)
	{
		self waittill ("trigger", player);
		player notify("enter_slowTrigger");
		self trigger_thread( player, ::trigger_slow_ent, ::trigger_unslow_ent );
		wait 0.1;
	}
}

trigger_slow_ent( player, endon_condition )
{
	player endon(endon_condition);
	if ( IsDefined( player ) )
	{
		prevTime = GetTime();
		
		while(player.moveSpeedScale > self.script_float)
		{
			wait .05;
			delta = GetTime() - prevTime;
			player.moveSpeedScale -= (delta/1000) * self.inturp_rate;
			prevTime = GetTime();
			player SetMoveSpeedScale( player.moveSpeedScale );
		}
		player.moveSpeedScale = self.script_float;
		
		player allowJump(false);
		player allowSprint(false);

		player SetMoveSpeedScale( self.script_float );
		player setvelocity((0,0,0));
	}
}

trigger_unslow_ent( player )
{
	player endon("enter_slowTrigger");
	
	if ( IsDefined( player ) )
	{
		prevTime = GetTime();
		
		while(player.moveSpeedScale < 1.0)
		{
			wait .05;
			delta = GetTime() - prevTime;
			player.moveSpeedScale += (delta/1000) * self.inturp_rate;
			prevTime = GetTime();
			player SetMoveSpeedScale( player.moveSpeedScale );
		}
		player.moveSpeedScale = 1.0;
		
		player allowJump(true);
		player allowSprint(true);
		player SetMoveSpeedScale( 1.0 );	
	}
}
//End slow Triggers


//
//Corspe Triggers - Detect
init_corpse_triggers()
{
	//triggers = getEntArray("corpse_trigger", "targetname");
	//array_thread(triggers, ::trigger_corpse);
	//level thread code_rewards();	
}

trigger_corpse()
{
	if(!isDefined(self.script_string))
	{
		self.script_string = "";
	}
	while(1)
	{
		box(self.origin, self.mins, self.maxs, 0, (1, 0.0, 0.0));
		corpses = getcorpsearray();
		for(i=0;i<corpses.size;i++)
		{
			corpse = corpses[i];
			box(corpse.orign, corpse.mins, corpse.maxs, 0, (1, 1.0, 0.0));
			if(corpse istouching(self))
			{
				self trigger_corpse_activated();
				return;
			}
		}
		wait .3;
	}
}
trigger_corpse_activated()
{
	iprintlnbold("Corpse Trigger Activated");
}

//Water drops / Water sheeting
init_water_drop_triggers()
{
	triggers = getEntArray("water_drop_trigger", "script_noteworthy");
	for(i=0;i<triggers.size;i++)
	{
		trig = triggers[i];

		trig.water_drop_time = 5;	//How long the drops stay up after leaving trigger

		trig.waterDrops = true;
		trig.waterSheeting = true;
		trig.waterSheetingTime = 5;
		if(isDefined(trig.script_string))
		{
			if(trig.script_string=="sheetingonly")
			{
				trig.waterDrops = false;
			}
			else if(trig.script_string=="dropsonly")
			{
				trig.waterSheeting = false;
			}
		}
		
		trig thread water_drop_trigger_think();
	}
}

water_drop_trigger_think()
{
	flag_wait( "all_players_connected" );
	
	wait( 1.0 );
	
	if(IsDefined(self.script_flag))
	{
		flag_wait( self.script_flag );
	}
	
	if(IsDefined(self.script_float))
	{
		wait( self.script_float );
	}
	
	while(1)
	{
		self waittill("trigger", who);
		if(isPlayer(who))
		{
			self trigger_thread(who, ::water_drop_trig_entered, ::water_drop_trig_exit);
		}
		else if(isDefined(who.water_trigger_func))
		{
			who thread [[who.water_trigger_func]](self);
		}
	}
}

water_drop_trig_entered( player, endon_string )
{
	player endon(endon_string);
	player notify("water_drop_trig_enter");
	player endon("death");
	player endon("disconnect");
	player endon("spawned_spectator");
	
	if(player.sessionstate == "spectator")
	{
		return;
	}
	
	if(!isDefined(player.water_drop_ents))
	{
		player.water_drop_ents = [];
	}
	
	if(isDefined(self.script_sound))
	{
		player playsound(self.script_sound);
	}
	
	if(self.waterDrops)
	{
		player.water_drop_ents = array_add(player.water_drop_ents, self);

		//When trigger does sheeting and drops don't turn the drops on while sheeting
		//They will be turned on when the player exits the trigger
		if(!self.waterSheeting)
		{
			player setwaterdrops(player player_get_num_water_drops());
		}
	}
	
	if(self.waterSheeting)
	{
		// set client side rumble
		player SetClientFlag( level._CF_PLAYER_MAZE_FLOOR_RUMBLE );
		player thread intermission_rumble_clean_up();
		
		while(1)
		{
			player setwatersheeting(1, self.waterSheetingTime);
			wait self.waterSheetingTime;
		}
	}
}

water_drop_trig_exit( player )
{	
	
	if(!isDefined(player.water_drop_ents))
	{
		player.water_drop_ents = [];
	}
	
	if(self.waterDrops)
	{
		if(self.waterSheeting)
		{
			player notify( "irt" ); //intermission rumble tracking
			player ClearClientFlag( level._CF_PLAYER_MAZE_FLOOR_RUMBLE );
			
			player setwaterdrops(player player_get_num_water_drops());
		}
		player.water_drop_ents = array_remove(player.water_drop_ents, self);
		
		if(player.water_drop_ents.size == 0)
		{
			player water_drop_remove(self.water_drop_time);
		}
		else
		{
			player setwaterdrops(player player_get_num_water_drops());
		}
	}
}
water_drop_remove(delay)
{
	self endon("death");
	self endon("disconnect");
	self endon("water_drop_trig_enter");
	
	wait delay;
	
	self setwaterdrops(0);
}
player_get_num_water_drops()
{
	if(self.water_drop_ents.size>0)
	{
		return 50; //50 is max in code
	}
	else
	{
		return 0;
	}
}

init_code_structs()
{
	structs = getStructArray("code_struct", "targetname");
	array_thread(structs, ::structs_code);
}

structs_code()
{
	code = self.script_noteworthy;
	if(!isDefined(code))
	{
		code = "DPAD_UP DPAD_DOWN DPAD_LEFT DPAD_RIGHT BUTTON_B BUTTON_A";
	}
	self.codes = strTok(code, " ");
	
	if(!isDefined(self.script_string))
	{
		self.script_string = "cash";
	}
	self.reward = self.script_string;
	
	if(!isDefined(self.radius))
	{
		self.radius = 32;
	}
	
	self.radiusSq = self.radius * self.radius;
	
	playersInRadius = [];
	while(1)
	{
		players = get_players();
		//Remove players no longer in radius
		for(i=playersInRadius.size-1;i>=0;i--)
		{
			player = playersInRadius[i];
			if(!self is_player_in_radius(player))
			{
				if(isDefined(player))
				{
					playersInRadius = array_remove(playersInRadius,player);
					self notify("end_code_struct");
				}
				else
				{
					playersInRadius = array_removeUndefined(playersInRadius);
				}
			}
			players = array_remove(players, player);
		}
		
		//Add any new player
		for(i=0;i<players.size;i++)
		{
			player = players[i];
			if(self is_player_in_radius(player))
			{
				self thread code_entry(player);
				playersInRadius[playersInRadius.size] = player;
			}
		}

		wait .5;
	}
}

code_entry(player)
{
	self endon("end_code_struct");
	player endon("death");
	player endon("disconnect");
	
	while(1)
	{
		for(i=0; i<self.codes.size;i++)
		{
			button = self.codes[i];
			
			//wait for button to be pressed or start over
			if(!player button_pressed(button,.3))
			{
				break;
			}
			
			//wait for button to not be pressed
			if( !player button_not_pressed(button, .3) )
			{
				break;
			}
			if(i==self.codes.size-1)
			{
				self code_reward(player);
				return;
			}
		}
		wait .1;
	}
}

code_reward(player)
{
	switch( self.reward )
	{
		case "cash":
			player maps\_zombiemode_score::add_to_player_score(100);
			break;
		case "mb":
			maps\zombie_temple_ai_monkey::monkey_ambient_gib_all();
			break;
		default:
	}	
}

is_player_in_radius(player)
{
	if(!is_player_valid(player))
	{
		return false;
	}
	
	if(abs(self.origin[2]-player.origin[2])>30)
	{
		return false;
	}
	
	if(distance2dsquared(self.origin, player.origin)>self.radiusSq)
	{
		return false;
	}
	
	return true;
}

intermission_rumble_clean_up()
{
	self endon( "irt" ); //intermission rumble tracking
	
	level waittill( "intermission" );
	
	self ClearClientFlag( level._CF_PLAYER_MAZE_FLOOR_RUMBLE );
}
