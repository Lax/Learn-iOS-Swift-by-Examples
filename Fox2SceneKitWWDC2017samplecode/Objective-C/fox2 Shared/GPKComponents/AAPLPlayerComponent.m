/*
 Copyright (C) 2018 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 GKComponent subclass that defines behaviors of the main character.
 */

#import "AAPLPlayerComponent.h"

@implementation AAPLPlayerComponent

- (void)updateWithDeltaTime:(NSTimeInterval)seconds
{
    [self positionAgentFromNode];
    [super updateWithDeltaTime:seconds];
}


@end
