/* zombie_temple_sq_oafc.gsc
 *
 * Purpose : 	Sidequest declaration and side-quest logic for zombie_temple stage 1.
 * 						The Once and Future Crystal
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
	PreCacheModel("p_ztem_glyphs_00");
	declare_sidequest_stage("sq", "OaFC", ::init_stage, ::stage_logic, ::exit_stage);
	set_stage_time_limit("sq", "OaFC", 5 * 60);	// 5 minute limit.
//	declare_stage_title("sq", "OaFC", &"ZOMBIE_TEMPLE_SIDEQUEST_STAGE_1_TITLE");
	declare_stage_asset_from_struct("sq", "OaFC", "sq_oafc_switch", ::oafc_switch);
	declare_stage_asset_from_struct("sq", "OaFC", "sq_oafc_tileset1", ::tileset1, maps\_zombiemode_sidequests::radius_trigger_thread);
	declare_stage_asset_from_struct("sq", "OaFC", "sq_oafc_tileset2", ::tileset2, maps\_zombiemode_sidequests::radius_trigger_thread);

	flag_init("oafc_switch_pressed");
	flag_init("oafc_plot_vo_done");
}

stage_logic()
{
	/#

	flag_wait("oafc_switch_pressed");

	if(get_players().size == 1)
	{
		wait(20);
		level notify("raise_crystal_1", true);
		level waittill("raised_crystal_1");

		wait(5.0);

		stage_completed("sq", "OaFC");
		return;
	}

	#/
}

oafc_switch()
{
	level endon("sq_OaFC_over");

	level thread knocking_audio();

	self.on_pos = self.origin;
	self.off_pos = self.on_pos - (AnglesToUp(self.angles) * 5.5);

	self waittill("triggered", who);

	entity_num = who GetEntityNumber();

	if( IsDefined( who.zm_random_char ) )
	{
		entity_num = who.zm_random_char;
	}

	//who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 0 );

	level._player_who_pressed_the_switch = entity_num;

	self.trigger trigger_off();

	self playsound( "evt_sq_gen_button" );

	self moveto(self.off_pos, 0.25);
	self waittill("movedone");

	flag_set("oafc_switch_pressed");

	level thread oafc_story_vox();
}

knocking_audio()
{
	level endon("sq_OaFC_over");

	struct = getstruct( "sq_location_oafc", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}

	while( !flag("oafc_switch_pressed") )
	{
		playsoundatposition( "evt_sq_oafc_knock", struct.origin );
		wait(randomfloatrange(1.5, 4 ) );
	}
}

tileset1()
{
	self.set = 1;
	self.original_origin = self.origin;
}

tileset2()
{
	self.set = 2;
	self.original_origin = self.origin;
}

tile_cheat()
{
	level endon("reset_tiles");
	level endon("sq_OaFC_over");

	while(IsDefined(self.matched) && !self.matched)
	{
		Print3d(self.origin, self.tile, (0,255,0));
		wait(0.1);
	}
}

tile_debug()
{
	level endon("sq_OaFC_over"); // Kill logic func if it's still running.

	if(!IsDefined(level._debug_tiles))
	{
		level._debug_tiles = true;

		level.selected_tile1 = NewDebugHudElem();
		level.selected_tile1.location = 0;
		level.selected_tile1.alignX = "left";
		level.selected_tile1.alignY = "middle";
		level.selected_tile1.foreground = 1;
		level.selected_tile1.fontScale = 1.3;
		level.selected_tile1.sort = 20;
		level.selected_tile1.x = 10;
		level.selected_tile1.y = 240;
		level.selected_tile1.og_scale = 1;
		level.selected_tile1.color = (255,255,255);
		level.selected_tile1.alpha = 1;

		level.selected_tile1_text = NewDebugHudElem();
		level.selected_tile1_text.location = 0;
		level.selected_tile1_text.alignX = "right";
		level.selected_tile1_text.alignY = "middle";
		level.selected_tile1_text.foreground = 1;
		level.selected_tile1_text.fontScale = 1.3;
		level.selected_tile1_text.sort = 20;
		level.selected_tile1_text.x = 0;
		level.selected_tile1_text.y = 240;
		level.selected_tile1_text.og_scale = 1;
		level.selected_tile1_text.color = (255, 255,255);
		level.selected_tile1_text.alpha = 1;
		level.selected_tile1_text SetText("Tile1: ");

		level.selected_tile2 = NewDebugHudElem();
		level.selected_tile2.location = 0;
		level.selected_tile2.alignX = "left";
		level.selected_tile2.alignY = "middle";
		level.selected_tile2.foreground = 1;
		level.selected_tile2.fontScale = 1.3;
		level.selected_tile2.sort = 20;
		level.selected_tile2.x = 10;
		level.selected_tile2.y = 270;
		level.selected_tile2.og_scale = 1;
		level.selected_tile2.color = (255,255,255);
		level.selected_tile2.alpha = 1;

		level.selected_tile2_text = NewDebugHudElem();
		level.selected_tile2_text.location = 0;
		level.selected_tile2_text.alignX = "right";
		level.selected_tile2_text.alignY = "middle";
		level.selected_tile2_text.foreground = 1;
		level.selected_tile2_text.fontScale = 1.3;
		level.selected_tile2_text.sort = 20;
		level.selected_tile2_text.x = 0;
		level.selected_tile2_text.y = 270;
		level.selected_tile2_text.og_scale = 1;
		level.selected_tile2_text.color = (255, 255,255);
		level.selected_tile2_text.alpha = 1;
		level.selected_tile2_text SetText("Tile2: ");

		level.num_matched = NewDebugHudElem();
		level.num_matched.location = 0;
		level.num_matched.alignX = "left";
		level.num_matched.alignY = "middle";
		level.num_matched.foreground = 1;
		level.num_matched.fontScale = 1.3;
		level.num_matched.sort = 20;
		level.num_matched.x = 10;
		level.num_matched.y = 300;
		level.num_matched.og_scale = 1;
		level.num_matched.color = (255,255,255);
		level.num_matched.alpha = 1;

		level.num_matched_text = NewDebugHudElem();
		level.num_matched_text.location = 0;
		level.num_matched_text.alignX = "right";
		level.num_matched_text.alignY = "middle";
		level.num_matched_text.foreground = 1;
		level.num_matched_text.fontScale = 1.3;
		level.num_matched_text.sort = 20;
		level.num_matched_text.x = 0;
		level.num_matched_text.y = 300;
		level.num_matched_text.og_scale = 1;
		level.num_matched_text.color = (255, 255,255);
		level.num_matched_text.alpha = 1;
		level.num_matched_text SetText("NMT: ");
	}

	while(1)
	{
		if(IsDefined(level._picked_tile1))
		{
			level.selected_tile1 SetText(level._picked_tile1.tile);
		}
		else
		{
			level.selected_tile1 SetText("None.");
		}

		if(IsDefined(level._picked_tile2))
		{
			level.selected_tile2 SetText(level._picked_tile2.tile);
		}
		else
		{
			level.selected_tile2 SetText("None.");
		}

		if(IsDefined(level._num_matched_tiles))
		{
			level.num_matched SetText(level._num_matched_tiles);
		}

		wait(0.05);
	}
}

tile_monitor()
{
	level endon("sq_OaFC_over");
	self endon("tiles_picked");
	level endon("reset_tiles");

	self.origin = self.original_origin;	// Reset position

//	self thread tile_cheat();
}

init_stage()
{
	level thread tile_debug();

	flag_clear("oafc_switch_pressed");
	flag_clear("oafc_plot_vo_done");

	reset_tiles();

	maps\zombie_temple_sq_brock::delete_radio();

	level thread delayed_start_skit();
}

delayed_start_skit()
{
	wait(.5);
	level thread maps\zombie_temple_sq_skits::start_skit("tt1");
}

tile_moves_up(delay)
{
	level endon("sq_OaFC_over");

	flag_wait("oafc_switch_pressed");

	for(i = 0; i < delay; i ++)
	{
		wait_network_frame();
	}

	self moveto(self.original_origin, 0.25);
}

set_tile_models(tiles, models)
{
	for(i = 0; i < tiles.size; i ++)
	{
		tiles[i] SetModel("p_ztem_glyphs_00");	// Set all tiles to blank.
		tiles[i].tile = models[i];

		tiles[i].matched = false;

		tiles[i].origin = tiles[i].original_origin - (0,0,24);	// Reset position

		//tiles[i] thread tiles_cheat();
		tiles[i] thread tile_moves_up(i%4);
	}
}

player_in_trigger()
{
	players = get_players();

	for(i = 0; i < players.size; i ++)
	{
		if(players[i].sessionstate != "spectator" && self IsTouching(players[i]))
		{
			return players[i];
		}
	}

	return undefined;
}

oafc_trigger_thread(tiles, set)
{
	self endon("death");
	level endon("reset_tiles");

	self trigger_off();

	flag_wait("oafc_switch_pressed");

	self trigger_on();

	while(1)
	{
		for(i = 0; i < tiles.size; i ++)
		{
			tile = tiles[i];

			if(IsDefined(tile) && !tile.matched)
			{
				self.origin = tiles[i].origin;

				touched_player = self player_in_trigger();

				if(IsDefined(touched_player))
				{

					if(set == 1)
					{
						PrintLn("trig thread has new tile " + i);
					}

					tile SetModel(tile.tile);
					tile playsound( "evt_sq_oafc_glyph_activate" );

					matched = false;

					if(set == 1)
					{
						level._picked_tile1 = tile;
					}
					else
					{
						level._picked_tile2 = tile;
					}

					while(IsDefined(touched_player) && self IsTouching(touched_player) && touched_player.sessionstate != "spectator" && !tile.matched)
					{
						self.touched_player = touched_player;
						//if(set == 1)
						{
							if(IsDefined(level._picked_tile1) && IsDefined(level._picked_tile2))
							{
								if(level._picked_tile1.tile == level._picked_tile2.tile)
								{
									level._picked_tile1 playsound( "evt_sq_oafc_glyph_correct" );
									level._picked_tile2 playsound( "evt_sq_oafc_glyph_correct" );

									matched = true;
									level._picked_tile1.matched = true;
									level._picked_tile2.matched = true;

									level._picked_tile1 moveto(level._picked_tile1.origin - (0,0,24), 0.5);
									level._picked_tile2 moveto(level._picked_tile2.origin - (0,0,24), 0.5);

									level._picked_tile1 waittill("movedone");

									level._picked_tile1 = undefined;
									level._picked_tile2 = undefined;

									level._num_matched_tiles ++;

									if( level._num_matched_tiles < level._num_tiles_to_match )
									{
										rand = randomintrange(0,2);

										if( isdefined( touched_player ) && rand == 0 )
										{
											touched_player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, randomintrange(5,8) );
										}
										else if( isdefined( level._oafc_trigger2.touched_player ) )
										{
											level._oafc_trigger2.touched_player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, randomintrange(5,8) );
										}
									}

									if(level._num_matched_tiles == level._num_tiles_to_match)
									{
										struct = getstruct( "sq_location_oafc", "targetname" );
										if( isdefined( struct ) )
										{
											playsoundatposition( "evt_sq_oafc_glyph_complete", struct.origin );
											playsoundatposition( "evt_sq_oafc_kachunk", struct.origin );
										}
										//tile playsound( "evt_sq_oafc_glyph_complete" );
										//tile playsound( "evt_sq_oafc_kachunk" );

										if( isdefined( touched_player ) )
										{
											//touched_player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 8 );
										}

										level notify( "suspend_timer" );
										level notify("raise_crystal_1", true);
										level waittill("raised_crystal_1");

										flag_wait("oafc_plot_vo_done");
										wait(5.0);

										stage_completed("sq", "OaFC");
										return;
									}

									PrintLn("breaking out of match");

									break;
								}
								/*else
								{
									level._picked_tile1 playsound( "evt_sq_oafc_glyph_wrong" );
									level._picked_tile2 playsound( "evt_sq_oafc_glyph_wrong" );

									rand = randomintrange(0,2);

									if( isdefined( touched_player ) && rand == 0 )
									{
										touched_player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, randomintrange(2,5) );
									}
									else if( isdefined( level._oafc_trigger2.touched_player ) )
									{
										level._oafc_trigger2.touched_player thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, randomintrange(2,5) );
									}

									while(IsDefined(touched_player) && self IsTouching(touched_player) && IsDefined(level._picked_tile2))
									{
										wait(0.05);
									}

									PrintLn("Breaking out of unmatched.");

									level thread reset_tiles();	// will end trigger threads - threads recreated by reset_tiles

									break;
								}*/
							}
						}

						wait(0.05);
					}

					tile thread deactivate_on_new_tile(set);

				}
			}
		}

		wait(0.05);
	}

	if(set == 1)
	{
		PrintLn("Fallen out of trig thread.");
	}
}

deactivate_on_new_tile(set)
{
	self notify("tile_activated");
	self endon("tile_activated");

	//self playsound( "evt_sq_oafc_glyph_clear" );

	if(set == 1)
	{
		while(level._picked_tile1 == self)
			wait .05;
	}
	else
	{
		while(level._picked_tile2 == self)
			wait .05;
	}

	self SetModel("p_ztem_glyphs_00");
}

reset_tiles()
{
	tile_models = array( 	"p_ztem_glyphs_01_unlit", "p_ztem_glyphs_02_unlit", "p_ztem_glyphs_03_unlit", "p_ztem_glyphs_04_unlit",
												"p_ztem_glyphs_05_unlit", "p_ztem_glyphs_06_unlit", "p_ztem_glyphs_07_unlit",	"p_ztem_glyphs_08_unlit",
												"p_ztem_glyphs_09_unlit", "p_ztem_glyphs_10_unlit", "p_ztem_glyphs_11_unlit", "p_ztem_glyphs_12_unlit" );

	level notify("reset_tiles");

	if(!IsDefined(level._oafc_trigger1))
	{
		level._oafc_trigger1 = Spawn( "trigger_radius",(0,0,0), 0, 22, 72 );
		level._oafc_trigger2 = Spawn( "trigger_radius",(0,0,0), 0, 22, 72 );
		level._oafc_trigger1 thread wait_for_first_stepon();
		level._oafc_trigger2 thread wait_for_first_stepon();
	}


	level._num_matched_tiles = 0;
	level._picked_tile1 = undefined;
	level._picked_tile2 = undefined;


	tile_models = array_randomize(tile_models);

	tileset1 = GetEntArray("sq_oafc_tileset1", "targetname");

	level._num_tiles_to_match = tileset1.size;

	set_tile_models(tileset1, tile_models);

	level._oafc_trigger1 thread oafc_trigger_thread(tileset1,1);

//	array_thread(tileset1, ::tile_monitor);



	tile_models = array_randomize(tile_models);
	tileset2 = GetEntArray("sq_oafc_tileset2", "targetname");
	set_tile_models(tileset2, tile_models);

	level._oafc_trigger2 thread oafc_trigger_thread(tileset2,2);

//	array_thread(tileset2, ::tile_monitor);
}

wait_for_first_stepon()
{
	self endon( "death" );
	level endon( "quest1_glyph_line_said" );

	while(1)
	{
		self waittill( "trigger", who );
		if( isdefined( who) && isPlayer(who) )
		{
			who thread maps\_zombiemode_audio::create_and_play_dialog( "eggs", "quest1", undefined, 1 );
			break;
		}
	}

	level notify( "quest1_glyph_line_said" );
}

exit_stage(success)
{
	if(IsDefined(level._debug_tiles))
	{
		level._debug_tiles = undefined;

		level.selected_tile1 Destroy();
		level.selected_tile1 = undefined;

		level.selected_tile1_text Destroy();
		level.selected_tile1_text = undefined;

		level.selected_tile2 Destroy();
		level.selected_tile2 = undefined;

		level.selected_tile2_text Destroy();
		level.selected_tile2_text = undefined;

		level.num_matched Destroy();
		level.num_matched.location = undefined;

		level.num_matched_text Destroy();
		level.num_matched_text = undefined;
	}


	if(success)
	{
		maps\zombie_temple_sq_brock::create_radio(2, maps\zombie_temple_sq_brock::radio2_override);
	}
	else
	{
		maps\zombie_temple_sq_brock::create_radio(1);
		level thread maps\zombie_temple_sq_skits::fail_skit(true);
	}

	level._oafc_trigger1 Delete();
	level._oafc_trigger2 Delete();

	if( isdefined( level._oafc_sound_ent ) )
	{
		level._oafc_sound_ent delete();
		level._oafc_sound_ent = undefined;
	}

	level.skit_vox_override = false;
}

oafc_story_vox()
{
	level endon("sq_OaFC_over");

	struct = getstruct( "sq_location_oafc", "targetname" );
	if( !isdefined( struct ) )
	{
		return;
	}

	level._oafc_sound_ent = spawn( "script_origin", struct.origin );

	//Start the vox here
	level._oafc_sound_ent playsound( "vox_egg_story_1_0", "sounddone" );
	level._oafc_sound_ent waittill( "sounddone" );

	players = get_players();
	if( isdefined( players[level._player_who_pressed_the_switch] ) )
	{
		level.skit_vox_override = true;
		players[level._player_who_pressed_the_switch] playsound( "vox_egg_story_1_1" + maps\zombie_temple_sq::get_variant_from_entity_num( level._player_who_pressed_the_switch ), "vox_egg_sounddone" );
		players[level._player_who_pressed_the_switch] waittill( "vox_egg_sounddone" );
		level.skit_vox_override = false;
	}

	level._oafc_sound_ent playsound( "vox_egg_story_1_2", "sounddone" );
	level._oafc_sound_ent waittill( "sounddone" );

	while( level._num_matched_tiles < 1 )
	{
		wait(.1);
	}

	level._oafc_sound_ent playsound( "vox_egg_story_1_3", "sounddone" );
	level._oafc_sound_ent waittill( "sounddone" );

	while( level._num_matched_tiles != level._num_tiles_to_match )
	{
		wait(.1);
	}

	level._oafc_sound_ent playsound( "vox_egg_story_1_4", "sounddone" );
	level._oafc_sound_ent waittill( "sounddone" );

	players = get_players();
	if( isdefined( players[level._player_who_pressed_the_switch] ) )
	{
		level.skit_vox_override = true;
		players[level._player_who_pressed_the_switch] playsound( "vox_egg_story_1_5" + maps\zombie_temple_sq::get_variant_from_entity_num( level._player_who_pressed_the_switch ), "vox_egg_sounddone" );
		players[level._player_who_pressed_the_switch] waittill( "vox_egg_sounddone" );
		level.skit_vox_override = false;
	}

	level._oafc_sound_ent playsound( "vox_egg_story_1_6", "sounddone" );
	level._oafc_sound_ent waittill( "sounddone" );

	level._oafc_sound_ent playsound( "vox_egg_story_1_7", "sounddone" );
	level._oafc_sound_ent waittill( "sounddone" );

	flag_set("oafc_plot_vo_done");

	level._oafc_sound_ent delete();
	level._oafc_sound_ent = undefined;
}
