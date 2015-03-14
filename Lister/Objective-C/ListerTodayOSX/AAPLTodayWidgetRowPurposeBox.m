/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLTodayWidgetRowPurpose enumeration and \c AAPLTodayWidgetRowPurposeBox class provide a way to represent the reason why a row is being displayed. The \c AAPLTodayWidgetRowPurposeBox class boxes an \c AAPLTodayWidgetRowPurpose enum to be represented as an object. The \c userInfo property of \c AAPLTodayWidgetRowPurposeBox is meant for binding to different properties (e.g. color) that is defined at initialization of the instance.
*/

#import "AAPLTodayWidgetRowPurposeBox.h"

@implementation AAPLTodayWidgetRowPurposeBox

- (instancetype)initWithPurpose:(AAPLTodayWidgetRowPurpose)purpose userInfo:(id)userInfo {
    self = [super init];
    
    if (self) {
        _purpose = purpose;
        _userInfo = userInfo;
    }
    
    return self;
}

@end
