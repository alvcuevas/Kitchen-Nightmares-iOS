//
//  Gameplay.m
//  KITCHEN NIGHTMARES - PESADILLA EN LA COCINA
//
//  Created by Álvaro on 11/03/14.
//  Copyright (c) 2014 Apportable. All rights reserved.
//

#import "Gameplay.h"
#import "tostadora.h"

@implementation Gameplay{
    CCPhysicsNode *_physicsNode;
    CCNode *_catapultArm;
    CCNode *_levelNode;
    CCNode *_contentNode;
    CCNode *_catapult;
    CCPhysicsJoint *_catapultJoint;
    CCNode *_pullbackNode;
    CCPhysicsJoint *_pullbackJoint;
    CCNode *_mouseJointNode;
    CCPhysicsJoint *_mouseJoint;
    tostadora *_tostadora;
    CCPhysicsJoint *_tostadoraCatapultJoint;
    CCAction *_followTostadora;
}

static const float MIN_SPEED = 5.f;


// Se ejecuta cuando se ha cargado la escena
- (void)didLoadFromCCB {
    // Habilita el touch al jugador
    self.userInteractionEnabled = TRUE;
    
    CCScene *level = [CCBReader loadAsScene:@"Niveles/Level1"];
    [_levelNode addChild:level];
    
    _physicsNode.debugDraw = TRUE;
    
    // Evitar colisiones entre catapulta y su brazo
    [_catapultArm.physicsBody setCollisionGroup:_catapult];
    [_catapult.physicsBody setCollisionGroup:_catapult];
    
    // Joint que conecta catapulta y el brazo
    _catapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_catapultArm.physicsBody bodyB:_catapult.physicsBody anchorA:_catapultArm.anchorPointInPoints];
    
    // Evitar la colision con los nodos invisibles de la escena
    _pullbackNode.physicsBody.collisionMask = @[];
    // Joint que crea impulso al brazo de la catapulta
    _pullbackJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_pullbackNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:60.f stiffness:500.f damping:40.f];
    
    _mouseJointNode.physicsBody.collisionMask = @[];
    
}

// Se ejecuta en cuanto se recibe un touch en escena
-(void) touchBegan:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    
    // Si la catapulta recibe un touch:
    // Se mueve el joint de la posicion y se carga la tostadora para ser lanzada
    if (CGRectContainsPoint([_catapultArm boundingBox], touchLocation))
    {
        _mouseJointNode.position = touchLocation;
        _mouseJoint = [CCPhysicsJoint connectedSpringJointWithBodyA:_mouseJointNode.physicsBody bodyB:_catapultArm.physicsBody anchorA:ccp(0, 0) anchorB:ccp(34, 138) restLength:0.f stiffness:3000.f damping:150.f];
        _tostadora = (tostadora*)[CCBReader load:@"tostadora"];
        CGPoint tostadoraPosition = [_catapultArm convertToWorldSpace:ccp(34, 138)];
        _tostadora.position = [_physicsNode convertToNodeSpace:tostadoraPosition];
        [_physicsNode addChild:_tostadora];
        _tostadora.physicsBody.allowsRotation = FALSE;
        
        _tostadoraCatapultJoint = [CCPhysicsJoint connectedPivotJointWithBodyA:_tostadora.physicsBody bodyB:_catapultArm.physicsBody anchorA:_tostadora.anchorPointInPoints];
    }
}

// Si se desliza el touch por la escena se actualiza la posicion del joint
- (void)touchMoved:(UITouch *)touch withEvent:(UIEvent *)event
{
    CGPoint touchLocation = [touch locationInNode:_contentNode];
    _mouseJointNode.position = touchLocation;
}

// Metodo que dispara la catapulta y sigue a la tostadora una vez lanzada
- (void)releaseCatapult {
    if (_mouseJoint != nil)
    {
        [_mouseJoint invalidate];
        _mouseJoint = nil;
        
        [_tostadoraCatapultJoint invalidate];
        _tostadoraCatapultJoint = nil;
        
        _tostadora.physicsBody.allowsRotation = TRUE;
        
        CCActionFollow *follow = [CCActionFollow actionWithTarget:_tostadora worldBoundary:self.boundingBox];
        [_contentNode runAction:follow];
    }
    
    _followTostadora = [CCActionFollow actionWithTarget:_tostadora worldBoundary:self.boundingBox];
    [_contentNode runAction:_followTostadora];
    _tostadora.launched = TRUE;
}

// Cuando acaba el touch en la escena o es cancelado, se dispara la catapulta
-(void) touchEnded:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self releaseCatapult];
}

-(void) touchCancelled:(UITouch *)touch withEvent:(UIEvent *)event
{
    [self releaseCatapult];
}

// Metodo que lanza la tostadora, cargando la escena y aplicandole impulso
- (void)lanzaTostadora {
    CCNode* tosta = [CCBReader load:@"tostadora"];
    tosta.position = ccpAdd(_catapultArm.position, ccp(16, 50));
    
    [_physicsNode addChild:tosta];
    
    CGPoint launchDirection = ccp(1, 0);
    CGPoint force = ccpMult(launchDirection, 8000);
    [tosta.physicsBody applyForce:force];
    
    self.position = ccp(0, 0);
    CCActionFollow *follow = [CCActionFollow actionWithTarget:tosta worldBoundary:self.boundingBox];
    [_contentNode runAction:follow];
}

// Metodo asignado al boton de Reintentar para volver al inicio de la escena
- (void)retry {
    [[CCDirector sharedDirector] replaceScene: [CCBReader loadAsScene:@"Gameplay"]];
}

- (void)nextAttempt {
    _tostadora = nil;
    [_contentNode stopAction:_followTostadora];
    
    CCActionMoveTo *actionMoveTo = [CCActionMoveTo actionWithDuration:1.f position:ccp(0, 0)];
    [_contentNode runAction:actionMoveTo];
}

- (void)update:(CCTime)delta
    {
        if (_tostadora.launched) {
            // if speed is below minimum speed, assume this attempt is over
            if (ccpLength(_tostadora.physicsBody.velocity) < MIN_SPEED){
                [self nextAttempt];
                return;
            }
            
            int xMin = _tostadora.boundingBox.origin.x;
            
            if (xMin < self.boundingBox.origin.x) {
                [self nextAttempt];
                return;
            }
            
            int xMax = xMin + _tostadora.boundingBox.size.width;
            
            if (xMax > (self.boundingBox.origin.x + self.boundingBox.size.width)) {
                [self nextAttempt];
                return;
            }
        }
    }




@end
