/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controller shown when a completed ice cream is selected in a conversation.
*/

import UIKit
import Messages

class CompletedIceCreamViewController: UIViewController {
    // MARK: Properties

    static let storyboardIdentifier = "CompletedIceCreamViewController"
    
    var iceCream: IceCream?

    @IBOutlet weak var stickerView: MSStickerView!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        guard let iceCream = iceCream else { fatalError("No ice cream has been set") }
        super.viewDidLoad()
        
        // Update the sticker view
        let cache = IceCreamStickerCache.cache
        
        stickerView.sticker = cache.placeholderSticker
        cache.sticker(for: iceCream) { sticker in
            OperationQueue.main.addOperation {
                guard self.isViewLoaded else { return }
                
                self.stickerView.sticker = sticker
            }
        }
    }
}
