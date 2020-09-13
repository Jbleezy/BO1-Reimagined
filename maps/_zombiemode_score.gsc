#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility;

init()
{
	team_score_init();
}

//chris_p - added dogs to the scoring
player_add_points( event, mod, hit_location ,is_dog)
{
	if( level.intermission )
	{
		return;
	}

	if( !is_player_valid( self ) )
	{
		return;
	}

	player_points = 0;
	team_points = 0;
	multiplier = self get_points_multiplier();

	switch( event )
	{
		case "death":
			player_points	= get_zombie_death_player_points();
			team_points		= get_zombie_death_team_points();
			points = player_add_points_kill_bonus( mod, hit_location );
			if( IsDefined(level.zombie_vars["zombie_powerup_insta_kill_on"]) && level.zombie_vars["zombie_powerup_insta_kill_on"] && mod == "MOD_UNKNOWN" )
			{
				points = points * 2;
			}

			// Give bonus points
			player_points	= player_points + points;
			// Don't give points if there's no team points involved.
			if ( team_points > 0 )
			{
				team_points		= team_points + points;
			}

			if(IsDefined(self.kill_tracker))
			{
				self.kill_tracker++;
			}
			else
			{
				self.kill_tracker = 1;
			}
			//stats tracking
			self.stats["kills"] = self.kill_tracker;

			break;

		case "ballistic_knife_death":
			player_points = get_zombie_death_player_points() + level.zombie_vars["zombie_score_bonus_melee"];

			if(IsDefined(self.kill_tracker))
			{
				self.kill_tracker++;
			}
			else
			{
				self.kill_tracker = 1;
			}
			//stats tracking
			self.stats["kills"] = self.kill_tracker;

			break;

		case "damage_light":
			player_points = level.zombie_vars["zombie_score_damage_light"];
			break;

		case "damage":
			player_points = level.zombie_vars["zombie_score_damage_normal"];
			break;

		case "damage_ads":
			player_points = level.zombie_vars["zombie_score_damage_normal"];
			break;

		case "rebuild_board":
		case "carpenter_powerup":
			player_points	= mod;
			break;

		case "bonus_points_powerup":
			player_points	= mod;
			break;

		case "nuke_powerup":
			player_points	= mod;
			team_points		= mod;
			break;

		case "thundergun_fling":
			player_points = mod;
			break;

		case "hacker_transfer":
			player_points = mod;
			break;

		case "reviver":
			player_points = mod;
			break;

		default:
			assertex( 0, "Unknown point event" );
			break;
	}

	//player_points = multiplier * round_up_score( player_points, 5 );
	//team_points = multiplier * round_up_score( team_points, 5 );
	player_points = int(multiplier * player_points);
	team_points = int(multiplier * team_points);

	if ( isdefined( self.point_split_receiver ) && (event == "death" || event == "ballistic_knife_death") )
	{
		split_player_points = player_points - round_up_score( (player_points * self.point_split_keep_percent), 10 );
		self.point_split_receiver add_to_player_score( split_player_points );
		player_points = player_points - split_player_points;
	}

	// Add the points
	self add_to_player_score( player_points );
	players = get_players();
	if ( players.size > 1 )
	{
		self add_to_team_score( team_points );
	}

	//stat tracking
	self.stats["score"] = self.score_total;

//	self thread play_killstreak_vo();
}

get_points_multiplier()
{
	multiplier = self.zombie_vars["zombie_point_scalar"];

	if( level.mutators["mutator_doubleMoney"] )
	{
		multiplier *= 2;
	}

	return multiplier;
}

// Adjust points based on number of players (MikeA)
get_zombie_death_player_points()
{
	players = get_players();
	if( players.size == 1 )
	{
		points = level.zombie_vars["zombie_score_kill_1player"];
	}
	else if( players.size == 2 )
	{
		points = level.zombie_vars["zombie_score_kill_2player"];
	}
	else if( players.size == 3 )
	{
		points = level.zombie_vars["zombie_score_kill_3player"];
	}
	else
	{
		points = level.zombie_vars["zombie_score_kill_4player"];
	}
	return( points );
}


// Adjust team points based on number of players (MikeA)
get_zombie_death_team_points()
{
	players = get_players();
	if( players.size == 1 )
	{
		points = level.zombie_vars["zombie_score_kill_1p_team"];
	}
	else if( players.size == 2 )
	{
		points = level.zombie_vars["zombie_score_kill_2p_team"];
	}
	else if( players.size == 3 )
	{
		points = level.zombie_vars["zombie_score_kill_3p_team"];
	}
	else
	{
		points = level.zombie_vars["zombie_score_kill_4p_team"];
	}
	return( points );
}


//TUEY Old killstreak VO script---moved to utility
/*
play_killstreak_vo()
{
	index = maps\_zombiemode_weapons::get_player_index(self);
	self.killstreak = "vox_killstreak";

	if(!isdefined (level.player_is_speaking))
	{
		level.player_is_speaking = 0;
	}
	if (!isdefined (self.killstreak_points))
	{
		self.killstreak_points = 0;
	}
	self.killstreak_points = self.score_total;
	if (!isdefined (self.killstreaks))
	{
		self.killstreaks = 1;
	}
	if (self.killstreak_points > 1500 * self.killstreaks )
	{
		wait (randomfloatrange(0.1, 0.3));
		if(level.player_is_speaking != 1)
		{
			level.player_is_speaking = 1;
			self playsound ("plr_" + index + "_" +self.killstreak, "sound_done");
			self waittill("sound_done");
			level.player_is_speaking = 0;

		}
		self.killstreaks ++;
	}


}
*/
player_add_points_kill_bonus( mod, hit_location )
{
	if( mod == "MOD_MELEE" )
	{
		return level.zombie_vars["zombie_score_bonus_melee"];
	}

	/*if( mod == "MOD_BURNED" )
	{
		return level.zombie_vars["zombie_score_bonus_burn"];
	}*/

	score = 0;

	switch( hit_location )
	{
		case "head":
		case "helmet":
		case "neck":
			score = level.zombie_vars["zombie_score_bonus_head"];
			break;
	}

	return score;
}

player_reduce_points( event, mod, hit_location )
{
	if( level.intermission )
	{
		return;
	}

	points = 0;

	switch( event )
	{
		case "no_revive_penalty":
			percent = level.zombie_vars["penalty_no_revive"];
			points = self.score * percent;
			break;

		case "died":
			percent = level.zombie_vars["penalty_died"];
			points = self.score * percent;
			break;

		case "downed":
			percent = level.zombie_vars["penalty_downed"];
			self notify("I_am_down");
			points = self.score * percent;

			self.score_lost_when_downed = round_up_to_ten( int( points ) );
			break;

		default:
			assertex( 0, "Unknown point event" );
			break;
	}

	points = self.score - round_up_to_ten( int( points ) );

	if( points < 0 )
	{
		points = 0;
	}

	self.score = points;

	self set_player_score_hud();
}


//
//	Add points to the player's score
//	self is a player
//
add_to_player_score( points, add_to_total )
{
	if ( !IsDefined(add_to_total) )
	{
		add_to_total = true;
	}

	if( !IsDefined( points ) || level.intermission )
	{
		return;
	}

	self.score += points;

	if ( add_to_total )
	{
		self.score_total += points;
	}

	// also set the score onscreen
	self set_player_score_hud();
}


//
//	Subtract points from the player's score
//	self is a player
//
minus_to_player_score( points )
{
	if( !IsDefined( points ) || level.intermission )
	{
		return;
	}

	self.score -= points;

	// also set the score onscreen
	self set_player_score_hud();
}


//
//	Add points to the team pool
//	self is a player.  We need to derive the team from the player
//
add_to_team_score( points )
{
	//MM (3/10/10)	Disable team points

// 	if( !IsDefined( points ) || points == 0 || level.intermission )
// 	{
// 		return;
// 	}
//
// 	// Find out which team pool to adjust
// 	team_pool = level.team_pool[ 0 ];
// 	if ( IsDefined( self.team_num ) && self.team_num != 0 )
// 	{
// 		team_pool = level.team_pool[ self.team_num ];
// 	}
//
// 	team_pool.score += points;
// 	team_pool.score_total += points;
//
// 	// also set the score onscreen
// 	team_pool set_team_score_hud();
}


//
//	Subtract points from the team pool
//	self is a player.  We need to derive the team from the player
//
minus_to_team_score( points )
{
	if( !IsDefined( points ) || level.intermission )
	{
		return;
	}

	team_pool = level.team_pool[ 0 ];
	if ( IsDefined( self.team_num ) && self.team_num != 0 )
	{
		team_pool = level.team_pool[ self.team_num ];
	}

	team_pool.score -= points;

	// also set the score onscreen
	team_pool set_team_score_hud();
}


//
//
//
player_died_penalty()
{
	// Penalize all of the other players
	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		if( players[i] != self && !players[i].is_zombie )
		{
			players[i] player_reduce_points( "no_revive_penalty" );
		}
	}
}


//
//
//
player_downed_penalty()
{
	self player_reduce_points( "downed" );
}



//
// SCORING HUD --------------------------------------------------------------------- //
//

//
//	Sets the point values of a score hud
//	self will be the player getting the score adjusted
//
set_player_score_hud( init )
{
	num = self.entity_num;

	score_diff = self.score - self.old_score;

	if ( IsPlayer( self ) )
	{
		// local only splitscreen only displays each player's own score in their own viewport only
		if( !level.onlineGame && !level.systemLink && IsSplitScreen() )
		{
			self thread score_highlight( self, self.score, score_diff );
		}
		else
		{
			players = get_players();
			for ( i = 0; i < players.size; i++ )
			{
				players[i] thread score_highlight( self, self.score, score_diff );
			}
		}
	}

	// cap points at 10 million
	if(self.score > 10000000)
	{
		self.score = 10000000;
	}

	if( IsDefined( init ) && init )
	{
		return;
	}

	self.old_score = self.score;
}


//
//	Sets the point values of a score hud
//	self will be the team_pool
//
set_team_score_hud( init )
{
	//MM (3/10/10)	Disable team points
	self.score = 0;
	self.score_total = 0;

//
// 	if ( !IsDefined(init) )
// 	{
// 		init = false;
// 	}
//
// 	//		TEMP function call.  Might rename this function so it makes more sense
// 	self set_player_score_hud( false );
// 	self.hud SetValue( self.score );
}

// Creates a hudelem used for the points awarded/taken away
create_highlight_hud( x, y, value )
{
	font_size = 8;
	if ( self IsSplitscreen() )
	{
		font_size *= 2;
	}

	hud = create_simple_hud( self );

	//level.hudelem_count++;

	hud.foreground = true;
	hud.sort = 0;
	hud.x = x;
	hud.y = y;
	hud.fontScale = font_size;
	hud.alignX = "right";
	hud.alignY = "middle";
	hud.horzAlign = "user_right";
	hud.vertAlign = "user_bottom";

	if( value < 1 )
	{
		hud.color = ( 0.4, 0, 0 );
	}
	else
	{
		hud.color = ( 0.9, 0.9, 0.0 );
		hud.label = &"SCRIPT_PLUS";
	}

	//hud.glowColor = ( 0.3, 0.6, 0.3 );
	//hud.glowAlpha = 1;
	hud.hidewheninmenu = true;

	hud SetValue( value );

	return hud;
}

//
// Handles the creation/movement/deletion of the moving hud elems
//
score_highlight( scoring_player, score, value )
{
	self endon( "disconnect" );

	// Location from hud.menu
	score_x = -103;
	score_y = -100;

	if ( self IsSplitscreen() )
	{
		score_y = -95;
	}

	x = score_x;

	// local only splitscreen only displays each player's own score in their own viewport only
	if( !level.onlineGame && !level.systemLink && IsSplitScreen() )
	{
		y = score_y;
	}
	else
	{
		players = get_players();

		num = 0;
		for ( i = 0; i < players.size; i++ )
		{
			if ( scoring_player == players[i] )
			{
				num = players.size - i - 1;
			}
		}
		y = ( num * -20 ) + score_y;
	}

	if ( self IsSplitscreen() )
	{
		y *= 2;
	}

	if(value < 1)
	{
		y += 5;
	}
	else
	{
		y -= 5;
	}

	time = 0.5;
	half_time = time * 0.5;
	quarter_time = time * 0.25;

	player_num = scoring_player GetEntityNumber();

	if(value < 1)
	{
		if(IsDefined(self.negative_points_hud) && IsDefined(self.negative_points_hud[player_num]))
		{
			value += self.negative_points_hud_value[player_num];
			self.negative_points_hud[player_num] Destroy();
		}
	}
	else if(IsDefined(self.positive_points_hud) && IsDefined(self.positive_points_hud[player_num]))
	{
		value += self.positive_points_hud_value[player_num];
		self.positive_points_hud[player_num] Destroy();
	}

	hud = self create_highlight_hud( x, y, value );

	if( value < 1 )
	{
		if(!IsDefined(self.negative_points_hud))
		{
			self.negative_points_hud = [];
		}
		if(!IsDefined(self.negative_points_hud_value))
		{
			self.negative_points_hud_value = [];
		}
		self.negative_points_hud[player_num] = hud;
		self.negative_points_hud_value[player_num] = value;
	}
	else
	{
		if(!IsDefined(self.positive_points_hud))
		{
			self.positive_points_hud = [];
		}
		if(!IsDefined(self.positive_points_hud_value))
		{
			self.positive_points_hud_value = [];
		}
		self.positive_points_hud[player_num] = hud;
		self.positive_points_hud_value[player_num] = value;
	}

	// Move the hud
	hud MoveOverTime( time );
	hud.x -= 50;
	if(value < 1)
	{
		hud.y += 5;
	}
	else
	{
		hud.y -= 5;
	}

	wait( half_time );

	if(!IsDefined(hud))
	{
		return;
	}

	// Fade half-way through the move
	hud FadeOverTime( half_time );
	hud.alpha = 0;

	wait( half_time );

	if(!IsDefined(hud))
	{
		return;
	}

	hud Destroy();
}

/*
//OLD
//
// Handles the creation/movement/deletion of the moving hud elems
//
score_highlight( scoring_player, score, value )
{
	self endon( "disconnect" );

	if(!IsDefined(self.highlight_hudelem_count))
	{
		self.highlight_hudelem_count = 0; //keeps track of any score streak so the scores go in order
		self.current_highlight_hudelem_count = 0; //keeps track of current scores on screen to prevent overlapping
	}

	// Location from hud.menu
	score_x = -103;
	score_y = -100;

	if ( self IsSplitscreen() )
	{
		score_y = -95;
	}

	x = score_x;

	// local only splitscreen only displays each player's own score in their own viewport only
	if( !level.onlineGame && !level.systemLink && IsSplitScreen() )
	{
		y = score_y;
	}
	else
	{
		players = get_players();

		num = 0;
		for ( i = 0; i < players.size; i++ )
		{
			if ( scoring_player == players[i] )
			{
				num = players.size - i - 1;
			}
		}
		y = ( num * -20 ) + score_y;
	}

	if ( self IsSplitscreen() )
	{
		y *= 2;
	}

	time = 0.5;
	half_time = time * 0.5;
	quarter_time = time * 0.25;

	while(self.current_highlight_hudelem_count >= 5)
	{
		wait_network_frame();
	}

	self.highlight_hudelem_count++;
	self.current_highlight_hudelem_count++;
	self thread minus_after_wait(.05);
	hud = self create_highlight_hud( x, y, value );
	current_count = self.highlight_hudelem_count;
	//x_count = (int(current_count / 6) % 4);
	y_count = current_count % 5;
	if(y_count == 0)
	{
		y_count = 5;
	}
	y_count--;

	// Move the hud
	hud MoveOverTime( time );
	//hud.x -= 20 + RandomInt( 40 );
	//hud.y -= ( -15 + RandomInt( 30 ) );
	hud.x -= 50;
	hud.y += ( -20 + (((y_count + 2) % 5) * 10) );

	wait( time - quarter_time );

	// Fade half-way through the move
	hud FadeOverTime( quarter_time );
	hud.alpha = 0;

	wait( quarter_time );

	hud Destroy();
	level.hudelem_count--;
	if(self.highlight_hudelem_count - current_count == 0)
	{
		self.highlight_hudelem_count = 0;
	}
}

minus_after_wait(time)
{
	wait time;
	self.current_highlight_hudelem_count--;
}*/


//
//	Initialize the team point counter
//
team_score_init()
{
	//	NOTE: Make sure all players have connected before doing this.
	flag_wait( "all_players_connected" );

	level.team_pool = [];

	// No Pools in a 1 player game
	players = get_players();
	if ( players.size == 1 )
	{
		// just create a stub team pool...
		level.team_pool[0] = SpawnStruct();
		pool				= level.team_pool[0];
		pool.team_num		= 0;
		pool.score			= 0;
		pool.old_score		= pool.score;
		pool.score_total	= pool.score;
		return;
	}

	if ( IsDefined( level.zombiemode_versus ) && level.zombiemode_versus )
	{
		num_pools = 2;
	}
	else
	{
		num_pools = 1;
	}

	for (i=0; i<num_pools; i++ )
	{
		level.team_pool[i] = SpawnStruct();
		pool				= level.team_pool[i];
		pool.team_num		= i;
		pool.score			= 0;
		pool.old_score		= pool.score;
		pool.score_total	= pool.score;

		// Based on the Location of the player score from hud.menu
		pool.hud_x			= -103 + 5;	// 2nd # is an offset from the menu position to get it to line up
		pool.hud_y			= -71 - 36;	// 2nd # is spacing away from the player score

		if( !IsSplitScreen() )
		{
			players = get_players();
			num = players.size - 1;
			pool.hud_y += (num+(num_pools-1 - i)) * -18;	// last number is a spacing gap from the player scores
		}

		//MM (3/10/10)	Disable team points
//		pool.hud = create_team_hud( pool.score, pool );
	}
}


//
//	Initialize the team score hud
//
create_team_hud( value, team_pool )
{
	AssertEx( IsDefined( team_pool ), "create_team_hud:  You must specify a team_pool when calling this function" );
	font_size = 8.0;

	hud				= create_simple_hud();
	hud.foreground	= true;
	hud.sort		= 10;
	hud.x			= team_pool.hud_x;
	hud.y			= team_pool.hud_y;
	hud.fontScale = font_size;
	hud.alignX		= "left";
	hud.alignY		= "middle";
	hud.horzAlign	= "user_right";
	hud.vertAlign	= "user_bottom";
	hud.color		= ( 0.9, 0.9, 0.0 );
	hud.hidewheninmenu = false;

	hud SetValue( value );

	// Set score icon
	bg_hud				= create_simple_hud();
	bg_hud.alignX		= "right";
	bg_hud.alignY		= "middle";
	bg_hud.horzAlign	= "user_right";
	bg_hud.vertAlign	= "user_bottom";
	bg_hud.color		= ( 1, 1, 1 );
	bg_hud.sort			= 8;
	bg_hud.x			= team_pool.hud_x - 8;
	bg_hud.y			= team_pool.hud_y;
	bg_hud.alpha		= 1;
	bg_hud SetShader( "zom_icon_community_pot", 32, 32 );

	// Set score highlight
	bg_hud				= create_simple_hud();
	bg_hud.alignX		= "left";
	bg_hud.alignY		= "middle";
	bg_hud.horzAlign	= "user_right";
	bg_hud.vertAlign	= "user_bottom";
	bg_hud.color		= ( 0.0, 0.0, 0 );
	bg_hud.sort			= 8;
	bg_hud.x			= team_pool.hud_x - 24;
	bg_hud.y			= team_pool.hud_y;
	bg_hud.alpha		= 1;
	bg_hud SetShader( "zom_icon_community_pot_strip", 128, 16 );

	return hud;
}
