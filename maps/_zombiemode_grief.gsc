#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_music;

init()
{
	grief_precache();

	if(level.gamemode == "survival")
	{
		return;
	}

	level thread include_grief_powerups();

	level thread post_all_players_connected();

	level thread turn_power_on();

	level thread open_doors();

	level thread disable_special_rounds();

	if(level.gamemode == "snr" || level.gamemode == "race" || level.gamemode == "gg")
	{
		if(level.gamemode == "snr")
		{
			level.snr_round_number = 1;
			level thread increase_zombie_health();
			level thread display_round_number();
			level thread increase_zombie_move_speed();
		}
		else if(level.gamemode == "race")
		{
			level thread race_win_watcher();
			level thread increase_round_number_over_time();
		}
		else if(level.gamemode == "gg")
		{
			level thread unlimited_ammo();
			level thread increase_zombie_health();
			level thread increase_zombie_move_speed();
			level thread setup_gungame_weapons();
		}

		level thread increase_zombie_spawn_rate();
		level thread unlimited_powerups();
		level thread unlimited_barrier_points();
		level thread unlimited_zombies();
	}

	if(level.gamemode != "grief")
	{
		if(level.vsteams == "ffa")
		{
			level thread setup_grief_top_playernames();
		}
		else
		{
			level thread setup_grief_top_logos();
		}
	}

	//level thread intro_vox();
}

grief_precache()
{
	PrecacheString( &"REIMAGINED_YOU_WIN" );
	PrecacheString( &"REIMAGINED_YOU_LOSE" );

	PrecacheString( &"REIMAGINED_ANOTHER_CHANCE" );
	PrecacheString( &"REIMAGINED_ENEMY_DOWN" );
	PrecacheString( &"REIMAGINED_ALL_ENEMIES_DOWN" );
	PrecacheString( &"REIMAGINED_SURVIVE_TO_WIN" );

	PrecacheString( &"REIMAGINED_CDC_WON" );
	PrecacheString( &"REIMAGINED_CIA_WON" );
	PrecacheString( &"REIMAGINED_FINAL_ROUND" );

	level._effect["equipment_damage"] = LoadFX( "env/electrical/fx_elec_sparking_oneshot" );
	level._effect["grief_shock"] = LoadFX("maps/zombie/grief/fx_grief_shock");
	level._effect["meat_stink"] = Loadfx( "weapon/meat/fx_meat_stink" );
	level._effect["meat_impact"] = Loadfx( "weapon/meat/fx_meat_impact" );

	PrecacheShader("waypoint_cia");
	PrecacheShader("waypoint_cdc");

	PrecacheModel("bo2_c_zom_hazmat_viewhands");
	PrecacheModel("bo2_c_zom_player_cdc_fb");
	PrecacheModel("bo2_c_zom_suit_viewhands");
	PrecacheModel("bo2_c_zom_player_cia_fb");
}

include_grief_powerups()
{
	include_powerup("bonus_points_team");
	include_powerup("meat");

	vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	if(level.gamemode == "gg")
	{
		include_powerup("random_weapon");

		if(vending_weapon_upgrade_trigger.size >= 1)
		{
			include_powerup("upgrade_weapon");
		}
	}

	PrecacheItem("meat_zm");

	wait_network_frame();
	level.zombie_powerup_array = [];
	level.zombie_powerup_array = array("full_ammo", "insta_kill", "double_points", "nuke", "bonus_points_team", "meat");

	if(!IsSubStr(level.script, "zombie_cod5_") && level.gamemode != "gg")
	{
		level.zombie_powerup_array = add_to_array(level.zombie_powerup_array, "fire_sale");
	}

	if(level.gamemode == "gg" && vending_weapon_upgrade_trigger.size >= 1)
	{
		level.zombie_powerup_array = add_to_array(level.zombie_powerup_array, "upgrade_weapon");
	}

	maps\_zombiemode_powerups::randomize_powerups();
}

post_all_players_connected()
{
	flag_wait("all_players_connected");

	setup_grief_teams();

	setup_grief_logo();

	level thread meat_stink_think();

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] setup_grief_msg();

		players[i].slowdown_wait = false;
		players[i].vs_attackers = [];
		players[i] thread grief_damage();
		players[i] thread grief_downed_points();
		players[i] thread grief_bleedout_points();
	}
}

intro_vox()
{
	flag_wait( "begin_spawning" );

	wait 3;

	sound = "vs_intro_short";
	/*if(level.vsteams == "ffa")
	{
		sound = "vs_intro_short_ffa";
	}*/

	players = GetPlayers();
	for( i = 0; i < players.size; i++ )
	{
		players[i] playlocalsound( sound );
	}
}

instant_bleedout()
{
	self.bleedout_time = 0;
}

is_team_valid()
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(players[i].vsteam == self.vsteam && is_player_valid(players[i]))
		{
			return true;
		}
	}
	return false;
}

setup_grief_teams()
{
	team_array = array("cdc", "cia");
	team_array = array_randomize(team_array);
	players = get_players();
	team_size = [];
	team_size["cdc"] = 0;
	team_size["cia"] = 0;
	max_team_size = int((players.size + 1) / 2);
	for(i=0;i<players.size;i++)
	{
		if(level.vsteams == "random")
		{
			players[i].vsteam = random(team_array);

			if(team_size[players[i].vsteam] >= max_team_size)
			{
				team = array_remove(team_array, players[i].vsteam);
				players[i].vsteam = random(team);
			}

			team_size[players[i].vsteam]++;
		}
		else if(level.vsteams == "custom")
		{
			ent_num = players[i] GetEntityNumber();

			if(ent_num == 0)
			{
				players[i].vsteam = GetDvar("player1_team");
			}
			else if(ent_num == 1)
			{
				players[i].vsteam = GetDvar("player2_team");
			}
			else if(ent_num == 2)
			{
				players[i].vsteam = GetDvar("player3_team");
			}
			else if(ent_num == 3)
			{
				players[i].vsteam = GetDvar("player4_team");
			}
			else
			{
				players[i].vsteam = random(team_array);
			}
		}
		else if(level.vsteams == "ffa")
		{
			if(!IsDefined(level.vsteam))
			{
				level.vsteam = random(team_array);
			}
			players[i].vsteam = "ffa" + (i + 1);
		}
	}
}

setup_grief_logo()
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(IsDefined(level.vsteam))
		{
			players[i] SetClientDvar("vs_logo", level.vsteam + "_logo");
		}
		else
		{
			players[i] SetClientDvar("vs_logo", players[i].vsteam + "_logo");
		}
		players[i] SetClientDvar("vs_logo_on", 1);
	}
}

disable_special_rounds()
{
	if(level.script == "zombie_cod5_sumpf" || level.script == "zombie_cod5_factory" || level.script == "zombie_theater")
	{
		level thread disable_dog_rounds();
	}
	else if(level.script == "zombie_pentagon")
	{
		level thread disable_thief_rounds();
	}
	else if(level.script == "zombie_cosmodrome")
	{
		level thread disable_monkey_rounds();
	}
}

disable_dog_rounds()
{
	flag_wait( "all_players_connected" );
	level.next_dog_round = 0;
}

disable_thief_rounds()
{
	flag_wait( "power_on" );
	wait_network_frame();
	level.prev_thief_round = 0;
	level.next_thief_round = 999;
}

disable_monkey_rounds()
{
	flag_wait( "perk_bought" );
	wait_network_frame();
	level.next_monkey_round = 0;
}

disable_character_dialog()
{
	while(1)
	{
		level.player_is_speaking = 1;
		level.cosmann_is_speaking = 1;
		wait .1;
	}
}

store_player_weapons()
{
	self.weaponInventory = self GetWeaponsList();

	self.lastActiveStoredWeap = self GetCurrentWeapon();

	// don't store the weapon attachment name as the last active weapon because it can't be switched to
	if(WeaponInventoryType(self.lastActiveStoredWeap) == "altmode")
	{
		self.lastActiveStoredWeap = WeaponAltWeaponName(self.lastActiveStoredWeap);
	}

	self.weaponEquipment["melee"] = self get_player_melee_weapon();
	self.weaponEquipment["lethal"] = self get_player_lethal_grenade();
	self.weaponEquipment["tactical"] = self get_player_tactical_grenade();
	self.weaponEquipment["mine"] = self get_player_placeable_mine();
	
	for( i = 0; i < self.weaponInventory.size; i++ )
	{
		weapon = self.weaponInventory[i];
		
		switch( weapon )
		{	
		case "syrette_sp": 
		case "zombie_perk_bottle_doubletap": 
		case "zombie_perk_bottle_revive":
		case "zombie_perk_bottle_jugg":
		case "zombie_perk_bottle_sleight":
		case "zombie_perk_bottle_marathon":
		case "zombie_perk_bottle_nuke":
		case "zombie_perk_bottle_deadshot":
		case "zombie_perk_bottle_additionalprimaryweapon":
		case "zombie_knuckle_crack":
		case "zombie_bowie_flourish":
		case "zombie_sickle_flourish":
		case "meat_zm":
			self TakeWeapon( weapon );
			self.lastActiveStoredWeap = "none";
			continue;
		}

		self.weaponAmmo[weapon]["clip"] = self GetWeaponAmmoClip( weapon );
		self.weaponAmmo[weapon]["stock"] = self GetWeaponAmmoStock( weapon );

		dual_wield_name = WeaponDualWieldWeaponName( weapon );
		if ( dual_wield_name != "none" )
		{
			self.weaponAmmo[dual_wield_name]["clip"] = self GetWeaponAmmoClip( dual_wield_name );
		}
	}
}

giveback_player_weapons()
{
	for( i = 0; i < self.weaponInventory.size; i++ )
	{
		weapon = self.weaponInventory[i];

		switch( weapon )
		{
		case "syrette_sp": 
		case "zombie_perk_bottle_doubletap": 
		case "zombie_perk_bottle_revive":
		case "zombie_perk_bottle_jugg":
		case "zombie_perk_bottle_sleight":
		case "zombie_perk_bottle_marathon":
		case "zombie_perk_bottle_nuke":
		case "zombie_perk_bottle_deadshot":
		case "zombie_perk_bottle_additionalprimaryweapon":
		case "zombie_knuckle_crack":
		case "zombie_bowie_flourish":
		case "zombie_sickle_flourish":
		case "meat_zm":
			continue;
		}

		if(IsDefined(self.weapon_taken_by_losing_additionalprimaryweapon) && IsDefined(self.weapon_taken_by_losing_additionalprimaryweapon[0]) && weapon == self.weapon_taken_by_losing_additionalprimaryweapon[0])
		{
			if(self.weapon_taken_by_losing_additionalprimaryweapon[0] == self.lastActiveStoredWeap)
			{
				self.lastActiveStoredWeap = "none";
			}
			self.weapon_taken_by_losing_additionalprimaryweapon = undefined;
			continue;
		}

		if ( !maps\_zombiemode_weapons::is_weapon_upgraded( weapon ) )
		{
			self GiveWeapon( weapon );
		}
		else
		{
			index = maps\_zombiemode_weapons::get_upgraded_weapon_model_index(weapon);

			self GiveWeapon( weapon, index, self maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( weapon ) );
		}
		self SetWeaponAmmoClip( weapon, self.weaponAmmo[weapon]["clip"] );

		if ( WeaponType( weapon ) != "grenade" )
		{
			self SetWeaponAmmoStock( weapon, self.weaponAmmo[weapon]["stock"] );

			dual_wield_name = WeaponDualWieldWeaponName( weapon );
			if ( dual_wield_name != "none" && IsDefined(self.weaponAmmo[dual_wield_name]["clip"]) )
			{
				self SetWeaponAmmoClip( dual_wield_name, self.weaponAmmo[dual_wield_name]["clip"] );
			}
		}
	}

	if(IsDefined(self.weaponEquipment["melee"]))
	{
		self set_player_melee_weapon(self.weaponEquipment["melee"]);
		self maps\_zombiemode::set_melee_actionslot();
	}
	
	if(IsDefined(self.weaponEquipment["lethal"]))
	{
		self set_player_lethal_grenade(self.weaponEquipment["lethal"]);
	}

	if(IsDefined(self.weaponEquipment["tactical"]))
	{
		self set_player_tactical_grenade(self.weaponEquipment["tactical"]);
	}

	if(IsDefined(self.weaponEquipment["mine"]))
	{
		self set_player_placeable_mine(self.weaponEquipment["mine"]);
		self SetActionSlot(4, "weapon", self.weaponEquipment["mine"]);
		self SetWeaponAmmoClip(self.weaponEquipment["mine"], 2);
	}

	if( self.lastActiveStoredWeap != "none" && !is_placeable_mine(self.lastActiveStoredWeap) && !is_melee_weapon(self.lastActiveStoredWeap) )
	{
		self SwitchToWeapon( self.lastActiveStoredWeap );
	}
	else
	{
		primaryWeapons = self GetWeaponsListPrimaries();
		if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
		else
		{
			self SwitchToWeapon("combat_" + self get_player_melee_weapon());
		}
	}
}

grief_damage()
{
	while(1)
	{
		self waittill( "grief_damage", weapon, mod, attacker, force_slowdown, vec );

		if(!is_player_valid(self))
		{
			continue;
		}

		if(attacker.vsteam == self.vsteam)
		{
			continue;
		}

		// special check for betties when player is prone
		if(weapon == "mine_bouncing_betty" && mod == "MOD_GRENADE_SPLASH" && self GetStance() == "prone" && self IsOnGround())
		{
			continue;
		}

		if(!IsDefined(force_slowdown))
		{
			force_slowdown = false;
		}

		tgun_hit = (weapon == "thundergun_zm" || weapon == "thundergun_upgraded_zm") && IsDefined(vec);
		if(mod == "MOD_MELEE" || IsSubStr(weapon, "knife_ballistic_") || tgun_hit)
		{
			force_slowdown = true;
			self thread push(weapon, mod, attacker, vec);
		}

		self thread slowdown(weapon, mod, attacker, force_slowdown);
	}
}

slowdown(weapon, mod, attacker, force_slowdown)
{
	//player is already slowed down, don't slow them down again
	if(is_true(self.slowdown_wait) && !force_slowdown)
	{
		return;
	}

	self notify("grief_slowdown");
	self endon("grief_slowdown");

	self.slowdown_wait = true;

	attacker grief_damage_points(self);
	attacker thread grief_downed_points_add_player(self);

	PlayFXOnTag( level._effect["grief_shock"], self, "J_SpineUpper" );

	amount = .3;
	if(maps\_zombiemode_weapons::is_weapon_upgraded(weapon))
	{
		amount = .2;
	}

	self AllowSprint(false);
	self SetMoveSpeedScale( self.move_speed * amount );
	self thread slowdown_blur();

	wait .75;

	if(!self is_drinking() || is_true(self.has_meat)) // holding meat counts as drinking
	{
		self AllowSprint(true);
	}
	self SetMoveSpeedScale( self.move_speed );

	self.slowdown_wait = false;
}

slowdown_blur()
{
	self endon("grief_slowdown");

	self SetBlur( 1, .1 );

	wait .1;

	self SetBlur( 0, .65 );
}

push(weapon, mod, attacker, vec) //prone, bowie/ballistic crouch, bowie/ballistic, crouch, regular
{
	if(!IsDefined(vec))
	{
		amount = 300;
		vec = vector_scale(VectorNormalize(self.origin - attacker.origin), amount);
	}

	scalar = 1;

	if(self GetStance() == "prone")
	{
		scalar = .25;
	}
	else if(self GetStance() == "crouch")
	{
		scalar = .5;
	}
	
	if(mod == "MOD_MELEE" && (attacker HasWeapon("bowie_knife_zm") || attacker HasWeapon("sickle_knife_zm") || IsSubStr(weapon, "knife_ballistic_")))
	{
		scalar *= 1.5;
	}

	vec = vector_scale(vec, scalar);

	self SetVelocity(vec);
}

grief_damage_points(got_griefed)
{
	if(got_griefed.health < got_griefed.maxhealth && is_player_valid(self))
	{
		self maps\_zombiemode_score::player_add_points( "damage" );
	}
}

grief_downed_points()
{
	while(1)
	{
		self waittill( "player_downed" );

		if(self.vs_attackers.size > 0)
		{
			percent = level.zombie_vars["penalty_downed"];
			points = round_up_to_ten( int( self.score * percent ) );

			for(i=0;i<self.vs_attackers.size;i++)
			{
				if(is_player_valid(self.vs_attackers[i]))
				{
					self.vs_attackers[i] maps\_zombiemode_score::add_to_player_score( points );
				}
			}

			self.vs_attackers = [];
		}
	}
}

grief_downed_points_add_player(gotgriefed)
{
	gotgriefed endon( "player_downed" );

	if(is_in_array(gotgriefed.vs_attackers, self))
	{
		return;
	}

	gotgriefed.vs_attackers = array_add(gotgriefed.vs_attackers, self);

	while(gotgriefed.health < gotgriefed.maxhealth || gotgriefed.slowdown_wait)
	{
		wait_network_frame();
	}

	gotgriefed.vs_attackers = array_remove_nokeys(gotgriefed.vs_attackers, self);
}

grief_bleedout_points(dead_player)
{
	while(1)
	{
		self waittill( "bled_out" );

		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if(is_player_valid(players[i]) && players[i].vsteam != self.vsteam)
			{
				percent = level.zombie_vars["penalty_no_revive"];
				points = round_up_to_ten( int( players[i].score * percent ) );
				players[i] maps\_zombiemode_score::add_to_player_score( points );
			}
		}
	}
}

setup_grief_msg()
{
	self.grief_hud1 = NewClientHudElem( self );
	self.grief_hud1.alignX = "center";
	self.grief_hud1.alignY = "middle";
	self.grief_hud1.horzAlign = "center";
	self.grief_hud1.vertAlign = "middle";
	self.grief_hud1.y -= 100;
	self.grief_hud1.foreground = true;
	self.grief_hud1.fontScale = 2;
	self.grief_hud1.alpha = 0;
	self.grief_hud1.color = ( 1.0, 1.0, 1.0 );

	self.grief_hud2 = NewClientHudElem( self );
	self.grief_hud2.alignX = "center";
	self.grief_hud2.alignY = "middle";
	self.grief_hud2.horzAlign = "center";
	self.grief_hud2.vertAlign = "middle";
	self.grief_hud2.y -= 75;
	self.grief_hud2.foreground = true;
	self.grief_hud2.fontScale = 2;
	self.grief_hud2.alpha = 0;
	self.grief_hud2.color = ( 1.0, 1.0, 1.0 );
}

grief_msg(msg, var1)
{
	self notify("grief_msg");
	self endon("grief_msg");

	players_alive = get_number_of_valid_players();
	enemies_alive = self get_number_of_valid_enemy_players();
	if(!is_player_valid(self))
		enemies_alive -= 1;

	self.grief_hud1.alpha = 0;
	self.grief_hud2.alpha = 0;

	if(IsDefined(msg))
	{
		if(IsDefined(var1))
		{
			self.grief_hud1 SetText( msg, var1 );
		}
		else
		{
			self.grief_hud1 SetText( msg );
		}
		self.grief_hud1 FadeOverTime( 1 );
		self.grief_hud1.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud1);
	}
	else if (enemies_alive >= 1)
	{
		self.grief_hud1 SetText( &"REIMAGINED_ENEMY_DOWN", enemies_alive );
		self.grief_hud1 FadeOverTime( 1 );
		self.grief_hud1.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud1);
		//self playlocalsound( "vs_" + enemies_alive + "rivup" );
	}
	else if (enemies_alive == 0 && players_alive >= 1)
	{
		self.grief_hud1 SetText( &"REIMAGINED_ALL_ENEMIES_DOWN" );
		self.grief_hud1 FadeOverTime( 1 );
		self.grief_hud1.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud1);
		//self playlocalsound( "vs_0rivup" );
		wait(2.5);
		self.grief_hud2 SetText( &"REIMAGINED_SURVIVE_TO_WIN" );
		self.grief_hud2 FadeOverTime( 1 );
		self.grief_hud2.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud2);
	}	
}

grief_msg_fade_away(text)
{
	self endon("grief_msg");

	wait( 3.0 );

	text FadeOverTime( 1 );
	text.alpha = 0;
	//text delete();
}

round_restart(same_round)
{
	level notify("round_restart");
	level endon("round_restart");

	if(flag("round_restarting"))
	{
		return;
	}

	flag_set("round_restarting");
	flag_clear("spawn_zombies");

	//let player who just downed get last stand stuff initialized first
	wait_network_frame();

	//dont let players bleedout or enter last stand during round restart
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] EnableInvulnerability();
		if(players[i] maps\_laststand::player_is_in_laststand())
		{
			players[i].bleedout_time = 45;
		}
	}

	if(level.gamemode == "snr")
	{
		display_round_won();
	}

	wait 1;

	fade_out(1, false);

	level notify( "round_restarted" );

	zombs = GetAiSpeciesArray("axis");
	for(i=0;i<zombs.size;i++)
	{
		if(zombs[i].animname == "zombie" || zombs[i].animname == "zombie_dog" || zombs[i].animname == "quad_zombie")
			zombs[i] DoDamage( zombs[i].health + 2000, (0,0,0) );
	}

	maps\_zombiemode::ai_calculate_amount(); // reset the amount of zombies in a round

	level.powerup_drop_count = 0; // restarts the amount of powerups you can earn this round

	if( !IsDefined( level.custom_spawnPlayer ) )
	{
		// Custom spawn call for when they respawn from spectator
		level.custom_spawnPlayer = maps\_zombiemode::spectator_respawn;
	}

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		self notify("player_meat_end");

		if(is_player_valid( players[i] ))
		{
			vending_triggers = GetEntArray( "zombie_vending", "targetname" );
			for ( j = 0; j < vending_triggers.size; j++ )
			{
				perk = vending_triggers[j].script_noteworthy;
				if ( players[i] HasPerk( perk ) )
				{
					perk_str = perk + "_stop";
					players[i] notify( perk_str );
				}
			}

			players[i] store_player_weapons();
		}

		if(players[i] maps\_laststand::player_is_in_laststand())
		{
			players[i] maps\_laststand::auto_revive();
		}
		players[i] [[level.spawnPlayer]]();
	}

	wait_network_frame(); // needed for stored weapons to work correctly and round_restarting flag was being cleared too soon

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] notify( "round_restarted" );
		players[i] DisableInvulnerability();
		players[i] TakeAllWeapons();
		players[i] giveback_player_weapons();
		players[i].rebuild_barrier_reward = 0;
		players[i].is_drinking = false;
		players[i].num_perks = 0;
		players[i] SetStance("stand");

		if(level.gamemode != "snr")
		{
			players[i] thread grief_msg(&"REIMAGINED_ANOTHER_CHANCE");
			//players[i] playlocalsound( "vs_restart" );
		}

		if(level.gamemode == "snr")
		{
			if(players[i].score < 5000)
			{
				players[i].score = 5000;
				players[i] maps\_zombiemode_score::set_player_score_hud();
			}
		}
		else
		{
			if(level.round_number > 6)
			{
				if(players[i].score < 1500)
				{
					players[i].score = 1500;
					players[i] maps\_zombiemode_score::set_player_score_hud();
				}
			}
			else if(players[i].score < 500)
			{
				players[i].score = 500;
				players[i] maps\_zombiemode_score::set_player_score_hud();
			}
		}
	}

	level thread maps\_zombiemode::award_grenades_for_survivors(); // get 2 extra grenades when you spawn back in

	level thread fade_in(0, 1, true);

	for(i=0;i<players.size;i++)
	{
		players[i] freezecontrols(false);
	}

	if(level.gamemode == "snr")
	{
		level.snr_round_number++;
		level thread display_round_number();
	}

	flag_clear("round_restarting");

	wait 5;

	flag_set("spawn_zombies");
}

set_grief_viewmodel()
{
	if(IsDefined(level.vsteam))
	{
		if(level.vsteam == "cdc")
		{
			self SetViewModel("bo2_c_zom_hazmat_viewhands");
		}
		else if(level.vsteam == "cia")
		{
			self SetViewModel("bo2_c_zom_suit_viewhands");
		}
	}
	else
	{
		if(self.vsteam == "cdc")
		{
			self SetViewModel("bo2_c_zom_hazmat_viewhands");
		}
		else if(self.vsteam == "cia")
		{
			self SetViewModel("bo2_c_zom_suit_viewhands");
		}
	}
}

set_grief_model()
{
	self DetachAll();
	if(IsDefined(level.vsteam))
	{
		if(level.vsteam == "cdc")
		{
			self setModel("bo2_c_zom_player_cdc_fb");
		}
		else if(level.vsteam == "cia")
		{
			self setModel( "bo2_c_zom_player_cia_fb" );
		}
	}
	else
	{
		if(self.vsteam == "cdc")
		{
			self setModel("bo2_c_zom_player_cdc_fb");
		}
		else if(self.vsteam == "cia")
		{
			self setModel( "bo2_c_zom_player_cia_fb" );
		}
	}
	self.voice = "american";
	self.skeleton = "base";
}

stop_shellshock_when_spectating()
{
	while(1)
	{
		if(!is_player_valid(self))
		{
			self StopShellShock();
			break;
		}
		wait(.05);
	}
}

turn_power_on()
{
	level waittill("fade_introblack");
	switch(level.script)
	{
		case "zombie_theater":
		case "zombie_pentagon":
		case "zombie_cosmodrome":
		case "zombie_coast":
		case "zombie_moon":
			trig = getent("use_elec_switch","targetname");
			trig notify("trigger");	
			break;
		case "zombie_temple":
			players = get_players();
			trig1 = getEnt( "power_trigger_left", "targetname" );
			trig2 = getEnt( "power_trigger_right", "targetname" );
			trig1 notify( "trigger", players[0] );
			trig2 notify( "trigger", players[0] );
			break;
		case "zombie_cod5_asylum":
			trig = getent("use_master_switch","targetname");
			trig notify("trigger");
			break;
		case "zombie_cod5_factory":
			trig = getent("use_power_switch","targetname");
			trig notify("trigger");
			break;
	}
}

open_doors()
{
	flag_wait( "all_players_connected" );
	zombie_doors = GetEntArray( "zombie_door", "targetname" );
	zombie_debris = GetEntArray( "zombie_debris", "targetname" );
	if(level.script == "zombie_cod5_prototype")
	{
		for(i = 0; i < zombie_doors.size; i++)
		{
			zombie_doors[i] open_door();
		}

		for(i = 0; i < zombie_debris.size; i++)
		{
			zombie_debris[i] clear_debris();
		}
	}
	else if(level.script == "zombie_cod5_asylum")
	{
		for(i = 0; i < zombie_doors.size; i++)
		{
			if(zombie_doors[i].target == "auto91")
			{
				zombie_doors[i] open_door();
			}
		}
	}
	else if(level.script == "zombie_cod5_sumpf")
	{
		for(i = 0; i < zombie_doors.size; i++)
		{
			if(zombie_doors[i].target == "attic_blocker")
			{
				zombie_doors[i] open_door();
			}
		}

		for(i = 0; i < zombie_debris.size; i++)
		{
			if(zombie_debris[i].target == "upstairs_blocker")
			{
				zombie_debris[i] clear_debris();
			}
		}
	}
	else if(level.script == "zombie_cod5_factory")
	{
		for(i = 0; i < zombie_doors.size; i++)
		{
			if(zombie_doors[i].target == "outside_west_door" || zombie_doors[i].target == "outside_east_door")
			{
				zombie_doors[i] open_door();
			}
		}
	}
	else if(level.script == "zombie_pentagon")
	{
		for(i = 0; i < zombie_doors.size; i++)
		{
			if(zombie_doors[i].target == "pf824_auto2727")
			{
				zombie_doors[i] open_door();
			}
		}

		for(i = 0; i < zombie_debris.size; i++)
		{
			if(zombie_debris[i].target == "war_room_stair")
			{
				zombie_debris[i] clear_debris();
			}
		}
	}
	else if(level.script == "zombie_cosmodrome")
	{
		for(i = 0; i < zombie_doors.size; i++)
		{
			if(zombie_doors[i].target == "pf41_auto2741" || zombie_doors[i].target == "pf41_auto2743" || zombie_doors[i].target == "pf41_auto2737" || zombie_doors[i].target == "pf41_auto2725")
			{
				zombie_doors[i] open_door();
			}
		}
	}
	else if(level.script == "zombie_moon")
	{
		level waittill("fade_introblack"); //causes error on fast_restart without a wait

		zombie_airlock_buys = GetEntArray("zombie_airlock_buy", "targetname");
		for(i = 0; i < zombie_airlock_buys.size; i++)
		{
			if(zombie_airlock_buys[i].target == "pf1344_auto361")
			{
				zombie_airlock_buys[i] maps\zombie_moon_utility::moon_door_opened();
			}
		}
	}
}

open_door()
{
	self._door_open = true;
	self notify("door_opened");
	self maps\_zombiemode_blockers::door_opened();
}

clear_debris()
{
	tokens = Strtok( self.script_flag, "," );
	for ( i=0; i<tokens.size; i++ )
	{
		flag_set( tokens[i] );
	}
	junk = getentarray( self.target, "targetname" );
	for ( k = 0; k < junk.size; k++ )
	{
		junk[k] trigger_off();
		junk[k] connectpaths();
		junk[k] delete();
	}
	self delete();
	level notify ("junk purchased");
}

remove_ee_songs()
{
	switch(level.script)
	{
		case "zombie_cod5_prototype":
			song = getentarray("evt_egg_killme", "targetname");
			for(i=0;i<song.size;i++)
			{
				song[i] delete();
			}
			break;
		case "zombie_cod5_asylum":
		case "zombie_cod5_sumpf":
			song = getent("toilet", "targetname");
			song disable_trigger();
			break;
		case "zombie_cod5_factory":
			song1 = getent("meteor_one", "targetname");
			song2 = getent("meteor_two", "targetname");
			song3 = getent("meteor_three", "targetname");
			song1 disable_trigger();
			song2 disable_trigger();
			song3 disable_trigger();
			break;
		case "zombie_theater":
			song = GetEntArray( "meteor_egg_trigger", "targetname" );
			for(i=0;i<song.size;i++)
			{
				song[i] delete();
			}
			break;
		case "zombie_pentagon":
			level.phone_counter = -1;
			break;
		case "zombie_cosmodrome":
			song = GetEntArray( "mus_teddybear", "targetname" );
			for(i=0;i<song.size;i++)
			{
				song[i] delete();
			}
			break;
		case "zombie_coast":
		case "zombie_temple":
		case "zombie_moon":
			level.meteor_counter = -1;
			break;
	}
}

get_number_of_valid_enemy_players()
{
	players = get_players();
	num_player_valid = 0;
	for( i = 0 ; i < players.size; i++ )
	{
		if( is_player_valid(players[i]) && players[i].vsteam != self.vsteam )
			num_player_valid += 1;
	}	
	return num_player_valid;
}

get_number_of_valid_friendly_players()
{
	players = get_players();
	num_player_valid = 0;
	for( i = 0 ; i < players.size; i++ )
	{
		if( is_player_valid(players[i]) && players[i].vsteam == self.vsteam )
			num_player_valid += 1;
	}	
	return num_player_valid;
}

enable_mixed_rounds()
{
	level.mixed_rounds_enabled = true;
}

unlimited_powerups()
{
	while(1)
	{
		level.powerup_drop_count = 0;
		wait 1;
	}
}

unlimited_barrier_points()
{
	flag_wait( "all_players_connected" );
	players = get_players();
	while(1)
	{
		for(i=0;i<players.size;i++)
		{
			players[i].rebuild_barrier_reward = 0;
		}
		wait 1;
	}
}

increase_zombie_health()
{
	level.zombie_health = 2000;
}

unlimited_zombies()
{
	wait 1;
	while(1)
	{
		level.zombie_total = 100;
		wait 1;
	}
}

increase_zombie_move_speed()
{
	wait 1;
	level.zombie_move_speed = 106;
}

increase_zombie_spawn_rate()
{
	wait 1;
	if(level.gamemode == "snr")
	{
		level.zombie_vars["zombie_spawn_delay"] = .5;
	}
	else
	{
		level.zombie_vars["zombie_spawn_delay"] = 1;
	}
}

display_round_number()
{
	round_number = level.snr_round_number;

	if(round_number == 1)
	{
		flag_wait("all_players_connected");
		wait 2;
		flag_clear( "spawn_zombies");
	}

	huds = [];
	huds[0] = maps\_zombiemode::create_chalk_hud(0);

	if( round_number >= 1 && round_number <= 5 )
	{
		huds[0] SetShader( "hud_chalk_" + round_number, 64, 64 );
	}
	else
	{
		huds[0].fontscale = 32;
		huds[0] SetValue( round_number );
	}

	// Create "ROUND" hud text
	round = create_simple_hud();
	round.alignX = "center";
	round.alignY = "bottom";
	round.horzAlign = "user_center";
	round.vertAlign = "user_bottom";
	round.fontscale = 16;
	round.color = ( 1, 1, 1 );
	round.x = 0;
	round.y = -265;
	round.alpha = 0;
	round SetText( &"ZOMBIE_ROUND" );

	huds[0].color = ( 1, 1, 1 );
	huds[0].alpha = 0;
	huds[0].alignX = "center";
	huds[0].horzAlign = "user_center";
	huds[0].x = 0;
	if(round_number >= 1 && round_number <= 3)
	{
		huds[0].x += (4 - round_number) * 8;
	}
	huds[0].y = -200;

	// Fade in white
	round FadeOverTime( 1 );
	round.alpha = 1;

	for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( 1 );
		huds[i].alpha = 1;
	}

	wait( 1 );

	// Fade to red
	round FadeOverTime( 2 );
	round.color = ( 0.21, 0, 0 );

	for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( 2 );
		huds[i].color = ( 0.21, 0, 0 );
	}
	wait(2);

	for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( 2 );
		huds[i].alpha = 1;
	}

	wait( 3 );

	if( IsDefined( round ) )
	{
		round FadeOverTime( 1 );
		round.alpha = 0;
		for ( i=0; i<huds.size; i++ )
		{
			huds[i] FadeOverTime( 1 );
			huds[i].alpha = 0;
		}
	}

	wait( 0.25 );

	//level notify( "intro_hud_done" );
	//		huds[0].x = 0;
	wait( 2 );

	if(round_number == 1)
	{
		flag_set( "spawn_zombies");
	}

	round destroy_hud();

	for ( i=0; i<huds.size; i++ )
	{
		huds[i] destroy_hud();
	}
}


add_grief_logo(logo)
{
	wait 1.75;
	hud = create_simple_hud(self);
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_bottom";
	//hud.color = ( 0.21, 0, 0 );
	//hud.x = x; 
	hud.y = -4; 
	hud.alpha = 1;
	hud.fontscale = 32.0;

	hud SetShader( logo, 64, 64 );

	return hud;
}

gamemode_intro_hud(gamemode_name)
{
	gamemode = create_simple_hud();
	gamemode.alignX = "center"; 
	gamemode.alignY = "bottom";
	gamemode.horzAlign = "user_center"; 
	gamemode.vertAlign = "user_bottom";
	gamemode.fontscale = 16;
	gamemode.color = ( 1, 1, 1 );
	gamemode.x = 0;
	gamemode.y = -300;
	gamemode.alpha = 0;
	gamemode SetText( gamemode_name );
	gamemode FadeOverTime( 1 );
	gamemode.alpha = 1;
	wait 1;
	gamemode FadeOverTime( 2 );
	gamemode.color = ( 0.21, 0, 0 );
	wait 5;
	gamemode FadeOverTime( 1 );
	gamemode.alpha = 0;
	return gamemode;
}

add_gamemode_hud()
{
	flag_wait( "all_players_spawned" );
	hud = create_simple_hud();
	hud.alignX = "left"; 
	hud.alignY = "top";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_top";
	hud.color = ( 0.21, 0, 0 );
	hud.fontscale = 9;
	hud.alpha = 1;
	while(1)
	{
		hud SetText("CDC: " + level.team1score + " | CIA: " + level.team2score);
		wait .05;
	}
}

race_points_handicap()
{
	while(1)
	{
		self waittill("player_revived");
		if (level.round_number > 6 && self.score < 1500)
		{
			self.score = 1500;
			self maps\_zombiemode_score::set_player_score_hud();
		}
	}
}

reduce_survive_zombie_amount()
{
	flag_wait( "all_players_spawned" );
	players = get_players();
	while(1)
	{
		for( i = 0; i < players.size; i++ )
		{
			if( players[i] get_number_of_valid_enemy_players() == 0  && players.size > 1 )
			{
				if(level.zombie_total > 100)
				{
					level.zombie_total = 100;
				}
			}
		}
		wait 1;
	}
}

snr_round_win()
{
	team = undefined;
	player = undefined;
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(is_player_valid( players[i] ))
		{
			player = players[i];
			break;
		}
	}

	team = player.vsteam;

	if(IsDefined(team))
	{
		if(!IsDefined(level.round_wins))
		{
			level.rounds_wins = [];
		}

		if(!IsDefined(level.round_wins[team]))
		{
			level.round_wins[team] = 0;
		}

		level.round_wins[team]++;

		for(i=0;i<players.size;i++)
		{
			if(players[i].vsteam == team)
			{
				players[i] SetClientDvar("vs_counter_friendly_num", level.round_wins[team]);
			}
			else
			{
				if(!IsDefined(players[i].highest_enemy_num) || level.round_wins[team] >= players[i].highest_enemy_num)
				{
					players[i].highest_enemy_num = level.round_wins[team];

					players[i] SetClientDvar("vs_counter_enemy_num", level.round_wins[team]);
					if(level.vsteams == "ffa")
					{
						players[i] SetClientDvar("vs_enemy_playername", player.playername);
					}
				}
			}
		}

		level.vs_recent_winning_player = player;
		level.vs_recent_winning_team = team;

		if(level.round_wins[team] == 3)
		{
			level.vs_winning_team = team;
			level notify( "end_game" );
		}
		else
		{
			for(i=0;i<players.size;i++)
			{
				if(players[i].vsteam == team)
				{
					//players[i] playlocalsound( "vs_0rivup" );
				}
			}
			level thread round_restart();
		}
	}
}

display_round_won(team)
{
	flag_wait("all_players_spawned");

	if(!IsDefined(level.vs_recent_winning_team))
	{
		return;
	}

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(level.vsteams == "ffa")
		{
			players[i] thread grief_msg(&"REIMAGINED_PLAYER_WON", level.vs_recent_winning_player.playername);
		}
		else
		{
			if(level.vs_recent_winning_team == "cdc")
			{
				players[i] thread grief_msg(&"REIMAGINED_CDC_WON");
			}
			else
			{
				players[i] thread grief_msg(&"REIMAGINED_CIA_WON");
			}
		}
	}

	wait 2;
}

setup_grief_top_logos()
{
	flag_wait( "all_players_connected" );

	wait_network_frame();

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] SetClientDvar("vs_top_logos_on", 1);

		if(IsDefined(level.vsteam))
		{
			team = level.vsteam;
		}
		else
		{
			team = players[i].vsteam;
		}

		if(team == "cdc")
		{
			if(IsDefined(level.vsteam))
			{
				players[i] SetClientDvar("vs_logo_enemy", "cdc_logo");
			}
			else
			{
				players[i] SetClientDvar("vs_logo_enemy", "cia_logo");
			}
		}
		else
		{
			if(IsDefined(level.vsteam))
			{
				players[i] SetClientDvar("vs_logo_enemy", "cia_logo");
			}
			else
			{
				players[i] SetClientDvar("vs_logo_enemy", "cdc_logo");
			}
		}

		players[i] SetClientDvar("vs_counter_friendly_num_on", true);
		players[i] SetClientDvar("vs_counter_enemy_num_on", true);

		players[i] SetClientDvar("vs_counter_friendly_num", 0);
		players[i] SetClientDvar("vs_counter_enemy_num", 0);
	}
}

setup_grief_top_playernames()
{
	flag_wait( "all_players_connected" );

	wait_network_frame();

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] SetClientDvar("vs_top_playernames_on", 1);

		players[i] SetClientDvar("vs_friendly_playername", players[i].playername);

		players[i] SetClientDvar("vs_enemy_playername", "Unknown Soldier");
		for(j=0;j<players.size;j++)
		{
			if(players[j].vsteam != players[i].vsteam)
			{
				players[i] SetClientDvar("vs_enemy_playername", players[j].playername);
				break;
			}
		}

		players[i] SetClientDvar("vs_counter_friendly_num_on", true);
		players[i] SetClientDvar("vs_counter_enemy_num_on", true);

		players[i] SetClientDvar("vs_counter_friendly_num", 0);
		players[i] SetClientDvar("vs_counter_enemy_num", 0);
	}
}

race_win_watcher()
{
	flag_wait("all_players_connected");

	wait_network_frame();

	team_kills = [];

	while(1)
	{
		players = get_players();
		for(i=0;i<players.size;i++)
		{
			team_kills[players[i].vsteam] = 0;
		}

		for(i=0;i<players.size;i++)
		{
			team_kills[players[i].vsteam] += players[i].kills;
		}

		teams = GetArrayKeys(team_kills);
		highest_player = undefined;
		second_highest_player = undefined;

		for(i=0;i<teams.size;i++)
		{
			for(j=0;j<players.size;j++)
			{
				if(players[j].vsteam == teams[i])
				{
					players[j] SetClientDvar("vs_counter_friendly_num", team_kills[teams[i]]);
				}
				else
				{
					if(!IsDefined(highest_player) || team_kills[players[j].vsteam] > team_kills[highest_player.vsteam])
					{
						second_highest_player = highest_player;
						highest_player = players[j];
					}
					else if(!IsDefined(second_highest_player) || team_kills[players[j].vsteam] > team_kills[second_highest_player.vsteam])
					{
						second_highest_player = players[j];
					}
				}
			}
		}

		if(!IsDefined(highest_player))
		{
			highest_player = players[0];
		}

		highest_team = highest_player.vsteam;
		second_highest_team = second_highest_player.vsteam;
		level.vs_winning_team = highest_team;

		for(i=0;i<players.size;i++)
		{
			if(players[i].vsteam == highest_team)
			{
				if(IsDefined(second_highest_player))
				{
					players[i] SetClientDvar("vs_counter_enemy_num", team_kills[second_highest_team]);
					if(level.vsteams == "ffa")
					{
						players[i] SetClientDvar("vs_enemy_playername", second_highest_player.playername);
					}
				}
			}
			else
			{
				players[i] SetClientDvar("vs_counter_enemy_num", team_kills[highest_team]);
				if(level.vsteams == "ffa")
				{
					players[i] SetClientDvar("vs_enemy_playername", highest_player.playername);
				}
			}
		}

		for(i=0;i<teams.size;i++)
		{
			if(team_kills[teams[i]] >= 500)
			{
				level.vs_winning_team = teams[i];
				level notify( "end_game" );
				return;
			}
		}

		wait_network_frame();
	}
}

increase_round_number_over_time()
{
	level endon("end_game");

	level waittill( "start_of_round" );

	while(1)
	{
		wait 28;

		level.old_music_state = undefined; // need this to be able to play the same music again
		level thread maps\_zombiemode_audio::change_zombie_music( "round_start" );

		wait 2;

		level.round_number++;

		level thread fast_chalk_one_up();

		prev_health = level.zombie_health;

		maps\_zombiemode::ai_calculate_health( level.round_number );

		if(level.zombie_vars["zombie_spawn_delay"] > 0.5)
		{
			level.zombie_vars["zombie_spawn_delay"] *= 0.95;

			if(level.zombie_vars["zombie_spawn_delay"] < 0.5)
			{
				level.zombie_vars["zombie_spawn_delay"] = 0.5;
			}
		}

		level.zombie_move_speed = level.round_number * level.zombie_vars["zombie_move_speed_multiplier"];

		//if a zombie has not been damaged yet, set their health to the new rounds health
		zombs = GetAiSpeciesArray( "axis", "all" );
		for (i = 0; i < zombs.size; i++)
		{
			if(zombs[i].animname == "zombie")
			{
				if(zombs[i].health == prev_health)
				{
					zombs[i].health = level.zombie_health;
				}
			}
			else if(zombs[i].animname == "quad_zombie")
			{
				if(zombs[i].health == int(prev_health * .75))
				{
					zombs[i].health = int(level.zombie_health * .75);
				}
			}
		}

		level thread maps\_zombiemode::award_grenades_for_survivors();

		players = get_players();
		for(i=0;i<players.size;i++)
		{
			if(IsDefined(players[i] get_player_placeable_mine()))
			{
				players[i] setweaponammoclip(players[i] get_player_placeable_mine(), 2);
			}
		}

		if(level.round_number == 20)
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				players[i] thread grief_msg(&"REIMAGINED_FINAL_ROUND");
			}

			wait 45;

			level notify("end_game");
		}
	}
}

fast_chalk_one_up()
{
	huds = [];
	huds[0] = level.chalk_hud1;
	huds[1] = level.chalk_hud2;

	/*for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( 0.5 );
		huds[i].alpha = 0;
	}
	wait( 0.5 );*/

	for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( .5 );
		//huds[i].alpha = 1;
		huds[i].color = ( 1, 1, 1 );
	}
	wait( .5 );

	round_number = level.round_number;

	// Hud1 shader
	if( round_number >= 1 && round_number <= 5 )
	{
		huds[0] SetShader( "hud_chalk_" + round_number, 64, 64 );
	}
	else if ( round_number >= 5 && round_number <= 10 )
	{
		huds[0] SetShader( "hud_chalk_5", 64, 64 );
	}

	// Hud2 shader
	if( round_number > 5 && round_number <= 10 )
	{
		huds[1] SetShader( "hud_chalk_" + ( round_number - 5 ), 64, 64 );
	}

	// Display value
	if( round_number <= 5 )
	{
		huds[1] SetText( " " );
	}
	else if( round_number > 10 )
	{
		huds[0].fontscale = 32;
		huds[0] SetValue( round_number );
		huds[1] SetText( " " );
	}

	for ( i=0; i<huds.size; i++ )
	{
		huds[i] FadeOverTime( .5 );
		huds[i].color = ( 0.21, 0, 0 );
	}
}

auto_revive_after_time()
{
	self endon( "disconnect" );
	self endon("player_revived");
	level endon("end_game");

	self.revive_hud setText( &"GAME_REVIVING" );
	self maps\_laststand::revive_hud_show_n_fade(10);
	wait 10;
	self maps\_laststand::auto_revive();
}

unlimited_ammo()
{
	level endon("end_game");

	flag_wait("all_players_connected");

	while(1)
	{
		players = get_players();

		for(i=0;i<players.size;i++)
		{
			if(players[i] maps\_laststand::player_is_in_laststand())
			{
				continue;
			}

			primaryWeapons = players[i] GetWeaponsListPrimaries();

			for(j=0;j<primaryWeapons.size;j++)
			{
				//clip_size = WeaponClipSize(primaryWeapons[j]);
				//players[i] SetWeaponAmmoStock(primaryWeapons[j], clip_size);
				players[i] GiveMaxAmmo(primaryWeapons[j]);

				alt_name = WeaponAltWeaponName(primaryWeapons[j]);
				if(alt_name != "none")
				{
					players[i] GiveMaxAmmo(alt_name);
				}

				if ( issubstr( primaryWeapons[j], "knife_ballistic_" ) )
				{
					players[i] notify( "zmb_lost_knife" );
				}
			}
		}

		wait .001;
	}
}

setup_gungame_weapons()
{
	level.gg_kills_to_next_wep = 10;
	level.gg_weps = [];
	level.gg_weps[0] = "cz75_zm";
	level.gg_weps[1] = "python_zm";

	if(!IsSubStr(level.script, "zombie_cod5_"))
	{
		level.gg_weps[2] = "ithaca_zm";
	}
	else
	{
		level.gg_weps[2] = "zombie_shotgun";
	}

	level.gg_weps[3] = "spas_zm";

	if(!IsSubStr(level.script, "zombie_cod5_"))
	{
		level.gg_weps[4] = "ak74u_zm";
	}
	else
	{
		level.gg_weps[4] = "zombie_thompson";
	}

	level.gg_weps[5] = "spectre_zm";
	level.gg_weps[6] = "ppsh_zm";
	level.gg_weps[7] = "fnfal_zm";
	level.gg_weps[8] = "g11_lps_zm";
	level.gg_weps[9] = "famas_zm";
	level.gg_weps[10] = "galil_zm";
	level.gg_weps[11] = "stoner63_zm";
	level.gg_weps[12] = "hk21_zm";
	level.gg_weps[13] = "psg1_zm";
	level.gg_weps[14] = "l96a1_zm";
	level.gg_weps[15] = "china_lake_zm";
	level.gg_weps[16] = "m72_law_zm";
	level.gg_weps[17] = "ray_gun_zm";

	if(level.script == "zombie_cod5_prototype" || level.script == "zombie_theater" || level.script == "zombie_cosmodrome")
	{
		level.gg_weps[18] = "thundergun_zm";
	}
	else if(level.script == "zombie_cod5_asylum" || level.script == "zombie_pentagon")
	{
		level.gg_weps[18] = "freezegun_zm";
	}
	else if(level.script == "zombie_cod5_sumpf" || level.script == "zombie_cod5_factory")
	{
		level.gg_weps[18] = "tesla_gun_zm";
	}
	else if(level.script == "zombie_coast")
	{
		level.gg_weps[18] = "humangun_zm";
	}
	else if(level.script == "zombie_temple")
	{
		level.gg_weps[18] = "shrink_ray_zm";
	}
	else if(level.script == "zombie_moon")
	{
		level.gg_weps[18] = "microwavegundw_zm";
	}

	level.gg_weps[19] = "knife_ballistic_zm";

	level.gg_weps[20] = "none";

	flag_wait("all_players_connected");

	players = get_players();

	for(i=0;i<players.size;i++)
	{
		players[i].gg_wep_num = 0;
		players[i].gg_kill_count = 0;
	}

	level waittill("fade_introblack");

	players = get_players();

	for(i=0;i<players.size;i++)
	{
		players[i] update_gungame_weapon();
	}
}

update_gungame_weapon(decrement, upgrade)
{
	if(!IsDefined(decrement))
		decrement = false;

	if(!IsDefined(upgrade))
		upgrade = false;

	//decrement updates hud earlier, upgrade doesnt change hud
	if(!decrement && !upgrade)
	{
		self update_gungame_hud();
	}

	if(!upgrade)
	{
		self.player_bought_pack = undefined;
	}

	//if player has weapon in pap, remove it
	pap_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	for(i=0;i<pap_trigger.size;i++)
	{
		if(IsDefined(pap_trigger[i].user) && pap_trigger[i].user == self)
		{
			pap_trigger[i] notify("pap_force_timeout");
		}
	}

	primaryWeapons = self GetWeaponsListPrimaries();
	holding_primary = false;
	for(j=0;j<primaryWeapons.size;j++)
	{
		if(self GetCurrentWeapon() == primaryWeapons[j] || self GetCurrentWeapon() == WeaponAltWeaponName(primaryWeapons[j]) || self IsSwitchingWeapons())
		{
			holding_primary = true;
		}

		if(is_placeable_mine(self GetCurrentWeapon()) && self GetWeaponAmmoClip(self GetCurrentWeapon()) == 0)
		{
			holding_primary = true;
		}

		if ( IsSubStr( primaryWeapons[j], "knife_ballistic_" ) )
		{
			self notify( "zmb_lost_knife" );
		}
		self TakeWeapon(primaryWeapons[j]);
	}

	weapon_string = level.gg_weps[self.gg_wep_num];
	if ( weapon_string == "knife_ballistic_zm" && self HasWeapon( "bowie_knife_zm" ) )
	{
		weapon_string = "knife_ballistic_bowie_zm";
	}
	else if ( weapon_string == "knife_ballistic_zm" && self HasWeapon( "sickle_knife_zm" ) )
	{
		weapon_string = "knife_ballistic_sickle_zm";
	}

	if(self.zombie_vars["zombie_powerup_upgrade_weapon_on"] || IsDefined(self.player_bought_pack))
	{
		weapon_string = level.zombie_weapons[weapon_string].upgrade_name;

		index = 0;
		if(weapon_string == "tesla_gun_upgraded_zm" && IsSubStr(level.script, "zombie_cod5_"))
		{
			index = 1;
		}

		self GiveWeapon( weapon_string, index, self maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( weapon_string ) );
	}
	else
	{
		self GiveWeapon(weapon_string);
	}

	//if player was holding primary, initially getting first wep, or decrementing, then switch to wep
	if(holding_primary || (self.gg_wep_num == 0 && !decrement) || decrement)
	{
		self SwitchToWeapon(weapon_string);
	}

	if(self.gg_wep_num != 0 && !decrement && !upgrade)
	{
		nade = self get_player_lethal_grenade();
		if(IsDefined(nade))
		{
			nade_clip = self GetWeaponAmmoClip(nade);
			nade_clip += 2;
			if(nade_clip > 4)
			{
				nade_clip = 4;
			}
			self SetWeaponAmmoClip( nade, nade_clip );
		}

		mine = self get_player_placeable_mine();
		if(IsDefined(mine))
		{
			self SetWeaponAmmoClip(mine, 2);
		}
	}
}

update_gungame_hud()
{
	wep_num = self.gg_wep_num + 1;

	//update personal counter (left side)
	if(wep_num > 0)
	{
		self SetClientDvar("vs_counter_friendly_num", wep_num);
	}

	players = get_players();

	highest_player = undefined;
	second_highest_player = undefined;
	for(i=0;i<players.size;i++)
	{
		//only check current teams score
		if(players[i].vsteam != self.vsteam)
		{
			continue;
		}

		if(!IsDefined(highest_player) || players[i].gg_wep_num > highest_player.gg_wep_num)
		{
			second_highest_player = highest_player;
			highest_player = players[i];
		}
		else if(!IsDefined(second_highest_player) || players[i].gg_wep_num > second_highest_player.gg_wep_num)
		{
			second_highest_player = players[i];
		}
	}

	if(!IsDefined(highest_player))
	{
		highest_player = players[0];
	}

	highest_wep = highest_player.gg_wep_num + 1;
	if(IsDefined(second_highest_player))
	{
		second_highest_wep = second_highest_player.gg_wep_num + 1;
	}
	else
	{
		second_highest_wep = 0;
	}

	//update highest enemy counter (right side)
	for(i=0;i<players.size;i++)
	{
		//dont need to check friendly players, right side is for enemy players
		if(players[i].vsteam == self.vsteam)
		{
			continue;
		}

		//show second place player's score for first place player
		if(players[i] == highest_player)
		{
			if(IsDefined(second_highest_player))
			{
				players[i] SetClientDvar("vs_counter_enemy_num", second_highest_wep);
				if(level.vsteams == "ffa")
				{
					players[i] SetClientDvar("vs_enemy_playername", second_highest_player.playername);
				}
			}
		}
		else
		{
			players[i] SetClientDvar("vs_counter_enemy_num", highest_wep);
			if(level.vsteams == "ffa")
			{
				players[i] SetClientDvar("vs_enemy_playername", highest_player.playername);
			}
		}
	}
}

meat_stink_think()
{
	level endon("end_game");

	while(1)
	{
		players = get_players();
		meat_stink_active = false;
		for(i=0;i<players.size;i++)
		{
			if(IsDefined(players[i].meat_stink_active))
			{
				meat_stink_active = true;
				break;
			}
		}

		if(meat_stink_active)
		{
			for(i=0;i<players.size;i++)
			{
				if(is_player_valid(players[i]))
				{
					if(!IsDefined(players[i].meat_stink_active))
					{
						players[i].ignoreme = true;
					}
					else
					{
						players[i].ignoreme = false;
					}
				}
			}
			wait .5;
		}
		else
		{
			for(i=0;i<players.size;i++)
			{
				if(is_player_valid(players[i]))
				{
					players[i].ignoreme = false;
				}
			}
			level waittill("meat_powerup_active");
		}
	}
}