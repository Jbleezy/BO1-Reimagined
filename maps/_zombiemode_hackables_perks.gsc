#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;

hack_perks()
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );

	for(i = 0; i < vending_triggers.size; i ++)
	{
		struct = SpawnStruct();
		machine = getentarray(vending_triggers[i].target, "targetname");
		struct.origin = machine[0].origin  + (AnglesToRight(machine[0].angles) * 18) + (0,0,48);
		struct.radius = 48;
		struct.height = 64;
		struct.script_float = 5;

		while(!IsDefined(vending_triggers[i].cost))
		{
			wait(0.05);
		}

		struct.script_int = Int(vending_triggers[i].cost * -1);
		struct.perk = vending_triggers[i];
		vending_triggers[i].hackable = struct;
		maps\_zombiemode_equip_hacker::register_pooled_hackable_struct(struct, ::perk_hack, ::perk_hack_qualifier);
	}

	level._solo_revive_machine_expire_func = ::solo_revive_expire_func;
}

solo_revive_expire_func()
{
	if(IsDefined(self.hackable))
	{
		maps\_zombiemode_equip_hacker::deregister_hackable_struct(self.hackable);
		self.hackable = undefined;
	}
}

perk_hack_qualifier(player)
{
	if(IsDefined(player._retain_perks))
	{
		return false;
	}

	if(player HasPerk(self.perk.script_noteworthy))
	{
		return true;
	}

	return false;
}

perk_hack(hacker)
{
	if ( flag( "solo_game" ) && self.perk.script_noteworthy == "specialty_quickrevive" )
	{
		hacker.lives--;
		level.solo_lives_given--;
	}

	hacker notify(self.perk.script_noteworthy + "_stop");
	hacker playsoundtoplayer( "evt_perk_throwup", hacker );

	/*if ( isdefined( hacker.perk_hud ) )
	{
		keys = getarraykeys( hacker.perk_hud );
		for ( i = 0; i < hacker.perk_hud.size; i++ )
		{
			hacker.perk_hud[ keys[i] ].x = i * 30;
		}
	}*/
}
