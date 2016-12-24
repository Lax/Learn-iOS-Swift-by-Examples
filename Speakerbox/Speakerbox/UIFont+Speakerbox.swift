/*
	Copyright (C) 2016 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Extension of UIFont for creating monospaced font attributes suitable for displaying increasing call durations
*/

import UIKit
import CoreText

extension UIFont {

    var addingMonospacedNumberAttributes: UIFont {
        let attributes = [
            UIFontDescriptorFeatureSettingsAttribute: [[
                UIFontFeatureTypeIdentifierKey: kNumberSpacingType,
                UIFontFeatureSelectorIdentifierKey: kMonospacedNumbersSelector
            ]]
        ]
        let fontDescriptorWithAttributes = fontDescriptor.addingAttributes(attributes)
        return UIFont(descriptor: fontDescriptorWithAttributes, size: pointSize)
    }

}
