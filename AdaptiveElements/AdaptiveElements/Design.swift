/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	The ExampleContainerViewController can look and act differently depending on its size.
	 We call each way of acting differently a "design".
	 Design is a struct that encapsulates everything that distinguishes one design from another.
	 Its definition is specific to this particular sample app, but you may want to use the
	 same concept in your own apps.
 */

import UIKit

struct Design {
    // A Design has two properties:

    // 1. Whether to be horizontal or vertical
    let axis: UILayoutConstraintAxis

    // 2. Whether the elements inside are small or large
    enum ElementKind {
        case small
        case large
    }
    let elementKind: ElementKind

    /*
        We also implement a computed read-only property, which returns the identifier
        of the view controller in the storyboard that this design should use.
     */
    var elementIdentifier: String {
        switch elementKind {
        case .small: return "smallElement"
        case .large: return "largeElement"
        }
    }
}

/// Allow Designs to be compared, e.g. `oldDesign == newDesign` or `oldDesign != newDesign`.

extension Design: Equatable { }

func == (left: Design, right: Design) -> Bool {
    return left.axis == right.axis && left.elementKind == right.elementKind
}
