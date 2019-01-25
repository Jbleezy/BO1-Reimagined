#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

hack_wallbuys()
{
	weapon_spawns = GetEntArray( "weapon_upgrade", "targetname" );

	for(i = 0; i < weapon_spawns.size; i ++)
	{

		if(WeaponType( weapon_spawns[i].zombie_weapon_upgrade ) == "grenade")
		{
			continue;
		}

		if(WeaponType( weapon_spawns[i].zombie_weapon_upgrade ) == "melee")
		{
			continue;
		}

		if(WeaponType( weapon_spawns[i].zombie_weapon_upgrade ) == "mine")
		{
			continue;
		}


		if(WeaponType( weapon_spawns[i].zombie_weapon_upgrade ) == "bomb")
		{
			continue;
		}


		struct = SpawnStruct();
		struct.origin = weapon_spawns[i].origin;
		struct.radius = 48;
		struct.height = 48;
		struct.script_float = 2;
		struct.script_int = 5000;
		struct.wallbuy = weapon_spawns[i];
		maps\_zombiemode_equip_hacker::register_pooled_hackable_struct(struct, ::wallbuy_hack);
	}

	bowie_triggers = GetEntArray( "bowie_upgrade", "targetname" );

	array_thread(bowie_triggers, maps\_zombiemode_equip_hacker::hide_hint_when_hackers_active);
}

wallbuy_hack(hacker)
{
	self.wallbuy.hacked = true;
	model = getent( self.wallbuy.target, "targetname" ); 
	self.wallbuy maps\_zombiemode_weapons::weapon_set_first_time_hint( level.zombie_weapons[self.wallbuy.zombie_weapon_upgrade].cost, level.zombie_weapons[self.wallbuy.zombie_weapon_upgrade].ammo_cost );
	if(!self.wallbuy.first_time_triggered)
	{
		self.wallbuy.first_time_triggered = true;
		model maps\_zombiemode_weapons::weapon_show( hacker );
	}
	model RotateRoll(180, 0.5);
	maps\_zombiemode_equip_hacker::deregister_hackable_struct(self);
}
