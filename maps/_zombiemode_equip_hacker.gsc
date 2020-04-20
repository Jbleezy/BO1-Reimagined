

#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

/*
 * Hacker tool script struct values of interest
 *
 * script_noteworthy:  hackable_*
 *
 * script_int: 		cost
 * script_float: 	time in seconds
 * targetname:		If set, will be filled in with the 'owner' struct or ent of the hackable struct, so that we can get access to any 'useful'
 *								data in there.
 *								Also, the hacker tool will send a "hacked" notify to that ent or struct on successful hack.
 * radius:  			If set, used for the hacker tool activation radius
 * height:				If set, used for the hacker tool activation radius
 *
 */


// Utility functions

// register_hackable("targetname", ::function_to_call_on_hack);
// deregister_hackable(struct);
// deregister_hackable("script_noteworthy");

init()
{
	if ( !maps\_zombiemode_equipment::is_equipment_included( "equip_hacker_zm" ) )
	{
		return;
	}

	maps\_zombiemode_equipment::register_equipment( "equip_hacker_zm", &"ZOMBIE_EQUIP_HACKER_PICKUP_HINT_STRING", &"ZOMBIE_EQUIP_HACKER_HOWTO", "hacker" );

	level._hackable_objects = [];
	level._pooled_hackable_objects = [];

	level thread hacker_on_player_connect();

	level thread hack_trigger_think();

	level thread hacker_trigger_pool_think();

	//level thread hacker_round_reward();

	//level thread hacker_on_zombies();

	if(GetDvarInt(#"scr_debug_hacker") == 1)
	{
		level thread hacker_debug();
	}
}

hacker_round_reward()
{
	while(1)
	{
		level waittill("end_of_round" );

		if(!IsDefined(level._from_nml))
		{
			players = get_players();

			for(i = 0; i < players.size; i ++)
			{
				if(IsDefined(players[i] get_player_equipment()) && players[i] get_player_equipment() == "equip_hacker_zm")
				{
					if(IsDefined(players[i].equipment_got_in_round["equip_hacker_zm"]))
					{
						got_in_round = players[i].equipment_got_in_round["equip_hacker_zm"];

						rounds_kept = level.round_number - got_in_round;

						rounds_kept -= 1;

						if(rounds_kept > 0)
						{
							rounds_kept = min(rounds_kept, 5);

							score = rounds_kept * 500;

							players[i] maps\_zombiemode_score::add_to_player_score( Int(score) );
						}
					}
				}
			}
		}
		else
		{
			level._from_nml = undefined;
		}
	}
}

hacker_debug()
{
	while(1)
	{
		for(i = 0; i < level._hackable_objects.size; i ++)
		{
			hackable = level._hackable_objects[i];

			if(IsDefined(hackable.pooled) && hackable.pooled)
			{
				if(IsDefined(hackable._trigger))
				{
					col = (0,255,0);

					if(IsDefined(hackable.custom_debug_color))
					{
						col = hackable.custom_debug_color;
					}

					Print3d(hackable.origin, "+", col, 1, 1);
				}
				else
				{
					Print3d(hackable.origin, "+", (0,0,255), 1, 1);
				}
			}
			else
			{
				Print3d(hackable.origin, "+", (255,0,0), 1, 1);
			}
		}
		wait(0.1);
	}
}

hacker_trigger_pool_think()
{

	if(!IsDefined(level._zombie_hacker_trigger_pool_size))
	{
		level._zombie_hacker_trigger_pool_size = 8;
	}

	pool_active = false;

	level._hacker_pool = [];

	while(1)
	{
		if(pool_active)
		{
			if(!any_hackers_active())
			{
				destroy_pooled_items();
			}
			else
			{
				sweep_pooled_items();

				add_eligable_pooled_items();

			}
		}
		else
		{
			if(any_hackers_active())
			{
				pool_active = true;
			}
		}

		wait(0.1);
	}

}

destroy_pooled_items()
{
	pool_active = false;

	for(i = 0; i < level._hacker_pool.size; i ++)
	{
		level._hacker_pool[i]._trigger Delete();
		level._hacker_pool[i]._trigger = undefined;
	}

	level._hacker_pool = [];
}

sweep_pooled_items()
{
	// clear out any pooled triggers that are no longer eligable.

	new_hacker_pool = [];

	for(i = 0; i < level._hacker_pool.size; i ++)
	{
		if(level._hacker_pool[i] should_pooled_object_exist())
		{
			new_hacker_pool[new_hacker_pool.size] = level._hacker_pool[i];
		}
		else
		{
			level._hacker_pool[i]._trigger Delete();
			level._hacker_pool[i]._trigger = undefined;
		}
	}

	level._hacker_pool = new_hacker_pool;
}

should_pooled_object_exist()
{
	players = get_players();

	for(i = 0; i < players.size; i ++)
	{
		if(players[i] hacker_active())
		{
			if(IsDefined(self.entity))
			{
				if(self.entity != players[i])
				{
					if(distance2dsquared(players[i].origin, self.entity.origin) <= (self.radius * self.radius))
					{
						return true;
					}
				}
			}
			else
			{
				if(distance2dsquared(players[i].origin, self.origin) <= (self.radius * self.radius))
				{
					return true;
				}
			}
		}
	}

	return false;
}

add_eligable_pooled_items()
{

	candidates = [];

	for(i = 0; i < level._hackable_objects.size; i ++)
	{
		hackable = level._hackable_objects[i];

		if(IsDefined(hackable.pooled) && hackable.pooled && !IsDefined(hackable._trigger))
		{
			if(!is_in_array(level._hacker_pool, hackable))
			{
				if(hackable should_pooled_object_exist())
				{
					candidates[candidates.size] = hackable;
				}
			}
		}
	}

	for(i = 0; i < candidates.size; i ++)
	{
		candidate = candidates[i];

		height = 72;
		radius = 32;

		if(IsDefined(candidate.radius))
		{
			radius = candidate.radius;
		}

		if(IsDefined(candidate.height))
		{
			height = candidate.height;
		}

		trigger = Spawn( "trigger_radius", candidate.origin, 0, radius, height);
		trigger UseTriggerRequireLookAt();
		trigger SetCursorHint( "HINT_NOICON" );
		trigger.radius = radius;
		trigger.height = height;
		trigger.beingHacked = false;

		candidate._trigger = trigger;

		level._hacker_pool[level._hacker_pool.size] = candidate;
	}

}

any_hackers_active()
{
	players = get_players();

	for(i = 0; i < players.size; i ++)
	{
		if(players[i] hacker_active())
		{
			return true;
		}
	}

	return false;
}

register_hackable(name, callback_func, qualifier_func)
{
	structs = getstructarray(name, "script_noteworthy");

	if(!IsDefined(structs))
	{
		/#
		PrintLn("Error:  register_hackable called on script_noteworthy " + name + " but no such structs exist.");
		#/
		return;
	}

	for(i = 0; i < structs.size; i ++)
	{
		if(!is_in_array(level._hackable_objects, structs[i]))
		{
			structs[i]._hack_callback_func = callback_func;
			structs[i]._hack_qualifier_func = qualifier_func;

			structs[i].pooled = level._hacker_pooled;

			if(IsDefined(structs[i].targetname))
			{
				structs[i].hacker_target = GetEnt(structs[i].targetname, "targetname");
			}

			level._hackable_objects[level._hackable_objects.size] = structs[i];

			if(IsDefined(level._hacker_pooled))
			{
				level._pooled_hackable_objects[level._pooled_hackable_objects.size] = structs[i];
			}

			structs[i] thread hackable_object_thread();
			wait_network_frame();
		}
	}
}

register_hackable_struct(struct, callback_func, qualifier_func)
{

	if(!is_in_array(level._hackable_objects, struct))
	{
		struct._hack_callback_func = callback_func;
		struct._hack_qualifier_func = qualifier_func;

		struct.pooled = level._hacker_pooled;

		if(IsDefined(struct.targetname))
		{
			struct.hacker_target = GetEnt(struct.targetname, "targetname");
		}

		level._hackable_objects[level._hackable_objects.size] = struct;

		if(IsDefined(level._hacker_pooled))
		{
			level._pooled_hackable_objects[level._pooled_hackable_objects.size] = struct;
		}

		struct thread hackable_object_thread();
	}
}

register_pooled_hackable_struct(struct, callback_func, qualifier_func)
{
	level._hacker_pooled = true;

	register_hackable_struct(struct, callback_func, qualifier_func);

	level._hacker_pooled = undefined;
}


register_pooled_hackable(name, callback_func, qualifier_func)
{
	level._hacker_pooled = true;

	register_hackable(name, callback_func, qualifier_func);

	level._hacker_pooled = undefined;
}

deregister_hackable_struct(struct)
{
	if(is_in_array(level._hackable_objects, struct))
	{
		new_list = [];

		for(i = 0; i < level._hackable_objects.size; i ++)
		{
			if(level._hackable_objects[i] != struct)
			{
				new_list[new_list.size] = level._hackable_objects[i];
			}
			else
			{
				level._hackable_objects[i] notify("hackable_deregistered");

				if(IsDefined(level._hackable_objects[i]._trigger))
				{
					level._hackable_objects[i]._trigger Delete();
				}

				if(IsDefined(level._hackable_objects[i].pooled) && level._hackable_objects[i].pooled)
				{
					level._hacker_pool = array_remove(level._hacker_pool, level._hackable_objects[i]);
					level._pooled_hackable_objects = array_remove(level._pooled_hackable_objects, level._hackable_objects[i]);
				}

			}
		}

		level._hackable_objects = new_list;
	}
}

deregister_hackable(noteworthy)
{
	new_list = [];

	for(i = 0; i < level._hackable_objects.size; i ++)
	{
		if(!IsDefined(level._hackable_objects[i].script_noteworthy) || level._hackable_objects[i].script_noteworthy != noteworthy)
		{
			new_list[new_list.size] = level._hackable_objects[i];
		}
		else
		{
			level._hackable_objects[i] notify("hackable_deregistered");

			if(IsDefined(level._hackable_objects[i]._trigger))
			{
				level._hackable_objects[i]._trigger Delete();
			}
		}

		if(IsDefined(level._hackable_objects[i].pooled) && level._hackable_objects[i].pooled)
		{
			level._hacker_pool = array_remove(level._hacker_pool, level._hackable_objects[i]);
		}
	}

	level._hackable_objects = new_list;
}

hack_trigger_think()
{
	while(1)
	{
		players = get_players();
		for( i = 0; i < players.size; i++ )
		{
			player = players[i];

			for(j = 0; j < level._hackable_objects.size; j ++)
			{
				hackable = level._hackable_objects[j];

				if(IsDefined(hackable._trigger))
				{
					qualifier_passed = true;

					if(IsDefined(hackable._hack_qualifier_func))
					{
						qualifier_passed = hackable [[hackable._hack_qualifier_func]](player);
					}

					if ( player hacker_active() && qualifier_passed && !hackable._trigger.beingHacked)
					{
						hackable._trigger SetInvisibleToPlayer( player, false );
					}
					else
					{
						hackable._trigger SetInvisibleToPlayer( player, true );
					}
				}
			}
		}
		wait( 0.1 );
	}
}

is_facing( facee )
{
	orientation = self getPlayerAngles();
	forwardVec = anglesToForward( orientation );
	forwardVec2D = ( forwardVec[0], forwardVec[1], 0 );
	unitForwardVec2D = VectorNormalize( forwardVec2D );

	toFaceeVec = facee.origin - self.origin;
	toFaceeVec2D = ( toFaceeVec[0], toFaceeVec[1], 0 );
	unitToFaceeVec2D = VectorNormalize( toFaceeVec2D );

	dotProduct = VectorDot( unitForwardVec2D, unitToFaceeVec2D );

	dot_limit = 0.8;

	if(IsDefined(facee.dot_limit))
	{
		dot_limit = facee.dot_limit;
	}

	return ( dotProduct > dot_limit ); // reviver is facing within a ~52-degree cone of the player
}

can_hack( hackable )
{
	if ( !isAlive( self ) )
	{
		return false;
	}

	if ( self maps\_laststand::player_is_in_laststand() )
	{
		return false;
	}

	if(!self hacker_active() )
	{
		return false;
	}

	if( !isDefined( hackable._trigger ) )
	{
		return false;
	}

	if( IsDefined(hackable.player) )
	{
		if(hackable.player != self)
		{
			return false;
		}
	}

	if(IsDefined(hackable._hack_qualifier_func))
	{
		if(!hackable [[hackable._hack_qualifier_func]](self))
		{
			return false;
		}
	}

	if( !is_in_array( level._hackable_objects, hackable ) )
	{
		return false;
	}

	radsquared = 64 * 64;

	if(IsDefined(hackable.radius))
	{
		radsquared = hackable.radius * hackable.radius;
	}

	origin = hackable.origin;

	if(IsDefined(hackable.entity))
	{
		origin = hackable.entity.origin;
	}

	if(distance2dsquared(self.origin, origin) > radsquared)
	{
		return false;
	}

	/*if ( !IsDefined(hackable.no_touch_check) && !self IsTouching( hackable._trigger ) )
	{
		return false;
	}*/

	if ( !self is_facing( hackable ) )
	{
		return false;
	}

	if( !IsDefined(hackable.no_sight_check) && !SightTracePassed( self.origin + ( 0, 0, 50 ), origin, false, undefined ) )
	{
		return false;
	}

	if( !IsDefined(hackable.no_bullet_trace) && !bullettracepassed(self.origin + (0,0,50), origin, false, undefined) )
	{
		return false;
	}

	if(IsDefined(self.hackable_being_hacked) && self.hackable_being_hacked != hackable)
	{
		return false;
	}

	return true;
}

is_hacking( hackable )
{
	return ( self can_hack( hackable ) && self UseButtonPressed() );
}

set_hack_hint_string()
{
	if(IsDefined(self._trigger))
	{
		if(IsDefined(self.custom_string))
		{
			self._trigger SetHintString(self.custom_string);
		}
		else
		{
			if(!IsDefined(self.script_int) || self.script_int <= 0)
			{
				self._trigger SetHintString(&"ZOMBIE_HACK_NO_COST");
			}
			else
			{
				self._trigger SetHintString(&"ZOMBIE_HACK", self.script_int);
			}
		}
	}
}

tidy_on_deregister(hackable)
{
	self endon("clean_up_tidy_up");
	hackable waittill("hackable_deregistered");

	if( isdefined( self.hackerProgressBar ) )
	{
		self.hackerProgressBar maps\_hud_util::destroyElem();
	}

	if( isdefined( self.hackerTextHud ) )
	{
		self.hackerTextHud destroy();
	}

	self.hackable_being_hacked = undefined;
}

hacker_do_hack( hackable )
{
//	assert( self is_reviving( playerBeingRevived ) );
	// reviveTime used to be set from a Dvar, but this can no longer be tunable:
	// it has to match the length of the third-person revive animations for
	// co-op gameplay to run smoothly.

	timer = 0;
	hacked = false;

	hackable._trigger.beingHacked = true;
	self.hackable_being_hacked = hackable;

	if( !isdefined(self.hackerProgressBar) )
	{
		self.hackerProgressBar = self maps\_hud_util::createPrimaryProgressBar();
	}

	if( !isdefined(self.hackerTextHud) )
	{
		self.hackerTextHud = newclientHudElem( self );
	}

	hack_duration = hackable.script_float;

	/*if(self hasperk( "specialty_fastreload"))
	{
		hack_duration *= 0.66;
	}*/

	hack_duration = max(1.5, hack_duration);

	self thread tidy_on_deregister(hackable);
	self.hackerProgressBar maps\_hud_util::updateBar( 0.01, 1 / hack_duration );

	self.hackerTextHud.alignX = "center";
	self.hackerTextHud.alignY = "middle";
	self.hackerTextHud.horzAlign = "center";
	self.hackerTextHud.vertAlign = "bottom";
	self.hackerTextHud.y = -113;
	if ( IsSplitScreen() )
	{
		self.hackerTextHud.y = -107;
	}
	self.hackerTextHud.foreground = true;
	self.hackerTextHud.font = "default";
	self.hackerTextHud.fontScale = 1.8;
	self.hackerTextHud.alpha = 1;
	self.hackerTextHud.color = ( 1.0, 1.0, 1.0 );
	self.hackerTextHud setText( &"ZOMBIE_HACKING" );

	//self playsound( "vox_mcomp_hack_inprogress" );
	self playloopsound( "zmb_progress_bar", .5 );

	//chrisp - zombiemode addition for reviving vo
	// cut , but leave the script just in case
	//self thread say_reviving_vo();

	self thread hacker_stop_loop_sound(hackable);

	while( self is_hacking ( hackable ) )
	{
		wait( 0.05 );
		timer += 0.05;

		if ( self maps\_laststand::player_is_in_laststand() )
		{
			break;
		}

		if( timer >= hack_duration)
		{
			hacked = true;
			break;
		}

	}

	if( hacked )
	{
		self playsound( "vox_mcomp_hack_success" );
	}
	else
	{
		self playsound( "vox_mcomp_hack_fail" );
	}

	if( isdefined( self.hackerProgressBar ) )
	{
		self.hackerProgressBar maps\_hud_util::destroyElem();
	}

	if( isdefined( self.hackerTextHud ) )
	{
		self.hackerTextHud destroy();
	}

	hackable set_hack_hint_string();

	if(IsDefined(hackable._trigger))
	{
		hackable._trigger.beingHacked = false;
	}

	self.hackable_being_hacked = undefined;

	self notify("clean_up_tidy_up");

	return hacked;
}

hacker_stop_loop_sound(hackable)
{
	while( self is_hacking ( hackable ) )
	{
		wait .05;
	}
	self stoploopsound( .5 );
}

lowreadywatcher(player)
{
	player endon("disconnected");
	self endon("kill_lowreadywatcher");
	self waittill("hackable_deregistered");

	player setlowready(0);
	player AllowMelee(true);
}

hackable_object_thread()
{
	self endon("hackable_deregistered");

	height = 72;
	radius = 64;

	if(IsDefined(self.radius))
	{
		radius = self.radius;
	}

	if(IsDefined(self.height))
	{
		height = self.height;
	}

	if(!IsDefined(self.pooled))
	{
		trigger = Spawn( "trigger_radius", self.origin, 0, radius, height);
		trigger UseTriggerRequireLookAt();
		trigger SetCursorHint( "HINT_NOICON" );
		trigger.radius = radius;
		trigger.height = height;
		trigger.beingHacked = false;

		self._trigger = trigger;
	}

	cost = 0;

	if(IsDefined(self.script_int))
	{
		cost = self.script_int;
	}

	duration = 1.0;

	if(IsDefined(self.script_float))
	{
		duration = self.script_float;
	}

	while(1)
	{
		wait(0.1);

		if(!IsDefined(self._trigger))
		{
			continue;
		}

		players = get_players();

		if(IsDefined(self._trigger))
		{
			self._trigger SetHintString("");

			if(IsDefined(self.entity))
			{
				self.origin = self.entity.origin;
				self._trigger.origin = self.entity.origin;

				if(IsDefined(self.trigger_offset))
				{
					self._trigger.origin += self.trigger_offset;
				}
			}
		}

		for ( i = 0; i < players.size; i++ )
		{
			if ( players[i] can_hack( self ) )
			{
				self set_hack_hint_string();
				break;
			}
		}

		for ( i = 0; i < players.size; i++ )
		{
			hacker = players[i];

			if ( !hacker is_hacking( self ) )
			{
				continue;
			}


			if( hacker.score >= cost || cost <= 0)
			{

				hacker setlowready(1);
				hacker AllowMelee(false);

				self thread lowreadywatcher(hacker);

				hack_success = hacker hacker_do_hack( self );

				self notify("kill_lowreadywatcher");
				if(IsDefined(hacker))
				{
					hacker setlowready(0);
					hacker AllowMelee(true);
				}

				if(IsDefined(hacker) && hack_success)
				{
					if(cost)
					{
						if(cost > 0)
						{
							hacker maps\_zombiemode_score::minus_to_player_score( cost );
						}
						else
						{
							hacker maps\_zombiemode_score::add_to_player_score( cost * -1 );
						}
					}

					hacker notify( "successful_hack" );
					if(IsDefined(self._hack_callback_func))
					{
						self thread [[self._hack_callback_func]](hacker);	// may well terminate this thread.
					}

				}
			}
			else
			{
				hacker play_sound_on_ent( "no_purchase" );
				hacker maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 1 );
			}
		}
	}
}

hacker_on_zombies()
{
	flag_wait("all_players_spawned");
	while(1)
	{
		zombs = GetAiSpeciesArray( "axis", "all" );
		for(i=0;i<zombs.size;i++)
		{
			if(!IsDefined(zombs[i].can_be_hacked) && (zombs[i].animname != "astro_zombie"))
			{
				zombs[i].can_be_hacked = true;

				struct = SpawnStruct();
				struct.origin = zombs[i].origin;
				struct.radius = 96;
				struct.height = 96;
				struct.script_float = 1.5;
				struct.script_int = 0;
				struct.entity = zombs[i];
				struct.trigger_offset = (0,0,40);

				register_pooled_hackable_struct(struct, ::zombie_hack, ::zombie_qualifier);

				struct thread zombie_hack_death_watcher();
			}
		}
		wait .05;
	}
}

zombie_hack(hacker)
{
	self.entity.no_powerups = true;
	self.entity DoDamage( self.entity.health + 1000, self.entity.origin, hacker );

	/*self.entity endon("death");

	self.entity notify( "stop_find_flesh" );
	self.entity notify( "zombie_acquire_enemy" );
	self.entity.ignoreall = true;

	points = int(10 * self.zombie_vars["zombie_point_scalar"]);
	hacker maps\_zombiemode_score::add_to_player_score( points );
	self.entity thread maps\_zombiemode_spawner::do_a_taunt();

	health = self.entity.health;

	while(self.entity.health == health && is_true(self.entity.is_taunting))
	{
		wait_network_frame();
	}

	self.entity.is_taunting = false;
	self.entity.ignoreall = false;
	self.entity StopAnimScripted();
	self.entity thread maps\_zombiemode_spawner::find_flesh();*/
}

zombie_qualifier()
{
	return true;
}

zombie_hack_death_watcher()
{
	self.entity waittill("death");
	deregister_hackable_struct(self);
}

hacker_on_player_connect()
{
	for( ;; )
	{
		level waittill( "connecting", player );

		struct = SpawnStruct();
		struct.origin = player.origin;
		struct.radius = 48;
		struct.height = 64;
		struct.script_float = 1.5;
		struct.script_int = 500;
		struct.entity = player;
		struct.trigger_offset = (0,0,48);

		register_pooled_hackable_struct(struct, ::player_hack, ::player_qualifier);

		struct thread player_hack_disconnect_watcher(player);
	}
}

player_hack_disconnect_watcher(player)
{
	player waittill("disconnect");
	deregister_hackable_struct(self);
}

player_hack(hacker)
{
	if(IsDefined(self.entity))
	{
		self.entity maps\_zombiemode_score::player_add_points( "hacker_transfer", 500 );
	}

	if( isdefined( hacker ) )
	{
		hacker thread maps\_zombiemode_audio::create_and_play_dialog( "general", "hack_plr" );
	}
}

player_qualifier(player)
{
	if(player == self.entity)
	{
		return false;		// No hack self.
	}

	if(self.entity maps\_laststand::player_is_in_laststand())
	{
		return false;
	}

	if(player maps\_laststand::player_is_in_laststand())
	{
		return false;
	}

	if(is_true(self.entity.sessionstate == "spectator"))
	{
		return false;
	}

	return true;
}

hide_hint_when_hackers_active(custom_logic_func, custom_logic_func_param)
{
	invis_to_any = 0;

	while(1)
	{
		if(IsDefined(custom_logic_func))
		{
			self [[custom_logic_func]](custom_logic_func_param);
		}

		if(maps\_zombiemode_equip_hacker::any_hackers_active())
		{
			players = get_players();

			for(i = 0; i < players.size; i ++)
			{
				if ( players[i] hacker_active() )
				{
					self SetInvisibleToPlayer( players[i], true );
					invis_to_any = 1;
				}
				else
				{
					self SetInvisibleToPlayer( players[i], false );
				}
			}
		}
		else
		{
			if(invis_to_any)
			{
				invis_to_any = 0;
				players = get_players();

				for(i = 0; i < players.size; i ++)
				{
					self SetInvisibleToPlayer( players[i], false );
				}
			}
		}
		wait(0.1);
	}
}

hacker_debug_print( msg, color )
{
/#
	if ( !GetDvarInt( #"scr_hacker_debug" ) )
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
