/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The table view cell class used to display a received chat.
 */

import UIKit

class ChatTableViewCell: UITableViewCell {
    static let identifier = "ChatTableViewCell"
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let imageView = imageView {
            imageView.contentMode = .scaleAspectFit
            imageView.clipsToBounds = true
            let imageSize = 0.9 * contentView.bounds.height
            var bounds = imageView.bounds
            bounds.size.width = imageSize
            bounds.size.height = imageSize
            imageView.bounds = bounds
            imageView.layer.cornerRadius = imageSize / 2.0
        }
    }
    
    func accessoryType(for chatItem: ChatItem) -> UITableViewCellAccessoryType {
        if chatItem.saved {
            return .checkmark
        }
        else {
            return .none
        }
    }
    
    func configure(with chatItem: ChatItem) {
        imageView?.image = chatItem.sender.profilePhoto
        accessoryType = accessoryType(for: chatItem)
        let format = NSLocalizedString("Chat from %@", comment: "Format string for a chat received from a friend")
        textLabel?.text = String(format: format, chatItem.sender.name)
        detailTextLabel?.text = chatItem.date.timeAgoString()
    }
}
