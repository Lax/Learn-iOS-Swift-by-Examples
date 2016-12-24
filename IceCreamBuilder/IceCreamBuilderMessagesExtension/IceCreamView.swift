/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `UIStackView` containing the parts of a given `IceCream`.
*/

import UIKit

class IceCreamView: UIStackView {
    
    var iceCream: IceCream? {
        didSet {
            // Remove any existing arranged subviews.
            for view in arrangedSubviews {
                removeArrangedSubview(view)
            }
            
            // Do nothing more if the `iceCream` property is nil.
            guard let unwrappedIceCream = iceCream else { return }
            
            // Add a `UIImageView` for each of the ice cream's valid parts.
            let iceCreamParts: [IceCreamPart?] = [unwrappedIceCream.topping, unwrappedIceCream.scoops, unwrappedIceCream.base]
            for iceCreamPart in iceCreamParts {
                guard let iceCreamPart = iceCreamPart else { continue }
                
                let imageView = UIImageView(image: iceCreamPart.image)
                imageView.contentMode = .scaleAspectFit
                addArrangedSubview(imageView)
            }
        }
    }
}
