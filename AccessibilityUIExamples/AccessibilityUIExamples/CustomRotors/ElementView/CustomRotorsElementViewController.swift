/*
See LICENSE folder for this sample’s licensing information.

Abstract:
An example demonstrating setup of an accessibility rotor to search for fruit buttons.
*/

import Cocoa

// Note: To test UIAccessibilityCustomRotor, focus on the CustomRotorsContainerView, and type control+option+u

@available(OSX 10.13, *)
class CustomRotorsElementViewController: NSViewController,
            NSAccessibilityCustomRotorItemSearchDelegate,
            NSAccessibilityElementLoading,
            CustomRotorsElementViewDelegate {
    
    static let SearchableItemsID = "searchable"
    static let CustomRotorFruitButtonsName = "Fruit Buttons"
    static let MaxPageIndex = 2
    
    var displayPageIndex = 0
    
    @IBOutlet var containerView: CustomRotorsContainerView!
    @IBOutlet var pageView1: CustomRotorsPageView!
    @IBOutlet var pageView2: CustomRotorsPageView!
    @IBOutlet var pageView3: CustomRotorsPageView!
    @IBOutlet var contentView1: NSView!
    @IBOutlet var contentView2: NSView!
    @IBOutlet var contentView3: NSView!
    
    // MARK: - View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        displayPageIndex = 0
        containerView.delegate = self
        pageView1.contentView = contentView1
        pageView2.contentView = contentView2
        pageView3.contentView = contentView3
        
        pageView1.addSubview(pageView1.contentView)
        pageView2.addSubview(pageView2.contentView)
        pageView3.addSubview(pageView3.contentView)
        
        pageView2.contentView.isHidden = true
        pageView3.contentView.isHidden = true
        
        pageView1.setAccessibilityLabel(NSLocalizedString("Page 1", comment: ""))
        pageView2.setAccessibilityLabel(NSLocalizedString("Page 2", comment: ""))
        pageView3.setAccessibilityLabel(NSLocalizedString("Page 3", comment: ""))
    }
    
    // Given a fruit name, display the page containing that fruit onscreen and return the button corresponding to that fruit.
    func showFruit(fruit: String) -> NSAccessibilityElementProtocol {
        
        var fruitButtonAccessibilityElement: NSAccessibilityElementProtocol?
        
        for pageView in containerView.subviews {
            if let pageCheck = pageView as? CustomRotorsPageView {
                for subView in pageCheck.contentView.subviews where subView is NSButton {
                    if let button = subView as? NSButton {
                        if button.cell?.title == fruit {
                            fruitButtonAccessibilityElement = NSAccessibilityUnignoredDescendant(button) as? NSAccessibilityElementProtocol
                            displayPageIndex = pageIndexForPageView(pageView: pageCheck)
                            updateViews()
                            break
                        }
                    }
                }
            }
        }
        return fruitButtonAccessibilityElement!
    }
    
    // MARK: Page Management
    
    fileprivate func pageIndexForPageView(pageView: CustomRotorsPageView) -> Int {
        var pageIndex = 0
        if pageView == pageView3 {
            pageIndex = 2
        } else if pageView == pageView2 {
            pageIndex = 1
        }
        return pageIndex
    }
    
    fileprivate func pageViewforPageIndex(pageIndex: Int) -> CustomRotorsPageView {
        var pageView: CustomRotorsPageView?
        switch pageIndex {
        case 0:
            pageView = pageView1
        case 1:
            pageView = pageView2
        case 2:
            pageView = pageView3
        default: break
        }
        return pageView!
    }
    
    fileprivate func updateViews() {
        let currentFocusedViewIndex = displayPageIndex
        for i in 0...CustomRotorsElementViewController.MaxPageIndex {
            let pageView = pageViewforPageIndex(pageIndex: i)
            if i == currentFocusedViewIndex {
                pageView.contentView.isHidden = false
            } else {
                pageView.contentView.isHidden = true
            }
        }
    }
    
    // MARK: - Actions
    
    @IBAction func nextPage(_ sender: Any) {
        if displayPageIndex < CustomRotorsElementViewController.MaxPageIndex {
            displayPageIndex += 1
        }
        updateViews()
    }
    
    @IBAction func previousPage(_ sender: Any) {
        if displayPageIndex > 0 {
            displayPageIndex -= 1
        }
        updateViews()
    }
    
    var fruitElements: [NSButton] {
        var fruitList = [NSButton]()
        for pageView in containerView.subviews {
            if let pageCheck = pageView as? CustomRotorsPageView {
                for subView in pageCheck.contentView.subviews where subView is NSButton {
                    if let button = subView as? NSButton {
                        fruitList.append(button)
                    }
                }
            }
        }
        return fruitList
    }
    
    // MARK: - NSAccessibilityElementLoading Token
    
    func accessibilityElement(withToken token: NSAccessibilityLoadingToken) -> NSAccessibilityElementProtocol? {
        let fruitToken = token as! CustomRotorsElementLoadingToken
        let fruitName = fruitToken.uniqueIdentifier
        return showFruit(fruit: fruitName)
    }
    
    // MARK: - CustomRotorsElementViewDelegate
    
    func createCustomRotors() -> [NSAccessibilityCustomRotor] {
        // Create the fruit rotor.
        let buttonRotor =
            NSAccessibilityCustomRotor(label: CustomRotorsElementViewController.CustomRotorFruitButtonsName,
                                       itemSearchDelegate: self as NSAccessibilityCustomRotorItemSearchDelegate)
        buttonRotor.itemLoadingDelegate = self
        return [buttonRotor]
    }
    
    // MARK: - NSAccessibilityCustomRotorItemSearchDelegate

    public func rotor(_ rotor: NSAccessibilityCustomRotor,
                      resultFor searchParameters: NSAccessibilityCustomRotor.SearchParameters) -> NSAccessibilityCustomRotor.ItemResult? {
        var searchResult: NSAccessibilityCustomRotor.ItemResult?
        
        let currentItemResult = searchParameters.currentItem
        let direction = searchParameters.searchDirection
        let filterText = searchParameters.filterString
        let currentItem = currentItemResult?.targetElement
        
        let children = NSAccessibilityUnignoredChildren(fruitElements)
        _ = children.filter {
            if let obj = $0 as? NSButtonCell {
                return filterText.isEmpty || // Filter based on filter string
                    (obj.accessibilityTitle()?.localizedCaseInsensitiveContains(filterText))!
            } else if let obj = $0 as? NSTextFieldCell {
                return filterText.isEmpty || // Filter based on filter string
                    (obj.accessibilityTitle()?.localizedCaseInsensitiveContains(filterText))!
            } else {
                return false
            }
        }
        
        var currentElementIndex = NSNotFound
        var targetElement : Any?
        let loadingToken = currentItemResult?.itemLoadingToken
        if currentItem == nil && loadingToken != nil {
            // Find out the corresponding hidden button of the current search position, in order to find the next/previous button.
            let elementLoadingToken = loadingToken as? CustomRotorsElementLoadingToken
            if let currentItemIdentifier = elementLoadingToken?.uniqueIdentifier {
                for case let child as NSButtonCell in children where child.title == currentItemIdentifier {
                    currentElementIndex = (children as NSArray).index(of: child)
                }
            }
        } else if currentItem != nil {
            currentElementIndex = (children as NSArray).index(of: currentItem!)
        }
        
        if currentElementIndex == NSNotFound {
            // Fetch the first element.
            if direction == NSAccessibilityCustomRotor.SearchDirection.next {
                targetElement = children.first
            }
                // Fetch the last element.
            else if direction == NSAccessibilityCustomRotor.SearchDirection.previous {
                targetElement = children.last
            }
        } else {
            if direction ==
                NSAccessibilityCustomRotor.SearchDirection.previous && currentElementIndex != 0 {
                targetElement = children[currentElementIndex - 1]
            } else if direction ==
                NSAccessibilityCustomRotor.SearchDirection.next && currentElementIndex < (children.count - 1) {
                targetElement = children[currentElementIndex + 1]
            }
        }
        
        if targetElement != nil {
            if let targetButtonCell = targetElement as? NSCell {
                if let controlView = targetButtonCell.controlView as? NSControl {
                    if controlView.isHiddenOrHasHiddenAncestor {
                        let label = targetButtonCell.title
                        let token = CustomRotorsElementLoadingToken(identifier: label)
                        searchResult =
                            NSAccessibilityCustomRotor.ItemResult(itemLoadingToken: token as NSAccessibilityLoadingToken, customLabel: label)
                    } else {
                        searchResult = NSAccessibilityCustomRotor.ItemResult(targetElement: targetElement as! NSAccessibilityElementProtocol)
                    }
                }
            }
        }
        return searchResult
    }
}
