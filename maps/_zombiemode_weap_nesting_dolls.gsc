// For the  black hole bomb
#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

init()
{
	if( !nesting_dolls_exists() )
	{
		return;
	}

	// some tweakable variables
	level.nesting_dolls_launch_speed = 500;
	level.nesting_dolls_launch_angle = 45;
	level.nesting_dolls_too_close_dist = 100 * 100;
	level.nesting_dolls_det_time = 0.25;
	level.nesting_dolls_player_aim_dot = Cos( 45 / 2 );
	level.nesting_dolls_damage_radius = 180;

	// precalculate this once since launch speed and angle are constant
	gravity = getdvarfloat(#"bg_gravity");
	level.nesting_dolls_launch_peak_time = (( level.nesting_dolls_launch_speed * Sin( level.nesting_dolls_launch_angle ) ) / Abs( gravity )) * 0.5;

/#
	level.zombiemode_devgui_nesting_dolls_give = ::player_give_nesting_dolls;
#/

	level.nesting_dolls_max_ids = 10;

	// create the data structures
	setup_nesting_dolls_data();

	// Single nesting doll
	PreCacheItem( "zombie_nesting_doll_single" );
}

setup_nesting_dolls_data()
{
	// call the override if one is specified
	if ( IsDefined( level.nesting_dolls_override_setup ) )
	{
		[[ level.nesting_dolls_override_setup ]]();
		return;
	}

	// precache fx
	level._effect["nesting_doll_trail_blue"] = loadFx("maps/zombie/fx_zmb_trail_doll_blue");
	level._effect["nesting_doll_trail_green"] = loadFx("maps/zombie/fx_zmb_trail_doll_green");
	level._effect["nesting_doll_trail_red"] = loadFx("maps/zombie/fx_zmb_trail_doll_red");
	level._effect["nesting_doll_trail_yellow"] = loadFx("maps/zombie/fx_zmb_trail_doll_yellow");

	// create the outer array
	level.nesting_dolls_data = [];

	// dempsey
	level.nesting_dolls_data[0] = SpawnStruct();
	level.nesting_dolls_data[0].name = "dempsey";
	level.nesting_dolls_data[0].id = 16;
	level.nesting_dolls_data[0].trailFx = level._effect["nesting_doll_trail_blue"];

	// nikolai
	level.nesting_dolls_data[1] = SpawnStruct();
	level.nesting_dolls_data[1].name = "nikolai";
	level.nesting_dolls_data[1].id = 17;
	level.nesting_dolls_data[1].trailFx = level._effect["nesting_doll_trail_red"];

	// takeo
	level.nesting_dolls_data[2] = SpawnStruct();
	level.nesting_dolls_data[2].name = "takeo";
	level.nesting_dolls_data[2].id = 18;
	level.nesting_dolls_data[2].trailFx = level._effect["nesting_doll_trail_green"];

	// richtofen
	level.nesting_dolls_data[3] = SpawnStruct();
	level.nesting_dolls_data[3].name = "richtofen";
	level.nesting_dolls_data[3].id = 19;
	level.nesting_dolls_data[3].trailFx = level._effect["nesting_doll_trail_yellow"];

	// precache models
	PreCacheModel( "t5_nesting_bomb_world_doll1_dempsey" );
	PreCacheModel( "t5_nesting_bomb_world_doll2_dempsey" );
	PreCacheModel( "t5_nesting_bomb_world_doll3_dempsey" );
	PreCacheModel( "t5_nesting_bomb_world_doll4_dempsey" );

	PreCacheModel( "t5_nesting_bomb_world_doll1_nikolai" );
	PreCacheModel( "t5_nesting_bomb_world_doll2_nikolai" );
	PreCacheModel( "t5_nesting_bomb_world_doll3_nikolai" );
	PreCacheModel( "t5_nesting_bomb_world_doll4_nikolai" );

	PreCacheModel( "t5_nesting_bomb_world_doll1_takeo" );
	PreCacheModel( "t5_nesting_bomb_world_doll2_takeo" );
	PreCacheModel( "t5_nesting_bomb_world_doll3_takeo" );
	PreCacheModel( "t5_nesting_bomb_world_doll4_takeo" );

	PreCacheModel( "t5_nesting_bomb_world_doll1_richtofen" );
	PreCacheModel( "t5_nesting_bomb_world_doll2_richtofen" );
	PreCacheModel( "t5_nesting_bomb_world_doll3_richtofen" );
	PreCacheModel( "t5_nesting_bomb_world_doll4_richtofen" );
}

nesting_dolls_exists()
{
	return IsDefined( level.zombie_weapons["zombie_nesting_dolls"] );
}

player_give_nesting_dolls()
{
	// create our randomized index arrays here so we can pass the appropriate first cammo
	self nesting_dolls_create_randomized_indices( 0 );

	start_cammo = level.nesting_dolls_data[ self.nesting_dolls_randomized_indices[0][0] ].id;

	self giveweapon( "zombie_nesting_dolls", 0, self CalcWeaponOptions( start_cammo ) );
	self set_player_tactical_grenade( "zombie_nesting_dolls" );
	self thread player_handle_nesting_dolls();
}

#using_animtree( "zombie_cymbal_monkey" ); // WW: A new animtree or should we just use generic human's throw?
player_handle_nesting_dolls()
{
	//self notify( "starting_nesting_dolls" );
	self endon( "disconnect" );
	//self endon( "starting_nesting_dolls" );

	grenade = get_thrown_nesting_dolls();
	self thread player_handle_nesting_dolls();
	if( IsDefined( grenade ) )
	{
		if( self maps\_laststand::player_is_in_laststand() )
		{
			grenade delete();
			return;
		}

		self thread doll_spawner_cluster( grenade );
	}
}

doll_spawner( start_grenade )
{
	self endon( "disconnect" );
	self endon( "death" );

	// initialize the number of dolls
	num_dolls = 1;

	// define the maximum to spawn
	max_dolls = 4;

	// get the id of this doll run
	self nesting_dolls_set_id();

	// switch cammo
	self thread nesting_dolls_setup_next_doll_throw();

	// spin off the achievement threads
	//self thread nesting_dolls_track_achievement( self.doll_id );
	//self thread nesting_dolls_check_achievement( self.doll_id );

	// so the compiler doesn't puke
	if ( IsDefined( start_grenade ) )
	{
		start_grenade spawn_doll_model( self.doll_id, 0, self );
		start_grenade thread doll_behavior_explode_when_stopped( self, self.doll_id, 0 );
	}

	start_grenade waittill( "spawn_doll", origin, angles );

	while( num_dolls < max_dolls )
	{
		grenade_vel = self get_launch_velocity( origin, 2000 );
		if ( grenade_vel == ( 0, 0, 0 ) )
		{
			grenade_vel = self get_random_launch_velocity( origin, angles);
		}

		grenade = self MagicGrenadeType( "zombie_nesting_doll_single", origin, grenade_vel );
		grenade spawn_doll_model( self.doll_id, num_dolls, self );
		grenade thread doll_behavior_explode_when_stopped( self, self.doll_id, num_dolls );

		//self thread nesting_dolls_tesla_nearby_zombies( grenade );

		num_dolls++;

		grenade waittill( "spawn_doll", origin, angles );
	}
}

doll_spawner_cluster( start_grenade )
{
	self endon( "disconnect" );
	self endon( "death" );

	// initialize the number of dolls
	num_dolls = 1;

	// define the maximum to spawn
	max_dolls = 4;

	// get the id of this doll run
	self nesting_dolls_set_id();

	// switch cammo
	self thread nesting_dolls_setup_next_doll_throw();

	// spin off the achievement threads
	self thread nesting_dolls_track_achievement( self.doll_id );
	self thread nesting_dolls_check_achievement( self.doll_id );

	// so the compiler doesn't puke
	if ( IsDefined( start_grenade ) )
	{
		start_grenade.angles = (0, start_grenade.angles[1], 0);

		start_grenade spawn_doll_model( self.doll_id, 0, self );
		start_grenade thread doll_behavior_explode_when_stopped( self, self.doll_id, 0 );
	}

	start_grenade waittill( "spawn_doll", origin, angles );

	while( num_dolls < max_dolls )
	{

		// get a velocity
		grenade_vel = self get_cluster_launch_velocity( angles, num_dolls );

		// spawn a magic grenade
		grenade = self MagicGrenadeType( "zombie_nesting_doll_single", origin, grenade_vel );
		grenade.angles = (0, grenade.angles[1], 0);
		grenade spawn_doll_model( self.doll_id, num_dolls, self );

		grenade PlaySound( "wpn_nesting_pop_npc" );

		grenade thread doll_behavior_explode_when_stopped( self, self.doll_id, num_dolls );

		num_dolls++;

		wait( 0.25 );
	}
}

doll_do_damage( origin, owner, id, index )
{
	self waittill( "explode" );

	zombies = GetAiSpeciesArray( "axis", "all" );
	if ( zombies.size == 0 )
	{
		return;
	}

	zombie_sort = get_array_of_closest( origin, zombies, undefined, undefined, level.nesting_dolls_damage_radius );

	// "Name: DoDamage( <health>, <source position>, <attacker>, <destructible_piece_index>, <means of death>, <hitloc> )"
	for ( i = 0; i < zombie_sort.size; i++ )
	{
		if ( IsAlive( zombie_sort[i] ) )
		{
			if ( zombie_sort[i] DamageConeTrace( origin, owner ) == 1 )
			{
				//// Kill 'em
				//zombie_sort[i] DoDamage( zombie_sort[i].health + 666, origin, owner, 0, "explosive", "none" );

				// track for the achievement
				owner.nesting_dolls_tracker[id][index] = owner.nesting_dolls_tracker[id][index] + 1;

				// Debug
				//PrintLn("ID: " + id + " Doll: " + index + " Count: " + owner.nesting_dolls_tracker[id][index] );
			}
		}
	}

	RadiusDamage( origin, level.nesting_dolls_damage_radius, level.zombie_health + 666, level.zombie_health + 666, owner, "MOD_GRENADE_SPLASH", "zombie_nesting_doll_single" );
}

randomize_angles( angles )
{
	random_yaw = RandomIntRange( -45, 45 );
	random_pitch = RandomIntRange( -45, -35 );
	random = ( random_pitch, random_yaw, 0 );
	return_angles = angles + random;
	return return_angles;
}

get_random_launch_velocity( doll_origin, angles )
{
	angles = randomize_angles( angles );
	trace_dist = level.nesting_dolls_launch_speed * level.nesting_dolls_launch_peak_time;

	for ( i = 0; i < 4; i++ )
	{
		dir = AnglesToForward( angles );

		if ( BulletTracePassed( doll_origin, doll_origin + dir * trace_dist, false, undefined ) )
		{
			//Line( doll_origin, doll_origin + dir * trace_dist, (0, 1, 0), 1, false, 20 );

			grenade_vel = dir * level.nesting_dolls_launch_speed;
			return grenade_vel;
		}
		else
		{
			//Line( doll_origin, doll_origin + dir * trace_dist, (1, 0, 0), 1, false, 20 );

			angles = angles + (0, 90, 0);
		}
	}

	return (0, 0, level.nesting_dolls_launch_speed);
}

get_cluster_launch_velocity( angles, index )
{
	// pitch up
	random_pitch = RandomIntRange( -45, -35 );

	// array of offsets
	offsets = array( 45, 0, -45 );

	// offset based on index
	angles = angles + ( random_pitch, offsets[index - 1], 0 );

	// convert to vector
	dir = AnglesToForward( angles );

	// scale
	grenade_vel = dir * level.nesting_dolls_launch_speed;

	// return
	return grenade_vel;
}

get_launch_velocity( doll_origin, range )
{
	velocity = ( 0, 0, 0 );

	// give priority to the player aim'd target
	//target = self get_player_aim_best_doll_target( range );

	// no target...try dolls best target
	//if ( !IsDefined( target ) )
	//{
		target = get_doll_best_doll_target( doll_origin, range );
	//}

	// if we got something launch towards it
	if ( IsDefined( target ) )
	{
		target_origin = target get_target_leading_pos();

		// calculate a direction to this zombie
		dir = VectorToAngles( target_origin - doll_origin );
		dir = ( dir[0] - level.nesting_dolls_launch_angle, dir[1], dir[2] );
		dir = AnglesToForward( dir );

		// scale it
		velocity = dir * level.nesting_dolls_launch_speed;
	}

	return velocity;
}

get_target_leading_pos( )
{
	position = self.origin;

	//velocity = self GetAIVelocity();
	//if ( IsDefined( velocity ) )
	//{
	//	// lead by x number of frames (0.1 = 1 server frame)
	//	position = position + velocity * 1.0;
	//}

	return position;
}

spawn_doll_model( id, index, parent )
{
	// hide the grenade model
	self hide();

	// spawn the doll model
	self.doll_model = spawn( "script_model", self.origin );
	self.doll_model.angles = self.angles + (0, 180, 0);

	// fix out the index
	data_index = parent.nesting_dolls_randomized_indices[ id ][ index ];

	// get the name from the data array...
	name = level.nesting_dolls_data[ data_index ].name;

	// construct the name
	model_index = index + 1;
	model_name = "t5_nesting_bomb_world_doll" + model_index + "_" + name;

	// finish setting up
	self.doll_model SetModel( model_name );
	self.doll_model UseAnimTree( #animtree );
	self.doll_model LinkTo( self );

	// attach the effect
	PlayFxOnTag( level.nesting_dolls_data[ data_index ].trailFx, self.doll_model, "tag_origin" );

	// spin off the clean up thread here
	self.doll_model thread nesting_dolls_cleanup( self );
}

doll_behavior_explode_when_stopped( parent, doll_id, index )
{
	velocitySq = 10000*10000;
	oldPos = self.origin;

	wait .05;

	while( velocitySq != 0 )
	{
		wait( 0.1 );

		if( !isDefined( self ) )
		{
			break;
		}

		velocitySq = distanceSquared( self.origin, oldPos );
		oldPos = self.origin;
	}

	if( isDefined( self ) )
	{
		// spawn a new doll
		self notify( "spawn_doll", self.origin, self.angles );

		// spin the damage thread
		self thread doll_do_damage( self.origin, parent, doll_id, index );

		// blow up!
		self ResetMissileDetonationTime( level.nesting_dolls_det_time );

		// if we're the last doll
		if ( IsDefined( index ) && index == 3 )
		{
			parent thread nesting_dolls_end_achievement_tracking( doll_id );
		}
	}
}

nesting_dolls_end_achievement_tracking( doll_id )
{
	// wait for the grenade to detonate + a little buffer
	wait( level.nesting_dolls_det_time + 0.1 );

	// send the notify
	//IPrintLn("STOP TRACKING: " + doll_id );
	self notify( "end_achievement_tracker" + doll_id );
}

get_player_aim_best_doll_target( range )
{
	view_pos = self GetWeaponMuzzlePoint();

	// Add a 10% epsilon to the range on this call to get guys right on the edge
	zombies = get_array_of_closest( view_pos, GetAiSpeciesArray( "axis", "all" ), undefined, undefined, (range * 1.1) );
	if ( !isDefined( zombies ) )
	{
		return;
	}

	range_squared = range * range;
	forward_view_angles = self GetWeaponForwardDir();
	end_pos = view_pos + vector_scale( forward_view_angles, range );

	best_dot = -999.0;
	best_target = undefined;

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		// test within range
		test_origin = zombies[i] getcentroid();
		test_range_squared = DistanceSquared( view_pos, test_origin );
		if ( test_range_squared > range_squared )
		{
			return; // everything else in the list will be out of range
		}

		// get the dot product
		normal = VectorNormalize( test_origin - view_pos );
		dot = VectorDot( forward_view_angles, normal );

		// bail if they are behind us
		if ( dot < 0 )
		{
			continue;
		}

		// check to see if we're in the cone angle
		if ( dot < level.nesting_dolls_player_aim_dot )
		{
			continue;
		}

		// see if we are damageable
		if ( 0 == zombies[i] DamageConeTrace( view_pos, self ) )
		{
			continue;
		}

		// if we've passed all the criteria check to see if we're the best target
		if ( dot > best_dot )
		{
			best_dot = dot;
			best_target = zombies[i];
		}
	}

/#
	//if ( IsDefined( best_target ) )
	//{
	//	best_target nesting_dolls_debug_print( "AIM", ( 1, 0, 0) );
	//}
#/

	return best_target;
}

get_doll_best_doll_target( origin, range )
{
	zombies = GetAIArray( "axis" );

	if ( zombies.size > 0 )
	{
		// find the zombies in range
		zombie_sort = get_array_of_closest( origin, zombies, undefined, undefined, range );

		for ( i = 0; i < zombie_sort.size; i++ )
		{
			if ( IsDefined( zombie_sort[i] ) && IsAlive( zombie_sort[i] ) )
			{
				centroid = zombie_sort[i] GetCentroid();

				if ( BulletTracePassed( origin, centroid, false, undefined ) )
				{
					//zombie_sort[i] nesting_dolls_debug_print( "DOLL", ( 0, 1, 0) );
					return zombie_sort[i];
				}
			}
		}
	}

	return undefined;
}

nesting_dolls_cleanup( parent )
{
	while( true )
	{
		if( !isDefined( parent ) )
		{
			self_delete();
			return;
		}
		wait( 0.05 );
	}
}

do_nesting_dolls_sound( model, info )
{
	monk_scream_vox = false;

	if( level.music_override == false )
	{
		monk_scream_vox = false;
		self playsound( "zmb_monkey_song" );
	}

	self waittill( "explode", position );
	if( isDefined( model ) )
	{
		// model ClearAnim( %o_monkey_bomb, 0.2 );
	}

	//for( i = 0; i < info.sound_attractors.size; i++ )
	//{
	//	if( isDefined( info.sound_attractors[i] ) )
	//	{
	//		info.sound_attractors[i] notify( "nesting_dolls_blown_up" );
	//	}
	//}

	if( !monk_scream_vox )
	{
		play_sound_in_space( "zmb_vox_monkey_explode", position );
	}

}

get_thrown_nesting_dolls()
{
	self endon( "disconnect" );
	self endon( "starting_nesting_dolls" );

	while( true )
	{
		self waittill( "grenade_fire", grenade, weapName );
		if( weapName == "zombie_nesting_dolls" )
		{
			return grenade;
		}

		wait( 0.05 );
	}
}

nesting_dolls_debug_print( msg, color )
{
/#
	if ( !isdefined( color ) )
	{
		color = (1, 1, 1);
	}

	Print3d(self.origin + (0,0,60), msg, color, 1, 1, 40); // 10 server frames is 1 second
#/
}

nesting_dolls_tesla_nearby_zombies( doll )
{
	wait( level.nesting_dolls_launch_peak_time );

	// get em
	zombies = GetAiSpeciesArray( "axis", "all" );

	// find the zombies in range
	zombie_sort = get_array_of_closest( doll.origin, zombies, undefined, 15, 250 );

	// shoot tesla rounds at them
	for (i = 0; i < zombie_sort.size; i++)
	{
		centroid = zombie_sort[i] GetCentroid();
		level thread nesting_dolls_play_tesla_bolt( doll.origin, centroid );
		zombie_sort[i] thread maps\_zombiemode_weap_tesla::tesla_damage_init( "head", centroid, self );
	}
}

nesting_dolls_play_tesla_bolt( origin, target_origin )
{
	fxOrg = Spawn( "script_model", origin );
	fxOrg SetModel( "tag_origin" );

	fx = PlayFxOnTag( level._effect["tesla_bolt"], fxOrg, "tag_origin" );
	playsoundatposition( "wpn_tesla_bounce", fxOrg.origin );

	fxOrg MoveTo( target_origin, 0.25 );
	fxOrg waittill( "movedone" );
	fxOrg delete();
}

nesting_dolls_set_id()
{
	if ( !IsDefined( self.doll_id ) )
	{
		self.doll_id = 0;
		return;
	}

	self.doll_id = self.doll_id + 1;

	if ( self.doll_id >= level.nesting_dolls_max_ids )
	{
		self.doll_id = 0;
	}
}

nesting_dolls_track_achievement( doll_id )
{
	self endon( "end_achievement_tracker" + doll_id );

	// create the array
	if ( !IsDefined( self.nesting_dolls_tracker ) )
	{
		self.nesting_dolls_tracker = [];

		for ( i = 0; i < level.nesting_dolls_max_ids; i++ )
		{
			self.nesting_dolls_tracker[i] = [];
		}
	}

	// reset up the array
	for ( i = 0; i < 4; i++ )
	{
		self.nesting_dolls_tracker[doll_id][i] = 0;
	}
}

nesting_dolls_check_achievement( doll_id )
{
	self waittill( "end_achievement_tracker" + doll_id );

	min_kills_per_doll = 1;

	// check to see if any of the counts are less than 2
	for ( i = 0; i < 4; i++ )
	{
		if ( self.nesting_dolls_tracker[doll_id][i] < min_kills_per_doll )
		{
			return;
		}
	}

	// if we made it here we're giving the achievement
	//self notify( "nesting_doll_kills_achievement" );
}

nesting_dolls_create_randomized_indices( id )
{
	if ( !IsDefined( self.nesting_dolls_randomized_indices ) )
	{
		self.nesting_dolls_randomized_indices = [];
	}

	base_indices = array( 0, 1, 2, 3 );

	self.nesting_dolls_randomized_indices[id] = array_randomize( base_indices );
}

nesting_dolls_setup_next_doll_throw()
{
	self endon( "death" );
	self endon( "disconnect" );

	wait(0.5);

	// after we have aquired an id setup the camo for the next run
	next_id = self.doll_id + 1;
	if ( next_id >= level.nesting_dolls_max_ids )
	{
		next_id = 0;
	}

	// randomize the next indices
	self nesting_dolls_create_randomized_indices( next_id );

	if ( self HasWeapon( "zombie_nesting_dolls" ) )
	{
		// swap the cammo
		cammo = level.nesting_dolls_data[ self.nesting_dolls_randomized_indices[next_id][0] ].id;
		self UpdateWeaponOptions( "zombie_nesting_dolls", self CalcWeaponOptions( cammo ) );
	}
}

//monitor_zombie_groans( info )
//{
//	self endon( "explode" );
//
//	while( true )
//	{
//		if( !isDefined( self ) )
//		{
//			return;
//		}
//
//		if( !isDefined( self.attractor_array ) )
//		{
//			wait( 0.05 );
//			continue;
//		}
//
//		for( i = 0; i < self.attractor_array.size; i++ )
//		{
//			if( array_check_for_dupes( info.sound_attractors, self.attractor_array[i] ) )
//			{
//				if ( isDefined( self.origin ) && isDefined( self.attractor_array[i].origin ) )
//				{
//					if( distanceSquared( self.origin, self.attractor_array[i].origin ) < 500 * 500 )
//					{
//						info.sound_attractors = array_add( info.sound_attractors, self.attractor_array[i] );
//						self.attractor_array[i] thread play_zombie_groans();
//					}
//				}
//			}
//		}
//		wait( 0.05 );
//	}
//}
//
//play_zombie_groans()
//{
//	self endon( "death" );
//	self endon( "nesting_dolls_blown_up" );
//
//	while(1)
//	{
//		if( isdefined ( self ) )
//		{
//			self playsound( "zmb_vox_zombie_groan" );
//			wait randomfloatrange( 2, 3 );
//		}
//		else
//		{
//			return;
//		}
//	}
//}
//
