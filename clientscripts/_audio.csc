// Client side audio functionality

#include clientscripts\_utility;


audio_init( localClientNum )
{
	if( localClientNum == 0 )
	{
		snd_snapshot_init();
		thread snd_snapshot_level_fadein();

		startSoundRandoms( localClientNum );
		startSoundLoops();
		startLineEmitters();

		thread bump_trigger_start();
		thread init_audio_step_triggers();
		thread start_player_health_snapshot();
		//thread berzerk_thread();

		init_after_save_restore();
	}
}

init_after_save_restore()
{
	level waittill( "save_restore" );
	level thread audio_init( 0 );
}

snd_snapshot_init()
{
	level._sndActiveSnapshot = "default";

	if(!isdefined(level._sndNextSnapshot))
	{
		level._sndNextSnapshot = "default";
	}

	setgroupsnapshot( level._sndActiveSnapshot );

	thread snd_snapshot_think();
	thread snd_snapshot_save();
	//thread sound_movie_snapshot_start();
	//thread sound_movie_snapshot_stop();
	//thread sound_movie_snapshot_alloff_but_mid_start();
}

snd_snapshot_save()
{
	level waittill( "save_restore" );
	setgroupsnapshot( level._sndActiveSnapshot );
}

snd_set_snapshot( state )
{
	level._sndNextSnapshot = state;

	println( "snd snapshot debug: set state '"+state+"'" );

	level notify( "new_bus" );
}

snd_snapshot_think()
{
	level endon( "save_restore" );

	for(;;)
	{
		if( level._sndActiveSnapshot == level._sndNextSnapshot ) //state didn't change during transition
		{
			level waittill( "new_bus" );
		}

		if( level._sndActiveSnapshot == level._sndNextSnapshot ) //got same one twice, ignore
		{
			continue;
		}

		assert( IsDefined( level._sndNextSnapshot ) );
		assert( IsDefined( level._sndActiveSnapshot ) );

		setgroupsnapshot( level._sndNextSnapshot );

		level._sndActiveSnapshot = level._sndNextSnapshot;
	}
}

snd_snapshot_level_fadein()
{
	//level endon( "save_restore" );
	level notify( "end_duplicate_fadein" );
	level endon( "end_duplicate_fadein" );

	for(;;)
	{
//		PrintLn( "fade_tst: setting value to 1.0" );
		SetLevelFadeSnapshot( "fadein", 1.0 ); //"fadein"

		waitforclient( 0 );

		wait( 0.5 );

		snapshot_value = 1.0;
		while( snapshot_value > 0.0 )
		{
			snapshot_value -= 0.05;
			SetLevelFadeSnapshot( "fadein", snapshot_value );
//			PrintLn( "fade_tst: value " + snapshot_value );
			wait( 0.02 );
		}

//		PrintLn( "fade_tst final: value " + snapshot_value + " setting to 0.0" );
		SetLevelFadeSnapshot( "fadein", 0.0 );

		if( level.zombiemode == true )
		{
		    return;
		}

		player = getlocalplayer(0);
		player waittill("respawn");
	}
}

soundRandom_Thread( localClientNum, randSound )
{
	level endon( "save_restore" );

	if( !IsDefined( randSound.script_wait_min ) )
	{
		randSound.script_wait_min = 1;
	}
	if( !IsDefined( randSound.script_wait_max ) )
	{
		randSound.script_wait_max = 3;
	}

	/#
	if( getdvarint( #"debug_audio" ) > 0 )
	{
			println( "*** Client : SR ( " + randSound.script_wait_min + " - " + randSound.script_wait_max + ")" );
	}
	#/

	while( 1 )
	{
		wait( RandomFloatRange( randSound.script_wait_min, randSound.script_wait_max ) );

		if( !IsDefined( randSound.script_sound ) )
		{
			println( "ambient sound at "+randSound.origin+" has undefined script_sound" );
		}
		else
		{
			playsound( localClientNum, randSound.script_sound, randSound.origin );
		}

		/#
		if( getdvarint( #"debug_audio" ) > 0 )
		{
			print3d( randSound.origin, randSound.script_sound, (0.0, 0.8, 0.0), 1, 3, 45 );
		}
		#/
	}
}


startSoundRandoms( localClientNum )
{
	randoms = GetStructArray( "random", "script_label" );

	if( IsDefined( randoms ) && randoms.size > 0 )
	{
		println( "*** Client : Initialising random sounds - " + randoms.size + " emitters." );
		for( i = 0; i < randoms.size; i++ )
		{
			thread soundRandom_Thread( localClientNum, randoms[i] );
		}
	}
	else
	{
		println( "*** Client : No random sounds." );
	}
}

//self is looper struct
soundLoopThink()
{
	if( !IsDefined( self.script_sound ) )
	{
		return;
	}

	if( !IsDefined( self.origin ) )
	{
		return;
	}

	level endon( "save_restore" );

	//println("starting loop loop");

	notifyName = "";
	assert( IsDefined( notifyName ) );

	if( IsDefined( self.script_string ) )
	{
		notifyName = self.script_string;
	}
	assert( IsDefined( notifyName ) );

	started = true;

	if( IsDefined( self.script_int) )
	{
		started = self.script_int != 0;
	}

	if( started )
	{
		soundloopemitter( self.script_sound, self.origin );
	}

	if( notifyName != "" )
	{
		println( "starting loop notify" );

		for(;;)
		{
			level waittill( notifyName );
			//iprintlnbold("got looper notify "+notifyName);
			if(started)
			{
				soundstoploopemitter( self.script_sound, self.origin );
			}
			else
			{
				soundloopemitter( self.script_sound, self.origin );
			}
			started = !started;
		}
	}
	else
	{
		//println( "looper doesn't take notifies" );
	}
}

//self is line struct
soundLineThink()
{
	level endon("save_restore");
	//println("starting line line");

	if( !IsDefined( self.target) )
	{
		return;
	}

	target = getstruct( self.target, "targetname" );

	if( !IsDefined( target) )
	{
		return;
	}

	notifyName = "";

	if( IsDefined( self.script_string ) )
	{
		notifyName = self.script_string;
	}

	started = true;

	if( IsDefined( self.script_int) )
	{
		started = self.script_int != 0;
	}

	if( started )
	{
		soundLineEmitter( self.script_sound, self.origin, target.origin );
	}

	if( notifyName != "" )
	{
		println( "starting line notify" );

		for(;;)
		{
			level waittill( notifyName );
			//println("got line notify "+notifyName);
			if( started )
			{
				soundStopLineEmitter( self.script_sound, self.origin, target.origin );
			}
			else
			{
				soundLineEmitter( self.script_sound, self.origin, target.origin );
			}
			started = !started;
		}
	}
	else
	{
		//println( "line doesn't take notifies" );
	}
}


startSoundLoops()
{
	loopers = GetStructArray( "looper", "script_label" );

	if( IsDefined( loopers ) && loopers.size > 0 )
	{
		delay = 0;
		println( "*** Client : Initialising looper sounds - " + loopers.size + " emitters." );
		for( i = 0; i < loopers.size; i++ )
		{
			loopers[i] thread soundLoopThink();
			delay += 1;

			if( delay % 20 == 0 ) //don't send more than 20 a frame
			{
				wait( 0.01 );
			}
		}
	}
	else
	{
		println( "*** Client : No looper sounds." );
	}
}


startLineEmitters()
{
	lineEmitters = GetStructArray( "line_emitter", "script_label" );

	if( IsDefined( lineEmitters ) && lineEmitters.size > 0 )
	{
		delay = 0;
		println( "*** Client : Initialising line emitter sounds - " + lineEmitters.size + " emitters." );
		for( i = 0; i < lineEmitters.size; i++ )
		{
			lineEmitters[i] thread soundLineThink();
			delay += 1;

			if( delay % 20 == 0 ) //don't send more than 20 a frame
			{
				wait( 0.01 );
			}
		}
	}
	else
	{
		println( "*** Client : No line emitter sounds." );
	}
}


// TRIGGERS
init_audio_step_triggers()
{
	waitforclient( 0 ); // wait until the first snapshot has arrived

	trigs = GetEntArray( 0, "audio_step_trigger","targetname" );

	println( "Client : " + trigs.size + " audio_step_triggers." );
	array_thread( trigs, ::audio_step_trigger );
}

audio_step_trigger( trig )
{
	for(;;)
	{
		self waittill( "trigger", trigPlayer );

		// set up the trigs
		self thread trigger_thread( trigPlayer, ::trig_enter_audio_step_trigger, ::trig_leave_audio_step_trigger );
	}
}

trig_enter_audio_step_trigger( trigPlayer )
{
	//iprintlnbold("enter");

	if( !IsDefined( trigPlayer.movementtype ) )
	{
		trigPlayer.movementtype = "null";
	}
	// trigPlayer is the player
	// self is the trigger.
	//iprintlnbold("Ent :" + trigPlayer getentitynumber() + " enters."+ self getentitynumber());

	// set the step script_label for use in _footstep
	if( Isdefined( self.script_label) )
	{
		trigPlayer.step_sound = self.script_label;
	}
	if( Isdefined( self.script_sound ) && ( trigPlayer.movementtype == "sprint" ) )
	{
		// get real speed later
		volume = 9;
		self playsound( 0, self.script_sound, self.origin, volume );
	}
}

trig_leave_audio_step_trigger(trigPlayer)
{
	if( Isdefined( self.script_noteworthy ) && ( trigPlayer.movementtype == "sprint" ) )
	{
		// get real speed later
		volume = 9;
		self playsound( 0, self.script_noteworthy, self.origin, volume );
	}
	//iprintlnbold("exit");
	trigPlayer.step_sound = "null";
}

bump_trigger_start()
{
	//wait (.1);
	bump_trigs = GetEntArray( 0, "audio_bump_trigger", "targetname" );

	for( i = 0; i < bump_trigs.size; i++)
	{
		bump_trigs[i] thread thread_bump_trigger();
	}
}

thread_bump_trigger()
{
	//self endon("entity_shutdown");
	//iprintlnbold ("Found a trigger!");
	self thread bump_trigger_listener();
	if( !IsDefined( self.script_activated ) ) //Sets a flag to turn the trigger on or off
	{
		self.script_activated = 1;
	}

	for(;;)
	{
		self waittill ( "trigger", trigPlayer );

		self thread trigger_thread( trigPlayer, ::trig_enter_bump, ::trig_leave_bump );
	}
}

trig_enter_bump( ent )
{
	// iPrintLnBold( "enter bump: " );
	volume = get_vol_from_speed( ent );

	if( IsDefined( self.script_sound ) && self.script_activated )
	{
		// script_noteworthy is the alias that will play if your speed is lower than the script_wait float
		if( IsDefined( self.script_noteworthy ) && IsDefined(self.script_wait) && ( self.script_wait > volume ) )
		{
			test_id = self playsound( 0, self.script_noteworthy,self.origin, volume );
		}

		if( !IsDefined( self.script_wait ) || ( self.script_wait <= volume ) )
		{
			test_id = self playsound( 0, self.script_sound, self.origin, volume );
		}
	}
}

trig_leave_bump( ent )
{
	//iPrintLnBold( "leave bump: " );
}

bump_trigger_listener() //This will deactivate the trigger on a level notify if its stored on the trigger
{
	//Store End-On conditions in script_label so you can turn off the bump trigger if a condition is met
	if( IsDefined( self.script_label ) )
	{
		level waittill( self.script_label );
		self.script_activated = 0;
	}
}

// HEALTH (SNAPSHOT)
start_player_health_snapshot()
{
	//C. Ayers: Turning this off for Zombiemode, as it does some weird stuff
	if( IsDefined( level.zombiemode ) && level.zombiemode == true )
	{
	    return;
	}

	//PrintLn( "health_tst audio_init" );
	level endon( "save_restore" );
	wait( 1 );

	max_health = GetLocalClientMaxHealth( 0 );
	last_health = 0;

	health_snapshot = "pain_heavy_occlude";//"pain_light_occlude";

	/#
	level.tst_health = 0.0;
	level.tst_last_health = 0.0;
	level.tst_snap_value = 0;
	//self thread print_health();
	#/

	SetHealthSnapshot( health_snapshot, 0 );
	for( ;; )
	{
		wait ( 0.05 );

		health = GetLocalClientHealth( 0 );

        if( health > 70 )
        {
            health_scale = 0;
        }
        else
        {
		    health_scale = 1 - ( health * ( 1 / 100 ) );
		}
		SetHealthSnapshot( health_snapshot, health_scale );

		/#
		level.tst_health = health;
		level.tst_last_health = last_health;
		level.tst_snap_value = health_scale;

		last_health = health;
		#/
	}
}

/#
print_health()
{
	while( 1 )
	{
		wait( 0.5 );
		PrintLn( "health_tst player last_health: " + level.tst_last_health + " player health: " + level.tst_health );
		PrintLn( "health_tst value: " + level.tst_snap_value );
	}
}
#/

//this will do some mathmagic to scale to the min/max speed to min max volume
scale_speed(x1 ,x2 ,y1 ,y2 ,z )
{
	if ( z < x1)
		z = x1;
	if ( z > x2)
		z = x2;

	dx = x2 - x1;
	n = ( z - x1) / dx;
	dy = y2 - y1;
	w = (n*dy + y1);

	return w;
}

get_vol_from_speed( player )
{
	// values to map to a linear scale
	min_speed = 21;
	max_speed = 285;
	max_vol = 1;
	min_vol = .1;

	speed = player getspeed();

	// hack for ai until getspeed returns correct speed
	if(speed == 0 )
	{
		// iprintlnbold( "AI override" );
		speed = 175;
	}

	//Ayers - Added in specifically to override low footstep volume during tunnel sequence in Creek
	//Can be used to keep volume up artificially during any sequence
	if( IsDefined( level.footstep_vol_override ) )
	{
		min_vol = .5;
	}

	// make sure we are not getting negative vaules. may be unneeded
	abs_speed = absolute_value( int( speed ) );
	volume = scale_speed( min_speed, max_speed, min_vol, max_vol, abs_speed );
	//iprintlnbold( "Volume: " + volume + " Speed: " + abs_speed );

	return volume;
}

absolute_value( fowd )
{
	if( fowd < 0 )
		return (fowd*-1);
	else
		return fowd;
}

// self is the script origin mover
// the crazy math Alex C wrote on COD3, convered to GSC for COD5
closest_point_on_line_to_point( Point, LineStart, LineEnd )
{
	self endon ("end line sound");

	LineMagSqrd = lengthsquared(LineEnd - LineStart);

	t =	( ( ( Point[0] - LineStart[0] ) * ( LineEnd[0] - LineStart[0] ) ) +
		( ( Point[1] - LineStart[1] ) * ( LineEnd[1] - LineStart[1] ) ) +
		( ( Point[2] - LineStart[2] ) * ( LineEnd[2] - LineStart[2] ) ) ) /
		( LineMagSqrd );

	if( t < 0.0  )
	{
		self.origin = LineStart;
	}
	else if( t > 1.0 )
	{
		self.origin = LineEnd;
	}
	else
	{
		start_x = LineStart[0] + t * ( LineEnd[0] - LineStart[0] );
		start_y = LineStart[1] + t * ( LineEnd[1] - LineStart[1] );
		start_z = LineStart[2] + t * ( LineEnd[2] - LineStart[2] );

		self.origin = ( start_x, start_y, start_z );
	}
}


playloopat( localClientNum, aliasname, origin, fade )
{
	if( !IsDefined( fade ) )
		fade = 0;

	fake_ent = spawnfakeent( localClientNum );
	setfakeentorg( localClientNum, fake_ent, origin );
	playloopsound( localClientNum, fake_ent, aliasname, fade );
	return fake_ent;
}

snd_play_auto_fx( fxid, alias )
{
	for( i = 0; i < level.createFXent.size; i++ )
	{
		if( level.createFXent[i].v["fxid"] == fxid && !IsDefined( level.createFXent[i].soundEnt ) )
		{
			level.createFXent[i].soundEnt = spawnFakeEnt( 0 );

			/*
			real_ent playloopsound( <alias_name>, <fade_in_time> )
			playloopsound( <local_client>, <entity_id(fakeent)>, <aliasname>, <fade_in_time> )
			*/

			setfakeentorg( 0, level.createFXent[i].soundEnt, level.createFXent[i].v["origin"] );
			playloopsound( 0, level.createFXent[i].soundEnt, alias, .5 );
			//IPrintLnBold("playing FX autos " + alias);
		}
	}
}

snd_delete_auto_fx( fxid )
{
    for( i = 0; i < level.createFXent.size; i++ )
	{
		if( level.createFXent[i].v["fxid"] == fxid && IsDefined( level.createFXent[i].soundEnt ) )
		{
			deletefakeent(0, level.createFXent[i].soundEnt);
			level.createFXent[i].soundEnt = undefined;
		}
	}
}

snd_print_fx_id( fxid, type, ent )
{
	printLn( "^5 ******* fxid; " + fxid + "^5 type; " + type );
}

debug_line_emitter()
{
	while( 1 )
	{
		/#
		if( getdvarint( #"debug_audio" ) > 0 )
		{
			line( self.start, self.end, (0, 1, 0) );

			print3d( self.start, "START", (0.0, 0.8, 0.0), 1, 3, 1 );
			print3d( self.end, "END", (0.0, 0.8, 0.0), 1, 3, 1 );
			print3d( self.origin, self.script_sound, (0.0, 0.8, 0.0), 1, 3, 1 );
		}
		wait( 0.01 );
		#/
	}
}

move_sound_along_line()
{
	closest_dist = undefined;

	/#
	self thread debug_line_emitter();
	#/

	while( 1 )
	{
		self closest_point_on_line_to_point( getlocalclientpos( 0 ), self.start, self.end );

		if( IsDefined( self.fake_ent ) )
		{
			setfakeentorg( self.localClientNum, self.fake_ent, self.origin );
		}

		//Update the sound based on distance to the point
		closest_dist = DistanceSquared( getlocalclientpos( 0 ), self.origin );

		if( closest_dist > 1024 * 1024 )
		{
			wait( 2 );
		}
		else if( closest_dist > 512 * 512 )
		{
			wait( 0.2 );
		}
		else
		{
			wait( 0.05 );
		}
	}
}

line_sound_player()
{
	if( IsDefined( self.script_looping ) )
	{
		self.fake_ent = spawnfakeent( self.localClientNum );
		setfakeentorg( self.localClientNum, self.fake_ent, self.origin );
		playloopsound( self.localClientNum, self.fake_ent, self.script_sound );
	}
	else
	{
		playsound( self.localClientNum, self.script_sound, self.origin );
	}
}

//berzerk_thread()
//{
//	ent = spawnfakeent( 0) ;
//	for(;;)
//	{
//		level waittill( "berzerk_audio_on" );
//		playloopsound( 0, ent, "uin_berzerker_loop", 1 );
//		level waittill( "berzerk_audio_off" );
//		stoploopsound( 0, ent, 1 );
//	}
//}

soundwait( id )
{
	while( soundplaying( id ) )
	{
		wait( 0.1 );
	}
}
sound_movie_snapshot_start()
{
	while(1)
	{
		level waittill ("pms");
		wait(0.3);
		snd_set_snapshot ("alloff_except_voice_music");

	}
}
sound_movie_snapshot_alloff_but_mid_start()
{
	while(1)
	{
		level waittill ("pmsao");
		wait(0.2);
//ECKERT - Trigger the special alloff except for MID here
		snd_set_snapshot ("flashback_duck");

	}
}
sound_movie_snapshot_stop()
{
	while(1)
	{
		level waittill ("pmo");
		snd_set_snapshot ("default");

	}

}
