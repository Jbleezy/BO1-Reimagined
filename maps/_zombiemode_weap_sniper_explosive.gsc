#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

init()
{
	if ( !maps\_zombiemode_weapons::is_weapon_included( "sniper_explosive_zm" ) )
	{
		return;
	}

	level._ZOMBIE_ACTOR_FLAG_SNIPER_EXPLOSIVE_DEATH = 13;

	level._effect["sniper_explosive_death_mist"] = loadfx( "maps/zombie/fx_zmb_coast_jackal_death" );

	maps\_zombiemode_spawner::register_zombie_death_animscript_callback( ::sniper_explosive_death_response );

	level thread sniper_explosive_on_player_connect();
}


sniper_explosive_on_player_connect()
{
	for( ;; )
	{
		level waittill( "connecting", player );
		player thread wait_for_sniper_explosive_fired();
		player thread watch_for_sniper_bolt();
		//player thread disable_ads_while_reloading();
	}
}


wait_for_sniper_explosive_fired()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );

	for( ;; )
	{
		self waittill( "weapon_fired" );
		currentweapon = self GetCurrentWeapon();
		if( ( currentweapon == "sniper_explosive_zm" ) || ( currentweapon == "sniper_explosive_upgraded_zm" ) )
		{
			self thread sniper_explosive_fired( currentweapon == "sniper_explosive_upgraded_zm" );

			view_pos = self GetTagOrigin( "tag_flash" ) - self GetPlayerViewHeight();
			view_angles = self GetTagAngles( "tag_flash" );
//			playfx( level._effect["sniper_explosive_smoke_cloud"], view_pos, AnglesToForward( view_angles ), AnglesToUp( view_angles ) );
		}
	}
}


sniper_explosive_fired( upgraded )
{
}


sniper_explosive_death_response_internal( player )
{
	if ( isdefined( player ) )
	{
		player maps\_zombiemode_score::player_add_points( "death", "", "" );

		if ( isdefined( player.shooting_on_location_count ) )
		{
			player.shooting_on_location_count++;
		}
	}

	// prevent them freezing the water, sice they were turned to mist
	self.water_damage = false;

	self hide();
	self setclientflag( level._ZOMBIE_ACTOR_FLAG_SNIPER_EXPLOSIVE_DEATH );

	wait ( 0.4 );
	self delete();
}


sniper_explosive_death_response()
{
	if ( !self is_sniper_explosive_damage( self.damagemod ) )
	{
		return false;
	}

	self thread sniper_explosive_death_response_internal( self.attacker );

	return true;
}


sniper_explosive_debug_print( msg, color )
{
/#
	if ( !GetDvarInt( #"scr_sniper_explosive_debug" ) )
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


is_sniper_explosive_damage( mod )
{
	return (("MOD_GRENADE" == mod || "MOD_GRENADE_SPLASH" == mod) && IsDefined( self.damageweapon ) && (self.damageweapon == "sniper_explosive_bolt_zm" || self.damageweapon == "sniper_explosive_bolt_upgraded_zm"));
}


should_do_sniper_explosive_death( mod )
{
	return is_sniper_explosive_damage( mod );
}

watch_for_sniper_bolt()
{
    self endon( "death" );
	self endon( "disconnect" );

	for (;;)
	{
		self waittill ( "grenade_fire", grenade, weaponName, parent );

		switch( weaponName )
		{
			case "sniper_explosive_bolt_zm":
			case "sniper_explosive_bolt_upgraded_zm":
				self thread shooting_on_location_achievement_check( grenade, (GetWeaponFuseTime( weaponName ) / 1000) );
				grenade thread ubersniper_bolt_audio();

				linked_ent = grenade GetLinkedEnt();
				if( IsDefined( linked_ent ) && IsAI( linked_ent ) && is_true( linked_ent.is_zombie ) )
				{
				    self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "ubersniper" );
				    linked_ent DoDamage( 1, grenade.origin, self, 0, "impact" );
				}
				break;
		}
	}
}

shooting_on_location_achievement_check( grenade, fusetime )
{
	self endon( "disconnect" );

	if ( (1200 * 1200) > DistanceSquared( self.origin, grenade.origin ) )
	{
		return;
	}

	wait( fusetime - 0.5 );
	self.shooting_on_location_count = 0;
	grenade waittill( "explode" );
	wait( 0.2 );

	if ( self.shooting_on_location_count >= 10 )
	{
		self notify( "shooting_on_location_achieved" );
	}
}

ubersniper_bolt_audio()
{
    self PlaySound( "wpn_ubersniper_rampup" );
    wait(2.1);
    self PlaySound( "wpn_ubersniper_snapshot" );
}

disable_ads_while_reloading()
{
	self endon( "death" );
	self endon( "disconnect" );

	while(1)
	{
		currentweapon = self GetCurrentWeapon();
		if((currentweapon == "sniper_explosive_zm") || (currentweapon == "sniper_explosive_upgraded_zm"))
		{
			self waittill("reload_start");
			currentweapon = self GetCurrentWeapon();
			if((currentweapon == "sniper_explosive_zm") || (currentweapon == "sniper_explosive_upgraded_zm"))
			{
				wait_network_frame();
				self AllowADS(false);
				while(self.is_reloading)
					wait_network_frame();
				self AllowADS(true);
			}
		}
		wait .05;
	}
}