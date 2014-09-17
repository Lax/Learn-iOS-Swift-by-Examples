/*
    Copyright (C) 2014 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    
                The AAPLTodayWidgetRowPurpose enum and AAPLTodayWidgetRowPurposeBox class provide a way to represent the reason why a row is being displayed. The AAPLTodayWidgetRowPurposeBox class boxes an AAPLTodayWidgetRowPurpose enum to be represented as an object. The userInfo property of AAPLTodayWidgetRowPurposeBox is meant for binding to different properties (e.g. color) that is defined at initialization of the instance.
            
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
