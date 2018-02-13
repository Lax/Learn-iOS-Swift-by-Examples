/*
 Copyright (C) 2017 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 Downloads, parses, and imports the iTunes top songs RSS feed into Core Data.
 */

#import "iTunesRSSImporter.h"
#import "Song.h"
#import "Category.h"
#import "CategoryCache.h"
#import <libxml/tree.h>

// Function prototypes for SAX callbacks. This sample implements a minimal subset of SAX callbacks.
// Depending on your application's needs, you might want to implement more callbacks.
static void startElementSAX(void *context, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes);
static void endElementSAX(void *context, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI);
static void charactersFoundSAX(void *context, const xmlChar *characters, int length);
static void errorEncounteredSAX(void *context, const char *errorMessage, ...);

// Forward reference. The structure is defined in full at the end of the file.
static xmlSAXHandler simpleSAXHandlerStruct;


#pragma mark -

// Class extension for private properties and methods.
@interface iTunesRSSImporter () <NSURLSessionDataDelegate>

// Reference to the libxml parser context
@property xmlParserCtxtPtr context;

// The following state variables deal with getting character data from XML elements. This is a potentially expensive
// operation. The character data in a given element may be delivered over the course of multiple callbacks, so that
// data must be appended to a buffer. The optimal way of doing this is to use a C string buffer that grows exponentially.
// When all the characters have been delivered, an NSString is constructed and the buffer is reset.
@property BOOL storingCharacters;
@property (nonatomic, strong) NSMutableData *characterBuffer;

// Overall state of the importer, used to exit the run loop.
@property BOOL done;

// State variable used to determine whether or not to ignore a given XML element
@property BOOL parsingASong;

// The number of parsed songs is tracked so that the autorelease pool for the parsing thread can be periodically
// emptied to keep the memory footprint under control.
@property NSUInteger countForCurrentBatch;

// A reference to the current song the importer is working with.
@property (nonatomic, strong) Song *currentSong;

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSURLSessionDataTask *sessionTask;

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property NSUInteger rankOfCurrentSong;

@property (nonatomic, strong) NSManagedObjectContext *insertionContext;
@property (nonatomic, strong) NSEntityDescription *songEntityDescription;
@property (nonatomic, strong) CategoryCache *theCache;

@end


#pragma mark -

static double lookuptime = 0;

@implementation iTunesRSSImporter

- (void)main {

    if (self.delegate && [self.delegate respondsToSelector:@selector(importerDidSave:)]) {
        [[NSNotificationCenter defaultCenter] addObserver:self.delegate
                                                 selector:@selector(importerDidSave:)
                                                     name:NSManagedObjectContextDidSaveNotification
                                                   object:self.insertionContext];
    }
    self.done = NO;
    _dateFormatter = [[NSDateFormatter alloc] init];
    self.dateFormatter.dateStyle = NSDateFormatterLongStyle;
    self.dateFormatter.timeStyle = NSDateFormatterNoStyle;
    // necessary because iTunes RSS feed is not localized, so if the device region has been set to other than US
    // the date formatter must be set to US locale in order to parse the dates
    self.dateFormatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"US"];
    _characterBuffer = [NSMutableData data];
    
    // create the session with the request and start loading the data
    NSURLRequest *request = [NSURLRequest requestWithURL:self.iTunesURL];
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    _session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    _sessionTask = [self.session dataTaskWithRequest:request];
    if (self.sessionTask != nil) {
        
        [self.sessionTask resume];

        // This creates a context for "push" parsing in which chunks of data that are not "well balanced" can be passed
        // to the context for streaming parsing. The handler structure defined above will be used for all the parsing. 
        // The second argument, self, will be passed as user data to each of the SAX handlers. The last three arguments
        // are left blank to avoid creating a tree in memory.
        //
        _context = xmlCreatePushParserCtxt(&simpleSAXHandlerStruct, (__bridge void *)(self), NULL, 0, NULL);
        do {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        } while (!self.done);
        
        // Display the total time spent finding a specific object for a relationship
        NSLog(@"lookup time %f", lookuptime);
        
        // Release resources used only in this thread.
        xmlFreeParserCtxt(self.context);
        _characterBuffer = nil;
        self.dateFormatter = nil;
        self.currentSong = nil;
        _theCache = nil;
        
        [self.insertionContext performBlockAndWait:^{
            NSError *saveError = nil;
            NSAssert1([self.insertionContext save:&saveError],
                        @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
            
            if (self.delegate && [self.delegate respondsToSelector:@selector(importerDidSave:)]) {
                [[NSNotificationCenter defaultCenter] removeObserver:self.delegate
                                                                name:NSManagedObjectContextDidSaveNotification
                                                              object:self.insertionContext];
            }
            
            // Call our delegate to signify parse completion.
            if (self.delegate != nil && [self.delegate respondsToSelector:@selector(importerDidFinishParsingData:)]) {
                [self.delegate importerDidFinishParsingData:self];
            }
        }];
    }
}

- (NSManagedObjectContext *)insertionContext {
    
    if (_insertionContext == nil) {
        _insertionContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        _insertionContext.persistentStoreCoordinator = self.persistentStoreCoordinator;
    }
    return _insertionContext;
}

- (void)forwardError:(NSError *)error {
    
    if (self.delegate != nil && [self.delegate respondsToSelector:@selector(importer:didFailWithError:)]) {
        [self.delegate importer:self didFailWithError:error];
    }
}

- (NSEntityDescription *)songEntityDescription {
    
    if (_songEntityDescription == nil) {
        _songEntityDescription = [NSEntityDescription entityForName:@"Song" inManagedObjectContext:self.insertionContext];
    }
    return _songEntityDescription;
}

- (CategoryCache *)theCache {
    
    if (_theCache == nil) {
        _theCache = [[CategoryCache alloc] init];
        _theCache.managedObjectContext = self.insertionContext;
    }
    return _theCache;
}

- (Song *)currentSong {
    
    if (_currentSong == nil) {
        _currentSong = [[Song alloc] initWithEntity:self.songEntityDescription insertIntoManagedObjectContext:self.insertionContext];
        _currentSong.rank = @(++_rankOfCurrentSong);
    }
    return _currentSong;
}


#pragma mark - NSURLSessionDataDelegate methods

// Sent when data is available for the delegate to consume.
//
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    
    // Process the downloaded chunk of data.
    xmlParseChunk(self.context, (const char *)data.bytes, (int)data.length, 0);
}

// Sent as the last message related to a specific task.
// Error may be nil, which implies that no error occurred and this task is complete.
//
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error != nil) {

        if (error.code == NSURLErrorAppTransportSecurityRequiresSecureConnection)
        {
            // if you get error NSURLErrorAppTransportSecurityRequiresSecureConnection (-1022),
            // then your Info.plist has not been properly configured to match the target server.
            //
            abort();
        }
        
        [self performSelectorOnMainThread:@selector(forwardError:) withObject:error waitUntilDone:NO];
    }
    
    // Signal the context that parsing is complete by passing "1" as the last parameter.
    xmlParseChunk(self.context, NULL, 0, 1);
    _context = NULL;
    // Set the condition which ends the run loop.
    self.done = YES;
}


#pragma mark - Parsing support methods

static const NSUInteger kImportBatchSize = 20;

- (void)finishedCurrentSong {
    
    self.parsingASong = NO;
    self.currentSong = nil;
    self.countForCurrentBatch++;

    if (self.countForCurrentBatch == kImportBatchSize) {
        
        NSError *saveError = nil;
        NSAssert1([self.insertionContext save:&saveError], @"Unhandled error saving managed object context in import thread: %@", [saveError localizedDescription]);
        self.countForCurrentBatch = 0;
    }
}

/*
 Character data is appended to a buffer until the current element ends.
 */
- (void)appendCharacters:(const char *)charactersFound length:(NSInteger)length {
    
    [self.characterBuffer appendBytes:charactersFound length:length];
}

- (NSString *)currentString {
    
    // Create a string with the character data using UTF-8 encoding. UTF-8 is the default XML data encoding.
    NSString *currentString = [[NSString alloc] initWithData:self.characterBuffer encoding:NSUTF8StringEncoding];
    self.characterBuffer.length = 0;
    return currentString;
}

@end


#pragma mark - SAX Parsing Callbacks

// The following constants are the XML element names and their string lengths for parsing comparison.
// The lengths include the null terminator, to ensure exact matches.
static const char *kName_Item = "item";
static const NSUInteger kLength_Item = 5;
static const char *kName_Title = "title";
static const NSUInteger kLength_Title = 6;
static const char *kName_Category = "category";
static const NSUInteger kLength_Category = 9;
static const char *kName_Itms = "itms";
static const NSUInteger kLength_Itms = 5;
static const char *kName_Artist = "artist";
static const NSUInteger kLength_Artist = 7;
static const char *kName_Album = "album";
static const NSUInteger kLength_Album = 6;
static const char *kName_ReleaseDate = "releasedate";
static const NSUInteger kLength_ReleaseDate = 12;

/*
 This callback is invoked when the importer finds the beginning of a node in the XML. For this application,
 out parsing needs are relatively modest - we need only match the node name. An "item" node is a record of
 data about a song. In that case we create a new Song object. The other nodes of interest are several of the
 child nodes of the Song currently being parsed. For those nodes we want to accumulate the character data
 in a buffer. Some of the child nodes use a namespace prefix. 
 */
static void startElementSAX(void *parsingContext, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI, 
                            int nb_namespaces, const xmlChar **namespaces, int nb_attributes, int nb_defaulted, const xmlChar **attributes) {
    
    iTunesRSSImporter *importer = (__bridge iTunesRSSImporter *)parsingContext;
    // The second parameter to strncmp is the name of the element, which we known from the XML schema of the feed.
    // The third parameter to strncmp is the number of characters in the element name, plus 1 for the null terminator.
    if (prefix == NULL && !strncmp((const char *)localname, kName_Item, kLength_Item)) {
        importer.parsingASong = YES;
    } else if (importer.parsingASong && ( (prefix == NULL && (!strncmp((const char *)localname, kName_Title, kLength_Title) || !strncmp((const char *)localname, kName_Category, kLength_Category))) || ((prefix != NULL && !strncmp((const char *)prefix, kName_Itms, kLength_Itms)) && (!strncmp((const char *)localname, kName_Artist, kLength_Artist) || !strncmp((const char *)localname, kName_Album, kLength_Album) || !strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate))) )) {
        importer.storingCharacters = YES;
    }
}

/*
 This callback is invoked when the parse reaches the end of a node. At that point we finish processing that node,
 if it is of interest to us. For "item" nodes, that means we have completed parsing a Song object. We pass the song
 to a method in the superclass which will eventually deliver it to the delegate. For the other nodes we
 care about, this means we have all the character data. The next step is to create an NSString using the buffer
 contents and store that with the current Song object.
 */
static void endElementSAX(void *parsingContext, const xmlChar *localname, const xmlChar *prefix, const xmlChar *URI) {
    
    iTunesRSSImporter *importer = (__bridge iTunesRSSImporter *)parsingContext;
    if (importer.parsingASong == NO) return;
    if (prefix == NULL) {
        if (!strncmp((const char *)localname, kName_Item, kLength_Item)) {
            [importer finishedCurrentSong];
        } else if (!strncmp((const char *)localname, kName_Title, kLength_Title)) {
            importer.currentSong.title = importer.currentString;
        } else if (!strncmp((const char *)localname, kName_Category, kLength_Category)) {
            double before = [NSDate timeIntervalSinceReferenceDate];
            Category *category = [importer.theCache categoryWithName:importer.currentString];
            double delta = [NSDate timeIntervalSinceReferenceDate] - before;
            lookuptime += delta;
            importer.currentSong.category = category;
        }
    } else if (!strncmp((const char *)prefix, kName_Itms, kLength_Itms)) {
        if (!strncmp((const char *)localname, kName_Artist, kLength_Artist)) {
            importer.currentSong.artist = importer.currentString;
        } else if (!strncmp((const char *)localname, kName_Album, kLength_Album)) {
            importer.currentSong.album = importer.currentString;
        } else if (!strncmp((const char *)localname, kName_ReleaseDate, kLength_ReleaseDate)) {
            NSString *dateString = importer.currentString;
            importer.currentSong.releaseDate = [importer.dateFormatter dateFromString:dateString];
        }
    }
    importer.storingCharacters = NO;
}

/*
 This callback is invoked when the parser encounters character data inside a node. The importer class determines how to use the character data.
 */
static void charactersFoundSAX(void *parsingContext, const xmlChar *characterArray, int numberOfCharacters) {
    
    iTunesRSSImporter *importer = (__bridge iTunesRSSImporter *)parsingContext;
    // A state variable, "storingCharacters", is set when nodes of interest begin and end. 
    // This determines whether character data is handled or ignored. 
    if (importer.storingCharacters == NO) return;
    [importer appendCharacters:(const char *)characterArray length:numberOfCharacters];
}

/*
 A production application should include robust error handling as part of its parsing implementation.
 The specifics of how errors are handled depends on the application.
 */
static void errorEncounteredSAX(void *parsingContext, const char *errorMessage, ...) {
    
    // Handle errors as appropriate for your application.
    NSCAssert(NO, @"Unhandled error encountered during SAX parse.");
}

// The handler struct has positions for a large number of callback functions. If NULL is supplied at a given position,
// that callback functionality won't be used. Refer to libxml documentation at http://www.xmlsoft.org for more information
// about the SAX callbacks.
static xmlSAXHandler simpleSAXHandlerStruct = {
NULL,                       /* internalSubset */
NULL,                       /* isStandalone   */
NULL,                       /* hasInternalSubset */
NULL,                       /* hasExternalSubset */
NULL,                       /* resolveEntity */
NULL,                       /* getEntity */
NULL,                       /* entityDecl */
NULL,                       /* notationDecl */
NULL,                       /* attributeDecl */
NULL,                       /* elementDecl */
NULL,                       /* unparsedEntityDecl */
NULL,                       /* setDocumentLocator */
NULL,                       /* startDocument */
NULL,                       /* endDocument */
NULL,                       /* startElement*/
NULL,                       /* endElement */
NULL,                       /* reference */
charactersFoundSAX,         /* characters */
NULL,                       /* ignorableWhitespace */
NULL,                       /* processingInstruction */
NULL,                       /* comment */
NULL,                       /* warning */
errorEncounteredSAX,        /* error */
NULL,                       /* fatalError //: unused error() get all the errors */
NULL,                       /* getParameterEntity */
NULL,                       /* cdataBlock */
NULL,                       /* externalSubset */
XML_SAX2_MAGIC,             //
NULL,
startElementSAX,            /* startElementNs */
endElementSAX,              /* endElementNs */
NULL,                       /* serror */
};
