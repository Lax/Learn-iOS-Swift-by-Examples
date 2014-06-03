/*
   <codex />
*/

import UIKit

class ListFileRepresentation: Equatable {
   
   var URL: NSURL! {
      if let item = self.item {
         return item.valueForAttribute(NSMetadataItemURLKey) as NSURL
      }
      else {
         return _URL
      }
   }
   var _URL: NSURL!
   var item: NSMetadataItem?
   var color: List.Color = .Gray
   
   init(URL: NSURL) {
      _URL = URL
   }
   
   init(metadataItem item: NSMetadataItem) {
      self.item = item
      _URL = item.valueForAttribute(NSMetadataItemURLKey) as NSURL
   }
   
   func prepare(completionHandler: () -> Void) {
      let document = ListDocument(fileURL: URL)
      document.openWithCompletionHandler() { _ in
         self.color = document.list.color
         
         document.closeWithCompletionHandler(nil)

         completionHandler()
      }
   }
}

func ==(lhs: ListFileRepresentation, rhs: ListFileRepresentation) -> Bool {
   // the metadata item does not impact equality for our purposes
   return lhs.URL == rhs.URL
}
