/*
        File: CustomSearchBarViewController.swift
    Abstract: 
                A view controller that demonstrates how to customize a UISearchBar.
            
     Version: 1.0
    
    Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
    Inc. ("Apple") in consideration of your agreement to the following
    terms, and your use, installation, modification or redistribution of
    this Apple software constitutes acceptance of these terms.  If you do
    not agree with these terms, please do not use, install, modify or
    redistribute this Apple software.
    
    In consideration of your agreement to abide by the following terms, and
    subject to these terms, Apple grants you a personal, non-exclusive
    license, under Apple's copyrights in this original Apple software (the
    "Apple Software"), to use, reproduce, modify and redistribute the Apple
    Software, with or without modifications, in source and/or binary forms;
    provided that if you redistribute the Apple Software in its entirety and
    without modifications, you must retain this notice and the following
    text and disclaimers in all such redistributions of the Apple Software.
    Neither the name, trademarks, service marks or logos of Apple Inc. may
    be used to endorse or promote products derived from the Apple Software
    without specific prior written permission from Apple.  Except as
    expressly stated in this notice, no other rights or licenses, express or
    implied, are granted by Apple herein, including but not limited to any
    patent rights that may be infringed by your derivative works or by other
    works in which the Apple Software may be incorporated.
    
    The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
    MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
    THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
    FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
    OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
    
    IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
    OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
    SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
    INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
    MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
    AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
    STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
    POSSIBILITY OF SUCH DAMAGE.
    
    Copyright (C) 2014 Apple Inc. All Rights Reserved.

*/

import UIKit

class CustomSearchBarViewController: UIViewController, UISearchBarDelegate {
    // MARK: Properties
    @IBOutlet var searchBar: UISearchBar

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        configureSearchBar()
    }

    // MARK: Configuration
    func configureSearchBar() {
        searchBar.showsCancelButton = true
        searchBar.showsBookmarkButton = true

        searchBar.tintColor = UIColor.applicationPurpleColor()

        searchBar.backgroundImage = UIImage(named: "search_bar_background")

        // Set the bookmark image for both normal and highlighted states.
        let bookmarkImage = UIImage(named: "bookmark_icon")
        searchBar.setImage(bookmarkImage, forSearchBarIcon: .Bookmark, state: .Normal)

        let bookmarkHighlightedImage = UIImage(named: "bookmark_icon_highlighted")
        searchBar.setImage(bookmarkHighlightedImage, forSearchBarIcon: .Bookmark, state: .Highlighted)
    }

    // MARK: UISearchBarDelegate
    func searchBarSearchButtonClicked(searchBar: UISearchBar) {
        NSLog("The custom search bar keyboard search button was tapped: \(searchBar).")
        
        searchBar.resignFirstResponder()
    }

    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        NSLog("The custom search bar cancel button was tapped.")

        searchBar.resignFirstResponder()
    }

    func searchBarBookmarkButtonClicked(searchBar: UISearchBar) {
        NSLog("The custom bookmark button inside the search bar was tapped.")
    }
}
