#include clientscripts\_utility;

init()
{
	clientscripts\_zombiemode_ffotd::register_client_system("zombiemode_perks", ::perks_message_handler);

	// Delete old perk bump triggers
	bump_trigs = GetEntArray(0, "audio_bump_trigger", "targetname");

	start_count = bump_trigs.size;
	removed = 0;

	for(i = 0; i < bump_trigs.size; i++)
	{
		is_perk = false;

		if(isdefined(bump_trigs[i].script_sound))
		{
			if(bump_trigs[i].script_sound == "perks_rattle" || bump_trigs[i].script_sound == "fly_bump_bottle")
				is_perk = true;
		}

		if(isdefined(bump_trigs[i].script_string))
		{
			switch(bump_trigs[i].script_string)
			{
				case "tap_additionalprimaryweapon":
				case "speedcola_perk":
				case "revive_perk":
				case "marathon_perk":
				case "jugg_perk":
				case "divetonuke_perk":
				case "tap_perk":
				case "tap_deadshot":
					is_perk = true;
					break;
				default:
					break;
			}
		}

		if(is_perk)
		{
			bump_trigs[i] Delete();
			removed++;
		}
	}
	spawn_new_bump_triggers();
}

perks_message_handler(clientnum, message)
{
	// delete bump = perk|delete_bump
	// spawn bump - perk|spawn_bump|origin
	tokens = StrTok(message, "|");

	perk = tokens[0];
	script_string = perk_to_script_string(perk);

	if(tokens[1] == "delete_bump")
	{
		bump_trigs = GetEntArray(0, "audio_bump_trigger", "targetname");

		for(i = 0; i < bump_trigs.size; i++)
		{
			if(!isdefined(bump_trigs[i].script_string))
				continue;
			if(bump_trigs[i].script_string != script_string)
				continue;

			bump_trigs[i] Delete();
		}
	}
	else if(tokens[1] == "spawn_bump")
	{
		origin = string_to_vector(tokens[2], ",");
		trigger = spawn_audio_bump_trigger(perk, origin);
	}
}

string_to_vector(str_vec, splitter)
{
	if(!isdefined(splitter))
		splitter = ",";

	tokens = StrTok(str_vec, splitter);

	x = string_to_float(tokens[0]);
	y = string_to_float(tokens[1]);
	z = string_to_float(tokens[2]);

	return(x, y, z);
}

string_to_float( string )
{
	floatParts = strTok( string, "." );
	if ( floatParts.size == 1 )
		return int(floatParts[0]);

	whole = int(floatParts[0]);
	// Convert the decimal part into a floating point value
	decimal = 0;
	for ( i=floatParts[1].size-1; i>=0; i-- )
	{
		decimal = decimal/10 + int(floatParts[1][i])/10;
	}

	if ( whole >= 0 )
		return (whole + decimal);
	else
		return (whole - decimal);
}

// this also spawns triggers on maps that dont have perk bump triggers
spawn_new_bump_triggers()
{
	perks = [];

	mapname = ToLower(GetDvar("mapname"));

	// level.script does not exist in csc
	switch(mapname)
	{
		case "zombie_theater":
			perks["specialty_armorvest"] = (-328, -491, 47);
			perks["specialty_fastreload"] = (1268, 147, 25);
			perks["specialty_rof"] = (-1728, -379, 34);
			perks["specialty_quickrevive"] = (523, -1260, 112);
			// perks["specialty_additionalprimaryweapon"] = (1172.4, -359.7, 320);
			break;
		case "zombie_pentagon":
			perks["specialty_armorvest"] = (-1568, 1844, -470);
			perks["specialty_fastreload"] = (-1148, 1933, 59);
			perks["specialty_rof"] = (-1488, 1976, -270);
			perks["specialty_quickrevive"] = (-1058, 2970, 49);
			// perks["specialty_additionalprimaryweapon"] = (-1081.4, 1496.9, -512);
			break;
		case "zombie_cosmodrome":
			perks["specialty_armorvest"] = (-63, 791, -262);
			perks["specialty_fastreload"] = (885, 1233, 393);
			perks["specialty_rof"] = (1129.3, 743.9, -321.9);
			perks["specialty_quickrevive"] = (-184, 825, -453);
			perks["specialty_longersprint"] = (618, -121, -118);
			perks["specialty_flakjacket"] = (-2314, 2368, -42);
			// perks["specialty_additionalprimaryweapon"] = (420.8, 1359.1, 55);
			break;
		case "zombie_coast":
			perks["specialty_armorvest"] = (1524, -2652, 116);
			perks["specialty_fastreload"] = (1263, 1570, 38);
			perks["specialty_rof"] = (-2538, -1444, 403);
			perks["specialty_quickrevive"] = (-1060, 544, 39);
			perks["specialty_longersprint"] = (303, 3550, 62);
			perks["specialty_flakjacket"] = (-345, 874, 417);
			perks["specialty_deadshot"] = (12, 1061, 898);
			// perks["specialty_additionalprimaryweapon"] = (2424.4, -2884.3, 314);
			break;
		case "zombie_temple":
			perks["specialty_quickrevive"] = (-8, -938, 46);
			// These are spawned later on after randomization has finished
			// perks["specialty_armorvest"] = (1384, -1147, -111); // MPL
			// perks["specialty_fastreload"] = (-1285, -933, 35); // Mud
			// perks["specialty_flakjacket"] = (175, -1583, -363); // Semtex
			// perks["specialty_deadshot"] = (429, -845, -362); // M16
			// perks["specialty_longersprint"] = (-332, -1043, -320); // Stakeout
			// perks["specialty_rof"] = (-535, 47, -390); // Power
			// perks["specialty_additionalprimaryweapon"] = (1494.0, -1561.4, -363); // Waterslide End
			// perks["specialty_additionalprimaryweapon"] = (-1352.9, -1437.2, -485); // Waterfall
			break;
		case "zombie_moon":
			// These are spawned later on after randomization has finished
			// perks["specialty_armorvest"] = (14282, -15032, -578);
			// perks["specialty_fastreload"] = (14277, -15036, -577);
			perks["specialty_quickrevive"] = (18, -150, 29);
			perks["specialty_rof"] = (1597, 3812, -291);
			perks["specialty_longersprint"] = (676, 2232, -326);
			perks["specialty_flakjacket"] = (-262, 8346, 30);
			perks["specialty_deadshot"] = (2138, 6041, 49);
			// perks["specialty_additionalprimaryweapon"] = (1480.8, 3450, -65);
			break;
		case "zombie_cod5_prototype":
			perks["specialty_additionalprimaryweapon"] = (-160, -528, 1);
			break;
		case "zombie_cod5_asylum":
			perks["specialty_armorvest"] = (1326, -415, 106);
			perks["specialty_fastreload"] = (-572, 706, 267);
			perks["specialty_rof"] = (437, -584, 261);
			perks["specialty_quickrevive"] = (1144, 403, 97);
			perks["specialty_additionalprimaryweapon"] = (-91, 540, 64);
			break;
		case "zombie_cod5_sumpf":
			// These are spawned later on after randomization has finished
			// perks["specialty_quickrevive"] = (11680, 3604, -606); // Doctors Quaters
			// perks["specialty_armorvest"] = (8520, 3196, -606); // Fishing Hut
			// perks["specialty_rof"] = (7844, -1193, -606); // Comm Room
			// perks["specialty_fastreload"] = (12376, -1199, -606); // Storage
			// perks["specialty_additionalprimaryweapon"] = (9565, 327, -529);
			break;
		case "zombie_cod5_factory":
			perks["specialty_armorvest"] = (673, -1421, 180);
			perks["specialty_fastreload"] = (-364, -794, 111);
			perks["specialty_rof"] = (-365, -1076, 230);
			perks["specialty_quickrevive"] = (-485, -2067, 182);
			// perks["specialty_additionalprimaryweapon"] = (-1089, -1366, 67);
			break;

		default:
			if(isdefined(level._zombiemode_perks_bump_trigs_locations))
				perks = [[level._zombiemode_perks_bump_trigs_locations]](perks);
			break;
	}

	if(isdefined(perks))
	{
		keys = GetArrayKeys(perks);

		for(i = 0; i < keys.size; i++)
		{
			perk = keys[i];
			origin = perks[perk];

			//check if mule kick is enabled
			//this won't work because we need to check the host value of the dvar "mule_kick_enabled" for each player, moved to gsc
			/*if(perk == "specialty_additionalprimaryweapon")
			{
				if(mapname == "zombie_cod5_prototype")
				{
					continue;
				}
				else if(mapname != "zombie_moon" && !GetDvarInt("mule_kick_enabled"))
				{
					continue;
				}
			}*/

			assert(isdefined(origin));

			trigger = spawn_audio_bump_trigger(perk, origin);
		}
	}
}

spawn_audio_bump_trigger(perk, origin)
{
	trigger = Spawn(0, origin, "trigger_radius", 0, 80, 80);
	trigger.radius = 80; // must match the Spawn() arg
	trigger.height = 80; // must match the Spawn() arg
	// trigger = SpawnStruct(); // TODO: Spawn a actual trigger
	trigger.targetname = "audio_bump_trigger";
	trigger.script_sound = "fly_bump_bottle";
	trigger.script_string = perk_to_script_string(perk);

	trigger thread audio_bump_trigger_think();

	return trigger;
}

audio_bump_trigger_think()
{
	self endon("death");
	self endon("entity_shutdown");

	touching = [];

	for(;;)
	{
		realwait(.1);

		players = GetLocalPlayers();

		for(i = 0; i < players.size; i++)
		{
			player = players[i];

			if(!isdefined(touching[i]))
				touching[i] = false;

			if(IsDefined(self.radius) && Distance(self.origin, player.origin) < self.radius)
			{
				if(!touching[i])
				{
					touching[i] = true;
					volume = clientscripts\_audio::get_vol_from_speed(player);
					self PlaySound(i, self.script_sound, self.origin, volume);
				}
			}
			else
			{
				if(touching[i])
					touching[i] = false;
			}
		}
	}
}

perk_to_script_string(perk)
{
	switch(perk)
	{
		case "specialty_armorvest": return "jugg_perk";
		case "specialty_rof": return "tap_perk";
		case "specialty_fastreload": return "speedcola_perk";
		case "specialty_quickrevive": return "revive_perk";
		case "specialty_flakjacket": return "divetonuke_perk";
		case "specialty_longersprint": return "marathon_perk";
		case "specialty_deadshot": return "tap_deadshot";
		case "specialty_additionalprimaryweapon": return "tap_additionalprimaryweapon";

		default:
			if(isdefined(level._zombiemode_perks_set_bump_kvps))
				return [[level._zombiemode_perks_set_bump_kvps]](perk);
			else
				return "speedcola_perk";
	}
}
