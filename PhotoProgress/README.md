# PhotoProgress: Using NSProgress

This sample demonstrates how to create and compose NSProgress objects, and show their progress in your app.

The app presents a collection view of photos, which will initially be placeholder images. Tap the "Import" button to import the album of photos, showing progress for each individual import as well as an overall progress. The import operation for each photo is composed of a faked "download" step followed by a filter step. Once the import of a photo finishes, the final image is displayed in the collection view cell.

1) Album: Model object that represents an array of Photos. Loads Photos from the mainBundle's resources.

2) Photo: Model object that represents an image that can be imported. Has a method startImport which creates a PhotoImport.

3) PhotoImport: Single use object that composes the PhotoDownload and PhotoFilter operations. Conforms to NSProgressReporting.

4) PhotoDownload: Single use object that fakes a download of a fileURL. Conforms to NSProgressReporting.

5) PhotoFilter: Has a single class method, filteredImage, which synchronously runs a filter using CoreImage on a UIImage. Supports implicit progress reporting.

6) PhotosViewController: Our root view controller. Observes the overall progress using key-value observing and updates a UIProgressView. Handles interactions with the tool bar buttons.

7) PhotosCollectionViewController: Our UICollectionViewController. Has an Album which it uses in the data source methods.

8) PhotoCollectionViewCell: A UICollectionViewCell subclass that shows an individual Photo as well as progress for the import of that photo. Uses KVO to observe the progress of the import, as well as the image for the photo.

## Requirements

### Build

Xcode 7.0, iOS 9.0 SDK

### Runtime

iOS 9.0

Copyright (C) 2015 Apple Inc. All rights reserved.
