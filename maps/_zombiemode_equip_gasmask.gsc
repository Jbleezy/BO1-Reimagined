#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

init()
{
	if ( !maps\_zombiemode_equipment::is_equipment_included( "equip_gasmask_zm" ) )
	{
		return;
	}

	level._CF_PLAYER_GASMASK_OVERLAY_REMOVE = 8;
	level._CF_PLAYER_GASMASK_OVERLAY = 9;

	maps\_zombiemode_equipment::register_equipment( "equip_gasmask_zm", &"ZOMBIE_EQUIP_GASMASK_PICKUP_HINT_STRING", &"ZOMBIE_EQUIP_GASMASK_HOWTO", "gasmask", ::gasmask_activation_watcher_thread );

	level.deathcard_spawn_func = ::remove_gasmask_on_player_bleedout;

	PreCacheItem("lower_equip_gasmask_zm");

	level thread gasmask_on_player_connect();
}


gasmask_on_player_connect()
{
	for( ;; )
	{
		level waittill( "connecting", player );
	}
}

gasmask_removed_watcher_thread()
{
	self notify("only_one_gasmask_removed_thread");
	self endon("only_one_gasmask_removed_thread");
	self endon("disconnect");

	self waittill("equip_gasmask_zm_taken");

	//  Do switch to normal player model/head here.

	if ( IsDefined( level.zombiemode_gasmask_set_player_model ) )
	{
		ent_num = self GetEntityNumber();

		if(IsDefined(self.zm_random_char))
		{
			ent_num = self.zm_random_char;
		}

		self [[level.zombiemode_gasmask_change_player_headmodel]]( ent_num, false );
	}

	/*if(IsDefined(level.zombiemode_gasmask_reset_player_model))
	{
		ent_num = self GetEntityNumber();

		if(IsDefined(self.zm_random_char))
		{
			ent_num = self.zm_random_char;
		}

		self [[level.zombiemode_gasmask_reset_player_model]](ent_num);
	}

	if(IsDefined(level.zombiemode_gasmask_reset_player_viewmodel))
	{
		ent_num = self GetEntityNumber();

		if(IsDefined(self.zm_random_char))
		{
			ent_num = self.zm_random_char;
		}

		self [[level.zombiemode_gasmask_reset_player_viewmodel]](ent_num);
	}*/

	self clearclientflag(level._CF_PLAYER_GASMASK_OVERLAY);
}

/*
	level.zombiemode_gasmask_reset_player_model = ::gasmask_reset_player_model;
	level.zombiemode_gasmask_reset_player_viewmodel = ::gasmask_reset_player_set_viewmodel;
	level.zombiemode_gasmask_set_player_model = ::gasmask_set_player_model;
	level.zombiemode_gasmask_set_player_viewmodel = ::gasmask_set_player_viewmodel;
*/

gasmask_activation_watcher_thread()
{
	self endon("zombified");
	self endon("disconnect");
	self endon("equip_gasmask_zm_taken");

	self thread gasmask_removed_watcher_thread();

	self thread remove_gasmask_on_game_over();


	// Switch to hazmat suited player model here.
	//IPrintLnBold("I can hazMat.");

	if(level.gamemode == "survival")
	{
		if(IsDefined(level.zombiemode_gasmask_set_player_model))
		{
			ent_num = self GetEntityNumber();

			if(IsDefined(self.zm_random_char))
			{
				ent_num = self.zm_random_char;
			}

			self [[level.zombiemode_gasmask_set_player_model]](ent_num);
		}

		if(IsDefined(level.zombiemode_gasmask_set_player_viewmodel))
		{
			ent_num = self GetEntityNumber();

			if(IsDefined(self.zm_random_char))
			{
				ent_num = self.zm_random_char;
			}

			self [[level.zombiemode_gasmask_set_player_viewmodel]](ent_num);
		}
	}

	while(1)
	{
		self waittill_either("equip_gasmask_zm_activate", "equip_gasmask_zm_deactivate");

		if(self HasPerk("specialty_fastreload"))
		{
			self UnSetPerk("specialty_fastswitch");
		}

		if(self maps\_zombiemode_equipment::is_equipment_active("equip_gasmask_zm"))
		{
			self increment_is_drinking();

			self TakeWeapon("equip_gasmask_zm");
			self GiveWeapon("equip_gasmask_zm");
			self SwitchToWeapon("equip_gasmask_zm");

			// Switch to hazmat suited player model, with gasmask here.
			if ( IsDefined( level.zombiemode_gasmask_set_player_model ) )
			{
				ent_num = self GetEntityNumber();

				if(IsDefined(self.zm_random_char))
				{
					ent_num = self.zm_random_char;
				}

				self [[level.zombiemode_gasmask_change_player_headmodel]]( ent_num, true );
			}

			wait .8;
			clientnotify( "gmsk2" );
			wait 1.8;

			//self waittill( "weapon_change_complete" );

			// Start overlay on client.

			//clientNotify( "_gasmask_on_pristine" );
			//self clientnotify("gmon");//setClientSysState("levelNotify", "gmon", self);
			self setclientflag(level._CF_PLAYER_GASMASK_OVERLAY);
		}
		else
		{
			self increment_is_drinking();

			self TakeWeapon("equip_gasmask_zm");
			self GiveWeapon("equip_gasmask_zm");
			self GiveWeapon("lower_equip_gasmask_zm");
			self SwitchToWeapon("lower_equip_gasmask_zm");

			// Switch to hazmat suited player model, without gasmask here.
			if ( IsDefined( level.zombiemode_gasmask_set_player_model ) )
			{
				ent_num = self GetEntityNumber();

				if(IsDefined(self.zm_random_char))
				{
					ent_num = self.zm_random_char;
				}

				self [[level.zombiemode_gasmask_change_player_headmodel]]( ent_num, false );
			}

			// wait until the gasmask is the player's current weapon, or else the "weapon_change_complete" notify can go off for the previous weapon and cause problems
			while(self GetCurrentWeapon() != "lower_equip_gasmask_zm")
			{
				wait_network_frame();
			}

			self clearclientflag(level._CF_PLAYER_GASMASK_OVERLAY);
			self waittill( "weapon_change_complete" );

			self TakeWeapon("lower_equip_gasmask_zm");
		}

		if(self HasPerk("specialty_fastreload"))
		{
			self SetPerk("specialty_fastswitch");
		}

		if ( !self maps\_laststand::player_is_in_laststand() )
		{
			if( self is_multiple_drinking() )
			{
				self decrement_is_drinking();
				self notify("equipment_select_response_done");
				continue;
			}
			else if ( isdefined( self.prev_weapon_before_equipment_change ) && self HasWeapon( self.prev_weapon_before_equipment_change ) )
			{
				if ( self.prev_weapon_before_equipment_change != self GetCurrentWeapon() )
				{
					self SwitchToWeapon( self.prev_weapon_before_equipment_change );

					self waittill( "weapon_change_complete" );
				}
			}
			else
			{
				primaryWeapons = self GetWeaponsListPrimaries();
				if ( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
				{
					if ( primaryWeapons[0] != self GetCurrentWeapon() )
					{
						self SwitchToWeapon( primaryWeapons[0] );

						self waittill( "weapon_change_complete" );
					}
				}
				else
				{
					// need to switch away from the mask somehow
					self SwitchToWeapon( get_player_melee_weapon() );
				}
			}
		}

		if ( !self maps\_laststand::player_is_in_laststand() && !is_true( self.intermission ) )
		{
			self decrement_is_drinking();
		}

		self notify("equipment_select_response_done");
	}
}

remove_gasmask_on_player_bleedout()
{
	self SetClientFlag( level._CF_PLAYER_GASMASK_OVERLAY_REMOVE );
	wait_network_frame();
	wait_network_frame();
	self ClearClientFlag( level._CF_PLAYER_GASMASK_OVERLAY_REMOVE );
}

remove_gasmask_on_game_over()
{
	self endon("equip_gasmask_zm_taken");
	level waittill("pre_end_game");

	self clearclientflag(level._CF_PLAYER_GASMASK_OVERLAY);


}



gasmask_active()
{
	return(self maps\_zombiemode_equipment::is_equipment_active("equip_gasmask_zm"));
}

gasmask_debug_print( msg, color )
{
/#
	if ( !GetDvarInt( #"scr_gasmask_debug" ) )
	{
		return;
	}

	if ( !isdefined( color ) )
	{
		color = (1, 1, 1);
	}

	Print3d(self.origin + (0,0,60), msg, color, 1, 1, 40); // 10 server frames is 1 second
#/
}
