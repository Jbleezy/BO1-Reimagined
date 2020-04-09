#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	PrecacheItem( "sickle_knife_zm" );
	PrecacheItem( "zombie_sickle_flourish" );

	if( isDefined( level.sickle_cost ) )
	{
		cost = level.sickle_cost;
	}
	else
	{
		cost = 3000;
	}

	sickle_triggers = GetEntArray( "sickle_upgrade", "targetname" );
	for( i = 0; i < sickle_triggers.size; i++ )
	{
		knife_model = GetEnt( sickle_triggers[i].target, "targetname" );
		knife_model hide();
		sickle_triggers[i] thread sickle_think(cost);
		sickle_triggers[i] SetHintString( &"ZOMBIE_WEAPON_SICKLE_BUY", cost );
		sickle_triggers[i] setCursorHint( "HINT_NOICON" );
		sickle_triggers[i] UseTriggerRequireLookAt();
	}

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill("connecting", player);

		player thread onPlayerSpawned();
	}
}

init_retrievable_knives( name, weapon )
{
	self maps\_weaponobjects::create_ballistic_knife_watcher_zm( name, weapon );

	watcher = maps\_weaponobjects::get_weapon_object_watcher_by_weapon( weapon );

	if( !isDefined( watcher.onSpawnRetrieveTriggers ) )
		watcher.onSpawnRetrieveTriggers = maps\_weaponobjects::on_spawn_retrievable_weapon_object;

	if( !isDefined( watcher.pickUp ) )
		watcher.pickUp = maps\_weaponobjects::pick_up;
}

onPlayerSpawned() // self == player
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("spawned_player");

		wait( 0.05 );

		if ( is_true( level._uses_retrievable_ballisitic_knives ) )
		{
			self init_retrievable_knives( "knife_ballistic_sickle", "knife_ballistic_sickle_zm" );
			self init_retrievable_knives( "knife_ballistic_sickle_upgraded", "knife_ballistic_sickle_upgraded_zm" );
		}
	}
}

sickle_think(cost)
{
	self.melee_wallbuy_name = "sickle_knife_zm";
	self thread maps\_zombiemode_weapons::decide_hide_show_hint();
	self.first_time_triggered = false;

	for( ;; )
	{
		self waittill( "trigger", player );
		// if not first time and they have the weapon give ammo

		if( !is_player_valid( player ) )
		{
			player thread ignore_triggers( 0.5 );
			continue;
		}

		if( player in_revive_trigger() )
		{
			wait( 0.1 );
			continue;
		}

		if( player isThrowingGrenade() )
		{
			wait( 0.1 );
			continue;
		}

		if( player is_drinking() )
		{
			wait( 0.1 );
			continue;
		}

		if( player HasWeapon( "sickle_knife_zm" ) || player HasWeapon( "minigun_zm" ) )
		{
			wait(0.1);
			continue;
		}

 		if( player isSwitchingWeapons() )
 		{
 			wait(0.1);
 			continue;
 		}

		current_weapon = player GetCurrentWeapon();
		if( current_weapon == "minigun_zm" ) //is_placeable_mine( current_weapon ) ||
		{
			wait(0.1);
			continue;
		}

		if (player maps\_laststand::player_is_in_laststand() || is_true( player.intermission ) )
		{
			wait(0.1);
			continue;
		}

//Z2	HasPerk( "specialty_altmelee" ) is returning undefined
//		player_has_sickle = player HasPerk( "specialty_altmelee" );
		player_has_sickle = false;

		if( !player_has_sickle )
		{
			// else make the weapon show and give it
			if( player.score >= cost )
			{
				if( self.first_time_triggered == false )
				{
					model = getent( self.target, "targetname" );
					//					model show();
					model thread sickle_show( player );
					self.first_time_triggered = true;
				}

				player maps\_zombiemode_score::minus_to_player_score( cost );

				bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type weapon",
						player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, cost, "sickle_knife", self.origin );

				player maps\_zombiemode_weapons::check_collector_achievement( "sickle_knife_zm" );

				self thread give_sickle_think(player);
			}
			else
			{
				play_sound_on_ent( "no_purchase" );
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 1 );
			}
		}
	}
}

give_sickle_think(player)
{
	player give_sickle();

	if ( player maps\_laststand::player_is_in_laststand() || is_true( player.intermission ) )
	{
		// if they're in laststand at this point then they won't have gotten the sickle, so don't hide the trigger
		return;
	}

	self SetInvisibleToPlayer( player );
	player._sickle_zm_equipped = 1;
}

give_sickle()
{
	if(self HasPerk("specialty_fastreload"))
	{
		self UnSetPerk("specialty_fastswitch");
	}

	gun = self do_sickle_flourish_begin();
	self maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", "sickle" );

	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );

	if(self HasPerk("specialty_fastreload"))
	{
		self SetPerk("specialty_fastswitch");
	}

	// restore player controls and movement
	self do_sickle_flourish_end( gun );
}

do_sickle_flourish_begin()
{
	self increment_is_drinking();

	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowCrouch( true );
	self AllowProne( false );
	self AllowMelee( false );

	wait( 0.05 );

	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}

	gun = self GetCurrentWeapon();
	weapon = "zombie_sickle_flourish";

	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	return gun;
}

do_sickle_flourish_end( gun )
{
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "zombie_perk_bottle_marathon" );
	assert( gun != "zombie_perk_bottle_nuke" );

	assert( gun != "syrette_sp" );

	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );
	self AllowMelee( true );
	weapon = "zombie_sickle_flourish";

	if ( self HasWeapon( "knife_ballistic_zm" ) )
	{
		ballistic_clip_ammo = self GetWeaponAmmoClip("knife_ballistic_zm");
		ballistic_stock_ammo = self GetWeaponAmmoStock("knife_ballistic_zm");
		
		//self notify( "zmb_lost_knife" );
		self TakeWeapon( "knife_ballistic_zm" );
		self GiveWeapon( "knife_ballistic_sickle_zm" );

		if ( gun == "knife_ballistic_zm" )
		{
			gun = "knife_ballistic_sickle_zm";
		}

		self SetWeaponAmmoClip("knife_ballistic_sickle_zm", ballistic_clip_ammo);
		self SetWeaponAmmoStock("knife_ballistic_sickle_zm", ballistic_stock_ammo);
	}
	else if ( self HasWeapon( "knife_ballistic_upgraded_zm" ) )
	{
		ballistic_clip_ammo = self GetWeaponAmmoClip("knife_ballistic_upgraded_zm");
		ballistic_stock_ammo = self GetWeaponAmmoStock("knife_ballistic_upgraded_zm");

		//self notify( "zmb_lost_knife" );
		self TakeWeapon( "knife_ballistic_upgraded_zm" );
		self GiveWeapon( "knife_ballistic_sickle_upgraded_zm", 0, self maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( "knife_ballistic_sickle_upgraded_zm" ) );

		if ( gun == "knife_ballistic_upgraded_zm" )
		{
			gun = "knife_ballistic_sickle_upgraded_zm";
		}

		self SetWeaponAmmoClip("knife_ballistic_sickle_upgraded_zm", ballistic_clip_ammo);
		self SetWeaponAmmoStock("knife_ballistic_sickle_upgraded_zm", ballistic_stock_ammo);
	}

	if(self HasWeapon(gun) && is_placeable_mine(gun) && self GetWeaponAmmoClip(gun) == 0)
	{
		gun = "none";
	}

	self TakeWeapon(weapon);

	self GiveWeapon( "sickle_knife_zm" );
	self set_player_melee_weapon( "sickle_knife_zm" );

	self TakeWeapon("combat_knife_zm");
	self GiveWeapon("combat_sickle_knife_zm");
	self SetActionSlot(2, "weapon", "combat_sickle_knife_zm");

	if( self HasWeapon("knife_zm") )
	{
		self TakeWeapon( "knife_zm" );
	}

	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() || is_true( self.intermission ) )
	{
		self TakeWeapon(weapon);
		self.lastActiveWeapon = "none"; // this should be handled by laststand.gsc, but then we couldn't FFOTD the fix
		return;
	}

	if( self is_multiple_drinking() )
	{
		self decrement_is_drinking();
		return;
	}
	else if ( gun == "combat_knife_zm" ) // if all they had was the knife, we need to switch them to the sickle
	{
		self SwitchToWeapon( "combat_sickle_knife_zm" );

		// and since it has no raise anim, there'll be no "weapon_change_complete" notify
		self decrement_is_drinking();
		return;
	}
	else if ( gun != "none" ) //&& !is_placeable_mine( gun )
	{
		self SwitchToWeapon( gun );
	}
	else
	{
		// try to switch to first primary weapon
		primaryWeapons = self GetWeaponsListPrimaries();
		if(IsDefined(self.last_held_primary_weapon) && self HasWeapon(self.last_held_primary_weapon))
		{
			self SwitchToWeapon(self.last_held_primary_weapon);
		}
		else if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
	}

	self waittill( "weapon_change_complete" );

	if ( !self maps\_laststand::player_is_in_laststand() && !is_true( self.intermission ) )
	{
		self decrement_is_drinking();
	}
}

sickle_show( player )
{
	player_angles = VectorToAngles( player.origin - self.origin );

	player_yaw = player_angles[1];
	weapon_yaw = self.angles[1];

	yaw_diff = AngleClamp180( player_yaw - weapon_yaw );

	if( yaw_diff > 0 )
	{
		yaw = weapon_yaw - 90;
	}
	else
	{
		yaw = weapon_yaw + 90;
	}

	self.og_origin = self.origin;
	self.origin = self.origin +( AnglesToForward( ( 0, yaw, 0 ) ) * 8 );

	wait( 0.05 );
	self Show();

	play_sound_at_pos( "weapon_show", self.origin, self );

	time = 1;
	self MoveTo( self.og_origin, time );
}
