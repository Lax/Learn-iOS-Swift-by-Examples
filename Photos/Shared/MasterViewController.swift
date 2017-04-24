/*
	Copyright (C) 2017 Apple Inc. All Rights Reserved.
	See LICENSE.txt for this sample’s licensing information
	
	Abstract:
	Manages the top-level table view, a list of photo collections.
 */


import UIKit
import Photos

class MasterViewController: UITableViewController {

    // MARK: Types for managing sections, cell and segue identifiers
    enum Section: Int {
        case allPhotos = 0
        case smartAlbums
        case userCollections

        static let count = 3
    }

    enum CellIdentifier: String {
        case allPhotos, collection
    }

    enum SegueIdentifier: String {
        case showAllPhotos
        case showCollection
    }

    // MARK: Properties
    var allPhotos: PHFetchResult<PHAsset>!
    var smartAlbums: PHFetchResult<PHAssetCollection>!
    var userCollections: PHFetchResult<PHCollection>!
    let sectionLocalizedTitles = ["", NSLocalizedString("Smart Albums", comment: ""), NSLocalizedString("Albums", comment: "")]

    // MARK: UIViewController / Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.addAlbum))
        self.navigationItem.rightBarButtonItem = addButton


        // Create a PHFetchResult object for each section in the table view.
        let allPhotosOptions = PHFetchOptions()
        allPhotosOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: true)]
        allPhotos = PHAsset.fetchAssets(with: allPhotosOptions)
        smartAlbums = PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .albumRegular, options: nil)
        userCollections = PHCollectionList.fetchTopLevelUserCollections(with: nil)

        PHPhotoLibrary.shared().register(self)

    }

    deinit {
        PHPhotoLibrary.shared().unregisterChangeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        self.clearsSelectionOnViewWillAppear = self.splitViewController!.isCollapsed
        super.viewWillAppear(animated)
    }

    func addAlbum(_ sender: AnyObject) {

        let alertController = UIAlertController(title: NSLocalizedString("New Album", comment: ""), message: nil, preferredStyle: .alert)
        alertController.addTextField { textField in
            textField.placeholder = NSLocalizedString("Album Name", comment: "")
        }

        alertController.addAction(UIAlertAction(title: NSLocalizedString("Create", comment: ""), style: .default) { action in
            let textField = alertController.textFields!.first!
            if let title = textField.text, !title.isEmpty {
                // Create a new album with the title entered.
                PHPhotoLibrary.shared().performChanges({
                    PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: title)
                }, completionHandler: { success, error in
                    if !success { print("error creating album: \(error)") }
                })
            }
        })
        self.present(alertController, animated: true, completion: nil)
    }


    // MARK: Segues

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

        guard let destination = (segue.destination as? UINavigationController)?.topViewController as? AssetGridViewController
            else { fatalError("unexpected view controller for segue") }
        let cell = sender as! UITableViewCell

        destination.title = cell.textLabel?.text

        switch SegueIdentifier(rawValue: segue.identifier!)! {
            case .showAllPhotos:
                destination.fetchResult = allPhotos
            case .showCollection:

                // get the asset collection for the selected row
                let indexPath = tableView.indexPath(for: cell)!
                let collection: PHCollection
                switch Section(rawValue: indexPath.section)! {
                    case .smartAlbums:
                        collection = smartAlbums.object(at: indexPath.row)
                    case .userCollections:
                        collection = userCollections.object(at: indexPath.row)
                    default: return // not reached; all photos section already handled by other segue
                }

                // configure the view controller with the asset collection
                guard let assetCollection = collection as? PHAssetCollection
                    else { fatalError("expected asset collection") }
                destination.fetchResult = PHAsset.fetchAssets(in: assetCollection, options: nil)
                destination.assetCollection = assetCollection
        }
    }

    // MARK: Table View

    override func numberOfSections(in tableView: UITableView) -> Int {
        return Section.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch Section(rawValue: section)! {
            case .allPhotos: return 1
            case .smartAlbums: return smartAlbums.count
            case .userCollections: return userCollections.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch Section(rawValue: indexPath.section)! {
            case .allPhotos:
                let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.allPhotos.rawValue, for: indexPath)
                cell.textLabel!.text = NSLocalizedString("All Photos", comment: "")
                return cell

            case .smartAlbums:
                let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.collection.rawValue, for: indexPath)
                let collection = smartAlbums.object(at: indexPath.row)
                cell.textLabel!.text = collection.localizedTitle
                return cell

            case .userCollections:
                let cell = tableView.dequeueReusableCell(withIdentifier: CellIdentifier.collection.rawValue, for: indexPath)
                let collection = userCollections.object(at: indexPath.row)
                cell.textLabel!.text = collection.localizedTitle
                return cell
        }
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionLocalizedTitles[section]
    }

}

// MARK: PHPhotoLibraryChangeObserver
extension MasterViewController: PHPhotoLibraryChangeObserver {

    func photoLibraryDidChange(_ changeInstance: PHChange) {
        // Change notifications may be made on a background queue. Re-dispatch to the
        // main queue before acting on the change as we'll be updating the UI.
        DispatchQueue.main.sync {
            // Check each of the three top-level fetches for changes.

            if let changeDetails = changeInstance.changeDetails(for: allPhotos) {
                // Update the cached fetch result. 
                allPhotos = changeDetails.fetchResultAfterChanges 
                // (The table row for this one doesn't need updating, it always says "All Photos".)
            }

            // Update the cached fetch results, and reload the table sections to match.
            if let changeDetails = changeInstance.changeDetails(for: smartAlbums) {
                smartAlbums = changeDetails.fetchResultAfterChanges
                tableView.reloadSections(IndexSet(integer: Section.smartAlbums.rawValue), with: .automatic)
            }
            if let changeDetails = changeInstance.changeDetails(for: userCollections) {
                userCollections = changeDetails.fetchResultAfterChanges
                tableView.reloadSections(IndexSet(integer: Section.userCollections.rawValue), with: .automatic)
            }

        }
    }
}

