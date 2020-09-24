// For the quantum bomb
#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include animscripts\zombie_Utility;

#using_animtree( "generic_human" );
init_registration()
{
	level.quantum_bomb_register_result_func = ::quantum_bomb_register_result;
	level.quantum_bomb_deregister_result_func = ::quantum_bomb_deregister_result;
	level.quantum_bomb_in_playable_area_validation_func = ::quantum_bomb_in_playable_area_validation;

	quantum_bomb_register_result( "random_lethal_grenade", ::quantum_bomb_lethal_grenade_result, 100 );
	quantum_bomb_register_result( "random_weapon_starburst", ::quantum_bomb_random_weapon_starburst_result, 100 );
	quantum_bomb_register_result( "pack_or_unpack_current_weapon", ::quantum_bomb_pack_or_unpack_current_weapon_result, 100, ::quantum_bomb_pack_or_unpack_current_weapon_validation );
	quantum_bomb_register_result( "auto_revive", ::quantum_bomb_auto_revive_result, 100, ::quantum_bomb_auto_revive_validation );
	quantum_bomb_register_result( "player_teleport", ::quantum_bomb_player_teleport_result, 100, ::quantum_bomb_player_teleport_validation );


	// added for zombie speed buff
	level.scr_anim["zombie"]["sprint5"] = %ai_zombie_fast_sprint_01;
	level.scr_anim["zombie"]["sprint6"] = %ai_zombie_fast_sprint_02;
	quantum_bomb_register_result( "zombie_speed_buff", ::quantum_bomb_zombie_speed_buff_result, 100 );
	quantum_bomb_register_result( "zombie_add_to_total", ::quantum_bomb_zombie_add_to_total_result, 100, ::quantum_bomb_zombie_add_to_total_validation );


	level._effect["zombie_fling_result"] = loadfx( "maps/zombie_moon/fx_moon_qbomb_explo_distort" );
	quantum_bomb_register_result( "zombie_fling", ::quantum_bomb_zombie_fling_result, 100, ::quantum_bomb_zombie_fling_validation );

	level._effect["quantum_bomb_viewmodel_twist"]			= LoadFX( "weapon/quantum_bomb/fx_twist" );
	level._effect["quantum_bomb_viewmodel_press"]			= LoadFX( "weapon/quantum_bomb/fx_press" );
	level._effect["quantum_bomb_area_effect"]				= loadfx( "weapon/quantum_bomb/area_effect" );
	level._effect["quantum_bomb_player_effect"]				= loadfx( "weapon/quantum_bomb/player_effect" );
	level._effect["quantum_bomb_player_position_effect"]	= loadfx( "weapon/quantum_bomb/fx_player_position_effect" );
	level._effect["quantum_bomb_mystery_effect"]			= loadfx( "weapon/quantum_bomb/fx_mystery_effect" );

	level.quantum_bomb_play_area_effect_func = ::quantum_bomb_play_area_effect;
	level.quantum_bomb_play_player_effect_func = ::quantum_bomb_play_player_effect;
	level.quantum_bomb_play_player_effect_at_position_func = ::quantum_bomb_play_player_effect_at_position;
	level.quantum_bomb_play_mystery_effect_func = ::quantum_bomb_play_mystery_effect;
}


init()
{
	if( !quantum_bomb_exists() )
	{
		return;
	}

	/#
	level.zombiemode_devgui_quantum_bomb_give = ::player_give_quantum_bomb;
	#/
}


quantum_bomb_debug_print_ln( msg )
{
/#
	if ( !GetDvarInt( #"scr_quantum_bomb_debug" ) )
	{
		return;
	}

	iprintlnbold( msg );
#/
}


quantum_bomb_debug_print_bold( msg )
{
/#
	if ( !GetDvarInt( #"scr_quantum_bomb_debug" ) )
	{
		return;
	}

	iprintlnbold( msg );
#/
}


quantum_bomb_debug_print_3d( msg, color )
{
/#
	if ( !GetDvarInt( #"scr_quantum_bomb_debug" ) )
	{
		return;
	}

	if ( !isdefined( color ) )
	{
		color = (1, 1, 1);
	}

	Print3d( self.origin + (0,0,60), msg, color, 1, 1, 40 ); // 20 server frames is 1 second
#/
}


quantum_bomb_register_result( name, result_func, chance, validation_func )
{
	if ( !isdefined( level.quantum_bomb_results ) )
	{
		level.quantum_bomb_results = [];
	}

	if ( isdefined( level.quantum_bomb_results[name] ) )
	{
		quantum_bomb_debug_print_ln( "quantum_bomb_register_result(): '" + name + "' is already registered as a quantum bomb result.\n" );
		return;
	}

	result = SpawnStruct();
	result.name = name;
	result.result_func = result_func;

	if ( !isdefined( chance ) )
	{
		result.chance = 100;
	}
	else
	{
		result.chance = clamp( chance, 1, 100 );
	}

	if ( !isdefined( validation_func ) )
	{
		result.validation_func = ::quantum_bomb_default_validation;
	}
	else
	{
		result.validation_func = validation_func;
	}

	level.quantum_bomb_results[name] = result;
}


quantum_bomb_deregister_result( name )
{
	if ( !isdefined( level.quantum_bomb_results ) )
	{
		level.quantum_bomb_results = [];
	}

	if ( !isdefined( level.quantum_bomb_results[name] ) )
	{
		quantum_bomb_debug_print_ln( "quantum_bomb_deregister_result(): '" + name + "' is not registered as a quantum bomb result.\n" );
		return;
	}

	level.quantum_bomb_results[name] = undefined;
}


quantum_bomb_play_area_effect( position )
{
	PlayFX( level._effect["quantum_bomb_area_effect"], position );
}


quantum_bomb_play_player_effect()
{
	PlayFXOnTag( level._effect["quantum_bomb_player_effect"], self, "tag_origin" );
}


quantum_bomb_play_player_effect_at_position( position )
{
	PlayFX( level._effect["quantum_bomb_player_position_effect"], position );
}


quantum_bomb_play_mystery_effect( position )
{
	PlayFX( level._effect["quantum_bomb_mystery_effect"], position );
}


quantum_bomb_clear_cached_data()
{
	level.quantum_bomb_cached_in_playable_area = undefined;
	level.quantum_bomb_cached_closest_zombies = undefined;
}


quantum_bomb_select_result( position )
{
	quantum_bomb_clear_cached_data();

/#
	result_name = GetDvar( #"scr_force_quantum_bomb_result" );
	if ( result_name != "" && IsDefined( level.quantum_bomb_results[result_name] ) )
	{
		return level.quantum_bomb_results[result_name];
	}
#/

	eligible_results = [];
	chance = RandomInt( 100 );
	keys = GetArrayKeys( level.quantum_bomb_results );
	for ( i = 0; i < keys.size; i++ )
	{
		result = level.quantum_bomb_results[keys[i]];

		if ( result.chance > chance && self [[result.validation_func]]( position ) )
		{
			eligible_results[eligible_results.size] = result.name;
		}
	}

	// forced results (in order of priority)
	forced_results = array("ctvg", "be2", "player_teleport", "auto_revive", "give_nearest_perk", "open_nearest_door", "pack_or_unpack_current_weapon", "remove_digger", "zombie_fling");

	for ( i = 0; i < forced_results.size; i++ )
	{
		for ( j = 0; j < eligible_results.size; j++ )
		{
			if(forced_results[i] == eligible_results[j])
			{
				return level.quantum_bomb_results[forced_results[i]];
			}
		}
	}

	return level.quantum_bomb_results[eligible_results[RandomInt( eligible_results.size )]];
}


player_give_quantum_bomb()
{
	self giveweapon( "zombie_quantum_bomb" );
	self set_player_tactical_grenade( "zombie_quantum_bomb" );
	self thread player_handle_quantum_bomb();
}


player_handle_quantum_bomb()
{
	//self notify( "starting_quantum_bomb" );
	self endon( "disconnect" );
	//self endon( "starting_quantum_bomb" );
	level endon( "end_game" );

	// anything to set up before watching for the toss

	grenade = self get_thrown_quantum_bomb();
	self thread player_handle_quantum_bomb();
	if( IsDefined( grenade ) )
	{
		if( self maps\_laststand::player_is_in_laststand() )
		{
			grenade delete();
			return;
		}

		grenade.angles = (0, grenade.angles[1], 0);

		grenade waittill( "explode", position );

		playsoundatposition( "wpn_quantum_exp", position );
		result = self quantum_bomb_select_result( position );
		//self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
		self thread [[result.result_func]]( position );
		quantum_bomb_debug_print_bold( "quantum_bomb exploded at " + position + ", result: '" + result.name + "'.\n" );
	}
}

quantum_bomb_exists()
{
	return IsDefined( level.zombie_weapons["zombie_quantum_bomb"] );
}

get_thrown_quantum_bomb()
{
	self endon( "disconnect" );
	self endon( "starting_quantum_bomb" );

	while( true )
	{
		self waittill( "grenade_fire", grenade, weapName );
		if( weapName == "zombie_quantum_bomb" )
		{
			return grenade;
		}

		wait( 0.05 );
	}
}


quantum_bomb_default_validation( position )
{
	return true;
}


quantum_bomb_get_cached_closest_zombies( position )
{
	if ( !isdefined( level.quantum_bomb_cached_closest_zombies ) )
	{
		level.quantum_bomb_cached_closest_zombies = get_array_of_closest( position, GetAiSpeciesArray( "axis", "all" ) );
	}

	return level.quantum_bomb_cached_closest_zombies;
}


quantum_bomb_get_cached_in_playable_area( position )
{
	if ( !isdefined( level.quantum_bomb_cached_in_playable_area ) )
	{
		level.quantum_bomb_cached_in_playable_area = check_point_in_playable_area( position );
	}

	return level.quantum_bomb_cached_in_playable_area;
}


quantum_bomb_in_playable_area_validation( position )
{
	return quantum_bomb_get_cached_in_playable_area( position );
}


quantum_bomb_lethal_grenade_result( position )
{
	self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
	self MagicGrenadeType( level.zombie_lethal_grenade_list[RandomInt( level.zombie_lethal_grenade_list.size )], position, (0, 0, 0), 0.35 );
}


quantum_bomb_random_weapon_starburst_result( position )
{
	self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );

	weapon = "spas_upgraded_zm";
	rand = RandomInt( 5 );
/#
	starburst_debug = GetDvarInt( #"scr_quantum_bomb_weapon_starburst_debug" );
	if ( starburst_debug )
	{
		rand = starburst_debug;
	}
#/

	switch ( rand )
	{
	case 0:
		weapon = "starburst_ray_gun_zm";
		if ( IsDefined( level.zombie_include_weapons["starburst_ray_gun_zm"] ) )
		{
			break;
		}
	case 1:
		weapon = "spas_upgraded_zm";
		if ( IsDefined( level.zombie_include_weapons["spas_upgraded_zm"] ) )
		{
			break;
		}
	case 2:
		weapon = "python_upgraded_zm";
		if ( IsDefined( level.zombie_include_weapons["python_upgraded_zm"] ) )
		{
			break;
		}
	case 3:
		weapon = "starburst_m72_law_zm";
		if ( IsDefined( level.zombie_include_weapons["starburst_m72_law_zm"] ) )
		{
			break;
		}
	case 4:
		weapon = "starburst_china_lake_zm";
		if ( IsDefined( level.zombie_include_weapons["starburst_china_lake_zm"] ) )
		{
			break;
		}
	}

	quantum_bomb_play_player_effect_at_position( position );

	base_pos = position + (0, 0, 40);
	start_yaw = VectorToAngles( base_pos - self.origin );
	start_yaw = (0, start_yaw[1], 0);

	weapon_model = spawn( "script_model", position );
	weapon_model.angles = start_yaw;

	modelname = GetWeaponModel( weapon );
	weapon_model setmodel( modelname );
	weapon_model useweaponhidetags( weapon );

	weapon_model MoveTo( base_pos, 1, 0.25, 0.25 );
	weapon_model waittill( "movedone" );

	attacker = self;

	for ( i = 0; i < 36; i++ )
	{
		yaw = start_yaw + (RandomIntRange( -3, 3 ), i * 10, 0);
		weapon_model.angles = yaw;
		flash_pos = weapon_model GetTagOrigin( "tag_flash" );
		target_pos = flash_pos + vector_scale( AnglesToForward( yaw ), 40 );

		if ( !isdefined( attacker ) )
		{
			attacker = undefined;
		}

		MagicBullet( weapon, flash_pos, target_pos, attacker );

		//wait .05;
		wait_network_frame();
	}

	weapon_model Delete();
}


quantum_bomb_pack_or_unpack_current_weapon_validation( position )
{
	if ( !quantum_bomb_get_cached_in_playable_area( position ) || maps\_zombiemode_weapons::is_weapon_upgraded(self GetCurrentWeapon()) || !IsDefined(level.zombie_weapons[self GetCurrentWeapon()].upgrade_name) )
	{
		return false;
	}

	pack_triggers = GetEntArray( "zombie_vending_upgrade", "targetname" );

	range_squared = 180 * 180; // 15 feet
	for ( i = 0; i < pack_triggers.size; i++ )
	{
		if ( DistanceSquared( pack_triggers[i].origin, position ) < range_squared )
		{
			return true;
		}
	}

	// if not near a machine, then can't happen
	return false;
}


quantum_bomb_pack_or_unpack_current_weapon_result( position )
{
	quantum_bomb_play_mystery_effect( position );

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if(player != self)
		{
			continue;
		}

		if ( player.sessionstate == "spectator" || player maps\_laststand::player_is_in_laststand() )
		{
			continue;
		}

		weapon = player GetCurrentWeapon();
		if ( "primary" != WeaponInventoryType( weapon ) || !isdefined( level.zombie_weapons[weapon] ) )
		{
			continue;
		}

		if ( isdefined( level.zombie_weapons[weapon].upgrade_name ) )
		{
			weapon_limit = 2;
			if ( player HasPerk( "specialty_additionalprimaryweapon" ) )
			{
				weapon_limit = 3;
			}

			primaries = player GetWeaponsListPrimaries();
			if( isDefined( primaries ) && primaries.size < weapon_limit )
			{
				// since we're under the weapon limit, weapon_give won't take the current weapon, so we need to do that here ourselves
				player TakeWeapon( weapon );
			}

			player thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
			player thread maps\_zombiemode_weapons::weapon_give( level.zombie_weapons[weapon].upgrade_name );
			player quantum_bomb_play_player_effect();
		}
	}
}


quantum_bomb_auto_revive_validation( position )
{
	if ( flag( "solo_game" ) )
	{
		return false;
	}

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( player maps\_laststand::player_is_in_laststand() && distance(player.origin, position) <= 64 )
		{
			return true;
		}
	}

	return false;
}


quantum_bomb_auto_revive_result( position )
{
	quantum_bomb_play_mystery_effect( position );

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( player maps\_laststand::player_is_in_laststand() && distance(player.origin, position) <= 64 )
		{
			player maps\_laststand::auto_revive( self );
			player quantum_bomb_play_player_effect();
		}
	}
}


quantum_bomb_player_teleport_result( position )
{
	quantum_bomb_play_mystery_effect( position );

	players = getplayers();
	players_to_teleport = [];
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( player.sessionstate == "spectator" || player maps\_laststand::player_is_in_laststand() )
		{
			continue;
		}

		if ( isdefined( level.quantum_bomb_prevent_player_getting_teleported ) && player [[level.quantum_bomb_prevent_player_getting_teleported]]( position ) )
		{
			continue;
		}

		players_to_teleport[players_to_teleport.size] = player;
	}

	players_to_teleport = array_randomize( players_to_teleport );
	for ( i = 0; i < players_to_teleport.size; i++ )
	{
		player = players_to_teleport[i];

		// first player in the list always teleports, others have a 20% chance
		if ( i && RandomInt( 5 ) )
		{
			continue;
		}

		level thread quantum_bomb_teleport_player( player );
	}
}


quantum_bomb_teleport_player( player )
{
	// grab all the structs
	black_hole_teleport_structs = getstructarray( "struct_black_hole_teleport", "targetname" );
	chosen_spot = undefined;

	if ( isDefined( level._special_blackhole_bomb_structs ) )
	{
		black_hole_teleport_structs = [[level._special_blackhole_bomb_structs]]();
	}

	player_current_zone = player get_current_zone();
	if ( !IsDefined( black_hole_teleport_structs ) || black_hole_teleport_structs.size == 0 || !IsDefined( player_current_zone ) )
	{
		// no structs so no teleport
		return;
	}

	// randomize the array
	black_hole_teleport_structs = array_randomize( black_hole_teleport_structs );

	if ( isDefined( level._override_blackhole_destination_logic ) )
	{
		chosen_spot = [[level._override_blackhole_destination_logic]]( black_hole_teleport_structs, player );
	}
	else
	{
		// decide which struct to move the player to
		for ( i = 0; i < black_hole_teleport_structs.size; i++ )
		{
			if ( check_point_in_active_zone( black_hole_teleport_structs[i].origin ) &&
					( player_current_zone != black_hole_teleport_structs[i].script_string ) )
			{
				chosen_spot = black_hole_teleport_structs[i];
				break;
			}
		}
	}

	if ( IsDefined( chosen_spot ) )
	{
		player thread quantum_bomb_teleport( chosen_spot );
	}

}

// teleports the player to a new position
// override included, runs before the player is moved this way anything that needs to be done for the teleport
// SELF == PLAYER
quantum_bomb_teleport( struct_dest )
{
	self endon( "death" );

	if( !IsDefined( struct_dest ) )
	{
		return;
	}

	prone_offset = (0, 0, 49);
	crouch_offset = (0, 0, 20);
	stand_offset = (0, 0, 0);
	destination = undefined;

	// figure out the player's stance
	if( self GetStance() == "prone" )
	{
		destination = struct_dest.origin + prone_offset;
	}
	else if( self GetStance() == "crouch" )
	{
		destination = struct_dest.origin + crouch_offset;
	}
	else
	{
		destination = struct_dest.origin + stand_offset;
	}

	// override
	if( IsDefined( level._black_hole_teleport_override ) )
	{
		level [[ level._black_hole_teleport_override ]]( self );
	}

	quantum_bomb_play_player_effect_at_position( self.origin );

	// don't allow any funny biz
	self FreezeControls( true );
	self DisableOffhandWeapons();
	self DisableWeapons();

	self playsoundtoplayer( "zmb_gersh_teleporter_go_2d", self );

	// so the player doesn't show up while moving
	self DontInterpolate();
	self SetOrigin( destination );
	self SetPlayerAngles( struct_dest.angles );

	// allow the funny biz
	self EnableOffhandWeapons();
	self EnableWeapons();
	self FreezeControls( false );

	self quantum_bomb_play_player_effect();
	self thread quantum_bomb_slightly_delayed_player_response();
}


quantum_bomb_slightly_delayed_player_response()
{
    wait(1);
    self maps\_zombiemode_audio::create_and_play_dialog( "general", "teleport_gersh" );
}


quantum_bomb_zombie_speed_buff_result( position )
{
	quantum_bomb_play_mystery_effect( position );

	self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_bad" );

	zombies = quantum_bomb_get_cached_closest_zombies( position );
	for ( i = 0; i < zombies.size; i++ )
	{
		fast_sprint = "sprint5";
		if ( RandomInt( 100 ) < 50 )
		{
			fast_sprint = "sprint6";
		}

		zombie = zombies[i];

		if ( isdefined( zombie.fastSprintFunc ) )
		{
			fast_sprint = zombie [[ zombie.fastSprintFunc ]]();
		}
		else if ( is_true( zombie.in_low_gravity ) )
		{
			if ( !zombie.has_legs )
			{
				fast_sprint = "crawl_low_g_super_sprint";
			}
			else
			{
				fast_sprint = "low_g_super_sprint";
			}
		}
		else
		{
			if ( !zombie.has_legs )
			{
				fast_sprint = "crawl_super_sprint";
			}
		}

		if ( zombie.isdog || !isdefined( level.scr_anim[ zombie.animname ][ fast_sprint ] ) )
		{
			continue;
		}

		zombie.zombie_move_speed = "sprint";
		zombie set_run_anim( fast_sprint );
		zombie.run_combatanim = level.scr_anim[ zombie.animname ][ fast_sprint ];
		zombie.needs_run_update = true;
	}
}

quantum_bomb_zombie_fling_validation( position )
{
	// fling effect if near any zombie
	zombs = GetAiSpeciesArray( "axis", "all" );
	near_zomb = false;
	for(i=0;i<zombs.size;i++)
	{
		if(DistanceSquared(zombs[i].origin, position) < 180*180)
		{
			return true;
		}
	}

	return false;
}

quantum_bomb_zombie_fling_result( position )
{
	PlayFX( level._effect["zombie_fling_result"], position );

	self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );

	range = 300;
	range_squared = range * range;
	zombies = quantum_bomb_get_cached_closest_zombies( position );
	view_pos = position + (0, 0, 40);
	for ( i = 0; i < zombies.size; i++ )
	{
		zombie = zombies[i];

		if( !IsDefined( zombie ) || !IsAlive( zombie ) )
		{
			// guy died on us
			continue;
		}

		test_origin = zombie.origin + (0, 0, 40); // Add some z to typically give some push up to the fling
		test_origin_squared = DistanceSquared( position, test_origin );
		if ( test_origin_squared > range_squared )
		{
			break;
		}

		if ( !zombie DamageConeTrace( view_pos ) && !BulletTracePassed( view_pos, test_origin, false, undefined ) && !SightTracePassed( view_pos, test_origin, false, undefined ) )
		{
			continue;
		}

		// the closer they are, the harder they get flung
		dist_mult = (range_squared - test_origin_squared) / range_squared;
		fling_vec = VectorNormalize( test_origin - position );
		fling_vec = (fling_vec[0], fling_vec[1], abs( fling_vec[2] ));
		fling_vec = vector_scale( fling_vec, 100 + 100 * dist_mult );

		zombie quantum_bomb_fling_zombie( self, fling_vec );

		/*if ( i && !(i % 10) )
		{
			wait_network_frame();
			wait_network_frame();
			wait_network_frame();
		}*/
	}
}


quantum_bomb_fling_zombie( player, fling_vec )
{
	if( !IsDefined( self ) || !IsAlive( self ) )
	{
		// guy died on us
		return;
	}

	self DoDamage( self.health + 666, player.origin, player );

	if ( self.health <= 0 )
	{
		self StartRagdoll();
		self LaunchRagdoll( fling_vec );
	}
}


quantum_bomb_zombie_add_to_total_validation( position )
{
	if ( level.zombie_total )
	{
		return false;
	}

	zombies = quantum_bomb_get_cached_closest_zombies( position );
	return (zombies.size < level.zombie_ai_limit);
}


quantum_bomb_zombie_add_to_total_result( position )
{
	quantum_bomb_play_mystery_effect( position );

	self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_bad" );

	level.zombie_total += level.zombie_ai_limit;
}

quantum_bomb_player_teleport_validation( position )
{
	if(![[level.quantum_bomb_in_playable_area_validation_func]](position))
	{
		return true;
	}

	return false;
}
