#include maps\_utility;
#include animscripts\utility;
#include common_scripts\utility;
// this script handles all major global gameskill considerations
setSkill( reset, skill_override )
{
	/#
	debug_replay("File: _gameskill.gsc. Function: setSkill()\n");
	#/

	if ( !isdefined( level.script ) )
	{
		level.script = tolower( GetDvar( #"mapname" ) );
	}


	if ( !isdefined( reset ) || reset == false )
	{
		if ( isdefined( level.gameSkill ) )
		{
			/#
			debug_replay("File: _gameskill.gsc. Function: setSkill() - COMPLETE EARLY\n");
			#/
			return;
		}

		if ( !isdefined( level.custom_player_attacker ) )
		{
			level.custom_player_attacker = ::return_false;
		}

		level.global_damage_func_ads = ::empty_kill_func;
		level.global_damage_func = ::empty_kill_func;
		level.global_kill_func = ::empty_kill_func;
//CZ MM (09/17/09) Temp fix to prevent arcade mode from running until we get a separate Zombie mode entry in the menus.
//		if ( GetDvar( #"arcademode" ) == "1" )
		//if ( GetDvar( #"arcademode" ) == "1" && GetDvar( #"zombiemode" ) != "1" && GetDvar( #"g_gametype" ) != "vs" )
		//{
		//	thread call_overloaded_func( "maps\_arcademode", "main" );
		//}

		// first init stuff
		set_console_status();
		flag_init( "player_has_red_flashing_overlay" );
		flag_init( "player_is_invulnerable" );
		flag_clear( "player_has_red_flashing_overlay" );
		flag_clear( "player_is_invulnerable" );
		level.difficultyType[ 0 ] = "easy";
		level.difficultyType[ 1 ] = "normal";
		level.difficultyType[ 2 ] = "hardened";
		level.difficultyType[ 3 ] = "veteran";

		level.difficultyString[ "easy" ] = &"GAMESKILL_EASY";
		level.difficultyString[ "normal" ] = &"GAMESKILL_NORMAL";
		level.difficultyString[ "hardened" ] = &"GAMESKILL_HARDENED";
		level.difficultyString[ "veteran" ] = &"GAMESKILL_VETERAN";

		// CODER_MOD - Sumeet, track skill changes in game
		level thread update_skill_on_change();

		/#
		thread playerHealthDebug();
		#/
	}

	if(!IsDefined(level.invulTime_onShield_multiplier))
	{
		level.invulTime_onShield_multiplier = 1;
	}

	if(!IsDefined(level.player_attacker_accuracy_multiplier))
	{
		level.player_attacker_accuracy_multiplier = 1;
	}



	level.gameSkill = GetDvarInt( #"g_gameskill" );
	if ( isdefined( skill_override ) )
	{
		level.gameSkill = skill_override;
	}


	switch (level.gameSkill)
	{
		case 0:
			setdvar ("currentDifficulty", "easy");
			break;
		case 1:
			setdvar ("currentDifficulty", "normal");
			break;
		case 2:
			setdvar ("currentDifficulty", "hardened");
			break;
		case 3:
			setdvar ("currentDifficulty", "veteran");
			break;
	}

// 	createprintchannel( "script_autodifficulty" );

	if ( GetDvar( #"autodifficulty_playerDeathTimer" ) == "" )
	{
		setdvar( "autodifficulty_playerDeathTimer", 0 );
	}

	anim.run_accuracy = 0.5;

	logString( "difficulty: " + level.gameSkill );

	// if ( GetDvar( #"autodifficulty_frac" ) == "" )
	setdvar( "autodifficulty_frac", 0 );// disabled for now

	// Turn back on coop difficulty scaling!
	setdvar( "coop_difficulty_scaling", 1 );

	level.difficultySettings_stepFunc_percent = [];
	level.difficultySettings_frac_data_points = [];
	level.auto_adjust_threatbias = true;

	setTakeCoverWarnings();
	thread increment_take_cover_warnings_on_death();

	level.mg42badplace_mintime = 8;// minimum # of seconds a badplace is created on an mg42 after its operator dies
	level.mg42badplace_maxtime = 16;// maximum # of seconds a badplace is created on an mg42 after its operator dies

	 // anim.playerGrenadeBaseTime
	add_fractional_data_point( "playerGrenadeBaseTime", 0.0, 50000 );
	add_fractional_data_point( "playerGrenadeBaseTime", 0.25, 40000 ); // original easy
	add_fractional_data_point( "playerGrenadeBaseTime", 0.75, 25000 ); // original normal
	add_fractional_data_point( "playerGrenadeBaseTime", 1.0, 13500 );
	level.difficultySettings[ "playerGrenadeBaseTime" ][ "hardened" ] = 10000;
	level.difficultySettings[ "playerGrenadeBaseTime" ][ "veteran" ] = 0;

	 // anim.playerGrenadeRangeTime
	add_fractional_data_point( "playerGrenadeRangeTime", 0.0, 22000 );
	add_fractional_data_point( "playerGrenadeRangeTime", 0.25, 20000 ); // original easy
	add_fractional_data_point( "playerGrenadeRangeTime", 0.75, 15000 ); // original normal
	add_fractional_data_point( "playerGrenadeRangeTime", 1.0, 7500 );
	level.difficultySettings[ "playerGrenadeRangeTime" ][ "hardened" ] = 5000;
	level.difficultySettings[ "playerGrenadeRangeTime" ][ "veteran" ] = 1;

	// time between instances where 2 grenades land near player at once( hardcoded to never happen in easy )
	add_fractional_data_point( "playerDoubleGrenadeTime", 0.25, 60 * 60 * 1000 ); // original easy
	add_fractional_data_point( "playerDoubleGrenadeTime", 0.75, 120 * 1000 ); // original normal
	add_fractional_data_point( "playerDoubleGrenadeTime", 1.0, 20 * 1000 );
	level.difficultySettings[ "playerDoubleGrenadeTime" ][ "hardened" ] = 15 * 1000;
	level.difficultySettings[ "playerDoubleGrenadeTime" ][ "veteran" ] = 0;

	level.difficultySettings[ "double_grenades_allowed" ][ "easy" ] = false;
	level.difficultySettings[ "double_grenades_allowed" ][ "normal" ] = true;
	level.difficultySettings[ "double_grenades_allowed" ][ "hardened" ] = true;
	level.difficultySettings[ "double_grenades_allowed" ][ "veteran" ] = true;
	level.difficultySettings_stepFunc_percent[ "double_grenades_allowed" ] = 0.75;


	add_fractional_data_point( "player_deathInvulnerableTime", 0.25, 4000 ); // original easy
	add_fractional_data_point( "player_deathInvulnerableTime", 0.75, 1700 ); // original normal
	add_fractional_data_point( "player_deathInvulnerableTime", 1.0, 850 );
	level.difficultySettings[ "player_deathInvulnerableTime" ][ "hardened" ] = 600;
	level.difficultySettings[ "player_deathInvulnerableTime" ][ "veteran" ] = 100;

	add_fractional_data_point( "threatbias", 0.0, 80 );
	add_fractional_data_point( "threatbias", 0.25, 100 ); // original easy
	add_fractional_data_point( "threatbias", 0.75, 150 ); // original normal
	add_fractional_data_point( "threatbias", 1.0, 165 );
	level.difficultySettings[ "threatbias" ][ "hardened" ] = 200;
	level.difficultySettings[ "threatbias" ][ "veteran" ] = 400;

	 // level.longRegenTime
	 /*
 	redFlashingOverlay() controls how long the overlay flashes, this var controls how long it takes
 	before your health comes back
	 */
	add_fractional_data_point( "longRegenTime", 1.0, 5000 );
	level.difficultySettings[ "longRegenTime" ][ "hardened" ] = 5000;
	level.difficultySettings[ "longRegenTime" ][ "veteran" ] = 5000;

	 // level.healthOverlayCutoff
	add_fractional_data_point( "healthOverlayCutoff", 0.25, 0.01 ); // original easy
	add_fractional_data_point( "healthOverlayCutoff", 0.75, 0.2 ); // original normal
	add_fractional_data_point( "healthOverlayCutoff", 1.0, 0.25 );
	level.difficultySettings[ "healthOverlayCutoff" ][ "hardened" ] = 0.3;
	level.difficultySettings[ "healthOverlayCutoff" ][ "veteran" ] = 0.5;

	// level.healthOverlayCutoff
	add_fractional_data_point( "base_enemy_accuracy", 0.25, 1 ); // original easy
	add_fractional_data_point( "base_enemy_accuracy", 0.75, 1 ); // original normal
	level.difficultySettings[ "base_enemy_accuracy" ][ "hardened" ] = 1.3;
	level.difficultySettings[ "base_enemy_accuracy" ][ "veteran" ] = 1.3;

	// lower numbers = higher accuracy for AI at a distance
	add_fractional_data_point( "accuracyDistScale", 0.25, 1.0 ); // original easy
	add_fractional_data_point( "accuracyDistScale", 0.75, 1.0 ); // original normal
	level.difficultySettings[ "accuracyDistScale" ][ "hardened" ] = 1.0;
	level.difficultySettings[ "accuracyDistScale" ][ "veteran" ]  = 0.5;

	 // level.playerDifficultyHealth
	add_fractional_data_point( "playerDifficultyHealth", 0.0, 550 );
	add_fractional_data_point( "playerDifficultyHealth", 0.25, 475 ); // original easy
	add_fractional_data_point( "playerDifficultyHealth", 0.75, 310 ); // original normal
	add_fractional_data_point( "playerDifficultyHealth", 1.0, 210 );
	level.difficultySettings[ "playerDifficultyHealth" ][ "hardened" ] = 165;
	level.difficultySettings[ "playerDifficultyHealth" ][ "veteran" ] = 115;

	// anim.min_sniper_burst_delay_time
	add_fractional_data_point( "min_sniper_burst_delay_time", 0.0, 3.5 );
	add_fractional_data_point( "min_sniper_burst_delay_time", 0.25, 3.0 ); // original easy
	add_fractional_data_point( "min_sniper_burst_delay_time", 0.75, 2.0 ); // original normal
	add_fractional_data_point( "min_sniper_burst_delay_time", 1.0, 1.80 );
	level.difficultySettings[ "min_sniper_burst_delay_time" ][ "hardened" ] = 1.5;
	level.difficultySettings[ "min_sniper_burst_delay_time" ][ "veteran" ] = 1.1;

	// anim.max_sniper_burst_delay_time
	add_fractional_data_point( "max_sniper_burst_delay_time", 0.0, 4.5 );
	add_fractional_data_point( "max_sniper_burst_delay_time", 0.25, 4.0 ); // original easy
	add_fractional_data_point( "max_sniper_burst_delay_time", 0.75, 3.0 ); // original normal
	add_fractional_data_point( "max_sniper_burst_delay_time", 1.0, 2.5 );
	level.difficultySettings[ "max_sniper_burst_delay_time" ][ "hardened" ] = 2.0;
	level.difficultySettings[ "max_sniper_burst_delay_time" ][ "veteran" ] = 1.5;


	add_fractional_data_point( "dog_health", 0.0, 0.2 );
	add_fractional_data_point( "dog_health", 0.25, 0.25 ); // original easy
	add_fractional_data_point( "dog_health", 0.75, 0.75 ); // original normal
	add_fractional_data_point( "dog_health", 1.0, 0.8 );
	level.difficultySettings[ "dog_health" ][ "hardened" ] = 1.0;
	level.difficultySettings[ "dog_health" ][ "veteran" ] = 1.0;


	add_fractional_data_point( "dog_presstime", 0.25, 415 ); // original easy
	add_fractional_data_point( "dog_presstime", 0.75, 375 ); // original normal
	level.difficultySettings[ "dog_presstime" ][ "hardened" ] = 250;
	level.difficultySettings[ "dog_presstime" ][ "veteran" ] = 225;

	level.difficultySettings[ "dog_hits_before_kill" ][ "easy" ] = 2;
	level.difficultySettings[ "dog_hits_before_kill" ][ "normal" ] = 1;
	level.difficultySettings[ "dog_hits_before_kill" ][ "hardened" ] = 0;
	level.difficultySettings[ "dog_hits_before_kill" ][ "veteran" ] = 0;
	level.difficultySettings_stepFunc_percent[ "dog_hits_before_kill" ] = 0.5;


	// anim.pain_test
	level.difficultySettings[ "pain_test" ][ "easy" ] = ::always_pain;
	level.difficultySettings[ "pain_test" ][ "normal" ] = ::always_pain;
	level.difficultySettings[ "pain_test" ][ "hardened" ] = ::pain_protection;
	level.difficultySettings[ "pain_test" ][ "veteran" ] = ::pain_protection;
	anim.pain_test = level.difficultySettings[ "pain_test"  ][ get_skill_from_index( level.gameskill ) ];

	 // missTime is a number based on the distance from the AI to the player + some baseline
	 // it simulates bad aim as the AI starts shooting, and helps give the player a warning before they get hit.
	 // this is used for auto and semi auto.
	 // missTime = missTimeConstant + distance * missTimeDistanceFactor

	level.difficultySettings[ "missTimeConstant" ][ "easy" ]     = 1.0; // 0.2;// 0.3;
	level.difficultySettings[ "missTimeConstant" ][ "normal" ]   = 0.05;// 0.1;
	level.difficultySettings[ "missTimeConstant" ][ "hardened" ] = 0;// 0.04;
	level.difficultySettings[ "missTimeConstant" ][ "veteran" ]  = 0;// 0.03;
	// determines which misstime constant to use based on difficulty frac. Hard and Vet use their own settings.
	level.difficultySettings_stepFunc_percent[ "missTimeConstant" ] = 0.5;


	level.difficultySettings[ "missTimeDistanceFactor" ][ "easy" ]     = 0.8  / 1000; // 0.4
	level.difficultySettings[ "missTimeDistanceFactor" ][ "normal" ]   = 0.1  / 1000;
	level.difficultySettings[ "missTimeDistanceFactor" ][ "hardened" ] = 0.05 / 1000;
	level.difficultySettings[ "missTimeDistanceFactor" ][ "veteran" ]  = 0;
	// determines which missTimeDistanceFactor to use based on difficulty frac. Hard and Vet use their own settings.
	level.difficultySettings_stepFunc_percent[ "missTimeDistanceFactor" ] = 0.5;

	add_fractional_data_point( "flashbangedInvulFactor", 0.25, 0.25 ); // original easy
	add_fractional_data_point( "flashbangedInvulFactor", 0.75, 0.0 ); // original normal
	level.difficultySettings[ "flashbangedInvulFactor" ][ "easy" ]     = 0.25;
	level.difficultySettings[ "flashbangedInvulFactor" ][ "normal" ]   = 0;
	level.difficultySettings[ "flashbangedInvulFactor" ][ "hardened" ] = 0;
	level.difficultySettings[ "flashbangedInvulFactor" ][ "veteran" ]  = 0;

	// level.invulTime_preShield: time player is invulnerable when hit before their health is low enough for a red overlay( should be very short )
	add_fractional_data_point( "invulTime_preShield", 0.0, 0.7 );
	add_fractional_data_point( "invulTime_preShield", 0.25, 0.6 ); // original easy
	add_fractional_data_point( "invulTime_preShield", 0.75, 0.35 ); // original normal
	add_fractional_data_point( "invulTime_preShield", 1.0, 0.3 );
	level.difficultySettings[ "invulTime_preShield" ][ "hardened" ] = 0.1;
	level.difficultySettings[ "invulTime_preShield" ][ "veteran" ] = 0.0;

	// level.invulTime_onShield: time player is invulnerable when hit the first time they get a red health overlay( should be reasonably long )
	add_fractional_data_point( "invulTime_onShield", 0.0, 1.0 );
	add_fractional_data_point( "invulTime_onShield", 0.25, 0.8 ); // original easy
	add_fractional_data_point( "invulTime_onShield", 0.75, 0.5 ); // original normal
	add_fractional_data_point( "invulTime_onShield", 1.0, 0.3 );
	level.difficultySettings[ "invulTime_onShield"  ][ "hardened" ] = 0.1;
	level.difficultySettings[ "invulTime_onShield"  ][ "veteran" ] = 0.05;

	// level.invulTime_postShield: time player is invulnerable when hit after the red health overlay is already up( should be short )
	add_fractional_data_point( "invulTime_postShield", 0.0, 0.6 );
	add_fractional_data_point( "invulTime_postShield", 0.25, 0.5 ); // original easy
	add_fractional_data_point( "invulTime_postShield", 0.75, 0.3 ); // original normal
	add_fractional_data_point( "invulTime_postShield", 1.0, 0.2 );
	level.difficultySettings[ "invulTime_postShield" ][ "hardened" ] = 0.1;
	level.difficultySettings[ "invulTime_postShield" ][ "veteran" ] = 0.0;

	// level.playerHealth_RegularRegenDelay
	// The delay before you regen health after getting hurt
	add_fractional_data_point( "playerHealth_RegularRegenDelay", 0.0, 3500 );
	add_fractional_data_point( "playerHealth_RegularRegenDelay", 0.25, 3000 ); // original easy
	add_fractional_data_point( "playerHealth_RegularRegenDelay", 0.75, 2400 ); // original normal
	add_fractional_data_point( "playerHealth_RegularRegenDelay", 1.0, 1500 );
	level.difficultySettings[ "playerHealth_RegularRegenDelay" ][ "hardened" ] = 1200;
	level.difficultySettings[ "playerHealth_RegularRegenDelay" ][ "veteran" ] = 1200;

	// level.worthyDamageRatio( player must recieve this much damage as a fraction of maxhealth to get invulTime. )
	add_fractional_data_point( "worthyDamageRatio", 0.25, 0.0 ); // original easy
	add_fractional_data_point( "worthyDamageRatio", 0.75, 0.1 ); // original normal
	level.difficultySettings[ "worthyDamageRatio" ][ "hardened" ] = 0.1;
	level.difficultySettings[ "worthyDamageRatio" ][ "veteran" ] = 0.1;

	// level.explosiveplanttime
	level.difficultySettings[ "explosivePlantTime" ][ "easy" ] = 10;
	level.difficultySettings[ "explosivePlantTime" ][ "normal" ] = 10;
	level.difficultySettings[ "explosivePlantTime" ][ "hardened" ] = 5;
	level.difficultySettings[ "explosivePlantTime" ][ "veteran" ] = 5;
	level.explosiveplanttime = level.difficultySettings[ "explosivePlantTime"  ][ get_skill_from_index( level.gameskill ) ];

	// anim.difficultyBasedAccuracy
	level.difficultySettings[ "difficultyBasedAccuracy" ][ "easy" ] = 1;
	level.difficultySettings[ "difficultyBasedAccuracy" ][ "normal" ] = 1;
	level.difficultySettings[ "difficultyBasedAccuracy" ][ "hardened" ] = 1;
	level.difficultySettings[ "difficultyBasedAccuracy" ][ "veteran" ] = 1.25;
	anim.difficultyBasedAccuracy = getRatio( "difficultyBasedAccuracy", level.gameskill, level.gameskill );

	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "easy" ][0] 		= 1.0;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "easy" ][1] 		= 0.9;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "easy" ][2] 		= 0.8;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "easy" ][3] 		= 0.7;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "normal" ][0] 		= 1.0; // one player
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "normal" ][1] 		= 0.9; // two players
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "normal" ][2] 		= 0.8; // three players
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "normal" ][3] 		= 0.7; // four players
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "hardened" ][0] 	= 1.00;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "hardened" ][1] 	= 0.9;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "hardened" ][2] 	= 0.8;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "hardened" ][3] 	= 0.7;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "veteran" ][0] 		= 1.0;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "veteran" ][1] 		= 0.9;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "veteran" ][2] 		= 0.8;
	level.difficultySettings[ "coopPlayer_deathInvulnerableTime" ][ "veteran" ][3] 		= 0.7;

	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "easy" ][0] = 1.00;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "easy" ][1] = 0.95;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "easy" ][2] = 0.8;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "easy" ][3] = 0.75;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "normal" ][0] = 1.00; // one player
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "normal" ][1] = 0.9; // two players
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "normal" ][2] = 0.8; // three players
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "normal" ][3] = 0.7; // four players
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "hardened" ][0] = 1.00;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "hardened" ][1] = 0.85;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "hardened" ][2] = 0.7;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "hardened" ][3] = 0.65;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "veteran" ][0] = 1.00;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "veteran" ][1] = 0.8;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "veteran" ][2] = 0.6;
	level.difficultySettings[ "coopPlayerDifficultyHealth" ][ "veteran" ][3] = 0.5;

	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "easy" ][0] = 1;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "easy" ][1] = 1.1;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "easy" ][2] = 1.2;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "easy" ][3] = 1.3;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "normal" ][0] = 1; // one player
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "normal" ][1] = 1.1; // two players
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "normal" ][2] = 1.3; // three players
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "normal" ][3] = 1.5; // four players
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "hardened" ][0] = 1.0;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "hardened" ][1] = 1.2;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "hardened" ][2] = 1.4;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "hardened" ][3] = 1.6;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "veteran" ][0] = 1;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "veteran" ][1] = 1.3;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "veteran" ][2] = 1.6;
	level.difficultySettings[ "coopEnemyAccuracyScalar" ][ "veteran" ][3] = 2;

	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "easy" ][0] = 1;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "easy" ][1] = 0.9;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "easy" ][2] = 0.8;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "easy" ][3] = 0.7;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "normal" ][0] = 1; // one player
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "normal" ][1] = 0.8; // two players
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "normal" ][2] = 0.7; // three players
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "normal" ][3] = 0.6; // four players
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "hardened" ][0] = 1;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "hardened" ][1] = 0.7;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "hardened" ][2] = 0.5;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "hardened" ][3] = 0.5;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "veteran" ][0] = 1;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "veteran" ][1] = 0.7;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "veteran" ][2] = 0.5;
	level.difficultySettings[ "coopFriendlyAccuracyScalar" ][ "veteran" ][3] = 0.4;

	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "easy" ][0] = 1;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "easy" ][1] = 1.1;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "easy" ][2] = 1.2;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "easy" ][3] = 1.3;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "normal" ][0] = 1; // one player
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "normal" ][1] = 2; // two players
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "normal" ][2] = 3; // three players
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "normal" ][3] = 4; // four players
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "hardened" ][0] = 1.0;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "hardened" ][1] = 3;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "hardened" ][2] = 6;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "hardened" ][3] = 9;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "veteran" ][0] = 1;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "veteran" ][1] = 10;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "veteran" ][2] = 20;
	level.difficultySettings[ "coopFriendlyThreatBiasScalar" ][ "veteran" ][3] = 30;



	 // lateral accuracy modifier
	level.difficultySettings[ "lateralAccuracyModifier" ][ "easy" ]     = 300;
	level.difficultySettings[ "lateralAccuracyModifier" ][ "normal" ]   = 700;
	level.difficultySettings[ "lateralAccuracyModifier" ][ "hardened" ] = 1000;
	level.difficultySettings[ "lateralAccuracyModifier" ][ "veteran" ]  = 2500;


	// in case there are no enties in the map.
	level.lastPlayerSighted = 0;

	// only easy and normal do adjusting
	difficulty_starting_frac[ "easy" ] = 0.25;
	difficulty_starting_frac[ "normal" ] = 0.75;

	if ( level.gameskill <= 1 )
	{
//		if ( aa_should_start_fresh() )
		{
			// started over so reset difficulty evaluation
			dif_frac = difficulty_starting_frac[ get_skill_from_index( level.gameskill ) ];
			dif_frac = int( dif_frac * 100 );
			setdvar( "autodifficulty_frac", dif_frac );
		}

		set_difficulty_from_current_aa_frac();
	}
	else
	{
		set_difficulty_from_locked_settings();
	}

	setdvar( "autodifficulty_original_setting", level.gameskill );
	if( GetDvar( #"g_gametype" ) != "vs" )
	{
		setsaveddvar( "player_meleeDamageMultiplier", 100 / 250 );
	}


	// Sets lateral accuracy so AI can hit you more as you move around
	//setdvar( "ai_accu_player_lateral_speed", int(getRatio( "lateralAccuracyModifier", level.gameskill, level.gameskill )) );

	// SCRIPTER_MOD: JesseS (6/4/2007): added coop enemy accuracy scalar
	thread coop_enemy_accuracy_scalar_watcher();
	thread coop_friendly_accuracy_scalar_watcher();

	// Makes the coop players get targeted more often
	thread coop_player_threat_bias_adjuster();

	thread coop_spawner_count_adjuster();

	/#
	debug_replay("File: _gameskill.gsc. Function: setSkill() - COMPLETE\n");
	#/

	if ( GetDvar( "zombiemode" ) == "1" )
	{
		level.healthOverlayCutoff = 0.2;
	}
}

get_skill_from_index( index )
{
	return level.difficultyType[ index ];
}

apply_difficulty_frac_with_func( difficulty_func, current_frac )
{
	//prof_begin( "apply_difficulty_frac_with_func" );

	level.invulTime_preShield = [[ difficulty_func ]]( "invulTime_preShield", current_frac );
	level.invulTime_onShield = [[ difficulty_func ]]( "invulTime_onShield", current_frac ) * level.invulTime_onShield_multiplier;
	level.invulTime_postShield = [[ difficulty_func ]]( "invulTime_postShield", current_frac );
	level.playerHealth_RegularRegenDelay = [[ difficulty_func ]]( "playerHealth_RegularRegenDelay", current_frac );
	level.worthyDamageRatio = [[ difficulty_func ]]( "worthyDamageRatio", current_frac );

	if ( level.auto_adjust_threatbias )
	{
		thread apply_threat_bias_to_all_players(difficulty_func, current_frac);
	}

	level.longRegenTime = [[ difficulty_func ]]( "longRegenTime", current_frac );
	level.healthOverlayCutoff = [[ difficulty_func ]]( "healthOverlayCutoff", current_frac );

	anim.player_attacker_accuracy = [[ difficulty_func ]]( "base_enemy_accuracy", current_frac ) * level.player_attacker_accuracy_multiplier;
	level.attackeraccuracy = anim.player_attacker_accuracy;

	anim.playerGrenadeBaseTime = int( [[ difficulty_func ]]( "playerGrenadeBaseTime", current_frac ) );
	anim.playerGrenadeRangeTime = int( [[ difficulty_func ]]( "playerGrenadeRangeTime", current_frac ) );
	anim.playerDoubleGrenadeTime = int( [[ difficulty_func ]]( "playerDoubleGrenadeTime", current_frac ) );

	anim.min_sniper_burst_delay_time = [[ difficulty_func ]]( "min_sniper_burst_delay_time", current_frac );
	anim.max_sniper_burst_delay_time = [[ difficulty_func ]]( "max_sniper_burst_delay_time", current_frac );

	anim.dog_health = [[ difficulty_func ]]( "dog_health", current_frac );
	anim.dog_presstime = [[ difficulty_func ]]( "dog_presstime", current_frac );

	setsaveddvar( "ai_accuracyDistScale", [[ difficulty_func ]]( "accuracyDistScale", current_frac ) );

	thread coop_damage_and_accuracy_scaling(difficulty_func, current_frac);

	level.playerHealth_RegularRegenDelay = 2000;
	level.longRegenTime = 4000;
	level.perk_healthRegenMultiplier = 1.25;

	//prof_end( "apply_difficulty_frac_with_func" );
}




apply_threat_bias_to_all_players(difficulty_func, current_frac)
{
	// waittill the flag is defined, then check for it
	while (!isdefined (level.flag) || !isdefined(level.flag[ "all_players_connected" ]))
	{
		wait 0.05;
		continue;
	}

	flag_wait( "all_players_connected" );

	players = get_players();
	for( i = 0; i < players.size; i++ )
	{
		players[i].threatbias = int( [[ difficulty_func ]]( "threatbias", current_frac ) );
	}
}

coop_damage_and_accuracy_scaling( difficulty_func, current_frac )
{
/#
	debug_replay("File: _gameskill.gsc. Function: coop_damage_and_accuracy_scaling() - 0\n");
#/
	// if it's not set up by now, wait for it
	while (!isdefined (level.flag))
	{
/#
	debug_replay("File: _gameskill.gsc. Function: coop_damage_and_accuracy_scaling() - 1\n");
#/
		wait 0.05;
	}

	while (!isdefined (level.flag["all_players_spawned"]))
	{
/#
	debug_replay("File: _gameskill.gsc. Function: coop_damage_and_accuracy_scaling() - 2\n");
#/
		wait 0.05;
	}

	flag_wait( "all_players_spawned" );
/#
	debug_replay("File: _gameskill.gsc. Function: coop_damage_and_accuracy_scaling() - 3\n");
#/

	players = get_players();
/#
	debug_replay("File: _gameskill.gsc. Function: coop_damage_and_accuracy_scaling()\n");
#/
	coop_healthscalar = getCoopValue( "coopPlayerDifficultyHealth", players.size );

	if( GetDvar( #"g_gametype" ) != "vs" )
	{
		setsaveddvar( "player_damageMultiplier", 100 / ([[ difficulty_func ]]( "playerDifficultyHealth", current_frac ) * coop_healthscalar) );
/#
		debug_replay("File: _gameskill.gsc. Function: coop_damage_and_accuracy_scaling()\n");
#/
		coop_invuln_remover = getCoopValue( "coopPlayer_deathInvulnerableTime", players.size );
		setsaveddvar( "player_deathInvulnerableTime", int( [[ difficulty_func ]]( "player_deathInvulnerableTime", current_frac ) * coop_invuln_remover) );
	}

}

apply_difficulty_step_with_func( difficulty_func, current_frac )
{
	//prof_begin( "apply_difficulty_step_with_func" );

	// sets the value of difficulty settings that can't blend between two
	anim.missTimeConstant = [[ difficulty_func ]]( "missTimeConstant", current_frac );
	anim.missTimeDistanceFactor = [[ difficulty_func ]]( "missTimeDistanceFactor", current_frac );
	anim.dog_hits_before_kill = [[ difficulty_func ]]( "dog_hits_before_kill", current_frac );
	anim.double_grenades_allowed = [[ difficulty_func ]]( "double_grenades_allowed", current_frac );

	//prof_end( "apply_difficulty_step_with_func" );
}

set_difficulty_from_locked_settings()
{
	apply_difficulty_frac_with_func( ::get_locked_difficulty_val, 1 );
	apply_difficulty_step_with_func( ::get_locked_difficulty_step_val, 1 );
}

set_difficulty_from_current_aa_frac()
{
	//prof_begin( "set_difficulty_from_current_aa_frac" );

	 // sets the difficulty to be a degree between two difficulty step values
	level.auto_adjust_difficulty_frac = GetDvarInt( #"autodifficulty_frac" );
	current_frac = level.auto_adjust_difficulty_frac * 0.01;
	assert( level.auto_adjust_difficulty_frac >= 0 );
	assert( level.auto_adjust_difficulty_frac <= 100 );

	apply_difficulty_frac_with_func( ::get_blended_difficulty, current_frac );
	apply_difficulty_step_with_func( ::get_stepped_difficulty, current_frac );

	//prof_end( "set_difficulty_from_current_aa_frac" );
}

get_stepped_difficulty( system, current_frac )
{
	// returns the Normal val if the difficulty is above specified percent
	if ( current_frac >= level.difficultySettings_stepFunc_percent[ system ] )
	{
		return level.difficultySettings[ system ][ "normal" ];
	}

	return level.difficultySettings[ system ][ "easy" ];
}

get_locked_difficulty_step_val( system, ignored )
{
	return level.difficultySettings[ system ][ get_skill_from_index( level.gameskill ) ];
}

get_blended_difficulty( system, current_frac )
{
	//prof_begin( "get_blended_difficulty" );

	// get the value from the available data points
	difficulty_array = level.difficultySettings_frac_data_points[ system ];

	for ( i = 1; i < difficulty_array.size; i++ )
	{
		high_frac = difficulty_array[ i ][ "frac" ];
		high_val = difficulty_array[ i ][ "val" ];

		if ( current_frac <= high_frac )
		{
			low_frac = difficulty_array[ i - 1 ][ "frac" ];
			low_val = difficulty_array[ i - 1 ][ "val" ];

			frac_range = high_frac - low_frac;
			val_range = high_val - low_val;

			base_frac = current_frac - low_frac;

			result_frac = base_frac / frac_range;

			return low_val + result_frac * val_range;

/*
			0.5		10		0.7
			0.75	100

frac_range		0.25
base_frac		0.2

val_range		90
*/
		}
	}

	assertex( difficulty_array.size == 1, "Shouldnt be multiple data points if we're here." );

	return difficulty_array[ 0 ][ "val" ];
}

getCurrentDifficultySetting( msg )
{
	return level.difficultySettings[ msg ][ get_skill_from_index( level.gameskill ) ];
}

getRatio( msg, min, max )
{
	return( level.difficultySettings[ msg ][ level.difficultyType[ min ] ] * ( 100 - GetDvarInt( #"autodifficulty_frac" ) ) + level.difficultySettings[ msg ][ level.difficultyType[ max ] ] * GetDvarInt( #"autodifficulty_frac" ) ) * 0.01;
}


getCoopValue( msg, numplayers )
{
	if (numplayers <= 0)
	{
		numplayers = 1;
	}
//	value = ( level.difficultySettings[ msg ][ GetDvar( #"currentDifficulty" ) ][numplayers - 1]);
	return( level.difficultySettings[ msg ][ GetDvar( #"currentDifficulty" ) ][numplayers - 1]);
}

get_locked_difficulty_val( msg, ignored ) // ignored is there because this is used as a function pointer with another function that does have a second parm
{
	return level.difficultySettings[ msg ][ level.difficultyType[ level.gameskill ] ];
}

always_pain()
{
		return false;
}

pain_protection()
{
	if ( !pain_protection_check() )
	{
		return false;
	}

	return( randomint( 100 ) > 25 );
}

pain_protection_check()
{
	if ( !isalive( self.enemy ) )
	{
		return false;
	}

	if ( !IsPlayer(self.enemy) )
	{
		return false;
	}

	if ( !isalive( level.painAI ) || level.painAI.a.script != "pain" )
	{
		level.painAI = self;
	}

	 // The pain AI can always take pain, so if the player focuses on one guy he'll see pain animations.
	if ( self == level.painAI )
	{
		return false;
	}

	if ( self.damageWeapon != "none" && weaponIsBoltAction( self.damageWeapon ) )
	{
		return false;
	}

	return true;
}

 /#
playerHealthDebug()
{
	debug_replay("File: _gameskill.gsc. Function: playerHealthDebug()\n");

	debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - WAIT FINISHED\n");

	if ( GetDvar( #"scr_health_debug" ) == "" )
	{
		setdvar( "scr_health_debug", "0" );
	}

	waittillframeend; // for init to finish

	while ( 1 )
	{
		debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - INNER LOOP START\n");

		while ( 1 )
		{
			debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - INNER INNER LOOP 1 START\n");

			if ( getdebugdvar( "scr_health_debug" ) != "0" )
			{
				break;
			}
			wait .5;

			debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - INNER INNER LOOP 1 STOP\n");
		}
		thread printHealthDebug();
		while ( 1 )
		{
			debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - INNER INNER LOOP 2 START\n");

			if ( getdebugdvar( "scr_health_debug" ) == "0" )
			{
				break;
			}
			wait .5;

			debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - INNER INNER LOOP 2 STOP\n");
		}
		level notify( "stop_printing_grenade_timers" );
		destroyHealthDebug();

		debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - INNER LOOP STOP\n");
	}

	debug_replay("File: _gameskill.gsc. Function: playerHealthDebug() - COMPLETE\n");
}

printHealthDebug()
{
	level notify( "stop_printing_health_bars" );
	level endon( "stop_printing_health_bars" );

	x = 40;
	y = 40;

	level.healthBarHudElems = [];

	level.healthBarKeys[ 0 ] = "Health";
	level.healthBarKeys[ 1 ] = "No Hit Time";
	level.healthBarKeys[ 2 ] = "No Die Time";

	if ( !isDefined( level.playerInvulTimeEnd ) )
	{
		level.playerInvulTimeEnd = 0;
	}

	if ( !isDefined( level.player_deathInvulnerableTimeout ) )
	{
		level.player_deathInvulnerableTimeout = 0;
	}

	for ( i = 0; i < level.healthBarKeys.size; i++ )
	{
		key = level.healthBarKeys[ i ];

		textelem = newHudElem();
		textelem.x = x;
		textelem.y = y;
		textelem.alignX = "left";
		textelem.alignY = "top";
		textelem.horzAlign = "fullscreen";
		textelem.vertAlign = "fullscreen";
		textelem setText( key );

		bgbar = newHudElem();
		bgbar.x = x + 79;
		bgbar.y = y + 1;
		bgbar.alignX = "left";
		bgbar.alignY = "top";
		bgbar.horzAlign = "fullscreen";
		bgbar.vertAlign = "fullscreen";
		bgbar.maxwidth = 3;
		bgbar setshader( "white", bgbar.maxwidth, 10 );
		bgbar.color = ( 0.5, 0.5, 0.5 );

		bar = newHudElem();
		bar.x = x + 80;
		bar.y = y + 2;
		bar.alignX = "left";
		bar.alignY = "top";
		bar.horzAlign = "fullscreen";
		bar.vertAlign = "fullscreen";
		bar setshader( "black", 1, 8 );

		textelem.bar = bar;
		textelem.bgbar = bgbar;
		textelem.key = key;

		y += 10;

		level.healthBarHudElems[ key ] = textelem;
	}

	flag_wait( "all_players_spawned" );

	while ( 1 )
	{
		wait .05;

		// CODER_MOD - JamesS fix for coop
		players = get_players();

		for ( i = 0; i < level.healthBarKeys.size && players.size > 0; i++ )
		{
			key = level.healthBarKeys[ i ];

			player = players[0];

			width = 0;
			if ( i == 0 )
			{
				width = player.health / player.maxhealth * 300;
			}
			else if ( i == 1 )
			{
				width = ( level.playerInvulTimeEnd - gettime() ) / 1000 * 40;
			}
			else if ( i == 2 )
			{
				width = ( level.player_deathInvulnerableTimeout - gettime() ) / 1000 * 40;
			}

			width = int( max( width, 1 ) );
			width = int( min( width, 300 ) );

			bar = level.healthBarHudElems[ key ].bar;
			bar setShader( "black", width, 8 );

			bgbar = level.healthBarHudElems[ key ].bgbar;
			if( width+2 > bgbar.maxwidth )
			{
				bgbar.maxwidth = width+2;
				bgbar setshader( "white", bgbar.maxwidth, 10 );
				bgbar.color = ( 0.5, 0.5, 0.5 );
			}
		}
	}
}

destroyHealthDebug()
{
	if ( !isdefined( level.healthBarHudElems ) )
	{
		return;
	}
	for ( i = 0; i < level.healthBarKeys.size; i++ )
	{
		level.healthBarHudElems[ level.healthBarKeys[ i ] ].bgbar destroy();
		level.healthBarHudElems[ level.healthBarKeys[ i ] ].bar destroy();
		level.healthBarHudElems[ level.healthBarKeys[ i ] ] destroy();

	}
}
#/


// this is run on each enemy AI.
axisAccuracyControl()
{
	self endon( "long_death" );
	self endon( "death" );

	self coop_axis_accuracy_scaler();
}


// this is run on each friendly AI.
alliesAccuracyControl()
{
	self endon( "long_death" );
	self endon( "death" );

	self coop_allies_accuracy_scaler();
}

/*
alliesAccuracyControl()
{
	self endon( "long_death" );
	self endon( "death" );

// 	self simpleAccuracyControl();
}
*/

set_accuracy_based_on_situation()
{
	if ( self animscripts\combat_utility::isSniper() && isAlive( self.enemy ) )
	{
		self setSniperAccuracy();
		return;
	}

	if ( isPlayer( self.enemy ) )
	{
		resetMissDebounceTime();
		if ( self.a.missTime > gettime() )
		{
			self.accuracy = 0;
			return;
		}

		if ( self.a.script == "move"  )
		{
			self.accuracy = anim.run_accuracy * self.baseAccuracy;
			return;
		}
	}
	else
	{
		if ( self.a.script == "move"  )
		{
			self.accuracy = anim.run_accuracy * self.baseAccuracy;
			return;
		}
	}

	self.accuracy = self.baseAccuracy;
}

setSniperAccuracy()
{
	/*
	// if sniperShotCount isn't defined, a sniper is shooting from some place that's not in normal shoot behavior.
	// that probably means they're doing some sort of blindfire or something that would look stupid for a sniper to do.
	assert( isdefined( self.sniperShotCount ) );
	*/
	if ( !isdefined( self.sniperShotCount ) )
	{
		// snipers get this error if a dog attacks them
		self.sniperShotCount = 0;
		self.sniperHitCount = 0;
	}

	self.sniperShotCount++ ;

	if ( ( !isDefined( self.lastMissedEnemy ) || self.enemy != self.lastMissedEnemy ) && distanceSquared( self.origin, self.enemy.origin ) > 500 * 500 )
	{
		// miss
		self.accuracy = 0;
		if ( level.gameSkill > 0 || self.sniperShotCount > 1 )
		{
			self.lastMissedEnemy = self.enemy;
		}
		return;
	}

	// guarantee a hit unless baseAccuracy is 0
	self.accuracy = ( 1 + 1 * self.sniperHitCount ) * self.baseAccuracy;

	self.sniperHitCount++ ;

	if ( level.gameSkill < 1 && self.sniperHitCount == 1 )
	{
		self.lastMissedEnemy = undefined;// miss again
	}
}

didSomethingOtherThanShooting()
{
	 // make sure the next time resetAccuracyAndPause() is called, we reset our misstime for sure
	self.a.missTimeDebounce = 0;
}

resetMissTime()
{
	//prof_begin( "resetMissTime" );
	if ( self.team != "axis" )
	{
		return;
	}

	if ( self.weapon == "none" )
	{
		return;
	}

	// we don't want bolt actions guys to miss their first shot
	if ( self usingBoltActionWeapon() )
	{
		self.missTime = 0;
		//prof_end( "resetMissTime" );
		return;
	}

	if ( !self animscripts\weaponList::usingAutomaticWeapon() && !self animscripts\weaponList::usingSemiAutoWeapon() )
	{
		self.missTime = 0;
		//prof_end( "resetMissTime" );
		return;
	}

	self.a.nonstopFire = false;

	if ( !isalive( self.enemy ) )
	{
		//prof_end( "resetMissTime" );
		return;
	}

	if ( !IsPlayer(self.enemy) )
	{
		self.accuracy = self.baseAccuracy;
		//prof_end( "resetMissTime" );
		return;
	}

	dist = distance( self.enemy.origin, self.origin );
	self setMissTime( anim.missTimeConstant + dist * anim.missTimeDistanceFactor );
	//prof_end( "resetMissTime" );
}

resetMissDebounceTime()
{
	self.a.missTimeDebounce = gettime() + 3000;
}

setMissTime( howLong )
{
	assertex( self.team == "axis", "Non axis tried to set misstime" );

	 // we can only start missing again if it's been a few seconds since we last shot
	if ( self.a.missTimeDebounce > gettime() )
	{
		return;
	}

	if ( howLong > 0 )
	{
		self.accuracy = 0;
	}

	howLong *= 1000;// convert to milliseconds

	self.a.missTime = gettime() + howLong;
	self.a.accuracyGrowthMultiplier = 1;
//	thread print3d_time( self.origin + (0,0,32 ), "Aiming..", (1,1,0), howLong * 0.001 );
	//thread player_aim_debug();
}

playerHurtcheck()
{
	self.hurtAgain = false;
	for ( ;; )
	{
		self waittill( "damage", amount, attacker, dir, point, mod );

		if(isdefined(attacker) && isplayer(attacker) && attacker.team == self.team)
		{
			continue;
		}

		self.hurtAgain = true;
		self.damagePoint = point;
		self.damageAttacker = attacker;

// MikeD (8/7/2007): New player_burned effect.
		if( IsDefined (mod) && mod == "MOD_BURNED" )
		{
			self setburn( 0.5 );

			if( isdefined( level.zombiemode ) && level.zombiemode == true )
			{
				self playsound( "chr_burn_zombiemode" );
			}
			else
			{
				self PlaySound( "chr_burn" );
			}
		}
	}
}

/*draw_player_health_packets()
{
	packets = [];
	red = ( 1, 0, 0 );
	orange = ( 1, 0.5, 0 );
	green = ( 0, 1, 0 );

	for ( i = 0; i < 3; i++ )
	{
		overlay = newHudElem();
		overlay.x = 5 + 20 * i;
		overlay.y = 20;
		overlay setshader( "white", 16, 16 );
		overlay.alignX = "left";
		overlay.alignY = "top";
		overlay.alpha = 1;
		overlay.color = ( 0, 1, 0 );
		packets[ packets.size ] = overlay;
	}

	for ( ;; )
	{
		level waittill( "update_health_packets" );
		if ( flag( "player_has_red_flashing_overlay" ) )
		{
			packetBase = 1;
			for ( i = 0; i < packetBase; i++ )
			{
				packets[ i ] fadeOverTime( 0.5 );
				packets[ i ].alpha = 1;
				packets[ i ].color = red;
			}

			for ( i = packetBase; i < 3; i++ )
			{
				packets[ i ] fadeOverTime( 0.5 );
				packets[ i ].alpha = 0;
				packets[ i ].color = red;
			}

			flag_waitopen( "player_has_red_flashing_overlay" );
		}

		packetBase = level.player_health_packets;
		if ( packetBase <= 0 )
			packetBase = 0;

		color = red;
		if ( packetBase == 2 )
			color = orange;
		if ( packetBase == 3 )
			color = green;

		for ( i = 0; i < packetBase; i++ )
		{
			packets[ i ] fadeOverTime( 0.5 );
			packets[ i ].alpha = 1;
			packets[ i ].color = color;
		}

		for ( i = packetBase; i < 3; i++ )
		{
			packets[ i ] fadeOverTime( 0.5 );
			packets[ i ].alpha = 0;
			packets[ i ].color = red;
		}
	}
}*/

// SCRIPTER_MOD: dguzzo: 3/20/2009 : need this anymore?
//player_health_packets()
//{
//// MikeD (12/15/2007): Doesn't actually do anything... change_player_health_packets is commented out, that's the only funcion
//// that did something
////	// CODER_MOD
////	// Austin (5/29/07): restore these they were clobbered during the integrate
////	self endon ("death");
////	self endon ("disconnect");
////
//// // 	thread draw_player_health_packets();
////	level.player_health_packets = 3;
////	for( ;; )
////	{
////		// CODER_MOD
////		// Austin (5/29/07): restore these flags as player flags, these changes were clobbered during the integrate
////		self player_flag_wait( "player_has_red_flashing_overlay" );
//// // 		change_player_health_packets( - 1 );
////		self player_flag_waitopen( "player_has_red_flashing_overlay" );
////	}
//}

playerHealthRegen()
{
	self endon ("death");
	self endon ("disconnect");

	if( !IsDefined( self.flag ) )
	{
		self.flag = [];
		self.flags_lock = [];
	}
	if( !IsDefined(self.flag["player_has_red_flashing_overlay"]) )
	{
		self player_flag_init("player_has_red_flashing_overlay");
		self player_flag_init("player_is_invulnerable");
	}
	self player_flag_clear("player_has_red_flashing_overlay");
	self player_flag_clear("player_is_invulnerable");

	self thread increment_take_cover_warnings_on_death();
	self setTakeCoverWarnings();

	self thread healthOverlay();
	oldratio = 1;
	health_add = 0;

	veryHurt = false;
	playerJustGotRedFlashing = false;

	self thread playerBreathingSound(self.maxhealth * 0.2);
	self thread playerHeartbeatSound(self.maxhealth * 0.2);
	self thread endPlayerBreathingSoundOnDeath();

	invulTime = 0;
	hurtTime = 0;
	newHealth = 0;
	lastinvulratio = 1;
	self thread playerHurtcheck();
	if(!IsDefined (self.veryhurt))
	{
		self.veryhurt = 0;
	}

	self.boltHit = false;

	if( GetDvar( #"scr_playerInvulTimeScale" ) == "" )
	{
		setdvar( "scr_playerInvulTimeScale", 1.0 );
	}

	//CODER_MOD: King (6/11/08) - Local copy of this dvar. Calling dvar get is expensive
	playerInvulTimeScale = GetDvarFloat( #"scr_playerInvulTimeScale" );

	for( ;; )
	{
		wait( 0.05 );
		waittillframeend; // if we're on hard, we need to wait until the bolt damage check before we decide what to do

		health_ratio = self.health / self.maxhealth;
		max_health_ratio = self.maxhealth / 100;
		regenRate = 0.05 / max_health_ratio;
		if(self HasPerk("specialty_quickrevive"))
		{
			regenRate *= level.perk_healthRegenMultiplier;
		}

		if( health_ratio > level.healthOverlayCutoff )
		{
			if( self player_flag( "player_has_red_flashing_overlay" ) )
			{
				player_flag_clear( "player_has_red_flashing_overlay" );
				level notify( "take_cover_done" );
			}

			lastinvulratio = 1;
			playerJustGotRedFlashing = false;
			veryHurt = false;
			playerHadMaxHealth = true;

			if(self.health == self.maxhealth)
			{
				oldratio = 1;
				continue;
			}
		}

		if( self.health <= 0 )
		{
			 /#showHitLog();#/
			return;
		}

		wasVeryHurt = veryHurt;

		if( health_ratio <= level.healthOverlayCutoff )
		{
			veryHurt = true;

			if( !wasVeryHurt )
			{
				hurtTime = gettime();

				num1 = 3.6;
				num2 = 2;
				if(self HasPerk("specialty_quickrevive"))
				{
					num1 /= level.perk_healthRegenMultiplier;
					num2 /= level.perk_healthRegenMultiplier;
				}
				self startfadingblur( num1, num2 );

				//self startfadingblur( 3.6, 2 );

				self player_flag_set( "player_has_red_flashing_overlay" );
				playerJustGotRedFlashing = true;
			}
		}

		if( self.hurtAgain )
		{
			hurtTime = gettime();
			self.hurtAgain = false;
		}

		if( health_ratio >= oldratio )
		{
			if( veryHurt )
			{
				self.veryhurt = 1;

				longRegenTime = level.longRegenTime;
				if(self HasPerk("specialty_quickrevive"))
				{
					longRegenTime /= level.perk_healthRegenMultiplier;
				}

				if(gettime() - hurttime < longRegenTime)
				{
					continue;
				}
			}
			else
			{
				playerHealth_RegularRegenDelay = level.playerHealth_RegularRegenDelay;
				if(self HasPerk("specialty_quickrevive"))
				{
					playerHealth_RegularRegenDelay /= level.perk_healthRegenMultiplier;
				}

				if(gettime() - hurttime < playerHealth_RegularRegenDelay)
				{
					continue;
				}
			}

			newHealth = health_ratio;
			newHealth += regenRate;

			if ( newHealth >= 1 )
			{
				reduceTakeCoverWarnings();
			}

			if( newHealth > 1.0 )
			{
				newHealth = 1.0;
			}

			if( newHealth <= 0 )
			{
				 // Player is dead
				return;
			}

			 /#
			if( newHealth > health_ratio )
			{
				logRegen( newHealth );
			}
			#/

			self setnormalhealth( newHealth );

			oldratio = self.health / self.maxHealth;
			continue;
		}
		// if we're here, we have taken damage: health_ratio < oldratio.

		invulWorthyHealthDrop = lastinvulRatio - health_ratio > level.worthyDamageRatio;

		if( self.health <= 1 )
		{
			 // if player's health is <= 1, code's player_deathInvulnerableTime has kicked in and the player won't lose health for a while.
			 // set the health to 2 so we can at least detect when they're getting hit.
			self setnormalhealth( 1 / self.maxHealth );
			invulWorthyHealthDrop = true;
/#
			if ( !isDefined( level.player_deathInvulnerableTimeout ) )
			{
				level.player_deathInvulnerableTimeout = 0;
			}
			if ( level.player_deathInvulnerableTimeout < gettime() )
			{
				level.player_deathInvulnerableTimeout = gettime() + GetDvarInt( #"player_deathInvulnerableTime" );
			}
			#/
		}

		oldratio = self.health / self.maxHealth;

		level notify( "hit_again" );

		health_add = 0;
		hurtTime = gettime();
		self startfadingblur( 3, 0.8 );

		if( !invulWorthyHealthDrop || playerInvulTimeScale <= 0.0 )
		{
			 /#logHit( self.health, 0 );#/
			continue;
		}

		if( self player_flag( "player_is_invulnerable" ) )
			continue;
		self player_flag_set( "player_is_invulnerable" );
		level notify( "player_becoming_invulnerable" ); // because "player_is_invulnerable" notify happens on both set * and * clear

		if( playerJustGotRedFlashing )
		{
			invulTime = level.invulTime_onShield;
			playerJustGotRedFlashing = false;
		}
		else if( veryHurt )
		{
			invulTime = level.invulTime_postShield;
		}
		else
		{
			invulTime = level.invulTime_preShield;
		}

		invulTime *= playerInvulTimeScale;

		 /#logHit( self.health, invulTime );#/
		lastinvulratio = self.health / self.maxHealth;
		self thread playerInvul( invulTime );
	}
}

reduceTakeCoverWarnings()
{
	//prof_begin( "reduceTakeCoverWarnings" );
	players = get_players();

	if ( isdefined( players[0] ) && isAlive( players[0] ) )
	{
		takeCoverWarnings = GetDvarInt( #"takeCoverWarnings" );
		if ( takeCoverWarnings > 0 )
		{
			takeCoverWarnings -- ;
			setdvar( "takeCoverWarnings", takeCoverWarnings );
			 /#DebugTakeCoverWarnings();#/
		}
	}

	//prof_end( "reduceTakeCoverWarnings" );
}

 /#
DebugTakeCoverWarnings()
{
	if ( GetDvar( #"scr_debugtakecover" ) == "" )
	{
		setdvar( "scr_debugtakecover", "0" );
	}
	if ( getdebugdvar( "scr_debugtakecover" ) == "1" )
	{
		iprintln( "Warnings remaining: ", getdebugdvarint( "takeCoverWarnings" ) - 3 );
	}
}
#/

 /#
logHit( newhealth, invulTime )
{
	/* if ( !isdefined( level.hitlog ) )
	{
		level.hitlog = [];
		thread showHitLog();
	}

	data = spawnstruct();
	data.regen = false;
	data.time = gettime();
	data.health = newhealth / self.maxhealth;
	data.invulTime = invulTime;

	level.hitlog[ level.hitlog.size ] = data;*/
}

logRegen( newhealth )
{
	/* if ( !isdefined( level.hitlog ) )
	{
		level.hitlog = [];
		thread showHitLog();
	}

	data = spawnstruct();
	data.regen = true;
	data.time = gettime();
	data.health = newhealth / self.maxhealth;

	level.hitlog[ level.hitlog.size ] = data;*/
}

showHitLog()
{
}
#/

playerInvul( timer )
{
	self endon( "death" );
	self endon( "disconnect" );

	if ( isdefined( self.flashendtime ) && self.flashendtime > gettime() )
	{
		timer = timer * getCurrentDifficultySetting( "flashbangedInvulFactor" );
	}

	if ( timer > 0 )
	{
		self.attackerAccuracy = 0;
		self.ignoreRandomBulletDamage = true;
		/#
		level.playerInvulTimeEnd = gettime() + timer * 1000;
		#/

		wait( timer );
	}

	self.attackerAccuracy = anim.player_attacker_accuracy;
	self.ignoreRandomBulletDamage = false;

	// CODER_MOD
	// Austin (5/29/07): restore these flags as player flags, these changes were clobbered during the integrate
	self player_flag_clear( "player_is_invulnerable" );
}


grenadeAwareness()
{
	if ( self.team == "allies" )
	{
		self.grenadeawareness  = 0.9;
		return;
	}

	if ( self.team == "axis" )
	{
		if ( level.gameSkill >= 2 )
		{
			 // hard and fu
			if ( randomint( 100 ) < 33 )
			{
				self.grenadeawareness = 0.2;
			}
			else
			{
				self.grenadeawareness = 0.5;
			}
		}
		else
		{
			 // normal
			if ( randomint( 100 ) < 33 )
			{
				self.grenadeawareness = 0;
			}
			else
			{
				self.grenadeawareness = 0.2;
			}
		}
	}
}
playerBreathingSound(healthcap)
{
	self endon("end_healthregen");
	self endon( "disconnect" );
 	self endon( "killed_player" );

 	if(!IsDefined (level.player_pain_vox))
	{
		level.player_pain_vox = 0;
	}

	//self.breathingStopTime = -10000;
	wait (2);
	player = self;
	for (;;)
	{
		wait (0.2);
		if (player.health <= 0)
		{
			level.player_pain_vox = 0;
			return;
		}
		// Player still has a lot of health so no breathing sound
		healthcap = self.maxhealth * 0.2;
		if (player.health > healthcap || player maps\_laststand::player_is_in_laststand() || player.sessionstate == "spectator")
		{
			player notify ("end_heartbeat_loop");
			continue;
		}
	//	if ( gettime() > self.breathingStopTime )
	//		continue;
		if (level.player_pain_vox == 0)
 		{
 			player playLocalSound("chr_breathing_hurt");
 			level.player_pain_vox = 1;
 		}
		else
		{
			player playLocalSound("chr_breathing_hurt");
		}
//		player notify ("snd_breathing_hurt");

		wait .545;
		wait (0.1 + randomfloat (0.8));
	}
}
playerHeartbeatSound(healthcap)
{
	//self endon("end_healthregen");
	self endon( "disconnect" );
 	self endon( "killed_player" );

 	level thread heartbeat_init();

	self.breathingStopTime = -10000;
	self.hearbeatwait = .46;
	wait (2);

	for (;;)
	{
		wait .2;
		//if (self.health <= 0)
		//return;

		// Player still has a lot of health so no hearbeat sound and set to default hearbeat wait
		healthcap = self.maxhealth * 0.2;
		if (self.health > healthcap || self.sessionstate == "spectator")
		{
			continue;
		}

		self thread event_heart_beat( "panicked" , 1 );

		level notify ("player_pain");
		//self playloopsound("NULL");
		//self thread playerSndHearbeatOneShots

		self waittill( "end_heartbeat_loop" );
		//self stoploopsound (1);

	  	wait (.2);
		self thread event_heart_beat( "none" , 0 );

		level.player_pain_vox = 0;

	}
}

heartbeat_init()
{
	level.current_heart_waittime = 2;
	level.heart_waittime = 2;
	level.current_breathing_waittime = 4;
	level.breathing_waittime = 4;
	level.emotional_state_system = 0;
}

event_heart_beat( emotion, loudness )
{
	// Emotional State of Player
	// sedated (super slow heartbeat )
	// relaxed ( normal heart beat )
	// stressed (fast heartbeat)

	self.current_emotion = emotion;
	if(!IsDefined(self.last_emotion))
	{
		self.last_emotion = "undefined";
	}

	if(self.emotional_state_system == 0)
	{
		self.emotional_state_system = 1;
		self thread play_heart_beat();
		self thread play_breathing();
	}

	if(!IsDefined (loudness) || (loudness == 0))
	{
		self.loudness = 0;
	}
	else
	{
		self.loudness = loudness;

	}

	switch (emotion)
	{
		case "sedated":
			self.heart_waittime = 3;
			self.breathing_waittime = 4;
			self.last_emotion = "sedated";
			break;

		case "relaxed":
			self.heart_waittime = 2;
			self.breathing_waittime = 4;
			self.last_emotion = "relaxed";
			break;

		case "stressed":
			self.heart_waittime = 0.5;
			self.breathing_waittime = 2;
			self.last_emotion = "stressed";
			break;

		case "panicked":
			self.heart_waittime = 0.3;
			self.breathing_waittime = 1.5;
			self.last_emotion = "panicked";
			break;

		case "none":
			self.last_emotion = "none";
			self notify ("no_more_heartbeat");
			self playlocalsound("vox_breath_scared_stop");
			self.emotional_state_system = 0;
			break;

		default: AssertMsg("Not a Valid Emotional State.  Please switch with sedated, relaxed, happy, stressed, or none");
	}

	self thread heartbeat_state_transitions();  // controls the wait between breaths and beats
}

heartbeat_state_transitions()
{
	self notify("heartbeat_state_transitions");
	self endon("heartbeat_state_transitions");

	/*while (level.current_heart_waittime > level.heart_waittime)
	{
		//iprintlnbold ("current: " + level.current_heart_waittime + "goal: "  + level.heart_waittime);
		level.current_heart_waittime = level.current_heart_waittime - .10;
		wait(.30);

	}*/

	prev_health = self.health;
	self.current_heart_waittime = self.heart_waittime;

	while(self.current_heart_waittime <= 2)
	{
		if(self.health < prev_health)
		{
			self.current_heart_waittime = self.heart_waittime;
		}
		prev_health = self.health;

		self.current_heart_waittime = self.current_heart_waittime + .05;

		wait(.40);
	}
}

play_heart_beat()
{
	self endon ("no_more_heartbeat");
	if(!IsDefined ( self.heart_wait_counter) )
	{
		self.heart_wait_counter = 0;
	}
	while( 1 )
	{
		while( self.heart_wait_counter < self.current_heart_waittime)
		{
			wait(0.1);
			self.heart_wait_counter = self.heart_wait_counter +0.1;
		}

		if (self.loudness == 0)
		{
			self playlocalsound("chr_heart_beat_ingame");
		}
		else
		{
			self playlocalsound("chr_heart_beat_ingame");
		}

		//player PlayRumbleOnEntity("damage_light");
		self.heart_wait_counter = 0;

	}

}

play_breathing()
{
	self endon ("no_more_heartbeat");

	if(!IsDefined ( self.breathing_wait_counter) )
	{
		self.breathing_wait_counter = 0;
	}
	for(;;)
	{
		while( self.breathing_wait_counter < self.current_breathing_waittime )
		{
			wait(0.1);
			self.breathing_wait_counter = self.breathing_wait_counter +0.1;
		}
		self playlocalsound("amb_player_breath_cold");
		self.breathing_wait_counter = 0;
	}
}

//kevin addin special case to stop the heartbeat and breathing when the player has landed after the base jump.
base_jump_heartbeat_stop()
{
	flag_wait( "players_jumped" );
	level thread event_heart_beat( "none" , 0 );
}

endPlayerBreathingSoundOnDeath()
{
	self endon( "disconnect" );

	self waittill_either( "killed_player", "death" );
	setclientsysstate( "levelNotify", "rfo2", self );
}

old_style_health_overlay()
{
	overlay = newClientHudElem( self );
	overlay.x = 0;
	overlay.y = 0;
	overlay setshader( "overlay_low_health", 640, 480 );
	overlay.alignX = "left";
	overlay.alignY = "top";
	overlay.horzAlign = "fullscreen";
	overlay.vertAlign = "fullscreen";
	overlay.alpha = 0;

	wait( 0.05 ); // to give a chance for moscow to init level.strings so it doesnt clear ours
	level.strings[ "take_cover" ] 				 = spawnstruct();
	level.strings[ "take_cover" ].text			 = &"GAME_GET_TO_COVER";

	//self thread compassHealthOverlay();

	// CODER_MOD
	// Austin (4/19/08): fade out the overlay for the 4/21 milestone
	self thread healthOverlay_remove( overlay );

	pulseTime = 0.8;
	for( ;; )
	{
		overlay fadeOverTime( 0.5 );
		overlay.alpha = 0;

		if( self player_flag( "player_has_red_flashing_overlay" ) && (self maps\_laststand::player_is_in_laststand() || self.sessionstate == "spectator") )
		{
			self player_flag_clear( "player_has_red_flashing_overlay" );
			level notify( "take_cover_done" );
		}

		// CODER_MOD
		// Austin (5/29/07): restore these flags as player flags, these changes were clobbered during the integrate
		self player_flag_wait( "player_has_red_flashing_overlay" );

		self redFlashingOverlay( overlay );
	}
}

new_style_health_overlay()
{
	overlay = NewClientHudElem( self );
	overlay.x = 0;
	overlay.y = 0;

	if ( issplitscreen() )
	{
		overlay SetShader( "overlay_low_health_splat", 640, 480 * 2 );

		// offset the blood a little so it looks different for each player
		if ( self == level.players[ 0 ] )
		{
			overlay.y -= 120;
		}
	}
	else
	{
		overlay SetShader( "overlay_low_health_splat", 640, 480 );
	}
	overlay.splatter = true;
	overlay.alignX = "left";
	overlay.alignY = "top";
	overlay.sort = 1;
	overlay.foreground = 0;
	overlay.horzAlign = "fullscreen";
	overlay.vertAlign = "fullscreen";
	overlay.alpha = 0;

	thread healthOverlay_remove( overlay );
//	thread take_cover_warning_loop();

	updateTime = 0.05;
	timeToFadeOut = 0.75;

	while (1)
	{
		wait updateTime;

		if(IsDefined(level.disable_damage_overlay_in_vehicle) && level.disable_damage_overlay_in_vehicle)
		{
			targetDamageAlpha = 0;
		}
		else
		{
			targetDamageAlpha = 1.0 - self.health / self.maxHealth;
		}

		if ( overlay.alpha < targetDamageAlpha ) // took damage since last update
		{
			overlay.alpha = targetDamageAlpha; // pop to alpha.  jarring effect.  nice.
		}
		else if ( ( targetDamageAlpha == 0 ) && ( overlay.alpha != 0 ) ) // full health
		{
			overlay FadeOverTime( timeToFadeOut );
			overlay.alpha = 0;
			// play the breathing better sound
			self playsound ("chr_breathing_better");
		}
	}
}

healthOverlay()
{
	self endon( "disconnect" );
	//self endon( "noHealthOverlay" );
	//self endon ("death");

	if ( GetDvar( #"zombiemode" ) == "1" )
	{
		old_style_health_overlay();
	}
	else
	{
		new_style_health_overlay();
	}
	//self thread compassHealthOverlay();


}

add_hudelm_position_internal( alignY )
{
	//prof_begin( "add_hudelm_position_internal" );

	if ( level.console )
	{
		self.fontScale = 2;
	}
	else
	{
		self.fontScale = 1.6;
	}

	self.x = 0;// 320;
	self.y = -36;// 200;
	self.alignX = "center";

	/* if ( 0 )// if we ever get the chance to localize or find a way to dynamically find how many lines in a string
	{
		if ( isdefined( alignY ) )
			self.alignY = alignY;
		else
			self.alignY = "middle";
	}
	else
	{*/
		self.alignY = "bottom";
	 // }

	self.horzAlign = "center";
	self.vertAlign = "middle";

	if ( !isdefined( self.background ) )
	{
		return;
	}
	self.background.x = 0;// 320;
	self.background.y = -40;// 200;
	self.background.alignX = "center";
	self.background.alignY = "middle";
	self.background.horzAlign = "center";
	self.background.vertAlign = "middle";
	if ( level.console )
	{
		self.background setshader( "popmenu_bg", 650, 52 );
	}
	else
	{
		self.background setshader( "popmenu_bg", 650, 42 );
	}
	self.background.alpha = .5;

	//prof_end( "add_hudelm_position_internal" );
}

create_warning_elem( ender, player )
{
	level.hudelm_unpause_ender = ender;
	level notify( "hud_elem_interupt" );
	hudelem = newHudElem();
	hudelem add_hudelm_position_internal();
	hudelem thread destroy_warning_elem_when_hit_again( player );
	hudelem thread destroy_warning_elem_when_mission_failed( player );
	hudelem setText( &"GAME_GET_TO_COVER" );
	hudelem.fontscale = 2;
	hudelem.alpha = 1;
	hudelem.color = ( 1, 0.9, 0.9 );

	player thread play_hurt_vox();

	return hudelem;
}
play_hurt_vox()
{
	if(IsDefined (self.veryhurt))
	{
		//Randomly plays a "hurt" sound when shot
		if(self.veryhurt == 0)
		{
			if(randomintrange(0,1) == 1)
			{
				self playlocalsound("chr_breathing_hurt_start");
			}
		}
	}

}

waitTillPlayerIsHitAgain()
{
	level endon( "hit_again" );
	self waittill( "damage" );
}


destroy_warning_elem_when_hit_again( player )
{
	self endon( "being_destroyed" );

	player waitTillPlayerIsHitAgain();

	fadeout = ( !isalive( player ) );
	self thread destroy_warning_elem( fadeout );
}

destroy_warning_elem_when_mission_failed( player )
{
	self endon( "being_destroyed" );

	flag_wait( "missionfailed" );

	player thread destroy_warning_elem( true );
}

destroy_warning_elem( fadeout )
{
	self notify( "being_destroyed" );
	self.beingDestroyed = true;

	if ( fadeout )
	{
		self fadeOverTime( 0.5 );
		self.alpha = 0;
		wait 0.5;
	}
	self death_notify_wrapper();
	self destroy();
}

mayChangeCoverWarningAlpha( coverWarning )
{
	if ( !isdefined( coverWarning ) )
	{
		return false;
	}
	if ( isdefined( coverWarning.beingDestroyed ) )
	{
		return false;
	}
	return true;
}

fontScaler( scale, timer )
{
	self endon( "death" );
	scale *= 2;
	dif = scale - self.fontscale;
	self changeFontScaleOverTime( timer );
	self.fontscale += dif;
}

fadeFunc( overlay, coverWarning, severity, mult, hud_scaleOnly )
{
	pulseTime = 0.8;
	scaleMin = 0.5;

	fadeInTime = pulseTime * 0.1;
	stayFullTime = pulseTime * ( .1 + severity * .2 );
	fadeOutHalfTime = pulseTime * ( 0.1 + severity * .1 );
	fadeOutFullTime = pulseTime * 0.3;
	remainingTime = pulseTime - fadeInTime - stayFullTime - fadeOutHalfTime - fadeOutFullTime;
	assert( remainingTime >= -.001 );
	if ( remainingTime < 0 )
	{
		remainingTime = 0;
	}

	halfAlpha = 0.8 + severity * 0.1;
	leastAlpha = 0.5 + severity * 0.3;

	overlay fadeOverTime( fadeInTime );
	overlay.alpha = mult * 1.0;
	if ( mayChangeCoverWarningAlpha( coverWarning ) )
	{
		if ( !hud_scaleOnly )
		{
			coverWarning fadeOverTime( fadeInTime );
			coverWarning.alpha = mult * 1.0;
		}
	}
	if ( isDefined( coverWarning ) )
	{
		coverWarning thread fontScaler( 1.0, fadeInTime );
	}
	wait fadeInTime + stayFullTime;

	overlay fadeOverTime( fadeOutHalfTime );
	overlay.alpha = mult * halfAlpha;
	if ( mayChangeCoverWarningAlpha( coverWarning ) )
	{
		if ( !hud_scaleOnly )
		{
			coverWarning fadeOverTime( fadeOutHalfTime );
			coverWarning.alpha = mult * halfAlpha;
		}
	}

	wait fadeOutHalfTime;

	overlay fadeOverTime( fadeOutFullTime );
	overlay.alpha = mult * leastAlpha;
	if ( mayChangeCoverWarningAlpha( coverWarning ) )
	{
		if ( !hud_scaleOnly )
		{
			coverWarning fadeOverTime( fadeOutFullTime );
			coverWarning.alpha = mult * leastAlpha;
		}
	}
	if ( isDefined( coverWarning ) )
	{
		coverWarning thread fontScaler( 0.9, fadeOutFullTime );
	}
	wait fadeOutFullTime;

	wait remainingTime;
}

shouldShowCoverWarning()
{
	// Glocke: need to disable this for the Makin outro so adding in a level var
	if( IsDefined(level.enable_cover_warning) )
	{
		return level.enable_cover_warning;
	}

	if ( !isAlive( self ) )
	{
		return false;
	}

	if ( level.gameskill > 1 )
	{
		return false;
	}

	if ( level.missionfailed )
	{
		return false;
	}

	if ( !maps\_load_common::map_is_early_in_the_game() )
	{
		return false;
	}

	if ( isSplitScreen() || coopGame() )
	{
		return false;
	}

	// note: takeCoverWarnings is 3 more than the number of warnings left.
	// this lets it stay away for a while unless we die 3 times in a row without taking cover successfully.
	takeCoverWarnings = GetDvarInt( #"takeCoverWarnings" );
	if ( takeCoverWarnings <= 3 )
	{
		return false;
	}

	return true;
}


// &"GAME_GET_TO_COVER";
redFlashingOverlay( overlay )
{
	self endon( "hit_again" );
	self endon( "damage" );
	self endon( "death" );
	self endon( "disconnect" );

	//prof_begin( "redFlashingOverlay" );

	coverWarning = undefined;

	if ( self shouldShowCoverWarning() )
	{
		 // get to cover!
		coverWarning = create_warning_elem( "take_cover_done", self );
		// coverWarning may be destroyed at any time if we fail the mission.
	}

	// if severity isn't very high, the overlay becomes very unnoticeable to the player.
	// keep it high while they haven't regenerated or they'll feel like their health is nearly full and they're safe to step out.

	longRegenTime = level.longRegenTime;
	if(self HasPerk("specialty_quickrevive"))
	{
		longRegenTime /= level.perk_healthRegenMultiplier;
	}

	stopFlashingBadlyTime = gettime() + longRegenTime;

	//stopFlashingBadlyTime = gettime() + level.longRegenTime;

	fadeFunc( overlay, coverWarning,  1,   1, false );
	while ( gettime() < stopFlashingBadlyTime && isalive( self ) )
	{
		fadeFunc( overlay, coverWarning, .9,   1, false );
	}

	if ( isalive( self ) )
	{
		fadeFunc( overlay, coverWarning, .65, 0.8, false );
	}

	if ( mayChangeCoverWarningAlpha( coverWarning ) )
	{
		coverWarning fadeOverTime( 1.0 );
		coverWarning.alpha = 0;
	}

	fadeFunc( overlay, coverWarning,  0, 0.6, true );

	overlay fadeOverTime( 0.5 );
	overlay.alpha = 0;

	// CODER_MOD
	// Austin (5/29/07): restore this flag as a player flag, these changes were clobbered during the integrate
	self player_flag_clear( "player_has_red_flashing_overlay" );

	//self thread play_sound_on_entity( "breathing_better" );

	// MikeD (8/1/2008): Send to CSC that the 'rfo' "red flashing overlay" is getting better and play the better breathing sound
	setclientsysstate( "levelNotify", "rfo3", self );


	//prof_end( "redFlashingOverlay" );

	wait( 0.5 );// for fade out
	self notify( "take_cover_done" );
	self notify( "hit_again" );
}

healthOverlay_remove( overlay )
{
	// this hud element will get cleaned up automatically by the code when the player disconnects
	// so we just need to make sure this thread ends
	self endon ("disconnect");
	// CODER_MOD
	// Austin (5/29/07): restore these they were clobbered during the integrate
	self waittill_any ("noHealthOverlay", "death");

	// CODER_MOD
	// Austin (4/19/08): fade out the overlay for the 4/21 milestone

	//overlay destroy();
	if ( GetDvar( #"zombiemode" ) == "1" )
	{
		overlay fadeOverTime( 3.5 );
		overlay.alpha = 0;
	}
	else
	{
		overlay fadeOverTime( 3.5 );
		overlay.alpha = 0;
	}
}

setTakeCoverWarnings()
{
	 // generates "Get to Cover" x number of times when you first get hurt
	// dvar defaults to - 1

	isPreGameplayLevel = ( level.script == "training" || level.script == "cargoship" || level.script == "coup" );

	if ( GetDvarInt( #"takeCoverWarnings" ) == -1 || isPreGameplayLevel )
	{
		// takeCoverWarnings is 3 more than the number of warnings we want to occur.
		setdvar( "takeCoverWarnings", 3 + 6 );
	}
	 /#DebugTakeCoverWarnings();#/
}

increment_take_cover_warnings_on_death()
{
	// MikeD (7/30/2007): This function is intended only for players.
	if( !IsPlayer( self ) )
	{
		return;
	}

	level notify( "new_cover_on_death_thread" );
	level endon( "new_cover_on_death_thread" );
	self waittill( "death" );

	// CODER_MOD
	// Austin (5/29/07): restore these flags as player flags, these changes were clobbered during the integrate
	// dont increment if player died to grenades, explosion, etc
	if( !(self player_flag( "player_has_red_flashing_overlay" ) ) )
	{
		return;
	}

	if ( level.gameSkill > 1 )
	{
		return;
	}

	warnings = GetDvarInt( #"takeCoverWarnings" );
	if ( warnings < 10 )
	{
		setdvar( "takeCoverWarnings", warnings + 1 );
	}
	 /#DebugTakeCoverWarnings();#/
}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//auto_adjust_difficulty_player_positioner()
//{
//	org = level.player.origin;
//// 	thread debug_message( ".", org, 6 );
//	wait( 5 );
//	if ( autospot_is_close_to_player( org ) )
//		level.autoAdjust_playerSpots[ level.autoAdjust_playerSpots.size ] = org;
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//autospot_is_close_to_player( org )
//{
//	return distanceSquared( level.player.origin, org ) < ( 140 * 140 );
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//auto_adjust_difficulty_player_movement_check()
//{
//	level.autoAdjust_playerSpots = [];
//	self.movedRecently = true;
//	wait( 1 );// for lvl start precaching of debug strings
//
//	for ( ;; )
//	{
//		thread auto_adjust_difficulty_player_positioner();
//		self.movedRecently = true;
//		newSpots = [];
//		start = level.autoAdjust_playerSpots.size - 5;
//		if ( start < 0 )
//			start = 0;
//
//		for ( i = start; i < level.autoAdjust_playerSpots.size;i++ )
//		{
//			if ( !autospot_is_close_to_player( level.autoAdjust_playerSpots[ i ] ) )
//				continue;
//
//			newSpots[ newSpots.size ] = level.autoAdjust_playerSpots[ i ];
//			self.movedRecently = false;
//		 // 	thread debug_message( "!", newSpots[ newSpots.size - 1 ], 1 );
//		}
//
//		level.autoAdjust_playerSpots = newSpots;
//
//		wait( 1 );
//	}
//}


// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//auto_adjust_difficulty_track_player_death()
//{
//	 // reduce the difficulty timer when you die
//	self waittill( "death" );
//	num = GetDvarInt( #"autodifficulty_playerDeathTimer" );
//	num -= 60;
//	setdvar( "autodifficulty_playerDeathTimer", num );
//// 	scriptPrintln( "script_autodifficulty", "Set deathtimer to " + num );
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//auto_adjust_difficulty_track_player_shots()
//{
//	 // reduce the "time spent alive" by the time between shots fired if there has been significant time between shots
//	lastShotTime = gettime();
//	for ( ;; )
//	{
//		if ( self attackButtonPressed() )
//			lastShotTime = gettime();
//
//		level.timeBetweenShots = gettime() - lastShotTime;
//		wait( 0.05 );
//		 /*
//		if ( lastShotTime < 10000 )
//			continue;
//
//		playerDeathTimer = getcvarint( "playerDeathTimer" );
//		playerDeathTimer = int( playerDeathTimer - lastShotTime * 0.001 );
//		setcvar( "playerDeathTimer", playerDeathTimer );
//		 */
//	}
//}


// MikeD (12/15/2007): Not called anywhere
//hud_debug_clear()
//{
//	level.hudNum = 0;
//	if ( isdefined( level.hudDebugNum ) )
//	{
//		for ( i = 0;i < level.hudDebugNum.size;i++ )
//			level.hudDebugNum[ i ] destroy();
//	}
//
//	level.hudDebugNum = [];
//}

hud_debug_add_message( msg )
{
	if ( !isdefined( level.hudMsgShare ) )
	{
		level.hudMsgShare = [];
	}
	if ( !isdefined( level.hudMsgShare[ msg ] ) )
	{
		hud = newHudElem();
		hud.x = level.debugLeft;
		hud.y = level.debugHeight + level.hudNum * 15;
		hud.foreground = 1;
		hud.sort = 100;
		hud.alpha = 1.0;
		hud.alignX = "left";
		hud.horzAlign = "left";
		hud.fontScale = 1.0;
		hud setText( msg );
		level.hudMsgShare[ msg ] = true;
	}
}

hud_debug_add_display( msg, num, isfloat )
{
	hud_debug_add_message( msg );

	num = int( num );
	negative = false;
	if ( num < 0 )
	{
		negative = true;
		num *= -1;
	}

	thousands = 0;
	hundreds = 0;
	tens = 0;
	ones = 0;
	while ( num >= 10000 )
	{
		num -= 10000;
	}

	while ( num >= 1000 )
	{
		num -= 1000;
		thousands++ ;
	}
	while ( num >= 100 )
	{
		num -= 100;
		hundreds++ ;
	}
	while ( num >= 10 )
	{
		num -= 10;
		tens++ ;
	}
	while ( num >= 1 )
	{
		num -= 1;
		ones++ ;
	}

	offset = 0;
	offsetSize = 10;
	if ( thousands > 0 )
	{
		hud_debug_add_num( thousands, offset );
		offset += offsetSize;
		hud_debug_add_num( hundreds, offset );
		offset += offsetSize;
		hud_debug_add_num( tens, offset );
		offset += offsetSize;
		hud_debug_add_num( ones, offset );
		offset += offsetSize;
	}
	else if ( hundreds > 0 || isFloat )
	{
		hud_debug_add_num( hundreds, offset );
		offset += offsetSize;
		hud_debug_add_num( tens, offset );
		offset += offsetSize;
		hud_debug_add_num( ones, offset );
		offset += offsetSize;
	}
	else if ( tens > 0 )
	{
		hud_debug_add_num( tens, offset );
		offset += offsetSize;
		hud_debug_add_num( ones, offset );
		offset += offsetSize;
	}
	else
	{
		hud_debug_add_num( ones, offset );
		offset += offsetSize;
	}

	if ( isFloat )
	{
		decimalHud = newHudElem();
		decimalHud.x = 204.5;
		decimalHud.y = level.debugHeight + level.hudNum * 15;
		decimalHud.foreground = 1;
		decimalHud.sort = 100;
		decimalHud.alpha = 1.0;
		decimalHud.alignX = "left";
		decimalHud.horzAlign = "left";
		decimalHud.fontScale = 1.0;
		decimalHud setText( "." );
		level.hudDebugNum[ level.hudDebugNum.size ] = decimalHud;
	}

	if ( negative )
	{
		negativeHud = newHudElem();
		negativeHud.x = 195.5;
		negativeHud.y = level.debugHeight + level.hudNum * 15;
		negativeHud.foreground = 1;
		negativeHud.sort = 100;
		negativeHud.alpha = 1.0;
		negativeHud.alignX = "left";
		negativeHud.horzAlign = "left";
		negativeHud.fontScale = 1.0;
		negativeHud setText( " - " );
		level.hudDebugNum[ level.hudNum ] = negativeHud;
	}

// 	level.hudDebugNum[ level.hudNum ] = hud;
	level.hudNum++ ;
}

hud_debug_add_num( num, offset )
{
	hud = newHudElem();
	hud.x = 200 + offset * 0.65;
	hud.y = level.debugHeight + level.hudNum * 15;
	hud.foreground = 1;
	hud.sort = 100;
	hud.alpha = 1.0;
	hud.alignX = "left";
	hud.horzAlign = "left";
	hud.fontScale = 1.0;
	hud setText( num + "" );
	level.hudDebugNum[ level.hudDebugNum.size ] = hud;
}

hud_debug_add_second_string( num, offset )
{
	hud = newHudElem();
	hud.x = 200 + offset * 0.65;
	hud.y = level.debugHeight + level.hudNum * 15;
	hud.foreground = 1;
	hud.sort = 100;
	hud.alpha = 1.0;
	hud.alignX = "left";
	hud.horzAlign = "left";
	hud.fontScale = 1.0;
	hud setText( num );
	level.hudDebugNum[ level.hudDebugNum.size ] = hud;
}

aa_init_stats()
{
//	/#
//	if ( GetDvar( #"createfx" ) == "on" )
//		return;
//	if ( GetDvar( #"r_reflectionProbeGenerate" ) == "1" )
//	{
//		return;
//	}
//	#/
//	//prof_begin( "aa_init_stats" );
//
//	level.sp_stat_tracking_func = maps\_gameskill::auto_adjust_new_zone;
//
//	setdvar( "aa_player_kills", "0" );
//	setdvar( "aa_enemy_deaths", "0" );
//	setdvar( "aa_enemy_damage_taken", "0" );
//	setdvar( "aa_player_damage_taken", "0" );
//	setdvar( "aa_player_damage_dealt", "0" );
//	setdvar( "aa_ads_damage_dealt", "0" );
//	setdvar( "aa_time_tracking", "0" );
//	setdvar( "aa_deaths", "0" );
//
//	setdvar( "player_cheated", 0 );
//
//	level.auto_adjust_results = [];
//	flag_set( "auto_adjust_initialized" );
//
//	flag_init( "aa_main_" + level.script );
//	flag_set( "aa_main_" + level.script );
//
//	//prof_end( "aa_init_stats" );
}

//aa_player_init_stats()
//{
//	/#
//	if ( GetDvar( #"createfx" ) == "on" )
//		return;
//	if ( GetDvar( #"r_reflectionProbeGenerate" ) == "1" )
//	{
//		return;
//	}
//	#/
//	//prof_begin( "aa_init_stats" );
//
//	self thread aa_time_tracking();
//	self thread aa_player_health_tracking();
//	self thread aa_player_ads_tracking();
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//aa_time_tracking()
//{
//	/#
//	if ( GetDvar( #"createfx" ) != "" )
//		return;
//	#/
//	waittillframeend; // so level.start_point is defined
//	for ( ;; )
//	{
//		//prof_begin( "aa_time_tracking" );
//
//		aa_add_event_float( "aa_time_tracking", 0.2 );
//		/#
//		if ( IsGodMode( level.player ) || level.start_point != "default" || GetDvar( #"timescale" ) != "1" )
//		{
//			setdvar( "player_cheated", 1 );
//		}
//		#/
//		/*
//		level.sprint_key = getKeyBinding( "+breath_sprint" );
//		sprinting = false;
//		sprinting = command_used( "+sprint" );
//		if ( !sprinting )
//		{
//			sprinting = command_used( "+breath_sprint" );
//		}
//		if ( sprinting )
//		{
//			aa_add_event_float( "aa_sprint_time", 0.2 );
//		}
//		*/
//		wait( 0.2 );
//	}
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//aa_player_ads_tracking()
//{
//	self endon( "death" );
//	self endon( "disconnect" );
//	self.player_ads_time = 0;
//	for ( ;; )
//	{
//		if ( isADS( self ) )
//		{
//			self.player_ads_time = gettime();
//			while ( isADS( self ) )
//			{
//				wait( 0.05 );
//			}
//			continue;
//		}
//		wait( 0.05 );
//	}
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//aa_player_health_tracking()
//{
//	for ( ;; )
//	{
//		self waittill( "damage", amount );
//		aa_add_event( "aa_player_damage_taken", amount );
//		if ( !isalive( self ) )
//		{
//			aa_add_event( "aa_deaths", 1 );
//			return;
//		}
//	}
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//auto_adjust_new_zone( zone )
//{
//
//
//	/#
//	if ( GetDvar( #"createfx" ) == "on" )
//		return;
//	#/
//	if ( !isdefined( level.auto_adjust_flags ) )
//	{
//		level.auto_adjust_flags = [];
//	}
//
//	flag_wait( "auto_adjust_initialized" );
//
//	//prof_begin( "auto_adjust_new_zone" );
//
//	level.auto_adjust_results[ zone ] = [];
//	level.auto_adjust_flags[ zone ] = 0;
//	flag_wait( zone );
//
//	//prof_begin( "auto_adjust_new_zone" );
//
//	// already processing this zone?
//	if ( GetDvar( #"aa_zone" + zone ) == "" )
//	{
//		setdvar( "aa_zone" + zone, "on" );
//		level.auto_adjust_flags[ zone ] = 1;
//		aa_update_flags();
//
//		setdvar( "start_time" + zone, GetDvar( #"aa_time_tracking" ) );
//
//		// measure always
//		setdvar( "starting_player_kills" + zone, GetDvar( #"aa_player_kills" ) );
//		setdvar( "starting_deaths" + zone, GetDvar( #"aa_deaths" ) );
//		setdvar( "starting_ads_damage_dealt" + zone, GetDvar( #"aa_ads_damage_dealt" ) );
//		setdvar( "starting_player_damage_dealt" + zone, GetDvar( #"aa_player_damage_dealt" ) );
//		setdvar( "starting_player_damage_taken" + zone, GetDvar( #"aa_player_damage_taken" ) );
//		setdvar( "starting_enemy_damage_taken" + zone, GetDvar( #"aa_enemy_damage_taken" ) );
//		setdvar( "starting_enemy_deaths" + zone, GetDvar( #"aa_enemy_deaths" ) );
//	}
//	else
//	{
//		if ( GetDvar( #"aa_zone" + zone ) == "done" )
//		{
//			//prof_end( "auto_adjust_new_zone" );
//			return;
//		}
//	}
//
//	//prof_end( "auto_adjust_new_zone" );
//	flag_waitopen( zone );
//	auto_adust_zone_complete( zone );
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//auto_adust_zone_complete( zone )
//{
//	//prof_begin( "auto_adust_zone_complete" );
//
//	setdvar( "aa_zone" + zone, "done" );
//
//	start_time = GetDvarFloat( #"start_time" + zone );
//	starting_player_kills = GetDvarInt( #"starting_player_kills" + zone );
//	starting_enemy_deaths = GetDvarInt( #"aa_enemy_deaths" + zone );
//	starting_enemy_damage_taken = GetDvarInt( #"aa_enemy_damage_taken" + zone );
//	starting_player_damage_taken = GetDvarInt( #"aa_player_damage_taken" + zone );
//	starting_player_damage_dealt = GetDvarInt( #"aa_player_damage_dealt" + zone );
//	starting_ads_damage_dealt = GetDvarInt( #"aa_ads_damage_dealt" + zone );
//	starting_deaths = GetDvarInt( #"aa_deaths" + zone );
//	level.auto_adjust_flags[ zone ] = 0;
//	aa_update_flags();
//
//	total_time = GetDvarFloat( #"aa_time_tracking" ) - start_time;
//	total_player_kills = GetDvarInt( #"aa_player_kills" ) - starting_player_kills;
//	total_enemy_deaths = GetDvarInt( #"aa_enemy_deaths" ) - starting_enemy_deaths;
//
//	player_kill_ratio = 0;
//	if ( total_enemy_deaths > 0 )
//	{
//		player_kill_ratio = total_player_kills / total_enemy_deaths;
//		player_kill_ratio *= 100;
//		player_kill_ratio = int( player_kill_ratio );
//	}
//
//	total_enemy_damage_taken = GetDvarInt( #"aa_enemy_damage_taken" ) - starting_enemy_damage_taken;
//	total_player_damage_dealt = GetDvarInt( #"aa_player_damage_dealt" ) - starting_player_damage_dealt;
//	player_damage_dealt_ratio = 0;
//	player_damage_dealt_per_minute = 0;
//	if ( total_enemy_damage_taken > 0 && total_time > 0 )
//	{
//		player_damage_dealt_ratio = total_player_damage_dealt / total_enemy_damage_taken;
//		player_damage_dealt_ratio *= 100;
//		player_damage_dealt_ratio = int( player_damage_dealt_ratio );
//
//		player_damage_dealt_per_minute = total_player_damage_dealt / total_time;
//		player_damage_dealt_per_minute = player_damage_dealt_per_minute * 60;
//		player_damage_dealt_per_minute = int( player_damage_dealt_per_minute );
//	}
//
//	total_ads_damage_dealt = GetDvarInt( #"aa_ads_damage_dealt" ) - starting_ads_damage_dealt;
//	player_ads_damage_ratio = 0;
//	if ( total_player_damage_dealt > 0 )
//	{
//		player_ads_damage_ratio = total_ads_damage_dealt / total_player_damage_dealt;
//		player_ads_damage_ratio *= 100;
//		player_ads_damage_ratio = int( player_ads_damage_ratio );
//	}
//
//
//	total_player_damage_taken = GetDvarInt( #"aa_player_damage_taken" ) - starting_player_damage_taken;
//
//	player_damage_taken_ratio = 0;
//	if ( total_time > 0 )
//	{
//		player_damage_taken_ratio = total_player_damage_taken / total_time;
//	}
//
//	player_damage_taken_per_minute = player_damage_taken_ratio * 60;
//	player_damage_taken_per_minute = int( player_damage_taken_per_minute );
//
//
//	total_deaths = GetDvarInt( #"aa_deaths" ) - starting_deaths;
//
//	aa_array = [];
//	aa_array[ "player_damage_taken_per_minute" ] = player_damage_taken_per_minute;
//	aa_array[ "player_damage_dealt_per_minute" ] = player_damage_dealt_per_minute;
//	aa_array[ "minutes" ] = total_time / 60;
//	aa_array[ "deaths" ] = total_deaths;
//	aa_array[ "gameskill" ] = level.gameskill;
//
//	level.auto_adjust_results[ zone ] = aa_array;
//
//	msg = "Completed AA sequence: ";
//	/#
//	if ( GetDvar( #"player_cheated" ) == "1" )
//	{
//		msg = "Cheated in AA sequence: ";
//	}
//	#/
//
//	msg += level.script + " / " + zone;
//	keys = getarraykeys( aa_array );
////	array_levelthread( keys, ::aa_print_vals, aa_array );
//
//	for ( i = 0; i < keys.size; i++ )
//	{
//		msg = msg + ", " + keys[ i ] + ": " + aa_array[ keys[ i ] ];
//	}
//
//	logstring( msg );
//	println( "^6" + msg );
//
//	//prof_end( "auto_adust_zone_complete" );
//}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//aa_print_vals( key, aa_array )
//{
//	logstring( key + ": " + aa_array[ key ] );
//	println( "^6" + key + ": " + aa_array[ key ] );
//}

/*
aa_print_vals( key, aa_array, file )
{
	fprintln( file, key + ": " + aa_array[ key ] );
}
*/

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//aa_update_flags()
//{
//}

 //MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
 // SCRIPTER_MOD: JesseS (4/14/2008): Added back in for Arcade mode
aa_add_event( event, amount )
{
	old_amount = getdvarint( event );
	setdvar( event, old_amount + amount );
}

return_false( attacker )
{
	return false;
}

player_attacker( attacker )
{
	if ( [[ level.custom_player_attacker ]]( attacker ) )
	{
		return true;
	}

	if ( IsPlayer(attacker) )
	{
		return true;
	}

	if ( !isdefined( attacker.car_damage_owner_recorder ) )
	{
		return false;
	}

	return attacker player_did_most_damage();
}

player_did_most_damage()
{
	return self.player_damage * 1.75 > self.non_player_damage;
}

empty_kill_func( type, loc, point, attacker, amount )
{

}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
// SCRIPTER_MOD: JesseS (4/14/2008): Needed for arcade mode
auto_adjust_enemy_died( ai, amount, attacker, type, point )
{
	//prof_begin( "auto_adjust_enemy_died" );

	/*
	Not worth effecting the speed of the game for one spot in one map in one mode
	// in case the team got changed.
	if ( self.team != "axis" )
		return;
	if ( isdefined( self.civilian ) )
		return;
	*/

	aa_add_event( "aa_enemy_deaths", 1 );
	if ( !isdefined( attacker ) )
	{
		//prof_end( "auto_adjust_enemy_died" );
		return;
	}

	if ( isDefined( ai ) && isDefined( ai.attackers ) )
	{
		for ( j = 0; j < ai.attackers.size; j++ )
		{
			player = ai.attackers[j];

			if ( !isDefined( player ) )
			{
				continue;
			}

			if ( player == attacker )
			{
				continue;
			}

			// removing coop challenges for now MGORDON
			// maps\_challenges_coop::doMissionCallback( "playerAssist", player );

			if( "0" == GetDvar( #"zombiemode" ) )
			{
				player.assists++;
			}

			// CODER MOD: TOMMY K - 07/30/08
			arcademode_assignpoints( "arcademode_score_assist", player );
		}
		ai.attackers = [];
		ai.attackerData = [];
	}

	if ( !player_attacker( attacker ) )
	{
		//prof_end( "auto_adjust_enemy_died" );
		return;
	}

	//CODER_MOD: TOMMYK
	if( arcadeMode() )
	{
		if( IsDefined( ai ) )
		{
			//Used later to figure out whether AI was stabbed in the back
			ai.anglesOnDeath = ai.angles;
			if ( isdefined( attacker ) )
			{
				attacker.anglesOnKill = attacker getPlayerAngles();
			}
		}

		//Used to check if multiple kills happened with a single bullet or grenade
		if ( attacker.arcademode_bonus["lastKillTime"] == gettime() )
		{
			attacker.arcademode_bonus["uberKillingMachineStreak"]++;
		}
		else
		{
			attacker.arcademode_bonus["uberKillingMachineStreak"] = 1;
		}

		attacker.arcademode_bonus["lastKillTime"] = gettime();
	}

	attacker.kills++;

	damage_location = undefined;
	if( IsDefined( ai ) )
	{
		damage_location	 = ai.damagelocation;

		if( (damage_location == "head" || damage_location == "helmet") && type != "MOD_MELEE" )
		{
			if( !IsDefined( level.zombietron_mode ) )
			{
				attacker.headshots++;
			}
		}
	}

	if( arcadeMode() )
	{
		[[ level.global_kill_func ]]( type, damage_location, point, attacker, ai, attacker.arcademode_bonus["uberKillingMachineStreak"] );
	}
	else
	{
		[[ level.global_kill_func ]]( type, damage_location, point, attacker );
	}


	aa_add_event( "aa_player_kills", 1 );

	//prof_end( "auto_adjust_enemy_died" );
}

// SCRIPTER_MOD: JesseS (4/14/2008): Needed for arcade mode
auto_adjust_enemy_death_detection()
{
	for ( ;; )
	{
		self waittill( "damage", amount, attacker, direction_vec, point, type );
		if ( !isDefined(amount) )
		{
			continue;
		}
		aa_add_event( "aa_enemy_damage_taken", amount );

		if ( !isalive( self ) || self.delayeddeath )
		{
			level auto_adjust_enemy_died( self, amount, attacker, type, point );
			return;
		}

		if ( !player_attacker( attacker ) )
		{
			continue;
		}

		self aa_player_attacks_enemy_with_ads( attacker, amount, type, point );

		if( !isDefined( self ) || !isalive( self ) )
		{
			attacker.kills++;
			return;
		}
	}
}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
//// SCRIPTER_MOD: JesseS (4/14/2008): Needed for arcade mode
aa_player_attacks_enemy_with_ads( player, amount, type, point )
{
	aa_add_event( "aa_player_damage_dealt", amount );
	assertex( GetDvarInt( #"aa_player_damage_dealt" ) > 0 );

	//CODER_MOD: TOMMYK 06/26/2008 - For coop scoreboards
	if ( self.health == self.maxhealth || !isDefined( self.attackers ) )
	{
		self.attackers = [];
		self.attackerData = [];
	}

	if ( !isdefined( self.attackerData[player getEntityNumber()] ) )
	{
		self.attackers[ self.attackers.size ] = player;
		self.attackerData[player getEntityNumber()] = false;
	}

	if ( !isADS(player) )
	{
		// defaults to empty_kill_func, for arcademode
		[[ level.global_damage_func ]]( type, self.damagelocation, point, player, amount );
		return false;
	}

	if ( !bullet_attack( type ) )
	{
		// defaults to empty_kill_func, for arcademode
		[[ level.global_damage_func ]]( type, self.damagelocation, point, player, amount );
		return false;
	}

	// defaults to empty_kill_func, for arcademode
	[[ level.global_damage_func_ads ]]( type, self.damagelocation, point, player, amount );

	// ads only matters for bullet attacks. Otherwise you could throw a grenade then go ads and get a bunch of ads damage
	aa_add_event( "aa_ads_damage_dealt", amount );
	return true;
}

// MikeD (12/15/2007): IW abandoned the auto-adjust feature, however, we can use it for stats?
// SCRIPTER_MOD: JesseS (4/14/2008):  Added back in for Arcade mode
bullet_attack( type )
{
	if ( type == "MOD_PISTOL_BULLET" )
	{
		return true;
	}
	return type == "MOD_RIFLE_BULLET";
}

/*
=============
///ScriptDocBegin
"Name: add_fractional_data_point( <name> , <frac> , <val> )"
"Summary: Adds difficulty setting data for a specific system at a specified fraction. The in game difficulty will be blended between this and the other data points."
"Module: Gameskill"
"MandatoryArg: <name>: The system being adjusted."
"MandatoryArg: <frac>: Which fraction from 0 to 1 that this difficulty value exists at."
"MandatoryArg: <val>: The value that this system should be set at when the difficulty is at the specified frac."
"Example: 	add_fractional_data_point( "playerGrenadeRangeTime", 1.0, 7500 );"
"SPMP: singleplayer"
///ScriptDocEnd
=============
*/
add_fractional_data_point( name, frac, val )
{
	//prof_begin( "add_fractional_data_point" );

	if ( !isdefined( level.difficultySettings_frac_data_points[ name ] ) )
	{
		level.difficultySettings_frac_data_points[ name ] = [];
	}

	array = [];
	array[ "frac" ] = frac;
	array[ "val" ] = val;
	assertex( frac >= 0, "Tried to set a difficulty data point less than 0." );
	assertex( frac <= 1, "Tried to set a difficulty data point greater than 1." );

	level.difficultySettings_frac_data_points[ name ][ level.difficultySettings_frac_data_points[ name ].size ] = array;

	//prof_end( "add_fractional_data_point" );
}

// CODER_MOD - Sumeet - On COD:BO we are supporting skill change in game
update_skill_on_change()
{
	waittillframeend; // for everything to be defined

	for(;;)
	{
		// CODER_MOD -  jmorelli: modification: g_gameskill can go up or down, but the menu option only allows it to go down
		//							the previous version was setting skill to normal after loading a savegame.
		//							Note: the only way to change g_gameskill is still though the ui (lower it in progress, or set it when chosing mission).

		gameskill 			 = GetDvarInt( #"g_gameskill" );
		if( gameskill != level.gameskill )
		{
			setSkill( true, gameskill );
		}

		wait( 1 );
	}
}


// SCRIPTER_MOD: JesseS (6/4/200):  added co-op health scalar
//coop_maxhealth_scalar_watcher()
//{
//	// CODER_MOD: Bryce (05/08/08): Useful output for debugging replay system
//	/#
//	if( getdebugdvar( "replay_debug" ) == "1" )
//		println("File: _gameskill.gsc. Function: coop_maxhealth_scalar_watcher()\n");
//	#/
//
//	level waittill ("load main complete");
//
//	// CODER_MOD: Bryce (05/08/08): Useful output for debugging replay system
//	/#
//	if( getdebugdvar( "replay_debug" ) == "1" )
//		println("File: _gameskill.gsc. Function: coop_maxhealth_scalar_watcher() - LOAD MAIN COMPLETE\n");
//	#/
//
//	if( GetDvarInt( #"coop_difficulty_scaling" ) == 0 )
//		return;
//
//	players_in_game = 0;
//	set_max_health_for_all_players = false;
//
//	while (1)
//	{
//		// CODER_MOD: Bryce (05/08/08): Useful output for debugging replay system
//		/#
//		if( getdebugdvar( "replay_debug" ) == "1" )
//			println("File: _gameskill.gsc. Function: coop_maxhealth_scalar_watcher() - INNER LOOP START\n");
//		#/
//
//		players = get_players();
//
//		if (players_in_game != players.size)
//		{
//			set_max_health_for_all_players = true;
//			players_in_game = players.size;
//		}
//
//		if( set_max_health_for_all_players )
//		{
//			healthscalar = getCoopValue( "coopMaxHealthScalar", players.size );
//
//			for (i = 0; i < players.size; i++)
//			{
//				if( IsDefined(healthscalar) && IsDefined(players[i].starthealth) )
//				{
//					old_maxhealth = players[i].maxhealth;
//					players[i].maxhealth = int(players[i].starthealth * healthscalar);
//					new_health = int( players[i].health * ( players[i].maxhealth / old_maxhealth ) );
//					if (new_health > 0)
//						players[i].health = new_health;
//
//					if (players[i].health > players[i].maxhealth)
//					{
//						players[i].health = players[i].maxhealth;
//					}
//					//println ("players[i].maxhealth = " + players[i].maxhealth + " players[i].health = " + players[i].health);
//				}
//			}
//
//			set_max_health_for_all_players = false;
//		}
//		wait (0.5);
//
//		// CODER_MOD: Bryce (05/08/08): Useful output for debugging replay system
//		/#
//		if( getdebugdvar( "replay_debug" ) == "1" )
//			println("File: _gameskill.gsc. Function: coop_maxhealth_scalar_watcher() - INNER LOOP STOP\n");
//		#/
//	}
//	// CODER_MOD: Bryce (05/08/08): Useful output for debugging replay system
//	/#
//	if( getdebugdvar( "replay_debug" ) == "1" )
//		println("File: _gameskill.gsc. Function: coop_maxhealth_scalar_watcher() - COMPLETE\n");
//	#/
//}

// updated the levelvar to lower or increase enemy accuracy
coop_enemy_accuracy_scalar_watcher()
{
	/#
	debug_replay("File: _gameskill.gsc. Function: coop_enemy_accuracy_scalar_watcher()\n");
	#/

	level waittill ("load main complete");

	/#
	debug_replay("File: _gameskill.gsc. Function: coop_enemy_accuracy_scalar_watcher() - LOAD MAIN COMPLETE\n");
	#/

	if( GetDvarInt( #"coop_difficulty_scaling" ) == 0 )
	{
		return;
	}

	while (1)
	{
		/#
		debug_replay("File: _gameskill.gsc. Function: coop_enemy_accuracy_scalar_watcher() - INNER LOOP START\n");
		#/

		// CODER_MOD : DSL - Only check number of friendlies.

		players = get_players("allies");

		level.coop_enemy_accuracy_scalar = getCoopValue( "coopEnemyAccuracyScalar", players.size  );

		wait (0.5);

		/#
		debug_replay("File: _gameskill.gsc. Function: coop_enemy_accuracy_scalar_watcher() - INNER LOOP STOP\n");
		#/
	}
	// CODER_MOD: Bryce (05/08/08): Useful output for debugging replay system
	/#
	debug_replay("File: _gameskill.gsc. Function: coop_enemy_accuracy_scalar_watcher() - COMPLETE\n");
	#/
}

coop_friendly_accuracy_scalar_watcher()
{
	level waittill ("load main complete");

	if( GetDvarInt( #"coop_difficulty_scaling" ) == 0 )
	{
		return;
	}

	while (1)
	{
		// CODER_MOD : DSL - only use friendly players.

		players = get_players("allies");

/#
	debug_replay("File: _gameskill.gsc. Function: coop_friendly_accuracy_scalar_watcher()\n");
#/
		level.coop_friendly_accuracy_scalar = getCoopValue( "coopFriendlyAccuracyScalar", players.size  );

		wait (0.5);
	}
}


// this gets called everytime an axis spawns in
coop_axis_accuracy_scaler()
{
	self endon ("death");

	/#
	debug_replay("File: _gameskill.gsc. Function: coop_axis_accuracy_scaler()\n");
	#/

	if( GetDvarInt( #"coop_difficulty_scaling" ) == 0 )
	{
		return;
	}

	// use the GDT value as the starting point
	initialValue = self.baseAccuracy;

	while (1)
	{
		// MikeD (6/25/2008): Since animscripts call this before the level var is even setup, we need to exit out until it is set.
		if( !IsDefined( level.coop_enemy_accuracy_scalar ) )
		{
			wait 0.5;
			continue;
		}

		self.baseAccuracy = initialValue * level.coop_enemy_accuracy_scalar;

		//level waittill ("player_disconnected");
		wait randomfloatrange(3,5);
	}
	//println("enemyacc = " + self.accuracy);

	/#
	debug_replay("File: _gameskill.gsc. Function: coop_axis_accuracy_scaler() - COMPLETE\n");
	#/
}


// this gets called everytime an axis spawns in
coop_allies_accuracy_scaler()
{
	self endon ("death");

	if( GetDvarInt( #"coop_difficulty_scaling" ) == 0 )
	{
		return;
	}

	// use the GDT value as the starting point
	initialValue = self.baseAccuracy;

	while (1)
	{
		// MikeD (6/25/2008): Since animscripts call this before the level var is even setup, we need to exit out until it is set.
		if( !IsDefined( level.coop_friendly_accuracy_scalar ) )
		{
			wait 0.5;
			continue;
		}

		self.baseAccuracy = initialValue * level.coop_friendly_accuracy_scalar;

		//level waittill ("player_disconnected");
		wait randomfloatrange(3,5);
	}
}

// to make the enemies shoot at players more often
coop_player_threat_bias_adjuster()
{
	while (1)
	{
		// we don't need to do this all the time, only if players drop out
		wait 5;

		// CODER_MOD : DSL - no ber3b on this project...

		// ber3b is artifically harder
/*		if (isdefined(level.script) && level.script == "ber3b")
		{
			return;
		} */

		if ( level.auto_adjust_threatbias )
		{
			// grab the friendly players

			// CODER_MOD : DSL - only figure in number of friendly players...

			players = get_players("allies");

			// the usual threat bias times some scalar
			for( i = 0; i < players.size; i++ )
			{
				// adjust according to the setup system
				enable_auto_adjust_threatbias(players[i]);
			}
		}
	}

}

// increases the count on certain spawners for co-op only
coop_spawner_count_adjuster()
{
	// waittill the flag is defined, then check for it
	while (!isdefined (level.flag) || !isdefined(level.flag[ "all_players_connected" ]))
	{
		wait 0.05;
		continue;
	}

	flag_wait( "all_players_connected" );

	spawners = GetSpawnerArray();

	// CODER_MOD : DSL - Only use friendly players

	players = get_players("allies");

	// for now, we only look for flood_spawners
	for (i = 0; i < spawners.size; i++)
	{
		if (isdefined(spawners[i].targetname))
		{
			possible_trig = getentarray(spawners[i].targetname, "target");

			// only check the first trig in case somone messed up their trigger ents
			if (isdefined(possible_trig[0]))
			{
				if (isdefined(possible_trig[0].targetname))
				{
					if (possible_trig[0].targetname == "flood_spawner")
					{
						spawners[i] coop_set_spawner_adjustment_values(players.size);
					}
				}
			}
		}
	}
}

coop_set_spawner_adjustment_values( player_count )
{
	if (!isdefined(self.count))
	{
		return;
	}

	if (isdefined(self.script_count_lock) && self.script_count_lock)
	{
		return;
	}

	if (player_count <= 1)
	{
		return;
	}
	else if (player_count == 2)
	{
		self.count = self.count + int(self.count * 0.75);
	}
	else if (player_count == 3)
	{
		self.count = self.count + int(self.count * 1.5);
	}
	else if (player_count == 4)
	{
		self.count = self.count + int(self.count * 2.5);
	}
	else
	{
		println("You've performed magic, sir.");
	}

}
