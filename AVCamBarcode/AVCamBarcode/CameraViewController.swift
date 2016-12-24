/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	View controller for camera interface.
*/

import UIKit
import AVFoundation

class CameraViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, ItemSelectionViewControllerDelegate {
	// MARK: View Controller Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		// Disable UI. The UI is enabled if and only if the session starts running.
		metadataObjectTypesButton.isEnabled = false
		sessionPresetsButton.isEnabled = false
		cameraButton.isEnabled = false
		zoomSlider.isEnabled = false
		
		// Add the open barcode gesture recognizer to the region of interest view.
		previewView.addGestureRecognizer(openBarcodeURLGestureRecognizer)
		
		// Set up the video preview view.
		previewView.session = session
		
		/*
			Check video authorization status. Video access is required and audio
			access is optional. If audio access is denied, audio is not recorded
			during movie recording.
		*/
		switch AVCaptureDevice.authorizationStatus(forMediaType: AVMediaTypeVideo) {
			case .authorized:
				// The user has previously granted access to the camera.
				break
			
			case .notDetermined:
				/*
					The user has not yet been presented with the option to grant
					video access. We suspend the session queue to delay session
					setup until the access request has completed.
				*/
				sessionQueue.suspend()
				AVCaptureDevice.requestAccess(forMediaType: AVMediaTypeVideo, completionHandler: { [unowned self] granted in
					if !granted {
						self.setupResult = .notAuthorized
					}
					self.sessionQueue.resume()
				})
		
			default:
				// The user has previously denied access.
				setupResult = .notAuthorized
		}
		
		/*
			Setup the capture session.
			In general it is not safe to mutate an AVCaptureSession or any of its
			inputs, outputs, or connections from multiple threads at the same time.
		
			Why not do all of this on the main queue?
			Because AVCaptureSession.startRunning() is a blocking call which can
			take a long time. We dispatch session setup to the sessionQueue so
			that the main queue isn't blocked, which keeps the UI responsive.
		*/
		sessionQueue.async { [unowned self] in
			self.configureSession()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		sessionQueue.async { [unowned self] in
			switch self.setupResult {
				case .success:
					// Only setup observers and start the session running if setup succeeded.
					self.addObservers()
					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning
				
				case .notAuthorized:
					DispatchQueue.main.async { [unowned self] in
						let message = NSLocalizedString("AVCamBarcode doesn't have permission to use the camera, please change privacy settings", comment: "Alert message when the user has denied access to the camera")
						let	alertController = UIAlertController(title: "AVCamBarcode", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
						alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"), style: .`default`, handler: { action in
							UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
						}))
						
						self.present(alertController, animated: true, completion: nil)
					}
				
				case .configurationFailed:
					DispatchQueue.main.async { [unowned self] in
						let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
						let alertController = UIAlertController(title: "AVCamBarcode", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
						
						self.present(alertController, animated: true, completion: nil)
					}
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		sessionQueue.async { [unowned self] in
			if self.setupResult == .success {
				self.session.stopRunning()
				self.isSessionRunning = self.session.isRunning
				self.removeObservers()
			}
		}
		
		super.viewWillDisappear(animated)
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "SelectMetadataObjectTypes" {
			let navigationController = segue.destination as! UINavigationController
			
			let itemSelectionViewController = navigationController.viewControllers[0] as! ItemSelectionViewController
			itemSelectionViewController.title = NSLocalizedString("Metadata Object Types", comment: "The title when selecting metadata object types.")
			itemSelectionViewController.delegate = self
			itemSelectionViewController.identifier = metadataObjectTypeItemSelectionIdentifier
			itemSelectionViewController.allItems = metadataOutput.availableMetadataObjectTypes as! [String]
			itemSelectionViewController.selectedItems = metadataOutput.metadataObjectTypes as! [String]
			itemSelectionViewController.allowsMultipleSelection = true
		}
		else if segue.identifier == "SelectSessionPreset" {
			let navigationController = segue.destination as! UINavigationController
			
			let itemSelectionViewController = navigationController.viewControllers[0] as! ItemSelectionViewController
			itemSelectionViewController.title = NSLocalizedString("Session Presets", comment: "The title when selecting a session preset.")
			itemSelectionViewController.delegate = self
			itemSelectionViewController.identifier = sessionPresetItemSelectionIdentifier
			itemSelectionViewController.allItems = availableSessionPresets()
			itemSelectionViewController.selectedItems = [session.sessionPreset]
			itemSelectionViewController.allowsMultipleSelection = false
		}
	}
	
    override var shouldAutorotate: Bool {
		// Do not allow rotation if the region of interest is being resized.
		return !previewView.isResizingRegionOfInterest
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
			let deviceOrientation = UIDevice.current.orientation
			guard let newVideoOrientation = deviceOrientation.videoOrientation, deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
				return
			}
			
			let oldSize = view.frame.size
			let oldVideoOrientation = videoPreviewLayerConnection.videoOrientation
			videoPreviewLayerConnection.videoOrientation = newVideoOrientation
			
			/*
				When we transition to the new size, we need to adjust the region
				of interest's origin and size so that it stays anchored relative
				to the camera.
			*/
			coordinator.animate(alongsideTransition: { [unowned self] context in
				
					let oldRegionOfInterest = self.previewView.regionOfInterest
					var newRegionOfInterest = CGRect()
				
					if oldVideoOrientation == .landscapeRight && newVideoOrientation == .landscapeLeft {
						newRegionOfInterest.origin.x = oldSize.width - oldRegionOfInterest.origin.x - oldRegionOfInterest.size.width
						newRegionOfInterest.origin.y = oldRegionOfInterest.origin.y
						newRegionOfInterest.size.width = oldRegionOfInterest.size.width
						newRegionOfInterest.size.height = oldRegionOfInterest.size.height
					}
					else if oldVideoOrientation == .landscapeRight && newVideoOrientation == .portrait {
						newRegionOfInterest.origin.x = size.width - oldRegionOfInterest.origin.y - oldRegionOfInterest.size.height
						newRegionOfInterest.origin.y = oldRegionOfInterest.origin.x
						newRegionOfInterest.size.width = oldRegionOfInterest.size.height
						newRegionOfInterest.size.height = oldRegionOfInterest.size.width
					}
					else if oldVideoOrientation == .landscapeLeft && newVideoOrientation == .landscapeRight {
						newRegionOfInterest.origin.x = oldSize.width - oldRegionOfInterest.origin.x - oldRegionOfInterest.size.width
						newRegionOfInterest.origin.y = oldRegionOfInterest.origin.y
						newRegionOfInterest.size.width = oldRegionOfInterest.size.width
						newRegionOfInterest.size.height = oldRegionOfInterest.size.height
					}
					else if oldVideoOrientation == .landscapeLeft && newVideoOrientation == .portrait {
						newRegionOfInterest.origin.x = oldRegionOfInterest.origin.y
						newRegionOfInterest.origin.y = oldSize.width - oldRegionOfInterest.origin.x - oldRegionOfInterest.size.width
						newRegionOfInterest.size.width = oldRegionOfInterest.size.height
						newRegionOfInterest.size.height = oldRegionOfInterest.size.width
					}
					else if oldVideoOrientation == .portrait && newVideoOrientation == .landscapeRight {
						newRegionOfInterest.origin.x = oldRegionOfInterest.origin.y
						newRegionOfInterest.origin.y = size.height - oldRegionOfInterest.origin.x - oldRegionOfInterest.size.width
						newRegionOfInterest.size.width = oldRegionOfInterest.size.height
						newRegionOfInterest.size.height = oldRegionOfInterest.size.width
					}
					else if oldVideoOrientation == .portrait && newVideoOrientation == .landscapeLeft {
						newRegionOfInterest.origin.x = oldSize.height - oldRegionOfInterest.origin.y - oldRegionOfInterest.size.height
						newRegionOfInterest.origin.y = oldRegionOfInterest.origin.x
						newRegionOfInterest.size.width = oldRegionOfInterest.size.height
						newRegionOfInterest.size.height = oldRegionOfInterest.size.width
					}
					
					self.previewView.setRegionOfInterestWithProposedRegionOfInterest(newRegionOfInterest)
					
				},
				completion: { [unowned self] context in
					self.sessionQueue.async {
						self.metadataOutput.rectOfInterest = self.previewView.videoPreviewLayer.metadataOutputRectOfInterest(for: self.previewView.regionOfInterest)
					}
					
					// Remove the old metadata object overlays.
					self.removeMetadataObjectOverlayLayers()
				}
			)
		}
	}
	
	// MARK: Session Management
	
	private enum SessionSetupResult {
		case success
		case notAuthorized
		case configurationFailed
	}
	
	private let session = AVCaptureSession()
	
	private var isSessionRunning = false
	
	private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], target: nil) // Communicate with the session and other session objects on this queue.
	
	private var setupResult: SessionSetupResult = .success
	
	var videoDeviceInput: AVCaptureDeviceInput!
	
	@IBOutlet private var previewView: PreviewView!
	
	// Call this on the session queue.
	private func configureSession() {
		if self.setupResult != .success {
			return
		}
		
		session.beginConfiguration()
		
		// Add video input.
		do {
			var defaultVideoDevice: AVCaptureDevice?
			
			// Choose the back dual camera if available, otherwise default to a wide angle camera.
			if let dualCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInDuoCamera, mediaType: AVMediaTypeVideo, position: .back) {
				defaultVideoDevice = dualCameraDevice
			}
			else if let backCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .back) {
				// If the back dual camera is not available, default to the back wide angle camera.
				defaultVideoDevice = backCameraDevice
			}
			else if let frontCameraDevice = AVCaptureDevice.defaultDevice(withDeviceType: .builtInWideAngleCamera, mediaType: AVMediaTypeVideo, position: .front) {
				// In some cases where users break their phones, the back wide angle camera is not available. In this case, we should default to the front wide angle camera.
				defaultVideoDevice = frontCameraDevice
			}
			
			let videoDeviceInput = try AVCaptureDeviceInput(device: defaultVideoDevice)
			
			if session.canAddInput(videoDeviceInput) {
				session.addInput(videoDeviceInput)
				self.videoDeviceInput = videoDeviceInput
				
				DispatchQueue.main.async {
					/*
						Why are we dispatching this to the main queue?
						Because AVCaptureVideoPreviewLayer is the backing layer for PreviewView and UIView
						can only be manipulated on the main thread.
						Note: As an exception to the above rule, it is not necessary to serialize video orientation changes
						on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
					
						Use the status bar orientation as the initial video orientation. Subsequent orientation changes are
						handled by CameraViewController.viewWillTransition(to:with:).
					*/
					let statusBarOrientation = UIApplication.shared.statusBarOrientation
					var initialVideoOrientation: AVCaptureVideoOrientation = .portrait
					if statusBarOrientation != .unknown {
						if let videoOrientation = statusBarOrientation.videoOrientation {
							initialVideoOrientation = videoOrientation
						}
					}
					
					self.previewView.videoPreviewLayer.connection.videoOrientation = initialVideoOrientation
				}
			}
			else {
				print("Could not add video device input to the session")
				setupResult = .configurationFailed
				session.commitConfiguration()
				return
			}
		}
		catch {
			print("Could not create video device input: \(error)")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}
		
		// Add metadata output.
		if session.canAddOutput(metadataOutput) {
			session.addOutput(metadataOutput)
			
			// Set this view controller as the delegate for metadata objects.
			metadataOutput.setMetadataObjectsDelegate(self, queue: metadataObjectsQueue)
			metadataOutput.metadataObjectTypes = metadataOutput.availableMetadataObjectTypes // Use all metadata object types by default.
			metadataOutput.rectOfInterest = CGRect.zero
		}
		else {
			print("Could not add metadata output to the session")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}
		
		session.commitConfiguration()
	}

	private let metadataOutput = AVCaptureMetadataOutput()
	
	private let metadataObjectsQueue = DispatchQueue(label: "metadata objects queue", attributes: [], target: nil)
	
	@IBOutlet private var sessionPresetsButton: UIButton!
	
	private func availableSessionPresets() -> [String] {
		let allSessionPresets = [AVCaptureSessionPresetPhoto,
		                         AVCaptureSessionPresetLow,
		                         AVCaptureSessionPresetMedium,
		                         AVCaptureSessionPresetHigh,
		                         AVCaptureSessionPreset352x288,
		                         AVCaptureSessionPreset640x480,
		                         AVCaptureSessionPreset1280x720,
		                         AVCaptureSessionPresetiFrame960x540,
		                         AVCaptureSessionPresetiFrame1280x720,
		                         AVCaptureSessionPreset1920x1080,
		                         AVCaptureSessionPreset3840x2160]
		
		var availableSessionPresets = [String]()
		for sessionPreset in allSessionPresets {
			if session.canSetSessionPreset(sessionPreset) {
				availableSessionPresets.append(sessionPreset)
			}
		}
		
		return availableSessionPresets
	}
	
	// MARK: Device Configuration
	
	@IBOutlet private var cameraButton: UIButton!
	
	@IBOutlet private var cameraUnavailableLabel: UILabel!
	
	private let videoDeviceDiscoverySession = AVCaptureDeviceDiscoverySession(deviceTypes: [.builtInWideAngleCamera, .builtInDuoCamera], mediaType: AVMediaTypeVideo, position: .unspecified)!
	
	@IBAction private func changeCamera() {
		metadataObjectTypesButton.isEnabled = false
		sessionPresetsButton.isEnabled = false
		cameraButton.isEnabled = false
		zoomSlider.isEnabled = false
		
		// Remove the metadata overlay layers, if any.
		removeMetadataObjectOverlayLayers()
		
		DispatchQueue.main.async { [unowned self] in
			let currentVideoDevice = self.videoDeviceInput.device
			let currentPosition = currentVideoDevice!.position
			
			let preferredPosition: AVCaptureDevicePosition
			let preferredDeviceType: AVCaptureDeviceType
			
			switch currentPosition {
				case .unspecified, .front:
					preferredPosition = .back
					preferredDeviceType = .builtInDuoCamera
				
				case .back:
					preferredPosition = .front
					preferredDeviceType = .builtInWideAngleCamera
			}
			
			let devices = self.videoDeviceDiscoverySession.devices!
			var newVideoDevice: AVCaptureDevice? = nil
			
			// First, look for a device with both the preferred position and device type. Otherwise, look for a device with only the preferred position.
			if let device = devices.filter({ $0.position == preferredPosition && $0.deviceType == preferredDeviceType }).first {
				newVideoDevice = device
			}
			else if let device = devices.filter({ $0.position == preferredPosition }).first {
				newVideoDevice = device
			}
			
			if let videoDevice = newVideoDevice {
				do {
					let videoDeviceInput = try AVCaptureDeviceInput.init(device: videoDevice)
					
					self.session.beginConfiguration()
					
					// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
					self.session.removeInput(self.videoDeviceInput)
					
					/*
						When changing devices, a session preset that may be supported
						on one device may not be supported by another. To allow the
						user to successfully switch devices, we must save the previous
						session preset, set the default session preset (High), and
						attempt to restore it after the new video device has been
						added. For example, the 4K session preset is only supported
						by the back device on the iPhone 6s and iPhone 6s Plus. As a
						result, the session will not let us add a video device that
						does not support the current session preset.
					*/
					let previousSessionPreset = self.session.sessionPreset
					self.session.sessionPreset = AVCaptureSessionPresetHigh
					
					if self.session.canAddInput(videoDeviceInput) {
						self.session.addInput(videoDeviceInput)
						self.videoDeviceInput = videoDeviceInput
					}
					else {
						self.session.addInput(self.videoDeviceInput)
					}
					
					// Restore the previous session preset if we can.
					if self.session.canSetSessionPreset(previousSessionPreset) {
						self.session.sessionPreset = previousSessionPreset
					}
					
					self.session.commitConfiguration()
				}
				catch {
					print("Error occured while creating video device input: \(error)")
				}
			}
			
			DispatchQueue.main.async { [unowned self] in
				self.metadataObjectTypesButton.isEnabled = true
				self.sessionPresetsButton.isEnabled = true
				self.cameraButton.isEnabled = self.videoDeviceDiscoverySession.uniqueDevicePositionsCount() > 1
				self.zoomSlider.isEnabled = true
				self.zoomSlider.maximumValue = Float(min(self.videoDeviceInput.device.activeFormat.videoMaxZoomFactor, CGFloat(8.0)))
				self.zoomSlider.value = Float(self.videoDeviceInput.device.videoZoomFactor)
			}
		}
	}
	
	@IBOutlet private var zoomSlider: UISlider!
	
	@IBAction private func zoomCamera(with zoomSlider: UISlider) {
		do {
			try videoDeviceInput.device.lockForConfiguration()
			videoDeviceInput.device.videoZoomFactor = CGFloat(zoomSlider.value)
			videoDeviceInput.device.unlockForConfiguration()
		}
		catch {
			print("Could not lock for configuration: \(error)")
		}
	}
	
	// MARK: KVO and Notifications
	
	private var sessionRunningObserveContext = 0
	
	private var previewViewRegionOfInterestObserveContext = 0
	
	private func addObservers() {
		session.addObserver(self, forKeyPath: "running", options: .new, context: &sessionRunningObserveContext)
		/*
			Observe the previewView's regionOfInterest to update the AVCaptureMetadataOutput's
			rectOfInterest when the user finishes resizing the region of interest.
		*/
		previewView.addObserver(self, forKeyPath: "regionOfInterest", options: .new, context: &previewViewRegionOfInterestObserveContext)
		
		NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: Notification.Name("AVCaptureSessionRuntimeErrorNotification"), object: session)
		
		/*
			A session can only run when the app is full screen. It will be interrupted
			in a multi-app layout, introduced in iOS 9, see also the documentation of
			AVCaptureSessionInterruptionReason. Add observers to handle these session
			interruptions and show a preview is paused message. See the documentation
			of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
		*/
		NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: Notification.Name("AVCaptureSessionWasInterruptedNotification"), object: session)
		NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: Notification.Name("AVCaptureSessionInterruptionEndedNotification"), object: session)
	}
	
	private func removeObservers() {
		NotificationCenter.default.removeObserver(self)
		
		session.removeObserver(self, forKeyPath: "running", context: &sessionRunningObserveContext)
		previewView.removeObserver(self, forKeyPath: "regionOfInterest", context: &previewViewRegionOfInterestObserveContext)
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
		let newValue = change?[.newKey] as AnyObject?
		
		if context == &sessionRunningObserveContext {
			guard let isSessionRunning = newValue?.boolValue else { return }
			
			DispatchQueue.main.async { [unowned self] in
				self.metadataObjectTypesButton.isEnabled = isSessionRunning
				self.sessionPresetsButton.isEnabled = isSessionRunning
				self.cameraButton.isEnabled = isSessionRunning && self.videoDeviceDiscoverySession.uniqueDevicePositionsCount() > 1
				self.zoomSlider.isEnabled = isSessionRunning
				self.zoomSlider.maximumValue = Float(min(self.videoDeviceInput.device.activeFormat.videoMaxZoomFactor, CGFloat(8.0)))
				self.zoomSlider.value = Float(self.videoDeviceInput.device.videoZoomFactor)
				
				/*
					After the session stop running, remove the metadata object overlays,
					if any, so that if the view appears again, the previously displayed
					metadata object overlays are removed.
				*/
				if !isSessionRunning {
					self.removeMetadataObjectOverlayLayers()
				}
			}
		}
		else if context == &previewViewRegionOfInterestObserveContext {
			guard let regionOfInterest = newValue?.cgRectValue else { return }
			
			// Update the AVCaptureMetadataOutput with the new region of interest.
			sessionQueue.async {
				// Translate the preview view's region of interest to the metadata output's coordinate system.
				self.metadataOutput.rectOfInterest = self.previewView.videoPreviewLayer.metadataOutputRectOfInterest(for: regionOfInterest)
				
				// Ensure we are not drawing old metadata object overlays.
				DispatchQueue.main.async { [unowned self] in
					self.removeMetadataObjectOverlayLayers()
				}
			}
		}
		else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}
	
	func sessionRuntimeError(notification: NSNotification) {
		guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else { return }
		
        let error = AVError(_nsError: errorValue)
		print("Capture session runtime error: \(error)")
		
		/*
			Automatically try to restart the session running if media services were
			reset and the last start running succeeded. Otherwise, enable the user
			to try to resume the session running.
		*/
		if error.code == .mediaServicesWereReset {
			sessionQueue.async { [unowned self] in
				if self.isSessionRunning {
					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning
				}
			}
		}
 	}
	
	func sessionWasInterrupted(notification: NSNotification) {
		/*
			In some scenarios we want to enable the user to resume the session running.
			For example, if music playback is initiated via control center while
			using AVCamBarcode, then the user can let AVCamBarcode resume
			the session running, which will stop music playback. Note that stopping
			music playback in control center will not automatically resume the session
			running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
		*/
		if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?, let reasonIntegerValue = userInfoValue.integerValue, let reason = AVCaptureSessionInterruptionReason(rawValue: reasonIntegerValue) {
			print("Capture session was interrupted with reason \(reason)")
			
			if reason == AVCaptureSessionInterruptionReason.videoDeviceNotAvailableWithMultipleForegroundApps {
				// Simply fade-in a label to inform the user that the camera is unavailable.
				self.cameraUnavailableLabel.isHidden = false
				self.cameraUnavailableLabel.alpha = 0
				UIView.animate(withDuration: 0.25) {
					self.cameraUnavailableLabel.alpha = 1
				}
			}
		}
	}
	
	func sessionInterruptionEnded(notification: NSNotification) {
		print("Capture session interruption ended")
		
		if cameraUnavailableLabel.isHidden {
			UIView.animate(withDuration: 0.25,
				animations: { [unowned self] in
					self.cameraUnavailableLabel.alpha = 0
				}, completion: { [unowned self] finished in
					self.cameraUnavailableLabel.isHidden = true
				}
			)
		}
	}
	
	// MARK: Drawing Metadata Object Overlay Layers
	
	@IBOutlet private var metadataObjectTypesButton: UIButton!
	
	private class MetadataObjectLayer: CAShapeLayer {
		var metadataObject: AVMetadataObject?
	}
	
	/**
		A dispatch semaphore is used for drawing metadata object overlays so that
		only one group of metadata object overlays is drawn at a time.
	*/
	private let metadataObjectsOverlayLayersDrawingSemaphore = DispatchSemaphore(value: 1)
	
	private var metadataObjectOverlayLayers = [MetadataObjectLayer]()
	
	private func createMetadataObjectOverlayWithMetadataObject(_ metadataObject: AVMetadataObject) -> MetadataObjectLayer {
		// Transform the metadata object so the bounds are updated to reflect those of the video preview layer.
		let transformedMetadataObject = previewView.videoPreviewLayer.transformedMetadataObject(for: metadataObject)
		
		// Create the initial metadata object overlay layer that can be used for either machine readable codes or faces.
		let metadataObjectOverlayLayer = MetadataObjectLayer()
		metadataObjectOverlayLayer.metadataObject = transformedMetadataObject
		metadataObjectOverlayLayer.lineJoin = kCALineJoinRound
		metadataObjectOverlayLayer.lineWidth = 7.0
		metadataObjectOverlayLayer.strokeColor = view.tintColor.withAlphaComponent(0.7).cgColor
		metadataObjectOverlayLayer.fillColor = view.tintColor.withAlphaComponent(0.3).cgColor
		
		if transformedMetadataObject is AVMetadataMachineReadableCodeObject {
			let barcodeMetadataObject = transformedMetadataObject as! AVMetadataMachineReadableCodeObject
			
			let barcodeOverlayPath = barcodeOverlayPathWithCorners(barcodeMetadataObject.corners as! [CFDictionary])
			metadataObjectOverlayLayer.path = barcodeOverlayPath
			
			// If the metadata object has a string value, display it.
			if barcodeMetadataObject.stringValue.characters.count > 0 {
				let barcodeOverlayBoundingBox = barcodeOverlayPath.boundingBox
				
				let textLayer = CATextLayer()
				textLayer.alignmentMode = kCAAlignmentCenter
				textLayer.bounds = CGRect(x: 0.0, y: 0.0, width: barcodeOverlayBoundingBox.size.width, height: barcodeOverlayBoundingBox.size.height)
				textLayer.contentsScale = UIScreen.main.scale
				textLayer.font = UIFont.boldSystemFont(ofSize: 19).fontName as CFString
				textLayer.position = CGPoint(x: barcodeOverlayBoundingBox.midX, y: barcodeOverlayBoundingBox.midY)
				textLayer.string = NSAttributedString(string: barcodeMetadataObject.stringValue, attributes: [
					NSFontAttributeName : UIFont.boldSystemFont(ofSize: 19),
				    kCTForegroundColorAttributeName as String : UIColor.white.cgColor,
				    kCTStrokeWidthAttributeName as String : -5.0,
				    kCTStrokeColorAttributeName as String : UIColor.black.cgColor])
				textLayer.isWrapped = true
				
				// Invert the effect of transform of the video preview so the text is orientated with the interface orientation.
				textLayer.transform = CATransform3DInvert(CATransform3DMakeAffineTransform(previewView.transform))
				
				metadataObjectOverlayLayer.addSublayer(textLayer)
			}
		}
		else if transformedMetadataObject is AVMetadataFaceObject {
			metadataObjectOverlayLayer.path = CGPath(rect: transformedMetadataObject!.bounds, transform: nil)
		}
		
		return metadataObjectOverlayLayer
	}
	
	private func barcodeOverlayPathWithCorners(_ corners: [CFDictionary]) -> CGMutablePath {
		let path = CGMutablePath()
		
		if !corners.isEmpty {
			guard let corner = CGPoint(dictionaryRepresentation: corners[0]) else { return path }
			path.move(to: corner, transform: .identity)
			
			for cornerDictionary in corners {
				guard let corner = CGPoint(dictionaryRepresentation: cornerDictionary) else { return path }
				path.addLine(to: corner)
			}
			
			path.closeSubpath()
		}
		
		return path
	}
	
	private var removeMetadataObjectOverlayLayersTimer: Timer?
	
	@objc private func removeMetadataObjectOverlayLayers() {
		for sublayer in metadataObjectOverlayLayers {
			sublayer.removeFromSuperlayer()
		}
		metadataObjectOverlayLayers = []
		
		removeMetadataObjectOverlayLayersTimer?.invalidate()
		removeMetadataObjectOverlayLayersTimer = nil
	}
	
	private func addMetadataObjectOverlayLayersToVideoPreviewView(_ metadataObjectOverlayLayers: [MetadataObjectLayer]) {
		// Add the metadata object overlays as sublayers of the video preview layer. We disable actions to allow for fast drawing.
		CATransaction.begin()
		CATransaction.setDisableActions(true)
		for metadataObjectOverlayLayer in metadataObjectOverlayLayers {
			previewView.videoPreviewLayer.addSublayer(metadataObjectOverlayLayer)
		}
		CATransaction.commit()
		
		// Save the new metadata object overlays.
		self.metadataObjectOverlayLayers = metadataObjectOverlayLayers
		
		// Create a timer to destroy the metadata object overlays.
		removeMetadataObjectOverlayLayersTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(removeMetadataObjectOverlayLayers), userInfo: nil, repeats: false)
	}
	
	private lazy var openBarcodeURLGestureRecognizer: UITapGestureRecognizer = {
		UITapGestureRecognizer(target: self, action: #selector(CameraViewController.openBarcodeURL(with:)))
	}()
	
	@objc private func openBarcodeURL(with openBarcodeURLGestureRecognizer: UITapGestureRecognizer) {
		for metadataObjectOverlayLayer in metadataObjectOverlayLayers {
			if metadataObjectOverlayLayer.path!.contains(openBarcodeURLGestureRecognizer.location(in: previewView), using: .winding, transform: .identity) {
				if let barcodeMetadataObject = metadataObjectOverlayLayer.metadataObject as? AVMetadataMachineReadableCodeObject {
					if barcodeMetadataObject.stringValue != nil {
						if let url = URL(string: barcodeMetadataObject.stringValue), UIApplication.shared.canOpenURL(url) {
							UIApplication.shared.open(url, options: [:], completionHandler: nil)
						}
					}
				}
			}
		}
	}
	
	// MARK: AVCaptureMetadataOutputObjectsDelegate
	
	func captureOutput(_ captureOutput: AVCaptureOutput!, didOutputMetadataObjects metadataObjects: [Any]!, from connection: AVCaptureConnection!) {
		// wait() is used to drop new notifications if old ones are still processing, to avoid queueing up a bunch of stale data.
		if metadataObjectsOverlayLayersDrawingSemaphore.wait(timeout: DispatchTime.now()) == .success {
			DispatchQueue.main.async { [unowned self] in
				self.removeMetadataObjectOverlayLayers()
				
				var metadataObjectOverlayLayers = [MetadataObjectLayer]()
				for metadataObject in metadataObjects as! [AVMetadataObject] {
					let metadataObjectOverlayLayer = self.createMetadataObjectOverlayWithMetadataObject(metadataObject)
					metadataObjectOverlayLayers.append(metadataObjectOverlayLayer)
				}
				
				self.addMetadataObjectOverlayLayersToVideoPreviewView(metadataObjectOverlayLayers)
				
				self.metadataObjectsOverlayLayersDrawingSemaphore.signal()
			}
		}
	}
	
	// MARK: ItemSelectionViewControllerDelegate
	
	let metadataObjectTypeItemSelectionIdentifier = "MetadataObjectTypes"
	
	let sessionPresetItemSelectionIdentifier = "SessionPreset"
	
	func itemSelectionViewController(_ itemSelectionViewController: ItemSelectionViewController, didFinishSelectingItems selectedItems: [String]) {
		let identifier = itemSelectionViewController.identifier
		
		if identifier == metadataObjectTypeItemSelectionIdentifier {
			sessionQueue.async { [unowned self] in
				self.metadataOutput.metadataObjectTypes = selectedItems
			}
		}
		else if identifier == sessionPresetItemSelectionIdentifier {
			sessionQueue.async { [unowned self] in
				self.session.sessionPreset = selectedItems.first
			}
		}
	}
}

extension AVCaptureDeviceDiscoverySession
{
	func uniqueDevicePositionsCount() -> Int {
		var uniqueDevicePositions = [AVCaptureDevicePosition]()
		
		for device in devices {
			if !uniqueDevicePositions.contains(device.position) {
				uniqueDevicePositions.append(device.position)
			}
		}
		
		return uniqueDevicePositions.count
	}
}

extension UIDeviceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
            case .portrait: return .portrait
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeLeft: return .landscapeRight
            case .landscapeRight: return .landscapeLeft
            default: return nil
        }
    }
}

extension UIInterfaceOrientation {
    var videoOrientation: AVCaptureVideoOrientation? {
        switch self {
            case .portrait: return .portrait
            case .portraitUpsideDown: return .portraitUpsideDown
            case .landscapeLeft: return .landscapeLeft
            case .landscapeRight: return .landscapeRight
            default: return nil
        }
    }
}
