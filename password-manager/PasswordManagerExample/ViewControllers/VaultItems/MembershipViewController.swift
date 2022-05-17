//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class MembershipViewController: UITableViewController {

    // Input for the vault the item belongs to
    var vault: Vault!

    // Membership to be updated, otherwise a new item will be created upon save.
    var membershipInput: Membership?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var memberIDField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var websiteField: UITextField!
    @IBOutlet weak var emailField: UITextField!
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
        nameField.placeholder = "Enter a name for the membership"
        memberIDField.placeholder =  "Enter the ID for the membership"
        phoneField.placeholder = "Enter the phone number associated with the membership"
        websiteField.placeholder = "Enter the website associated with the membership"
        emailField.placeholder = "Enter the email associated with the membership"
        notesField.text = "" // no placeholder on textview, clear whatever is there.
        createdLabel.text = ""
        updatedLabel.text = ""
        favoriteButton.setTitle("", for: .normal)

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let membership = membershipInput {
            self.title = "Edit Membership"
            self.loadDataFrom(membership: membership)
        }
        else {
            self.title = "Create Membership"
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

    func loadDataFrom(membership: Membership?) {
        Task {
            nameField.text = membership?.name
            memberIDField.text =  membership?.memberID
            phoneField.text = membership?.phone
            websiteField.text = membership?.website
            notesField.text = try? await membership?.notes?.getValue()
            emailField.text = membership?.email

            if let favorite = membership?.favorite {
                isFavorite = favorite
            }

            favoriteButtonImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            favoriteButton.setImage(favoriteButtonImage, for: .normal)

            if let hexColor = membership?.hexColor {
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
        if let membership = membership {
            createdLabel.text = "Created: \(formatter.string(from: membership.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: membership.updatedAt))"
        }
    }

    func updateModelWithInputs() -> Membership {

        // Get the passed in membership so it can be updated, or create a new one and update that.
        var membership = self.membershipInput ?? Membership(name: "",
                                                            hexColor: nil,
                                                            favorite: false,
                                                            notes: nil,
                                                            address: nil,
                                                            email: nil,
                                                            expires: nil,
                                                            firstName: nil,
                                                            lastName: nil,
                                                            memberID: nil,
                                                            memberSince: nil,
                                                            password: nil,
                                                            phone: nil,
                                                            website: nil)

        if let name = nameField.text {
            membership.name = name
        }
        if let memberID = memberIDField.text {
            membership.memberID = memberID
        }
        if let phone = phoneField.text {
            membership.phone = phone
        }
        if let website = websiteField.text {
            membership.website = website
        }
        if let email = emailField.text {
            membership.email = email
        }
        if let notes = notesField.text {
            membership.notes = VaultItemValue(value: notes)
        }
        membership.favorite = isFavorite
        membership.hexColor = hexColor

        return membership
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: Membership) -> Bool {
        return model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @objc func save() {
        let item = self.updateModelWithInputs()

        guard isModelValidForSave(model: item) else {
            self.presentErrorAlert(message: "Name is required")
            return
        }

        self.presentActivityAlert(message: "Saving Membership")

        /// The add/update functions take different parameters to their closures.
        if self.membershipInput == nil {
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
