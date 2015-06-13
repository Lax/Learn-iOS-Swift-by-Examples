/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
                PhotosCollectionViewController is a UICollectionViewController subclass that has a reference to the Album.
            
*/

import UIKit

class PhotosCollectionViewController: UICollectionViewController {
    // MARK: Properties

    var album: Album? {
        didSet {
            collectionView?.reloadData()
        }
    }
    
    // MARK: UICollectionViewController
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return album?.photos.count ?? 0
    }

    /**
        The cell that is returned must be retrieved from a call to 
        `dequeueReusableCellWithReuseIdentifier(_:forIndexPath:)`.
    */
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("Photo", forIndexPath: indexPath) as! PhotoCollectionViewCell

        cell.photo = album?.photos[indexPath.row]
        
        return cell
    }
}
