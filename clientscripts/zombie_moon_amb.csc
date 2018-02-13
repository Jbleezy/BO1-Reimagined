//
// file: template_amb.csc
// description: clientside ambient script for template: setup ambient sounds, etc.
// scripter: 		(initial clientside work - laufer)
//

#include clientscripts\_utility;
#include clientscripts\_ambientpackage;
#include clientscripts\_music;
#include clientscripts\_busing;
#include clientscripts\_audio;

main()
{
		level._audio_zombie_gasmask_func = ::enable_gasmask_audio;

		level.audio_zones_breached 			= [];
		level.audio_zones_breached["1"] 	= false;
		level.audio_zones_breached["2a"] 	= false;
		level.audio_zones_breached["2b"] 	= false;
		level.audio_zones_breached["3a"] 	= false;
		level.audio_zones_breached["3b"] 	= false;
		level.audio_zones_breached["3c"] 	= false;
		level.audio_zones_breached["4a"] 	= false;
		level.audio_zones_breached["4b"] 	= false;
		level.audio_zones_breached["5"] 	= false;
		level.audio_zones_breached["6"] 	= false;

		//MOON
		declareAmbientRoom( "space" );
		declareAmbientPackage( "space" );
			setAmbientRoomTone( "space", "amb_wind_outside", .60, 1);
			setAmbientRoomReverb( "space", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "space", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "space", "zmb_moon_airless" );

		declareAmbientRoom( "airlock" );
		declareAmbientPackage( "airlock" );
			setAmbientRoomTone( "airlock", "", .60, 1);
			setAmbientRoomReverb( "airlock", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "airlock", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "airlock", "zmb_moon_airless" );

		//ZONE 1: Moon Starting Area, windows can be blown out, causing air loss
		declareAmbientRoom( "ZONE1_moon_room_large" );
		declareAmbientPackage( "ZONE1_moon_room_large" );
			setAmbientRoomTone( "ZONE1_moon_room_large", "", .60, 1);
			setAmbientRoomReverb( "ZONE1_moon_room_large", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE1_moon_room_large", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE1_moon_room_large", "zmb_moon_airless" );

		//ZONE 2: LEFT cave system.  Caused by digger. 2a is only airless if door has been opened
		declareAmbientRoom( "ZONE2a_moon_caves" );
		declareAmbientPackage( "ZONE2a_moon_caves" );
			setAmbientRoomTone( "ZONE2a_moon_caves", "", .60, 1);
			setAmbientRoomReverb( "ZONE2a_moon_caves", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE2a_moon_caves", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE2a_moon_caves", "zmb_moon_airless" );

		declareAmbientRoom( "ZONE2b_moon_caves" );
		declareAmbientPackage( "ZONE2b_moon_caves" );
			setAmbientRoomTone( "ZONE2b_moon_caves", "", .60, 1);
			setAmbientRoomReverb( "ZONE2b_moon_caves", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE2b_moon_caves", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE2b_moon_caves", "zmb_moon_airless" );

		//ZONE 3: RIGHT cave system.  Caused by digger. 3a is only airless if door has been opened
		declareAmbientRoom( "ZONE3a_moon_caves" );
		declareAmbientPackage( "ZONE3a_moon_caves" );
			setAmbientRoomTone( "ZONE3a_moon_caves", "", .60, 1);
			setAmbientRoomReverb( "ZONE3a_moon_caves", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE3a_moon_caves", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE3a_moon_caves", "zmb_moon_airless" );

		declareAmbientRoom( "ZONE3b_moon_room_medium" );
		declareAmbientPackage( "ZONE3b_moon_room_medium" );
			setAmbientRoomTone( "ZONE3b_moon_room_medium", "", .60, 1);
			setAmbientRoomReverb( "ZONE3b_moon_room_medium", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE3b_moon_room_medium", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE3b_moon_room_medium", "zmb_moon_airless" );

		declareAmbientRoom( "ZONE3c_moon_caves" );
		declareAmbientPackage( "ZONE3c_moon_caves" );
			setAmbientRoomTone( "ZONE3c_moon_caves", "", .60, 1);
			setAmbientRoomReverb( "ZONE3c_moon_caves", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE3c_moon_caves", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE3c_moon_caves", "zmb_moon_airless" );

		//ZONE 4: Rooms Pre-Atrium, windows can be blown out, causing air loss
		declareAmbientRoom( "ZONE4a_moon_room_medium" );
		declareAmbientPackage( "ZONE4a_moon_room_medium" );
			setAmbientRoomTone( "ZONE4a_moon_room_medium", "", .60, 1);
			setAmbientRoomReverb( "ZONE4a_moon_room_medium", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE4a_moon_room_medium", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE4a_moon_room_medium", "zmb_moon_airless" );

		declareAmbientRoom( "ZONE4a_moon_hallway" );
		declareAmbientPackage( "ZONE4a_moon_hallway" );
			setAmbientRoomTone( "ZONE4a_moon_hallway", "", .60, 1);
			setAmbientRoomReverb( "ZONE4a_moon_hallway", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE4a_moon_hallway", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE4a_moon_hallway", "zmb_moon_airless" );

		declareAmbientRoom( "ZONE4b_moon_room_medium" );
		declareAmbientPackage( "ZONE4b_moon_room_medium" );
			setAmbientRoomTone( "ZONE4b_moon_room_medium", "", .60, 1);
			setAmbientRoomReverb( "ZONE4b_moon_room_medium", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE4b_moon_room_medium", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE4b_moon_room_medium", "zmb_moon_airless" );

		//ZONE 5: Atrium and it's airlocks.  Caused by a digger
		declareAmbientRoom( "ZONE5_atrium" );
		declareAmbientPackage( "ZONE5_atrium" );
			setAmbientRoomTone( "ZONE5_atrium", "", .60, 1);
			setAmbientRoomReverb( "ZONE5_atrium", "rv_zmbtemple_cave_tunnels", 1, 1 );
			setAmbientRoomContext( "ZONE5_atrium", "ringoff_plr", "outdoor" );
			setAmbientRoomSnapshot( "ZONE5_atrium", "zmb_moon_airless" );

		//EARTH
		declareAmbientRoom( "earth_outdoors" );
		declareAmbientPackage( "earth_outdoors" );
			setAmbientRoomTone( "earth_outdoors", "amb_earth_bg", .60, 1);
			setAmbientRoomReverb( "earth_outdoors", "rv_mparea51_outdoor", 1, 1 );
			setAmbientRoomContext( "earth_outdoors", "ringoff_plr", "outdoor" );

		declareAmbientRoom( "earth_hangar" );
		declareAmbientPackage( "earth_hangar" );
			setAmbientRoomTone( "earth_hangar", "amb_earth_bg", .60, 1);
			setAmbientRoomReverb( "earth_hangar", "rv_mparea51_partial_room_metal", 1, 1 );
			setAmbientRoomContext( "earth_hangar", "ringoff_plr", "outdoor" );

  	activateAmbientRoom( 0, "space", 0 );
	activateAmbientPackage( 0, "space", 0 );

//------------------------------------------------

  //MUSIC STATES
	declareMusicState("WAVE");
		musicAliasloop("mus_moon_underscore", 4, 2);

	declareMusicState("EGG");
		musicAlias("mus_egg", 1);

	declareMusicState( "SILENCE" );
	    musicAlias("null", 1 );

	declareMusicState("EGG_A7X");
		musicAlias("mus_egg_a7x", 1);

	declareMusicState("SAM");
		musicAlias("mus_samantha_reveal", 1);

	level thread setup_airless_ambient_packages();
	level thread teleporter_audio_sfx();
	level thread beam_fx_audio();
	level thread zone_alarms_setup();
	level thread waitfor_gasmask_buy();
	level thread waitfor_gasmask_on();
	level thread ambience_randoms();
	level thread snd_start_autofx_audio();
}

snd_start_autofx_audio()
{
	snd_play_auto_fx( "fx_moon_floodlight_wide", "amb_lights" );
	snd_play_auto_fx( "fx_moon_floodlight_narrow", "amb_lights" );
}

ambience_randoms()
{
	level waittill( "power_on" );

	array_thread( getstructarray( "amb_random_beeps", "targetname" ), ::play_random_beeps );
}

play_random_beeps()
{
	while(1)
	{
		playsound( 0, "amb_random_beeps", self.origin );
		wait(randomintrange( 10, 30 ));
	}
}

waitfor_gasmask_on()
{
	while(1)
	{
		level waittill( "gmsk2" );
		playsound( 0, "evt_gasmask_on", (0,0,0) );
	}
}

waitfor_gasmask_buy()
{
	level waittill( "gmsk" );
	playsound( 0, "evt_gasmask_suit_on", (0,0,0) );
}

zone_alarms_setup()
{
	wait(5);
	array1 = getstructarray( "zone_alarm", "targetname" );
	array2 = getstructarray( "zone_shakes", "targetname" );

	if( !isdefined( array1 ) || !isdefined( array2 ) )
		return;

	array_thread( array1, ::play_zone_alarms );
	array_thread( array2, ::play_zone_shakes );
}

play_zone_alarms()
{
	level endon( "Dz" + self.script_noteworthy + "e" );

	self thread reset_alarms();

	level waittill( "Dz" + self.script_noteworthy );

	while(1)
	{
		playsound( 0, "evt_zone_alarm", self.origin );
		realwait(2.8);
	}
}

play_zone_shakes()
{
	level endon( "Dz" + self.script_noteworthy + "e" );

	self thread reset_shakes();

	level waittill( "Dz" + self.script_noteworthy );

	while(1)
	{
		playsound( 0, "evt_digger_rattles_random", self.origin );
		realwait(randomfloatrange(1.2,2.3));
	}
}

reset_alarms()
{
	level waittill( "Dz" + self.script_noteworthy + "e" );
	wait(2);
	self thread play_zone_alarms();
}

reset_shakes()
{
	level waittill( "Dz" + self.script_noteworthy + "e" );
	wait(2);
	self thread play_zone_shakes();
}

beam_fx_audio()
{
	while(1)
	{
		level waittill( "bmfx" );
		playsound( 0, "evt_teleporter_beam_sfx", (0,0,0) );

		//DCS: clientsiding these fx as well.
		clientscripts\_fx::activate_exploder(122);
		clientscripts\_fx::activate_exploder(132);

	}
}

teleporter_audio_sfx()
{
	click_array = getstructarray( "teleporter_click_sfx", "targetname" );
	warmup_array = getstructarray( "teleporter_warmup_sfx", "targetname" );

	while(1)
	{
		level waittill( "tafx" );
		array_thread( click_array, ::play_teleporter_sounds );
		array_thread( warmup_array, ::play_warmup_cooldown );

		//DCS: clientsiding these fx as well.
		clientscripts\_fx::activate_exploder(121);
		clientscripts\_fx::activate_exploder(131);
	}
}

play_teleporter_sounds()
{
	level endon( "cafx" );

	wait(.5);

	if( isdefined( self.script_int ) && isdefined( self.script_noteworthy ) )
	{
		val = int(self.script_noteworthy)/2;
		realwait(val);
		playsound( 0, "evt_teleporter_click_" + self.script_noteworthy, self.origin );
	}
}

play_warmup_cooldown()
{
	level endon( "cafx" );

	realwait(.5);
	playsound( 0, "evt_teleporter_warmup", self.origin );
	realwait(2);
	playsound( 0, "evt_teleporter_cooldown", self.origin );
}

setup_zone_1_special()
{
	level waittill( "power_on" );
	level reset_ambient_packages( "1", true );
	level reset_ambient_packages( "2a", true );
	level reset_ambient_packages( "2b", true );
	level reset_ambient_packages( "3a", true );
	level reset_ambient_packages( "3b", true );
	level reset_ambient_packages( "3c", true );
	level reset_ambient_packages( "4a", true );
	level reset_ambient_packages( "4b", true );
	level reset_ambient_packages( "5", true );
	level reset_ambient_packages( "6", true );
}

setup_airless_ambient_packages()
{
	//wait(5);
	waitforclient(0);

	trigs = GetEntArray( 0, "ambient_package","targetname");
	for(i=0;i<trigs.size;i++)
	{
		if( isdefined( trigs[i].script_ambientroom ) )
		{
			trigs[i] remember_old_verb( trigs[i].script_ambientroom );
		}

		trigs[i].first_time = true;
	}

	level thread setup_zone_1_special();

	level thread waitfor_notify( "1" );
	level thread waitfor_notify( "2a" );
	level thread waitfor_notify( "2b" );
	level thread waitfor_notify( "3a" );
	level thread waitfor_notify( "3b" );
	level thread waitfor_notify( "3c" );
	level thread waitfor_notify( "4a" );
	level thread waitfor_notify( "4b" );
	level thread waitfor_notify( "5" );
}

waitfor_notify( zone, array )
{
	level waittill( "Az" + zone );

	level reset_ambient_packages( zone );
}

reset_ambient_packages( zone, poweron )
{
	if( !isdefined( poweron ) )
	{
		poweron = false;
	}

	if( isdefined( zone ) )
	{
		trigs = GetEntArray( 0, "ambient_package","targetname");
		zone_array = [];
		z = 0;

		for(i=0;i<trigs.size;i++)
		{
			if( isdefined( trigs[i].script_noteworthy ) && isdefined( trigs[i].script_ambientroom ) )
			{
				if( trigs[i].script_noteworthy == zone )
				{
					if( poweron && !level.audio_zones_breached[zone] )
					{
						if( isdefined( trigs[i].script_string ) )
						{
							setAmbientRoomTone( trigs[i].script_ambientroom, trigs[i].script_string, .25, .25);
						}

						setAmbientRoomSnapshot( trigs[i].script_ambientroom, "" );
						zone_array[z] = trigs[i];
						z++;
					}
					else
					{
						setAmbientRoomTone( trigs[i].script_ambientroom, "", .25, .25);
						setAmbientRoomSnapshot( trigs[i].script_ambientroom, "zmb_moon_airless");
						zone_array[z] = trigs[i];
						z++;
					}
				}
			}
		}

		players = getlocalplayers();
		for(i=0;i<players.size;i++)
		{
			for(a=0;a<zone_array.size;a++)
			{
				if( players[i] istouching( zone_array[a] ) )
				{
					level.activeAmbientRoom = "";
					level.activeAmbientPackage = "";
					level notify( "updateActiveAmbientRoom" );
					level notify( "updateActiveAmbientPackage" );

					if( !level.audio_zones_breached[zone] )
					{
						if( poweron )
						{
							players[i] playsound( 0, "evt_air_repressurize" );
						}
						else if( !zone_array[a].first_time )
						{
							if( zone == "5" )
							{
								players[i] playsound( 0, "evt_dig_wheel_breakthrough_bio" );
							}
							else if( ( ( zone == "2a" || zone == "2b" ) && !level.audio_zones_breached["2b"] ) || ( ( zone == "3a" || zone == "3b" || zone == "3c" ) && !level.audio_zones_breached["3b"] ) )
							{
								players[i] playsound( 0, "evt_dig_wheel_breakthrough" );
							}

							players[i] playsound( 0, "evt_air_release" );
						}
					}
				}

				zone_array[a].first_time = false;
			}
		}

		if( !poweron )
		{
			level.audio_zones_breached[zone] = true;
		}
	}
}

enable_gasmask_audio( on )
{
	if( on )
	{
		trigs = GetEntArray( 0, "ambient_package","targetname");

		for(i=0;i<trigs.size;i++)
		{
			if( isdefined( trigs[i].script_ambientroom ) )
			{
				setAmbientRoomReverb( trigs[i].script_ambientroom, "rebirth_hazmat", 1, 1 );
				setAmbientRoomContext( trigs[i].script_ambientroom, "ringoff_plr", "indoor" );
			}
		}

		snd_set_snapshot( "zmb_moon_gasmask" );
		level.activeAmbientRoom = "";
		level.activeAmbientPackage = "";
		level notify( "updateActiveAmbientRoom" );
		level notify( "updateActiveAmbientPackage" );
	}
	else
	{
		trigs = GetEntArray( 0, "ambient_package","targetname");

		for(i=0;i<trigs.size;i++)
		{
			if( isdefined( trigs[i].script_ambientroom ) && isdefined( trigs[i].masterReverbRoomType ) )
			{
				setAmbientRoomReverb( trigs[i].script_ambientroom, trigs[i].masterReverbRoomType, 1, 1 );
				setAmbientRoomContext( trigs[i].script_ambientroom, "ringoff_plr", "outdoor" );
			}
		}

		snd_set_snapshot( "default" );
		level.activeAmbientRoom = "";
		level.activeAmbientPackage = "";
		level notify( "updateActiveAmbientRoom" );
		level notify( "updateActiveAmbientPackage" );
	}
}

remember_old_verb( name )
{
	if( !isdefined( self.masterReverbRoomType ) )
	{
		self.masterReverbRoomType = level.ambientRooms[name].reverb.reverbRoomType;
	}
}
