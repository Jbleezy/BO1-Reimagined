#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#using_animtree( "generic_human" );

//
//
//
init()
{
	//////////////////////////////////////////////////////////////////////////////////////
	//
	// Zombie Window and Blockers speaks between two main scripts _zombiemode_blockers
	// and _zombiemode_spawner and _zombimode _utility
	//
	//
	//
	//
	//
	//
	//
	//
	//////////////////////////////////////////////////////////////////////////////////////


	init_blockers();

//	level thread rebuild_barrier_think();

	//////////////////////////////////////////
	//designed by prod
	//set_zombie_var( "rebuild_barrier_cap_per_round", 500 );
	//////////////////////////////////////////

	if ( isdefined( level.quantum_bomb_register_result_func ) )
	{
		[[level.quantum_bomb_register_result_func]]( "open_nearest_door", ::quantum_bomb_open_nearest_door_result, 100, ::quantum_bomb_open_nearest_door_validation );
	}
}


//
//	BLOCKERS
//
init_blockers()
{
	// EXTERIOR BLOCKERS ----------------------------------------------------------------- //
	level.exterior_goals = getstructarray( "exterior_goal", "targetname" );

	for( i = 0; i < level.exterior_goals.size; i++ )
	{
		level.exterior_goals[i] thread blocker_init();
	}

	// DOORS ----------------------------------------------------------------------------- //
	zombie_doors = GetEntArray( "zombie_door", "targetname" );

	for( i = 0; i < zombie_doors.size; i++ )
	{
		zombie_doors[i] thread door_init();
	}

	// DEBRIS ---------------------------------------------------------------------------- //
	zombie_debris = GetEntArray( "zombie_debris", "targetname" );

	for( i = 0; i < zombie_debris.size; i++ )
	{
		zombie_debris[i] thread debris_init();
	}

	// Flag Blockers ---------------------------------------------------------------------- //
	flag_blockers = GetEntArray( "flag_blocker", "targetname" );

	for( i = 0; i < flag_blockers.size; i++ )
	{
		flag_blockers[i] thread flag_blocker();
	}

	// SHUTTERS --------------------------------------------------------------------------- //
	window_shutter = GetEntArray( "window_shutter", "targetname" );

	for( i = 0; i < window_shutter.size; i++ )
	{
		window_shutter[i] thread shutter_init();
	}
}


//
// DOORS --------------------------------------------------------------------------------- //
//
door_init()
{
	self.type = undefined;

	self._door_open = false;

	// Figure out what kind of door we are
	targets = GetEntArray( self.target, "targetname" );

	//CHRIS_P - added script_flag support for doors as well
	if( isDefined(self.script_flag) && !IsDefined( level.flag[self.script_flag] ) )
	{
		// Initialize any flags called
		if( IsDefined( self.script_flag ) )
		{
			tokens = Strtok( self.script_flag, "," );
			for ( i=0; i<tokens.size; i++ )
			{
				flag_init( self.script_flag );
			}
		}
	}

	// Door trigger types
	if ( !IsDefined( self.script_noteworthy ) )
	{
		self.script_noteworthy = "default";
	}

	//MM Consolidate type codes for each door into script_string
	self.doors = [];
	for(i=0;i<targets.size;i++)
	{
		targets[i] door_classify( self );
	}

	//AssertEx( IsDefined( self.type ), "You must determine how this door opens. Specify script_angles, script_vector, or a script_noteworthy... Door at: " + self.origin );
	cost = 1000;
	if( IsDefined( self.zombie_cost ) )
	{
		cost = self.zombie_cost;
	}

	self SetCursorHint( "HINT_NOICON" );

	// MM (03/09/10) - Allow activation at any time in order to make it easier to open bigger doors.
//	self UseTriggerRequireLookAt();
	self thread door_think();

	// MM - Added support for electric doors.  Don't have to add them to level scripts
	if ( IsDefined( self.script_noteworthy ) )
	{
		if ( self.script_noteworthy == "electric_door" || self.script_noteworthy == "electric_buyable_door" )
		{
			self sethintstring(&"ZOMBIE_NEED_POWER");
//			self set_door_unusable();
			if( isDefined( level.door_dialog_function ) )
			{
				self thread [[ level.door_dialog_function ]]();
			}
			return;
		}
		else if ( self.script_noteworthy == "kill_counter_door" )
		{
			self sethintstring(&"ZOMBIE_DOOR_ACTIVATE_COUNTER", cost);
//			self thread add_teampot_icon();
			return;
		}
	}

	self set_hint_string( self, "default_buy_door_" + cost );
//	self thread add_teampot_icon();
}

//
//	Help fix-up doors not using script_string and also to reclassify non-door entities.
//
door_classify( parent_trig )
{
	if ( IsDefined(self.script_noteworthy) && self.script_noteworthy == "clip" )
	{
		parent_trig.clip = self;
		parent_trig.script_string = "clip";
	}
	else if( !IsDefined( self.script_string ) )
	{
		if( IsDefined( self.script_angles ) )
		{
			self.script_string = "rotate";
		}
		else if( IsDefined( self.script_vector ) )
		{
			self.script_string = "move";
		}
	}
	else
	{
		if ( !IsDefined( self.script_string ) )
		{
			self.script_string = "";
		}

		// Handle other script_strings here
		switch( self.script_string )
		{
		case "anim":
			AssertEx( IsDefined( self.script_animname ), "Blocker_init: You must specify a script_animname for "+self.targetname );
			AssertEx( IsDefined( level.scr_anim[ self.script_animname ] ), "Blocker_init: You must define a level.scr_anim for script_anim -> "+self.script_animname );
			AssertEx( IsDefined( level.blocker_anim_func ), "Blocker_init: You must define a level.blocker_anim_func" );
			break;

		case "counter_1s":
			parent_trig.counter_1s = self;
			return;	// this is not a door element

		case "counter_10s":
			parent_trig.counter_10s = self;
			return;	// this is not a door element

		case "counter_100s":
			parent_trig.counter_100s = self;
			return;	// this is not a door element

		case "explosives":
			if ( !IsDefined(parent_trig.explosives) )
			{
				parent_trig.explosives = [];
			}
			parent_trig.explosives[parent_trig.explosives.size] = self;
			return;	// this is not a door element
		}
	}

	if ( self.classname == "script_brushmodel" )
	{
		self DisconnectPaths();
	}
	parent_trig.doors[parent_trig.doors.size] = self;
}


//
//	Someone just tried to buy the door
//		return true if door was bought
//		NOTE: This is currently intended to be used as a non-threaded call
//	self is a door trigger
door_buy()
{
	self waittill( "trigger", who, force );

	if ( GetDvarInt( #"zombie_unlock_all") > 0 || is_true( force ) )
	{
		return true;
	}

	if( !who UseButtonPressed() )
	{
		return false;
	}

	if( who in_revive_trigger() )
	{
		return false;
	}

	if( is_player_valid( who ) )
	{
		players = get_players();
		// No pools in solo game
		if ( players.size == 1 && who.score >= self.zombie_cost )
		{
			// solo buy
			who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
		}
		else if( level.team_pool[ who.team_num ].score >= self.zombie_cost )
		{
			// team buy
			who maps\_zombiemode_score::minus_to_team_score( self.zombie_cost );
		}
		else if( level.team_pool[ who.team_num ].score + who.score >= self.zombie_cost )
		{
			// team funds + player funds
			team_points = level.team_pool[ who.team_num ].score;
			who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost - team_points );
			who maps\_zombiemode_score::minus_to_team_score( team_points );
		}
		else // Not enough money
		{
			play_sound_at_pos( "no_purchase", self.doors[0].origin );
			who maps\_zombiemode_audio::create_and_play_dialog( "general", "door_deny", undefined, 0 );
			return false;
		}

		// buy the thing
		bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type door", who.playername, who.score, level.team_pool[ who.team_num ].score, level.round_number, self.zombie_cost, self.script_flag, self.origin );
	}

	return true;
}


//
//	Open a delay door once the time has expired
//	self is a door
door_delay()
{
	// Show explosives
	if ( IsDefined( self.explosives ) )
	{
		for ( i=0; i<self.explosives.size; i++ )
		{
			self.explosives[i] Show();
		}
	}

	// Now wait
	if (!IsDefined(self.script_int) )
	{
		self.script_int = 5;
	}

	// Turn off the triggers.
	all_trigs = getentarray( self.target, "target" );
	for( i = 0; i < all_trigs.size; i++ )
	{
		all_trigs[i] trigger_off();
	}

	wait (self.script_int);
	for ( i=0; i<self.script_int; i++ )
	{
		/#
		iprintln( self.script_int - i );
		#/
		wait(1);
	}

	// Time's Up!
	// Show explosives
	if ( IsDefined( self.explosives ) )
	{
		for ( i=0; i<self.explosives.size; i++ )
		{
			PlayFX( level._effect["def_explosion"], self.explosives[i].origin, AnglesToForward(self.explosives[i].angles) );
			self.explosives[i] Hide();
		}
	}
}


//
//	Initialize the countdown
//
kill_countdown()
{
	kills_remaining = self.kill_goal - level.total_zombies_killed;

	// Play initiate sound
	players = GetPlayers();
	for (i=0; i<players.size; i++ )
	{
		if( is_true( level.player_4_vox_override ) )
		{
			players[i] playlocalsound( "zmb_laugh_rich" );
		}
		else
		{
			players[i] playlocalsound( "zmb_laugh_child" );
		}
	}

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
			ones = kills_remaining % 10;
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
				tens = int( kills_remaining / 10 );
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
				hundreds = int( kills_remaining / 100 );
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


	level.kill_counter_hud FadeOverTime( 1.0 );
	level.kill_counter_hud.color = ( 0.21, 0, 0 );

	// Now keep track of how many kills are needed
	while ( level.total_zombies_killed < self.kill_goal )
	{
		kills_remaining = self.kill_goal - level.total_zombies_killed;
		self.counter_1s set_counter( kills_remaining % 10 );
		if ( IsDefined( self.counter_10s ) )
		{
			self.counter_10s set_counter( int( kills_remaining / 10 ) );
		}
		if ( IsDefined( self.counter_100s ) )
		{
			self.counter_100s set_counter( int( kills_remaining / 100 ) );
		}
		level.kill_counter_hud SetValue( kills_remaining );

		level waittill( "zom_kill" );
	}

	// Zero!  Play end sound
	players = GetPlayers();
	for (i=0; i<players.size; i++ )
	{
		players[i] playlocalsound( "zmb_perks_packa_ready" );
	}

	self.counter_1s set_counter( 0 );
	if ( IsDefined( self.counter_10s ) )
	{
		self.counter_10s set_counter( 0 );
	}
	if ( IsDefined( self.counter_100s ) )
	{
		self.counter_100s set_counter( 0 );
	}
	level.kill_counter_hud SetValue( 0 );
	wait(1.0);

	self notify( "countdown_finished" );
}

//
//	Open a delay door once the time has expired
//	self is a door
door_kill_counter()
{
//	flag_wait( "all_players_connected" );

	// init the counter
	counter = 0;
	if (!IsDefined(self.script_int) )
	{
		counter = 5;
	}
	else
	{
		counter = self.script_int;

		// formula for reducing the kills needed by number of players
		players = GetPlayers();
		if ( players.size < 4 )
		{
			// Reduce it by 20% per person under three players
			fraction = int( counter * 0.2 );
			counter -= fraction * (4 - players.size );
		}
	}
	// Now randomize between that and +20%.
	counter = RandomIntRange( counter, Int(counter * 1.2)+1 );

/#
	if( GetDvarInt( #"zombie_cheat" ) >= 1 )
	{
		counter = 0;
	}
#/

	AssertEx( IsDefined( self.counter_1s ), "Door Kill counter needs a 'ones' digit model" );
	AssertEx( (counter < 9 || IsDefined( self.counter_10s )), "Door Kill counter needs a 'tens' digit model" );
	AssertEx( (counter < 99 || IsDefined( self.counter_100s )), "Door Kill counter needs a 'hundreds' digit model" );

	// Setup the Hud display
	level.kill_counter_hud = create_counter_hud();

	// Show explosives
// 	if ( IsDefined( self.explosives ) )
// 	{
// 		for ( i=0; i<self.explosives.size; i++ )
// 		{
// 			self.explosives[i] Show();
// 		}
// 	}
//	self waittill( "trigger", who );

	num_enemies = get_enemy_count();
	if ( level.zombie_total + num_enemies < counter )
	{
		level.zombie_total += counter - num_enemies;
	}

	// Turn off the triggers.
	all_trigs = getentarray( self.target, "target" );
	for( i = 0; i < all_trigs.size; i++ )
	{
		all_trigs[i] trigger_off();
	}

	// Now do the countdown
	self.kill_goal = level.total_zombies_killed + counter;
	self thread kill_countdown();

	self waittill( "countdown_finished" );

	level.kill_counter_hud destroy_hud();

	// Goal reached!  BOOM!
	self.counter_1s Delete();
	if ( IsDefined( self.counter_10s ) )
	{
		self.counter_10s Delete();
	}
	if ( IsDefined( self.counter_100s ) )
	{
		self.counter_100s Delete();
	}
	if ( IsDefined( self.explosives ) )
	{
		for ( i=0; i<self.explosives.size; i++ )
		{
			self.explosives[i] Hide();
		}
		PlayFX( level._effect["betty_explode"], self.explosives[0].origin, AnglesToForward(self.explosives[0].angles) );

		self.explosives[0] playsound( "mpl_kls_artillery_impact" );
	}
}


//
//	Make the door do its thing
//	self is a door
//	open: true makes the door open, false makes it close (reverse operation).  Defaults to TRUE
//		NOTE: open is currently ONLY supported for  "move" type doors
//	time is a time override
door_activate( time, open, door )
{
	if ( !IsDefined(time) )
	{
		time = 1;
		if( IsDefined( self.script_transition_time ) )
		{
			time = self.script_transition_time;
		}
	}

	if ( !IsDefined( open ) )
	{
		open = true;
	}

	zombie_doors = GetEntArray( "zombie_door", "targetname" );
	self NotSolid();

	if(self.classname == "script_brushmodel")
	{
		if ( open )
		{
			self ConnectPaths();
		}
	}

	// Prevent multiple triggers from making doors move more than once
	if ( IsDefined(self.door_moving) )
	{
		return;
	}
	self.door_moving = 1;

	if ( ( IsDefined( self.script_noteworthy )	&& self.script_noteworthy == "clip" ) ||
		( IsDefined( self.script_string )		&& self.script_string == "clip" ) )
	{
		return;
	}

	if ( IsDefined( self.script_sound ) )
	{
		play_sound_at_pos( self.script_sound, self.origin );
	}
	else
	{
		play_sound_at_pos( "door_slide_open", self.origin );
	}

	// scale
	scale = 1;
	if ( !open )
	{
		scale = -1;
	}

	// MM - each door can now have a different opening style instead of
	//	needing to be all the same
	switch( self.script_string )
	{
	case "rotate":
		if(isDefined(self.script_angles))
		{
			self RotateTo( self.script_angles, time, 0, 0 );
			self thread door_solid_thread();
		}
		wait(randomfloat(.15));
		break;
	case "move":
	case "slide_apart":
		if(isDefined(self.script_vector))
		{
			vector = vector_scale( self.script_vector, scale );
			if ( time >= 0.5 )
			{
				self MoveTo( self.origin + vector, time, time * 0.25, time * 0.25 );
			}
			else
			{
				self MoveTo( self.origin + vector, time );
			}
			self thread door_solid_thread();
			if ( !open )
			{
				self thread disconnect_paths_when_done();
			}
		}
		wait(randomfloat(.15));
		break;

	case "anim":
		//						self animscripted( "door_anim", self.origin, self.angles, level.scr_anim[ self.script_animname ] );
		self [[ level.blocker_anim_func ]]( self.script_animname );
		self thread door_solid_thread_anim();
		wait(randomfloat(.15));
		break;

	case "physics":
		self thread physics_launch_door( self );
		wait(0.10);
		break;
	}

	//Chris_P - just in case spawners are targeted
// 	if( isDefined( self.target ) )
// 	{
// 		// door needs to target new spawners which will become part
// 		// of the level enemy array
// 		self add_new_zombie_spawners();
// 	}
}


//
//	Wait to be opened!
//	self is a door trigger
door_think()
{
	self endon("kill_door_think");
	// maybe the door the should just bust open instead of slowly opening.
	// maybe just destroy the door, could be two players from opposite sides..
	// breaking into chunks seems best.
	// or I cuold just give it no collision

	cost = 1000;
	if( IsDefined( self.zombie_cost ) )
	{
		cost = self.zombie_cost;
	}

	while( 1 )
	{
		switch( self.script_noteworthy )
		{
		case "electric_door":
			flag_wait( "power_on" );
			break;

		case "electric_buyable_door":
			flag_wait( "power_on" );

			self set_hint_string( self, "default_buy_door_" + cost );
//			self thread add_teampot_icon();
//			self UseTriggerRequireLookAt();

			if ( !self door_buy() )
			{
				continue;
			}
			break;

		case "delay_door":	// set timer and explode
			if ( !self door_buy() )
			{
				continue;
			}

			self door_delay( cost );
			break;

		case "kill_counter_door":
 			if ( !self door_buy() )
 			{
 				continue;
 			}

			self door_kill_counter();
			break;

		default:
			if ( !self door_buy() )
			{
				continue;
			}
			break;
		}
// 		if(isDefined(self.script_noteworthy) && self.script_noteworthy == "electric_door")
// 		{
// 			flag_wait( "power_on" );
// 		}
// 		else if(isDefined(self.script_noteworthy) && self.script_noteworthy == "electric_buyable_door")
// 		{
// 			flag_wait( "power_on" );
//
// 			self set_hint_string( self, "default_buy_door_" + cost );
// 			self SetCursorHint( "HINT_NOICON" );
// 			self UseTriggerRequireLookAt();
//
// 			self waittill( "trigger", who );
//
// 			self door_buy();
// 		}
// 		else
// 		{
// 			self waittill( "trigger", who );
//
// 			self door_buy();
// 		}

		self door_opened();

		break;
	}

	self._door_open = true;
	self notify("door_opened");
}

door_opened()
{
	// Set any flags called
	if( IsDefined( self.script_flag ) )
	{
		tokens = Strtok( self.script_flag, "," );
		for ( i=0; i<tokens.size; i++ )
		{
			flag_set( tokens[i] );
		}
	}

	// get all trigs for the door, we might want a trigger on both sides
	// of some junk sometimes
	all_trigs = getentarray( self.target, "target" );
	for( i = 0; i < all_trigs.size; i++ )
	{
		all_trigs[i] trigger_off();
	}

	// Just play purchase sound on the first door
	if( self.doors.size )
	{
		play_sound_at_pos( "purchase", self.doors[0].origin );
	}

	// Door has been activated, make it do its thing
	for(i=0;i<self.doors.size;i++)
	{
		// Don't thread this so the doors don't move at once
		self.doors[i] door_activate(undefined, undefined, self);
	}
}

//
//	Launch the door!
//	self = door entity
//	door_trig = door trigger
physics_launch_door( door_trig )
{
// 	origin = self.origin;
// 	if ( IsDefined(door_trig.explosives) )
// 	{
// 		origin = door_trig.explosives[0].origin;
// 	}
//
	vec = vector_scale( VectorNormalize( self.script_vector ), 5 );
	self MoveTo( self.origin + vec, 0.1 );
	self waittill( "movedone" );

	self PhysicsLaunch( self.origin, self.script_vector *10 );
	wait(0.1);
	PhysicsExplosionSphere( vector_scale( vec, -1 ), 120, 1, 100 );

	wait(1);

	self delete();
}


//
//	Waits until it is finished moving and then returns to solid once no player is touching it
//		(So they don't get stuck).  The door is made notSolid initially, otherwise, a player
//		could block its movement or cause a player to become stuck.
//	self is a door
door_solid_thread()
{
	// MM - added support for movedone.
	self waittill_either( "rotatedone", "movedone" );

	self.door_moving = undefined;
	while( 1 )
	{
		players = get_players();
		player_touching = false;
		for( i = 0; i < players.size; i++ )
		{
			if( players[i] IsTouching( self ) )
			{
				player_touching = true;
				players[i] random_push();
			}
		}

		if( !player_touching )
		{
			self Solid();
			return;
		}

		wait( .05 );
	}
}

random_push()
{
	vector = VectorNormalize((RandomIntRange(-100,99),RandomIntRange(-100,99),0))*(100,100,100);
	self SetVelocity(vector);
}

//
//	Called on doors using anims.  It needs a different waittill,
//		and expects the animname message to be the same as the one passed into scripted anim
//	self is a door
door_solid_thread_anim( )
{
	// MM - added support for movedone.
	self waittillmatch( "door_anim", "end" );

	self.door_moving = undefined;
	while( 1 )
	{
		players = get_players();
		player_touching = false;
		for( i = 0; i < players.size; i++ )
		{
			if( players[i] IsTouching( self ) )
			{
				player_touching = true;
				break;
			}
		}

		if( !player_touching )
		{
			self Solid();
			return;
		}

		wait( 1 );
	}
}


//
//
//
disconnect_paths_when_done()
{
	self waittill_either( "rotatedone", "movedone" );

	self DisconnectPaths();
}

//
// DEBRIS - these are "doors" that consist of various pieces of piled objects
//		they lift up and disappear when bought.
//
debris_init()
{
	cost = 1000;
	if( IsDefined( self.zombie_cost ) )
	{
		cost = self.zombie_cost;
	}

	self set_hint_string( self, "default_buy_debris_" + cost );
	self setCursorHint( "HINT_NOICON" );

//	self thread add_teampot_icon();

	if( isdefined (self.script_flag)  && !IsDefined( level.flag[self.script_flag] ) )
	{
		flag_init( self.script_flag );
	}

//	self UseTriggerRequireLookAt();
	self thread debris_think();
}


//
//	self is a debris trigger
//
debris_think()
{

	if( isDefined( level.custom_debris_function ) )
	{
		self [[ level.custom_debris_function ]]();
	}

	while( 1 )
	{
		self waittill( "trigger", who, force );

		if ( GetDvarInt( #"zombie_unlock_all") > 0 || is_true( force ) )
		{
			//bypass.
		}
		else
		{
			if( !who UseButtonPressed() )
			{
				continue;
			}

			if( who in_revive_trigger() )
			{
				continue;
			}
		}

		if( is_player_valid( who ) )
		{
			// Can we afford this door?
			players = get_players();
			if(GetDvarInt( #"zombie_unlock_all") > 0)
			{
				// bypass charge.
			}
			else if ( players.size == 1 && who.score >= self.zombie_cost )
			{
				// solo buy
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
			}
			else if( level.team_pool[ who.team_num ].score >= self.zombie_cost )
			{
				// team buy
				who maps\_zombiemode_score::minus_to_team_score( self.zombie_cost );
			}
			else if( level.team_pool[ who.team_num ].score + who.score >= self.zombie_cost )
			{
				// team funds + player funds
				team_points = level.team_pool[ who.team_num ].score;
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost - team_points );
				who maps\_zombiemode_score::minus_to_team_score( team_points );
			}
			else
			{
				play_sound_at_pos( "no_purchase", self.origin );
				who maps\_zombiemode_audio::create_and_play_dialog( "general", "door_deny", undefined, 1 );
				continue;
			}

			// Okay remove the debris
			bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type door", who.playername, who.score, level.team_pool[ who.team_num ].score, level.round_number, self.zombie_cost, self.script_flag, self.origin );

			// delete the stuff
			junk = getentarray( self.target, "targetname" );

			// Set any flags called
			if( IsDefined( self.script_flag ) )
			{
				tokens = Strtok( self.script_flag, "," );
				for ( i=0; i<tokens.size; i++ )
				{
					flag_set( tokens[i] );
				}
			}

			play_sound_at_pos( "purchase", self.origin );
			level notify ("junk purchased");

			move_ent = undefined;
			clip = undefined;
			for( i = 0; i < junk.size; i++ )
			{
				junk[i] connectpaths();
//				junk[i] add_new_zombie_spawners();

				if( IsDefined( junk[i].script_noteworthy ) )
				{
					if( junk[i].script_noteworthy == "clip" )
					{
						clip = junk[i];
						continue;
					}
				}

				struct = undefined;
				if( IsDefined( junk[i].script_linkTo ) )
				{
					struct = getstruct( junk[i].script_linkTo, "script_linkname" );
					if( IsDefined( struct ) )
					{
						move_ent = junk[i];
						junk[i] thread debris_move( struct );
					}
					else
					{
						junk[i] Delete();
					}
				}
				else
				{
					junk[i] Delete();
				}
			}

			// get all trigs, we might want a trigger on both sides
			// of some junk sometimes
			all_trigs = getentarray( self.target, "target" );
			for( i = 0; i < all_trigs.size; i++ )
			{
				all_trigs[i] delete();
			}

			if( IsDefined( clip ) )
			{
				if( IsDefined( move_ent ) )
				{
					move_ent waittill( "movedone" );
				}

				clip Delete();
			}

			break;
		}
	}
}


//
//	Moves the debris out of place
//	self is a debris piece
//
debris_move( struct )
{
	self script_delay();
	//chrisp - prevent playerse from getting stuck on the stuff
	self notsolid();

	self play_sound_on_ent( "debris_move" );
	playsoundatposition ("zmb_lightning_l", self.origin);
	if( IsDefined( self.script_firefx ) )
	{
		PlayFX( level._effect[self.script_firefx], self.origin );
	}

	// Do a little jiggle, then move.
	if( IsDefined( self.script_noteworthy ) )
	{
		if( self.script_noteworthy == "jiggle" )
		{
			num = RandomIntRange( 3, 5 );
			og_angles = self.angles;
			for( i = 0; i < num; i++ )
			{
				angles = og_angles + ( -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ) );
				time = RandomFloatRange( 0.1, 0.4 );
				self Rotateto( angles, time );
				wait( time - 0.05 );
			}
		}
	}

	time = 0.5;
	if( IsDefined( self.script_transition_time ) )
	{
		time = self.script_transition_time;
	}

	self MoveTo( struct.origin, time, time * 0.5 );
	self RotateTo( struct.angles, time * 0.75 );

	self waittill( "movedone" );

	//Z2 commented out missing sound, wouldn't go past.
	//self play_sound_on_entity("couch_slam");

	if( IsDefined( self.script_fxid ) )
	{
		PlayFX( level._effect[self.script_fxid], self.origin );
		playsoundatposition("zmb_zombie_spawn", self.origin); //just playing the zombie_spawn sound when it deletes the blocker because it matches the particle.
	}

	self Delete();

}


//
// BLOCKER (aka window, bar, board)
// Self = exterior_goal, it is the node that targets all of the boards and bars
// This sets up every window in level,
blocker_init()
{
	if( !IsDefined( self.target ) ) // If the exterior_goal entity has no targets defined then return
	{
		return;
	}

	targets = GetEntArray( self.target, "targetname" ); // Grab all the pieces that are targeted by the exterior_goal

	self.barrier_chunks = []; // self has a newly defined array of barrier_chunks

	use_boards = true;

	if( level.mutators["mutator_noBoards"] )
	{
		use_boards = false;
	}

	for( j = 0; j < targets.size; j++ ) // count total targets of exterior_goal
	{
		if( IsDefined( targets[j].script_noteworthy ) ) // If a script noteworthy is defined
		{
			if( targets[j].script_noteworthy == "clip" ) //  Grab the clip and continue
			{
				self.clip = targets[j]; // self.clip is defined from the array
				continue; // Go forward with the script
			}
		}

		// jl/ jan/15/10 add new setup for grates
		// I hide all the pieces you don't need to see right now.
		// This works
		// Now when they get pulled off, I just want them to swap out the model

		if( IsDefined( targets[j].script_string ) && targets[j].script_string == "rock" )
		{
		    targets[j].material = "rock";
		}

		if( IsDefined( targets[j].script_parameters ) ) // If a script noteworthy is defined
		{
			if( targets[j].script_parameters == "grate" )
			{
				if( IsDefined( targets[j].script_noteworthy ) ) // If a script noteworthy is defined
				{
					if( targets[j].script_noteworthy == "2" || targets[j].script_noteworthy == "3" || targets[j].script_noteworthy == "4" ||
					 targets[j].script_noteworthy == "5" || targets[j].script_noteworthy == "6")
					{
						// this is an improper setup because each piece is still sitting there
						targets[j] Hide(); // this grabs all the pieces and hides it
						/#
						IPrintLnBold(" Hide ");
						#/
					}
				}
			}
			//DCS: new pentagon system where barricade starts as new and is repaired with boards, etc.
			// start with repair boards hidden.
			else if( targets[j].script_parameters == "repair_board" )
			{
				targets[j].unbroken_section = GetEnt(targets[j].target,"targetname");
				if(IsDefined(targets[j].unbroken_section))
				{
					targets[j].unbroken_section LinkTo(targets[j]);
					if(!IsDefined(targets[j].unbroken_section.script_noteworthy) || targets[j].unbroken_section.script_noteworthy != "glass")
					{
						targets[j] Hide();
						targets[j] notSolid();
					}
					targets[j].unbroken = true;

					// self is the goal (level.exterior_goals)
					if(IsDefined(targets[j].unbroken_section.script_noteworthy) && targets[j].unbroken_section.script_noteworthy == "glass")
					{
						targets[j].material = "glass";
						targets[j] thread destructible_glass_barricade(targets[j].unbroken_section, self);
					}
					else if(IsDefined(targets[j].unbroken_section.script_noteworthy) && targets[j].unbroken_section.script_noteworthy == "metal")
					{
						targets[j].material = "metal";
					}
				}
			}
			else if( targets[j].script_parameters == "barricade_vents" )
			{
				targets[j].material = "metal_vent";
			}
		}

			if( IsDefined ( targets[j].targetname ) )
			{
				if( targets[j].targetname == "auto2" )
				{
					//	 targets[j]
				}
			}

			if( use_boards )
			{
				targets[j] update_states("repaired"); // Change state to repaired
				targets[j].destroyed = false;
			}
			else
			{
				targets[j] update_states("destroyed");
				targets[j].destroyed = true;
				targets[j] Hide();
				targets[j] notSolid();
			}
			targets[j].claimed = false;
			targets[j].anim_grate_index = 0; // check this index to know where each piece is
			// I can create another thing to track here if I need to
			targets[j].og_origin = targets[j].origin; // This one piece's origin is defined by grabbing the starting origin
			targets[j].og_angles = targets[j].angles; // The one piece's angles is defined by grabbing the starting angles
			self.barrier_chunks[self.barrier_chunks.size] = targets[j]; // barrier_chunks is the total size of the bars windows or boards used

			self blocker_attack_spots(); // exterior_goal thread
	}

	if( use_boards )
	{
		assert( IsDefined( self.clip ) );
		self.trigger_location = getstruct( self.target, "targetname" ); // trigger_location is the new name for exterior_goal targets -- which is auto1 in all cases

		self thread blocker_think(); // exterior_goal thread blocker_think
	}
}


//-------------------------------------------------------------------------------
// DCS 090710:	glass barricade. Player can damage.
//							self is chunk, aka. repair_board
//-------------------------------------------------------------------------------
destructible_glass_barricade(unbroken_section, node)
{
	unbroken_section SetCanDamage( true );
	
	while(1)
	{
		unbroken_section.health = 99999;
		unbroken_section waittill( "damage", amount, who);

		self thread maps\_zombiemode_spawner::zombie_boardtear_offset_fx_horizontle( self, node );
		level thread remove_chunk( self, node, true );

		self waittill("repaired");
	}
}
//-------------------------------------------------------------------------------

// jl jan/05/10
// Self = exterior_goal, it is the node that targets all of the boards and bars
// Creates three spots that the AI can now choose from to attack the window
blocker_attack_spots()
{
	// Get closest chunk
	chunk = getClosest( self.origin, self.barrier_chunks );  // chunk = grab closest origin from array of barrier_chunks

	dist = Distance2d( self.origin, chunk.origin ) - 36;
	spots = [];
	spots[0] = groundpos( self.origin + ( AnglesToForward( self.angles ) * dist ) + ( 0, 0, 60 ) );
	spots[spots.size] = groundpos( spots[0] + ( AnglesToRight( self.angles ) * 28 ) + ( 0, 0, 60 ) );
	spots[spots.size] = groundpos( spots[0] + ( AnglesToRight( self.angles ) * -28 ) + ( 0, 0, 60 ) );

	taken = []; // new array
	for( i = 0; i < spots.size; i++ ) // cycle through all spots and define as not taken
	{
		taken[i] = false;
	}

	self.attack_spots_taken = taken; // set attack_spots_taken to taken
	self.attack_spots = spots; // set attack_spots to spots

	self thread debug_attack_spots_taken(); // self = exterior_goal
}


blocker_choke()
{
	level._blocker_choke = 0;

	while(1)
	{
		wait(0.05);
		level._blocker_choke = 0;
	}
}

// jl jan/05/10
// Self = exterior_goal, it is the node that targets all of the boards and bars
blocker_think()
{

	if(!IsDefined(level._blocker_choke))
	{
		level thread blocker_choke();
	}

	use_choke = false;

	if(IsDefined(level._use_choke_blockers) && level._use_choke_blockers == 1)
	{
		use_choke = true;
	}

	while( 1 ) // exterior_goal is going to constantly loop
	{
		wait( 0.5 );

		if(use_choke)
		{
			if(level._blocker_choke > 3)
			{
				wait(0.05);
			}
		}

		level._blocker_choke ++;

		if( all_chunks_intact( self.barrier_chunks ) ) // speak to _zombiemode_utility and into all_chunks_intact function
		{
			// if any piece has the state of not repaired then return false
			// if the board has been repaired then return true
			continue;
		}

		if( no_valid_repairable_boards( self.barrier_chunks ) )// speak to _zombiemode_utility and into no_valid_repairable_boards function
		{
			// if any piece has been destroyed return false
			// if any piece is not destroyed then return true
			continue;
		}

		self blocker_trigger_think();
	}
}


// Self = exterior_goal, it is the node that targets all of the boards and bars
// trigger_location
// this function repairs the boards
blocker_trigger_think()
{
	// They don't cost, they now award the player the cost...
	cost = 10;
	if( IsDefined( self.zombie_cost ) )
	{
		cost = self.zombie_cost;
	}

	original_cost = cost;

	radius = 96;
	height = 96;

	if( IsDefined( self.trigger_location ) ) // this is defined in the blocker_init function
	{
		trigger_location = self.trigger_location; // trigger_location is the new name for exterior_goal targets -- which is auto1 in all cases
	}
	else
	{
		trigger_location = self; // if it is not defined then just use self as the trigger_location
	}

	if( IsDefined( trigger_location.radius ) ) // he is asking if it is defined here, yet he never defines it anywhere
	{
		radius = trigger_location.radius;
	}

	if( IsDefined( trigger_location.height ) ) // he is asking if it is defined here, yet he never defines it anywhere
	{
		height = trigger_location.height;
	}

	trigger_pos = groundpos( trigger_location.origin ) + ( 0, 0, 4 ); // this is from trigger_location and is reset to trigger_pos
	trigger = Spawn( "trigger_radius", trigger_pos, 0, radius, height ); // spawn in a trigger at the location of the exterior_goal

	trigger thread trigger_delete_on_repair(); // This function waits till the boards/bars are repaired
	if(IsDefined(level._zombiemode_blocker_trigger_extra_thread))
	{
		trigger thread [[level._zombiemode_blocker_trigger_extra_thread]]();
	}
	/#
		if( GetDvarInt( #"zombie_debug" ) > 0 ) //
		{
			thread debug_blocker( trigger_pos, radius, height );
		}
	#/

	// Rebuilding no longer costs us money... It's rewarded

	//////////////////////////////////////////
	//designed by prod; NO reward hint (See DT#36173)
	trigger set_hint_string( self, "default_reward_barrier_piece" ); // this is the string to call when the player is the trigger
	//trigger thread blocker_doubler_hint( "default_reward_barrier_piece_", original_cost );
	//////////////////////////////////////////

	trigger SetCursorHint( "HINT_NOICON" );

	while( 1 ) // the trigger constantly loops here till while the player interacts with it.
	{
		trigger waittill( "trigger", player );

		if( player hasperk( "specialty_fastreload" ) )
		{
			has_perk = "specialty_fastreload";
		}
		//else if( player hasperk( "specialty_fastreload_upgrade" ) )
		//{
		//	has_perk = "specialty_fastreload_upgrade";
		//}
		else
		{
			has_perk = undefined;
		}

		if( all_chunks_intact( self.barrier_chunks ) ) // barrier chunks are all the pieces targeted from the exterior_goal
		{
			// if any piece has the state of not repaired then return false
			// if the board has been repaired then return true
			trigger notify("all_boards_repaired");
			return;
		}

		if( no_valid_repairable_boards( self.barrier_chunks ) ) // barrier chunks are all the pieces targeted from the exterior_goal
		{
			// if any piece has been destroyed return false
			// if any piece is not destroyed then return true
			trigger notify("no valid boards");
			return;
		}

		players = GetPlayers();

		while( 1 )
		{
			if( !player IsTouching( trigger ) )
			{
				break;
			}

			if( !is_player_valid( player ) )
			{
				break;
			}

			if( player in_revive_trigger() )
			{
				break;
			}

			if( players.size == 1 && IsDefined( players[0].intermission ) && players[0].intermission == 1)
			{
				break;
			}

			if( player hacker_active() )
			{
				break;
			}

			if( !player UseButtonPressed() )
			{
				break;
			}

			if( player IsSprinting() )
			{
				break;
			}

			if( is_true(player.divetoprone) )
			{
				break;
			}

			if( !player use_button_held() )
			{
				break;
			}



			chunk = get_random_destroyed_chunk( self.barrier_chunks ); // calls get_random_destroyed_chunk in _zombiemode_utility, continue if the chunk was destroyed

			if(IsDefined(chunk.script_parameter) && chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents")
			{
				if(IsDefined(chunk.unbroken_section))
				{
					chunk Show();
					chunk Solid();
					chunk.unbroken_section self_delete();
				}
			}
			else
			{
				if(!IsDefined(chunk.unbroken_section))
				{
					chunk Show();
				}
			}



			    if ( !isDefined( chunk.script_parameters ) || chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents")
			    {
			    	//sounds now played on client

			    	if(!is_true(level.use_clientside_board_fx))
			    	{

							if( !IsDefined( chunk.material ) || ( IsDefined( chunk.material ) && chunk.material != "rock" ) )
							{
						    chunk play_sound_on_ent( "rebuild_barrier_piece" );
							}
							playsoundatposition ("zmb_cha_ching", (0,0,0));
						}

			    }
			   	if ( chunk.script_parameters == "bar" )
			    {
						chunk play_sound_on_ent( "rebuild_barrier_piece" );
						playsoundatposition ("zmb_cha_ching", (0,0,0));
			    }

				// I need to do this in a different place
					if(isdefined(chunk.script_parameters))
					{
						if( chunk.script_parameters == "bar"  )
						{
								if(isdefined(chunk.script_noteworthy))
								{
									if(chunk.script_noteworthy == "5") // this is the far left , this bar now bends it does not leave
									{
										chunk hide();
									}
									else if(chunk.script_noteworthy == "3" )
									{
										chunk hide();
									}
								}
						}
					}


			self thread replace_chunk( chunk ); // writing out


			assert( IsDefined( self.clip ) );
			self.clip enable_trigger();
			self.clip DisconnectPaths(); // the boards disconnect paths everytime they are used here

			//maps\_zombiemode_challenges::doMissionCallback( "zm_board_repair", player );
			bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type repair", player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, original_cost, self.target, self.origin );

			if( !self script_delay() )
			{
				wait( 1 );
			}

			if( !is_player_valid( player ) )
			{
				break;
			}

			// set the score
			if( player.rebuild_barrier_reward < level.zombie_vars["rebuild_barrier_cap_per_round"] )
			{
				player maps\_zombiemode_score::player_add_points( "rebuild_board", cost );
				player play_sound_on_ent( "purchase" );
			}
			player.rebuild_barrier_reward += cost;
			// general contractor achievement for dlc 2. keep track of how many board player repaired.
			if(IsDefined(player.board_repair))
			{
				player.board_repair += 1;
			}

			if( all_chunks_intact( self.barrier_chunks ) ) // This calls into _zombiemode_utility
			{
				// if any piece has the state of not repaired then return false
				// if the board has been repaired then return true
				trigger notify("all_boards_repaired");
				return;
			}

			if( no_valid_repairable_boards( self.barrier_chunks ) ) // This calls into _zombiemode_utility
			{
				// if any piece has been destroyed return false
				// if any piece is not destroyed then return true
				trigger notify("no valid boards");
				return;
			}

		}
	}
}

random_destroyed_chunk_show( )
{
	wait( 0.5 );
	self Show();
}


// jl this calls a rumble and zombie scream on the players if they are next to a door being opened.
// call a distance check of the the last chunk replaced
door_repaired_rumble_n_sound()
{
	players = GetPlayers();
	//players[0] PlayRumbleOnEntity("damage_heavy");
	// only do this if they are close enough
	// add distnace check

	for(i = 0; i < players.size; i++)
		{

			if (distance (players[i].origin, self.origin) < 150)
			{

				if(isalive(players[i]))
					//-- not usedif(isalive(players[i]) && (isdefined(players[i].pers["team"])) && (players[i].pers["team"] == team))
				{

				players[i] thread board_completion();

				}
			}
		}
}

board_completion()
{
	self endon ("disconnect");

		// need to be place a delay if done within a certain time frame
		//wait(1.2);
		//self play_sound_on_ent( "purchase" );
		//players[i] iprintlnbold("Entrance 1 is fixed!!!");
		//wait(0.3);
		//self play_sound_on_ent( "purchase" );
		//wait(0.3);
		//self play_sound_on_ent( "purchase" );
}


// self is a trigger that is spawned off of the exterior_goal entity.
trigger_delete_on_repair()
{
	while( IsDefined( self ) )
	{
		self waittill_either("all_boards_repaired", "no valid boards");
		self thread door_repaired_rumble_n_sound(); // jl added cool repair sound
		self delete(); // when the boards are totally repaired then delete your self
		break;
	}

}

blocker_doubler_hint( hint, original_cost )
{
	self endon( "death" );

	doubler_status = level.zombie_vars["zombie_powerup_point_doubler_on"];
	while( 1 )
	{
		wait( 0.5 );

		if( doubler_status != level.zombie_vars["zombie_powerup_point_doubler_on"] )
		{
			doubler_status = level.zombie_vars["zombie_powerup_point_doubler_on"];
			cost = original_cost;
			if( level.zombie_vars["zombie_powerup_point_doubler_on"] )
			{
				cost = original_cost * 2;
			}

			self set_hint_string( self, hint + cost );
		}
	}
}

rebuild_barrier_reward_reset()
{
	self.rebuild_barrier_reward = 0;
}

remove_chunk( chunk, node, destroy_immediately, zomb )
{
	if(IsDefined(chunk.unbroken_section) && IsDefined(chunk.material) && chunk.material == "glass")
	{
		chunk.unbroken_section self_delete();
		chunk thread zombie_boardtear_audio_offset(chunk);
		chunk.already_broken = true;
		chunk.unbroken = false;
		chunk update_states("repaired");
		return;
	}

	chunk update_states("mid_tear");

	// jl dec 15 09
	// jl added check for differnt types of windows
	if(IsDefined(chunk.script_parameters))
	{
		if( chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents") // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{
			chunk thread zombie_boardtear_audio_offset(chunk);
		}
	}

	if(IsDefined(chunk.script_parameters))
	{
		if( chunk.script_parameters == "bar" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{
			chunk thread zombie_bartear_audio_offset(chunk);
		}
	}


	chunk NotSolid();
	// here I do a check for if it is a bar

	//if ( isdefined( destroy_immediately ) && destroy_immediately)
	//{
	//	chunk.destroyed = true;
	//}

	fx = "wood_chunk_destory";
	if( IsDefined( self.script_fxid ) )
	{
		fx = self.script_fxid;
	}



	if ( IsDefined( chunk.script_moveoverride ) && chunk.script_moveoverride )
	{
		chunk Hide();
	}


	// an origin is created and the current chunk is linked to it. Then it flings the chunk and deletes the origin
	if ( IsDefined( chunk.script_parameters ) && ( chunk.script_parameters == "bar" ) )
	{

		// added top bar check so it goes less higher
		if( IsDefined ( chunk.script_noteworthy ) && ( chunk.script_noteworthy == "4" ) )
		{
			ent = Spawn( "script_origin", chunk.origin );
			ent.angles = node.angles +( 0, 180, 0 );

			//DCS 030711: adding potential for having max distance movement
			//for boards in closets that aren't very deep.
			dist = 100; // base number.
			if(IsDefined(chunk.script_move_dist))
			{
					dist_max = chunk.script_move_dist - 100;
					dist = 100 + RandomInt(dist_max);
			}
			else
			{
				dist = 100 + RandomInt( 100 );
			}

			dest = ent.origin + ( AnglesToForward( ent.angles ) * dist );
			trace = BulletTrace( dest + ( 0, 0, 16 ), dest + ( 0, 0, -200 ), false, undefined );

			if( trace["fraction"] == 1 )
			{
				dest = dest + ( 0, 0, -200 );
			}
			else
			{
				dest = trace["position"];
			}

	//		time = 1;
			chunk LinkTo( ent );

			//time = ent fake_physicslaunch( dest, 200 + RandomInt( 100 ) );
			time = ent fake_physicslaunch( dest, 300 + RandomInt( 100 ) );


			if( RandomInt( 100 ) > 40 )
			{
				ent RotatePitch( 180, time * 0.5 );
			}
			else
			{
				ent RotatePitch( 90, time, time * 0.5 );
			}
			wait( time );

			chunk Hide();

			// try sending the notify now...
			wait( 0.1);
			//wait( 1 ); // the notify is sent out late... so I can't call it right away...
			// I need to keep track of what the last peice is...
			ent Delete();
		}

		else
		{
			ent = Spawn( "script_origin", chunk.origin );
			ent.angles = node.angles +( 0, 180, 0 );


			//DCS 030711: adding potential for having max distance movement
			//for boards in closets that aren't very deep.
			dist = 100; // base number.
			if(IsDefined(chunk.script_move_dist))
			{
					dist_max = chunk.script_move_dist - 100;
					dist = 100 + RandomInt(dist_max);
			}
			else
			{
				dist = 100 + RandomInt( 100 );
			}

			dest = ent.origin + ( AnglesToForward( ent.angles ) * dist );
			trace = BulletTrace( dest + ( 0, 0, 16 ), dest + ( 0, 0, -200 ), false, undefined );

			if( trace["fraction"] == 1 )
			{
				dest = dest + ( 0, 0, -200 );
			}
			else
			{
				dest = trace["position"];
			}

	//		time = 1;
			chunk LinkTo( ent );

			time = ent fake_physicslaunch( dest, 260 + RandomInt( 100 ) );

			// here you will do a random damage... however it would be better if you made them fall over
			// call damage function out of here so the wait doesn't interrupt normal flow.


			//time = ent fake_physicslaunch( dest, 200 + RandomInt( 100 ) );

			//forward = AnglesToForward( ent.angles + ( -60, 0, 0 ) ) * power );
			//ent MoveGravity( forward, time );

			if( RandomInt( 100 ) > 40 )
			{
				ent RotatePitch( 180, time * 0.5 );
			}
			else
			{
				ent RotatePitch( 90, time, time * 0.5 );
			}
			wait( time );

			chunk Hide();

			// try sending the notify now...
			wait( 0.1);
			//wait( 1 ); // the notify is sent out late... so I can't call it right away...
			// I need to keep track of what the last peice is...
			ent Delete();

		}
		//if (isdefined( destroy_immediately ) && destroy_immediately)
		//{
		//	return;
		//}

		chunk update_states("destroyed");
		chunk notify( "destroyed" );
	}

	if ( IsDefined ( chunk.script_parameters ) && chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents" )
	{
		ent = Spawn( "script_origin", chunk.origin );
		ent.angles = node.angles +( 0, 180, 0 );

		//DCS 030711: adding potential for having max distance movement
		//for boards in closets that aren't very deep.
		dist = 100; // base number.
		if(IsDefined(chunk.script_move_dist))
		{
			dist_max = chunk.script_move_dist - 100;
			dist = 100 + RandomInt(dist_max);
		}
		else
		{
			dist = 100 + RandomInt( 100 );
		}

		dest = ent.origin + ( AnglesToForward( ent.angles ) * dist );
		trace = BulletTrace( dest + ( 0, 0, 16 ), dest + ( 0, 0, -200 ), false, undefined );

		if( trace["fraction"] == 1 )
		{
			dest = dest + ( 0, 0, -200 );
		}
		else
		{
			dest = trace["position"];
		}

		// Five glass barriers - destroy immediately
		if(IsDefined(chunk.unbroken_section) && IsDefined(chunk.material) && chunk.material == "glass")
		{
			chunk.unbroken_section self_delete();
			//chunk.unbroken_section Hide();
			//chunk.unbroken_section NotSolid();

			chunk.origin = groundpos( chunk.origin + ( AnglesToForward( node.angles + (0, 180, 0) ) * dist ) );

			if( RandomInt( 100 ) > 40 )
			{
				chunk.angles = chunk.angles + (180, 0, 0);
			}
			else
			{
				chunk.angles = chunk.angles + (90, 0, 0);
			}

			ent Delete();
			chunk update_states("destroyed");
			chunk notify( "destroyed" );
			return;
		}

		//time = 1;
		chunk LinkTo( ent );

		time = ent fake_physicslaunch( dest, 200 + RandomInt( 100 ) );
		//time = ent fake_physicslaunch( dest, 200 + RandomInt( 100 ) );

		//forward = AnglesToForward( ent.angles + ( -60, 0, 0 ) ) * power );
		//ent MoveGravity( forward, time );

		// DCS 090110: delete glass or wall piece before sending flying.
		//DCS 090910: but not metal.
		if(IsDefined(chunk.unbroken_section))
		{
			if(IsDefined(chunk.material) && chunk.material == "glass")
			{
				chunk.unbroken_section self_delete();
				//chunk.unbroken_section Hide();
				//chunk.unbroken_section NotSolid();
			}
		}

		if( RandomInt( 100 ) > 40 )
		{
			ent RotatePitch( 180, time * 0.5 );
		}
		else
		{
			ent RotatePitch( 90, time, time * 0.5 );
		}
		wait( time );

		if(IsDefined(chunk.unbroken_section))
		{
			//chunk.unbroken_section self_delete();
			chunk.unbroken_section Hide();
			chunk.unbroken_section NotSolid();
		}

		chunk Hide();

		// try sending the notify now...
		wait( 0.1);
		//wait( 1 ); // the notify is sent out late... so I can't call it right away...
		// I need to keep track of what the last peice is...
		ent Delete();


		//if (isdefined( destroy_immediately ) && destroy_immediately)
		//{
		//	return;
		//}

		chunk update_states("destroyed");
		chunk notify( "destroyed" );
	}


	if ( IsDefined ( chunk.script_parameters ) && ( chunk.script_parameters == "grate" ) )
	{
		// Only make the last piece of the grate get pulled off.
		if( IsDefined ( chunk.script_noteworthy ) && ( chunk.script_noteworthy == "6" ) )
		{
	//		angles = node.angles +( 0, 180, 0 );
	//		force = AnglesToForward( angles + ( -60, 0, 0 ) ) * ( 200 + RandomInt( 100 ) );
	//		chunk PhysicsLaunch( chunk.origin, force );

			ent = Spawn( "script_origin", chunk.origin );
			ent.angles = node.angles +( 0, 180, 0 );
			dist = 100 + RandomInt( 100 );
			dest = ent.origin + ( AnglesToForward( ent.angles ) * dist );
			trace = BulletTrace( dest + ( 0, 0, 16 ), dest + ( 0, 0, -200 ), false, undefined );

			if( trace["fraction"] == 1 )
			{
				dest = dest + ( 0, 0, -200 );
			}
			else
			{
				dest = trace["position"];
			}

	//		time = 1;
			chunk LinkTo( ent );

			time = ent fake_physicslaunch( dest, 200 + RandomInt( 100 ) );
			//time = ent fake_physicslaunch( dest, 200 + RandomInt( 100 ) );

	//		forward = AnglesToForward( ent.angles + ( -60, 0, 0 ) ) * power );
	//		ent MoveGravity( forward, time );

			if( RandomInt( 100 ) > 40 )
			{
				ent RotatePitch( 180, time * 0.5 );
			}
			else
			{
				ent RotatePitch( 90, time, time * 0.5 );
			}
			wait( time );
			chunk Hide();
			//wait( 1 ); // the notify is sent out late... so I can't call it right away...
			// I need to keep track of what the last peice is...
			ent Delete();
			chunk update_states("destroyed");
			chunk notify( "destroyed" );
		}

		else
		{
			chunk Hide();
			//chunk moveto( chunk.origin + ( 0, 0, -1000 ), 0.3, 0.1, 0.1 );
			chunk update_states("destroyed");
			chunk notify( "destroyed" );
		}
			//chunk Hide();
	}

	/*
	// this is kicking off but is to late to send the notify
	if( all_chunks_destroyed( node.barrier_chunks ) )
	{

		if( IsDefined( node.clip ) )
		{
			node.clip ConnectPaths();
			wait( 0.05 );
			node.clip disable_trigger();
		}
		else
		{
			for( i = 0; i < node.barrier_chunks.size; i++ )
			{
				node.barrier_chunks[i] ConnectPaths();
			}
		}
	}
	else
	{
		EarthQuake( RandomFloatRange( 1, 3 ), 0.9, chunk.origin, 500 );
	}
	*/
}


// jl dec 15 09
remove_chunk_rotate_grate( chunk )
{
	// this is going to rotate all of them.. I need to some how do this off of the node pointing to it..
	//chunk_rotate_piece = GetEntArray( "grate", "script_parameters");

	//chunk_rotate_piece = GetEnt( "grate", "script_parameters");
	//chunk vibrate(( 0, 270, 0 ), 0.2, 0.4, 0.4);


	// how do I only effect the one for that window and not affect all of them
	// This is actually checked every time

	if( IsDefined (chunk.script_parameters) && chunk.script_parameters == "grate" ) //&& chunk.script_parameters != "grate" )
	{
		chunk vibrate(( 0, 270, 0 ), 0.2, 0.4, 0.4);
		return;
	}
}

// jl just for now I added an audio offset to give more length and depth to the tearing off feeling
// i should add these to the same area where the fx is called, which is zombie_boardtear_offset_fx_horizontle(chunk)
// in zombiemode_spawner
zombie_boardtear_audio_offset(chunk)
{
	if( IsDefined(chunk.material) && !IsDefined( chunk.already_broken ) )
	    chunk.already_broken = false;

	if( IsDefined(chunk.material) && chunk.material == "glass" && chunk.already_broken == false )
	{
	    chunk PlaySound( "zmb_break_glass_barrier" );
	    //wait( randomfloat( 0.3, 0.6 ));
	    //chunk PlaySound( "zmb_break_glass_barrier" );
	    //chunk.already_broken = true;
	}
	else if( IsDefined(chunk.material) && chunk.material == "metal" && chunk.already_broken == false )
	{
	    chunk play_sound_on_ent( "grab_metal_bar" );
	    wait( randomfloat( 0.3, 0.6 ));
	    chunk play_sound_on_ent( "break_metal_bar" );
	    //chunk.already_broken = true;
	}
	else if( IsDefined(chunk.material) && chunk.material == "rock" )
	{
	    if(!is_true(level.use_clientside_rock_tearin_fx))
		{
	    	chunk PlaySound( "zmb_break_rock_barrier" );
	    	wait( randomfloat( 0.3, 0.6 ));
	    	chunk PlaySound( "zmb_break_rock_barrier" );
	    }
	    chunk.already_broken = true;
	}
	else if( IsDefined(chunk.material) && chunk.material == "metal_vent")
	{
			if(!is_true(level.use_clientside_board_fx))
			{
	    	//chunk PlaySound( "evt_vent_slat_grab" );
	    	//wait( randomfloat( 0.3, 0.6 ));
	    	chunk PlaySound( "evt_vent_slat_remove" );
	  	}
	}
	else
	{
		if(!is_true(level.use_clientside_board_fx))
		{
	    	chunk play_sound_on_ent( "break_barrier_piece" );
	    	wait( randomfloat( 0.3, 0.6 )); // 06 might be too much, a little seperation sounds great...
	    	chunk play_sound_on_ent( "break_barrier_piece" );
	    }
	    chunk.already_broken = true;
	}
}

zombie_bartear_audio_offset(chunk)
{
	chunk play_sound_on_ent( "grab_metal_bar" );
	//iprintlnbold("RRIIIPPPPP!!!");
	wait( randomfloat( 0.3, 0.6 ));
	chunk play_sound_on_ent( "break_metal_bar" );
	wait( randomfloat( 1.0, 1.3 ));
	chunk play_sound_on_ent( "drop_metal_bar" );
}

ensure_chunk_is_back_to_origin( chunk )
{
	if ( chunk.origin != chunk.og_origin )
	{
		chunk notsolid();
		chunk waittill( "movedone" );
	}
}

replace_chunk( chunk, perk, via_powerup )
{
	chunk update_states("mid_repair");
	assert( IsDefined( chunk.og_origin ) );
	assert( IsDefined( chunk.og_angles ) );

	has_perk = false;

	if( isDefined( perk ) )
	{
		has_perk = true;
	}

	// need to remove this for the bar bend repair
	//chunk Show();

	sound = "rebuild_barrier_hover";
	if( IsDefined( chunk.script_presound ) )
	{
		sound = chunk.script_presound;
	}
	// TODO - get rebuild barrier sounds from other maps working on Five
	/*// Five metal barrier
	if(IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board" && IsDefined(chunk.material) && chunk.material == "metal")
	{
		sound = "zmb_vent_fix";
	}*/


	if( !isdefined( via_powerup  ) )
	{
		play_sound_at_pos( sound, chunk.origin );
	}


	only_z = ( chunk.origin[0], chunk.origin[1], chunk.og_origin[2] );

// JL I setup the bar check on the inside of the else, but I will probably need to make it the first check and incompass all of it.

	if( IsDefined(chunk.script_parameters) )
	{

		if( chunk.script_parameters == "board" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{
			chunk Show();

			if( has_perk )
			{
				if( "specialty_fastreload" == perk )
				{

					chunk RotateTo( chunk.og_angles,  0.15 );
					chunk waittill_notify_or_timeout( "rotatedone", 1 );
					wait( 0.1 );
				}
				else if( "specialty_fastreload_upgrade" == perk )
				{

					chunk RotateTo( chunk.og_angles,  0.08 );
					chunk waittill_notify_or_timeout( "rotatedone", 1 );
					wait( 0.1 );
				}
			}
			else
			{
				chunk RotateTo( chunk.angles + (  0,  -9, 0 ) , 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.angles + (  0,  18,  0 ) , 0.1 );
				chunk waittill ("rotatedone");
				chunk MoveTo( only_z, 0.15);
				chunk RotateTo( chunk.og_angles,  0.3 );
				chunk waittill_notify_or_timeout( "rotatedone", 1 );
				wait( 0.2 );
			}
		}
		// DCS: new start in good shape.
		else if(chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents" )
		{
			if(IsDefined(chunk.unbroken_section))
			{
				//chunk.unbroken_section self_delete();
				//chunk Show();
				chunk.unbroken_section Show();
			}
			else
			{
				chunk Show();
			}

			if( has_perk )
			{
				if( "specialty_fastreload" == perk )
				{

					chunk RotateTo( chunk.og_angles,  0.15 );
					chunk waittill_notify_or_timeout( "rotatedone", 1 );
					wait( 0.1 );
				}
				else if( "specialty_fastreload_upgrade" == perk )
				{

					chunk RotateTo( chunk.og_angles,  0.08 );
					chunk waittill_notify_or_timeout( "rotatedone", 1 );
					wait( 0.1 );
				}
			}
			else
			{
				chunk RotateTo( chunk.angles + (  0,  -9, 0 ) , 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.angles + (  0,  18,  0 ) , 0.1 );
				chunk waittill ("rotatedone");
				chunk MoveTo( only_z, 0.15);
				chunk RotateTo( chunk.og_angles,  0.3 );
				chunk waittill_notify_or_timeout( "rotatedone", 1 );
				wait( 0.2 );
			}
		}


		if( IsDefined(chunk.script_parameters) )
		{

			if( chunk.script_parameters == "bar" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
			{

				chunk Show();

				if( has_perk )
				{
					if( "specialty_fastreload" == perk )
					{
						chunk RotateTo( chunk.og_angles,  0.15 );
						chunk waittill_notify_or_timeout( "rotatedone", 1 );
						wait( 0.1 );
					}
					else if( "specialty_fastreload_upgrade" == perk )
					{

						chunk RotateTo( chunk.og_angles,  0.08 );
						chunk waittill_notify_or_timeout( "rotatedone", 1 );
						wait( 0.1 );
					}
				}



				if(chunk.script_noteworthy == "3"  || chunk.script_noteworthy == "5")
				{
							// bend model back here... send notify0.
				}

					// was 180
				chunk RotateTo( chunk.angles + (  0,  -9, 0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.angles + (  0,  18,  0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk MoveTo( only_z, 0.15);
				chunk RotateTo( chunk.og_angles,  0.3 );
				chunk waittill_notify_or_timeout( "rotatedone", 1 );
				wait( 0.2 );
			}
		}
	}

	//Jl seperate board and bar type checks now
	if(isdefined(chunk.script_parameters))
	{
		if( chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents") // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{

			if( has_perk )
			{
				if( "specialty_fastreload" == perk )
				{
					chunk MoveTo( chunk.og_origin, 0.05 );
					chunk waittill_notify_or_timeout( "movedone", 1 );
					ensure_chunk_is_back_to_origin( chunk );
				}
				else if( "specialty_fastreload_upgrade" == perk )
				{
					chunk MoveTo( chunk.og_origin, 0.03 );
					chunk waittill_notify_or_timeout( "movedone", 1 );
					ensure_chunk_is_back_to_origin( chunk );
				}
			}
			else
			{
				chunk RotateTo( chunk.angles + (  0,  -9, 0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.angles + (  0,  18,  0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.og_angles,  0.1 );
				chunk waittill_notify_or_timeout( "RotateTo", 0.1 );
				chunk MoveTo( chunk.og_origin, 0.1 );
				chunk waittill_notify_or_timeout( "movedone", 1 ); // the time out is playing crashing out
				ensure_chunk_is_back_to_origin( chunk );
				// jl try flipping the boards as they move in to add more impact
			}
		}
	}

	if(isdefined(chunk.script_parameters))
	{

		if( chunk.script_parameters == "bar" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{



			if( has_perk )
			{
				if( "specialty_fastreload" == perk )
				{
					chunk Show();
					chunk MoveTo( chunk.og_origin, 0.05 );
					chunk waittill_notify_or_timeout( "movedone", 1 );
					ensure_chunk_is_back_to_origin( chunk );
				}
				else if( "specialty_fastreload_upgrade" == perk  )
				{
					chunk Show();
					chunk MoveTo( chunk.og_origin, 0.03 );
					chunk waittill_notify_or_timeout( "movedone", 1 );
					ensure_chunk_is_back_to_origin( chunk );
				}
			}
			else if(chunk.script_noteworthy == "3") // bend repiar
			{
				chunk RotateTo( chunk.angles + (  0,  -9, 0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.angles + (  0,  18,  0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.og_angles,  0.1 );
				chunk MoveTo( chunk.og_origin, 0.1 );
				chunk waittill_notify_or_timeout( "movedone", 1 );
				ensure_chunk_is_back_to_origin( chunk );
				//targets[j].destroyed = false;
				//level notify ("reset_bar_left");
				chunk Show();
			}

			else if(chunk.script_noteworthy == "5") // bend repiar
			{
				chunk RotateTo( chunk.angles + (  0,  -9, 0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.angles + (  0,  18,  0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.og_angles,  0.1 );
				chunk MoveTo( chunk.og_origin, 0.1 );
				chunk waittill_notify_or_timeout( "movedone", 1 );
				ensure_chunk_is_back_to_origin( chunk );
				// change this to chunk set
				//level notify ("reset_bar_right");
				chunk Show();
			}

			else
			{
				chunk Show();
				// jl added extra rotation for extra flair
				// 20, 25 these felt good
				chunk RotateTo( chunk.angles + (  0,  -9, 0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.angles + (  0,  18,  0 ), 0.1 );
				chunk waittill ("rotatedone");
				chunk RotateTo( chunk.og_angles,  0.1 );
				chunk MoveTo( chunk.og_origin, 0.1 );
				chunk waittill_notify_or_timeout( "movedone", 1 );
				ensure_chunk_is_back_to_origin( chunk );
				// jl try flipping the boards as they move in to add more impact
			}
		}
	}

	if( IsDefined(chunk.script_parameters) )
	{

		if( chunk.script_parameters == "grate" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{
			// Replace the grate
			if( IsDefined ( chunk.script_noteworthy ) && ( chunk.script_noteworthy == "6" ) )
			{
				amplitude1 = RandomfloatRange( 10, 15); // the amount of vibration in a degree , this feels good for wood but too much for bars
				period1 = RandomfloatRange( 0.3, 0.5); // number of vibrations within one second
				time1 = RandomfloatRange( 0.3, 0.4); // total time to move
				chunk vibrate(( 0, 180, 0 ), amplitude1,  period1, time1); // this looks really cool.. very sppplke
				wait(0.3);
				chunk RotateTo( chunk.og_angles,  0.1 );
				chunk MoveTo( chunk.og_origin, 0.1 );
				chunk waittill_notify_or_timeout( "movedone", 1 );
				// jl 02/11/10 I removed the line below because we don't need this check
				ensure_chunk_is_back_to_origin( chunk );
				// change this to chunk set
				//level notify ("reset_bar_right");
				chunk thread zombie_gratetear_audio_plus_fx_offset_repair_horizontal( chunk );
				chunk Show();
			}

			// If they are not noteworthy six then do a check for the entity index
			else
			{

				// was 180 chunk vibrate(( 0, 270, 0 ), 5, 1, 0.3);
				//wait(0.3);
				//chunk moveto( chunk.origin + ( 0, 0, 1000 ), 0.3, 0.1, 0.1 );
				wait( 0.5 );
				chunk waittill_notify_or_timeout( "movedone", 1 );
				chunk thread zombie_gratetear_audio_plus_fx_offset_repair_horizontal( chunk );
				chunk Show();
			}
		}
	}


	// jl moved this to another location
	//chunk waittill_notify_or_timeout( "movedone", 1 );
	//assert( chunk.origin == chunk.og_origin );

	// Jl commented out
	sound = "barrier_rebuild_slam";
	if( IsDefined( self.script_ender ) )
	{
		sound = self.script_ender;
	}
	if( IsDefined( chunk.script_string ) && chunk.script_string == "rock" )
	{
	    sound = "zmb_rock_fix";
	}
	if( IsDefined( chunk.script_parameters ) && chunk.script_parameters == "barricade_vents" )
	{
		sound = "zmb_vent_fix";
	}
	// TODO - get rebuild barrier sounds from other maps working on Five
	/*// Five glass barrier
	if(IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board" && IsDefined(chunk.material) && chunk.material == "glass")
	{
		sound = "zmb_break_glass_barrier";
	}
	// Five wall barrier
	if(IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board" && !IsDefined(chunk.material))
	{
		sound = "zmb_rock_fix";
	}
	// Five metal barrier
	if(IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board" && IsDefined(chunk.material) && chunk.material == "metal")
	{
		sound = "zmb_vent_fix";
	}*/
	
	/*iprintln("script_ender: " + self.script_ender);
	iprintln("script_string: " + chunk.script_string);
	iprintln("script_parameters: " + chunk.script_parameters);
	iprintln("material: " + chunk.material);
	iprintln("script_noteworthy: " + chunk.unbroken_section.script_noteworthy);*/

		//TUEY Play the sounds
		// JL, hey Tuey I added calls in here for our different windows so we can call different sounds
		if(isdefined(chunk.script_parameters))
		{
			if( chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents") // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
			{
				if(chunk.script_noteworthy == "1" || chunk.script_noteworthy == "5" || chunk.script_noteworthy == "6")
				{
							chunk thread zombie_boardtear_audio_plus_fx_offset_repair_horizontal(chunk);
				}
				else
				{
						chunk thread zombie_boardtear_audio_plus_fx_offset_repair_verticle(chunk);
				}

			}
		}

		if(isdefined(chunk.script_parameters))
		{
			if( chunk.script_parameters == "bar" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
			{
				if(chunk.script_noteworthy == "4"  || chunk.script_noteworthy == "6")
				{
						// Jluyties 03/09/10 I commented out fx for non model bars till we get the models
						if( IsDefined( chunk.script_squadname ) && ( chunk.script_squadname == "cosmodrome_storage_area" ) )
						{
							// I need to kill this thread.
						}

						if (!IsDefined( chunk.script_squadname ) )
						{
						// this doesn't work because it calls it at the beggining, I need to find where it locks into place
							chunk thread zombie_bartear_audio_plus_fx_offset_repair_horizontal(chunk);
						}
				}
				else
				{
						// Jluyties 03/09/10 I commented out fx for non model bars till we get the models
						if ( IsDefined( chunk.script_squadname ) && ( chunk.script_squadname == "cosmodrome_storage_area" ) )
						{
							// I need to kill this thread.
						}
						if (!IsDefined( chunk.script_squadname ) )
						{
						// this doesn't work because it calls it at the beggining, I need to find where it locks into place
									chunk thread zombie_bartear_audio_plus_fx_offset_repair_verticle(chunk);
						}
				}

			}
		}

	chunk Solid();
	if(IsDefined(chunk.unbroken_section))
	{
		chunk.unbroken_section Solid();
	}
	chunk update_states("repaired");
	chunk notify("repaired");

	fx = "wood_chunk_destory";
	if( IsDefined( self.script_fxid ) )
	{
		fx = self.script_fxid;
	}

	//AUDIO: Removing this isdefined, because we want the sound to play always
	//if( !IsDefined( via_powerup ) )
	//{

		//the repair sounds are now played on the client

		if( IsDefined( chunk.script_string ) && chunk.script_string == "rock" )
		{
			if(	!is_true(level.use_clientside_rock_tearin_fx))
			{
				play_sound_at_pos( sound, chunk.origin );
			}
		}
		else if( isDefined(chunk.script_parameters) && (chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents"))
		{
			if(!is_true(level.use_clientside_board_fx))
			{
				play_sound_at_pos( sound, chunk.origin );
			}
		}
		else
		{
			play_sound_at_pos( sound, chunk.origin );
		}

		//wait( randomfloat( 0.3, 0.6 ));
		//play_sound_at_pos( sound, chunk.origin );
		//playfx( level._effect[fx], chunk.origin ); // need to call at offset
		//JL u need to call the offset for particles and sounds from here
		//playfx( level._effect[fx], chunk.origin +( randomint( 20 ), randomint( 20 ), randomint( 10 ) ) );
		//playfx( level._effect[fx], chunk.origin +( randomint( 40 ), randomint( 40 ), randomint( 20 ) ) );
	//}

	// TODO - get rebuild barrier sounds from other maps working on Five
	/*// Five glass barrier
	if(IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board" && IsDefined(chunk.material) && chunk.material == "glass")
	{
		chunk PlaySound( "zmb_break_glass_barrier" );
	}
	// Five wall barrier
	if(IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board" && !IsDefined(chunk.material))
	{
		chunk PlaySound( "zmb_rock_fix" );
	}
	// Five metal barrier
	if(IsDefined(chunk.script_parameters) && chunk.script_parameters == "repair_board" && IsDefined(chunk.material) && chunk.material == "metal")
	{
		chunk PlaySound( "zmb_vent_fix" );
	}*/

	if( !Isdefined( self.clip ) )
	{
		chunk Disconnectpaths();
	}

}

// Jl we want different audio for each type of board or bar when they are repaired
// Need tags so the off sets for the effects is less code.
zombie_boardtear_audio_plus_fx_offset_repair_horizontal( chunk )
{

	if(isDefined(chunk.material) && chunk.material == "rock" )
	{
		if(is_true(level.use_clientside_rock_tearin_fx))
		{
			chunk clearclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_ROCK_FX);//PlayFX( level._effect["wall_break"], chunk.origin );
		}
		else
		{
			EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (0, 0, 30));
			wait( randomfloat( 0.3, 0.6 )); // 06 might be too much, a little seperation sounds great...
			chunk play_sound_on_ent( "break_barrier_piece" );
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (0, 0, -30));
		}
	}
	else
	{
		if(is_true(level.use_clientside_board_fx))
		{
			chunk clearclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOARD_HORIZONTAL_FX);
		}
		else
		{
			EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (0, 0, 30));
			wait( randomfloat( 0.3, 0.6 )); // 06 might be too much, a little seperation sounds great...
			chunk play_sound_on_ent( "break_barrier_piece" );
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (0, 0, -30));
		}
	}


}

zombie_boardtear_audio_plus_fx_offset_repair_verticle( chunk )
{
	if(isDefined(chunk.material) && chunk.material == "rock")
	{
		if (is_true(level.use_clientside_rock_tearin_fx))
		{
			chunk clearclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_ROCK_FX);//PlayFX( level._effect["wall_break"], chunk.origin );
		}
		else
		{

			EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (30, 0, 0));
			wait( randomfloat( 0.3, 0.6 )); // 06 might be too much, a little seperation sounds great...
			chunk play_sound_on_ent( "break_barrier_piece" );
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (-30, 0, 0));
		}
	}
	else
	{
		if(is_true(level.use_clientside_board_fx))
		{
			chunk clearclientflag(level._ZOMBIE_SCRIPTMOVER_FLAG_BOARD_VERTICAL_FX);
		}
		else
		{
			EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (30, 0, 0));
			wait( randomfloat( 0.3, 0.6 )); // 06 might be too much, a little seperation sounds great...
			chunk play_sound_on_ent( "break_barrier_piece" );
			PlayFx( level._effect["wood_chunk_destory"], chunk.origin + (-30, 0, 0));
		}
	}


}


zombie_gratetear_audio_plus_fx_offset_repair_horizontal( chunk )
{
	EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
	chunk play_sound_on_ent( "bar_rebuild_slam" );

		switch( randomInt( 9 ) ) // This sets up random versions of the bars being pulled apart for variety
		{
			case 0:
							PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
				break;

			case 1:
							PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );

				break;

			case 2:
							PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );

				break;

			case 3:
							PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );

				break;

			case 4:
							PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
				break;

			case 5:
							PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
				break;
			case 6:
							PlayFX( level._effect["fx_zombie_bar_break_lite"], chunk.origin + (-30, 0, 0) );
				break;
			case 7:
							PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
				break;
			case 8:
							PlayFX( level._effect["fx_zombie_bar_break"], chunk.origin + (-30, 0, 0) );
				break;
		}

}


zombie_bartear_audio_plus_fx_offset_repair_horizontal( chunk )
{

	EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
	chunk play_sound_on_ent( "bar_rebuild_slam" );


		switch( randomInt( 9 ) ) // This sets up random versions of the bars being pulled apart for variety
		{
			case 0:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
				break;

			case 1:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_right" );
				break;

			case 2:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_right" );
				break;

			case 3:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
				break;

			case 4:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
				break;

			case 5:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_left" );
				break;
			case 6:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_right" );
				break;
			case 7:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_left" );
				break;
			case 8:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_right" );
				break;
		}

}

zombie_bartear_audio_plus_fx_offset_repair_verticle(chunk)
{
	EarthQuake( RandomFloatRange( 0.3, 0.4 ), RandomFloatRange(0.2, 0.4), chunk.origin, 150 ); // do I want an increment if more are gone...
	chunk play_sound_on_ent( "bar_rebuild_slam" );


		switch( randomInt( 9 ) ) // This sets up random versions of the bars being pulled apart for variety
		{
			case 0:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
				break;

			case 1:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_top" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_bottom" );
				break;

			case 2:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_bottom" );
				break;

			case 3:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_top" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
				break;

			case 4:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
							wait( randomfloat( 0.0, 0.3 ));
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
				break;

			case 5:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_top" );
				break;
			case 6:
							PlayFXOnTag( level._effect["fx_zombie_bar_break_lite"], chunk, "Tag_fx_bottom" );
				break;
			case 7:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_top" );
				break;
			case 8:
							PlayFXOnTag( level._effect["fx_zombie_bar_break"], chunk, "Tag_fx_bottom" );
				break;
		}
}

add_new_zombie_spawners()
{
	if( isdefined( self.target ) )
	{
		self.possible_spawners = getentarray( self.target, "targetname" );
	}

	if( isdefined( self.script_string ) )
	{
		spawners = getentarray( self.script_string, "targetname" );
		self.possible_spawners = array_combine( self.possible_spawners, spawners );
	}

	if( !isdefined( self.possible_spawners ) )
	{
		return;
	}

	// add new check if they've been added already
	zombies_to_add = self.possible_spawners;

	for( i = 0; i < self.possible_spawners.size; i++ )
	{
		self.possible_spawners[i].is_enabled = true;
		add_spawner( self.possible_spawners[i] );
	}
}

//
// Flag Blocker ----------------------------------------------------------------------------------- //
//

flag_blocker()
{
	if( !IsDefined( self.script_flag_wait ) )
	{
		AssertMsg( "Flag Blocker at " + self.origin + " does not have a script_flag_wait key value pair" );
		return;
	}

	if( !IsDefined( level.flag[self.script_flag_wait] ) )
	{
		flag_init( self.script_flag_wait );
	}

	type = "connectpaths";
	if( IsDefined( self.script_noteworthy ) )
	{
		type = self.script_noteworthy;
	}

	flag_wait( self.script_flag_wait );

	self script_delay();

	if( type == "connectpaths" )
	{
		self ConnectPaths();
		//FOCKER
		//iprintlnbold("BOARDS AREE ALL DOWN!!!");
		self disable_trigger();
		return;
	}

	if( type == "disconnectpaths" )
	{
		self DisconnectPaths();
		//iprintlnbold("BOARDS ARE ALL UP!!!");
		self disable_trigger();
		return;
	}

	AssertMsg( "flag blocker at " + self.origin + ", the type \"" + type + "\" is not recognized" );
}

update_states( states )
{
	assertex( isdefined( states ) );

	self.state = states;

}


//*****************************************************************************
//	SHUTTERS - they cover windows and prevent zombies from spawning and entering through them
//
//		Shutter Switch Trigger
//			targetname		"window_shutter"
//			target			targets all related entities.  script will sort them out
//			script_int		number of players needed to keep shutter open
//							If you have fewer players, the shutter will be closed permanently
//			script_wait		length of time to keep shutter closed once activated
//
//	Shutter Switch Trigger targets the following:
//
//		Area affected by the shutter
//			trigger_multi - (all things that must be killed or deactivated must be encompased by this)/
//
//		Shutter Switch Model
//			script_model
//
//		Shutter Light
//			script_model - changes color depending on usage
//
//		Shutter
//			script_model/brushmodel - the thing that will move to cover the window
//			script_string		the movement mode the shutter will use, like "move"
//								(see doors, may require other fields to be set)
//
//*****************************************************************************
shutter_init()
{
	// Find shutter, handle, light & trigger
	self.shutters = [];
	self.lights = [];
	self.area_triggers = [];
//	self.type = undefined;

	targets = GetEntArray(self.target, "targetname" );
	for(i=0;i<targets.size;i++)
	{
		if ( IsDefined( targets[i].script_string ) )
		{
			self.shutters[ self.shutters.size ] = targets[i];
		}
		else if(targets[i].classname == "trigger_multiple")
		{
			self.area_triggers[ self.area_triggers.size ] = targets[i];
		}
		else if(targets[i].classname == "script_model")
		{
			if (targets[i].model == "zombie_zapper_cagelight" )
			{
				self.lights[ self.lights.size ] = targets[i];
			}
			else if(targets[i].model == "zombie_zapper_handle")
			{
				self.handle = targets[i];
			}
		}
	}

	//	Add check for number of players
	flag_wait( "all_players_connected" );
	players = GetPlayers();

	// If the number of players is >= self.script_int keep it open
	min_size = 4;
	if ( IsDefined( self.script_int ) )
	{
		min_size = self.script_int;
	}

	if ( players.size > min_size )
	{
		//make light green.  may start red if we decide to connect to power
		shutter_light_green( self.lights );

		// Door has been activated, make it do its thing
		for(i=0;i<self.shutters.size;i++)
		{
			if( self.shutters[i].script_string == "anim" )
			{
				AssertEx( IsDefined( self.shutters[i].script_animname ), "Blocker_init: You must specify a script_animname for "+self.shutters[i].targetname );
				AssertEx( IsDefined( level.scr_anim[ self.shutters[i].script_animname ] ), "Blocker_init: You must define a level.scr_anim for script_anim -> "+self.shutters[i].script_animname );
				AssertEx( IsDefined( level.blocker_anim_func ), "Blocker_init: You must define a level.blocker_anim_func" );
			}
			self.shutters[i] door_activate( 0.05 );
		}

		cost = 1000;
		if( IsDefined( self.zombie_cost ) )
		{
			cost = self.zombie_cost;
		}

		self set_hint_string( self, "default_buy_door_" + cost );
//		self thread add_teampot_icon();
//		self UseTriggerRequireLookAt();
		self thread shutter_think();
	}
	else	// shut it down permanently
	{
		//make light red
//		shutter_light_red( self.lights );

		// Keep it off
		self disable_trigger();

		self thread shutter_enable_zone( false );
	}
}

//*****************************************************************************
//	Swaps a cage light model to the red one.
//*****************************************************************************
shutter_light_red( shutter_lights )
{
	for(i=0;i<shutter_lights.size;i++)
	{
		shutter_lights[i] setmodel("zombie_zapper_cagelight_red");

		if(isDefined(shutter_lights[i].fx))
		{
			shutter_lights[i].fx delete();
		}

		shutter_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_red", 2, "script_model", shutter_lights[i].origin );
		shutter_lights[i].fx setmodel("tag_origin");
		shutter_lights[i].fx.angles = shutter_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_notready"],shutter_lights[i].fx,"tag_origin");
	}
}


//*****************************************************************************
//	Swaps a cage light model to the green one.
//*****************************************************************************
shutter_light_green( shutter_lights )
{
	for(i=0;i<shutter_lights.size;i++)
	{
		shutter_lights[i] setmodel("zombie_zapper_cagelight_green");

		if(isDefined(shutter_lights[i].fx))
		{
			shutter_lights[i].fx delete();
		}

		shutter_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_green", 2, "script_model", shutter_lights[i].origin );
		shutter_lights[i].fx setmodel("tag_origin");
		shutter_lights[i].fx.angles = shutter_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_ready"],shutter_lights[i].fx,"tag_origin");
	}
}


//*****************************************************************************
// It's a throw switch
//*****************************************************************************
shutter_move_switch()
{
	if(IsDefined(self.handle))
	{
		// Rotate switch model
		self.handle rotatepitch( 180, .5 );
		self.handle playsound( "amb_sparks_l_b" );
		self.handle waittill( "rotatedone" );

		// When "available" notify hit, bring back the level
		self notify( "switch_activated" );
		self waittill( "available" );

		self.handle rotatepitch( -180, .5 );
	}
}


//*****************************************************************************
// Shutter think
//		Wait until the handle's pulled and then close the shutter for X time
//	Then reopen.
//*****************************************************************************
shutter_think()
{
	while( 1 )
	{
		self waittill( "trigger", who );
		if( !who UseButtonPressed() )
		{
			continue;
		}

		if( who in_revive_trigger() )
		{
			continue;
		}

		if( is_player_valid( who ) )
		{
			// Check to see if you can afford this and deduct money if so
			players = get_players();
			if ( players.size == 1 && who.score >= self.zombie_cost )
			{
				// solo buy
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
			}
			else if( level.team_pool[ who.team_num ].score >= self.zombie_cost )
			{
				// team buy
				who maps\_zombiemode_score::minus_to_team_score( self.zombie_cost );
			}
			else if( level.team_pool[ who.team_num ].score + who.score >= self.zombie_cost )
			{
				// team funds + player funds
				team_points = level.team_pool[ who.team_num ].score;
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost - team_points );
				who maps\_zombiemode_score::minus_to_team_score( team_points );
			}
			else // Not enough money
			{
				play_sound_at_pos( "zmb_no_cha_ching", self.shutters[0].origin );
				who maps\_zombiemode_audio::create_and_play_dialog( "general", "door_deny", undefined, 0 );
				continue;
			}

			bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type door", who.playername, who.score, level.team_pool[ who.team_num ].score, level.round_number, self.zombie_cost, self.target, self.origin );
		}

		// shutter has been activated, make it do its thing

		// rotate switch
		self disable_trigger();
		self thread shutter_move_switch();
		shutter_light_red( self.lights );

		// wait for switch to rotate
		self waittill( "switch_activated" );

		// Door has been activated, make it do its thing
		for(i=0;i<self.shutters.size;i++)
		{
			// Don't thread this so the doors don't move at once
			self.shutters[i] door_activate( undefined, false );
		}

		self thread shutter_enable_zone( false );
		delay = 10;
		if ( IsDefined( self.script_wait ) )
		{
			delay = self.script_wait ;
		}
		wait( delay );

		self notify( "available" );
		self thread shutter_enable_zone( true );

		// Deactivate the doors
		for(i=0;i<self.shutters.size;i++)
		{
			// Don't thread this so the doors don't move at once
			self.shutters[i] door_activate( undefined, true );
		}

		// Let the switch get back up
		wait(1);

		shutter_light_green( self.lights );
		self enable_trigger();
	}
}


//
//	Disables spawners and rise locations in the affected areas as
//	well as killing any active spawners and adding them back into the spawn pool
//	enable is true if enabling the area and false if disabling.
shutter_enable_zone( set_enable )
{
	//	Shut off the spawners
	zkeys = GetArrayKeys( level.zones );
	for( z=0; z<zkeys.size; z++ )
	{
		zone_name = zkeys[z];
		zone = level.zones[ zone_name ];
		for(s=0;s<zone.spawners.size;s++)
		{
			for ( at=0; at<self.area_triggers.size; at++ )
			{
				if ( zone.spawners[s] IsTouching( self.area_triggers[at] ) )
				{
					zone.spawners[s].is_enabled = set_enable;
				}
			}
		}

		// Making an assumption that if one of the zone's spawners is in the array, then all of them are in the array
// 		for(ds=0;ds<zone.dog_spawners.size;ds++)
// 		{
// 			for ( at=0; at<self.area_triggers.size; at++ )
// 			{
// 				if ( zone.dog_spawners[ds] IsTouching( self.area_triggers[at] ) )
// 				{
// 					zone.dog_spawners[ds].is_enabled = set_enable;
// 				}
// 			}
// 		}

		// Check rise locations
		for(rl=0; rl<zone.rise_locations.size; rl++)
		{
			for ( at=0; at<self.area_triggers.size; at++ )
			{
//TODO Begin crazy hack to see if a struct is in the volume.  Do not keep this crap in!!!
				org = Spawn( "script_origin", zone.rise_locations[rl].origin );
				if ( org IsTouching( self.area_triggers[at] ) )
				{
					zone.rise_locations[rl].is_enabled = set_enable;
				}
				org delete();
// 				if ( zone.rise_locations[rl] IsTouching( self.area_triggers[at] ) )
// 				{
// 					zone.rise_locations[rl].is_enabled = set_enable;
// 				}
			}
		}
	}

	// If we're disabling the area, we'll need to kill any AI in the area since they
	//	can't go anywhere
	if ( !set_enable )
	{
		// First wait for the zone manager loop to cycle once and remove the
		//	spawn locations in the area from the list of available spawn locations
		wait( 1.5 );

		// Okay, now kill whoever's in the area
		ai_array = GetAIArray( "axis" );
		num_to_add = 0;
		for ( ai_num = 0; ai_num < ai_array.size; ai_num++ )
		{
			ai = ai_array[ ai_num ];
			for ( i=0; i<self.area_triggers.size; i++ )
			{
				if ( IsAlive(ai) && ai IsTouching( self.area_triggers[i] ) )
				{
					ai DoDamage( ai.health, ai.origin );
					num_to_add++;
				}
			}
		}

		level.zombie_total += num_to_add;
	}
}





replace_chunk_instant( chunk )
{
	chunk update_states("mid_repair");
	assert( IsDefined( chunk.og_origin ) );
	assert( IsDefined( chunk.og_angles ) );

	if( IsDefined(chunk.script_parameters) )
	{
		chunk Show();
		chunk.origin = chunk.og_origin;
		chunk.angles = chunk.og_angles;

		if( chunk.script_parameters == "board" || chunk.script_parameters == "repair_board" || chunk.script_parameters == "barricade_vents") // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{
			if(chunk.script_noteworthy == "1" || chunk.script_noteworthy == "4" ||chunk.script_noteworthy == "5" || chunk.script_noteworthy == "6")
			{

				chunk thread zombie_boardtear_audio_plus_fx_offset_repair_horizontal(chunk);
			}
			else
			{
				chunk thread zombie_boardtear_audio_plus_fx_offset_repair_verticle(chunk);
			}

		}

		else if( chunk.script_parameters == "bar" ) // jl this is new check to see if it is a board then do board anims, this needs to hold the entire function
		{
			if(chunk.script_noteworthy == "4"  || chunk.script_noteworthy == "6")
			{
				// Jluyties 03/09/10 I commented out fx for non model bars till we get the models
				if( IsDefined( chunk.script_squadname ) && ( chunk.script_squadname == "cosmodrome_storage_area" ) )
				{
					// I need to kill this thread.
				}

				if (!IsDefined( chunk.script_squadname ) )
				{
				// this doesn't work because it calls it at the beggining, I need to find where it locks into place
					chunk thread zombie_bartear_audio_plus_fx_offset_repair_horizontal(chunk);
				}
			}
			else
			{
				// Jluyties 03/09/10 I commented out fx for non model bars till we get the models
				if ( IsDefined( chunk.script_squadname ) && ( chunk.script_squadname == "cosmodrome_storage_area" ) )
				{
					// I need to kill this thread.
				}
				if (!IsDefined( chunk.script_squadname ) )
				{
				// this doesn't work because it calls it at the beggining, I need to find where it locks into place
							chunk thread zombie_bartear_audio_plus_fx_offset_repair_verticle(chunk);
				}
			}

		}
	}

	chunk Solid();
	chunk update_states("repaired");

	if( !Isdefined( self.clip ) )
	{
		chunk Disconnectpaths();
	}

}


quantum_bomb_open_nearest_door_validation( position )
{
	range_squared = 180 * 180; // 15 feet

	zombie_doors = GetEntArray( "zombie_door", "targetname" );
	for( i = 0; i < zombie_doors.size; i++ )
	{
		if ( DistanceSquared( zombie_doors[i].origin, position ) < range_squared )
		{
			return true;
		}
	}

	zombie_airlock_doors = GetEntArray( "zombie_airlock_buy", "targetname" );
	for( i = 0; i < zombie_airlock_doors.size; i++ )
	{
		if ( DistanceSquared( zombie_airlock_doors[i].origin, position ) < range_squared )
		{
			return true;
		}
	}

	zombie_debris = GetEntArray( "zombie_debris", "targetname" );
	for( i = 0; i < zombie_debris.size; i++ )
	{
		if ( DistanceSquared( zombie_debris[i].origin, position ) < range_squared )
		{
			return true;
		}
	}

	return false;
}


quantum_bomb_open_nearest_door_result( position )
{
	range_squared = 180 * 180; // 15 feet

	zombie_doors = GetEntArray( "zombie_door", "targetname" );
	for( i = 0; i < zombie_doors.size; i++ )
	{
		if ( DistanceSquared( zombie_doors[i].origin, position ) < range_squared )
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
			zombie_doors[i] notify( "trigger", self, true );
			[[level.quantum_bomb_play_area_effect_func]]( position );
			return;
		}
	}

	zombie_airlock_doors = GetEntArray( "zombie_airlock_buy", "targetname" );
	for( i = 0; i < zombie_airlock_doors.size; i++ )
	{
		if ( DistanceSquared( zombie_airlock_doors[i].origin, position ) < range_squared )
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
			zombie_airlock_doors[i] notify( "trigger", self, true );
			[[level.quantum_bomb_play_area_effect_func]]( position );
			return;
		}
	}

	zombie_debris = GetEntArray( "zombie_debris", "targetname" );
	for( i = 0; i < zombie_debris.size; i++ )
	{
		if ( DistanceSquared( zombie_debris[i].origin, position ) < range_squared )
		{
			self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
			zombie_debris[i] notify( "trigger", self, true );
			[[level.quantum_bomb_play_area_effect_func]]( position );
			return;
		}
	}
}
