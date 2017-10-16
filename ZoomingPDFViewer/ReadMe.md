# ZoomingPDFViewer

Multi-paged PDF viewing with UIPageViewController demonstrates two-page spline viewing in landscape orientation, which looks like a book within iBooks. The sample also uses UIScrollView and CATiledLayer to support zooming within a single-page view used in portrait orientations. This app is universal and only supports the two-page spline view in landscape orientation on iPad.

## FAQ

* Why does this sample swap out the scrollview's embedded CATiledLayer-backed subview on every didEndZoom event?

Swapping out the scrollview's tiledlayer-backed subview on every didEndZooming event allows this implementation to support essentially an "infinite" zoom scale. This is great for vector-based PDF's like blue prints or maps. The trade off is that infinite zooming is by default support in both directions, and infinite zooming out is not usually desired.

* How do I clamp zooming in and out to maximum and minimum zoom scales?

To clamp zooming in and out to a defined minimum and maximum scale, remove the code that swaps in and out the tiledlayer-backed subview on the scrollview's didEndZooming event. Doing so will reenable the minimumZoomScale and maximumZoomScale properties of the UIScrollView. The swapping in and out of the scrollview's subview was done purposesfully to bypass minimum and maximum zoom scales as a way to support "infinite" zooming in (which is great for detailed vector based PDFs).

## Requirements

### Build

Xcode 8 or later 

### Runtime

iOS 10 or later



Copyright (C) 2017 Apple Inc. All rights reserved.
