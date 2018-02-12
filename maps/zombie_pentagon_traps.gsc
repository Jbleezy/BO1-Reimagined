#include common_scripts\utility;
#include maps\_utility;
#include maps\_zombiemode_traps;
#include maps\_zombiemode_utility;


init_traps()
{
	level init_flags();

	level electric_trap_battery_init();
	level pentagon_fix_electric_trap_init();

	// ww: getting teh quad intro fx in with the changes to the trap system
	level quad_first_drop_fx_init();
}

init_flags()
{
	flag_init( "trap_elevator" );
	flag_init( "trap_quickrevive" );


}
//-------------------------------------------------------------------------------
// DCS 082410: standarding and making into prefabs batteries for traps.
//-------------------------------------------------------------------------------
electric_trap_battery_init()
{
	trap_batteries = GetEntArray( "trigger_trap_piece", "targetname" );
	players = get_players();
	for ( i = 0; i < players.size; i++ )
	{
		players[i]._trap_piece = 0;
	}

	array_thread( trap_batteries, ::pickup_trap_piece );
}

pickup_trap_piece()
{
	self endon( "_piece_placed" );

	if( !IsDefined( self.target ) )
	{
		// where the model goes isn't hooked up, leave
		return;
	}

	self SetCursorHint( "HINT_NOICON" );
	self trigger_off();

	/*trap_piece = self spawn_trap_piece();

	self SetHintString( &"ZOMBIE_PENTAGON_GRAB_MISSING_PIECE" );
	self SetCursorHint( "HINT_NOICON" );

	// battery = getstruct( self.target, "targetname" );
	self.picked_up = 0;

	// require look at
	self UseTriggerRequireLookAt();

	while( self.picked_up == 0 )
	{
		self waittill( "trigger", user );

		if( is_player_valid( user ) )
		{
			if( IsDefined( user._trap_piece ) && user._trap_piece > 0 ) // you have a piece, go away
			{
				play_sound_at_pos( "no_purchase", self.origin );
				continue;
			}
			else
			{
				self trigger_off();

				if( IsDefined( trap_piece ) )
				{
					//PlayFXOnTag( level._effect["switch_sparks"], trap_piece, "tag_origin" );

					// TODO: NEED A BETTER SOUND HERE, COULD WE GET AN EVIL BARB?
					// SOMETHING LIKE "SO YOU THINK YOU'RE SLICK?!"
					//trap_piece thread play_sound_on_entity( "zmb_battery_pickup" );

					//user thread pentagon_have_battery_hud();
					user thread trap_piece_deliver_clean_up( self );
				}
				//user._trap_piece = 1;
				self.picked_up = 1;

				user thread pentagon_hide_piece_triggers();

				// wait( 1.0 );
				trap_piece Delete();
			}
		}
	}*/
}

// ww: trigger spawns the script model that will be picked up, script model is returned
spawn_trap_piece()
{
	spawn_struct = getstruct( self.target, "targetname" );

	trap_model = Spawn( "script_model", spawn_struct.origin );
	trap_model SetModel( "zombie_sumpf_power_switch" );
	trap_model.angles = spawn_struct.angles;

	return trap_model;
}


// WW: make all other trap piece triggers invisible to players who have a trap piece
pentagon_hide_piece_triggers()
{
	trap_piece_triggers = GetEntArray( "trigger_trap_piece", "targetname" );

	for( i = 0; i < trap_piece_triggers.size; i++ )
	{
		if( trap_piece_triggers[i].picked_up == 0 )
		{
			trap_piece_triggers[i] SetInvisibleToPlayer( self );
		}
	}
}

// WW: Init all the triggers needed for fixing the electric traps. there should be one of these per electric trap
pentagon_fix_electric_trap_init()
{
	fix_trigger_array = GetEntArray( "trigger_battery_trap_fix", "targetname" );

	if( IsDefined( fix_trigger_array ) )
	{
		array_thread( fix_trigger_array, ::pentagon_fix_electric_trap );
	}
}

// WW: Traps wait for a battery to be delivered before becoming active
pentagon_fix_electric_trap()
{
	if( !IsDefined( self.script_flag_wait ) ) // make sure the proper kvp is on the object
	{
		PrintLn( "trap at " + self.origin + " missing script flag" );
		return;
	}

	if( !IsDefined( self.script_string ) )
	{
		PrintLn( "trap at " + self.origin + " missing script string" );
	}

	self SetHintString( &"ZOMBIE_PENTAGON_MISSING_PIECE" );
	self SetCursorHint( "HINT_NOICON" );
	self UseTriggerRequireLookAt();

	trap_trigger = GetEntArray( self.script_flag_wait, "targetname" ); // the script string has the trap trigger targetname
	array_thread( trap_trigger, ::electric_hallway_trap_piece_hide, self.script_flag_wait );

	trap_cover = GetEnt( self.script_string, "targetname" ); // script brush model covering the trap pieces
	level thread pentagon_trap_cover_remove( trap_cover, self.script_flag_wait );

	/*while( !flag( self.script_flag_wait ) ) // this flag will be set internally when the battery is delivered
	{
		self waittill( "trigger", who );

		if( is_player_valid( who ) )
		{
			if( !IsDefined( who._trap_piece ) || who._trap_piece == 0 ) // you don't have it, go away
			{
				play_sound_at_pos( "no_purchase", self.origin );
				// continue;
			}
			else if( IsDefined( who._trap_piece ) && who._trap_piece == 1 ) // you have the battery
			{
				who._trap_piece = 0;

				self PlaySound( "zmb_battery_insert" );

				who thread pentagon_show_piece_triggers();

				flag_set( self.script_flag_wait ); // flag is set on the trigger in the trap

				who notify( "trap_piece_returned" );

				who thread pentagon_remove_battery_hud();
			}
		}
	}*/

	flag_set( self.script_flag_wait );

	// hide the trigger
	self SetHintString( "" );
	self trigger_off();
}

// WW: make all other trap piece triggers visbile to players who have placed a trap piece
pentagon_show_piece_triggers()
{
	trap_piece_triggers = GetEntArray( "trigger_trap_piece", "targetname" );

	for( i = 0; i < trap_piece_triggers.size; i++ )
	{
		if( trap_piece_triggers[i].picked_up == 0 )
		{
			trap_piece_triggers[i] SetVisibleToAll();
		}
	}
}

// ww: removes trigger on successfuly piece placement
trap_piece_deliver_clean_up( ent_trig )
{
	self endon( "death" );
	self endon( "disconnect" );

	self waittill( "trap_piece_returned" );

	ent_trig notify( "_piece_placed" );

	ent_trig Delete();
}

// ww: hides the zctivation trigger for the trap, but goes through multiple script ents
// SELF == SCRIPT MODEL/TRIGGER
electric_hallway_trap_piece_hide( str_flag )
{
	if( !IsDefined( str_flag ) )
	{
		return;
	}

	if( self.classname == "trigger_use" )
	{
		self SetHintString( &"ZOMBIE_NEED_POWER" );
		self thread electric_hallway_trap_piece_show( str_flag );
		self trigger_off();
	}
}

// ww: returns the trigger once the piece has been placed
// SELF == SCRIPT MODEL/TRIGGER
electric_hallway_trap_piece_show( str_flag )
{
	if( !IsDefined( str_flag ) )
	{
		return;
	}

	flag_wait( str_flag );

	self trigger_on();
}

// ww: removes the script brushmodel covers when teh trap has been created
pentagon_trap_cover_remove( ent_cover, str_flag )
{
	flag_wait( str_flag );

	// TODO: COOL FX TO PLAY WHILE MOVING IT?
	ent_cover NotSolid();
	ent_cover.fx = Spawn( "script_model", ent_cover.origin );
	ent_cover.fx SetModel( "tag_origin" );

	ent_cover MoveZ( 48, 1.0, 0.4, 0 );
	ent_cover waittill( "movedone" );

	ent_cover RotateRoll( ( 360 * RandomIntRange( 4, 10 ) ), 1.2, 0.6, 0 );
	PlayFXOnTag( level._effect["poltergeist"], ent_cover.fx, "tag_origin" );
	// TODO: COOL ANGRY VOICE HERE? AS IF THE ETHER IS ANGRY YOU PUT THE TRAP TOGETHER
	ent_cover waittill( "rotatedone" );

	ent_cover Hide();
	ent_cover.fx Hide();
	ent_cover.fx Delete();
	ent_cover Delete();

	// ent_cover Hide();
	// ent_cover Delete();
}

// WW:add the hud element for the battery so a player knows they have the battery
pentagon_have_battery_hud()
{
	self.powercellHud = create_simple_hud( self );

	self.powercellHud.foreground = true;
	self.powercellHud.sort = 2;
	self.powercellHud.hidewheninmenu = false;
	self.powercellHud.alignX = "center";
	self.powercellHud.alignY = "bottom";
	self.powercellHud.horzAlign = "user_right";
	self.powercellHud.vertAlign = "user_bottom";
	self.powercellHud.x = -200; // ww: started at 256
	self.powercellHud.y = 0;

	self.powercellHud.alpha = 1;
	self.powercellHud setshader( "zom_icon_trap_switch_handle", 32, 32 );

	self thread pentagon_remove_hud_on_death();
}

// WW: remove the battery hud element
pentagon_remove_battery_hud()
{
	if( IsDefined( self.powercellHud ) )
	{
		self.powercellHud Destroy();
	}
}

// WW: remove the trap piece hud on player death
pentagon_remove_hud_on_death()
{
	self endon( "trap_piece_returned" );

	self waittill_either( "death", "_zombie_game_over" );

	self thread pentagon_remove_battery_hud()	;
}

//-------------------------------------------------------------------------------
// ww: setups the fx exploder for certain vents the first time a quad comes out
quad_first_drop_fx_init()
{
	vent_drop_triggers = GetEntArray( "trigger_quad_intro", "targetname" );

	// these triggers are one timers, don't thread them or the function dies
	for( i = 0; i < vent_drop_triggers.size; i++ )
	{
		level thread quad_first_drop_fx( vent_drop_triggers[i] );
	}
}

quad_first_drop_fx( ent_trigger )
{
	if( !IsDefined( ent_trigger.script_int ) )
	{
		return;
	}

	exploder_id = ent_trigger.script_int;

	ent_trigger waittill( "trigger" );

	ent_trigger PlaySound( "evt_pentagon_quad_spawn" );

	exploder( exploder_id );
}
