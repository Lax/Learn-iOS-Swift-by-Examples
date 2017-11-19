/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Node object representing each item in our custom outline view.
*/

import Foundation

class OutlineViewNode: NSObject, NSCopying {
    
    var name = ""
    var children = [OutlineViewNode]()
    var depth = 0
	var expanded = false
    
    override var description: String {
        let descriptionFormatter = NSLocalizedString("OutlineNodeDescriptionFormatter", comment:"")
        return String(format: descriptionFormatter, super.description, depth, name)
    }
    
    class func node(name: String) -> OutlineViewNode {
        return OutlineViewNode.node(name: name, depth: 0)
    }
    
    class func node(name: String, depth: Int) -> OutlineViewNode {
        let node = OutlineViewNode()
        node.name = name
        node.expanded = false
        node.depth = depth
        return node
    }
    
    func addChildNode(name: String) -> OutlineViewNode {
        let child = OutlineViewNode.node(name: name, depth: depth + 1)
        children.append(child)
        return child
    }
    
    fileprivate func hash() -> Int {
        return name.hash ^ depth
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if object is OutlineViewNode {
            guard let checkObject = object as? OutlineViewNode else { return false }
            return depth == checkObject.depth && name == checkObject.name
        }
        
        return super.isEqual(to: object)
    }
    
    // MARK: - NSCopying
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = OutlineViewNode.node(name: name, depth: depth)
        copy.children = children
        return copy
    }
}
