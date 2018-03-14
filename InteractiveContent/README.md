# Interactive Content with ARKit

This sample demonstrates using SceneKit content with ARKit together to achieve an interactive AR experience.  

It uses ARKit to display an animated chameleon in a camera view. You can interact with the chameleon by touching it, and you can move it to new locations by tapping at a place or dragging the chameleon. The model also reacts to the user's movement based on the relative position and proximity of the camera.

## What this sample demonstrates

This sample demonstrates the following concepts:

* How to place an interactive animated SceneKit managed CG object (a chameleon) that you can interact with into a scene viewed through the device's camera.
* How to trigger and control animations of the object based on the user's movement and proximity.
* How to use shaders to adjust the appearance of that object based on what the camera is seeing (see the `ARSCNView` extension in the file `Extensions.swift`).

## Implementation Details

### Reacting on events in the renderer loop
The interactive chameleon in this sample reacts to various events based on the rendering loop and interactions by the user. These actions are triggered in the following methods in `Chameleon.swift`:

* `reactToInitialPlacement(in:)`: Called when a plane was detected and the chameleon is initially placed in the scene.
* `reactToPositionChange(in:)`: Called when the user moved the chameleon to a new location.
* `reactToTap(in:)`: Called when the user touched the chameleon.
* `reactToRendering(in:)`: Called at every frame at the beginning of a new rendering cycle. Used to control head and body turn animations based on the camera pose.
* `reactToDidApplyConstraints(in:)`: Called at every frame after all constraints have been applied. Used to update the position of the tongue.

### Placing the object on a horizontal plane
Plane detection is used to identify a horizontal surface on which the chameleon can be placed.
Once a plane has been found, the chameleon's transform is set to the plane anchor's transform in the `renderer(_:didAdd:for:)` method.

For reasons of simplicity in this sample, the model has already been invisibly loaded into the scene since the beginning, and the node's `hidden` property is set to `false` to display it. In a more complex scene, you could asynchronously load the content when needed.

### Looking at the user
The chameleon's eyes focus on the camera by a `SCNLookAtConstraint`. For a more natural saccadic eye movement, a random offset is additionally applied to the each eye's pose.

### Moving the head and body to face the user
In each frame, the chameleon's position in relation to the camera is computed (see `reactToRendering(in:)`) to determine whether the user is within the chameleon's field of view. In that case, the chameleon moves its head (with some delay) to look at the user (see `handleWithinFieldOfView(localTarget:distance:)`). In this method, it is also checked whether

* the user has reached a certain threshold distance. In that case, the chameleon's head movement follows the user closely without a delay ("target lock").
* the user is within reach of the tongue. In that case, the chameleon opens the mouth and prepares for shooting the tongue.

The head movement is realized by a `SCNLookAtConstraint`.

If the camera pose is such that the chameleon cannot turn its head to face the user, a turn animation is triggered to obtain a better position (see `playTurnAnimation(_:)`).

### Shooting the tongue based on proximity
When shooting the tongue, it has to be ensured that it moves towards to user and sticks to the screen even when the camera moves. For that reason, the tongue's position must be updated each frame. This is done in `reactToDidApplyConstraints(in:)` to ensure that this happens after other animations, like head rotation, have already been applied.

### Adjusting the appearance based on what the camera is seeing
Chameleons can change color to adapt to the environment. This is done upon initial placement and when the chameleon is moved (see `activateCamouflage(_:)` and `updateCamouflage(_:)`).

The camouflage color is determined by retrieving an average color in a patch taken from the center of the current camera image (see `averageColorFromEnvironment(at:)` in `Extensions.swift`).

The camouflage is then applied by modifying two variables in a Metal shader:

* `blendFactor` allows to blend between an opaque colorful texture, and a semitransparent texture which can be combined with a uniform color.
* `skinColorFromEnvironment` sets the base color that shines through the transparent parts of the texture, creating a skin tone that is dominated by this color.


## Useful Resources

* [ARKit Framework](https://developer.apple.com/documentation/arkit)

* [WWDC 2017 - Session 602, Introducing ARKit: Augmented Reality for iOS ](https://developer.apple.com/videos/play/wwdc2017/602/)

## Requirements

### Running the sample

* For plane detection to work, you will need to view a flat and sufficiently textured surface through the on device camera while this sample is running.
* Try out differently colored surfaces to see the chameleon change its color.

### Build

Xcode 9 and iOS 11 SDK

### Runtime

iOS 11 or later

ARKit requires an iOS device with an A9 or later processor.

Copyright (C) 2017 Apple Inc. All rights reserved.
