/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A protocol representing a type that loads resources into memory and keeps them around for future use. Classes adopt this protocol to indicate that they can preload SpriteKit textures and other resources in advance of when they will be needed, to improve performance when those resources are accessed.
*/

/// A type capable of loading and managing static resources.
protocol ResourceLoadableType: class {
    /// Indicates that static resources need to be loaded.
    static var resourcesNeedLoading: Bool { get }
    
    /// Loads static resources into memory.
    static func loadResources(withCompletionHandler completionHandler: @escaping () -> ())
    
    /// Releases any static resources that can be loaded again later.
    static func purgeResources()
}
