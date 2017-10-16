/*
See LICENSE.txt for this sample’s licensing information.

Abstract:
Boilerplate main for the FilterDemo extension. It is empty since all of the functionality is in the FilterDemo.framework.
*/

/* 
 A version 3 audio unit can be loaded into a separate extension service process and this is the default behavior. To be able to load in-process on macOS (see AudioComponentInstantiationOptions) requires that the audio unit is packaged in a bundle separate from the application extension since an extensions main binary cannot be dynamically loaded into another process.
 
 The Info.plist of the .appex bundle describes the type of extension and the principal class. It also contains an AudioComponents array (see AudioComponent.h) and an optional AudioComponentBundle entry to support loading in-process (see AUAudioUnitImplementation.h). If specified, the AudioComponentBundle entry designates the identifier of a bundle in the .appex or its enclosing app container in which the factory function and/or principal class are implemented.
 
 To facilitate loading in-process and into a separate extension process, the .appx main binary cannot contain any code. Therefore, all the plugin functionality is contained in the FilterDemo.framework and the .appx Info.plist contains an AudioComponentBundle entry specifying the frameworks bundle identifier.
 
    <key>AudioComponentBundle</key>
    <string>com.example.apple-samplecode.FilterDemoFrameworkOSX</string>
*/
void dummy() {}
