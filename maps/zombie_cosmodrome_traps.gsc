#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_traps;
#include maps\_zombiemode_utility;


//
init_funcs()
{
	// ww: centrifuge is going to be random
	// level._zombiemode_trap_activate_funcs[ "centrifuge" ]	= ::centrifuge_activate;

	//level._zombiemode_trap_activate_funcs[ "rocket" ]		= ::trap_activate_rocket;
	//level._zombiemode_trap_use_funcs[ "rocket" ]			= ::trap_use_rocket;

}

//*****************************************************************************
//	Initialize cosmodrome specific traps
//*****************************************************************************
init_traps()
{

	// The rocket is no longer a trap
	level thread rocket_init();

	// Centrifuge trap
	level thread centrifuge_init();

	level thread door_firetrap_init();

}


//*****************************************************************************
// Attach the claw pieces to the moving arm
//*****************************************************************************
claw_attach( arm, claw_name )
{
	claws = GetEntArray(claw_name, "targetname");
	for(i = 0 ; i < claws.size; i++)
	{
		claws[i] LinkTo(arm);
	}
}



//*****************************************************************************
// detach the claw pieces to the moving arm
//*****************************************************************************
claw_detach( arm, claw_name )
{
	claws = GetEntArray(claw_name, "targetname");
	for(i = 0 ; i < claws.size; i++)
	{
		claws[i] unlink();
	}
}



//*****************************************************************************
// Rocket Trap initialize the parts
//*****************************************************************************
rocket_init()
{

	flag_wait("all_players_spawned");
	wait(1);

	// DCS: rocket bracing claws init
	retract_l	= GetStruct("claw_l_retract",	"targetname");
	retract_r	= GetStruct("claw_r_retract",	"targetname");
	extend_l	= GetStruct("claw_l_extend",	"targetname");
	extend_r	= GetStruct("claw_r_extend",	"targetname");

	level.claw_retract_l_pos	= retract_l.origin;
	level.claw_retract_r_pos	= retract_r.origin;
	level.claw_extend_l_pos		= extend_l.origin;
	level.claw_extend_r_pos		= extend_r.origin;

	level.gantry_l = getent("claw_arm_l","targetname");
	level.gantry_r = getent("claw_arm_r","targetname");

	level.claw_arm_l = GetEnt( "claw_l_arm", "targetname" );
	claw_attach( level.claw_arm_l, "claw_l" );

	level.claw_arm_r = GetEnt( "claw_r_arm", "targetname" );
	claw_attach( level.claw_arm_r, "claw_r" );

	//rocket
	level.rocket = GetEnt("zombie_rocket", "targetname");
	rocket_pieces = getentarray( level.rocket.target, "targetname" );
	for ( i = 0; i < rocket_pieces.size; i++ )
	{
		rocket_pieces[i] setforcenocull();
		rocket_pieces[i] linkto( level.rocket );
	}

	// Lifter
	level.rocket_lifter = GetEnt( "lifter_body", "targetname" );
	lifter_pieces = GetEntArray( level.rocket_lifter.target, "targetname" );
	for ( i = 0; i < lifter_pieces.size; i++ )
	{
		lifter_pieces[i] linkto( level.rocket_lifter );
	}

	level.rocket_lifter_arm = GetEnt( "lifter_arm", "targetname" );
	level.rocket_lifter_clamps = GetEntArray( "lifter_clamp", "targetname" );
	for ( i = 0; i < level.rocket_lifter_clamps.size; i++ )
	{
		level.rocket_lifter_clamps[i] linkto( level.rocket_lifter_arm );
	}

	// Rocket attaches to the arm, arm attaches to the lifter
	level.rocket linkto( level.rocket_lifter_arm );
	level.rocket_lifter_arm linkto ( level.rocket_lifter );

	level thread rocket_move_ready( );

	level thread rocket_spotlight_init();

}


//*****************************************************************************
// Move the rocket into vertical position
//*****************************************************************************
rocket_move_ready( )
{
	start_spot	= GetStruct( "rail_start_spot",	"targetname" );
	dock_spot	= GetStruct( "rail_dock_spot",	"targetname" );

	// DCS: move new claws.
	level.claw_arm_r MoveTo(level.claw_retract_r_pos, 0.05);
	level.claw_arm_l MoveTo(level.claw_retract_l_pos, 0.05);

	level.rocket_lifter MoveTo( start_spot.origin, 0.05 );
	level.rocket_lifter waittill("movedone");

	// Need to unlink the arm from the lifter when you want to rotate it.
	//	Otherwise it won't rotate
	level.rocket_lifter_arm unlink();
	level.rocket_lifter_arm RotateTo( (13, 0, 0), 0.05 );
	level.rocket_lifter_arm waittill("rotatedone");

	//unlink all the linked pieces of the rocket and lifter
	unlink_rocket_pieces();

	// Wait for power to turn on.
	level waittill("power_on");

	// Wait for the sounds to settle
	wait(5.0);

	link_rocket_pieces();

	level.rocket_lifter_arm linkto( level.rocket_lifter );

	// move rocket into position after power.
	level.rocket_lifter MoveTo( dock_spot.origin, 10, 3, 3 );

	// Shawn J  - Sound - adding sound to rocket rolling
	level.rocket_lifter playsound( "evt_rocket_roll" );

	//wait( 16.0 );
	level.rocket_lifter waittill("movedone");

	//unlink
	level.rocket_lifter_arm unlink();

	// Start it in vertical position
	rocket_move_vertical();

	unlink_rocket_pieces();

}

//
// Spotlights for the rocket
//
rocket_spotlight_init()
{

	level waittill( "rocket_lights_on" );

	exploder(5501); //- Low level 1 lights
	wait(randomfloatrange(1,2));
	exploder(5502); //- Mid level 2 lights
	wait(randomfloatrange(1,2));
	exploder(5503); //- High level 3 lights


}

//*****************************************************************************
// Move the rocket into vertical position
//*****************************************************************************
rocket_move_vertical()
{

	// Shawn J  - Sound - adding sound to rocket moving into position
	//iprintlnbold( "rocket setting up!" );
	level thread rocket_arm_sounds();

	level.rocket_lifter_arm RotateTo( (90, 0, 0), 15, 3, 5 );
	wait( 16.0 );

	// Disconntect the rocket
	level.rocket unlink();

	// Drop the rocket into place
	level.rocket MoveZ( -20, 3 );

	// DCS: move new claws in.
	// Steve G movement sound
	level.claw_arm_r playsound("evt_rocket_claw_arm");
	level.claw_arm_r MoveTo(level.claw_extend_r_pos, 3.0);
	level.claw_arm_l MoveTo(level.claw_extend_l_pos, 3.0);

	level thread maps\zombie_cosmodrome_amb::play_cosmo_announcer_vox( "vox_ann_rocket_anim" );

	wait( 3 );

}

// DCS: move lifter arm back out of the way.
move_lifter_away()
{
		start_spot	= GetStruct( "rail_start_spot",	"targetname" );

		// Disconntect the rocket
		level.rocket_lifter_arm linkto( level.rocket_lifter );

		// Move and rotate the arm at the same time
		offset = level.rocket_lifter_arm.origin - level.rocket_lifter.origin;
		level.rocket_lifter_arm unlink();
		level.rocket_lifter_arm RotateTo( (0, 0, 0), 15 );
		level.rocket_lifter_arm MoveTo( start_spot.origin + offset, 15, 3, 3 );
		level.rocket_lifter MoveTo( start_spot.origin, 15, 3, 3 );
		wait(15.0);

		//detach the claws
		claw_detach( level.claw_arm_l, "claw_l" );
		claw_detach( level.claw_arm_r, "claw_r" );


	//	level.rocket_lifter_arm unlink();
}


////*****************************************************************************
//// Move the rocket into horizontal position
////*****************************************************************************
//rocket_move_horizontal( )
//{
//
//	// Lift the rocket back up
//	level.rocket MoveZ( 20, 3 );
//	wait( 4 );
//
//	// Connect the rocket
//	level.rocket linkto( level.rocket_lifter_arm );
//
//	// Shawn J  - Sound - adding sound to rocket moving into position
//	//iprintlnbold( "rocket setting up!" );
//	level.rocket_lifter_arm playsound( "evt_rocket_set_main" );
//
//	// DCS: move new claws.
//	level.claw_arm_r MoveTo(level.claw_retract_r_pos, 3.0);
//	level.claw_arm_l MoveTo(level.claw_retract_l_pos, 3.0);
//
//	level.rocket_lifter_arm RotateTo( (0, 0, 0), 15, 3, 5 );
//	wait( 15.0 );
//
//}

////*****************************************************************************
////	This controls the electric traps in the level
////		self = use trigger associated with the trap
////		trap = trap trigger entity
////*****************************************************************************
//trap_use_rocket( trap )
//{
//	while(1)
//	{
//		//wait until someone uses the valve
//		self waittill("trigger",who);
//
//		if( who in_revive_trigger() )
//		{
//			continue;
//		}
//
//		if( is_player_valid( who ) )
//		{
//			// Don't do anything if the rocket isn't in position
//			if ( level.rocket.status == "moving" || level.rocket.status == "activated" )
//			{
//				continue;
//			}
//
//			// Move it if it's not in the right spot
//			if ( IsDefined(self.script_string) && self.script_string != level.rocket.status )
//			{
//				if ( self.script_string == "vertical" && level.rocket.status == "horizontal" )
//				{
//					self rocket_move_vertical();
//					continue;
//				}
//				else if ( self.script_string == "horizontal" && level.rocket.status == "vertical" )
//				{
//					self rocket_move_horizontal();
//					continue;
//				}
//			}
//
//			if ( trap._trap_in_use || level.rocket.status == "cooldown" )
//			{
//				continue;
//			}
//
//			players = get_players();
//			if ( players.size == 1 && who.score >= trap.zombie_cost )
//			{
//				// solo buy
//				who maps\_zombiemode_score::minus_to_player_score( trap.zombie_cost );
//				can_purchase = true;
//			}
//			else if( level.team_pool[ who.team_num ].score >= trap.zombie_cost )
//			{
//				// team buy
//				who maps\_zombiemode_score::minus_to_team_score( trap.zombie_cost );
//				can_purchase = true;
//			}
//			else if( level.team_pool[ who.team_num ].score + who.score >= trap.zombie_cost )
//			{
//				// team funds + player funds
//				team_points = level.team_pool[ who.team_num ].score;
//				who maps\_zombiemode_score::minus_to_player_score( trap.zombie_cost - team_points );
//				who maps\_zombiemode_score::minus_to_team_score( team_points );
//			}
//			else
//			{
//				continue;
//			}
//
//			trap._trap_in_use = 1;
//
//			play_sound_at_pos( "purchase", who.origin );
//
//			if ( trap._trap_switches.size )
//			{
//				trap thread maps\_zombiemode_traps::trap_move_switches();
//				//need to play a 'woosh' sound here, like a gas furnace starting up
//				trap waittill("switch_activated");
//			}
//
//			update_rocket_status( "activated" );
//
//			//this trigger detects zombies who need to be smacked
//			trap trigger_on();
//
//			//start the movement
//			trap thread [[ trap._trap_activate_func ]]();
//			//wait until done and then clean up and cool down
//			trap waittill("trap_done");
//
//			update_rocket_status( "cooldown" );
//
//			//turn the damage detection trigger off until the trap is used again
//			trap trigger_off();
///#
//			if ( GetDvarInt( #"zombie_cheat" ) >= 1 )
//			{
//				self._trap_cooldown_time = 5;
//			}
//#/
//			wait( trap._trap_cooldown_time );
//
//			//COLLIN: Play the 'alarm' sound to alert players that the traps are available again (playing on a temp ent in case the PA is already in use.
//			//speakerA = getstruct("loudspeaker", "targetname");
//			//playsoundatposition("warning", speakera.origin);
//			trap notify("available");
//			update_rocket_status( "available" );
//
//			trap._trap_in_use = 0;
//		}
//	}
//}


//
// Fire the rockets
//		self = the damage trigger for the trap, also the main entity with the trap info.
//
//trap_activate_rocket()
//{
//	self._trap_duration = 40;
//	self._trap_cooldown_time = 60;
//
///#
//	if ( GetDvarInt( #"zombie_cheat" ) >= 1 )
//	{
//		self._trap_cooldown_time = 5;
//	}
//#/
//	// Kick off the client side FX structs
//	number = Int( self.script_string );
//	if ( number != 0 )
//	{
//		Exploder( number );
//	}
//	else
//	{
//		clientnotify( self.script_string+"1" );
//	}
//
//	// Kick off audio
//	fx_points = getstructarray( self.target,"targetname" );
//	for( i=0; i<fx_points.size; i++ )
//	{
//		wait_network_frame();
//		fx_points[i] thread maps\_zombiemode_traps::trap_audio_fx(self);
//	}
//
//	// Shawn J  - Sound - adding sound to rocket fire
//	self playloopsound( "evt_rocket_fire", 1 );
//
//	// Do the damage
//	self thread rocket_trap_damage();
//
//	earthquake( .25, self._trap_duration, self.origin, 1000 );
//	wait( self._trap_duration );
//
//	// Shawn J  - Sound - stopping sound for rocket fire
//	self stoploopsound( 2 );
//
//	// Shut down
//	self notify ("trap_done");
//	clientnotify(self.script_string +"0");	// turn off FX
//}


//
//	This handles anyone stepping into the damage trigger
//		self = the damage trigger for the trap, also the main entity with the trap info.
//
//rocket_trap_damage()
//{
//	self endon( "trap_done" );
//
//	while(1)
//	{
//		self waittill( "trigger", ent );
//
//		// Is player standing in the electricity?
//		if( isplayer(ent) )
//		{
//			ent setburn( 0.4 );  // ww: disable until the material is fixed
//			// ent dodamage( 2, ent.origin+(0,0,20) );
//			self thread trigger_thread( ent, ::rocket_trap_player_damage, undefined );	// Self == The trigger.
//		}
//		else
//		{
//			if(!isDefined(ent.marked_for_death))
//			{
//				ent.marked_for_death = true;
////				ent thread zombie_trap_death( self, 100 );
//
//				if ( !IsDefined( ent.fire_damage_func ) )
//				{
//					ent thread rocket_death( self );
//				}
//				else
//				{
//					ent [[ ent.fire_damage_func ]]( self );
//				}
//			}
//		}
//	}
//}

//
//  This hanles damaging the player when they are inside the triggers under teh rocket trap
//
//rocket_trap_player_damage( guy, str_endon )
//{
//	if( IsDefined( str_endon ) )
//	{
//		self endon( str_endon );
//	}
//
//	while( guy IsTouching( self ) )
//	{
//		guy DoDamage( 2, guy.origin+(0,0,20) );
//		wait( 0.2 );
//	}
//
//}


//
//	This is what happens to zombies who enter the rocket trap
//	self is the AI entity that entered the trigger
////
//rocket_death( trap )
//{
//	level.burning_zombies[level.burning_zombies.size] = self;
//	self thread maps\_zombiemode_traps::zombie_flame_watch();
//	self playsound("ignite");
//	self thread animscripts\zombie_death::flame_death_fx();
//	wait( randomfloat(1.0) );
//
//	self StartRagdoll();
//	direction_vector = (0,0,-5);
//	if(isDefined(trap.trap_fx_structs))
//	{
//		direction_vector = vector_scale( AnglesToForward( trap._trap_fx_structs[0].angles + (RandomIntRange(-50,-28),0,0) ), 120 );
//	}
//	self launchragdoll( direction_vector );
//	wait_network_frame();
//
//	// Make sure they're dead...physics launch didn't kill them.
//	self.a.gib_ref = "head";
//	self dodamage(self.health, self.origin, trap);
//}


//
//
centrifuge_init()
{
	// awards should be allocated along a 360 degree wheel.
	// ww TODO: remove this functionality
	level.spinner_awards = [];
	spinner_add_award(   0,   5, "jackpot" );
	spinner_add_award(  85,  95, "double_points" );
	spinner_add_award( 175, 185, "zero" );
//	spinner_add_award( 265, 275, "powerup" );
	spinner_add_award( 265, 275, "double_points" );
	spinner_add_award( 355, 359, "jackpot" );

	// Get Centrifuge trigger
	centrifuge_trig = GetEnt( "trigger_centrifuge_damage", "targetname" );
	centrifuge_trap = GetEnt( "rotating_trap_group1", "targetname" );

	// ww: client flag for centrifuge (allows csc to perform rumble
	level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_RUMBLE = 8;
	level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_LIGHTS = 11;

	// attached the trigger for damage
	centrifuge_trig EnableLinkTo();
	centrifuge_trig LinkTo( centrifuge_trap );


	// Link the collision to the centrifuge
	centrifuge_collision_brush = GetEnt( "rotating_trap_collision", "targetname" );
	/#
	AssertEx( IsDefined( centrifuge_collision_brush.target ), "collision missing target" );
	#/
	centrifuge_collision_brush LinkTo( GetEnt( centrifuge_collision_brush.target, "targetname" ) );


	// Link the origins needed for sound to play on the ends of the model
	tip_sound_origins = GetEntArray( "origin_centrifuge_spinning_sound", "targetname" );
	array_thread( tip_sound_origins, ::centrifuge_spinning_edge_sounds );

	flag_wait( "all_players_connected" );

	if(level.gamemode == "survival")
	{
		// warning lights on
		centrifuge_trap SetClientFlag( level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_LIGHTS );

		// Now power down

		wait(4);
		centrifuge_trap RotateYaw( 720, 10.0, 0.0, 4.5 );
	    //centrifuge_trap playloopsound( "zmb_cent_mach_loop", .6 );
		centrifuge_trap waittill( "rotatedone" );
		//centrifuge_trap stoploopsound( 2 );
		centrifuge_trap playsound( "zmb_cent_end" );

		// warning lights off
		centrifuge_trap ClearClientFlag( level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_LIGHTS );
	}

	level thread centrifuge_random();

}


//#####################################################################
//	Centrifuge trap
//#####################################################################
centrifuge_activate()
{
	self._trap_duration = 30;
	self._trap_cooldown_time = 60;
/#
	if ( GetDvarInt( #"zombie_cheat" ) >= 1 )
	{
		self._trap_cooldown_time = 5;
	}
#/
	// Do the damage
	centrifuge = self._trap_movers[0];
	old_angles = centrifuge.angles;
	self thread maps\_zombiemode_traps::trig_update( centrifuge );

	//Shawn J Sound - power up sound for centrifuge
	//self playsound ("zmb_cent_start");

	for ( i=0; i<self._trap_movers.size; i++ )
	{
		self._trap_movers[i] RotateYaw( 360, 5.0, 4.5 );
	}
	wait( 2.0 );

	self thread centrifuge_damage();
	wait( 3.0 );

	// Spin full rotations as long as we can
	//Shawn J Sound - loop sound for centrifuge
	self playloopsound ("zmb_cent_mach_loop", .6);

	step = 3.0;
	for (t=0; t<self._trap_duration; t=t+step )
	{
		for ( i=0; i<self._trap_movers.size; i++ )
		{
			self._trap_movers[i] RotateYaw( 360, step );
		}
		wait( step );
	}

	// Spin to the angle we're going to end at
	end_angle = RandomInt( 360 );
	curr_angle = Int(centrifuge.angles[1]) % 360;
	if ( end_angle < curr_angle )
	{
		end_angle += 360;
	}
	degrees = end_angle - curr_angle;
	if ( degrees > 0 )
	{
		time = degrees / 360 * step;
		for ( i=0; i<self._trap_movers.size; i++ )
		{
			self._trap_movers[i] RotateYaw( degrees, time );
		}
		wait( time );
	}


	//Shawn J Sound - power down sound for centrifuge
	self stoploopsound (2);
	self playsound ("zmb_cent_end");

	// Set it up to go for 5 seconds, but interrupt it at 4 so it goes to the precise angle we need.
	for ( i=0; i<self._trap_movers.size; i++ )
	{
		self._trap_movers[i] RotateYaw( 360, 5.0, 0.0, 4.0 );
	}
	wait( 5.0 );

	self notify( "trap_done" );

	//
	for ( i=0; i<self._trap_movers.size; i++ )
	{
		self._trap_movers[i] RotateTo( (0, end_angle%360, 0), 1.0, 0.0, 0.9);
	}
	wait(1.0);

	self PlaySound( "zmb_cent_lockdown" );

	// Pick a prize
//	self centrifuge_award_prize( end_angle );

	// Shut down
	self notify( "kill_counter_end" );
//	clientnotify(self.script_string +"0");	// turn off FX
}

//*****************************************************************************
// Random activation of the centrifuge
//*****************************************************************************
centrifuge_random()
{
	// objects
	centrifuge_model = GetEnt( "rotating_trap_group1", "targetname" );
	centrifuge_damage_trigger = GetEnt( "trigger_centrifuge_damage", "targetname" );

	// save the start angles
	centrifuge_start_angles = centrifuge_model.angles;

	while( true )
	{
		// randomize centrifuge so it has the chance of missing a round
		/*malfunction_for_round = RandomInt( 10 );
		if( malfunction_for_round > 6 )
		{
			level waittill( "between_round_over" ); // this will wait for the next time a round starts
		}
		else if( malfunction_for_round == 1 )
		{
			level waittill( "between_round_over" ); // this will wait for the next time a round starts
			level waittill( "between_round_over" ); // this will wait for the next time a round starts
		}*/

		wait( RandomIntRange( 24, 120 ) );

		// figure out the roatation amount
		rotation_amount = RandomIntRange( 3, 7 ) * 360;

		// how much time will it take to rotate?
		wait_time = RandomIntRange( 4, 7 );

		// activation warning
		level centrifuge_spin_warning( centrifuge_model );

		// set client flag for rumble
		centrifuge_model SetClientFlag( level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_RUMBLE );

		// rotate the centrifuge
		centrifuge_model RotateYaw( rotation_amount, wait_time, 1.0, 2.0 );

		// start the damage
		centrifuge_damage_trigger thread centrifuge_damage();

		//C. Ayers: Start the sound
		//centrifuge_model playsound ("zmb_cent_start");

		wait( 3.0 );

		// Spin full rotations as long as we can

		// track when the fuge should start slowing down in order to change the sound
		// wait time minus the spin up and spin down times
		slow_down_moment = wait_time - 3;
		if( slow_down_moment < 0 )
		{
			slow_down_moment = Abs( slow_down_moment );
		}
		centrifuge_model stoploopsound (4);
		centrifuge_model playsound ("zmb_cent_end");
		wait( slow_down_moment );

		//Shawn J Sound - power down sound for centrifuge

		centrifuge_model waittill( "rotatedone" );
		centrifuge_damage_trigger notify( "trap_done" );
		centrifuge_model PlaySound( "zmb_cent_lockdown" );

		// warning lights on
		centrifuge_model ClearClientFlag( level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_LIGHTS );

		//for( i = 0; i < red_lights_fx.size; i++ )
		//{
		//	red_lights_fx[i] Unlink();
		//}

		//array_delete( red_lights_fx );

		// clear client flag for rumble
		centrifuge_model ClearClientFlag( level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_RUMBLE );
	}

}

centrifuge_spin_warning( ent_centrifuge_model )
{
	// create the fx parts
	//centrifuge_warning_lights = [];
	//for( i = 0; i < ent_centrifuge_model._fx_spots_lights.size; i++ )
	//{
	//	temp_mdl = Spawn( "script_model", ent_centrifuge_model GetTagOrigin( ent_centrifuge_model._fx_spots_lights[i] ) );
	//	temp_mdl.angles = ent_centrifuge_model GetTagAngles( ent_centrifuge_model._fx_spots_lights[i] );
	//	temp_mdl SetModel( "tag_origin" );
	//	temp_mdl LinkTo( ent_centrifuge_model, ent_centrifuge_model._fx_spots_lights[i] );
	//	PlayFXOnTag( level._effect[ "centrifuge_warning_light" ], temp_mdl, "tag_origin" );
	//	centrifuge_warning_lights = add_to_array( centrifuge_warning_lights, temp_mdl, false );
	//}

	// count down
	// 3
	// warning lights on
	ent_centrifuge_model SetClientFlag( level._SCRIPTMOVER_COSMODROME_CLIENT_FLAG_CENTRIFUGE_LIGHTS );
	ent_centrifuge_model playsound ( "zmb_cent_alarm" );
	ent_centrifuge_model PlaySound( "vox_ann_centrifuge_spins_1" );
	wait( 1.0 );

	// 2 & 1
	ent_centrifuge_model playsound ( "zmb_cent_start" );
	//exhuast fx
	// PlayFXOnTag( level._effect[ "centrifuge_start_steam" ], centrifuge_steam_spot, "tag_origin" );
	//for( i = 0; i < ent_centrifuge_model._fx_spots_steam.size; i++ )
	//{
	//	PlayFXOnTag( level._effect[ "centrifuge_start_steam" ], ent_centrifuge_model, ent_centrifuge_model._fx_spots_steam[i] );
	//}
	wait( 2.0 );

	// 0
	//C. Ayers: Play the looper
	ent_centrifuge_model playloopsound ("zmb_cent_mach_loop", .6);
	wait( 1.0 );


	//return centrifuge_warning_lights;
}


//*****************************************************************************
// Damage things that touch the damage trigger
//*****************************************************************************
centrifuge_damage()
{
	self endon( "trap_done" );

	// ww: Hack which allows the trigger to use zombie_trap_death even through it didn't go through trap init
	self._trap_type = self.script_noteworthy;
	players = getplayers();

	while(1)
	{
		self waittill( "trigger", ent );

		if( isplayer(ent) && !ent maps\_laststand::player_is_in_laststand() )
		{
			ent thread centrifuge_player_damage(self);
		}
		else
		{
			if(!isDefined(ent.marked_for_death))
			{
//				self._kill_count++;
				ent.marked_for_death = true;
				closest_player = get_closest_player(ent.origin);
				ent thread maps\_zombiemode_traps::zombie_trap_death( self, randomint(100), closest_player );
				ent PlaySound( "zmb_cent_zombie_gib" );
			}
		}
	}
}

centrifuge_player_damage(centrifuge)
{
	self endon("death");
	self endon("disconnect");

	if(IsDefined(self.touching_centrifuge) && self.touching_centrifuge)
	{
		return;
	}

	if(!self maps\_laststand::player_is_in_laststand())
	{
		RadiusDamage(self.origin + (0, 0, 5), 10, 100, 100, undefined, "MOD_UNKNOWN");
		self SetStance( "crouch" );
	}

	self.touching_centrifuge = true;
	while(self IsTouching(centrifuge))
	{
		wait_network_frame();
	}
	self.touching_centrifuge = false;
}

//*****************************************************************************
// Link the origins that need to play sound durring spinning, also track when the fuge is spinning
//*****************************************************************************
centrifuge_spinning_edge_sounds()
{
	/#
	AssertEx( IsDefined( self.target ), "origin is missing a target to link to" );
	#/

	// leave the function if the origin has no target
	if( !IsDefined( self.target ) )
	{
		return;
	}

	// link the origin to the target
	self LinkTo( GetEnt( self.target, "targetname" ) );

	// while loop so the sound can play each time the spinning starts
	while( true )
	{
		// wait for the flag to start sound
		flag_wait( "fuge_spining" );

		// play sound
		self PlayLoopSound( "zmb_cent_close_loop", .5 );

		// wait for spinning to end
		flag_wait( "fuge_slowdown" );

		self StopLoopSound( 2 );

		// avoid any infinite loop issues
		wait( 0.05 );
	}
}


//
//	Initialize the countdown
//
kill_counter()
{
	// Play initiate sound
	players = GetPlayers();
	for (i=0; i<players.size; i++ )
	{
		players[i] playlocalsound( "zmb_laugh_child" );
	}

	level.kill_counter_hud = create_counter_hud();

	// Random number flipping to setup the counter
	level.kill_counter_hud FadeOverTime( 1.0 );
	level.kill_counter_hud.alpha = 1;

	// Note: First 2 stages will be number flipping
	num_stages = 3;		// Only 1 digit counter
	if ( IsDefined( self.counter_10s ) )
	{
		num_stages = 4;	// 2-digit
	}
	else
	{
		num_stages = 5;	// 3-digit
	}

	time_per_stage = 1.0;	// how long to take for each phase
	steps = time_per_stage * num_stages / 0.1;		// 0.1 is the interval
	steps_per_stage = steps / num_stages;
	stage_num = 1;
	ones = 0;
	tens = 0;
	hundreds = 0;

	for (i=0; i<steps; i++ )
	{
		if ( i > steps_per_stage * stage_num )
		{
			stage_num++;
		}

		// 1s
		if ( num_stages - stage_num == 0 )
		{
			ones = self._kill_count % 10;
		}
		else
		{
			ones = i % 10;
		}
		self.counter_1s set_counter( ones );

		// 10s
		if ( IsDefined( self.counter_10s ) )
		{
			if ( num_stages - stage_num <= 1 )
			{
				tens = int( self._kill_count / 10 );
			}
			else
			{
				tens = i % 10;
			}
			self.counter_10s set_counter( tens );
		}

		if ( IsDefined( self.counter_100s ) )
		{
			if ( num_stages - stage_num <= 1 )
			{
				hundreds = int( self._kill_count / 100 );
			}
			else
			{
				hundreds = i % 10;
			}
			self.counter_100s set_counter( hundreds );
		}

		level.kill_counter_hud SetValue( hundreds*100 + tens*10 + ones );
		wait (0.1);
	}

	self thread kill_counter_update();
	self waittill( "kill_counter_end" );

	level.kill_counter_hud FadeOverTime( 1.0 );
	level.kill_counter_hud.alpha = 0;
 	wait(1.0);

	level.kill_counter_hud destroy_hud();
}


//
//	Update the hud and physical counters.
//
kill_counter_update()
{
	self endon( "kill_counter_end" );

	if ( !IsDefined( level.kill_counter_hud ) )
	{
		return;
	}

	// Now keep track of how many kills
	while ( 1 )
	{
		if ( IsDefined( self.counter_10s ) )
		{
			self.counter_1s set_counter( self._kill_count % 10 );
		}
		if ( IsDefined( self.counter_10s ) )
		{
			self.counter_10s set_counter( int( self._kill_count / 10 ) );
		}
		if ( IsDefined( self.counter_100s ) )
		{
			self.counter_100s set_counter( int( self._kill_count / 100 ) );
		}
		level.kill_counter_hud SetValue( self._kill_count );

		level waittill( "zom_kill" );
	}
}


//
//	Add a prize slot on the wheel
//
spinner_add_award( start_angle, end_angle, prize )
{
	index = level.spinner_awards.size;
	level.spinner_awards[ index ] = SpawnStruct();
	level.spinner_awards[ index ].name			= prize;
	level.spinner_awards[ index ].start_angle	= start_angle;
	level.spinner_awards[ index ].end_angle		= end_angle;
}


rocket_arm_sounds()
//play sounds off of rocket arm
{
	level.rocket_lifter playsound( "evt_rocket_set_main" );
	wait(13.8);
	level.rocket_lifter playsound( "evt_rocket_set_impact" );
}

door_firetrap_init()
{
	flag_init("base_door_opened");
	door_trap = undefined;
	traps = GetEntArray( "zombie_trap", "targetname" );
	for( i = 0; i < traps.size; i++ )
	{
		if(IsDefined(traps[i].script_string) && traps[i].script_string == "f2")
		{
			door_trap = traps[i];
			door_trap trap_set_string( &"ZOMBIE_NEED_POWER" );
		}
	}

	flag_wait("power_on");

	if(!flag("base_entry_2_north_path"))
	{
		door_trap trap_set_string( &"REIMAGINED_DOOR_CLOSED" );
	}
	flag_wait("base_entry_2_north_path");

	flag_set("base_door_opened");
}


unlink_rocket_pieces()
{
//		// DCS: rocket bracing claws init
//	retract_l	= GetStruct("claw_l_retract",	"targetname");
//	retract_r	= GetStruct("claw_r_retract",	"targetname");
//	extend_l	= GetStruct("claw_l_extend",	"targetname");
//	extend_r	= GetStruct("claw_r_extend",	"targetname");
//
//	level.claw_retract_l_pos	= retract_l.origin;
//	level.claw_retract_r_pos	= retract_r.origin;
//	level.claw_extend_l_pos		= extend_l.origin;
//	level.claw_extend_r_pos		= extend_r.origin;

//	level.gantry_l = getent("claw_arm_l","targetname");
//	level.gantry_r = getent("claw_arm_r","targetname");

//	level.claw_arm_l = GetEnt( "claw_l_arm", "targetname" );
	claw_detach( level.claw_arm_l, "claw_l" );

	//level.claw_arm_r = GetEnt( "claw_r_arm", "targetname" );
	claw_detach( level.claw_arm_r, "claw_r" );

	//rocket
//	level.rocket = GetEnt("zombie_rocket", "targetname");
	rocket_pieces = getentarray( level.rocket.target, "targetname" );
	for ( i = 0; i < rocket_pieces.size; i++ )
	{
		//rocket_pieces[i] setforcenocull();
		rocket_pieces[i] unlink();//( level.rocket );
	}

	// Lifter
	//level.rocket_lifter = GetEnt( "lifter_body", "targetname" );
	lifter_pieces = GetEntArray( level.rocket_lifter.target, "targetname" );
	for ( i = 0; i < lifter_pieces.size; i++ )
	{
		lifter_pieces[i] unlink();//( level.rocket_lifter );
	}

	//level.rocket_lifter_arm = GetEnt( "lifter_arm", "targetname" );
	level.rocket_lifter_clamps = GetEntArray( "lifter_clamp", "targetname" );
	for ( i = 0; i < level.rocket_lifter_clamps.size; i++ )
	{
		level.rocket_lifter_clamps[i] unlink();//( level.rocket_lifter_arm );
	}

}

link_rocket_pieces()
{

	claw_attach( level.claw_arm_l, "claw_l" );

	level.claw_arm_r = GetEnt( "claw_r_arm", "targetname" );
	claw_attach( level.claw_arm_r, "claw_r" );

	// level.rocket = GetEnt("zombie_rocket", "targetname");
	rocket_pieces = getentarray( level.rocket.target, "targetname" );
	for ( i = 0; i < rocket_pieces.size; i++ )
	{
		//rocket_pieces[i] setforcenocull();
		rocket_pieces[i] linkto( level.rocket );
	}

	// Lifter
	//level.rocket_lifter = GetEnt( "lifter_body", "targetname" );
	lifter_pieces = GetEntArray( level.rocket_lifter.target, "targetname" );
	for ( i = 0; i < lifter_pieces.size; i++ )
	{
		lifter_pieces[i] linkto( level.rocket_lifter );
	}

	//level.rocket_lifter_arm = GetEnt( "lifter_arm", "targetname" );
	level.rocket_lifter_clamps = GetEntArray( "lifter_clamp", "targetname" );
	for ( i = 0; i < level.rocket_lifter_clamps.size; i++ )
	{
		level.rocket_lifter_clamps[i] linkto( level.rocket_lifter_arm );
	}

}
