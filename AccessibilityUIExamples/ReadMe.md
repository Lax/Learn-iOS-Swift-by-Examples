# Accessibility UI Examples

This sample shows how to implement accessibility for several common UI controls. The examples make the controls accessible by using accessibility properties, accessibility protocols, and the [`NSAccessibilityElement`](https://developer.apple.com/documentation/appkit/nsaccessibilityelement) class.


## Overview

In macOS 10.10, the Accessibility API moved to a protocol-based approach, in contrast to the key-based API from macOS 10.9 and earlier.

The goals of this API are to:

* Simplify the implementation of accessibility
* Achieve better API parity with iOS
* Ensure compatibility with existing applications and code


Prior versions of the Accessibility API are deprecated, but can coexist alongside the new API. No changes are required for applications or accessibility clients that use prior versions of the Accessibility API. If both the new API and old API are implemented on the same class, the new API always takes precedence for that class. For cell-based controls, Accessibility API implementations should always be provided on the cell.


## Accessibility Properties

Most accessibility attributes from 10.9 and earlier are now properties on the following AppKit classes:

* `NSApplication`
* `NSWindow`
* `NSView`
* `NSDrawer`
* `NSPopover`
* `NSCell`

To set an accessibility attribute value on an instance of one of these classes (or a subclass), simply assign the value to the property:

``` swift
button.setAccessibilityLabel(NSLocalizedString("My label", comment: "label to use for this button"))
```

or override the getter in the subclass's implementation:

``` swift
override func accessibilityLabel() -> String? {
    return NSLocalizedString("Play", comment: "accessibility label of the Play button")
}
```
[View in Source](x-source-tag://accessibilityLabel)

The [`NSAccessibility`](https://developer.apple.com/documentation/appkit/nsaccessibility) contains the full list of accessibility properties.


## Accessibility Protocols

The new Accessibility API includes accessibility protocols that define the required accessibility functions for many common accessibility elements. Conformance to an accessibility protocol is not required to use the new API, but conformance is recommended when making custom controls accessible. Conforming to an accessibility protocol displays a warning for each unimplemented required function and allows the accessibilityRole and isAccessibilityElement properties to be automatically inferred.

Standard AppKit controls conform to the appropriate accessibility protocol (for example, NSButton conforms to NSAccessibilityButton protocol, and NSSlider conforms to NSAccessibilitySlider protocol). Whenever possible, subclass from the appropriate AppKit control to leverage the built-in accessibility.

To add accessibility to a custom control:

1. Conform to the appropriate protocol.
2. Implement all the required functions. A warning appears for each unimplemented required function.
3. Test using VoiceOver and Accessibility Inspector.

For example, to create a custom control that subclasses NSView and draws and behaves like a button:

``` swift
class CustomButtonView: NSView {
```
[View in Source](x-source-tag://customButtonDeclare)

If a custom control does not conform to an accessibility protocol, the accessibilityRole and isAccessibilityElement functions must also be implemented:

``` swift
override func accessibilityRole() -> NSAccessibilityRole? {
    return NSAccessibilityRole.button
}
    
override func isAccessibilityElement() -> Bool {
    return true
}
```
[View in Source](x-source-tag://customButtonAdoption)


## `NSAccessibilityElement`

For objects that do not have a backing view (for example, a single view that draws several images, each of which should be individually accessible), create an instance of `NSAccessibilityElement` for each object, and return an array of the instances from the accessibility parent's `accessibilityChildren` function.


## Convenience Methods

`NSAccessibilityElement` has two convenience methods to simplify its use.

The [`accessibilityAddChildElement`](https://developer.apple.com/documentation/appkit/nsaccessibilityelement/1533717-accessibilityaddchildelement) function sets the specified element as one of the receiver’s `accessibilityChildren` and also automatically sets the receiver as the specified element’s accessibilityParent. This behavior is useful when you create hierarchies of accessibility elements.

The `accessibilityFrameInParentSpace` property allows the accessibility element to specify its frame relative to its accessibility parent, so that the` accessibilityFrame` property value (given in screen coordinates) can be automatically recalculated whenever the element or any of its parents changes location.

The new Accessibility API includes two new convenience methods in `AppKit/NSAccessibility.h` to simplify common accessibility tasks.

The [`NSAccessibilityFrameInView`](https://developer.apple.com/documentation/appkit/1528628-nsaccessibilityframeinview) convenience method converts `frame` from `parentView`'s coordinate space to screen coordinate space. This is useful when you calculate an object's accessibilityFrame.

Likewise, the [`NSAccessibilityPointInView`](https://developer.apple.com/documentation/appkit/1534336-nsaccessibilitypointinview) convenience method converts `point` from `parentView`'s coordinate space to screen coordinate space. This is useful when you calculate an object's `accessibilityActivationPoint`.


## Testing

AccessibilityInspector is a tool that displays all accessibility information for the element currently under the mouse, including the accessibility hierarchy, accessibility attributes, and accessibility actions. It also shows warnings for common accessibility problems such as a missing accessibility label. Accessibility Inspector can be launched from the Xcode > Developer Tools menu.

VoiceOver is the built-in screen reader on macOS. Enable it by choosing System Preferences > Accessibility > VoiceOver > Enable VoiceOver or by pressing Command-F5. For a tutorial on how to use VoiceOver, choose System Preferences > Accessibility > VoiceOver > Open VoiceOver Training.
