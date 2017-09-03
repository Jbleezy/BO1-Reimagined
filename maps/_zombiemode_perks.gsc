#include maps\_utility; 
#include common_scripts\utility; 
#include maps\_zombiemode_utility;

init()
{
	place_additionalprimaryweapon_machine();

	// Perks-a-cola vending machine use triggers
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );

	// Pack-A-Punch weapon upgrade machine use triggers
	vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	flag_init("pack_machine_in_use");
	flag_init( "solo_game" );

	if( level.mutators["mutator_noPerks"] )
	{
		for( i = 0; i < vending_triggers.size; i++ )
		{
			vending_triggers[i] disable_trigger();
		}
		for( i = 0; i < vending_weapon_upgrade_trigger.size; i++ )
		{
			vending_weapon_upgrade_trigger[i] disable_trigger();
		}
		return;
	}
	
	if ( vending_triggers.size < 1 )
	{
		return;
	}
	
	if ( vending_weapon_upgrade_trigger.size >= 1 )
	{
		array_thread( vending_weapon_upgrade_trigger, ::vending_weapon_upgrade );;
	}
	
	//Perks machine
	if( !isDefined( level.custom_vending_precaching ) )
	{
		level.custom_vending_precaching = maps\_zombiemode_perks::default_vending_precaching;
	}
	[[ level.custom_vending_precaching ]]();

	if( !isDefined( level.packapunch_timeout ) )
	{
		level.packapunch_timeout = 15;
	}

	set_zombie_var( "zombie_perk_cost",					2000 );
	if( level.mutators["mutator_susceptible"] )
	{
		set_zombie_var( "zombie_perk_juggernaut_health",	80 );
		set_zombie_var( "zombie_perk_juggernaut_health_upgrade",	95 );
	}
	else
	{
		set_zombie_var( "zombie_perk_juggernaut_health",	160 );
		set_zombie_var( "zombie_perk_juggernaut_health_upgrade",	190 );
	}

	array_thread( vending_triggers, ::vending_trigger_think );
	array_thread( vending_triggers, ::electric_perks_dialog );

	level thread turn_doubletap_on();
	if ( is_true( level.zombiemode_using_marathon_perk ) )
	{
		level thread turn_marathon_on();
	}
	if ( is_true( level.zombiemode_using_divetonuke_perk ) )
	{
		level thread turn_divetonuke_on();

		// set the behavior function
		level.zombiemode_divetonuke_perk_func = ::divetonuke_explode;

		// precache the effect
		level._effect["divetonuke_groundhit"] = loadfx("maps/zombie/fx_zmb_phdflopper_exp");

		// tweakable variables
		set_zombie_var( "zombie_perk_divetonuke_radius", 300 ); // WW (01/12/2011): Issue 74726:DLC 2 - Zombies - Cosmodrome - PHD Flopper - Increase the radius on the explosion (Old: 150)
		set_zombie_var( "zombie_perk_divetonuke_min_damage", 1000 );
		set_zombie_var( "zombie_perk_divetonuke_max_damage", 5000 );
	}
	level thread turn_jugger_on();
	level thread turn_revive_on();
	level thread turn_sleight_on();
	
	// WW (02-02-11): Deadshot perk
	if( is_true( level.zombiemode_using_deadshot_perk ) )
	{
		level thread turn_deadshot_on();
	}

	if ( is_true( level.zombiemode_using_additionalprimaryweapon_perk ) )
	{
		level thread turn_additionalprimaryweapon_on();
	}

	level thread turn_PackAPunch_on();

	if ( isdefined( level.quantum_bomb_register_result_func ) )
	{
		[[level.quantum_bomb_register_result_func]]( "give_nearest_perk", ::quantum_bomb_give_nearest_perk_result, 100, ::quantum_bomb_give_nearest_perk_validation );
	}
}


place_additionalprimaryweapon_machine()
{
	if ( !isdefined( level.zombie_additionalprimaryweapon_machine_origin ) )
	{
		return;
	}

	machine = Spawn( "script_model", level.zombie_additionalprimaryweapon_machine_origin );
	machine.angles = level.zombie_additionalprimaryweapon_machine_angles;
	machine setModel( "zombie_vending_three_gun" );
	machine.targetname = "vending_additionalprimaryweapon";

	machine_trigger = Spawn( "trigger_radius_use", level.zombie_additionalprimaryweapon_machine_origin + (0, 0, 30), 0, 20, 70 );
	machine_trigger.targetname = "zombie_vending";
	machine_trigger.target = "vending_additionalprimaryweapon";
	machine_trigger.script_noteworthy = "specialty_additionalprimaryweapon";

	if ( isdefined( level.zombie_additionalprimaryweapon_machine_clip_origin ) )
	{
		machine_clip = spawn( "script_model", level.zombie_additionalprimaryweapon_machine_clip_origin );
		machine_clip.angles = level.zombie_additionalprimaryweapon_machine_clip_angles;
		machine_clip setmodel( "collision_geo_64x64x256" );
		machine_clip Hide();
	}

	if ( isdefined( level.zombie_additionalprimaryweapon_machine_monkey_origins ) )
	{
		machine.target = "vending_additionalprimaryweapon_monkey_structs";
		for ( i = 0; i < level.zombie_additionalprimaryweapon_machine_monkey_origins.size; i++ )
		{
			machine_monkey_struct = SpawnStruct();
			machine_monkey_struct.origin = level.zombie_additionalprimaryweapon_machine_monkey_origins[i];
			machine_monkey_struct.angles = level.zombie_additionalprimaryweapon_machine_monkey_angles;
			machine_monkey_struct.script_int = i + 1;
			machine_monkey_struct.script_notetworthy = "cosmo_monkey_additionalprimaryweapon";
			machine_monkey_struct.targetname = "vending_additionalprimaryweapon_monkey_structs";

			if ( !IsDefined( level.struct_class_names["targetname"][machine_monkey_struct.targetname] ) )
			{
				level.struct_class_names["targetname"][machine_monkey_struct.targetname] = [];
			}
			
			size = level.struct_class_names["targetname"][machine_monkey_struct.targetname].size;
			level.struct_class_names["targetname"][machine_monkey_struct.targetname][size] = machine_monkey_struct;
		}
	}

	level.zombiemode_using_additionalprimaryweapon_perk = true;
}


//
//	Precaches all machines
//
//	"weapon" - 1st person Bottle when drinking
//	icon - Texture for when perk is active
//	model - Perk Machine on/off versions
//	fx - machine on
//	sound
default_vending_precaching()
{
	PrecacheItem( "zombie_perk_bottle_doubletap" );
	PrecacheItem( "zombie_perk_bottle_jugg" );
	PrecacheItem( "zombie_perk_bottle_revive" );
	PrecacheItem( "zombie_perk_bottle_sleight" );
	PrecacheItem( "zombie_knuckle_crack" );

	PrecacheShader( "specialty_doubletap_zombies" );
	
	if ( is_true( level.zombiemode_using_marathon_perk ) )
	{
		PrecacheItem( "zombie_perk_bottle_marathon" );
		PrecacheShader( "specialty_marathon_zombies" );
	}
	
	if ( is_true( level.zombiemode_using_divetonuke_perk ) )
	{
		PrecacheItem( "zombie_perk_bottle_nuke" );
		PrecacheShader( "specialty_divetonuke_zombies" );
	}
	
	if( is_true( level.zombiemode_using_deadshot_perk ) )
	{
		PreCacheItem( "zombie_perk_bottle_deadshot" );	
		PrecacheShader( "specialty_ads_zombies" );
	}
	
	if ( is_true( level.zombiemode_using_additionalprimaryweapon_perk ) )
	{
		PrecacheItem( "zombie_perk_bottle_additionalprimaryweapon" );
		PrecacheShader( "specialty_extraprimaryweapon_zombies" );
	}
	
	PrecacheShader( "specialty_juggernaut_zombies" );
	PrecacheShader( "specialty_quickrevive_zombies" );
	PrecacheShader( "specialty_fastreload_zombies" );
	PrecacheShader( "specialty_juggernaut_zombies_pro" );
	PrecacheShader( "specialty_quickrevive_zombies_pro" );
	PrecacheShader( "specialty_fastreload_zombies_pro" );

	// Minimap icons
	PrecacheShader( "minimap_icon_juggernog" );
	PrecacheShader( "minimap_icon_revive" );
	PrecacheShader( "minimap_icon_reload" );

	PrecacheModel("zombie_vending_doubletap_on");
	if ( is_true( level.zombiemode_using_marathon_perk ) )
	{
		PrecacheModel("zombie_vending_marathon_on");
	}
	if ( is_true( level.zombiemode_using_divetonuke_perk ) )
	{
		PrecacheModel("zombie_vending_nuke_on");
	}
	if ( is_true( level.zombiemode_using_deadshot_perk ) )
	{
		PrecacheModel("zombie_vending_ads_on");
	}
	if ( is_true( level.zombiemode_using_additionalprimaryweapon_perk ) )
	{
		PrecacheModel("zombie_vending_three_gun_on");
	}
	PreCacheModel("zombie_vending_jugg_on");
	PrecacheModel("zombie_vending_revive_on");
	PrecacheModel("zombie_vending_sleight_on");
	PrecacheModel("zombie_vending_packapunch_on");

	PrecacheString( &"ZOMBIE_PERK_DOUBLETAP" );
	if ( is_true( level.zombiemode_using_marathon_perk ) )
	{
		PrecacheString( &"ZOMBIE_PERK_MARATHON" );
	}
	if ( is_true( level.zombiemode_using_divetonuke_perk ) )
	{
		PrecacheString( &"ZOMBIE_PERK_DIVETONUKE" );
	}
	if ( is_true( level.zombiemode_using_additionalprimaryweapon_perk ) )
	{
		PrecacheString( &"ZOMBIE_PERK_ADDITIONALWEAPONPERK" );
	}
	PrecacheString( &"ZOMBIE_PERK_JUGGERNAUT" );
	PrecacheString( &"ZOMBIE_PERK_QUICKREVIVE" );
	PrecacheString( &"ZOMBIE_PERK_FASTRELOAD" );
	PrecacheString( &"ZOMBIE_PERK_PACKAPUNCH" );

	level._effect["doubletap_light"]		= loadfx("misc/fx_zombie_cola_dtap_on");
	if ( is_true( level.zombiemode_using_marathon_perk ) )
	{
		level._effect["marathon_light"]			= loadfx("maps/zombie/fx_zmb_cola_staminup_on");
	}
	if ( is_true( level.zombiemode_using_divetonuke_perk ) )
	{
		level._effect["divetonuke_light"]		= loadfx("misc/fx_zombie_cola_dtap_on");
	}
	if ( is_true( level.zombiemode_using_deadshot_perk ) )
	{
		level._effect["deadshot_light"]		= loadfx("misc/fx_zombie_cola_dtap_on");
	}	
	if ( is_true( level.zombiemode_using_additionalprimaryweapon_perk ) )
	{
		level._effect["additionalprimaryweapon_light"] = loadfx("misc/fx_zombie_cola_arsenal_on");
	}
	level._effect["jugger_light"]			= loadfx("misc/fx_zombie_cola_jugg_on");
	level._effect["revive_light"]			= loadfx("misc/fx_zombie_cola_revive_on");
	level._effect["sleight_light"]			= loadfx("misc/fx_zombie_cola_on");

	level._effect["packapunch_fx"]			= loadfx("maps/zombie/fx_zombie_packapunch");

	// solo revive flicker
	level._effect["revive_light_flicker"] = loadfx("maps/zombie/fx_zmb_cola_revive_flicker");
}

third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine )
{
	forward = anglesToForward( angles );
	interact_pos = origin + (forward*-25);
	PlayFx( level._effect["packapunch_fx"], origin+(0,1,-34), forward );
	
	worldgun = spawn( "script_model", interact_pos );
	worldgun.angles  = self.angles;
	worldgun setModel( GetWeaponModel( current_weapon ) );
	worldgun useweaponhidetags( current_weapon );
	worldgun rotateto( angles+(0,90,0), 0.35, 0, 0 );

	offsetdw = ( 3, 3, 3 );
	worldgundw = undefined;
	if ( maps\_zombiemode_weapons::weapon_is_dual_wield( current_weapon ) )
	{
		worldgundw = spawn( "script_model", interact_pos + offsetdw );
		worldgundw.angles  = self.angles;

		worldgundw setModel( maps\_zombiemode_weapons::get_left_hand_weapon_model_name( current_weapon ) );
		worldgundw useweaponhidetags( current_weapon );
		worldgundw rotateto( angles+(0,90,0), 0.35, 0, 0 );
	}

	wait( 0.5 );

	worldgun moveto( origin, 0.5, 0, 0 );
	if ( isdefined( worldgundw ) )
	{
		worldgundw moveto( origin + offsetdw, 0.5, 0, 0 );
	}

	self playsound( "zmb_perks_packa_upgrade" );
	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles+(179, 0, 0), 0.25, 0, 0 );
	}
	wait( 0.35 );

	worldgun delete();
	if ( isdefined( worldgundw ) )
	{
		worldgundw delete();
	}

	wait( 3 );

	self playsound( "zmb_perks_packa_ready" );

	worldgun = spawn( "script_model", origin );
	worldgun.angles  = angles+(0,90,0);
	worldgun setModel( GetWeaponModel( level.zombie_weapons[current_weapon].upgrade_name ) );
	worldgun useweaponhidetags( level.zombie_weapons[current_weapon].upgrade_name );
	worldgun moveto( interact_pos, 0.5, 0, 0 );

	worldgundw = undefined;
	if ( maps\_zombiemode_weapons::weapon_is_dual_wield( level.zombie_weapons[current_weapon].upgrade_name ) )
	{
		worldgundw = spawn( "script_model", origin + offsetdw );
		worldgundw.angles  = angles+(0,90,0);

		worldgundw setModel( maps\_zombiemode_weapons::get_left_hand_weapon_model_name( level.zombie_weapons[current_weapon].upgrade_name ) );
		worldgundw useweaponhidetags( level.zombie_weapons[current_weapon].upgrade_name );
		worldgundw moveto( interact_pos + offsetdw, 0.5, 0, 0 );
	}

	if( isDefined( perk_machine.wait_flag ) )
	{
		perk_machine.wait_flag rotateto( perk_machine.wait_flag.angles-(179, 0, 0), 0.25, 0, 0 );
	}

	wait( 0.5 );

	worldgun moveto( origin, level.packapunch_timeout, 0, 0);
	if ( isdefined( worldgundw ) )
	{
		worldgundw moveto( origin + offsetdw, level.packapunch_timeout, 0, 0);
	}

	worldgun.worldgundw = worldgundw;
	return worldgun;
}


vending_machine_trigger_think()
{
	self endon("death");
	
	while(1)
	{
		players = get_players();
		for(i = 0; i < players.size; i ++)
		{
			current_weapon = players[i] getCurrentWeapon();
			primaryWeapons = players[i] GetWeaponsListPrimaries();
			if ( players[i] hacker_active() )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else if( !players[i] maps\_zombiemode_weapons::can_buy_weapon() || players[i] maps\_laststand::player_is_in_laststand() || is_true( players[i].intermission ) || players[i] isThrowingGrenade() )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else if( is_true(level.pap_moving)) //can't use the pap machine while it's being lowered or raised
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else if( players[i] isSwitchingWeapons() )
	 		{
	 			self SetInvisibleToPlayer( players[i], true );
	 		}
	 		else if( flag("pack_machine_in_use") && IsDefined(self.user) && self.user != players[i] )
	 		{
	 			self SetInvisibleToPlayer( players[i], true );
	 		}
			else if( flag("pack_machine_in_use") && is_melee_weapon(current_weapon) && primaryWeapons.size > 0 )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else if(!flag("pack_machine_in_use") && is_melee_weapon(current_weapon))
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else if ( !flag("pack_machine_in_use") && !IsDefined( level.zombie_include_weapons[current_weapon] ) )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else if ( !flag("pack_machine_in_use") && players[i] maps\_zombiemode_weapons::is_weapon_upgraded( current_weapon ) )
			{
				self SetInvisibleToPlayer( players[i], true );
			}
			else
			{
				self SetInvisibleToPlayer( players[i], false );
			}	
		}
		wait(0.05);
	}
}

//
//	Pack-A-Punch Weapon Upgrade
//
vending_weapon_upgrade()
{
	perk_machine = GetEnt( self.target, "targetname" );
	perk_machine_sound = GetEntarray ( "perksacola", "targetname");
	packa_rollers = spawn("script_origin", self.origin);
	packa_timer = spawn("script_origin", self.origin);
	packa_rollers LinkTo( self );
	packa_timer LinkTo( self );
	
	if( isDefined( perk_machine.target ) )
	{
		perk_machine.wait_flag = GetEnt( perk_machine.target, "targetname" );
	}

	self UseTriggerRequireLookAt();
	self SetHintString( &"ZOMBIE_NEED_POWER" );
	self SetCursorHint( "HINT_NOICON" );
	
	level waittill("Pack_A_Punch_on");
	
	self thread vending_machine_trigger_think();
	
	//self thread maps\_zombiemode_weapons::decide_hide_show_hint();
	
	perk_machine playloopsound("zmb_perks_packa_loop");

	self thread vending_weapon_upgrade_cost();
	
	for( ;; )
	{
		self waittill( "trigger", player );		
				
		index = maps\_zombiemode_weapons::get_player_index(player);	
		plr = "zmb_vox_plr_" + index + "_";
		current_weapon = player getCurrentWeapon();
		
		if ( "microwavegun_zm" == current_weapon )
		{
			current_weapon = "microwavegundw_zm";
		}

		if( !player maps\_zombiemode_weapons::can_buy_weapon() ||
			player maps\_laststand::player_is_in_laststand() ||
			is_true( player.intermission ) ||
			player isThrowingGrenade() ||
			player maps\_zombiemode_weapons::is_weapon_upgraded( current_weapon ) )
		{
			wait( 0.1 );
			continue;
		}
		
		if( is_true(level.pap_moving)) //can't use the pap machine while it's being lowered or raised
		{
			continue;
		}
		
 		if( player isSwitchingWeapons() )
 		{
 			wait(0.1);
 			continue;
 		}

		if ( !IsDefined( level.zombie_include_weapons[current_weapon] ) )
		{
			continue;
		}

		if( is_melee_weapon(current_weapon) )
		{
			wait(0.1);
 			continue;
		}

		if ( player.score < self.cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("deny");
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
			continue;
		}
		
		self.user = player;
		flag_set("pack_machine_in_use");
		
		player maps\_zombiemode_score::minus_to_player_score( self.cost ); 
		sound = "evt_bottle_dispense";
		playsoundatposition(sound, self.origin);
		
		//TUEY TODO: Move this to a general init string for perk audio later on
		self thread maps\_zombiemode_audio::play_jingle_or_stinger("mus_perks_packa_sting");
		player maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", "upgrade_wait" );
		
		origin = self.origin;
		angles = self.angles;
		
		if( isDefined(perk_machine))
		{
			origin = perk_machine.origin+(0,0,35);
			angles = perk_machine.angles+(0,90,0);
		}
		
		self SetHintString("");
		self disable_trigger();
		
		player thread do_knuckle_crack();

		// Remember what weapon we have.  This is needed to check unique weapon counts.
		self.current_weapon = current_weapon;
											
		weaponmodel = player third_person_weapon_upgrade( current_weapon, origin, angles, packa_rollers, perk_machine );
		
		self enable_trigger();
		self SetHintString( &"ZOMBIE_GET_UPGRADED" );
		//self setvisibletoplayer( player );
		
		self thread wait_for_player_to_take( player, current_weapon, packa_timer );
		self thread wait_for_timeout( current_weapon, packa_timer );
		
		self waittill_either( "pap_timeout", "pap_taken" );
		
		self.current_weapon = "";
		if ( isdefined( weaponmodel.worldgundw ) )
		{
			weaponmodel.worldgundw delete();
		}
		weaponmodel delete();
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );
		self setvisibletoall();
		flag_clear("pack_machine_in_use");
		self.user = undefined;

	}
}


vending_weapon_upgrade_cost()
{
	while ( 1 )
	{
		self.cost = 5000;
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );

		level waittill( "powerup bonfire sale" );

		self.cost = 1000;
		self SetHintString( &"ZOMBIE_PERK_PACKAPUNCH", self.cost );

		level waittill( "bonfire_sale_off" );
	}
}


//	
//
wait_for_player_to_take( player, weapon, packa_timer )
{
	AssertEx( IsDefined( level.zombie_weapons[weapon] ), "wait_for_player_to_take: weapon does not exist" );
	AssertEx( IsDefined( level.zombie_weapons[weapon].upgrade_name ), "wait_for_player_to_take: upgrade_weapon does not exist" );
	
	upgrade_weapon = level.zombie_weapons[weapon].upgrade_name;
	
	self endon( "pap_timeout" );
	while( true )
	{
		packa_timer playloopsound( "zmb_perks_packa_ticktock" );
		self waittill( "trigger", trigger_player );
		packa_timer stoploopsound(.05);
		if( trigger_player == player ) 
		{
			current_weapon = player GetCurrentWeapon();
/#
if ( "none" == current_weapon )
{
	iprintlnbold( "WEAPON IS NONE, PACKAPUNCH RETRIEVAL DENIED" );
}
#/
			if( is_player_valid( player ) && !player is_drinking() && !is_placeable_mine( current_weapon ) && !is_equipment( current_weapon ) && "syrette_sp" != current_weapon && "none" != current_weapon && !player hacker_active())
			{
				self notify( "pap_taken" );
				player notify( "pap_taken" );
				player.pap_used = true;

				weapon_limit = 2;
				if ( player HasPerk( "specialty_additionalprimaryweapon" ) )
				{
					weapon_limit = 3;
				}

				primaries = player GetWeaponsListPrimaries();
				if( isDefined( primaries ) && primaries.size >= weapon_limit )
				{
					player maps\_zombiemode_weapons::weapon_give( upgrade_weapon );
				}
				else
				{
					player GiveWeapon( upgrade_weapon, 0, player maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( upgrade_weapon ) );
					player GiveStartAmmo( upgrade_weapon );
				}
				
				player SwitchToWeapon( upgrade_weapon );
				player maps\_zombiemode_weapons::play_weapon_vo(upgrade_weapon);
				return;
			}
		}
		wait( 0.05 );
	}
}


//	Waiting for the weapon to be taken
//
wait_for_timeout( weapon, packa_timer )
{
	self endon( "pap_taken" );
	
	wait( level.packapunch_timeout );
	
	self notify( "pap_timeout" );
	packa_timer stoploopsound(.05);
	packa_timer playsound( "zmb_perks_packa_deny" );

	maps\_zombiemode_weapons::unacquire_weapon_toggle( weapon );
}


//	Weapon has been inserted, crack knuckles while waiting
//
do_knuckle_crack()
{
	has_fastswitch = self HasPerk("specialty_fastswitch");

	if(has_fastswitch)
	{
		self UnSetPerk("specialty_fastswitch");
	}

	gun = self upgrade_knuckle_crack_begin();
	
	self waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );

	if(has_fastswitch && !self maps\_laststand::player_is_in_laststand() && !is_true(self.intermission) && self.sessionstate != "spectator")
	{
		self SetPerk("specialty_fastswitch");
	}
	
	self upgrade_knuckle_crack_end( gun );
}


//	Switch to the knuckles
//
upgrade_knuckle_crack_begin()
{
	self increment_is_drinking();
	
	self AllowLean( false );
	self AllowAds( false );
	self AllowSprint( false );
	self AllowCrouch( true );
	self AllowProne( false );
	self AllowMelee( false );
	
	if ( self GetStance() == "prone" )
	{
		self SetStance( "crouch" );
	}

	primaries = self GetWeaponsListPrimaries();

	gun = self GetCurrentWeapon();
	weapon = "zombie_knuckle_crack";
	
	if ( gun != "none" && !is_placeable_mine( gun ) && !is_equipment( gun ) )
	{
		self notify( "zmb_lost_knife" );
		self TakeWeapon( gun );
	}
	else
	{
		return;
	}

	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	return gun;
}

//	Anim has ended, now switch back to something
//
upgrade_knuckle_crack_end( gun )
{
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "zombie_perk_bottle_marathon" );
	assert( gun != "zombie_perk_bottle_nuke" );
	assert( gun != "zombie_perk_bottle_deadshot" );
	assert( gun != "zombie_perk_bottle_additionalprimaryweapon" );
	assert( gun != "syrette_sp" );

	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );		
	self AllowMelee( true );
	weapon = "zombie_knuckle_crack";

	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() || is_true( self.intermission ) )
	{
		self TakeWeapon(weapon);
		return;
	}

	self decrement_is_drinking();

	self TakeWeapon(weapon);
	primaries = self GetWeaponsListPrimaries();
	if( self is_drinking() )
	{
		return;
	}
	else if( isDefined( primaries ) && primaries.size > 0 )
	{
		self SwitchToWeapon( primaries[0] );
	}
	else
	{
		self SwitchToWeapon( level.laststandpistol );
	}
}

// PI_CHANGE_BEGIN
//	NOTE:  In the .map, you'll have to make sure that each Pack-A-Punch machine has a unique targetname
turn_PackAPunch_on()
{
	level waittill("Pack_A_Punch_on");

	vending_weapon_upgrade_trigger = GetEntArray("zombie_vending_upgrade", "targetname");
	for(i=0; i<vending_weapon_upgrade_trigger.size; i++ )
	{
		perk = getent(vending_weapon_upgrade_trigger[i].target, "targetname");
		if(isDefined(perk))
		{
			perk thread activate_PackAPunch();
		}
	}
}

activate_PackAPunch()
{
	self setmodel("zombie_vending_packapunch_on");
	self playsound("zmb_perks_power_on");
	self vibrate((0,-100,0), 0.3, 0.4, 3);
	/*
	self.flag = spawn( "script_model", machine GetTagOrigin( "tag_flag" ) );
	self.angles = machine GetTagAngles( "tag_flag" );
	self.flag setModel( "zombie_sign_please_wait" );
	self.flag linkto( machine );
	self.flag.origin = (0, 40, 40);
	self.flag.angles = (0, 0, 0);
	*/
	timer = 0;
	duration = 0.05;

	level notify( "Carpenter_On" );
}
// PI_CHANGE_END



//############################################################################
//		P E R K   M A C H I N E S
//############################################################################

//
//	Threads to turn the machines to their ON state.
//


// Speed Cola / Sleight of Hand
//
turn_sleight_on()
{
	machine = getentarray("vending_sleight", "targetname");
	
	level waittill("sleight_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_sleight_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("zmb_perks_power_on");
		machine[i] thread perk_fx( "sleight_light" );
	}

	level notify( "specialty_fastreload_power_on" );
}

// Quick Revive
//
turn_revive_on()
{
	machine = getentarray("vending_revive", "targetname");
	machine_model = undefined;
	machine_clip = undefined;
	
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	if ( players.size == 1 )
	{
		for( i = 0; i < machine.size; i++ )
		{
			if(IsDefined(machine[i].script_noteworthy) && machine[i].script_noteworthy == "clip")
			{
				machine_clip = machine[i];
			}
			else // then the model
			{	
				machine[i] setmodel("zombie_vending_revive_on");
				machine_model = machine[i];
			}
		}
		wait_network_frame();
		if ( isdefined( machine_model ) )
		{
			machine_model thread revive_solo_fx(machine_clip);
		}
	}
	else
	{
		level waittill("revive_on");

		for( i = 0; i < machine.size; i++ )
		{
			if(IsDefined(machine[i].classname) && machine[i].classname == "script_model")
			{
				machine[i] setmodel("zombie_vending_revive_on");
				machine[i] playsound("zmb_perks_power_on");
				machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
				machine[i] thread perk_fx( "revive_light" );
			}
		}
		
		level notify( "specialty_quickrevive_power_on" );
	}
}


revive_solo_fx(machine_clip)
{
	flag_init( "solo_revive" );

	self.fx = Spawn( "script_model", self.origin );
	self.fx.angles = self.angles;
	self.fx SetModel( "tag_origin" );
	self.fx LinkTo(self);

	playfxontag( level._effect[ "revive_light" ], self.fx, "tag_origin" );
	playfxontag( level._effect[ "revive_light_flicker" ], self.fx, "tag_origin" );

	flag_wait( "solo_revive" );

	if ( isdefined( level.revive_solo_fx_func ) )
	{
		level thread [[ level.revive_solo_fx_func ]]();
	}
	
	//DCS: make revive model fly away like a magic box.
	//self playsound("zmb_laugh_child");

	wait(2.0);

	self playsound("zmb_box_move");

	playsoundatposition ("zmb_whoosh", self.origin );
	//playsoundatposition ("zmb_vox_ann_magicbox", self.origin );

	self moveto(self.origin + (0,0,40),3);

	if( isDefined( level.custom_vibrate_func ) )
	{
		[[ level.custom_vibrate_func ]]( self );
	}
	else
	{
	   direction = self.origin;
	   direction = (direction[1], direction[0], 0);
	   
	   if(direction[1] < 0 || (direction[0] > 0 && direction[1] > 0))
	   {
            direction = (direction[0], direction[1] * -1, 0);
       }
       else if(direction[0] < 0)
       {
            direction = (direction[0] * -1, direction[1], 0);
       }
	   
        self Vibrate( direction, 10, 0.5, 5);
	}
	
	self waittill("movedone");
	PlayFX(level._effect["poltergeist"], self.origin);
	playsoundatposition ("zmb_box_poof", self.origin);

    level clientNotify( "drb" );

	//self setmodel("zombie_vending_revive");
	self.fx Unlink();
	self.fx delete();	
	self Delete();

	// DCS: remove the clip.
	machine_clip trigger_off();
	machine_clip ConnectPaths();	
	machine_clip Delete();
}

// Jugger-nog / Juggernaut
//
turn_jugger_on()
{
	machine = getentarray("vending_jugg", "targetname");
	
	level waittill("juggernog_on");

	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_jugg_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("zmb_perks_power_on");
		machine[i] thread perk_fx( "jugger_light" );
	}
	level notify( "specialty_armorvest_power_on" );
	
}

// Double-Tap
//
turn_doubletap_on()
{
	machine = getentarray("vending_doubletap", "targetname");
	level waittill("doubletap_on");
	
	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_doubletap_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("zmb_perks_power_on");
		machine[i] thread perk_fx( "doubletap_light" );
	}
	level notify( "specialty_rof_power_on" );
}

// Marathon
//
turn_marathon_on()
{
	machine = getentarray("vending_marathon", "targetname");
	level waittill("marathon_on");
	
	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_marathon_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("zmb_perks_power_on");
		machine[i] thread perk_fx( "marathon_light" );
	}
	level notify( "specialty_longersprint_power_on" );
}

// Divetonuke
//
turn_divetonuke_on()
{
	machine = getentarray("vending_divetonuke", "targetname");
	level waittill("divetonuke_on");
	
	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_nuke_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("zmb_perks_power_on");
		machine[i] thread perk_fx( "divetonuke_light" );
	}
	level notify( "specialty_flakjacket_power_on" );
}

divetonuke_explode( attacker, origin )
{
	// tweakable vars
	radius = level.zombie_vars["zombie_perk_divetonuke_radius"];
	min_damage = level.zombie_vars["zombie_perk_divetonuke_min_damage"];
	max_damage = level.zombie_vars["zombie_perk_divetonuke_max_damage"];

	// radius damage
	RadiusDamage( origin, radius, max_damage, min_damage, attacker, "MOD_GRENADE_SPLASH" );

	// play fx
	PlayFx( level._effect["divetonuke_groundhit"], origin );

	// play sound
	attacker playsound("zmb_phdflop_explo");
	
	// WW (01/12/11): start clientsided effects - These client flags are defined in _zombiemode.gsc & _zombiemode.csc
	// Used for zombie_dive2nuke_visionset() in _zombiemode.csc
	attacker SetClientFlag( level._ZOMBIE_PLAYER_FLAG_DIVE2NUKE_VISION );
	wait_network_frame();
	wait_network_frame();
	attacker ClearClientFlag( level._ZOMBIE_PLAYER_FLAG_DIVE2NUKE_VISION );
}

// WW (02-02-11): Deadshot
turn_deadshot_on()
{
	machine = getentarray("vending_deadshot", "targetname");
	level waittill("deadshot_on");
	
	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_ads_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("zmb_perks_power_on");
		machine[i] thread perk_fx( "deadshot_light" );
	}
	level notify( "specialty_deadshot_power_on" );
}

// additionalprimaryweapon
//
turn_additionalprimaryweapon_on()
{
	machine = getentarray("vending_additionalprimaryweapon", "targetname");
//	level waittill("additionalprimaryweapon_on");
	if ( "zombie_cod5_prototype" != level.script && "zombie_cod5_sumpf" != level.script )
	{
		flag_wait( "power_on" );
	}
	wait ( 3 );
	
	for( i = 0; i < machine.size; i++ )
	{
		machine[i] setmodel("zombie_vending_three_gun_on");
		machine[i] vibrate((0,-100,0), 0.3, 0.4, 3);
		machine[i] playsound("zmb_perks_power_on");
		machine[i] thread perk_fx( "additionalprimaryweapon_light" );
	}
	level notify( "specialty_additionalprimaryweapon_power_on" );
}

//	
//
perk_fx( fx )
{
	wait(3);
	playfxontag( level._effect[ fx ], self, "tag_origin" );
}




electric_perks_dialog()
{
	//TODO  TEMP Disable Revive in Solo games
	flag_wait( "all_players_connected" );
	players = GetPlayers();
	if ( players.size == 1 )
	{
		return;
	}
	
	self endon ("warning_dialog");
	level endon("switch_flipped");
	timer =0;
	while(1)
	{
		wait(0.5);
		players = get_players();
		for(i = 0; i < players.size; i++)
		{		
			dist = distancesquared(players[i].origin, self.origin );
			if(dist > 70*70)
			{
				timer = 0;
				continue;
			}
			if(dist < 70*70 && timer < 3)
			{
				wait(0.5);
				timer ++;
			}
			if(dist < 70*70 && timer == 3)
			{
				
				players[i] thread do_player_vo("vox_start", 5);	
				wait(3);				
				self notify ("warning_dialog");
				/#
				iprintlnbold("warning_given");
				#/
			}
		}
	}
}


//
//
vending_trigger_think()
{
	//self thread turn_cola_off();
	perk = self.script_noteworthy;
	solo = false;
	flag_init( "_start_zm_pistol_rank" );
	
	//TODO  TEMP Disable Revive in Solo games
	if ( IsDefined(perk) && 
		(perk == "specialty_quickrevive" || perk == "specialty_quickrevive_upgrade") )
	{
		flag_wait( "all_players_connected" );
		players = GetPlayers();
		if ( players.size == 1 )
		{
			solo = true;
			flag_set( "solo_game" );
			level.solo_lives_given = 0;
			players[0].lives = 0;
			level maps\_zombiemode::zombiemode_solo_last_stand_pistol();
		}
	}
	
	flag_set( "_start_zm_pistol_rank" );

	if ( !solo )
	{
		self SetHintString( &"ZOMBIE_NEED_POWER" );
	}

	self SetCursorHint( "HINT_NOICON" );
	self UseTriggerRequireLookAt();

	cost = level.zombie_vars["zombie_perk_cost"];
	switch( perk )
	{
	case "specialty_armorvest_upgrade":
	case "specialty_armorvest":
		cost = 2500;
		break;

	case "specialty_quickrevive_upgrade":
	case "specialty_quickrevive":
		if( solo )
		{
			cost = 500;
		}
		else
		{
			cost = 1500;
		}
		break;

	case "specialty_fastreload_upgrade":
	case "specialty_fastreload":
		cost = 3000;
		break;

	case "specialty_rof_upgrade":
	case "specialty_rof":
		cost = 2000;
		break;
		
	case "specialty_longersprint_upgrade":
	case "specialty_longersprint":
		cost = 2000;
		break;
		
	case "specialty_flakjacket_upgrade":
	case "specialty_flakjacket":
		cost = 2000;
		break;
		
	case "specialty_deadshot_upgrade":
	case "specialty_deadshot":
		cost = 1500; // WW (02-03-11): Setting this low at first so more people buy it and try it (TEMP)
		break;
		
	case "specialty_additionalprimaryweapon_upgrade":
	case "specialty_additionalprimaryweapon":
		cost = 4000;
		break;

	}

	self.cost = cost;

	if ( !solo || level.script == "zombie_cod5_sumpf" ) //fix for being able to buy Quick Revive on solo on Shi No Numa before the perk-a-cola spawn animation is complete
	{
		notify_name = perk + "_power_on";
		level waittill( notify_name );
	}

	if(!IsDefined(level._perkmachinenetworkchoke))
	{
		level._perkmachinenetworkchoke = 0;
	}
	else
	{
		level._perkmachinenetworkchoke ++;
	}
	
	for(i = 0; i < level._perkmachinenetworkchoke; i ++)
	{
		wait_network_frame();
	}
	
	//Turn on music timer
	self thread maps\_zombiemode_audio::perks_a_cola_jingle_timer();
	
	perk_hum = spawn("script_origin", self.origin);
	perk_hum playloopsound("zmb_perks_machine_loop");

	self thread check_player_has_perk(perk);
	
	switch( perk )
	{
	case "specialty_armorvest_upgrade":
	case "specialty_armorvest":
		self SetHintString( &"ZOMBIE_PERK_JUGGERNAUT", cost );
		break;

	case "specialty_quickrevive_upgrade":
	case "specialty_quickrevive":
		/*if( solo )
		{
			self SetHintString( &"ZOMBIE_PERK_QUICKREVIVE_SOLO", cost );
		}
		else
		{
			self SetHintString( &"ZOMBIE_PERK_QUICKREVIVE", cost );
		}*/
		self SetHintString("Hold ^3[{+activate}]^7 to buy Quick Revive [Cost: &&1]", cost);
		break;

	case "specialty_fastreload_upgrade":
	case "specialty_fastreload":
		self SetHintString( &"ZOMBIE_PERK_FASTRELOAD", cost );
		break;

	case "specialty_rof_upgrade":
	case "specialty_rof":
		self SetHintString( &"ZOMBIE_PERK_DOUBLETAP", cost );
		break;
		
	case "specialty_longersprint_upgrade":
	case "specialty_longersprint":
		self SetHintString( &"ZOMBIE_PERK_MARATHON", cost );
		break;
		
	case "specialty_flakjacket_upgrade":
	case "specialty_flakjacket":
		self SetHintString( &"ZOMBIE_PERK_DIVETONUKE", cost );
		break;
		
	case "specialty_deadshot_upgrade":
	case "specialty_deadshot":
		self SetHintString( &"ZOMBIE_PERK_DEADSHOT", cost );
		break;
		
	case "specialty_additionalprimaryweapon_upgrade":
	case "specialty_additionalprimaryweapon":
		self SetHintString( &"ZOMBIE_PERK_ADDITIONALPRIMARYWEAPON", cost );
		break;

	default:
		self SetHintString( perk + " Cost: " + level.zombie_vars["zombie_perk_cost"] );
	}

	for( ;; )
	{
		self waittill( "trigger", player );
		
		index = maps\_zombiemode_weapons::get_player_index(player);
		
		if (player maps\_laststand::player_is_in_laststand() || is_true( player.intermission ) )
		{
			continue;
		}

		if(player in_revive_trigger())
		{
			continue;
		}
		
		if( player isThrowingGrenade() )
		{
			wait( 0.1 );
			continue;
		}
		
 		if( player isSwitchingWeapons() )
 		{
 			wait(0.1);
 			continue;
 		}

		if( player is_drinking() )
		{
			wait( 0.1 );
			continue;
		}

		if ( player HasPerk( perk ) )
		{
			cheat = false;

			/#
			if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
			{
				cheat = true;
			}
			#/
			cheat = true;

			if ( cheat != true )
			{
				//player iprintln( "Already using Perk: " + perk );
				self playsound("deny");
				player maps\_zombiemode_audio::create_and_play_dialog( "general", "perk_deny", undefined, 1 );

				
				continue;
			}
		}

		if ( player.score < cost )
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("evt_perk_deny");
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "perk_deny", undefined, 0 );
			continue;
		}

		if ( player.num_perks >= 4 && !player._retain_perks )
		{
			//player iprintln( "Too many perks already to buy Perk: " + perk );
			self playsound("evt_perk_deny");
			// COLLIN: do we have a VO that would work for this? if not we'll leave it at just the deny sound
			player maps\_zombiemode_audio::create_and_play_dialog( "general", "sigh" );
			continue;
		}

		sound = "evt_bottle_dispense";
		playsoundatposition(sound, self.origin);
		player maps\_zombiemode_score::minus_to_player_score( cost );

		player.perk_purchased = perk;

		//if( player unlocked_perk_upgrade( perk ) )
		//{
		//	perk += "_upgrade";
		//}

		///bottle_dispense
		switch( perk )
		{
		case "specialty_armorvest_upgrade":
		case "specialty_armorvest":
			sound = "mus_perks_jugger_sting";
			break;

		case "specialty_quickrevive_upgrade":
		case "specialty_quickrevive":
			sound = "mus_perks_revive_sting";
			break;

		case "specialty_fastreload_upgrade":
		case "specialty_fastreload":
			sound = "mus_perks_speed_sting";
			break;

		case "specialty_rof_upgrade":
		case "specialty_rof":
			sound = "mus_perks_doubletap_sting";
			break;
			
		case "specialty_longersprint_upgrade":
		case "specialty_longersprint":
			sound = "mus_perks_phd_sting";
			break;
			
		case "specialty_flakjacket_upgrade":
		case "specialty_flakjacket":
			sound = "mus_perks_stamin_sting";
			break;
			
		case "specialty_deadshot_upgrade":
		case "specialty_deadshot":
			sound = "mus_perks_jugger_sting"; // WW TODO: Place new deadshot stinger
			break;
			
		case "specialty_additionalprimaryweapon_upgrade":
		case "specialty_additionalprimaryweapon":
			sound = "mus_perks_mulekick_sting";
			break;

		default:
			sound = "mus_perks_jugger_sting";
			break;
		}
		
		self thread maps\_zombiemode_audio::play_jingle_or_stinger (self.script_label);
	
		//		self waittill("sound_done");

		
		// do the drink animation
		has_fastswitch = player HasPerk("specialty_fastswitch");
		if(has_fastswitch)
		{
			player UnSetPerk("specialty_fastswitch");
		}
		gun = player perk_give_bottle_begin( perk );
		self thread give_perk_think(player, gun, perk, cost, has_fastswitch);
	}
}

give_perk_think(player, gun, perk, cost, has_fastswitch)
{
	player waittill_any( "fake_death", "death", "player_downed", "weapon_change_complete" );

	// restore player controls and movement
	player perk_give_bottle_end( gun, perk, has_fastswitch );
	
	// TODO: race condition?
	if ( player maps\_laststand::player_is_in_laststand() || is_true( player.intermission ) )
	{
		if(perk == "specialty_fastreload")
		{
			player UnSetPerk("specialty_fastswitch");
		}
		return;
	}

	if ( isDefined( level.perk_bought_func ) )
	{
		player [[ level.perk_bought_func ]]( perk );
	}

	player.perk_purchased = undefined;

	player give_perk( perk, true );

	//player iprintln( "Bought Perk: " + perk );
	bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type perk",
		player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, cost, perk, self.origin );
}

// ww: tracks the player's lives in solo, once a life is used then the revive trigger is moved back in to position
solo_revive_buy_trigger_move( revive_trigger_noteworthy )
{
	self endon( "death" );
	
	revive_perk_trigger = GetEnt( revive_trigger_noteworthy, "script_noteworthy" );
	
	revive_perk_trigger trigger_off();
	
	if( level.solo_lives_given >= 3 )
	{
		if(IsDefined(level._solo_revive_machine_expire_func))
		{
			revive_perk_trigger [[level._solo_revive_machine_expire_func]]();
		}

		return;
	}
	
	while( self.lives > 0 )
	{
		wait( 0.1 );
	}
	
	revive_perk_trigger trigger_on();
}

unlocked_perk_upgrade( perk )
{
	ch_ref = string(tablelookup( "mp/challengeTable_zmPerk.csv", 12, perk, 7 ));
	ch_max = int(tablelookup( "mp/challengeTable_zmPerk.csv", 12, perk, 4 ));
	ch_progress = self getdstat( "challengeStats", ch_ref, "challengeProgress" );
	
	if( ch_progress >= ch_max )
	{
		return true;
	}
	return false;
}

give_perk( perk, bought )
{
	self SetPerk( perk );
	self.num_perks++;

	perk_str = perk + "_stop";

	if ( is_true( bought ) )
	{
		//AUDIO: Ayers - Sending Perk Name over to audio common script to play VOX
		self thread maps\_zombiemode_audio::perk_vox( perk );
		//self setblur( 4, 0.1 );
		//wait(0.1);
		//self setblur(0, 0.1);
		//earthquake (0.4, 0.2, self.origin, 100);

		self notify( "perk_bought", perk );
	}

	if(perk == "specialty_armorvest")
	{
		self.preMaxHealth = self.maxhealth;
		self SetMaxHealth( level.zombie_vars["zombie_perk_juggernaut_health"] );
	}
	else if(perk == "specialty_armorvest_upgrade")
	{
		self.preMaxHealth = self.maxhealth;
		self SetMaxHealth( level.zombie_vars["zombie_perk_juggernaut_health_upgrade"] );
	}

	if(perk == "specialty_fastreload" && !self HasPerk("specialty_fastswitch"))
	{
		self SetPerk("specialty_fastswitch");
	}
	
	// WW (02-03-11): Deadshot csc call
	if( perk == "specialty_deadshot" )
	{
		self SetClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
		perk_str = perk + "_stop";
		//self thread move_faster_while_ads(perk_str);
	}
	else if( perk == "specialty_deadshot_upgrade" )
	{
		self SetClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
	}

	// quick revive in solo gives an extra life
	players = getplayers();
	if ( players.size == 1 && perk == "specialty_quickrevive" )
	{
		self.lives = 1;
		
		level.solo_lives_given++;
		
		if( level.solo_lives_given >= 3 )
		{
			flag_set( "solo_revive" );
		}
		
		self thread solo_revive_buy_trigger_move( perk );
		
		// self disable_trigger();
	}

	if(perk == "specialty_additionalprimaryweapon")
	{
		if(IsDefined(self.weapon_taken_by_losing_additionalprimaryweapon[0]))
		{
			can_give_wep = true;
			if( IsDefined( level.limited_weapons )  )
			{
				keys2 = GetArrayKeys( level.limited_weapons );
				players = get_players();
				pap_triggers = GetEntArray("zombie_vending_upgrade", "targetname");
				for( q = 0; q < keys2.size; q++ )
				{
					if(keys2[q] != self.weapon_taken_by_losing_additionalprimaryweapon[0])
						continue;

					count = 0;
					for( i = 0; i < players.size; i++ )
					{
						if( players[i] maps\_zombiemode_weapons::has_weapon_or_upgrade( keys2[q] ) )
						{
							count++;
						}
					}

					// Check the pack a punch machines to see if they are holding what we're looking for
					for ( k=0; k<pap_triggers.size; k++ )
					{
						if ( IsDefined(pap_triggers[k].current_weapon) && pap_triggers[k].current_weapon == keys2[q] )
						{
							count++;
						}
					}

					// Check the other boxes so we don't offer something currently being offered during a fire sale
					for ( chestIndex = 0; chestIndex < level.chests.size; chestIndex++ )
					{
						if ( IsDefined( level.chests[chestIndex].chest_origin.weapon_string ) && level.chests[chestIndex].chest_origin.weapon_string == keys2[q] )
						{
							count++;
						}
					}
					
					//check weapon powerup
					if ( isdefined( level.random_weapon_powerups ) )
					{
						for ( powerupIndex = 0; powerupIndex < level.random_weapon_powerups.size; powerupIndex++ )
						{
							if ( IsDefined( level.random_weapon_powerups[powerupIndex] ) && level.random_weapon_powerups[powerupIndex].base_weapon == keys2[q] )
							{
								count++;
							}
						}
					}

					if( count >= level.limited_weapons[keys2[q]] )
					{
						can_give_wep = false;
						break;
					}
				}
			}
			if(can_give_wep)
			{
				self thread give_back_mule_weapon();
			}
			else
			{
				self.weapon_taken_by_losing_additionalprimaryweapon = [];
			}
		}
		/*if(!IsDefined(level.first_time_buying_mule))
		{
			level.first_time_buying_mule = true;
			self GiveWeapon("knife_ballistic_zm");
			wait_network_frame();
			self SwitchToWeapon("knife_ballistic_zm");
		}*/
		self thread unsave_additional_weapon_on_bleedout();
		self thread additional_weapon_indicator(perk, perk_str);
	}


	self perk_hud_create( perk );

	//stat tracking
	self.stats["perks"]++;

	self thread perk_think( perk );
}

give_back_mule_weapon()
{
	unupgrade_name = self.weapon_taken_by_losing_additionalprimaryweapon[0];
	if(maps\_zombiemode_weapons::is_weapon_upgraded(self.weapon_taken_by_losing_additionalprimaryweapon[0]))
	{
		unupgrade_name = GetSubStr(unupgrade_name, 0, unupgrade_name.size - 12) + GetSubStr(unupgrade_name, unupgrade_name.size - 3);
	}

	if(self HasWeapon(level.zombie_weapons[unupgrade_name].upgrade_name) || (self HasWeapon(unupgrade_name) && !maps\_zombiemode_weapons::is_weapon_upgraded(self.weapon_taken_by_losing_additionalprimaryweapon[0])))
	{
		//cant give wep back if player has the wep or player has upgraded version and we're trying to give them unupgraded version
		self.weapon_taken_by_losing_additionalprimaryweapon = [];
		return;
	}

	if(self HasWeapon(unupgrade_name))
	{
		self TakeWeapon(unupgrade_name);
	}

	self GiveWeapon(self.weapon_taken_by_losing_additionalprimaryweapon[0], 0, self maps\_zombiemode_weapons::get_pack_a_punch_weapon_options( self.weapon_taken_by_losing_additionalprimaryweapon[0] ));
	self SetWeaponAmmoClip(self.weapon_taken_by_losing_additionalprimaryweapon[0], self.weapon_taken_by_losing_additionalprimaryweapon[1]);
	self SetWeaponAmmoStock(self.weapon_taken_by_losing_additionalprimaryweapon[0], self.weapon_taken_by_losing_additionalprimaryweapon[2]);
	dual_wield_name = WeaponDualWieldWeaponName( self.weapon_taken_by_losing_additionalprimaryweapon[0] );
	if ( "none" != dual_wield_name )
	{
		self SetWeaponAmmoClip( dual_wield_name, self.weapon_taken_by_losing_additionalprimaryweapon[3] );
	}
	//wait_network_frame();
	//self SwitchToWeapon(self.weapon_taken_by_losing_additionalprimaryweapon[0]);
	self.weapon_taken_by_losing_additionalprimaryweapon = [];
}

check_player_has_perk(perk)
{
	self endon( "death" );
/#
	if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
	{
		return;
	}
#/
	if(true == true)
	{
		return;
	}

	dist = 128 * 128;
	while(true)
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			if(DistanceSquared( players[i].origin, self.origin ) < dist)
			{
				if (players[i] maps\_laststand::player_is_in_laststand() || is_true( players[i].intermission ) )
				{
					self SetInvisibleToPlayer(players[i], true);
				}
				else if(players[i] in_revive_trigger())
				{
					self SetInvisibleToPlayer(players[i], true);
				}				
				else if( players[i] isThrowingGrenade() )
				{
					self SetInvisibleToPlayer(players[i], true);
				}	
		 		else if( players[i] isSwitchingWeapons() )
		 		{
		 			self SetInvisibleToPlayer(players[i], true);
		 		}
				else if( players[i] is_drinking() )
				{
					self SetInvisibleToPlayer(players[i], true);
				}
				else if(!players[i] hasperk(perk) && !(players[i] in_revive_trigger()) && (!players[i] hacker_active()))
				{
					self SetInvisibleToPlayer(players[i], false);
				}
				else
				{
					self SetInvisibleToPlayer(players[i], true);
				}
			}
		}
		wait(0.05);

	}
}


vending_set_hintstring( perk )
{
	switch( perk )
	{
	case "specialty_armorvest_upgrade":
	case "specialty_armorvest":
		break;

	}
}


perk_think( perk )
{
/#
	if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
	{
		if ( IsDefined( self.perk_hud[ perk ] ) )
		{
			return;
		}
	}
#/
	if(true == true)
	{
		self.num_perks = 0;
		return;
	}

	perk_str = perk + "_stop";
	result = self waittill_any_return( "fake_death", "death", "player_downed", perk_str );

	do_retain = true;
	
	if( (get_players().size == 1) && perk == "specialty_quickrevive")
	{
		do_retain = false;
	}

	if(do_retain && IsDefined(self._retain_perks) && self._retain_perks)
	{
		wait_network_frame();
		self update_perk_hud();
		return;
	}

	self UnsetPerk( perk );
	self.num_perks--;
	
	switch(perk)
	{
		case "specialty_armorvest":
			self SetMaxHealth( 100 );
			break;

		case "specialty_fastreload":
			self UnsetPerk("specialty_fastswitch");
			break;
		
		case "specialty_additionalprimaryweapon":
			self SetClientDvar("ui_show_mule_wep_color", "0");
			//only take weapon from here if perk is lost from a way besides downing
			//weapon is not taken properly from here if downed, so called in _zombiemode::player_laststand() instead
			if ( result == perk_str )
			{
				self.weapon_taken_by_losing_additionalprimaryweapon = self maps\_zombiemode::take_additionalprimaryweapon();
			}
			break;
		
		case "specialty_deadshot":
			self ClearClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
			break;
		
		case "specialty_deadshot_upgrade":		
			self ClearClientFlag(level._ZOMBIE_PLAYER_FLAG_DEADSHOT_PERK);
			break;
	}
	
	self perk_hud_destroy( perk );
	self.perk_purchased = undefined;
	//self iprintln( "Perk Lost: " + perk );


	if ( IsDefined( level.perk_lost_func ) )
	{
		self [[ level.perk_lost_func ]]( perk );
	}

	self notify( "perk_lost" );
}


perk_hud_create( perk )
{
	if ( !IsDefined( self.perk_hud ) )
	{
		self.perk_hud = [];
		self.perk_hud_num = [];
	}

/#
	if ( GetDvarInt( #"zombie_cheat" ) >= 5 )
	{
		if ( IsDefined( self.perk_hud[ perk ] ) )
		{
			return;
		}
	}
#/
	if(true == true)
	{
		return;
	}


	shader = "";

	switch( perk )
	{
	case "specialty_armorvest_upgrade":
		shader = "specialty_juggernaut_zombies_pro";
		break;
	case "specialty_armorvest":
		shader = "specialty_juggernaut_zombies";
		break;

	case "specialty_quickrevive_upgrade":
		shader = "specialty_quickrevive_zombies_pro";
		break;
	case "specialty_quickrevive":
		shader = "specialty_quickrevive_zombies";
		break;

	case "specialty_fastreload_upgrade":
		shader = "specialty_fastreload_zombies_pro";
		break;
	case "specialty_fastreload":
		shader = "specialty_fastreload_zombies";
		break;

	case "specialty_rof_upgrade":
	case "specialty_rof":
		shader = "specialty_doubletap_zombies";
		break;
		
	case "specialty_longersprint_upgrade":
	case "specialty_longersprint":
		shader = "specialty_marathon_zombies";
		break;
		
	case "specialty_flakjacket_upgrade":
	case "specialty_flakjacket":
		shader = "specialty_divetonuke_zombies";
		break;
		
	case "specialty_deadshot_upgrade":
	case "specialty_deadshot":
		shader = "specialty_ads_zombies"; 
		break;

	case "specialty_additionalprimaryweapon_upgrade":
	case "specialty_additionalprimaryweapon":
		shader = "specialty_extraprimaryweapon_zombies";
		break;
		
	default:
		shader = "";
		break;
	}

	hud = create_simple_hud( self );
	hud.foreground = true; 
	hud.sort = 1; 
	hud.hidewheninmenu = false; 
	hud.alignX = "left"; 
	hud.alignY = "bottom";
	hud.horzAlign = "user_left"; 
	hud.vertAlign = "user_bottom";
	hud.x = (self.perk_hud.size * 30) + 4; 
	hud.y -= 70;
	hud.alpha = 0;
	hud FadeOverTime(.5);
	hud.alpha = 1;
	hud SetShader( shader, 24, 24 );

	self.perk_hud[ perk ] = hud;
	self.perk_hud_num[self.perk_hud_num.size] = perk;
}


perk_hud_destroy( perk )
{
	self.perk_hud_num = array_remove(self.perk_hud_num, perk);
	self.perk_hud[ perk ] destroy_hud();
	self.perk_hud[ perk ] = undefined;
}

perk_hud_flash(damage)
{
	self endon( "death" );

	self.flash = 1;
	self ScaleOverTime( 0.05, 32, 32 );
	color = self.color;
	if(damage == level.machine_damage_max)
	{
		self FadeOverTime(.15);
		self.color = (1,0,0);
	}
	wait( 0.3 );
	self ScaleOverTime( 0.05, 24, 24 );
	if(damage == level.machine_damage_max)
	{
		self FadeOverTime(.15);
		self.color = color;
	}
	wait( 0.3 );
	self.flash = 0;
}

perk_flash_audio( perk )
{
    alias = undefined;
    
    switch( perk )
    {
        case "specialty_armorvest":
            alias = "zmb_hud_flash_jugga";
            break;
        
        case "specialty_quickrevive":
            alias = "zmb_hud_flash_revive";
            break;
            
        case "specialty_fastreload":
            alias = "zmb_hud_flash_speed";
            break;
        
        case "specialty_longersprint":
            alias = "zmb_hud_flash_stamina";
            break;
            
        case "specialty_flakjacket":
            alias = "zmb_hud_flash_phd";
            break;
        
        case "specialty_deadshot":
            alias = "zmb_hud_flash_deadshot";
            break;
        
        case "specialty_additionalprimaryweapon":
            alias = "zmb_hud_flash_additionalprimaryweapon";
            break;
    }
    
    if( IsDefined( alias ) )
        self PlayLocalSound( alias );
}

perk_hud_start_flash( perk, damage )
{
	if ( self HasPerk( perk ) && isdefined( self.perk_hud ) )
	{
		hud = self.perk_hud[perk];
		if ( isdefined( hud ) )
		{
			if ( !is_true( hud.flash ) )
			{
				hud thread perk_hud_flash(damage);
				self thread perk_flash_audio( perk );
			}
		}
	}
}

perk_hud_stop_flash( perk, taken )
{
	if ( self HasPerk( perk ) && isdefined( self.perk_hud ) )
	{
		hud = self.perk_hud[perk];
		if ( isdefined( hud ) )
		{
			hud.flash = undefined;
			if ( isdefined( taken ) )
			{
				hud notify( "stop_flash_perk" );
			}
		}
	}
}

perk_give_bottle_begin( perk )
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
	weapon = "";

	switch( perk )
	{
	case " _upgrade":
	case "specialty_armorvest":
		weapon = "zombie_perk_bottle_jugg";
		break;

	case "specialty_quickrevive_upgrade":
	case "specialty_quickrevive":
		weapon = "zombie_perk_bottle_revive";
		break;

	case "specialty_fastreload_upgrade":
	case "specialty_fastreload":
		weapon = "zombie_perk_bottle_sleight";
		break;

	case "specialty_rof_upgrade":
	case "specialty_rof":
		weapon = "zombie_perk_bottle_doubletap";
		break;
		
	case "specialty_longersprint_upgrade":
	case "specialty_longersprint":
		weapon = "zombie_perk_bottle_marathon";
		break;
		
	case "specialty_flakjacket_upgrade":
	case "specialty_flakjacket":
		weapon = "zombie_perk_bottle_nuke";
		break;
		
	case "specialty_deadshot_upgrade":
	case "specialty_deadshot":
		weapon = "zombie_perk_bottle_deadshot";
		break;
		
	case "specialty_additionalprimaryweapon_upgrade":
	case "specialty_additionalprimaryweapon":
		weapon = "zombie_perk_bottle_additionalprimaryweapon";
		break;
	}

	self GiveWeapon( weapon );
	self SwitchToWeapon( weapon );

	return gun;
}


perk_give_bottle_end( gun, perk, has_fastswitch )
{
	assert( gun != "zombie_perk_bottle_doubletap" );
	assert( gun != "zombie_perk_bottle_jugg" );
	assert( gun != "zombie_perk_bottle_revive" );
	assert( gun != "zombie_perk_bottle_sleight" );
	assert( gun != "zombie_perk_bottle_marathon" );
	assert( gun != "zombie_perk_bottle_nuke" );
	assert( gun != "zombie_perk_bottle_deadshot" );
	assert( gun != "zombie_perk_bottle_additionalprimaryweapon" );
	assert( gun != "syrette_sp" );

	self AllowLean( true );
	self AllowAds( true );
	self AllowSprint( true );
	self AllowProne( true );		
	self AllowMelee( true );
	weapon = "";
	switch( perk )
	{
	case "specialty_rof_upgrade":
	case "specialty_rof":
		weapon = "zombie_perk_bottle_doubletap";
		break;

	case "specialty_longersprint_upgrade":
	case "specialty_longersprint":
		weapon = "zombie_perk_bottle_marathon";
		break;
		
	case "specialty_flakjacket_upgrade":
	case "specialty_flakjacket":
		weapon = "zombie_perk_bottle_nuke";
		break;

	case "specialty_armorvest_upgrade":
	case "specialty_armorvest":
		weapon = "zombie_perk_bottle_jugg";
		self.jugg_used = true;
		break;

	case "specialty_quickrevive_upgrade":
	case "specialty_quickrevive":
		weapon = "zombie_perk_bottle_revive";
		break;

	case "specialty_fastreload_upgrade":
	case "specialty_fastreload":
		weapon = "zombie_perk_bottle_sleight";
		self.speed_used = true;
		break;
		
	case "specialty_deadshot_upgrade":
	case "specialty_deadshot":
		weapon = "zombie_perk_bottle_deadshot";
		break;

	case "specialty_additionalprimaryweapon_upgrade":
	case "specialty_additionalprimaryweapon":
		weapon = "zombie_perk_bottle_additionalprimaryweapon";
		break;

	}

	// TODO: race condition?
	if ( self maps\_laststand::player_is_in_laststand() || is_true( self.intermission ) )
	{
		self TakeWeapon(weapon);
		return;
	}

	if(has_fastswitch || perk == "specialty_fastreload")
	{
		self SetPerk("specialty_fastswitch");
	}

	self TakeWeapon(weapon);

	if( self is_multiple_drinking() )
	{
		self decrement_is_drinking();
		return;
	}
	else if( gun != "none" && !is_equipment( gun ) ) // && !is_placeable_mine( gun )
	{
		self SwitchToWeapon( gun );
		// ww: the knives have no first raise anim so they will never get a "weapon_change_complete" notify
		// meaning it will never leave this funciton and will break buying weapons for the player
		if( is_melee_weapon( gun ) )
		{
			self decrement_is_drinking();
			return;
		}
	}
	else 
	{
		// try to switch to first primary weapon
		primaryWeapons = self GetWeaponsListPrimaries();
		if( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
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

give_random_perk()
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );

	perks = [];
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		perk = vending_triggers[i].script_noteworthy;

		if ( isdefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
			continue;
		}

		if ( !self HasPerk( perk ) )
		{
			perks[ perks.size ] = perk;
		}
	}

	if ( perks.size > 0 )
	{
		perks = array_randomize( perks );
		self give_perk( perks[0] );
	}
}


lose_random_perk()
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );

	perks = [];
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		perk = vending_triggers[i].script_noteworthy;

		if ( isdefined( self.perk_purchased ) && self.perk_purchased == perk )
		{
			continue;
		}

		if ( self HasPerk( perk ) )
		{
			perks[ perks.size ] = perk;
		}
	}

	if ( perks.size > 0 )
	{
		perks = array_randomize( perks );
		perk = perks[0];

		perk_str = perk + "_stop";
		self notify( perk_str );

		if ( flag( "solo_game" ) && perk == "specialty_quickrevive" )
		{
			self.lives--;
		}
	}
}

update_perk_hud()
{
	if ( isdefined( self.perk_hud ) )
	{
		for ( i = 0; i < self.perk_hud_num.size; i++ )
		{
			self.perk_hud[ self.perk_hud_num[i] ].x = (i * 30) + 4;
		}
	}
}

quantum_bomb_give_nearest_perk_validation( position )
{
	vending_triggers = GetEntArray( "zombie_vending", "targetname" );

	range_squared = 180 * 180; // 15 feet
	for ( i = 0; i < vending_triggers.size; i++ )
	{
		if ( DistanceSquared( vending_triggers[i].origin, position ) < range_squared )
		{
			perk = vending_triggers[i].script_noteworthy;
			if ( !self HasPerk( perk ) && ( !isdefined( self.perk_purchased ) || self.perk_purchased != perk) )
			{
				return true;
			}
		}
	}

	return false;
}


quantum_bomb_give_nearest_perk_result( position )
{
	[[level.quantum_bomb_play_mystery_effect_func]]( position );

	vending_triggers = GetEntArray( "zombie_vending", "targetname" );

	nearest = 0;
	for ( i = 1; i < vending_triggers.size; i++ )
	{
		if ( DistanceSquared( vending_triggers[i].origin, position ) < DistanceSquared( vending_triggers[nearest].origin, position ) )
		{
			nearest = i;
		}
	}

	players = getplayers();
	perk = vending_triggers[nearest].script_noteworthy;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( player.sessionstate == "spectator" || player maps\_laststand::player_is_in_laststand() )
		{
			continue;
		}

		if ( !player HasPerk( perk ) && ( !isdefined( player.perk_purchased ) || player.perk_purchased != perk) )
		{
			if( player == self )
			{
				self thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "quant_good" );
				player give_perk( perk );
				player [[level.quantum_bomb_play_player_effect_func]]();
			}
		}
	}
}

unsave_additional_weapon_on_bleedout()
{
	self notify("additionalprimaryweapon bought");
	self endon("additionalprimaryweapon bought");
	while(1)
	{
		self waittill("bled_out");
		self.weapon_taken_by_losing_additionalprimaryweapon = [];
	}
}

additional_weapon_indicator(perk, perk_str)
{
	self endon("fake_death");
	self endon("death");
	self endon("player_downed");
	self endon(perk_str);

	indicated = false;
	while(1)
	{
		additional_wep = undefined;

		primary_weapons_that_can_be_taken = [];
		primaryWeapons = self GetWeaponsListPrimaries();
		for ( i = 0; i < primaryWeapons.size; i++ )
		{
			if ( maps\_zombiemode_weapons::is_weapon_included( primaryWeapons[i] ) || maps\_zombiemode_weapons::is_weapon_upgraded( primaryWeapons[i] ) )
			{
				primary_weapons_that_can_be_taken[primary_weapons_that_can_be_taken.size] = primaryWeapons[i];
			}
		}

		if ( primary_weapons_that_can_be_taken.size >= 3 )
			additional_wep = primary_weapons_that_can_be_taken[primary_weapons_that_can_be_taken.size - 1];

		current_wep = self GetCurrentWeapon();

		if(IsDefined(additional_wep) && (current_wep == additional_wep || current_wep == WeaponAltWeaponName(additional_wep)))
		{
			self SetClientDvar("ui_show_mule_wep_color", "1");
		}

		self thread wait_for_weapon_switch(perk_str);

		notify_string = self waittill_any_return("weapon_change", "weapon_switch");

		//iprintln(notify_string);

		if(notify_string == "weapon_switch")
		{
			self SetClientDvar("ui_show_mule_wep_color", "0");
			self thread wait_for_weapon_switch_stop(perk_str);
			//iprintln("switching");
			self waittill_any( "weapon_switch_stop", "weapon_change", "weapon_change_complete" );
			//self waittill( "weapon_change", current_wep, prev_wep );
		}
		else if(notify_string == "weapon_change")
		{
			//need to wait 2 frames here for things to work right
			wait_network_frame();
			wait_network_frame();
			self SetClientDvar("ui_show_mule_wep_color", "0");
		}

		//iprintln("actually switched");
	}
}

wait_for_weapon_switch(perk_str)
{
	self endon("fake_death");
	self endon("death");
	self endon("player_downed");
	self endon(perk_str);

	while(self isSwitchingWeapons())
	{
		wait_network_frame();
	}

	while(!self isSwitchingWeapons())
	{
		wait_network_frame();
	}

	self notify("weapon_switch");
}

wait_for_weapon_switch_stop(perk_str)
{
	self endon("fake_death");
	self endon("death");
	self endon("player_downed");
	self endon(perk_str);

	while(self isSwitchingWeapons())
	{
		wait_network_frame();
	}

	self notify("weapon_switch_stop");
}

move_faster_while_ads(perk_str)
{
	self endon("fake_death");
	self endon("death");
	self endon("player_downed");
	self endon(perk_str);

	set = false;
	while(1)
	{
		if(isADS(self) && (!set))
		{
			set = true;
			self SetMoveSpeedScale(1.5);
		}
		else if(!isADS(self) && set)
		{
			set = false;
			self SetMoveSpeedScale(1);
		}

		wait_network_frame();
	}
}