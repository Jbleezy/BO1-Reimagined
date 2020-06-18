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

spawn_audio_bump_trigger(perk, origin)
{
	radius = 72;
	height = 80;

	trigger = Spawn(0, origin, "trigger_radius", 0, radius, height);
	trigger.radius = radius; // must match the Spawn() arg
	trigger.height = height; // must match the Spawn() arg
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
		case "specialty_endurance": return "marathon_perk";
		case "specialty_deadshot": return "tap_deadshot";
		case "specialty_additionalprimaryweapon": return "tap_additionalprimaryweapon";

		default:
			if(isdefined(level._zombiemode_perks_set_bump_kvps))
				return [[level._zombiemode_perks_set_bump_kvps]](perk);
			else
				return "speedcola_perk";
	}
}
