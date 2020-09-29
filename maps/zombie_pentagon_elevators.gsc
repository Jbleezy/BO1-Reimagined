#include animscripts\zombie_utility;
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\zombie_pentagon_teleporter;

init()
{
	//flag intitializations.
	flag_init("defcon_active");
	flag_init("no_pack_room_spawning");
	flag_init("open_pack_hideaway");
	flag_init( "labs_enabled" );
	flag_init("bonfire_reset");
	flag_init("elevator_grounded");
	flag_init( "war_room_start" ); // ww: flag for war room achievement
	flag_init("no_warroom_elevator_spawning");
	flag_init("no_labs_elevator_spawning");

	elevator1 = getent( "elevator1", "targetname" );
	elevator2 = getent( "elevator2", "targetname" );

	elevator1.cost = 250;	// rsh071510 - can have independent cost
	elevator1.station = "elevator1_up";
	elevator1.called = false;
	elevator1.active = false;
	elevator1.travel_up = elevator1.origin; // DCS 082210: hard coding the positions
	elevator1.travel_down = elevator1.origin - (0, 0, 201);

	elevator2.cost = 250;	// rsh071510 - can have independent cost
	elevator2.station = "elevator2_up";
	elevator2.called = false;
	elevator2.active = false;
	elevator2.travel_up = elevator2.origin; // DCS 082210: hard coding the positions
	elevator2.travel_down = elevator2.origin - (0, 0, 320);

	elevator1 link_pieces();
	elevator1 init_elevator1_doors();
	elevator1 init_buy();
	elevator1 init_call_boxes();

	elevator2 link_pieces();
	elevator2 init_elevator2_doors();
	elevator2 init_buy();
	elevator2 init_call_boxes();

	wait_network_frame();
	elevator1 enable_callboxes();
	elevator1 block_elev_doors( false );
	elevator1 open_elev_doors();

	elevator2 enable_callboxes();
	elevator2 block_elev_doors( false );
	elevator2 open_elev_doors();

	//Playing Muzak in the elevator at all times
	elevator2 PlayLoopSound( "mus_elevator_muzak" );
	elevator1 thread elevator1_3d_audio();
	elevator2 thread elevator2_3d_audio();
}


//---------------------------------------------------------------------------
// attach all the elevator pieces, this includes spots for the players
//---------------------------------------------------------------------------
link_pieces()
{
	pieces = GetEntArray( self.target, "targetname" );

	for ( i = 0; i < pieces.size; i++ )
	{
		if(IsDefined(pieces[i].classname) && pieces[i].classname == "trigger_use" || pieces[i].classname == "trigger_multiple")
		{
			pieces[i] EnableLinkTo();
		}
		pieces[i] LinkTo( self );
	}
}

//---------------------------------------------------------------------------
// sets up the areas where an elevator can be called for pick up
//---------------------------------------------------------------------------
init_call_boxes()
{
	trigger = GetEntArray( self.targetname + "_call_box", "targetname" );

	for ( i = 0; i < trigger.size; i++ )
	{
		trigger[i] thread call_box_think(self);
	}
}

//---------------------------------------------------------------------------
// handles bringing the zipline back to the call box if it's not there
//---------------------------------------------------------------------------
call_box_think(elevator)
{
	self setcursorhint( "HINT_NOICON" );
	self SetHintString( &"ZOMBIE_PENTAGON_CALL_ELEVATOR" );
	PreCacheString(&"ZOMBIE_PENTAGON_ELEV_BLOCKED");

	while ( 1 )
	{
		who = undefined;
		self waittill( "trigger", who );

		CleanupSpawnedDynEnts();

		elev_clear = is_elevator_clear(elevator);

		if(!elev_clear)
		{
			play_sound_at_pos( "no_purchase", self.origin );
			self SetHintString( &"ZOMBIE_PENTAGON_ELEV_BLOCKED" );
			wait(1.0);
			self SetHintString( &"ZOMBIE_PENTAGON_CALL_ELEVATOR" );

			//who thread elevator_hint_text(&"ZOMBIE_PENTAGON_ELEV_BLOCKED");
		}
		else if(flag("thief_round") || flag("pig_killed_round"))
		{
			play_sound_at_pos( "no_purchase", self.origin );
			self SetHintString( &"ZOMBIE_PENTAGON_PACK_ROOM_DOOR" );
			wait(1.0);
			self SetHintString( &"ZOMBIE_PENTAGON_CALL_ELEVATOR" );
		}
		else if(elevator.active == true || !who can_buy_elevator())
		{
			//Don't allow call while elevator is active.
			play_sound_at_pos( "no_purchase", self.origin );
		}
		else
		{
			//if elevator not at this floor, calls elevator to this floor.
			if(	elevator.station != self.script_noteworthy)
			{
				call_destination = self.script_noteworthy;
				elevator.called = true;
				elevator.active = true;

				elevator disable_callboxes();
				elevator disable_elevator_buys();
				self thread elevator_move_to(elevator);
			}
		}
		wait( .05 );
	}

}
is_elevator_clear(elevator)
{
	elevator_door_safety = GetEntArray(elevator.targetname + "_safety","script_noteworthy");
	players = get_players();

	if(IsDefined(elevator_door_safety))
	{
		for ( i = 0; i < elevator_door_safety.size; i++ )
		{
			for ( j = 0; j < players.size; j++ )
			{
				if(players[j] IsTouching(elevator_door_safety[i]))
				return false;
			}
		}
	}
	return true;
}
block_elev_doors_internal( block, suffix )
{
	elevator_door_safety_clip = GetEntArray( self.targetname + suffix, "script_noteworthy" );

	if ( IsDefined( elevator_door_safety_clip ) )
	{
		for ( i = 0; i < elevator_door_safety_clip.size; i++ )
		{
			if ( block )
			{
				elevator_door_safety_clip[i] Solid();
			}
			else
			{
				elevator_door_safety_clip[i] NotSolid();
			}
		}
	}
}
block_elev_doors( block )
{
	block_elev_doors_internal( block, "_safety_top" );
	block_elev_doors_internal( block, "_safety_bottom" );
}
elevator_hint_text(msg)
{
	self endon( "death" );
	self endon( "disconnect" );

	text = NewClientHudElem( self );
	text.alignX = "center";
	text.alignY = "middle";
	text.horzAlign = "user_center";
	text.vertAlign = "user_bottom";
	text.foreground = true;
	text.font = "default";
	text.fontScale = 1.8;
	text.alpha = 0;
	text.color = ( 1.0, 1.0, 1.0 );
	text SetText( msg );

	text.y = -113;
	if( IsSplitScreen() )
	{
		text.y = -137;
	}

	text FadeOverTime( 0.1 );
	text.alpha = 1;

	wait(2.0);

	text FadeOverTime( 0.1 );
	text.alpha = 0;
}
//---------------------------------------------------------------------------
// setup buy thinks
//---------------------------------------------------------------------------
init_buy()
{
	trigger = GetEnt( self.targetname + "_buy", "script_noteworthy" );
	trigger thread elevator_buy_think(self);
}
//---------------------------------------------------------------------------
// handles player purchasing and using the elevator
//---------------------------------------------------------------------------
elevator_buy_think(elevator)
{
	self setcursorhint( "HINT_NOICON" );
	self UseTriggerRequireLookAt();
	self SetHintString( &"ZOMBIE_PENTAGON_USE_ELEVATOR", elevator.cost );

	while ( 1 )
	{
		who = undefined;
		self waittill( "trigger", who );

		CleanupSpawnedDynEnts();

		elev_clear = is_elevator_clear(elevator);

		if(!elev_clear)
		{
			play_sound_at_pos( "no_purchase", self.origin );
			self SetHintString( &"ZOMBIE_PENTAGON_ELEV_BLOCKED" );
			wait(1.0);
			self SetHintString( &"ZOMBIE_PENTAGON_USE_ELEVATOR", elevator.cost );

			//who thread elevator_hint_text(&"ZOMBIE_PENTAGON_ELEV_BLOCKED");
		}
		else if(flag("thief_round") || flag("pig_killed_round"))
		{
			play_sound_at_pos( "no_purchase", self.origin );
			self SetHintString( &"ZOMBIE_PENTAGON_PACK_ROOM_DOOR" );
			wait(1.0);
			self SetHintString( &"ZOMBIE_PENTAGON_USE_ELEVATOR", elevator.cost );
		}
		else if ( is_player_valid( who ) && who.score >= elevator.cost && who can_buy_elevator())
		{
			elevator.active = true;
			who maps\_zombiemode_score::minus_to_player_score( elevator.cost );
			play_sound_at_pos( "purchase", self.origin );

			elevator disable_callboxes();
			elevator disable_elevator_buys();

			// DCS 082010: Now call doors on both sides of elevator 1.
			call_box_array = GetEntArray( elevator.station, "script_noteworthy" );
			call_box = call_box_array[0];
			if(call_box.script_noteworthy == elevator.targetname + "_up")
			{
				call_box.destination = elevator.targetname + "_down";
			}
			else
			{
				call_box.destination = elevator.targetname + "_up";
			}

			//elevator thread redirect_zombies(call_box.destination);
			self elevator_move_to(elevator);
		}
		else // Not enough money
		{
			play_sound_at_pos( "no_purchase", self.origin );
			who maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 1 );
		}
		wait( .05 );
	}
}
//---------------------------------------------------------------------------
// DCS: version of maps\_zombiemode_weapons::can_buy_weapon()
//			that allows player to activate with claymores out.
//---------------------------------------------------------------------------
can_buy_elevator()
{
	if( self in_revive_trigger() )
	{
		return false;
	}

	return true;
}
//---------------------------------------------------------------------------
// disables the zip buy triggers until the cooldown period is over
// the callbox at the current station will also stay hidden after cooldown
//---------------------------------------------------------------------------
disable_callboxes()
{
	call_boxes = GetEntArray( self.targetname + "_call_box", "targetname" );
	for ( j = 0; j < call_boxes.size; j++ )
	{
		call_boxes[j] trigger_off();

		players = get_players();
		for ( i = 0; i < players.size; i++ )
		{
			call_boxes[j] SetInvisibleToPlayer(players[i]);
		}
	}
}
disable_elevator_buys()
{
	elevator_buy = GetEnt( self.targetname + "_buy", "script_noteworthy" );

	elevator_buy setcursorhint( "HINT_NOICON" );
	elevator_buy SetHintString( "" );
	elevator_buy trigger_off();

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		elevator_buy SetInvisibleToPlayer(players[i]);
	}
}
//---------------------------------------------------------------------------
// enables the zip buys except the call box at the current station
//---------------------------------------------------------------------------
enable_elevator_buys()
{
	elevator_buy = GetEnt( self.targetname + "_buy", "script_noteworthy" );

	elevator_buy setcursorhint( "HINT_NOICON" );
	elevator_buy SetHintString( &"ZOMBIE_PENTAGON_USE_ELEVATOR", self.cost );
	elevator_buy trigger_on();

	elevator_buy SetVisibleToAll();
}

enable_callboxes()
{
	call_boxes = getentarray( self.targetname + "_call_box", "targetname" );

	for ( j = 0; j < call_boxes.size; j++ )
	{
		if ( call_boxes[j].script_noteworthy != self.station )
		{
			call_boxes[j] trigger_on();
			call_boxes[j] sethintstring( &"ZOMBIE_PENTAGON_CALL_ELEVATOR" );

			call_boxes[j] SetVisibleToAll();
		}
		else
		{
			//call_boxes[j] trigger_on();
			call_boxes[j] sethintstring( "" );
		}
	}
}
//---------------------------------------------------------------------------
// Actual elevator movement, doors opening, etc.
//---------------------------------------------------------------------------
elevator_move_to(elevator)
{
	level thread check_for_round_restart();

	players = getplayers();
	elevator close_elev_doors();

	flag_clear("spawn_zombies");

	level waittill("doors_finished_moving");

	elevator block_elev_doors( false );

    elevator notify( "start_3d_audio" );

	elevator thread elev_clean_up_corpses();

	if(elevator.station == elevator.targetname + "_up")
	{
		elevator thread move_zombies_elevator(false);
		if(elevator.targetname == "elevator1")
		{
			elevator thread zombie_elevator_closets(false);
		}

		elevator MoveTo( elevator.travel_down, 5.0);
		elevator waittill( "movedone" );
		elevator.station = elevator.targetname + "_down";

		level thread maps\zombie_pentagon::change_pentagon_vision();

		if(elevator.targetname == "elevator1" && !flag("labs_enabled"))
		{
			flag_set( "labs_enabled" );
		}
		else if( elevator.targetname == "elevator2" && !flag( "war_room_start" ) )
		{
			flag_set( "war_room_start" );
		}
	}
	else
	{
		elevator thread move_zombies_elevator(true);
		if(elevator.targetname == "elevator1")
		{
			elevator thread zombie_elevator_closets(true);
		}

		elevator MoveTo( elevator.travel_up, 5.0);
		elevator waittill( "movedone" );
		elevator.station = elevator.targetname + "_up";

		level thread maps\zombie_pentagon::change_pentagon_vision();
	}

	if( elevator.targetname == "elevator2" )
    {
		clientnotify( "ele1e" );
		if(elevator.station == elevator.targetname + "_up")
		{
		    elevator PlaySound( "zmb_vox_pentann_level_1" );
		}
		else if(elevator.station == elevator.targetname + "_down")
		{
		    elevator PlaySound( "zmb_vox_pentann_level_2" );
		}
	}
	else if( elevator.targetname == "elevator1" )
	{
		clientnotify( "ele2e" );
		if(elevator.station == elevator.targetname + "_up")
		{
		    elevator PlaySound( "zmb_vox_pentann_level_2" );
		}
		else if(elevator.station == elevator.targetname + "_down")
		{
		    elevator PlaySound( "zmb_vox_pentann_level_3" );
		}
	}

	flag_set("elevator_grounded");
	flag_set("spawn_zombies");

	elevator open_elev_doors();

	//unlock_players();

	wait(1.25);
	//DCS 091610: Clean up any zombies that spawned while elevator moved.
	elevator.called = false;
	elevator.active = false;
	elevator enable_elevator_buys();
	elevator enable_callboxes();
	level thread check_if_empty_floors();
}

check_for_round_restart()
{
	level endon("open_elev_doors");

	level.round_restart_happened = false;

	level waittill("round_restarted");

	level.round_restart_happened = true;
}

//---------------------------------------------------------------------------
// DCS 082710:	check for zombies within special closets.
//							kill them and readd to spawn array
//							only needed for elevator 1.
//---------------------------------------------------------------------------
zombie_elevator_closets(going_up)
{
	if(!IsDefined(going_up))
	{
		return;
	}

	if(going_up == true)
	{
		special_spawn = GetEntArray("elevator1_down_spawncloset", "targetname");

		flag_set("no_labs_elevator_spawning");
		flag_clear("no_warroom_elevator_spawning");
		maps\_zombiemode_zone_manager::reinit_zone_spawners();
	}
	else
	{
		special_spawn = GetEntArray("elevator1_up_spawncloset", "targetname");

		flag_set("no_warroom_elevator_spawning");
		flag_clear("no_labs_elevator_spawning");
		maps\_zombiemode_zone_manager::reinit_zone_spawners();
	}

	if(IsDefined(special_spawn))
	{
		for (i = 0; i < special_spawn.size; i++)
		{
			special_spawn[i] thread elevator_closet_cleanup();
		}
	}
}
elevator_closet_cleanup()
{
	zombies = GetAIArray("axis");
	if(!IsDefined(zombies))
	{
		return;
	}
	for (i = 0; i < zombies.size; i++)
	{
		if(zombies[i] IsTouching(self))
		{
			level.zombie_total++;
			zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
		}
	}
}
//---------------------------------------------------------------------------
// DCS 082610:	teleport some zombies to be waiting at next floor.
//							if all players in elevator.
//---------------------------------------------------------------------------
move_zombies_elevator(going_up)
{
	if(!IsDefined(going_up))
	{
		return;
	}
	check_trig = undefined;
	downed_player = undefined;
	current_floor = 1;
	next_floor = 2;
	num_in_elev = 0;
	num_current_floor = 0;
	num_next_floor = 0;
	num_floor_laststand = 0;
	pos_num = 0;
	pos_num_hidden = 0;
	floor_height = 0;
	self.elevator_players = [];

	players = getplayers();
	in_elevator = GetEnt(self.targetname + "_zombie_cleanup", "targetname");

	if(going_up == true)
	{
		check_trig = GetEnt(self.targetname + "_down_riders", "targetname");
	}
	else
	{
		check_trig = GetEnt(self.targetname + "_up_riders", "targetname");
	}

	// check number of players in elevator and current floor
	for ( i = 0; i < players.size; i++ )
	{
		players[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( players[i] );
		if(players[i] IsTouching(check_trig))
		{
			current_floor = players[i].floor;
			num_in_elev++;
			players[i].end_portal = undefined;

			// DCS 111610: create array to track player in elevator.
			self.elevator_players = array_add(self.elevator_players, players[i]);

			if( self.targetname == "elevator2" )
			{
			    setClientSysState( "levelNotify", "ele1", players[i] );
			}
			else if ( self.targetname == "elevator1" )
			{
			    setClientSysState( "levelNotify", "ele2", players[i] );
			}
		}
	}

	// Check next floor.
	if(IsDefined(current_floor) && going_up == false)
	{
		next_floor = current_floor + 1;
	}
	else if(IsDefined(current_floor) && going_up == true)
	{
		next_floor = current_floor - 1;
	}

	// now check current floor number after all checked in elevator and current floor established.
	// also check next floor for players.
	for ( i = 0; i < players.size; i++ )
	{
		if(IsDefined(current_floor) && players[i].floor == current_floor)
		{
			num_current_floor++;
		}
		if(IsDefined(next_floor) && players[i].floor == next_floor)
		{
			num_next_floor++;
		}
		if(IsDefined(current_floor) && players[i].floor == current_floor && (players[i] maps\_laststand::player_is_in_laststand()
		|| players[i].sessionstate == "spectator") && !players[i] IsTouching(check_trig))
		{
			if(!IsDefined(downed_player))
			{
				downed_player = players[i];
			}
			num_floor_laststand++;
		}

	}

	wait_network_frame();
	// DCS 092110: everyone left on floor in last stand.
	if(players.size > 1 && num_floor_laststand > 0
	&& num_in_elev == (num_current_floor - num_floor_laststand))
	{
		downed_player thread laststand_elev_zombies_away(current_floor, next_floor);
		return;
	}

	if(num_in_elev != num_current_floor)
	{
		return;
	}

	if(num_next_floor > 0 )
	{
		// will force them not to teleport into playable area.
		pos_num = 6;
	}

	// special case for single players.
	if(players.size == 1)
	{
		// fill position number, no zombies in play area ahead.
		if(level.round_number <= 5)
		{
			pos_num = 6;
		}
		else if(level.round_number > 5 && level.round_number < 10)
		{
			pos_num = 5;
		}
		else if(level.round_number >= 10)
		{
			pos_num = 3;
		}
	}

	zombies = GetAIArray("axis");
	if(!IsDefined(zombies))
	{
		return;
	}
	for (i = 0; i < zombies.size; i++)
	{
		zombies[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( zombies[i] );

		// leave alone if not on same floor
		if(IsDefined(current_floor) && zombies[i].floor != current_floor)
		{
			continue;
		}
		// ignore if technician
		else if(IsDefined(zombies[i].animname) && zombies[i].animname == "thief_zombie")
		{
			continue;
		}
		// or in elevator.
		else if(zombies[i] IsTouching(in_elevator))
		{
			continue;
		}
		else if(IsDefined(zombies[i].teleporting) && zombies[i].teleporting == true)
		{
			continue;
		}
		else
		{
			if(IsDefined(current_floor) && is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
			{
				if(current_floor == 1)
				{
					zombies[i] thread send_zombies_out(level.portal_top);
				}
				else if(current_floor == 2)
				{
					zombies[i] thread send_zombies_out(level.portal_mid);
				}
				else if(current_floor == 3)
				{
					zombies[i] thread send_zombies_out(level.portal_power);
				}
			}
			else
			{
				level.zombie_total++;
				zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
			}
		}
		//or go ahead and delete if still behind tear.
		/*else if(zombies[i].ignoreall == true)
		{
			if(zombies[i].health == level.zombie_health || zombies[i].animname == "quad_zombie")
			{
				level.zombie_total++;
				if(IsDefined(zombies[i].fx_quad_trail))
				{
					zombies[i].fx_quad_trail Delete();
				}
				zombies[i] maps\_zombiemode_spawner::reset_attack_spot();

				zombies[i] notify("zombie_delete");
				zombies[i] Delete();
			}
			else
			{
				zombies[i] thread zombies_elev_teleport_hidden(self, RandomIntRange(0,6), going_up);
			}
		}
		else
		{
			//Teleport first 6 to next floor into playable area...
			if(pos_num <= 5 )
			{

				zombies[i] thread zombies_elev_teleport(self, pos_num, going_up);
				pos_num++;
			}
			// teleport 6 into next floor spawn closets (excluding quads).
			else if(pos_num_hidden <=5 && zombies[i].animname != "quad_zombie")
			{
				if(zombies[i].health == level.zombie_health)
				{
					level.zombie_total++;
					zombies[i] maps\_zombiemode_spawner::reset_attack_spot();

					zombies[i] notify("zombie_delete");
					zombies[i] Delete();
				}
				else
				{
					zombies[i] thread zombies_elev_teleport_hidden(self, pos_num_hidden, going_up);
					pos_num_hidden++;
				}
			}
			//then send them through portal if power on.
			else
			{
				if(IsDefined(current_floor) && current_floor == 1 && flag("power_on"))
				{
					zombies[i] thread send_zombies_out(level.portal_top);
				}
				else if(IsDefined(current_floor) && current_floor == 2 && flag("power_on"))
				{
					zombies[i] thread send_zombies_out(level.portal_mid);
				}
				else if(IsDefined(current_floor) && current_floor == 3 && flag("power_on"))
				{
					zombies[i] thread send_zombies_out(level.portal_power);
				}
				else
				{
					move_speed = undefined;
					if(IsDefined(self.zombie_move_speed))
					{
						move_speed = self.zombie_move_speed;
					}

					PlayFX(level._effect["transporter_start"], zombies[i].origin);
					if(zombies[i].health == level.zombie_health)
					{
						level.zombie_total++;
						if(IsDefined(zombies[i].fx_quad_trail))
						{
							zombies[i].fx_quad_trail Delete();
						}
						zombies[i] maps\_zombiemode_spawner::reset_attack_spot();

						zombies[i] notify("zombie_delete");
						zombies[i] Delete();
					}
					else
					{
						zombies[i] thread cleanup_unoccupied_floor(move_speed,current_floor,next_floor);
					}
				}
			}
		}*/
	}
}
//---------------------------------------------------------------------------
laststand_elev_zombies_away(current_floor,next_floor)
{
	// now see if need to delete zombies.
	zombies = GetAIArray("axis");
	if(!IsDefined(zombies))
	{
		return;
	}

	for (i = 0; i < zombies.size; i++)
	{
		// leave thief zombie alone.
		if(IsDefined(zombies[i].animname) && zombies[i].animname == "thief_zombie")
		{
			continue;
		}

		move_speed = undefined;
		if(IsDefined(zombies[i].zombie_move_speed))
		{
			move_speed = zombies[i].zombie_move_speed;
		}

		zombies[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( zombies[i] );

		if(IsDefined(zombies[i].floor) && zombies[i].floor == self.floor)
		{
			if(is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
			{
				if(zombies[i].floor == 1)
				{
					zombies[i] thread send_zombies_out(level.portal_top);
				}
				else if(zombies[i].floor == 2)
				{
					zombies[i] thread send_zombies_out(level.portal_mid);
				}
				else if(zombies[i].floor == 3)
				{
					zombies[i] thread send_zombies_out(level.portal_power);
				}
			}
			else
			{
				level.zombie_total++;
				zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
			}
		}
	}
}
//---------------------------------------------------------------------------
// DCS: 	teleport zombies into playable area when using elevator
//				if next floor is clear of players.
//---------------------------------------------------------------------------
zombies_elev_teleport(elevator, pos_num, going_up)
{
	self endon( "death" );

	teleport_pos = [];

	if(going_up == true)
	{
		teleport_pos = getstructarray(elevator.targetname + "_up_zombie", "targetname");
	}
	else
	{
		teleport_pos = getstructarray(elevator.targetname + "_down_zombie", "targetname");
	}

	if(IsDefined(teleport_pos[pos_num]))
	{
		//IPrintLnBold("moving zombie to position ", pos_num);
		self forceteleport(teleport_pos[pos_num].origin,teleport_pos[pos_num].angles);
	}
}
//---------------------------------------------------------------------------
// DCS 091010:	teleport zombies into available spawn closets
//							on next floor when using elevators. Only called
//							if floor is occuppied already and/or power is off.
//---------------------------------------------------------------------------
zombies_elev_teleport_hidden(elevator, pos_num, going_up)
{
	self endon( "death" );

	teleport_pos = [];

	if(going_up == true)
	{
		teleport_pos = getstructarray(elevator.targetname + "_up_hidden", "targetname");
	}
	else
	{
		teleport_pos = getstructarray(elevator.targetname + "_down_hidden", "targetname");
	}

	if(IsDefined(teleport_pos[pos_num]))
	{
		self forceteleport(teleport_pos[pos_num].origin + (RandomFloatRange(0,22), RandomFloatRange(0,22), 0),teleport_pos[pos_num].angles);

		// now reset zombie to tear through barricade.
		wait(1);
		if(IsDefined(self))
		{
			self.ignoreall = true;
			self notify( "stop_find_flesh" );
			self notify( "zombie_acquire_enemy" );

			if(IsDefined(self.target))
			{
				self.target = undefined;
			}
			wait_network_frame();
			self thread maps\_zombiemode_spawner::zombie_think();
		}
	}
}
//---------------------------------------------------------------------------
// clean up dead zombie corpses
//---------------------------------------------------------------------------
elev_clean_up_corpses()
{
	corpse_trig = GetEnt(self.targetname + "_zombie_cleanup", "targetname");

	corpses = GetCorpseArray();
	if(IsDefined(corpses))
	{
		for ( i = 0; i < corpses.size; i++ )
		{
			if(corpses[i] istouching(corpse_trig))
			{
				corpses[i] thread elev_remove_corpses();

			}
		}
	}
}
elev_remove_corpses()
{
	PlayFX(level._effect["dog_gib"], self.origin);
	self Delete();
}

//---------------------------------------------------------------------------
// int_doors()
//---------------------------------------------------------------------------
init_elevator1_doors()
{
	self.doors_up = GetEntArray("elevator1_doors_up", "script_noteworthy" );
	for ( i = 0; i < self.doors_up.size; i++ )
	{
		self.doors_up[i].startpos = self.doors_up[i].origin;
	}
	self.doors_down = GetEntArray( "elevator1_doors_down", "script_noteworthy" );
	for ( j = 0; j < self.doors_down.size; j++ )
	{
		self.doors_down[j].startpos = self.doors_down[j].origin;
	}
	self.doors_outer_down = GetEntArray("elevator1_outerdoors_down", "script_noteworthy");
	for ( k = 0; k < self.doors_outer_down.size; k++ )
	{
		self.doors_outer_down[k].startpos = self.doors_outer_down[k].origin;
	}
	self.doors_outer_up = GetEntArray("elevator1_outerdoors_up", "script_noteworthy");
	for ( l = 0; l < self.doors_outer_up.size; l++ )
	{
		self.doors_outer_up[l].startpos = self.doors_outer_up[l].origin;
	}
}
init_elevator2_doors()
{
	self.doors = GetEntArray("elevator2_doors", "script_noteworthy" );
	for ( i = 0; i < self.doors.size; i++ )
	{
		self.doors[i].startpos = self.doors[i].origin;
	}
	self.doors_outer_down = GetEntArray("elevator2_outerdoors_down", "script_noteworthy");
	for ( k = 0; k < self.doors_outer_down.size; k++ )
	{
		self.doors_outer_down[k].startpos = self.doors_outer_down[k].origin;
	}
	self.doors_outer_up = GetEntArray("elevator2_outerdoors_up", "script_noteworthy");
	for ( l = 0; l < self.doors_outer_up.size; l++ )
	{
		self.doors_outer_up[l].startpos = self.doors_outer_up[l].origin;
	}
}
//---------------------------------------------------------------------------
// closes all elevator doors
//---------------------------------------------------------------------------
close_elev_doors()
{
	self block_elev_doors( true );

	for(i = 0; i < self.doors_outer_down.size; i++)
	{
		self.doors_outer_down[i] thread relink_elev_doors(self.doors_outer_down[i].startpos, self, false);
	}
	for(j = 0; j < self.doors_outer_up.size; j++)
	{
		self.doors_outer_up[j] thread relink_elev_doors(self.doors_outer_up[j].startpos, self, false);
	}
	if(IsDefined(self.doors_down)) // only elevator 1 (exit opposite sides up or down)
	{
		for ( k = 0; k < self.doors_down.size; k++ )
		{
			newpos3 = (self.doors_down[k].startpos[0], self.doors_down[k].startpos[1], self.doors_down[k].origin[2]);
			self.doors_down[k]	thread relink_elev_doors(newpos3, self, true);
			playsoundatposition( "evt_elevator_freight_door_close", newpos3 );
		}
	}
	if(IsDefined(self.doors_up)) // only elevator 1 (exit opposite sides up or down)
	{
		for ( l = 0; l < self.doors_up.size; l++ )
		{
			newpos4 = (self.doors_up[l].startpos[0], self.doors_up[l].startpos[1], self.doors_up[l].origin[2]);
			self.doors_up[l]	thread relink_elev_doors(newpos4, self, true);
			playsoundatposition( "evt_elevator_freight_door_close", newpos4 );
		}
	}
	//added for elevator 2.
	if(IsDefined(self.doors)) // only elevator 2 (single set of elevator doors.)
	{
		for ( m = 0; m < self.doors.size; m++ )
		{
			if(self.station == self.targetname + "_up")
			{
				newpos5 = (self.doors[m].startpos);
			}
			else
			{
				newpos5 = (self.doors[m].startpos[0], self.doors[m].startpos[1], self.doors[m].origin[2]);
			}
			self.doors[m]	thread relink_elev_doors(newpos5, self, true);
			playsoundatposition( "evt_elevator_office_door_close", newpos5 );
		}
	}

	if(self.station == self.targetname + "_up")
	{
		check_trig = GetEnt(self.targetname + "_up_riders", "targetname");
	}
	else
	{
		check_trig = GetEnt(self.targetname + "_down_riders", "targetname");
	}

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		if(players[i] IsTouching(check_trig))
		{
			players[i].in_elevator = true;
		}
	}
}
//---------------------------------------------------------------------------
// Open doors on floor elevator is at.
//---------------------------------------------------------------------------
open_elev_doors()
{
	//DCS 111610: checking array of players that started in elevator to make sure they are still there.
	// self is the elevator.
	if(IsDefined(self.elevator_players))
	{
		check_trig = undefined;
		if(self.station == self.targetname + "_down")
		{
			check_trig = GetEnt(self.targetname + "_down_riders", "targetname");
		}
		else
		{
			check_trig = GetEnt(self.targetname + "_up_riders", "targetname");
		}

		for ( i = 0; i < self.elevator_players.size; i++ )
		{
			if(!level.round_restart_happened && !self.elevator_players[i] IsTouching(check_trig))
			{
				self.elevator_players[i] SetOrigin( self.origin + (RandomFloatRange(-32,32), RandomFloatRange(-32,32), 10 ));
				self.elevator_players[i] playsound( "zmb_laugh_child" );
			}

			self.elevator_players[i].in_elevator = false;

			self.elevator_players = array_remove(self.elevator_players, self.elevator_players[i]);
		}
	}


	if(self.station == self.targetname + "_down")
	{
		for(j = 0; j < self.doors_outer_down.size; j++)
		{
			newpos1 = self.doors_outer_down[j].startpos + self.doors_outer_down[j].script_vector;
			self.doors_outer_down[j] thread relink_elev_doors(newpos1, self, false);
		}
		if(IsDefined(self.doors_up)) // rsh071510 - when down, both sides of elevator 1 need to open for spawning
		{
			for ( i = 0; i < self.doors_up.size; i++ )
			{
				pos2 = self.doors_up[i].startpos + self.doors_up[i].script_vector;
				newpos2 = (pos2[0], pos2[1], self.doors_up[i].origin[2]);
				self.doors_up[i]	thread relink_elev_doors(newpos2, self, true);
				playsoundatposition( "evt_elevator_freight_door_open", newpos2 );
			}
		}
		if(IsDefined(self.doors_down)) // elevator 1
		{
			for ( i = 0; i < self.doors_down.size; i++ )
			{
				pos1 = self.doors_down[i].startpos + self.doors_down[i].script_vector;
				newpos = (pos1[0], pos1[1], self.doors_down[i].origin[2]);
				self.doors_down[i]	thread relink_elev_doors(newpos, self, true);
				playsoundatposition( "evt_elevator_freight_door_open", newpos );
			}
		}
		//added for elevator 2.
		if(IsDefined(self.doors)) // only elevator 2 (single set of elevator doors.)
		{
			for ( m = 0; m < self.doors.size; m++ )
			{
				pos2 = self.doors[m].startpos + self.doors[m].script_vector;

				if(self.station == self.targetname + "_up")
				{
					newpos2 = (pos2[0], pos2[1], self.doors[m].startpos[2]);
				}
				else
				{
					newpos2 = (pos2[0], pos2[1], self.doors[m].origin[2]);
				}
				self.doors[m]	thread relink_elev_doors(newpos2, self, true);
				playsoundatposition( "evt_elevator_office_door_open_1", newpos2 );
			}
		}
	}
	else
	{
		for(j = 0; j < self.doors_outer_up.size; j++)
		{
			newpos1 = self.doors_outer_up[j].startpos + self.doors_outer_up[j].script_vector;
			self.doors_outer_up[j] thread relink_elev_doors(newpos1, self, false);
		}
		if(IsDefined(self.doors_up)) //elevator 1
		{
			for ( i = 0; i < self.doors_up.size; i++ )
			{
				pos2 = self.doors_up[i].startpos + self.doors_up[i].script_vector;
				newpos2 = (pos2[0], pos2[1], self.doors_up[i].origin[2]);
				self.doors_up[i]	thread relink_elev_doors(newpos2, self, true);
				playsoundatposition( "evt_elevator_freight_door_open", newpos2 );
			}
		}
		if(IsDefined(self.doors_down)) //DCS 082010: new spawn closet at war room level.
		{
			for ( k = 0; k < self.doors_down.size; k++ )
			{
				pos4 = self.doors_down[k].startpos + self.doors_down[k].script_vector;
				newpos4 = (pos4[0], pos4[1], self.doors_down[k].origin[2]);
				self.doors_down[k]	thread relink_elev_doors(newpos4, self, true);
				playsoundatposition( "evt_elevator_freight_door_open", newpos4 );
			}
		}
		//added for elevator 2.
		if(IsDefined(self.doors)) // only elevator 2 (single set of elevator doors.)
		{
			for ( m = 0; m < self.doors.size; m++ )
			{
				pos3 = self.doors[m].startpos + self.doors[m].script_vector;
				newpos3 = (pos3[0], pos3[1], self.doors[m].origin[2]);
				self.doors[m]	thread relink_elev_doors(newpos3, self, true);
				playsoundatposition( "evt_elevator_office_door_open_1", newpos3 );
			}
		}
	}

	level notify("open_elev_doors");
}

relink_elev_doors(pos, elev, linked)
{
	self Unlink();
	self moveto(pos, 1.0);

	self waittill("movedone");
	if(linked)
	{
		self LinkTo(elev);
	}

	level notify("doors_finished_moving");
	// startpos is closed for all doors, disconnect paths.
	if(self.classname == "script_model")
	{
		return;
	}
	if(self.origin[0] == self.startpos[0])
	{
		self DisconnectPaths();
	}
	else
	{
		self ConnectPaths();
	}

}
//---------------------------------------------------------------------------
//	Make the zombies head to the elevator destination
//---------------------------------------------------------------------------
redirect_zombies( destination )
{

	// If not all players on elevator leave zombies alone.
	players = get_players();
	num_players = 0;
	for ( i = 0; i < players.size; i++ )
	{
		if(players[i] IsTouching(self))
		num_players++;
	}
	if(!num_players == players.size)
	{
		return;
	}

	wait( 2.0 );
	location = GetNode( destination, "targetname" );
	if ( IsDefined( location ) )
	{
		poi = Spawn( "script_origin", location.origin );
		poi create_zombie_point_of_interest( undefined, 25, 0, true );
		flag_wait("elevator_grounded");

		poi deactivate_zombie_point_of_interest();
		poi delete();
	}
}

//---------------------------------------------------------------------------
// unlinks players from the spots
//---------------------------------------------------------------------------
unlock_players()
{
	players = getplayers();

	for ( i = 0; i < players.size; i++ )
	{
		players[i] unlink();
		players[i] allowcrouch( true );
		players[i] allowprone( true );
		players[i] disableinvulnerability();

/#
		//Make sure cheat is still working
		if ( GetDvarInt( #"zombie_cheat" ) >= 1 && GetDvarInt( #"zombie_cheat" ) <= 3 )
		{
			players[i] EnableInvulnerability();
		}
#/

		players[i] thread maps\_zombiemode::store_crumb( players[i].origin );
	}
}

elevator1_3d_audio()
{
    while(1)
    {
        self waittill( "start_3d_audio" );
        ent = Spawn( "script_origin", self.origin + (0,0,30) );
        ent LinkTo( self );
        ent PlayLoopSound( "evt_elevator_freight_run_3d" );
        self waittill( "movedone" );
        ent Delete();
    }
}

elevator2_3d_audio()
{
    while(1)
    {
        self waittill( "start_3d_audio" );
        ent = Spawn( "script_origin", self.origin + (0,0,30) );
        ent LinkTo( self );
        ent PlayLoopSound( "evt_elevator_office_run_3d" );
        self waittill( "movedone" );
        ent Delete();
    }
}
