/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    `SceneManager` is responsible for presenting scenes, requesting future scenes be downloaded, and loading assets in the background.
*/

import SpriteKit

protocol SceneManagerDelegate: class {
    // Called whenever a scene manager has transitioned to a new scene.
    func sceneManagerDidTransitionToScene(scene: SKScene)
}

/**
    A manager for presenting `BaseScene`s. This allows for the preloading of future
    levels while the player is in game to minimize the time spent between levels.
*/
final class SceneManager {
    // MARK: Types
    
    enum SceneIdentifier {
        case Home, End
        case CurrentLevel, NextLevel
        case Level(Int)
    }
    
    // MARK: Properties
    
    /**
        A mapping of `SceneMetadata` instances to the resource requests 
        responsible for accessing the necessary resources for those scenes.
    */
    let sceneLoaderForMetadata: [SceneMetadata: SceneLoader]
    
    /**
        The games input via connected control input sources. Used to
        provide control to scenes after presentation.
    */
    let gameInput: GameInput
    
    /// The view used to choreograph scene transitions.
    let presentingView: SKView
    
    /// The next scene, assuming linear level progression.
    var nextSceneMetadata: SceneMetadata {
        let homeScene = sceneConfigurationInfo.first!
        
        // If there is no current scene, we can only transition back to the home scene.
        guard let currentSceneMetadata = currentSceneMetadata else { return homeScene }
        let index = sceneConfigurationInfo.indexOf(currentSceneMetadata)!
        
        if index + 1 < sceneConfigurationInfo.count {
            // Return the metadata for the next scene in the array.
            return sceneConfigurationInfo[index + 1]
        }
        
        // Otherwise, loop back to the home scene.
        return homeScene
    }
    
    /// The `SceneManager`'s delegate.
    weak var delegate: SceneManagerDelegate?
    
    /// The scene that is currently being presented.
    private (set) var currentSceneMetadata: SceneMetadata?
    
    /// The scene used to indicate progress when additional content needs to be loaded.
    private var progressScene: ProgressScene?
    
    /// Cached array of scene structure loaded from "SceneConfiguration.plist".
    private let sceneConfigurationInfo: [SceneMetadata]
    
    /// An object to act as the observer for `SceneLoaderDidCompleteNotification`s.
    private var loadingCompletedObserver: AnyObject?
    
    // MARK: Initialization
    
    init(presentingView: SKView, gameInput: GameInput) {
        self.presentingView = presentingView
        self.gameInput = gameInput
        
        /*
            Load the game's `SceneConfiguration` plist. This provides information
            about every scene in the game, and the order in which they should be displayed.
        */
        let url = NSBundle.mainBundle().URLForResource("SceneConfiguration", withExtension: "plist")!
        let scenes = NSArray(contentsOfURL: url) as! [[String: AnyObject]]
        
        /*
            Extract the configuration info dictionary for each possible scene,
            and create a `SceneMetadata` instance from the contents of that dictionary.
        */
        sceneConfigurationInfo = scenes.map {
            SceneMetadata(sceneConfiguration: $0)
        }
        
        // Map `SceneMetadata` to a `SceneLoader` for each possible scene.
        var sceneLoaderForMetadata = [SceneMetadata: SceneLoader]()
        for metadata in sceneConfigurationInfo {
            let sceneLoader = SceneLoader(sceneMetadata: metadata)
            sceneLoaderForMetadata[metadata] = sceneLoader
        }
        
        // Keep an immutable copy of the scene loader dictionary.
        self.sceneLoaderForMetadata = sceneLoaderForMetadata
        
        /*
            Because `SceneManager` is marked as `final` and cannot be subclassed,
            it is safe to register for notifications within the initializer.
        */
        registerForNotifications()
    }
    
    deinit {
        // Unregister for `SceneLoader` notifications if the observer is still around.
        if let loadingCompletedObserver = loadingCompletedObserver {
            NSNotificationCenter.defaultCenter().removeObserver(loadingCompletedObserver, name: SceneLoaderDidCompleteNotification, object: nil)
        }
    }
    
    // MARK: Scene Transitioning
    
    /**
        Instructs the scene loader associated with the requested scene to begin
        preparing the scene's resources.

        This method should be called in preparation for the user needing to transition
        to the scene in order to minimize the amount of load time.
    */
    func prepareSceneWithSceneIdentifier(sceneIdentifier: SceneIdentifier) {
        let sceneLoader = sceneLoaderForSceneIdentifier(sceneIdentifier)
        sceneLoader.asynchronouslyLoadSceneForPresentation()
    }
    
    /**
        Loads and presents a scene if the all the resources for the scene are
        currently in memory. Otherwise, presents a progress scene to monitor the progress
        of the resources being downloaded, or display an error if one has occurred.
    */
    func transitionToSceneWithSceneIdentifier(sceneIdentifier: SceneIdentifier) {
        let sceneLoader = sceneLoaderForSceneIdentifier(sceneIdentifier)
        
        
        if sceneLoader.stateMachine.currentState is SceneLoaderResourcesReadyState {
            // The scene is ready to be displayed.
            presentSceneForSceneLoader(sceneLoader)
        }
        else {
            sceneLoader.asynchronouslyLoadSceneForPresentation()
            
            /*
                Mark the `sceneLoader` as `requestedForPresentation` to automatically
                present the scene when loading completes.
            */
            sceneLoader.requestedForPresentation = true
            
            // The scene requires a progress scene to be displayed while its resources are prepared.
            if sceneLoader.requiresProgressSceneForPreparing {
                presentProgressScene(sceneLoader)
            }
        }
    }
    
    // MARK: Scene Presentation
    
    /// Configures and presents a scene.
    func presentSceneForSceneLoader(sceneLoader: SceneLoader) {
        guard let scene = sceneLoader.scene else {
            assertionFailure("Requested presentation for a `sceneLoader` without a valid `scene`.")
            return
        }
                
        // Hold on to a reference to the currently requested scene's metadata.
        currentSceneMetadata = sceneLoader.sceneMetadata

        // Ensure we present the scene on the main queue.
        dispatch_async(dispatch_get_main_queue()) {
            /*
                Provide the scene with a reference to the `SceneLoadingManger`
                so that it can coordinate the next scene that should be loaded.
            */
            scene.sceneManager = self
        
            // Present the scene with a transition.
            let transition = SKTransition.fadeWithDuration(GameplayConfiguration.SceneManager.transitionDuration)
            self.presentingView.presentScene(scene, transition: transition)
            
            /*
                When moving to a new scene in the game, we also start downloading
                on demand resources for any subsequent possible scenes.
            */
            #if os(iOS) || os(tvOS)
            self.beginDownloadingNextPossibleScenes()
            #endif
            
            // Clear any reference to a progress scene that may have been presented.
            self.progressScene = nil
            
            // Notify the delegate that the manager has presented a scene.
            self.delegate?.sceneManagerDidTransitionToScene(scene)
            
            // Restart the scene loading process.
            sceneLoader.stateMachine.enterState(SceneLoaderInitialState.self)
        }
    }
    
    /// Configures the progress scene to show the progress of the `sceneLoader`.
    func presentProgressScene(sceneLoader: SceneLoader) {
        // If the `progressScene` is already being displayed, there's nothing to do.
        guard progressScene == nil else { return }

        // Create a `ProgressScene` for the scene loader.
        progressScene = ProgressScene.progressSceneWithSceneLoader(sceneLoader)
        progressScene!.sceneManager = self
    
        let transition = SKTransition.doorsCloseHorizontalWithDuration(GameplayConfiguration.SceneManager.progressSceneTransitionDuration)
        presentingView.presentScene(progressScene!, transition: transition)
    }
    
    #if os(iOS) || os(tvOS)
    /**
        Begins downloading on demand resources for all scenes that the user may reach next,
        and purges resources for any unreachable scenes that are no longer accessible.
    */
    private func beginDownloadingNextPossibleScenes() {
        let possibleScenes = allPossibleNextScenes()
        
        for sceneMetadata in possibleScenes {
            let resourceRequest = sceneLoaderForMetadata[sceneMetadata]!
            resourceRequest.downloadResourcesIfNecessary()
        }
        
        // Clean up scenes that are no longer accessible.
        let allScenes = Set(sceneLoaderForMetadata.keys)
        let unreachableScenes = allScenes.subtract(possibleScenes)
        
        for sceneMetadata in unreachableScenes {
            let resourceRequest = sceneLoaderForMetadata[sceneMetadata]!
            resourceRequest.purgeResources()
        }
    }
    #endif

    /// Determines all possible scenes that the player may reach after the current scene.
    private func allPossibleNextScenes() -> Set<SceneMetadata> {
        let homeScene = sceneConfigurationInfo.first!
        
        // If there is no current scene, we can only go to the home scene.
        guard let currentSceneMetadata = currentSceneMetadata else {
            return [homeScene]
        }
        
        /*
            In DemoBots, the user can always go home, replay the level, or progress linearly
            to the next level.
            
            This could be expanded to include the previous level, the furthest
            level that has been unlocked, etc. depending on how the game progresses.
        */
        return [homeScene, nextSceneMetadata, currentSceneMetadata]
    }
    
    // MARK: SceneLoader Notifications

    /// Register for notifications of `SceneLoader` download completion.
    func registerForNotifications() {
        // Avoid reregistering for the notification.
        guard loadingCompletedObserver == nil else { return }
        
        loadingCompletedObserver = NSNotificationCenter.defaultCenter().addObserverForName(SceneLoaderDidCompleteNotification, object: nil, queue: NSOperationQueue.mainQueue()) { [unowned self] notification in
            let sceneLoader = notification.object as! SceneLoader
            
            // Ensure this is a `sceneLoader` managed by this `SceneManager`.
            guard let managedSceneLoader = self.sceneLoaderForMetadata[sceneLoader.sceneMetadata] where managedSceneLoader === sceneLoader else { return }
            
            guard sceneLoader.stateMachine.currentState is SceneLoaderResourcesReadyState else {
                fatalError("Received complete notification, but the `stateMachine`'s current state is not ready.")
            }
            
            /*
                If the `sceneLoader` associated with this state has been requested
                for presentation than we will present it here. 
            
                This is used to present the `HomeScene` without any possibility of
                a progress scene.
            */
            if sceneLoader.requestedForPresentation {
                self.presentSceneForSceneLoader(sceneLoader)
            }
            
            // Reset the scene loader's presentation preference.
            sceneLoader.requestedForPresentation = false
        }
    }
    
    // MARK: Convenience
    
    /// Returns the scene loader associated with the scene identifier.
    func sceneLoaderForSceneIdentifier(sceneIdentifier: SceneIdentifier) -> SceneLoader {
        let sceneMetadata: SceneMetadata
        switch sceneIdentifier {
            case .Home:
                sceneMetadata = sceneConfigurationInfo.first!
            
            case .CurrentLevel:
                guard let currentSceneMetadata = currentSceneMetadata else {
                    fatalError("Current scene doesn't exist.")
                }
                sceneMetadata = currentSceneMetadata
            
            case .Level(let number):
                sceneMetadata = sceneConfigurationInfo[number]
            
            case .NextLevel:
                sceneMetadata = nextSceneMetadata
            
            case .End:
                sceneMetadata = sceneConfigurationInfo.last!
        }
        
        return sceneLoaderForMetadata[sceneMetadata]!
    }
}
