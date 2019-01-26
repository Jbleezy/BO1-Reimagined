#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_audio;

init()
{
	init_equipment_upgrade();
}

register_equipment( equipment_name, hint, howto_hint, equipmentVO, watcher_thread )
{
	if ( !IsDefined( level.zombie_include_equipment ) || !is_true( level.zombie_include_equipment[equipment_name] ) )
	{
		return;
	}

	PrecacheString( hint );

	struct = SpawnStruct();

	if ( !IsDefined( level.zombie_equipment ) )
	{
		level.zombie_equipment = [];
	}

	struct.equipment_name = equipment_name;
	struct.hint = hint;
	struct.howto_hint = howto_hint;
	struct.vox = equipmentVO;
	struct.triggers = [];
	struct.models = [];
	struct.watcher_thread = watcher_thread;

	level.zombie_equipment[equipment_name] = struct;
}


is_equipment_included( equipment_name )
{
	if ( !IsDefined( level.zombie_include_equipment ) )
	{
		return false;
	}

	return IsDefined( level.zombie_include_equipment[equipment_name] );
}


include_zombie_equipment( equipment_name )
{
	if ( !IsDefined( level.zombie_include_equipment ) )
	{
		level.zombie_include_equipment = [];
	}

	level.zombie_include_equipment[equipment_name] = true;

	PrecacheItem( equipment_name );
}


init_equipment_upgrade()
{
	equipment_spawns = [];
	equipment_spawns = GetEntArray( "zombie_equipment_upgrade", "targetname" );

	for( i = 0; i < equipment_spawns.size; i++ )
	{
		if(level.gamemode != "survival")
		{
			equipment_spawns[i] disable_trigger();
			continue;
		}
		
		hint_string = get_equipment_hint( equipment_spawns[i].zombie_equipment_upgrade );

		equipment_spawns[i] SetHintString( hint_string );
		equipment_spawns[i] setCursorHint( "HINT_NOICON" );
		equipment_spawns[i] UseTriggerRequireLookAt();
		equipment_spawns[i] add_to_equipment_trigger_list( equipment_spawns[i].zombie_equipment_upgrade );
		equipment_spawns[i] thread equipment_spawn_think();
	}
}


get_equipment_hint( equipment_name )
{
	AssertEx( IsDefined( level.zombie_equipment[equipment_name] ), equipment_name + " was not included or is not registered with the equipment system." );

	return level.zombie_equipment[equipment_name].hint;
}


get_equipment_howto_hint( equipment_name )
{
	AssertEx( IsDefined( level.zombie_equipment[equipment_name] ), equipment_name + " was not included or is not registered with the equipment system." );

	return level.zombie_equipment[equipment_name].howto_hint;
}


add_to_equipment_trigger_list( equipment_name )
{
	AssertEx( IsDefined( level.zombie_equipment[equipment_name] ), equipment_name + " was not included or is not registered with the equipment system." );

	level.zombie_equipment[equipment_name].triggers[level.zombie_equipment[equipment_name].triggers.size] = self;

	// also need to add the model to the models list
	level.zombie_equipment[equipment_name].models[level.zombie_equipment[equipment_name].models.size] = GetEnt( self.target, "targetname" );
}


equipment_spawn_think()
{
	for ( ;; )
	{
		self waittill( "trigger", player );

		if ( player in_revive_trigger() || player is_drinking() )
		{
			wait( 0.1 );
			continue;
		}

		if( is_limited_equipment(self.zombie_equipment_upgrade)) //only one player can have limited equipment at a time
		{
			player setup_limited_equipment(self.zombie_equipment_upgrade);

			//move the equpiment respawn to a new location
			if(isDefined(level.hacker_tool_positions))
			{
				new_pos = random(level.hacker_tool_positions);
				self.origin = new_pos.trigger_org;
				model = getent(self.target,"targetname");
				model.origin = new_pos.model_org;
				model.angles = new_pos.model_ang;
			}

		}

		player equipment_give( self.zombie_equipment_upgrade );
	}
}


set_equipment_invisibility_to_player( equipment, invisible )
{
	triggers = level.zombie_equipment[equipment].triggers;
	for ( i = 0; i < triggers.size; i++ )
	{
		if(isDefined(triggers[i]))
		{
			triggers[i] SetInvisibleToPlayer( self, invisible );
		}
	}

	if(equipment != "equip_hacker_zm")
	{
		models = level.zombie_equipment[equipment].models;
		for ( i = 0; i < models.size; i++ )
		{
			if(isDefined(models[i]))
			{
				models[i] SetInvisibleToPlayer( self, invisible );
			}
		}
	}
}


equipment_take()
{

	equipment = self get_player_equipment();

	if ( !isdefined( equipment ) )
	{
		return;
	}

	if(self.current_equipment_active[equipment])
	{
		self.current_equipment_active[equipment] = false;
		self notify(equipment + "_deactivate");
	}

	self notify(equipment + "_taken");

	self TakeWeapon( equipment );

	if( (!is_limited_equipment(equipment) ) ||  (is_limited_equipment(equipment) && !limited_equipment_in_use(equipment) ))
	{
		self set_equipment_invisibility_to_player( equipment, false );
	}
	self set_player_equipment( undefined );
}


equipment_give( equipment )
{
	// skip all this if they already have it
	if ( self is_player_equipment( equipment ) )
	{
		return;
	}

	curr_weapon = self GetCurrentWeapon();
	curr_weapon_was_curr_equipment = self is_player_equipment( curr_weapon );
	self equipment_take();
	if ( curr_weapon_was_curr_equipment )
	{
		// if they just traded in their current weapon, switch them to a primary
		primaryWeapons = self GetWeaponsListPrimaries();
		if ( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
	}

	self set_player_equipment( equipment );
	self GiveWeapon( equipment );
	self thread show_equipment_hint( equipment );
	self notify(equipment + "_given");
	self set_equipment_invisibility_to_player( equipment, true );
	self setactionslot( 1, "weapon", equipment );

	if(IsDefined(level.zombie_equipment[equipment].watcher_thread))
	{
		self thread [[level.zombie_equipment[equipment].watcher_thread]]();
	}

	self thread equipment_slot_watcher(equipment);

	self maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", level.zombie_equipment[equipment].vox );
}

equipment_slot_watcher(equipment)
{
	self notify("kill_equipment_slot_watcher");
	self endon("kill_equipment_slot_watcher");
	self endon("disconnect");

	while(1)
	{
		self waittill( "weapon_change", curr_weapon, prev_weapon );

		self.prev_weapon_before_equipment_change = undefined;
		if ( isdefined( prev_weapon ) && "none" != prev_weapon )
		{
			prev_weapon_type = WeaponInventoryType( prev_weapon );
			//if ( "primary" == prev_weapon_type || "altmode" == prev_weapon_type )
			//{
			self.prev_weapon_before_equipment_change = prev_weapon;
			//}
		}

		if ( IsDefined( level.zombie_equipment[equipment].watcher_thread ) )
		{
			if ( curr_weapon == equipment )
			{
				if ( self.current_equipment_active[equipment] == true )
				{
					self notify( equipment + "_deactivate" );
					self.current_equipment_active[equipment] = false;
				}
				else if ( self.current_equipment_active[equipment] == false )
				{
					self notify( equipment + "_activate" );
					self.current_equipment_active[equipment] = true;
				}

				self waittill( "equipment_select_response_done" );
			}
		}
		else
		{
			if ( curr_weapon == equipment && !self.current_equipment_active[equipment] )
			{
				self notify( equipment + "_activate" );
				self.current_equipment_active[equipment] = true;
			}
			else if ( curr_weapon != equipment && self.current_equipment_active[equipment] )
			{
				self notify( equipment + "_deactivate" );
				self.current_equipment_active[equipment] = false;
			}
		}
	}
}

is_limited_equipment(equipment)
{
	if(isDefined(level._limited_equipment))
	{

		for(i=0;i<level._limited_equipment.size;i++)
		{
			if(level._limited_equipment[i] == equipment)
			{
				return true;
			}
		}

		return false;
	}
}

limited_equipment_in_use(equipment)
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		current_equipment = players[i] get_player_equipment();
		if(isDefined(current_equipment) && current_equipment == equipment)
		{
			return true;
		}
	}
	return false;
}


setup_limited_equipment(equipment)
{
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		players[i] set_equipment_invisibility_to_player( equipment, true );
	}

	self thread release_limited_equipment_on_disconnect(equipment);
	self thread release_limited_equipment_on_equipment_taken(equipment);
}

release_limited_equipment_on_equipment_taken(equipment)
{
	self endon("disconnect");

	self waittill_either( equipment + "_taken","spawned_spectator");

	players = get_players();
	for(i=0;i<players.size;i++)
	{

		players[i] set_equipment_invisibility_to_player( equipment, false );
	}
}


release_limited_equipment_on_disconnect(equipment)
{
	self endon( equipment + "_taken");

	self waittill("disconnect");

	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(isAlive(players[i]))
		{
			players[i] set_equipment_invisibility_to_player( equipment, false );
		}
	}
}

is_equipment_active(equipment)
{
	if(!IsDefined(self.current_equipment_active) || !IsDefined(self.current_equipment_active[equipment]))
	{
		return false;
	}

	return(self.current_equipment_active[equipment]);
}


init_equipment_hint_hudelem(x, y, alignX, alignY, fontscale, alpha)
{
	self.x = x;
	self.y = y;
	self.alignX = alignX;
	self.alignY = alignY;
	self.fontScale = fontScale;
	self.alpha = alpha;
	self.sort = 20;
	//self.font = "objective";
}


setup_equipment_client_hintelem()
{
	self endon("death");
	self endon("disconnect");

	if(!isDefined(self.hintelem))
	{
		self.hintelem = newclienthudelem(self);
	}
	self.hintelem init_equipment_hint_hudelem(320, 220, "center", "bottom", 1.6, 1.0);
}


show_equipment_hint( equipment )
{
	self notify("kill_previous_show_equipment_hint_thread");
	self endon("kill_previous_show_equipment_hint_thread");
	self endon("death");
	self endon("disconnect");

	wait(.5);

	text = get_equipment_howto_hint( equipment );

	self setup_equipment_client_hintelem();
	self.hintelem setText(text);
	self.hintelem.font = "small";
	self.hintelem.fontscale = 1.25;
	wait(3.5);
	self.hintelem settext("");
	self.hintelem destroy();
}
