
# SimpleGestureRecognizers: Using standard UIGestureRecognizers

This sample shows how to use standard gesture recognizers. 

The functionality is implemented in the ViewController class--a view controller that manages a view and gesture recognizers.

The view controller's view has four gesture recognizers to recognize a tap, a right swipe, a left swipe, and a rotation gesture. When they recognize a gesture, the recognizers send a suitable message to the view controller, which in turn displays an appropriate image at the location of the gesture.

The view controller acts as a delegate for the tap recognizer so that it can disallow recognition of a tap within the segmented control. Recognizers ignore the exclusive touch setting for views. This is so that they can consistently recognize gestures even if they cross other views. For example, suppose you had two buttons, each marked exclusive touch, and you added a pinch gesture recognizer to their superview. That a finger came down in one the of the buttons shouldn't prevent you from pinching in the general case. If you do want to selectively disallow recognition of a gesture, you can use the recognizer's delegate methods. In this example, the view controller uses gestureRecognizer:shouldReceiveTouch: to test whether the tap recognizer will try to recognize a touch in the segmented control. If it is, it is disallowed.

In general, there's no need to maintain a reference to a recognizer once you've added it to a view. You can simply implement the appropriate callback method for the recognizer and wait for messages. This is shown in the cases of the right swipe and rotation recognizers. In some situations, however, it may be appropriate to maintain a reference to the recognizer, so that you can for example determine which recognizer sent a delegate message. This is shown in the cases of the left swipe and tap recognizers.

For the purpose of illustration, the left swipe recognizer can be enabled and disabled by toggling a segmented control. The view controller maintains a reference to the recognizer so that it can be added to and removed from the view as appropriate.

## Requirements

### Build

Xcode 6.0 or later, iOS 8 SDK or later.

### Runtime

iOS 7 or later.

----
Copyright (C) 2014 Apple Inc. All rights reserved.
