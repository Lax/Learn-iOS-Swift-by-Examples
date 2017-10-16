//
//  PDFView.h
//  PageBasedPDF
//
//  Created by Bob Thomas on 7/15/13.
//  Copyright (c) 2013 Apple DTS. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PDFView : UIView

@property CGPDFDocumentRef pdf;
@property CGPDFPageRef page;
@property int pageNumber;
@property CGFloat myScale;

@end
