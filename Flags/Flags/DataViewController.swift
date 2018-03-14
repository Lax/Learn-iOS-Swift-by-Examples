/*
 Copyright (C) 2016 Apple Inc. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information
 
 Abstract:
 The Data View Controller displays a flag, and controls the 'Reveal' button for showing the answer.
*/

import UIKit

class DataViewController: UIViewController {
    // MARK: Properties

    @IBOutlet weak var answerLabel: UILabel!
    
	@IBOutlet weak var flagLabel: UILabel!
    
	@IBOutlet weak var revealButton: UIButton!
    
    var regionCode: String? {
        didSet {
            if let regionCode = regionCode {
                // Offset for flags range in Unicode.
                flag = ""
                let base: UInt32 = 127397
                
                for character in regionCode.unicodeScalars {
                    guard let unicodeScalar = UnicodeScalar(base + character.value) else {
                        // `base` + `character.value` is an invalid unicode scalar value.
                        continue
                    }
                    flag?.append(String(unicodeScalar))
                }
            }
            else {
                flag = nil
            }
        }
    }
    
    private var flag: String?
    
    // MARK: UIViewController
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
        guard let regionCode = regionCode else { fatalError("No region code has been set") }
        
		answerLabel.text = Locale.current.localizedString(forRegionCode: regionCode)
		flagLabel.text = flag

        answerLabel.isHidden = true
        revealButton.isHidden = false
	}

	@IBAction func revealAnswer(sender: UIButton) {
		answerLabel.isHidden = false
		revealButton.isHidden = true
	}
}
