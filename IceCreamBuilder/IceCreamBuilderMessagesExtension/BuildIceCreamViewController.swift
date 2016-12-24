/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The view controller shown to select an ice-cream part for a partially built ice cream.
*/

import UIKit

class BuildIceCreamViewController: UIViewController {
    // MARK: Properties

    static let storyboardIdentifier = "BuildIceCreamViewController"
    
    weak var delegate: BuildIceCreamViewControllerDelegate?
    
    var iceCream: IceCream? {
        didSet {
            guard let iceCream = iceCream else { return }
            
            // Determine the ice cream parts to show in the collection view.
            if iceCream.base == nil {
                iceCreamParts = Base.all.map { $0 }
                prompt = NSLocalizedString("Select a base", comment: "")
            }
            else if iceCream.scoops == nil {
                iceCreamParts = Scoops.all.map { $0 }
                prompt = NSLocalizedString("Add some scoops", comment: "")
            }
            else if iceCream.topping == nil {
                iceCreamParts = Topping.all.map { $0 }
                prompt = NSLocalizedString("Finish with a topping", comment: "")
            }
        }
    }
    
    /// An array of `IceCreamPart`s to show in the collection view.
    fileprivate var iceCreamParts = [IceCreamPart]() {
        didSet {
            // Update the collection view to show the new ice cream parts.
            guard isViewLoaded else { return }
            collectionView.reloadData()
        }
    }
    
    private var prompt: String?
    
    @IBOutlet weak var promptLabel: UILabel!
    
    @IBOutlet weak var iceCreamView: IceCreamView!
    
    @IBOutlet weak var iceCreamViewHeightConstraint: NSLayoutConstraint!

    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var collectionViewHeightConstraint: NSLayoutConstraint!
    
    // MARK: UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Make sure the prompt and ice cream view are showing the correct information.
        promptLabel.text = prompt
        iceCreamView.iceCream = iceCream
        
        /*
            We want the collection view to decelerate faster than normal so comes
            to rests on a body part more quickly.
        */
        collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // There is nothing to layout of there are no ice cream parts to pick from.
        guard !iceCreamParts.isEmpty else { return }
        guard let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout else { fatalError("Expected the collection view to have a UICollectionViewFlowLayout") }
        
        // The ideal cell width is 1/3 of the width of the collection view.
        layout.itemSize.width = floor(view.bounds.size.width / 3.0)

        // Set the cell height using the aspect ratio of the ice cream part images.
        let iceCreamPartImageSize = iceCreamParts[0].image.size
        guard iceCreamPartImageSize.width > 0 else { return }
        let imageAspectRatio = iceCreamPartImageSize.width / iceCreamPartImageSize.height
        
        layout.itemSize.height = floor(layout.itemSize.width / imageAspectRatio)
        
        // Set the collection view's height constraint to match the cell size.
        collectionViewHeightConstraint.constant = layout.itemSize.height
        
        // Adjust the collection view's `contentInset` so the first item is centered.
        var contentInset = collectionView.contentInset
        contentInset.left = (view.bounds.size.width - layout.itemSize.width) / 2.0
        contentInset.right = contentInset.left
        collectionView.contentInset = contentInset
        
        // Calculate the ideal height of the ice cream view.
        let iceCreamViewContentHeight = iceCreamView.arrangedSubviews.reduce(0.0) { total, arrangedSubview in
            return total + arrangedSubview.intrinsicContentSize.height
        }
        
        let iceCreamPartImageScale = layout.itemSize.height / iceCreamPartImageSize.height
        iceCreamViewHeightConstraint.constant = floor(iceCreamViewContentHeight * iceCreamPartImageScale)
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func didTapSelect(_: AnyObject) {
        // Determine the index path of the centered cell in the collection view.
        guard let layout = collectionView.collectionViewLayout as? IceCreamPartCollectionViewLayout else { fatalError("Expected the collection view to have a IceCreamPartCollectionViewLayout") }
        
        let halfWidth = collectionView.bounds.size.width / 2.0
        guard let indexPath = layout.indexPathForVisibleItemClosest(to: collectionView.contentOffset.x + halfWidth) else { return }
        
        // Call the delegate with the body part for the centered cell.
        delegate?.buildIceCreamViewController(self, didSelect: iceCreamParts[indexPath.row])
    }
}



/**
 A delegate protocol for the `BuildIceCreamViewController` class.
 */
protocol BuildIceCreamViewControllerDelegate: class {
    /// Called when the user taps to select an `IceCreamPart` in the `BuildIceCreamViewController`.
    func buildIceCreamViewController(_ controller: BuildIceCreamViewController, didSelect iceCreamPart: IceCreamPart)
}



/**
 Extends `BuildIceCreamViewController` to conform to the `UICollectionViewDataSource`
 protocol.
 */
extension BuildIceCreamViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return iceCreamParts.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: IceCreamPartCell.reuseIdentifier, for: indexPath as IndexPath) as? IceCreamPartCell else { fatalError("Unable to dequeue a BodyPartCell") }

        let iceCreamPart = iceCreamParts[indexPath.row]
        cell.imageView.image = iceCreamPart.image
        
        return cell
    }
}
