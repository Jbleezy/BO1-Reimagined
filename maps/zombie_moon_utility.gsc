#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_blockers;
#include maps\_zombiemode;

// --------------------------------------------------------------------------------------
// New airlock door system (051211)
// DCS: doors that close and open
// --------------------------------------------------------------------------------------
init_zombie_airlocks()
{
	// buy triggers for unlocking airlocks. this may be moved to blockers at some point.
	airlock_buys = GetEntArray("zombie_airlock_buy", "targetname");
	for( i = 0; i < airlock_buys.size; i++ )
	{
		airlock_buys[i] thread airlock_buy_init();
	}

	level thread maps\_zombiemode_hackables_doors::hack_doors("zombie_airlock_hackable", maps\zombie_moon_utility::moon_door_opened);
	airlock_hacks = GetEntArray("zombie_airlock_hackable", "targetname");
	for( i = 0; i < airlock_hacks.size; i++ )
	{
		airlock_hacks[i] thread airlock_hack_init();
	}


	// triggers that open airlock doors when entered after purchase.
	airlock_doors = GetEntArray("zombie_door_airlock", "script_noteworthy");
	for( i = 0; i < airlock_doors.size; i++ )
	{
		airlock_doors[i] thread airlock_init();
	}

	level thread init_door_sounds();
	level thread zombie_moon_receiving_hatch_init();
	//level thread hacker_location_random_init();
	level thread moon_glass_breach_init();
}

// ------------------------------------------------------------------------------------------------
init_door_sounds()
{
	maps\_zombiemode_utility::add_sound( "lab_door", "zmb_lab_door_slide" );
	maps\_zombiemode_utility::add_sound( "electric_metal_big", "zmb_heavy_door_open" );
}


// ------------------------------------------------------------------------------------------------
// DCS: Functions for hackable only access to an airlock
// ------------------------------------------------------------------------------------------------
airlock_hack_init()
{
	self.type = undefined;

	if( isDefined(self.script_flag) && !IsDefined( level.flag[self.script_flag] ) )
	{
		if( IsDefined( self.script_flag ) )
		{
			tokens = Strtok( self.script_flag, "," );
			for ( i=0; i<tokens.size; i++ )
			{
				flag_init( self.script_flag );
			}
		}
	}

	self.trigs = [];
	targets = GetEntArray( self.target, "targetname" );
	for(i=0;i<targets.size;i++)
	{
		self.trigs = array_add(self.trigs, targets[i]);
		if(IsDefined(targets[i].classname) && targets[i].classname == "trigger_multiple")
		{
			targets[i] trigger_off();
		}
	}

	self SetCursorHint( "HINT_NOICON" );
	self.script_noteworthy = "default";

	self SetHintString(&"ZOMBIE_EQUIP_HACKER");
}

// ------------------------------------------------------------------------------------------------
// DCS: Functions for purchasing access to an airlock
// ------------------------------------------------------------------------------------------------
airlock_buy_init()
{
	self.type = undefined;

	if( isDefined(self.script_flag) && !IsDefined( level.flag[self.script_flag] ) )
	{
		if( IsDefined( self.script_flag ) )
		{
			tokens = Strtok( self.script_flag, "," );
			for ( i=0; i<tokens.size; i++ )
			{
				flag_init( self.script_flag );
			}
		}
	}

	self.trigs = [];
	targets = GetEntArray( self.target, "targetname" );
	for(i=0;i<targets.size;i++)
	{
		self.trigs = array_add(self.trigs, targets[i]);
		if(IsDefined(targets[i].classname) && targets[i].classname == "trigger_multiple")
		{
			targets[i] trigger_off();
		}
	}

	self SetCursorHint( "HINT_NOICON" );

	if ( IsDefined( self.script_noteworthy ) && ( self.script_noteworthy == "electric_door" || self.script_noteworthy == "electric_buyable_door" ))
	{
		self sethintstring(&"ZOMBIE_NEED_POWER");
	}
	else
	{
		self.script_noteworthy = "default";
	}

	self thread airlock_buy_think();
}

airlock_buy_think()
{
	self endon("kill_door_think");
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

			if ( !self airlock_buy() )
			{
				continue;
			}
			break;

		default:

			self set_hint_string( self, "default_buy_door_" + cost );

			if ( !self airlock_buy() )
			{
				continue;
			}

			self moon_door_opened();

			break;
		}
	}


}

moon_door_opened()
{
	self notify("door_opened");
	// Set any flags called
	if( IsDefined( self.script_flag ) )
	{
		tokens = Strtok( self.script_flag, "," );
		for ( i=0; i<tokens.size; i++ )
		{
			flag_set( tokens[i] );
		}
	}

	for(i=0;i<self.trigs.size;i++)
	{
		self.trigs[i] thread trigger_on();
		self.trigs[i] thread change_door_models();
	}

	play_sound_at_pos( "purchase", self.origin );

	all_trigs = getentarray( self.target, "target" );
	for( i = 0; i < all_trigs.size; i++ )
	{
		all_trigs[i] trigger_off();
	}
}

change_door_models()
{
	doors = GetEntArray(self.target,"targetname");
	for(i=0;i<doors.size;i++)
	{
		if(IsDefined(doors[i].model) && doors[i].model == "p_zom_moon_lab_airlock_door01_left_locked")
		{
			doors[i] SetModel("p_zom_moon_lab_airlock_door01_left");
		}
		else if(IsDefined(doors[i].model) && doors[i].model == "p_zom_moon_lab_airlock_door01_right_locked")
		{
			doors[i] SetModel("p_zom_moon_lab_airlock_door01_right");
		}
		else if(IsDefined(doors[i].model) && doors[i].model == "p_zom_moon_mine_airlock_door03_single_locked")
		{
			doors[i] SetModel("p_zom_moon_mine_airlock_door03_single");
		}

		doors[i] thread airlock_connect_paths();

	}
}

airlock_connect_paths()
{
	if(self.classname == "script_brushmodel")
	{
		self NotSolid();
		self ConnectPaths();

		if(!IsDefined(self._door_open) || self._door_open == false)
		{
			self Solid();
		}
	}
}

airlock_buy()
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
			play_sound_at_pos( "no_purchase", self.origin );
			who maps\_zombiemode_audio::create_and_play_dialog( "general", "door_deny", undefined, 0 );
			return false;
		}

		// buy the thing
		bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type door", who.playername, who.score, level.team_pool[ who.team_num ].score, level.round_number, self.zombie_cost, self.script_flag, self.origin );
	}

	return true;
}

// ------------------------------------------------------------------------------------------------
// DCS: functions for opening airlock doors once airlock has been purchased.
// ------------------------------------------------------------------------------------------------
airlock_init()
{

	self.type = undefined;

	self._door_open = false;

	targets = GetEntArray( self.target, "targetname" );

	self.doors = [];
	for(i=0;i<targets.size;i++)
	{
		targets[i] maps\_zombiemode_blockers::door_classify( self );
		targets[i].startpos = targets[i].origin;

	}

	self thread airlock_think();
}

airlock_think()
{
	while( 1 )
	{
		self waittill("trigger", who);

		//if door already open pass through.
		if(IsDefined(self.doors[0].startpos) && self.doors[0].startpos != self.doors[0].origin)
		{
			continue;
		}
		//IPrintLnBold("Open airlock door");
		for(i=0;i<self.doors.size;i++)
		{
			self.doors[i] thread airlock_activate(0.25, true);
		}
		self._door_open = true;

		// if airlock remains occupied or is moving.
		while((self moon_airlock_occupied()) || (IsDefined(self.doors[0].door_moving) && self.doors[0].door_moving == true))
		{
			wait(0.1);
		}

		//IPrintLnBold("Close airlock door");

		//cleanup corpses in doorway
		self thread door_clean_up_corpses();

		// Close the door back when area left.
		for(i=0;i<self.doors.size;i++)
		{
			self.doors[i] thread airlock_activate(0.25, false);
		}
		self._door_open = false;
	}
}

airlock_activate( time, open  )
{
	if ( !IsDefined(time) )
	{
		time = 1;
	}

	if ( !IsDefined( open ) )
	{
		open = true;
	}

	// Prevent multiple triggers from making doors move more than once
	if ( IsDefined(self.door_moving) )
	{
		return;
	}
	self.door_moving = true;


	self NotSolid();

	if(self.classname == "script_brushmodel")
	{
		if ( open )
		{
			self ConnectPaths();
		}
	}

	if ( IsDefined( self.script_sound ) )
	{
		if( open )
			self playsound( "zmb_airlock_open" );
		else
			self playsound( "zmb_airlock_close" );
	}

	// scale
	scale = 1;
	if ( !open )
	{
		scale = -1;
	}

	switch( self.script_string )
	{
		case "slide_apart":
		if(isDefined(self.script_vector))
		{
			vector = vector_scale( self.script_vector, scale );
			if ( open )
			{
				if(IsDefined(self.startpos))
				{
					self MoveTo( self.startpos + vector, time );
				}
				else
				{
					self MoveTo( self.origin + vector, time );
				}

				self._door_open = true;
			}
			else
			{
				if(IsDefined(self.startpos))
				{
					self MoveTo( self.startpos, time );
				}
				else
				{
					self MoveTo( self.origin - vector, time ); //this could get messy, system probably failed.
				}

				self._door_open = false;
			}
			self thread maps\_zombiemode_blockers::door_solid_thread();
		}
		break;
	}

}

moon_airlock_occupied()
{
	is_occupied = 0;

	zombies = GetAIArray ("axis");
	for ( i = 0; i < zombies.size; i++ )
	{
		if(zombies[i] IsTouching(self))
		{
			is_occupied++;
		}
	}

	players = get_players();
	for( i=0; i<players.size; i++ )
	{
		if(players[i] IsTouching(self))
		{
			is_occupied++;
		}
	}

	if(is_occupied > 0)
	{
		// backup: if doors somehow closed, force back open.
		if(IsDefined(self.doors[0].startpos) && self.doors[0].startpos == self.doors[0].origin)
		{
			for(i=0;i<self.doors.size;i++)
			{
				self.doors[i] thread airlock_activate(0.25, true);
			}
			self._door_open = true;
		}
		return true;
	}
	else
	{
		return false;
	}
}

//---------------------------------------------------------------------------
// clean up dead zombie corpses in doorway
//---------------------------------------------------------------------------
door_clean_up_corpses()
{

	corpses = GetCorpseArray();
	if(IsDefined(corpses))
	{
		for ( i = 0; i < corpses.size; i++ )
		{
			if(corpses[i] istouching(self))
			{
				corpses[i] thread door_remove_corpses();

			}
		}
	}
}
door_remove_corpses()
{
	PlayFX(level._effect["dog_gib"], self.origin);
	self Delete();
}
// --------------------------------------------------------------------------------------
// DCS: fog setting changes when teleporting between earth and moon sky. need to clientside yet.
// --------------------------------------------------------------------------------------

// Hanger 18 settings

sky_transition_fog_settings()
{
	players = get_players();

	if(flag("enter_nml"))
	{
		for(i=0;i<players.size;i++)
		{
			players[i] setclientflag(level._CLIENTFLAG_PLAYER_SKY_TRANSITION);
		}
	}

	// Moon exterior settings
	else
	{
		for(i=0;i<players.size;i++)
		{
			players[i] clearclientflag(level._CLIENTFLAG_PLAYER_SKY_TRANSITION);
		}
	}

}


//*****************************************************************************
//	Swaps a cage light model to the green one.
//*****************************************************************************
zapper_light_green( light_name, key_name )
{
	zapper_lights = getentarray( light_name, key_name );

	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_trap_switch_light_on_green");

		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}

		zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_green", 2, "script_model", zapper_lights[i].origin );
		zapper_lights[i].fx setmodel("tag_origin");
		zapper_lights[i].fx.angles = zapper_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_ready"],zapper_lights[i].fx,"tag_origin");
	}
}
//*****************************************************************************
//	Swaps a cage light model to the red one.
//*****************************************************************************

zapper_light_red( light_name, key_name )
{
	zapper_lights = getentarray( light_name, key_name );

	for(i=0;i<zapper_lights.size;i++)
	{
		zapper_lights[i] setmodel("zombie_trap_switch_light_on_red");

		if(isDefined(zapper_lights[i].fx))
		{
			zapper_lights[i].fx delete();
		}

		zapper_lights[i].fx = maps\_zombiemode_net::network_safe_spawn( "trap_light_red", 2, "script_model", zapper_lights[i].origin );
		zapper_lights[i].fx setmodel("tag_origin");
		zapper_lights[i].fx.angles = zapper_lights[i].angles+(-90,0,0);
		playfxontag(level._effect["zapper_light_notready"],zapper_lights[i].fx,"tag_origin");
	}
}




// ------------------------------------------------------------------------------------------------
// DCS: custom intermission so will only show moon on moon and earth on earth.
// ------------------------------------------------------------------------------------------------
moon_intermission()
{
	self closeMenu();
	self closeInGameMenu();

	level endon( "stop_intermission" );
	self endon("disconnect");
	self endon("death");
	self notify( "_zombie_game_over" ); // ww: notify so hud elements know when to leave

	//Show total gained point for end scoreboard and lobby
	self.score = self.score_total;

	self.sessionstate = "intermission";
	self.spectatorclient = -1;
	self.killcamentity = -1;
	self.archivetime = 0;
	self.psoffsettime = 0;
	self.friendlydamage = undefined;

	points = getstructarray( "intermission", "targetname" );

	for(i=0;i<points.size;i++)
	{
		if(flag("enter_nml"))
		{
			// in Area 51, remove moon intermissions.
			if(points[i].script_noteworthy == "moon")
			{
				points = array_remove(points, points[i]);
			}
		}
		else
		{
			if(points[i].script_noteworthy == "earth")
			{
				points = array_remove(points, points[i]);
			}
		}
	}

	if( !IsDefined( points ) || points.size == 0 )
	{
		points = getentarray( "info_intermission", "classname" );
		if( points.size < 1 )
		{
			println( "NO info_intermission POINTS IN MAP" );
			return;
		}
	}


	self.game_over_bg = NewClientHudelem( self );
	self.game_over_bg.horzAlign = "fullscreen";
	self.game_over_bg.vertAlign = "fullscreen";
	self.game_over_bg SetShader( "black", 640, 480 );
	self.game_over_bg.alpha = 1;

	org = undefined;
	while( 1 )
	{
		points = array_randomize( points );
		for( i = 0; i < points.size; i++ )
		{
			point = points[i];
			// Only spawn once if we are using 'moving' org
			// If only using info_intermissions, this will respawn after 5 seconds.
			if( !IsDefined( org ) )
			{
				self Spawn( point.origin, point.angles );
			}

			// Only used with STRUCTS
			if( IsDefined( points[i].target ) )
			{
				if( !IsDefined( org ) )
				{
					org = Spawn( "script_model", self.origin + ( 0, 0, -60 ) );
					org SetModel("tag_origin");
				}

//				self LinkTo( org, "", ( 0, 0, -60 ), ( 0, 0, 0 ) );
//				self SetPlayerAngles( points[i].angles );
				org.origin = points[i].origin;
				org.angles = points[i].angles;


				for ( j = 0; j < get_players().size; j++ )
				{
					player = get_players()[j];
					player CameraSetPosition( org );
					player CameraSetLookAt();
					player CameraActivate( true );
				}

				speed = 20;
				if( IsDefined( points[i].speed ) )
				{
					speed = points[i].speed;
				}

				target_point = getstruct( points[i].target, "targetname" );
				dist = Distance( points[i].origin, target_point.origin );
				time = dist / speed;

				q_time = time * 0.25;
				if( q_time > 1 )
				{
					q_time = 1;
				}

				self.game_over_bg FadeOverTime( q_time );
				self.game_over_bg.alpha = 0;

				org MoveTo( target_point.origin, time, q_time, q_time );
				org RotateTo( target_point.angles, time, q_time, q_time );
				wait( time - q_time );

				self.game_over_bg FadeOverTime( q_time );
				self.game_over_bg.alpha = 1;

				wait( q_time );
			}
			else
			{
				self.game_over_bg FadeOverTime( 1 );
				self.game_over_bg.alpha = 0;

				wait( 5 );

				self.game_over_bg thread fade_up_over_time(1);

				//wait( 1 );
			}
		}
	}
}

// ------------------------------------------------------------------------------------------------
// DCS 070611: set up hacker tool location randomization.
// ------------------------------------------------------------------------------------------------
hacker_location_random_init()
{
	hacker_tool_array = [];
	hacker_pos = undefined;

	level.hacker_tool_positions = [];

	hacker = GetEntArray( "zombie_equipment_upgrade", "targetname" );
	for ( i = 0; i < hacker.size; i++ )
	{
		if(isDefined(hacker[i].zombie_equipment_upgrade ) && hacker[i].zombie_equipment_upgrade == "equip_hacker_zm")
		{
			hacker_tool_array = array_add(hacker_tool_array, hacker[i]);

			struct = spawnstruct();
			struct.trigger_org = hacker[i].origin;
			//struct.model = getent(hacker[i].target,"targetname");
			struct.model_org = getent(hacker[i].target,"targetname").origin;
			struct.model_ang = getent(hacker[i].target,"targetname").angles;

			level.hacker_tool_positions[level.hacker_tool_positions.size] = struct;
		}
	}

	if(	hacker_tool_array.size > 1)
	{
		if(GetDvar("zm_gamemode") == "survival") // the global variable isnt defined yet
		{
			hacker_pos = hacker_tool_array[RandomInt(hacker_tool_array.size)];
			hacker_tool_array  = array_remove(hacker_tool_array, hacker_pos);
		}

		array_thread(hacker_tool_array, ::hacker_position_cleanup);
	}
}

hacker_position_cleanup()
{
	model = GetEnt(self.target,"targetname");
	if(IsDefined(model))
	{
		model Delete();
	}
	if(IsDefined(self))
	{
		self Delete();
	}
}

// ------------------------------------------------------------------------------------------------
// DCS 070711: Breachable glass.
// ------------------------------------------------------------------------------------------------
moon_glass_breach_init()
{
	level.glass = GetEntArray("moon_breach_glass","targetname");
	array_thread(level.glass, ::glass_breach_think);

	flag_wait( "all_players_connected" );
	players = get_players();
	for( i=0; i<players.size; i++ )
	{
		players[i] thread check_for_grenade_throw();
	}
}

glass_gets_destroyed()
{
	if(IsDefined(self.fxpos_array))
	{
		for ( i = 0; i < self.fxpos_array.size; i++ )
		{
			PlayFX(level._effect["glass_impact"], self.fxpos_array[i].origin, AnglesToForward(self.fxpos_array[i].angles) );
		}
	}

	if(IsDefined(self.script_noteworthy))
	{
		level thread send_client_notify_for_breach( self.script_noteworthy );
		_zones = getentarray(self.script_noteworthy,"targetname");

		if(IsDefined(_zones))
		{
			for(i=0;i<_zones.size;i++)
			{
				_zones[i].script_string = "lowgravity";
			}

			level thread maps\zombie_moon_gravity::zone_breached( self.script_noteworthy );
		}
	}

	wait_network_frame();

	if(IsDefined(self.model) && self.damage_state == 0)
	{
		self SetModel(self.model + "_broken");
		self.damage_state = 1;

		// remove return if add additional states.
		return;
	}
	else
	{
		self Delete();
		return;
	}
}


// self is grenade
wait_for_grenade_explode( player )
{
	player endon( "projectile_impact" );

	self waittill( "explode", grenade_origin );
	self thread check_for_grenade_damage_on_window( grenade_origin, self );
}


// self is player
wait_for_projectile_impact( grenade )
{
	grenade endon( "explode" );

	self waittill( "projectile_impact", weapon_name, position );
	self thread check_for_grenade_damage_on_window( position, self );
}


check_for_grenade_damage_on_window( grenade_origin, grenade )
{
	radiusSqToCheck = 64*64 + 200*200;

	for( i=0; i<level.glass.size; i++ )
	{
		if( level.glass[i].damage_state == 0 ) //no damage yet
		{
			glass_destroyed = false;
			for( j=0; j<level.glass[i].fxpos_array.size; j++ )
			{
				glass_origin = level.glass[i].fxpos_array[j].origin;

				//Do distance check and line of sight check
				if( DistanceSquared( glass_origin, grenade_origin ) < radiusSqToCheck && SightTracePassed(glass_origin, grenade_origin + (0,0,30), false, undefined) )
				{
					glass_destroyed = true;
					break;
				}
			}

			if( glass_destroyed )
			{
				//IPrintLnBold( "BOOM GOES GLASS" );
				level.glass[i] glass_gets_destroyed();
				level.glass[i].damage_state = 1;
			}
		}
	}
}


check_for_grenade_throw()
{
	while(1)
	{
		self waittill("grenade_fire", grenade, weapname);

		if(!is_lethal_grenade(weapname))
			continue;

		grenade thread wait_for_grenade_explode( self );
		//self thread wait_for_projectile_impact( grenade );
	}
}

glass_breach_think()
{
	level endon("intermission");

	self.fxpos_array = [];
	if(IsDefined(self.target))
	{
		self.fxpos_array = getstructarray(self.target, "targetname");
	}

	self.health = 99999;
	self SetCanDamage( true );
	self.damage_state = 0;

	while(true)
	{
		self waittill( "damage", amount, attacker, direction, point, dmg_type, model_name, tag_name);

		if( IsPlayer( attacker ) && ( dmg_type == "MOD_PROJECTILE" || dmg_type == "MOD_PROJECTILE_SPLASH" || dmg_type == "MOD_GRENADE" || dmg_type == "MOD_GRENADE_SPLASH" ) ) // && self damageConeTrace(point) > 0
		{
			//IPrintLnBold( "BANG GOES GLASS" );
			if( self.damage_state == 0 ) //no damage yet
			{
				self glass_gets_destroyed();
				self.damage_state = 1;
				return;
			}
		}
	}
}

send_client_notify_for_breach( zone )
{
	switch(zone)
	{
		case "bridge_zone":
			if( !is_true( level.audio_zones_breached["1"] ) )
			{
				clientnotify( "Az1" );
				level.audio_zones_breached["1"] = true;
				if( flag( "power_on" ) )
				{
					level thread maps\zombie_moon_amb::play_mooncomp_vox( "vox_mcomp_breach_start" );
				}
			}
			break;

		case "generator_exit_east_zone":
			if( !is_true( level.audio_zones_breached["4a"] ) )
			{
				clientnotify( "Az4a" );
				level.audio_zones_breached["4a"] = true;
				if( flag( "power_on" ) )
				{
					level thread maps\zombie_moon_amb::play_mooncomp_vox( "vox_mcomp_breach_labs" );
				}
			}
			break;

		case "enter_forest_east_zone":
			if( !is_true( level.audio_zones_breached["4b"] ) )
			{
				clientnotify( "Az4b" );
				level.audio_zones_breached["4b"] = true;
				if( flag( "power_on" ) )
				{
					level thread maps\zombie_moon_amb::play_mooncomp_vox( "vox_mcomp_breach_labs" );
				}
			}
			break;
	}
}

// ------------------------------------------------------------------------------------------------
// DCS 070611: set up receiving hatch for power.
// ------------------------------------------------------------------------------------------------
zombie_moon_receiving_hatch_init()
{
	hatches = GetEntArray("recieving_hatch","targetname");
	array_thread(hatches, ::zombie_moon_hatch);
}
zombie_moon_hatch()
{
	scale = 1;

	flag_wait("power_on");
	flag_wait( "receiving_exit" );

	self playsound( "evt_loading_door_start" );

	if(isDefined(self.script_vector))
	{
		vector = vector_scale( self.script_vector, scale );
		self MoveTo( self.origin + vector, 1.0 );

		if(IsDefined(self.script_noteworthy) && self.script_noteworthy == "hatch_clip")
		{
			self thread maps\_zombiemode_blockers::disconnect_paths_when_done();
		}
		else
		{
			self NotSolid();
			self ConnectPaths();
		}

		wait(1);
		self playsound( "evt_loading_door_end" );
	}
}
