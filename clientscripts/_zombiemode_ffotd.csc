#include clientscripts\_utility;


main_start()
{
	players = GetLocalPlayers();
	for(i = 0; i < players.size; i++)
	{
		players[i] thread set_fov();
		players[i] thread remove_pause_screen_darkness();
		players[i] thread fog_setting();
	}

	// registerSystem("hud", ::hud);
	registerSystem("wardog_client_systems", ::_wardog_client_systems_message_handler);
	register_client_system("hud_anim_handler", ::hud_message_handler);
}


main_end()
{
	clientscripts\_zombiemode_perks::init();
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
		if(GetDvarInt("cg_fov_settings") == GetDvarInt("cg_fov"))
		{
			wait .05;
			continue;
		}
		if((IsDefined(self.is_ziplining) && self.is_ziplining))
		{
			wait .05;
			continue;
		}
		fov = GetDvarInt("cg_fov_settings");
		SetClientDvar("cg_fov", fov);
		wait .05;
	}
}

remove_pause_screen_darkness()
{
	self endon("disconnect");

	while(1)
	{
		if(GetDvarInt("cl_paused") == 1)
		{
			SetClientDvar("cg_drawpaused", 0);

			while(GetDvarInt("cl_paused") == 1)
				wait .05;

			SetClientDvar("cg_drawpaused", 1); //have to set it back because it makes certain hud elements not work...
		}

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

hud_message_handler(clientnum, state)
{
	MENU_NAME = "weaponinfo_zombie"; // MUST MATCH MENU FILE DEFINES

	if(state == "hud_zone_name_in")
	{
		ITEM_NAME = "hud_zone_name";
		FADE_IN_TIME = 250; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 0; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadein", FADE_IN_TIME);
	}
	else if(state == "hud_zone_name_out")
	{
		ITEM_NAME = "hud_zone_name";
		FADE_IN_TIME = 250; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 0; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadeout", FADE_OUT_TIME);
	}
	else if(state == "hud_round_time_in")
	{
		ITEM_NAME = "hud_round_time";
		FADE_IN_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadein", FADE_IN_TIME);
	}
	else if(state == "hud_round_time_out")
	{
		ITEM_NAME = "hud_round_time";
		FADE_IN_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadeout", FADE_OUT_TIME);
	}
	else if(state == "hud_round_total_time_in")
	{
		ITEM_NAME = "hud_round_total_time";
		FADE_IN_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadein", FADE_IN_TIME);
	}
	else if(state == "hud_round_total_time_out")
	{
		ITEM_NAME = "hud_round_total_time";
		FADE_IN_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadeout", FADE_OUT_TIME);
	}
	else if(state == "hud_sidequest_time_in")
	{
		ITEM_NAME = "hud_sidequest_time";
		FADE_IN_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadein", FADE_IN_TIME);
	}
	else if(state == "hud_sidequest_time_out")
	{
		ITEM_NAME = "hud_sidequest_time";
		FADE_IN_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		FADE_OUT_TIME = 1000; // MUST MATCH MENU FILE DEFINES
		AnimateUI(clientnum, MENU_NAME, ITEM_NAME, "fadeout", FADE_OUT_TIME);
	}
}

// Infinate client systems
register_client_system(name, func)
{
	if(!isdefined(level._wardog_client_systems))
		level._wardog_client_systems = [];
	if(isdefined(func))
		level._wardog_client_systems[name] = func;
}

_wardog_client_systems_message_handler(clientnum, state, oldState)
{
	tokens = StrTok(state, ":");

	name = tokens[0];
	message = tokens[1];

	if(isdefined(level._wardog_client_systems) && isdefined(level._wardog_client_systems[name]))
		level thread [[level._wardog_client_systems[name]]](clientnum, message);
}
