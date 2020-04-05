#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;

#using_animtree( "generic_human" );

init()
{
	if ( !maps\_zombiemode_weapons::is_weapon_included( "shrink_ray_zm" ) )
	{
		return;
	}

	level.shrink_models = [];
	if(isDefined(level.shrink_ray_model_mapping_func))
	{
		[[level.shrink_ray_model_mapping_func]]();
	}

	set_zombie_var( "shrink_ray_fling_range",			450 ); // 40 feet
	set_zombie_var( "shrink_ray_cylinder_radius",			90 );

	//Precache all mini models
	keys = getarraykeys(level.shrink_models);
	for(i=0;i<keys.size;i++)
	{
		precacheModel(level.shrink_models[keys[i]]);
	}

	//FX
	level._effect[ "shrink_ray_stepped_on" ]			= loadfx( "maps/zombie_temple/fx_ztem_zombie_mini_squish" );
	level._effect[ "shrink_ray_stepped_on_in_water" ]	= loadfx( "maps/zombie_temple/fx_ztem_zombie_mini_drown" );
	level._effect["shrink_ray_stepped_on_no_gore"]		= loadfx( "maps/zombie_temple/fx_ztem_monkey_shrink" );
	level._effect[ "shrink" ]							= loadfx( "weapon/shrink_ray/zombie_shrink" );
	level._effect[ "unshrink" ]							= loadfx( "weapon/shrink_ray/zombie_unshrink" );

	level thread shrink_ray_on_player_connect();

	level._shrinkable_objects = [];
}

add_shrinkable_object(ent)
{
	level._shrinkable_objects = add_to_array(level._shrinkable_objects, ent, false);
}

remove_shrinkable_object(ent)
{
	level._shrinkable_objects = array_remove(level._shrinkable_objects, ent);
}

shrink_ray_on_player_connect()
{
	for( ;; )
	{
		level waittill( "connecting", player );
		player thread wait_for_shrink_ray_fired();
	}
}

kicked_vox_network_choke()
{
	while(1)
	{
		level._num_kicked_vox = 0;
		wait_network_frame();
	}
}


wait_for_shrink_ray_fired()
{
	self endon( "disconnect" );
	self waittill( "spawned_player" );

	for( ;; )
	{
		self waittill( "weapon_fired" );
		currentweapon = self GetCurrentWeapon();
		if( ( currentweapon == "shrink_ray_zm" ) || ( currentweapon == "shrink_ray_upgraded_zm" ) )
		{
			self thread shrink_ray_fired( currentweapon == "shrink_ray_upgraded_zm" );

//			view_pos = self GetTagOrigin( "tag_flash" ) - self GetPlayerViewHeight();
//			view_angles = self GetTagAngles( "tag_flash" );
//			playfx( level._effect["freezegun_smoke_cloud"], view_pos, AnglesToForward( view_angles ), AnglesToUp( view_angles ) );
		}
	}
}


shrink_ray_fired( upgraded )
{
	zombies = shrink_ray_get_enemies_in_range( upgraded, false );
	objects = shrink_ray_get_enemies_in_range( upgraded, true );

	zombies = array_combine(zombies, objects);

	maxShrinks = 1000; //No max
//	maxShrinks = 5;
//	if(upgraded)
//	{
//		maxShrinks = 10;
//	}

	for ( i = 0; i < zombies.size && i<maxShrinks; i++ )
	{
		if(IsAI(zombies[i]))
		{
			zombies[i] thread shrink_zombie(upgraded, self);
		}
		else if(IsPlayer(zombies[i]))
		{
			weapon = "shrink_ray_zm";
			if(upgraded)
			{
				weapon = "shrink_ray_upgraded_zm";
			}
			zombies[i] notify("grief_damage", weapon, "MOD_PROJECTILE", self);
		}
		else
		{
			zombies[i] notify("shrunk", upgraded);	// To allow sidequest items to react to the shrink ray....
		}
	}
}

shrink_ray_do_damage( upgraded, player )
{
	damage = 10;
	self DoDamage( damage, player.origin, player, undefined, "projectile" );

	self shrink_ray_debug_print( damage, (0, 1, 0) );
}

shrink_corpse(upgraded, attacker)
{
	//Check if already been hit by the shink ray
	if(isDefined(self.shrinked) && self.shrinked)
	{
		return;
	}

	self.shrinked = true;

	numModels = self GetAttachSize();
	for( i = numModels-1; i >= 0; i-- )
	{
		model = self GetAttachModelName( i );
		self Detach( model );

		//If there is a mapping for part
		attachModel = level.shrink_models[model];
		if(isDefined(attachModel))
		{
			self Attach( attachModel );
		}
	}

	//Set to small body
	mini_model = level.shrink_models[self.model];
	if(isDefined(mini_model))
	{
		self setModel(mini_model);
	}
}

shrink_zombie(upgraded, attacker)
{
	self endon( "death" );

	//Check if already been hit by the shink ray
	if(isDefined(self.shrinked) && self.shrinked)
	{
		return;
	}

	if( !isdefined(self.shrink_count) )
	{
		self.shrink_count = 0;
	}

	shrinkTime = 2.5;
	if(self.animname == "sonic_zombie")
	{
		if(self.shrink_count==0)
		{
			shrinkTime = 0.75;
		}
		else if(self.shrink_count==1)
		{
			shrinkTime = 1.5;
		}
		else
		{
			shrinkTime = 2.5;
		}
	}
	else if(self.animname == "napalm_zombie")
	{
		if(self.shrink_count==0)
		{
			shrinkTime = 0.75;
		}
		else if(self.shrink_count==1)
		{
			shrinkTime = 1.5;
		}
		else
		{
			shrinkTime = 2.5;
		}
	}
	else
	{
		shrinkTime = 2.5;
		shrinkTime += randomfloatrange(0.0,0.5);
	}

	if(upgraded)
	{
		shrinkTime *= 2;
	}

	self.shrink_count++;


	shrinkFXWait = 0;

	self setZombieShrink(1);
	self notify("shrink");
	self.shrinked = true;
	self.shrinkAttacker = attacker;

	if ( !isdefined( attacker.shrinked_zombies ) )
	{
		attacker.shrinked_zombies = [];
	}
	if ( !isdefined( attacker.shrinked_zombies[self.animname] ) )
	{
		attacker.shrinked_zombies[self.animname] = 0;
	}
	attacker.shrinked_zombies[self.animname]++;

	//Save health and model
	///////////////////////
	normalModel = self.model;
	health = self.health;

	if(isDefined(self.animname) && self.animname == "monkey_zombie")
	{
		if ( IsDefined(self.shrink_ray_fling) )
		{
			self [[self.shrink_ray_fling]](attacker);
		}
		else
		{
			// the closer they are, the harder they get flung
			fling_range_squared = level.zombie_vars["shrink_ray_fling_range"] * level.zombie_vars["shrink_ray_fling_range"];
			view_pos = attacker GetWeaponMuzzlePoint();
			test_origin = self getcentroid();

			test_range_squared = DistanceSquared( view_pos, test_origin );

			dist_mult = (fling_range_squared - test_range_squared) / fling_range_squared;
			fling_vec = VectorNormalize( test_origin - view_pos );

			fling_vec = (fling_vec[0], fling_vec[1], abs( fling_vec[2] ));
			fling_vec = vector_scale( fling_vec, 100 + 100 * dist_mult );

			self DoDamage( self.health + 666, attacker.origin, attacker );
			self StartRagdoll();
			self LaunchRagdoll( fling_vec );
		}
	}
	else if(self zombie_gib_on_shrink_ray())
	{
		self shrink_death(attacker);
	}
	else
	{
		// Play shrink sfx
		self thread play_shrink_sound( "evt_shrink" );
		self.shrinkAttacker thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "shrink" );

		//Play shrink fx
		self thread play_shrink_fx("shrink", "J_MainRoot");

		//override damage
		saved_meleeDamage = self.meleeDamage;
		self.meleeDamage = 10;
		//Disable Attacks
		//self.in_special_attack = true;

		//Stop glowing eyes
		self maps\_zombiemode_spawner::zombie_eye_glow_stop();

		attachedModels = [];
		attachedTags = [];

		hatModel = self.hatModel;

		numModels = self GetAttachSize();
		for( i = numModels-1; i >= 0; i-- )
		{

			model = self GetAttachModelName( i );
			tag = self GetAttachTagName(i);

			isHat = isDefined(self.hatModel) && (self.hatModel == model);
			if(isHat)
			{
				self.hatModel = undefined;	//So no one tries to remove it.
			}

			//Save detached models do they can be put back
			attachedModels[attachedModels.size] = model;
			attachedTags[attachedTags.size] = tag;

			self Detach( model );

			//If there is a mapping for part
			attachModel = level.shrink_models[model];
			if(isDefined(attachModel))
			{
				self Attach( attachModel );
				if(isHat)
				{
					self.hatModel = attachModel;
				}
			}
		}


		//Set to small body
		mini_model = level.shrink_models[self.model];
		if(isDefined(mini_model))
		{
			self setModel(mini_model);
		}

//		if(GetDvar( "zombie_shrink_radius") == "")
//		{
//			setdvar("zombie_shrink_radius","8");
//			setdvar("zombie_shrink_min","-16");
//			setdvar("zombie_shrink_max","10");
//			setdvar("zombie_shrink_z", "0");
//		}
//
//		dvar_radius = GetDvarInt( "zombie_shrink_radius");
//		dvar_min = GetDvarInt( "zombie_shrink_min");
//		dvar_max = GetDvarInt( "zombie_shrink_max");
//		dvar_z = getdvarint("zombie_shrink_z");

		if ( self.has_legs )
		{
			self setPhysParams( 8, -2, 32 );
		}
		else
		{
			//Bump the crawlers out of the ground a little
			newOrigin = self.origin + (0,0,10);
			self teleport(newOrigin, self.angles);
			self setPhysParams( 8, -16, 10 );
		}

		self.health  = 1;

		//Wait
		self thread play_ambient_vox();
		self thread watch_for_kicked();
		self thread watch_for_death();

		self.zombie_board_tear_down_callback = ::zomibe_shrunk_board_tear_down;

		if ( IsDefined( self._zombie_shrink_callback ) )
		{
			self [[ self._zombie_shrink_callback ]]();
		}

		wait(shrinkTime);

		// Play unshrink sfx
		self thread play_shrink_sound( "evt_unshrink" );

		self thread play_shrink_fx("unshrink", "J_MainRoot");
		wait 0.5;

		self.zombie_board_tear_down_callback = undefined;

		if ( IsDefined( self._zombie_unshrink_callback ) )
		{
			self [[ self._zombie_unshrink_callback ]]();
		}

		//Detach all current attachments
		numModels = self GetAttachSize();
		for( i = numModels-1; i >=0 ; i-- )
		{
			model = self GetAttachModelName( i );
			tag = self GetAttachTagName(i);

			self Detach( model );
		}

		self.hatModel = hatModel;

		//Attach all previous attachements
		for(i=0; i<attachedModels.size; i++)
		{
			self Attach( attachedModels[i] );
		}

		//Grow back
		self setModel( normalModel );

		if ( self.has_legs )
		{
			self setPhysParams(15,0,72);
		}
		else
		{
			self setPhysParams(15,0,24);
		}

		self.health = health;

		self.meleeDamage = saved_meleeDamage;

		//Enable Attacks
		//self.in_special_attack = undefined;
	}

	self maps\_zombiemode_spawner::zombie_eye_glow();
  	self setZombieShrink(0);
	self notify("unshrink");
	self.shrinked = false;
	self.shrinkAttacker = undefined;
}

zombie_gib_on_shrink_ray()
{
	//Crawlers shrunk while linked would be underground so we kill them
	if(isDefined(self GetLinkedEnt()))
	{
		return true;
	}
	//Prevent zombies from going under geo
	if(is_true(self.sliding))
	{
		return true;
	}
	if(is_true(self.in_the_ceiling))
	{
		return true;
	}
	return false;
}

play_ambient_vox()
{
	self endon("unshrink");
	self endon("stepped_on");
	self endon("kicked");
	self endon("death");

	wait(randomfloatrange(.2,.5));

	while(1)
	{
		self playsound( "zmb_mini_ambient" );
		wait(randomfloatrange(1,2.25));
	}
}

//Play Shrink FX
play_shrink_fx(fxName, jointName, offset)
{
	PlayFXOnTag( level._effect[fxName], self, "tag_origin" );
}

play_shrink_sound( alias )
{
	self endon("death");
	wait( randomfloat( 0.5 ) );
	self play_sound_on_entity( alias );
}

//zombie_set_head_model()
//{
//	if(isDefined(self.headModel) && isDefined(self.headModelTag))
//	{
//		return;
//	}
//	num = self GetAttachSize();
//	for( i = 0; i < num; i++ )
//	{
//		model = self GetAttachModelName( i );
//		if( isDefined(self.headModel) )
//		{
//			if(model == self.headModel)
//			{
//				self.headModelTag = self GetAttachTagName(i);
//				break;
//			}
//		}
//		else if( IsSubStr( model, "head" ) )
//		{
//			self.headModel = model;
//			self.headModelTag = self GetAttachTagName(i);
//			break;
//		}
//	}
//}

watch_for_kicked()
{
	self endon("death");
	self endon("unshrink");

	self.shrinkTrigger = spawn( "trigger_radius", self.origin, 0, 30, 24 );
	self.shrinkTrigger setHintString( "" );
	self.shrinkTrigger setCursorHint( "HINT_NOICON" );

	self.shrinkTrigger EnableLinkTo();
	self.shrinkTrigger LinkTo( self );

	self thread delete_on_unshrink();

	while(1)
	{
		self.shrinkTrigger waittill("trigger", who);
		if(!isPlayer(who))
		{
			continue;
		}

		//Don't kick zombies behind barriers
		if(!is_true(self.completed_emerging_into_playable_area))
		{
			continue;
		}

		//Don't kick guys with mbs (for risers, sonics, and napalms)
		if(is_true(self.magic_bullet_shield))
		{
			continue;
		}

		//Movement Dir
		movement = who GetNormalizedMovement();
		if ( Length(movement) < .1)
		{
			continue;
		}

		//Direction to enemy
		toEnemy = self.origin - who.origin;
		toEnemy = (toEnemy[0], toEnemy[1], 0);
		toEnemy = VectorNormalize( toEnemy );

		//Facing Direction
		forward_view_angles = AnglesToForward(who.angles);

		dotFacing = VectorDot( forward_view_angles, toEnemy );	//Check player is facing enemy

		//Kick if facing enemy
		if( dotFacing > 0.5 && movement[0] > 0.0)
		{
			//Kick if in front
			self notify("kicked");
			self kicked_death(who);
		}
		else
		{
			//Step on
			self notify("stepped_on");
			self shrink_death(who);
		}
	}
}

delete_on_unshrink()
{
	self endon("death");

	self waittill("unshrink");
	if( isDefined(self.shrinkTrigger))
	{
		self.shrinkTrigger Delete();
	}
}

watch_for_death()
{
	self endon("unshrink");
	self endon("stepped_on");
	self endon("kicked");

	self waittill("death");

	self shrink_death();
}

kicked_death(killer)
{
	if( isDefined(self.shrinkTrigger))
	{
		self.shrinkTrigger Delete();
	}

	self thread kicked_sound();

	kickAngles = killer.angles;
	kickAngles += (RandomFloatRange(-30, -20), RandomFloatRange(-5, 5), 0); //pitch up the angle
	launchDir = AnglesToForward(kickAngles);

	if(killer isSprinting())
	{
		launchForce = RandomFloatRange(350, 400);
	}
	else
	{
		vel = killer GetVelocity();
		speed = Length(vel);
		scale = clamp(speed/190,0.1,1.0);
		launchForce = RandomFloatRange(200*scale, 250*scale);
	}

	self SetPlayerCollision(0);
	self StartRagdoll();
	self launchragdoll(launchDir * launchForce);
	self setclientflag(level._CF_ACTOR_RAGDOLL_IMPACT_GIB);
	wait_network_frame();

	killer thread maps\_zombiemode_audio::create_and_play_dialog( "kill", "shrunken" );

	// Make sure they're dead...physics launch didn't kill them.
	self dodamage(self.health + 666, self.origin, killer);
}

kicked_sound()
{
	if(!IsDefined(level._num_kicked_vox))
    {
    	level thread kicked_vox_network_choke();
    }

    if(level._num_kicked_vox > 3)
    {
    	return;
    }

    level._num_kicked_vox ++;

	playsoundatposition("zmb_mini_kicked", self.origin);
}

shrink_death(killer)
{
	if( isDefined(self.shrinkTrigger))
	{
		self.shrinkTrigger Delete();
	}

	playsoundatposition("zmb_mini_squashed", self.origin);

	if(is_mature())
	{
		fx_name = "shrink_ray_stepped_on";
		if(self depthinwater()>0)
		{
			fx_name = "shrink_ray_stepped_on_in_water";
		}
		playfx( level._effect[ fx_name ], self.origin );
	}
	else
	{
		playfx( level._effect["shrink_ray_stepped_on_no_gore"], self.origin );
	}

	self SetPlayerCollision(0);
	self thread maps\_zombiemode_spawner::zombie_eye_glow_stop();
	wait_network_frame();
	self Hide();
	self dodamage(self.health + 666, self.origin, killer);
}

shrink_ray_get_enemies_in_range( upgraded, shrinkable_objects )
{
	range = level.zombie_vars["shrink_ray_fling_range"];
	radius = level.zombie_vars["shrink_ray_cylinder_radius"];

	hitZombies = [];

	view_pos = self GetWeaponMuzzlePoint();

	// Add a 10% epsilon to the range on this call to get guys right on the edge

	test_list = undefined;

	if(shrinkable_objects)
	{
		test_list = level._shrinkable_objects;
		range *= 10;
	}
	else
	{
		test_list = GetAISpeciesArray("axis", "all");
		test_list = array_merge(test_list, get_players());
	}

	zombies = get_array_of_closest( view_pos, test_list, undefined, undefined, (range * 1.1) );

	if ( !isDefined( zombies ))
	{
		return;
	}

	range_squared = range * range;
	radius_squared = radius * radius;

	forward_view_angles = self GetWeaponForwardDir();
	end_pos = view_pos + vector_scale( forward_view_angles, range );

/#
	if ( 2 == GetDvarInt( #"scr_shrink_ray_debug" ) )
	{
		// push the near circle out a couple units to avoid an assert in Circle() due to it attempting to
		// derive the view direction from the circle's center point minus the viewpos
		// (which is what we're using as our center point, which results in a zeroed direction vector)
		near_circle_pos = view_pos + vector_scale( forward_view_angles, 2 );

		Circle( near_circle_pos, radius, (1, 0, 0), false, false, 100 );
		Line( near_circle_pos, end_pos, (0, 0, 1), 1, false, 100 );
		Circle( end_pos, radius, (1, 0, 0), false, false, 100 );
	}
#/

	for ( i = 0; i < zombies.size; i++ )
	{
		if ( !IsDefined( zombies[i] ) || (IsAI(zombies[i]) && !IsAlive( zombies[i] )) )
		{
			// guy died on us
			continue;
		}

		if(isDefined(zombies[i].shrinked) && zombies[i].shrinked)
		{
			zombies[i] shrink_ray_debug_print( "shrinked", (1, 0, 0) );
			continue; //Dont include already shrinked guys
		}

		if ( IsDefined(zombies[i].no_shrink) && zombies[i].no_shrink )
		{
			zombies[i] shrink_ray_debug_print( "no_shrink", (1, 0, 0) );
			continue; //Dont include zombies that cannot be shrunk guys
		}

		test_origin = zombies[i] getcentroid();
		test_range_squared = DistanceSquared( view_pos, test_origin );
		if ( test_range_squared > range_squared )
		{
			zombies[i] shrink_ray_debug_print( "range", (1, 0, 0) );
			break; // everything else in the list will be out of range
		}

		normal = VectorNormalize( test_origin - view_pos );
		dot = VectorDot( forward_view_angles, normal );
		if ( 0 > dot )
		{
			// guy's behind us
			zombies[i] shrink_ray_debug_print( "dot", (1, 0, 0) );
			continue;
		}

		radial_origin = PointOnSegmentNearestToPoint( view_pos, end_pos, test_origin );
		if ( DistanceSquared( test_origin, radial_origin ) > radius_squared )
		{
			// guy's outside the range of the cylinder of effect
			zombies[i] shrink_ray_debug_print( "cylinder", (1, 0, 0) );
			continue;
		}

		if ( 0 == zombies[i] DamageConeTrace( view_pos, self ) && !BulletTracePassed( view_pos, test_origin, false, undefined ) && !SightTracePassed( view_pos, test_origin, false, undefined ) )
		{
			// guy can't actually be hit from where we are
			zombies[i] shrink_ray_debug_print( "cone", (1, 0, 0) );
			continue;
		}

		hitZombies[hitZombies.size] = zombies[i];
	}

	return hitZombies;
}

shrink_ray_debug_print( msg, color )
{
/#
	if ( !GetDvarInt( #"scr_shrink_ray_debug" ) )
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

zomibe_shrunk_board_tear_down()
{
	self endon("death");
	self endon("unshrink");

	while(1)
	{
		taunt_anim = random(level._zombie_board_taunt["zombie"]);
		self animscripted( "shrunk_taunt_end", self.origin, self.angles, taunt_anim );
		animscripts\traverse\zombie_shared::wait_anim_length( taunt_anim, .02 );
	}
}
