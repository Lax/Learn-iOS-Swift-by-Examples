/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Extends the CustomLayoutAreaView with methods to return position and size measurements
*/

import Cocoa

extension CustomLayoutAreaView {
    
    fileprivate func rectForItemIndex(itemIndex: Int) -> NSRect {
        let layoutItem = layoutItems[itemIndex]
        return layoutItem.bounds
    }
    
    func handleRectForItemIndex(itemIndex: Int, position: HandlePosition) -> NSRect {
        let itemRect = rectForItemIndex(itemIndex: itemIndex)
        var handleRect = NSRect.zero
        let size = LayoutInfo.LayoutItemHandleSize
        let halfSize = size / 2.0
        
        switch position {
        case .north:
            handleRect = NSRect(x: itemRect.midX, y: itemRect.maxY, width: size, height: size)
        case .northEast:
            handleRect = NSRect(x: itemRect.maxX, y: itemRect.maxY, width: size, height: size)
        case .east:
            handleRect = NSRect(x: itemRect.maxX, y: itemRect.midY, width: size, height: size)
        case .southEast:
            handleRect = NSRect(x: itemRect.maxX, y: itemRect.minY, width: size, height: size)
        case .south:
            handleRect = NSRect(x: itemRect.midX, y: itemRect.minY, width: size, height: size)
        case .southWest:
            handleRect = NSRect(x: itemRect.minX, y: itemRect.minY, width: size, height: size)
        case .west:
            handleRect = NSRect(x: itemRect.minX, y: itemRect.midY, width: size, height: size)
        case .northWest:
            handleRect = NSRect(x: itemRect.minX, y: itemRect.maxY, width: size, height: size)
        default: break
        }
        handleRect.origin.x -= halfSize
        handleRect.origin.y -= halfSize
        return handleRect
    }
    
    func rectForLayoutItem(rect: NSRect, handle: HandlePosition, deltaX: CGFloat, deltaY: CGFloat) -> NSRect {
        var originX = rect.origin.x
        var originY = rect.origin.y
        var width = rect.size.width
        var height = rect.size.height
        
        let eastDeltaX = max(min(deltaX, bounds.size.width - width - originX), -(width - LayoutInfo.LayoutItemMinSize))
        let westDeltaX = max(min(deltaX, width - LayoutInfo.LayoutItemMinSize), -originX)
        let northDeltaY = max(min(deltaY, bounds.size.height - height - originY), -(height - LayoutInfo.LayoutItemMinSize))
        let southDeltaY = max(min(deltaY, height - LayoutInfo.LayoutItemMinSize), -originY)
        
        switch handle {
        case .north:
            height += northDeltaY
        case .northEast:
            width += eastDeltaX
            height += northDeltaY
        case .east:
            width += eastDeltaX
        case .southEast:
            originY += southDeltaY
            width += eastDeltaX
            height -= southDeltaY
        case .south:
            originY += southDeltaY
            height -= southDeltaY
        case .southWest:
            originX += westDeltaX
            originY += southDeltaY
            width -= westDeltaX
            height -= southDeltaY
        case .west:
            originX += westDeltaX
            width -= westDeltaX
        case .northWest:
            originX += westDeltaX
            width -= westDeltaX
            height += northDeltaY
        case .unknown:
            originX += max(min(deltaX, bounds.size.width - width - originX), -originX)
            originY += max(min(deltaY, bounds.size.height - height - originY), -originY)
        }
        
        return NSRect(x: originX, y: originY, width: width, height: height)
    }
    
}
