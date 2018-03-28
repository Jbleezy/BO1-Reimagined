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
			level thread increase_round_number();
			level thread increase_zombie_move_speed();
			level thread increase_zombie_spawn_rate();
			level thread setup_grief_top_logos();
		}
		else if(level.gamemode == "race")
		{
			level thread race_win_watcher();
			level thread increase_round_number_over_time();
			level thread setup_grief_top_logos();
		}
		else if(level.gamemode == "gg")
		{
			level thread unlimited_ammo();
			level thread increase_round_number();
			level thread increase_zombie_health();
			level thread increase_zombie_spawn_rate();
			level thread setup_gungame_weapons();
			level thread setup_grief_top_playernames();
		}

		if(level.script == "zombie_temple")
		{
			level thread unlimited_shrieker_and_napalm_spawns();
		}

		level thread unlimited_powerups();
		level thread unlimited_barrier_points();
		level thread unlimited_zombies();
	}
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

	level._effect["grief_shock"] = LoadFX("grief/fx_grief_shock");
	level._effect["meat_fx"] = Loadfx( "grief/fx_meat_stink" );

	PrecacheShader("waypoint_cia");
	PrecacheShader("waypoint_cdc");

	precacheModel("bo2_c_zom_hazmat_viewhands");
	precacheModel("bo2_c_zom_player_cdc_fb");
	precacheModel("bo2_c_zom_suit_viewhands");
	precacheModel("bo2_c_zom_player_cia_fb");
}

include_grief_powerups()
{
	include_powerup("grief_empty_clip");
	include_powerup("grief_lose_points");
	include_powerup("grief_half_points");
	include_powerup("grief_half_damage");
	include_powerup("grief_slow_down");
	include_powerup("meat");

	vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	if(level.gamemode == "gg")
	{
		include_powerup("random_weapon");
		include_powerup("all_revive");

		if(vending_weapon_upgrade_trigger.size >= 1)
		{
			include_powerup("upgrade_weapon");
		}
	}

	PrecacheItem("meat_zm");

	wait_network_frame();
	level.zombie_powerup_array = [];
	level.zombie_powerup_array = array("full_ammo", "insta_kill", "double_points", "nuke", "grief_empty_clip", "grief_lose_points", "grief_half_points", "grief_half_damage", "grief_slow_down", "meat"); 

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

		//players[i] thread take_tac_nades_when_used();
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
	players = get_players();
	array = array("cdc", "cia");
	array = array_randomize(array);
	for(i=0;i<players.size;i++)
	{
		if(level.gamemode == "ffa" || level.gamemode == "gg" || level.gamemode == "turned")
		{
			if(!IsDefined(level.vsteam))
			{
				level.vsteam = random(array);
			}
			players[i].vsteam = "ffa" + (i + 1);
		}
		else
		{
			if(i / players.size < .5)
			{
				players[i].vsteam = array[0];
			}
			else
			{
				players[i].vsteam = array[1];
			}
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
	if(self.lastActiveStoredWeap == "microwavegun_zm")
	{
		self.lastActiveStoredWeap = "microwavegundw_zm";
	}
	else if(self.lastActiveStoredWeap == "microwavegun_upgraded_zm")
	{
		self.lastActiveStoredWeap = "microwavegundw_upgraded_zm";
	}
	self SetLastStandPrevWeap( self.lastActiveStoredWeap );

	self.melee = self get_player_melee_weapon();
	self.lethal = self get_player_lethal_grenade();
	self.tac = self get_player_tactical_grenade();
	self.mine = self get_player_placeable_mine();
	
	self.hadpistol = false;
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

		self.weaponAmmo[weapon]["clip_dual_wield"] = undefined;
		dual_wield_name = WeaponDualWieldWeaponName( weapon );
		if ( dual_wield_name != "none" )
		{
			self.weaponAmmo[dual_wield_name]["clip"] = self GetWeaponAmmoClip( dual_wield_name );
		}

		//dont store the weapon attachment name as the last active weapon or can't switch to it
		wep_prefix = GetSubStr(weapon, 0, 3);
		alt_wep = WeaponAltWeaponName(weapon);
		if(alt_wep != "none" && (wep_prefix == "gl_" || wep_prefix == "mk_" || wep_prefix == "ft_"))
		{
			self.lastActiveStoredWeap = alt_wep;
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
		// this player was killed while reviving another player
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

		if(IsDefined(self.weapon_taken_by_losing_additionalprimaryweapon) && weapon == self.weapon_taken_by_losing_additionalprimaryweapon[0])
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
			self GiveWeapon( weapon, 0, self maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( weapon ) );
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

	self set_player_melee_weapon(self.melee);
	self thread maps\_zombiemode::set_melee_actionslot();
	
	self set_player_lethal_grenade(self.lethal);

	if(IsDefined(self.tac))
	{
		self set_player_tactical_grenade(self.tac);
	}

	if(IsDefined(self.mine))
	{
		self giveweapon(self.mine);
		self set_player_placeable_mine(self.mine);
		self setactionslot(4,"weapon",self.mine);
		self setweaponammoclip(self.mine,2);
	}

	if( self.lastActiveStoredWeap != "none" && self.lastActiveStoredWeap != "mine_bouncing_betty" && self.lastActiveStoredWeap != "claymore_zm" && self.lastActiveStoredWeap != "spikemore_zm" 
		&& self.lastActiveStoredWeap != "combat_knife_zm" && self.lastActiveStoredWeap != "combat_bowie_knife_zm" && self.lastActiveStoredWeap != "combat_sickle_knife_zm" )
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
			self thread switch_to_combat_knife();
		}
	}
}

switch_to_combat_knife()
{
	wait_network_frame();

	melee = self get_player_melee_weapon();
	if(IsDefined(melee))
	{
		wep = "combat_" + melee;
		self SwitchToWeapon(wep);
	}
}

grief(eAttacker, sMeansOfDeath, sWeapon, iDamage, eInflictor, sHitLoc)
{
	if(sWeapon == "mine_bouncing_betty" && self getstance() == "prone" && sMeansOfDeath == "MOD_GRENADE_SPLASH")
		return;

	//only nades, mines, and flops do actual damage
	if(!self HasPerk( "specialty_flakjacket" ))
	{
		//80 DoDamage = 25 actual damage
		if(sMeansOfDeath == "MOD_GRENADE_SPLASH" && (sWeapon == "frag_grenade_zm" || sWeapon == "sticky_grenade_zm" || sWeapon == "stielhandgranate"))
		{
			//nades
			self DoDamage( 80, eInflictor.origin );
		}
		else if( eAttacker HasPerk( "specialty_flakjacket" ) && isdefined( eAttacker.divetoprone ) && eAttacker.divetoprone == 1 && sMeansOfDeath == "MOD_GRENADE_SPLASH" )
		{
			//for flops, the origin of the player must be used
			self DoDamage( 80, eAttacker.origin );
		}
		else if( sMeansOfDeath == "MOD_GRENADE_SPLASH" && (is_placeable_mine( sWeapon ) || is_tactical_grenade( sWeapon )) )
		{
			//tactical nades and mines
			self DoDamage( 80, eInflictor.origin );
		}
	}

	self thread slowdown(sWeapon, sMeansOfDeath, eAttacker, sHitLoc);

	if(sMeansOfDeath == "MOD_MELEE" 
		|| sWeapon == "knife_ballistic_zm" || sWeapon == "knife_ballistic_upgraded_zm" || sWeapon == "knife_ballistic_bowie_zm" || sWeapon == "knife_ballistic_bowie_upgraded_zm")
	{
		self thread push(eAttacker, sWeapon, sMeansOfDeath);
	}
}

slowdown(weapon, mod, eAttacker, loc)
{
	if(!IsDefined(self.slowdown_wait))
	{
		self.slowdown_wait = false;
	}

	if(weapon == "mine_bouncing_betty" && self GetStance() == "prone")
		return;

	//shotguns were being called here for each pellet that hit a player, causing players to earn more grief points than they should have, this prevents that from happening
	if(WeaponClass(weapon) == "spread")
	{
		if(!IsDefined(eAttacker.spread_already_damaged))
		{
			eAttacker.spread_already_damaged = [];
		}

		if(IsDefined(eAttacker.spread_already_damaged[self GetEntityNumber()]))
		{
			return;
		}
		else
		{
			eAttacker.spread_already_damaged[self GetEntityNumber()] = true;
			self thread set_undamaged_after_frame(eAttacker);
		}
	}

	eAttacker thread grief_damage_points(self);

	//player is already slowed down, don't slow them down again
	if(self.slowdown_wait)
	{
		return;
	}

	self.slowdown_wait = true;

	eAttacker thread grief_downed_points(self);

	PlayFXOnTag( level._effect["grief_shock"], self, "back_mid" );
	self AllowSprint(false);
	self SetBlur( 1, .1 );

	if(maps\_zombiemode_weapons::is_weapon_upgraded(weapon) || is_placeable_mine(weapon) || is_tactical_grenade(weapon) || weapon == "sniper_explosive_zm" || ( eAttacker HasPerk( "specialty_flakjacket" ) && eAttacker.divetoprone == 1 && mod == "MOD_GRENADE_SPLASH"))
	{
		self SetMoveSpeedScale( self.move_speed * .2 );	
	}
	else
	{
		self SetMoveSpeedScale( self.move_speed * .3 );
	}

	wait( .75 );

	self SetMoveSpeedScale( 1 );
	if(!self.is_drinking || IsDefined(self.has_meat))
		self AllowSprint(true);
	self SetBlur( 0, .2 );

	self.slowdown_wait = false;
}

set_undamaged_after_frame(eAttacker)
{
	wait_network_frame();
	eAttacker.spread_already_damaged[self GetEntityNumber()] = undefined;
}

push(eAttacker, sWeapon, sMeansOfDeath) //prone, bowie/ballistic crouch, bowie/ballistic, crouch, regular
{
	if(self.push_wait == false)
	{
		amount = 0;
		self.push_wait = true;
		if( self GetStance() == "prone" )
		{
			wait .75;
			self.push_wait = false;
			return;
		}
		else if(eAttacker._bowie_zm_equipped || eAttacker._sickle_zm_equipped || sWeapon == "knife_ballistic_zm" || sWeapon == "knife_ballistic_upgraded_zm")
		{
			if(self GetStance() == "crouch")
			{
				amount = 150;
			}
			else
			{
				amount = 450;
			}
		}
		else
		{
			if(self GetStance() == "crouch")
			{
				amount = 100;
			}
			else
			{
				amount = 300;	
			}
		}
		self SetVelocity( VectorNormalize( self.origin - eAttacker.origin ) * (amount, amount, amount) );
		wait .75;
		self.push_wait = false;
	}
}

grief_damage_points(gotgriefed)
{
	if(gotgriefed.health < gotgriefed.maxhealth && is_player_valid(self))
	{
		points = int(10 * self.zombie_vars["zombie_point_scalar"]);
		self maps\_zombiemode_score::add_to_player_score( points );
	}
}

grief_downed_points(gotgriefed)
{
	//self notify("monitor downed points");
	//self endon("monitor downed points");
	gotgriefed endon( "player_downed" );

	if(!IsDefined(gotgriefed.vs_attackers))
	{
		gotgriefed.vs_attackers = [];
	}

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

	/*while(gotgriefed.health < gotgriefed.maxhealth)
	{
		if(!is_player_valid(gotgriefed))
		{
			if(is_player_valid(self))
			{
				points = round_up_to_ten(int(gotgriefed.score * .05));
				self maps\_zombiemode_score::add_to_player_score( points );
			}
			return;
		}

		wait_network_frame();
	}*/

	/*if(!is_player_valid(gotgriefed) && is_player_valid(self))
	{
		points = round_up_to_ten(int(gotgriefed.score * .05));
		self maps\_zombiemode_score::add_to_player_score( points );
	}*/
}

grief_bleedout_points(dead_player)
{
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		if(is_player_valid(players[i]) && players[i].vsteam != dead_player.vsteam)
		{
			points = round_up_to_ten(int(players[i].score * .1));
			players[i] maps\_zombiemode_score::add_to_player_score( points );
		}
		/*else if(is_player_valid(players[i]) && players[i].vsteam == dead_player.vsteam)
		{
			points = round_up_to_ten(int(players[i].score * .1));
			players[i] maps\_zombiemode_score::minus_to_player_score( points );
		}*/
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

grief_msg(msg)
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
		self.grief_hud1 SetText( msg );
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
	}
	else if (enemies_alive == 0 && players_alive >= 1)
	{
		self.grief_hud1 SetText( &"REIMAGINED_ALL_ENEMIES_DOWN" );
		self.grief_hud1 FadeOverTime( 1 );
		self.grief_hud1.alpha = 1;
		self thread grief_msg_fade_away(self.grief_hud1);
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
	flag_set("round_restarting");
	flag_clear( "spawn_zombies");

	//let player who just downed get last stand stuff initialized first
	wait_network_frame();
	level notify( "round_restarted" );

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

	SetTimeScale(.5);

	wait(1);

	fade_out(1, false);

	SetTimeScale(1);

	zombs = GetAiSpeciesArray("axis");
	for(i=0;i<zombs.size;i++)
	{
		if(zombs[i].animname == "zombie" || zombs[i].animname == "zombie_dog" || zombs[i].animname == "quad_zombie")
			zombs[i] DoDamage( zombs[i].health + 2000, (0,0,0) );
	}

	maps\_zombiemode::ai_calculate_amount(); //reset the amount of zombies in a round

	level.powerup_drop_count = 0; //restarts the amount of powerups you can earn this round

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

	wait_network_frame(); //needed for stored weapons to work correctly and round_restarting flag was being cleared too soon

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] notify( "round_restarted" );
		players[i] DisableInvulnerability();
		players[i].rebuild_barrier_reward = 0;
		players[i] DoDamage( 0, (0,0,0) ); //fix for health not being correct
		players[i] TakeAllWeapons();
		players[i] giveback_player_weapons();
		players[i].is_drinking = false;
		players[i] SetStance("stand");

		if(level.gamemode != "snr")
		{
			players[i] thread grief_msg(&"REIMAGINED_ANOTHER_CHANCE");
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

	level thread maps\_zombiemode::award_grenades_for_survivors(); //get 2 extra grenades when you spawn back in

	/*if(level.script == "zombie_pentagon")
		level thread maps\zombie_pentagon_amb::play_pentagon_announcer_vox( "zmb_vox_pentann_defcon_reset" );
	else
		level thread play_sound_2d( "sam_nospawn" );*/

	//had to put here instead of the very end, since display_round_number is a timed function and if this flag isnt cleared players cant take damage from traps (and at this point players are spawned back in)
	flag_clear("round_restarting");

	level thread fade_in(0, 1, true);

	for(i=0;i<players.size;i++)
	{
		players[i] freezecontrols(false);
	}

	if(level.gamemode == "snr")
	{
		level.snr_round_number++;
		display_round_number();
	}

	flag_set( "spawn_zombies");
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

take_tac_nades_when_used()
{
	self endon( "disconnect" );

	while(1)
	{
		self waittill( "grenade_fire", grenade, weaponName, parent );
		tac_nade = self get_player_tactical_grenade();
		if(IsDefined(tac_nade) && weaponName == tac_nade && self GetFractionMaxAmmo(tac_nade) == 0)
		{
			self TakeWeapon(tac_nade);
		}
	}
}

//disable certain box weapons
disable_box_weapons()
{
	//wait for guns to be registered
	wait_network_frame();

	if(IsDefined(level.zombie_weapons["zombie_cymbal_monkey"]))
		level.zombie_weapons["zombie_cymbal_monkey"].is_in_box = false;

	if(IsDefined(level.zombie_weapons["crossbow_explosive_zm"]))
		level.zombie_weapons["crossbow_explosive_zm"].is_in_box = false;

	if(IsDefined(level.zombie_weapons["zombie_black_hole_bomb"]))
		level.zombie_weapons["zombie_black_hole_bomb"].is_in_box = false;
}

turn_power_on()
{
	flag_wait( "all_players_connected" );
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
		zombie_doors[0] open_door();
		zombie_debris[0] clear_debris();
		zombie_debris[1] clear_debris();
		zombie_debris[2] clear_debris();
	}
	else if(level.script == "zombie_cod5_asylum")
	{
		zombie_doors[1] open_door();
	}
	else if(level.script == "zombie_cod5_sumpf")
	{
		zombie_doors[4] open_door();
		zombie_debris[0] clear_debris();
		zombie_debris[1] clear_debris();
	}
	else if(level.script == "zombie_cod5_factory")
	{
		zombie_doors[2] open_door();
		zombie_doors[3] open_door();
	}
	else if(level.script == "zombie_pentagon")
	{
		zombie_doors[0] open_door();
		zombie_doors[1] open_door();
		zombie_debris[0] clear_debris();
	}
	else if(level.script == "zombie_cosmodrome")
	{
		zombie_doors[0] open_door();
		zombie_doors[2] open_door();
		zombie_doors[4] open_door();
		zombie_doors[8] open_door();
	}
	else if(level.script == "zombie_moon")
	{
		level waittill("fade_introblack"); //causes error on fast_restart without a wait
		zombie_airlock_buys = GetEntArray("zombie_airlock_buy", "targetname");
		zombie_airlock_buys[13] maps\zombie_moon_utility::moon_door_opened();
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

increase_round_number()
{
	wait 1;
	level.round_number = 20;
}

increase_zombie_health()
{
	wait 1;

	health = 2000;

	while(1)
	{
		level.zombie_health = health;
		wait 1;
	}
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
	level.zombie_move_speed = 100;
}

increase_zombie_spawn_rate()
{
	wait 1;
	if(level.gamemode == "gg")
	{
		level.zombie_vars["zombie_spawn_delay"] = 2;
	}
	else
	{
		level.zombie_vars["zombie_spawn_delay"] = .5;
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

revive_grace_period()
{
	while(1)
	{
		self waittill("player_revived");
		self.ignoreme = true;
		wait 1;
		self.ignoreme = false;
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

snr_round_win_watcher()
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] SetClientDvar("hud_zombs_remaining_on_game", true);
	}

	zombs = get_enemy_count();

	while(zombs == 0)
	{
		if(flag("round_restarting"))
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				players[i] SetClientDvar("hud_zombs_remaining_on_game", false);
				players[i] SetClientDvar("zombs_remaining", "");
			}

			return;
		}

		wait_network_frame();
		zombs = get_enemy_count();
	}

	flag_clear( "spawn_zombies");

	while(zombs > 0)
	{
		if(flag("round_restarting"))
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				players[i] SetClientDvar("hud_zombs_remaining_on_game", false);
				players[i] SetClientDvar("zombs_remaining", "");
			}

			return;
		}

		if(GetDvarInt("zombs_remaining") != zombs)
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				players[i] SetClientDvar("zombs_remaining", zombs);
			}
		}

		wait_network_frame();
		zombs = get_enemy_count();
	}

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] SetClientDvar("zombs_remaining", "");
	}

	team = undefined;
	for(i=0;i<players.size;i++)
	{
		if(is_player_valid( players[i] ))
		{
			team = players[i].vsteam;
			break;
		}
	}

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
				players[i] SetClientDvar("vs_counter_enemy_num", level.round_wins[team]);
			}
		}

		if(level.round_wins[team] == 3)
		{
			level.vs_winning_team = team;
			level notify( "end_game" );
		}
		else
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				players[i] SetClientDvar("hud_zombs_remaining_on_game", false);
			}

			level thread display_round_won(team);

			wait 2;

			level thread round_restart();
		}
	}
}

display_round_won(team)
{
	flag_wait("all_players_spawned");
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(team == "cdc")
		{
			players[i] thread grief_msg(&"REIMAGINED_CDC_WON");
		}
		else
		{
			players[i] thread grief_msg(&"REIMAGINED_CIA_WON");
		}
	}

	/*round = create_simple_hud();
	round.alignX = "center";
	round.alignY = "bottom";
	round.horzAlign = "user_center";
	round.vertAlign = "user_bottom";
	round.fontscale = 16;
	round.color = ( 0.4, 0, 0 );
	round.x = 0;
	round.y = -300;
	round.alpha = 0;
	if(team == "cdc")
	{
		round SetText( &"REIMAGINED_CDC_WON" );
	}
	else
	{
		round SetText( &"REIMAGINED_CIA_WON" );
	}

	// Fade in white
	round FadeOverTime( 1 );
	round.alpha = 1;

	wait( 1 );

	// Fade to red
	//round FadeOverTime( 2 );
	//round.color = ( 0.21, 0, 0 );

	wait(2);

	wait( 3 );

	if( IsDefined( round ) )
	{
		round FadeOverTime( 1 );
		round.alpha = 0;
	}

	wait( 0.25 );

	wait( 2 );

	round destroy_hud();*/
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
			if(players[j] != players[i])
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

	kills = [];

	while(1)
	{
		kills["cdc"] = 0;
		kills["cia"] = 0;

		players = get_players();
		for(i=0;i<players.size;i++)
		{
			kills[players[i].vsteam] += players[i].kills;
		}

		//display hud counters
		if(kills["cdc"] > 0)
		{
			for(i=0;i<players.size;i++)
			{
				if(players[i].vsteam == "cdc")
				{
					players[i] SetClientDvar("vs_counter_friendly_num", kills["cdc"]);
				}
				else
				{
					players[i] SetClientDvar("vs_counter_enemy_num", kills["cdc"]);
				}
			}
		}

		if(kills["cia"] > 0)
		{
			for(i=0;i<players.size;i++)
			{
				if(players[i].vsteam == "cia")
				{
					players[i] SetClientDvar("vs_counter_friendly_num", kills["cia"]);
				}
				else
				{
					players[i] SetClientDvar("vs_counter_enemy_num", kills["cia"]);
				}
			}
		}

		if(kills["cdc"] >= 250)
		{
			level.vs_winning_team = "cdc";
			level notify( "end_game" );
			return;
		}
		else if(kills["cia"] >= 250)
		{
			level.vs_winning_team = "cia";
			level notify( "end_game" );
			return;
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
		wait 43;

		level.old_music_state = undefined; // need this to be able to play the same music again
		level thread maps\_zombiemode_audio::change_zombie_music( "round_start" );

		wait 2;

		level.round_number++;

		level thread fast_chalk_one_up();

		prev_health = level.zombie_health;

		maps\_zombiemode::ai_calculate_health( level.round_number );

		level.zombie_vars["zombie_spawn_delay"] *= 0.95;

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

			if(is_player_valid(players[i]))
			{
				players[i].score += 500;
				players[i] maps\_zombiemode_score::set_player_score_hud();
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

			kills = [];
			kills["cdc"] = 0;
			kills["cia"] = 0;

			players = get_players();
			for(i=0;i<players.size;i++)
			{
				kills[players[i].vsteam] += players[i].kills;
			}

			if(kills["cdc"] > kills["cia"])
			{
				level.vs_winning_team = "cdc";
			}
			else if(kills["cia"] > kills["cdc"])
			{
				level.vs_winning_team = "cia";
			}
			else
			{
				level.vs_winning_team = undefined;
			}

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

	wait 5;
	self.revive_hud setText( &"GAME_REVIVING" );
	self maps\_laststand::revive_hud_show_n_fade( 5.0 );
	wait 5;
	self maps\_laststand::auto_revive();
}

unlimited_shrieker_and_napalm_spawns()
{
	level endon("end_game");

	while(1)
	{
		level.special_zombie_spawned_this_round = false;

		wait 1;
	}
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
	level.gg_weps[2] = "spas_zm";

	if(!IsSubStr(level.script, "zombie_cod5_"))
	{
		level.gg_weps[3] = "ithaca_zm";
	}
	else
	{
		level.gg_weps[3] = "zombie_shotgun";
	}

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
		level.gg_weps[18] = "sniper_explosive_zm";
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

	if(IsDefined(self.has_meat))
	{
		self.gg_wep_changed = true;
		return;
	}

	primaryWeapons = self GetWeaponsListPrimaries();
	holding_primary = false;
	for(j=0;j<primaryWeapons.size;j++)
	{
		if(self GetCurrentWeapon() == primaryWeapons[j] || self GetCurrentWeapon() == WeaponAltWeaponName(primaryWeapons[j]) || self IsSwitchingWeapons())
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
		self GiveWeapon( weapon_string, 0, self maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( weapon_string ) );
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

	highest_player = players[0];
	second_highest_player = undefined;
	for(i=1;i<players.size;i++)
	{
		if(players[i].gg_wep_num > highest_player.gg_wep_num)
		{
			second_highest_player = highest_player;
			highest_player = players[i];
		}
		else if(!IsDefined(second_highest_player) || players[i].gg_wep_num > second_highest_player.gg_wep_num)
		{
			second_highest_player = players[i];
		}
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
		//dont need to check current player, right side is for other players
		if(players[i] == self)
		{
			continue;
		}

		//show second place player's score for first place player
		if(players[i] == highest_player)
		{
			if(IsDefined(second_highest_player))
			{
				players[i] SetClientDvar("vs_counter_enemy_num", second_highest_wep);
				players[i] SetClientDvar("vs_enemy_playername", second_highest_player);
			}
		}
		else
		{
			players[i] SetClientDvar("vs_counter_enemy_num", highest_wep);
			players[i] SetClientDvar("vs_enemy_playername", highest_player);
		}
	}
}

gungame_weapons_test()
{
	flag_wait("all_players_spawned");

	players = get_players();

	for(i=1;i<level.gg_weps.size;i++)
	{
		wait .1;

		players[0].gg_wep_num++;

		players[0] update_gungame_weapon();
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