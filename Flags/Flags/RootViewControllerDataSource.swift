/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The RootViewControllerDataSource manages a list of country codes and their flags and provides instances of `DataViewController` to the `RootViewController`'s `UIPageViewController`.
*/

import UIKit
import GameKit

class RootViewControllerDataSource: NSObject, UIPageViewControllerDataSource {
    // MARK: Properties
	
	private let regionCodes: [String]
    
    private let cachedDataViewControllers = NSCache<NSString, DataViewController>()
    
    private let storyboard: UIStoryboard
    
    var numberOfFlags: Int {
        return regionCodes.count
    }
	
    // MARK: Initialization
    
    init(storyboard: UIStoryboard) {
        self.storyboard = storyboard
        
        // Create a random array of region codes.
        regionCodes = GKRandomSource.sharedRandom().arrayByShufflingObjects(in: Locale.isoRegionCodes) as! [String]
        
		super.init()
	}
	
	// MARK: UIPageViewControllerDataSource
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let dataViewController = viewController as? DataViewController else { return nil }
        guard var index = indexOfViewController(dataViewController), index > 0 else { return nil }
        
		index -= 1
        return self.viewController(at: index)
	}
	
	func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let dataViewController = viewController as? DataViewController else { return nil }
        guard var index = indexOfViewController(dataViewController), index < regionCodes.count - 1 else { return nil }
		
		index += 1
        return self.viewController(at: index)
	}
    
    // MARK: Convenience
    
    func viewController(at index: Int) -> DataViewController? {
        guard regionCodes.count > 0 && index < regionCodes.count else { return nil }
        let regionCode = regionCodes[index]
        
        // Return the data view controller for the given index.
        if let dataViewController = cachedDataViewControllers.object(forKey: regionCode as NSString) {
            return dataViewController
        }
        
        // Create a new view controller and pass suitable data.
        let dataViewController = storyboard.instantiateViewController(withIdentifier: "DataViewController") as! DataViewController
        dataViewController.regionCode = regionCodes[index]
        
        // Cache the view controller before returning it.
        cachedDataViewControllers.setObject(dataViewController, forKey: regionCode as NSString)

        return dataViewController
    }

    func indexOfViewController(_ viewController: DataViewController) -> Int? {
        guard let regionCode = viewController.regionCode else { return nil }
        return regionCodes.index(of: regionCode)
    }
}
