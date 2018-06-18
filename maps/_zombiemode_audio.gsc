#include maps\_utility; 
#include common_scripts\utility;
#include maps\_zombiemode_utility; 
#include maps\_music; 
#include maps\_busing;

audio_init()
{
	level init_audio_aliases();
	level init_music_states();
	level thread init_audio_functions();
}

//All Vox should be found in this section.
//If there is an Alias that needs to be changed, check here first.
init_audio_aliases()
{
	//**Announcer Vox Categories**\\
		//ARRAY and PREFIX: Setting up a prefix and array for all Devil lines
		level.devil_vox													=		[];
		level.devil_vox["prefix"]										=		"zmb_vox_ann_";
		
		//POWERUPS: Play after a player picks up a powerup; plays for ALL players
		level.devil_vox["powerup"]										=		[];
		level.devil_vox["powerup"]["carpenter"]							=		"carpenter";
		level.devil_vox["powerup"]["insta_kill"]						=		"instakill";
		level.devil_vox["powerup"]["double_points"]						=		"doublepoints";
		level.devil_vox["powerup"]["nuke"]								=		"nuke";
		level.devil_vox["powerup"]["full_ammo"]							=		"maxammo";
		level.devil_vox["powerup"]["fire_sale"]							=		"firesale";
		level.devil_vox["powerup"]["fire_sale_short"]					=		"firesale_short";
		level.devil_vox["powerup"]["minigun"]						    =		"death_machine";
		level.devil_vox["powerup"]["bonfire_sale"]						=		"bonfiresale";
		level.devil_vox["powerup"]["all_revive"]						=		undefined;
		level.devil_vox["powerup"]["tesla"]						        =		"tesla";
		level.devil_vox["powerup"]["random_weapon"]						=		"random_weapon";
		level.devil_vox["powerup"]["bonus_points_player"]				=		"points_positive";
		level.devil_vox["powerup"]["bonus_points_team"]					=		"points_positive";
		level.devil_vox["powerup"]["lose_points_team"]					=		"points_negative";
		level.devil_vox["powerup"]["lose_perk"]							=		"powerup_negative";
		level.devil_vox["powerup"]["empty_clip"]						=		"powerup_negative";
	
	//**Player Zombie Vox Categories**\\
		//ARRAY and PREFIX: Creating the main player vox array, setting up the default alias prefix that will be added onto all lines
		level.plr_vox 											        =		[];
		level.plr_vox["prefix"]							                =		"vox_plr_";
		
		//GENERAL: Any lines that do not fit into an overall larger category.
		level.plr_vox["general"]										=		[];
		level.plr_vox["general"]["crawl_spawn"]							=		"spawn_crawl";		    //OCCURS WHEN THE PLAYER SHOOTS THE LEGS OFF A ZOMBIE, CREATING A CRAWLER
		level.plr_vox["general"]["crawl_spawn_response"]				=		"resp_spawn_crawl";		//RESPONSE TO ABOVE
		level.plr_vox["general"]["dog_spawn"]							=		"spawn_dog";			//OCCURS AT THE BEGINNING OF A DOG ROUND
		level.plr_vox["general"]["dog_spawn_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["quad_spawn"]							=		"spawn_quad";			//OCCURS WHEN QUADS FIRST SPAWN THROUGH THE ROOF
		level.plr_vox["general"]["quad_spawn_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["ammo_low"]							=		"ammo_low";				//OCCURS WHEN THE PLAYERS AMMO IN A WEAPON IS BELOW 5
		level.plr_vox["general"]["ammo_low_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["ammo_out"]							=		"ammo_out";				//OCCURS WHEN THE PLAYER HAS NO MORE AMMO FOR A WEAPON
		level.plr_vox["general"]["ammo_out_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["door_deny"]							=		"nomoney";				//CURRENTLY UNUSED: INTENDED FOR LOCKED, POWER-DRIVEN DOORS
		level.plr_vox["general"]["door_deny_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["perk_deny"]							=		"nomoney";				//OCCURS WHEN THE PLAYER CANNOT AFFORD A PERK OR ALREADY HAS THE PERK
		level.plr_vox["general"]["perk_deny_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["intro"]								=		"level_start";		    //CURRENTLY UNUSED: INTENDED AS THE FIRST LINE WHEN THE GAME BEGINS
		level.plr_vox["general"]["intro_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["shoot_arm"]							=		"shoot_limb";			//OCCURS WHEN THE PLAYER SHOOTS OFF AN ARM
		level.plr_vox["general"]["shoot_arm_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["box_move"]							=		"box_move";				//OCCURS WHEN THE PLAYER CAUSES THE MAGIC BOX TO CHANGE POSITION
		level.plr_vox["general"]["box_move_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["no_money"]							=		"nomoney";	    //OCCURS WHEN THE PLAYER HAS NO MONEY AND TRIES TO BUY A WEAPON
		level.plr_vox["general"]["no_money_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["oh_shit"]								=		"ohshit";				//OCCURS WHEN 4 OR MORE ZOMBIES ARE WITHIN 250 UNITS OF THE PLAYER
		level.plr_vox["general"]["oh_shit_response"]					=		"resp_ohshit";			//RESPONSE TO ABOVE
		level.plr_vox["general"]["revive_down"]							=		"revive_down";		    //OCCURS WHEN THE PLAYER GOES INTO LAST STAND
		level.plr_vox["general"]["revive_down_response"]				=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["revive_up"]						    =		"revive_up";			//OCCURS WHEN THE PLAYER REVIVES A TEAMMATE
		level.plr_vox["general"]["revive_up_response"]			        =		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["crawl_hit"]							=		"crawler_hit";		    //OCCURS WHEN THE PLAYER IS HIT BY A CRAWLER
		level.plr_vox["general"]["crawl_hit_response"]				    =		undefined;		        //RESPONSE TO ABOVE
		//Added for Cosmodrome (Ascension)
		level.plr_vox["general"]["teleport_gersh"]						=		"teleport_gersh_device";//OCCURS WHEN THE PLAYER TELEPORTS THROUGH THE GERSH DEVICE
		level.plr_vox["general"]["teleport_gersh_response"]				=		undefined;              //RESPONSE TO ABOVE
		level.plr_vox["general"]["monkey_spawn"]						=		"monkey_start";			//OCCURS AT THE BEGINNING OF A MONKEY ROUND
		level.plr_vox["general"]["monkey_spawn_response"]				=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["general"]["monkey_hit"]							=		"space_monkey_hit";		    //OCCURS WHEN THE PLAYER IS HIT BY A CRAWLER
		level.plr_vox["general"]["monkey_hit_response"]				    =		undefined;		        //RESPONSE TO ABOVE
		level.plr_vox["general"]["sigh"]                                =       "sigh";
		level.plr_vox["general"]["sigh_response"]                       =       undefined;
		//Added for Coast (Call of the Dead)
		level.plr_vox["general"]["zipline"]                             =       "zipline";
		level.plr_vox["general"]["zipline_response"]                    =       undefined;
		level.plr_vox["general"]["water_damage"]                        =       "damage_water";
		level.plr_vox["general"]["water_damage_response"]               =       undefined;
		level.plr_vox["general"]["turret_active"]                       =       "turret_active";
		level.plr_vox["general"]["turret_active_response"]              =       undefined;
		level.plr_vox["general"]["turret_inactive"]                     =       "turret_inactive";
		level.plr_vox["general"]["turret_inactive_response"]            =       undefined;
		level.plr_vox["general"]["yes"]                                 =       "yes";
		level.plr_vox["general"]["yes_response"]                        =       undefined;
		level.plr_vox["general"]["no"]                                  =       "no";
		level.plr_vox["general"]["no_response"]                         =       undefined;
		level.plr_vox["general"]["uncertain"]                           =       "uncertain";
		level.plr_vox["general"]["uncertain_response"]                  =       undefined;
		level.plr_vox["general"]["hitmed"]                              =       "gen_hitmed";
		level.plr_vox["general"]["hitmed_response"]                     =       undefined;
		level.plr_vox["general"]["hitlrg"]                              =       "gen_hitlrg";
		level.plr_vox["general"]["hitlrg_response"]                     =       undefined;
		level.plr_vox["catapult"]										=		[];
		level.plr_vox["catapult"]["zombie"]                             =       "catapult_zmb";
		level.plr_vox["catapult"]["zombie_response"]                    =       undefined;
		level.plr_vox["catapult"]["ally"]                               =       "catapult_ally";
		level.plr_vox["catapult"]["ally_response"]                      =       undefined;
		level.plr_vox["catapult"]["rival"]                              =       "catapult_rival";
		level.plr_vox["catapult"]["rival_response"]                     =       undefined;
		level.plr_vox["catapult"]["self"]                               =       "catapult_self";
		level.plr_vox["catapult"]["self_response"]                      =       undefined;
		level.plr_vox["general"]["weather_good"]                        =       "weather_good";
		level.plr_vox["general"]["weather_good_response"]               =       undefined;
		level.plr_vox["general"]["weather_bad"]                         =       "weather_bad";
		level.plr_vox["general"]["weather_bad_response"]                =       undefined;
		level.plr_vox["director"]                                       =       [];
		level.plr_vox["director"]["anger"]                              =       "director_anger";
		level.plr_vox["director"]["anger_response"]                     =       undefined;
		level.plr_vox["director"]["weaken"]                             =       "director_weaken";
		level.plr_vox["director"]["weaken_response"]                    =       undefined;
		level.plr_vox["director"]["water"]                              =       "director_water";
		level.plr_vox["director"]["water_response"]                     =       undefined;
		level.plr_vox["director"]["exit"]                               =       "director_exit";
		level.plr_vox["director"]["exit_response"]                      =       undefined;
		level.plr_vox["general"]["round_5"]                             =       "round_5";
		level.plr_vox["general"]["round_5_response"]                    =       undefined;
		level.plr_vox["general"]["round_20"]                            =       "round_20";
		level.plr_vox["general"]["round_20_response"]                   =       undefined;
		level.plr_vox["general"]["round_10"]                            =       "round_10";
		level.plr_vox["general"]["round_10_response"]                   =       undefined;
		level.plr_vox["general"]["round_35"]                            =       "round_35";
		level.plr_vox["general"]["round_35_response"]                   =       undefined;
		level.plr_vox["general"]["round_50"]                            =       "round_50";
		level.plr_vox["general"]["round_50_response"]                   =       undefined;
		level.plr_vox["general"]["water_frozen"]                        =       "damage_frozen";
		level.plr_vox["general"]["water_frozen_response"]               =       undefined;
		level.plr_vox["general"]["react_sparkers"]                      =       "react_sparkers";
		level.plr_vox["general"]["react_sparkers_response"]             =       undefined;
		level.plr_vox["general"]["damage_shocked"]                      =       "damage_shocked";
		level.plr_vox["general"]["damage_shocked_response"]             =       undefined;
		level.plr_vox["general"]["react_sprinters"]                     =       "react_sprinters";
		level.plr_vox["general"]["react_sprinters_response"]            =       undefined;
		//Added for Temple (Shangri-La)
		level.plr_vox["general"]["location_maze"]                     	=       "location_maze";
		level.plr_vox["general"]["location_maze_response"]            	=       undefined;
		level.plr_vox["general"]["location_waterfall"]                  =       "location_waterfall";
		level.plr_vox["general"]["location_waterfall_response"]         =       undefined;
		level.plr_vox["general"]["mine_see"]                 	 		=       "mine_see";
		level.plr_vox["general"]["mine_see_response"]         			=       undefined;
		level.plr_vox["general"]["mine_ride"]                 	 		=       "mine_ride";	//Working
		level.plr_vox["general"]["mine_ride_response"]         			=       undefined;		
		level.plr_vox["general"]["spikes_close"]                 	 	=       "spikes_close";	//Working
		level.plr_vox["general"]["spikes_close_response"]         		=       undefined;		
		level.plr_vox["general"]["spikes_damage"]                 	 	=       "spikes_dmg";	//Working
		level.plr_vox["general"]["spikes_damage_response"]         		=       undefined;
		level.plr_vox["general"]["geyser"]                 	 			=       "geyser";		//working
		level.plr_vox["general"]["geyser_response"]         			=       undefined;
		level.plr_vox["general"]["slide"]                 	 			=       "slide";		//working
		level.plr_vox["general"]["slide_response"]         				=       undefined;
//		level.plr_vox["general"]["meteor_see"]                 	 		=       "meteor_see";
//		level.plr_vox["general"]["meteor_see_response"]         		=       undefined;
		level.plr_vox["general"]["poweron"]                 	 		=       "power_on";		//working
		level.plr_vox["general"]["poweron_response"]         			=       undefined;
		level.plr_vox["general"]["sonic_spawn"]                 	 	=       "sonic_spawn";	//working
		level.plr_vox["general"]["sonic_spawn_response"]         		=       undefined;
		level.plr_vox["general"]["sonic_hit"]                 	 		=       "sonic_dmg";	//working
		level.plr_vox["general"]["sonic_hit_response"]         			=       undefined;
		level.plr_vox["general"]["napalm_spawn"]                 	 	=       "napalm_spawn";	//working
		level.plr_vox["general"]["napalm_spawn_response"]         		=       undefined;
		level.plr_vox["general"]["thief_steal"]                 	 	=       "thief_steal";	//working
		level.plr_vox["general"]["thief_steal_response"]         		=       undefined;
		level.plr_vox["general"]["start"]								=		"start";
		level.plr_vox["general"]["start_response"]						=		undefined;
		
		//PERKS: Play whenever a player buys a perk.
		level.plr_vox["perk"]											=		[];
		level.plr_vox["perk"]["specialty_armorvest"]			        =		"perk_jugga";			//JUGGERNOG PURCHASE
		level.plr_vox["perk"]["specialty_armorvest_response"]	        =		undefined;				//JUGGERNOG PURCHASE RESPONSE
		level.plr_vox["perk"]["specialty_quickrevive"]			        =		"perk_revive";		    //REVIVE SODA PURCHASE
		level.plr_vox["perk"]["specialty_quickrevive_response"]	        =		undefined;				//REVIVE SODA PURCHASE RESPONSE
		level.plr_vox["perk"]["specialty_fastreload"]			        =		"perk_speed";			//SPEED COLA PURCHASE
		level.plr_vox["perk"]["specialty_fastreload_response"]	        =		undefined;				//SPEED COLA PURCHASE RESPONSE
		level.plr_vox["perk"]["specialty_rof"]					        =		"perk_doubletap";	    //DOUBLETAP ROOTBEER PURCHASE
		level.plr_vox["perk"]["specialty_rof_response"]			        =		undefined;				//DOUBLETAP ROOTBEER PURCHASE RESPONSE
		level.plr_vox["perk"]["specialty_longersprint"]					=		"perk_stamin";	        //MARATHON PURCHASE
		level.plr_vox["perk"]["specialty_longersprint_response"]		=		undefined;				//MARATHON PURCHASE RESPONSE
		level.plr_vox["perk"]["specialty_flakjacket"]					=		"perk_phdflopper";	    //DIVETONUKE PURCHASE
		level.plr_vox["perk"]["specialty_flakjacket_response"]			=		undefined;				//DIVETONUKE PURCHASE RESPONSE
		level.plr_vox["perk"]["specialty_deadshot"]					    =		"perk_deadshot";	    //DEADSHOT PURCHASE
		level.plr_vox["perk"]["specialty_deadshot_response"]			=		undefined;
		//STEAL PERKS: Plays when a monkey starts stealing a perk
		level.plr_vox["perk"]["steal_specialty_armorvest"]				=		"perk_steal_jugga";
		level.plr_vox["perk"]["steal_specialty_armorvest_response"]		=		undefined;
		level.plr_vox["perk"]["steal_specialty_quickrevive"]			=		"perk_steal_revive";
		level.plr_vox["perk"]["steal_specialty_quickrevive_response"]	=		undefined;
		level.plr_vox["perk"]["steal_specialty_fastreload"]			    =		"perk_steal_speed";
		level.plr_vox["perk"]["steal_specialty_fastreload_response"]	=		undefined;
		level.plr_vox["perk"]["steal_specialty_longersprint"]			=		"perk_steal_stamin";
		level.plr_vox["perk"]["steal_specialty_longersprint_response"]	=		undefined;
		level.plr_vox["perk"]["steal_specialty_flakjacket"]			    =		"perk_steal_prone";
		level.plr_vox["perk"]["steal_specialty_flakjacket_response"]	=		undefined;
		
		//POWERUPS: Play whenever a player picks up a powerup
		level.plr_vox["powerup"]										=		[];
		level.plr_vox["powerup"]["nuke"]								=		"powerup_nuke";		    //NUKE PICKUP
		level.plr_vox["powerup"]["nuke_response"]						=		undefined;				//NUKE PICKUP RESPONSE
		level.plr_vox["powerup"]["insta_kill"]							=		"powerup_insta";	    //INSTA-KILL PICKUP
		level.plr_vox["powerup"]["insta_kill_response"]					=		undefined;				//INSTA-KILL PICKUP RESPONSE
		level.plr_vox["powerup"]["full_ammo"]							=		"powerup_ammo";		    //MAX AMMO PICKUP
		level.plr_vox["powerup"]["full_ammo_response"]					=		undefined;				//MAX AMMO PICKUP RESPONSE
		level.plr_vox["powerup"]["double_points"]						=		"powerup_double";	    //DOUBLE POINTS PICKUP
		level.plr_vox["powerup"]["double_points_response"]				=		undefined;				//DOUBLE POINTS PICKUP RESPONSE
		level.plr_vox["powerup"]["carpenter"]							=		"powerup_carp";		    //CARPENTER PICKUP
		level.plr_vox["powerup"]["carpenter_response"]					=		undefined;				//CARPENTER RESPONSE
		level.plr_vox["powerup"]["firesale"]							=		"powerup_firesale";	    //FIRESALE PICKUP
		level.plr_vox["powerup"]["firesale_response"]					=		undefined;				//FIRESALE RESPONSE
		level.plr_vox["powerup"]["minigun"]							    =		"powerup_minigun";	    //MINIGUN PICKUP
		level.plr_vox["powerup"]["minigun_response"]					=		undefined;
		
		//WEAPON KILLS: Plays whenever certain Kill Criteria are met
		level.plr_vox["kill"]											=		[];
		level.plr_vox["kill"]["melee"]									=		"kill_melee";			//PLAYER KILLS A ZOMBIE USING MELEE
		level.plr_vox["kill"]["melee_response"]							=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["melee_instakill"]						=		"kill_insta";		    //PLAYER KILLS A ZOMBIE USING MELEE WHILE INSTAKILL IS ACTIVE
		level.plr_vox["kill"]["melee_instakill_response"]				=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["weapon_instakill"]						=		"kill_insta";			//PLAYER KILLS A ZOMBIE USING ANY WEAPON WHILE INSTAKILL IS ACTIVE
		level.plr_vox["kill"]["weapon_instakill_response"]				=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["closekill"]								=		"kill_close";			//PLAYER KILLS A ZOMBIE WHO IS WITHIN 64 UNITS OF THE PLAYER
		level.plr_vox["kill"]["closekill_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["damage"]									=		"kill_damaged";			//WHEN THE PLAYER KILLS A ZOMBIE AFTER RECEIVING DAMAGE FROM SAID ZOMBIE
		level.plr_vox["kill"]["damage_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["streak"]							        =		"kill_streak";			//OCCURS WHEN THE PLAYER KILLS OVER 6 ZOMBIES WITHIN A SMALL TIME PERIOD
		level.plr_vox["kill"]["streak_response"]					    =		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["headshot"]								=		"kill_headshot";	    //PLAYER KILLS A ZOMBIE WITH A HEADSHOT OVER 400 UNITS AWAY
		level.plr_vox["kill"]["headshot_response"]						=		"resp_kill_headshot";	//RESPONSE TO ABOVE
		level.plr_vox["kill"]["explosive"]								=		"kill_explo";			//PLAYER KILLS A ZOMBIE USING EXPLOSIVES
		level.plr_vox["kill"]["explosive_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["flame"]									=		"kill_flame";			//PLAYER KILLS A ZOMBIE USING FLAME
		level.plr_vox["kill"]["flame_response"]							=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["raygun"]									=		"kill_ray";				//PLAYER KILLS A ZOMBIE USING THE RAYGUN
		level.plr_vox["kill"]["raygun_response"]						=		undefined;				//RESPONSE TO ABOVE
	    level.plr_vox["kill"]["bullet"]									=		"kill_streak";			//PLAYER KILLS A ZOMBIE USING ANY BULLET BASED WEAPON
		level.plr_vox["kill"]["bullet_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["tesla"]									=		"kill_tesla";			//PLAYER KILLS 4 OR MORE ZOMBIES WITH ONE SHOT OF THE TESLA GUN
		level.plr_vox["kill"]["tesla_response"]							= 	    undefined;				//RESPONSE TO ABOVE
	    level.plr_vox["kill"]["monkey"]									=		"kill_monkey";			//WHEN THE PLAYER KILLS A ZOMBIE USING THE MONKEYBOMB
		level.plr_vox["kill"]["monkey_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["thundergun"]								=		"kill_thunder";			//PLAYER KILLS A ZOMBIE USING THE THUNDERGUN
		level.plr_vox["kill"]["thundergun_response"]					= 	    undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["freeze"]								    =		"kill_freeze";			//PLAYER KILLS A ZOMBIE USING THE FREEZEGUN
		level.plr_vox["kill"]["freeze_response"]						= 	    undefined;
		level.plr_vox["kill"]["crawler"]								=		"kill_crawler";			//PLAYER KILLS A CRAWLING ZOMBIE
		level.plr_vox["kill"]["crawler_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["hellhound"]								=		"kill_hellhound";		//PLAYER KILLS A HELLHOUND
		level.plr_vox["kill"]["hellhound_response"]						=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["quad"]								    =		"kill_quad";			//PLAYER KILLS A QUAD ZOMBIE
		level.plr_vox["kill"]["quad_response"]						    =		undefined;				//RESPONSE TO ABOVE
		//Added for Cosmodrome (Ascension)
		level.plr_vox["kill"]["space_monkey"]						    =		"kill_space_monkey";	//PLAYER KILLS A SPACE MONKEY
		level.plr_vox["kill"]["space_monkey_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["gersh_device"]						    =		"kill_gersh_device";	//PLAYER KILLS 3 OR MORE ZOMBIES WITH THE GERSH DEVICE
		level.plr_vox["kill"]["gersh_device_response"]					=		undefined;				//RESPONSE TO ABOVE
		level.plr_vox["kill"]["sickle"]						            =		"kill_sickle";	        //PLAYER KILLS WITH THE SICKLE
		level.plr_vox["kill"]["sickle_response"]					    =		undefined;				//RESPONSE TO ABOVE
		//Added for Coast (Call of the Dead)
		level.plr_vox["kill"]["human"]						            =		"kill_human";	        //PLAYER KILLS WITH THE V-R11
		level.plr_vox["kill"]["human_response"]					        =		undefined;
		level.plr_vox["kill"]["ubersniper"]						        =		"kill_ubersniper";	    //PLAYER KILLS WITH THE SCAVENGER
		level.plr_vox["kill"]["ubersniper_response"]					=		undefined;
		level.plr_vox["kill"]["dolls"]						            =		"kill_dolls";	        //PLAYER KILLS WITH THE DOLLS
		level.plr_vox["kill"]["dolls_response"]					        =		undefined;
		level.plr_vox["kill"]["claymore"]						        =		"kill_claymore";	    //PLAYER KILLS WITH THE CLAYMORE
		level.plr_vox["kill"]["claymore_response"]					    =		undefined;
		//Added for Temple (Shangri-La)
		level.plr_vox["kill"]["sonic"]						        	=		"sonic_kill";	    //working
		level.plr_vox["kill"]["sonic_response"]					    	=		undefined;
		level.plr_vox["kill"]["napalm"]						        	=		"napalm_kill";	    //working
		level.plr_vox["kill"]["napalm_response"]					    =		undefined;
		level.plr_vox["kill"]["shrink"]						        	=		"kill_shrink";	    //working
		level.plr_vox["kill"]["shrink_response"]					    =		undefined;
		level.plr_vox["kill"]["shrunken"]						        =		"kill_shrunken";	//working    
		level.plr_vox["kill"]["shrunken_response"]					    =		undefined;
		level.plr_vox["kill"]["spikemore"]						        =		"kill_spikemore";	//working    
		level.plr_vox["kill"]["spikemore_response"]					    =		undefined;
		level.plr_vox["kill"]["thief"]						        	=		"kill_thief";	    //working
		level.plr_vox["kill"]["thief_response"]					   	 	=		undefined;
		
		//WEAPON PICKUPS: Each will play after the Player buys or gets a weapon from the box.  Broken into weapon categories.
		//Can be made weapon specific, if the need arises.
		level.plr_vox["weapon_pickup"]									=		[];
		level.plr_vox["weapon_pickup"]["pistol"]						=		"wpck_crappy";
		level.plr_vox["weapon_pickup"]["pistol_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["smg"]							=		"wpck_smg";
		level.plr_vox["weapon_pickup"]["smg_response"]					=		undefined;
		level.plr_vox["weapon_pickup"]["dualwield"]						=		"wpck_dual";
		level.plr_vox["weapon_pickup"]["dualwield_response"]			=		undefined;
		level.plr_vox["weapon_pickup"]["shotgun"]						=		"wpck_shotgun";
		level.plr_vox["weapon_pickup"]["shotgun_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["rifle"]							=		"wpck_sniper";
		level.plr_vox["weapon_pickup"]["rifle_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["burstrifle"]					=		"wpck_mg";
		level.plr_vox["weapon_pickup"]["burstrifle_response"]			=		undefined;
		level.plr_vox["weapon_pickup"]["assault"]						=		"wpck_mg";
		level.plr_vox["weapon_pickup"]["assault_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["sniper"]						=		"wpck_sniper";
		level.plr_vox["weapon_pickup"]["sniper_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["mg"]							=		"wpck_mg";
		level.plr_vox["weapon_pickup"]["mg_response"]					=		undefined;
		level.plr_vox["weapon_pickup"]["launcher"]						=		"wpck_launcher";
		level.plr_vox["weapon_pickup"]["launcher_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["grenade"]						=		"wpck_grenade";
		level.plr_vox["weapon_pickup"]["grenade_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["bowie"]						    =		"wpck_bowie";
		level.plr_vox["weapon_pickup"]["bowie_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["sickle"]						=		"wpck_sickle";
		level.plr_vox["weapon_pickup"]["sickle_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["raygun"]						=		"wpck_raygun";
		level.plr_vox["weapon_pickup"]["raygun_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["monkey"]						=		"wpck_monkey";
		level.plr_vox["weapon_pickup"]["monkey_response"]				=		"resp_wpck_monkey";
		level.plr_vox["weapon_pickup"]["tesla"]							=		"wpck_tesla";
		level.plr_vox["weapon_pickup"]["tesla_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["thunder"]						=		"wpck_thunder";
		level.plr_vox["weapon_pickup"]["thunder_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["freezegun"]						=		"wpck_freeze";
		level.plr_vox["weapon_pickup"]["freezegun_response"]		    =		undefined;
		level.plr_vox["weapon_pickup"]["crossbow"]					    =		"wpck_launcher";
		level.plr_vox["weapon_pickup"]["crossbow_response"]			    =		undefined;
		level.plr_vox["weapon_pickup"]["upgrade"]					    =		"wpck_upgrade";
		level.plr_vox["weapon_pickup"]["upgrade_response"]			    =		undefined;
		level.plr_vox["weapon_pickup"]["upgrade_wait"]					=		"wpck_upgrade_wait";
		level.plr_vox["weapon_pickup"]["upgrade_wait_response"]			=		undefined;
		level.plr_vox["weapon_pickup"]["favorite"]					    =		"wpck_favorite";
		level.plr_vox["weapon_pickup"]["favorite_response"]			    =		undefined;
		level.plr_vox["weapon_pickup"]["favorite_upgrade"]			    =		"wpck_favorite_upgrade";
		level.plr_vox["weapon_pickup"]["favorite_upgrade_response"]		=		undefined;
		//Added for Cosmodrome (Ascension)
		level.plr_vox["weapon_pickup"]["sickle"]						=		"wpck_sickle";
		level.plr_vox["weapon_pickup"]["sickle_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["dolls"]						    =		"wpck_dolls";
		level.plr_vox["weapon_pickup"]["dolls_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["gersh"]						    =		"wpck_gersh_device";
		level.plr_vox["weapon_pickup"]["gersh_response"]				=		undefined;
	    //Added for Coast (Call of the Dead)
	    level.plr_vox["weapon_pickup"]["human"]						    =		"wpck_human";
		level.plr_vox["weapon_pickup"]["human_response"]				=		undefined;
		level.plr_vox["weapon_pickup"]["ubersniper"]				    =		"wpck_ubersniper";
		level.plr_vox["weapon_pickup"]["ubersniper_response"]		    =		undefined;
		//Added for Temple (Shangri-La)
		level.plr_vox["weapon_pickup"]["shrink"]				    	=		"wpck_shrink";		//working
		level.plr_vox["weapon_pickup"]["shrink_response"]		    	=		undefined;
		level.plr_vox["weapon_pickup"]["spikemore"]				    	=		"wpck_spikemore";	//working
		level.plr_vox["weapon_pickup"]["spikemore_response"]		    =		undefined;
	
	    //EGGS and OTHER STUFF: Egg lines, achievements, etc
		level.plr_vox["eggs"]											=		[];
		level.plr_vox["eggs"]["achievement"]                            =       "achievement";
		level.plr_vox["eggs"]["music_activate"]                         =       "secret";
		level.plr_vox["eggs"]["meteors"]                                =       "egg_pedastool";
		//Theater (Kino Der Toten) Specific
		level.plr_vox["eggs"]["room_screen"]                            =       "egg_room_screen";
		level.plr_vox["eggs"]["room_dress"]                             =       "egg_room_dress";
		level.plr_vox["eggs"]["room_lounge"]                            =       "egg_room_lounge";
		level.plr_vox["eggs"]["room_rest"]                              =       "egg_room_rest";
		level.plr_vox["eggs"]["room_alley"]                             =       "egg_room_alley";
		level.plr_vox["eggs"]["portrait_dempsey"]                       =       "egg_port_dempsey";
		level.plr_vox["eggs"]["portrait_nikolai"]                       =       "egg_port_nikolai";
		level.plr_vox["eggs"]["portrait_takeo"]                         =       "egg_port_takeo";
		level.plr_vox["eggs"]["portrait_richtofan"]                     =       "egg_port_richtofan";
		level.plr_vox["eggs"]["portrait_empty"]                         =       "egg_port_empty";
		//Cosmodrome (Ascension) Specific
	    level.plr_vox["eggs"]["gersh_response"]                         =       "cosmo_egg";
	    ////Added for Coast (Call of the Dead)
	    level.plr_vox["eggs"]["coast_response"]                         =       "egg_response";
	    level.plr_vox["eggs"]["dolls"]                                  =       "egg_dolls";
		//Added for Temple (Shangri-La)
		level.plr_vox["eggs"]["quest1"]									=		"quest_step1";
		level.plr_vox["eggs"]["quest2"]									=		"quest_step2";
		level.plr_vox["eggs"]["quest3"]									=		"quest_step3";
		level.plr_vox["eggs"]["quest4"]									=		"quest_step4";
		level.plr_vox["eggs"]["quest5"]									=		"quest_step5";
		level.plr_vox["eggs"]["quest6"]									=		"quest_step6";
		level.plr_vox["eggs"]["quest7"]									=		"quest_step7";
		level.plr_vox["eggs"]["quest8"]									=		"quest_step8";
		level.plr_vox["eggs"]["rod"]									=		"rod";
//		level.plr_vox["eggs"]["safety"]									=		"safety";
//		level.plr_vox["eggs"]["gameover"]								=		"gameover";
	    
	//**ZOMBIE VOCALIZATIONS**\\    
	    //ARRAY and PREFIX: Setting up a prefix and array for all Zombie vocalizations  
	    level.zmb_vox                               =   [];
	    level.zmb_vox["prefix"]                     =   "zmb_vocals_";
	    
	    //Standard Zombies
	    level.zmb_vox["zombie"]                     =   [];
	    level.zmb_vox["zombie"]["ambient"]          =   "zombie_ambience";
	    level.zmb_vox["zombie"]["sprint"]           =   "zombie_sprint";
	    level.zmb_vox["zombie"]["attack"]           =   "zombie_attack";
	    level.zmb_vox["zombie"]["teardown"]         =   "zombie_teardown";
	    level.zmb_vox["zombie"]["taunt"]            =   "zombie_taunt";
	    level.zmb_vox["zombie"]["behind"]           =   "zombie_behind";
	    level.zmb_vox["zombie"]["death"]            =   "zombie_death";
	    level.zmb_vox["zombie"]["crawler"]          =   "zombie_crawler";
	    
	    //Quad Zombies
		level.zmb_vox["quad_zombie"]                =   [];
	    level.zmb_vox["quad_zombie"]["ambient"]     =   "quad_ambience";
	    level.zmb_vox["quad_zombie"]["sprint"]      =   "quad_sprint";
	    level.zmb_vox["quad_zombie"]["attack"]      =   "quad_attack";
	    level.zmb_vox["quad_zombie"]["behind"]      =   "quad_behind";
	    level.zmb_vox["quad_zombie"]["death"]       =   "quad_death";
	    
	    //Thief Zombies
		level.zmb_vox["thief_zombie"]                =   [];
	    level.zmb_vox["thief_zombie"]["ambient"]     =   "thief_ambience";
	    level.zmb_vox["thief_zombie"]["sprint"]      =   "thief_sprint";
	    level.zmb_vox["thief_zombie"]["steal"]       =   "thief_steal";
	    level.zmb_vox["thief_zombie"]["death"]       =   "thief_death";
	    level.zmb_vox["thief_zombie"]["anger"]       =   "thief_anger";
	
	    //Boss Zombies
		level.zmb_vox["boss_zombie"]                =   [];
	    level.zmb_vox["boss_zombie"]["ambient"]     =   "boss_ambience";
	    level.zmb_vox["boss_zombie"]["sprint"]      =   "boss_sprint";
	    level.zmb_vox["boss_zombie"]["attack"]      =   "boss_attack";
	    level.zmb_vox["boss_zombie"]["behind"]      =   "boss_behind";
	    level.zmb_vox["boss_zombie"]["death"]       =   "boss_death";
	    
	    //Monkey Zombies
	    level.zmb_vox["monkey_zombie"]              =   [];
	    level.zmb_vox["monkey_zombie"]["ambient"]   =   "monkey_ambience";
	    level.zmb_vox["monkey_zombie"]["sprint"]    =   "monkey_sprint";
	    level.zmb_vox["monkey_zombie"]["attack"]    =   "monkey_attack";
	    level.zmb_vox["monkey_zombie"]["behind"]    =   "monkey_behind";
	    level.zmb_vox["monkey_zombie"]["death"]     =   "monkey_death";
		
		if( isdefined( level._audio_alias_override ) )
		{
			level thread [[level._audio_alias_override]]();
		}
}

init_audio_functions()
{
	flag_wait( "all_players_connected" );
	
	players = get_players(); 
	for( i = 0; i < players.size; i++ )
	{
		players[i] thread zombie_behind_vox();
		players[i] thread player_killstreak_timer();
		players[i] thread oh_shit_vox();
	}
}

//Plays a specific Zombie vocal when they are close behind the player
//Self is the Player(s)
zombie_behind_vox()
{
	self endon("disconnect");
	self endon("death");
	
	if(!IsDefined(level._zbv_vox_last_update_time))
	{
		level._zbv_vox_last_update_time = 0;	
		level._audio_zbv_shared_ent_list = GetAISpeciesArray("axis");
	}
	
	while(1)
	{
		wait(1);		
		
		t = GetTime();
		
		if(t > level._zbv_vox_last_update_time + 1000)
		{
			level._zbv_vox_last_update_time = t;
			level._audio_zbv_shared_ent_list = GetAISpeciesArray("axis");
		}
	
		zombs = level._audio_zbv_shared_ent_list;
		
		played_sound = false;
		
		for(i=0;i<zombs.size;i++)
		{
			if(!isDefined(zombs[i]))
			{
				continue;
			}
			
			if(zombs[i].isdog)
			{
				continue;
			}
				
			dist = 200;	
			z_dist = 50;	
			alias = level.vox_behind_zombie;
					
			if(IsDefined(zombs[i].zombie_move_speed))
			{
				switch(zombs[i].zombie_move_speed)
				{
					case "walk": dist = 200;break;
					case "run": dist = 250;break;
					case "sprint": dist = 275;break;
				}	
			}			
			if(DistanceSquared(zombs[i].origin,self.origin) < dist * dist )
			{				
				yaw = self animscripts\utility::GetYawToSpot(zombs[i].origin );
				z_diff = self.origin[2] - zombs[i].origin[2];
				if( (yaw < -95 || yaw > 95) && abs( z_diff ) < 50 )
				{
					zombs[i] thread maps\_zombiemode_audio::do_zombies_playvocals( "behind", zombs[i].animname );
					played_sound = true;
					break;
				}			
			}
		}
		
		if(played_sound)
		{
			wait(5);		// Each player can only play one instance of this sound every 5 seconds - instead of the previous network storm.
		}
	}
}

attack_vox_network_choke()
{
	while(1)
	{
		level._num_attack_vox = 0;
		wait_network_frame();
	}
}

do_zombies_playvocals( alias_type, zombie_type )
{
    self endon( "death" );
    
    if( !IsDefined( zombie_type ) )
    {
        zombie_type = "zombie";
    }
	
	//Prevent shrinked zombies from playing vocals OTHER than shrinked ambients
	if( is_true( self.shrinked ) )
	{
		return;
	}
    
    if( !IsDefined( self.talking ) )
    {
        self.talking = false;
    }
    
    //DEBUG SECTION
    if( !IsDefined( level.zmb_vox[zombie_type] ) )
    {
        /#
        //IPrintLnBold( "AUDIO - ZOMBIE TYPE: " + zombie_type + " has NO aliases set up for it." );
        #/
        return;
    }
    
    if( !IsDefined( level.zmb_vox[zombie_type][alias_type] ) )
    {
        /#
        //IPrintLnBold( "AUDIO - ZOMBIE TYPE: " + zombie_type + " has NO aliases set up for ALIAS_TYPE: " + alias_type );
        #/
        return;
    }
    
    if(alias_type == "attack")
    {
    	if(!IsDefined(level._num_attack_vox))
    	{
    		level thread attack_vox_network_choke();
    	}
    	
    	if(level._num_attack_vox > 4)
    	{
    		return;
    	}
    	
    	level._num_attack_vox ++;
  	}
    
    alias = level.zmb_vox["prefix"] + level.zmb_vox[zombie_type][alias_type];
    
    if( alias_type == "attack" || alias_type == "behind" || alias_type == "death" || alias_type == "anger" || alias_type == "steal" )
    {
        self PlaySound( alias );
    }
    else if( !self.talking )
    {
        self.talking = true;
        self PlaySound( alias, "sounddone" );
        self waittill( "sounddone" );
        self.talking = false;
    }
}   

oh_shit_vox()
{
	self endon("disconnect");
	self endon("death");
	
	while(1)
	{
		wait(1);
		
		players = getplayers();
		zombs = GetAISpeciesArray("axis");
	
		if( players.size > 1 )
		{
			close_zombs = 0;
			for( i=0; i<zombs.size; i++ )
			{
				if( DistanceSquared( zombs[i].origin, self.origin ) < 250 * 250)
				{
					close_zombs ++;
				}
			}
			if( close_zombs > 4 )
			{
				if( randomintrange( 0, 20 ) < 5 )
				{
					self create_and_play_dialog( "general", "oh_shit" );
					wait(4);	
				}
			}
		}
	}
}

//**Player Dialog - The following functions all serve to play Player dialog
//**To use create_and_play_dialog, _zombiemode_audio must be included in the GSC you're using the function in, or you must
//**call the function like so: player maps\_zombiemode_audio::create_and_play_dialog()

create_and_play_dialog( category, type, response, force_variant, override )
{              
	waittime = .25;
	
	/#
	if( GetDvarInt( #"debug_audio" ) > 0 )
	    level thread dialog_debugger( category, type );
	#/
	
	if( !IsDefined( level.plr_vox[category][type] ) )
	{
		//IPrintLnBold( "No Category: " + category + " and Type: " + type );
		return;
	}
	
	//Preventing the player from spouting off a bunch of crap in laststand
	if( self maps\_laststand::player_is_in_laststand() && ( type != "revive_down" || type != "revive_up" ) )
	{
	    return;
	}
	
	alias_suffix = level.plr_vox[category][type];
	
	if( IsDefined( response ) )
	    alias_suffix = response + alias_suffix;
	    
	index = maps\_zombiemode_weapons::get_player_index(self);
	
	if( is_true( level.player_4_vox_override ) && index == 3 )
	{
		index = 4;
	}
	
	prefix = level.plr_vox["prefix"] + index + "_";
	
	if( !IsDefined ( self.sound_dialog ) )
	{
		self.sound_dialog = [];
		self.sound_dialog_available = [];
	}
				
	if ( !IsDefined ( self.sound_dialog[ alias_suffix ] ) )
	{
		num_variants = maps\_zombiemode_spawner::get_number_variants( prefix + alias_suffix );      
		
		//TOOK OUT THE ASSERT AND ADDED THIS CHECK FOR LOCS
		if( num_variants <= 0 )
		{
		    /#
		    if( GetDvarInt( #"debug_audio" ) > 0 )
		        PrintLn( "DIALOG DEBUGGER: No variants found for - " + prefix + alias_suffix );
		    #/
		    return;
		}     
		
		/#      
		//assertex( num_variants > 0, "No dialog variants found for category: " + alias_suffix );
		#/
		
		for( i = 0; i < num_variants; i++ )
		{
			self.sound_dialog[ alias_suffix ][ i ] = i;     
		}	
		
		self.sound_dialog_available[ alias_suffix ] = [];
	}
	
	if ( self.sound_dialog_available[ alias_suffix ].size <= 0 )
	{
		self.sound_dialog_available[ alias_suffix ] = self.sound_dialog[ alias_suffix ];
	}
  
	variation = random( self.sound_dialog_available[ alias_suffix ] );
	self.sound_dialog_available[ alias_suffix ] = array_remove( self.sound_dialog_available[ alias_suffix ], variation );
    
    if( IsDefined( force_variant ) )
    {
        variation = force_variant;
    }
    
    if( !IsDefined( override ) )
    {
        override = false;
    }
    
	sound_to_play = alias_suffix + "_" + variation;
	
	if( isdefined( level._audio_custom_player_playvox ) )
	{
		self thread [[level._audio_custom_player_playvox]]( prefix, index, sound_to_play, waittime, category, type, override );
	}
	else
	{
		self thread do_player_playvox( prefix, index, sound_to_play, waittime, category, type, override );
	}
}

do_player_playvox( prefix, index, sound_to_play, waittime, category, type, override )
{
	players = getplayers();
	if( !IsDefined( level.player_is_speaking ) )
	{
		level.player_is_speaking = 0;	
	}
	
	if( is_true(level.skit_vox_override) && !override )
	    return;
	
	if( level.player_is_speaking != 1 )
	{
		level.player_is_speaking = 1;
		self playsound( prefix + sound_to_play, "sound_done" + sound_to_play );			
		self waittill( "sound_done" + sound_to_play );
		wait( waittime );		
		level.player_is_speaking = 0;
		
		if( !flag( "solo_game" ) && ( isdefined (level.plr_vox[category][type + "_response"] )))
		{
			if ( isDefined( level._audio_custom_response_line ) )
	        {
		        level thread [[ level._audio_custom_response_line ]]( self, index, category, type );
	        }
			else
			{
			    level thread setup_response_line( self, index, category, type ); 
			}
		}
	}
}

setup_response_line( player, index, category, type )
{
	Dempsey = 0;
	Nikolai = 1;
	Takeo = 2;
	Richtofen = 3;
	
	switch( player.entity_num )
	{
		case 0:
			level setup_hero_rival( player, Nikolai, Richtofen, category, type );
		break;
		
		case 1:
			level setup_hero_rival( player, Richtofen, Takeo, category, type );
		break;
		
		case 2:
			level setup_hero_rival( player, Dempsey, Nikolai, category, type );
		break;
		
		case 3:
			level setup_hero_rival( player, Takeo, Dempsey, category, type );
		break;
	}
	return;
}

setup_hero_rival( player, hero, rival, category, type )
{
	players = getplayers();
	
    playHero = false;
    playRival = false;
    hero_player = undefined;
    rival_player = undefined;
    
	for ( i = 0; i < players.size; i++ )
	{
    	if ( players[i].entity_num == hero )
    	{
    	    playHero = true;
    	    hero_player = players[i];
    	}
    	if ( players[i].entity_num == rival )
    	{
    	    playRival = true;
    	    rival_player = players[i];
    	}
	}
	
	if(playHero && playRival)
	{
		if(randomfloatrange(0,1) < .5)
		{
			playRival = false;
		}
		else
		{
			playHero = false;
		}
	}	
	if( playHero && IsDefined( hero_player ) )
	{		
		if( distancesquared (player.origin, hero_player.origin) < 500*500)
		{
			hero_player create_and_play_dialog( category, type + "_response", "hr_" );
		}
		else if( isdefined( rival_player ) )
		{
			playRival = true;
		}
	}		
	if( playRival && IsDefined( rival_player ) )
	{
		if( distancesquared (player.origin, rival_player.origin) < 500*500)
		{
			rival_player create_and_play_dialog( category, type + "_response", "riv_" );
		}
	}
}

//For any 2d Announcer Line
do_announcer_playvox( category )
{
	if( !IsDefined( category ) )
		return;
	
	if( !IsDefined( level.devil_is_speaking ) )
	{
		level.devil_is_speaking = 0;
	}
	
	alias = level.devil_vox["prefix"] + category;
	
	if( level.devil_is_speaking == 0 )
	{
		level.devil_is_speaking = 1;
		level play_sound_2D( alias );
		wait 2.0;
		level.devil_is_speaking =0;
	}
}

//** Player Killstreaks: The following functions start a timer on each player whenever they begin killing zombies.
//** If they kill a certain amount of zombies within a certain time, they will get a Killstreak line
player_killstreak_timer()
{
	self endon("disconnect");
	self endon("death");
	
	if(getdvar ("zombie_kills") == "") 
	{
		setdvar ("zombie_kills", "7");
	}	
	if(getdvar ("zombie_kill_timer") == "") 
	{
		setdvar ("zombie_kill_timer", "5");
	}

	kills = GetDvarInt( #"zombie_kills");
	time = GetDvarInt( #"zombie_kill_timer");

	if (!isdefined (self.timerIsrunning))	
	{
		self.timerIsrunning = 0;
	}

	while(1)
	{
		self waittill( "zom_kill", zomb );	
		
		if( IsDefined( zomb._black_hole_bomb_collapse_death ) && zomb._black_hole_bomb_collapse_death == 1 )
		{
		    continue;
		}
		
		if( is_true( zomb.microwavegun_death ) )
		{
			continue;
		}
		
		self.killcounter ++;

		if (self.timerIsrunning != 1)	
		{
			self.timerIsrunning = 1;
			self thread timer_actual(kills, time);			
		}
	}	
}

player_zombie_kill_vox( hit_location, player, mod, zombie )
{
	weapon = player GetCurrentWeapon();
	dist = DistanceSquared( player.origin, zombie.origin );
	
	if( !isdefined(level.zombie_vars["zombie_insta_kill"] ) )
		level.zombie_vars["zombie_insta_kill"] = 0;
		
	instakill = level.zombie_vars["zombie_insta_kill"];
	
	death = get_mod_type( hit_location, mod, weapon, zombie, instakill, dist, player );
	chance = get_mod_chance( death );
	
	if( !IsDefined( player.force_wait_on_kill_line ) )
	    player.force_wait_on_kill_line = false;

	if( ( chance > RandomIntRange( 1, 100 ) ) && player.force_wait_on_kill_line == false )
	{
		player.force_wait_on_kill_line = true;
		player create_and_play_dialog( "kill", death );
		wait(2);
		player.force_wait_on_kill_line = false;
	}
}

get_mod_chance( meansofdeath )
{
	chance = undefined;
	
	switch( meansofdeath )
	{
		case "sickle":                  chance = 40; break;
		case "melee": 					chance = 40; break;
		case "melee_instakill": 	    chance = 99; break;
		case "weapon_instakill": 	    chance = 10; break;
		case "explosive": 				chance = 60; break;	
		case "flame":					chance = 60; break;	
		case "raygun":					chance = 75; break;	
		case "headshot":				chance = 99; break;
		case "crawler":					chance = 30; break;
		case "quad":					chance = 30; break;
		case "astro":					chance = 99; break;
		case "closekill":				chance = 15; break;	
		case "bullet":					chance = 10; break;
		case "claymore":                chance = 99; break;
		case "dolls":                   chance = 99; break;
		case "default":					chance = 1;  break;
	}
	return chance;
}

get_mod_type( impact, mod, weapon, zombie, instakill, dist, player )
{
	close_dist = 64 * 64;
	far_dist = 400 * 400;
	
	//PREVENTING BLACK HOLE BOMB FROM CALLING A BUNCH OF WEAPON KILL LINES
	if( IsDefined( zombie._black_hole_bomb_collapse_death ) && zombie._black_hole_bomb_collapse_death == 1 )
	{
	    return "default";
	}
	
	if( is_placeable_mine( weapon ) )
	{
	    if( !instakill )
	        return "claymore";
	    else
	        return "weapon_instakill";
	}
	
	//MELEE & MELEE_INSTAKILL
	if( ( mod == "MOD_MELEE" ||
				mod == "MOD_BAYONET" ||
				mod == "MOD_UNKNOWN" ) &&
				dist < close_dist )
	{
		if( !instakill )
		{
			if( player HasWeapon( "sickle_knife_zm" ) )
			    return "sickle";
			else
			    return "melee";
		}
		else
			return "melee_instakill";
	}
	
	if( IsDefined( zombie.damageweapon ) && zombie.damageweapon == "zombie_nesting_doll_single" )
	{
	    if( !instakill )
	        return "dolls";
	    else
	        return "weapon_instakill";
	}
	
	//EXPLOSIVE & EXPLOSIVE_INSTAKILL
	if( ( mod == "MOD_GRENADE" ||
				mod == "MOD_GRENADE_SPLASH" ||
				mod == "MOD_PROJECTILE_SPLASH" ||
				mod == "MOD_EXPLOSIVE" ) && 
			  weapon != "ray_gun_zm" )
	{
		if( !instakill )
			return "explosive";
		else
			return "weapon_instakill";
	}
	
	//FLAME & FLAME_INSTAKILL
	if( ( IsSubStr( weapon, "flame" ) || 
				IsSubStr( weapon, "molotov_" ) ||
				IsSubStr( weapon, "napalmblob_" ) ) && 
			( mod == "MOD_BURNED" || 
			 	mod == "MOD_GRENADE" || 
			 	mod == "MOD_GRENADE_SPLASH" ) )
	{
		if( !instakill )
			return "flame";
		else
			return "weapon_instakill";
	}
	
	//RAYGUN & RAYGUN_INSTAKILL
	if( weapon == "ray_gun_zm" &&
			dist > far_dist )
	{
		if( !instakill )
			return "raygun";
		else
			return "weapon_instakill";
	}
		
	//HEADSHOT
	if( ( mod == "MOD_RIFLE_BULLET" || 
		    mod == "MOD_PISTOL_BULLET" ) &&
		  ( impact == "head" &&
		  	dist > far_dist &&
		  	!instakill ) )
	{
		return "headshot";
	}
	
	//QUAD
	if( mod != "MOD_MELEE" && 
			impact != "head" &&
			zombie.animname == "quad_zombie" &&
			!instakill )
	{
	    return "quad";
	}	
	
	//ASTRO
	if( mod != "MOD_MELEE" && 
			impact != "head" &&
			zombie.animname == "astro_zombie" &&
			!instakill )
	{
	    return "astro";
	}
	
	//CRAWLER
	if( mod != "MOD_MELEE" && 
			impact != "head" &&
			!zombie.has_legs &&
			!instakill )
	{
		return "crawler";
	}
	
	//CLOSEKILL
	if( mod != "MOD_BURNED" &&
			dist < close_dist && 
			!instakill )
	{
		return "closekill";
	}
	
	//BULLET & BULLET_INSTAKILL
	if( mod == "MOD_RIFLE_BULLET" || 
		  mod == "MOD_PISTOL_BULLET" )
	{
		if( !instakill )
			return "bullet";
		else
			return "weapon_instakill";
	}
	
	return "default";
}

timer_actual(kills, time)
{
	self endon("disconnect");
	self endon("death");
	
	timer = gettime() + (time * 1000);
	while(getTime() < timer)
	{
		if (self.killcounter > kills)
		{
			self create_and_play_dialog( "kill", "streak" );

			wait(1);
		
			//resets the killcounter and the timer 
			self.killcounter = 0;

			timer = -1;
		}
		wait(0.1);
	}
	self.killcounter = 0;
	self.timerIsrunning = 0;
}

perks_a_cola_jingle_timer()
{	
	self endon( "death" );
	self thread play_random_broken_sounds();
	while(1)
	{
		//wait(randomfloatrange(60, 120));
		wait(randomfloatrange(31,45));
		if(randomint(100) < 15)
		{
			self thread play_jingle_or_stinger(self.script_sound);
			
		}		
	}	
}

play_jingle_or_stinger( perksacola )
{
	playsoundatposition ("evt_electrical_surge", self.origin);
	if(!IsDefined (self.jingle_is_playing ))
	{
		self.jingle_is_playing = 0;
	}	
	if (IsDefined ( perksacola ))
	{
		if(self.jingle_is_playing == 0 && level.music_override == false)
		{
			self.jingle_is_playing = 1;
			self playsound ( perksacola, "sound_done");
			self waittill ("sound_done");
			self.jingle_is_playing = 0;
		}
	}
}

play_random_broken_sounds()
{
	self endon( "death" );
	level endon ("jingle_playing");
	if (!isdefined (self.script_sound))
	{
		self.script_sound = "null";
	}
	if (self.script_sound == "mus_perks_revive_jingle")
	{
		while(1)
		{
			wait(randomfloatrange(7, 18));
			playsoundatposition ("zmb_perks_broken_jingle", self.origin);
			//playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("evt_electrical_surge", self.origin);
	
		}
	}
	else
	{
		while(1)
		{
			wait(randomfloatrange(7, 18));
			// playfx (level._effect["electric_short_oneshot"], self.origin);
			playsoundatposition ("evt_electrical_surge", self.origin);
		}
	}
}	

//SELF = Player Buying Perk
perk_vox( perk )
{
	self endon( "death" );
	self endon( "disconnect" );
	
	//Delay to prevent an early speech
	wait( 1.5 );
	if( !IsDefined( level.plr_vox["perk"][perk] ) )
	{
		/#
		IPrintLnBold( perk + " has no PLR VOX category set up." );
		#/
		return;
	}
	
	self create_and_play_dialog( "perk", perk );
}

dialog_debugger( category, type )
{
    /#
    PrintLn( "DIALOG DEBUGGER: Category - " + category + " Type - " + type + " Response - " + type + "_response" );
    
    if( !IsDefined( level.plr_vox[category][type] ) )
    {
        IPrintLnBold( "Player tried to play a line, but no alias exists. Category: " + category + " Type: " + type );
        PrintLn( "DIALOG DEBUGGER ERROR: Alias Not Defined For " + category + " " + type );
    }
    
    if( !IsDefined( level.plr_vox[category][type + "_response" ] ) )
        PrintLn( "DIALOG DEBUGGER ERROR: Response Alias Not Defined For " + category + " " + type + "_response" );
    #/
}

//MUSIC STATES
init_music_states()
{
    level.music_override = false;
    level.music_round_override = false;
    level.old_music_state = undefined;
    
    level.zmb_music_states                                  =   [];
    level.zmb_music_states["round_start"]                   =   spawnStruct();
    level.zmb_music_states["round_start"].music             =   "mus_zombie_round_start";
    level.zmb_music_states["round_start"].is_alias          =   true; 
    level.zmb_music_states["round_start"].override          =   true;
    level.zmb_music_states["round_start"].round_override    =   true;
    level.zmb_music_states["round_start"].musicstate        =   "WAVE";
    level.zmb_music_states["round_end"]                     =   spawnStruct();
    level.zmb_music_states["round_end"].music               =   "mus_zombie_round_over";
    level.zmb_music_states["round_end"].is_alias            =   true;
    level.zmb_music_states["round_end"].override            =   true;
    level.zmb_music_states["round_end"].round_override      =   true;
    level.zmb_music_states["round_end"].musicstate          =   "SILENCE";
    level.zmb_music_states["wave_loop"]                     =   spawnStruct();
    level.zmb_music_states["wave_loop"].music               =   "WAVE";
    level.zmb_music_states["wave_loop"].is_alias            =   false;
    level.zmb_music_states["wave_loop"].override            =   true;
    level.zmb_music_states["game_over"]                     =   spawnStruct();
    level.zmb_music_states["game_over"].music               =   "mus_zombie_game_over";
    level.zmb_music_states["game_over"].is_alias            =   true;
    level.zmb_music_states["game_over"].override            =   false;
    level.zmb_music_states["game_over"].musicstate          =   "SILENCE";
    level.zmb_music_states["dog_start"]                     =   spawnStruct();
    level.zmb_music_states["dog_start"].music               =   "mus_zombie_dog_start";
    level.zmb_music_states["dog_start"].is_alias            =   true;
    level.zmb_music_states["dog_start"].override            =   true;
    level.zmb_music_states["dog_end"]                       =   spawnStruct();
    level.zmb_music_states["dog_end"].music                 =   "mus_zombie_dog_end";
    level.zmb_music_states["dog_end"].is_alias              =   true;
    level.zmb_music_states["dog_end"].override              =   true;
    level.zmb_music_states["egg"]                           =   spawnStruct();
    level.zmb_music_states["egg"].music                     =   "EGG";
    level.zmb_music_states["egg"].is_alias                  =   false;
    level.zmb_music_states["egg"].override                  =   false;
    level.zmb_music_states["egg_safe"]                      =   spawnStruct();
    level.zmb_music_states["egg_safe"].music                =   "EGG_SAFE";
    level.zmb_music_states["egg_safe"].is_alias             =   false;
    level.zmb_music_states["egg_safe"].override             =   false;  
	level.zmb_music_states["egg_a7x"]                    	=   spawnStruct();
    level.zmb_music_states["egg_a7x"].music					=   "EGG_A7X";
    level.zmb_music_states["egg_a7x"].is_alias           	=   false;
    level.zmb_music_states["egg_a7x"].override           	=   false;
	level.zmb_music_states["sam_reveal"]                    =   spawnStruct();
    level.zmb_music_states["sam_reveal"].music				=   "SAM";
    level.zmb_music_states["sam_reveal"].is_alias           =   false;
    level.zmb_music_states["sam_reveal"].override           =   false;
}

change_zombie_music( state )
{
    wait(.05);
    
    m = level.zmb_music_states[state];
    
    if( !IsDefined( m ) )
    {
        /#
        IPrintLnBold( "Called change_zombie_music on undefined state: " + state );
        #/
        return;
    }
    
    do_logic =  true;
    
    if( !IsDefined( level.old_music_state ) )
    {
        do_logic = false;
    }
    
    if(do_logic)
    {
        if( level.old_music_state == m )
        {
            return;
        }
        else if( level.old_music_state.music == "mus_zombie_game_over" )
        {
            return;
        }
    }
    
    if( !IsDefined( m.round_override ) )
        m.round_override = false;
    
    if( m.override == true && level.music_override == true )
        return;
        
    if( m.round_override == true && level.music_round_override == true )
        return;    
    
    if( m.is_alias )
    {
        if( IsDefined( m.musicstate ) )
            setmusicstate( m.musicstate );
            
        play_sound_2d( m.music );
    }
    else
    {
        setmusicstate( m.music );
    }
    
    level.old_music_state = m;
}

//SELF == Trigger, for now
weapon_toggle_vox( alias, weapon )
{
    self notify( "audio_activated_trigger" );
    self endon( "audio_activated_trigger" );
    
    prefix = "vox_pa_switcher_";
    sound_to_play = prefix + alias;
    type = undefined;
    
    if( IsDefined( weapon ) )
    {
        type = get_weapon_num( weapon );
        
        if( !IsDefined( type ) )
        {
            return;
        }
    }
    
    self StopSounds();
    wait(.05);
    
    if( IsDefined( type ) )
    {
        self PlaySound( prefix + "weapon_" + type, "sounddone" );
        self waittill( "sounddone" );
    }
    
    self PlaySound( sound_to_play + "_0" );
}
get_weapon_num( weapon )
{
    weapon_num = undefined;
    
    switch( weapon )
    {
        case "humangun_zm":         
            weapon_num =  0;   
        break;
        
		case "sniper_explosive_zm": 
		    weapon_num =  1;   
		break;
		
		case "tesla_gun_zm":        
		    weapon_num =  2;   
		break;
    }
    
    return weapon_num;
}