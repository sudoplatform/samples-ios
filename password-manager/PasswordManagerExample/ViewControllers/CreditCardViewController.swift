//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class CreditCardViewController: UITableViewController {

    @IBOutlet weak var itemTitle: UITextField!
    @IBOutlet weak var cardholderName: UITextField!
    @IBOutlet weak var number: UITextField!
    @IBOutlet weak var expiration: UITextField!
    @IBOutlet weak var securityCode: UITextField!
    @IBOutlet weak var cardType: UITextField!
    @IBOutlet weak var notes: UITextView!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!


    // Input for the vault the item belongs to
    var vault: Vault!

    // Input card data, used for editing.  Otherwise a new card will be created.
    var creditCardInput: VaultCreditCard?

    // Reference to the save button so we can manage its state.

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set placeholder text
        itemTitle.placeholder = "Enter a name for the credit card"
        cardholderName.placeholder = "Card Holder"
        number.placeholder = "4444 4444 4444 4444 4448"
        expiration.placeholder = "MM/YY"
        securityCode.placeholder = "Secret Code"
        cardType.placeholder = "VISA, Mastercard, etc."
        notes.text = ""
        createdLabel.text = ""
        updatedLabel.text = ""

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let card = self.creditCardInput {
            self.title = "Edit Credit Card"
            self.loadDataFrom(card: card)
        }
        else {
            self.title = "Create Credit Card"
        }

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(self.cancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.save))

        self.tableView.tableFooterView = UIView()
    }

    // Date formatter for use with expiry.
    lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/yy"
        return f
    }()

    /// Loads data from the model into the textfields, making any conversions needed. Best effort
    func loadDataFrom(card: VaultCreditCard) {
        itemTitle.text = card.name
        cardholderName.text = card.cardName

        if let cardNumber = try? card.cardNumber?.getValue() {
            number.text = cardNumber
        }

        if let expiration = card.cardExpiration {
            self.expiration.text = self.dateFormatter.string(from: expiration)
        }

        if let securityCode = try? card.cardSecurityCode?.getValue() {
            self.securityCode.text = securityCode
        }
        cardType.text = card.cardType
        notes.text = (try? card.notes?.getValue()) ?? ""

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        createdLabel.text = "Created: \(formatter.string(from: card.createdAt))"
        updatedLabel.text = "Updated: \(formatter.string(from: card.updatedAt))"
    }

    /// Writes the data from the text fields to the model.  Best effort.
    func updateModelWithInputs() -> VaultCreditCard {

        let card = self.creditCardInput ?? VaultCreditCard(name: "", notes: nil, cardType: nil, cardName: nil, cardExpiration: nil, cardNumber: nil, cardSecurityCode: nil)

        if let text = itemTitle.text {
            card.name = text
        }

        if let text = cardholderName.text {
            card.cardName = text
        }

        if let text = number.text {
            card.cardNumber = VaultItemValue(value: text)
        }

        if let text = expiration.text {
            card.cardExpiration = self.dateFormatter.date(from: text)
        }

        if let text = securityCode.text {
            card.cardSecurityCode = VaultItemValue(value: text)
        }

        if let text = cardType.text {
            card.cardType = text
        }

        if let notes = notes.text {
            card.notes = VaultItemNote(value: notes)
        }

        return card
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: VaultCreditCard) -> Bool {
        return model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @objc func save() {
        let dataToSave = self.updateModelWithInputs()

        guard isModelValidForSave(model: dataToSave) else {
            self.presentErrorAlert(message: "Name is required.")
            return
        }

        self.presentActivityAlert(message: "Saving")

        /// The add/update functions take different parameters to their closures.
        if self.creditCardInput == nil {
            Clients.passwordManagerClient.add(item: dataToSave, toVault: self.vault, completion: {  [weak self] (result) in
                runOnMain {
                    switch result {
                    case .success(_):
                        (self?.presentingViewController ?? self)?.dismiss(animated: true, completion: nil)
                    case .failure(let error):
                        self?.dismiss(animated: false, completion: {
                            self?.presentErrorAlert(message: "Failed to add vault item", error: error)
                        })
                    }
                }
            })
        }
        else {
            Clients.passwordManagerClient.update(item: dataToSave, in: self.vault, completion: {  [weak self] (result) in
                runOnMain {
                    switch result {
                    case .success(_):
                        (self?.presentingViewController ?? self)?.dismiss(animated: true, completion: nil)
                    case .failure(let error):
                        self?.dismiss(animated: false, completion: {
                            self?.presentErrorAlert(message: "Failed to update vault item", error: error)
                        })
                    }
                }
            })
        }
    }
}
