#include clientscripts\_utility;
#include clientscripts\_zombiemode;

//----------------------------------------------------------------------------------------------
// setup
//----------------------------------------------------------------------------------------------
init()
{
	level.low_gravity_default = -136;
}

//----------------------------------------------------------------------------------------------
// client flag callbacks
//----------------------------------------------------------------------------------------------
zombie_low_gravity( local_client_num, set, newEnt )
{
	self endon( "death" );
	self endon( "entityshutdown" );

	if( set )
	{
		self SetPhysicsGravity( level.low_gravity_default );
		self.in_low_g = true;
	}
	else
	{
		self ClearPhysicsGravity();
		self.in_low_g = false;
	}
}

