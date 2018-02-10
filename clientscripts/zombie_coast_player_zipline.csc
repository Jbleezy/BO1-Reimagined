#include clientscripts\_utility;

/*------------------------------------
player zipline clientscript
------------------------------------*/

/*------------------------------------
setup the player zipline anims
------------------------------------*/
#using_animtree("zombie_coast");
init_player_zipline_anims()
{

	//temp test with CUBA zipline anim to get it working
	level.zipline_anims = [];
	level.zipline_anims["zipline_grab"] = %pb_zombie_zipline_grab;
	level.zipline_anims["zipline_release"] = %pb_zombie_zipline_release;
	level.zipline_anims["zipline_loop"] = %pb_zombie_zipline_loop;

	level.zipline_animtree = #animtree;

	level.zipline_fov = 55;
	level.default_fov = 65;

}


/*------------------------------------
some rumble during the player ziplining
------------------------------------*/
zipline_rumble_and_quake(localClientNum, set,newEnt)
{
	self endon("death");
	self endon("disconnect");

	player = getlocalplayers()[localClientNum];

	if(player GetEntityNumber() != self GetEntityNumber())
	{
		return;	// only do this for the player going down the zipline...
	}

	if(self isspectating())
	{
		return;
	}

	if(set)
	{
		//any zipline hotness
		self thread do_zipline_fx(localClientNum);
	}
	else
	{
		self notify("stop_zipline_fx");

		realwait(1.5);
		/*if (getlocalplayers().size == 1)
		{
			fov = GetDvarInt("cg_fov_settings");
			self thread lerp_fov(.75,level.zipline_fov,fov,false);
		}*/
	}
}

do_zipline_fx(localClientNum)
{
	self endon("stop_zipline_fx");
	self endon("disconnect");
	self endon("entityshutdown");

	/*if (getlocalplayers().size == 1)
	{
		fov = GetDvarInt("cg_fov_settings");
		self thread lerp_fov(.75,fov,level.zipline_fov,true);
	}*/

	ent_num = self GetEntityNumber();

	while(1)
	{
		if(ent_num != self GetEntityNumber())
		{
			return;	// spectate mode viewer toggle.
		}

		self Earthquake( RandomFloatRange( 0.15, 0.22 ), RandomFloatRange(0.15, 0.22), self.origin, 100 );
		self PlayRumbleOnEntity(localClientNum, "slide_rumble");
		realwait(randomfloatrange(.1,.15));
	}
}


/*------------------------------------
some hackery to get the player looking decent in 3rd person
------------------------------------*/

/*zipline_debug_thread(fake)
{
	self endon("end_zipline");

	while(1)
	{
		pos = self.origin;

		pos += AnglesToForward(self.angles) * 1440;
		pos -= AnglesToRight(self.angles) * 480;

		Print3D(pos, "O (" + self GetEntityNumber() + ") : " + self.origin, (0.2, 0.8, 0.2), 1, 3, 1);

		pos += (0,0,-32);

		Print3D(pos, "A (" + self GetEntityNumber() + ") : " + self.angles, (0.2, 0.8, 0.2), 1, 3, 1);


		if(IsDefined(fake))
		{
			pos += (0,0,-32);

			Print3D(pos, "O (" + fake GetEntityNumber() + ") : " + fake.origin, (0.8, 0.2, 0.2), 1, 3, 1);

			pos += (0,0,-32);

			Print3D(pos, "A (" + fake GetEntityNumber() + ") : " + fake.angles, (0.8, 0.2, 0.2), 1, 3, 1);
		}

		wait(0.01);
	}
}*/

zipline_player_fire(fake_player)
{
	self endon("end_zipline");
	self endon ("entityshutdown");

	while(1)
	{
		self waittill("weapon_fired", weapon, tag);

//		fake_player.fake_weapon FireWeapon(weapon, tag, self GetEntityNumber());
	}
}

#using_animtree("zombie_coast");
zipline_player_setup(localClientNum, set,newEnt)
{
	player = getlocalplayers()[localClientNum];

	if(player GetEntityNumber() == self GetEntityNumber())
	{
		return;	// Dont be doing this for the player going down the zipline...
	}

	if(set)
	{

		if(localClientNum == 0)
		{
				self thread player_disconnect_tracker();
		}

		fake_player = Spawn( localClientNum, self.origin, "script_model" );
		fake_player.angles = self.angles;
		fake_player SetModel( self.model );
		fake_player linkto(self,"tag_origin");
		self EntYawOverridesLinkYaw(true);
		self EntGetsWeaponFireNotification(true);
		fake_player.fake_weapon = spawn(localClientNum, self.origin, "script_model");

		if( self.weapon != "none")
		{
			fake_player.fake_weapon SetModel( getweaponmodel(self.weapon) );
			fake_player.fake_weapon useweaponhidetags( self.weapon );
		}
		else
		{
			self thread zipline_weapon_monitor(fake_player.fake_weapon);
		}

		fake_player.fake_weapon LinkTo( fake_player, "tag_weapon_right");

		realWait(0.016);

		fake_player UseAnimTree( level.zipline_animtree);
		fake_player setanim( level.zipline_anims["zipline_grab"],1,0,1);
		grab_time = GetAnimLength(level.zipline_anims["zipline_grab"]);
		wait(grab_time);
		fake_player clearanim(level.zipline_anims["zipline_grab"],0);
		fake_player SetAnim( level.zipline_anims["zipline_loop"], 1.0, 0.0, 1.0 );

		if(!isDefined(self.fake_player_zipline))
		{
			self.fake_player_zipline = [];
		}
		self.fake_player_zipline[localClientNum] = fake_player;

//		self thread zipline_debug_thread(fake_player);
		self thread zipline_player_fire(fake_player);
		self thread wait_for_ziplining_player_to_disconnect(localClientNum);

	}
	else
	{
		if(!IsDefined(self) || !isDefined(self.fake_player_zipline) || !isDefined(self.fake_player_zipline[localClientNum]))
		{
			return;
		}

		self notify("end_zipline");

		self.fake_player_zipline[localClientNum] clearanim(level.zipline_anims["zipline_loop"],0);
		self.fake_player_zipline[localClientNum] SetAnim( level.zipline_anims["zipline_release"], 1.0, 0.0, 1.0 );
		release_time = GetAnimLength(level.zipline_anims["zipline_release"]);
		wait(release_time);

		if(IsDefined(self.fake_player_zipline[localClientNum].fake_weapon))
		{
			self.fake_player_zipline[localClientNum].fake_weapon Delete();
			self.fake_player_zipline[localClientNum].fake_weapon = undefined;
		}

		self EntYawOverridesLinkYaw(false);
		self EntGetsWeaponFireNotification(false);

		self.fake_player_zipline[localClientNum] delete();
		self.fake_player_zipline[localClientNum] = undefined;

		str_notify = "player_ziplining" + localClientNum;
		self notify(str_notify);

	}
}

zipline_weapon_monitor(fake_weapon)
{
	self endon("end_zipline");
	self endon("disconnect");

	while(self.weapon == "none")
	{
		wait(.05);
	}
	fake_weapon SetModel( getweaponmodel(self.weapon) );
	fake_weapon useweaponhidetags( self.weapon );

}



lerp_fov( time, basefov, destfov, ziplining )
{
	level endon("stop_lerping_thread");
	self endon("entityshutdown");

	incs = int( time/.01 );
	incfov = (  destfov  -  basefov  ) / incs ;
	currentfov = basefov;

	// AE 9-17-09: if incfov is 0 we should move on without looping
	if(incfov == 0)
	{
		return;
	}

	if(ziplining)
		self.is_ziplining = true;

	for ( i = 0; i < incs; i++ )
	{
		currentfov += incfov;
		SetClientDvar( "cg_fov", currentfov );
		realwait(.01);
	}
	//fix up the little bit of rounding error. not that it matters much .002, heh
	SetClientDvar( "cg_fov", destfov );

	if(!ziplining)
		self.is_ziplining = false;
}


/*------------------------------------
track the player being flung
self = the flung player
------------------------------------*/
player_disconnect_tracker()
{
	self endon("stop_zipline_fx");

	ent_num = self GetEntityNumber();

	while(IsDefined(self))
	{
		wait(0.05);
	}

	level notify("player_disconnected_zip",ent_num);
}


/*------------------------------------
wait to see if the person ziplining disconnects during the ride
then do some cleanup

self = players who are NOT ziplining
------------------------------------*/

zipline_model_remover(str_endon, player)
{
	player endon(str_endon);

	level waittill("player_disconnected_zip", client);

	if(IsDefined(self.fake_weapon))
	{
		self.fake_weapon Delete();
	}

	self Delete();
}

wait_for_ziplining_player_to_disconnect(localClientNum)
{
	str_endon = "player_ziplining"+localClientNum;

	self.fake_player_zipline[localClientNum] thread zipline_model_remover(str_endon, self);
}
