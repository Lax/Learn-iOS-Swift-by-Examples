# DemoBots: Building a Cross Platform Game with SpriteKit and GameplayKit

DemoBots is a fully-featured 2D game built with SpriteKit and GameplayKit, and written in Swift. It demonstrates how to use agents, goals, and behaviors to drive the movement of characters in your game, and how to use rule systems and state machines to provide those characters with intelligent behavior. You'll see how to integrate on-demand resources into a game to optimize resource usage and reduce the time needed to download additional levels.

DemoBots takes advantage of the Xcode scene and actions editor to create detailed level designs and animations. The sample also contains assets tailored to ensure the best experience on every supported device.

## Release Note

- There are limitations with texture loading and reference actions that prevent DemoBots from being run on 32-bit hardware in this release. These issues will be addressed in future OS releases.

## Requirements

### Build

Xcode 8.0, OS X 10.12 SDK, iOS 10.0 SDK, tvOS 10.0 SDK

### Runtime

OS X 10.12, iOS 10.0, tvOS 10.0

## About DemoBots

### Premise

You know those tiny robots that keep your electronic gadgets working correctly? Well: some of them have turned *bad*. It's up to you, PlayerBot, to teleport inside the gadgets and fix the bad robots with your Debug Beam.

### Gameplay

Each level of DemoBots contains one or more TaskBots - GroundBots that trundle around on caterpillar tracks, and FlyingBots that fly through the air. Some of these TaskBots start the level in a "bad" state, indicated by their red faces and red lights. Your job is to track down all of the "bad" TaskBots on the level and zap them with your beam for a few seconds until they turn "good". Watch out, though - bad TaskBots can attack good TaskBots and turn them bad too.

Each level is played against a time limit. If you turn all of the TaskBots "good" before the time runs out, you've completed the level successfully. Otherwise, you'll need to try the level again.

Your PlayerBot has a certain level of charge energy, indicated by a charge bar above the PlayerBot's head. You'll lose charge every time a TaskBot attacks you. Whenever your charge bar reaches zero, the PlayerBot will deactivate for a few seconds in order to recharge. You can't be attacked while you're in this recharging state.

"Bad" GroundBots speed towards you when you get near to them. If you don't get out of their way, they'll hit you and remove some of your charge.

Whenever a "bad" FlyingBot bumps in to another character, it performs a "blast" attack, indicated by a red smoke effect. If you get caught in one of these blast attacks, you'll lose charge while caught in the red smoke. If you successfully zap a FlyingBot and turn it to its "good" state, it will perform a beneficial "blast" attack, indicated by a green smoke effect. This beneficial attack cures any "bad" TaskBots that are close to the FlyingBot.

Your PlayerBot has a beam that can be fired at "bad" TaskBots to turn them "good". The beam can only fire for a limited time, after which the beam must recharge. This prevents you from running around the level with the fire button constantly pressed. You'll see the beam decay over time when you zap a TaskBot - if the beam decays completely before the TaskBot is cured, you'll have to zap that TaskBot again once your beam has recharged.

### Controls

#### Keyboard Controls

On OS X, you control the PlayerBot with the keyboard:

- "w" or "up arrow" moves the PlayerBot forwards.
- "d" or "right arrow" rotates the PlayerBot clockwise.
- "a" or "left arrow" rotates the PlayerBot counterclockwise.
- "s" or "down arrow" moves the PlayerBot backwards.
- "f", "space", or "mouse click" fires the PlayerBot's beam.
- "p" pauses the game.

##### Debug Keyboard Controls

DemoBots supports additional key commands on OS X to assist with debugging:

- "[" takes you straight to the "success" state for the current level, and is useful for quickly skipping the current level.
- "]" takes you straight to the "fail" state for the current level.
- "/" toggles the debug drawing overlay for the current level.

The debug drawing overlay shows the following information when enabled.

- Each TaskBot's current path, where the path color indicates:
	- Green for patrolling when good.
	- Purple for patrolling when bad.
	- Red for hunting the player or another TaskBot.
	- Yellow for returning to a point on a patrol path.
- White lines overlaid on the level's background show a map of the pathfinding grid for the current level.
- Orange boxes around obstacles show the extruded size of each obstacle in the level as used for TaskBot pathfinding.
- A blue arc shows the effective target zone for the PlayerBot's beam when the beam is activated.
- A cyan outline shows the physics body outline for any physical entity in the level.
- The current frame rate for the game is shown in the bottom right hand corner of the view.

#### Touch Controls

On iOS, you control the PlayerBot with on-screen thumbstick touch pads that emulate real-world controller thumbsticks:

- The left thumbstick controls the PlayerBot's movement.
- The right thumbstick fires the PlayerBot's beam when pressed, and changes the PlayerBot's orientation independently of its movement direction when moved.

#### Game Controllers

DemoBots uses the GameController framework to support game controllers on iOS, OS X, and tvOS.

Note: A physical controller paired to the Mac is required to play DemoBots in the tvOS simulator.

When using a controller that matches the Micro Gamepad profile:

- The d-pad controls the PlayerBot's movement.
- The controller's buttons (A, X) fire the PlayerBot's beam. (On the Apple TV remote, this action is triggered by clicking the touch surface or pressing the Play/Pause button.)
- The pause button pauses / resumes the game. (On the Apple TV remote, this action is triggered by pressing the Menu button.)

DemoBots supports the Micro Gamepad profile in both landscape and portrait orientations.

When using a controller that matches the Gamepad profile:

- The d-pad controls the PlayerBot's movement.
- The controller's buttons (A, B, X, Y, left shoulder, right shoulder) fire the PlayerBot's beam.
- The pause button pauses / resumes the game.

When using a controller that matches the Extended Gamepad profile:

- The d-pad and left thumbstick control the PlayerBot's movement.
- The right thumbstick controls the PlayerBot's orientation independently of its movement direction, and fires the beam when displaced.
- The controller's buttons (A, B, X, Y, left shoulder, right shoulder, left trigger, right trigger) fire the PlayerBot's beam.
- The pause button pauses / resumes the game.

### ReplayKit

DemoBots supports screen recording on iOS with ReplayKit to capture and share your gameplay. Enable auto-recording using the button on the game's home screen, and your gameplay will be automatically recorded as you play each level. At the end of each level, you can review a video of that level, and save or share the video.

## More Information

For more information about DemoBots, see WWDC 2015 session 609, "Deeper into GameplayKit with DemoBots", available from https://developer.apple.com/videos/wwdc/2015/ .

Copyright (C) 2016 Apple Inc. All rights reserved.
