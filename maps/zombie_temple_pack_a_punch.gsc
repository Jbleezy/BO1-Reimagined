#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_utility_raven;
#include maps\zombie_temple;
#include maps\zombie_temple_elevators;




//-------------------------------------------------------
// name: 	init_pack_a_punch_round
// self: 	level
// return:	nothing
// desc:	initializes the pack-a-punch round
//-------------------------------------------------------
init_pack_a_punch()
{
	flag_init( "pap_round" );
	flag_init( "pap_active" );
	flag_init( "pap_open" );
	flag_init("pap_enabled");

	level.pack_a_punch_round_time = 30;
	level.pack_a_punch_stone_timer = GetEntArray ("pack_a_punch_timer", "targetname");
	level.pack_a_punch_stone_timer_dist = 176;

	registerClientSys( "pap_indicator_spinners" );

	level.pap_active_time = 60.0;
	/#
	if ( GetDvarInt("zombie_debug_temple_pap") )
	{
		level.pap_active_time = 20.0;
	}
    #/

	_setup_pap_blocker();
	_setup_pap_timer();
	_setup_pap_path();
	_setup_pap_fx();
}

///////////////////////////////////////////////////////////////////////////////////////

_setup_pap_blocker()
{
	//level thread _setup_pressure_plate_bodies();
	level thread _setup_simultaneous_pap_triggers();

	// move the stairs down so they can't initially be seen
	level.pap_stairs = [];
	for(i=0;i<4;i++)
	{
		stair = GetEnt("pap_stairs" + (i+1), "targetname");

		if(!isdefined(stair.script_vector))
		{
			stair.script_vector = (0,0,72);
		}

		stair.moveTime = 3;
		stair.moveDist = stair.script_vector;
		if ( i == 3 )
		{
			//bottom stair starts down
			stair.down_origin = stair.origin;
			stair.up_origin = stair.down_origin + stair.moveDist;
		}
		else
		{
			stair.up_origin = stair.origin;
			stair.down_origin = stair.up_origin - stair.moveDist;
			stair.origin = stair.down_origin;
		}
		stair.state = "down";
		level.pap_stairs[i] = stair;
	}

	level.pap_stairs_clip = GetEnt("pap_stairs_clip", "targetname");
	if ( IsDefined(level.pap_stairs_clip) )
	{
		level.pap_stairs_clip.zMove = 72;
		//starts down now
		//level.pap_stairs_clip.origin -= (0,0,level.pap_stairs_clip.zMove);
	}

	level.pap_playerclip = GetEntArray("pap_playerclip", "targetname");
	for ( i = 0; i < level.pap_playerclip.size; i++ )
	{
		level.pap_playerclip[i].saved_origin = level.pap_playerclip[i].origin;
	}

	level.pap_ramp = GetEnt("pap_ramp", "targetname");

	//enable the jump traversal
	level.brush_pap_traversal = GetEnt( "brush_pap_traversal", "targetname" );
	if ( isdefined( level.brush_pap_traversal ) )
	{
		level.brush_pap_traversal _pap_brush_connect_paths();
	}

	//disable the side paths
	level.brush_pap_side_l = GetEnt( "brush_pap_side_l", "targetname" );
	if ( isdefined( level.brush_pap_side_l ) )
	{
		level.brush_pap_side_l _pap_brush_disconnect_paths();
	}
	level.brush_pap_side_r = GetEnt( "brush_pap_side_r", "targetname" );
	if ( isdefined( level.brush_pap_side_r ) )
	{
		level.brush_pap_side_r _pap_brush_disconnect_paths();
	}

	//delete the ramp clips placed just to make sure side paths generate correctly
	brush_pap_pathing_ramp_r = GetEnt( "brush_pap_pathing_ramp_r", "targetname" );
	if ( isdefined( brush_pap_pathing_ramp_r ) )
	{
		brush_pap_pathing_ramp_r delete();
	}
	brush_pap_pathing_ramp_l = GetEnt( "brush_pap_pathing_ramp_l", "targetname" );
	if ( isdefined( brush_pap_pathing_ramp_l ) )
	{
		brush_pap_pathing_ramp_l delete();
	}
}

/*#using_animtree( "generic_human" );
_setup_pressure_plate_bodies()
{
	wait(1.0);

	joint_array = [];
	joint_array[joint_array.size] = "j_neck";
	joint_array[joint_array.size] = "j_ankle_ri";
	joint_array[joint_array.size] = "j_wrist_le";
	joint_index = 0;

	spots = GetEntArray( "hanging_base", "targetname" );

	// keep track of how many zombies have been dropped before allowing the elevator to be activated
	level.zombie_drops_left = spots.size;

	for( i=0; i<spots.size; i++ )
	{
		guy = spawn( "script_model", spots[i].origin - (0,0,50) );
		guy.base = spots[i];
		guy.animname = "generic";

		guy _setup_hanging_model(i);
		guy SetModel("c_vtn_civ_fullbody");	//make random

		guy makeFakeAI();
		guy useAnimTree(#animtree);
		guy setAnim( %crouch2stand, 1.0, 1.0, 1.0 );
		guy.health = 1000;

		joint = joint_array[joint_index];
		joint_index = (joint_index + 1) % joint_array.size;

		guy.rope = createrope( spots[i].origin, (0,0,0), 40, guy, joint );

		guy thread _watch_for_fall();
	}

	//level thread _wait_for_pap_enable();
}*/

_setup_hanging_model(index)
{
	switch( index )
	{
	case 0:
		self character\c_usa_dempsey_zt::main();// Dempsy
		break;
	case 1:
		self character\c_rus_nikolai_zt::main();// Nikolai
		break;
	case 2:
		self character\c_jap_takeo_zt::main();// Takeo
		break;
	case 3:
		self character\c_ger_richtofen_zt::main();// Richtofen
		break;
	}
}

_watch_for_fall()
{
	wait(0.1);
	self SetContents(0);
	self startragdoll();

	self.base SetCanDamage(true);
	self.base.health = 1;

	self.base waittill("damage");

	// get the mover before deleting
	mover = GetEnt(self.base.target, "targetname");
	//Does this body trigger a geyser?
	geyserFX = isdefined(self.base.script_string) && self.base.script_string == "geyser";

	self.base Delete();
	self.base = undefined;

	DeleteRope(self.rope);

	// wait for a bit, then lower the pressure plate and activate the elevator
	wait(0.5);

	if(geyserFX)
	{
		level thread _play_geyser_fx(mover.origin);
	}

	mover MoveZ(-14.0, 1.0, 0.2, 0.0);
	mover waittill("movedone");

	level.zombie_drops_left -= 1;
	if ( level.zombie_drops_left <= 0 )
	{
		flag_set("pap_enabled");
	}
}

_play_geyser_fx(origin)
{
	fxObj = spawnFX(level._effect[ "geyser_active" ], origin);
	TriggerFX(fxObj);

	wait 3.0;

	fxObj Delete();
}

power( base, exp )
{
	assert( exp >= 0 );

	if ( exp == 0 )
	{
		return 1;
	}

	return base * power( base, exp - 1 );
}

_setup_simultaneous_pap_triggers()
{
	spots = GetEntArray( "hanging_base", "targetname" );
	for ( i = 0; i < spots.size; i++ )
	{
		spots[i] Delete();
	}

	// pap can be activated as soon as the power is on now
	flag_wait("power_on");

	// raise up the 4 pressure plates so they can be stepped on
	triggers = [];
	for(i=0;i<4;i++)
	{
		triggers[i] = GetEnt("pap_blocker_trigger" + (i+1), "targetname");
	}

	if(level.gamemode != "survival")
	{
		// end all the threads that manage the pressure plate action
		for ( i = 0; i < triggers.size; i++ )
		{
			triggers[i] notify("pap_active");
			triggers[i].plate _plate_move_down();
		}

		_pap_think();
		_set_num_plates_active(4, 15);

		return;
	}

	_randomize_pressure_plates(triggers);

	array_thread( triggers, ::_pap_pressure_plate_move );

	wait(1.0);

	last_num_plates_active = -1;
	last_plate_state = -1;
	while ( true )
	{
		players = GetPlayers();

		//if(players.size == 1) //Player must touch each plate once
		//{
		//	num_plates_needed = 4;
		//}
		//else //Multiplayer must touch all plates at the same time
		//{
			num_plates_needed = players.size;
		//}
		num_plates_active = 0;
		plate_state = 0;
		for ( i = 0; i < triggers.size; i++ )
		{
			if ( triggers[i].plate.active )
			{
				num_plates_active++;
			}

			if(triggers[i].plate.active || (triggers[i].requiredPlayers-1)>=num_plates_needed)
			{
				plate_state += power(2,(triggers[i].requiredPlayers-1));
			}
		}

		if ( last_num_plates_active != num_plates_active || plate_state != last_plate_state )
		{
			last_num_plates_active = num_plates_active;
			last_plate_state = plate_state;
			_set_num_plates_active(num_plates_active, plate_state);
		}

		_update_stairs(triggers);


		if ( num_plates_active >= num_plates_needed )
		{
			// end all the threads that manage the pressure plate action
			for ( i = 0; i < triggers.size; i++ )
			{
				triggers[i] notify("pap_active");
				triggers[i].plate _plate_move_down();
			}

			_pap_think();
			_randomize_pressure_plates(triggers);
			array_thread( triggers, ::_pap_pressure_plate_move );
			_set_num_plates_active(4, 15);
			wait(1.0);
		}

		wait_network_frame();
	}
}

_randomize_pressure_plates(triggers)
{
	//Randomize what plates required for the players to activate the pap
	rand_nums = array(1,2,3,4);
	rand_nums = array_randomize(rand_nums);
	for(i=0;i<triggers.size;i++)
	{
		triggers[i].requiredPlayers = rand_nums[i];
	}
}

_update_stairs(triggers)
{
	numTouched = 0;
	for(i=0;i<triggers.size;i++)
	{
		if(is_true(triggers[i].touched))
		{
			numTouched++;
		}
	}

	for(i=0;i<numTouched;i++)
	{
		level.pap_stairs[i] _stairs_move_up();
	}
	for(i=numTouched; i<level.pap_stairs.size; i++)
	{
		level.pap_stairs[i] _stairs_move_down();
	}
}

_pap_pressure_plate_move_enabled()
{
	numPlayers = GetPlayers().size;
//	if(numPlayers == 1)
//	{
//		return true;
//	}

	if(numPlayers>=self.requiredPlayers)
	{
		return true;
	}

	return false;
}

_pap_pressure_plate_move()
{
	self endon("pap_active");

	plate = GetEnt(self.target, "targetname");
	self.plate = plate;

	// initialized the ent flags we will use to control up/down movement

	plate.moveTime = 2;
	plate.moveDist = (0,0,10);
	plate.down_origin = plate.origin;
	plate.up_origin = plate.origin + plate.moveDist;
	plate.origin = plate.down_origin;
	plate.state = "down";

	moveSpeed = 10.0;

	while(true)
	{

		while(!self _pap_pressure_plate_move_enabled())
		{
			plate.active = false;
			self.touched = false;

			plate thread _plate_move_down();

			wait .1;
		}

		// initially move the plates up to where they can be pressed down
		plate.active = false;
		self.touched = false;

		plate _plate_move_up();
		plate waittill("state_set");

		while ( self _pap_pressure_plate_move_enabled() )
		{
			players = GetPlayers();
			touching = false;

			//Check for players dropping out
			if(!self _pap_pressure_plate_move_enabled())
			{
				break;
			}

			for ( i = 0; i < players.size && !touching; i++ )
			{
				if( players[i].sessionstate != "spectator" )
				{
					touching = players[i] IsTouching(self);
				}
			}

			//Once a plate is touched in solo it remains touched
			//if(!self.touched || players.size != 1)
			//{
				self.touched = touching;
			//}

			if(touching)
			{
				plate _plate_move_down();
			}
			else if(!plate.active)
			{
				plate _plate_move_up();
			}

			plate.active = plate.state == "down";

			wait(0.1);
		}
	}
}

/////////////
//Move Sounds
/////////////
_stairs_playMoveSound()
{
	self _stairs_stopMoveSound();
	self playloopsound("zmb_staircase_loop");
}
_stairs_stopMoveSound()
{
	self stoploopsound();
}
_stairs_playLockedSound()
{
	self playsound("zmb_staircase_lock");
}
_plate_playMoveSound()
{
	self _plate_stopMoveSound();
	self playloopsound("zmb_pressure_plate_loop");
}
_plate_stopMoveSound()
{
	self stoploopsound();
}
_plate_playLockedSound()
{
	self playsound("zmb_pressure_plate_lock");
}

////
//Generic Move with State
///
_mover_get_origin(state)
{
	if(state == "up")
	{
		return self.up_origin;
	}
	else if(state == "down")
	{
		return self.down_origin;
	}

	return undefined;
}
_move_pap_mover_wait(state, onMoveFunc, onStopFunc)
{
	self endon("move");

	goalOrigin = self _mover_get_origin(state);

	//Scale time if not at beginning
	moveTime = self.moveTime;
	timeScale = abs((self.origin[2] - goalOrigin[2])) / (self.moveDist[2]);
	moveTime *= timeScale;

	self.state = "moving_" + state;
	if(moveTime > 0)
	{
		if(isDefined(onMoveFunc))
		{
			self thread [[onMoveFunc]]();
		}

		self MoveTo(goalOrigin, moveTime);
		self waittill("movedone");

		if(isDefined(onStopFunc))
		{
			self thread [[onStopFunc]]();
		}
	}
	self.state = state;
	self notify("state_set");
}

//state = up or down
_move_pap_mover(state, onMoveFunc, onStopFunc)
{
	if(self.state == state || self.state == "moving_" + state)
	{
		return;
	}

	self notify("move");

	self thread _move_pap_mover_wait(state, onMoveFunc, onStopFunc);

}
_move_down(onMoveFunc, onStopFunc)
{
	self thread _move_pap_mover("down", onMoveFunc, onStopFunc);
}

_move_up(onMoveFunc, onStopFunc)
{
	self thread _move_pap_mover("up", onMoveFunc, onStopFunc);
}

////////////
//Plate Move
////////////
_plate_move_up()
{
	onMoveFunc = ::_plate_onMove;
	onStopFunc = ::_plate_onStop;
	self thread _move_up(onMoveFunc, onStopFunc);
}

_plate_move_down()
{
	onMoveFunc = ::_plate_onMove;
	onStopFunc = ::_plate_onStop;
	self thread _move_down(onMoveFunc, onStopFunc);
}

_plate_onMove()
{
	self _plate_playMoveSound();
}

_plate_onStop()
{
	self _plate_stopMoveSound();
	self _plate_playLockedSound();
}

////////////
//Stairs Move
////////////
_move_all_stairs_down()
{
	for(i=0;i<level.pap_stairs.size;i++)
	{
		level.pap_stairs[i] thread _stairs_move_down();
	}
}

_move_all_stairs_up()
{
	for(i=0;i<level.pap_stairs.size;i++)
	{
		level.pap_stairs[i] thread _stairs_move_up();
	}
}
_stairs_move_up()
{
	onMoveFunc = ::_stairs_onMove;
	onStopFunc = ::_stairs_onStop;
	self _move_up(onMoveFunc, onStopFunc);
}

_stairs_move_down()
{
	onMoveFunc = ::_stairs_onMove;
	onStopFunc = ::_stairs_onStop;
	self _move_down(onMoveFunc, onStopFunc);
}

_stairs_onMove()
{
	self _stairs_playMoveSound();
}

_stairs_onStop()
{
	self _stairs_stopMoveSound();
	self _stairs_playLockedSound();
}

//_wait_for_pap_enable()
//{
//	cheat = false;
//
//	/#
//	cheat = GetDvarInt("zombie_debug_temple_pap") > 0;
//    #/

//	if ( !cheat )
//	{
//		flag_wait("power_on");
//		flag_wait("pap_enabled");
//	}

//	// raise up the 4 pressure plates so they can be stepped on
//	triggers = GetEntArray("pap_blocker_trigger", "targetname");
//	array_thread( triggers, ::_pap_pressure_plate_think );

//	plates_active = 0;

//	/#
//	if ( cheat )
//	{
//		plates_active = 4;
//	}
//    #/
//
//	_set_num_plates_active(plates_active);

//	while ( true )
//	{
//		if ( level.pap_plates_active >= 4 )
//		{
//			_pap_think();

//			plates_active = 0;

//			/#
//			if ( cheat )
//			{
//				plates_active = 4;
//			}
//            #/

//			_set_num_plates_active(plates_active);
//		}

//		wait_network_frame();
//	}
//}

_wait_for_all_stairs(state)
{
	for(i=0;i<level.pap_stairs.size;i++)
	{
		stair = level.pap_stairs[i];
		while(1)
		{
			if(stair.state == state)
			{
				break;
			}
			wait .1;
		}
	}
}
_wait_for_all_stairs_up()
{
	_wait_for_all_stairs("up");
	if ( isdefined( level.brush_pap_traversal ) )
	{
		level.brush_pap_traversal _pap_brush_disconnect_paths();
	}
	if ( isdefined( level.brush_pap_side_l ) )
	{
		level.brush_pap_side_l _pap_brush_connect_paths();
	}
	if ( isdefined( level.brush_pap_side_r ) )
	{
		level.brush_pap_side_r _pap_brush_connect_paths();
	}
}
_wait_for_all_stairs_down()
{
	_wait_for_all_stairs("down");
	if ( isdefined( level.brush_pap_traversal ) )
	{
		level.brush_pap_traversal _pap_brush_connect_paths();
	}
	if ( isdefined( level.brush_pap_side_l ) )
	{
		level.brush_pap_side_l _pap_brush_disconnect_paths();
	}
	if ( isdefined( level.brush_pap_side_r ) )
	{
		level.brush_pap_side_r _pap_brush_disconnect_paths();
	}
}

_pap_think()
{
	player_blocker = GetEnt("pap_stairs_player_clip", "targetname");

	flag_set("pap_active");

	level thread _pap_clean_up_corpses();

	if ( IsDefined(level.pap_stairs_clip) )
	{
		level.pap_stairs_clip MoveZ(level.pap_stairs_clip.zMove, 2.0, 0.5, 0.5);
	}

	_move_all_stairs_up();
	_wait_for_all_stairs_up();

	//Turn on all indeicators right away
	//level thread _show_activated_fx();

	if ( IsDefined(player_blocker) )
	{
		player_blocker Notsolid();
	}

	level stop_pap_fx();

	if(level.gamemode != "survival")
	{
		return;
	}

	level thread _wait_for_pap_reset();
	level waittill("flush_done");

	flag_clear("pap_active");

//	if ( IsDefined(player_blocker) )
//	{
//		player_blocker Solid();
//	}

	if ( IsDefined(level.pap_stairs_clip) )
	{
		level.pap_stairs_clip MoveZ(-1 * level.pap_stairs_clip.zMove, 2.0, 0.5, 0.5);
	}

	level thread _pap_ramp();

	_move_all_stairs_down();
	_wait_for_all_stairs_down();

}

_pap_clean_up_corpses()
{
	corpse_trig = GetEnt( "pap_target_finder", "targetname" );
	stairs_trig = GetEnt( "pap_target_finder2", "targetname" );

	corpses = GetCorpseArray();
	if( IsDefined( corpses ) )
	{
		for ( i = 0; i < corpses.size; i++ )
		{
			if( corpses[i] istouching( corpse_trig ) || corpses[i] istouching( stairs_trig ) )
			{
				corpses[i] thread _pap_remove_corpse();
			}
		}
	}
}

_pap_remove_corpse()
{
	PlayFX( level._effect["corpse_gib"], self.origin );
	self Delete();
}


_pap_ramp()
{

	if( IsDefined(level.pap_ramp) )
	{
		level thread playerclip_restore();

		if(!IsDefined(level.pap_ramp.original_origin))
		{
			level.pap_ramp.original_origin = level.pap_ramp.origin;
		}

		level.pap_ramp rotateRoll(45, .5);
		wait 3;
		level.pap_ramp RotateRoll(45, .5);
		level.pap_ramp moveto(getstruct("pap_ramp_push", "targetname").origin, 2);
		level.pap_ramp waittill("movedone");
		level.pap_ramp.origin = level.pap_ramp.original_origin;
		level.pap_ramp rotateRoll(-90, .5);
	}
}

playerclip_restore()
{


	volume = GetEnt("pap_target_finder", "targetname");

	while(1)
	{
		touching = false;
		// find all players and zombies inside the volume
		players = GetPlayers();
		for ( i = 0; i < players.size; i++ )
		{
			if(players[i] IsTouching(volume) || players[i] isTouching(level.pap_player_flush_temp_trig))
			{
				touching = true;
			}
		}
		if(!touching)
		{
			break;
		}
		wait(.05);
	}

	player_clip = getent("pap_stairs_player_clip","targetname");
	if(isDefined(player_clip))
	{
		player_clip solid();
	}

	if(isDefined( level.pap_player_flush_temp_trig ))
	{
		level.pap_player_flush_temp_trig delete();
	}
}

_show_activated_fx()
{
	setclientsysstate( "pap_indicator_spinners", 4 );
	wait 1.0;
	setclientsysstate( "pap_indicator_spinners", 0 );
}

_wait_for_pap_reset()
{
	level endon( "fake_death" );
	level endon ( "force_flush" );

	array_thread(level.pap_timers, ::_move_visual_timer );
	array_thread(level.pap_timers, ::_pack_a_punch_timer_sounds );

	level thread _pack_a_punch_warning_fx(level.pap_active_time);

	fx_time_offset = 0.5;
	wait(level.pap_active_time - fx_time_offset );

	flag_waitopen("pack_machine_in_use");
	level.pap_moving = true;
	level start_pap_fx();
	level thread _pap_fx_timer();
	wait fx_time_offset;

	_find_ents_to_flush();
	wait 1;
	level.pap_moving = false;
}

_pap_force_reset()
{
	level notify( "force_flush" );

	array_thread(level.pap_timers, ::_force_visual_timer_reset );

	self playsound("evt_pap_timer_stop");

	fx_time_offset = 0.5;
	level start_pap_fx();
	level thread _pap_fx_timer();
	wait fx_time_offset;

	_find_ents_to_flush();
	level.pap_moving = false;
}

_pap_fx_timer()
{
	level endon ( "force_flush" );

	wait( 5.5 );
	level notify( "flush_fx_done" );
}

_pack_a_punch_warning_fx(pap_time)
{
	level endon ( "force_flush" );

	//Give the player a 5 second warning before flush
	wait(pap_time - 5.0);
	exploder(60);
}

_pack_a_punch_timer_sounds()
{
	level endon ( "force_flush" );

	pap_timer_length = 8.5;

	self playsound("evt_pap_timer_start");
	self playloopsound("evt_pap_timer_loop");

	wait (level.pap_active_time - pap_timer_length);

	self playsound("evt_pap_timer_countdown");

	wait pap_timer_length;
	flag_waitopen("pack_machine_in_use");

	self stoploopsound();
	self playsound("evt_pap_timer_stop");
}

_find_ents_to_flush()
{
	level notify("flush_ents");
	level endon( "fake_death" );

	_play_flush_sounds();

	level.flushSpeed = 400.0;  // unit/sec
	level.ents_being_flushed = 0;
	level.flushScale = 1.0;

	volume = GetEnt("pap_target_finder", "targetname");
	level.pap_player_flush_temp_trig = spawn( "trigger_radius", (-8, 560, 288), 0, 768, 256 );
	// find all players and zombies inside the volume

	players = GetPlayers();

	touching_players = [];
	for ( i = 0; i < players.size; i++ )
	{
		touching = players[i] IsTouching(volume) || players[i] IsTouching(level.pap_player_flush_temp_trig);
		if ( touching )
		{
			touching_players[touching_players.size] = players[i];
			players[i] thread _player_flushed_out( volume );
		}
	}


	bottom_stairs_vol = getent("pap_target_finder2","targetname");

	zombies_to_flush = [];
	zombies = GetAiSpeciesArray( "axis", "all" );
	for ( i = 0; i < zombies.size; i++ )
	{
		if ( zombies[i] isTouching(volume) || zombies[i] isTouching(bottom_stairs_vol) )
		{
			zombies_to_flush[zombies_to_flush.size] = zombies[i];
		}
	}

	if(zombies_to_flush.size > 0)
	{
		level thread do_zombie_flush(zombies_to_flush);
	}

	level notify("flush_done");

	// now that we are done finding ents to sweep, wait until all the ents have been swept
	while ( level.ents_being_flushed > 0 )
	{
		wait_network_frame();
	}

	level notify("pap_reset_complete");
}

_player_flushed_out( volume )
{
	self endon( "death" );
	self endon( "disconnect" );

	level endon( "flush_fx_done" );

	self thread _player_flush_fx_done();

	water_start_org = (0, 408, 304);
	max_dist= 400;
	time = 1.5;

	dist = distance(self.origin,water_start_org);
	scale_dist = dist/max_dist;

	time = time * scale_dist;
	wait(time);

	if(self.sessionstate == "playing")
	{
		self SetWaterSheeting( 1 );
	}

	while ( 1 )
	{
		if ( !self IsTouching( volume ) )
		{
			break;
		}

		wait_network_frame();
	}

	if(self.sessionstate == "playing")
	{
		self SetWaterSheeting( 0 );
	}
}

_player_flush_fx_done()
{
	self endon( "death" );
	self endon( "disconnect" );

	level waittill( "flush_fx_done" );

	if(self.sessionstate == "playing")
	{
		self SetWaterSheeting( 0 );
	}
}

_play_flush_sounds()
{
	snd_struct = getstruct( "pap_water", "targetname" );
	if( IsDefined( snd_struct ) )
	{
		level thread play_sound_in_space( "evt_pap_water", snd_struct.origin );
	}
}

_flush_compare_func(p1, p2)
{
	dist1 = DistanceSquared(p1.origin, level.flush_path.origin);
	dist2 = DistanceSquared(p2.origin, level.flush_path.origin);

	return dist1 > dist2;
}

_player_flush(index)
{
	//can't let players die while being flushed - causes crash
	self EnableInvulnerability();

	self AllowProne(false);
	self AllowCrouch(false);
	self PlayRumbleLoopOnEntity( "tank_rumble" );
	self thread pap_flush_screen_shake(3);

	mover = Spawn("script_origin", self.origin);
	self PlayerLinkTo(mover);

	// link the playerclip to ourself
	pc = level.pap_playerclip[index];
	pc.origin = self.origin;
	pc LinkTo(self);

	level.ents_being_flushed++;
	self.flushed = true;

	useAccel = true;

	flushSpeed = level.flushSpeed - 30.0 * index;

	wait(index*0.1);

	nextTarget = self _ent_GetNextFlushTarget();
	while ( IsDefined(nextTarget) )
	{
		// ignore x here--just care about y/z -- probably could do this more generically with projections, but it doesn't really matter
		moveTarget = (self.origin[0], nextTarget.origin[1], nextTarget.origin[2]);
		if ( !IsDefined(nextTarget.next) )
		{
			// scale each move by a bit so the players don't end up on top of each other at the end
			moveTarget = (moveTarget[0], self.origin[1] + (moveTarget[1] - self.origin[1])* level.flushScale, moveTarget[2]);
			level.flushScale -= 0.25;
			if ( level.flushScale <= 0.0 )
			{
				level.flushScale = 0.1;
			}
		}

		dist = Abs(nextTarget.origin[1] - self.origin[1]);
		time = dist / flushSpeed;

		accel = 0.0;
		decel = 0.0;
		if ( useAccel )
		{
			useAccel = false;
			accel = Min(0.2, time);
		}

		if ( !IsDefined(nextTarget.target) )
		{
			accel = 0.0;
			decel = time;
			time += 0.5;
		}

		mover MoveTo(moveTarget, time, accel, decel);

		waitTime = Max(time, 0.0);
		wait(waitTime);

		nextTarget = nextTarget.next;
	}

	mover Delete();

	self stoprumble( "tank_rumble" );
	self notify( "pap_flush_done" );
	pc Unlink();
	pc.origin = pc.saved_origin;

	self AllowProne(true);
	self AllowCrouch(true);

	self.flushed = false;
	self DisableInvulnerability();
	level.ents_being_flushed--;
}

pap_flush_screen_shake(activeTime)
{
	self endon( "pap_flush_done" );
	while( 1 )
	{
		Earthquake( RandomFloatRange(0.2, 0.4), RandomFloatRange(1, 2), self.origin, 100, self );
		wait( RandomFloatRange( 0.1, 0.3 ) );
	}
}

do_zombie_flush(zombies_to_flush)
{
	for(i=0;i<zombies_to_flush.size;i++)
	{
		if(isDefined(zombies_to_flush[i]) && isalive(zombies_to_flush[i]))
		{
			zombies_to_flush[i] thread _zombie_flush();
		}
	}
}

/*------------------------------------
flush the zombies out with a time delay based on
how far away they are from the waterfall that flushes
the area
------------------------------------*/
_zombie_flush()
{
	self endon("death");
	water_start_org = (0, 408, 304);
	max_dist= 400;
	time = 1.5;

	dist = distance(self.origin,water_start_org);
	scale_dist = dist/max_dist;

	time = time * scale_dist;
	wait(time);


	self StartRagdoll();

	// send the ragdoll towards the next target
	nextTarget = self _ent_GetNextFlushTarget();
	launchDir = nextTarget.origin - self.origin;
	launchDir = (0.0, launchDir[1], launchDir[2]);
	launchDir = VectorNormalize(launchDir);
	self launchragdoll(launchDir * 50.0);
	wait_network_frame();

	// Make sure they're dead...physics launch didn't kill them.
	self.no_gib = true;

	player = get_closest_player(self.origin);

	self.trap_death = true;
	self.no_powerups = true;
	self dodamage(self.health + 666, self.origin, player);

}

_ent_GetNextFlushTarget()
{
	current_node = level.flush_path;
	while ( true )
	{
		if ( self.origin[1] >= current_node.origin[1] )
		{
			break;
		}

		current_node = current_node.next;
	}

	return current_node;
}

//_pap_pressure_plate_think()
//{
//	plate = GetEnt(self.target, "targetname");

//	while ( true )
//	{
//		plate MoveZ( 10.0, 2.0, 0.0, 0.0);
//		plate waittill("movedone");

//		self waittill("trigger");

//		plate MoveZ(-10.0, 2.0, 0.0, 0.0);
//		plate waittill("movedone");

//		_set_num_plates_active(level.pap_plates_active + 1);

//		level waittill("pap_reset_complete");
//	}
//}

_set_num_plates_active(num, state)
{
	level.pap_plates_active = num;
	level.pap_plates_state = state;
	setclientsysstate( "pap_indicator_spinners", state );
}

///////////////////////////////////////////////////////////////////////////////

_setup_pap_timer()
{
	level.pap_timers = GetEntArray("pap_timer", "targetname");

	for ( i = 0; i < level.pap_timers.size; i++ )
	{
		timer = level.pap_timers[i];
		timer.path = [];

		targetName = timer.target;
		while ( IsDefined(targetName) )
		{
			s = GetStruct(targetName, "targetname");
			if ( !IsDefined(s) )
			{
				break;
			}
			timer.path[timer.path.size] = s;
			targetName = s.target;
		}

		timer.origin = timer.path[0].origin;

		// now calculate the distance of the path so we can uniformly move the timer along it
		pathLength = 0;
		for ( p = 1; p < timer.path.size; p++ )
		{
			length = Distance(timer.path[p-1].origin, timer.path[p].origin);
			timer.path[p].pathLength = length;
			pathLength += length;
		}
		timer.pathLength = pathLength;

		//Reverse path length
		for(p=timer.path.size-2; p>=0; p--)
		{
			length = Distance(timer.path[p+1].origin, timer.path[p].origin);
			timer.path[p].pathLengthReverse = length;
		}

	}
}

_move_visual_timer()
{
	level endon ( "force_flush" );

	reverseSpin = self.angles[1] != 0;
	speed = self.pathLength / level.pap_active_time;
	self _travel_path(speed, reverseSpin);

	returnTime = 4.0;
	flag_waitopen("pack_machine_in_use");

	speed = self.pathLength / returnTime;
	self _travel_path_reverse(speed, reverseSpin);
	self.origin = self.path[0].origin;
}

_force_visual_timer_reset()
{
	returnTime = 4.0;
	reverseSpin = self.angles[1] != 0;
	speed = self.pathLength / returnTime;
	self _travel_path_reverse(speed, reverseSpin);
	self.origin = self.path[0].origin;
}

_travel_path(speed, reverseSpin)
{
	for ( i = 1; i < self.path.size; i++ )
	{
		length = self.path[i].pathLength;
		time = length / speed;

		accelTime = 0;
		decelTime = 0;
		if(i==1)
		{
			accelTime = .2;
		}
		else if(i==self.path.size-1)
		{
			decelTime = .2;
		}

		self MoveTo(self.path[i].origin, time, accelTime, decelTime);

		rotateSpeed = speed*-4;
		if(reverseSpin)
		{
			rotateSpeed *= -1;
		}
		self rotatevelocity((0,0,rotateSpeed), time);
		self waittill("movedone");
		//wait(time - 0.1);
	}

}

_travel_path_reverse(speed, reverseSpin)
{
	for ( i = self.path.size-2; i >= 0; i-- )
	{
		length = self.path[i].pathLengthReverse;
		time = length / speed;

		accelTime = 0;
		decelTime = 0;
		if(i==self.path.size-2)
		{
			accelTime = .2;
		}
		else if(i==0)
		{
			decelTime = .5;
		}


		self MoveTo(self.path[i].origin, time, accelTime, decelTime );

		rotateSpeed = speed*4;
		if(reverseSpin)
		{
			rotateSpeed *= -1;
		}
		self rotatevelocity((0,0,rotateSpeed), time);
		self waittill("movedone");
		self playsound("evt_pap_timer_stop");
		self playsound("evt_pap_timer_start");
		//wait(time - 0.1);
	}

}

/////////////////////////////////////////////////////

_setup_pap_path()
{
	level.flush_path = GetStruct("pap_flush_path", "targetname");
	current_node = level.flush_path;
	while ( true )
	{
		if ( !IsDefined(current_node.target) )
		{
			break;
		}

		next_node = GetStruct(current_node.target, "targetname");
		current_node.next = next_node;
		current_node = next_node;
	}
}

/////////////////////////////////////////////////////
_setup_pap_fx()
{

}

start_pap_fx()
{
	Exploder(61);
}

stop_pap_fx()
{
	stop_exploder(61);
}

_pap_brush_disconnect_paths()
{
	self Solid();
	self enable_trigger();
	self DisconnectPaths();
	self disable_trigger();
	self NotSolid();
}

_pap_brush_connect_paths()
{
	self Solid();
	self enable_trigger();
	self ConnectPaths();
	self disable_trigger();
	self NotSolid();
}
