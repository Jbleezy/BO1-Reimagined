#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

init()
{
	if ( is_true( level.use_freezegun_features ) )
	{
		// using the functionality but not the weapon itself
	}
	else if ( !maps\_zombiemode_weapons::is_weapon_included( "freezegun_zm" ) )
	{
		return;
	}

	level._ZOMBIE_ACTOR_FLAG_FREEZEGUN_EXTREMITY_DAMAGE_FX = 15;
	level._ZOMBIE_ACTOR_FLAG_FREEZEGUN_TORSO_DAMAGE_FX = 14;

	set_zombie_var( "freezegun_cylinder_radius",				120 ); // 10 feet
	set_zombie_var( "freezegun_inner_range",					300 ); // 5 feet
	set_zombie_var( "freezegun_outer_range",					600 ); // 50 feet
	set_zombie_var( "freezegun_inner_damage",					1500 );
	set_zombie_var( "freezegun_outer_damage",					750 );
	set_zombie_var( "freezegun_shatter_range",					180 ); // 150 feet
	set_zombie_var( "freezegun_shatter_inner_damage",			500 );
	set_zombie_var( "freezegun_shatter_outer_damage",			500 );
	set_zombie_var( "freezegun_cylinder_radius_upgraded",		120 ); // 15 feet
	set_zombie_var( "freezegun_inner_range_upgraded",			450 ); // 10 feet
	set_zombie_var( "freezegun_outer_range_upgraded",			900 ); // 75 feet
	set_zombie_var( "freezegun_inner_damage_upgraded",			2000 );
	set_zombie_var( "freezegun_outer_damage_upgraded",			1000 );
	set_zombie_var( "freezegun_shatter_range_upgraded",			180 ); // 25 feet
	set_zombie_var( "freezegun_shatter_inner_damage_upgraded",	500 );
	set_zombie_var( "freezegun_shatter_outer_damage_upgraded",	500 );

	level._effect[ "freezegun_shatter" ]				= LoadFX( "weapon/freeze_gun/fx_freezegun_shatter" );
	level._effect[ "freezegun_crumple" ]				= LoadFX( "weapon/freeze_gun/fx_freezegun_crumple" );
	level._effect[ "freezegun_smoke_cloud" ]			= loadfx( "weapon/freeze_gun/fx_freezegun_smoke_cloud" );
	level._effect[ "freezegun_damage_torso" ]			= LoadFX( "maps/zombie/fx_zombie_freeze_torso" );
	level._effect[ "freezegun_damage_sm" ]				= LoadFX( "maps/zombie/fx_zombie_freeze_md" );
	level._effect[ "freezegun_shatter_upgraded" ]		= LoadFX( "weapon/freeze_gun/fx_exp_freezegun_impact" );
	level._effect[ "freezegun_crumple_upgraded" ]		= LoadFX( "weapon/freeze_gun/fx_exp_freezegun_impact" );

	level._effect[ "freezegun_shatter_gib_fx" ]			= LoadFX( "weapon/bullet/fx_flesh_gib_fatal_01" );
	level._effect[ "freezegun_shatter_gibtrail_fx" ]	= LoadFX( "weapon/freeze_gun/fx_trail_freezegun_blood_streak" );
	level._effect[ "freezegun_crumple_gib_fx" ]			= LoadFX( "system_elements/fx_null" );
	level._effect[ "freezegun_crumple_gibtrail_fx" ]	= LoadFX( "system_elements/fx_null" );
	// level._effect[ "freezegun_crumple_gib_fx" ]			= LoadFX( "weapon/bullet/fx_flesh_gib_fatal_01" );
	// level._effect[ "freezegun_crumple_gibtrail_fx" ]	= LoadFX( "trail/fx_trail_blood_streak" );

	// For testing FX
	// system_elements/fx_null

	level thread freezegun_on_player_connect();

	level.freezegun_shatter_triggers = [];
}


freezegun_on_player_connect()
{
	for( ;; )
	{
		level waittill( "connecting", player );
		player thread wait_for_thundergun_fired();
	}
}


wait_for_thundergun_fired()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );

	for( ;; )
	{
		self waittill( "weapon_fired" );
		currentweapon = self GetCurrentWeapon();
		if( ( currentweapon == "freezegun_zm" ) || ( currentweapon == "freezegun_upgraded_zm" ) )
		{
			self thread freezegun_fired( currentweapon == "freezegun_upgraded_zm" );

			view_pos = self GetTagOrigin( "tag_flash" ) - self GetPlayerViewHeight();
			view_angles = self GetTagAngles( "tag_flash" );
			playfx( level._effect["freezegun_smoke_cloud"], view_pos, AnglesToForward( view_angles ), AnglesToUp( view_angles ) );
		}
	}
}


freezegun_fired( upgraded )
{
	if ( !IsDefined( level.freezegun_enemies ) )
	{
		level.freezegun_enemies = [];
		level.freezegun_enemies_dist_ratio = [];
	}

	self freezegun_get_enemies_in_range( upgraded );

	//level.freezegun_network_choke_count = 0;

	for ( i = 0; i < level.freezegun_enemies.size; i++ )
	{
		//freezegun_network_choke();
		if(IsAI(level.freezegun_enemies[i]))
		{
			level.freezegun_enemies[i] thread freezegun_do_damage( upgraded, self, level.freezegun_enemies_dist_ratio[i] );
		}
		else if(IsPlayer(level.freezegun_enemies[i]))
		{
			weapon = "freezegun_zm";
			if(upgraded)
			{
				weapon = "freezegun_upgraded_zm";
			}
			level.freezegun_enemies[i] notify("grief_damage", weapon, "MOD_PROJECTILE", self);
		}
		else
		{
			level.freezegun_enemies[i] notify("damage", 0, self, undefined, undefined, "MOD_PROJECTILE");
		}
	}

	level.freezegun_enemies = [];
	level.freezegun_enemies_dist_ratio = [];
}


freezegun_get_cylinder_radius( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_cylinder_radius_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_cylinder_radius"];
	}
}


freezegun_get_inner_range( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_inner_range_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_inner_range"];
	}
}


freezegun_get_outer_range( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_outer_range_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_outer_range"];
	}
}


freezegun_get_inner_damage( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_inner_damage_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_inner_damage"];
	}
}


freezegun_get_outer_damage( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_outer_damage_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_outer_damage"];
	}
}


freezegun_get_shatter_range( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_shatter_range_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_shatter_range"];
	}
}


freezegun_get_shatter_inner_damage( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_shatter_inner_damage_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_shatter_inner_damage"];
	}
}


freezegun_get_shatter_outer_damage( upgraded )
{
	if ( upgraded )
	{
		return level.zombie_vars["freezegun_shatter_outer_damage_upgraded"];
	}
	else
	{
		return level.zombie_vars["freezegun_shatter_outer_damage"];
	}
}


freezegun_get_enemies_in_range( upgraded )
{
	inner_range = freezegun_get_inner_range( upgraded );
	outer_range = freezegun_get_outer_range( upgraded );
	cylinder_radius = freezegun_get_cylinder_radius( upgraded );

	view_pos = self GetWeaponMuzzlePoint();

	// Add a 10% epsilon to the range on this call to get guys right on the edge
	zombies = GetAiSpeciesArray( "axis", "all" );
	zombies = array_merge(zombies, level.freezegun_shatter_triggers);
	zombies = array_merge(zombies, get_players());
	zombies = get_array_of_closest( view_pos, zombies, undefined, undefined, (outer_range * 1.1) );
	if ( !isDefined( zombies ) )
	{
		return;
	}

	freezegun_inner_range_squared = inner_range * inner_range;
	freezegun_outer_range_squared = outer_range * outer_range;
	cylinder_radius_squared = cylinder_radius * cylinder_radius;

	forward_view_angles = self GetWeaponForwardDir();
	end_pos = view_pos + vector_scale( forward_view_angles, outer_range );

/#
	if ( 2 == GetDvarInt( #"scr_freezegun_debug" ) )
	{
		// push the near circle out a couple units to avoid an assert in Circle() due to it attempting to
		// derive the view direction from the circle's center point minus the viewpos
		// (which is what we're using as our center point, which results in a zeroed direction vector)
		near_circle_pos = view_pos + vector_scale( forward_view_angles, 2 );

		Circle( near_circle_pos, cylinder_radius, (1, 0, 0), false, false, 100 );
		Line( near_circle_pos, end_pos, (0, 0, 1), 1, false, 100 );
		Circle( end_pos, cylinder_radius, (1, 0, 0), false, false, 100 );
	}
#/

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) || !IsAlive( zombies[i] ) )
		{
			// guy died on us
			continue;
		}

		test_origin = zombies[i] GetCentroid();
		test_range_squared = DistanceSquared( view_pos, test_origin );
		if ( test_range_squared > freezegun_outer_range_squared )
		{
			zombies[i] freezegun_debug_print( "range", (1, 0, 0) );
			return; // everything else in the list will be out of range
		}

		normal = VectorNormalize( test_origin - view_pos );
		dot = VectorDot( forward_view_angles, normal );
		if ( 0 > dot )
		{
			// guy's behind us
			zombies[i] freezegun_debug_print( "dot", (1, 0, 0) );
			continue;
		}

		radial_origin = PointOnSegmentNearestToPoint( view_pos, end_pos, test_origin );
		if ( DistanceSquared( test_origin, radial_origin ) > cylinder_radius_squared )
		{
			// guy's outside the range of the cylinder of effect
			zombies[i] freezegun_debug_print( "cylinder", (1, 0, 0) );
			continue;
		}

		if ( !zombies[i] DamageConeTrace( view_pos, self ) && !BulletTracePassed( view_pos, test_origin, false, undefined ) && !SightTracePassed( view_pos, test_origin, false, undefined ) )
		{
			// guy can't actually be hit from where we are
			zombies[i] freezegun_debug_print( "cone", (1, 0, 0) );
			continue;
		}

		level.freezegun_enemies[level.freezegun_enemies.size] = zombies[i];
		level.freezegun_enemies_dist_ratio[level.freezegun_enemies_dist_ratio.size] = (freezegun_outer_range_squared - test_range_squared) / (freezegun_outer_range_squared - freezegun_inner_range_squared);
	}
}


freezegun_debug_print( msg, color )
{
/#
	if ( !GetDvarInt( #"scr_freezegun_debug" ) )
	{
		return;
	}

	if ( !isdefined( color ) )
	{
		color = (1, 1, 1);
	}

	Print3d(self.origin + (0,0,60), msg, color, 1, 1, 40); // 10 server frames is 1 second
#/
}


freezegun_do_damage( upgraded, player, dist_ratio )
{
	min_damage = Int( LerpFloat( freezegun_get_outer_damage(upgraded), freezegun_get_inner_damage(upgraded), dist_ratio ) );
	damage = Int( LerpFloat( int(self.maxhealth / 3) + 1, int((self.maxhealth * 2) / 3) + 1, dist_ratio ) );

	if(dist_ratio >= 1)
	{
		damage = self.maxhealth;
	}

	if(self.animname == "thief_zombie" || self.animname == "director_zombie")
	{
		damage = min_damage;
	}

	self.freezegun_damage += damage;

	if(self.freezegun_damage >= self.maxhealth)
	{
		min_damage = self.maxhealth;
	}

	self freezegun_debug_print( damage, (0, 1, 0) );

	self DoDamage( min_damage, player.origin, player, undefined, "projectile" );
}

freezegun_set_extremity_damage_fx()
{
	self setclientflag( level._ZOMBIE_ACTOR_FLAG_FREEZEGUN_EXTREMITY_DAMAGE_FX  );
}


freezegun_clear_extremity_damage_fx()
{
	self clearclientflag( level._ZOMBIE_ACTOR_FLAG_FREEZEGUN_EXTREMITY_DAMAGE_FX  );
}


freezegun_set_torso_damage_fx()
{
	self setclientflag( level._ZOMBIE_ACTOR_FLAG_FREEZEGUN_TORSO_DAMAGE_FX );
}


freezegun_clear_torso_damage_fx()
{
	self clearclientflag( level._ZOMBIE_ACTOR_FLAG_FREEZEGUN_TORSO_DAMAGE_FX );
}


freezegun_damage_response( player, amount )
{
	if ( IsDefined( self.freezegun_damage_response_func ) )
	{
		if ( self [[ self.freezegun_damage_response_func ]]( player, amount ) )
		{
			return;
		}
	}

	new_move_speed = self.zombie_move_speed;

	percent_dmg = self enemy_percent_damaged_by_freezegun();

	if ( 0.66 <= percent_dmg )
	{
		new_move_speed = "walk";
	}
	else if ( 0.33 <= percent_dmg )
	{
		if ( self.zombie_move_speed == "sprint" )
		{
			new_move_speed = "run";
		}
		else
		{
			new_move_speed = "walk";
		}
	}

	if ( is_true(self.zombie_move_speed_supersprint) )
	{
		self.zombie_move_speed_supersprint = false;

		maps\_zombiemode_spawner::set_zombie_run_cycle( new_move_speed );
	}
	else if ( !self.isdog && self.zombie_move_speed != new_move_speed )
	{
		maps\_zombiemode_spawner::set_zombie_run_cycle( new_move_speed );
	}

	self thread freezegun_set_extremity_damage_fx();
}

freezegun_do_gib( gib_type, upgraded )
{
	gibArray = [];
	gibArray[gibArray.size] = level._ZOMBIE_GIB_PIECE_INDEX_ALL;

	if ( upgraded )
	{
		gibArray[gibArray.size] = 7;
	}

	self gib( gib_type, gibArray );

	self hide();
	wait( 0.1 );
	self self_delete();
}


freezegun_do_shatter( player, weap, shatter_trigger )
{
	freezegun_debug_print( "shattered" );

	self freezegun_cleanup_freezegun_triggers( shatter_trigger );

	upgraded = (weap == "freezegun_upgraded_zm");
	self RadiusDamage( self.origin, freezegun_get_shatter_range( upgraded ), freezegun_get_shatter_inner_damage( upgraded ), freezegun_get_shatter_outer_damage( upgraded ), player, "MOD_EXPLOSIVE", weap );

	if ( is_mature() )
	{
		self thread freezegun_do_gib( "up", upgraded );
	}
	else
	{
		self StartRagdoll();
		self freezegun_clear_extremity_damage_fx();
		self freezegun_clear_torso_damage_fx();
	}
}


freezegun_wait_for_shatter( player, weap, shatter_trigger )
{
	self endon( "cleanup_freezegun_triggers" );

	// must wait 2 frames - instant shatters cause crash eventually
	wait_network_frame();
	wait_network_frame();

	while(1)
	{
		shatter_trigger waittill( "damage", amount, attacker, dir, org, mod );

		if(!is_freezegun_shatter_damage(mod))
		{
			break;
		}
	}

	if(self is_freezegun_damage(mod))
	{
		self thread freezegun_do_crumple( player, weap, shatter_trigger );
	}
	else
	{
		self thread freezegun_do_shatter( player, weap, shatter_trigger );
	}
}


freezegun_do_crumple( player, weap, shatter_trigger )
{
	freezegun_debug_print( "crumpled" );

	self freezegun_cleanup_freezegun_triggers( shatter_trigger );

	upgraded = (weap == "freezegun_upgraded_zm");

	if ( isDefined( self ) )
	{
		if ( is_mature() )
		{
			self thread freezegun_do_gib( "freeze", upgraded );
		}
		else
		{
			self StartRagdoll();
			self freezegun_clear_extremity_damage_fx();
			self freezegun_clear_torso_damage_fx();
		}
	}
}


freezegun_wait_for_crumple( player, weap, shatter_trigger )
{
	self endon( "cleanup_freezegun_triggers" );

	// must wait 2 frames - instant shatters cause crash eventually
	wait_network_frame();
	wait_network_frame();

	test_origin = self GetCentroid();
	touching = false;
	while(1)
	{
		zombies = GetAiSpeciesArray( "axis", "all" );
		zombies = array_merge(zombies, get_players());
		for(i=0;i<zombies.size;i++)
		{
			origin = zombies[i] GetCentroid();

			if ( !zombies[i] DamageConeTrace( test_origin, self ) && !BulletTracePassed( origin, test_origin, false, undefined ) && !SightTracePassed( origin, test_origin, false, undefined ) )
			{
				continue;
			}

			if(DistanceSquared(origin, test_origin) < 64*64)
			{
				touching = true;
				break;
			}
		}

		if(touching)
		{
			break;
		}

		wait_network_frame();
	}

	self thread freezegun_do_shatter( player, weap, shatter_trigger );
}


freezegun_cleanup_freezegun_triggers( shatter_trigger )
{
	self notify( "cleanup_freezegun_triggers" );

	level.freezegun_shatter_triggers = array_remove(level.freezegun_shatter_triggers, shatter_trigger);

	shatter_trigger Delete();
}


// call this when we skip out of freezegun_death() to run the things we skipped in zombie_death_event()
freezegun_run_skipped_death_events()
{
	self thread maps\_zombiemode_audio::do_zombies_playvocals( "death", self.animname );
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();
}


freezegun_death( hit_location, hit_origin, player )
{
	if ( self.isdog )
	{
		self freezegun_run_skipped_death_events();
		return;
	}

	if ( !self.has_legs )
	{
		if ( !isDefined( level._zombie_freezegun_death_missing_legs[self.animname] ) )
		{
			self freezegun_run_skipped_death_events();
			return;
		}

		self.deathanim = random( level._zombie_freezegun_death_missing_legs[self.animname] );
	}
	else
	{
		if ( !isDefined( level._zombie_freezegun_death[self.animname] ) )
		{
			self freezegun_run_skipped_death_events();
			return;
		}

		self.deathanim = random( level._zombie_freezegun_death[self.animname] );
	}

	self.freezegun_death = true;
	self.skip_death_notetracks = true;
	self.nodeathragdoll = true;

	self PlaySound( "wpn_freezegun_impact_zombie" );

	if ( IsPlayer( player ) )
	{
		if( RandomIntRange(0,101) >= 88 )
		{
			player maps\_zombiemode_audio::create_and_play_dialog( "kill", "freeze" );
		}
	}

	anim_len = getanimlength( self.deathanim );

	self thread freezegun_set_extremity_damage_fx();
	self thread freezegun_set_torso_damage_fx();

	shatter_trigger = spawn( "trigger_damage", self.origin, 0, 15, 72 );
	shatter_trigger enablelinkto();
	shatter_trigger linkto( self );
	level.freezegun_shatter_triggers = array_add(level.freezegun_shatter_triggers, shatter_trigger, false);

	/*spawnflags = 1 + 2 + 4 + 16 + 64; // SF_TOUCH_AI_AXIS | SF_TOUCH_AI_ALLIES | SF_TOUCH_AI_NEUTRAL | SF_TOUCH_VEHICLE | SF_TOUCH_ONCE
	crumple_trigger = spawn( "trigger_radius", self.origin, spawnflags, 15, 72 );
	crumple_trigger enablelinkto();
	crumple_trigger linkto( self );*/

	weap = self.damageweapon;
	if(weap != "freezegun_zm" && weap != "freezegun_upgraded_zm")
	{
		weap = "freezegun_zm";
	}

	self thread freezegun_wait_for_shatter( player, weap, shatter_trigger );
	self thread freezegun_wait_for_crumple( player, weap, shatter_trigger );
	self endon( "cleanup_freezegun_triggers" );

	if(!is_true(self.in_the_ground) && !is_true(self.in_the_ceiling))
	{
		wait( anim_len * 0.625 ); // force the zombie to crumple if he is untouched after time
	}
	else
	{
		// must wait 2 frames - instant shatters cause crash eventually
		wait_network_frame();
		wait_network_frame();
	}

	self thread freezegun_do_shatter( player, weap, shatter_trigger );
}


is_freezegun_damage( mod )
{
	// added for the water hazard
	if ( is_true( self.water_damage ) )
	{
		return true;
	}

	return (("MOD_PROJECTILE" == mod) && IsDefined( self.damageweapon ) && (self.damageweapon == "freezegun_zm" || self.damageweapon == "freezegun_upgraded_zm"));
}


is_freezegun_shatter_damage( mod )
{
	return (("MOD_EXPLOSIVE" == mod) && IsDefined( self.damageweapon ) && (self.damageweapon == "freezegun_zm" || self.damageweapon == "freezegun_upgraded_zm"));
}


should_do_freezegun_death( mod )
{
	return is_freezegun_damage( mod );
}


enemy_damaged_by_freezegun()
{
	return 0 < self.freezegun_damage;
}


enemy_percent_damaged_by_freezegun()
{
	return self.freezegun_damage / self.maxhealth;
}


enemy_killed_by_freezegun()
{
	return ( IsDefined( self.freezegun_death ) && self.freezegun_death == true );
}

freezegun_network_choke()
{
	if ( level.freezegun_network_choke_count != 0 && !(level.freezegun_network_choke_count % 4) )
	{
		wait_network_frame();
		//wait_network_frame();
		//wait_network_frame();
	}

	level.freezegun_network_choke_count++;
}