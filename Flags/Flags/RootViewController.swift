/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The `RootViewController` manages an embedded `UIPageViewController` to display a randomized list of flags provided by a `RootViewControllerDataSource`.
*/

import UIKit

class RootViewController: UIViewController, UIPageViewControllerDelegate {
    // MARK: Properties

    private var pageViewController: UIPageViewController?

    private var currentIndex = 0
    
    private lazy var dataSource: RootViewControllerDataSource = {
        let controller = RootViewControllerDataSource(storyboard: self.storyboard!)
        return controller
    }()
    
    // MARK: UIViewController

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pageViewController = childViewControllers[0] as? UIPageViewController
        guard let pageViewController = pageViewController else { return }
        guard let startingViewController = dataSource.viewController(at: 0) else { return }
        
        let viewControllers = [startingViewController]
        pageViewController.setViewControllers(viewControllers, direction: .forward, animated: false, completion: nil)
        
        pageViewController.dataSource = dataSource
        pageViewController.didMove(toParentViewController: self)
    }
    
    // MARK: Interface Builder actions
    
    @IBAction func forwardButtonPressed(_ sender: UIButton) {
        currentIndex += 1
        currentIndex = currentIndex % dataSource.numberOfFlags
        
        let viewController = dataSource.viewController(at: currentIndex)!
        pageViewController?.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
    }
    
    @IBAction func backButtonPressed(_ sender: UIButton) {
        currentIndex -= 1
        if currentIndex < 0 {
            currentIndex = dataSource.numberOfFlags - 1
        }
        
        let viewController = dataSource.viewController(at: currentIndex)!
        pageViewController?.setViewControllers([viewController], direction: .reverse, animated: true, completion: nil)
    }
}
