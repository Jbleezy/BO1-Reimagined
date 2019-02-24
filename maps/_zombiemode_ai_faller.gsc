/// _zombiemode_ai_faller.gsc
/// Common location for faller logic

#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree("generic_human");
faller_init()
{
	level._zombie_fall_anims["zombie"] = [];
	level._zombie_fall_anims["zombie"]["default"] = %ai_zombie_jump_down_72;
	level._zombie_fall_anims["zombie"]["emerge"] = %ai_zombie_ceiling_emerge_01;
	level._zombie_fall_anims["zombie"]["fall"] = %ai_zombie_ceiling_dropdown_01;
	level._zombie_fall_anims["zombie"]["fall_loop"] = %ai_zombie_ceiling_fall_loop;
	level._zombie_fall_anims["zombie"]["land"][0] = %ai_zombie_ceiling_fall_land;
	level._zombie_fall_anims["zombie"]["land"][1] = %ai_zombie_ceiling_fall_land_02;
	level._zombie_fall_anims["zombie"]["attack"][0] = %ai_zombie_ceiling_attack_01;
	level._zombie_fall_anims["zombie"]["attack"][1] = %ai_zombie_ceiling_attack_02;
	level._zombie_fall_anims["zombie"]["emerge_death"] = %ai_zombie_ceiling_death;

	// setup the default callback
	level.zombie_custom_think_logic = ::check_do_zombie_fall;

	// setup the faller locations once the zones have been initialized
	level thread setup_faller_locations();
}

setup_faller_locations()
{
	flag_wait("zones_initialized");

	zkeys = GetArrayKeys(level.zones);
	for ( i = 0; i < level.zones.size; i++ )
	{
		zone = level.zones[ zkeys[i] ];

		if ( IsDefined( zone.volumes[0].target ) )
		{
			zone.fall_locations = GetStructArray(zone.volumes[0].target + "_fall", "targetname");
			for ( x = 0; x < zone.fall_locations.size; x++ )
			{
				zone.fall_locations[x].is_enabled = true;
			}
		}
	}
}

get_available_fall_locations()
{
	level.zombie_fall_spawners  = [];
	zone = level.zones[ self.zone_name ];
	if ( IsDefined( zone ) )
	{
		// add zombie_fall locations
		for(x=0; x<zone.fall_locations.size; x++)
		{
			if ( zone.fall_locations[x].is_enabled )
			{
				level.zombie_fall_spawners[ level.zombie_fall_spawners.size ] = zone.fall_locations[x];
			}
		}
	}
	else
	{
		spots = GetStructArray("zombie_fall", "targetname");
		for(x=0; x<spots.size; x++)
		{
			if ( spots[x].is_enabled )
			{
				level.zombie_fall_spawners[ level.zombie_fall_spawners.size ] = spots[x];
			}
		}
	}

	return level.zombie_fall_spawners;
}


round_spawning_fall_test()
{
	while (true)
	{
		spawn_points = [];
		for ( i = 0; i < level.enemy_spawns.size; i++ )
		{
			spawner = level.enemy_spawns[i];
			if ( IsDefined(spawner.script_string) && spawner.script_string == "faller" )
			{
				spawn_points[spawn_points.size] = spawner;
			}
		}

		// grab the spawn point closest to the first player
		player = GetPlayers()[0];
		bestPoint = undefined;
		bestDist = 0.0;
		for ( i = 0; i < spawn_points.size; i++ )
		{
			checkDist = DistanceSquared(spawn_points[i].origin, player.origin);
			if ( !IsDefined(bestPoint) || checkDist < bestDist )
			{
				bestPoint = spawn_points[i];
				bestDist = checkDist;
			}
		}

		if ( IsDefined(bestPoint) )
		{
			ai = spawn_zombie( bestPoint );
			ai waittill("death");
		}

		wait 5;
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

check_do_zombie_fall()
{
	if ( (GetDvarInt( #"zombie_fall_test") || (IsDefined(self.script_string) && self.script_string == "faller")))
	{
		self thread do_zombie_fall();
		return true;
	}

	return false;
}

zombie_faller_delete()
{
	level.zombie_total++;
	self maps\_zombiemode_spawner::reset_attack_spot();
	if ( IsDefined( self.zombie_faller_location ) )
	{
		self.zombie_faller_location.is_enabled = true;
		self.zombie_faller_location = undefined;
	}
	self Delete();
}

parse_script_parameters()
{
	if ( IsDefined( self.script_parameters ) )
	{
		parms = strtok( self.script_parameters, ";" );
		if ( IsDefined( parms ) && parms.size > 0 )
		{
			for ( i = 0; i < parms.size; i++ )
			{
				if ( parms[i] == "drop_now" )
				{
					self.drop_now = true;
				}
				//Drop if zone is not occupied
				if ( parms[i] == "drop_not_occupied" )
				{
					self.drop_not_occupied = true;
				}
			}
		}
	}
}

setup_deathfunc()
{
	self endon( "death" );

	while ( !is_true( self.zombie_init_done ) )
	{
		wait_network_frame();
	}

	// rsh040711 - fixed faller deaths
	self.deathFunction = ::zombie_fall_death_func;
}

do_zombie_fall()
{
	self endon("death");

	self thread setup_deathfunc();

	// don't drop powerups until we are on the ground
	self.no_powerups = true;
	self.in_the_ceiling = true;

	if ( !IsDefined( self.zone_name ) )
	{
		self.zone_name = self get_current_zone();
	}

	spots = get_available_fall_locations();

	if( spots.size < 1 )
	{
		//IPrintLnBold("deleting zombie faller - no available fall locations");
		//can't delete if we're in the middle of spawning, so wait a frame
		self Hide();//hide so we're not visible for one frame while waiting to delete
		self delayThread( 0.1, ::zombie_faller_delete );
		return;
	}
	else if ( GetDvarInt(#"zombie_fall_test") )
	{
		// use the spot closest to the first player always
		player = GetPlayers()[0];
		spot = undefined;
		bestDist = 0.0;
		for ( i = 0; i < spots.size; i++ )
		{
			checkDist = DistanceSquared(spots[i].origin, player.origin);
			if ( !IsDefined(spot) || checkDist < bestDist )
			{
				spot = spots[i];
				bestDist = checkDist;
			}
		}
	}
	else
	{
		spot = random(spots);
	}
	self.zombie_faller_location = spot;
	//NOTE: multiple zombie fallers could be waiting in the same spot now, need to have spawners detect this
	//		and not use the spot again until the previous zombie has died or dropped down
	self.zombie_faller_location.is_enabled = false;
	self.zombie_faller_location parse_script_parameters();

	if( !isDefined( spot.angles ) )
	{
		spot.angles = (0, 0, 0);
	}

	anim_org = spot.origin;
	anim_ang = spot.angles;

	level thread zombie_fall_death(self, spot);
	self thread zombie_faller_death_wait();

	self Hide();
	self.anchor = spawn("script_origin", self.origin);
	self.anchor.angles = self.angles;
	self linkto(self.anchor);
	self.anchor.origin = anim_org;
	// face goal
	target_org = maps\_zombiemode_spawner::get_desired_origin();
	if (IsDefined(target_org))
	{
		anim_ang = VectorToAngles(target_org - self.origin);
		self.anchor.angles = (0, anim_ang[1], 0);
	}
	wait_network_frame();
	self unlink();
	self.anchor delete();
	self thread maps\_zombiemode_spawner::hide_pop();

	spot thread zombie_fall_fx(self);

	//need to thread off the rest because we're apparently still in the middle of our init!
	self thread zombie_faller_do_fall();
}

zombie_faller_do_fall()
{
	self endon("death");

	emerge_anim = self get_fall_emerge_anim();
	// first play the emerge, then the fall anim
	self AnimScripted("fall_emerge", self.zombie_faller_location.origin, self.zombie_faller_location.angles, emerge_anim);
	self animscripts\zombie_shared::DoNoteTracks("fall_emerge", ::handle_fall_notetracks, undefined, self.zombie_faller_location);

	//NOTE: now we don't fall until we've attacked at least once from the ceiling
	self.zombie_faller_wait_start = GetTime();
	self.zombie_faller_should_drop = false;
	self.attacked_times = 0;
	//self thread zombie_fall_wait();
	self thread zombie_faller_watch_all_players();
	while ( !self.zombie_faller_should_drop )
	{
		if(self.attacked_times >= 3)
		{
			self.zombie_faller_should_drop = true;
			break;
		}
		if ( self zombie_fall_should_attack(self.zombie_faller_location) )
		{
			self.attacked_times++;
			attack_anim = self get_attack_anim(self.zombie_faller_location);
			self AnimScripted("attack", self.origin, self.zombie_faller_location.angles, attack_anim);
			self animscripts\zombie_shared::DoNoteTracks("attack", ::handle_fall_notetracks, undefined, self.zombie_faller_location);
			//50/50 chance that we'll stay up here and attack again or drop down
			if ( !(self zombie_faller_always_drop()) && randomfloat(1) > 0.5 )
			{
				//NOTE: if we *can* attack, should we actually stay up here until we can't anymore?
				self.zombie_faller_should_drop = true;
			}
		}
		else
		{
			if ( (self zombie_faller_always_drop()) )
			{
				//drop as soon as we have nobody to attack!
				self.zombie_faller_should_drop = true;
				break;
			}
			//otherwise, wait to attack
			else if ( GetTime() >= self.zombie_faller_wait_start + 20000 )
			{
				//we've been hanging here for 20 seconds, go ahead and drop
				//IPrintLnBold("zombie faller waited too long, dropping");
				self.zombie_faller_should_drop = true;
				break;
			}
			else if ( self zombie_faller_drop_not_occupied() )
			{
				self.zombie_faller_should_drop = true;
				break;
			}
			else
			{
				self.attacked_times++;
				//NOTE: instead of playing a looping idle, they just flail and attack over and over
				attack_anim = self get_attack_anim(self.zombie_faller_location);
				self AnimScripted("attack", self.origin, self.zombie_faller_location.angles, attack_anim);
				self animscripts\zombie_shared::DoNoteTracks("attack", ::handle_fall_notetracks, undefined, self.zombie_faller_location);
				if ( !(self zombie_faller_always_drop()) && randomfloat(1) > 0.5 )
				{
					//NOTE: if we *can* attack, should we actually stay up here until we can't anymore?
					self.zombie_faller_should_drop = true;
				}
			}
		}
	}

	self notify("falling");
	//now the fall location (spot) can be used by another zombie faller again
	spot  = self.zombie_faller_location;
	self zombie_faller_enable_location();

	fall_anim = self get_fall_anim(spot);
	self AnimScripted("fall", self.origin, spot.angles, fall_anim);
	self animscripts\zombie_shared::DoNoteTracks("fall", ::handle_fall_notetracks, undefined, spot);

	// rsh040711 - set the death func back to normal
	self.deathFunction = maps\_zombiemode_spawner::zombie_death_animscript;

	self notify("fall_anim_finished");
	spot notify("stop_zombie_fall_fx");

	//play fall loop
	self StopAnimScripted();
	landAnim = random(level._zombie_fall_anims["zombie"]["land"]);
	// Get Z distance
	landAnimDelta = 15; //GetMoveDelta( landAnim, 0, 1 )[2];//delta in the anim doesn't seem to reflect actual distance to ground correctly
	ground_pos = groundpos_ignore_water_new( self.origin );
	//draw_arrow_time( self.origin, ground_pos, (1, 1, 0), 10 );
	physDist = self.origin[2] - ground_pos[2] + landAnimDelta;

	if ( physDist > 0 )
	{
		//high enough above the ground to play some of the falling loop before we can play the land
		ground_pos = groundpos_ignore_water_new( self.origin );
		if( self.origin[2] - ground_pos[2] >= 20)
		{
			fallAnim = level._zombie_fall_anims["zombie"]["fall_loop"];
			if ( IsDefined( fallAnim ) )
			{
				self.fall_anim = fallAnim;
				self animcustom(::zombie_fall_loop);
				self waittill("faller_on_ground");
			}
		}

		//play land
		self.landAnim = landAnim;
		self animcustom(::zombie_land);
		wait( GetAnimLength( landAnim ) );
	}

	self.in_the_ceiling = false;
	self traverseMode( "gravity" );
	//looks like I have to start this manually?
	self SetAnimKnobAllRestart( animscripts\zombie_run::GetRunAnim(), %body, 1, 0.2, 1 );

	self.no_powerups = false;

	// let the default spawn logic know we are done
	self notify("zombie_custom_think_done", spot.script_noteworthy );

	self notify("land_anim_finished");
}

zombie_fall_loop()
{
	self endon("death");

	self setFlaggedAnimKnobRestart( "fall_loop", self.fall_anim, 1, 0.20, 1.0 );

	while(1)
	{
		ground_pos = groundpos_ignore_water_new( self.origin );
		if( self.origin[2] - ground_pos[2] < 20)
		{
			self notify("faller_on_ground");
			break;
		}
		wait .05;
	}
}

zombie_land()
{
	self setFlaggedAnimKnobRestart( "land", self.landAnim, 1, 0.20, 1.0 );
	wait( GetAnimLength( self.landAnim ) );
}


zombie_faller_always_drop()
{
	if ( IsDefined(self.zombie_faller_location.drop_now) )
	{
		if ( self.zombie_faller_location.drop_now == true )
		{
			return true;
		}
	}
	return false;
}

zombie_faller_drop_not_occupied()
{
	if ( is_true(self.zombie_faller_location.drop_not_occupied) )
	{
		if( isDefined(self.zone_name) && isDefined(level.zones[ self.zone_name ]) )
		{
			return !level.zones[ self.zone_name ].is_occupied;
		}
	}
	return false;
}

//Watchs for players standing in the general area
zombie_faller_watch_all_players()
{
	players = get_players();
	for(i=0; i<players.size; i++)
	{
		self thread zombie_faller_watch_player(players[i]);
	}
}

zombie_faller_watch_player(player)
{
	self endon("falling");
	self endon("death");
	player endon("disconnect");


	range = 200;
	rangeSqr = range*range;

	timer = 5000; //5 seconds

	inRange = false;
	inRangeTime = 0;

	//Used to detect player passing under zombie
	closeRange = 60;
	closeRangeSqr = closeRange*closeRange;
	dirToPlayerEnter = (0,0,0);
	inCloseRange = false;

	while(1)
	{
		//Watch for standing in general area
		distSqr = distance2dsquared(self.origin, player.origin);
		if(distSqr < rangeSqr)
		{
			if(inRange)
			{
				if(inRangeTime+timer < GetTime())
				{
					self.zombie_faller_should_drop = true;
					break;
				}
			}
			else
			{
				inRange = true;
				inRangeTime = GetTime();
			}
		}
		else
		{
			inRange = false;
		}

		//Watch for pass under
		if(distSqr<closeRangeSqr)
		{
			//Just entered range
			if(!inCloseRange)
			{
				dirToPlayerEnter = player.origin - self.origin;
				dirToPlayerEnter = (dirToPlayerEnter[0], dirToPlayerEnter[1], 0.0);
				dirToPlayerEnter = vectornormalize(dirToPlayerEnter);
			}

			inCloseRange = true;
		}
		else
		{
			//Just exited range
			if(inCloseRange)
			{
				dirToPlayerExit = player.origin - self.origin;
				dirToPlayerExit = (dirToPlayerExit[0], dirToPlayerExit[1], 0.0);
				dirToPlayerExit = vectornormalize(dirToPlayerExit);

				if(vectordot(dirToPlayerEnter, dirToPlayerExit) < 0)
				{
					self.zombie_faller_should_drop = true;
					break;
				}
			}

			inCloseRange = false;
		}

		wait .1;
	}
}

zombie_fall_wait()
{
	self endon("falling");
	self endon("death");

	if ( IsDefined( self.zone_name ) )
	{
		if ( IsDefined(level.zones) && IsDefined(level.zones[ self.zone_name ] ) )
		{
			zone = level.zones[ self.zone_name ];
			while ( 1 )
			{
				//no players in an adjacent zone?  Delete me if nobody can see me
				//NOTE: what if he's not in a zone at all?
				if ( (!zone.is_enabled ||!zone.is_active) )
				{
					if ( !(self potentially_visible( 1500 )) )
					{
						if ( self.health != level.zombie_health )
						{
							//took some damage - fall instead of delete
							//IPrintLnBold("damaged zombie faller in inactive zone dropping down");
							self.zombie_faller_should_drop = true;
							break;
						}
						else
						{
							//IPrintLnBold("deleting zombie faller in inactive zone");
							self zombie_faller_delete();
							return;
						}
					}
				}
				wait( 0.5 );
			}
		}
	}
}

zombie_fall_should_attack(spot)
{
	victims = zombie_fall_get_vicitims(spot);
	return victims.size > 0;
}

zombie_fall_get_vicitims(spot)
{
	ret = [];
	players = GetPlayers();

	checkDist2 = 40.0;
	checkDist2 *= checkDist2;
	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if ( player maps\_laststand::player_is_in_laststand() )
		{
			continue;
		}

		// if the player is in crouch or prone, fallers can't attack them
		stance = player GetStance();
		if ( stance == "crouch" || stance == "prone" )
		{
			continue;
		}

		// make sure the player is below us first
		zCheck = self.origin[2] - player.origin[2];
		if ( zCheck < 0.0 || zCheck > 120.0 )
		{
			continue;
		}

		dist2 = Distance2DSquared(player.origin, self.origin);
		if ( dist2 < checkDist2 )
		{
			ret[ret.size] = player;
		}
	}

	return ret;
}

get_fall_emerge_anim(spot)
{
	return level._zombie_fall_anims[self.animname]["emerge"];
}

get_fall_anim(spot)
{
	return level._zombie_fall_anims[self.animname]["fall"];
}

get_attack_anim(spot)
{
	return random(level._zombie_fall_anims[self.animname]["attack"]);
}

zombie_faller_enable_location()
{
	if ( IsDefined( self.zombie_faller_location ) )
	{
		self.zombie_faller_location.is_enabled = true;
		self.zombie_faller_location = undefined;
	}
}

//Wait until we die, then clear our spawn spot so it can be used again
zombie_faller_death_wait()
{
	self waittill( "death" );
	self endon( "falling" );
	//in case we're killed while still hanging out in our location
	self zombie_faller_enable_location();
}

zombie_fall_death_func()
{
	// rsh040711 - set noclip so death anim can translate through the ceiling
	self animmode( "noclip" );
	self.deathanim = level._zombie_fall_anims["zombie"]["emerge_death"];

	return self maps\_zombiemode_spawner::zombie_death_animscript();
}

/*
zombie_fall_death:
Track when the zombie should die, set the death anim, and stop the animscripted so he can die
*/
zombie_fall_death(zombie, spot)
{
	//zombie.zombie_fall_death_out = false;

	zombie endon("fall_anim_finished");

	while (zombie.health > 1)	// health will only go down to 1 when playing animation with AnimScripted()
	{
		zombie waittill("damage", amount, attacker, dir, p, type);
	}

	zombie StopAnimScripted();	//Need to stop anim so we don't get into delayedDeath (native var).
	spot notify("stop_zombie_fall_fx");
}

_damage_mod_to_damage_type(type)
{
	toks = strtok(type, "_");
	if(toks.size<2)
	{
		return type;
	}

	//Throw out "MOD_"
	returnStr = toks[1];

	for(i=2;i<toks.size;i++)
	{
		returnStr += toks[i];
	}

	returnStr = tolower(returnStr);
	return returnStr;
}

/*
zombie_fall_fx:	 self is the script struct at the rise location
Play the fx as the zombie crawls out of the ground and thread another function to handle the dust falling
off when the zombie is out of the ground.
*/
zombie_fall_fx(zombie)
{
	self thread zombie_fall_dust_fx(zombie);
	self thread zombie_fall_burst_fx();
	playsoundatposition ("zmb_zombie_spawn", self.origin);
	zombie endon("death");
	self endon("stop_zombie_fall_fx");
	wait 1;
	if (zombie.zombie_move_speed != "sprint")
	{
		// wait longer before starting billowing fx if it's not a really fast animation
		wait 1;
	}
}

zombie_fall_burst_fx()
{
	self endon("stop_zombie_fall_fx");
	self endon("fall_anim_finished");

	playfx(level._effect["rise_burst"],self.origin + ( 0,0,randomintrange(5,10) ) );
	wait(.25);
	playfx(level._effect["rise_billow"],self.origin + ( randomintrange(-10,10),randomintrange(-10,10),randomintrange(5,10) ) );
}

zombie_fall_dust_fx(zombie)
{
	dust_tag = "J_SpineUpper";

	self endon("stop_zombie_fall_dust_fx");
	self thread stop_zombie_fall_dust_fx(zombie);

	dust_time = 7.5; // play dust fx for a max time
	dust_interval = .1; //randomfloatrange(.1,.25); // wait this time in between playing the effect

	for (t = 0; t < dust_time; t += dust_interval)
	{
		PlayfxOnTag(level._effect["rise_dust"], zombie, dust_tag);
		wait dust_interval;
	}
}

stop_zombie_fall_dust_fx(zombie)
{
	zombie waittill("death");
	self notify("stop_zombie_fall_dust_fx");
}

handle_fall_notetracks(note, spot)
{
	// the anim notetracks control which death anim to play
	// default to "deathin" (still in the ground)

	if (note == "deathout" )
	{
		self.deathFunction = ::faller_death_ragdoll;
		//self.zombie_fall_death_out = true;
		//self notify("zombie_fall_death_out");
	}
	else if ( note == "fire" )
	{
		// attack all players beneath us
		victims = zombie_fall_get_vicitims(spot);
		for ( i = 0; i < victims.size; i++ )
		{
			victims[i] DoDamage( self.meleeDamage, self.origin, self, 0, "MOD_MELEE" );
			//damaged someone!
			self.zombie_faller_should_drop = true;
		}
	}
}

faller_death_ragdoll()
{
	self StartRagdoll();
	self launchragdoll((0, 0, -1));

	return self maps\_zombiemode_spawner::zombie_death_animscript();
}

//Test if self is in player's FOV
in_player_fov( player )
{
	playerAngles = player getplayerangles();
	playerForwardVec = AnglesToForward( playerAngles );
	playerUnitForwardVec = VectorNormalize( playerForwardVec );

	banzaiPos = self.origin;
	playerPos = player GetOrigin();
	playerToBanzaiVec = banzaiPos - playerPos;
	playerToBanzaiUnitVec = VectorNormalize( playerToBanzaiVec );

	forwardDotBanzai = VectorDot( playerUnitForwardVec, playerToBanzaiUnitVec );
	angleFromCenter = ACos( forwardDotBanzai );

	playerFOV = GetDvarFloat( #"cg_fov" );
	banzaiVsPlayerFOVBuffer = GetDvarFloat( #"g_banzai_player_fov_buffer" );
	if ( banzaiVsPlayerFOVBuffer <= 0 )
	{
		banzaiVsPlayerFOVBuffer = 0.2;
	}

	inPlayerFov = ( angleFromCenter <= ( playerFOV * 0.5 * ( 1 - banzaiVsPlayerFOVBuffer ) ) );

	return inPlayerFov;
}

//-------------------------------------------------------------------------------
//	MCG 030711:
//	can faller zombie potentially be seen by any players?
//	self = zombie to check.
//-------------------------------------------------------------------------------
potentially_visible( how_close )
{
	if ( !IsDefined( how_close ) )
	{
		how_close = 1000;
	}
	potentiallyVisible = false;

	players = getplayers();
	for ( i = 0; i < players.size; i++ )
	{
		dist = Distance(self.origin, players[i].origin);
		if(dist < how_close)
		{
			inPlayerFov = self in_player_fov(players[i]);
			if(inPlayerFov)
			{
				potentiallyVisible = true;
				//no need to check rest of players
				break;
			}
		}
	}

	return potentiallyVisible;
}
