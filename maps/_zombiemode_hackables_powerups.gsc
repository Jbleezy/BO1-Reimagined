#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;


unhackable_powerup(name)
{
	ret = false;

	switch(name)
	{
		case "bonus_points_team":
		case "lose_points_team":
		case "bonus_points_player":
		case "random_weapon":
		case "free_perk":
			ret = true;
			break;
	}

	return ret;
}

hack_powerups()
{
	while(1)
	{
		level waittill("powerup_dropped", powerup);

		if(!unhackable_powerup(powerup.powerup_name))
		{
			struct = SpawnStruct();
			struct.origin = powerup.origin;
			struct.radius = 84;
			struct.height = 72;
			struct.script_float = 5;
			struct.script_int = 5000;
			struct.powerup = powerup;
			struct.entity = powerup;

			powerup thread powerup_pickup_watcher(struct);

			maps\_zombiemode_equip_hacker::register_pooled_hackable_struct(struct, ::powerup_hack );
		}
	}
}

powerup_pickup_watcher(powerup_struct)
{
	self endon("hacked");
	self waittill("death");

	maps\_zombiemode_equip_hacker::deregister_hackable_struct(powerup_struct);
}

powerup_hack(hacker)
{
	self.powerup notify("hacked");

	if(IsDefined(self.powerup.zombie_grabbable) && self.powerup.zombie_grabbable)
	{
		self.powerup notify("powerup_timedout");
		origin = self.powerup.origin;
		self.powerup Delete();

		self.powerup = maps\_zombiemode_net::network_safe_spawn( "powerup", 1, "script_model", origin);

		if ( IsDefined(self.powerup) )
		{
			self.powerup maps\_zombiemode_powerups::powerup_setup( "full_ammo" );

			self.powerup thread maps\_zombiemode_powerups::powerup_timeout();
			self.powerup thread maps\_zombiemode_powerups::powerup_wobble();
			self.powerup thread maps\_zombiemode_powerups::powerup_grab();
		}
	}
	else if(self.powerup.powerup_name == "full_ammo")
	{
		self.powerup notify("powerup_timedout");
		origin = self.powerup.origin;
		self.powerup Delete();

		self.powerup = maps\_zombiemode_net::network_safe_spawn( "powerup", 1, "script_model", origin);

		if ( IsDefined(self.powerup) )
		{
			self.powerup maps\_zombiemode_powerups::powerup_setup( "free_perk" );

			self.powerup thread maps\_zombiemode_powerups::powerup_timeout();
			self.powerup thread maps\_zombiemode_powerups::powerup_wobble();
			self.powerup thread maps\_zombiemode_powerups::powerup_grab();
		}
	}
	else
	{
		self.powerup notify("powerup_timedout");
		origin = self.powerup.origin;
		self.powerup Delete();

		self.powerup = maps\_zombiemode_net::network_safe_spawn( "powerup", 1, "script_model", origin);

		if ( IsDefined(self.powerup) )
		{
			self.powerup maps\_zombiemode_powerups::powerup_setup( "full_ammo" );

			self.powerup thread maps\_zombiemode_powerups::powerup_timeout();
			self.powerup thread maps\_zombiemode_powerups::powerup_wobble();
			self.powerup thread maps\_zombiemode_powerups::powerup_grab();
		}
	}

	maps\_zombiemode_equip_hacker::deregister_hackable_struct(self);
}
