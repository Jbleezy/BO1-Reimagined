#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_zone_manager;


//-------------------------------------------------------------------------------
// setup and kick off think functions
//-------------------------------------------------------------------------------
teleporter_init()
{

	level.teleport_ae_funcs = [];
	SetDvar( "pentagonAftereffectOverride", "-1" );

	thread teleport_pad_init();
	thread enable_zone_portals_init();
	thread open_portal_rooms();
	thread pack_hideaway_init();

	poi1 = GetEnt("pack_room_poi1", "targetname");
	poi2 = GetEnt("pack_room_poi2", "targetname");

	// attract_dist, num_attractors, added_poi_value, start_turned_on
	poi1 create_zombie_point_of_interest( undefined, 30, 0, false );
	poi1 thread create_zombie_point_of_interest_attractor_positions( 4, 45 );

	poi2 create_zombie_point_of_interest( undefined, 30, 0, false );
	poi2 thread create_zombie_point_of_interest_attractor_positions( 4, 45 );

}

//-------------------------------------------------------------------------------
// handles turning on the pad.
//-------------------------------------------------------------------------------
teleport_pad_init()
{
	level.portal_trig = GetEntArray( "portal_trigs", "targetname" );
	for ( i = 0; i < level.portal_trig.size; i++ )
	{
		level.portal_trig[i].active = true;
		level.portal_trig[i].portal_used =[];
		level.portal_trig[i] thread player_teleporting();
	}
}
//-------------------------------------------------------------------------------
// DCS: hideaway closet for pack a punch.
//-------------------------------------------------------------------------------
pack_hideaway_init()
{
	hideaway = GetEnt("pack_hideaway","targetname");
	parts = GetEntArray(hideaway.target, "targetname");

	level.punch_trigger = GetEnt( "zombie_vending_upgrade", "targetname" );
	level.punch_machine = GetEnt( level.punch_trigger.target, "targetname" );
	level.punch_sign = GetEnt( level.punch_machine.target, "targetname" );
	level.punch_sign LinkTo( level.punch_machine );

	if(IsDefined(level.punch_trigger))
	{
		level.punch_trigger EnableLinkTo();
		level.punch_trigger LinkTo(hideaway);
	}
	if(IsDefined(level.punch_machine))
	{
		level.punch_machine LinkTo(hideaway);
	}

	pack_audio_trig = GetEnt( "pack_audio_trig", "script_noteworthy" );
	pack_audio_trig EnableLinkTo();
	pack_audio_trig LinkTo(hideaway);

	if(IsDefined(parts))
	{
		for ( i = 0; i < parts.size; i++ )
		{
			parts[i] LinkTo(hideaway);
		}
	}

	if(level.gamemode == "survival")
	{
		while(true)
		{
			flag_wait("open_pack_hideaway");

			level.pap_moving = true;
			hideaway NotSolid();
			hideaway RotateYaw(180, 2.5);
			hideaway PlaySound( "evt_packapunch_revolve_start" );
			hideaway PlayLoopSound( "evt_packapunch_revolve_loop" );
			hideaway waittill("rotatedone");
			level.pap_moving = false;
			level.punch_trigger SetVisibleToAll();
			level.punch_trigger trigger_on();

			hideaway StopLoopSound( 1 );
		    hideaway PlaySound( "evt_packapunch_revolve_end" );

			level.punch_sign Unlink();

			// time given for everyone to pack if they want.
			//level waittill("defcon_reset");
			wait(40); // additional time after countdown

			while(!is_packroom_clear())
			{
				wait_network_frame();
			}

			if(flag("pack_machine_in_use"))
			{
				while(flag("pack_machine_in_use"))
				{
					wait(0.1);
				}
			}
			level.punch_sign LinkTo( level.punch_machine );
			level.punch_trigger trigger_off();

			players = get_players();
			for ( i = 0; i < players.size; i++ )
			{
				level.punch_trigger SetInvisibleToPlayer(players[i]);
			}

			level.pap_moving = true;
			hideaway RotateYaw(180, 2.5);
			hideaway PlaySound( "evt_packapunch_revolve_start" );
			hideaway PlayLoopSound( "evt_packapunch_revolve_loop" );
			flag_clear("open_pack_hideaway");
			wait_network_frame();
			hideaway waittill("rotatedone");
			level.pap_moving = false;
			hideaway StopLoopSound( 1 );
		    hideaway PlaySound( "evt_packapunch_revolve_end" );
		}
	}
	else
	{
		level.pap_moving = true;
		hideaway NotSolid();
		hideaway RotateYaw(180, 2.5);
		hideaway PlaySound( "evt_packapunch_revolve_start" );
		hideaway PlayLoopSound( "evt_packapunch_revolve_loop" );
		hideaway waittill("rotatedone");
		level.pap_moving = false;
		level.punch_trigger SetVisibleToAll();
		level.punch_trigger trigger_on();

		hideaway StopLoopSound( 1 );
	    hideaway PlaySound( "evt_packapunch_revolve_end" );

		level.punch_sign Unlink();
	}
}
//-------------------------------------------------------------------------------
// DCS: Pack room door init
//-------------------------------------------------------------------------------
pack_door_init()
{
	if(level.gamemode != "survival")
	{
		level thread pack_door_buyable_init();
		return;
	}

	trigger = GetEnt("pack_room_door","targetname");
	doors = GetEntArray(trigger.target, "targetname");
	pack_door_slam = GetEnt("slam_pack_door","targetname");
	pack_door_open = false;

	while(true)
	{
		trigger setcursorhint( "HINT_NOICON" );
		trigger sethintstring( &"ZOMBIE_PENTAGON_PACK_ROOM_DOOR" );
		level waittill_any("defcon_reset", "player_in_pack");

		players = get_players();

		if(level.zones["conference_level2"].is_occupied)
		{

			if(level.zones["war_room_zone_south"].is_enabled  && !flag("bonfire_reset"))
			{
				// Open doors, if war room south has been enabled, otherwise they have to go through the portal.
				trigger sethintstring( "" );
				for ( i = 0; i < doors.size; i++ )
				{
					doors[i].start_angles = doors[i].angles;

					if(isDefined(doors[i].script_angles))
					{
						doors[i] NotSolid();
						doors[i] RotateTo( doors[i].script_angles, 1.0 );
						play_sound_at_pos( "door_rotate_open", doors[i].origin );
						doors[i] thread pack_door_solid_thread();
					}
				}
				pack_door_open = true;
			}

			// wait for players to leave zone.
			while(!is_packroom_clear())
			{
				if(flag("bonfire_reset")) // leave loop if bonfire sale picked up.
				{
					break;
				}
				wait(0.1);
			}

			if(	pack_door_open == true)
			{
				// close doors
				for ( i = 0; i < doors.size; i++ )
				{
					if(isDefined(doors[i].script_angles))
					{
						doors[i] NotSolid();
						doors[i] RotateTo( doors[i].start_angles, 0.25 );
						play_sound_at_pos( "door_rotate_open", doors[i].origin );
						doors[i] thread pack_door_solid_thread();
					}
				}
			}
		}
		if(flag("bonfire_reset"))
		{
			flag_clear("bonfire_reset");
			//IPrintLnBold("bonfire reset cleared");
		}
		else
		{
			level notify("pack_room_reset");
		}
		wait_network_frame();
	}
}

pack_door_buyable_init()
{
	add_adjacent_zone( "war_room_zone_south", "conference_level2", "war_room_entry", true );

	trigger = GetEnt("pack_room_door","targetname");
	doors = GetEntArray(trigger.target, "targetname");

	trigger setcursorhint( "HINT_NOICON" );
	trigger.zombie_cost = 1500;
	trigger set_hint_string( trigger, "default_buy_door_" + trigger.zombie_cost );

	while(1)
	{
		if( trigger maps\_zombiemode_blockers::door_buy() )
			break;
	}

	trigger sethintstring( "" );

	for ( i = 0; i < doors.size; i++ )
	{
		doors[i].start_angles = doors[i].angles;

		if(isDefined(doors[i].script_angles))
		{
			doors[i] NotSolid();
			doors[i] RotateTo( doors[i].script_angles, 1.0 );
			play_sound_at_pos( "door_rotate_open", doors[i].origin );
			doors[i] thread pack_door_solid_thread();
		}
	}

	flag_set("war_room_entry");

	//open pack door
	level thread pack_hideaway_init();
}

//-------------------------------------------------------------------------------
is_packroom_clear()
{
	pack_door_slam = GetEnt("slam_pack_door","targetname");
	pack_room_trig = GetEnt("pack_room_trigger", "targetname");

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		if(players[i] IsTouching(pack_door_slam))
		{
			return false;
		}
	}
	if(level.zones["conference_level2"].is_occupied)
	{
		return false;
	}
	else if(flag("thief_round"))
	{
		zombies = GetAIArray("axis");
		for (i = 0; i < zombies.size; i++)
		{
			if(IsDefined(zombies[i].animname) && zombies[i].animname == "thief_zombie"
			&& zombies[i] IsTouching(pack_room_trig))
			{
				return false;
			}
			if(IsDefined(zombies[i].animname) && zombies[i].animname == "thief_zombie"
			&& zombies[i] IsTouching(pack_door_slam))
			{
				return false;
			}
		}
	}
	return true;
}

//-------------------------------------------------------------------------------
pack_door_solid_thread()
{
	self waittill( "rotatedone" );

	self.door_moving = undefined;
	while( 1 )
	{
		players = get_players();
		zombies = GetAIArray("axis");
		ents = array_merge(players, zombies);
		ent_touching = false;
		
		for( i = 0; i < ents.size; i++ )
		{
			if( ents[i] IsTouching( self ) )
			{
				ent_touching = true;
				break;
			}
		}

		if( !ent_touching )
		{
			self Solid();

			// Now connect paths after door is cleared.
			if(self.angles != self.start_angles)
			{
				self ConnectPaths();
			}
			else
			{
				self DisconnectPaths();
			}
			return;
		}
		wait( 1 );
	}

}
clear_zombies_in_packroom()
{
	pack_room_trig = GetEnt("pack_room_trigger", "targetname");

	if(flag("thief_round"))
	{
		return;
	}

	zombies = GetAIArray("axis");
	if(!IsDefined(zombies))
	{
		return;
	}

	for(i = 0; i < zombies.size; i++)
	{
		if(zombies[i] IsTouching(pack_room_trig) && zombies[i].ignoreall == true) // not through barricade
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
		else if(zombies[i] maps\_zombiemode_zone_manager::entity_in_zone("conference_level2"))
		{
			zombies[i] thread send_zombies_out(level.portal_pack);
		}
	}
}

//-------------------------------------------------------------------------------
// handles moving the players and fx, etc...moved out so it can be threaded
//-------------------------------------------------------------------------------
player_teleporting()
{
	user = undefined;
	while(true)
	{
		self waittill( "trigger", user );

		player_used = false;

		if(IsDefined(self.portal_used))
		{
			for (i = 0; i < self.portal_used.size; i++)
			{
				if(self.portal_used[i] == user)
				{
					player_used = true;
				}
			}
		}

		wait_network_frame();

		if(player_used == true)
		{
			continue;
		}
		// DCS 081810: also allow when in last stand
		else if ( is_player_valid( user ) || user maps\_laststand::player_is_in_laststand())
		{
			self thread Teleport_Player(user);
		}

	}
}
cooldown_portal_timer(player)
{
	//self.active = false;
	self.portal_used = array_add(self.portal_used, player);

	time = 0;
	while(!flag("defcon_active") && time < 20 )
	{
		wait(1);
		time++;
	}
	//self.active = true;
	self.portal_used = array_remove(self.portal_used, player);
}
//-------------------------------------------------------------------------------
//-------------------------------------------------------------------------------
teleport_player(user)
{
	prone_offset = (0, 0, 49);
	crouch_offset = (0, 0, 20);
	stand_offset = (0, 0, 0);
	destination = undefined;
	dest_trig = 0;

	if(IsDefined(user.teleporting) && user.teleporting == true)
	{
		return;
	}

	user.teleporting = true;
	//user FreezeControls( true );
	//user disableOffhandWeapons();
	//user disableweapons();

	// random portal to exit check, or at defcon 5 go to pack room, pack room still goes random.
	if(flag("defcon_active") && self.script_noteworthy != "conference_level2")
	{
		for ( i = 0; i < level.portal_trig.size; i++ )
		{
			if(IsDefined(level.portal_trig[i].script_noteworthy) && level.portal_trig[i].script_noteworthy == "conference_level2")
			{
				dest_trig = i;
				user thread start_defcon_countdown();
				self thread defcon_pack_poi();
			}
		}
	}
	else
	{
		dest_trig = find_portal_destination(self);

		// rediculous failsafe.
		if(!IsDefined(dest_trig))
		{
			while(!IsDefined(dest_trig))
			{
				dest_trig = find_portal_destination(self);
				break;
				wait_network_frame();
			}
		}

		// setup zombies to follow.
		self thread no_zombie_left_behind(level.portal_trig[dest_trig], user);
	}

	// script origin trigger destination targets for player placement.
	player_destination = getstructarray(level.portal_trig[dest_trig].target, "targetname");
	if(IsDefined(player_destination))
	{
		for ( i = 0; i < player_destination.size; i++ )
		{
			if(IsDefined(player_destination[i].script_noteworthy) && player_destination[i].script_noteworthy == "player_pos")
			{
				destination = player_destination[i];
			}
		}
	}

	if(!IsDefined(destination))
	{
		destination = groundpos(level.portal_trig[dest_trig].origin);
	}

	// add cool down for exiting portal.
	level.portal_trig[dest_trig] thread cooldown_portal_timer(user);

	/*if( user getstance() == "prone" )
	{
		desired_origin = destination.origin + prone_offset;
	}
	else if( user getstance() == "crouch" )
	{
		desired_origin = destination.origin + crouch_offset;
	}
	else
	{
		desired_origin = destination.origin + stand_offset;
	}*/

	desired_origin = destination.origin;

	//add player jump height
	if(user.origin[2]-groundpos(user.origin)[2] > 0)
	{
		desired_origin += (0,0,user.origin[2]-groundpos(user.origin)[2]);
	}

	wait_network_frame();
	PlayFX(level._effect["transporter_start"], user.origin);
	playsoundatposition( "evt_teleporter_out", user.origin );

	//user.teleport_origin = spawn( "script_origin", user.origin );
	//user.teleport_origin.angles = user.angles;
	//user linkto( user.teleport_origin );
	//user.teleport_origin.origin = desired_origin;
	//user.teleport_origin.angles = destination.angles;

	//DCS 113010: fix for telefrag posibility.
	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		if(players[i] == user)
		{
			continue;
		}

		if(Distance(players[i].origin, desired_origin) < 18)
		{
			desired_origin = desired_origin + (AnglesToForward(destination.angles) * -32);
		}
	}


	// trying to force angles on player.
	user DontInterpolate();
	user SetOrigin( desired_origin );
	user SetPlayerAngles( destination.angles );
	user SetVelocity((0,0,0));

	PlayFX(level._effect["transporter_beam"], user.origin);
	playsoundatposition( "evt_teleporter_go", user.origin );
	wait(0.5);
	//user enableweapons();
	//user enableoffhandweapons();
	//user FreezeControls( false );
	user.teleporting = false;


	//user Unlink();
//	if(IsDefined(user.teleport_origin))
//	{
//		user.teleport_origin Delete();
//	}

	//now check if and empty floors to clean up.
	level thread check_if_empty_floors();

	setClientSysState( "levelNotify", "cool_fx", user );

	//teleporter after effects.
	setClientSysState( "levelNotify", "ae1", user );
	wait( 1.25 );

	//check if a thief round.
	if(flag("thief_round") || flag("pig_killed_round"))
	{
		setClientSysState( "levelNotify", "vis4", user );
		return;
	}
	else
	{
		user.floor = maps\_zombiemode_ai_thief::thief_check_floor( user );
		setClientSysState( "levelNotify", "vis" + user.floor, user );
	}



}
//-------------------------------------------------------------------------------
// checks for portal destinations and is valid.
//-------------------------------------------------------------------------------
find_portal_destination(orig_trig)
{
	// rsh091310 - thief can override destination
	if(IsDefined(orig_trig.thief_override))
	{
		return orig_trig.thief_override;
	}

	// DCS 091210: power room portal go to another floor.
	if(IsDefined(orig_trig.script_string) && orig_trig.script_string == "power_room_portal")
	{
		loc = [];

		for (i = 0; i < level.portal_trig.size; i++)
		{
			if(level.portal_trig[i].script_noteworthy == "war_room_zone_north")
			{
				loc[0] = i;
			}
			else if(level.portal_trig[i].script_noteworthy == "conference_level1")
			{
				loc[1] = i;
			}
		}

		dest_trig = loc[RandomIntRange(0,2)];
		return dest_trig;
	}
	else
	{
		dest_trig = RandomIntRange(0,level.portal_trig.size);

		assertex(IsDefined(level.portal_trig[dest_trig].script_noteworthy),"portals need a script_noteworthy");

		// make sure didn't pick same portal or to inactive zone.
		if(level.portal_trig[dest_trig] == orig_trig || level.portal_trig[dest_trig].script_noteworthy == "conference_level2"
		|| !level.zones[level.portal_trig[dest_trig].script_noteworthy].is_enabled)
		{

			portals = level.portal_trig;

			for( i = 0; i < level.portal_trig.size; i ++)
			{
				level.portal_trig[i].index = i;

				if(level.portal_trig[i] == orig_trig || level.portal_trig[i].script_noteworthy == "conference_level2"
				|| !level.zones[level.portal_trig[i].script_noteworthy].is_enabled)
				{
					portals = array_remove( portals, level.portal_trig[i] );
				}
			}

			rand = RandomIntRange(0, portals.size);
			dest_trig = portals[rand].index;
			//IPrintLnBold("destination ", level.portal_trig[dest_trig].script_noteworthy);
		}
		return dest_trig;
	}
}
//-------------------------------------------------------------------------------
//	DCS 090410: now only used for pack room cleanup.
//	if can't be seen kill and so replacement can spawn closer to player.
//-------------------------------------------------------------------------------

delete_zombie_noone_looking(how_close, verticle_only, need_to_see)
{
	self endon( "death" );

	if(!IsDefined(how_close))
	{
		how_close = 500;
	}
	if(!IsDefined(verticle_only))
	{
		verticle_only = true;
	}
	if(!IsDefined(need_to_see))
	{
		need_to_see = true;
	}

	self.inview = 0;
	self.player_close = 0;

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		can_be_seen = self player_can_see_me(players[i]);

		if(can_be_seen)
		{
			self.inview++;
		}
		else
		{
			if(verticle_only)
			{
				//checking to see if 500 units above or below, likely 2 floors
				closest = abs(self.origin[2] - players[i].origin[2]);
				if(closest < how_close)
				{
					self.player_close++;
				}
			}
			else
			{
				// DCS 081910: changing to any distance not just up and down.
				closest = Distance(self.origin, players[i].origin);
				if(closest < how_close)
				{
					self.player_close++;
				}
			}
		}
	}

	// if can't be seen and likely 2 floors below or above (500 units)...
	// raise total for round by one and kill zombie so another can spawn closer to players.
	// none close, none in view.
	wait_network_frame();
	if(self.inview == 0 && self.player_close == 0 || need_to_see == false && self.player_close == 0)
	{
		if(IsDefined(self.teleporting) && self.teleporting == true)
		{
			return;
		}
		else //kill zombie so another can spawn closer.
		{
			//IPrintLnBold("Killing zombie so another can spawn closer");
			if(IsDefined(self.animname) && self.animname == "thief_zombie")
			{
				return;
			}
			else
			{
				// deleting quads leaves their effect, must delete fx.
				if(IsDefined(self.animname) &&  self.animname == "quad_zombie")
				{
					level.zombie_total++;
					if(IsDefined(self.fx_quad_trail))
					{
						self.fx_quad_trail Delete();
					}
					self notify("zombie_delete");
					self Delete();
				}
				else
				{
					level.zombie_total++;
					self maps\_zombiemode_spawner::reset_attack_spot();
					self notify("zombie_delete");
					self Delete();
				}
			}
		}
	}
}
//-------------------------------------------------------------------------------
// Utility for checking if the player can see the zombie (ai).
// Can the player see me?
//-------------------------------------------------------------------------------
player_can_see_me( player )
{
	playerAngles = player getplayerangles();
	playerForwardVec = AnglesToForward( playerAngles );
	playerUnitForwardVec = VectorNormalize( playerForwardVec );

	banzaiPos = self.origin;
	playerPos = player GetOrigin();
	playerToBanzaiVec = banzaiPos - playerPos;
	playerToBanzaiUnitVec = VectorNormalize( playerToBanzaiVec );

	forwardDotBanzai = VectorDot( playerUnitForwardVec, playerToBanzaiUnitVec );
	angleFromCenter = ACos( forwardDotBanzai );

	playerFOV = GetDvarFloat( #"cg_fov" );
	banzaiVsPlayerFOVBuffer = GetDvarFloat( #"g_banzai_player_fov_buffer" );
	if ( banzaiVsPlayerFOVBuffer <= 0 )
	{
		banzaiVsPlayerFOVBuffer = 0.2;
	}

	playerCanSeeMe = ( angleFromCenter <= ( playerFOV * 0.5 * ( 1 - banzaiVsPlayerFOVBuffer ) ) );

	return playerCanSeeMe;
}
//-------------------------------------------------------------------------------
// Hidden teleporters revealed when power turned on.
//-------------------------------------------------------------------------------
open_portal_rooms()
{
	yellow_conf_screen = GetEnt("yellow_conf_screen", "targetname");
	power_room_screen = GetEnt("power_room_screen", "targetname");
	jfk_room_screen = GetEnt("jfk_room_screen", "targetname");
	war_room_screen_north = GetEnt("war_room_screen_north", "targetname");
	war_room_screen_ramp = GetEnt("war_room_screen_ramp", "targetname");

	flag_wait( "power_on" );
	yellow_conf_screen PlaySound( "evt_teleporter_door_short" );
	yellow_conf_screen MoveZ(116, 1.5);
	yellow_conf_screen ConnectPaths();

	power_room_screen PlaySound( "evt_teleporter_door_short" );
	power_room_screen MoveZ(116, 1.5);
	power_room_screen ConnectPaths();

  	jfk_room_screen PlaySound( "evt_teleporter_door_long" );
	jfk_room_screen MoveZ(150, 2.0);
	jfk_room_screen ConnectPaths();

  	war_room_screen_north PlaySound( "evt_teleporter_door_short" );
	level thread war_room_portal_door();

	war_room_screen_north MoveZ(-122, 1.5);
	war_room_screen_ramp MoveY(46, 1.5);
	war_room_screen_ramp waittill("movedone");
	war_room_screen_north ConnectPaths();

}
war_room_portal_door()
{
	war_room_screen_south = GetEnt("war_room_screen_south", "targetname");

	war_room_screen_south PlaySound( "evt_teleporter_door_short" );
	war_room_screen_south MoveZ(-120, 1.5);
	war_room_screen_south waittill("movedone");
	war_room_screen_south ConnectPaths();
}
//-------------------------------------------------------------------------------
// zone enable through portals
// script_noteworthy  = name of zone to enable upon entry.
//-------------------------------------------------------------------------------
enable_zone_portals_init()
{
	portal_zone_trig = GetEntArray( "portal_zone_trigs", "targetname" );
	for ( i = 0; i < portal_zone_trig.size; i++ )
	{
		portal_zone_trig[i] thread enable_zone_portals();
	}
}
enable_zone_portals()
{
	self waittill( "trigger", user );
	if ( (  user maps\_laststand::player_is_in_laststand() || is_player_valid( user ) ) &&
	IsDefined(self.script_noteworthy) )
	{
		level thread maps\_zombiemode_zone_manager::enable_zone(self.script_noteworthy);
	}
}


//-------------------------------------------------------------------------------
// Check for lost Zombies.
// If close to portal player went through have the zombie follow.
// self = portal trigger entered by player, portal_trig = destination portal.
//-------------------------------------------------------------------------------
no_zombie_left_behind(portal_trig, targeted_player)
{
	portal_enter = undefined;
	teleporting_zombies = 0;

	portal_entered = getstructarray(self.target, "targetname");
	for ( i = 0; i < portal_entered.size; i++ )
	{
		if(IsDefined(portal_entered[i].script_noteworthy) && portal_entered[i].script_noteworthy == "zombie_pos")
		{
			portal_enter = portal_entered[i];
		}
	}
	if(!IsDefined(portal_enter))
	{
		return;
	}
	// check distance to portal entered by player
	zombies = GetAIArray("axis");
		if(IsDefined(zombies))
	{
		for( i = 0; i < zombies.size; i++ )
		{
			if(IsDefined(zombies[i].animname) && zombies[i].animname == "thief_zombie")
			{
				continue;
			}

			// DCS: all zombies from conference room follow last player out.
			else if(IsDefined(self.script_noteworthy) && self.script_noteworthy == "conference_level2" && !level.zones[ "conference_level2" ].is_occupied
			&& IsDefined(zombies[i].favoriteenemy) && zombies[i].favoriteenemy == targeted_player)
			{
				zombies[i].teleporting = true;
				zombies[i] thread zombie_through_portal(portal_enter, portal_trig, targeted_player);
			}
			else if(Distance(zombies[i].origin, portal_enter.origin) < 500 && IsDefined(zombies[i].favoriteenemy) && zombies[i].favoriteenemy == targeted_player)
			{
				//IPrintLnBold("Found zombie to send through portal");
				zombies[i].teleporting = true;
				zombies[i] thread zombie_through_portal(portal_enter, portal_trig, targeted_player);
				teleporting_zombies++;
			}
		}
	}

	//IPrintLnBold("Here come ", teleporting_zombies, " zombies!");
}

zombie_through_portal(portal_enter, portal_exit, targeted_player)
{
	self endon( "death" );
	self endon( "damage" );

	//returned close to other portal, probably in labs.
	wait_network_frame();
	if(Distance(self.origin, targeted_player.origin) < 500)
	{
		self.teleporting = false;
		return;
	}

	move_speed = undefined;
	if(IsDefined(self.zombie_move_speed))
	{
		move_speed = self.zombie_move_speed;
	}

	self.ignoreall = true;
	self.goalradius = 32;
	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );
	self SetGoalPos(portal_enter.origin);

	//IPrintLnBold("zombie heading to portal");

	self.timed_out = false;
	self thread teleportation_timed_out();

	/*while(Distance(self.origin, portal_enter.origin) > self.goalradius && self.timed_out == false)
	{
		wait(0.1);
	}*/
	self waittill_any("goal", "timed_out");
	self notify("teleportation_timed_out");
	wait 1;

	if(!IsDefined(level.send_zombies_out_choke))
	{
		level.send_zombies_out_choke = false;
	}

	send_zombies_out_choke_wait();

	level thread send_zombies_out_choke();

	//IPrintLnBold("zombie followed through portal");

	if ( isDefined( self.pre_teleport_func ) )
	{
		self [[ self.pre_teleport_func ]]();
	}

	PlayFX(level._effect["transporter_start"], self.origin);
	playsoundatposition( "evt_teleporter_out", portal_enter.origin );

	final_destination = getstructarray(portal_exit.target, "targetname");
	for ( i = 0; i < final_destination.size; i++ )
	{
		if(IsDefined(final_destination[i].script_noteworthy) && final_destination[i].script_noteworthy == "zombie_pos")
		{
			portal_exit = final_destination[i];
		}
	}
	self forceteleport(portal_exit.origin + (AnglesToForward(portal_exit.angles) * RandomFloatRange(0,64)),portal_exit.angles);
	PlayFX(level._effect["transporter_beam"], portal_exit.origin);
	playsoundatposition( "evt_teleporter_go", portal_exit.origin );

	self.teleporting = false;
	self.ignoreall = false;
	self thread maps\_zombiemode_spawner::find_flesh();

	if(IsDefined(move_speed))
	{
		self.zombie_move_speed = move_speed;
	}

	if ( isDefined( self.post_teleport_func ) )
	{
		self [[ self.post_teleport_func ]]();
	}
}

//-------------------------------------------------------------------------------
//	DCS: Zombie Pentagon Pack-A-Punch System
//	Rises from level 1 to 5 then links all portals to pack-a-punch room.
//-------------------------------------------------------------------------------
pentagon_packapunch_init()
{
	level.defcon_level = 1;
	level.defcon_activated = false;
	level.ignore_spawner_func = ::pentagon_ignore_spawner;

	level thread defcon_sign_lights();

	punch_switches = GetEntArray("punch_switch","targetname");
	if(IsDefined(punch_switches))
	{
		for ( i = 0; i < punch_switches.size; i++ )
		{
			punch_switches[i] thread defcon_sign_setup();
		}
	}
}
defcon_sign_setup()
{
	self SetHintString( &"ZOMBIE_NEED_POWER" );
	self setcursorhint( "HINT_NOICON" );

	flag_wait("power_on");

	//change sign level, turn light or representation of used switch
	self.lights = GetEntArray(self.target, "targetname");
	if(IsDefined(self.lights))
	{
		for ( j = 0; j < self.lights.size; j++ )
		{
			if(IsDefined(self.lights[j].script_noteworthy) && self.lights[j].script_noteworthy == "defcon_bulb")
			{
				self.lights[j] SetModel("zombie_trap_switch_light_on_green");
			}
		}
	}

	while(true)
	{
		if(level.gamemode == "survival")
		{
			self SetHintString( &"ZOMBIE_PENTAGON_DEFCON_SWITCH" );
			self waittill( "trigger", user );
		}
		self SetHintString( "" );

		if(IsDefined(self.lights))
		{
			for ( j = 0; j < self.lights.size; j++ )
			{
				if(IsDefined(self.lights[j].script_noteworthy) && self.lights[j].script_noteworthy == "defcon_bulb")
				{
					self.lights[j] SetModel("zombie_trap_switch_light_on_red");
				}
				if(IsDefined(self.lights[j].script_noteworthy) && self.lights[j].script_noteworthy == "defcon_handle")
				{
					self.lights[j] rotatepitch( -180, .5 );
					self.lights[j] playsound( "zmb_defcon_switch" );
				}
			}
		}

		if(level.defcon_level != 4)
		{
			level.defcon_level++;

			if( level.zombie_vars["zombie_powerup_bonfire_sale_on"] == false && level.gamemode == "survival" )
			{
			    level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_defcon", level.defcon_level );
      		}

			level thread defcon_sign_lights();

		}
		else
		{
			//link all portals to pack-a-punch room.
			level.defcon_level = 5;

			level thread defcon_sign_lights();

			if( level.gamemode == "survival" )
			{
				if( level.zombie_vars["zombie_powerup_bonfire_sale_on"] == false || !flag("bonfire_reset"))
				{
				    level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_defcon", level.defcon_level );
				}

				//IPrintLnBold("all portals to pack room");
				flag_set("defcon_active");

				if( level.zombie_vars["zombie_powerup_bonfire_sale_on"] == false || !flag("bonfire_reset"))
				{
				    level thread play_defcon5_alarms();
				}

				level thread pack_portal_fx_on();
			}
		}
		level waittill("pack_room_reset");

		if(!flag("bonfire_reset")) //DCS: don't want vo every time bonfire goes into effect.
		{
			level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_defcon_reset" );
		}

		if(IsDefined(self.lights))
		{
			for ( j = 0; j < self.lights.size; j++ )
			{
				if(IsDefined(self.lights[j].script_noteworthy) && self.lights[j].script_noteworthy == "defcon_bulb")
				{
					self.lights[j] SetModel("zombie_trap_switch_light_on_green");
				}
				if(IsDefined(self.lights[j].script_noteworthy) && self.lights[j].script_noteworthy == "defcon_handle")
				{
					self.lights[j] rotatepitch( 180, .5 );
					self.lights[j] playsound( "zmb_defcon_switch" );
				}
			}
		}

	}
}
//-------------------------------------------------------------------------------
// DCS 091410: moving client notifies out so can have frame waits for splitscreen.
//-------------------------------------------------------------------------------
pack_portal_fx_on()
{
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] ClearClientFlag(level.ZOMBIE_PENTAGON_PLAYER_PORTALFX);
	}
}
regular_portal_fx_on()
{
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[i] SetClientFlag(level.ZOMBIE_PENTAGON_PLAYER_PORTALFX);
	}
}
//-------------------------------------------------------------------------------

defcon_sign_lights()
{
	//change sign level, turn light or representation of used switch
	defcon_signs = GetEntArray("defcon_sign", "targetname");

	defcon[1] = "p_zom_pent_defcon_sign_01";
	defcon[2] = "p_zom_pent_defcon_sign_02";
	defcon[3] = "p_zom_pent_defcon_sign_03";
	defcon[4] = "p_zom_pent_defcon_sign_04";
	defcon[5] = "p_zom_pent_defcon_sign_05";


	if(IsDefined(defcon_signs))
	{
		for ( i = 0; i < defcon_signs.size; i++ )
		{
			if(IsDefined(level.defcon_level))
			{
				defcon_signs[i] SetModel(defcon[level.defcon_level]);
			}
			else
			{
				defcon_signs[i] SetModel(defcon[1]);
			}
		}
	}
}

//-------------------------------------------------------------------------------
start_defcon_countdown()
{
	if(level.defcon_activated)
	{
		return;
	}

	//set adjacency for one way war room to cenference room.
	if(level.zones["war_room_zone_south"].is_enabled)
	{
		if(!flag("war_room_entry"))
		{
			flag_set("war_room_entry");
		}
	}
	else
	{
		if(!flag("war_room_special"))
		{
			flag_set("war_room_special");
		}
	}

	// special spawning and cleanup for pack room.
	level thread special_pack_time_spawning();
	level thread special_pack_cleanup();

	//open pack-a-punch hideaway.
	flag_set("open_pack_hideaway");

	level.defcon_activated = true;
	level.defcon_countdown_time = 30;

	while(level.defcon_level > 1)
	{
		wait(level.defcon_countdown_time /4);
		level.defcon_level--;

		level thread defcon_sign_lights();
	}

	level.defcon_level = 1;
	flag_clear("defcon_active");
	level.defcon_activated = false;

	level thread regular_portal_fx_on();

	flag_clear("bonfire_reset");
	level notify("defcon_reset");

	//	DCS: fix to make certain player didn't pop into pack room as was clearing.
	//	will reopen door.
	wait(2.0);
	if(!is_packroom_clear())
	{
		level notify("player_in_pack");
	}
}

//-------------------------------------------------------------------------------
special_pack_time_spawning()
{
	// no pack room spawning until level2
	flag_set("no_pack_room_spawning");
	maps\_zombiemode_zone_manager::reinit_zone_spawners();

	while(level.defcon_level >= 3)
	{
		wait(0.1);
	}
	flag_clear("no_pack_room_spawning");
	maps\_zombiemode_zone_manager::reinit_zone_spawners();
}
special_pack_cleanup()
{
	while(flag("defcon_active"))
	{
		wait(1);
	}

	// Now clear the room of left over zombies.
	while(!is_packroom_clear())
	{
		wait_network_frame();
	}

	level thread clear_zombies_in_packroom();
}

//-------------------------------------------------------------------------------
defcon_pack_poi()
{
	zone_name = "conference_level2";
	players = get_players();
	poi1 = GetEnt("pack_room_poi1", "targetname");
	poi2 = GetEnt("pack_room_poi2", "targetname");

	wait(0.5);
	num_players = maps\_zombiemode_zone_manager::get_players_in_zone( zone_name, true );

	if(num_players == get_number_of_valid_players())
	{
		if(level.zones["war_room_zone_south"].is_enabled)
		{
			poi1 activate_zombie_point_of_interest();
		}
		else
		{
			poi2 activate_zombie_point_of_interest();
		}
	}
	else
	{
		return;
	}

	while(num_players == get_number_of_valid_players() && flag("defcon_active"))
	{
		num_players = maps\_zombiemode_zone_manager::get_players_in_zone( zone_name, true );
		wait (0.1);
	}

	poi1 deactivate_zombie_point_of_interest();
	poi2 deactivate_zombie_point_of_interest();

}
//-------------------------------------------------------------------------------
// DCS 090110: check floors for no player when teleporting.
//-------------------------------------------------------------------------------
check_if_empty_floors()
{
	num_floor1 = 0;
	num_floor2 = 0;
	num_floor3 = 0;

	num_floor1_laststand = 0;
	num_floor2_laststand = 0;
	num_floor3_laststand = 0;

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		players[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( players[i] );
		if(players[i].floor == 1)
		{
			num_floor1++;
			if(players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator")
			{
				num_floor1_laststand++;
			}
		}
		else if(players[i].floor == 2 )
		{
			num_floor2++;
			if(players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator")
			{
				num_floor2_laststand++;
			}
		}
		else if(players[i].floor == 3)
		{
			num_floor3++;
			if(players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator")
			{
				num_floor3_laststand++;
			}
		}
	}

	// now see if need to delete zombies.
	zombies = GetAIArray("axis");
	if(!IsDefined(zombies))
	{
		return;
	}

	for (i = 0; i < zombies.size; i++)
	{
		zombies[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( zombies[i] );

		// leave thief zombie alone.
		if(IsDefined(zombies[i].animname) && zombies[i].animname == "thief_zombie")
		{
			continue;
		}
		else if(IsDefined(zombies[i].teleporting) && zombies[i].teleporting == true)
		{
			continue;
		}
		else if(IsDefined(zombies[i].floor) && zombies[i].floor == 1)
		{
			if(num_floor1 == num_floor1_laststand && players.size > 1)
			{
				if(is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
				{
					zombies[i] thread send_zombies_out(level.portal_top);
				}
				else
				{
					level.zombie_total++;
					zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
				}
			}
			else if(num_floor1 == 0)
			{
				if(is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
				{
					zombies[i] thread send_zombies_out(level.portal_top);
				}
				else
				{
					level.zombie_total++;
					zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
				}
			}
			else
			{
				continue;
			}
		}
		else if(IsDefined(zombies[i].floor) && zombies[i].floor == 2)
		{
			if(num_floor2 == num_floor2_laststand && players.size > 1)
			{
				if(is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
				{
					zombies[i] thread send_zombies_out(level.portal_mid);
				}
				else
				{
					level.zombie_total++;
					zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
				}
			}
			else if(num_floor2 == 0)
			{
				if(is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
				{
					zombies[i] thread send_zombies_out(level.portal_mid);
				}
				else
				{
					level.zombie_total++;
					zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
				}
			}
			else
			{
				continue;
			}
		}
		else if(IsDefined(zombies[i].floor) && zombies[i].floor == 3)
		{
			if(num_floor3 == num_floor3_laststand && players.size > 1)
			{
				if(is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
				{
					zombies[i] thread send_zombies_out(level.portal_power);
				}
				else
				{
					level.zombie_total++;
					zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
				}
			}
			else if(num_floor3 == 0)
			{
				if(is_true(zombies[i].completed_emerging_into_playable_area) && flag("power_on") && level.gamemode == "survival")
				{
					zombies[i] thread send_zombies_out(level.portal_power);
				}
				else
				{
					level.zombie_total++;
					zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
				}
			}
			else
			{
				continue;
			}
		}
		else // zombie not on known floor kill
		{
			level.zombie_total++;
			zombies[i] DoDamage(zombies[i].health + 100, zombies[i].origin);
		}
	}
}
//-------------------------------------------------------------------------------
// DCS 090310: last stand only person on floor.
// if zombies on floor where only player is in last stand
// we need to get zombies out of sight  and teleport or delete them.
//-------------------------------------------------------------------------------
send_zombies_out(portal)
{
	self notify("send_zombies_out");
	self endon("send_zombies_out");
	self endon("death");

	move_speed = undefined;
	if(IsDefined(self.zombie_move_speed))
	{
		move_speed = self.zombie_move_speed;
	}

	self.ignoreall = true;
	self.teleporting = true;
	self.goalradius = 32;

	self notify( "stop_find_flesh" );
	self notify( "zombie_acquire_enemy" );
	self SetGoalPos(portal.origin);

	self.timed_out = false;
	self thread teleportation_timed_out();

	/*while(Distance(self.origin, portal.origin) > self.goalradius && self.timed_out == false)
	{
		wait(0.1);
	}*/
	self waittill_any("goal", "timed_out");
	self notify("teleportation_timed_out");
	wait 1;

	if(!IsDefined(level.send_zombies_out_choke))
	{
		level.send_zombies_out_choke = false;
	}

	send_zombies_out_choke_wait();

	level thread send_zombies_out_choke();

	PlayFX(level._effect["transporter_start"], self.origin);
	playsoundatposition( "evt_teleporter_out", self.origin );
	if(portal == level.portal_pack)
	{
		// send to warroom mid first, then check floors.
		self forceteleport(level.portal_mid.origin + (AnglesToForward(level.portal_mid.angles) * RandomFloatRange(0,32)),level.portal_mid.angles);
		PlayFX(level._effect["transporter_beam"], level.portal_mid.origin);
		playsoundatposition( "evt_teleporter_go", level.portal_mid.origin);

		self thread cleanup_unoccupied_floor(move_speed);
	}
	else
	{
		self thread cleanup_unoccupied_floor(move_speed);
	}
}

teleportation_timed_out()
{
	self notify("teleportation_timed_out");
	self endon("teleportation_timed_out");
	self endon("death");

	time = 0;
	while(IsDefined(self) && !self.timed_out && time < 15 )
	{
		wait(1);
		time++;
	}
	if(IsDefined(self))
	{
		self.timed_out = true;
		self notify("timed_out");
	}
}

send_zombies_out_choke()
{
	level.send_zombies_out_choke = true;

	wait .1;

	level.send_zombies_out_choke = false;
}

send_zombies_out_choke_wait()
{
	while(level.send_zombies_out_choke)
	{
		wait_network_frame();
	}
}
//-------------------------------------------------------------------------------
// DCS 090410:	send zombie on unoccupied floor to occupied floor
//							or back into array.
//-------------------------------------------------------------------------------

cleanup_unoccupied_floor(move_speed,current_floor,next_floor)
{
	self endon( "death" );
	self notify("teleporting");

	// even if defined could have changed.
	self.floor = maps\_zombiemode_ai_thief::thief_check_floor( self );
	self maps\_zombiemode_spawner::reset_attack_spot();

	// should have been covered before, just making sure.
	if(IsDefined(self.animname) && self.animname == "thief_zombie")
	{
		return;
	}

	num_floor1 = 0;
	num_floor2 = 0;
	num_floor3 = 0;
	num_floor1_laststand = 0;
	num_floor2_laststand = 0;
	num_floor3_laststand = 0;
	pos_num = 0;
	teleport_pos = [];

	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[i].floor = maps\_zombiemode_ai_thief::thief_check_floor( players[i] );

		//now check number in each floor
		if(players[i].floor == 1)
		{
			num_floor1++;
			if(players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator")
			{
				num_floor1_laststand++;
			}
		}
		else if(players[i].floor == 2)
		{
			num_floor2++;
			if(players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator")
			{
				num_floor2_laststand++;
			}
		}
		else if(players[i].floor == 3)
		{
			num_floor3++;
			if(players[i] maps\_laststand::player_is_in_laststand() || players[i].sessionstate == "spectator")
			{
				num_floor3_laststand++;
			}
		}
	}

	if(flag("power_on")) //teleport them through portals.
	{
		if(num_floor3 > 0 && num_floor3 != num_floor3_laststand && self.floor != 3)
		{
			num = RandomIntRange(0, level.portal_bottom.size);

			self forceteleport(level.portal_bottom[num].origin + (AnglesToForward(level.portal_bottom[num].angles) * RandomFloatRange(0,32)),level.portal_bottom[num].angles);
			PlayFX(level._effect["transporter_beam"], level.portal_bottom[num].origin);
			playsoundatposition( "evt_teleporter_go", level.portal_bottom[num].origin);
		}
		else if(num_floor2 > 0  && num_floor2 != num_floor2_laststand && self.floor != 2)
		{
			self forceteleport(level.portal_mid.origin + (AnglesToForward(level.portal_mid.angles) * RandomFloatRange(0,32)),level.portal_mid.angles);
			PlayFX(level._effect["transporter_beam"], level.portal_mid.origin);
			playsoundatposition( "evt_teleporter_go", level.portal_mid.origin);
		}
		else if(num_floor1 > 0  && num_floor1 != num_floor1_laststand && self.floor != 1)
		{
			self forceteleport(level.portal_top.origin + (AnglesToForward(level.portal_top.angles) * RandomFloatRange(0,32)),level.portal_top.angles);
			PlayFX(level._effect["transporter_beam"], level.portal_top.origin);
			playsoundatposition( "evt_teleporter_go", level.portal_top.origin);
		}

		self.teleporting = false;
		self.ignoreall = false;
		self thread maps\_zombiemode_spawner::find_flesh();

		if(IsDefined(move_speed))
		{
			self.zombie_move_speed = move_speed;
		}

	}
	else // will pop all but quads into spawn closets.
	{
		self.teleporting = false;

		if(!IsDefined(self.animname) || self.animname != "quad_zombie")
		{
			if(self.health == level.zombie_health) // can cause problems teleporting everyone into spawn closets.
			{
				level.zombie_total++;
				if(IsDefined(self.fx_quad_trail))
				{
					self.fx_quad_trail Delete();
				}
				self maps\_zombiemode_spawner::reset_attack_spot();

				self notify("zombie_delete");
				self Delete();
			}
			else if(IsDefined(next_floor) && IsDefined(current_floor)) // if using elevator send to next floor
			{
				if(next_floor == 3 && current_floor == 2)
				{
					teleport_pos = getstructarray("elevator1_down_hidden", "targetname");
				}
				else if(next_floor == 2 && current_floor == 3)
				{
					teleport_pos = getstructarray("elevator1_up_hidden", "targetname");
				}
				else if(next_floor == 2 && current_floor == 1)
				{
					teleport_pos = getstructarray("elevator2_down_hidden", "targetname");
				}
				else if(next_floor == 1 && current_floor == 2)
				{
					teleport_pos = getstructarray("elevator2_up_hidden", "targetname");
				}
			}
			else // send to other occupied floors.
			{
				if(num_floor3 > 0  && num_floor3 != num_floor3_laststand && self.floor != 3)
				{
					teleport_pos = getstructarray("elevator1_down_hidden", "targetname");
				}
				else if(num_floor2 > 0  && num_floor2 != num_floor2_laststand && self.floor != 2)
				{
					teleport_pos = getstructarray("elevator2_down_hidden", "targetname");
					//IPrintLnBold("teleport to war room");
				}
				else if(num_floor1 > 0  && num_floor1 != num_floor1_laststand && self.floor != 1)
				{
					teleport_pos = getstructarray("elevator2_up_hidden", "targetname");
					//IPrintLnBold("teleport to offices");
				}
				else
				{
					return;
				}
			}

			if(IsDefined(teleport_pos))
			{
				pos_num = RandomIntRange(0,teleport_pos.size);
				self forceteleport(teleport_pos[pos_num].origin + (RandomFloatRange(0,22), RandomFloatRange(0,22), 0),teleport_pos[pos_num].angles);
			}

			// now reset zombie to tear through barricade.
			wait(1);
			if(IsDefined(self))
			{
				self.ignoreall = true;
				self notify( "stop_find_flesh" );
				self notify( "zombie_acquire_enemy" );

				wait_network_frame();
				if(IsDefined(self.target))
				{
					self.target = undefined;
				}
				self thread maps\_zombiemode_spawner::zombie_think();
			}
		}
		// deleting quads leaves their effect, must delete fx.
		else if(IsDefined(self.animname) &&  self.animname == "quad_zombie")
		{
			level.zombie_total++;
			if(IsDefined(self.fx_quad_trail))
			{
				self.fx_quad_trail Delete();
			}
			self notify("zombie_delete");
			self Delete();
		}
		else
		{
			level.zombie_total++;
			self maps\_zombiemode_spawner::reset_attack_spot();

			self notify("zombie_delete");
			self Delete();
		}
	}
}

//-------------------------------------------------------------------------------
// DCS 090210: turn on/off portal wires.
//-------------------------------------------------------------------------------
teleporter_power_cable()
{
	cable_on = GetEnt("teleporter_link_cable_on","targetname");
	cable_off = GetEnt("teleporter_link_cable_off","targetname");

	cable_on Hide();

	flag_wait( "power_on" );

	cable_off Hide();
	cable_on Show();
}

//-------------------------------------------------------------------------------
// DCS: copy of ignore spawner functio.
//-------------------------------------------------------------------------------
pentagon_ignore_spawner( spawner )
{
	if ( flag( "no_pack_room_spawning" ) )
	{
		if (spawner.targetname == "conference_level2_spawners" )
		{
			return true;
		}
	}
	if ( flag( "no_warroom_elevator_spawning" ) )
	{
		if (spawner.targetname == "war_room_zone_elevator_spawners" )
		{
			return true;
		}
	}
	if ( flag( "no_labs_elevator_spawning" ) )
	{
		if (spawner.targetname == "labs_elevator_spawners" )
		{
			return true;
		}
	}
	return false;
}

play_defcon5_alarms()
{
    structs = getstructarray( "defcon_alarms", "targetname" );
    sound_ent = [];

    for(i=0;i<structs.size;i++)
    {
        sound_ent[i] = Spawn( "script_origin", structs[i].origin );
        sound_ent[i] PlayLoopSound( "zmb_defcon_alarm", .25 );
    }

    level waittill( "defcon_reset" );

    for(i=0;i<sound_ent.size;i++)
    {
        sound_ent[i] StopLoopSound( .5 );
    }

    wait(1);

    array_delete( sound_ent );
}
