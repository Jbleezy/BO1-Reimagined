#include maps\_utility;
#include animscripts\zombie_utility;
#include animscripts\zombie_SetPoseMovement;
#include animscripts\Combat_Utility;
#include animscripts\Debug;
#include common_scripts\utility;
#using_animtree ("generic_human");

// ===========================================================
//     AI vs Player melee
// ===========================================================

MeleeCombat()
{
	self endon( "end_melee" );
 	self endon("killanimscript");
	self melee_notify_wrapper();

	/#
	self animscripts\debug::debugPushState( "melee" );
	#/

	assert( CanMeleeAnyRange() );

	// AI vs AI melee disabled for now.
	if(IsDefined(level.allow_ai_vs_ai_melee ))
	{
		doingAIMelee = (isAI( self.enemy ) && self.enemy.type == "human");
	}
	else
	{
		doingAIMelee = false;
	}

	if ( doingAiMelee )
	{
		assert( animscripts\zombie_utility::okToMelee( self.enemy ) );
		animscripts\zombie_utility::IAmMeleeing( self.enemy );

		AiVsAiMeleeCombat();

		animscripts\zombie_utility::ImNotMeleeing( self.enemy );

		scriptChange();

		/#
		self animscripts\debug::debugPopState();
		#/

		return;
	}

	realMelee = true;

	if ( animscripts\zombie_utility::okToMelee(self.enemy) )
	{
		animscripts\zombie_utility::IAmMeleeing(self.enemy);
	}
	else
	{
		realMelee = false;
	}

	self thread EyesAtEnemy();
	self OrientMode("face enemy");

	MeleeDebugPrint("Melee begin");

	self AnimMode( "zonly_physics" );

	resetGiveUpTime();

    for ( ;; )
    {
		// Don't attack if you're supposed to die but can't because of the network
		if ( IsDefined(self.marked_for_death) )
		{
			return;
		}

		MeleeDebugPrint("Melee main loop" + RandomInt(100));

		// we should now be close enough to melee.

		// If no one else is meleeing this person, tell the system that I am, so no one else will charge him.
		if ( !realMelee && animscripts\zombie_utility::okToMelee(self.enemy) )
		{
			realMelee = true;
			animscripts\zombie_utility::IAmMeleeing(self.enemy);
		}

		self thread EyesAtEnemy();

		self animscripts\battleChatter_ai::evaluateMeleeEvent();

		if( IsDefined( self.enemy ) )
		{
			angles = VectorToAngles( self.enemy.origin - self.origin );
			self OrientMode( "face angle", angles[1] );
		}

		if( !IsDefined(level.zombietron_mode) )
		{
		    switch( self.animname )
		    {
		        case "zombie":
		            self PlaySound( "zmb_vocals_zombie_attack" );
		            break;

		        case "quad_zombie":
		            self PlaySound( "zmb_vocals_quad_attack" );
		            break;

		        case "boss_zombie":
		            self PlaySound( "zmb_vocals_boss_attack" );
		            break;
				//Raven begin
				case "napalm_zombie":
					self PlaySound( "zmb_vocals_napalm_attack" );
					break;

				case "sonic_zombie":
					self PlaySound( "zmb_vocals_sonic_attack" );
					break;
				//Raven End
		    }
		}

		if ( is_true( self.noChangeDuringMelee ) )
		{
			self.safeToChangeScript = false;
		}

		zombie_attack = pick_zombie_melee_anim( self );

		if ( isDefined( self.melee_anim_func ) )
		{
			self thread [[ self.melee_anim_func ]]( zombie_attack );
		}

		self SetFlaggedAnimKnobAllRestart("meleeanim", zombie_attack, %body, 1, .2, 1);

		while ( 1 )
		{
			self waittill("meleeanim", note);
			if ( note == "end" )
			{
				break;
			}
			else if ( note == "fire" )
			{
				if ( !IsDefined( self.enemy ) )
				{
					break;
				}

				oldhealth = self.enemy.health;

				self melee();

				if ( self.enemy.health < oldhealth )
				{
					resetGiveUpTime();
				}
				else
				{
					if ( isDefined( self.melee_miss_func ) )
					{
						self [[ self.melee_miss_func ]]();
					}
					else if ( isDefined( level.melee_miss_func ) )
					{
						self [[ level.melee_miss_func ]]();
					}
				}
			}
			else if ( note == "stop" )
			{
				// check if it's worth continuing with another melee.
				if ( !CanContinueToMelee() ) // "if we can't melee without charging"
				{
					break;
				}
			}
		}

		self OrientMode("face default");

		if ( is_true( self.noChangeDuringMelee ) )
		{
			if ( isDefined( self.enemy ) )
			{
				dist_sq = DistanceSquared( self.origin, self.enemy.origin );
				if ( dist_sq > self.meleeAttackDist * self.meleeAttackDist )
				{
					self.safeToChangeScript = true;
					wait_network_frame();
					break;
				}
			}
			else
			{
				self.safeToChangeScript = true;
				wait_network_frame();
				break;
			}
		}
    }

	if (realMelee)
	{
		animscripts\zombie_utility::ImNotMeleeing(self.enemy);
	}

	self AnimMode("none");

	/#
	debug_replay("melee.gsc MeleeCombat()");
	#/
	self thread animscripts\zombie_combat::main();
	self notify ("stop EyesAtEnemy");
	self notify ("stop_melee_debug_print");
	scriptChange();

	/#
	self animscripts\debug::debugPopState();
	#/
}

resetGiveUpTime()
{
	if ( DistanceSquared( self.origin, self.enemy.origin ) > anim.chargeRangeSq )
	{
		self.giveUpOnMeleeTime = GetTime() + randomintrange( 2700, 3300 );
	}
	else
	{
		self.giveUpOnMeleeTime = GetTime() + randomintrange( 1700, 2300 );
	}
}

MeleeDebugPrint(text)
{
	return;
	self.meleedebugprint = text;
	self thread meleeDebugPrintThreadWrapper();
}

meleeDebugPrintThreadWrapper()
{
	if ( !IsDefined(self.meleedebugthread) )
	{
		self.meleedebugthread = true;
		self meleeDebugPrintThread();
		self.meleedebugthread = undefined;
	}
}

meleeDebugPrintThread()
{
	self endon("death");
	self endon("killanimscript");
	self endon("stop_melee_debug_print");

	while(1)
	{
		Print3d(self.origin + (0,0,60), self.meleedebugprint, (1,1,1), 1, .1);
		wait .05;
	}
}

// Debug melee functions
debug_melee_on_actor()
{
	/#
	dvar = GetDvarInt( #"ai_debugMelee" );
	if ( dvar == 0 )
	{
		return false;
	}

	if ( dvar == 1 )
	{
		return true;
	}

	if ( int( dvar ) == self getentnum() )
	{
		return true;
	}
	#/

	return false;
}

debug_melee( msg )
{
	if ( !debug_melee_on_actor() )
	{
		return;
	}

	PrintLn( msg );

	/#recordEntText( msg, self, level.color_debug["white"], "Script" );#/
}

debug_melee_line( start, end, color, duration )
{
	/#
	dvar = GetDvarInt( #"ai_debugMelee" );
	if ( dvar == 0 )
	{
		return;
	}


	if( IsDefined(self) )
	{
		recordLine( start, end, color, "Script", self );
	}

	debugLine( start, end, color, duration );
	#/
}

CanContinueToMelee()
{
	return CanMeleeInternal( "already started" );
}

CanMeleeAnyRange()
{
	return CanMeleeInternal( "any range" );
}

CanMeleeDesperate()
{
	return CanMeleeInternal( "long range" );
}

CanMelee()
{
	return CanMeleeInternal( "normal" );
}

CanMeleeInternal( state )
{
	// no meleeing virtual targets
	if ( !IsSentient( self.enemy ) )
	{
		debug_melee( "Not doing melee - Does not have a valid target." );
		return false;
	}

	// or dead ones
	if (!IsAlive(self.enemy))
	{
		return false;
	}

	if ( IsDefined( self.disableMelee ) )
	{
		assert( self.disableMelee ); // must be true or undefined
		debug_melee( "Not doing melee - Melee is disabled, self.disableMelee is set to true." );
		return false;
	}

	// if we're not at least partially facing the guy, wait until we are
	yaw = abs(getYawToEnemy());
	if ( (yaw > 60 && state != "already started") || yaw > 110 )
	{

		debug_melee( "Not doing melee - Not facing the enemy." );
		return false;
	}

	enemyPoint = self.enemy GetOrigin();
	vecToEnemy = enemyPoint - self.origin;
	self.enemyDistanceSq = lengthSquared( vecToEnemy );

	// so we don't melee charge a guy who has gained ignoreme in the past frame
	nearest_enemy_sqrd_dist = self GetClosestEnemySqDist();
	epsilon = 0.1; // Necessary to avoid rounding errors.


	if( IsDefined( nearest_enemy_sqrd_dist ) &&  ( nearest_enemy_sqrd_dist - epsilon > self.enemyDistanceSq ) )
	{
		debug_melee( "Not doing melee - Entity " + self getEntityNumber() + " can't melee entity " + self.enemy getEntityNumber() + " at distSq " + self.enemyDistanceSq + " because there is a closer enemy at distSq " + nearest_enemy_sqrd_dist + "." );
		return false;
	}

	// AI vs AI melee disabled for now.
	if(IsDefined(level.allow_ai_vs_ai_melee ))
	{
		doingAIMelee = (isAI( self.enemy ) && self.enemy.type == "human");
	}
	else
	{
		doingAIMelee = false;
	}

	if ( doingAIMelee )
	{
		// check if someone else is already meleeing my enemy.
		if ( !animscripts\zombie_utility::okToMelee(self.enemy) )
		{
			debug_melee( "Not doing melee - Enemy is already being meleed." );
			return false;
		}

		if ( IsDefined( self.magic_bullet_shield ) && self.magic_bullet_shield && IsDefined( self.enemy.magic_bullet_shield ) && self.enemy.magic_bullet_shield )
		{
			debug_melee( "Not doing melee - Enemy has magic bullet shield." );
			return false;
		}

		if ( !isMeleePathClear( vecToEnemy, enemyPoint ) )
		{
			return false;
		}
	}
	else
	{
		// this check can be removed when AI vs AI melee is working.
		if ( IsDefined( self.enemy.magic_bullet_shield ) && self.enemy.magic_bullet_shield )
		{
			// Banzai attacks are OK against those with magic_bullet_shield - as long as the
			// shielded ones always win the melee.
			if ( !( self is_banzai() ) )
			{
				//AI_TODO - In this case the heros should go through melee, but they do and look bad
				debug_melee( "Not doing melee - Enemy has magic bullet shield." );
				return false;
			}
		}

		if (self.enemyDistanceSq <= anim.meleeRangeSq)
		{
				if ( !isMeleePathClear( vecToEnemy, enemyPoint ) )
				{
					if ( !self is_banzai() )
					{
						return false;
					}
				}

			// Enemy is already close enough to melee.
			return true;
		}
		else if ( self is_banzai() )
		{
			return false;
		}

		if ( state != "any range" )
		{
			chargeRangeSq = anim.chargeRangeSq;
			if ( state == "long range" )
			{
				chargeRangeSq = anim.chargeLongRangeSq;
			}

			if (self.enemyDistanceSq > chargeRangeSq)
			{
				// Enemy isn't even close enough to charge.
				debug_melee( "Not doing melee - Enemy is not close enough to charge." );
				return false;
			}
		}

		if ( state == "already started" ) // if we already started, we're checking to see if we can melee *without* charging.
		{
			return false;
		}

		// at this point, we can melee iff we can charge.

		// don't charge if we recently missed someone
		if ( ( !self is_banzai() || IsPlayer( self.enemy ) ) && IsDefined( self.lastMeleeGiveUpTime ) && GetTime() - self.lastMeleeGiveUpTime < 3000 )
		{
			debug_melee( "Not doing melee - Recently meleed someone and missed." );
			return false;
		}

		// check if someone else is already meleeing my enemy.
		if ( !animscripts\zombie_utility::okToMelee(self.enemy) )
		{
			debug_melee( "Not doing melee - Enemy is being meleed." );
			return false;
		}

		if ( is_true( self.check_melee_path ) )
		{
			if( !isMeleePathClear( vecToEnemy, enemyPoint ) )
			{
				self notify("melee_path_blocked");
				return false;
			}
		}
	}

	return true;
}

isMeleePathClear( vecToEnemy, enemyPoint )
{
	dirToEnemy = VectorNormalize( (vecToEnemy[0], vecToEnemy[1], 0 ) );
	meleePoint = enemyPoint - ( dirToEnemy[0]*28, dirToEnemy[1]*28, 0 );

	thread debug_melee_line( self.origin, meleePoint, ( 1,0,0 ), 1.5 );

	if ( !self IsInGoal( meleePoint ) )
	{
		debug_melee( "Not doing melee - Enemy is outside not in goal." );
		return false;
	}

	if ( self maymovetopoint(meleePoint) )
	{
		return true;
	}

	// we're within melee distance and the melee point is within our goalradius
	// BUT we cannot move to the point with a capsule trace
	// what if we do a sight trace from the knees/eye position.
	trace1 = bullettrace( self.origin + (0,0,20), meleePoint + (0,0,20), true, self );
	trace2 = bullettrace( self.origin + (0,0,72), meleePoint + (0,0,72), true, self );

	//see if we hit anything at all?
	if ( isDefined(trace1["fraction"]) && trace1["fraction"] == 1  &&
			 isDefined(trace2["fraction"]) && trace2["fraction"] == 1 	)
	{	//clear traces (value == 1), room to move?
		return true;
	}
	//trace contacted something, was it the player?
	if ( isDefined(trace1["entity"]) && trace1["entity"] == self.enemy  &&
			 isDefined(trace2["entity"]) && trace2["entity"] == self.enemy 	)
	{
		return true;
	}

	// knees in water / eyes clear
	if ( is_true( level.zombie_melee_in_water ) )
	{
		if ( isDefined( trace1["surfacetype"] ) && trace1["surfacetype"] == "water" &&
			 isDefined( trace2["fraction"] ) && trace2["fraction"] == 1 )
		{
			return true;
		}
	}

	debug_melee( "Not doing melee - Can not move to the melee point, MayMoveToPoint failed." );
	return false;
}

PlayMeleeSound()
{
	if ( !IsDefined ( self.a.nextMeleeChargeSound ) )
	{
		 self.a.nextMeleeChargeSound = 0;
	}

	if ( GetTime() > self.a.nextMeleeChargeSound )
	{
		self animscripts\face::SaySpecificDialogue( undefined, "chr_play_grunt_" + self.voice, 0.3 );
		self.a.nextMeleeChargeSound = GetTime() + 8000;
	}
}

// ===========================================================
//     AI vs AI synced melee
// ===========================================================

AiVsAiMeleeCombat()
{
	self endon("killanimscript");
	self melee_notify_wrapper();

	self OrientMode("face enemy");

	self ClearAnim( %root, 0.3 );

	IWin = ( RandomInt(10) < 8 );
	if ( IsDefined( self.magic_bullet_shield ) && self.magic_bullet_shield )
	{
		IWin = true;
	}

	if ( IsDefined( self.enemy.magic_bullet_shield ) && self.enemy.magic_bullet_shield )
	{
		IWin = false;
	}

	// TODO: more anims
	winAnim = %bog_melee_R_attack;
	loseAnim = %bog_melee_R_defend;

	if ( IWin )
	{
		myAnim = winAnim;
		theirAnim = loseAnim;
	}
	else
	{
		myAnim = loseAnim;
		theirAnim = winAnim;
	}

	// TODO: associate this with the anim
	desiredDistSqrd = 72 * 72;

	self PlayMeleeSound();

	// charge into correct distance
	AiVsAiMeleeCharge( desiredDistSqrd );

	if ( DistanceSquared( self.origin, self.enemy.origin ) > desiredDistSqrd )
	{
		return false;
	}

	// TODO: if too close, Teleport backwards?

	// TODO: disable pushing?

	// TODO: need a tag_sync to LinkTo, like is done with dogs

	// start animation, start enemy on animation
	self.meleePartner = self.enemy;
	self.enemy.meleePartner = self;

	self.enemy.meleeAnim = theirAnim;
	self.enemy animcustom( ::AiVsAiAnimCustom );

	self.meleeAnim = myAnim;
	self animcustom( ::AiVsAiAnimCustom ); // TODO: we should try to avoid using animcustom on ourselves
}

AiVsAiMeleeCharge( desiredDistSqrd )
{
	giveUpTime = GetTime() + 2500;
	self SetAnimKnobAll( animscripts\zombie_run::GetRunAnim(), %body, 1, 0.2 );

	while ( DistanceSquared( self.origin, self.enemy.origin ) > desiredDistSqrd && GetTime() < giveUpTime )
	{
		// play run forward anim
		wait .05;
	}
}

AiVsAiAnimCustom()
{
	self endon("killanimscript");
	self AiVsAiMeleeAnim( self.meleeAnim );
}

AiVsAiMeleeAnim( myAnim )
{
	self endon("end_melee");
	self thread endMeleeOnKillanimscript();

	partnerDir = self.meleePartner.origin - self.origin;
	self OrientMode( "face angle", VectorToAngles( partnerDir )[1] );
	self AnimMode( "zonly_physics" );

	self SetFlaggedAnimKnobAllRestart( "meleeAnim", myAnim, %body, 1, 0.2 );
	self animscripts\zombie_shared::DoNoteTracks( "meleeAnim" );

	self notify("end_melee");
}

endMeleeOnKillanimscript()
{
	self endon("end_melee");
	self waittill("killanimscript");
	self.meleePartner notify("end_melee");
}

//chris_p - rewrote this to be more friendly
pick_zombie_melee_anim( zombie_guy )
{
	melee_anim = undefined;
	if ( zombie_guy.has_legs )
	{
		switch(zombie_guy.zombie_move_speed)
		{

			case "walk":
				anims = array_combine(level._zombie_melee[zombie_guy.animname],level._zombie_walk_melee[zombie_guy.animname]);
				melee_anim = random(anims);
				break;

			case "run":
			case "sprint":
				anims = array_combine(level._zombie_melee[zombie_guy.animname],level._zombie_run_melee[zombie_guy.animname]);
				melee_anim = random(anims);
				break;
		}
	}
	else if(zombie_guy.a.gib_ref == "no_legs")
	{
		// if zombie have no legs whatsoever.
		melee_anim = random(level._zombie_stumpy_melee[zombie_guy.animname]);
	}
	else
	{
 		melee_anim = random(level._zombie_melee_crawl[zombie_guy.animname]);
	}

	return melee_anim;
}
