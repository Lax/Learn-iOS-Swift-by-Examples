/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
View controller for camera interface.
*/

import UIKit
import AVFoundation
import CoreVideo
import Photos
import MobileCoreServices

class CameraViewController: UIViewController, AVCapturePhotoCaptureDelegate, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureDepthDataOutputDelegate, AVCaptureDataOutputSynchronizerDelegate {

	// MARK: - Properties

	@IBOutlet weak private var cameraButton: UIButton!

	@IBOutlet weak private var photoButton: UIButton!

	@IBOutlet weak private var resumeButton: UIButton!

	@IBOutlet weak private var cameraUnavailableLabel: UILabel!

	@IBOutlet weak private var filterLabel: UILabel!

	@IBOutlet weak private var previewView: PreviewMetalView!

	@IBOutlet weak private var videoFilterSwitch: UISwitch!

    @IBOutlet weak private var depthVisualizationSwitch: UISwitch!

	@IBOutlet weak private var depthVisualizationLabel: UILabel!

	@IBOutlet weak private var depthSmoothingSwitch: UISwitch!

	@IBOutlet weak private var depthSmoothingLabel: UILabel!

    @IBOutlet weak private var mixFactorSlider: UISlider!

	private enum SessionSetupResult {
		case success
		case notAuthorized
		case configurationFailed
	}

	private var setupResult: SessionSetupResult = .success

	private let session = AVCaptureSession()

	private var isSessionRunning = false

	// Communicate with the session and other session objects on this queue.
	private let sessionQueue = DispatchQueue(label: "session queue", attributes: [], autoreleaseFrequency: .workItem)

	private var videoDeviceInput: AVCaptureDeviceInput!

	private let dataOutputQueue = DispatchQueue(label: "video data queue", qos: .userInitiated, attributes: [], autoreleaseFrequency: .workItem)

	private let videoDataOutput = AVCaptureVideoDataOutput()

	private let depthDataOutput = AVCaptureDepthDataOutput()

	private var outputSynchronizer: AVCaptureDataOutputSynchronizer?

	private let photoOutput = AVCapturePhotoOutput()

	private let filterRenderers: [FilterRenderer] = [RosyMetalRenderer(), RosyCIRenderer()]

	private let photoRenderers: [FilterRenderer] = [RosyMetalRenderer(), RosyCIRenderer()]

	private let videoDepthMixer = VideoMixer()

	private let photoDepthMixer = VideoMixer()

	private var filterIndex: Int = 0

	private var videoFilter: FilterRenderer?

	private var photoFilter: FilterRenderer?

	private let videoDepthConverter = DepthToGrayscaleConverter()

	private let photoDepthConverter = DepthToGrayscaleConverter()

	private var currentDepthPixelBuffer: CVPixelBuffer?

	private var renderingEnabled = true

	private var depthVisualizationEnabled = false

	private let processingQueue = DispatchQueue(label: "photo processing queue", attributes: [], autoreleaseFrequency: .workItem)

	private let videoDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInDualCamera,
	                                                                                         .builtInWideAngleCamera],
	                                                                           mediaType: .video,
	                                                                           position: .unspecified)

	private var statusBarOrientation: UIInterfaceOrientation = .portrait

	// MARK: - View Controller Life Cycle

	override func viewDidLoad() {
		super.viewDidLoad()

		// Disable UI. The UI is enabled if and only if the session starts running.
		cameraButton.isEnabled = false
		photoButton.isEnabled = false
		videoFilterSwitch.isEnabled = false
		depthVisualizationSwitch.isHidden = true
		depthVisualizationLabel.isHidden = true
		depthSmoothingSwitch.isHidden = true
		depthSmoothingLabel.isHidden = true
		mixFactorSlider.isHidden = true

		let tapGesture = UITapGestureRecognizer(target: self, action: #selector(focusAndExposeTap))
		previewView.addGestureRecognizer(tapGesture)

		let leftSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilterSwipe))
		leftSwipeGesture.direction = .left
		previewView.addGestureRecognizer(leftSwipeGesture)

		let rightSwipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(changeFilterSwipe))
		rightSwipeGesture.direction = .right
		previewView.addGestureRecognizer(rightSwipeGesture)

		// Check video authorization status, video access is required
		switch AVCaptureDevice.authorizationStatus(for: .video) {
			case .authorized:
				// The user has previously granted access to the camera
				break

			case .notDetermined:
				/*
					The user has not yet been presented with the option to grant video access
					We suspend the session queue to delay session setup until the access request has completed
				*/
				sessionQueue.suspend()
				AVCaptureDevice.requestAccess(for: .video, completionHandler: { granted in
					if !granted {
						self.setupResult = .notAuthorized
					}
					self.sessionQueue.resume()
				})

			default:
				// The user has previously denied access
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

		let interfaceOrientation = UIApplication.shared.statusBarOrientation
		statusBarOrientation = interfaceOrientation

		let initialThermalState = ProcessInfo.processInfo.thermalState
		if initialThermalState == .serious || initialThermalState == .critical {
			showThermalState(state: initialThermalState)
		}

		sessionQueue.async {
			switch self.setupResult {
				case .success:
					// Only setup observers and start the session running if setup succeeded
					self.addObservers()
					if let photoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
						self.photoOutput.connection(with: .video)!.videoOrientation = photoOrientation
					}
					let videoOrientation = self.videoDataOutput.connection(with: .video)!.videoOrientation
					let videoDevicePosition = self.videoDeviceInput.device.position
					let rotation = PreviewMetalView.Rotation(with: interfaceOrientation, videoOrientation: videoOrientation, cameraPosition: videoDevicePosition)
					self.previewView.mirroring = (videoDevicePosition == .front)
					if let rotation = rotation {
						self.previewView.rotation = rotation
					}
					self.dataOutputQueue.async {
						self.renderingEnabled = true
					}

					self.session.startRunning()
					self.isSessionRunning = self.session.isRunning

					let photoDepthDataDeliverySupported = self.photoOutput.isDepthDataDeliverySupported
					let depthEnabled = self.depthVisualizationEnabled
					DispatchQueue.main.async {
						self.depthVisualizationSwitch.isHidden = !photoDepthDataDeliverySupported
						self.depthVisualizationLabel.isHidden = !photoDepthDataDeliverySupported
						self.depthVisualizationSwitch.isOn = depthEnabled
						self.depthSmoothingSwitch.isHidden = !depthEnabled
						self.depthSmoothingLabel.isHidden = !depthEnabled
						self.mixFactorSlider.isHidden = !depthEnabled
					}

				case .notAuthorized:
					DispatchQueue.main.async {
						let message = NSLocalizedString("AVCamPhotoFilter doesn't have permission to use the camera, please change privacy settings",
						                                comment: "Alert message when the user has denied access to the camera")
						let alertController = UIAlertController(title: "AVCamPhotoFilter", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"),
						                                        style: .cancel,
						                                        handler: nil))
						alertController.addAction(UIAlertAction(title: NSLocalizedString("Settings", comment: "Alert button to open Settings"),
						                                        style: .`default`,
						                                        handler: { _ in
																	UIApplication.shared.open(URL(string: UIApplicationOpenSettingsURLString)!,
																	                          options: [:],
																	                          completionHandler: nil)
						}))

						self.present(alertController, animated: true, completion: nil)
					}

				case .configurationFailed:
					DispatchQueue.main.async {
						let message = NSLocalizedString("Unable to capture media", comment: "Alert message when something goes wrong during capture session configuration")
						let alertController = UIAlertController(title: "AVCamPhotoFilter", message: message, preferredStyle: .alert)
						alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))

						self.present(alertController, animated: true, completion: nil)
					}
			}
		}
	}

	override func viewWillDisappear(_ animated: Bool) {
		dataOutputQueue.async {
			self.renderingEnabled = false
		}
		sessionQueue.async {
			if self.setupResult == .success {
				self.session.stopRunning()
				self.isSessionRunning = self.session.isRunning
				self.removeObservers()
			}
		}

		super.viewWillDisappear(animated)
	}

	@objc
	func didEnterBackground(notification: NSNotification) {
		// Free up resources
		dataOutputQueue.async {
			self.renderingEnabled = false
			if let videoFilter = self.videoFilter {
				videoFilter.reset()
			}
			self.videoDepthMixer.reset()
			self.currentDepthPixelBuffer = nil
			self.videoDepthConverter.reset()
			self.previewView.pixelBuffer = nil
			self.previewView.flushTextureCache()
		}
		processingQueue.async {
			if let photoFilter = self.photoFilter {
				photoFilter.reset()
			}
			self.photoDepthMixer.reset()
			self.photoDepthConverter.reset()
		}
	}

	@objc
	func willEnterForground(notification: NSNotification) {
		dataOutputQueue.async {
			self.renderingEnabled = true
		}
	}

	// You can use this opportunity to take corrective action to help cool the system down.
	@objc
	func thermalStateChanged(notification: NSNotification) {
		if let processInfo = notification.object as? ProcessInfo {
			showThermalState(state: processInfo.thermalState)
		}
	}

	func showThermalState(state: ProcessInfo.ThermalState) {
		DispatchQueue.main.async {
			var thermalStateString = "UNKNOWN"
			if state == .nominal {
				thermalStateString = "NOMINAL"
			} else if state == .fair {
				thermalStateString = "FAIR"
			} else if state == .serious {
				thermalStateString = "SERIOUS"
			} else if state == .critical {
				thermalStateString = "CRITICAL"
			}

			let message = NSLocalizedString("Thermal state: \(thermalStateString)", comment: "Alert message when thermal state has changed")
			let alertController = UIAlertController(title: "AVCamPhotoFilter", message: message, preferredStyle: .alert)
			alertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil))
			self.present(alertController, animated: true, completion: nil)
		}
	}

	override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
		return .all
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
		super.viewWillTransition(to: size, with: coordinator)

		coordinator.animate(
			alongsideTransition: { _ in
				let interfaceOrientation = UIApplication.shared.statusBarOrientation
				self.statusBarOrientation = interfaceOrientation
				self.sessionQueue.async {
					/*
						The photo orientation is based on the interface orientation. You could also set the orientation of the photo connection based
						on the device orientation by observing UIDeviceOrientationDidChangeNotification.
					*/
					if let photoOrientation = AVCaptureVideoOrientation(interfaceOrientation: interfaceOrientation) {
						self.photoOutput.connection(with: .video)!.videoOrientation = photoOrientation
					}
					let videoOrientation = self.videoDataOutput.connection(with: .video)!.videoOrientation
					if let rotation = PreviewMetalView.Rotation(with: interfaceOrientation, videoOrientation: videoOrientation, cameraPosition: self.videoDeviceInput.device.position) {
						self.previewView.rotation = rotation
					}
				}
			}, completion: nil
		)
	}

	// MARK: - KVO and Notifications

	private var sessionRunningContext = 0

	private func addObservers() {
		NotificationCenter.default.addObserver(self, selector: #selector(didEnterBackground), name: NSNotification.Name.UIApplicationDidEnterBackground, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(willEnterForground), name: NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(thermalStateChanged), name: ProcessInfo.thermalStateDidChangeNotification,	object: nil)
		NotificationCenter.default.addObserver(self, selector: #selector(sessionRuntimeError), name: NSNotification.Name.AVCaptureSessionRuntimeError, object: session)

		session.addObserver(self, forKeyPath: "running", options: NSKeyValueObservingOptions.new, context: &sessionRunningContext)

		/*
			A session can only run when the app is full screen. It will be interrupted
			in a multi-app layout, introduced in iOS 9, see also the documentation of
			AVCaptureSessionInterruptionReason. Add observers to handle these session
			interruptions and show a preview is paused message. See the documentation
			of AVCaptureSessionWasInterruptedNotification for other interruption reasons.
		*/
		NotificationCenter.default.addObserver(self, selector: #selector(sessionWasInterrupted), name: NSNotification.Name.AVCaptureSessionWasInterrupted, object: session)
		NotificationCenter.default.addObserver(self, selector: #selector(sessionInterruptionEnded), name: NSNotification.Name.AVCaptureSessionInterruptionEnded, object: session)
		NotificationCenter.default.addObserver(self, selector: #selector(subjectAreaDidChange), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: videoDeviceInput.device)
	}

	private func removeObservers() {
		NotificationCenter.default.removeObserver(self)
		session.removeObserver(self, forKeyPath: "running", context: &sessionRunningContext)
	}

	override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?) {
		if context == &sessionRunningContext {
			let newValue = change?[.newKey] as AnyObject?
			guard let isSessionRunning = newValue?.boolValue else { return }
			DispatchQueue.main.async {
				self.cameraButton.isEnabled = (isSessionRunning && self.videoDeviceDiscoverySession.devices.count > 1)
				self.photoButton.isEnabled = isSessionRunning
				self.videoFilterSwitch.isEnabled = isSessionRunning
			}
		} else {
			super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
		}
	}

	// MARK: - Session Management

	// Call this on the session queue
	private func configureSession() {
		if setupResult != .success {
			return
		}

		let defaultVideoDevice: AVCaptureDevice? = videoDeviceDiscoverySession.devices.first

		guard let videoDevice = defaultVideoDevice else {
			print("Could not find any video device")
			setupResult = .configurationFailed
			return
		}

		do {
			videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
		} catch {
			print("Could not create video device input: \(error)")
			setupResult = .configurationFailed
			return
		}

		session.beginConfiguration()

		session.sessionPreset = AVCaptureSession.Preset.photo

		// Add a video input
		guard session.canAddInput(videoDeviceInput) else {
			print("Could not add video device input to the session")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}
		session.addInput(videoDeviceInput)

		// Add a video data output
		if session.canAddOutput(videoDataOutput) {
			session.addOutput(videoDataOutput)
			videoDataOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
			videoDataOutput.setSampleBufferDelegate(self, queue: dataOutputQueue)
		} else {
			print("Could not add video data output to the session")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}

		// Add photo output
		if session.canAddOutput(photoOutput) {
			session.addOutput(photoOutput)

			photoOutput.isHighResolutionCaptureEnabled = true

			if depthVisualizationEnabled {
				if photoOutput.isDepthDataDeliverySupported {
					photoOutput.isDepthDataDeliveryEnabled = true
				} else {
					depthVisualizationEnabled = false
				}
			}

		} else {
			print("Could not add photo output to the session")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}

		// Add a depth data output
		if session.canAddOutput(depthDataOutput) {
			session.addOutput(depthDataOutput)
			depthDataOutput.setDelegate(self, callbackQueue: dataOutputQueue)
			depthDataOutput.isFilteringEnabled = false
            if let connection = depthDataOutput.connection(with: .depthData) {
                connection.isEnabled = depthVisualizationEnabled
            } else {
                print("No AVCaptureConnection")
            }
		} else {
			print("Could not add depth data output to the session")
			setupResult = .configurationFailed
			session.commitConfiguration()
			return
		}

		if depthVisualizationEnabled {
			// Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
			// The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
			outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [videoDataOutput, depthDataOutput])
			outputSynchronizer!.setDelegate(self, queue: dataOutputQueue)
		} else {
			outputSynchronizer = nil
		}

		if self.photoOutput.isDepthDataDeliverySupported {
			// Cap the video framerate at the max depth framerate
			if let frameDuration = videoDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
				do {
					try videoDevice.lockForConfiguration()
					videoDevice.activeVideoMinFrameDuration = frameDuration
					videoDevice.unlockForConfiguration()
				} catch {
					print("Could not lock device for configuration: \(error)")
				}
			}
		}

		session.commitConfiguration()
	}

	private func focus(with focusMode: AVCaptureDevice.FocusMode, exposureMode: AVCaptureDevice.ExposureMode, at devicePoint: CGPoint, monitorSubjectAreaChange: Bool) {
		sessionQueue.async {
			let videoDevice = self.videoDeviceInput.device

			do {
				try videoDevice.lockForConfiguration()
				if videoDevice.isFocusPointOfInterestSupported && videoDevice.isFocusModeSupported(focusMode) {
					videoDevice.focusPointOfInterest = devicePoint
					videoDevice.focusMode = focusMode
				}

				if videoDevice.isExposurePointOfInterestSupported && videoDevice.isExposureModeSupported(exposureMode) {
					videoDevice.exposurePointOfInterest = devicePoint
					videoDevice.exposureMode = exposureMode
				}

				videoDevice.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
				videoDevice.unlockForConfiguration()
			} catch {
				print("Could not lock device for configuration: \(error)")
			}
		}
	}

	@IBAction private func changeVideoFilteringEnabled(_ sender: UISwitch) {
		let filteringEnabled = sender.isOn
		let index = filterIndex

		if filteringEnabled {
			let filterDescription = filterRenderers[index].description
			updateFilterLabel(description: filterDescription)
		}

		// Enable/disable video filter
		dataOutputQueue.async {
			if filteringEnabled {
				self.videoFilter = self.filterRenderers[index]
			} else {
				if let filter = self.videoFilter {
					filter.reset()
				}
				self.videoFilter = nil
			}
		}

		// Enable/disable photo filter
		processingQueue.async {
			if filteringEnabled {
				self.photoFilter = self.photoRenderers[index]
			} else {
				if let filter = self.photoFilter {
					filter.reset()
				}
				self.photoFilter = nil
			}
		}
	}

	@IBAction private func changeDepthEnabled(_ sender: UISwitch) {
		var depthEnabled = sender.isOn
		depthSmoothingSwitch.isHidden = !depthEnabled
		depthSmoothingLabel.isHidden = !depthEnabled
		mixFactorSlider.isHidden = !depthEnabled

		sessionQueue.async {
			self.session.beginConfiguration()

			if self.photoOutput.isDepthDataDeliverySupported {
				self.photoOutput.isDepthDataDeliveryEnabled = depthEnabled
			} else {
				depthEnabled = false
			}

			self.depthDataOutput.connection(with: .depthData)!.isEnabled = depthEnabled

			if depthEnabled {
				// Use an AVCaptureDataOutputSynchronizer to synchronize the video data and depth data outputs.
				// The first output in the dataOutputs array, in this case the AVCaptureVideoDataOutput, is the "master" output.
				self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput, self.depthDataOutput])
				self.outputSynchronizer!.setDelegate(self, queue: self.dataOutputQueue)
			} else {
				self.outputSynchronizer = nil
			}

			self.session.commitConfiguration()

			self.dataOutputQueue.async {
				if !depthEnabled {
					self.videoDepthConverter.reset()
					self.videoDepthMixer.reset()
					self.currentDepthPixelBuffer = nil
				}
				self.depthVisualizationEnabled = depthEnabled
			}

			self.processingQueue.async {
				if !depthEnabled {
					self.photoDepthMixer.reset()
					self.photoDepthConverter.reset()
				}
			}
		}
	}

	@IBAction private func changeMixFactor(_ sender: UISlider) {
		let mixFactor = sender.value

		dataOutputQueue.async {
			self.videoDepthMixer.mixFactor = mixFactor
		}

		processingQueue.async {
			self.photoDepthMixer.mixFactor = mixFactor
		}
	}

	@IBAction private func changeDepthSmoothing(_ sender: UISwitch) {
		let smoothingEnabled = sender.isOn

		sessionQueue.async {
			self.depthDataOutput.isFilteringEnabled = smoothingEnabled
		}
	}

	@IBAction private func changeFilterSwipe(_ gesture: UISwipeGestureRecognizer) {
		let filteringEnabled = videoFilterSwitch.isOn
		if filteringEnabled {
			if gesture.direction == .left {
				filterIndex = (filterIndex + 1) % filterRenderers.count
			} else if gesture.direction == .right {
				filterIndex = (filterIndex + filterRenderers.count - 1) % filterRenderers.count
			}

			let newIndex = filterIndex
			let filterDescription = filterRenderers[newIndex].description
			updateFilterLabel(description: filterDescription)

			// Switch renderers
			dataOutputQueue.async {
				if let filter = self.videoFilter {
					filter.reset()
				}
				self.videoFilter = self.filterRenderers[newIndex]
			}

			processingQueue.async {
				if let filter = self.photoFilter {
					filter.reset()
				}
				self.photoFilter = self.photoRenderers[newIndex]
			}
		}
	}

	func updateFilterLabel(description: String) {
		filterLabel.text = description
		filterLabel.alpha = 0.0
		filterLabel.isHidden = false

		// Fade in
		UIView.animate(withDuration: 0.25) {
			self.filterLabel.alpha = 1.0
		}

		// Fade out
		UIView.animate(withDuration: 2.0) {
			self.filterLabel.alpha = 0.0
		}
	}

	@IBAction private func focusAndExposeTap(_ gesture: UITapGestureRecognizer) {
		let location = gesture.location(in: previewView)
		guard let texturePoint = previewView.texturePointForView(point: location) else {
			return
		}

		let textureRect = CGRect(origin: texturePoint, size: .zero)
		let deviceRect = videoDataOutput.metadataOutputRectConverted(fromOutputRect: textureRect)
		focus(with: .autoFocus, exposureMode: .autoExpose, at: deviceRect.origin, monitorSubjectAreaChange: true)
	}

	@objc
	func subjectAreaDidChange(notification: NSNotification) {
		let devicePoint = CGPoint(x: 0.5, y: 0.5)
		focus(with: .continuousAutoFocus, exposureMode: .continuousAutoExposure, at: devicePoint, monitorSubjectAreaChange: false)
	}

	@objc
	func sessionWasInterrupted(notification: NSNotification) {
		// In iOS 9 and later, the userInfo dictionary contains information on why the session was interrupted.
		if let userInfoValue = notification.userInfo?[AVCaptureSessionInterruptionReasonKey] as AnyObject?,
			let reasonIntegerValue = userInfoValue.integerValue,
			let reason = AVCaptureSession.InterruptionReason(rawValue: reasonIntegerValue) {
			print("Capture session was interrupted with reason \(reason)")

			if reason == .videoDeviceInUseByAnotherClient {
				// Simply fade-in a button to enable the user to try to resume the session running.
				resumeButton.isHidden = false
				resumeButton.alpha = 0.0
				UIView.animate(withDuration: 0.25) {
					self.resumeButton.alpha = 1.0
				}
			} else if reason == .videoDeviceNotAvailableWithMultipleForegroundApps {
				// Simply fade-in a label to inform the user that the camera is unavailable.
				cameraUnavailableLabel.isHidden = false
				cameraUnavailableLabel.alpha = 0.0
				UIView.animate(withDuration: 0.25) {
					self.cameraUnavailableLabel.alpha = 1.0
				}
			}
		}
	}

	@objc
	func sessionInterruptionEnded(notification: NSNotification) {
		if !resumeButton.isHidden {
			UIView.animate(withDuration: 0.25,
				animations: {
					self.resumeButton.alpha = 0
				}, completion: { _ in
					self.resumeButton.isHidden = true
				}
			)
		}
		if !cameraUnavailableLabel.isHidden {
			UIView.animate(withDuration: 0.25,
				animations: {
					self.cameraUnavailableLabel.alpha = 0
				}, completion: { _ in
					self.cameraUnavailableLabel.isHidden = true
				}
			)
		}
	}

	@objc
	func sessionRuntimeError(notification: NSNotification) {
		guard let errorValue = notification.userInfo?[AVCaptureSessionErrorKey] as? NSError else {
			return
		}

		let error = AVError(_nsError: errorValue)
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
				} else {
					DispatchQueue.main.async {
						self.resumeButton.isHidden = false
					}
				}
			}
		} else {
			resumeButton.isHidden = false
		}
	}

	@IBAction private func resumeInterruptedSession(_ sender: UIButton) {
		sessionQueue.async {
			/*
				The session might fail to start running. A failure to start the session running will be communicated via
				a session runtime error notification. To avoid repeatedly failing to start the session
				running, we only try to restart the session running in the session runtime error handler
				if we aren't trying to resume the session running.
			*/
			self.session.startRunning()
			self.isSessionRunning = self.session.isRunning
			if !self.session.isRunning {
				DispatchQueue.main.async {
					let message = NSLocalizedString("Unable to resume", comment: "Alert message when unable to resume the session running")
					let alertController = UIAlertController(title: "AVCamPhotoFilter", message: message, preferredStyle: .alert)
					let cancelAction = UIAlertAction(title:NSLocalizedString("OK", comment: "Alert OK button"), style: .cancel, handler: nil)
					alertController.addAction(cancelAction)
					self.present(alertController, animated: true, completion: nil)
				}
			} else {
				DispatchQueue.main.async {
					self.resumeButton.isHidden = true
				}
			}
		}
	}

	@IBAction private func changeCamera(_ sender: UIButton) {
		cameraButton.isEnabled = false
		photoButton.isEnabled = false

		dataOutputQueue.sync {
			renderingEnabled = false
			if let filter = videoFilter {
				filter.reset()
			}
			videoDepthMixer.reset()
			currentDepthPixelBuffer = nil
			videoDepthConverter.reset()
			previewView.pixelBuffer = nil
		}

		processingQueue.async {
			if let filter = self.photoFilter {
				filter.reset()
			}
			self.photoDepthMixer.reset()
			self.photoDepthConverter.reset()
		}

		let interfaceOrientation = statusBarOrientation
		var depthEnabled = depthVisualizationSwitch.isOn

		sessionQueue.async {
			let currentVideoDevice = self.videoDeviceInput.device
			let currentPhotoOrientation = self.photoOutput.connection(with: .video)!.videoOrientation

			var preferredPosition = AVCaptureDevice.Position.unspecified
			switch currentVideoDevice.position {
				case .unspecified, .front:
					preferredPosition = .back

				case .back:
					preferredPosition = .front
			}

			let devices = self.videoDeviceDiscoverySession.devices
			if let videoDevice = devices.first(where: { $0.position == preferredPosition }) {
				var videoInput: AVCaptureDeviceInput
				do {
					videoInput = try AVCaptureDeviceInput(device: videoDevice)
				} catch {
					print("Could not create video device input: \(error)")
					self.dataOutputQueue.async {
						self.renderingEnabled = true
					}
					return
				}
				self.session.beginConfiguration()

				// Remove the existing device input first, since using the front and back camera simultaneously is not supported.
				self.session.removeInput(self.videoDeviceInput)

				if self.session.canAddInput(videoInput) {
					NotificationCenter.default.removeObserver(self,
					                                          name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
					                                          object: currentVideoDevice)
					NotificationCenter.default.addObserver(self,
					                                       selector: #selector(self.subjectAreaDidChange),
					                                       name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange,
					                                       object: videoDevice)

					self.session.addInput(videoInput)
					self.videoDeviceInput = videoInput
				} else {
					print("Could not add video device input to the session")
					self.session.addInput(self.videoDeviceInput)
				}

				self.photoOutput.connection(with: .video)!.videoOrientation = currentPhotoOrientation

				if self.photoOutput.isDepthDataDeliverySupported {
					self.photoOutput.isDepthDataDeliveryEnabled = depthEnabled
					self.depthDataOutput.connection(with: .depthData)!.isEnabled = depthEnabled
					if depthEnabled && self.outputSynchronizer == nil {
						self.outputSynchronizer = AVCaptureDataOutputSynchronizer(dataOutputs: [self.videoDataOutput, self.depthDataOutput])
						self.outputSynchronizer!.setDelegate(self, queue: self.dataOutputQueue)
					}

					// Cap the video framerate at the max depth framerate
					if let frameDuration = videoDevice.activeDepthDataFormat?.videoSupportedFrameRateRanges.first?.minFrameDuration {
						do {
							try videoDevice.lockForConfiguration()
							videoDevice.activeVideoMinFrameDuration = frameDuration
							videoDevice.unlockForConfiguration()
						} catch {
							print("Could not lock device for configuration: \(error)")
						}
					}
				} else {
					self.outputSynchronizer = nil
					depthEnabled = false
				}

				self.session.commitConfiguration()
			}

			let videoPosition = self.videoDeviceInput.device.position
			let videoOrientation = self.videoDataOutput.connection(with: .video)!.videoOrientation
			let rotation = PreviewMetalView.Rotation(with: interfaceOrientation, videoOrientation: videoOrientation, cameraPosition: videoPosition)

			self.previewView.mirroring = (videoPosition == .front)
			if let rotation = rotation {
				self.previewView.rotation = rotation
			}

			self.dataOutputQueue.async {
				self.renderingEnabled = true
				self.depthVisualizationEnabled = depthEnabled
			}

			let photoDepthDataDeliverySupported = self.photoOutput.isDepthDataDeliverySupported
			DispatchQueue.main.async {
				self.depthVisualizationSwitch.isHidden = !photoDepthDataDeliverySupported
				self.depthVisualizationLabel.isHidden = !photoDepthDataDeliverySupported
				self.depthSmoothingSwitch.isHidden = !depthEnabled
				self.depthSmoothingLabel.isHidden = !depthEnabled
				self.mixFactorSlider.isHidden = !depthEnabled
				self.cameraButton.isEnabled = true
				self.photoButton.isEnabled = true
			}
		}
	}

	@IBAction private func capturePhoto(_ photoButton: UIButton) {
		let depthEnabled = depthVisualizationSwitch.isOn

		sessionQueue.async {
			let photoSettings = AVCapturePhotoSettings(format: [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)])
			if depthEnabled && self.photoOutput.isDepthDataDeliverySupported {
				photoSettings.isDepthDataDeliveryEnabled = true
				photoSettings.embedsDepthDataInPhoto = false
			}

			self.photoOutput.capturePhoto(with: photoSettings, delegate: self)
		}
	}

	// MARK: - Video Data Output Delegate

	func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
		processVideo(sampleBuffer: sampleBuffer)
	}

	func processVideo(sampleBuffer: CMSampleBuffer) {
		if !renderingEnabled {
			return
		}

		guard let videoPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer),
			let formatDescription = CMSampleBufferGetFormatDescription(sampleBuffer) else {
			return
		}

		var finalVideoPixelBuffer = videoPixelBuffer
		if let filter = videoFilter {
			if !filter.isPrepared {
				/*
				outputRetainedBufferCountHint is the number of pixel buffers we expect to hold on to from the renderer. This value informs the renderer
				how to size its buffer pool and how many pixel buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
				*/
				filter.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
			}

			// Send the pixel buffer through the filter
			guard let filteredBuffer = filter.render(pixelBuffer: finalVideoPixelBuffer) else {
				print("Unable to filter video buffer")
				return
			}

			finalVideoPixelBuffer = filteredBuffer
		}

		if depthVisualizationEnabled {
			if !videoDepthMixer.isPrepared {
				videoDepthMixer.prepare(with: formatDescription, outputRetainedBufferCountHint: 3)
			}

			if let depthBuffer = currentDepthPixelBuffer {

				// Mix the video buffer with the last depth data we received
				guard let mixedBuffer = videoDepthMixer.mix(videoPixelBuffer: finalVideoPixelBuffer, depthPixelBuffer: depthBuffer) else {
					print("Unable to combine video and depth")
					return
				}

				finalVideoPixelBuffer = mixedBuffer
			}
		}

		previewView.pixelBuffer = finalVideoPixelBuffer
	}

	// MARK: - Depth Data Output Delegate

	func depthDataOutput(_ depthDataOutput: AVCaptureDepthDataOutput, didOutput depthData: AVDepthData, timestamp: CMTime, connection: AVCaptureConnection) {
		processDepth(depthData: depthData)
	}

	func processDepth(depthData: AVDepthData) {
		if !renderingEnabled {
			return
		}

		if !depthVisualizationEnabled {
			return
		}

		if !videoDepthConverter.isPrepared {
			/*
			outputRetainedBufferCountHint is the number of pixel buffers we expect to hold on to from the renderer. This value informs the renderer
			how to size its buffer pool and how many pixel buffers to preallocate. Allow 2 frames of latency to cover the dispatch_async call.
			*/
			var depthFormatDescription: CMFormatDescription?
			CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, depthData.depthDataMap, &depthFormatDescription)
			videoDepthConverter.prepare(with: depthFormatDescription!, outputRetainedBufferCountHint: 2)
		}

		guard let depthPixelBuffer = videoDepthConverter.render(pixelBuffer: depthData.depthDataMap) else {
			print("Unable to process depth")
			return
		}

		currentDepthPixelBuffer = depthPixelBuffer
	}

	// MARK: - Video + Depth Output Synchronizer Delegate

	func dataOutputSynchronizer(_ synchronizer: AVCaptureDataOutputSynchronizer, didOutput synchronizedDataCollection: AVCaptureSynchronizedDataCollection) {

		if let syncedDepthData: AVCaptureSynchronizedDepthData = synchronizedDataCollection.synchronizedData(for: depthDataOutput) as? AVCaptureSynchronizedDepthData {
			if !syncedDepthData.depthDataWasDropped {
				let depthData = syncedDepthData.depthData
				processDepth(depthData: depthData)
			}
		}

		if let syncedVideoData: AVCaptureSynchronizedSampleBufferData = synchronizedDataCollection.synchronizedData(for: videoDataOutput) as? AVCaptureSynchronizedSampleBufferData {
			if !syncedVideoData.sampleBufferWasDropped {
				let videoSampleBuffer = syncedVideoData.sampleBuffer
				processVideo(sampleBuffer: videoSampleBuffer)
			}
		}
	}

	// MARK: - Photo Output Delegate

	func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
		guard let photoPixelBuffer = photo.pixelBuffer else {
			print("Error occurred while capturing photo: Missing pixel buffer (\(String(describing: error)))")
			return
		}

		var photoFormatDescription: CMFormatDescription?
		CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, photoPixelBuffer, &photoFormatDescription)

		processingQueue.async {
			var finalPixelBuffer = photoPixelBuffer
			if let filter = self.photoFilter {
				if !filter.isPrepared {
					filter.prepare(with: photoFormatDescription!, outputRetainedBufferCountHint: 2)
				}

				guard let filteredPixelBuffer = filter.render(pixelBuffer: finalPixelBuffer) else {
					print("Unable to filter photo buffer")
					return
				}
				finalPixelBuffer = filteredPixelBuffer
			}

			if let depthData = photo.depthData {
				let depthPixelBuffer = depthData.depthDataMap

				if !self.photoDepthConverter.isPrepared {
					var depthFormatDescription: CMFormatDescription?
					CMVideoFormatDescriptionCreateForImageBuffer(kCFAllocatorDefault, depthPixelBuffer, &depthFormatDescription)

					/*
					outputRetainedBufferCountHint is the number of pixel buffers we expect to hold on to from the renderer. This value informs the renderer
					how to size its buffer pool and how many pixel buffers to preallocate. Allow 3 frames of latency to cover the dispatch_async call.
					*/
					self.photoDepthConverter.prepare(with: depthFormatDescription!, outputRetainedBufferCountHint: 3)
				}

				guard let convertedDepthPixelBuffer = self.photoDepthConverter.render(pixelBuffer: depthPixelBuffer) else {
					print("Unable to convert depth pixel buffer")
					return
				}

				if !self.photoDepthMixer.isPrepared {
					self.photoDepthMixer.prepare(with: photoFormatDescription!, outputRetainedBufferCountHint: 2)
				}

				// Combine image and depth map
				guard let mixedPixelBuffer = self.photoDepthMixer.mix(videoPixelBuffer: finalPixelBuffer, depthPixelBuffer: convertedDepthPixelBuffer) else {
					print("Unable to mix depth and photo buffers")
					return
				}

				finalPixelBuffer = mixedPixelBuffer
			}

			let metadataAttachments: CFDictionary = photo.metadata as CFDictionary
			guard let jpegData = CameraViewController.jpegData(withPixelBuffer: finalPixelBuffer, attachments: metadataAttachments) else {
				print("Unable to create JPEG photo")
				return
			}

			// Save JPEG to photo library
			PHPhotoLibrary.requestAuthorization { status in
				if status == .authorized {
					PHPhotoLibrary.shared().performChanges({
						let creationRequest = PHAssetCreationRequest.forAsset()
						creationRequest.addResource(with: .photo, data: jpegData, options: nil)
					}, completionHandler: { _, error in
						if let error = error {
							print("Error occurred while saving photo to photo library: \(error)")
						}
					})
				}
			}
		}
	}

	// MARK: - Utilities

	private class func jpegData(withPixelBuffer pixelBuffer: CVPixelBuffer, attachments: CFDictionary?) -> Data? {
		let ciContext = CIContext()
		let renderedCIImage = CIImage(cvImageBuffer: pixelBuffer)
		guard let renderedCGImage = ciContext.createCGImage(renderedCIImage, from: renderedCIImage.extent) else {
			print("Failed to create CGImage")
			return nil
		}

		guard let data = CFDataCreateMutable(kCFAllocatorDefault, 0) else {
			print("Create CFData error!")
			return nil
		}

		guard let cgImageDestination = CGImageDestinationCreateWithData(data, kUTTypeJPEG, 1, nil) else {
			print("Create CGImageDestination error!")
			return nil
		}

		CGImageDestinationAddImage(cgImageDestination, renderedCGImage, attachments)
		if CGImageDestinationFinalize(cgImageDestination) {
			return data as Data
		}
		print("Finalizing CGImageDestination error!")
		return nil
	}
}

extension AVCaptureVideoOrientation {
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

extension PreviewMetalView.Rotation {
	init?(with interfaceOrientation: UIInterfaceOrientation, videoOrientation: AVCaptureVideoOrientation, cameraPosition: AVCaptureDevice.Position) {
		/*
			Calculate the rotation between the videoOrientation and the interfaceOrientation.
			The direction of the rotation depends upon the camera position.
		*/
		switch videoOrientation {
			case .portrait:
				switch interfaceOrientation {
					case .landscapeRight:
						if cameraPosition == .front {
							self = .rotate90Degrees
						} else {
							self = .rotate270Degrees
					}

				case .landscapeLeft:
					if cameraPosition == .front {
						self = .rotate270Degrees
					} else {
						self = .rotate90Degrees
					}

				case .portrait:
					self = .rotate0Degrees

				case .portraitUpsideDown:
					self = .rotate180Degrees

				default: return nil
			}
		case .portraitUpsideDown:
			switch interfaceOrientation {
			case .landscapeRight:
				if cameraPosition == .front {
					self = .rotate270Degrees
				} else {
					self = .rotate90Degrees
				}

			case .landscapeLeft:
				if cameraPosition == .front {
					self = .rotate90Degrees
				} else {
					self = .rotate270Degrees
				}

			case .portrait:
				self = .rotate180Degrees

			case .portraitUpsideDown:
				self = .rotate0Degrees

			default: return nil
			}

		case .landscapeRight:
			switch interfaceOrientation {
			case .landscapeRight:
				self = .rotate0Degrees

			case .landscapeLeft:
				self = .rotate180Degrees

			case .portrait:
				if cameraPosition == .front {
					self = .rotate270Degrees
				} else {
					self = .rotate90Degrees
				}

			case .portraitUpsideDown:
				if cameraPosition == .front {
					self = .rotate90Degrees
				} else {
					self = .rotate270Degrees
				}

			default: return nil
			}

		case .landscapeLeft:
			switch interfaceOrientation {
			case .landscapeLeft:
				self = .rotate0Degrees

			case .landscapeRight:
				self = .rotate180Degrees

			case .portrait:
				if cameraPosition == .front {
					self = .rotate90Degrees
				} else {
					self = .rotate270Degrees
				}

			case .portraitUpsideDown:
				if cameraPosition == .front {
					self = .rotate270Degrees
				} else {
					self = .rotate90Degrees
				}

			default: return nil
			}
		}
	}
}
