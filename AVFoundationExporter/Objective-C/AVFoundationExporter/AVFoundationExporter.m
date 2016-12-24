/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file shows an example of using the export and metadata functions in AVFoundation as a part of a command line tool for simple exports.
*/

@import Foundation;
@import AVFoundation;

// ---------------------------------------------------------------------------
//		Convenience Functions
// ---------------------------------------------------------------------------

static void printNSString(NSString *string);
static void printArgs(int argc, const char **argv);


// ---------------------------------------------------------------------------
//		AAPLExporter Class Interface
// ---------------------------------------------------------------------------
@interface AAPLExporter: NSObject {
	NSString *programName;
	NSString *exportType;
	NSString *preset;
	NSString *sourcePath;
	NSString *destinationPath;
	NSString *fileType;
	NSNumber *progress;
	NSNumber *startSeconds;
	NSNumber *durationSeconds;
	BOOL showProgress;
	BOOL verbose;
	BOOL exportFailed;
	BOOL exportComplete;
	BOOL listTracks;
	BOOL listMetadata;
	BOOL removePreExistingFiles;
}

@property (copy) NSString *programName;
@property (copy) NSString *exportType;
@property (copy) NSString *preset;
@property (copy) NSString *sourcePath;
@property (copy) NSString *destinationPath;
@property (copy) NSString *fileType;
@property (strong) NSNumber *progress;
@property (strong) NSNumber *startSeconds;
@property (strong) NSNumber *durationSeconds;
@property (getter=isVerbose) BOOL verbose;
@property BOOL showProgress;
@property BOOL exportFailed;
@property BOOL exportComplete;
@property BOOL listTracks;
@property BOOL listMetadata;
@property BOOL removePreExistingFiles;

- (id)initWithArgs:(int)argc argv:(const char **)argv environ:(const char **)environ;
- (void)printUsage;

- (int)run;

- (NSArray *)addNewMetadata:(NSArray *)sourceMetadataList presetName:(NSString *)presetName;

+ (void)doListPresets;
- (void)doListTracks:(NSString *)assetPath;
- (void)doListMetadata:(NSString *)assetPath;


@end


// ---------------------------------------------------------------------------
//		AAPLExporter Class Implementation
// ---------------------------------------------------------------------------

@implementation AAPLExporter

@synthesize programName, exportType, preset;
@synthesize sourcePath, destinationPath, progress, fileType;
@synthesize startSeconds, durationSeconds;
@synthesize	verbose, showProgress, exportComplete, exportFailed; 
@synthesize listTracks, listMetadata;
@synthesize removePreExistingFiles;

-(id) initWithArgs: (int) argc  argv: (const char **) argv environ: (const char **) environ
{
	self = [super init];

    if (self == nil) {
		return nil;
	}

	printArgs(argc,argv);
	
	BOOL gotpreset = NO;
	BOOL gotsource = NO;
	BOOL gotout = NO;
	BOOL parseOK = NO;
	BOOL listPresets = NO;
	[self setProgramName:[NSString stringWithUTF8String: *argv++]];
	argc--;
	while ( argc > 0 && **argv == '-' )
	{
		const char*	args = &(*argv)[1];
		
		argc--;
		argv++;
		
		if ( ! strcmp ( args, "source" ) )
		{
			[self setSourcePath: [NSString stringWithUTF8String: *argv++] ];
			gotsource = YES;
			argc--;
		}
		else if (( ! strcmp ( args, "dest" )) || ( ! strcmp ( args, "destination" )) )
		{
			[self setDestinationPath: [NSString stringWithUTF8String: *argv++]];
			gotout = YES;
			argc--;
		}
		else if ( ! strcmp ( args, "preset" ) )
		{
			[self setPreset: [NSString stringWithUTF8String: *argv++]];
			gotpreset = YES;
			argc--;
		}
		else if ( ! strcmp ( args, "replace" ) )
		{
			[self setRemovePreExistingFiles: YES];
		}
		else if ( ! strcmp ( args, "filetype" ) )
		{
			[self setFileType: [NSString stringWithUTF8String: *argv++]];
			argc--;
		}
		else if ( ! strcmp ( args, "verbose" ) )
		{
			[self setVerbose:YES];
		}
		else if ( ! strcmp ( args, "progress" ) )
		{
			[self setShowProgress: YES];
		}
		else if ( ! strcmp ( args, "start" ) )
		{
			[self setStartSeconds: [NSNumber numberWithFloat:[[NSString stringWithUTF8String: *argv++] floatValue]]];
			argc--;
		}
		else if ( ! strcmp ( args, "duration" ) )
		{
			[self setDurationSeconds: [NSNumber numberWithFloat:[[NSString stringWithUTF8String: *argv++] floatValue]]];
			argc--;
		}
		else if ( ! strcmp ( args, "listpresets" ) )
		{
			listPresets = YES;
			parseOK = YES;
		}
		else if ( ! strcmp ( args, "listtracks" ) )
		{
			[self setListTracks: YES];
			parseOK = YES;
		}
		else if ( ! strcmp ( args, "listmetadata" ) )
		{
			[self setListMetadata: YES];
			parseOK = YES;
		}
		else if ( ! strcmp ( args, "help" ) )
		{
			[self printUsage];
		}
		else {
			printf("Invalid input parameter: %s\n", args );
			[self printUsage];
			return nil;
		}
	}
	[self setProgress: [NSNumber numberWithFloat:(float)0.0]];
	[self setExportFailed: NO];
	[self setExportComplete: NO];
	
	if (listPresets) {
		[AAPLExporter doListPresets];
	}
	
	if ([self isVerbose]) {
		printNSString([NSString stringWithFormat:@"Running: %@\n", [self programName]]);
	}
	
	// There must be a source and either a preset and output (the normal case) or parseOK set for a listing
	if ((gotsource == NO)  || ((parseOK == NO) && ((gotpreset == NO) || (gotout == NO)))) {
		[self printUsage];
		return nil;
	}
	return self;
}


-(void) printUsage
{
	printf("AVFoundationExporter - usage:\n");
	printf("	./AVFoundationExporter [-parameter <value> ...]\n");
	printf("	 parameters are all preceded by a -<parameterName>.  The order of the parameters is unimportant.\n");
	printf("	 Required parameters are  -preset <presetName> -source <sourceFileURL> -dest <outputFileURL>\n");
	printf("	 Source and destination URL strings cannot contain spaces.\n");
	printf("	 Available parameters are:\n");
	printf("	 	-preset <preset name>.  The preset name eg: AVAssetExportPreset640x480 AVAssetExportPresetAppleM4VWiFi. Use -listpresets to see a full list.\n");
	printf("	 	-destination (or -dest) <outputFileURL>\n");
	printf("	 	-source <sourceMovieURL>\n");
	printf("		-replace   If there is a preexisting file at the destination location, remove it before exporting.");
	printf("	 	-filetype <file type string> The file type (eg com.apple.m4v-video) for the output file.  If not specified, the first supported type will be used.\n");
	printf("	 	-start <start time>  time in seconds (decimal are OK).  Removes the startClip time from the beginning of the movie before exporting.\n");
	printf("	 	-duration <duration>  time in seconds (decimal are OK).  Trims the movie to this duration before exporting.  \n");
	printf("	Also available are some setup options:\n");
	printf("		-verbose  Print more information about the execution.\n");
	printf("		-progress  Show progress information.\n");
	printf("		-listpresets  For sourceMovieURL sources only, lists the tracks in the source movie before the export.  \n");
	printf("		-listtracks  For sourceMovieURL sources only, lists the tracks in the source movie before the export.  \n");
	printf("			Always lists the tracks in the destination asset at the end of the export.\n");
	printf("		-listmetadata  Lists the metadata in the source movie before the export.  \n");
	printf("			Also lists the metadata in the destination asset at the end of the export.\n");
	printf("	Sample export lines:\n");
	printf("	./AVFoundationExporter -dest /tmp/testOut.m4v -replace -preset AVAssetExportPresetAppleM4ViPod -listmetadata -source /path/to/myTestMovie.m4v\n");
	printf("	./AVFoundationExporter -destination /tmp/testOut.mov -preset AVAssetExportPreset640x480 -listmetadata -listtracks -source /path/to/myTestMovie.mov\n");
}


static dispatch_time_t getDispatchTimeFromSeconds(float seconds) {
	long long milliseconds = seconds * 1000.0;
	dispatch_time_t waitTime = dispatch_time( DISPATCH_TIME_NOW, 1000000LL * milliseconds );
	return waitTime;
}

- (int)run
{	
	NSURL   *sourceURL = nil;
	AVAssetExportSession *avsession = nil;
	NSURL   *destinationURL = nil;
	BOOL	success = YES;

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSParameterAssert( [self sourcePath] != nil );

	if ([self listTracks] && [self sourcePath]) {
		[self doListTracks:[self sourcePath]];
	}
	if ([self listMetadata] && [self sourcePath]) {
		[self doListMetadata:[self sourcePath]];
	}
	if ([self destinationPath] == nil) {
		NSLog(@"No output path specified, only listing tracks and/or metadata, export was not performed.");
		goto bail;
	}
	if ([self preset] == nil) {
		NSLog(@"No preset specified, only listing tracks and/or metadata, export was not performed.");
		goto bail;
	}
	
	if ( [self isVerbose] && [self sourcePath] ) {
		printNSString([NSString stringWithFormat:@"all av asset presets:%@", [AVAssetExportSession allExportPresets]]);
	}
	
	if ([self sourcePath] != nil) {
		sourceURL = [[NSURL fileURLWithPath: [self sourcePath] isDirectory: NO] retain];
	}

	AVAsset *sourceAsset = nil;
	NSError* error = nil;
	
	if ([self isVerbose]) {
		printNSString([NSString stringWithFormat:@"AVAssetExport for preset:%@ to with source:%@", [self preset], [destinationURL path]]);
	}
	
	destinationURL = [NSURL fileURLWithPath: [self destinationPath] isDirectory: NO];
	if ([self removePreExistingFiles] && [[NSFileManager defaultManager] fileExistsAtPath:[self destinationPath]]) {
		if ([self isVerbose]) {
			printNSString([NSString stringWithFormat:@"Removing re-existing destination file at:%@", destinationURL]);
		}
		[[NSFileManager defaultManager] removeItemAtURL:destinationURL error:&error];
	}

	sourceAsset = [[[AVURLAsset alloc] initWithURL:sourceURL options:nil] autorelease];

	if ([self isVerbose]) {
		printNSString([NSString stringWithFormat:@"Compatible av asset presets:%@", [AVAssetExportSession exportPresetsCompatibleWithAsset:sourceAsset]]);
	}
	avsession = [[AVAssetExportSession alloc] initWithAsset:sourceAsset presetName:[self preset]];

	[avsession setOutputURL:destinationURL];

	if ([self fileType] != nil) {
		[avsession setOutputFileType:[self fileType]];
	}
	else {
		[avsession setOutputFileType:[[avsession supportedFileTypes] objectAtIndex:0]];
	}
	
	if ([self isVerbose]) {
		printNSString([NSString stringWithFormat:@"Created AVAssetExportSession: %p", avsession]);
		printNSString([NSString stringWithFormat:@"presetName:%@", [avsession presetName]]);
		printNSString([NSString stringWithFormat:@"source URL:%@", [sourceURL path]]);
		printNSString([NSString stringWithFormat:@"destination URL:%@", [[avsession outputURL] path]]);
		printNSString([NSString stringWithFormat:@"output file type:%@", [avsession outputFileType]]);
	}
	
	// Add a metadata item to indicate how thie destination file was created.
	NSArray *sourceMetadataList = [avsession metadata];
	sourceMetadataList = [self addNewMetadata: sourceMetadataList presetName:[self preset]];
	[avsession setMetadata:sourceMetadataList];
	
	// Set up the time range
	CMTime startTime = kCMTimeZero;
	CMTime durationTime = kCMTimePositiveInfinity;
	
	if ([self startSeconds] != nil) {
		startTime = CMTimeMake([[self startSeconds] floatValue] * 1000, 1000);
	}
	if ([self durationSeconds] != nil) {
		durationTime = CMTimeMake([[self durationSeconds] floatValue] * 1000, 1000);
	}
	CMTimeRange exportTimeRange = CMTimeRangeMake(startTime, durationTime);
	[avsession setTimeRange:exportTimeRange];
	
	// start a fresh pool for the export.
	[pool drain];
	pool = [[NSAutoreleasePool alloc] init];
	
	//  Set up a semaphore for the completion handler and progress timer
	dispatch_semaphore_t sessionWaitSemaphore = dispatch_semaphore_create( 0 );
	
	void (^completionHandler)(void) = ^(void)
	{
		dispatch_semaphore_signal(sessionWaitSemaphore);
	};
	
	// do it.
	[avsession exportAsynchronouslyWithCompletionHandler:completionHandler];

	do {
		dispatch_time_t dispatchTime = DISPATCH_TIME_FOREVER;  // if we dont want progress, we will wait until it finishes.
		if ([self showProgress]) {
			dispatchTime = getDispatchTimeFromSeconds((float)1.0);
			printNSString([NSString stringWithFormat:@"AVAssetExport running  progress=%3.2f%%", [avsession progress]*100]);
		}
		dispatch_semaphore_wait(sessionWaitSemaphore, dispatchTime);
	} while( [avsession status] < AVAssetExportSessionStatusCompleted );

	if ([self showProgress]) {
		printNSString([NSString stringWithFormat:@"AVAssetExport finished progress=%3.2f", [avsession progress]*100]);
	}
	
	[avsession release];
	avsession = nil;
	
	if ([self listMetadata] && [self destinationPath]) {
		[self doListMetadata:[self destinationPath]];
	}
	if ([self listTracks] && [self destinationPath]) {
		[self doListTracks:[self destinationPath]];
	}
	
	printNSString([NSString stringWithFormat:@"Finished export of %@ to %@ using preset:%@ success=%s\n", [self sourcePath], [self destinationPath], [self preset], (success ? "YES" : "NO")]);
	
bail:
	[sourceURL release];
	
	[pool drain];
	
	return success;
}


- (NSArray *) addNewMetadata: (NSArray *)sourceMetadataList presetName:(NSString *)presetName
{
	// This method creates a few new metadata items in different keySpaces to be inserted into the exported file along with the metadata that
	// was in the original source.  
	// Depending on the output file format, not all of these items will be valid and not all of them will come through to the destination.
	
	AVMutableMetadataItem *newUserDataCommentItem = [[[AVMutableMetadataItem alloc] init] autorelease];
	[newUserDataCommentItem setKeySpace:AVMetadataKeySpaceQuickTimeUserData];
	[newUserDataCommentItem setKey:AVMetadataQuickTimeUserDataKeyComment];
	[newUserDataCommentItem setValue:[NSString stringWithFormat:@"QuickTime userdata: Exported to preset %@ using AVFoundationExporter at: %@", presetName,
									  [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle: NSDateFormatterShortStyle]]];
	
	AVMutableMetadataItem *newMetaDataCommentItem = [[[AVMutableMetadataItem alloc] init] autorelease];
	[newMetaDataCommentItem setKeySpace:AVMetadataKeySpaceQuickTimeMetadata];
	[newMetaDataCommentItem setKey:AVMetadataQuickTimeMetadataKeyComment];
	[newMetaDataCommentItem setValue:[NSString stringWithFormat:@"QuickTime metadata: Exported to preset %@ using AVFoundationExporter at: %@", presetName,
									  [NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle: NSDateFormatterShortStyle]]];
	
	AVMutableMetadataItem *newiTunesCommentItem = [[[AVMutableMetadataItem alloc] init] autorelease];
	[newiTunesCommentItem setKeySpace:AVMetadataKeySpaceiTunes];
	[newiTunesCommentItem setKey:AVMetadataiTunesMetadataKeyUserComment];
	[newiTunesCommentItem setValue:[NSString stringWithFormat:@"iTunes metadata: Exported to preset %@ using AVFoundationExporter at: %@", presetName, 
									[NSDateFormatter localizedStringFromDate:[NSDate date] dateStyle:NSDateFormatterMediumStyle timeStyle: NSDateFormatterShortStyle]]];
	
	NSArray *newMetadata = [NSArray arrayWithObjects:newUserDataCommentItem, newMetaDataCommentItem, newiTunesCommentItem, nil];
	NSArray *newMetadataList = (sourceMetadataList == nil ? newMetadata : [sourceMetadataList arrayByAddingObjectsFromArray:newMetadata]);
	return newMetadataList;
}


+ (void) doListPresets
{ 
	//  A simple listing of the presets available for export
	printNSString(@"");
	printNSString(@"Presets available for AVFoundation export:");
	printNSString(@"  QuickTime movie presets:");
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPreset640x480]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPreset960x540]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPreset1280x720]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPreset1920x1080]);
	printNSString(@"  Audio only preset:");
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleM4A]);
	printNSString(@"  Apple device presets:");
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleM4VCellular]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleM4ViPod]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleM4V480pSD]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleM4VAppleTV]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleM4VWiFi]);
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleM4V720pHD]);
	printNSString(@"  Interim format (QuickTime movie) preset:");
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetAppleProRes422LPCM]);
	printNSString(@"  Passthrough preset:");
	printNSString([NSString stringWithFormat:@"    %@", AVAssetExportPresetPassthrough]);
	printNSString(@"");
}


- (void)doListTracks:(NSString *)assetPath
{ 
	//  A simple listing of the tracks in the asset provided
	NSURL *sourceURL = [NSURL fileURLWithPath: assetPath isDirectory: NO];
	if (sourceURL) {
		AVURLAsset *sourceAsset = [[[AVURLAsset alloc] initWithURL:sourceURL options:nil] autorelease];
		printNSString([NSString stringWithFormat:@"Listing tracks for asset from url:%@", [sourceURL path]]);
		NSInteger index = 0;
		for (AVAssetTrack *track in [sourceAsset tracks]) {
			[track retain];
			printNSString([ NSString stringWithFormat:@"  Track index:%ld, trackID:%d, mediaType:%@, enabled:%d, isSelfContained:%d", index, [track trackID], [track mediaType], [track isEnabled], [track isSelfContained] ] );
			index++;
			[track release];
		}
	}
}

enum {
	kMaxMetadataValueLength = 80,
};

- (void)doListMetadata:(NSString *)assetPath
{
	//  A simple listing of the metadata in the asset provided
	NSURL *sourceURL = [NSURL fileURLWithPath: assetPath isDirectory: NO];
	if (sourceURL) {
		AVURLAsset *sourceAsset = [[[AVURLAsset alloc] initWithURL:sourceURL options:nil] autorelease];
		NSLog(@"Listing metadata for asset from url:%@", [sourceURL path]);
		for (NSString *format in [sourceAsset availableMetadataFormats]) {
			NSLog(@"Metadata for format:%@", format);
			for (AVMetadataItem *item in [sourceAsset metadataForFormat:format]) {
				NSObject *key = [item key];
				NSString *itemValue = [[item value] description];
				if ([itemValue length] > kMaxMetadataValueLength) {
					itemValue = [NSString stringWithFormat:@"%@ ...", [itemValue substringToIndex:kMaxMetadataValueLength-4]];
				}
				if ([key isKindOfClass: [NSNumber class]]) {
					NSInteger longValue = [(NSNumber *)key longValue];
					char *charSource = (char *)&longValue;
					char charValue[5] = {0};
					charValue[0] = charSource[3];
					charValue[1] = charSource[2];
					charValue[2] = charSource[1];
					charValue[3] = charSource[0];
					NSString *stringKey = [[[NSString alloc] initWithBytes: charValue length:4 encoding:NSMacOSRomanStringEncoding] autorelease];
					printNSString([NSString stringWithFormat:@"  metadata item key:%@ (%ld), keySpace:%@ commonKey:%@ value:%@", stringKey, longValue, [item keySpace], [item commonKey], itemValue]);
				}
				else {
					printNSString([NSString stringWithFormat:@"  metadata item key:%@, keySpace:%@ commonKey:%@ value:%@", [item key], [item keySpace], [item commonKey], itemValue]);
				}
			}
		}
	}
}


@end


// ---------------------------------------------------------------------------
//		main
// ---------------------------------------------------------------------------


int main (int argc, const char * argv[], const char* environ[])
{
	NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
	AAPLExporter* exportObj = [[AAPLExporter alloc] initWithArgs:argc argv:argv  environ:environ];
	BOOL success;
	if (exportObj)
		success = [exportObj run];
	else {
		success = NO;
	}
	
	[exportObj release];
	[pool release];
	
	return ((success == YES) ? 0 : -1);
}


// ---------------------------------------------------------------------------
//		printNSString
// ---------------------------------------------------------------------------
static void printNSString(NSString *string)
{
	printf("%s\n", [string cStringUsingEncoding:NSUTF8StringEncoding]);
}

// ---------------------------------------------------------------------------
//		printArgs
// ---------------------------------------------------------------------------
static void printArgs(int argc, const char **argv)
{
	int i;
	for( i = 0; i < argc; i++ )
		printf("%s ", argv[i]);
	printf("\n");
}

