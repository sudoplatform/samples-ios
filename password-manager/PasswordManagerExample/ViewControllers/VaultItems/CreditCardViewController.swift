//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

@MainActor
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
    @IBOutlet weak var favoriteButton: UIButton!

    @IBOutlet var colorButtons: [UIButton]!

    // Input for the vault the item belongs to
    var vault: Vault!

    // Input card data, used for editing.  Otherwise a new card will be created.
    var creditCardInput: CreditCard?

    var isFavorite: Bool = false
    var favoriteButtonImage: UIImage?

    // If nil, all buttons should be deselected and background should be set to system white.
    var hexColor: String?
    // Arbitrarily chosen colors values. Actual colors come from themes?
    var hexColors = ["EBC7CA", "EBE9C7", "BBEBBC", "A0EBE6", "DEBAEB"]

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
        favoriteButton.setTitle("", for: .normal)

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let card = self.creditCardInput {
            self.title = "Edit Credit Card"
            Task {
                await self.loadDataFrom(card: card)
            }
        }
        else {
            self.title = "Create Credit Card"
        }

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .done, target: self, action: #selector(self.cancel))
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.save))

        self.tableView.tableFooterView = UIView()
    }

    override func viewDidLayoutSubviews() {
        colorButtons.forEach { button in
            let buttonHexString = hexColors[button.tag]
            button.backgroundColor = UIColor(hexString: buttonHexString)
            button.setTitle("", for: .normal)
            button.layer.cornerRadius = button.frame.height/2
            button.layer.borderColor = UIColor.black.cgColor
        }
    }

    // Date formatter for use with expiry.
    lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MM/yy"
        return f
    }()

    /// Loads data from the model into the textfields, making any conversions needed. Best effort
    func loadDataFrom(card: CreditCard) async {
        itemTitle.text = card.name
        cardholderName.text = card.cardName

        if let cardNumber = try? await card.cardNumber?.getValue() {
            number.text = cardNumber
        }

        if let expiration = card.cardExpiration {
            self.expiration.text = self.dateFormatter.string(from: expiration)
        }

        if let securityCode = try? await card.cardSecurityCode?.getValue() {
            self.securityCode.text = securityCode
        }
        cardType.text = card.cardType
        notes.text = (try? await card.notes?.getValue()) ?? ""

        isFavorite = card.favorite

        favoriteButtonImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favoriteButton.setImage(favoriteButtonImage, for: .normal)

        if let hexColor = card.hexColor {
            self.hexColor = hexColor

            // Find the button associated with the hex color and update it's border.
            colorButtons.forEach { button in
                if self.hexColor == hexColors[button.tag] {
                    button.layer.borderWidth = 2
                }
            }

            navigationController?.navigationBar.backgroundColor = UIColor(hexString: hexColor)
        } else {
            navigationController?.navigationBar.backgroundColor = .systemBackground
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        createdLabel.text = "Created: \(formatter.string(from: card.createdAt))"
        updatedLabel.text = "Updated: \(formatter.string(from: card.updatedAt))"
    }

    /// Writes the data from the text fields to the model.  Best effort.
    func updateModelWithInputs() -> CreditCard {

        var card = self.creditCardInput ?? CreditCard(name: "",
                                                      notes: nil,
                                                      cardType: nil,
                                                      cardName: nil,
                                                      cardExpiration: nil,
                                                      cardNumber: nil,
                                                      cardSecurityCode: nil,
                                                      hexColor: nil,
                                                      favorite: false)

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
        card.favorite = isFavorite
        card.hexColor = hexColor

        return card
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: CreditCard) -> Bool {
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

            Task {
                do {
                    _ = try await Clients.passwordManagerClient.add(item: dataToSave, toVault: self.vault)
                    (self.presentingViewController ?? self)?.dismiss(animated: true, completion: nil)
                }
                catch {
                    self.dismiss(animated: false, completion: {
                        self.presentErrorAlert(message: "Failed to add vault item", error: error)
                    })
                }
            }
        }
        else {
            Task {
                do {
                    try await Clients.passwordManagerClient.update(item: dataToSave, in: self.vault)
                    (self.presentingViewController ?? self)?.dismiss(animated: true, completion: nil)
                }
                catch {
                    self.dismiss(animated: false, completion: {
                        self.presentErrorAlert(message: "Failed to update vault item", error: error)
                    })
                }
            }
        }
    }

    // MARK: - Favorite and HexColor
    @IBAction func favoriteButtonTapped(_ sender: Any) {
        isFavorite = !isFavorite
        let image = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        favoriteButton.setImage( image, for: .normal)
    }

    @IBAction func colorButtonTapped(_ sender: UIButton) {
        // Clear all the buttons' borders
        colorButtons.forEach { button in
            button.layer.borderWidth = 0
        }

        // Set the class hexColor and update the border and navBar color as needed.
        let index = sender.tag
        if self.hexColor == hexColors[index] {
            self.hexColor = nil
            navigationController?.navigationBar.backgroundColor = .systemBackground
        } else {
            // Otherwise, set the class property and outline the button
            sender.layer.borderWidth = 2
            self.hexColor = hexColors[index]
            guard let colorString = self.hexColor else {return}
            navigationController?.navigationBar.backgroundColor = UIColor(hexString: colorString)
        }
    }
}
