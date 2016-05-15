/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    This file contains the list of error codes that ShapeEdit can throw.
*/

/// These represent the possible errors thrown in our project.
enum ShapeEditError: ErrorType {
    case ThumbnailLoadFailed
    case BookmarkResolveFailed
    case NoShape
    case PlistReadFailed
    case SignedOutOfiCloud
}