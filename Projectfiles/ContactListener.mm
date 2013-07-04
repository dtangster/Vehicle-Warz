/*
 * Kobold2D™ --- http://www.kobold2d.org
 *
 * Copyright (c) 2010-2011 Steffen Itterheim. 
 * Released under MIT License in Germany (LICENSE-Kobold2D.txt).
 */

#import "ContactListener.h"
#import "cocos2d.h"
#import "Vehicle.h"
#import "Weapon.h"

// This is called when two fixtures begin to overlap. This is called for sensors and non-sensors.
// This event can only occur inside the time step.
void ContactListener::BeginContact(b2Contact* contact)
{
	b2Body* bodyA = contact->GetFixtureA()->GetBody();
	b2Body* bodyB = contact->GetFixtureB()->GetBody();
	CCSprite* spriteA = (__bridge CCSprite*)bodyA->GetUserData();
	CCSprite* spriteB = (__bridge CCSprite*)bodyB->GetUserData();
	
	if (spriteA && spriteB)
	{

	}
}

// This is called when two fixtures cease to overlap. This is called for sensors and non-sensors.
// This may be called when a body is destroyed, so this event can occur outside the time step.
void ContactListener::EndContact(b2Contact* contact)
{
	b2Body* bodyA = contact->GetFixtureA()->GetBody();
	b2Body* bodyB = contact->GetFixtureB()->GetBody();
	CCSprite* spriteA = (__bridge CCSprite*)bodyA->GetUserData();
	CCSprite* spriteB = (__bridge CCSprite*)bodyB->GetUserData();
	
	if (spriteA && spriteB)
	{

	}
}

// This is called after collision detection, but before collision resolution.
// This gives you a chance to disable the contact based on the current configuration.
void ContactListener::PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
{
    
}

// The post solve event is where you can gather collision impulse results.
// NOTE: Do not alter physics world here!
void ContactListener::PostSolve(b2Contact* contact, const b2ContactImpulse* impulse)
{
    b2Body* bodyA = contact->GetFixtureA()->GetBody();
	b2Body* bodyB = contact->GetFixtureB()->GetBody();
	CCSprite* spriteA = (__bridge CCSprite*)bodyA->GetUserData();
	CCSprite* spriteB = (__bridge CCSprite*)bodyB->GetUserData();
    
    // Handles the case when a collision happens between a vehicle and a weapon
    if (([spriteA isKindOfClass:[Vehicle class]] && [spriteB isKindOfClass:[Weapon class]])
        || ([spriteB isKindOfClass:[Vehicle class]] && [spriteA isKindOfClass:[Weapon class]])) {
        
        Vehicle *vehicle;
        Weapon *weapon;
        
        if ([spriteA isKindOfClass:[Vehicle class]]) {
            vehicle = (Vehicle *)spriteA;
            weapon = (Weapon *)spriteB;
        }
        else {
            vehicle = (Vehicle *)spriteB;
            weapon = (Weapon *)spriteA;
        }
        
        // Delegate any events to the Weapon class
        [weapon damageVehicle:vehicle withContactData:contact withImpulse:impulse];
    }
    // Handles the case when two weapons collide
    else if ([spriteA isKindOfClass:[Weapon class]] && [spriteB isKindOfClass:[Weapon class]]) {
        Weapon *weapon1 = (Weapon *)spriteA;
        Weapon *weapon2 = (Weapon *)spriteB;
        
        // Do something here!
    }
}
