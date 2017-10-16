/*
Copyright (C) 2017 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

Abstract:
The app's view controller which presents viewable content.
*/


import UIKit

class DataViewController: UIViewController {


    @IBOutlet weak var scrollView: TiledPDFScrollView!

    var pdf: CGPDFDocument!

    var page: CGPDFPage!

    var pageNumber: Int = 0
    
    var myScale: CGFloat = 0



    override func viewDidLoad()
    {
        super.viewDidLoad()

        // Do any additional setup after loading the view, typically from a nib.
        page = pdf.page(at: pageNumber)
        scrollView.setPDFPage(page)

        // Disable zooming if our pages are currently shown in landscape, for new views
        scrollView.isUserInteractionEnabled = UIApplication.shared.statusBarOrientation.isPortrait
    }



    override func viewDidLayoutSubviews()
    {
        restoreScale()
    }



    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        super.viewWillTransition(to: size, with: coordinator)

        coordinator.animate(alongsideTransition: nil, completion: { context in

            // Disable zooming if our pages are currently shown in landscape after orientation changes
            self.scrollView.isUserInteractionEnabled = UIApplication.shared.statusBarOrientation.isPortrait
        })
    }



    func restoreScale()
    {
        // Called on orientation change.
        // We need to zoom out and basically reset the scrollview to look right in two-page spline view.
        let pageRect = page.getBoxRect(CGPDFBox.mediaBox)
        let yScale = view.frame.size.height / pageRect.size.height
        let xScale = view.frame.size.width / pageRect.size.width
        myScale = min(xScale, yScale)
        scrollView.bounds = view.bounds
        scrollView.zoomScale = 1.0
        scrollView.PDFScale = myScale
        scrollView.tiledPDFView.bounds = view.bounds
        scrollView.tiledPDFView.myScale = myScale
        scrollView.tiledPDFView.layer.setNeedsDisplay()
    }


}

