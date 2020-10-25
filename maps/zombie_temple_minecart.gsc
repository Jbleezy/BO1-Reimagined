/*
*****************************************************************************
 MINECART

12/10/10 - completed prototype
12/15/10 - moved to main map


MIGHT TRY
=================
- Smashing through "do not enter" boards
- Jump a gap?
	
TODO
=================
- Detail pass
- Sound pass
- FX pass
- Lock & lerp players into specific locations
- Gate opens once vehicle gets into position
- Better integration with rest of level
	- Fix killbrush
	- Make enter area better integrated into map
	- Make exit area better integrated into map
	- Clear out cliff area for better vista view
	- Add visibility into playable tunnel spaces
- Reset
	- Wait for all players to be out
	- Start moving
	- Reach teleport node and jump back to start
	- Maybe pause for a while?
	- Reenable lever
	
*****************************************************************************
*/
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_utility_raven;


precache_assets()
{
	level._effect["fx_headlight"]  		= LoadFx("env/light/fx_flashlight_ai_spotlight");
//	level._effect["fx_spark_wheel"]			  		= LoadFx("env/electrical/fx_elec_wire_spark_dl_oneshot");

	PrecacheModel("rv_vehicle_zombie_minecart_reverse");

	precacherumble( "tank_rumble" );
	precacherumble( "damage_heavy" );
}

minecart_main()
{
	flag_init("players_riding_minecart");
	
	level.minecart_levers = GetEntArray("minecart_lever_trigger", "targetname");
	for (i=0; i<level.minecart_levers.size; i++)
	{
		level.minecart_levers[i] Hide();
		level.minecart_levers[i] thread minecart_lever_think();
	}

	if ( GetDvar("minecart_debug") == "" ) 
	{
		SetDvar("minecart_debug", "0");
	}

}




/*
*****************************************************************************
Minecart Vehicle
*****************************************************************************
*/
minecart_setup()
{
	self.drivepath      = false;
	self.accel 			= 5;
	self.decel 			= 30;
	//self.maxSpeed		= 60; //Max speed from GDT
	self.loopingPath	= IsDefined(self.script_string) && self.script_string == "loopingPath";
	self.away 			= false;

	// Wheels turning
	self minecart_init_anims(1.0);
	
	// Setup Passengers
	//------------------
	self.passengers		= [];

	// Setup Attach Points
	//---------------------
	self.floorheight	= 24;
	self.width = 20;

	self.linkEnts		= [];
	minecart_add_linkEnt( (  50,  self.width, self.floorheight ) );		// front left
	minecart_add_linkEnt( (  50, 0 - self.width, self.floorheight ) );		// front right
	minecart_add_linkEnt( ( -66,  self.width, self.floorheight ) );		// back left
	minecart_add_linkEnt( ( -66, 0 - self.width, self.floorheight ) );		// back right
	minecart_add_linkEnt( (  -8,   0, self.floorheight ) );		// center 
	
	// Add FX & Sounds
	//-----------------
	self.headlights_offset = ( 87,    0,  15);
	self.headlights_angles = (0,0,0);

	self.headlights_offset_reverse = (0 - self.headlights_offset[0], self.headlights_offset[1], self.headlights_offset[2]);
	self.headlights_angles_reverse = (0,180,0);

	//self.headLights 	= SpawnAndLinkFXToOffset(level._effect["fx_headlight"], 	self, self.headlights_offset, ( 0, 0, 0));
	
 	//Can't set max speed at runtime because it causes SRE when playing XBL
	//self SetVehMaxSpeed( self.maxSpeed );

	//Activate Switch
	self.start_switch = GetEnt(self.targetname + "_start_switch", "targetname");
	
	// bind the clip cage to the minecart
	self.cage = GetEnt(self.targetname + "_cage", "targetname");
	if ( IsDefined(self.cage) )
	{
		self.cage LinkTo(self);
	}

	// get the door as well
	self.cage_door = GetEnt(self.targetname + "_cage_door", "targetname");
	if ( IsDefined(self.cage_door) )
	{
		self.cage_door LinkTo(self);
		self.cage_door NotSolid();
	}

	self.door = GetEnt(self.targetname + "_door", "targetname");
	if ( IsDefined(self.door) ) 
	{
		self.door.closed = true;
		self.door.clip = GetEnt(self.targetname + "_door_clip", "targetname");
		
		//Start with cage open
		self thread _minecart_open_door(1.0);
	}

	self.pusher = GetEnt(self.targetname + "_pusher", "targetname");
	if ( IsDefined(self.pusher) ) 
	{
		self.pusher.out = false;
	}

	self.floor = GetEnt(self.targetname + "_floor", "targetname");
	if ( IsDefined(self.floor) )
	{
		self.floor LinkTo(self);
	}

	self.front = GetEnt(self.targetname + "_front", "targetname");
	if ( IsDefined(self.front) )
	{
		self.front LinkTo(self);
	}
	
	self.front_doors = GetEntArray(self.targetname + "_front_door", "targetname");
	self.front_doors_closed = true;
	self.front_doors_clip = GetEnt(self.targetname + "_front_door_clip", "targetname");
	
	self.start_volume = GetEnt(self.targetname + "_start_volume", "targetname");
	if( IsDefined(self.start_volume) )
	{
		self.start_volume.minecart = self;
		self.start_volume thread show_players_on_mine_cart();
	}
	
	self.trigger_splash = GetEnt( "trigger_minecart_water_splash", "targetname" );
	if ( IsDefined( self.trigger_splash ) )
	{
		self.trigger_splash thread minecart_trigger_splash_think();
	}

	//spawn speakers
	self.speaker_left = Spawn( "script_model", self.origin );//maps\_zombiemode_net::network_safe_spawn( "minecart_speaker_left", 1, "script_model", self.origin );
	self.speaker_left setmodel("tag_origin");
	self.speaker_left LinkTo(self, "tag_origin", (0,32.0,40.0));

	wait_network_frame();
	self.speaker_right = Spawn( "script_model", self.origin );//maps\_zombiemode_net::network_safe_spawn( "minecart_speaker_left", 1, "script_model", self.origin );
	self.speaker_right setmodel("tag_origin");
	self.speaker_right LinkTo(self, "tag_origin", (0,-32.0,40.0));

	//Mine cart blocks are broken the first time the minecart runs
	blockers = GetEntArray(self.targetname + "_blocker", "targetname");
	array_thread(blockers, ::blocker_init, self);

	// maybe make this per minecart ? -- only care if there are ever more than one minecart, which there currently isn't
	level.minecart_force_zone_active = false;

	// get to the start spot
	self minecart_begin_path("start");
	self minecart_stop();

}

blocker_init(minecart)
{
	self.unbroken = getEnt(self.target, "targetname");
	self.broken = getEnt(self.unbroken.target, "targetname");
//	self.struct_fx = getstruct(self.broken.target, "targetname");
	
	if(isDefined(self.broken))
	{
		self.broken hide();
	}
	
	self thread blocker_think(minecart);
}

blocker_think(minecart)
{
	minecart endon("minecart_end");
	minecart waittill("minecart_start");
	
	while(1)
	{
		if(self blocker_is_mine_cart_touching(minecart))
		//if(self blocker_is_any_player_touching())
		{
			self thread blocker_break();
			break;
		}

		wait .05;
	}	
}
blocker_is_mine_cart_touching(minecart)
{
	dist2 = distance2dsquared(minecart.origin, self.origin);
	return dist2<70*70;
}
blocker_is_any_player_touching()
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(players[i] isTouching(self))
		{
			return true;
		}
	}
	return false;
}

blocker_break()
{
	//Play Fx
	self.unbroken Delete();
	self.broken show();
//	fwd = anglestoforward( self.broken.angles );
//	PlayFX( level._effect["barrier_break"], self.broken.origin, fwd );
	exploder(400);
	self PlaySound( "evt_minecart_barrier" );
}

minecart_add_linkEnt( offsetOrigin )
{
	linkEnt =  Spawn("script_model", (0,0,0));
	linkEnt.offsetOrigin = offsetOrigin;
	linkEnt LinkTo(self, "", linkEnt.offsetOrigin, (0,0,0));
	linkEnt SetModel("tag_origin_animate");	
	
	linkEnt.occupied = false;

	self.linkEnts[ self.linkEnts.size ] = linkEnt;
	wait_network_frame();
}


minecart_link_passengers(activator)
{
	wait(0.5);

	players = GetPlayers();

	if ( IsDefined(self.cage_door) ) 
	{
		self.cage_door Solid();
	}

	// make sure all link ents are available
	for ( i = 0; i < self.linkEnts.size; i++ )
	{
		self.linkEnts[i].claimed = false;
	}

	linkPlayers = [];

	// find the closest link to to each player
	for ( p = 0; p < players.size; p++ )
	{
		player = players[p];

		closestEnt = undefined;
		closestDist = 0.0;

		playerNear = self minecart_contains(player) || player == activator;
		if ( !playerNear )
		{
			continue;
		}

		linkPlayers[linkPlayers.size] = player;

		for ( e = 0; e < self.linkEnts.size; e++ )
		{
			linkEnt = self.linkEnts[e];
			dist = DistanceSquared(player.origin, linkEnt.origin);

			if ( !linkEnt.claimed && (!IsDefined(closestEnt) || dist < closestDist) )
			{
				closestEnt = linkEnt;
				closestDist = dist;
			}
		}

		closestEnt.claimed = true;
		player.minecart_link = closestEnt;
	}

	array_thread( linkPlayers, ::player_minecart_ride, self );
	level thread delayed_player_response_to_minecart_ride( linkPlayers );
	
	//Link Zombies
	zombies = GetAiSpeciesArray( "axis", "all" ); 
	zombie_sort = get_array_of_closest( self.origin, zombies, undefined, undefined, 300.0 );
	self.linkZombies = [];
	for(i=0;i<zombie_sort.size;i++)
	{
		zombie = zombie_sort[i];

		closestEnt = undefined;
		closestDist = 0.0;

		if(zombie.animname == "monkey_zombie")
		{
			continue;
		}
		
		if(is_true(zombie.shrinked))
		{
			continue;
		}
		
		zombieNear = self minecart_contains(zombie);
		if ( !zombieNear )
		{
			continue;
		}

		for ( e = 0; e < self.linkEnts.size; e++ )
		{
			linkEnt = self.linkEnts[e];
			dist = DistanceSquared(zombie.origin, linkEnt.origin);

			if ( !linkEnt.claimed && (!IsDefined(closestEnt) || dist < closestDist) )
			{
				closestEnt = linkEnt;
				closestDist = dist;
			}
		}

		if(isDefined(closestEnt))
		{
			closestEnt.claimed = true;
			zombie.minecart_link = closestEnt;
			
			self.linkZombies[self.linkZombies.size] = zombie;
		}
	}
	
	array_thread( self.linkZombies, ::zombie_minecart_ride, self );
}

player_minecart_ride(minecart)
{
	self endon("death");
	self endon("disconnect");
	level endon("minecart_end");

	self.is_on_minecart = true;
	
	self AllowSprint(false);

	turn_angle = 360;
	pitch_up = 90;
	pitch_down = 75;

	self StartCameraTween( 1.0 );

	if ( self maps\_laststand::player_is_in_laststand() )
	{
		// teleport the player onto the minecart
		self SetOrigin(self.minecart_link.origin);

		while ( self maps\_laststand::player_is_in_laststand() ) 
		{
			wait(0.1);
		}

		self StartCameraTween(1.0);
	}
	else
	{
		self EnableInvulnerability();
		self playerLinkToMineCart(360);
		wait(1.0);
	}

	//Allow player to look around
	self EnableInvulnerability();
	self playerLinkToMineCart(360);
	
	self thread minecart_screen_shake();
}

zombie_minecart_ride(minecart)
{
	level endon("minecart_end");
	
	self setplayercollision(0);
	self linkto(self.minecart_link, "tag_origin", (0,0,0), (0,0,0));
	self waittill("death");
	self unlink();
	
}

minecart_screen_shake(activeTime)
{
	self endon("death");
	self endon("disconnect");
	self endon( "minecart_exit" );
	self PlayRumbleLoopOnEntity( "tank_rumble" );
	while( 1 )
	{
		Earthquake( RandomFloatRange(0.1, 0.2), RandomFloatRange(1, 2), self.origin, 100, self );
		wait( RandomFloatRange( 0.1, 0.3 ) );
	}
}

playerLinkToMineCart(view_yaw)
{
	if(!self maps\_laststand::player_is_in_laststand())
	{
		self SetStance( "crouch" );
		self AllowStand( false );
		self AllowProne( false );
	}

	self PlayerLinkToDelta( self.minecart_link, "tag_origin", 1, view_yaw, view_yaw, 90, 75, true );

}

minecart_unlink_passengers( throw_velocity )
{
	self notify("minecart_end");
	level notify("minecart_end");

	if ( IsDefined(self.front) )
	{
		self.front NotSolid();
	}

	players = GetPlayers();
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( IsDefined(player.minecart_link) )
		{
			player Unlink();
			player setvelocity( throw_velocity );
			player.minecart_link = undefined;
			player.is_on_minecart = false;


			inLastStand = player maps\_laststand::player_is_in_laststand();
			if ( !inLastStand )
			{
				player AllowCrouch(true);
				player AllowProne(true);
				player AllowLean(true);
				player AllowStand(true);
				player SetStance("stand");
			}

			player AllowSprint(true);

			//player DisableInvulnerability();
		}
	}
}

minecart_throw_zombie(zombie, vel, activator)
{
	if(!isDefined(zombie))
	{
		return;
	}
	
	zombie StartRagdoll();
	zombie launchragdoll(vel);
	wait_network_frame();
	
	//level.zombie_total++; //Add the zombies back
	
	if(isDefined(zombie))
	{
		zombie.trap_death = true;
		zombie.no_powerups = true;
		zombie dodamage(zombie.health + 666, zombie.origin, activator);
	}
}

minecart_contains(ent)
{
	// TODO: make this function smarter, use an attached volume or something
	if(isDefined(self.start_volume))
	{
		return ent isTouching(self.start_volume);
	}
	else
	{
		return (distance2d(ent.origin, self.origin) < 120.0);
	}
}

//	Kill anything near the minecart
_minecart_nuke(activator)
{
	zombies = get_ai_touching_volume( "axis", self.targetname + "_start_volume", self.start_volume );

	for (i = 0; i < zombies.size; i++)
	{
		//wait (randomfloatrange(0.05, 0.1));
		if( !IsDefined( zombies[i] ) )
		{
			continue;
		}
		if( isDefined(zombies[i].minecart_link))
		{
			continue;
		}
		
		//level.zombie_total++; //Add the zombies back

		zombies[i].trap_death = true;
		zombies[i].no_powerups = true;
		zombies[i] dodamage( zombies[i].health + 100, zombies[i].origin, activator );
	}
}

_minecart_fire_spikemores()
{
	if ( !isdefined( level.spikemores ) || level.spikemores.size <= 0 )
	{
		return;
	}
	
	//fire off all spikemores sitting on the minecart
	minecart_spikemores = [];
	
	//NOTE: max 8 traces if 4 players placed 2 spikemores each.  if I had access to getgroundent or if IsTouching worked for spikemores, I wouldn't have to do this...
	for (i = 0; i < level.spikemores.size; i++)
	{
		if ( !isdefined( level.spikemores[i] ) )
		{
			continue;
		}
		trace = groundtrace( level.spikemores[i].origin, level.spikemores[i].origin+(0,0,-24), false, level.spikemores[i] );
		if( IsDefined( trace[ "entity" ] ) )
		{
			if ( self == trace[ "entity" ] || (IsDefined( self.floor) && self.floor == trace[ "entity" ]) )
			{
				minecart_spikemores = array_add( minecart_spikemores, level.spikemores[i] );
			}
		}
	}
	if ( minecart_spikemores.size )
	{
		//array_delete( minecart_spikemores );
		//the below method causes QNANs in Release...
		array_thread( minecart_spikemores, ::minecart_spikemore_detonate );
	}
}

#using_animtree("fxanim_props_dlc4");
minecart_init_anims(anim_scale)
{	
	self UseAnimTree(#animtree);
	self.animname = "minecart";
	level.scr_anim[self.animname]["wheels_turn"][0] = %fxanim_zom_ztem_minecart_wheels_anim;
	self.wheel_spin_scale = anim_scale;
}

minecart_spikemore_detonate()
{
	self maps\_zombiemode_spikemore::_spikemore_SmallSpearActivate();
}

	
minecart_begin_path(name)
{
	node = GetVehicleNode(self.targetname + "_" + name, "targetname");

	if ( IsDefined(node) )
	{
		self maps\_vehicle::getonpath( node );
		self thread maps\_vehicle::gopath();
	}
}

minecart_start(accel, backwards)
{
	if(!IsDefined(backwards))
	{
		backwards = false;
	}

	self notify("minecart_start");
	if ( !IsDefined(accel) )
	{
		accel = self.accel;
	}
	if(backwards)
	{
		self SetSpeed(5, accel);
	}
	else
	{
		self ResumeSpeed( accel );
	}
	self thread minecart_animate_wheels();
}

minecart_animate_wheels()
{
	self endon("death");
	// vehicles use generic anim commands
	if(!isDefined(self.wheel_spin_scale))
	{
		self.wheel_spin_scale = 1.0;
	}
	
	wheel_anim = level.scr_anim[ self.animname ][ "wheels_turn" ][ 0 ];
	self SetAnimKnobRestart( wheel_anim, 1, 0.2, self.wheel_spin_scale );
	self waittill("wheels_turn_stop");
	self clearanim(wheel_anim, 1.0);
}

minecart_stop(accel, decel)
{
	if ( !IsDefined(accel) )
	{
		accel = self.accel;
	}
	if ( !IsDefined(decel) )
	{
		decel = self.decel;
	}

	self SetSpeed( 0, accel, decel );
	self notify("wheels_turn_stop");
}

minecart_stop_instant()
{
	self SetSpeed(0,10000);
	self notify("wheels_turn_stop");
}



/*
*****************************************************************************
Minecart Lever
*****************************************************************************
*/
minecart_lever_move( to_on_position )
{
	play_sound_at_pos( "grab_metal_bar", self.origin );	// TEMP
	
	if (self.makeInvisible)
	{
		if (to_on_position)
		{
			self setvisibletoall();
		}
		else
		{
			self setinvisibletoall();
		}
	}	
}

minecart_lever_think()
{
	level endon("fake_death");

	if( !IsDefined(self.zombie_cost) )
	{
		self.zombie_cost = 250;
	}
	self.cooldowntimer = 10.0;	// TODO: get off of dvar or something else?
	self.makeInvisible = false;
	self SetCursorHint( "HINT_NOICON" );
	self SetHintString( "" ); //No hint untill minecart is activated
	self usetriggerrequirelookat();
	self.cost = 250; // add cost amount so hint string knows what value to use

	//point of interest stuff
	minecart_poi = getent("minecart_poi","targetname");
	minecart_poi 	create_zombie_point_of_interest( undefined, 30, 0, false );
	minecart_poi thread create_zombie_point_of_interest_attractor_positions( 4, 45 );
	
	// Get The Cart
	//---------------
	if (IsDefined(self.target))
	{
		self.minecart = GetEnt(self.target, "targetname");
	}
	else	
	{
		self.minecart = GetEnt("minecart", "targetname");
	}
	self.minecart minecart_setup();
	
	// Wait For Power
	//----------------
	self minecart_lever_move( false );

	wait_for_flags = true;
	/#
		wait_for_flags = (GetDvarInt("minecart_debug") == 0);
    #/
	if ( wait_for_flags )
	{
		self SetHintString( &"ZOMBIE_NEED_POWER" );

		flag_wait("power_on");
	
		//Wait For Destination To Be Open
		//-------------------------------
		//self SetHintString( &"ZOMBIE_TEMPLE_DESTINATION_NOT_OPEN" );
		//flag_wait_any("cave_water_to_waterfall", "waterfall_to_tunnel");
	}

	wait(1.0);
	
 	level notify("mine_cart_ready");
	
	while(1)
	{
		// Wait For The Cart To Arrive In Loading Area
		//---------------------------------------------
		self minecart_lever_move( true );

		if ( IsDefined(self.minecart.cage) )
		{
			self.minecart.cage Solid();
		}
		if ( IsDefined(self.minecart.cage_door) )
		{
			self.minecart.cage_door NotSolid();
		}
		if ( IsDefined(self.minecart.front) )
		{
			self.minecart.front Solid();
		}
		
		//Set The Hint String Now
		//-----------------------
		self SetHintString( &"ZOMBIE_TEMPLE_MINECART_COST", self.zombie_cost );
		
		// Wait For A Player To Pull The Lever
		//-------------------------------------
		while (1)
		{
			self waittill( "trigger", player );
			
			if( player.score >= self.zombie_cost )
			{
				play_sound_at_pos( "purchase", self.origin );
				player maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
				break;
			}
		}
		
		flag_set("players_riding_minecart");

		level thread minecart_clean_up_corpses();
		
		self trigger_off(); // Moves the trigger down so the hint string doesn't pop up right away
		
		self SetHintString( &"ZOMBIE_TEMPLE_MINECART_UNAVAVILABLE" );
		
		if(isDefined(self.minecart.start_switch))
		{
			self.minecart.start_switch rotateRoll(180, .3, .1, .1);
			self.minecart.start_switch waittill("rotatedone");
		}
		
		//start opening front gate
		frontDoorOpenTime = 0.25;
		self.minecart thread _minecart_open_front_door(frontDoorOpenTime);
		//wait frontDoorOpenTime;
		
		self.minecart thread _minecart_fire_spikemores();
		self.minecart thread _minecart_close_door();
		self.minecart thread _minecart_pusher_out();
		
		self.minecart.away = true;
		//Removed for now
		//exploder( 10 );//minecart start fx
		
		self.minecart minecart_start();

		//play on linked ents offset to either side of the cart
		self.minecart.speaker_left PlaySound( "evt_minecart_l" );
		self.minecart.speaker_right PlaySound( "evt_minecart_r" );
		self.minecart.speaker_left playloopsound( "zmb_singing", 5 );
		
		self thread minecart_lever_move( false );

		self.minecart minecart_link_passengers(player);
		self.minecart thread _minecart_nuke(player);
		
		//Put front gate back up
		self.minecart thread _minecart_close_front_door_delay(2.0);
				
		//open the gate
		cageOpenTime = 0.5;
		self.minecart thread _minecart_open_door_delay(cageOpenTime, 2.0);
		
		//Start Zombie Spawns
		//-------------------
		//self.minecart minecart_spawn_zombies();
		should_activate_poi = check_should_activate_minecart_poi();
		self.minecart thread minecart_activate_zone();

		//Enable Zone At The End Of The Track
		//-----------------------------------
		maps\_zombiemode_zone_manager::zone_init( "waterfall_lower_zone" );
		maps\_zombiemode_zone_manager::enable_zone( "waterfall_lower_zone" );
	
		
		//all players on the minecart, the POI should be activated
		if(should_activate_poi)
		{
			minecart_poi activate_zombie_point_of_interest();
		}
		
		wait( 1.0 ); // gives the cart a second to get out of the trigger before bringing it back
		self trigger_on(); // Raises the trigger back in to play space
		
		// Wait For The Cart To Reach The Unloading Area
		//-----------------------------------------------
		self.minecart waittill( "reached_stop_point" );

		// move all the players forward a bit, since we 'crashed'
		self.minecart minecart_crash(player);
		self.minecart.speaker_left stoploopsound( 1 );

		// Kill all zombies after using minecart if zone isn't open and all players were on minecart
		if(!flag("waterfall_to_tunnel") && !flag("cave_water_to_waterfall") && maps\_zombiemode_zone_manager::get_players_in_zone("waterfall_lower_zone", true) == get_number_of_valid_players())
		{
			zombs = GetAiSpeciesArray("axis");
			for(i=0;i<zombs.size;i++)
			{
				if(zombs[i] get_current_zone() != "waterfall_lower_zone")
				{
					level.zombie_total++;
					zombs[i] DoDamage( zombs[i].health + 2000, (0,0,0) );
				}
			}
		}

		wait(1.0);
		
		flag_clear("players_riding_minecart");
		
		//turn off the POI if it was activated
		if(should_activate_poi)
		{
			minecart_poi deactivate_zombie_point_of_interest();
		}
		
		if(!GetDvarInt(#"scr_minecart_cheat"))
		{
		
			// make a vehicle for the backwards path and hide it
			backVehicle = SpawnVehicle(self.minecart.model + "_reverse", self.minecart.targetname + "_reverse", self.minecart.vehicletype, self.minecart.origin, self.minecart.angles);
			maps\_vehicle::vehicle_init(backVehicle);
			backVehicle.drivePath = false;
	
			// setup the headlights so we can massage them into the correct place
			backVehicle.headlights_offset = self.minecart.headlights_offset_reverse;
			backVehicle.headlights_angles = self.minecart.headlights_angles_reverse;
	
			// don't start the back minecart going yet
			backVehicle minecart_stop_instant();
			backVehicle minecart_begin_path("start");
			backVehicle Hide();
	
			_minecart_lerp(self.minecart, backVehicle);
			
			backVehicle minecart_init_anims(.4);
	
			backVehicle thread play_loop_sound_on_entity( "evt_minecart_climb_loop" );
			
			// put the forward minecart back in place
			self.minecart.away = false;
			self.minecart minecart_begin_path("start");
			
			// start the backwards vehicle on it's way
			backVehicle minecart_start(self.minecart.accel, true);
			backVehicle waittill("reached_stop_point");
			
	
	
			backVehicle minecart_stop(self.minecart.accel, self.minecart.decel);
	
			_minecart_lerp(backVehicle, self.minecart);
			backVehicle stop_loop_sound_on_entity( "evt_minecart_climb_loop" );
			self.minecart PlaySound("evt_spiketrap_warn");
			
			backVehicle Delete();
		}
		else
		{
			// put the forward minecart back in place
			self.minecart.away = false;
			self.minecart minecart_begin_path("start");
		}
		
		if(isDefined(self.minecart.start_switch))
		{
			self.minecart.start_switch rotateRoll(-180, .3, .1, .1);
			self.minecart.start_switch waittill("rotatedone");
		}
	}
}

check_should_activate_minecart_poi()
{

	all_players_riding = true;
	
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(players[i] maps\_laststand::player_is_in_laststand())
		{
			continue;
		}
		if(!is_true(players[i].is_on_minecart))
		{
			all_players_riding = false;
		}
	}
	return all_players_riding;
	
}


_minecart_lerp(start_vehicle, end_vehicle, time)
{
	model = Spawn("script_model", start_vehicle.origin);
	model SetModel(start_vehicle.model);
	model.angles = start_vehicle.angles;

	// unlink the headlights and put them on the temp model
	//start_vehicle.headlights Unlink();
	//start_vehicle.headlights LinkTo(model, "", start_vehicle.headlights_offset, start_vehicle.headlights_angles);

	start_vehicle Hide();

	// hide the transition between forwards and backwards vehicle
	model MoveTo(end_vehicle.origin, 1.0, 0.1, 0.1);
	rotateAngles = (0 - end_vehicle.angles[0], end_vehicle.angles[1] - 180, 0);
	model RotateTo(rotateAngles, 1.0, 0.1, 0.1);
	model waittill("movedone");

	//start_vehicle.headlights Unlink();
	//end_vehicle.headlights = start_vehicle.headlights;
	//end_vehicle.headlights LinkTo(end_vehicle, "", end_vehicle.headlights_offset, end_vehicle.headlights_angles);

	model Delete();
	end_vehicle Show();
}

minecart_crash(activator)
{
	speed = 500.0;
	self minecart_stop_instant();  
	
	exploder(6); // minecart crash fx
	if ( IsDefined( self.trigger_splash ) )
	{
		self.trigger_splash thread minecart_trigger_splash_activate();
	}
	
	forward = AnglesToForward(self.angles);

	forwardDist = 370.0;
	throw_velocity = (forward * forwardDist) + (0,0,110);

	time = forwardDist / speed;

	players = GetPlayers();
	crashed_players = [];

	if ( IsDefined(self.front) )
	{
		self.front NotSolid();
	}
	
	//Throw off zombies
	for(i=0;i<self.linkZombies.size;i++)
	{
		self thread minecart_throw_zombie(self.linkZombies[i], throw_velocity/2, activator);
	}

	playersOnMineCart = [];
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];
		if ( !IsDefined(player.minecart_link) )
		{
			continue;
		}
		
		playersOnMineCart[playersOnMineCart.size] = player;

		crashed_players[crashed_players.size] = player;
		player notify( "minecart_exit" );
		player stoprumble( "tank_rumble" );
		player PlayRumbleOnEntity( "damage_heavy" );
		Earthquake( 0.5, 2, player.origin, 100, player );
		
		//allow player to hit the trigger_minecart_water_splash trigger for a couple seconds so we can play the splash effect on them
		player.minecart_splash_time = gettime() + 2000;
		
		// unlink the minecart link, keeping the player linked to it
		player.minecart_link Unlink();

		if(!isDefined(player getlinkedent()))
		{
			player playerLinkToMinecart(360);
		}
		//before we throw the player, make him invulnerable for a second or two to make sure they don't take damage from being thrown
		player EnableInvulnerability();
		//clear invulnerable after 2 seconds
		player delayThread( 2, ::minecart_remove_invulnerable );
		//chuck 'em out!
		player.minecart_link MoveGravity( throw_velocity, time);//MoveTo(player.minecart_link.origin + forward * forwardDist
	}

	throw_velocity = (0,0,0);
	
	wait(time*0.9-0.1);
	
	if(playersOnMineCart.size>0)
	{
		old_origin = playersOnMineCart[0].minecart_link.origin;
		wait(0.1);
		throw_velocity = (playersOnMineCart[0].minecart_link.origin-old_origin)*10;
	}
	else
	{
		wait(0.1);
	}

	
	self minecart_unlink_passengers( throw_velocity );

	wait(0.5);

	// relink the minecart links we moved
	for ( i = 0; i < self.linkEnts.size; i++ )
	{
		e = self.linkEnts[i];
		e Unlink();
		e.origin = (0,0,0);
		e LinkTo(self, "", e.offsetOrigin,(0,0,0));
	}

}

minecart_remove_invulnerable()
{
	if ( IsDefined( self ) )
	{
		self DisableInvulnerability();
	}
}

//minecart_spawn_zombies()
//{
//	
//	triggers = getEntArray("trigger_minecart_spawner", "targetname");
//	
//	for(i=0; i<triggers.size; i++)
//	{
//		triggers[i] thread _trigger_mine_cart_spawns(self);
//	}
//}
//_trigger_mine_cart_spawns(minecart)
//{
//	self waittill("trigger");
//	
//	//Are all players on the mine cart??
//	allPlayersInMineCart = true;
//	players = get_players();
//	playersNotInCart = [];
//	for(i=0;i<players.size;i++)
//	{
//		if(!isDefined(players[i].inMinecart) || players[i].inMinecart != minecart)
//		{
//			allPlayersInMineCart = false;
//			playersNotInCart[playersNotInCart.size] = players[i];
//		}
//	}
//	
//	spawner_or_poi = getEntArray(self.target, "targetname");
//	
//	for(i=0; i<spawner_or_poi.size; i++)
//	{
//		if(spawner_or_poi[i].classname == "script_origin")
//		{
//			//Only activate if everyone is riding
//			if(allPlayersInMineCart)
//			{
//				spawner_or_poi[i] _poi_toggle(minecart);
//			}
//		}
//		else
//		{
//			spawner_zone = spawner_or_poi[i] _spawner_get_zone();
//			
//			if(!isDefined(spawner_zone))
//			{
//				continue;
//			}
//			
//			//Check if there are players in the zone that are not on the mine cart
//			safeToSpawn = true;
//			for(j=0; j<playersNotInCart.size; j++)
//			{
//				if( playersNotInCart[j] _player_in_zone(spawner_zone))
//				{
//					safeToSpawn = false;
//					break;
//				}
//			}
//			
//			if( safeToSpawn )
//			{
//				zombie = spawn_zombie(spawner_or_poi[i]);
//				if(isDefined(zombie))
//				{
//					zombie.no_powerups = true;
//					zombie thread _zombie_minecart_cleanup(minecart);
//				}
//			}
//		}
//	}	
//}

//_player_in_zone(zone)
//{
//	for (i = 0; i < zone.volumes.size; i++)
//	{
//		if ( self IsTouching(zone.volumes[i]) && !(self.sessionstate == "spectator"))
//		{
//			return true;
//		}
//	}
//	
//	return false;
//}

//_zombie_minecart_cleanup(minecart)
//{
//	self endon("death");
//	minecart waittill( "reached_stop_point" );
//	
//	wait 1.0;
//	
//	//Check zombie is in an active zone
// 	if( ! self _zombie_is_touching_active_zone())
//	{
//		self DoDamage(self.health + 666, self.origin);
//	}
//	
//}

//_spawner_get_zone()
//{
//	zone = undefined;
//	keys = getarraykeys( level.zones );
//
//	for ( i = 0; i < keys.size; i++ )
//	{
//		zone = level.zones[ keys[i] ];
//		if(zone.is_active)
//		{
//			for ( j = 0; j < zone.volumes.size; j++ )
//			{
//				if ( self isTouching( zone.volumes[j] ) )
//				{
//					return zone;
//				}
//			}
//		}
//	}
//	
//	return zone;
//}

//_zombie_is_touching_active_zone()
//{
//	zone = undefined;
//	keys = getarraykeys( level.zones );
//
//	for ( i = 0; i < keys.size; i++ )
//	{
//		zone = level.zones[ keys[i] ];
//		if(zone.is_active)
//		{
//			for ( j = 0; j < zone.volumes.size; j++ )
//			{
//				if ( self isTouching( zone.volumes[j] ) )
//				{
//					return true;
//				}
//			}
//		}
//	}
//	
//	return false;
//}
//
//_poi_toggle(minecart)
//{
//	poiActive = isDefined(self.poi_active) && self.poi_active;
//
//	if( poiActive )
//	{
//		self deactivate_zombie_point_of_interest();
//	}
//	else
//	{
//		self create_zombie_point_of_interest( undefined, 10, 0, true);
//		self thread _poi_ensure_off(minecart);
//	}
//}

//Make sure the poi is turned off at the end of the minecart ride
_poi_ensure_off(minecart)
{
	minecart waittill( "reached_stop_point" );
	self deactivate_zombie_point_of_interest();
}

/////////////////////////////////////////////////////////////////////////////////////////////

minecart_activate_zone()
{
	trigger = GetEnt("force_waterfall_active", "script_noteworthy");
	if ( IsDefined(trigger) )
	{
		trigger waittill("trigger");

		level.minecart_force_zone_active = true;

		self waittill("reached_stop_point");

		level.minecart_force_zone_active = false;
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////
_minecart_open_door_delay(time, delay)
{
	wait delay;
	self thread _minecart_open_door(time);
}

_minecart_open_door(time)
{
	if ( IsDefined(self.door) )
	{
		if ( self.door.closed )
		{
			self.door MoveZ(-130, time, 0.1, 0.1);
			self.door.clip MoveZ(-130, time, 0.1, 0.1);

			self.door waittill("movedone");
			self.door.closed = false;

			self.door.clip ConnectPaths();
		}
	}
}

_minecart_close_door()
{
	if ( IsDefined(self.door) )
	{

		if ( !self.door.closed )
		{
			self.door MoveZ(130, 0.5, 0.1, 0.1);
			self.door.clip MoveZ(130, 0.1);

			self.door waittill("movedone");
			self.door.closed = true;

			self.door.clip DisconnectPaths();
		}
	}
}

_minecart_open_front_door(time)
{
	if ( self.front_doors_closed )
	{
		door = undefined;
		for(i=0;i<self.front_doors.size;i++)
		{
			door = self.front_doors[i];
			door rotateyaw(door.script_angles[1],time,0.1,0.1);
		}
		
		if(isdefined(door))
		{
			door waittill("rotatedone");
		}

		self.front_doors_closed = false;
		
		if(isDefined(self.front_doors_clip))
		{
			self.front_doors_clip notsolid();
		}
	}
}

_minecart_close_front_door()
{
	if ( !self.front_doors_closed )
	{
		if(isDefined(self.front_doors_clip))
		{
			self.front_doors_clip solid();
		}
		
		door = undefined;
		for(i=0;i<self.front_doors.size;i++)
		{
			door = self.front_doors[i];
			door rotateyaw(-1*door.script_angles[1],1.0,0.1,0.1);
		}
		
		if(isdefined(door))
		{
			door waittill("rotatedone");
		}

		self.front_doors_closed = true;
	}
}


_minecart_close_front_door_delay(delay)
{
	wait delay;
	self thread _minecart_close_front_door();
}

_minecart_pusher_out()
{
	if ( IsDefined(self.pusher) )
	{
		if ( !self.pusher.out )
		{
			wait (.3);
			self.pusher MoveY(166, 2.0, 0.25, 0.1);

			self.pusher waittill("movedone");
			self.pusher.out = true;
			
			level waittill( "minecart_returned" );
			wait(2.7);
			self thread _minecart_pusher_in();
		}
	}
}

_minecart_pusher_in()
{
	if ( IsDefined(self.pusher) )
	{
		if ( self.pusher.out )
		{
			self.pusher MoveY(-166, 4.0, 0.25, 0.1);

			self.pusher waittill("movedone");
			self.pusher.out = false;
		}
	}
}

show_players_on_mine_cart()
{
	height = 0;
	scale = getEnt("minecart1_scale", "targetname");
	if ( !isdefined( scale ) )
	{
		return;
	}
	
	//Scale starts fully extended for lighting
	scale.origin = scale.origin + (0,0,-37);
	
	level waittill("mine_cart_ready");
	
	while(1)
	{
		count = 0;
		if ( IsDefined(self.minecart) && !self.minecart.away )
		{
			players = getPlayers();
			
			//Count up the players on the mine cart
			for(i=0; i< players.size; i++)
			{
				if(players[i] isTouching(self) && players[i] IsOnGround())
				{
					count++;
				}
			}
		}
		
		if ( height < count )
		{
			while ( height < count )
			{
				play_sound_at_pos( "grab_metal_bar", self.origin );	// TEMP
				//push up
				rise = 0;
				if ( height == 3 )
				{//last push up, add a little extra
					rise = 10;
				}
				else if ( height == 0 )
				{//first one, add a little extra
					rise = 11;
				}
				else
				{
					rise = 8;
				}
				height++;
				if ( height == count )
				{//last one, going to dip/pop after this, so add 1 to rise dist
					rise += 1;
				}
				scale MoveZ(rise, 0.35, 0.05, 0);
				scale waittill("movedone");
			}
			scale MoveZ(-2, 0.2, 0, 0);
			scale waittill("movedone");
			scale MoveZ(1, 0.1, 0, 0);
			scale waittill("movedone");
		}
		else if ( height > count )
		{
			drop = 0;
			time = 0;
			pop = 2;
			dip = -1;
			while ( height > count )
			{
				if ( height == 4 )
				{//first drop
					drop += -10;
				}
				else if ( height == 1 )
				{//last drop
					drop += -11;
				}
				else
				{
					drop += -8;
				}
				time += 0.2;
				height--;
			}
			if ( height == 0 )
			{//will be settling on the bottom - fully seal
				pop = 1;
			}
			else
			{//sink a little extra so we can pop up and settle
				drop += -1;
			}
			play_sound_at_pos( "grab_metal_bar", self.origin );	// TEMP
			scale MoveZ(drop, time, 0.1, 0);
			scale waittill("movedone");

			play_sound_at_pos( "grab_metal_bar", self.origin );	// TEMP
			scale MoveZ(pop, pop*0.1, 0, 0);
			scale waittill("movedone");
			scale MoveZ(dip, Abs(dip*0.1), 0, 0);
			scale waittill("movedone");
		}
		
		wait .1;
	}
}
	
minecart_trigger_splash_activate()
{
	self trigger_on();
	wait( 3 );
	self trigger_off();
}

minecart_trigger_splash_think()
{
	while(1)
	{
		self waittill( "trigger", player );
		if ( isdefined( player ) && isdefined( player.minecart_splash_time ) && player.minecart_splash_time > gettime() )
		{
			//thrown from the minecart, play the splash
			playfx( level._effect["player_water_splash"], player.origin );
			player playsound( "fly_bodyfall_large_water" );
			//only one splash
			player.minecart_splash_time = 0;
		}
	}
}

delayed_player_response_to_minecart_ride( array )
{
	if(array.size==0)
	{
		return;
	}
	
	wait(6);
	
	player = array[randomintrange(0,array.size)];
	
	if( isdefined( player ) && isPlayer( player ) )
	{
		player thread maps\_zombiemode_audio::create_and_play_dialog( "general", "mine_ride" );
	}
}

//---------------------------------------------------------------------------
// clean up dead zombie corpses
//---------------------------------------------------------------------------
minecart_clean_up_corpses()
{
	corpse_trig = GetEnt( "minecart1_start_volume", "targetname" );
	
	corpses = GetCorpseArray();
	if( IsDefined( corpses ) )
	{
		for ( i = 0; i < corpses.size; i++ )
		{
			if( corpses[i] istouching( corpse_trig ) )
			{
				corpses[i] thread minecart_remove_corpses();
			}
		}		
	}		
}

minecart_remove_corpses()
{
	PlayFX( level._effect["corpse_gib"], self.origin );
	self Delete();
}		
