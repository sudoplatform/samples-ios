//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class BankAccountViewController: UITableViewController {

    // Input for the vault the item belongs to
    var vault: Vault!

    // Bank account to be updated, otherwise a new item will be created upon save.
    var bankAccountInput: BankAccount?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var bankNameField: UITextField!
    @IBOutlet weak var accountNumberField: UITextField!
    @IBOutlet weak var routingNumberField: UITextField!
    @IBOutlet weak var accountTypeField: UITextField!
    @IBOutlet weak var notesField: UITextView!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var favoriteButton: UIButton!

    @IBOutlet var colorButtons: [UIButton]!

    // Reference to the save button so we can manage its state.
    var saveButton = UIBarButtonItem(title: "Save", style: .done, target: nil, action: nil)

    var isFavorite: Bool = false
    var favoriteButtonImage: UIImage?

    // If nil, all buttons should be deselected and background should be set to system white.
    var hexColor: String?
    // Arbitrarily chosen colors values. Actual colors come from themes?
    var hexColors = ["EBC7CA", "EBE9C7", "BBEBBC", "A0EBE6", "DEBAEB"]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Set placeholder text
        nameField.placeholder = "Enter a name for the Bank Account"
        bankNameField.placeholder =  "Name of the bank this account belongs to"
        accountNumberField.placeholder = "Bank account number"
        routingNumberField.placeholder = "Routing number for holding bank"
        accountTypeField.placeholder = "Checking, Savings, etc."
        notesField.text = "" // no placeholder on textview, clear whatever is there.
        createdLabel.text = ""
        updatedLabel.text = ""
        favoriteButton.setTitle("", for: .normal)

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let account = bankAccountInput {
            self.title = "Edit Bank Account"
            self.loadDataFrom(bankAccount: account)
        }
        else {
            self.title = "Create Bank Account"
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

    func loadDataFrom(bankAccount: BankAccount?) {
        Task {
            nameField.text = bankAccount?.name
            bankNameField.text =  bankAccount?.bankName
            accountNumberField.text = try? await bankAccount?.accountNumber?.getValue()
            routingNumberField.text = bankAccount?.routingNumber
            notesField.text = try? await bankAccount?.notes?.getValue()
            accountTypeField.text = bankAccount?.accountType

            if let favorite = bankAccount?.favorite {
                isFavorite = favorite
            }

            favoriteButtonImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            favoriteButton.setImage(favoriteButtonImage, for: .normal)

            if let hexColor = bankAccount?.hexColor {
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
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        if let account = bankAccount {
            createdLabel.text = "Created: \(formatter.string(from: account.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: account.updatedAt))"
        }
    }

    func updateModelWithInputs() -> BankAccount {

        // Get the passed in bank account so it can be updated, or create a new one and update that.
        var bankAccount = self.bankAccountInput ?? BankAccount(name: "",
                                                               notes: nil,
                                                               accountType: nil,
                                                               bankName: nil,
                                                               branchAddress: nil,
                                                               branchPhone: nil,
                                                               ibanNumber: nil,
                                                               routingNumber: nil,
                                                               swiftCode: nil,
                                                               accountNumber: nil,
                                                               accountPin: nil,
                                                               hexColor: nil,
                                                               favorite: false)

        if let name = nameField.text {
            bankAccount.name = name
        }
        if let name = bankNameField.text {
            bankAccount.bankName = name
        }
        if let number = accountNumberField.text {
            bankAccount.accountNumber = VaultItemValue(value: number)
        }
        if let number = routingNumberField.text {
            bankAccount.routingNumber = number
        }
        if let type = accountTypeField.text {
            bankAccount.accountType = type
        }
        if let notes = notesField.text {
            bankAccount.notes = VaultItemValue(value: notes)
        }
        bankAccount.favorite = isFavorite
        bankAccount.hexColor = hexColor

        return bankAccount
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: BankAccount) -> Bool {
        return model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @objc func save() {
        let item = self.updateModelWithInputs()

        guard isModelValidForSave(model: item) else {
            self.presentErrorAlert(message: "Name is required")
            return
        }

        self.presentActivityAlert(message: "Saving Bank Account")

        /// The add/update functions take different parameters to their closures.
        if self.bankAccountInput == nil {
            Task {
                do {
                    _ = try await Clients.passwordManagerClient.add(item: item, toVault: vault)
                    (self.presentingViewController ?? self).dismiss(animated: true, completion: nil)
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
                    try await Clients.passwordManagerClient.update(item: item, in: vault)
                    (self.presentingViewController ?? self).dismiss(animated: true, completion: nil)
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
        // Set the class property, saves when the save button is tapped
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
