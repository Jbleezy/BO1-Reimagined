#include maps\_utility;
#include common_scripts\utility;

init()
{
	if ( IsDefined( level._uses_retrievable_ballisitic_knives ) && level._uses_retrievable_ballisitic_knives == true )
	{
		PrecacheModel( "t5_weapon_ballistic_knife_blade" );
		PrecacheModel( "t5_weapon_ballistic_knife_blade_retrieve" );
	}
}

on_spawn( watcher, player )
{
	player endon( "death" );
	player endon( "disconnect" );
	player endon( "zmb_lost_knife" ); // occurs when the player gives up or changes the type of ballistic_knife they are carrying
	level endon( "game_ended" );

	self waittill( "stationary", endpos, normal, angles, attacker, prey, bone );
	
	isFriendly = false;

	if( isDefined(endpos) )
	{
		// once the missile dies, spawn a model there to be retrieved
		retrievable_model = Spawn( "script_model", endpos );
		//retrievable_model SetModel( "t5_weapon_ballistic_knife_blade" );
		retrievable_model SetModel( "t5_weapon_ballistic_knife_blade_retrieve" );
		retrievable_model SetOwner( player );
		retrievable_model.owner = player;
		retrievable_model.angles = angles;
		retrievable_model.name = watcher.weapon;

		if( IsDefined( prey ) )
		{
			//Don't stick to teammates and friendly dogs
			if( isPlayer(prey) && player.team == prey.team )
				isFriendly = true;
			else if( isAI(prey) && player.team == prey.team)
				isFriendly = true;

			if( !isFriendly )
			{
				retrievable_model LinkTo( prey, bone );
				retrievable_model thread force_drop_knives_to_ground_on_death( player, prey );
				//retrievable_model thread force_drop_knives_to_ground_on_gib( player, prey );
			}
			else if( isFriendly )
			{
				//launchVec = normal * -1;
				retrievable_model physicslaunch();

				//Since the impact normal is not what we want anymore, and the knife will fall to the ground, send the world up normal.
				normal = (0,0,1);
			}

		}

		watcher.objectArray[watcher.objectArray.size] = retrievable_model;

		//Wait until the model is stationary again
		if( isFriendly )
		{
			retrievable_model waittill( "stationary");
		}

		retrievable_model thread drop_knives_to_ground( player );

		/*if ( isFriendly )
		{
			player notify( "ballistic_knife_stationary", retrievable_model, normal );
		}
		else
		{
			player notify( "ballistic_knife_stationary", retrievable_model, normal, prey );
		}*/

		//retrievable_model thread wait_to_show_glowing_model( prey );

		/*vec_scale = 10;
		trigger_pos = [];
		if ( IsDefined( prey ) && ( isPlayer( prey ) || isAI( prey ) ) )
		{
			trigger_pos[0] = prey.origin[0];
			trigger_pos[1] = prey.origin[1];
			trigger_pos[2] = prey.origin[2] + vec_scale;
		}
		else
		{
			trigger_pos[0] = retrievable_model.origin[0] + (vec_scale * normal[0]);
			trigger_pos[1] = retrievable_model.origin[1] + (vec_scale * normal[1]);
			trigger_pos[2] = retrievable_model.origin[2] + (vec_scale * normal[2]);
		}*/

		pickup_trigger = Spawn( "trigger_radius", retrievable_model.origin, 0, 32, 64 );
		pickup_trigger SetCursorHint( "HINT_NOICON" );
		pickup_trigger.owner = player;
		retrievable_model.retrievableTrigger = pickup_trigger;

		pickup_trigger SetTeamForTrigger( player.team );
		
		player ClientClaimTrigger( pickup_trigger );

		// link the model and trigger, then link them to the ragdoll if needed
		pickup_trigger EnableLinkTo();
		if ( IsDefined( prey ) )
		{
			pickup_trigger LinkTo( prey );
		}
		else
		{
			pickup_trigger LinkTo( retrievable_model );
		}

		retrievable_model thread watch_use_trigger( pickup_trigger, retrievable_model, ::pick_up, watcher.weapon, watcher.pickUpSoundPlayer, watcher.pickUpSound );
		player thread watch_shutdown( pickup_trigger, retrievable_model );
	}
}

wait_to_show_glowing_model( prey ) // self == retrievable_model
{
	level endon( "game_ended" );
	self endon( "death" );

	glowing_retrievable_model = Spawn( "script_model", self.origin );
	self.glowing_model = glowing_retrievable_model;
	glowing_retrievable_model.angles = self.angles;
	glowing_retrievable_model LinkTo( self );

	// we don't want to show the glowing retrievable model until the ragdoll finishes, this will keep the glow out of the kill cam
	if( IsDefined( prey ) )
	{
		wait( 2 );
	}

	glowing_retrievable_model SetModel( "t5_weapon_ballistic_knife_blade_retrieve" );
}

on_spawn_retrieve_trigger( watcher, player )
{
	/*player endon( "death" );
	player endon( "disconnect" );
	player endon( "zmb_lost_knife" ); // occurs when the player gives up or changes the type of ballistic_knife they are carrying
	level endon( "game_ended" );

	player waittill( "ballistic_knife_stationary", retrievable_model, normal, prey );

	if( !IsDefined( retrievable_model ) )
		return;

	vec_scale = 10;
	trigger_pos = [];
	if ( IsDefined( prey ) && ( isPlayer( prey ) || isAI( prey ) ) )
	{
		trigger_pos[0] = prey.origin[0];
		trigger_pos[1] = prey.origin[1];
		trigger_pos[2] = prey.origin[2] + vec_scale;
	}
	else
	{
		trigger_pos[0] = retrievable_model.origin[0] + (vec_scale * normal[0]);
		trigger_pos[1] = retrievable_model.origin[1] + (vec_scale * normal[1]);
		trigger_pos[2] = retrievable_model.origin[2] + (vec_scale * normal[2]);
	}
	pickup_trigger = Spawn( "trigger_radius", (trigger_pos[0], trigger_pos[1], trigger_pos[2]) );
	pickup_trigger SetCursorHint( "HINT_NOICON" );
	pickup_trigger.owner = player;
	retrievable_model.retrievableTrigger = pickup_trigger;


	//retrievable_model thread debug_print( endpos );

	hint_string = &"WEAPON_BALLISTIC_KNIFE_PICKUP";
	if( IsDefined( hint_string ) )
	{
		pickup_trigger SetHintString( hint_string );
	}
	else
	{
		pickup_trigger SetHintString( &"GENERIC_PICKUP" );
	}


	pickup_trigger SetTeamForTrigger( player.team );
	
	player ClientClaimTrigger( pickup_trigger );

	// link the model and trigger, then link them to the ragdoll if needed
	pickup_trigger EnableLinkTo();
	if ( IsDefined( prey ) )
	{
		pickup_trigger LinkTo( prey );
	}
	else
	{
		pickup_trigger LinkTo( retrievable_model );
	}

	retrievable_model thread watch_use_trigger( pickup_trigger, retrievable_model, ::pick_up, watcher.weapon, watcher.pickUpSoundPlayer, watcher.pickUpSound );
	player thread watch_shutdown( pickup_trigger, retrievable_model );*/
}

debug_print( endpos )
{
	self endon( "death" );
	while( true )
	{
		Print3d( endpos, "pickup_trigger" );
		wait(0.05);
	}
}

watch_use_trigger( trigger, model, callback, weapon, playerSoundOnUse, npcSoundOnUse ) // self == retrievable_model
{
	self endon( "death" );
	self endon( "delete" );
	level endon ( "game_ended" );

	while ( true )
	{
		trigger waittill( "trigger", player );

		if ( !IsAlive( player ) )
			continue;

		if ( IsDefined( trigger.triggerTeam ) && ( player.team != trigger.triggerTeam ) )
			continue;

		if ( IsDefined( trigger.claimedBy ) && ( player != trigger.claimedBy ) )
			continue;

		// player got the bowie or sickle
		if(!player HasWeapon(weapon))
		{
			if(player HasWeapon("knife_ballistic_bowie_zm"))
			{
				weapon = "knife_ballistic_bowie_zm";
			}
			else if(player HasWeapon("knife_ballistic_bowie_upgraded_zm"))
			{
				weapon = "knife_ballistic_bowie_upgraded_zm";
			}
			else if(player HasWeapon("knife_ballistic_sickle_zm"))
			{
				weapon = "knife_ballistic_sickle_zm";
			}
			else if(player HasWeapon("knife_ballistic_sickle_upgraded_zm"))
			{
				weapon = "knife_ballistic_sickle_upgraded_zm";
			}
		}

		max_ammo = WeaponMaxAmmo(weapon);
		if(player HasPerk("specialty_stockpile"))
			max_ammo += WeaponClipSize(weapon);

		if(player GetWeaponAmmoStock(weapon) >= max_ammo)
			continue;

		if ( isdefined( playerSoundOnUse ) )
			player playLocalSound( playerSoundOnUse );
		if ( isdefined( npcSoundOnUse ) )
			player playSound( npcSoundOnUse );
		player thread [[callback]]( weapon, model, trigger );
		break;
	}
}

pick_up( weapon, model, trigger ) // self == player
{
	self SetWeaponAmmoStock( weapon, self GetWeaponAmmoStock( weapon ) + 1 );

	model destroy_ent();
	trigger destroy_ent();
}

destroy_ent()
{
	if( IsDefined(self) )
	{
		if( IsDefined( self.glowing_model  ) )
		{
			self.glowing_model delete();
		}

		self delete();
	}
}

watch_shutdown( trigger, model ) // self == player
{
	self waittill_any( "death", "disconnect", "zmb_lost_knife" );  // "zmb_lost_knife", occurs when the player gives up or changes the type of ballistic_knife they are carrying

	trigger destroy_ent();
	model destroy_ent();
}

drop_knives_to_ground( player )
{
	player endon("death");
	player endon( "zmb_lost_knife" ); // occurs when the player gives up or changes the type of ballistic_knife they are carrying

	for( ;; )
	{
		level waittill( "drop_objects_to_ground", origin, radius );
		if( DistanceSquared( origin, self.origin )< radius * radius )
		{
			self physicslaunch();
			self thread update_retrieve_trigger( player );
		}
	}
}

force_drop_knives_to_ground_on_death( player, prey )
{
	self endon("death");
	player endon( "zmb_lost_knife" ); // occurs when the player gives up or changes the type of ballistic_knife they are carrying
	self endon("gibbed");

	if(prey.health > 0)
	{
		prey waittill( "death" );
	}

	self Unlink();
	self physicslaunch();
	self thread update_retrieve_trigger( player );
}

force_drop_knives_to_ground_on_gib( player, prey )
{
	self endon("death");
	player endon( "zmb_lost_knife" ); // occurs when the player gives up or changes the type of ballistic_knife they are carrying
	prey endon("death");

	while(1)
	{
		if(!self IsTouching(prey))
		{
			break;
		}

		wait_network_frame();
	}

	self notify("gibbed");
	self Unlink();
	self physicslaunch();
	self thread update_retrieve_trigger( player );
}

update_retrieve_trigger( player )
{
	self endon("death");
	player endon( "zmb_lost_knife" ); // occurs when the player gives up or changes the type of ballistic_knife they are carrying

	self waittill( "stationary");

	trigger = self.retrievableTrigger;

	trigger.origin = ( self.origin[0], self.origin[1], self.origin[2] + 10 );
	trigger LinkTo( self );
}