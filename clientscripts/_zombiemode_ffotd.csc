#include clientscripts\_utility;


main_start()
{
	players = GetLocalPlayers();
	for(i = 0; i < players.size; i++)
	{
		players[i] thread set_fov();
		players[i] thread remove_pause_screen_darkness();
	}

	registerSystem("hud", ::hud);
}


main_end()
{
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
		if(GetDvarInt("cg_fov_real") == GetDvarInt("cg_fov"))
		{
			wait .05;
			continue;
		}
		if((IsDefined(self.is_ziplining) && self.is_ziplining))
		{
			wait .05;
			continue;
		}
		fov = GetDvarInt("cg_fov_real");
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

			SetClientDvar("cg_drawpaused", 1); //have to set it back because it makes hintstrings not work...
		}

		wait .05;
	}
}

real_wait_time(time_ms)
{
	start_time = GetRealTime();

	while(GetRealTime() - start_time <= time_ms)
	{
		realwait(.1);
	}
}

hud(clientnum, state, oldState)
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