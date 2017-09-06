/* zombie_temple_sq_bttp.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 7.
 *						Back to the past.
 *
 *
 * Author : 	Dan L
 *
 */



#include maps\_utility;
#include common_scripts\utility;
#include maps\_zombiemode_utility;
#include maps\_zombiemode_sidequests;

init()
{

	declare_sidequest_stage("sq", "bttp", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "bttp", 5 * 60);	// 5 minute limit.
//	declare_stage_title("sq", "bttp", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_6_TITLE");
	declare_stage_asset_from_struct("sq", "bttp", "sq_bttp_glyph", undefined, ::bttp_damage_thread);

	PreCacheModel("p_ztem_glyphs_01_unfinished");
	PreCacheModel("p_ztem_glyphs_02_unfinished");
	PreCacheModel("p_ztem_glyphs_03_unfinished");
	PreCacheModel("p_ztem_glyphs_04_unfinished");
	PreCacheModel("p_ztem_glyphs_05_unfinished");
	PreCacheModel("p_ztem_glyphs_06_unfinished");
	PreCacheModel("p_ztem_glyphs_07_unfinished");
	PreCacheModel("p_ztem_glyphs_08_unfinished");
	PreCacheModel("p_ztem_glyphs_09_unfinished");
	PreCacheModel("p_ztem_glyphs_10_unfinished");
	PreCacheModel("p_ztem_glyphs_11_unfinished");
	PreCacheModel("p_ztem_glyphs_12_unfinished");
}

init_stage()
{
	if(IsDefined(level._sq_skel))
	{
		level._sq_skel Hide();
	}
	level._num_done = 0;

	maps\zombie_temple_sq_brock::delete_radio();

	trap = GetEnt("sq_spiketrap", "targetname");
	trap thread trap_thread();

	level thread delayed_start_skit();
}

delayed_start_skit()
{
	wait(.5);
	level thread maps\zombie_temple_sq_skits::start_skit("tt6");
}

trap_trigger()
{
	level endon("sq_bttp_over");

	while(1)
	{
		self waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );
		if( isplayer( attacker ) && ( 	dmg_type == "MOD_EXPLOSIVE" || dmg_type == "MOD_EXPLOSIVE_SPLASH"
																|| 	dmg_type == "MOD_GRENADE" || dmg_type == "MOD_GRENADE_SPLASH" ) )
		{
			self.owner_ent notify("triggered", attacker);
			return;
		}
	}
}

trap_thread()
{
	level endon("sq_bttp_over");

	self.trigger = Spawn( "trigger_damage", self.origin, 0, 32, 72 );
	self.trigger.height = 72;
	self.trigger.radius = 32;

	self.trigger.owner_ent = self;
	self.trigger thread trap_trigger();

	self waittill("triggered", who);

	who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 7 );
	self.trigger playsound( "evt_sq_bttp_wood_explo" );

	self Hide();

	flag_set("trap_destroyed");


}

bttp_debug()
{
	self endon("death");
	self endon("done");
	level endon("sq_bttp_over");

	while(1)
	{
		Print3d(self.origin, "+", (0,255,0), 1);
		wait(0.1);
	}
}

bttp_damage_thread()
{
	self endon("death");

	hits = 0;

	//self thread glyph_debug();

	self.owner_ent thread bttp_debug();

	self.trigger = Spawn( "trigger_damage", self.origin, 0, 64, 72 );
	self.trigger.height = 72;
	self.trigger.radius = 64;

	self.trigger.owner_ent = self;

	while(1)
	{
		self.trigger waittill( "damage", amount, attacker, direction, point, dmg_type, modelName, tagName );

		//iprintln("damage");

		if( isplayer( attacker ) && dmg_type == "MOD_MELEE" )
		{
			break;
		}
	}

	self playsound( "evt_sq_bttp_carve" );

	self.owner_ent SetModel(self.owner_ent.tile);
	self.owner_ent notify("done");

	level._num_done ++;

	if( isdefined( attacker ) && isPlayer( attacker ) )
	{
		if( level._num_done < level._bttp_num_goal )
		{
			if( randomintrange(0,101) <= 75 )
			{
				attacker thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest6", undefined, randomintrange(0,4) );
			}
		}
		else
		{
			attacker thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest6", undefined, 4 );

			flag_wait("trap_destroyed");

			if(IsDefined(self.trigger))
				self.trigger Delete();
		}
	}
}

get_unfinished_tile_model(tile)
{
	retVal = "p_ztem_glyphs_01_unfinished";

	switch(tile)
	{
		case "p_ztem_glyphs_01_unlit":
			retVal = "p_ztem_glyphs_01_unfinished";
			break;
		case "p_ztem_glyphs_02_unlit":
			retVal = "p_ztem_glyphs_02_unfinished";
			break;
		case "p_ztem_glyphs_03_unlit":
			retVal = "p_ztem_glyphs_03_unfinished";
			break;
		case "p_ztem_glyphs_04_unlit":
			retVal = "p_ztem_glyphs_04_unfinished";
			break;
		case "p_ztem_glyphs_05_unlit":
			retVal = "p_ztem_glyphs_05_unfinished";
			break;
		case "p_ztem_glyphs_06_unlit":
			retVal = "p_ztem_glyphs_06_unfinished";
			break;
		case "p_ztem_glyphs_07_unlit":
			retVal = "p_ztem_glyphs_07_unfinished";
			break;
		case "p_ztem_glyphs_08_unlit":
			retVal = "p_ztem_glyphs_08_unfinished";
			break;
		case "p_ztem_glyphs_09_unlit":
			retVal = "p_ztem_glyphs_09_unfinished";
			break;
		case "p_ztem_glyphs_10_unlit":
			retVal = "p_ztem_glyphs_10_unfinished";
			break;
		case "p_ztem_glyphs_11_unlit":
			retVal = "p_ztem_glyphs_11_unfinished";
			break;
		case "p_ztem_glyphs_12_unlit":
			retVal = "p_ztem_glyphs_12_unfinished";
			break;
	}

	return retVal;
}

stage_logic()
{

	level endon("sq_bttp_over");

	tile_models = array( 	"p_ztem_glyphs_01_unlit", "p_ztem_glyphs_02_unlit", "p_ztem_glyphs_03_unlit", "p_ztem_glyphs_04_unlit",
												"p_ztem_glyphs_05_unlit", "p_ztem_glyphs_06_unlit", "p_ztem_glyphs_07_unlit", "p_ztem_glyphs_08_unlit",
												"p_ztem_glyphs_09_unlit", "p_ztem_glyphs_10_unlit", "p_ztem_glyphs_11_unlit", "p_ztem_glyphs_12_unlit" );

	tile_models = array_randomize(tile_models);

	ents = GetEntArray("sq_bttp_glyph", "targetname");
	level._bttp_num_goal = ents.size;

	for(i = 0; i < ents.size; i ++)
	{
		ents[i].tile = tile_models[i];
		ents[i] SetModel(get_unfinished_tile_model(tile_models[i]));

	}

	while(1)
	{
		if(level._num_done == ents.size)
		{
			break;
		}
		wait(0.1);
	}

	flag_wait("trap_destroyed");
	level notify( "suspend_timer" );

	wait(5);

	stage_completed("sq", "bttp");
}

exit_stage(success)
{

	trap = GetEnt("sq_spiketrap", "targetname");

	if(success)
	{
		maps\zombie_temple_sq::remove_skel();
		maps\zombie_temple_sq_brock::create_radio(7, maps\zombie_temple_sq_brock::radio7_override);
	}
	else
	{
		if(IsDefined(level._sq_skel))
		{
			level._sq_skel Show();
		}
		maps\zombie_temple_sq_brock::create_radio(6);

		trap Show();
		level thread maps\zombie_temple_sq_skits::fail_skit();
	}


	if(IsDefined(trap.trigger))
	{
		trap.trigger Delete();
	}
}
