/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A utility function for statically loading assets shared by instances of each of the characters (and their associated types).
*/

import SpriteKit

func LoadSharedDemoBotsAssets() {
    BeamNode.loadSharedAssets()
    FlyingBot.loadSharedAssets()
    GroundBot.loadSharedAssets()
    PlayerBot.loadSharedAssets()
    TaskBot.loadSharedAssets()
}