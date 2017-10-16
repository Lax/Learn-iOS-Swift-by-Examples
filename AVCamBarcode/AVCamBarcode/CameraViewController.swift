/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for camera interface.
*/

import UIKit
import AVFoundation
import SafariServices

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
		switch AVCaptureDevice.authorizationStatus(for: .video) {
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
				AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
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
		sessionQueue.async {
			self.configureSession()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		sessionQueue.async {
			switch self.setupResult {
				case .success:
					// Only setup observers and start the session running if setup succeeded.
					self.addObservers()
					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning
				
				case .notAuthorized:
					DispatchQueue.main.async {
						let changePrivatySetting = "AVCamBarcode doesn't have permission to use the camera, please change privacy settings"
						let message = NSLocalizedString(changePrivatySetting, comment: "Alert message when the user has denied access to the camera")
						let	alertController = UIAlertController(title: "AVCamBarcode", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
						alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings",
						                                                                 comment: "Alert button to open Settings"),
						                                                                 style: .`default`, handler: { _ in
							UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!, options: [:], completionHandler: nil)
						}))
						
						self.present(alertController, animated: true, completion: nil)
					}
				
				case .configurationFailed:
					DispatchQueue.main.async {
						let alertMsg = "Unable to capture media"
						let message = NSLocalizedString(alertMsg, comment: "Alert message when something goes wrong during capture session configuration")
						let alertController = UIAlertController(title: "AVCamBarcode", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
						
						self.present(alertController, animated: true, completion: nil)
					}
			}
		}
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		sessionQueue.async {
			if self.setupResult == .success {
				self.session.stopRunning()
				self.isSessionRunning = self.session.isRunning
				self.removeObservers()
			}
		}
		
		super.viewWillDisappear(animated)
	}
	
    override var shouldAutorotate: Bool {
		// Do not allow rotation if the region of interest is being resized.
		return !previewView.isResizingRegionOfInterest
	}
	
	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)
		
		if let videoPreviewLayerConnection = previewView.videoPreviewLayer.connection {
			let deviceOrientation = UIDevice.current.orientation
			guard let newVideoOrientation = AVCaptureVideoOrientation(deviceOrientation: deviceOrientation),
				deviceOrientation.isPortrait || deviceOrientation.isLandscape else {
				return
			}
			
			videoPreviewLayerConnection.videoOrientation = newVideoOrientation
			
			/*
				When we transition to a new size, we need to recalculate the preview
				view's region of interest rect so that it stays in the same
				position relative to the camera.
			*/
			coordinator.animate(alongsideTransition: { context in
				
					let newRegionOfInterest = self.previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: self.metadataOutput.rectOfInterest)
					self.previewView.setRegionOfInterestWithProposedRegionOfInterest(newRegionOfInterest)
				},
				completion: { context in
					
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
	
	private let sessionQueue = DispatchQueue(label: "session queue") // Communicate with the session and other session objects on this queue.
	
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
			let defaultVideoDevice: AVCaptureDevice?
			
			// Choose the back wide angle camera if available, otherwise default to the front wide angle camera.
			if let backCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
				defaultVideoDevice = backCameraDevice
			} else if let frontCameraDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
				// Default to the front wide angle camera if the back wide angle camera is unavailable.
				defaultVideoDevice = frontCameraDevice
			} else {
				defaultVideoDevice = nil
			}
			
			guard let videoDevice = defaultVideoDevice else {
				print("Could not get video device")
				setupResult = .configurationFailed
				session.commitConfiguration()
				return
			}
			
			let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
			
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
						if let videoOrientation = AVCaptureVideoOrientation(interfaceOrientation: statusBarOrientation) {
							initialVideoOrientation = videoOrientation
						}
					}
					
					self.previewView.videoPreviewLayer.connection!.videoOrientation = initialVideoOrientation
				}
			} else {
				print("Could not add video device input to the session")
				setupResult = .configurationFailed
				session.commitConfiguration()
				return
			}
		} catch {
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
			
			/*
				Set an inital rect of interest that is 80% of the view's shortest side
				and 25% of the longest side. This means that the region of interest will
				appear in the same spot regardless of whether the app starts in portrait
				or landscape.
			*/
			let width = 0.25
			let height = 0.8
			let x = (1.0 - width) / 2.0
			let y = (1.0 - height) / 2.0
			let initialRectOfInterest = CGRect(x: x, y: y, width: width, height: height)
			metadataOutput.rectOfInterest = initialRectOfInterest

			DispatchQueue.main.async {
				let initialRegionOfInterest = self.previewView.videoPreviewLayer.layerRectConverted(fromMetadataOutputRect: initialRectOfInterest)
				self.previewView.setRegionOfInterestWithProposedRegionOfInterest(initialRegionOfInterest)
			}
		} else {
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
	
	private func availableSessionPresets() -> [AVCaptureSession.Preset] {
		let allSessionPresets: [AVCaptureSession.Preset] = [.photo,
		                                                    .low,
		                                                    .medium,
		                                                    .high,
		                                                    .cif352x288,
		                                                    .vga640x480,
		                                                    .hd1280x720,
		                                                    .iFrame960x540,
		                                                    .iFrame1280x720,
		                                                    .hd1920x1080,
		                                                    .hd4K3840x2160]
		
		var availableSessionPresets: [AVCaptureSession.Preset] = []
		for sessionPreset in allSessionPresets {
			if session.canSetSessionPreset(sessionPreset) {
				availableSessionPresets.append(sessionPreset)
			}
		}
		
		return availableSessionPresets
	}
	
	@IBAction private func selectSessionPreset() {
		let itemSelectionViewController = ItemSelectionViewController<AVCaptureSession.Preset>(delegate: self,
		                                                                                       identifier: sessionPresetItemSelectionIdentifier,
		                                                                                       allItems: availableSessionPresets(),
		                                                                                       selectedItems: [session.sessionPreset],
		                                                                                       allowsMultipleSelection: false)
		
		presentItemSelectionViewController(itemSelectionViewController)
	}
	
	// MARK: Device Configuration
	
	@IBOutlet private var cameraButton: UIButton!
	
	@IBOutlet private var cameraUnavailableLabel: UILabel!
	
	private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .unspecified)
	
	@IBAction private func changeCamera() {
		metadataObjectTypesButton.isEnabled = false
		sessionPresetsButton.isEnabled = false
		cameraButton.isEnabled = false
		zoomSlider.isEnabled = false
		
		// Remove the metadata overlay layers, if any.
		removeMetadataObjectOverlayLayers()
		
		DispatchQueue.main.async {
			let currentVideoDevice = self.videoDeviceInput.device
			let currentPosition = currentVideoDevice.position
			
			let preferredPosition: AVCaptureDevice.Position
			
			switch currentPosition {
				case .unspecified, .front:
					preferredPosition = .back
				
				case .back:
					preferredPosition = .front
			}
			
			let devices = self.videoDeviceDiscoverySession.devices
			let newVideoDevice = devices.first(where: { $0.position == preferredPosition })
			
            if let videoDevice = newVideoDevice {
				do {
					let videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
					
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
					self.session.sessionPreset = .high
					
					if self.session.canAddInput(videoDeviceInput) {
						self.session.addInput(videoDeviceInput)
						self.videoDeviceInput = videoDeviceInput
					} else {
						self.session.addInput(self.videoDeviceInput)
					}
					
					// Restore the previous session preset if we can.
					if self.session.canSetSessionPreset(previousSessionPreset) {
						self.session.sessionPreset = previousSessionPreset
					}
					
					self.session.commitConfiguration()
				} catch {
					print("Error occured while creating video device input: \(error)")
				}
			}
			
			DispatchQueue.main.async {
				self.metadataObjectTypesButton.isEnabled = true
				self.sessionPresetsButton.isEnabled = true
				self.cameraButton.isEnabled = true
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
		} catch {
			print("Could not lock for configuration: \(error)")
		}
	}
	
	// MARK: KVO and Notifications
	
	private var keyValueObservations = [NSKeyValueObservation]()
	
	private func addObservers() {
		var keyValueObservation: NSKeyValueObservation
		
		keyValueObservation = session.observe(\.isRunning, options: .new) { _, change in
			guard let isSessionRunning = change.newValue else { return }
			
			DispatchQueue.main.async {
				self.metadataObjectTypesButton.isEnabled = isSessionRunning
				self.sessionPresetsButton.isEnabled = isSessionRunning
				self.cameraButton.isEnabled = isSessionRunning && self.videoDeviceDiscoverySession.devices.count > 1
				self.zoomSlider.isEnabled = isSessionRunning
				self.zoomSlider.maximumValue = Float(min(self.videoDeviceInput.device.activeFormat.videoMaxZoomFactor, CGFloat(8.0)))
				self.zoomSlider.value = Float(self.videoDeviceInput.device.videoZoomFactor)
				
				/*
					After the session stops running, remove the metadata object overlays,
					if any, so that if the view appears again, the previously displayed
					metadata object overlays are removed.
				*/
				if !isSessionRunning {
					self.removeMetadataObjectOverlayLayers()
				}
				
				/*
					When the session starts running, the aspect ratio of the video preview may also change if a new session preset was applied.
					To keep the preview view's region of interest within the visible portion of the video preview, the preview view's region of
					interest will need to be updated.
				*/
				if isSessionRunning {
					self.previewView.setRegionOfInterestWithProposedRegionOfInterest(self.previewView.regionOfInterest)
				}
			}
		}
		keyValueObservations.append(keyValueObservation)
		
		/*
			Observe the previewView's regionOfInterest to update the AVCaptureMetadataOutput's
			rectOfInterest when the user finishes resizing the region of interest.
		*/
		keyValueObservation = previewView.observe(\.regionOfInterest, options: .new) { _, change in
			guard let regionOfInterest = change.newValue else { return }
			
			DispatchQueue.main.async {
				// Ensure we are not drawing old metadata object overlays.
				self.removeMetadataObjectOverlayLayers()
				
				// Translate the preview view's region of interest to the metadata output's coordinate system.
				let metadataOutputRectOfInterest = self.previewView.videoPreviewLayer.metadataOutputRectConverted(fromLayerRect: regionOfInterest)
				
				// Update the AVCaptureMetadataOutput with the new region of interest.
				self.sessionQueue.async {
					self.metadataOutput.rectOfInterest = metadataOutputRectOfInterest
				}
			}
		}
		keyValueObservations.append(keyValueObservation)
	
		let notificationCenter = NotificationCenter.default
		
		notificationCenter.addObserver(self, selector: #selector(sessionRuntimeError), name: .AVCaptureSessionRuntimeError, object: session)
		
		/*
			A session can only run when the app is full screen. It will be interrupted
			in a multi-app layout, introduced in iOS 9, see also the documentation of
			AVCaptureSessionInterruptionReason. Add observers to handle these session
			interruptions and show a preview is paused message. See the documentation
			of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
		*/
		notificationCenter.addObserver(self, selector: #selector(sessionWasInterrupted), name: .AVCaptureSessionWasInterrupted, object: session)
		notificationCenter.addObserver(self, selector: #selector(sessionInterruptionEnded), name: .AVCaptureSessionInterruptionEnded, object: session)
	}
	
	private func removeObservers() {
		NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionInterruptionEnded, object: session)
		NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionWasInterrupted, object: session)
		NotificationCenter.default.removeObserver(self, name: .AVCaptureSessionRuntimeError, object: session)
		
		for keyValueObservation in keyValueObservations {
			keyValueObservation.invalidate()
		}
		keyValueObservations.removeAll()
	}
	
	@objc
	func sessionRuntimeError(notification: NSNotification) {
		guard let error = notification.userInfo?[AVCaptureSessionErrorKey] as? AVError else { return }
		
		print("Capture session runtime error: \(error)")
		
		/*
			Automatically try to restart the session running if media services were
			reset and the last start running succeeded. Otherwise, enable the user
			to try to resume the session running.
		*/
		if error.code == .mediaServicesWereReset {
			sessionQueue.async {
				if self.isSessionRunning {
					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning
				}
			}
		}
 	}
	
	@objc
	func sessionWasInterrupted(notification: NSNotification) {
		/*
			In some scenarios we want to enable the user to resume the session running.
			For example, if music playback is initiated via control center while
			using AVCamBarcode, then the user can let AVCamBarcode resume
			the session running, which will stop music playback. Note that stopping
			music playback in control center will not automatically resume the session
			running. Also note that it is not always possible to resume, see `resumeInterruptedSession(_:)`.
		*/
		if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
			let reasonIntegerValue = userInfoValue.integerValue,
			let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
			print("Capture session was interrupted with reason \(reason)")
			
			if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
				// Simply fade-in a label to inform the user that the camera is unavailable.
				self.cameraUnavailableLabel.isHidden = false
				self.cameraUnavailableLabel.alpha = 0
				UIView.animate(withDuration: 0.25) {
					self.cameraUnavailableLabel.alpha = 1
				}
			}
		}
	}
	
	@objc
	func sessionInterruptionEnded(notification: NSNotification) {
		print("Capture session interruption ended")
		
		if cameraUnavailableLabel.isHidden {
			UIView.animate(withDuration: 0.25,
				animations: {
					self.cameraUnavailableLabel.alpha = 0
				}, completion: { _ in
					self.cameraUnavailableLabel.isHidden = true
				}
			)
		}
	}
	
	// MARK: Drawing Metadata Object Overlay Layers
	
	@IBOutlet private var metadataObjectTypesButton: UIButton!
	
	@IBAction private func selectMetadataObjectTypes() {
		let itemSelectionViewController = ItemSelectionViewController<AVMetadataObject.ObjectType>(delegate: self,
		                                                                                           identifier: metadataObjectTypeItemSelectionIdentifier,
		                                                                                           allItems: metadataOutput.availableMetadataObjectTypes,
		                                                                                           selectedItems: metadataOutput.metadataObjectTypes,
		                                                                                           allowsMultipleSelection: true)
		
		presentItemSelectionViewController(itemSelectionViewController)
	}
	
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
		
		if let barcodeMetadataObject = transformedMetadataObject as? AVMetadataMachineReadableCodeObject {
			
			let barcodeOverlayPath = barcodeOverlayPathWithCorners(barcodeMetadataObject.corners)
			metadataObjectOverlayLayer.path = barcodeOverlayPath
			
			// If the metadata object has a string value, display it.
			let textLayerString: String?
			if let stringValue = barcodeMetadataObject.stringValue, !stringValue.characters.isEmpty {
				textLayerString = stringValue
			} else if let barcodeDescriptor = barcodeMetadataObject.descriptor {
				if barcodeDescriptor is CIQRCodeDescriptor {
					textLayerString = "<QR Code Binary Data Present>"
				} else if barcodeDescriptor is CIAztecCodeDescriptor {
					textLayerString = "<Aztec Code Binary Data Present>"
				} else if barcodeDescriptor is CIPDF417CodeDescriptor {
					textLayerString = "<PDF417 Code Binary Data Present>"
				} else if barcodeDescriptor is CIDataMatrixCodeDescriptor {
					textLayerString = "<Data Matrix Code Binary Data Present>"
				} else {
					fatalError("Unexpected barcode descriptor found: \(barcodeDescriptor)")
				}
			} else {
				textLayerString = nil
			}
			
			if let textLayerString = textLayerString {
				let barcodeOverlayBoundingBox = barcodeOverlayPath.boundingBox
				
				let textLayer = CATextLayer()
				textLayer.alignmentMode = kCAAlignmentCenter
				textLayer.bounds = CGRect(x: 0.0, y: 0.0, width: barcodeOverlayBoundingBox.size.width, height: barcodeOverlayBoundingBox.size.height)
				textLayer.contentsScale = UIScreen.main.scale
				textLayer.font = UIFont.boldSystemFont(ofSize: 19).fontName as CFString
				textLayer.position = CGPoint(x: barcodeOverlayBoundingBox.midX, y: barcodeOverlayBoundingBox.midY)
				textLayer.string = NSAttributedString(string: textLayerString,
				                                      attributes: [.font: UIFont.boldSystemFont(ofSize: 19),
				                                                   .foregroundColor: UIColor.white.cgColor,
				                                                   .strokeWidth: -5.0,
				                                                   .strokeColor: UIColor.black.cgColor])
				textLayer.isWrapped = true
				
				// Invert the effect of transform of the video preview so the text is orientated with the interface orientation.
				textLayer.transform = CATransform3DInvert(CATransform3DMakeAffineTransform(previewView.transform))
				
				metadataObjectOverlayLayer.addSublayer(textLayer)
			}
		} else if let faceMetadataObject = transformedMetadataObject as? AVMetadataFaceObject {
			metadataObjectOverlayLayer.path = CGPath(rect: faceMetadataObject.bounds, transform: nil)
		}
		
		return metadataObjectOverlayLayer
	}
	
	private func barcodeOverlayPathWithCorners(_ corners: [CGPoint]) -> CGMutablePath {
		let path = CGMutablePath()
		
		if let corner = corners.first {
			path.move(to: corner, transform: .identity)
			
			for corner in corners[1..<corners.count] {
				path.addLine(to: corner)
			}
			
			path.closeSubpath()
		}
		
		return path
	}
	
	private var removeMetadataObjectOverlayLayersTimer: Timer?
	
	@objc
	private func removeMetadataObjectOverlayLayers() {
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
	
	@objc
	private func openBarcodeURL(with openBarcodeURLGestureRecognizer: UITapGestureRecognizer) {
		for metadataObjectOverlayLayer in metadataObjectOverlayLayers {
			if metadataObjectOverlayLayer.path!.contains(openBarcodeURLGestureRecognizer.location(in: previewView), using: .winding, transform: .identity) {
				if let barcodeMetadataObject = metadataObjectOverlayLayer.metadataObject as? AVMetadataMachineReadableCodeObject {
					if let stringValue = barcodeMetadataObject.stringValue {
						if let url = URL(string: stringValue) {
							let safariViewController = SFSafariViewController(url: url)
							present(safariViewController, animated: true, completion: nil)
						}
					}
				}
			}
		}
	}
	
	// MARK: AVCaptureMetadataOutputObjectsDelegate
	
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
		// wait() is used to drop new notifications if old ones are still processing, to avoid queueing up a bunch of stale data.
        if metadataObjectsOverlayLayersDrawingSemaphore.wait(timeout: .now()) == .success {
			DispatchQueue.main.async {
				self.removeMetadataObjectOverlayLayers()
				
				var metadataObjectOverlayLayers = [MetadataObjectLayer]()
				for metadataObject in metadataObjects {
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
	
	private func presentItemSelectionViewController<Item>(_ itemSelectionViewController: ItemSelectionViewController<Item>) {
		let navigationController = UINavigationController(rootViewController: itemSelectionViewController)
		navigationController.navigationBar.barTintColor = .black
		navigationController.navigationBar.tintColor = view.tintColor
		present(navigationController, animated: true, completion: nil)
	}
	
	func itemSelectionViewController<Item>(_ itemSelectionViewController: ItemSelectionViewController<Item>, didFinishSelectingItems selectedItems: [Item]) {
		let identifier = itemSelectionViewController.identifier
		
		if identifier == metadataObjectTypeItemSelectionIdentifier {
			guard let selectedMetadataObjectTypes = selectedItems as? [AVMetadataObject.ObjectType] else {
				fatalError("Expected `[AVMetadataObject.ObjectType]` type for selectedItems. Check `selectMetadataObjectTypes()` implementation.")
			}
			
			sessionQueue.async {
				self.metadataOutput.metadataObjectTypes = selectedMetadataObjectTypes
			}
		} else if identifier == sessionPresetItemSelectionIdentifier {
			guard let selectedSessionPreset = selectedItems.first as? AVCaptureSession.Preset else {
				fatalError("Expected `[AVCaptureSession.Preset]` type for selectedItems. Check `selectSessionPreset()` implementation.")
			}
			
			sessionQueue.async {
				self.session.sessionPreset = selectedSessionPreset
			}
		}
	}
}

extension AVCaptureVideoOrientation {
	init?(deviceOrientation: UIDeviceOrientation) {
		switch deviceOrientation {
			case .portrait: self = .portrait
			case .portraitUpsideDown: self = .portraitUpsideDown
			case .landscapeLeft: self = .landscapeRight
			case .landscapeRight: self = .landscapeLeft
			default: return nil
		}
	}
	
	init?(interfaceOrientation: UIInterfaceOrientation) {
		switch interfaceOrientation {
			case .portrait: self = .portrait
			case .portraitUpsideDown: self = .portraitUpsideDown
			case .landscapeLeft: self = .landscapeLeft
			case .landscapeRight: self = .landscapeRight
			default: return nil
		}
	}
}
