/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A custom `UICollectionViewFlowLayout` that allows the `UICollectionView` in the `BuildIceCreamViewController` to horizontally center selected ice cream parts.
*/

import UIKit

class IceCreamPartCollectionViewLayout: UICollectionViewFlowLayout {
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        guard let collectionView = collectionView else { return proposedContentOffset }
        let halfWidth = collectionView.bounds.width / 2.0
        
        guard let targetIndexPath = indexPathForVisibleItemClosest(to: proposedContentOffset.x + halfWidth) else { return proposedContentOffset }
        guard let itemAttributes = layoutAttributesForItem(at: targetIndexPath) else { return proposedContentOffset }
        
        return CGPoint(x: itemAttributes.center.x - halfWidth, y: proposedContentOffset.y)
    }
    
    func indexPathForVisibleItemClosest(to offset: CGFloat) -> IndexPath? {
        guard let collectionView = collectionView else { return nil }
        guard let layoutAttributes = layoutAttributesForElements(in: collectionView.bounds), !layoutAttributes.isEmpty else { return nil }
        
        let closestAttributes = layoutAttributes.sorted { attributesA, attributesB in
            let distanceA = abs(attributesA.center.x - offset)
            let distanceB = abs(attributesB.center.x - offset)
            
            return distanceA < distanceB
        }.first!
        
        return closestAttributes.indexPath
    }
}
