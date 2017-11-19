/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Object to describe an accessibility example.
*/

import Foundation

class Example: NSObject {
    var name = ""
    var desc = ""
    var viewControllerIdentifier = ""
    
    init(name: String, description: String, viewControllerIdentifier: String) {
        self.name = name
        self.desc = description
        self.viewControllerIdentifier = viewControllerIdentifier
        super.init()
    }
    
}
