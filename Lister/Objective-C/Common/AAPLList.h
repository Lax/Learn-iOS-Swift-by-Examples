/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLList class manages a list of items and the color of the list.
*/

@import Foundation;

@class AAPLListItem;

/*!
 * The possible colors a list can have.
 */
typedef NS_ENUM(NSInteger, AAPLListColor) {
    AAPLListColorGray = 0,
    AAPLListColorBlue,
    AAPLListColorGreen,
    AAPLListColorYellow,
    AAPLListColorOrange,
    AAPLListColorRed
};

/*!
 * Returns the name of \c listColor in a human readable form. As an example, \c AAPLNameFromListColor(AAPLListColorRed)
 * returns the string \c @"Red".
 *
 * \param listColor
 * The list color to determine the name of.
 *
 * \returns
 * The human readable representation of the color as a string.
 */
NSString *AAPLNameFromListColor(AAPLListColor listColor);

/*!
 * The \c AAPLList class manages the color of a list and each \c AAPLListItem, including the order of
 * the list. Incomplete items are located at the start of the items array, followed by complete list
 * items. There are many convenience methods on the \c AAPLList class to query whether an item can be
 * moved or inserted at a certain index, to perform those move and insert operations, to toggle an
 * item between a complete and incomplete state, and to fetch list items by index. Note that in order
 * to be able to archive and unarchive \c AAPLList objects in both the Objective-C and Swift versions
 * of the app, the Swift version of the app ensures that the runtime name of its \c List object is
 * also \c AAPLList.
 */
@interface AAPLList : NSObject <NSCoding, NSCopying>

/*!
 * Initializes an \c AAPLList instance with the designated color and items.
 *
 * \param color
 * The intended color of the list.
 *
 * \param items
 * The items that represent the underlying list. The \c AAPLList class copies the items in
 * initialization.
 */
- (instancetype)initWithColor:(AAPLListColor)color items:(NSArray *)items;

/*!
 *  The list's color. This property is stored when it is archived and read when it is unarchived.
 */
@property AAPLListColor color;

/*!
 * \returns
 * A copy of the list items. The underlying items are stored when the list is archived and read when
 * they are unarchived.
 */
@property (copy) NSArray *items;

/*!
 * Determines whether or not a list is equal to another list. This is a specialization of \c -isEqual:
 * that is specific for instances of \c AAPLList.
 *
 * \param
 * list Any list.
 *
 * \returns
 * \c YES if the list has the same color and items as the receiving instance. \c NO otherwise.
 */
- (BOOL)isEqualToList:(AAPLList *)list;

@end
