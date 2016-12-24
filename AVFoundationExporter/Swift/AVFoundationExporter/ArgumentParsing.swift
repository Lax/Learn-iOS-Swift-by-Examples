/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Parses command-line arguments and invokes the appropriate command
*/

import CoreMedia
import AVFoundation

// Use enums to enforce uniqueness of option labels.
enum LongLabel: String {
	case FileType           = "filetype"
	case PresetName         = "preset"
	case DeleteExistingFile = "replace"
	case LogEverything      = "verbose"
	case TrimStartTime      = "trim-start-time"
	case TrimEndTime        = "trim-end-time"
	case FilterMetadata     = "filter-metadata"
	case InjectMetadata     = "inject-metadata"
}

enum ShortLabel: String {
	case FileType           = "f"
	case PresetName         = "p"
	case DeleteExistingFile = "r"
	case LogEverything      = "v"
}

let executableName = NSString(string: Process.arguments.first!).pathComponents.last!

func usage() {
	print("Usage:")
	print("\t\(executableName) <source path> <dest path> [options]")
	print("\t\(executableName) list-presets [<source path>]")
	print("") // newline
	print("In the first form, \(executableName) performs an export of the file at <source path>, writing the result to a file at <dest path>.  If no options are given, a passthrough export to a QuickTime Movie file is performed.")
	print("")
	print("In the second form, \(executableName) lists the available parameters to the -preset option.  If <source path> is specified, only the presets compatible with the file at <source path> will be listed.")
	print("")
	print("Options for first form:")
	print("\t-f, -filetype <UTI>")
	print("\t\tThe file type (e.g. com.apple.m4v-video) for the output file")
	print("")
	print("\t-p, -preset <preset>")
	print("\t\tThe preset name; use commmand list-presets to see available preset names")
	print("")
	print("\t-r, -replace YES")
	print("\t\tIf there is a pre-existing file at the destination location, remove it before exporting")
	print("")
	print("\t-v, -verbose YES")
	print("\t\tPrint more information about the execution")
	print("")
	print("\t-trim-start-time <seconds>")
	print("\t\tWhen specified, all media before the start time will be trimmed out")
	print("")
	print("\t-trim-end-time <seconds>")
	print("\t\tWhen specified, all media after the end time will be trimmed out")
	print("")
	print("\t-filter-metadata YES")
	print("\t\tFilter out privacy-sensitive metadata")
	print("")
	print("\t-inject-metadata YES")
	print("\t\tAdd simple metadata during export")
}

// Errors that can occur during argument parsing.
enum CommandLineError: ErrorType, CustomStringConvertible {
	case TooManyArguments
	case TooFewArguments(descriptionOfRequiredArguments: String)
	case InvalidArgument(reason: String)
	
	var description: String {
		switch self {
            case .TooManyArguments:
                return "Too many arguments"
                
            case .TooFewArguments(let descriptionOfRequiredArguments):
                return "Missing argument(s).  Must specify \(descriptionOfRequiredArguments)."
                
            case .InvalidArgument(let reason):
                return "Invalid argument. \(reason)."
		}
	}
}

/// A set of convenience methods to use with our specific command line arguments.
extension NSUserDefaults {
	func stringForLongLabel(longLabel: LongLabel) -> String? {
		return stringForKey(longLabel.rawValue)
	}
	
    func stringForShortLabel(shortLabel: ShortLabel) -> String? {
		return stringForKey(shortLabel.rawValue)
	}
	
    func boolForLongLabel(longLabel: LongLabel) -> Bool {
		return boolForKey(longLabel.rawValue)
	}
	
    func boolForShortLabel(shortLabel: ShortLabel) -> Bool {
		return boolForKey(shortLabel.rawValue)
	}

    func timeForLongLabel(longLabel: LongLabel) throws -> CMTime? {
		if let timeAsString = stringForLongLabel(longLabel) {
			guard let timeAsSeconds = Float64(timeAsString) else {
				throw CommandLineError.InvalidArgument(reason: "Non-numeric time \"\(timeAsString)\".")
			}

            return CMTimeMakeWithSeconds(timeAsSeconds, 600)
		}

        return nil
	}

    func timeForShortLabel(shortLabel: ShortLabel) throws -> CMTime? {
		if let timeAsString = stringForShortLabel(shortLabel) {
			guard let timeAsSeconds = Float64(timeAsString) else {
				throw CommandLineError.InvalidArgument(reason: "Non-numeric time \"\(timeAsString)\".")
			}
		
            return CMTimeMakeWithSeconds(timeAsSeconds, 600)
		}

        return nil
	}
}

// Lists all presets, or the presets compatible with the file at the given path
func listPresets(sourcePath: String? = nil) {
    let presets: [String]
    
    switch sourcePath {
        case let sourcePath?:
            print("Presets compatible with \(sourcePath):.")
            
            let sourceURL = NSURL(fileURLWithPath: sourcePath)
            let asset = AVAsset(URL: sourceURL)
            presets = AVAssetExportSession.exportPresetsCompatibleWithAsset(asset)
            
        case nil:
            print("Available presets:")
            presets = AVAssetExportSession.allExportPresets()
    }
    
    let presetsDescription = presets.joinWithSeparator("\n\t")
    
    print("\t\(presetsDescription)")
}

/// The main function that handles all of the command line argument parsing.
func actOnCommandLineArguments() {
	let arguments = Process.arguments
	let firstArgumentAfterExecutablePath: String? = (arguments.count >= 2) ? arguments[1] : nil
	
	if arguments.contains("-help") || arguments.contains("-h") {
		usage()
		exit(0)
	}
	
	do {
		switch firstArgumentAfterExecutablePath {
            case nil, "help"?:
                usage()
                exit(0)
                
            case "list-presets"?:
                if arguments.count == 3 {
                    listPresets(arguments[2])
                }
                else if arguments.count > 3 {
                    throw CommandLineError.TooManyArguments
                }
                else {
                    listPresets()
                }
                
            default:
                guard arguments.count >= 3 else {
                    throw CommandLineError.TooFewArguments(descriptionOfRequiredArguments: "source and dest paths")
                }
               
                let sourceURL = NSURL(fileURLWithPath: arguments[1])
                let destinationURL = NSURL(fileURLWithPath: arguments[2])
                
                var exporter = Exporter(sourceURL: sourceURL, destinationURL: destinationURL)
                
                let options = NSUserDefaults.standardUserDefaults()
                
                if let fileType = options.stringForLongLabel(.FileType) ?? options.stringForShortLabel(.FileType) {
                    exporter.destinationFileType = fileType
                }
                
                if let presetName = options.stringForLongLabel(.PresetName) ?? options.stringForShortLabel(.PresetName) {
                    exporter.presetName = presetName
                }
                
                exporter.deleteExistingFile = options.boolForLongLabel(.DeleteExistingFile) || options.boolForShortLabel(.DeleteExistingFile)
                
                exporter.isVerbose = options.boolForLongLabel(.LogEverything) || options.boolForShortLabel(.LogEverything)
                
                let trimStartTime = try options.timeForLongLabel(.TrimStartTime)
                let trimEndTime = try options.timeForLongLabel(.TrimEndTime)
                
                switch (trimStartTime, trimEndTime) {
                    case (nil, nil):
                        exporter.timeRange = nil
                        
                    case (let realStartTime?, nil):
                        exporter.timeRange = CMTimeRange(start: realStartTime, duration: kCMTimePositiveInfinity)
                        
                    case (nil, let realEndTime?):
                        exporter.timeRange = CMTimeRangeFromTimeToTime(kCMTimeZero, realEndTime)
                        
                    case (let realStartTime?, let realEndTime?):
                        exporter.timeRange = CMTimeRangeFromTimeToTime(realStartTime, realEndTime)
                }
                
                exporter.filterMetadata = options.boolForLongLabel(.FilterMetadata)
                
                exporter.injectMetadata = options.boolForLongLabel(.InjectMetadata)
                
                try exporter.export()
            }
	}
    catch let error as CommandLineError {
        print("error parsing arguments: \(error).")
        print("") // newline
        usage()
        exit(1)
    }
	catch let error as NSError {
        let highLevelFailure = error.localizedDescription
        var errorOutput = highLevelFailure
        
        if let detailedFailure = error.localizedRecoverySuggestion ?? error.localizedFailureReason {
            errorOutput += ": \(detailedFailure)"
        }
        
        print("error: \(errorOutput).")
        
        exit(1)
	}
}