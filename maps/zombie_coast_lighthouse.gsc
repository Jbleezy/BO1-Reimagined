//---------------------------------------------
// Light house functions for zombie_coast
//---------------------------------------------
#include common_scripts\utility; 
#include maps\_utility;
#include maps\_zombiemode_utility;


init()
{
	pack_a_punch_init();
	
	// wait for power
	level thread lighthouse_wait_for_power();
	
	level thread hide_packapunch_at_beginning();

}

hide_packapunch_at_beginning()
{
	wait(5);
	pack_a_punch_hide();
}



// WW (02-02-11): Waits for power before starting functions
lighthouse_wait_for_power()
{
	level waittill( "power_on" );
	clientnotify("LHL");

	while(1)
	{
		pack_a_punch_hide();
		//wait(randomintrange(100,120));	//pap is searching for between 1:40 and 2:00
		wait 15;  
	
		clientnotify("lhfo"); // the lighthouse freaks out for a bit
		exploder(310);
		playsoundatposition ("zmb_pap_lightning_1", (0,0,0));
		wait(15);
		exploder(310);
		playsoundatposition ("zmb_pap_lightning_2", (0,0,0));
		clientnotify("lhfd");				
		pack_a_punch_move_to_spot();
		wait(120);//2:00 wait while pap is active
		
		//make sure the machine is done being used before moving it!
		while(flag("pack_machine_in_use"))
		{	
			wait .05;
		}	
		
	}
}

pack_a_punch_init()
{
	pap_machine_trig = getent("zombie_vending_upgrade","targetname");
	pap_bump_trig = getent("pack_bump_trig","script_noteworthy");
	pap_bump_trig	enablelinkto();			//this has to be set once to enable linkto on triggers, but cannot be set again or an error occurs
	pap_machine_trig enablelinkto();	
}


/*------------------------------------
links all the pieces for the packapunch machine
then moves it to a new spot, then unlinks everything
------------------------------------*/
pack_a_punch_move_to_spot()
{
	
	level.pap_moving = true;
	pap_clip = getent("zombie_vending_upgrade_clip","targetname");
	pap_clip notsolid();
	
	
	pap_machine_trig = getent("zombie_vending_upgrade","targetname");	//the trigger that the player uses
	pap_pieces = getentarray(pap_machine_trig.target,"targetname");	//the pieces for the machine
	
	pap_bump_trig = getent("pack_bump_trig","script_noteworthy");		//bump trigger when the player bumps into it
	pap_jingle_struct = getstruct("pack_jingle_struct","script_noteworthy");	//struct where the jingle plays from

	link_ent = spawn("script_origin",pap_clip.origin);
	link_ent.angles = pap_jingle_struct.angles;	

	pap_machine_trig linkto(link_ent);
	pap_bump_trig linkto(link_ent);
	pap_clip linkto(link_ent);
	
	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") linkto(link_ent);
			getent(pap_pieces[i].target,"targetname") hide();
			
		}
		pap_pieces[i] linkto(link_ent);
		pap_pieces[i] hide();
	}
		
	link_ent moveto(link_ent.origin + (0,0,-1500),.5);	
	
	new_spot = get_new_pack_spot();
		
	assertex(isDefined(new_spot.script_string),"structs placed for the packapunch machine neeed to have a script_string value to contain client notification string");
	
	level.current_pap_spot = new_spot;
	
	//this tells the spotlight to focus on the new location
	clientnotify(new_spot.script_string);
	
	
	//position the pap machine underneath the spot where it will rise up	
	link_ent moveto(new_spot.origin + (0,0,-350),.05);
	link_ent rotateto(new_spot.angles,.1);
	link_ent waittill("rotatedone");
	
	
	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") show();
		}
		pap_pieces[i] show();
	}
	
	//rise the machine out of the ground with some FX and some wobble
	link_ent moveto(new_spot.origin ,5);	
	link_ent PlaySound( "zmb_pap_rise" );
	link_ent thread pap_rise_fx();
	link_ent thread pap_wobble();
	
	
	//to give the light time to focus on the new area and start the pre-rise FX
	wait(1);
	level thread hide_pap_debris();
	
	//causes the light on the lighthouse to be augmented by a cool effect
	do_packapunch_fx();
	
	
	//wait until the pap machine rises then rotate it to the final angles
	link_ent waittill("movedone");
	wait(.3);
	link_ent rotateto(new_spot.angles,.2);
	link_ent waittill("rotatedone");	
	
	//unlink everything to help out the network
	pap_machine_trig unlink();
	pap_bump_trig	unlink();

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") unlink();
		}
		pap_pieces[i] unlink();
	}
	
	//reset the jingle struct 
	pap_jingle_struct.origin = pap_bump_trig.origin;
	pap_jingle_struct.angles = link_ent.angles;
	
	pap_clip unlink();
	
	link_ent delete();
	
	level.pap_moving = undefined;
	
}

/*------------------------------------
the packapunch machine wobbles as it's rising out of the ground
self = the ent which the pap machine is linked to
------------------------------------*/
pap_wobble()
{
	self endon("movedone");
	self.og_angles = self.angles;
	while(1)
	{	
		self rotateto( self.og_angles + (randomintrange(-10,10),randomintrange(-10,10),randomintrange(-10,10)) ,.2);
		wait(.2);
	}
	
}

/*------------------------------------
plays some fx on the spot whre the packapunch machhine will rise from
------------------------------------*/
pap_rise_fx()
{
	if(!isDefined(level.current_pap_spot))
	{
		return;
	}
	
	switch(level.current_pap_spot.script_string)
	{
		case "pp0": //inside the ship				
				exploder(212);
			break;
						
		case "pp1":	//front/beach area
				exploder(211);
			break;
				
		case "pp2":
				exploder(213);
			break;
	}
	
}

get_new_pack_spot()
{
	spots = getstructarray("pap_location","targetname");
	
	if(isDefined(level.current_pap_spot))
	{
		spots = array_remove(spots,level.current_pap_spot);
	}
	spot = random(spots);
	

	return spot;
	
}

/*------------------------------------
any FX related things for the packapunch when it rises
------------------------------------*/
do_packapunch_fx()
{
	switch(level.current_pap_spot.script_string)
	{
		case "pp0": //inside the ship				
				exploder(202);
			break;
						
		case "pp1":	//front/beach area
				exploder(201);
			break;
				
		case "pp2":
				exploder(203);
			break;
	}
	
}

stop_packapunch_fx()
{
	if(!isDefined(level.current_pap_spot))
	{
		return undefined;
	}	
	
	if(level.current_pap_spot.script_string == "pp0")	//ship
	{
		stop_exploder(202);
	}
	else if(level.current_pap_spot.script_string ==  "pp1") 	//front/beach area
	{			
		stop_exploder(201);
	}
	else if(  level.current_pap_spot.script_string ==  "pp2")
	{
		stop_exploder(203);
	}

}

/*------------------------------------
hide the pap machine after a while before moving it again
------------------------------------*/
pack_a_punch_hide()
{
	level.pap_moving = true;
	
	//stops any FX associated with the packapunch
	stop_packapunch_fx();
	
	pap_clip = getent("zombie_vending_upgrade_clip","targetname");
	pap_clip notsolid();

	pap_machine_trig = getent("zombie_vending_upgrade","targetname");
	pap_pieces = getentarray(pap_machine_trig.target,"targetname");
	
	pap_bump_trig = getent("pack_bump_trig","script_noteworthy");
	pap_jingle_struct = getstruct("pack_jingle_struct","script_noteworthy");
	
	link_ent = spawn("script_origin",pap_machine_trig.origin);
	link_ent.angles = pap_jingle_struct.angles;
	pap_machine_trig linkto(link_ent);

	pap_bump_trig linkto(link_ent);
	pap_clip linkto(link_ent);

	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") linkto(link_ent);
			//getent(pap_pieces[i].target,"targetname") hide();
		}
		pap_pieces[i] linkto(link_ent);
		//pap_pieces[i] hide();
	}

	link_ent moveto(link_ent.origin + (0,0,-350) ,5);	
	link_ent PlaySound( "zmb_pap_lower" );

	link_ent thread pap_rise_fx();
	
	wait(1);
	
	level thread replace_pap_debris();
	
	link_ent waittill("movedone");			
		
	link_ent moveto(link_ent.origin + (0,0,-1500),.05);
	
	link_ent waittill("movedone");
	
	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") hide();
		}
		pap_pieces[i] hide();
	}
	
	pap_machine_trig unlink();
	pap_bump_trig	unlink();
	
	for(i=0;i<pap_pieces.size;i++)
	{
		if(isDefined(pap_pieces[i].target))
		{
			getent(pap_pieces[i].target,"targetname") unlink();
		}
		
		pap_pieces[i] unlink();
	}
	pap_jingle_struct.origin = pap_machine_trig.origin;
	pap_jingle_struct.angles = link_ent.angles;
	
	pap_clip unlink();

	link_ent delete();

	
	level.pap_moving = undefined;
	clientnotify ("PPH");
	

	
}

replace_pap_debris()
{
	if(!isDefined(level.current_pap_spot))
	{
		return undefined;
	}	
	
	playfx(level._effect["rise_burst_water"],level.current_pap_spot.origin);
	debris = getent(level.current_pap_spot.target,"targetname");
	if(isDefined(debris))
	{
		debris show();
		if(isDefined(debris._hidden))
		{
			debris moveto(debris.origin + (0,0,200),3);
			debris._hidden = undefined;
		}		
	}
}

hide_pap_debris()
{
	if(!isDefined(level.current_pap_spot))
	{
		return undefined;
	}	

	playfx(level._effect["rise_burst_water"],level.current_pap_spot.origin);
	debris = getent(level.current_pap_spot.target,"targetname");
	if(isDefined(debris))
	{
		debris._hidden = true;
		debris moveto(debris.origin + (0,0,-200),3);
		wait(3);
		debris hide();		
	}
}