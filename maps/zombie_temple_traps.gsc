#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;



//-----------------------------------------------
// name: 	init_temple_traps
// self: 	level
// return:	nothing
// desc:	sets up the traps for temple
//------------------------------------------------
init_temple_traps()
{
	PrecacheString(&"REIMAGINED_WATER_TRAP_ACTIVE");
	level thread spear_trap_init();
	level thread waterfall_trap_init();
	level thread init_maze_trap();
}


//-----------------------------------------------
// name: 	trigger_wait_for_power
// self: 	trigger
// return:	nothing
// desc:	waits for power to be turned on
//------------------------------------------------
trigger_wait_for_power()
{
	self sethintstring( &"ZOMBIE_NEED_POWER" );
	self SetCursorHint("HINT_NOICON");
	self.in_use = 0;

	flag_wait( "power_on" );
}

/////////////////////////////////////////////////////////////////////////////////////
//	SPEAR TRAP - uses a prefab
/////////////////////////////////////////////////////////////////////////////////////
spear_trap_init()
{
	spearTraps = GetEntArray("spear_trap", "targetname");
	for(i=0; i<spearTraps.size; i++)
	{
		spearTrap = spearTraps[i];

		//Setup spear locations
		spearTrap.clip = GetEnt(spearTrap.target, "targetname");

		spearTrap.clip notsolid();
		spearTrap.clip connectPaths();

		//Enable flag prevents the trap from being active enven when the power is on
		//Used when trap is in a doorway and can't be used until it is opened
		spearTrap.enable_flag = spearTrap.script_noteworthy;

		spearTrap thread spear_trap_think();
	}
}

spear_trap_think()
{
	if( isdefined(self.enable_flag) && !flag(self.enable_flag) )
	{
		flag_wait( self.enable_flag );
	}

	while(1)
	{
		self waittill("trigger", who);

		//Only player can trigger trap
		if(!IsDefined( who ) || !IsPlayer( who ) || who maps\_laststand::player_is_in_laststand() || who.sessionstate == "spectator" )
		{
			continue;
		}

		if(!who IsOnGround())
		{
			continue;
		}

		if(who GetStance() != "stand")
		{
			continue;
		}

		wait .3;

		for(i=0;i<3;i++)
		{
			self thread spear_trap_activate_spears( i, who );	//Collin A. - Added i as a value so I could tell whether or not it was the first raise
			wait 2.4; //Allow time for spears to reset
		}
	}
}

spear_trap_activate_spears( audio_counter, player )
{
	self spear_trap_damage_all_characters( audio_counter, player );

	self thread spear_activate(0);
}

spear_trap_damage_all_characters( audio_counter, player )
{
	wait .1; //allow some time for spears to extend

	characters = array_combine(get_players(), GetAiSpeciesArray( "axis" ));

	for(i=0; i<characters.size; i++)
	{
		char	= characters[i];
		if( self spear_trap_is_character_touching(char) )
		{
			self thread spear_damage_character(char, player);
		}
		else if( isPlayer(char) && (audio_counter==0) && (randomintrange(0,101) <=10) )	//Collin A. - play vox on the player if he avoids the spikes on their first raise, 25% chance
		{
			if( isdefined( player ) && player == char )
				char thread delayed_spikes_close_vox();
		}
	}
}

delayed_spikes_close_vox()
{
	self notify( "playing_spikes_close_vox" );
	self endon( "death" );
	self endon( "playing_spikes_close_vox" );

	wait(.5);

	if( isdefined( self ) && ( !isdefined( self.spear_trap_slow ) || (isdefined( self.spear_trap_slow ) && self.spear_trap_slow == false ) ) )
	{
		self thread maps\_zombiemode_audio::create_and_play_dialog( "general", "spikes_close" );
	}
}

spear_damage_character(char, activator)
{
	char thread spear_trap_slow(activator, self);
}

#using_animtree( "generic_human" );
spear_trap_slow(activator, trap)
{
	self endon("death");

	//Already SLow
	if(is_true(self.spear_trap_slow))
	{
		return;
	}

	self.spear_trap_slow = true;
	if(isPlayer(self))
	{
		if(is_player_valid(self))
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "general", "spikes_damage" );
			//self thread _fake_red();
			RadiusDamage(self.origin + (0, 0, 5), 10, 50, 50, undefined, "MOD_UNKNOWN");
			//iprintln(self.health);
		}
		self setvelocity((0,0,0));
		self.move_speed = .2;
		self SetMoveSpeedScale(self.move_speed);
		wait 1.0;
		self.move_speed = 1;
		if(!is_true(self.slowdown_wait))
		{
			self SetMoveSpeedScale(self.move_speed);
		}
		wait 0.5;
	}
	else if(self.animname == "zombie")
	{
		self thread spear_kill(undefined, activator);

		painAnims = [];
		painAnims[0] = %ai_zombie_taunts_5b;
		painAnims[1] = %ai_zombie_taunts_5c;
		painAnims[2] = %ai_zombie_taunts_5d;
		painAnims[3] = %ai_zombie_taunts_5e;
		painAnims[4] = %ai_zombie_taunts_5f;
		painAnim = random(painAnims);
		if(is_true(self.has_legs))
		{
			self animscripted("spear_pain_anim", self.origin, self.angles, painAnim);
			self _zombie_spear_trap_damage_wait();
		}

	}
	self.spear_trap_slow = false;
}

spear_choke()
{
	level._num_ai_released = 0;

	while(1)
	{
		wait(0.05);
		level._num_ai_released = 0;
	}
}

_zombie_spear_trap_damage_wait()
{
	self endon("death");

	if(!IsDefined(level._spear_choke))
	{
		level._spear_choke = true;
		level thread spear_choke();
	}

	endTime = GetTime() + randomintrange(800,1200);
	while(endTime>GetTime())
	{
		if(!is_true(self.has_legs))
		{
			break;
		}
		wait .05;
	}

	while(level._num_ai_released > 2)
	{
		PrintLn("Spear Trap : Choke");
		wait(0.05);
	}

	self stopanimscripted(.5);
	level._num_ai_released ++;
}


_fake_red()
{
	prompt = NewClientHudElem(self);
	prompt.alignX = "left";
	prompt.x = 0;
	prompt.y = 0;
	prompt.alignX = "left";
	prompt.alignY = "top";
	prompt.horzAlign = "fullscreen";
	prompt.vertAlign = "fullscreen";

	//prompt.sort = 2;
	//prompt.fontscale = 3.0;
	fadeTime = 1.0;
	prompt.color = ( 0.2, 0, 0 );
	prompt.alpha = 0.7;
	prompt FadeOverTime(fadeTime);
	prompt.alpha = 0;
	prompt.shader = "white";
	prompt setShader( "white", 640, 480 );

	wait(fadeTime);

	prompt Destroy();
}

spear_trap_is_character_touching(char)
{
	return self isTouching(char);
}

spear_activate(delay)
{
	wait delay;

	if(isDefined(self.clip))
	{
		self.clip solid();
		self.clip setclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_SPIKES);
	}

	wait(2);

	if(isDefined(self.clip))
	{
		self.clip notsolid();
		self.clip clearclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_SPIKES);
	}

	wait .2;
}

spear_kill(magnitude, activator)
{
	self StartRagdoll();
	self launchragdoll((0, 0, 50));
	wait_network_frame();

	// Make sure they're dead...physics launch didn't kill them.
	self.a.gib_ref = "head";

	self.trap_death = true;
	self.no_powerups = true;
	self dodamage(self.health + 666, self.origin, activator);
}

/*
///////////////////////////////////////////////////////
//Trap Switch
///////////////////////////////////////////////////////
temple_trap_light_red()
{

	for(i=0;i<self.trap_lights.size;i++)
	{
		light = self.trap_lights[i];
		light setmodel("zombie_zapper_cagelight_red");

		if(isDefined(light.fx))
		{
			light.fx delete();
		}

		light.fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_red", 2, "script_model", ( light.origin[0], light.origin[1], light.origin[2]+10 ) );
		light.fx setmodel("tag_origin");
		playfxontag(level._effect["trap_light_notready"],light.fx,"tag_origin");
	}
}

temple_trap_light_green()
{
	for(i=0;i<self.trap_lights.size;i++)
	{
		light = self.trap_lights[i];
		light setmodel("zombie_zapper_cagelight_green");

		if(isDefined(light.fx))
		{
			light.fx delete();
		}

		light.fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_green", 2, "script_model", ( light.origin[0], light.origin[1], light.origin[2]+10 ) );
		light.fx setmodel("tag_origin");
		playfxontag(level._effect["trap_light_ready"],light.fx,"tag_origin");
	}
}
*/
temple_trap_move_switch()
{
	default_amount = 5;
	default_time = .75;
	extra_time = 0;

	// Rotate switch model
	trap_switch = undefined;
	for(i=0; i<self.trap_switches.size; i++)
	{
		trap_switch = self.trap_switches[i];
		//trap_switch movey(-5,.75);//rotatepitch( 30, .5 );

		amount = (self.init_y - default_amount) - trap_switch.origin[1];
		time = (abs(amount) / default_amount) * default_time;
		if(time == 0)
		{
			time = .05;
		}
		extra_time = default_time - time;

		trap_switch movey(amount, time);
	}

	if(isDefined(trap_switch))
	{
		trap_switch playloopsound("zmb_pressure_plate_loop");
		//trap_switch playsound( "amb_sparks_l_b" );
		trap_switch waittill( "movedone" );
		trap_switch stoploopsound();
		trap_switch playsound("zmb_pressure_plate_lock");
	}

	if(extra_time > 0)
	{
		wait extra_time;
	}

	// Set switch back when availible
	self notify( "switch_activated" );
	self waittill( "trap_ready" );
	for(i=0; i<self.trap_switches.size; i++)
	{
		trap_switch = self.trap_switches[i];
		//trap_switch movey(5,.75);

		amount = self.init_y - trap_switch.origin[1];
		
		trap_switch movey(amount, default_time);
		trap_switch playloopsound("zmb_pressure_plate_loop");
		//trap_switch playsound( "amb_sparks_l_b" );
		trap_switch waittill( "movedone" );
		trap_switch stoploopsound();
		trap_switch playsound("zmb_pressure_plate_lock");
	}
}

///////////////////////////////////////////////////////
//Waterfall Trap
///////////////////////////////////////////////////////
waterfall_trap_init()
{
	useTriggers = GetEntArray("waterfall_trap", "targetname");
	for(i=0; i<useTriggers.size; i++)
	{
		trapStruct = spawnStruct();

		//Setup the use trigger
		trapStruct.useTrigger = useTriggers[i];
		trapStruct.useTrigger SetHintString( &"ZOMBIE_NEED_POWER");
		trapStruct.useTrigger SetCursorHint( "HINT_NOICON" );

		//Get fx locations
		//MCG NOTE: Done with exploders now
		//trapStruct.waterFX = [];
		//trapStruct.waterFX = GetStructArray(trapStruct.useTrigger.target, "targetname");

		//Setup switch and light model
		//trapStruct.trap_lights = [];
		trapStruct.trap_switches = [];
		trapStruct.trap_damage = []; //Damage triggers or zones
		trapStruct.trap_shake = []; //Origins of screen shake
		trapStruct.water_drop_trigs = []; //Water drop tiggers to turn on and off;
		targetEnts = GetEntArray(trapStruct.useTrigger.target, "targetname");
		targetStructs = GetStructArray(trapStruct.useTrigger.target, "targetname");
		targets = array_combine(targetEnts, targetStructs);
		for(j=0; j<targets.size; j++)
		{
			if(!isDefined(targets[j].script_noteworthy))
			{
				continue;
			}

			switch(targets[j].script_noteworthy)
			{
				case "trap_switch":
				trapStruct.trap_switches[trapStruct.trap_switches.size] = targets[j];
				break;
				/*
				case "trap_light":
				trapStruct.trap_lights[trapStruct.trap_lights.size] = targets[j];
				break;
				*/
				case "trap_damage":
				trapStruct.trap_damage[trapStruct.trap_damage.size] = targets[j];
				break;

				case "trap_shake":
				trapStruct.trap_shake[trapStruct.trap_shake.size] = targets[j];
				break;

				case "water_drop_trigger":
				targets[j] trigger_off();
				trapStruct.water_drop_trigs[trapStruct.water_drop_trigs.size] = targets[j];
				break;
			}
		}

		//Enable flag prevents the trap from being active enven when the power is on
		//Used when trap is in a doorway and can't be used until it is opened
		trapStruct.enable_flag = trapStruct.useTrigger.script_noteworthy;

		trapStruct waterfall_trap_think();
	}
}

waterfall_trap_think()
{
	self.useTrigger.zombie_cost = 500;
	flag_wait("power_on");

	self.useTrigger thread update_string();
	self.init_y = self.trap_switches[0].origin[1];

	while (1)
	{
		//Set trap as usable
		self notify("trap_ready");
		self.useTrigger SetHintString(&"REIMAGINED_USE_WATER_TRAP", self.useTrigger.zombie_cost);

		//Wait for a use trigger to be activated

		self.useTrigger waittill("trigger", who);

		// Did a valid player use the trigger?
		if( is_player_valid( who ) && !who in_revive_trigger() )
		{
			if( who.score < self.useTrigger.zombie_cost)
			{
				continue;
			}

			play_sound_at_pos( "purchase", who.origin );
			who maps\_zombiemode_score::minus_to_player_score( self.useTrigger.zombie_cost );

			//Added for sidequest
			who.used_waterfall = true;

			//"animate" the switch
			self.useTrigger._trap_in_use = 1;
			self.useTrigger SetHintString(&"REIMAGINED_WATER_TRAP_ACTIVE");
			self thread temple_trap_move_switch();
			self waittill( "switch_activated" );

			//Activate Waterfall FX
			waterfall_trap_on();

			//wait here to let the fx get started
			wait(.5);

			//Added for sidequest
			who.used_waterfall = false;

			activeTime = 5.5;

			//Water on screen triggers
			array_thread(self.water_drop_trigs, ::waterfall_screen_fx, activeTime);

			//Activate Damage Trigger
			array_thread(self.trap_damage, ::waterfall_trap_damage, who);

			//Screen shake
			self thread waterfall_screen_shake(activeTime);

			//Active time
			wait activeTime;

			//Turn off trap
			self notify("trap_off");

			//Hide Use Message
			self.useTrigger._trap_cooling_down = 1;
			self.useTrigger SetHintString(&"ZOMBIE_TEMPLE_WATER_TRAP_COOL");

			array_thread(self.water_drop_trigs, ::trigger_off);
			waterfall_trap_off();
			array_notify(self.trap_damage, "trap_off");

			//Cool Down time
			if(!level.zombie_vars["zombie_powerup_fire_sale_on"])
			{
				level waittill_notify_or_timeout("fire_sale_on", 30);
			}

			self.useTrigger._trap_in_use = 0;
			self.useTrigger._trap_cooling_down = 0;
		}
	}
}

waterfall_screen_fx(activeTime)
{
	delay = 1.5;
	wait delay;

	self.waterSheetingTime = activeTime-delay;
	self trigger_on();
}
waterfall_screen_shake(activeTime)
{
	wait( 1 );
	for(i=0;i<self.trap_shake.size;i++)
	{
		waterfall_screen_shake_single( activeTime, self.trap_shake[i].origin );
	}
}

waterfall_screen_shake_single(activeTime, origin)
{
	remainingTime = 1.0;
	if ( activeTime > 6.0 )
	{
		remainingTime = activeTime-6.0;
	}
	while( remainingTime > 0.0 )
	{
		Earthquake( 0.14, activeTime, origin, 400 );
		wait( 1.0 );
		remainingTime -= 1.0;
	}
}

waterfall_trap_on()
{
	soundStruct = getStruct("waterfall_trap_origin", "targetname");
	if(isDefined(soundStruct))
	{
		playsoundatposition("evt_waterfall_trap", soundStruct.origin);
	}

	level notify("waterfall");
	clientnotify("WF");

	exploder(21); // waterfall body w trap
	stop_exploder(20); // waterfall body w/o trap
}

waterfall_trap_off()
{
    exploder(20); // waterfall body w/o trap
		//stop_exploder(21);
}

/*
waterfall_trap_fx()
{
	if(!isDefined(self.angles))
	{
		self.angles = (0,0,0);
	}

	fx = SpawnFx(level._effect["waterfall_trap"],self.origin, AnglesToForward(self.angles));
	triggerfx( fx );

	self waittill("trap_off");

	fx Delete();

}
*/

waterfall_trap_damage(activator)
{
	self endon("trap_off");

	fwd = AnglesToForward(self.angles);

	zombies_knocked_down = [];

	wait 1;

	while(1)
	{

		self waittill("trigger", who);
		if(isPlayer(who))
		{
			if(isDefined(self.script_string) && self.script_string == "hurt_player")
			{
				who dodamage(20, self.origin);
				wait 1.0;
			}
			else
			{
				who thread waterfall_trap_player(fwd,5.45);
			}
		}
		if( isDefined(who.animname) && who.animname == "monkey_zombie")
		{
			who thread waterfall_trap_monkey(randomintrange(30,80),fwd, activator);
		}
		else
		{
			if(!ent_in_array(who,zombies_knocked_down)) //make sure this only gets called on the zombies once
			{
				zombies_knocked_down[zombies_knocked_down.size] = who;
				//wait_network_frame();
				who thread zombie_waterfall_knockdown(activator);
			}
		}
	}
}

waterfall_trap_player(fwd,time)
{
	vel = self GetVelocity();
	self SetVelocity(vel + fwd * 60.0);

	//time = time - 4;

	//end_time = gettime() + (time * 1000);

	//while(end_time > gettime() )
	//{
	self PlayRumbleOnEntity("slide_rumble");
		//wait(randomfloatrange(.1,.15));
	//}

}

waterfall_trap_monkey(magnitude, dir, activator)
{
	//wait(1);
	self StartRagdoll();
	self launchragdoll(dir * magnitude);
	wait_network_frame();

	// Make sure they're dead...physics launch didn't kill them.
	//self.a.gib_ref = "head";
	self.trap_death = true;
	self.no_powerups = true;
	self dodamage(self.health + 666, self.origin, activator);
}


ent_in_array(ent,_array)
{
	for(i=0;i<_array.size;i++)
	{
		if(_array[i] == ent)
		{
			return true;
		}
	}
	return false;
}



////////////////////////
//Maze Trap
///////////////////////
init_maze_trap()
{
	level.mazeCells = [];
	level.mazeFloors = [];
	level.mazeWalls = [];
	level.mazePath = [];
	level.startCells = [];
	level.pathPlayers = [];
	level.pathActive = false;

	//Set up client system
	level thread init_client_maze_trap();

	//Delete clip brush that allows pathing to generate correctly
	mazeClip = getEnt("maze_path_clip", "targetname");
	if(isDefined(mazeClip))
	{
		mazeClip delete();
	}

	//Set up predefined maze paths
	init_maze_paths();

	//Triggers
	mazeTriggers = getEntArray("maze_trigger", "targetname");
	for(i=0;i<mazeTriggers.size;i++)
	{
		mazeTrigger = mazeTriggers[i];
		mazeTrigger.pathCount = 0;
		triggerNum = mazeTrigger.script_int;
		if(!isDefined(triggerNum))
		{
			//Warning
			continue;
		}
		_add_maze_cell(triggerNum);
		level.mazeCells[triggerNum-1].trigger = mazeTrigger;

		//Is this a start Cell (can paths randomly start or end here)
		if(isDefined(mazeTrigger.script_string))
		{
			//Possible Start squares
			startCell = mazeTrigger.script_string == "start";
			if(startCell)
			{
				level.startCells[level.startCells.size] = level.mazeCells[triggerNum-1];
			}
		}
	}

	//Floors
	mazeFloors = getEntArray("maze_floor", "targetname");
	for(i=0;i<mazeFloors.size;i++)
	{
		mazeFloor = mazeFloors[i];
		floorNum = mazeFloor.script_int;
		if(!isDefined(floorNum))
		{
			//Warning
			continue;
		}

		mazeFloor init_maze_mover(16,0.25,0.5,false,"evt_maze_floor_up","evt_maze_floor_up",false);
		level.mazeCells[floorNum-1].floor = mazeFloor;

		level.mazeFloors[level.mazeFloors.size] = mazeFloor;
	}

	//Walls
	mazeWalls = getEntArray("maze_door", "targetname");
	for(i=0;i<mazeWalls.size;i++)
	{
		mazeWall = mazeWalls[i];
		wallNum = mazeWall.script_int;
		if(!isDefined(wallNum))
		{
			//Warning
			continue;
		}

		mazeWall init_maze_mover(-128,0.25,1.0,true,"evt_maze_wall_down","evt_maze_wall_up",true);//NOTE: up & down event names are backwards, hence the unbackwardsifying here...
		mazeWall NotSolid();
		mazeWall connectpaths();
		mazeWall.script_fxid = level._effect["maze_wall_impact"];//fx_ztem_dust_impact_maze
		mazeWall.script_fxid2 = level._effect["maze_wall_raise"];//fx_ztem_dust_maze_raise
		mazeWall.fx_active_offset = (0,0,-60);

		mazeWall.adjacentCells = [];

		adjacent_cell_nums = [];
		adjacent_cell_nums[0] = wallNum % 100;
		adjacent_cell_nums[1] = int((wallNum - (wallNum % 100)) / 100);

		for(j=0;j<adjacent_cell_nums.size;j++)
		{
			cell_num = adjacent_cell_nums[j];
			if(cell_num == 0)
			{
				continue;
			}

			mazeCell = level.mazeCells[cell_num-1];
			mazeCell.walls[mazeCell.walls.size] = mazeWall;
			mazeWall.adjacentCells[mazeWall.adjacentCells.size] = mazeCell;
		}

		level.mazeWalls[level.mazeWalls.size] = mazeWall;
	}

	//Init start cells
	maze_show_starts();

	array_thread(level.mazeCells, ::maze_cell_watch);
	array_thread(level.mazeCells, ::maze_cell_debug);
}

init_client_maze_trap()
{
	wait_for_all_players();
	wait 3;
}

init_maze_paths()
{
	level.mazePathCounter = 0;	//Number of times the maze has generated a path

	level.mazePaths = [];

	//  __ __ __ __ __
	// |12| 9| 6| 3| 0|
	// |13|10| 7| 4| 1|
	// |14|11| 8| 5| 2|
	//  -- -- -- -- --

	//5 -> 3
	add_maze_path(array(5,4,3));
	add_maze_path(array(5,4,1,0,3));
	add_maze_path(array(5,4,7,6,3));

	//5->12
	add_maze_path(array(5,4,3,6,9,12));
	add_maze_path(array(5,4,7,10,11,14,13,12));
	add_maze_path(array(5,4,1,0,3,6,9,12));

	//5->8 Loop back
	add_maze_path(array(5,4,7,8), true);
	add_maze_path(array(5,4,1,0,3,6,7,8), true);

	//  __ __ __ __ __
	// |12| 9| 6| 3| 0|
	// |13|10| 7| 4| 1|
	// |14|11| 8| 5| 2|
	//  -- -- -- -- --

	//3->12
	add_maze_path(array(3,4,7,10,13,12));
	add_maze_path(array(3,4,5,8,7,6,9,12));
	add_maze_path(array(3,4,1,2,5,8,11,10,9,12));

	//3->5
	add_maze_path(array(3,4,5));
	add_maze_path(array(3,4,7,6,9,10,11,8,5));
	add_maze_path(array(3,4,1,2,5));

	//3->6 Loop Back
	add_maze_path(array(3,4,7,6),true);
	add_maze_path(array(3,4,1,2,5,8,7,6),true);

	//  __ __ __ __ __
	// |12| 9| 6| 3| 0|
	// |13|10| 7| 4| 1|
	// |14|11| 8| 5| 2|
	//  -- -- -- -- --

	//12->3
	add_maze_path(array(12,9,6,3));
	add_maze_path(array(12,9,10,7,4,3));
	add_maze_path(array(12,9,10,13,14,11,8,5,4,3));

	//12->5
	add_maze_path(array(12,9,6,3,4,5));
	add_maze_path(array(12,9,10,11,8,7,4,5));
	add_maze_path(array(12,9,6,3,0,1,2,5));

	//12->13 Loop Back
	add_maze_path(array(12,9,10,13),true);
	add_maze_path(array(12,9,6,7,10,13),true);
}

add_maze_path(path, loopback)
{
	if(!isDefined(loopBack))
	{
		loopBack = false;
	}

	s = spawnStruct();
	s.path = path;
	s.loopBack = loopback;
	level.mazePaths[level.mazePaths.size] = s;
}

//self = mover (wall or floor)
//Walls and floors share many common variables
//floor init_maze_mover(16,0.5,0.5,false, "evt_maze_floor_up", false);
//wall init_maze_mover(120,0.5,1.0,true,"evt_maze_wall_up", "evt_maze_wall_down", true);
init_maze_mover(moveDist, moveUpTime, moveDownTime, blocksPaths, moveUpSound, moveDownSound,clipOnly)
{
	self.isActive = false;
	self.activeCount = 0;
	self.isMoving = false;
	self.moveDist = moveDist;
	self.activeHeight = self.origin[2] + moveDist;
	self.moveUpTime = moveUpTime;
	self.moveDownTime = moveDownTime;
	self.pathBlocker = blocksPaths;
	self.alwaysActive = false;
	self.moveUpSound = moveUpSound;
	self.moveDownSound = moveDownSound;
	self.startAngles = self.angles;
	self.clipOnly = clipOnly;
	if(isDefined(self.script_string) && self.script_string == "always_active")
	{
		maze_mover_active(true);
		self.alwaysActive = true;
	}
}

maze_cell_debug()
{
//	floor = self.floor;
//	while (1)
//	{
//		text = "Count: " + floor.activeCount;
//		print3d( floor.origin+(0,0,50), text, (0.0, 0.8, 0.0), 1, .5, 1 );
//		wait .05;
//	}

/#
	while (1)
	{
		if(getDebugDvarInt( "debug_temple_maze" ) == 1)
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				if(!isDefined(players[i].mazePathCells))
				{
					continue;
				}

				for(j=0;j<players[i].mazePathCells.size;j++)
				{
					text = "Player: " + i;
					print3d( players[i].mazePathCells[j].floor.origin+(0,0,50 + i *10), text, (0.0, 0.8, 0.0), 1, .5, 1 );

				}
			}
		}
		wait .05;
	}
#/
}


_add_maze_cell(cell_index)
{
	for(i=level.mazeCells.size;i<cell_index; i++)
	{
		level.mazeCells[i] = spawnStruct();
		level.mazeCells[i] _init_maze_cell();
	}
}

//self = maze cell
_init_maze_cell()
{
	self.trigger = undefined;
	self.floor = undefined;
	self.walls = [];
}

maze_mover_active(active)
{
	if(self.alwaysActive)
	{
		return;
	}

	if(active)
	{
		self.activeCount++;
	}
	else
	{
		self.activeCount = int(max(0, self.activeCount-1));
	}

	active = self.activeCount > 0;

	if(self.isActive == active)
	{
		return;
	}

	//Play Move sound
	if(active && isDefined(self.moveUpSound))
	{
		self playSound(self.moveUpSound);
	}

	if(!active && isDefined(self.moveDownSound))
	{
		self playSound(self.moveDownSound);
	}

	//Set goal pos
	goalPos = (self.origin[0], self.origin[1], self.activeHeight);
	if(!active)
	{
		goalPos = (goalPos[0], goalPos[1], goalPos[2] - self.moveDist);
	}

	//Set up moveTime
	moveTime = self.moveUpTime;
	if(!active)
	{
		moveTime = self.moveDownTime;
	}

	//Scale move time so we get constant move speed
	if(self.isMoving)
	{
		currentZ = self.origin[2];
		goalZ = goalPos[2];
		ratio = Abs(goalZ-currentZ)/Abs(self.moveDist);
		moveTime *= ratio;
	}

	//Stop other movement
	self notify("stop_maze_mover");

	//Start new movement
	self.isActive = active;

	//Server side may only do clip, no actual movement
	if(self.clipOnly)
	{
		if(active)
		{
			self Solid();
			self disconnectPaths();
			self setclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_MAZE_WALL);
		}
		else
		{
			self NotSolid();
			self connectPaths();
			self clearclientflag(level._CF_SCRIPTMOVER_CLIENT_FLAG_MAZE_WALL);
		}
	}
	else
	{
		self thread _maze_mover_move(goalPos, moveTime);
	}



}
_maze_mover_move(goal, time)
{
	self endon("stop_maze_mover");

	self.isMoving = true;
	if(time==0)
	{
		time = .01; //Cancel move command
	}

	self moveto(goal, time);
	self waittill("movedone");

	self.isMoving = false;

	if(self.isActive)
	{
		_maze_mover_play_fx(self.script_fxid, self.fx_active_offset);
	}
	else
	{
		_maze_mover_play_fx(self.script_fxid2, self.fx_active2_offset);
	}

	if(self.pathBlocker)
	{
		if(	self.isActive )
		{
			self disconnectpaths();
		}
		else
		{
			self connectpaths();
		}
	}

}

_maze_mover_play_fx(fx_name, offset)
{
	if ( IsDefined( fx_name ) )
	{
		vFwd = AnglesToForward(self.angles);
		org = self.origin;
		if ( isdefined( offset ) )
		{
			org += offset;
		}
		PlayFX( fx_name, org, vFwd, (0,0,1) );
	}
}

maze_cell_watch()
{
	level endon("fake_death");

	while(1)
	{
		self.trigger waittill("trigger", who);

		//This is a path trigger
		if(self.trigger.pathCount > 0)
		{
			if ( isplayer( who ) && who IsOnGround() )
			{
				//Player must be completely out of slow triggers to start path trigger
				if(who is_player_maze_slow())
				{
					continue;
				}

				if(who.sessionstate == "spectator")
				{
					continue;
				}

				self thread maze_cell_player_enter(who);
			}
			else if ( isdefined( who.animname ) && who.animname == "zombie" )
			{
				self.trigger thread zombie_normal_trigger_exit( who );
			}
		}
		else //This is a slow trigger
		{
			if ( isplayer( who ) && who IsOnGround() )
			{
				if(who is_player_on_path())
				{
					continue;
				}
				if(who.sessionstate == "spectator")
				{
					continue;
				}
				self.trigger thread watch_slow_trigger_exit(who);
			}
			else if ( isdefined( who.animname ) && who.animname == "zombie" )
			{
				self.trigger thread zombie_slow_trigger_exit( who );
			}
		}
	}
}

//----------------------------------------------------------------------------------------------
// change run speed in mud
//----------------------------------------------------------------------------------------------
zombie_mud_move_slow()
{
	switch( self.zombie_move_speed )
	{
	case "run":
		var = randomintrange( 1, 9 );
		self set_run_anim( "walk" + var );
		self.run_combatanim = level.scr_anim[ self.animname ][ "walk" + var ];
		break;

	case "sprint":
		var = randomintrange( 1, 7 );
		self set_run_anim( "run" + var );
		self.run_combatanim = level.scr_anim[ self.animname ][ "run" + var ];
		break;
	}

	self.needs_run_update = true;
}

//----------------------------------------------------------------------------------------------
// back to previous move speed
//----------------------------------------------------------------------------------------------
zombie_mud_move_normal()
{
	switch( self.zombie_move_speed )
	{
	case "run":
		var = randomintrange( 1, 7 );
		self set_run_anim( "run" + var );
		self.run_combatanim = level.scr_anim[ self.animname ][ "run" + var ];
		break;

	case "sprint":
		var = randomintrange( 1, 5 );
		self set_run_anim( "sprint" + var );
		self.run_combatanim = level.scr_anim[ self.animname ][ "sprint" + var ];
		break;
	}

	self.needs_run_update = true;
}

//----------------------------------------------------------------------------------------------
// zombie no longer on mud
//----------------------------------------------------------------------------------------------
zombie_slow_trigger_exit( zombie )
{
	zombie endon( "death" );

	if ( isdefined( zombie.mud_triggers ) )
	{
		if ( is_in_array( zombie.mud_triggers, self ) )
		{
			return;
		}
	}
	else
	{
		zombie.mud_triggers = [];
	}

	if ( !zombie zombie_on_mud() )
	{
		zombie zombie_mud_move_slow();
	}

	zombie.mud_triggers[ zombie.mud_triggers.size ] = self;

	while ( self.pathCount == 0 && zombie isTouching( self ) )
	{
		wait( 0.1 );
	}

	zombie.mud_triggers = array_remove( zombie.mud_triggers, self );

	if ( !zombie zombie_on_mud() && !zombie zombie_on_path() )
	{
		zombie zombie_mud_move_normal();
	}
}

zombie_on_path()
{
	return ( isdefined( self.path_triggers ) && self.path_triggers.size > 0 );
}

zombie_on_mud()
{
	return ( isdefined( self.mud_triggers ) && self.mud_triggers.size > 0 );
}

//----------------------------------------------------------------------------------------------
// zombie no longer on path
//----------------------------------------------------------------------------------------------
zombie_normal_trigger_exit( zombie )
{
	zombie endon( "death" );

	if ( isdefined( zombie.path_triggers ) )
	{
		if ( is_in_array( zombie.path_triggers, self ) )
		{
			return;
		}
	}
	else
	{
		zombie.path_triggers = [];
	}

	if ( !zombie zombie_on_path() )
	{
		zombie zombie_mud_move_normal();
	}

	zombie.path_triggers[ zombie.path_triggers.size ] = self;

	while ( self.pathCount != 0 && zombie isTouching( self ) )
	{
		wait( 0.1 );
	}

	zombie.path_triggers = array_remove( zombie.path_triggers, self );

	//if ( zombie zombie_on_mud() )
	//{
	//	zombie zombie_mud_move_slow();
	//}
}

is_player_on_path()
{
	return isDefined(self.mazePathCells) && self.mazePathCells.size>0;
}

is_player_maze_slow()
{
	return isDefined(self.mazeSlowTrigger) && self.mazeSlowTrigger.size>0;
}

maze_cell_player_enter(player)
{

	if(isDefined(player.mazePathCells))
	{
		if( is_in_array(player.mazePathCells, self))
		{
			//Already watching this path trigger
			return;
		}
	}
	else
	{
		player.mazePathCells = [];
	}

	//Track players on the path
	if(!is_in_array(level.pathPlayers,player))
	{
		level.pathPlayers[level.pathPlayers.size] = player;
	}

	//Track triggers the player is touching
	player.mazePathCells[player.mazePathCells.size] = self;

	//Player who touched the path first is the path master
	//isPathMaster = player == level.pathPlayers[0];

	//if(!level.pathActive && isPathMaster )
	if(!level.pathActive)
	{
		//init maze with new random path
		self maze_start_path();
	}

	//if(isPathMaster)
	{
		on_maze_cell_enter();
	}

	//Wait till the player stops touching this trigger or it is no longer a path trigger
	self path_trigger_wait(player);

	//Player may have been disconnected, need to be carful with clean up
	isPlayerValid = isDefined(player);

	//May have become path master while waiting
	if(isPlayerValid)
	{
		//Stop Tracking this cell on player
		player.mazePathCells = array_remove(player.mazePathCells, self);
		//isPathMaster = player == level.pathPlayers[0];
	}
	else
	{
		//isPathMaster = !isDefined(level.pathPlayers[0]);
	}

	//Special cases for exiting the path
	if(!isPlayerValid || !player is_player_on_path())
	{
		level.pathPlayers = remove_undefined_from_array(level.pathPlayers);

		if(isPlayerValid)
		{
			level.pathPlayers = array_remove(level.pathPlayers, player);
		}

		//if(isPathMaster)
		{
			//Reset the maze if no players on the path
			if(level.pathPlayers.size == 0)
			{
				maze_end_path();
			}
//			else //init new path master
//			{
//
//				newPathMaster = level.pathPlayers[0];
//
//				for(i=0; i<newPathMaster.mazePathCells.size; i++)
//				{
//					newPathMaster.mazePathCells[i] on_maze_cell_enter();
//				}
//			}
		}
	}

//	if(isPathMaster)
	{
		on_maze_cell_exit();
	}
}

path_trigger_wait(player)
{
	player endon("disconnect");
	player endon("fake_death");
	player endon("death");
	level endon("maze_timer_end");

	while(self.trigger.pathCount != 0 && player isTouching(self.trigger) && player.sessionstate != "spectator")
	{
		wait .1;
	}
}

//self = cell
on_maze_cell_enter()
{
	//Set up information about adjacent cells
	current 			= self;
	previous 			= current cell_get_previous();
	next 				= current cell_get_next();

	//Raise The Floor
	raise_floor(previous);
	raise_floor(current);
	raise_floor(next);

	//Raise/Lower Walls
	activate_walls(previous);
	activate_walls(current);
	activate_walls(next);
}

//self = cell
on_maze_cell_exit()
{
	//Set up information about adjacent cells
	current 			= self;
	previous 			= current cell_get_previous();
	next 				= current cell_get_next();

	//Lower the floor
	lower_floor(previous);
	lower_floor(current);
	lower_floor(next);

	//Lower Walls
	lower_walls(previous);
	lower_walls(current);
	lower_walls(next);
}


watch_slow_trigger_exit(player)
{
	player endon("death");
	player endon("fake_death");
	player endon("disconnect");

	//This must be set every frame becasue it can be unset by a revive.
	player allowJump(false);

	if(isDefined(player.mazeSlowTrigger))
	{
		if( is_in_array(player.mazeSlowTrigger, self))
		{
			//Already watching this slow trigger
			return;
		}
	}
	else
	{
		player.mazeSlowTrigger = [];
	}

	//First time touching a slow trigger?
	if(!player is_player_maze_slow())
	{
		player.move_speed = .35;
		player SetMoveSpeedScale( player.move_speed );
		player clientnotify( "sle" );//notify to override footstep audio
		//player setvelocity((0,0,0));
	}

	player.mazeSlowTrigger[player.mazeSlowTrigger.size] = self;

	//Wait till the player stops touching this trigger or it is no longer a slow trigger
	while(self.pathCount == 0 && player isTouching(self))
	{
		player allowSprint(false);
		player allowProne(false);
		wait .1;
	}

	player.mazeSlowTrigger = array_remove(player.mazeSlowTrigger, self);

	if(!player is_player_maze_slow())
	{
		player allowJump(true);
		player allowSprint(true);
		player allowProne(true);
		player.move_speed = 1;
		if(!is_true(player.slowdown_wait))
		{
			player SetMoveSpeedScale(player.move_speed);
		}
		player clientnotify( "sll" );//notify to override footstep audio
	}
}
lower_walls(cell)
{
	if(!isDefined(cell))
	{
		return;
	}

	for(i=0;i<cell.walls.size;i++)
	{
		wall = cell.walls[i];
		wall thread maze_mover_active(false);
	}


}
activate_walls(cell)
{
	if(!isDefined(cell))
	{
		return;
	}

	previous 			= cell cell_get_previous();
	next 				= cell cell_get_next();

	previousSharedWall 	= maze_cells_get_shared_wall(previous,cell);
	nextSharedWall 		= maze_cells_get_shared_wall(cell,next);

	for(i=0;i<cell.walls.size;i++)
	{
		wall = cell.walls[i];
		activateWall = true;

		if(		(isDefined(previousSharedWall) 	&& wall==previousSharedWall) //Don't block path to my next cell
			|| 	(isDefined(nextSharedWall) 		&& wall==nextSharedWall)	//Don't block path to my previous cell
			|| 	(!isDefined(previous) 			&& wall.adjacentCells.size == 1) //Don't close the maze entrance wall
			|| 	(!isDefined(next) 				&& wall.adjacentCells.size == 1) ) //Don't close the maze exit wall
		{
			activateWall = false;
		}

		wall thread maze_mover_active(activateWall);
	}
}

raise_floor(mazeCell)
{
	if(isDefined(mazeCell))
	{
		mazeCell.trigger.pathCount++;
		mazeCell.floor thread maze_mover_active(true);
	  level thread delete_cell_corpses(mazeCell);
	}

}

delete_cell_corpses(mazeCell)
{
	//delete any corpses
	bodies = getcorpsearray();
	for(i=0;i<bodies.size;i++)
	{
		if(!isdefined(bodies[i]))
		{
			continue;
		}
		if(bodies[i] istouching(mazeCell.trigger) || bodies[i] istouching(mazeCell.floor))
		{
			bodies[i] thread delete_corpse();
			wait_network_frame();
		}
	}
}

delete_corpse()
{
	self endon("death");

	if(is_mature() )
	{
		PlayFX(level._effect[ "animscript_gib_fx" ]	, self.origin);
	}
	if(isDefined(self))
	{
		self Delete();
	}
}

lower_floor(mazeCell)
{
	if(isDefined(mazeCell))
	{
		mazeCell.trigger.pathCount--;
		mazeCell.floor thread maze_mover_active(false);
	}

}

maze_cells_get_shared_wall(a,b)
{
	if(!isDefined(a) || !isDefined(b))
	{
		return undefined;
	}

	for(i=0;i<a.walls.size;i++)
	{
		for(j=0;j<b.walls.size;j++)
		{
			if(a.walls[i] == b.walls[j])
			{
				return a.walls[i];
			}
		}
	}

	return undefined;
}

maze_show_starts()
{
	for(i=0;i<level.startCells.size;i++)
	{
		raise_floor(level.startCells[i]);
	}
}

//self = start cell
maze_start_path()
{
	level.pathActive = true;
	for(i=0;i<level.startCells.size;i++)
	{
		lower_floor(level.startCells[i]);
	}

	self maze_generate_path();

	level thread maze_path_timer(10);
}

//When player on the path exits the maze
maze_end_path()
{
	level notify("maze_path_end");
	level.pathActive = false;
	level thread maze_show_starts_delayed();
}

maze_show_starts_delayed()
{
	level endon("maze_all_safe");
	wait 3;
	maze_show_starts();
}

//Diables path if it has been active for too long
maze_path_timer(time)
{
	level endon("maze_path_end");
	level endon("maze_all_safe");

	vibrateTime = 3;
	wait time-vibrateTime;

	level thread maze_vibrate_floor_stop();
	level thread maze_vibrate_active_floors(vibrateTime);
	wait vibrateTime;

	level notify("maze_timer_end");
	level thread repath_zombies_in_maze();
}

repath_zombies_in_maze()
{
	wait_network_frame();

	zombies = getaiarray("axis");
	for(i=0;i<zombies.size;i++)
	{
		zombie = zombies[i];

		if(!isDefined(zombie))
		{
			continue;
		}

		if(!isDefined(zombie.animname) || zombie.animname == "monkey_zombie")
		{
			continue;
		}
		if(zombie zombie_on_path() || zombie zombie_on_mud())
		{
			//Repath because there is probably a better path to the player now that the
			//walls are all reset.
			zombie notify( "stop_find_flesh" );
			zombie notify( "zombie_acquire_enemy" );
			wait_network_frame();
			zombie thread maps\_zombiemode_spawner::find_flesh();
		}
	}
}

maze_vibrate_active_floors(time)
{
	level endon("maze_path_end");
	level endon("maze_all_safe");

	endTime = GetTime() + time * 1000;
	while(endTime>GetTime())
	{
		for(i=0;i<level.mazeCells.size;i++)
		{
			cell = level.mazeCells[i];
			if(cell.floor.isActive)
			{
				cell thread maze_vibrate_floor((endTime - GetTime()) / 1000.0);

				// check to see if a player is touching the floor
				players = GetPlayers();
				for( w = 0; w < players.size; w++ )
				{
					if( players[w] IsTouching( cell.trigger ) )
					{
						cell.trigger thread trigger_thread( players[w], ::temple_maze_player_vibrate_on, ::temple_maze_player_vibrate_off );
					}
				}
			}
		}
		wait .1;
	}
}

// Set a flag on the player. If they are standing on the active tile before it leaves they should get some controller vibration.
temple_maze_player_vibrate_on( player, endon_condition )
{
	player endon( endon_condition );

	player SetClientFlag( level._CF_PLAYER_MAZE_FLOOR_RUMBLE );

	wait_network_frame();

	self thread temple_inactive_floor_rumble_cancel( player );
}

// Clear a flag on the player. If the player leaves a vibrating floor piece then their controller rumble should stop.
temple_maze_player_vibrate_off( player )
{
	player endon( "frc" ); // floor rumble cancel

	player ClearClientFlag( level._CF_PLAYER_MAZE_FLOOR_RUMBLE );

	player notify( "frc" ); // floor rumble cancel
}

// If the player stands still the trigger_thread will not exit and the controller will keep rumbling
temple_inactive_floor_rumble_cancel( ent_player )
{
	ent_player endon( "frc" ); // floor rumble cancel

	floor_piece = undefined;

	maze_floor_array = GetEntArray( "maze_floor", "targetname" );

	for( i = 0; i < maze_floor_array.size; i++ )
	{
		if( maze_floor_array[i].script_int == self.script_int )
		{
			floor_piece = maze_floor_array[i];
		}
	}

	while( IsDefined( floor_piece ) && floor_piece.isActive == true )
	{
		wait( 0.05 );
	}

	if( IsDefined( ent_player ) )
	{
		ent_player ClearClientFlag( level._CF_PLAYER_MAZE_FLOOR_RUMBLE );
	}

	ent_player notify( "frc" ); // floor rumble cancel
}


maze_vibrate_floor(time)
{
	if( is_true(self.isVibrating) )
	{
		return;
	}

	self.floor playsound("evt_maze_floor_collapse");

	self.isVibrating = true;
	dir = (randomFloatRange(-1,1),randomFloatRange(-1,1), 0);
	self.floor vibrate(dir, 0.75, 0.3, time);
	wait time;
	self.isVibrating = false;
}

maze_vibrate_floor_stop()
{
	level waittill_any("maze_path_end","maze_timer_end","maze_all_safe");

	for(i=0;i<level.mazeCells.size;i++)
	{
		cell = level.mazeCells[i];
		if(is_true(cell.isVibrating))
		{
			//Quick Stop
			cell.floor vibrate((0,0,1), 1, 1, .05);
			cell.floor rotateTo(cell.floor.startAngles, .1);
			cell.floor stopsounds();
		}
	}
}

//self = start cell
maze_generate_path()
{
	level.mazePath = [];

	//Init all cells
	for(i=0;i<level.mazeCells.size;i++)
	{
		level.mazeCells[i].pathIndex = -1;
	}

	path_index = self pick_random_path_index();

	path = level.mazePaths[path_index].path;
	level.mazePathLastStart = path[0];
	level.mazePathLastEnd = path[path.size-1];

	//Set path
	for(i=0;i<path.size;i++)
	{
		level.mazePath[i] = level.mazeCells[path[i]];
		level.mazePath[i].pathIndex = i;
	}

	level.mazePathCounter++;
}

//Self == start cell
pick_random_path_index()
{
	//Find start Cell index
	startIndex = 0;
	for(i=0;i<level.mazeCells.size;i++)
	{
		if(level.mazeCells[i] == self)
		{
			startIndex = i;
			break;
		}
	}

	//Create random index array
	path_indexes = [];
	for(i=0;i<level.mazePaths.size;i++)
	{
		path_indexes[i] = i;
	}

	path_indexes = array_randomize(path_indexes);

	returnIndex = -1;	//
	//loop through all the paths and find on that is not a repeating path
	for(i=0;i<path_indexes.size;i++)
	{
		index = path_indexes[i];
		path = level.mazePaths[index].path;

		if(level.mazePaths[index].loopBack)
		{
			//The first 3 times the players use the maze it wont give loop back
			if(level.mazePathCounter<3)
			{
				continue;
			}

			//Reduce the odds of getting a loop back
			//If paths were picked completely at random loop back would occur 25% of the time
			//We would like it to be closer to 10%
			if(randomfloat(100)>40)
			{
				continue;
			}
		}


		//Check for repeat paths
		if(isDefined(level.mazePathLastStart) && isDefined(level.mazePathLastEnd))
		{
			if(level.mazePathLastStart == path[0] && level.mazePathLastEnd == path[path.size-1])
			{
				continue;
			}
		}

		//Make sure path starts at current cell
		if(startIndex == path[0])
		{
			returnIndex = index;
			break;
		}
	}

	return returnIndex;
}

//self = cell
cell_get_next()
{
	index = self.pathIndex;
	if(index < level.mazePath.size - 1)
	{
		return level.mazePath[index+1];
	}

	return undefined;
}

cell_get_previous()
{
	index = self.pathIndex;
	if(index > 0)
	{
		return level.mazePath[index-1];
	}

	return undefined;
}

/*------------------------------------
knock the zombies down w/the water trap
------------------------------------*/
zombie_waterfall_knockdown(activator)
{
	self endon("death");

	self.lander_knockdown = 1;
	//wait(1.25);

	if ( IsDefined( self.thundergun_knockdown_func ) )
	{
		self[[ self.thundergun_knockdown_func ]]( activator, false );
	}
}

override_thundergun_damage_func(player,gib)
{
	dmg_point = getstruct("waterfall_dmg_point","script_noteworthy");
	self.thundergun_handle_pain_notetracks = ::handle_knockdown_pain_notetracks;
	if(self.animname == "zombie")
	{
		if( self.has_legs )
		{
			self.deathanim = random( level._zombie_knockdowns[self.animname]["front"]["has_legs"] );
		}

		self.trap_death = true;
		self.no_powerups = true;
		self DoDamage( level.zombie_health + 1000, dmg_point.origin, player );
	}
	else
	{
		self DoDamage( 1, dmg_point.origin, player );
	}
}

handle_knockdown_pain_notetracks( note )
{

}

update_string()
{
	self.old_cost = self.zombie_cost;

	while(1)
	{
		level waittill("fire_sale_on");

		self.zombie_cost = 10;

		if(!is_true(self._trap_in_use) && !is_true(self._trap_cooling_down))
		{
			self SetHintString( &"REIMAGINED_USE_WATER_TRAP", self.zombie_cost );
		}

		level waittill("fire_sale_off");

		self.zombie_cost = self.old_cost;

		if(!is_true(self._trap_in_use) && !is_true(self._trap_cooling_down))
		{
			self SetHintString( &"REIMAGINED_USE_WATER_TRAP", self.zombie_cost );
		}
	}
}