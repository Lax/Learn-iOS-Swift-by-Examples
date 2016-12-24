/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 This view controller provides the UI for the photo edting extension in OS X.
 */

import Cocoa
import Photos
import PhotosUI

class PhotoEditingViewController: NSViewController, ContentEditingDelegate {

    @IBOutlet weak var collectionView: NSCollectionView!
    @IBOutlet weak var previewImageView: NSImageView!

    // Shared object to handle editing in both iOS and OS X
    let editController = ContentEditingController()

    // ContentEditingDelegate callbacks to UI
    var preselectedFilterIndex: Int?
    var previewImage: CIImage?

    // Hide stored properties in computed properties to allow use of @available.
    private var livePhoto: AnyObject?
    @available(OSXApplicationExtension 10.12, *)
    var previewLivePhoto: PHLivePhoto? {
        set {
            livePhoto = newValue

            if previewLivePhotoView == nil {
                previewLivePhotoView = PHLivePhotoView(frame: previewImageView.bounds)
                previewLivePhotoView!.topAnchor.constraint(equalTo: previewImageView.topAnchor).isActive = true
                previewLivePhotoView!.bottomAnchor.constraint(equalTo: previewImageView.bottomAnchor).isActive = true
                previewLivePhotoView!.leftAnchor.constraint(equalTo: previewImageView.leftAnchor).isActive = true
                previewLivePhotoView!.rightAnchor.constraint(equalTo: previewImageView.rightAnchor).isActive = true
                previewImageView.addSubview(previewLivePhotoView!)
            }
            previewLivePhotoView!.livePhoto = previewLivePhoto
        }
        get {
            return livePhoto as! PHLivePhoto?
        }
    }
    private var livePhotoView: NSView?
    @available(OSXApplicationExtension 10.12, *)
    var previewLivePhotoView: PHLivePhotoView? {
        set { livePhotoView = newValue }
        get { return livePhotoView as! PHLivePhotoView? }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        editController.delegate = self
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        if let index = preselectedFilterIndex {
            let indexPath = IndexPath(item: index, section: 0)
            collectionView!.selectItems(at: [indexPath], scrollPosition: .centeredVertically)
            updateSelection(for: collectionView.item(at: indexPath)!)
        }
    }

}

// MARK: PHContentEditingController
extension PhotoEditingViewController: PHContentEditingController {

    // Forward all methods to shared implementation for both platforms.

    func canHandle(_ adjustmentData: PHAdjustmentData) -> Bool {
        return editController.canHandle(adjustmentData)
    }

    func startContentEditing(with contentEditingInput: PHContentEditingInput, placeholderImage: NSImage) {

        previewImageView.image = placeholderImage
        collectionView.reloadData()

        editController.startContentEditing(with: contentEditingInput)
    }

    func finishContentEditing(completionHandler: @escaping ((PHContentEditingOutput?) -> Void)) {
        // Update UI to reflect that editing has finished and output is being rendered.

        editController.finishContentEditing(completionHandler: completionHandler)
    }

    var shouldShowCancelConfirmation: Bool {
        return editController.shouldShowCancelConfirmation
    }

    func cancelContentEditing() {
        editController.cancelContentEditing()
    }

}

extension PhotoEditingViewController: NSCollectionViewDataSource {

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return editController.filterNames.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {

        let item = collectionView.makeItem(withIdentifier: "PhotoFilterItem", for: indexPath)

        let filterName = editController.filterNames[indexPath.item!]
        if filterName == editController.wwdcFilter {
            item.textField!.stringValue = editController.wwdcFilter
        } else {
            // Query Core Image for filter's display name.
            let filter = CIFilter(name: filterName)!
            let filterDisplayName = filter.attributes[kCIAttributeFilterDisplayName]! as! String
            item.textField!.stringValue = filterDisplayName
        }

        // Show the preview image defined by the editing controller.
        if let images = editController.previewImages {
            previewImage = images[indexPath.item]
            item.imageView!.image = NSImage(ciImage: previewImage!)
        }
        return item
    }

}

extension PhotoEditingViewController: NSCollectionViewDelegate {

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        updateSelection(for: collectionView.item(at: indexPath)!)

        let filterName = editController.filterNames[indexPath.item]
        editController.selectedFilterName = filterName

        // Edit controller has already defined preview images for all filters,
        // so just switch the big preview to the right one.
        if let images = editController.previewImages {
            previewImage = images[indexPath.item]
            previewImageView.image = NSImage(ciImage: previewImage!)
        }
        
        if #available(OSXApplicationExtension 10.12, *) {
            editController.updateLivePhotoIfNeeded() // applies filter, sets previewLivePhoto on completion
        }

    }

    func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        updateSelection(for: collectionView.item(at: indexPath)!)
    }

    func updateSelection(for item: NSCollectionViewItem) {

        let selectionColor = NSColor.alternateSelectedControlColor
        item.imageView!.layer!.borderColor = selectionColor.cgColor
        item.imageView!.layer!.borderWidth = item.isSelected ? 2 : 0

        item.textField!.textColor = item.isSelected ? selectionColor : NSColor.alternateSelectedControlTextColor
    }

}

// Convenience extension for creating a CIImageRep-backed NSImage.
private extension NSImage {
    convenience init(ciImage: CIImage) {
        self.init(size: ciImage.extent.size)
        self.addRepresentation(NSCIImageRep(ciImage: ciImage))
    }
}

// IndexPath.init(item:section) and IndexPath.item are missing from OS X in the WWDC seed.
// Use this extension as a temporary workaround.
private extension IndexPath {
    init(item: Int, section: Int) {
        self.init(indexes: [section, item])
    }
    var item: Int! {
        return (self as NSIndexPath).item
    }
}


