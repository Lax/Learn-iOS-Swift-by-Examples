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
        return childNode(withName: "backgroundNode") as? SKSpriteNode
    }
    
    var labelNode: SKLabelNode {
        return backgroundNode!.childNode(withName: "label") as! SKLabelNode
    }
    
    var progressBarNode: SKSpriteNode {
        return backgroundNode!.childNode(withName: "progressBar") as! SKSpriteNode
    }
    
    /*
        Because we're using a factory method for initialization (we want to load
        the scene from a file, but `init(fileNamed:)` is not a designated init),
        we need to make most of the properties `var` and implicitly unwrapped
        optional so we can set the properties after creating the scene with
        `progressScene(withSceneLoader sceneLoader:)`.
    */
    
    /// The scene loader currently handling the requested scene.
    var sceneLoader: SceneLoader!
    
    /// Keeps track of the progress bar's initial width.
    var progressBarInitialWidth: CGFloat!
    
    /// Add child progress objects to track downloading and loading states.
    var progress: Progress? {
        didSet {
            // Unregister as an observer on the old value for the "fractionCompleted" property.
            oldValue?.removeObserver(self, forKeyPath: "fractionCompleted", context: &progressSceneKVOContext)

            // Register as an observer on the initial and for changes to the "fractionCompleted" property.
            progress?.addObserver(self, forKeyPath: "fractionCompleted", options: [.new, .initial], context: &progressSceneKVOContext)
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
    static func progressScene(withSceneLoader loader: SceneLoader) -> ProgressScene {
        // Load the progress scene from its sks file.
        let progressScene = ProgressScene(fileNamed: "ProgressScene")!
        
        progressScene.createCamera()
        progressScene.setup(withSceneLoader: loader)
        
        // Return the setup progress scene.
        return progressScene
    }
    
    func setup(withSceneLoader loader: SceneLoader) {
        // Set the sceneLoader. This may be in the downloading or preparing state.
        self.sceneLoader = loader
        
        // Grab the `sceneLoader`'s progress if it is already loading.
        if let progress = sceneLoader.progress {
            self.progress = progress
        }
        else {
            // Else start loading the scene and hold onto the progress.
            progress = sceneLoader.asynchronouslyLoadSceneForPresentation()
        }
        
        // Register for notifications posted when the `SceneDownloader` fails.
        let defaultCenter = NotificationCenter.default
        downloadFailedObserver = defaultCenter.addObserver(forName: NSNotification.Name.SceneLoaderDidFailNotification, object: sceneLoader, queue: OperationQueue.main) { [unowned self] notification in
            guard let loader = notification.object as? SceneLoader, let error = loader.error else { fatalError("The scene loader has no error to show.") }
            
            self.showError(error as NSError)
        }
    }
    
    deinit {
        // Unregister as an observer of 'SceneLoaderDownloadFailedNotification' notifications.
        if let downloadFailedObserver = downloadFailedObserver {
            NotificationCenter.default.removeObserver(downloadFailedObserver, name: NSNotification.Name.SceneLoaderDidFailNotification, object: sceneLoader)
        }
        
        // Set the progress property to nil which will remove this object as an observer.
        progress = nil
    }
    
    // MARK: Scene Life Cycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        centerCameraOnPoint(point: backgroundNode!.position)

        // Remember the progress bar's initial width. It will change to indicate progress.
        progressBarInitialWidth = progressBarNode.frame.width
        
        if let error = sceneLoader.error {
            // Show the scene loader's error.
            showError(error as NSError)
        }
        else {
            showDefaultState()
        }
    }
    
    // MARK: Key Value Observing (KVO) for NSProgress

    @nonobjc override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        // Check if this is the KVO notification we need.
        
        guard context == &progressSceneKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        if let changedProgress = object as? Progress, changedProgress == progress, keyPath == "fractionCompleted" {
            // Update the progress UI on the main queue.
            DispatchQueue.main.async {
                guard let progress = self.progress else { return }
        
                // Update the progress bar to match the amount of progress completed.
                self.progressBarNode.size.width = self.progressBarInitialWidth * CGFloat(progress.fractionCompleted)
                
                // Display a contextually specific progress description.
                self.labelNode.text = progress.localizedDescription
            }
        }
    }
    
    // MARK: ButtonNodeResponderType
    
    override func buttonTriggered(button: ButtonNode) {
        switch button.buttonIdentifier! {
            case .retry:
                // Set up the progress for a new preparation attempt.
                progress = sceneLoader.asynchronouslyLoadSceneForPresentation()
                sceneLoader.requestedForPresentation = true
                showDefaultState()
            
            case .cancel:
                /*
                    Canceling the parent progress propagates the cancellation to the child
                    progress objects.
                    
                    In `SceneLoaderDownloadingResourcesState` this will cause the completionHandler to
                    be invoked on `beginAccessingResources(withCompletionHandler completionHandler:)`
                    with an NSUserCancelledError. See the NSBundleResourceRequest documentation
                    for more information.
                    
                    In `SceneLoaderPreparingResourcesState` this will cancel all operations.
                */
                progress!.cancel()
            
            default:
                // Allow `BaseScene` to handle the event in `BaseScene+Buttons`.
                super.buttonTriggered(button: button)
        }
    }
    
    // MARK: Convenience
    
    func button(withIdentifier identifier: ButtonIdentifier) -> ButtonNode? {
        return backgroundNode?.childNode(withName: identifier.rawValue) as? ButtonNode
    }
    
    func showDefaultState() {
        progressBarNode.isHidden = false
        
        // Only display the "Cancel" button.
        button(withIdentifier: .home)?.isHidden = true
        button(withIdentifier: .retry)?.isHidden = true
        button(withIdentifier: .cancel)?.isHidden = false
        
        // Reset the button focus.
        resetFocus()
    }
    
    func showError(_ error: NSError) {
        // A new progress object will have to be created for any subsequent loading attempts.
        progress = nil
        
        // Display "Quit" and "Retry" buttons.
        button(withIdentifier: .home)?.isHidden = false
        button(withIdentifier: .retry)?.isHidden = false
        button(withIdentifier: .cancel)?.isHidden = true
        
        // Hide normal state.
        progressBarNode.isHidden = true
        progressBarNode.size.width = 0.0
        
        // Reset the button focus.
        resetFocus()
        
        // Check if the error was due to the user cancelling the operation.
        if error.domain == NSCocoaErrorDomain && error.code == NSUserCancelledError {
            labelNode.text = NSLocalizedString("Cancelled", comment: "Displayed when the user cancels loading.")
        }
        else {
            showAlert(for: error)
        }
    }
    
    func showAlert(for error: NSError) {
        labelNode.text = NSLocalizedString("Failed", comment: "Displayed when the scene loader fails to load a scene.")
        
        // Display the error description in a native alert.
        #if os(OSX)
        guard let window = view?.window else { fatalError("Attempting to present an error when the scene is not in a window.") }
        
        let alert = NSAlert(error: error)
        alert.beginSheetModal(for: window, completionHandler: nil)
        #else
        guard let rootViewController = view?.window?.rootViewController else { fatalError("Attempting to present an error when the scene is not in a view controller.") }
        
        let alert = UIAlertController(title: error.localizedDescription, message: error.localizedRecoverySuggestion, preferredStyle: .alert)
        let alertAction = UIAlertAction(title: "OK", style: .`default`, handler: nil)
        alert.addAction(alertAction)
        
        rootViewController.present(alert, animated: true, completion: nil)
        #endif
    }
}
