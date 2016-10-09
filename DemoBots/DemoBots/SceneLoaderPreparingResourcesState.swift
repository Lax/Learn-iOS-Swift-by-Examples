/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A state used by `SceneLoader` to indicate that resources for the scene are being loaded into memory.
*/

import GameplayKit

class SceneLoaderPreparingResourcesState: GKState {
    // MARK: Properties
    
    unowned let sceneLoader: SceneLoader
    
    /// An internal operation queue for loading scene resources in the background.
    let operationQueue = OperationQueue()
    
    /**
        An NSProgress object that can be used to query and monitor progress of 
        the resources being loaded. Also supports cancellation.
    */
    var progress: Progress? {
        didSet {
            guard let progress = progress else { return }
            
            /*
                Setup the progress object's cancellation handler to cancel any pending operations and update
                the state machine to the appropriate state.
            */
            progress.cancellationHandler = { [unowned self] in
                self.cancel()
            }
        }
    }

    // MARK: Initialization
    
    init(sceneLoader: SceneLoader) {
        self.sceneLoader = sceneLoader
        
        // Set the name of the operation queue to identify the queue at run time.
        operationQueue.name = "com.example.apple-samplecode.sceneloaderpreparingresourcesstate"
        
        /*
            The preparing resources state is often initiated automatically by the `LevelScene`
            state machine. Setting the `qualityOfService` as `.Utility` reflects the
            fact that this is an important task, but is not blocking the user.
        */
        operationQueue.qualityOfService = .utility
    }
    
    // MARK: GKState Life Cycle
    
    override func didEnter(from previousState: GKState?) {
        super.didEnter(from: previousState)
        
        // Begin loading the scene and associated resources in the background.
        loadResourcesAsynchronously()
    }
    
    override func isValidNextState(_ stateClass: AnyClass) -> Bool {
        switch stateClass {
            // Only valid if the `sceneLoader`'s scene has been loaded.
            case is SceneLoaderResourcesReadyState.Type where sceneLoader.scene != nil:
                return true
            
            case is SceneLoaderResourcesAvailableState.Type:
                return true
            
            default:
                return false
        }
    }
    
    // MARK: Load Resources
    
    /**
        Loads all resources specific to the requested scene with a series of
        operations.

        Note: You must ensure the resources have been downloaded before calling 
        this method. Attempting to load the scene without the necessary 
        resources in local storage will result in a crash.
    */
    private func loadResourcesAsynchronously() {
        let sceneMetadata = sceneLoader.sceneMetadata
        
        /*
            Create an `NSProgress` object with the total unit count equal to the number of entities that
            need to be loaded plus a unit for loading the scene itself.
        */
        let loadingProgress = Progress(totalUnitCount: sceneMetadata.loadableTypes.count + 1)
        
        // Add the `SceneLoaderPreparingResourcesState`'s progress to the overall `sceneLoader`'s progress.
        sceneLoader.progress?.addChild(loadingProgress, withPendingUnitCount: 1)
        progress = loadingProgress

        /*
            Create an operation to load the scene. Dependencies will be added to this operation so that
            it does not begin to execute until all the necessary resources have been loaded.
        */
        let loadSceneOperation = LoadSceneOperation(sceneMetadata: sceneMetadata)
        loadingProgress.addChild(loadSceneOperation.progress, withPendingUnitCount: 1)
        
        loadSceneOperation.completionBlock = { [unowned self] in
            // Enter the next state on the main queue.
            DispatchQueue.main.async {
                self.sceneLoader.scene = loadSceneOperation.scene
                
                let didEnterReadyState = self.stateMachine!.enter(SceneLoaderResourcesReadyState.self)
                assert(didEnterReadyState, "Failed to transition to `ReadyState` after resources were prepared.")
            }
        }
        
        /*
            Create an operation for each resource that needs to be loaded. Make `loadSceneOperation`
            dependent on each new operation.
        */
        for loaderType in sceneMetadata.loadableTypes {
            let loadResourcesOperation = LoadResourcesOperation(loadableType: loaderType)
            
            // Update the progress object's completed unit count when the operation has completed.
            loadingProgress.addChild(loadResourcesOperation.progress, withPendingUnitCount: 1)
            
            // Make `loadSceneOperation` dependent on the completion of the new operation.
            loadSceneOperation.addDependency(loadResourcesOperation)
            
            // Add `loadResourcesOperation` to be managed by the operation queue.
            operationQueue.addOperation(loadResourcesOperation)
        }
        
        // Add `loadSceneOperation` to the operation queue now it has all its dependancies setup.
        operationQueue.addOperation(loadSceneOperation)
    }
    
    /// Cancels all pending operations and sets an appropriate error.
    func cancel() {
        // Ensure all operations are cancelled.
        operationQueue.cancelAllOperations()
        sceneLoader.scene = nil
        sceneLoader.error = NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError, userInfo: nil)
        
        // Enter the next state on the main queue.
        DispatchQueue.main.async {
            self.stateMachine!.enter(SceneLoaderResourcesAvailableState.self)
            
            // Notify that loading was not completed.
            NotificationCenter.default.post(name: NSNotification.Name.SceneLoaderDidFailNotification, object: self.sceneLoader)
        }
    }
}
