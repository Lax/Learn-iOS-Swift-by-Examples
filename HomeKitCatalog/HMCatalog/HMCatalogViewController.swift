/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    The `HMCatalogViewController` is a super class which mainly provides easy-access methods for shared HomeKit objects.
*/

import UIKit
import HomeKit

/**
    The super class for most table view controllers in this app. It manages home
    delegate registration and facilitates 'popping back' when it's discovered that
    a home has been deleted.
*/
class HMCatalogViewController: UITableViewController, HMHomeDelegate {
    // MARK: Properties
    
    var homeStore: HomeStore {
        return HomeStore.sharedStore
    }
    
    var home: HMHome! {
        return homeStore.home
    }
    
    // MARK: View Methods
    
    /**
        Evaluates whether or not the view controller should pop to
        the list of homes.
        
        - returns:  `true` if this instance is not the root view controller
                    and the `home` is nil; `false` otherwise.
    */
    private func shouldPopViewController() -> Bool {
        if let rootViewController = navigationController?.viewControllers.first
            where rootViewController == self {
                return false
        }

        return home == nil
    }

    /// Pops the view controller, if required. Invokes the delegate registration method.
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if shouldPopViewController() {
            // Pop to root view controller if our home was destroyed while we were away.
            navigationController?.popToRootViewControllerAnimated(true)
            return
        }

        registerAsDelegate()
    }
    
    // MARK: Delegate Registration
    
    /**
        A hierarchical method, to be overriden by superclasses.
        The base implementation registers as the delegate for the `HomeStore`'s home.
        Thus, any subclasses may override this, register as the delegate for any 
        objects they please, and then call `super.registerAsDelegate()` to register 
        as the home delegate as well.
        
        This method will be called when the view appears.
    */
    func registerAsDelegate() {
        homeStore.home?.delegate = self
    }
}
