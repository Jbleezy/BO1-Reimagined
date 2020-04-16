#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_net;

#using_animtree( "generic_human" );

init()
{
	if( !maps\_zombiemode_weapons::is_weapon_included( "thundergun_zm" ) )
	{
		return;
	}

	// precache the clientside effects
	level._effect["thundergun_viewmodel_power_cell1"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view1");
	level._effect["thundergun_viewmodel_power_cell2"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view2");
	level._effect["thundergun_viewmodel_power_cell3"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view3");
	level._effect["thundergun_viewmodel_steam"] = loadfx("weapon/thunder_gun/fx_thundergun_steam_view");

	level._effect["thundergun_viewmodel_power_cell1_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view1");
	level._effect["thundergun_viewmodel_power_cell2_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view2");
	level._effect["thundergun_viewmodel_power_cell3_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_power_cell_view3");
	level._effect["thundergun_viewmodel_steam_upgraded"] = loadfx("weapon/thunder_gun/fx_thundergun_steam_view");


	level._effect["thundergun_knockdown_ground"]	= loadfx( "weapon/thunder_gun/fx_thundergun_knockback_ground" );
	level._effect["thundergun_smoke_cloud"]			= loadfx( "weapon/thunder_gun/fx_thundergun_smoke_cloud" );

	set_zombie_var( "thundergun_cylinder_radius",		180 );
	set_zombie_var( "thundergun_fling_range",			450 ); // 40 feet
	set_zombie_var( "thundergun_gib_range",				900 ); // 75 feet
	set_zombie_var( "thundergun_gib_damage",			0 );
	set_zombie_var( "thundergun_knockdown_range",		1200 ); // 100 feet
	set_zombie_var( "thundergun_knockdown_damage",		0 );

	level.thundergun_gib_refs = [];
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "guts";
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "right_arm";
	level.thundergun_gib_refs[level.thundergun_gib_refs.size] = "left_arm";

	level thread thundergun_on_player_connect();
}


thundergun_on_player_connect()
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
		if( ( currentweapon == "thundergun_zm" ) || ( currentweapon == "thundergun_upgraded_zm" ) )
		{
			self thread thundergun_fired(currentweapon);

			view_pos = self GetTagOrigin( "tag_flash" ) - self GetPlayerViewHeight();
			view_angles = self GetTagAngles( "tag_flash" );
			playfx( level._effect["thundergun_smoke_cloud"], view_pos, AnglesToForward( view_angles ), AnglesToUp( view_angles ) );
		}
	}
}


thundergun_network_choke()
{
	if ( level.thundergun_network_choke_count != 0 && !(level.thundergun_network_choke_count % 4) )
	{
		wait_network_frame();
		//wait_network_frame();
		//wait_network_frame();
	}

	level.thundergun_network_choke_count++;
}


thundergun_fired(currentweapon)
{
	// ww: physics hit when firing
	PhysicsExplosionCylinder( self.origin, 600, 240, 1 );

	if ( !IsDefined( level.thundergun_knockdown_enemies ) )
	{
		level.thundergun_knockdown_enemies = [];
		level.thundergun_knockdown_gib = [];
		level.thundergun_fling_enemies = [];
		level.thundergun_fling_vecs = [];
	}

	self thundergun_get_enemies_in_range();

	//iprintlnbold( "flg: " + level.thundergun_fling_enemies.size + " gib: " + level.thundergun_gib_enemies.size + " kno: " + level.thundergun_knockdown_enemies.size );

	level.thundergun_network_choke_count = 0;
	for ( i = 0; i < level.thundergun_fling_enemies.size; i++ )
	{
		//thundergun_network_choke();
		if(IsAI(level.thundergun_fling_enemies[i]))
		{
			level.thundergun_fling_enemies[i] thread thundergun_fling_zombie( self, level.thundergun_fling_vecs[i], i );
		}
		else if(IsPlayer(level.thundergun_fling_enemies[i]))
		{
			vec = vector_scale( level.thundergun_fling_vecs[i], 3 );
			level.thundergun_fling_enemies[i] notify("grief_damage", currentweapon, "MOD_PROJECTILE", self, true, vec);
		}
	}

	for ( i = 0; i < level.thundergun_knockdown_enemies.size; i++ )
	{
		//thundergun_network_choke();
		if(IsAI(level.thundergun_fling_enemies[i]))
		{
			level.thundergun_knockdown_enemies[i] thread thundergun_knockdown_zombie( self, level.thundergun_knockdown_gib[i] );
		}
		else if(IsPlayer(level.thundergun_fling_enemies[i]))
		{
			level.thundergun_fling_enemies[i] notify("grief_damage", currentweapon, "MOD_PROJECTILE", self);
		}
	}

	level.thundergun_knockdown_enemies = [];
	level.thundergun_knockdown_gib = [];
	level.thundergun_fling_enemies = [];
	level.thundergun_fling_vecs = [];
}


thundergun_get_enemies_in_range()
{
	view_pos = self GetWeaponMuzzlePoint();
	zombies = GetAiSpeciesArray( "axis", "all" );
	zombies = array_merge(zombies, get_players());
	zombies = get_array_of_closest( view_pos, zombies, undefined, undefined, level.zombie_vars["thundergun_knockdown_range"] );
	if ( !isDefined( zombies ) )
	{
		return;
	}

	knockdown_range_squared = level.zombie_vars["thundergun_knockdown_range"] * level.zombie_vars["thundergun_knockdown_range"];
	gib_range_squared = level.zombie_vars["thundergun_gib_range"] * level.zombie_vars["thundergun_gib_range"];
	fling_range_squared = level.zombie_vars["thundergun_fling_range"] * level.zombie_vars["thundergun_fling_range"];
	cylinder_radius_squared = level.zombie_vars["thundergun_cylinder_radius"] * level.zombie_vars["thundergun_cylinder_radius"];

	forward_view_angles = self GetWeaponForwardDir();
	end_pos = view_pos + vector_scale( forward_view_angles, level.zombie_vars["thundergun_knockdown_range"] );

/#
	if ( 2 == GetDvarInt( #"scr_thundergun_debug" ) )
	{
		// push the near circle out a couple units to avoid an assert in Circle() due to it attempting to
		// derive the view direction from the circle's center point minus the viewpos
		// (which is what we're using as our center point, which results in a zeroed direction vector)
		near_circle_pos = view_pos + vector_scale( forward_view_angles, 2 );

		Circle( near_circle_pos, level.zombie_vars["thundergun_cylinder_radius"], (1, 0, 0), false, false, 100 );
		Line( near_circle_pos, end_pos, (0, 0, 1), 1, false, 100 );
		Circle( end_pos, level.zombie_vars["thundergun_cylinder_radius"], (1, 0, 0), false, false, 100 );
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
		if ( test_range_squared > knockdown_range_squared )
		{
			zombies[i] thundergun_debug_print( "range", (1, 0, 0) );
			return; // everything else in the list will be out of range
		}

		normal = VectorNormalize( test_origin - view_pos );
		dot = VectorDot( forward_view_angles, normal );
		if ( 0 > dot )
		{
			// guy's behind us
			zombies[i] thundergun_debug_print( "dot", (1, 0, 0) );
			continue;
		}

		radial_origin = PointOnSegmentNearestToPoint( view_pos, end_pos, test_origin );
		if ( DistanceSquared( test_origin, radial_origin ) > cylinder_radius_squared )
		{
			// guy's outside the range of the cylinder of effect
			zombies[i] thundergun_debug_print( "cylinder", (1, 0, 0) );
			continue;
		}

		if ( !zombies[i] DamageConeTrace( view_pos, self ) && !BulletTracePassed( view_pos, test_origin, false, undefined ) && !SightTracePassed( view_pos, test_origin, false, undefined ) )
		{
			// guy can't actually be hit from where we are
			zombies[i] thundergun_debug_print( "cone", (1, 0, 0) );
			continue;
		}

		if ( test_range_squared < fling_range_squared )
		{
			level.thundergun_fling_enemies[level.thundergun_fling_enemies.size] = zombies[i];

			// the closer they are, the harder they get flung
			dist_mult = (fling_range_squared - test_range_squared) / fling_range_squared;
			
			angles = self GetPlayerAngles();
			up_angle = angles[0];
			if(up_angle > -15)
			{
				up_angle = -15;
			}
			angles = (up_angle, angles[1], angles[2]);

			fling_vec = AnglesToForward(angles);
			fling_vec = vector_scale( fling_vec, 200 + 200 * dist_mult );
			level.thundergun_fling_vecs[level.thundergun_fling_vecs.size] = fling_vec;

			zombies[i] thread setup_thundergun_vox( self, true, false, false );
		}
		else
		{
			level.thundergun_knockdown_enemies[level.thundergun_knockdown_enemies.size] = zombies[i];
			level.thundergun_knockdown_gib[level.thundergun_knockdown_gib.size] = false;

			zombies[i] thread setup_thundergun_vox( self, false, false, true );
		}
	}
}

thundergun_debug_print( msg, color )
{
/#
	if ( !GetDvarInt( #"scr_thundergun_debug" ) )
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


thundergun_fling_zombie( player, fling_vec, index )
{
	if( !IsDefined( self ) || !IsAlive( self ) )
	{
		// guy died on us
		return;
	}

	if ( IsDefined( self.thundergun_fling_func ) )
	{
		self [[ self.thundergun_fling_func ]]( player );
		return;
	}

	self DoDamage( self.health + 666, player.origin, player );

	if ( self.health <= 0 )
	{
		points = maps\_zombiemode_score::get_zombie_death_player_points();
		/*points = 10;
		if ( !index )
		{
			points = maps\_zombiemode_score::get_zombie_death_player_points();
		}
		else if ( 1 == index )
		{
			points = 30;
		}*/

		if(!self.isdog)
		{
			player maps\_zombiemode_score::player_add_points( "thundergun_fling", points );
		}

		self StartRagdoll();
		self LaunchRagdoll( fling_vec );

		self.thundergun_death = true;
	}
}


thundergun_knockdown_zombie( player, gib )
{
	self endon( "death" );
	playsoundatposition ("vox_thundergun_forcehit", self.origin);
	playsoundatposition ("wpn_thundergun_proj_impact", self.origin);


	if( !IsDefined( self ) || !IsAlive( self ) )
	{
		// guy died on us
		return;
	}

	if ( IsDefined( self.thundergun_knockdown_func ) )
	{
		self [[ self.thundergun_knockdown_func ]]( player, gib );
	}
	else
	{

		//self DoDamage( level.zombie_vars["thundergun_knockdown_damage"], player.origin, player );



	}

	if ( gib )
	{
		self.a.gib_ref = random( level.thundergun_gib_refs );
		self thread animscripts\zombie_death::do_gib();
	}

//	self playsound( "thundergun_impact" );
	self.thundergun_handle_pain_notetracks = ::handle_thundergun_pain_notetracks;
	//self DoDamage( level.zombie_vars["thundergun_knockdown_damage"], player.origin, player );
	self playsound( "fly_thundergun_forcehit" );

}


handle_thundergun_pain_notetracks( note )
{
	if ( note == "zombie_knockdown_ground_impact" )
	{
		playfx( level._effect["thundergun_knockdown_ground"], self.origin, AnglesToForward( self.angles ), AnglesToUp( self.angles ) );
		self playsound( "fly_thundergun_forcehit" );
	}
}


is_thundergun_damage()
{
	return IsDefined( self.damageweapon ) && (self.damageweapon == "thundergun_zm" || self.damageweapon == "thundergun_upgraded_zm") && (self.damagemod != "MOD_GRENADE" && self.damagemod != "MOD_GRENADE_SPLASH");
}


enemy_killed_by_thundergun()
{
	return ( IsDefined( self.thundergun_death ) && self.thundergun_death == true );
}


thundergun_sound_thread()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );


	for( ;; )
	{
		result = self waittill_any_return( "grenade_fire", "death", "player_downed", "weapon_change", "grenade_pullback" );

		if ( !IsDefined( result ) )
		{
			continue;
		}

		if( ( result == "weapon_change" || result == "grenade_fire" ) && self GetCurrentWeapon() == "thundergun_zm" )
		{
			self PlayLoopSound( "tesla_idle", 0.25 );

		}
		else
		{
			self notify ("weap_away");
			self StopLoopSound(0.25);


		}
	}
}

//SELF = Zombie Being Hit With Thundergun
setup_thundergun_vox( player, fling, gib, knockdown )
{
	if( !IsDefined( self ) || !IsAlive( self ) )
	{
		return;
	}

	if( !fling && ( gib || knockdown ) )
	{
		if( 25 > RandomIntRange( 1, 100 ) )
		{
			//IPrintLnBold( "HAHA, You Knocked Down Some Zombies!" );
		}
	}

	if( fling )
	{
		if( 30 > RandomIntRange( 1, 100 ) )
		{
			//IPrintLnBold( "WAY TO DISINTEGRATE THEM!!" );
			player maps\_zombiemode_audio::create_and_play_dialog( "kill", "thundergun" );
		}
	}
}
