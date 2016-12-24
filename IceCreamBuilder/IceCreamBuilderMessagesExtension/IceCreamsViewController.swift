/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A `UICollectionViewController` that displays the history of ice creams as well as a cell that can be tapped to start the process of creating a new ice cream.
*/

import UIKit

class IceCreamsViewController: UICollectionViewController {
    // MARK: Types
    
    /// An enumeration that represents an item in the collection view.
    enum CollectionViewItem {
        case iceCream(IceCream)
        case create
    }
    
    // MARK: Properties
    
    static let storyboardIdentifier = "IceCreamsViewController"
    
    weak var delegate: IceCreamsViewControllerDelegate?

    private let items: [CollectionViewItem]
    
    private let stickerCache = IceCreamStickerCache.cache
    
    // MARK: Initialization
    
    required init?(coder aDecoder: NSCoder) {
        // Map the previously completed ice creams to an array of `CollectionViewItem`s.
        let reversedHistory = IceCreamHistory.load().reversed()
        var items: [CollectionViewItem] = reversedHistory.map { .iceCream($0) }
        
        // Add `CollectionViewItem` that the user can tap to start building a new ice cream.
        items.insert(.create, at: 0)
        
        self.items = items
        super.init(coder: aDecoder)
    }

    // MARK: UICollectionViewDataSource
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = items[indexPath.row]
        
        // The item's type determines which type of cell to return.
        switch item {
            case .iceCream(let iceCream):
                return dequeueIceCreamCell(for: iceCream, at: indexPath)
            
            case .create:
                return dequeueIceCreamOutlineCell(at: indexPath)
        }
    }

    // MARK: UICollectionViewDelegate

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        
        switch item {
            case .create:
                delegate?.iceCreamsViewControllerDidSelectAdd(self)
            
            default:
                break
        }
    }
    
    // MARK: Convenience
    
    private func dequeueIceCreamCell(for iceCream: IceCream, at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: IceCreamCell.reuseIdentifier, for: indexPath) as? IceCreamCell else { fatalError("Unable to dequeue am IceCreamCell") }
        
        cell.representedIceCream = iceCream
        
        // Use a placeholder sticker while we fetch the real one from the cache.
        let cache = IceCreamStickerCache.cache
        cell.stickerView.sticker = cache.placeholderSticker
        
        // Fetch the sticker for the ice cream from the cache.
        cache.sticker(for: iceCream) { sticker in
            OperationQueue.main.addOperation {
                // If the cell is still showing the same ice cream, update its sticker view.
                guard cell.representedIceCream == iceCream else { return }
                cell.stickerView.sticker = sticker
            }
        }
        
        return cell
    }
    
    private func dequeueIceCreamOutlineCell(at indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView?.dequeueReusableCell(withReuseIdentifier: IceCreamOutlineCell.reuseIdentifier, for: indexPath) as? IceCreamOutlineCell else { fatalError("Unable to dequeue a IceCreamOutlineCell") }
        
        return cell
    }
}



/**
 A delegate protocol for the `IceCreamsViewController` class.
 */
protocol IceCreamsViewControllerDelegate: class {
    /// Called when a user choses to add a new `IceCream` in the `IceCreamsViewController`.
    func iceCreamsViewControllerDidSelectAdd(_ controller: IceCreamsViewController)
}
