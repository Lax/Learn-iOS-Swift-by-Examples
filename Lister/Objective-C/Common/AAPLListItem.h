/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The \c AAPLListItem class represents the text and completion state of a single item in the list.
*/

@import Foundation;

/*!
 * An \c AAPLListItem object is composed of a text property, a completion status, and an underlying
 * opaque identity that distinguishes one \c AAPLListItem object from another. Note that in order to
 * be able to archive and unarchive \c AAPLListItem objects in both the Objective-C and Swift versions
 * of the app, the Swift version of the app ensures that the runtime name of its \c AAPLListItem object
 * is also \c AAPLListItem.
 */
@interface AAPLListItem : NSObject <NSCoding, NSCopying>

/*!
 * Initializes an \c AAPLListItem instance with the designated text and completion state.
 *
 * \param text
 * The intended text content of the list item.
 *
 * \param complete
 * The item's initial completion state.
 */
- (instancetype)initWithText:(NSString *)text complete:(BOOL)complete;

/*!
 * Initializes an \c AAPLListItem instance with the designated text and a default value for \c complete.
 * The default value for \c complete is \c NO.
 *
 * \param text
 * The intended text content of the list item.
 */
- (instancetype)initWithText:(NSString *)text;

/*!
 * The text content for an \c AAPLListItem.
 */
@property (copy) NSString *text;

/*!
 * Whether or not this \c AAPLListItem is complete.
 */
@property (getter=isComplete) BOOL complete;

/*!
 * Resets the underlying identity of the \c AAPLListItem. If a copy of this item is made, and a call
 * to \c -refreshIdentity is made afterward, the items will no longer be equal.
 */
- (void)refreshIdentity;

/*!
 * Determines whether or not a list item is equal to another list item. This is a specialization of \c -isEqual: that is specific for \c AAPLListItem instances.
 *
 * \param listItem
 * Any list item.
 *
 * \returns
 * \c YES if the object is an \c AAPLListItem and it has the same underlying identity as the receiving
 * instance. \c NO otherwise.
 */
- (BOOL)isEqualToListItem:(AAPLListItem *)listItem;

@end
