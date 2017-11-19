/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The main table view controller for the app, which displays a list of received chats from other users.
 */

import UIKit

class ChatTableViewController: UITableViewController {
    private let chatItemManager = ChatItemManager.sharedInstance
    private var newChatDelegate: NewChatDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.rightBarButtonItem?.isEnabled = NewChatDelegate.isCameraAvailable()
        
        registerForPreviewing(with: self, sourceView: tableView)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if let selectedIndexPaths = tableView.indexPathsForSelectedRows {
            for selectedIndexPath in selectedIndexPaths {
                tableView.deselectRow(at: selectedIndexPath, animated: true)
            }
        }
    }
    
    func chatItem(at indexPath: IndexPath) -> ChatItem {
        return chatItemManager.receivedChatItems[indexPath.row]
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return chatItemManager.receivedChatItems.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ChatTableViewCell.identifier, for: indexPath)
        if let chatTableCell = cell as? ChatTableViewCell {
            let chatItem = self.chatItem(at: indexPath)
            chatTableCell.configure(with: chatItem)
        }
        return cell
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let chatDetailViewController = segue.destination as? ChatDetailViewController, let selectedIndexPath = tableView.indexPathForSelectedRow {
            chatDetailViewController.chatItem = chatItem(at: selectedIndexPath)
        }
    }
    
    @IBAction func createNewChat(_ sender: AnyObject?) {
        presentNewChatController()
    }
    
    func presentNewChatController(for friend: Friend? = nil, animated: Bool = true, completion: (() -> Void)? = nil) {
        assert(NewChatDelegate.isCameraAvailable(), "The device must have a camera to create a new chat.")
        guard newChatDelegate == nil else {
            completion?()
            return
        }
        newChatDelegate = NewChatDelegate(presentingViewController: self, recipient: friend) {[unowned self] (chatImage: UIImage?) in
            self.newChatDelegate = nil
        }
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = newChatDelegate
        imagePickerController.sourceType = .camera
        present(imagePickerController, animated: animated, completion: completion)
    }
}

extension ChatTableViewController: UIViewControllerPreviewingDelegate {
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        guard let indexPath = tableView.indexPathForRow(at: location) else { return nil }
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: ChatDetailViewController.identifier)
        guard let chatDetailViewController = viewController as? ChatDetailViewController else { return nil }
        
        chatDetailViewController.chatItem = chatItem(at: indexPath)
        let cellRect = tableView.rectForRow(at: indexPath)
        previewingContext.sourceRect = previewingContext.sourceView.convert(cellRect, from: tableView)
        chatDetailViewController.isReplyButtonHidden = true
        
        return chatDetailViewController
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        if let chatDetailViewController = viewControllerToCommit as? ChatDetailViewController {
            chatDetailViewController.isReplyButtonHidden = false
        }
        show(viewControllerToCommit, sender: self)
    }
}
