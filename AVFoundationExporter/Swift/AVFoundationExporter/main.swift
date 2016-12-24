/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Demonstrates how to use AVAssetExportSession to export and transcode media files
*/

import AVFoundation

/*
    Perform all of the argument parsing / set up. The interesting AV exporting
    code is done in the `Exporter` type.
*/
actOnCommandLineArguments()

/// The type that performs all of the asset exporting.
struct Exporter {
	// MARK: Properties
	
	let sourceURL: NSURL
	
	let destinationURL: NSURL
	
	var destinationFileType = AVFileTypeQuickTimeMovie
	
	var presetName = AVAssetExportPresetPassthrough
	
	var timeRange: CMTimeRange?
	
	var filterMetadata = false
	
	var injectMetadata = false
	
	var deleteExistingFile = false
	
	var isVerbose = false
	
	// MARK: Initialization
	
	init(sourceURL: NSURL, destinationURL: NSURL) {
		self.sourceURL = sourceURL
		self.destinationURL = destinationURL
	}
	
	func export() throws {
		let asset = AVURLAsset(URL: sourceURL)
		
		printVerbose("Exporting \"\(sourceURL)\" to \"\(destinationURL)\" (file type \(destinationFileType)), using preset \(presetName).")
		
		// Set up export session.
		let exportSession = try setUpExportSession(asset, destinationURL: destinationURL)
        
        // AVAssetExportSession will not overwrite existing files.
		try deleteExistingFile(destinationURL)

        describeSourceFile(asset)
		
		// Kick off asynchronous export operation.
		let group = dispatch_group_create()
		dispatch_group_enter(group)
		exportSession.exportAsynchronouslyWithCompletionHandler {
			dispatch_group_leave(group)
		}
		
		waitForExportToFinish(exportSession, group: group)
		
		if exportSession.status == .Failed {
			// `error` is non-nil when in the "failed" status.
			throw exportSession.error!
		}
		else {
			describeDestFile(destinationURL)
		}
		
		printVerbose("Export completed successfully.")
	}
	
	func setUpExportSession(asset: AVAsset, destinationURL: NSURL) throws -> AVAssetExportSession {
		guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
			throw CommandLineError.InvalidArgument(reason: "Invalid preset \(presetName).")
		}
		
		// Set required properties.
		exportSession.outputURL = destinationURL
		exportSession.outputFileType = destinationFileType
		
		if let timeRange = timeRange {
			exportSession.timeRange = timeRange
			
			printVerbose("Trimming to time range \(CMTimeRangeCopyDescription(nil, timeRange)!).")
		}
		
		if filterMetadata {
			printVerbose("Filtering metadata.")
			
			exportSession.metadataItemFilter = AVMetadataItemFilter.metadataItemFilterForSharing()
		}
		
		if injectMetadata {
			printVerbose("Injecting metadata")
			
			let now = NSDate()
			let currentDate = NSDateFormatter.localizedStringFromDate(now, dateStyle: .MediumStyle, timeStyle: .ShortStyle)
			
			let userDataCommentItem = AVMutableMetadataItem()
			userDataCommentItem.identifier = AVMetadataIdentifierQuickTimeUserDataComment
			userDataCommentItem.value = "QuickTime userdata: Exported to preset \(presetName) using AVFoundationExporter at: \(currentDate)."
			
			let metadataCommentItem = AVMutableMetadataItem()
			metadataCommentItem.identifier = AVMetadataIdentifierQuickTimeMetadataComment
			metadataCommentItem.value = "QuickTime metadata: Exported to preset \(presetName) using AVFoundationExporter at: \(currentDate)."
			
			let iTunesCommentItem = AVMutableMetadataItem()
			iTunesCommentItem.identifier = AVMetadataIdentifieriTunesMetadataUserComment
			iTunesCommentItem.value = "iTunes metadata: Exported to preset \(presetName) using AVFoundationExporter at: \(currentDate)."
			
			/*
                To avoid replacing metadata from the asset:
                    1. Fetch existing metadata from the asset.
                    2. Combine it with the new metadata.
                    3. Set the result on the export session.
			*/
			exportSession.metadata = asset.metadata + [
				userDataCommentItem,
				metadataCommentItem,
				iTunesCommentItem
			]
		}
		
		return exportSession
	}
	
	func deleteExistingFile(destinationURL: NSURL) throws {
		let fileManager = NSFileManager()

        if let destinationPath = destinationURL.path {
			if deleteExistingFile && fileManager.fileExistsAtPath(destinationPath) {
				printVerbose("Removing pre-existing file at destination path \"\(destinationPath)\".")
				
				try fileManager.removeItemAtURL(destinationURL)
			}
		}
	}
	
	func describeSourceFile(asset: AVAsset) {
		guard isVerbose else { return }
		
		printVerbose("Tracks in source file:")
		
        let trackDescriptions = trackDescriptionsForAsset(asset)
		let tracksDescription = trackDescriptions.joinWithSeparator("\n\t")
		printVerbose("\t\(tracksDescription)")
		
		printVerbose("Metadata in source file:")
        let metadataDescriptions = metadataDescriptionsForAsset(asset)
		let metadataDescription = metadataDescriptions.joinWithSeparator("\n\t")
		
		printVerbose("\t\(metadataDescription)")
	}
	
	// Periodically polls & prints export session progress while waiting for the export to finish.
	func waitForExportToFinish(exportSession: AVAssetExportSession, group: dispatch_group_t) {
		while exportSession.status == .Waiting || exportSession.status == .Exporting {
			printVerbose("Progress: \(exportSession.progress * 100.0)%.")
			
			dispatch_group_wait(group, dispatch_time(DISPATCH_TIME_NOW, Int64(500 * NSEC_PER_MSEC)))
		}
		
		printVerbose("Progress: \(exportSession.progress * 100.0)%.")
	}
	
	func describeDestFile(destinationURL: NSURL) {
		guard isVerbose else { return }
		
		let destinationAsset = AVAsset(URL:destinationURL)
		
		printVerbose("Tracks in written file:")
		
        let trackDescriptions = trackDescriptionsForAsset(destinationAsset)
        let tracksDescription = trackDescriptions.joinWithSeparator("\n\t")
		printVerbose("\t\(tracksDescription)")
		
		printVerbose("Metadata in written file:")
		
        let metadataDescriptions = metadataDescriptionsForAsset(destinationAsset)
        let metadataDescription = metadataDescriptions.joinWithSeparator("\n\t")
		printVerbose("\t\(metadataDescription)")
	}
	
	func trackDescriptionsForAsset(asset: AVAsset) -> [String] {
		return asset.tracks.map { track in
			let enabledString = track.enabled ? "YES" : "NO"
			
			let selfContainedString = track.selfContained ? "YES" : "NO"
			
			let formatDescriptions = track.formatDescriptions as! [CMFormatDescriptionRef]
			
			let formatStrings = formatDescriptions.map { formatDescription -> String in
                let mediaSubType = CMFormatDescriptionGetMediaSubType(formatDescription)

                let mediaSubTypeString = NSFileTypeForHFSTypeCode(mediaSubType)
				
				return "'\(track.mediaType)'/\(mediaSubTypeString)"
			}
			
			let formatString = !formatStrings.isEmpty ? formatStrings.joinWithSeparator(", ") : "'\(track.mediaType)'"
			
			return "Track ID \(track.trackID): \(formatString), data length: \(track.totalSampleDataLength), enabled: \(enabledString), self-contained: \(selfContainedString)"
		}
	}
	
	func metadataDescriptionsForAsset(asset: AVAsset) -> [String] {
		return asset.metadata.map { item in
			let identifier = item.identifier ?? "<no identifier>"
			
			let value = item.value?.description ?? "<no value>"
			
			return "metadata item \(identifier): \(value)"
		}
	}
	
	func printVerbose(string: String) {
		if isVerbose {
			print(string)
		}
	}
}
