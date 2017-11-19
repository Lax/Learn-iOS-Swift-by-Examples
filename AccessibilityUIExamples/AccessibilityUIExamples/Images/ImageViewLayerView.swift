/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating adding accessibility to an NSView subclass that draws itself using two separate CALayers.
*/

import Cocoa

class ImageViewLayerView: NSView {

    // MARK: - Internals
    
    fileprivate struct LayoutInfo {
        static let ImageWidth = CGFloat(75.0)
        static let ImageHeight = ImageWidth
        static let FontSize = CGFloat(18.0)
        static let TextFrameHeight = CGFloat(25.0)
    }
    
    var imageLayer: CustomImageLayer!
    var textLayer: CustomTextLayer!
    
    // MARK: - View Lifecycle
    
    required override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    func commonInit() {
        // Root layer will have a green background color.
        let rootLayer = CALayer()
        let colorSpace = CGColorSpace(name: CGColorSpace.sRGB)
        rootLayer.backgroundColor = CGColor(colorSpace: colorSpace!, components: [0.9, 1.0, 0.60, 1.0])
        layer = rootLayer
        
        // Sub image layer will have the RedDot image as it's content.
        let imageLayer = CustomImageLayer()
        let imageName = "RedDot"
        imageLayer.contents = NSImage(named: NSImage.Name(rawValue: imageName))
        imageLayer.parent = self
        let imageFrame = NSRect(x: (frame.size.width / 2) - LayoutInfo.ImageWidth,
                                y: (frame.size.height / 2) - LayoutInfo.ImageHeight + 8,
                                width: LayoutInfo.ImageWidth,
                                height: LayoutInfo.ImageHeight)
        imageLayer.frame = imageFrame
        imageLayer.anchorPoint = CGPoint()
        rootLayer.addSublayer(imageLayer)
        
        // Sub text layer will have a black label.
        let textLayer = CustomTextLayer()
        textLayer.string = NSLocalizedString("Red Dot", comment: "displayed text for the RedDot image")
        textLayer.parent = self
        textLayer.frame = CGRect(x: imageFrame.origin.x,
                                 y: imageFrame.origin.y,
                                 width: LayoutInfo.ImageWidth,
                                 height: LayoutInfo.TextFrameHeight)
        textLayer.anchorPoint = CGPoint()
        textLayer.fontSize = LayoutInfo.FontSize
        textLayer.alignmentMode = "center"
        textLayer.foregroundColor = NSColor.black.cgColor
        rootLayer.addSublayer(textLayer)
        
        wantsLayer = true
        
        imageLayer.titleElement = textLayer
        
        self.imageLayer = imageLayer
        self.textLayer = textLayer
    }
    
    override var wantsUpdateLayer: Bool {
        return true
    }
    
}

// MARK: -

extension ImageViewLayerView {
    
    // MARK: NSAccessibility
    
    override func accessibilityChildren() -> [Any]? {
        return [imageLayer, textLayer]
    }
    
    override func accessibilityHitTest(_ point: NSPoint) -> Any? {
        // Note: use Xcode's "Accessibility Inspector" to test this.
        let accessibilityContainer = NSAccessibilityUnignoredAncestor(self)
        let imageFrame = NSAccessibilityFrameInView(self, imageLayer.frame)
        let textFrame = NSAccessibilityFrameInView(self, textLayer.frame)
        
        var hitTestElement : Any
        if imageFrame.contains(point) {
            hitTestElement = imageLayer
        } else if textFrame.contains(point) {
            hitTestElement = textLayer
        } else {
            hitTestElement = accessibilityContainer!
        }
        
        return hitTestElement
    }
    
}

