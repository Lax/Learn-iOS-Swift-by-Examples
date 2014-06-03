/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                ListInfo is an abstraction to contain information about list documents such as their color.
            
*/

import UIKit
import ListerKit

// A ListInfoProvider needs to provide a URL for the ListInfo object to query.
@class_protocol protocol ListInfoProvider {
    var URL: NSURL { get }
}

// Make NSURL a ListInfoProvider, since it's by default an NSURL.
extension NSURL: ListInfoProvider {
    var URL: NSURL {
        return self
    }
}

// Make NSMetadataItem a ListInfoProvider and return its value for the NSMetadataItemURLKey attribute.
extension NSMetadataItem: ListInfoProvider {
    var URL: NSURL {
        return valueForAttribute(NSMetadataItemURLKey) as NSURL
    }
}

class ListInfo: Equatable {
    // MARK: Properties

    let provider: ListInfoProvider
    
    var color: List.Color?
    var name: String?
    
    var isLoaded: Bool {
        return color && name
    }
    
    var URL: NSURL {
        return provider.URL
    }
    
    // MARK: Initializers

    init(provider: ListInfoProvider) {
        self.provider = provider
    }

    // MARK: Methods

    func fetchInfoWithCompletionHandler(completionHandler: () -> Void) {
        if isLoaded {
            completionHandler()
            return
        }
        
        let document = ListDocument(fileURL: URL)
        document.openWithCompletionHandler { success in
            if success {
                self.color = document.list.color
                self.name = document.localizedName
                
                completionHandler()
                
                document.closeWithCompletionHandler(nil)
            }
            else {
                fatalError("Your attempt to open the document failed.")
            }
        }
    }
    
    func createAndSaveWithCompletionHandler(completionHandler: Bool -> Void) {
        let list = List()
        
        list.color = color ? color! : .Gray
        
        let document = ListDocument(fileURL: URL)
        document.list = list
        
        document.saveToURL(URL, forSaveOperation: .ForCreating, completionHandler: completionHandler)
    }
}

// Equality operator to compare two ListInfo objects.
func ==(lhs: ListInfo, rhs: ListInfo) -> Bool {
    return lhs.URL == rhs.URL
}
