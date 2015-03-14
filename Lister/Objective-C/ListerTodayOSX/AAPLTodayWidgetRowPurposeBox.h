/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLTodayWidgetRowPurpose enumeration and \c AAPLTodayWidgetRowPurposeBox class provide a way to represent the reason why a row is being displayed. The \c AAPLTodayWidgetRowPurposeBox class boxes an \c AAPLTodayWidgetRowPurpose enum to be represented as an object. The \c userInfo property of \c AAPLTodayWidgetRowPurposeBox is meant for binding to different properties (e.g. color) that is defined at initialization of the instance.
*/

@import Foundation;

/// An enumeration of the different kinds of rows that can be displayed in Lister's OS X Today widget.
typedef NS_ENUM(NSInteger, AAPLTodayWidgetRowPurpose) {
    AAPLTodayWidgetRowPurposeOpenLister,
    AAPLTodayWidgetRowPurposeRequiresCloud,
    AAPLTodayWidgetRowPurposeNoItemsInList
};

/*!
 * A wrapper around a \c AAPLTodayWidgetRowPurpose that is used to bind to different objects in the
 * \c AAPLTodayViewController widget list view controller's row row views.
 */
@interface AAPLTodayWidgetRowPurposeBox : NSObject

- (instancetype)initWithPurpose:(AAPLTodayWidgetRowPurpose)purpose userInfo:(id)userInfo;

@property (nonatomic) AAPLTodayWidgetRowPurpose purpose;
@property (nonatomic, strong) id userInfo;

@end
