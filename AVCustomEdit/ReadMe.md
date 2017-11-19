# AVCustomEdit

Using AVFoundation custom compositors to add transitions to an AVMutableComposition.

## Overview

AVCustomEdit is a simple AVFoundation based movie editing application demonstrating custom compositing to add transitions. The sample demonstrates the use of custom compositors to add transitions to an AVMutableComposition. It implements the AVVideoCompositing and AVVideoCompositionInstruction protocols to have access to individual source frames, which are then rendered using OpenGL or Metal off screen rendering.

Note: These developed transitions are not supported on simulator.

The main classes are as follows:

APLViewController:

A UIViewController subclass. This contains the view controller logic including playback and editing setup.

APLTransitionTypeController:

A subclass of UITableViewController which controls UI for selecting transition type.

APLSimpleEditor:

This class setups an AVComposition with relevant AVVideoCompositions using the provided clips and time ranges.

APLCustomVideoCompositionInstruction:

Custom video composition instruction class implementing AVVideoCompositionInstruction protocol.

APLCustomVideoCompositor:

Custom video compositor class implementing AVVideoCompositing protocol.


Objective-C Target

APLOpenGLRenderer:

Base class renderer setups an EAGLContext for rendering, it also loads, compiles and links the vertex and fragment shaders for both Y and UV plane.

APLDiagonalWipeRenderer:

A subclass of APLOpenGLRenderer, renders the given source buffers to perform a diagonal wipe over the transition time range.

APLCrossDissolveRenderer:

A subclass of APLOpenGLRenderer, renders the given source buffers to perform a cross dissolve over the transition time range.


Swift Target

APLMetalRenderer:

Base class renderer setups a reference to the preferred system default Metal device.

APLDiagonalWipeRenderer:

A subclass of APLMetalRenderer, renders the given source buffers to perform a diagonal wipe over the transition time range.

APLCrossDissolveRenderer:

A subclass of APLMetalRenderer, renders the given source buffers to perform a cross dissolve over the transition time range.


## Requirements

### Build

Xcode 8.3.3, iOS 10.0 SDK

### Runtime

iOS 9.3.3 or later

Copyright (C) 2013 - 2017 Apple Inc. All rights reserved.
