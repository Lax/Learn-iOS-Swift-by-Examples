/*
    Copyright (C) 2015 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The definition for the \c AAPLListPresenting type. This protocol defines the contract between list presenters and how their lists are presented / archived.
*/

@import Foundation;
#import "AAPLList.h"

@protocol AAPLListPresenterDelegate;

/*!
    The \c AAPLListPresenting protocol defines the building blocks required for an object to be used as a list
    presenter. List presenters are meant to be used where an \c AAPLList object is displayed; in essence, a list
    presenter "fronts" an \c AAPLList object. With iOS / OS X apps, iOS / OS X widgets, and WatchKit extensions,
    we can classify these interaction models into list presenters. All of the logic can then be abstracted away
    so that the interaction is testable, reusable, and scalable. By defining the core requirements of a list
    presenter through the \c AAPLListPresenting, consumers of \c AAPLListPresenting instances can share a common
    interaction interface to a list.

    Types that conform to \c AAPLListPresenting will have other methods to manipulate a list. For example, a
    presenter can allow for inserting list items into the list, it can allow moving a list item from one index
    to another, etc. All of these updates require that the \c AAPLListPresenting notify its delegate (an
    \c AAPLListPresenterDelegate) of these changes through the common delegate methods. Each of these methods
    should be surrounded by \c -listPresenterWillChangeListLayout: and \c -listPresenterDidChangeListLayout:
    invocations. For more information about the expectations of how an \c AAPLListPresenterDelegate interacts
    with an \c AAPLListPresenting, see the \c AAPLListPresenterDelegate protocol comments.

    The underlying implementation of the \c AAPLListPresenting may use an \c AAPLList object to store certain properties
    as a convenience, but there's no need to do that directly. You query an instance of an \c AAPLListPresenting
    instance for its \c archiveableList representation; that is, a representation of the currently presented list
    that can be archiveable. This may happen, for example, when a document needs to save the currently presented
    list in an archiveable form. Note that list presenters should be used on the main queue only.
 */
@protocol AAPLListPresenting <NSObject>

/*!
    The delegate that will receive callbacks from the \c AAPLListPresenting instance when the presentation
    of the list changes.
 */
@property (nonatomic, weak) id<AAPLListPresenterDelegate> delegate;

/*!
    Resets the presented list to a new list. This can be called, for example, when a new list is unarchived and
    needs to be presented. Calls to this method should wrap the entire sequence of changes in a single
    \c -listPresenterWillChangeListLayout:isInitialLayout: and \c -listPresenterDidChangeListLayout:isInitialLayout:
    invocation. In more complicated implementations of this method, you can find the intersection / difference
    between the new list's presented list items and the old list's presented list items. You can then call into the
    remove / update / move delegate methods to inform the delegate of the re-organization. Delegates should
    receive updates if the text of a \c AAPLListItem instance has changed. Delegates should also receive a
    callback if the new color is different from the old list's color.

    \param list
    The new list that the \c AAPLListPresenting instance should present.
 */
- (void)setList:(AAPLList *)list;

/*!
    The color of the presented list. If the new color is different from the old color, the delegate should be
    notified through the \c -listPresenter:didUpdateListColorWithColor: method.
 */
@property AAPLListColor color;

/*!
    An archiveable presentation of the list that that presenter is presenting. This commonly returns the underlying
    list being manipulated. However, this can be computed based on the current state of the presenter (color, list
    items, etc.). If a presenter has changes that are not yet applied to the list, the list returned here should
    have those changes applied.
 */
@property (readonly, copy) AAPLList *archiveableList;

/*!
    The presented list items that should be displayed in order. Adopters of the \c AAPLListPresenting protocol can
    decide not to show all of the list items within a list.
 */
@property (readonly, copy) NSArray *presentedListItems;

/*!
    A convenience property that should return the equivalent of \c self.presentedListItems.count.
 */
@property (readonly) NSInteger count;

/*!
    A convenience property that should return whether or not there are any presented list items.
 */
@property (readonly, getter=isEmpty) BOOL empty;

@end