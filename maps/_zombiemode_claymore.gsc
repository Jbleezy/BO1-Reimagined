#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;


/*------------------------------------
CLAYMORE STUFFS -
a rough prototype for now, needs a bit more polish

------------------------------------*/
init()
{
	trigs = getentarray("claymore_purchase","targetname");
	for(i=0; i<trigs.size; i++)
	{
		model = getent( trigs[i].target, "targetname" );
		model hide();
	}

	array_thread(trigs,::buy_claymores);
	level thread give_claymores_after_rounds();

	level.pickup_claymores = ::pickup_claymores;
	level.pickup_claymores_trigger_listener = ::pickup_claymores_trigger_listener;

	level.claymore_detectionDot = cos( 70 );
	level.claymore_detectionMinDist = 20;

	level thread update_claymore_fires();
}

buy_claymores()
{
	self.zombie_cost = 1000;
	self UseTriggerRequireLookAt();
	self sethintstring( &"ZOMBIE_CLAYMORE_PURCHASE" );
	self setCursorHint( "HINT_NOICON" );

	//level thread set_claymore_visible();
	self.placeable_mine_name = "claymore_zm";
	self thread maps\_zombiemode_weapons::decide_hide_show_hint();
	self.claymores_triggered = false;

	while(1)
	{
		self waittill("trigger",who);
		if( who in_revive_trigger() )
		{
			continue;
		}

		if( who has_powerup_weapon() )
		{
			wait( 0.1 );
			continue;
		}

		if( is_player_valid( who ) )
		{

			if( who.score >= self.zombie_cost )
			{
				if ( !who is_player_placeable_mine( "claymore_zm" ) )
				{
					who maps\_zombiemode_weapons::check_collector_achievement( "claymore_zm" );
					who thread show_claymore_hint("claymore_purchased");
					who thread maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", "grenade" );

					who thread claymore_watch();

					/*trigs = getentarray("claymore_purchase","targetname");
					for(i = 0; i < trigs.size; i++)
					{
						trigs[i] SetInvisibleToPlayer(who);
					}*/
				}
				/*else
				{
					who thread show_claymore_hint("already_purchased");
				}*/

				play_sound_at_pos( "purchase", self.origin );

				//set the score
				who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
				who thread claymore_setup();
				who notify( "zmb_disable_claymore_prompt" );

				// JMA - display the claymores
				if( self.claymores_triggered == false )
				{
					model = getent( self.target, "targetname" );
					model thread maps\_zombiemode_weapons::weapon_show( who );
					self.claymores_triggered = true;
				}
			}
			else
			{
				who maps\_zombiemode_audio::create_and_play_dialog( "general", "no_money", undefined, 1 );
			}
		}
	}
}

set_claymore_visible()
{
	players = getplayers();
	trigs = getentarray("claymore_purchase","targetname");

	while(1)
	{
		for(j = 0; j < players.size; j++)
		{
			if( !players[j] is_player_placeable_mine( "claymore_zm" ) )
			{
				for(i = 0; i < trigs.size; i++)
				{
					trigs[i] SetInvisibleToPlayer(players[j], false);
				}
			}
		}

		wait(1);
		players = getplayers();
	}
}

claymore_watch()
{
	self endon("death");

	while(1)
	{
		self waittill("grenade_fire",claymore,weapname);
		if(weapname == "claymore_zm")
		{
			claymore.owner = self;
			//claymore thread satchel_damage();
			claymore thread claymore_detonation();
			claymore thread play_claymore_effects();

			if(level.gamemode != "survival")
			{
				claymore thread claymore_damage();
			}

			self notify( "zmb_enable_claymore_prompt" );
		}
	}
}

claymore_setup()
{
	self giveweapon("claymore_zm");
	self set_player_placeable_mine("claymore_zm");
	self setactionslot(4,"weapon","claymore_zm");
	self setweaponammostock("claymore_zm",2);
}

pickup_claymores()
{
	player = self.owner;

	if ( !player hasweapon( "claymore_zm" ) )
	{
		player thread claymore_watch();
		player thread claymore_setup();
		
		player notify( "zmb_enable_claymore_prompt" );
	}
	else
	{
		clip_ammo = player GetWeaponAmmoClip( self.name );
		clip_max_ammo = WeaponClipSize( self.name );
		if ( clip_ammo >= clip_max_ammo )
		{
			player notify( "zmb_disable_claymore_prompt" ); // just to be safe
			return;
		}
	}

	self maps\_weaponobjects::pick_up();

	clip_ammo = player GetWeaponAmmoClip( self.name );
	clip_max_ammo = WeaponClipSize( self.name );
	if ( clip_ammo >= clip_max_ammo )
	{
		player notify( "zmb_disable_claymore_prompt" );
	}
}

pickup_claymores_trigger_listener( trigger, player )
{
	self thread pickup_claymores_trigger_listener_enable( trigger, player );
	self thread pickup_claymores_trigger_listener_disable( trigger, player );
}

pickup_claymores_trigger_listener_enable( trigger, player )
{
	self endon( "delete" );

	while ( true )
	{
		player waittill_any( "zmb_enable_claymore_prompt", "spawned_player" );

		if ( !isDefined( trigger ) )
		{
			return;
		}

		trigger trigger_on();
		trigger linkto( self );
	}
}

pickup_claymores_trigger_listener_disable( trigger, player )
{
	self endon( "delete" );

	while ( true )
	{
		player waittill( "zmb_disable_claymore_prompt" );

		if ( !isDefined( trigger ) )
		{
			return;
		}

		trigger unlink();
		trigger trigger_off();
	}
}

/*
waittill_not_moving()
{
	prevorigin = self.origin;
	while(1)
	{
		wait .1;
		if ( self.origin == prevorigin )
			break;
		prevorigin = self.origin;
	}
}
*/

shouldAffectWeaponObject( object )
{
	pos = self.origin + (0,0,32);

	dirToPos = pos - object.origin;
	objectForward = anglesToForward( object.angles );

	dist = vectorDot( dirToPos, objectForward );
	if ( dist < level.claymore_detectionMinDist )
		return false;

	dirToPos = vectornormalize( dirToPos );

	dot = vectorDot( dirToPos, objectForward );
	return ( dot > level.claymore_detectionDot );
}

claymore_detonation()
{
	self endon("death");

	// wait until we settle
	self waittill_not_moving();

	detonateRadius = 96;

	spawnFlag = 1;// SF_TOUCH_AI_AXIS
	playerTeamToAllow = "axis";
	if( isDefined( self.owner ) && isDefined( self.owner.pers["team"] ) && self.owner.pers["team"] == "axis" )
	{
		spawnFlag = 2;// SF_TOUCH_AI_ALLIES
		playerTeamToAllow = "allies";
	}

	damagearea = spawn("trigger_radius", self.origin + (0,0,0-detonateRadius), spawnFlag, detonateRadius, detonateRadius*2);

	damagearea enablelinkto();
	damagearea linkto( self );

	self.trigger = damagearea;

	self thread delete_claymores_on_death( damagearea );

	if(!isdefined(self.owner.mines))
		self.owner.mines = [];
	self.owner.mines = array_add( self.owner.mines, self );

	amount = level.max_mines;

	if( self.owner.mines.size > amount )
	{
		self detonate( self.owner );
	}

	while(1)
	{
		damagearea waittill( "trigger", ent );

		if ( isdefined( self.owner ) && ent == self.owner )
			continue;

		if( level.gamemode == "survival" && isDefined( ent.pers ) && isDefined( ent.pers["team"] ) && ent.pers["team"] != playerTeamToAllow )
			continue;
			
		if( level.gamemode != "survival" && IsPlayer(ent) && ent.vsteam == self.owner.vsteam )
			continue;

		if ( !ent shouldAffectWeaponObject( self ) )
			continue;

		if ( ent damageConeTrace(self.origin, self) > 0 )
		{
			wait_to_fire_claymore();

			self notify("pickUpTrigger_death");
			self playsound ("claymore_activated_SP");
			wait 0.4;
			if ( isdefined( self.owner ) )
				self detonate( self.owner );
			else
				self detonate( undefined );

			return;
		}
	}
}

delete_claymores_on_death(ent)
{
	self waittill("death");
	
	self.owner.mines = array_removeUndefined(self.owner.mines);

	if(isDefined(self.tag_origin))
	{
		self.tag_origin Delete();
	}
	// stupid getarraykeys in array_remove reversing the order - nate
	//level.claymores = array_remove_nokeys( level.claymores, self );
	wait .05;
	if ( isdefined( ent ) )
		ent delete();
}

satchel_damage()
{
//	self endon( "death" );

	self setcandamage(true);
	self.health = 100000;

	attacker = undefined;

	playerTeamToAllow = "axis";
	if( isDefined( self.owner ) && isDefined( self.owner.pers["team"] ) && self.owner.pers["team"] == "axis" )
	{
		playerTeamToAllow = "allies";
	}

	while(1)
	{
		self waittill("damage", amount, attacker);

		if ( !isdefined( self ) )	// something else killed it
		{
			return;
		}

		self.health = self.maxhealth;
		if ( !isplayer(attacker) )
			continue;

		if ( isdefined( self.owner ) && attacker == self.owner )
			continue;

		if( isDefined( attacker.pers ) && isDefined( attacker.pers["team"] ) && attacker.pers["team"] != playerTeamToAllow )
			continue;

		break;
	}

	if ( level.satchelexplodethisframe )
		wait .1 + randomfloat(.4);
	else
		wait .05;

	if (!isdefined(self))
		return;

	level.satchelexplodethisframe = true;

	thread reset_satchel_explode_this_frame();

	self detonate( attacker );
	// won't get here; got death notify.
}

reset_satchel_explode_this_frame()
{
	wait .05;
	level.satchelexplodethisframe = false;
}

play_claymore_effects()
{
	self endon("death");

	self waittill_not_moving();

	PlayFXOnTag( level._effect[ "claymore_laser" ], self, "tag_fx" );
}

give_claymores_after_rounds()
{
	while(1)
	{
		level waittill( "between_round_over" );

		if ( !level flag_exists( "teleporter_used" ) || !flag( "teleporter_used" ) )
		{
			players = get_players();
			for(i=0;i<players.size;i++)
			{
				if ( players[i] is_player_placeable_mine( "claymore_zm" ) )
				{
					players[i] giveweapon("claymore_zm");
					players[i] set_player_placeable_mine("claymore_zm");
					players[i] setactionslot(4,"weapon","claymore_zm");
					players[i] setweaponammoclip("claymore_zm",2);
					players[i] notify( "zmb_disable_claymore_prompt" );
				}
			}
		}
	}
}

init_hint_hudelem(x, y, alignX, alignY, fontscale, alpha)
{
	self.x = x;
	self.y = y;
	self.alignX = alignX;
	self.alignY = alignY;
	self.fontScale = fontScale;
	self.alpha = alpha;
	self.sort = 20;
	//self.font = "objective";
}

setup_client_hintelem()
{
	self endon("death");
	self endon("disconnect");

	if(!isDefined(self.hintelem))
	{
		self.hintelem = newclienthudelem(self);
	}
	self.hintelem init_hint_hudelem(320, 220, "center", "bottom", 1.6, 1.0);
}


show_claymore_hint(string)
{
	self endon("death");
	self endon("disconnect");

	if(string == "claymore_purchased")
		text = &"ZOMBIE_CLAYMORE_HOWTO";
	else
		text = &"ZOMBIE_CLAYMORE_ALREADY_PURCHASED";

	self setup_client_hintelem();
	self.hintelem setText(text);
	self.hintelem.font = "small";
	self.hintelem.fontscale = 1.25;
	wait(3.5);
	self.hintelem settext("");
}

claymore_damage()
{
	self endon( "death" );

	tag_origin = spawn("script_model",self.origin);
	tag_origin.angles = self.angles;
	tag_origin setmodel(self.model);
	tag_origin linkto(self);
	self.tag_origin = tag_origin;

	tag_origin setcandamage(true);
	tag_origin.health = 100000;

	while(1)
	{
		tag_origin waittill("damage", amount, attacker);
		if(attacker.vsteam != self.owner.vsteam)
		{
			PlayFX(level._effect["equipment_damage"], self.origin);

			if(IsDefined(self.trigger))
			{
				self.trigger delete();
			}
			tag_origin Delete();
			self delete();
		}
	}
}

update_claymore_fires()
{
	while(true)
	{
		level.hasClaymoreFiredRecently = 0;
		wait_network_frame();
	}
}

wait_to_fire_claymore()
{
	while(level.hasClaymoreFiredRecently >= 4)
	{
		wait_network_frame();
	}

	level.hasClaymoreFiredRecently++;
}