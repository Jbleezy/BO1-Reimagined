/*------------------------------------
player zipline - chrisp
------------------------------------*/
#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_utility;


main()
{
	precache_zipline_assets();	
	init_player_ziplines();
}

//	current_poi activate_zombie_point_of_interest();
//	flag_wait("lander_grounded");
//	current_poi deactivate_zombie_point_of_interest();

#using_animtree ( "zombie_coast" );
precache_zipline_assets()
{
	precachemodel("viewmodel_hands_no_model");
	
	//temp test with CUBA zipline anim to get it working
	level.zipline_anims = [];
	level.zipline_anims["zipline_grab"] = %pb_zombie_zipline_grab;
	level.zipline_anims["zipline_release"] = %pb_zombie_zipline_release;	
	level.zipline_anims["zipline_loop"] = %pb_zombie_zipline_loop;

	level.zipline_animtree = #animtree;
	
}


/*------------------------------------
init the usable player ziplines
------------------------------------*/
init_player_ziplines()
{
	//players get linked to these fake vehicles, which in turn get put onto splines which run along the zip_lines. There needs to be 4 placed in the map ( 1 for each player)
	zipline_vehicles = getentarray("zipline_vehicles","script_noteworthy");	
	
	//each zipline needs to have a trigger_use with a targetname of "player_zipline" . The trigger needs to target the first node of the zipline vehicle spline. Optionally it can also target a script entity ( i.e. a gate )
	zipline_trigs = getentarray("player_zipline","targetname");	
	array_thread(zipline_trigs,::monitor_player_zipline,zipline_vehicles);
	
	flag_wait("all_players_spawned");
	players = get_players();
	array_thread(players,::jump_button_monitor);
	
	
}



/*------------------------------------
wait for the player to jump onto a zipline
------------------------------------*/
monitor_player_zipline(zipline_vehicles)
{

	//this needs to target the start node of the vehicle spline that the zipline vehicle travels on
	zip_path = self.target;

	
	//the zipline trigger should target both a "gate" and the start node of the vehicle spline
	targets = getentarray(self.target,"targetname");
	poi = undefined;
	for(i=0;i<targets.size;i++)
	{
		
		//the gate that opens, allowing access to the zipline. The script_string should hold any flag names that are required to allow access to the zipline
		//TODO - make system able to handle the gate in a more elegant way than just deleting it ;)
		if(targets[i].classname == "script_brushmodel"  || targets[i].classname == "script_model")
		{
			assertex( isDefined(targets[i].script_string), "The zipline gate needs to have a script_string reference with one or more flag names seperated by spaces");
			
			zip_hint_trig = Spawn( "trigger_radius_use", targets[i].origin );
			zip_hint_trig SetCursorHint( "HINT_NOICON" );
			zip_hint_trig sethintstring(&"ZOMBIE_COAST_ZIPLINE_NO_ACCESS");
			
			zipline_flags = strTok( targets[i].script_string, " " );
			
			if(targets[i].targetname == "zipline_test1") //we need to wait for multiple flags intead of "either" flag
			{
				//flag_wait("start_beach_group");
				//flag_wait_any("shipfront_far_enter", "shipfront_deck_storage");
			}
			else
			{
				flag_wait_any_array(zipline_flags);
			}
			// DCS 030111: lowering door and connecting paths, for now.
			//targets[i] Moveto(targets[i].origin + (-76, -33, 0), 0.5);
			targets[i] ConnectPaths();
			zip_hint_trig delete();
			playfx(level._effect["poltergeist"],targets[i].origin);
			targets[i] thread move_delete_zipline_gate();
		}
		else if( targets[i].classname == "script_origin") //for setting up POI stuff
		{
			targets[i] create_zombie_point_of_interest( undefined, 30, 0, false );
			targets[i] thread create_zombie_point_of_interest_attractor_positions( 4, 45 );
			poi = targets[i];
		}
	}
	
	enemyoverride = [];
	enemyoverride[0] = poi.origin;
	enemyoverride[1] = poi;
	

	while(1)
	{
		self  waittill("trigger",who);
				
		if(!isplayer(who) )
		{
			
			if(who.team == "axis")
			{
				who PlayLoopSound( "evt_zipline_slide", .5 );
				who thread wait_to_end_looper();
				continue;
			}
			
			ai = getaiarray("axis");
			followers = [];
			for(i=0;i<ai.size;i++)
			{
				if(isDefined(ai[i].favoriteenemy) && ai[i].favoriteenemy == who)
				{
					ai[i].enemyoverride = enemyoverride;
					ai[i].following_human_zombie = true;
					followers[followers.size] = ai[i];
					//ai[i] thread draw_debug_info();
				}
			}
			who thread wait_for_human_zombie_exit_zipline(followers);			
			who thread reset_followers_on_death(followers);
			continue;
		}
		
		if( !who is_ok_to_zipline(zip_path))
		{
			continue;
		}
		 
		if(isDefined(who.is_ziplining))
		{
			continue;
		}		

		//grab an available vehicle
		vehicle = get_zipline_vehicle(zipline_vehicles);
		
		if(isDefined(vehicle) )
		{
			who.is_ziplining = true;
			who thread do_player_zipline(vehicle,zip_path,self);
			
			//check to see if we should set up the zombie POI stuff
			players = get_players();
			ai = getaiarray("axis");
			followers = [];
			for(i=0;i<ai.size;i++)
			{
				if(isDefined(ai[i].favoriteenemy) && ai[i].favoriteenemy == who)
				{
					ai[i].following_player_zipline = true;
					ai[i].enemyoverride = enemyoverride;
					followers[followers.size] = ai[i];
				}
			}
			who thread wait_for_player_to_disconnect(followers);
			who thread wait_for_player_exit_zipline(followers);
		}		
	}
}

wait_to_end_looper()
{
	self endon("death");
	self waittill( "zombie_end_traverse");
	
	if( IsDefined( self ) )
	{
        self StopLoopSound( 1 );
    }
}

//draw_debug_info()
//{
//	while(isDefined(self.enemyoverride))
//	{
//		Print3D(self.origin + (0,0,70),"POI");
//		wait(.05);
//
//	}
//	
//}
wait_for_player_to_disconnect(followers)
{
	self endon("exit_zipline");
	self waittill("disconnect");
	for(i=0;i<followers.size;i++)
	{
		if(isDefined(followers[i]) && isalive(followers[i]))
		{
			followers[i].following_player_zipline = undefined;
			followers[i].enemyoverride = undefined;
		}
	}
}


wait_for_player_exit_zipline(followers)
{
	self endon("disconnect");
	self endon("death");
	
	self waittill("exit_zipline");

	for(i=0;i<followers.size;i++)
	{
		if(isDefined(followers[i]) && isalive(followers[i]))
		{
			if(isDefined(followers[i].favoriteenemy) && followers[i].favoriteenemy == self)
			{
				followers[i].following_player_zipline = undefined;
				followers[i].enemyoverride = undefined;
			}
		}
	}
}


wait_for_human_zombie_exit_zipline(followers)
{
	self endon("death");
	
	while(is_true(self.is_traversing))
	{
		wait(.05);
	}
	self.is_ziplining = undefined;

	for(i=0;i<followers.size;i++)
	{
		if(isDefined(followers[i]) && isalive(followers[i]))
		{
			if(isDefined(followers[i].favoriteenemy) && followers[i].favoriteenemy == self)
			{
				followers[i].following_human_zombie = undefined;
				followers[i].enemyoverride = undefined;
			}
		}
	}
}

reset_followers_on_death(followers)
{
	
	self endon("zombie_end_traverse");
	self waittill("death");
	for(i=0;i<followers.size;i++)
	{
		if(isDefined(followers[i]) && isalive(followers[i]))
		{
			if(isDefined(followers[i].favoriteenemy) && followers[i].favoriteenemy == self)
			{
				followers[i].following_human_zombie = undefined;
				followers[i].enemyoverride = undefined;
			}
		}
	}
	
}




/*------------------------------------
Checks to make sure the player
should grab the zipline ( i.e. - he's not prone and crawling off the ledge )
------------------------------------*/
is_ok_to_zipline(zip_path)
{
	//TODO: add whatever other checks need to be added

	if(self maps\_laststand::player_is_in_laststand() ) 
	{
		return false;
	}	
	
	
	weap = self getcurrentweapon();
	if( weap == "syrette_sp")
	{
		return false;
	}
	
	if( self getstance() == "stand" || is_true(self.divetoprone))
	{
		
		if(!isDefined(self.jumptime))
		{
			return false;
		}		
		
		if( self jumpbuttonpressed() || ( gettime() - self.jumptime <= 800) || is_true(self.divetoprone))
		{
			return true;
		}

//		//make sure the player is looking forward ( using the zipline spline end node as the direction the player should be looking...)
//		end_node = 	get_zipline_end_node(zip_path);		
//		yaw  =  self animscripts\utility::GetYawToSpot(end_node.origin );
//		
//		// make sure the player is looking withing a 70 degree "cone" of the direction he's supposed to be jumping
//		if( yaw < 70 && yaw > -70 )
//		{		
//			return true;
//		}
	}
	return false;	
}

/*------------------------------------
make the player zipline
self = a player
------------------------------------*/
do_player_zipline(vehicle,zip_path,zip_trig)
{
	self endon("disconnect");
	
	vehicle thread zipline_player_death_disconnect_failsafe(self);

	self Allowstand(true);
	self allowcrouch(true);	
	self EnableInvulnerability();

	
	// attach the vehicle and wait 1 network frame to give the client a chance to catch up.
	// this helps eliminate the rubber-band effect
	vehicle attachpath( getvehiclenode(zip_path,"targetname"));	
	wait_network_frame();
	
	has_perk = isDefined(self.perk_purchased);

	weaponname = self getcurrentweapon();
	
	//set properties on the player for starting the zipline
	self player_enter_zipline(vehicle,zip_path);
	
	//kevin adding audio
	//iprintlnbold ("START");
	sound_ent = spawn( "script_origin" , self.origin );
	sound_ent linkto( self );
	sound_ent playloopsound( "evt_zipline_slide" );
	sound_ent thread force_deletion_of_soundent( self, vehicle );
	

	vehicle startpath();
	wait(.5);
	
	self maps\_zombiemode_audio::create_and_play_dialog( "general", "zipline" );
	
	// so that it looks like the player is firing with one hand while breaching ;)
	
		
	/*if(!has_perk) //the perk system already re-enables the weapons
	{
		//make sure the player doesn't enter the zipline carrying these
		weaponname = self getcurrentweapon();
		if ( is_placeable_mine( weaponname ) || is_equipment( weaponname ) || weaponname == "syrette_sp" )
		{
			primaryWeapons = self GetWeaponsListPrimaries();
			if ( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
			{
				self SwitchToWeapon( primaryWeapons[0] );
			}
		}

		self setviewmodel("viewmodel_hands_no_model");	
		//self enableweapons();	
	}*/
	
	end_node = 	get_zipline_end_node(zip_path);
	wait(.75);
	//self EnableWeaponFire();
	
	while(distancesquared(vehicle.origin,end_node.origin) > (950*950))
	{
		wait(.05);
	}
		
	//stop the rumble/quake before the player exits the zipline
	self clearclientflag(level._CF_PLAYER_ZIPLINE_RUMBLE_QUAKE);
	
	//make the vehicle usable again once it's reached the end of the ride
	vehicle waittill("reached_end_node");	
	
	self thread player_exit_zipline(vehicle,zip_trig);

	//make sure the player doesn't enter the zipline carrying these
	if ( is_equipment( weaponname ) || weaponname == "syrette_sp" )
	{
		primaryWeapons = self GetWeaponsListPrimaries();
		if(IsDefined(self.last_held_primary_weapon) && self HasWeapon(self.last_held_primary_weapon))
		{
			self SwitchToWeapon(self.last_held_primary_weapon);
		}
		else if ( IsDefined( primaryWeapons ) && primaryWeapons.size > 0 )
		{
			self SwitchToWeapon( primaryWeapons[0] );
		}
		else
		{
			self SwitchToWeapon( "combat_" + self get_player_melee_weapon() );
		}
	}
	
	if( IsDefined( sound_ent ) )
	{
	    sound_ent delete();
	}
	
	//stop the telefraging thread
	wait(2);
	self.is_ziplining = undefined;
		
}

force_deletion_of_soundent( player, vehicle )
{
    vehicle endon( "reached_end_node" );
    vehicle endon( "player_unlinked" );
    
    player waittill_any( "death", "disconnect" );
    self Delete();
}

/*------------------------------------
this releases the vehicle back for use in case the player dies or disconnects while on the zipline
------------------------------------*/
zipline_player_death_disconnect_failsafe(player)
{
	//this notify is sent off when the player finishes ziplining
	self endon("player_unlinked");
	player waittill_any("death","disconnect");	

	self unlink();
	self.in_use = undefined;	
}

/*------------------------------------
do anything here to the player that needs to happen just before he starts ziplining
------------------------------------*/
player_exit_zipline(vehicle,zip_trig)
{
	vehicle.in_use = undefined;
	vehicle notify("player_unlinked");
	self DisableInvulnerability();
	
	//stop the clientside zipline fx
	self clearclientflag(level._CF_PLAYER_ZIPLINE_FAKE_PLAYER_SETUP );	
	self move_to_safe_landing_spot(zip_trig,vehicle,self);
	
	//unlink the player and reset everything
	self unlink();

	release_time = GetAnimLength(level.zipline_anims["zipline_release"]);
	//self disableweapons();
	wait(release_time);

	//player dismounts the zipline
	self setloweredweapon(0);
	self Show();	
	wait(1);
	//self maps\zombie_coast::coast_custom_viewmodel_override();
	self EnableWeapons();
	//self EnableWeaponFire();	
	//self EnableWeaponReload();
	self notify("exit_zipline");
	
	//allow the stances
	self allowcrouch(true);
	self allowprone(true);
		
	// a little post effect
	wait(.1);
	Earthquake( RandomFloatRange( 0.35, 0.45 ), RandomFloatRange(.25, .5), self.origin, 100 );

	self.zipline_vehicle = undefined;
	
	self allowads(true);
	self allowsprint(true);
	
	self decrement_is_drinking();
	//self EnableWeaponCycling();
	//self enableoffhandweapons();
	
	self allowmelee(true);
	

}

move_to_safe_landing_spot(zip_trig,vehicle,zipliner)
{
	
	landing_spots = getstructarray(zip_trig.target,"targetname");
	if(landing_spots.size < 1)
	{
		return;
	}
	
	landing_spot_found = false;
	while(!landing_spot_found)
	{
	
		for(i=0;i< landing_spots.size;i++)
		{
			if ( zipliner_can_land_here(landing_spots[i].origin,zipliner) )
			{
				vehicle.origin = landing_spots[i].origin;
				landing_spot_found = true;
			}
		}
		wait(.05);
	}
	
	
}
zipliner_can_land_here(spot,zipliner)
{
	
	players = get_players();
	for(i=0;i<players.size;i++)
	{
		if(players[i] == zipliner)
		{
			continue;
		}
		if( distancesquared(players[i].origin,spot) < 60*60)
		{
			return false;
		}
	}
	return true;	
	
}
/*
zipline_debug_thread(veh)
{
	self endon("end_zipline_debug");
	
	while(1)
	{
		pos = self.origin + (0,0,128);
		
		pos += AnglesToForward(self.angles) * 1440;
		pos -= AnglesToRight(self.angles) * 480;
		
		(pos, "O (" + self GetEntityNumber() + ") : " + self.origin, (0.2, 0.2, 0.8), 1, 3, 1);
		Print3Dpos += (0,0,-32);
		Print3D(pos, "A (" + self GetEntityNumber() + ") : " + self.angles, (0.2, 0.2, 0.8), 1, 3, 1);
		pos += (0,0,-32);
		Print3D(pos, "O (" + veh GetEntityNumber() + ") : " + veh.origin, (0.2, 0.8, 0.8), 1, 3, 1);
		pos += (0,0,-32);
		Print3D(pos, "A (" + veh GetEntityNumber() + ") : " + veh.angles, (0.2, 0.8, 0.8), 1, 3, 1);

		wait(0.05);
	}
}
*/

/*------------------------------------
do anything here to the player that needs to happen just before he starts ziplining
------------------------------------*/
player_enter_zipline(vehicle,path_start)
{
	self thread zombie_zipline_intersect_monitor();
	
	self setloweredweapon(1);
	//self DisableWeaponFire();
	
	if(isDefined(self.perk_purchased))
	{
		self thread monitor_perk_on_zipline();
	}
	
	self playerlinktodelta(vehicle,"tag_origin",.5,180,180,180,180);
	
	self.zipline_vehicle = vehicle;
	
	// wait until dtp is done
	while(is_true(self.divetoprone)  )
	{
		wait(.05);
	}	
	//starts the rumble/quake effect
	self setclientflag(level._CF_PLAYER_ZIPLINE_RUMBLE_QUAKE);
	
	//set up the fake player
	self setclientflag(level._CF_PLAYER_ZIPLINE_FAKE_PLAYER_SETUP);
	self allowsprint(false);

			
	if(!isDefined(self.perk_purchased))
	{
		self allowmelee(false);	
		self DisableWeapons();
		//self DisableWeaponFire();
		//self DisableWeaponReload();	
		self increment_is_drinking();
		self setstance("stand");
		self allowcrouch(false);	
		self allowprone(false);
		self allowads(false);

	}
	//self DisableWeaponCycling();

	self Hide();
	
	//wait a frame
	wait_network_frame();	
}

monitor_perk_on_zipline()
{
	self endon("disconnect");
	//self setloweredweapon(1);
		
	while(isDefined(self.perk_purchased))
	{
		wait(.05);
	}	

	//self setviewmodel("viewmodel_hands_no_model");
	
	//self DisableWeaponReload();
	self allowmelee(false);	
		
	self increment_is_drinking();
	self setstance("stand");
	self allowcrouch(false);	
	self allowprone(false);
	self allowads(false);
	self allowsprint(false);
	//wait(.5);

	//self setviewmodel("viewmodel_hands_no_model");
	self DisableWeapons();
}


zombie_zipline_intersect_monitor()
{
	self endon("exit_zipline");
	self endon("disconnect");
	
	while(1)
	{
		ai = getaiarray();
		count = 0;
		for(i=0;i<ai.size;i++)
		{
			
			if( !is_true(ai[i].is_ziplining) )
			{
				continue;
			}
			count++;
			if( is_true( ai[i].animname == "director_zombie"))
			{
				if(distancesquared(self.origin,ai[i].origin) < (100*100))
				{
					if(isDefined(self.zipline_vehicle))
					{
						speed = self.zipline_vehicle getspeedmph();
						if(speed - 5 > 0)
						{
							self.zipline_vehicle setspeed(speed - 5,10000,10000);
							self.zipline_vehicle.speed_reduced = true;
						}
					}
				}				
				else
				{
					if(isDefined(self.zipline_vehicle) && isDefined(self.zipline_vehicle.speed_reduced))
					{
						self.zipline_vehicle ResumeSpeed(10000);
						self.zipline_vehicle.speed_reduced = undefined;
					}
				}
				continue;
				
			}
			if( distancesquared(self.origin,ai[i].origin) < (18*18))
			{
				ai[i] dodamage(ai[i].health + 100,ai[i].origin);
				//add this zombie back into the spawner queue
				level.zombie_total++;
			}
		}
		if(count < 1)
		{
			if(isDefined(self.zipline_vehicle) && isDefined(self.zipline_vehicle.speed_reduced))
			{
				self.zipline_vehicle ResumeSpeed(1000);
				self.zipline_vehicle.speed_reduced = undefined;
			}
		}
		wait(.05);
	}
}

/*------------------------------------
grab an available zipline vehicle for the player
------------------------------------*/
get_zipline_vehicle(vehicles)
{
	for(i=0;i<vehicles.size;i++)
	{
		if(!isDefined(vehicles[i].in_use))
		{
			vehicles[i].in_use = true;
			return vehicles[i];
		}
	}
	return undefined;
}

/*------------------------------------
this gets the last node of the zipline vehicle spline
------------------------------------*/
get_zipline_end_node(start_path)
{
	
	start_node = getvehiclenode(start_path,"targetname");
	
	while(1)
	{
		if(isDefined(start_node.target))
		{
			next_node = getvehiclenode(start_node.target,"targetname");
			if(isDefined(next_node))
			{
				start_node = next_node;
			}
		}
		else
		{
			return start_node;
		}
	}
}



flag_wait_any_array( flag_array )
{
                
  flag_activated = false;
  
  while(!flag_activated)
  {
                  
    for(i=0; i<flag_array.size; i++)
    {
      if( flag( flag_array[i] ) )
      {
        flag_activated = true;
      }
    }
    wait(.1);             
  }                
}


jump_button_monitor()
{
	
	level endon("intermission");
	self endon("disconnect");
	
	while(1)
	{
		if( self jumpbuttonpressed() )
		{
			self.jumptime = gettime();
		}
		wait(.1);
	}	
}



move_delete_zipline_gate( )
{

	//chrisp - prevent playerse from getting stuck on the stuff
	self notsolid();
	org = self.origin + (0,0,250);
	self play_sound_on_ent( "debris_move" );
	playsoundatposition ("zmb_lightning_l", self.origin);

	num = RandomIntRange( 3, 5 );
	og_angles = self.angles;
	for( i = 0; i < num; i++ )
	{
		angles = og_angles + ( -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ), -5 + RandomFloat( 10 ) );
		time = RandomFloatRange( 0.1, 0.4 );
		self Rotateto( angles, time );
		wait( time - 0.05 );
	}


	time = 1;

	self MoveTo( org, time, time * 0.5 );
	self RotateTo( self.angles + (randomintrange(-20,20),randomintrange(-20,20),randomintrange(-20,20)), time * 0.75 );

	self waittill( "movedone" );

	playsoundatposition("zmb_zombie_spawn", self.origin); //just playing the zombie_spawn sound when it deletes the blocker because it matches the particle.
	playfx(level._effect["large_ceiling_dust"],self.origin);
	self Delete();

}