/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `CNMutablePostalAddress+Convenience` method creates `CNMutablePostalAddress` from a `CLPlacemark`.
*/

import MapKit
import Contacts

extension CNMutablePostalAddress {
    /// Constructs a `CNMutablePostalAddress` from a `CLPlacemark`
    convenience init(placemark: CLPlacemark) {
        self.init()
        self.street = (placemark.subThoroughfare ?? "") + " " + (placemark.thoroughfare ?? "")
        self.city = placemark.locality ?? ""
        self.state = placemark.administrativeArea ?? ""
        self.postalCode = placemark.postalCode ?? ""
        self.country = placemark.country ?? ""
    }
}
