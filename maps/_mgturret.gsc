#include maps\_utility; 
#include common_scripts\utility; 
#using_animtree( "generic_human" ); 
init_mgTurretsettings()
{
	level.mgTurretSettings["easy"]["convergenceTime"] = 2.5; 
	level.mgTurretSettings["easy"]["suppressionTime"] = 3.0; 
	level.mgTurretSettings["easy"]["accuracy"] = 0.38; 
	level.mgTurretSettings["easy"]["aiSpread"] = 2; 
	level.mgTurretSettings["easy"]["playerSpread"] = 0.5; 	
	level.mgTurretSettings["medium"]["convergenceTime"] = 1.5; 
	level.mgTurretSettings["medium"]["suppressionTime"] = 3.0; 
	level.mgTurretSettings["medium"]["accuracy"] = 0.38; 
	level.mgTurretSettings["medium"]["aiSpread"] = 2; 
	level.mgTurretSettings["medium"]["playerSpread"] = 0.5; 	
	level.mgTurretSettings["hard"]["convergenceTime"] = .8; 
	level.mgTurretSettings["hard"]["suppressionTime"] = 3.0; 
	level.mgTurretSettings["hard"]["accuracy"] = 0.38; 
	level.mgTurretSettings["hard"]["aiSpread"] = 2; 
	level.mgTurretSettings["hard"]["playerSpread"] = 0.5; 	
	level.mgTurretSettings["fu"]["convergenceTime"] = .4; 
	level.mgTurretSettings["fu"]["suppressionTime"] = 3.0; 
	level.mgTurretSettings["fu"]["accuracy"] = 0.38; 
	level.mgTurretSettings["fu"]["aiSpread"] = 2; 
	level.mgTurretSettings["fu"]["playerSpread"] = 0.5; 	
}
main()
{
	
	
	if( GetDvar( #"mg42" ) == "" )
	{
		SetDvar( "mgTurret", "off" ); 
	}
		
	level.magic_distance = 24; 
	turretInfos = getEntArray( "turretInfo", "targetname" );
	for( index = 0; index < turretInfos.size; index++ )
    {
		turretInfos[index] Delete();
    }
    
    
}
portable_mg_behavior()
{
	
	self.a.combatrunanim = %ai_mg_shoulder_run;
	self.run_noncombatanim = %ai_mg_shoulder_run;
	
	
	self.walk_combatanim = %ai_mg_shoulder_run;
	self.walk_noncombatanim = %ai_mg_shoulder_run;
	
	
	self.a.crouchRunAnim = %ai_mg_shoulder_run;
	self.crouchrun_combatanim = %ai_mg_shoulder_run;
	
	self.alwaysRunForward = true;	
	
	
	
	self.disableExits = true;
}
mg42_trigger()
{
	self waittill( "trigger" ); 
	level notify( self.targetname ); 
	level.mg42_trigger[self.targetname] = true; 
	self Delete(); 
}
mgTurret_auto( trigger )
{
	trigger waittill( "trigger" ); 
	ai = GetAiArray( "axis" ); 
	for( i = 0; i < ai.size; i++ )
	{
		if( ( IsDefined( ai[i].script_mg42auto ) ) &&( trigger.script_mg42auto == ai[i].script_mg42auto ) )
		{
			ai[i] notify( "auto_ai" ); 
			println( "^a ai auto on!" ); 
		}
	}
	spawners = GetSpawnerArray(); 
	for( i = 0; i < spawners.size; i++ )
	{
		if( ( IsDefined( spawners[i].script_mg42auto ) ) &&( trigger.script_mg42auto == spawners[i].script_mg42auto ) )
		{
			spawners[i].ai_mode = "auto_ai"; 
			println( "^aspawner ", i, " set to auto" ); 
		}
	}
		
	maps\_spawner::kill_trigger( trigger ); 
}
mg42_suppressionFire( targets )
{
	self endon( "death" ); 
	self endon( "stop_suppressionFire" ); 
	if( !IsDefined( self.suppresionFire ) )
	{
		self.suppresionFire = true; 
	}
	
	for( ;; )
	{
		while( self.suppresionFire )
		{
			self SetTargetEntity( targets[RandomInt( targets.size )] ); 
			wait( 2 + RandomFloat( 2 ) ); 
		}
		
		self ClearTargetEntity(); 
		while( !self.suppresionFire )
		{
			wait( 1 ); 
		}
	}
}
manual_think( mg42 ) 
{
	self waittill( "auto_ai" ); 
	mg42 notify( "stopfiring" ); 
	mg42 SetMode( "auto_ai" ); 
}
burst_fire_settings( setting )
{
	if( setting == "delay" )
	{
		return 0.2; 
	}
	else if( setting == "delay_range" )
	{
		return 0.5; 
	}
	else if( setting == "burst" )
	{
		return 0.5; 
	}
	else if( setting == "burst_range" )
	{
		return 4; 
	}
}
burst_fire_unmanned()
{
	self notify( "stop_burst_fire_unmanned" );
	self endon( "stop_burst_fire_unmanned" );
	self endon( "death" );

	/*if( IsDefined( self.script_delay_min ) )
	{
		mg42_delay = self.script_delay_min; 
	}
	else
	{
		mg42_delay = burst_fire_settings( "delay" ); 
	}
	if( IsDefined( self.script_delay_max ) ) 
	{
		mg42_delay_range = self.script_delay_max - mg42_delay; 
	}
	else
	{
		mg42_delay_range = burst_fire_settings( "delay_range" ); 
	}
	if( IsDefined( self.script_burst_min ) )
	{
		mg42_burst = self.script_burst_min; 
	}
	else
	{
		mg42_burst = burst_fire_settings( "burst" ); 
	}
	if( IsDefined( self.script_burst_max ) ) 
	{
		mg42_burst_range = self.script_burst_max - mg42_burst; 
	}
	else
	{
		mg42_burst_range = burst_fire_settings( "burst_range" ); 
	}
	pauseUntilTime = GetTime();*/

	turretState = "start";
	self.script_shooting = false;
	self.convergence_amount = 0;
	turret_origin = self.origin + (0, 0, 40);
	target = undefined;

	for( ;; )
	{
		prev_target = target;
		target = undefined;
		target_origin = undefined;

		dist = 1500 * 1500;

		if(level.gamemode != "survival")
		{
			players = get_players();
			for( i = 0; i < players.size; i++ )
			{
				if(players[i].vsteam == self.owner.vsteam)
				{
					continue;
				}

				if(players[i] maps\_laststand::player_is_in_laststand())
				{
					continue;
				}

				if(players[i].sessionstate == "spectator")
				{
					continue;
				}

				temp_origin = players[i] GetCentroid();

				if(!SightTracePassed(turret_origin, temp_origin, false, undefined))
				{
					continue;
				}

				if(DistanceSquared(turret_origin, temp_origin) < dist) // attack the closest player
				{
					dist = DistanceSquared(players[i].origin, self.origin);
					target = players[i];
					target_origin = temp_origin;
				} 
			}
		}

		if(!IsDefined(target)) // if no closeby enemy player, attack the zombies
		{
			zombs = GetAiSpeciesArray("axis");
			for(i=0;i<zombs.size;i++)
			{
				if(zombs[i].health == 0)
				{
					continue;
				}

				temp_origin = zombs[i] GetCentroid();

				if(!SightTracePassed(turret_origin, temp_origin, false, undefined))
				{
					continue;
				}

				if(DistanceSquared(turret_origin, temp_origin) < dist) 
				{
					dist = DistanceSquared(zombs[i].origin, self.origin);
					target = zombs[i];
					target_origin = temp_origin;
				}
			}
		}

		self ClearTargetEntity();
		if(IsDefined(target))
		{
			self SetMode("manual");

			if(!IsDefined(prev_target) || prev_target != target)
			{
				if(IsDefined(self.manual_targets))
				{
					for(i=0; i<self.manual_targets.size; i++)
					{
						self.manual_targets[i] Delete();
					}
				}

				self.manual_targets = [];
				self.manual_targets[0] = Spawn("script_origin", target_origin);
				self.manual_targets[0] EnableLinkTo();
				self.manual_targets[0] LinkTo(target);
			}

			self SetTargetEntity( self.manual_targets[RandomInt( self.manual_targets.size )] );

			if(self.convergence_amount < 6)
			{
				self.convergence_amount++;
				wait_network_frame();
				continue;
			}

			if( turretState != "fire" )
			{
				turretState = "fire";
				self thread DoShoot();
				self.script_shooting = true;
			}
		}
		else
		{
			self SetMode("auto_ai");
			self.convergence_amount = 0;

			if(IsDefined(self.manual_targets))
			{
				for(i=0; i<self.manual_targets.size; i++)
				{
					self.manual_targets[i] Delete();
				}
			}

			if( turretState != "aim" )
			{
				turretState = "aim";
				self notify( "turretstatechange" );
			}
		}

		wait_network_frame();

		/*duration = ( pauseUntilTime - GetTime() ) * 0.001; 
		if( self IsFiringTurret() &&( duration <= 0 ) )
		{
			if( turretState != "fire" )
			{
				turretState = "fire";
				self thread DoShoot();
				self.script_shooting = true;
			}
			duration = mg42_burst + RandomFloat( mg42_burst_range ); 
			
			self thread TurretTimer( duration );
			self waittill( "turretstatechange" ); 
			
			self.script_shooting = false;
			duration = mg42_delay + RandomFloat( mg42_delay_range ); 
			
			pauseUntilTime = GetTime() + Int( duration * 1000 ); 
		}
		else
		{
			if( turretState != "aim" )
			{
				turretState = "aim"; 
			}
			
			self thread TurretTimer( duration );
			self waittill( "turretstatechange" ); 
		}*/
	}
}
DoShoot()
{
	self endon( "death" ); 
	self endon( "turretstatechange" ); 
	for( ;; )
	{
		self ShootTurret(); 
		wait( 0.1 ); 
	}
}
TurretTimer( duration )
{
	if( duration <= 0 )
	{
		return; 
	}
	self endon( "turretstatechange" ); 
	
	wait( duration ); 
	if( IsDefined( self ) )
	{
		self notify( "turretstatechange" ); 
	}
	
}
random_spread( ent )
{
	self endon( "death" ); 
	self notify( "stop random_spread" ); 
	self endon( "stop random_spread" ); 
	
	self endon( "stopfiring" ); 
	self SetTargetEntity( ent ); 
	
	while( 1 )
	{
		if( IsPlayer( ent ) )
		{
			ent.origin = self.manual_target GetOrigin(); 
		}
		else
		{
			ent.origin = self.manual_target.origin; 
		}
		ent.origin += ( 20 - RandomFloat( 40 ), 20 - RandomFloat( 40 ), 20 - RandomFloat( 60 ) ); 
		wait( 0.2 ); 
	}
}
mg42_firing( mg42 )
{
	self notify( "stop_using_built_in_burst_fire" ); 
	self endon( "stop_using_built_in_burst_fire" ); 
	mg42 StopFiring(); 
	
	while( 1 )
	{
		mg42 waittill( "startfiring" ); 
		self thread burst_fire( mg42 ); 
		mg42 StartFiring(); 
		mg42 waittill( "stopfiring" ); 
		mg42 StopFiring(); 
	}
}
burst_fire( mg42, manual_target )
{
	mg42 endon( "death" ); 
	mg42 endon( "stopfiring" ); 
	self endon( "stop_using_built_in_burst_fire" ); 
	if( IsDefined( mg42.script_delay_min ) )
	{
		mg42_delay = mg42.script_delay_min; 
	}
	else
	{
		mg42_delay = maps\_mgturret::burst_fire_settings( "delay" ); 
	}
	if( IsDefined( mg42.script_delay_max ) ) 
	{
		mg42_delay_range = mg42.script_delay_max - mg42_delay; 
	}
	else
	{
		mg42_delay_range = maps\_mgturret::burst_fire_settings( "delay_range" ); 
	}
	if( IsDefined( mg42.script_burst_min ) )
	{
		mg42_burst = mg42.script_burst_min; 
	}
	else
	{
		mg42_burst = maps\_mgturret::burst_fire_settings( "burst" ); 
	}
	if( IsDefined( mg42.script_burst_max ) ) 
	{
		mg42_burst_range = mg42.script_burst_max - mg42_burst; 
	}
	else
	{
		mg42_burst_range = maps\_mgturret::burst_fire_settings( "burst_range" ); 
	}
	while( 1 )
	{	
		mg42 StartFiring(); 
		if( IsDefined( manual_target ) )
		{
			mg42 thread random_spread( manual_target ); 
		}
			
		wait( mg42_burst + RandomFloat( mg42_burst_range ) ); 
		mg42 StopFiring(); 
		wait( mg42_delay + RandomFloat( mg42_delay_range ) ); 
	}
}
_spawner_mg42_think()
{
	if( !IsDefined( self.flagged_for_use ) )
	{
		self.flagged_for_use = false; 
	}
	if( !IsDefined( self.targetname ) )
	{
		return; 
	}
	node = GetNode( self.targetname, "target" ); 
	if( !IsDefined( node ) )
	{
		return; 
	}
	if( !IsDefined( node.script_mg42 ) )
	{
		return; 
	}
	if( !IsDefined( node.mg42_enabled ) )
	{
		node.mg42_enabled = true; 
	}
	self.script_mg42 = node.script_mg42; 
	first_run = true; 
	while( 1 )
	{
		if( first_run )
		{
			first_run = false; 
			if( ( IsDefined( node.targetname ) ) ||( self.flagged_for_use ) )
			{
				self waittill( "get new user" ); 
			}
		}
		if( !node.mg42_enabled )
		{
			node waittill( "enable mg42" ); 
			node.mg42_enabled = true; 
		}
		excluders = []; 
		ai = GetAiArray(); 
		for( i = 0; i < ai.size; i++ )
		{
			excluded = true; 
			if( ( IsDefined( ai[i].script_mg42 ) ) &&( ai[i].script_mg42 == self.script_mg42 ) )
				excluded = false; 
			if( IsDefined( ai[i].used_an_mg42 ) )
			{
				excluded = true; 
			}
				
			if( excluded )
			{
				excluders[excluders.size] = ai[i]; 
			}
		}
		if( excluders.size )
		{
			ai = maps\_utility::get_closest_ai_exclude( node.origin, undefined, excluders ); 
		}
		else
		{
			ai = maps\_utility::get_closest_ai( node.origin, undefined ); 
		}
		excluders = undefined; 
		if( IsDefined( ai ) )
		{
			ai notify( "stop_going_to_node" ); 
			ai thread maps\_spawner::go_to_node( node ); 
			ai waittill( "death" ); 
		}
		else
		{
			self waittill( "get new user" ); 
		}
	}
}
move_use_turret( mg42, aitype, target )
{
	self SetGoalPos( mg42.org ); 
	self.goalradius = level.magic_distance; 
	self waittill( "goal" ); 
	if( IsDefined( aitype ) && aitype == "auto_ai" )
	{
		mg42 SetMode( "auto_ai" ); 
		if( IsDefined( target ) )
		{
			mg42 SetTargetEntity( target ); 
		}
		else
		{
			mg42 ClearTargetEntity(); 
		}
	}
	self USeturret( mg42 ); 
}
turret_think( node )
{
	turret = GetEnt( node.auto_mg42_target, "targetname" ); 
	mintime = 0.5; 
	if( IsDefined( turret.script_turret_reuse_min ) )
	{
		mintime = turret.script_turret_reuse_min; 
	}
	maxtime = 2; 
	if( IsDefined( turret.script_turret_reuse_max ) )
	{
		mintime = turret.script_turret_reuse_max; 
	}
	assert( maxtime >= mintime ); 
	for( ;; )
	{
		turret waittill( "turret_deactivate" ); 
		wait( mintime + RandomFloat( maxtime - mintime ) ); 
		while( !( IsTurretActive( turret ) ) )
		{
			turret_find_user( node, turret ); 
			wait( 1.0 ); 
		}
	}
}
turret_find_user( node, turret )
{
	ai = GetAiArray(); 	
	for( i = 0; i < ai.size; i++ )
	{
		if( ai[i] IsInGoal( node.origin ) && ai[i] CanUSeturret( turret ) )
		{
			savekeepclaimed = ai[i].keepClaimedNodeInGoal; 
			ai[i].keepClaimedNodeInGoal = false; 
			if( !( ai[i] UseCOverNode( node ) ) )
			{
				ai[i].keepClaimedNodeInGoal = savekeepclaimed; 
			}
		}
	}
}
setDifficulty()
{
	init_mgTurretsettings();
	
	mg42s = GetEntArray( "misc_turret", "classname" ); 
	
	difficulty = GetDifficulty(); 
	
	for( index = 0; index < mg42s.size; index++ )
	{
		if( IsDefined( mg42s[index].script_skilloverride ) )
		{
			switch( mg42s[index].script_skilloverride )
			{
				case "easy":
					difficulty = "easy"; 
					break; 
				case "medium":
					difficulty = "medium"; 
					break; 
				case "hard":
					difficulty = "hard"; 
					break; 
				case "fu":
					difficulty = "fu"; 
					break; 
				default:
					continue; 
			}
		}
		mg42_setdifficulty( mg42s[index], difficulty ); 
	}
}
mg42_setdifficulty( mg42, difficulty )
{
		mg42.convergenceTime = level.mgTurretSettings[difficulty]["convergenceTime"]; 
		mg42.suppressionTime = level.mgTurretSettings[difficulty]["suppressionTime"]; 
		mg42.accuracy = level.mgTurretSettings[difficulty]["accuracy"]; 
		mg42.aiSpread = level.mgTurretSettings[difficulty]["aiSpread"]; 
		mg42.playerSpread = level.mgTurretSettings[difficulty]["playerSpread"]; 	
}
mg42_target_drones( nonai, team, fakeowner )
{
	if( !IsDefined( fakeowner ) )
	{
		fakeowner = false; 
	}
	self endon( "death" ); 
	self.dronefailed = false; 
	if( !IsDefined( self.script_fireondrones ) )
	{
		self.script_fireondrones = false; 
	}
	if( !IsDefined( nonai ) )
	{
		nonai = false; 
	}
	self SetMode( "manual_ai" ); 
	difficulty = GetDifficulty(); 
	if( !IsDefined( level.drones ) )
	{
		waitfornewdrone = true; 
	}
	else
	{
		waitfornewdrone = false; 
	}
	while( 1 )
	{
		if( fakeowner && !IsDefined( self.fakeowner ) )
		{
			self SetMode( "manual" ); 
			while( !IsDefined( self.fakeowner ) )
			{
				wait( .2 ); 
			}
			
		}
		else if( nonai )
		{
			self SetMode( "auto_nonai" ); 
		}
		else
		{
			self SetMode( "auto_ai" ); 
		}
		
		if( waitfornewdrone )
		{
			level waittill( "new_drone" ); 
		}
		if( !IsDefined( self.oldconvergencetime ) )
		{
			self.oldconvergencetime = self.convergencetime; 
		}
		self.convergencetime = 2; 
		if( !nonai )
		{
			turretowner = self GetTurretOwner(); 
			if( !IsAlive( turretowner ) || IsPlayer( turretowner ) )
			{
				wait( .05 ); 
				continue; 
			}
			else
			{
				team = turretowner.team; 
			}
		}
		else
		{
			if( fakeowner && !IsDefined( self.fakeowner ) )
			{
				wait( .05 ); 
				continue; 
			}
			assert( IsDefined( team ) ); 
			turretowner = undefined; 
		}
		if( team == "allies" )
		{
			targetteam = "axis"; 
		}
		else
		{
			targetteam = "allies"; 
		}
		while( level.drones[targetteam].lastindex )
		{
			
			target = get_bestdrone( targetteam ); 
			if( !IsDefined( self.script_fireondrones ) || !self.script_fireondrones )
			{
				wait( .2 ); 
				break; 
			}
			if( !IsDefined( target ) )
			{
				wait( .2 ); 
				break; 
			}
			if( nonai )	
			{
				self SetMode( "manual" ); 
			}
			else
			{
				self SetMode( "manual_ai" ); 
			}
				
			thread drone_fail( target, 3 ); 
			if( !self.dronefailed )
			{
				self SetTargetEntity( target.turrettarget ); 
				self ShootTurret(); 
				self StartFiring(); 
			}
			else
			{
				self.dronefailed = false; 
				wait( .05 ); 
				continue; 
				
			}
			target waittill_any ("death","drone_mg42_fail");
			waittillframeend; 
			if( !nonai && !( IsDefined( self GetTurretOwner() ) && self GetTurretOwner() == turretowner ) )
			{
				break; 
			}
		}
		self.convergencetime = self.oldconvergencetime; 
		self.oldconvergencetime = undefined; 
		self ClearTargetEntity(); 
		self StopFiring(); 
		if( level.drones[targetteam].lastindex )
		{
			waitfornewdrone = false; 
		}
		else
		{
			waitfornewdrone = true; 
		}
	}
}
drone_fail( drone, time )
{
	self endon( "death" ); 
	drone endon( "death" ); 
	timer = GetTime()+( time*1000 ); 
	while( timer > GetTime() )
	{
		turrettarget = self GetTurretTarget(); 
		if( !SightTracePassed( self GetTagOrigin( "tag_flash" ), drone.origin+( 0, 0, 40 ), 0, drone ) )
		{
			self.dronefailed = true; 
			wait( .2 ); 
			break; 
		}
		else if( IsDefined( turrettarget ) && Distance( turrettarget.origin, self.origin ) < Distance( self.origin, drone.origin ) )
		{
			self.dronefailed = true; 
			wait( .1 ); 
			break; 	
		}
		wait( .1 ); 
	}
	maps\_utility::structarray_shuffle( level.drones[drone.team], 1 ); 
	drone notify( "drone_mg42_fail" ); 
}
get_bestdrone( team )
{
	
	if( level.drones[team].lastindex < 1 )
	{
		return; 
	}
	ent = undefined; 
	dotforward = AnglesToForward( self.angles ); 
	for( i = 0; i < level.drones[team].lastindex; i++ )
	{
		angles = VectorToAngles( level.drones[team].array[i].origin - self.origin ); 
		forward = AnglesToForward( angles ); 
		if( VectorDot( dotforward, forward ) < .88 )
		{
			continue; 
		}
		ent = level.drones[team].array[i]; 
		break; 
	}
	aitarget = self GetTurretTarget(); 
	if( IsDefined( ent ) && IsDefined( aitarget ) && Distance( self.origin, aitarget.origin ) < Distance( self.origin, ent.origin ) )
	{
		ent = undefined;  
	}
	
	return ent; 
}
saw_mgTurretLink( nodes )
{
	possible_turrets = getEntArray( "misc_turret", "classname" );
	turrets = [];
	for ( i=0; i < possible_turrets.size; i++ )
	{
		if ( isDefined( possible_turrets[ i ].targetname ) )
			continue;
			
		if ( isdefined( possible_turrets[ i ].isvehicleattached ) )
		{
			assertEx( possible_turrets[ i ].isvehicleattached != 0, "Setting must be either true or undefined" );
			continue;
		}
		turrets[ possible_turrets[ i ].origin + "" ] = possible_turrets[ i ];
	}
	
	if ( !turrets.size )
		return;
		
	for ( nodeIndex = 0; nodeIndex < nodes.size; nodeIndex++)
	{
		node = nodes[ nodeIndex ];
		if ( node.type == "Path" )
			continue;
		if ( node.type == "Begin" )
			continue;
		if ( node.type == "End" )
			continue;
	    nodeForward = anglesToForward( ( 0, node.angles[ 1 ], 0 ) );
		keys = getArrayKeys( turrets );
		for ( i=0; i < keys.size; i++ )
		{
			turret = turrets[ keys[ i ] ];
			
			
			
			if ( distance( node.origin, turret.origin ) > 75 )
				continue;
		
		   turretForward = anglesToForward( ( 0, turret.angles[ 1 ], 0 ) );
		    
			dot = vectorDot( nodeForward, turretForward );
			if ( dot < 0.9 )
				continue;
			
			
			node.turretInfo = spawnstruct();
			node.turretInfo.origin = turret.origin;
			node.turretInfo.angles = turret.angles;
			node.turretInfo.node = node;
			node.turretInfo.leftArc = 45;
			node.turretInfo.rightArc = 45;
			node.turretInfo.topArc = 15;
			node.turretInfo.bottomArc = 15;
			
			turrets[ keys[ i ] ] = undefined;
			turret delete();
			println("PortableMG: " + turret.weaponinfo + " was set up to be portable.");
		}
	}
	keys = getArrayKeys( turrets );
	for ( i=0; i < keys.size; i++ )
	{
		turret = turrets[ keys[ i ] ];
		println( "^1!!!ERROR: turret at " + turret.origin + " could not link to any node! You need to make sure that a node is directly behind the mg42 and less than 50 units behind it." );
	}
}
auto_mgTurretLink( nodes )
{
	
	possible_turrets = GetEntArray( "misc_turret", "classname" ); 
	turrets = []; 
	for( i = 0; i < possible_turrets.size; i++ )
	{
		if ( !isDefined( possible_turrets[ i ].targetname ) || tolower( possible_turrets[ i ].targetname ) != "auto_mgturret" )
			continue;
		
		if( !IsDefined( possible_turrets[i].export ) )
		{
			continue; 
		}
		if( !IsDefined( possible_turrets[i].script_dont_link_turret ) )
		{
			turrets[possible_turrets[i].origin + ""] = possible_turrets[i]; 
		}
	}
	
	if( !turrets.size )
	{
		return; 
	}
		
	for( nodeIndex = 0; nodeIndex < nodes.size; nodeIndex++ )
	{
		node = nodes[nodeIndex]; 
		if( node.type == "Path" )
		{
			continue; 
		}
		if( node.type == "Begin" )
		{
			continue; 
		}
		if( node.type == "End" )
		{
			continue; 
		}
	    nodeForward = AnglesToForward( ( 0, node.angles[1], 0 ) ); 
		keys = GetArrayKeys( turrets ); 
		for( i = 0; i < keys.size; i++ )
		{
			turret = turrets[keys[i]]; 
			if( Distance( node.origin, turret.origin ) > 70 )
			{
				continue; 
			}
		
		    turretForward = AnglesToForward( ( 0, turret.angles[1], 0 ) ); 
		    
			dot = VectorDot( nodeForward, turretForward ); 
			if( dot < 0.9 )
			{
				continue; 
			}
	
			node.turret = turret; 
			turret.node = node; 
			turret.isSetup = true;
			assertEx( isdefined( turret.export ), "Turret at " + turret.origin + " does not have a .export value but is near a cover node. If you do not want them to link, use .script_dont_link_turret." );
			
			
			turrets[keys[i]] = undefined; 
		}
		
	}
	
	
	
		
	
	nodes = undefined; 
}
save_turret_sharing_info()
{
	
	self.shared_turrets = []; 
	self.shared_turrets["connected"] = []; 
	self.shared_turrets["ambush"] = []; 
	
	if( !IsDefined( self.export ) )
	{
		assertex( !IsDefined( self.script_turret_share ), "Turret at " + self.origin + " has script_turret_share but has no .export value, so script_turret_share won't have any effect." ); 
		assertex( !IsDefined( self.script_turret_ambush ), "Turret at " + self.origin + " has script_turret_ambush but has no .export value, so script_turret_ambush won't have any effect." ); 
		return; 
	}
		
	level.shared_portable_turrets[self.export] = self; 
	if( IsDefined( self.script_turret_share ) )
	{
		
		
		
		strings = Strtok( self.script_turret_share, " " ); 
		
		for( i = 0; i < strings.size; i++ )
		{
			self.shared_turrets["connected"][strings[i]] = true; 
		}
	}
	if( IsDefined( self.script_turret_ambush ) )
	{
		
		
		
		strings = Strtok( self.script_turret_ambush, " " ); 
		
		for( i = 0; i < strings.size; i++ )
		{
			self.shared_turrets["ambush"][strings[i]] = true; 
		}
	}
}
restoreDefaultPitch()
{
	self notify( "gun_placed_again" ); 
	self endon( "gun_placed_again" ); 
	self waittill( "restore_default_drop_pitch" ); 
	wait( 1 ); 
	self RestoreDefaultDropPitch(); 
}
dropTurret()
{
	thread dropTurretProc(); 
}
dropTurretProc()
{
	turret = Spawn( "script_model", ( 0, 0, 0 ) ); 
	turret.origin = self GetTagOrigin( level.portable_mg_gun_tag ); 
	turret.angles = self GetTagAngles( level.portable_mg_gun_tag ); 
	turret SetModel( self.turretModel ); 
	forward = AnglesToForward( self.angles ); 
	forward = vector_scale( forward, 100 ); 
	turret MoveGravity( forward, 0.5 ); 
	self Detach( self.turretModel,  level.portable_mg_gun_tag ); 
	self.turretmodel = undefined; 
	wait( 0.7 ); 
	turret Delete(); 
}
turretDeathDetacher()
{
	self endon( "kill_turret_detach_thread" ); 
	self endon( "dropped_gun" ); 
	self waittill( "death" ); 
	if( !IsDefined( self ) )
	{
		return; 
	}
	dropTurret(); 
}
turretDetacher()
{
	self endon( "death" ); 
	self endon( "kill_turret_detach_thread" ); 
	
	self waittill( "dropped_gun" ); 
	self Detach( self.turretModel,  level.portable_mg_gun_tag ); 
}
restoreDefaults()
{
	self.run_noncombatanim = undefined; 
	self.run_combatanim = undefined; 
	self set_all_exceptions( get_overloaded_func( "animscripts\init", "empty" ) ); 
}
restorePitch()
{
	self waittill( "turret_deactivate" ); 
	self RestoreDefaultDropPitch(); 
}
update_enemy_target_pos_while_running( ent )
{
	self endon( "death" ); 
	self endon( "end_mg_behavior" ); 
	self endon( "stop_updating_enemy_target_pos" ); 
	for( ;; )
	{
		self waittill( "saw_enemy" ); 		
		ent.origin = self.last_enemy_sighting_position; 
	}
}
move_target_pos_to_new_turrets_visibility( ent, new_spot )
{
	
	
	
	
	
	
	
	
	
	
	self endon( "death" ); 
	self endon( "end_mg_behavior" ); 
	self endon( "stop_updating_enemy_target_pos" ); 
	old_turret_pos = self.turret.origin +( 0, 0, 16 ); 
	dest_pos = new_spot.origin +( 0, 0, 16 ); 
	
	for( ;; )
	{
		wait( 0.05 ); 
		if( SightTracePassed( ent.origin, dest_pos, 0, undefined ) )
		{
			continue; 
		}
		
		
		angles = VectorToAngles( old_turret_pos - ent.origin ); 
		forward = AnglesToForward( angles ); 
		forward = vector_scale( forward, 8 ); 
		
		ent.origin = ent.origin + forward; 
	}
}
record_bread_crumbs_for_ambush( ent )
{
	self endon( "death" ); 
	self endon( "end_mg_behavior" ); 
	self endon( "stop_updating_enemy_target_pos" ); 
	
	ent.bread_crumbs = []; 
	for( ;; )
	{
		ent.bread_crumbs[ent.bread_crumbs.size] = self.origin +( 0, 0, 50 ); 
		wait( 0.35 ); 	
	}
}
aim_turret_at_ambush_point_or_visible_enemy( turret, ent )
{
	if( !IsAlive( self.current_enemy ) && self CanSee( self.current_enemy ) )
	{
		
		ent.origin = self.last_enemy_sighting_position; 
		return; 
	}
	
	
	forward = AnglesToForward( turret.angles ); 
	
	
	
	
	for( i = ent.bread_crumbs.size - 3; i >= 0; i-- )
	{
		
		crumb = ent.bread_crumbs[i]; 
		normal = VectorNormalize( crumb - turret.origin ); 
		dot = VectorDot( forward, normal ); 
		if( dot < 0.75 )
		{
			continue; 
		}
		ent.origin = crumb; 
			
		
		if( SightTracePassed( turret.origin, crumb, 0, undefined ) )
		{
			continue; 
		}
		
		break; 
	}
}
find_a_new_turret_spot( ent )
{
	
	array = get_portable_mg_spot( ent ); 
	new_spot = array["spot"]; 
	connection_type = array["type"]; 
	
	if( !IsDefined( new_spot ) )
	{
		return; 
	}
	reserve_turret( new_spot ); 
		
	
	thread update_enemy_target_pos_while_running( ent ); 
	thread move_target_pos_to_new_turrets_visibility( ent, new_spot ); 
	
	if( connection_type == "ambush" )
	{
		thread record_bread_crumbs_for_ambush( ent ); 
	}
	if( new_spot.isSetup )
	{
		leave_gun_and_run_to_new_spot( new_spot ); 
	}
	else
	{
		pickup_gun( new_spot ); 
		run_to_new_spot_and_setup_gun( new_spot ); 
	}
		
	self notify( "stop_updating_enemy_target_pos" ); 
	if( connection_type == "ambush" )
	{
		aim_turret_at_ambush_point_or_visible_enemy( new_spot, ent ); 
	}
	
	new_spot SetTargetEntity( ent ); 
}
leave_gun_and_run_to_new_spot( spot )
{
	assert( spot.reserved == self ); 
	
	
	self StopUSeturret(); 
	self animscripts\shared::placeWeaponOn( self.primaryweapon, "none" ); 
	
	setup_anim = get_turret_setup_anim( spot ); 
	org = GetStartOrigin( spot.origin, spot.angles, setup_anim ); 
	self SetruntoPos( org ); 
	assertex( Distance( org, self.goalpos ) < self.goalradius, "Tried to set the run pos outside the goalradius" ); 
	
	self waittill( "runto_arrived" ); 
	
	use_the_turret( spot ); 
}
pickup_gun( spot )
{
	
	
	
	self StopUSeturret(); 
	self.turret hide_turret(); 
}
get_turret_setup_anim( turret )
{
	spot_types = []; 
	spot_types[ "saw_bipod_stand" ] =			level.mg_animmg[ "bipod_stand_setup" ];
	spot_types[ "saw_bipod_crouch" ] =			level.mg_animmg[ "bipod_crouch_setup" ];
	spot_types[ "saw_bipod_prone" ] =			level.mg_animmg[ "bipod_prone_setup" ];
	
	return spot_types[turret.weaponinfo]; 
}
run_to_new_spot_and_setup_gun( spot )
{
	assert( spot.reserved == self ); 
	
	oldhealth = self.health; 
	spot endon( "turret_deactivate" ); 
	
	self.mg42 = spot; 
	self endon( "death" ); 
	self endon( "dropped_gun" ); 
	setup_anim = get_turret_setup_anim( spot ); 
	
	self.turretModel = "weapon_mg42_carry"; 
	
	
	self notify( "kill_get_gun_back_on_killanimscript_thread" ); 
	self animscripts\shared::placeWeaponOn( self.weapon, "none" ); 
	if( self.team == "axis" )
	{
		self.health = 1; 
	}
	
	self.run_noncombatanim = %saw_gunner_run_slow;
	self.run_combatanim = %saw_gunner_run_fast;
	self.crouchrun_combatanim = %saw_gunner_run_fast;
	
	self Attach( self.turretModel, level.portable_mg_gun_tag ); 
	thread turretDeathDetacher(); 
	
	org = GetStartOrigin( spot.origin, spot.angles, setup_anim ); 
	self SetruntoPos( org ); 
	assertex( Distance( org, self.goalpos ) < self.goalradius, "Tried to set the run pos outside the goalradius" ); 
	
	wait( 0.05 ); 
	self set_all_exceptions( maps\_mgturret::exception_exposed_mg42_portable ); 
	clear_exception( "move" ); 
	set_exception( "cover_crouch", ::hold_indefintely ); 
	
	while( Distance( self.origin, org ) > 16 )
	{
		self SetruntoPos( org ); 
		wait( 0.05 ); 
	}
		
	self notify( "kill_turret_detach_thread" ); 
	
	if( self.team == "axis" )
	{
		self.health = oldhealth; 
	}
	
	if( SoundExists( "weapon_setup" ) )
	{
		thread play_sound_in_space( "weapon_setup" ); 
	}
		
	self AnimScripted( "setup_done", spot.origin, spot.angles, setup_anim ); 
	
	restoreDefaults(); 
	
	self waittillmatch( "setup_done", "end" ); 
	spot notify( "restore_default_drop_pitch" ); 
	spot show_turret(); 
	
	self animscripts\shared::placeWeaponOn( self.primaryweapon, "right" ); 
	use_the_turret( spot ); 
	self Detach( self.turretModel, level.portable_mg_gun_tag ); 
	self set_all_exceptions( get_overloaded_func( "animscripts\init", "empty" ) ); 
	self notify( "bcs_portable_turret_setup" ); 
}
move_to_run_pos()
{
	self SetruntoPos( self.runpos ); 
}
hold_indefintely()
{
	self endon( "killanimscript" ); 
	self waittill( "death" ); 
}
using_a_turret()
{
	if( !IsDefined( self.turret ) )
	{
		return false; 
	}
		
	return self.turret.owner == self; 
}
	
turret_user_moves()
{
	
	if( !using_a_turret() )
	{
		clear_exception( "move" ); 
		return; 
	}
	array = find_connected_turrets( "connected" ); 
	new_spots = array["spots"]; 
	
	if( !new_spots.size )
	{
		
		
		clear_exception( "move" ); 
		return; 
	}
	
	
	turret_node = self.node; 
	
	
	if( !IsDefined( turret_node ) || !is_in_array( new_spots, turret_node ) )
	{
		taken_nodes = getTakenNodes(); 
		for( i = 0; i < new_spots.size; i++ )
		{
			turret_node = random( new_spots ); 
	
			
			
			if( IsDefined( taken_nodes[turret_node.origin + ""] ) )
			{
				return; 
			}
		}
	}
	
	turret = turret_node.turret; 
	
	if( IsDefined( turret.reserved ) )
	{
		assert( turret.reserved != self ); 
		return; 
	}
		
	reserve_turret( turret ); 
	
	
	if( turret.isSetup )
	{
		
		leave_gun_and_run_to_new_spot( turret ); 
	}
	else
	{
		
		run_to_new_spot_and_setup_gun( turret ); 
	}
		
	maps\_mg_penetration::gunner_think( turret_node.turret ); 
}
use_the_turret( spot )
{
	turretWasUsed = self USeturret( spot ); 
	if( turretWasUsed )
	{	
		set_exception( "move", ::turret_user_moves ); 
		self.turret = spot; 
		self thread mg42_firing( spot ); 
		spot SetMode( "manual_ai" ); 
		spot thread restorePitch(); 
		self.turret = spot; 
		spot.owner = self; 
		return true; 
	}
	else
	{
		spot RestoreDefaultDropPitch(); 
		return false; 
	}
}
get_portable_mg_spot( ent )
{
	find_spot_funcs = []; 
	find_spot_funcs[find_spot_funcs.size] = ::find_different_way_to_attack_last_seen_position; 
	find_spot_funcs[find_spot_funcs.size] = ::find_good_ambush_spot; 
	find_spot_funcs = array_randomize( find_spot_funcs ); 
	
	for( i = 0; i < find_spot_funcs.size; i++ )
	{
		array = [[find_spot_funcs[i]]]( ent ); 
		
		if( !IsDefined( array["spots"] ) )
		{
			continue; 
		}
		
		array["spot"] = random( array["spots"] ); 
		return array; 
	}
}
getTakenNodes()
{
	
	array = []; 
	ai = GetAiArray(); 
	
	for( i = 0; i < ai.size; i++ )
	{
		if( !IsDefined( ai[i].node ) )
		{
			continue; 
		}
		
		array[ai[i].node.origin + ""] = true; 
	}
	
	return array; 
}
find_connected_turrets( connection_type )
{
	spots = level.shared_portable_turrets; 	
	usable_spots = []; 
	
	spot_exports = GetArrayKeys( spots ); 
	
	taken_nodes = getTakenNodes(); 
	taken_nodes[self.node.origin + ""] = undefined; 
	
	
	for( i = 0; i < spot_exports.size; i++ )
	{
		export = spot_exports[i]; 
		if( spots[export] == self.turret )
			continue; 
			
		
		keys = GetArrayKeys( self.turret.shared_turrets[connection_type] ); 	
		for( p = 0; p < keys.size; p++ )
		{
			
			
			
			if( spots[export].export + "" != keys[p] )
			{
				continue; 
			}
				
			
			if( IsDefined( spots[export].reserved ) )
			{
				continue; 
			}
				
			
			if( IsDefined( taken_nodes[spots[export].node.origin + ""] ) )
			{
				continue; 
			}
				
			
			if( Distance( self.goalpos, spots[export].origin ) > self.goalradius )
			{
				continue; 
			}
				
			
			usable_spots[usable_spots.size] = spots[export]; 
		}
	}
	array = []; 
	
	array["type"] = connection_type; 
	array["spots"] = usable_spots; 
	return array; 	
}
find_good_ambush_spot( ent )
{
	return find_connected_turrets( "ambush" ); 
}
find_different_way_to_attack_last_seen_position( ent )
{
	array = find_connected_turrets( "connected" ); 
	usable_spots = array["spots"]; 
	
	if( !usable_spots.size )
	{
		return; 
	}
	good_spot = []; 
	
	
	for( i = 0; i < usable_spots.size; i++ )
	{
			
		if( !within_fov( usable_spots[i].origin, usable_spots[i].angles, ent.origin, 0.75 ) )
		{
			continue; 
		}
		
		
			
		if( !SightTracePassed( ent.origin, usable_spots[i].origin +( 0, 0, 16 ), 0, undefined ) )
		{
			continue; 
		}
	
		good_spot[good_spot.size] = usable_spots[i]; 
	}
	
	array["spots"] = good_spot; 
	return array; 
}
portable_mg_spot()
{
	save_turret_sharing_info(); 	
	self.isSetup = true; 
	assert( !IsDefined( self.reserved ) ); 
	self.reserved = undefined;
	if( IsDefined( self.isvehicleattached ) )
	{
		return; 	
	}
	if( self has_spawnflag(level.SPAWNFLAG_TURRET_PREPLACED) )
	{
		return; 
	}
	
	hide_turret();	
}
hide_turret()
{
	assert( self.isSetup ); 
	self notify( "stop_checking_for_flanking" ); 
	self.isSetup = false; 
	self Hide(); 
	self.solid = false; 
	self MakeTurretUnusable(); 
	self SetDefaultDropPitch( 0 ); 
	self thread restoreDefaultPitch(); 
}
show_turret()
{
	self Show(); 
	self.solid = true; 
	self MakeTurretUsable(); 
	assert( !self.isSetup ); 
	self.isSetup = true; 
	thread stop_mg_behavior_if_flanked(); 
}
stop_mg_behavior_if_flanked()
{
	self endon( "stop_checking_for_flanking" ); 
	
	self waittill( "turret_deactivate" ); 
	if( IsAlive( self.owner ) )
	{
		self.owner notify( "end_mg_behavior" ); 
	}
}
turret_is_mine( turret )
{
	owner = turret GetTurretOwner(); 
	if( !IsDefined( owner ) )
	{
		return false; 
	}
	
	return owner == self; 
}
end_turret_reservation( turret )
{
	waittill_turret_is_released( turret ); 
	turret.reserved = undefined; 
}
waittill_turret_is_released( turret )
{
	turret endon( "turret_deactivate" ); 
	self endon( "death" ); 
	self waittill( "end_mg_behavior" ); 
}
	
reserve_turret( turret )
{
	turret.reserved = self; 
	thread end_turret_reservation( turret ); 
}
link_turrets( turretArray )
{
	self endon( "death" );
	
	level.print3d_ran_already = false;  
	
	
	if( !IsDefined( turretArray ) || turretArray.size <= 1 )
	{
		return;
	}
	
	
	while( 1 )
	{
		for( i = 0; i < turretArray.size; i++ )
		{
			if( turretArray[i] IsFiringTurret() )
			{
				
				self link_turrets_fireall( turretArray[i], turretArray );
			}
		}
		
		
		wait( 0.05 );
	}
}
link_turrets_fireall( leaderTurret, turretArray )
{
	self endon( "death" );
	
	self.leadTurretState = 0;
	
	
	for( i = 0; i < turretArray.size; i++ )
	{
		if( turretArray[i] != leaderTurret && !turretArray[i] IsFiringTurret() )
		{
			turretArray[i] SetMode( "manual" );
		}
	}
	
	
	while( leaderTurret IsFiringTurret() )
	{
		
		if( leaderTurret.script_shooting )
		{
			
			for( i = 0; i < turretArray.size; i++ )
			{
				if( turretArray[i] != leaderTurret && !turretArray[i] IsFiringTurret() )
				{
					turretArray[i] ShootTurret();
				}
			}
		}
		
		wait( 0.1 );
	}
	
	
	self notify( "lead_turret_stopped" );
	
	
	for( i = 0; i < turretArray.size; i++ )
	{
		if( turretArray[i] != leaderTurret && !turretArray[i] IsFiringTurret() )
		{
			
			turretArray[i] SetMode( "auto_nonai" );
		}
	}
}
init_mg_animent()
{
	mg42s = GetEntArray( "misc_mg42", "classname" );
	turrets = GetEntArray( "misc_turret", "classname" );
	turrets = array_combine( mg42s, turrets );
	for( i = 0; i < turrets.size; i++ )
	{
		if( IsDefined( turrets[i].script_animent ) )
		{
			turrets[i] thread mg_anim_ent();
		}
	}
}
mg_anim_ent()
{
	self endon( "stop_mg_anim_ent" );
	self endon( "death" );
	anim_ent = GetEnt( self.script_animent, "targetname" );
	if( IsDefined( anim_ent.script_animname ) )
	{
		anim_ent.animname = anim_ent.script_animname;
	}
	else
	{
		anim_ent.animname = anim_ent.targetname;
	}
	delay = 0.2;
	intro_time = GetAnimLength( level.scr_anim[anim_ent.animname]["intro"] ) - delay;
	anim_ent maps\_anim::SetAnimTree();
	state = "outro";
	for( ;; )
	{
		owner = self GetTurretOwner();
		if( !IsDefined( owner ) )
		{
			if( state != "outro" )
			{
				state = "outro";
				anim_ent SetFlaggedAnimKnobRestart( "mg_animent_anim", level.scr_anim[anim_ent.animname][state], 1.0, 0.2, 1.0 );
			}
			self waittill( "turretownerchange" );
			owner = self GetTurretOwner();
		}
		if( self mg_is_firing( owner ) )
		{
			if( state == "outro" )
			{
				state = "intro";
				anim_ent SetFlaggedAnimKnobRestart( "mg_animent_anim", level.scr_anim[anim_ent.animname][state], 1.0, 0.2, 1.0 );
				wait( intro_time );
			}
			else if( state == "intro" || state == "loop" )
			{
				state = "loop";
				anim_ent SetFlaggedAnimKnob( "mg_animent_anim", level.scr_anim[anim_ent.animname][state], 1.0, 0.2, 1.0 );
			}
		}
		else if( state != "outro" )
		{
			state = "outro";
			anim_ent SetFlaggedAnimKnobRestart( "mg_animent_anim", level.scr_anim[anim_ent.animname][state], 1.0, 0.2, 1.0 );
		}
		wait( delay );
	}
}
mg_is_firing( owner )
{
	if( !IsDefined( owner ) )
	{
		return false;
	}
	if( IsPlayer( owner ) )
	{
		return IsTurretFiring( self );
	}
	else
	{
		if( IsDefined( self.doFiring ) && self.doFiring )
		{
			return true;
		}
	
		if( IsDefined( self.script_shooting ) && self.script_shooting )
		{
			return true;
		}
	}
	return false;
}
drop_turret()
{
	maps\_mgturret::dropTurret();
	self animscripts\weaponList::RefillClip();
	self.a.needsToRechamber = 0;
	self notify ("dropped_gun");
	maps\_mgturret::restoreDefaults();
}
exception_exposed_mg42_portable()
{
	drop_turret();
} 
 
  
