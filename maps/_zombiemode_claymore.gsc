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
					play_sound_at_pos( "purchase", self.origin );

					//set the score
					who maps\_zombiemode_score::minus_to_player_score( self.zombie_cost );
					who maps\_zombiemode_weapons::check_collector_achievement( "claymore_zm" );
					who thread claymore_setup();
					who thread show_claymore_hint("claymore_purchased");
					who thread maps\_zombiemode_audio::create_and_play_dialog( "weapon_pickup", "grenade" );

					// JMA - display the claymores
					if( self.claymores_triggered == false )
					{
						model = getent( self.target, "targetname" );
						model thread maps\_zombiemode_weapons::weapon_show( who );
						self.claymores_triggered = true;
					}

					trigs = getentarray("claymore_purchase","targetname");
					for(i = 0; i < trigs.size; i++)
					{
						trigs[i] SetInvisibleToPlayer(who);
					}
				}
				else
				{
					who thread show_claymore_hint("already_purchased");
				}
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
			claymore thread satchel_damage();
			claymore thread claymore_detonation();
			claymore thread play_claymore_effects();

			self notify( "zmb_enable_claymore_prompt" );
		}
	}
}

claymore_setup()
{
	self thread claymore_watch();

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

		player giveweapon("claymore_zm");
		player set_player_placeable_mine("claymore_zm");
		player setactionslot(4,"weapon","claymore_zm");
		player setweaponammoclip("claymore_zm",0);
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

	self thread delete_claymores_on_death( damagearea );

	if(!isdefined(self.owner.mines))
		self.owner.mines = [];
	self.owner.mines = array_add( self.owner.mines, self );

	if( self.owner.mines.size > 20 )
	{
		self.owner.mines[0] detonate( self.owner );
		self.owner.mines = array_remove_nokeys( self.owner.mines, self.owner.mines[0] );
	}

	while(1)
	{
		damagearea waittill( "trigger", ent );

		if ( isdefined( self.owner ) && ent == self.owner )
			continue;

		if( isDefined( ent.pers ) && isDefined( ent.pers["team"] ) && ent.pers["team"] != playerTeamToAllow )
			continue;

		if ( !ent shouldAffectWeaponObject( self ) )
			continue;

		if ( ent damageConeTrace(self.origin, self) > 0 )
		{
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
	// stupid getarraykeys in array_remove reversing the order - nate
	//level.claymores = array_remove_nokeys( level.claymores, self );
	if(is_in_array(self.owner.mines,self))
	{
		self.owner.mines = array_remove_nokeys(self.owner.mines,self);
	}
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
					players[i]  giveweapon("claymore_zm");
					players[i]  set_player_placeable_mine("claymore_zm");
					players[i]  setactionslot(4,"weapon","claymore_zm");
					players[i]  setweaponammoclip("claymore_zm",2);
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
	wait(3.5);
	self.hintelem settext("");
}
