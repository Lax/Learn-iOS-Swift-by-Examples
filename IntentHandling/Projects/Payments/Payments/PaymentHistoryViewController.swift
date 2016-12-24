/*
    Copyright (C) 2016 Apple Inc. All Rights Reserved.
    See LICENSE.txt for this sample’s licensing information
    
    Abstract:
    A view controller that lists recent payments made with our app.
*/

import UIKit
import PaymentsFramework

class PaymentHistoryViewController: UITableViewController {
    
    private let paymentProvider = PaymentProvider()
    
    private var payments = [Payment]() {
        didSet {
            // If a new array of `Payment`s has been set, reload the table view.
            guard oldValue != payments && isViewLoaded else { return }
            tableView.reloadData()
        }
    }
    
    /// Used to format payment amounts in table view cells.
    private var amountFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
    
    /// Used to format payment dates in table view cells.
    private var dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter
    }()
    
    // MARK: UIViewController
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        payments = paymentProvider.loadPaymentHistory().reversed()
    }
    
    // MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return payments.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: PaymentTableViewCell.reuseIdentifier, for: indexPath) as? PaymentTableViewCell else { fatalError("Unable to dequeue a PaymentTableViewCell") }
        let payment = payments[indexPath.row]
        
        // Configure the cell with the payment details.
        cell.contactLabel.text = payment.contact.formattedName
        
        if let date = payment.date {
            cell.dateLabel.text = dateFormatter.string(from: date)
        }
        else {
            cell.dateLabel.text = "-"
        }
        
        amountFormatter.currencyCode = payment.currencyCode
        cell.amountLabel.text = amountFormatter.string(from: payment.amount)
        
        return cell
    }
}



/// Used by `PaymentHistoryViewController` to show details of a `Payment`.
class PaymentTableViewCell: UITableViewCell {
    
    static let reuseIdentifier = "PaymentTableViewCell"
    
    @IBOutlet weak var contactLabel: UILabel!
    
    @IBOutlet weak var dateLabel: UILabel!
    
    @IBOutlet weak var amountLabel: UILabel!
    
}
