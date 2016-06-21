//
//  MainScene.m
//  KITCHEN NIGHTMARES
//
//  Created by Alvaro.
//  Copyright (c) 2013 Apportable. All rights reserved.
//

#import "MainScene.h"

@implementation MainScene

//Aquello que se ejecuta al ser pulsado el boton de Jugar de inicio
-(void)jugar
{
    CCScene *gameplayScene = [CCBReader loadAsScene:@"Gameplay"];
    [[CCDirector sharedDirector] replaceScene:gameplayScene];
}

@end
