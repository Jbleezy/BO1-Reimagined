// _sticky_grenade.csc
// Sets up clientside behavior for the sticky grenade
#include clientscripts\_utility;

main()
{
	level._effect["grenade_enemy_light"] = loadfx( "weapon/crossbow/fx_trail_crossbow_blink_red_os" );
	level._effect["grenade_friendly_light"] = loadfx( "weapon/crossbow/fx_trail_crossbow_blink_grn_os" );

	level.zombie_sticky_grenade_spawned_func = ::spawned;
}


spawned( localClientNum, play_sound ) // self == the grenade
{
	self endon( "entityshutdown" );

	player = GetLocalPlayer( localClientNum );
	enemy = false;
	self.fxTagName = "tag_fx";

	if ( self.team != player.team )
	{
		enemy = true;
	}

	if ( enemy )
	{
		if( play_sound )
		{
			self thread loop_local_sound( localClientNum, "wpn_semtex_alert", 0.3, level._effect["grenade_enemy_light"] );
		}
		else
		{
			PlayFXOnTag( localClientNum, level._effect["grenade_enemy_light"], self, self.fxTagName );
		}
	}
	else
	{
		if( play_sound )
		{
			//PrintLn("play sound");
			self thread loop_local_sound( localClientNum, "wpn_semtex_alert", 0.3, level._effect["grenade_friendly_light"] );
		}
		else
		{
			PlayFXOnTag( localClientNum, level._effect["grenade_friendly_light"], self, self.fxTagName );
		}
	}
}

loop_local_sound( localClientNum, alias, interval, fx ) // self == the grenade
{
	self endon( "entityshutdown" );

	while(1)
	{
		self PlaySound( localClientNum, alias );
		PlayFXOnTag( localClientNum, fx, self, self.fxTagName );

		realwait(interval);
		interval = (interval / 1.2);

		if (interval < .05)
		{
			interval = .05;
		}
	}
}
