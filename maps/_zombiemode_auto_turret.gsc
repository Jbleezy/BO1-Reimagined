#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	level.auto_turret_array = GetEntArray( "auto_turret_trigger", "script_noteworthy" );

	if( !isDefined( level.auto_turret_array ) )
	{
		return;
	}
	else if( level.mutators["mutator_noTraps"] )
	{
		for( i = 0; i < level.auto_turret_array.size; i++ )
		{
			level.auto_turret_array[i] disable_trigger();
		}
	}

	level.curr_auto_turrets_active = 0;

	if( !isDefined( level.max_auto_turrets_active ) )
	{
		level.max_auto_turrets_active = 2;
	}

	if( !isDefined( level.auto_turret_cost ) )
	{
		level.auto_turret_cost = 1500;
	}

	if( !isDefined( level.auto_turret_timeout ) )
	{
		level.auto_turret_timeout = 30;
	}

	for( i = 0; i < level.auto_turret_array.size; i++ )
	{
		level.auto_turret_array[i] SetCursorHint( "HINT_NOICON" );
		level.auto_turret_array[i] sethintstring( &"ZOMBIE_NEED_POWER" );
		level.auto_turret_array[i] UseTriggerRequireLookAt();
		level.auto_turret_array[i].curr_time = -1;
		level.auto_turret_array[i].turret_active = false;
		level.auto_turret_array[i] thread auto_turret_think();
	}
}

auto_turret_think()
{
	if( !isDefined( self.target ) )
	{
		return;
	}

	turret_array = GetEntArray( self.target, "targetname" );

	if(IsDefined(self.target))
	{
		for(i=0;i<turret_array.size;i++)
		{
			if(turret_array[i].model == "zombie_zapper_handle")
			{
				self.handle = turret_array[i];
			}
			else if(turret_array[i].classname == "misc_turret")
			{
				self.turret = turret_array[i];
			}
		}
	}

	self.turret SetDefaultDropPitch( -35 );

	if( !isDefined( self.turret ) )
	{
		return;
	}

	self.turret SetConvergenceTime( 0.3 );
	self.turret SetTurretTeam( "allies" );
	self.turret MakeTurretUnusable();

	self.audio_origin = self.origin;

	flag_wait("power_on");


	for( ;; )
	{
		self.owner = undefined;

		cost = level.auto_turret_cost;
		self SetHintString( &"ZOMBIE_AUTO_TURRET", cost );
//		self thread add_teampot_icon();

		self waittill( "trigger", player );
		index = maps\_zombiemode_weapons::get_player_index(player);

		if (player maps\_laststand::player_is_in_laststand() )
		{
			continue;
		}

		if(player in_revive_trigger())
		{
			continue;
		}

		//players = get_players();
//		if ( (players.size == 1 && player.score < cost) ||
//			 (players.size > 1 && level.team_pool[player.team_num].score < cost) )
		if(player.score < cost)
		{
			//player iprintln( "Not enough points to buy Perk: " + perk );
			self playsound("deny");
			player thread play_no_money_turret_dialog();
			continue;
		}

		player maps\_zombiemode_score::minus_to_player_score( cost );
		self.owner = player;

		bbPrint( "zombie_uses: playername %s playerscore %d teamscore %d round %d cost %d name %s x %f y %f z %f type autoturret", player.playername, player.score, level.team_pool[ player.team_num ].score, level.round_number, cost, self.target, self.origin );

        if( IsDefined( player ) )
		{
            player maps\_zombiemode_audio::create_and_play_dialog( "general", "turret_active" );
        }

		self thread auto_turret_activate();
		self PlaySound( "zmb_turret_startup" );

		self disable_trigger();

		self waittill( "turret_deactivated" );

		if( IsDefined( player ) )
		{
		    //Play the turret inactive vox
		    player maps\_zombiemode_audio::create_and_play_dialog( "general", "turret_inactive" );
		}

	    playsoundatposition( "zmb_turret_down", self.audio_origin );

		self enable_trigger();
	}
}


activate_move_handle()
{
	if(IsDefined(self.handle))
	{
		if(IsDefined(self.handle.rotating) && self.handle.rotating)
			self.handle waittill( "rotatedone" );

		// Rotate switch model
		self.handle rotatepitch( 160, .5 );
		//self.handle playsound( "amb_sparks_l_b" );
		self.handle.rotating = true;
		self.handle waittill( "rotatedone" );
		self.handle.rotating = false;

		self notify( "switch_activated" );
		self waittill( "turret_deactivated" );

		self.handle rotatepitch( -160, .5 );
		self.handle.rotating = true;
		self.handle waittill( "rotatedone" );
		self.handle.rotating = false;
	}
}

play_no_money_turret_dialog()
{

}

auto_turret_activate()
{
	self endon( "turret_deactivated" );

	self thread activate_move_handle();
	self waittill( "switch_activated" );

	if( level.max_auto_turrets_active <= 0 )
	{
		return;
	}

	while( level.curr_auto_turrets_active >= level.max_auto_turrets_active )
	{
		worst_turret = undefined;
		worst_turret_time = -1;
		for( i = 0; i < level.auto_turret_array.size; i++ )
		{
			if( level.auto_turret_array[i] == self )
			{
				continue;
			}

			if( !level.auto_turret_array[i].turret_active )
			{
				continue;
			}

			if( worst_turret_time < 0 || level.auto_turret_array[i].curr_time < worst_turret_time )
			{
				worst_turret = level.auto_turret_array[i];
				worst_turret_time = level.auto_turret_array[i].curr_time;
			}
		}
		if( isDefined( worst_turret ) )
		{
			worst_turret auto_turret_deactivate();
		}
		else
		{
			assertex( false, "Couldn't free an auto turret to activate another, this should never be the case" );
		}
	}

	self.turret SetMode( "auto_nonai" );
	self.turret thread maps\_mgturret::burst_fire_unmanned();
	self.turret_active = true;

	self.turret_fx = Spawn( "script_model", self.turret.origin );
	self.turret_fx SetModel( "tag_origin" );
	self.turret_fx.angles = self.turret.angles;
	PlayFxOnTag( level._effect["auto_turret_light"], self.turret_fx, "tag_origin" );

	self.curr_time = level.auto_turret_timeout;

	self thread auto_turret_update_timeout();

	wait( level.auto_turret_timeout );

	self auto_turret_deactivate();
}

auto_turret_deactivate()
{
	self.turret_active = false;
	self.curr_time = -1;
	self.turret SetMode( "auto_ai" );
	self.turret notify( "stop_burst_fire_unmanned" );

	self.turret_fx delete();

	self notify( "turret_deactivated" );
}

auto_turret_update_timeout()
{
	self endon( "turret_deactivated" );

	while( self.curr_time > 0 )
	{
		wait( 1 );
		self.curr_time--;
	}
}
