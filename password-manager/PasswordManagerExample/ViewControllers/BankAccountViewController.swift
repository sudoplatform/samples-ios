//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

@MainActor
class BankAccountViewController: UITableViewController {

    // Input for the vault the item belongs to
    var vault: Vault!

    // Bank account to be updated, otherwise a new item will be created upon save.
    var bankAccountInput: VaultBankAccount?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var bankNameField: UITextField!
    @IBOutlet weak var accountNumberField: UITextField!
    @IBOutlet weak var routingNumberField: UITextField!
    @IBOutlet weak var accountTypeField: UITextField!
    @IBOutlet weak var notesField: UITextView!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!

    // Reference to the save button so we can manage its state.
    var saveButton = UIBarButtonItem(title: "Save", style: .done, target: nil, action: nil)

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

    func loadDataFrom(bankAccount: VaultBankAccount?) {
        Task {
            nameField.text = bankAccount?.name
            bankNameField.text =  bankAccount?.bankName
            accountNumberField.text = try? await bankAccount?.accountNumber?.getValue()
            routingNumberField.text = bankAccount?.routingNumber
            notesField.text = try? await bankAccount?.notes?.getValue()
            accountTypeField.text = bankAccount?.accountType
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        if let account = bankAccount {
            createdLabel.text = "Created: \(formatter.string(from: account.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: account.updatedAt))"
        }
    }

    func updateModelWithInputs() -> VaultBankAccount {

        // Get the passed in bank account so it can be updated, or create a new one and update that.
        var bankAccount = self.bankAccountInput ?? VaultBankAccount(name: "", notes: nil, accountType: nil, bankName: nil, branchAddress: nil, branchPhone: nil, ibanNumber: nil, routingNumber: nil, swiftCode: nil, accountNumber: nil, accountPin: nil)

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

        return bankAccount
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: VaultBankAccount) -> Bool {
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
}
