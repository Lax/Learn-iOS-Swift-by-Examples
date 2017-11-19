/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Helpful extension to Character.
*/

import Cocoa

extension Character {
    init?(_ ascii: Int) {
        guard let scalar = UnicodeScalar(ascii) else {
            return nil
        }
        self = Character(scalar)
    }
}
