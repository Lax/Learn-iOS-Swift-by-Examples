/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A class encapsulating the work necessary to load a scene and its resources based on a given `SceneMetadata` instance.
*/

import GameplayKit

/*
    Use these constants with `NSNotificationCenter` to listen for events from the
    scene resource states.

    The `object` property of the notification will contain the `SceneLoader`.
*/
extension NSNotification.Name {
    public static let SceneLoaderDidCompleteNotification    = NSNotification.Name(rawValue: "SceneLoaderDidCompleteNotification")
    public static let SceneLoaderDidFailNotification        = NSNotification.Name(rawValue: "SceneLoaderDidFailNotification")
}

/// A class encapsulating the work necessary to load a scene and its resources based on a given `SceneMetadata` instance.
class SceneLoader {
    // MARK: Properties
    
    lazy var stateMachine: GKStateMachine = {
        var states = [
            SceneLoaderInitialState(sceneLoader: self),
            SceneLoaderResourcesAvailableState(sceneLoader: self),
            SceneLoaderPreparingResourcesState(sceneLoader: self),
            SceneLoaderResourcesReadyState(sceneLoader: self)
        ]
        
        #if os(iOS) || os(tvOS)
        // States associated with on demand resources only apply to iOS and tvOS.
        states += [
            SceneLoaderDownloadingResourcesState(sceneLoader: self),
            SceneLoaderDownloadFailedState(sceneLoader: self)
        ]
        #endif
        
        return GKStateMachine(states: states)
    }()
    
    /// The metadata describing the scene whose resources should be loaded.
    let sceneMetadata: SceneMetadata
    
    /// The actual scene after it has been successfully loaded. Set in `SceneLoaderPreparingResourcesState`.
    var scene: BaseScene?
    
    /// The error, if one occurs, from fetching resources.
    var error: Error?
    
    /**
        A parent progress, constructed when `prepareSceneForPresentation()`
        is called. Child progress objects are added by the 
        `SceneLoaderDownloadingResourcesState` and `SceneLoaderPreparingResourcesState` 
        states.
    */
    var progress: Progress? {
        didSet {
            guard let progress = progress else { return }

            progress.cancellationHandler = { [unowned self] in
                // Cleanup the `SceneLoader`'s state and assign an appropriate error.
                self.requestedForPresentation = false
                self.error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
                
                // Notify any interested objects that the download was not completed.
                NotificationCenter.default.post(name: NSNotification.Name.SceneLoaderDidFailNotification, object: self)
            }
        }
    }
    
    #if os(iOS) || os(tvOS)
    /**
        The current `NSBundleResourceRequest` used to download the necessary resources.
        We keep a reference to the resource request so that it can be modified
        while it is in progress, and pin the resources when complete.
        
        For example: the `loadingPriority` is updated when the user reaches
        the loading scene, and the request is cancelled and released as part of
        cleaning up the scene loader.
    */
    var bundleResourceRequest: NSBundleResourceRequest?
    #endif

    /**
        A computed property that returns `true` if the scene's resources are expected
        to take a long time to load.
    */
    var requiresProgressSceneForPreparing: Bool {
        return sceneMetadata.loadableTypes.contains { $0.resourcesNeedLoading }
    }
    
    /**
        Indicates whether the scene we are loading has been requested to be presented
        to the user. Used to change how aggressively the resources are being made available.
    */
    var requestedForPresentation = false {
        didSet {
            /*
                Don't adjust resource loading priorities if `requestedForPresentation`
                was just set to `false`.
            */
            guard requestedForPresentation else { return }
            
            #if os(iOS) || os(tvOS)
            if stateMachine.currentState is SceneLoaderDownloadingResourcesState {
                /*
                    The presentation of this scene is blocked by downloading the
                    scene's resources, so mark the bundle resource request's loading
                    priority as urgent.
                */
                bundleResourceRequest?.loadingPriority = NSBundleResourceRequestLoadingPriorityUrgent
            }
            #endif
            
            if let preparingState = stateMachine.currentState as? SceneLoaderPreparingResourcesState {
                /*
                    The presentation of this scene is blocked by the preparation of
                    the scene's resources, so bump up the quality of service of
                    the operation queue that is preparing the resources.
                */
                preparingState.operationQueue.qualityOfService = .userInteractive
            }
        }
    }
    
    // MARK: Initialization
    
    init(sceneMetadata: SceneMetadata) {
        self.sceneMetadata = sceneMetadata
        
        // Enter the initial state as soon as the scene loader is created.
        stateMachine.enter(SceneLoaderInitialState.self)
    }
    
    #if os(iOS) || os(tvOS)
    /**
        Moves the state machine to the appropriate state when a request is made to
        download the `sceneLoader`'s scene.
    */
    func downloadResourcesIfNecessary() {
        if sceneMetadata.requiresOnDemandResources {
            stateMachine.enter(SceneLoaderDownloadingResourcesState.self)
        }
        else {
            stateMachine.enter(SceneLoaderResourcesAvailableState.self)
        }
    }
    #endif
    
    /**
        Ensures that the resources for a scene are downloaded and begins loading them into memory.

        Creates and returns a progress object for tracking loading the scene for presentation.
        Note: On iOS there are two distinct steps to loading: downloading on demand resources
        -> loading assets into memory.
    */
    func asynchronouslyLoadSceneForPresentation() -> Progress {
        // If a valid progress already exists it means the scene is already being prepared.
        if let progress = progress , !progress.isCancelled {
            return progress
        }

        switch stateMachine.currentState {
            case is SceneLoaderResourcesReadyState:
                // No additional work needs to be done.
                progress = Progress(totalUnitCount: 0)

            
            case is SceneLoaderResourcesAvailableState:
                progress = Progress(totalUnitCount: 1)
                
                /*
                    Begin preparing the scene's resources.

                    The `SceneLoaderPreparingResourcesState`'s progress is added to the `SceneLoader`s
                    progress when the operation is started.
                */
                stateMachine.enter(SceneLoaderPreparingResourcesState.self)

            default:
                #if os(iOS) || os(tvOS)
                // Set two units of progress to account for both downloading and then loading into memory.
                progress = Progress(totalUnitCount: 2)
                
                let downloadingState = stateMachine.state(forClass: SceneLoaderDownloadingResourcesState.self)!
                downloadingState.enterPreparingStateWhenFinished = true
                
                stateMachine.enter(SceneLoaderDownloadingResourcesState.self)
                
                guard let bundleResourceRequest = bundleResourceRequest else {
                    fatalError("In the `SceneLoaderDownloadingResourcesState`, but a valid resource request has not been created.")
                }
                
                /*
                    Add the `bundleResourceRequest`'s' progress to the `sceneLoader`'s overall progress.

                    Note: The `SceneLoaderPreparingResourcesState`'s progress will be added to
                    the `SceneLoader`'s progress when the state is entered and the
                    operation is started.
                */
                progress!.addChild(bundleResourceRequest.progress, withPendingUnitCount: 1)
                
                // Increase the priority for the requested scene because it is about to be presented.
                bundleResourceRequest.loadingPriority = 0.8
                #elseif os(OSX)
                fatalError("Invalid `currentState`: \(stateMachine.currentState).")
                #endif
        }
        
        return progress!
    }
    
    #if os(iOS) || os(tvOS)
    /// Marks the resources as no longer necessary cancelling any pending requests.
    func purgeResources() {
        // Cancel any pending requests.
        progress?.cancel()
        
        // Reset the state machine back to the initial state.
        stateMachine.enter(SceneLoaderInitialState.self)

        // Unpin any on demand resources.
        bundleResourceRequest = nil
        
        // Release the loaded scene instance.
        scene = nil
        
        // Discard any errors in preparation for a new loading attempt.
        error = nil
    }
    #endif
}
