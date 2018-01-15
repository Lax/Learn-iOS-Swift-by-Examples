/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
Main view controller for this application.
*/

import UIKit
import AVFoundation

class APLViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	@IBOutlet var imageView: UIImageView?
	@IBOutlet var cameraButton: UIBarButtonItem?
	@IBOutlet var overlayView: UIView?
	
	// Camera controls found in the overlay view.
	@IBOutlet var takePictureButton: UIBarButtonItem?
	@IBOutlet var startStopButton: UIBarButtonItem?
	@IBOutlet var delayedPhotoButton: UIBarButtonItem?
	@IBOutlet var doneButton: UIBarButtonItem?

	var imagePickerController = UIImagePickerController()
	
	var cameraTimer = Timer()
	var capturedImages = [UIImage]()
	
	// MARK: - View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()

		imagePickerController.modalPresentationStyle = .currentContext
		imagePickerController.delegate = self
		
		// Remove the camera button if the camera is not currently available.
		if !UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.camera) {
			toolbarItems = self.toolbarItems?.filter { $0 != cameraButton }
		}
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

	fileprivate func finishAndUpdate() {
		dismiss(animated: true, completion: { [weak self] in
			guard let `self` = self else {
				return
			}
			
			if `self`.capturedImages.count > 0 {
				if self.capturedImages.count == 1 {
					// Camera took a single picture.
					`self`.imageView?.image = `self`.capturedImages[0]
				} else {
					// Camera took multiple pictures; use the list of images for animation.
					`self`.imageView?.animationImages = `self`.capturedImages
					`self`.imageView?.animationDuration = 5    // Show each captured photo for 5 seconds.
					`self`.imageView?.animationRepeatCount = 0   // Animate forever (show all photos).
					`self`.imageView?.startAnimating()
				}
				
				// To be ready to start again, clear the captured images array.
				`self`.capturedImages.removeAll()
			}
		})
	}
	
	// MARK: - Toolbar Actions
	
	@IBAction func showImagePickerForCamera(_ sender: UIBarButtonItem) {
		let authStatus = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
		
		if authStatus == AVAuthorizationStatus.denied {
			// Denied access to camera, alert the user.
			// The user has previously denied access. Remind the user that we need camera access to be useful.
			let alert = UIAlertController(title: "Unable to access the Camera",
										  message: "To enable access, go to Settings > Privacy > Camera and turn on Camera access for this app.",
										  preferredStyle: UIAlertControllerStyle.alert)
			
			let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
			alert.addAction(okAction)
			
			let settingsAction = UIAlertAction(title: "Settings", style: .default, handler: { _ in
				// Take the user to Settings app to possibly change permission.
				guard let settingsUrl = URL(string: UIApplicationOpenSettingsURLString) else { return }
				if UIApplication.shared.canOpenURL(settingsUrl) {
					UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
						// Finished opening URL
					})
				}
			})
			alert.addAction(settingsAction)
			
			present(alert, animated: true, completion: nil)
		}
		else if (authStatus == AVAuthorizationStatus.notDetermined) {
			// The user has not yet been presented with the option to grant access to the camera hardware.
			// Ask for permission.
			//
			// (Note: you can test for this case by deleting the app on the device, if already installed).
			// (Note: we need a usage description in our Info.plist to request access.
			//
			AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: { (granted) in
				if granted {
					DispatchQueue.main.async {
						self.showImagePicker(sourceType: UIImagePickerControllerSourceType.camera, button: sender)
					}
				}
			})
		} else {
			// Allowed access to camera, go ahead and present the UIImagePickerController.
			showImagePicker(sourceType: UIImagePickerControllerSourceType.camera, button: sender)
		}
	}

	@IBAction func showImagePickerForPhotoPicker(_ sender: UIBarButtonItem) {
		showImagePicker(sourceType: UIImagePickerControllerSourceType.photoLibrary, button: sender)
	}
	
	fileprivate func showImagePicker(sourceType: UIImagePickerControllerSourceType, button: UIBarButtonItem) {
		// If the image contains multiple frames, stop animating.
		if (imageView?.isAnimating)! {
			imageView?.stopAnimating()
		}
		if capturedImages.count > 0 {
			capturedImages.removeAll()
		}
		
		imagePickerController.sourceType = sourceType
		imagePickerController.modalPresentationStyle =
			(sourceType == UIImagePickerControllerSourceType.camera) ?
				UIModalPresentationStyle.fullScreen : UIModalPresentationStyle.popover
		
		let presentationController = imagePickerController.popoverPresentationController
		presentationController?.barButtonItem = button	 // Display popover from the UIBarButtonItem as an anchor.
		presentationController?.permittedArrowDirections = UIPopoverArrowDirection.any
		
		if sourceType == UIImagePickerControllerSourceType.camera {
			// The user wants to use the camera interface. Set up our custom overlay view for the camera.
			imagePickerController.showsCameraControls = false
		
			// Apply our overlay view containing the toolar to take pictures in various ways.
			overlayView?.frame = (imagePickerController.cameraOverlayView?.frame)!
			imagePickerController.cameraOverlayView = overlayView
		}
		
		present(imagePickerController, animated: true, completion: {
			// Done presenting.
		})
	}
	
	// MARK: - Camera View Actions
	
	@IBAction func done(_ sender: UIBarButtonItem) {
		if cameraTimer.isValid {
			cameraTimer.invalidate()
		}
		finishAndUpdate()
	}
	
	@IBAction func takePhoto(_ sender: UIBarButtonItem) {
		imagePickerController.takePicture()
	}
	
	@IBAction func delayedTakePhoto(_ sender: UIBarButtonItem) {
		// These controls can't be used until the photo has been taken.
		doneButton?.isEnabled = false
		takePictureButton?.isEnabled = false
		delayedPhotoButton?.isEnabled = false
		startStopButton?.isEnabled = false
		
		let fireDate = Date(timeIntervalSinceNow: 5)
		cameraTimer = Timer.init(fire: fireDate, interval: 1.0, repeats: false, block: { timer in
			self.imagePickerController.takePicture()
			
			self.doneButton?.isEnabled = true
			self.takePictureButton?.isEnabled = true
			self.delayedPhotoButton?.isEnabled = true
			self.startStopButton?.isEnabled = true
		})
		RunLoop.main.add(cameraTimer, forMode: RunLoopMode.defaultRunLoopMode)
	}
	
	@IBAction func startTakingPicturesAtIntervals(_ sender: UIBarButtonItem) {
		/*
		Start the timer to take a photo every 1.5 seconds.
		
		CAUTION: for the purpose of this sample, we will continue to take pictures indefinitely.
		Be aware we will run out of memory quickly.  You must decide the proper threshold number of
		photos allowed to take from the camera. One solution to avoid memory constraints is to save each
		taken photo to disk rather than keeping all of them in memory. In low memory situations sometimes
		our "didReceiveMemoryWarning" method will be called in which case we can recover some memory
		and keep the app running.
		*/
		
		// Change the button to represent "Stop" taking pictures.
		startStopButton?.title = NSLocalizedString("Stop", comment: "Title for overlay view controller start/stop button")
		startStopButton?.action = #selector(stopTakingPicturesAtIntervals)
		
		// These buttons can be working while we are running.
		doneButton?.isEnabled = false
		delayedPhotoButton?.isEnabled = false
		takePictureButton?.isEnabled = false

		// Start taking pictures right away.
		cameraTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { timer in
			self.imagePickerController.takePicture()
		}
	}
	
	@IBAction func stopTakingPicturesAtIntervals(_ sender: UIBarButtonItem) {
		// Stop and reset the timer.
		cameraTimer.invalidate()

		finishAndUpdate()
		
		// Make these buttons available again.
		self.doneButton?.isEnabled = true
		self.takePictureButton?.isEnabled = true
		self.delayedPhotoButton?.isEnabled = true
		
		// Reset the button back to start taking pictures again.
		startStopButton?.title = NSLocalizedString("Start", comment: "Title for overlay view controller start/stop button")
		startStopButton?.action = #selector(startTakingPicturesAtIntervals)
	}
	
	// MARK: - UIImagePickerControllerDelegate
	
	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
		let image = info[UIImagePickerControllerOriginalImage]
		capturedImages.append(image as! UIImage)
		
		if !cameraTimer.isValid {
			// Timer is done firing so Finish up until the user stops the timer from taking photos.
			finishAndUpdate()
		}
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: {
			// Done cancel dismiss of image picker.
		})
	}
}

