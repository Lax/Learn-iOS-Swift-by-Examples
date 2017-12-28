/*
     File: SampleController.m 
 Abstract: Main controller object for the CallJS sample. 
  Version: 1.1 
  
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple 
 Inc. ("Apple") in consideration of your agreement to the following 
 terms, and your use, installation, modification or redistribution of 
 this Apple software constitutes acceptance of these terms.  If you do 
 not agree with these terms, please do not use, install, modify or 
 redistribute this Apple software. 
  
 In consideration of your agreement to abide by the following terms, and 
 subject to these terms, Apple grants you a personal, non-exclusive 
 license, under Apple's copyrights in this original Apple software (the 
 "Apple Software"), to use, reproduce, modify and redistribute the Apple 
 Software, with or without modifications, in source and/or binary forms; 
 provided that if you redistribute the Apple Software in its entirety and 
 without modifications, you must retain this notice and the following 
 text and disclaimers in all such redistributions of the Apple Software. 
 Neither the name, trademarks, service marks or logos of Apple Inc. may 
 be used to endorse or promote products derived from the Apple Software 
 without specific prior written permission from Apple.  Except as 
 expressly stated in this notice, no other rights or licenses, express or 
 implied, are granted by Apple herein, including but not limited to any 
 patent rights that may be infringed by your derivative works or by other 
 works in which the Apple Software may be incorporated. 
  
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE 
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION 
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS 
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND 
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS. 
  
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL 
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF 
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS 
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, 
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED 
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE), 
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE 
 POSSIBILITY OF SUCH DAMAGE. 
  
 Copyright (C) 2011 Apple Inc. All Rights Reserved. 
  
 */


#import "SampleController.h"


@implementation SampleController


	/* storage management for our sharedValue instance variable.  The other
	instance variables are taken care of by the nib loading process, so we don't
	manage them here.
	*/
-(id) init {
    self = [super init];
	if (self) {
		sharedValue = [[NSString alloc] initWithString:@"okay"];
	}
	return self;
}

- (void) dealloc {
	self.sharedValue = nil;
	[super dealloc];
}



	/* accessor methods for our sharedValue instance variable.  If you watch the run log
	you'll see that JavaScript does NOT use these accessors for setting and getting the
	shared field value.  This may be an important consideration for you if you are
	relying on KVC accessors to add some special processing surrounding your instance
	variable access.
	*/
- (NSString *)sharedValue {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    return [[sharedValue retain] autorelease];
}

- (void)setSharedValue:(NSString *)value {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
    if (sharedValue != value) {
        [sharedValue release];
        sharedValue = [value copy];
    }
}




	/* called when our nib is loaded into memory and ready for action.
	Here, we initialize our web view and load in the initial html.
	*/
- (void) awakeFromNib {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
	
	
	NSLog(@"app plugins path = '%@'", [[NSBundle mainBundle] builtInPlugInsPath]);
	
		/* set ourself to the app's delegate so our
		applicationShouldTerminateAfterLastWindowClosed
		method will be called. */
	[NSApp setDelegate: self];

		/* set self as UI and Resource Load delegate for our WebView */
	[theWebView setUIDelegate: self];
	[theWebView setResourceLoadDelegate: self];
	
		/* Ask webKit to load the test.html file from our resources directory. */
	[[theWebView mainFrame] loadRequest:
		[NSURLRequest requestWithURL:
			[NSURL fileURLWithPath:
				[[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"]]]];
	
}



	/* this NSApplication delegate method will allow our application
	to 'quit' when the user closes the main window.
	*/
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
	return YES;  /* quit when main window is closed */
}



	/* this message is sent to the WebView's frame load delegate 
	when the page is ready for JavaScript.  It will be called just after 
	the page has loaded, but just before any JavaScripts start running on the
	page.  This is the perfect time to install any of your own JavaScript
	objects on the page.
	*/
- (void)webView:(WebView *)webView windowScriptObjectAvailable:(WebScriptObject *)windowScriptObject {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));

		/* here we'll add our object to the window object as an object named
		'console'.  We can use this object in JavaScript by referencing the 'console'
		property of the 'window' object.   */
    [windowScriptObject setValue:self forKey:@"console"];

}



	/* sent to the WebView's ui delegate when alert() is called in JavaScript.
	If you call alert() in your JavaScript methods, it will call this
	method and display the alert message in the log.  In Safari, this method
	displays an alert that presents the message to the user.
	*/
- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message {
	NSLog(@"%@ received %@ with '%@'", self, NSStringFromSelector(_cmd), message);
}



	/* This method is called when the 'Call JavaScript Function' button
	is pressed in the UI.  Here, we retrieve the parameters
	from the two text fields in the UI, build a parameter list, and then
	we call through to the JavaScript function named 'SampleFunction'.
	The result returned by SampleFunction is displayed in the UI.
	
	callWebScriptMethod:withArguments: is available in Mac OS X 10.3.9 and later.
	*/
- (IBAction)callJavaScriptWithParameters:(id)sender {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
	
		/* set up the function arguments */
	NSArray* args = [NSArray arrayWithObjects:
			[paramOne stringValue],
			[paramTwo stringValue],
			nil];

		/* call the javascript function named SampleFunction */
	[callResult setStringValue:
		[[theWebView windowScriptObject] callWebScriptMethod:@"SampleFunction" withArguments:args]];
}



	/* This method is called when the 'Run JavaScript' button is pressed in the UI.
	Here, we retrieve the JavaScript we want to run from the UI, run the script, and
	display the result in the UI.
	
	stringByEvaluatingJavaScriptFromString: is available in Mac OS X 10.2 (with
	Safari installed) and in Mac OS X 10.2.7 and later.
	*/
- (IBAction)runJavaScript:(id)sender {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
	
	[runResult setStringValue:
		[theWebView stringByEvaluatingJavaScriptFromString:[[scriptText textStorage] string]]];

}



	/* the following three methods are used to determine 
	what methods on our object are exposed to JavaScript */


	/* This method is called by the WebView when it is deciding what
	methods on this object can be called by JavaScript.  The method
	should return NO the methods we would like to be able to call from
	JavaScript, and YES for all of the methods that cannot be called
	from JavaScript.
	*/
+ (BOOL)isSelectorExcludedFromWebScript:(SEL)selector {
	NSLog(@"%@ received %@ for '%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(selector));
    if (selector == @selector(doOutputToLog:)
	|| selector == @selector(changeJavaScriptText:)
	|| selector == @selector(reportSharedValue)) {
        return NO;
    }
    return YES;
}



	/* This method is called by the WebView to decide what instance
	variables should be shared with JavaScript.  The method should
	return NO for all of the instance variables that should be shared
	between JavaScript and Objective-C, and YES for all others.
	*/
+ (BOOL)isKeyExcludedFromWebScript:(const char *)property {
	NSLog(@"%@ received %@ for '%s'", self, NSStringFromSelector(_cmd), property);
	if (strcmp(property, "sharedValue") == 0) {
        return NO;
    }
    return YES;
}



	/* This method converts a selector value into the name we'll be using
	to refer to it in JavaScript.  here, we are providing the following
	Objective-C to JavaScript name mappings:
		'doOutputToLog:' => 'log'
		'changeJavaScriptText:' => 'setscript'
	With these mappings in place, a JavaScript call to 'console.log' will
	call through to the doOutputToLog: Objective-C method, and a JavaScript call
	to console.setscript will call through to the changeJavaScriptText:
	Objective-C method.  
	
	Comments for the webScriptNameForSelector: method in WebScriptObject.h talk more
	about the default name conversions performed from Objective-C to JavaScript names.
	You can overrride those defaults by providing your own translations in your
	webScriptNameForSelector: method.
	*/
+ (NSString *) webScriptNameForSelector:(SEL)sel {
	NSLog(@"%@ received %@ with sel='%@'", self, NSStringFromSelector(_cmd), NSStringFromSelector(sel));
    if (sel == @selector(doOutputToLog:)) {
		return @"log";
    } else if (sel == @selector(changeJavaScriptText:)) {
		return @"setscript";
	/*
		NOTE:  for the console.report method, we do not need to perform a name translation
		because the Objective-C method name is already the same as the method name
		we will be using in JavaScript.  We have left this part commented out to show
		that the name translation here would be redundant.
		  
    } else if (sel == @selector(report)) {
		return @"report";
		
	*/
	} else {
		return nil;
	}
}



	/* Here is our Objective-C implementation for the JavaScript console.log() method.
	*/
- (void) doOutputToLog: (NSString*) theMessage {
	NSLog(@"%@ received %@ with message=%@", self, NSStringFromSelector(_cmd), theMessage);
		
		/* write the message to the log */
    NSLog(@"LOG: %@", theMessage);

}



	/* Here is our Objective-C implementation for the JavaScript console.setscript() method.
	*/
- (NSString*) changeJavaScriptText: (NSString*) theScriptText {
	NSLog(@"%@ received %@ with script=%@", self, NSStringFromSelector(_cmd), theScriptText);
	
		/* set the script text to the parameter */
	[scriptText setString: theScriptText];
		
		/* return a result to display in the status field */
	return @"okay";
}


	/* Here is our Objective-C implementation for the JavaScript console.report() method.
	Mote that this Objective-C method uses the same name as the JavaScript method.  In cases
	where your Objective-C methods do not have any parameters, you can use the automatic name
	sharing performed by WebKit.
	*/
- (void) report {
	NSLog(@"%@ received %@", self, NSStringFromSelector(_cmd));
		
		/* write the message to the log */
    NSLog(@"sharedValue = %@", self.sharedValue);

}


@end
