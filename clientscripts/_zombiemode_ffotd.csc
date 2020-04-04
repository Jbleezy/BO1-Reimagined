#include clientscripts\_utility;
#include clientscripts\_zombiemode_weapons;

main_start()
{
	include_weapons();

	players = GetLocalPlayers();
	for(i = 0; i < players.size; i++)
	{
		players[i] thread set_fov();
		players[i] thread fog_setting();
		players[i] thread grenade_hud(i);
	}

	// registerSystem("hud", ::hud);
	registerSystem("client_systems", ::client_systems_message_handler);
	register_client_system("hud_anim_handler", ::hud_message_handler);

	//level thread notetrack_think();
}

main_end()
{
	clientscripts\_zombiemode_perks::init();
}

notetrack_think()
{
	for ( ;; )
	{
		level waittill( "notetrack", localclientnum, note );

		iprintlnbold(note);
	}
}

include_weapons()
{
	if(GetDvar("mapname") == "zombie_cod5_prototype")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "stoner63_zm" );
		include_weapon( "ppsh_zm" );
		include_weapon( "psg1_zm" );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "molotov_zm" );
	}
	else if(GetDvar("mapname") == "zombie_cod5_asylum")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "stoner63_zm" );
		include_weapon( "ppsh_zm" );
		include_weapon( "psg1_zm" );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "molotov_zm" );
	}
	else if(GetDvar("mapname") == "zombie_cod5_sumpf")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "stoner63_zm" );
		include_weapon( "ppsh_zm" );
		include_weapon( "psg1_zm" );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "molotov_zm" );
	}
	else if(GetDvar("mapname") == "zombie_cod5_factory")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "ak47_upgraded_zm", false );
		include_weapon( "stoner63_zm" );
		include_weapon( "stoner63_upgraded_zm", false );
		include_weapon( "ppsh_zm" );
		include_weapon( "ppsh_upgraded_zm", false );
		include_weapon( "psg1_zm" );
		include_weapon( "psg1_upgraded_zm", false );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "combat_bowie_knife_zm", false );
		include_weapon( "molotov_zm" );
	}
	else if(GetDvar("mapname") == "zombie_theater")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "ak47_upgraded_zm", false );
		include_weapon( "stoner63_zm" );
		include_weapon( "stoner63_upgraded_zm", false );
		include_weapon( "ppsh_zm" );
		include_weapon( "ppsh_upgraded_zm", false );
		include_weapon( "psg1_zm" );
		include_weapon( "psg1_upgraded_zm", false );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "combat_bowie_knife_zm", false );
	}
	else if(GetDvar("mapname") == "zombie_pentagon")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "ak47_upgraded_zm", false );
		include_weapon( "stoner63_zm" );
		include_weapon( "stoner63_upgraded_zm", false );
		include_weapon( "ppsh_zm" );
		include_weapon( "ppsh_upgraded_zm", false );
		include_weapon( "psg1_zm" );
		include_weapon( "psg1_upgraded_zm", false );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "combat_bowie_knife_zm", false );
	}
	else if(GetDvar("mapname") == "zombie_cosmodrome")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "ak47_upgraded_zm", false );
		include_weapon( "stoner63_zm" );
		include_weapon( "stoner63_upgraded_zm", false );
		include_weapon( "ppsh_zm" );
		include_weapon( "ppsh_upgraded_zm", false );
		include_weapon( "psg1_zm" );
		include_weapon( "psg1_upgraded_zm", false );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "combat_sickle_knife_zm", false );
	}
	else if(GetDvar("mapname") == "zombie_coast")
	{
		include_weapon( "sticky_grenade_zm", false );
		
		include_weapon( "ak47_zm" );
		include_weapon( "ak47_upgraded_zm", false );
		include_weapon( "stoner63_zm" );
		include_weapon( "stoner63_upgraded_zm", false );
		include_weapon( "ppsh_zm" );
		include_weapon( "ppsh_upgraded_zm", false );
		include_weapon( "psg1_zm" );
		include_weapon( "psg1_upgraded_zm", false );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "combat_sickle_knife_zm", false );
	}
	else if(GetDvar("mapname") == "zombie_temple")
	{
		include_weapon( "sticky_grenade_zm", false );

		include_weapon( "ak47_zm" );
		include_weapon( "ak47_upgraded_zm", false );
		include_weapon( "stoner63_zm" );
		include_weapon( "stoner63_upgraded_zm", false );
		include_weapon( "ppsh_zm" );
		include_weapon( "ppsh_upgraded_zm", false );
		include_weapon( "psg1_zm" );
		include_weapon( "psg1_upgraded_zm", false );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "combat_bowie_knife_zm", false );
	}
	else if(GetDvar("mapname") == "zombie_moon")
	{
		include_weapon( "ak47_zm" );
		include_weapon( "ak47_upgraded_zm", false );
		include_weapon( "stoner63_zm" );
		include_weapon( "stoner63_upgraded_zm", false );
		include_weapon( "ppsh_zm" );
		include_weapon( "ppsh_upgraded_zm", false );
		include_weapon( "psg1_zm" );
		include_weapon( "psg1_upgraded_zm", false );

		include_weapon( "combat_knife_zm", false );
		include_weapon( "combat_bowie_knife_zm", false );
	}
}

set_fov()
{
	self endon("disconnect");

	while(1)
	{
		if(GetDvarInt("cg_thirdPerson") == 1)
		{
			wait .05;
			continue;
		}

		if((IsDefined(self.is_ziplining) && self.is_ziplining))
		{
			wait .05;
			continue;
		}

		fov = GetDvarFloat("cg_fov_settings");
		if(fov == GetDvarFloat("cg_fov"))
		{
			wait .05;
			continue;
		}

		SetClientDvar("cg_fov", fov);

		wait .05;
	}
}

fog_setting()
{
	self endon("disconnect");

	while(1)
	{
		if(GetDvarInt("r_fog_settings") == GetDvarInt("r_fog"))
		{
			wait .05;
			continue;
		}

		fog = GetDvarInt("r_fog_settings");
		SetClientDvar("r_fog", fog);

		wait .05;
	}
}

grenade_hud(clientnum)
{
	self endon("disconnect");

	lethal_nades = [];
	tactical_nades = [];

	for(i = 0; i < level._included_weapons.size; i++)
	{
		weapon = level._included_weapons[i];
		nade_type = get_grenade_type(weapon);

		if(IsDefined(nade_type))
		{
			icon = get_grenade_icon(weapon, nade_type);

			if(nade_type == "lethal")
			{
				size = lethal_nades.size;
				lethal_nades[size] = [];
				lethal_nades[size]["weapon"] = weapon;
				lethal_nades[size]["icon"] = icon;
			}
			else if(nade_type == "tactical")
			{
				size = tactical_nades.size;
				tactical_nades[size] = [];
				tactical_nades[size]["weapon"] = weapon;
				tactical_nades[size]["icon"] = icon;
			}
		}
	}

	while(1)
	{
		if(GetDvarInt("disable_grenade_amount_update") == 1)
		{
			wait .05;
			continue;
		}

		lethal_nade = undefined;
		tactical_nade = undefined;
		lethal_nade_amt = 0;
		tactical_nade_amt = 0;

		for(i = 0; i < lethal_nades.size; i++)
		{
			weapon = lethal_nades[i]["weapon"];
			count = GetWeaponAmmoClip(clientnum, weapon);

			if(count > 0)
			{
				lethal_nade = i;
				lethal_nade_amt = count;
				break;
			}
		}

		for(i = 0; i < tactical_nades.size; i++)
		{
			weapon = tactical_nades[i]["weapon"];
			count = GetWeaponAmmoClip(clientnum, weapon);

			if(count > 0)
			{
				tactical_nade = i;
				tactical_nade_amt = count;
				break;
			}
		}

		if(IsDefined(lethal_nade))
		{
			SetClientDvar("lethal_grenade_icon", lethal_nades[lethal_nade]["icon"]);
			SetClientDvar("lethal_grenade_amount", lethal_nade_amt);
		}
		else
		{
			SetClientDvar("lethal_grenade_amount", 0);
		}

		if(IsDefined(tactical_nade))
		{
			SetClientDvar("tactical_grenade_icon", tactical_nades[tactical_nade]["icon"]);
			SetClientDvar("tactical_grenade_amount", tactical_nade_amt);
		}
		else
		{
			SetClientDvar("tactical_grenade_amount", 0);
		}

		wait .05;
	}
}

get_grenade_type(weapon)
{
	if(!isdefined(weapon) || weapon == "" || weapon == "none")
		return undefined;

	switch(weapon)
	{
		case "frag_grenade_zm":
		case "sticky_grenade_zm":
		case "stielhandgranate":
			return "lethal";

		case "zombie_cymbal_monkey":
		case "zombie_black_hole_bomb":
		case "zombie_nesting_dolls":
		case "zombie_quantum_bomb":
		case "molotov_zm":
			return "tactical";

		default:
			return undefined;
	}
}

get_grenade_icon(weapon, nade_type)
{
	icon = "hud_grenadeicon";
	if(nade_type == "tactical")
	{
		icon = "hud_cymbal_monkey";
	}

	if(nade_type == "lethal")
	{
		if(weapon == "frag_grenade_zm")
		{
			icon = "hud_grenadeicon";
		}
		else if(weapon == "sticky_grenade_zm")
		{
			icon = "hud_icon_sticky_grenade";
		}
		else if(weapon == "stielhandgranate")
		{
			icon = "hud_icon_stielhandgranate";
		}
	}
	else if(nade_type == "tactical")
	{
		if(weapon == "zombie_cymbal_monkey")
		{
			icon = "hud_cymbal_monkey";
		}
		else if(weapon == "zombie_black_hole_bomb")
		{
			icon = "hud_blackhole";
		}
		else if(weapon == "zombie_nesting_dolls")
		{
			icon = "hud_nestingbomb";
		}
		else if(weapon == "zombie_quantum_bomb")
		{
			icon = "hud_icon_quantum_bomb";
		}
		else if(weapon == "molotov_zm")
		{
			icon = "hud_icon_molotov";
		}
	}

	return icon;
}

hud_message_handler(clientnum, state)
{
	// MUST MATCH MENU FILE DEFINES
	menu_name = "";
	item_name = "";
	fade_type = "";
	fade_time = 0;

	if(state == "hud_zone_name_in")
	{
		menu_name = "zone_name";
		item_name = "zone_name_text";
		fade_type = "fadein";
		fade_time = 250;
	}
	else if(state == "hud_zone_name_out")
	{
		menu_name = "zone_name";
		item_name = "zone_name_text";
		fade_type = "fadeout";
		fade_time = 250;
	}
	else if(state == "hud_round_time_in")
	{
		menu_name = "timer";
		item_name = "round_timer";
		fade_type = "fadein";
		fade_time = 1000;
	}
	else if(state == "hud_round_time_out")
	{
		menu_name = "timer";
		item_name = "round_timer";
		fade_type = "fadeout";
		fade_time = 1000;
	}
	else if(state == "hud_round_total_time_in")
	{
		menu_name = "timer";
		item_name = "round_total_timer";
		fade_type = "fadein";
		fade_time = 1000;
	}
	else if(state == "hud_round_total_time_out")
	{
		menu_name = "timer";
		item_name = "round_total_timer";
		fade_type = "fadeout";
		fade_time = 1000;
	}
	else if(state == "hud_sidequest_time_in")
	{
		menu_name = "timer";
		item_name = "sidequest_timer";
		fade_type = "fadein";
		fade_time = 1000;
	}
	else if(state == "hud_sidequest_time_out")
	{
		menu_name = "timer";
		item_name = "sidequest_timer";
		fade_type = "fadeout";
		fade_time = 1000;
	}
	else if(state == "hud_mule_wep_in")
	{
		menu_name = "mule_wep_indicator";
		item_name = "mule_wep_indicator_image";
		fade_type = "fadein";
		fade_time = 250;
	}
	else if(state == "hud_mule_wep_out")
	{
		menu_name = "mule_wep_indicator";
		item_name = "mule_wep_indicator_image";
		fade_type = "fadeout";
		fade_time = 250;
	}

	AnimateUI(clientnum, menu_name, item_name, fade_type, fade_time);
}

// Infinate client systems
register_client_system(name, func)
{
	if(!isdefined(level.client_systems))
		level.client_systems = [];
	if(isdefined(func))
		level.client_systems[name] = func;
}

client_systems_message_handler(clientnum, state, oldState)
{
	tokens = StrTok(state, ":");

	name = tokens[0];
	message = tokens[1];

	if(isdefined(level.client_systems) && isdefined(level.client_systems[name]))
		level thread [[level.client_systems[name]]](clientnum, message);
}
