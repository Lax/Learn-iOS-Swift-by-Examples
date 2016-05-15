/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A scene used to indicate the progress of loading additional content between scenes.
*/

import SpriteKit

/**
    The KVO context for `ProgressScene` instances. This provides a stable
    address to use as the `context` parameter for the KVO observation methods.
*/
private var progressSceneKVOContext = 0

class ProgressScene: BaseScene {
    // MARK: Properties
    
    /// Returns the background node from the scene.
    override var backgroundNode: SKSpriteNode? {
        return childNodeWithName("backgroundNode") as? SKSpriteNode
    }
    
    var labelNode: SKLabelNode {
        return backgroundNode!.childNodeWithName("label") as! SKLabelNode
    }
    
    var progressBarNode: SKSpriteNode {
        return backgroundNode!.childNodeWithName("progressBar") as! SKSpriteNode
    }
    
    /*
        Because we're using a factory method for initialization (we want to load
        the scene from a file, but `init(fileNamed:)` is not a designated init),
        we need to make most of the properties `var` and implicitly unwrapped
        optional so we can set the properties after creating the scene with
        `progressSceneWithSceneLoader(sceneLoader:)`.
    */
    
    /// The scene loader currently handling the requested scene.
    var sceneLoader: SceneLoader!
    
    /// Keeps track of the progress bar's initial width.
    var progressBarInitialWidth: CGFloat!
    
    /// Add child progress objects to track downloading and loading states.
    var progress: NSProgress? {
        didSet {
            // Unregister as an observer on the old value for the "fractionCompleted" property.
            oldValue?.removeObserver(self, forKeyPath: "fractionCompleted", context: &progressSceneKVOContext)

            // Register as an observer on the initial and for changes to the "fractionCompleted" property.
            progress?.addObserver(self, forKeyPath: "fractionCompleted", options: [.New, .Initial], context: &progressSceneKVOContext)
        }
    }
    
    /// A registered observer object for `SceneLoaderDownloadFailedNotification`s.
    private var downloadFailedObserver: AnyObject?
    
    // MARK: Initializers
    
    /**
        Constructs a `ProgressScene` that will monitor the download
        progress of on demand resources and the loading progress of bringing
        assets into memory.
    */
    static func progressSceneWithSceneLoader(sceneLoader: SceneLoader) -> ProgressScene {
        // Load the progress scene from its sks file.
        let progressScene = ProgressScene(fileNamed: "ProgressScene")!
        
        progressScene.createCamera()
        progressScene.setupWithSceneLoader(sceneLoader)
        
        // Return the setup progress scene.
        return progressScene
    }
    
    func setupWithSceneLoader(sceneLoader: SceneLoader) {
        // Set the sceneLoader. This may be in the downloading or preparing state.
        self.sceneLoader = sceneLoader
        
        // Grab the `sceneLoader`'s progress if it is already loading.
        if let progress = sceneLoader.progress {
            self.progress = progress
        }
        else {
            // Else start loading the scene and hold onto the progress.
            progress = sceneLoader.asynchronouslyLoadSceneForPresentation()
        }
        
        // Register for notifications posted when the `SceneDownloader` fails.
        let defaultCenter = NSNotificationCenter.defaultCenter()
        downloadFailedObserver = defaultCenter.addObserverForName(SceneLoaderDidFailNotification, object: sceneLoader, queue: NSOperationQueue.mainQueue()) { [unowned self] notification in
            guard let sceneLoader = notification.object as? SceneLoader, error = sceneLoader.error else { fatalError("The scene loader has no error to show.") }
            
            self.showErrorStateForError(error)
        }
    }
    
    deinit {
        // Unregister as an observer of 'SceneLoaderDownloadFailedNotification' notifications.
        if let downloadFailedObserver = downloadFailedObserver {
            NSNotificationCenter.defaultCenter().removeObserver(downloadFailedObserver, name: SceneLoaderDidFailNotification, object: sceneLoader)
        }
        
        // Set the progress property to nil which will remove this object as an observer.
        progress = nil
    }
    
    // MARK: Scene Life Cycle
    
    override func didMoveToView(view: SKView) {
        super.didMoveToView(view)
        
        centerCameraOnPoint(backgroundNode!.position)

        // Remember the progress bar's initial width. It will change to indicate progress.
        progressBarInitialWidth = progressBarNode.frame.width
        
        if let error = sceneLoader.error {
            // Show the scene loader's error.
            showErrorStateForError(error)
        }
        else {
            showDefaultState()
        }
    }
    
    // MARK: Key Value Observing (KVO) for NSProgress
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String: AnyObject]?, context: UnsafeMutablePointer<Void>) {
        // Check if this is the KVO notification we need.
        if context == &progressSceneKVOContext && keyPath == "fractionCompleted" && object === progress {
            // Update the progress UI on the main queue.
            dispatch_async(dispatch_get_main_queue()) {
                guard let progress = self.progress else { return }
        
                // Update the progress bar to match the amount of progress completed.
                self.progressBarNode.size.width = self.progressBarInitialWidth * CGFloat(progress.fractionCompleted)
                
                // Display a contextually specific progress description.
                self.labelNode.text = progress.localizedDescription
            }
        }
        else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: ButtonNodeResponderType
    
    override func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
            case .Retry:
                // Set up the progress for a new preparation attempt.
                progress = sceneLoader.asynchronouslyLoadSceneForPresentation()
                sceneLoader.requestedForPresentation = true
                showDefaultState()
            
            case .Cancel:
                /*
                    Canceling the parent progress propagates the cancellation to the child
                    progress objects.
                    
                    In `SceneLoaderDownloadingResourcesState` this will cause the completionHandler to
                    be invoked on `beginAccessingResourcesWithCompletionHandler(_:)`
                    with an NSUserCancelledError. See the NSBundleResourceRequest documentation
                    for more information.
                    
                    In `SceneLoaderPreparingResourcesState` this will cancel all operations.
                */
                progress!.cancel()
            
            default:
                // Allow `BaseScene` to handle the event in `BaseScene+Buttons`.
                super.buttonTriggered(button)
        }
    }
    
    // MARK: Convenience
    
    func buttonWithIdentifier(identifier: ButtonIdentifier) -> ButtonNode? {
        return backgroundNode?.childNodeWithName(identifier.rawValue) as? ButtonNode
    }
    
    func showDefaultState() {
        progressBarNode.hidden = false
        
        // Only display the "Cancel" button.
        buttonWithIdentifier(.Home)?.hidden = true
        buttonWithIdentifier(.Retry)?.hidden = true
        buttonWithIdentifier(.Cancel)?.hidden = false
        
        // Reset the button focus.
        resetFocus()
    }
    
    func showErrorStateForError(error: NSError) {
        // A new progress object will have to be created for any subsequent loading attempts.
        progress = nil
        
        // Display "Quit" and "Retry" buttons.
        buttonWithIdentifier(.Home)?.hidden = false
        buttonWithIdentifier(.Retry)?.hidden = false
        buttonWithIdentifier(.Cancel)?.hidden = true
        
        // Hide normal state.
        progressBarNode.hidden = true
        progressBarNode.size.width = 0.0
        
        // Reset the button focus.
        resetFocus()
        
        // Check if the error was due to the user cancelling the operation.
        if error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError {
            labelNode.text = NSLocalizedString("Cancelled", comment: "Displayed when the user cancels loading.")
        }
        else {
            showErrorAlert(error)
        }
    }
    
    func showErrorAlert(error: NSError) {
        labelNode.text = NSLocalizedString("Failed", comment: "Displayed when the scene loader fails to load a scene.")
        
        // Display the error description in a native alert.
        #if os(OSX)
        guard let window = view?.window else { fatalError("Attempting to present an error when the scene is not in a window.") }
        
        let alert = NSAlert(error: error)
        alert.beginSheetModalForWindow(window, completionHandler: nil)
        #else
        guard let rootViewController = view?.window?.rootViewController else { fatalError("Attempting to present an error when the scene is not in a view controller.") }
        
        let alert = UIAlertController(title: error.localizedDescription, message: error.localizedRecoverySuggestion, preferredStyle: .Alert)
        let alertAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(alertAction)
        
        rootViewController.presentViewController(alert, animated: true, completion: nil)
        #endif
    }
}
