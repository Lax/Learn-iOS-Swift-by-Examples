/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A protocol representing the ability of a `GKEntity` to respond to the start and end of a physics contact with another `GKEntity`.
*/

import GameplayKit

protocol ContactNotifiableType {

    func contactWithEntityDidBegin(_ entity: GKEntity)
    
    func contactWithEntityDidEnd(_ entity: GKEntity)
}
