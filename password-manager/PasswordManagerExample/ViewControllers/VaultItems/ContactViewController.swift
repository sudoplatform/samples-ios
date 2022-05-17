//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class ContactViewController: UITableViewController {

    // Input for the vault the item belongs to
    var vault: Vault!

    // Contact to be updated, otherwise a new item will be created upon save.
    var contactInput: Contact?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var genderField: UITextField!
    @IBOutlet weak var addressField: UITextField!
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var phoneField: UITextField!
    @IBOutlet weak var websiteField: UITextField!
    @IBOutlet weak var companyField: UITextField!
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
        nameField.placeholder = "Enter the name of the contact"
        genderField.placeholder = "Enter the gender of the contact"
        addressField.placeholder = "Enter the address of the contact"
        emailField.placeholder = "Enter the email of the contact"
        phoneField.placeholder = "Enter the phone number of the contact"
        websiteField.placeholder = "Enter the website of the contact"
        companyField.placeholder = "Enter the company of the contact"
        notesField.text = "" // no placeholder on textview, clear whatever is there.
        createdLabel.text = ""
        updatedLabel.text = ""
        favoriteButton.setTitle("", for: .normal)

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let contact = contactInput {
            self.title = "Edit Contact"
            self.loadDataFrom(contact: contact)
        }
        else {
            self.title = "Create Contact"
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

    func loadDataFrom(contact: Contact?) {
        Task {
            nameField.text = contact?.name
            genderField.text = contact?.gender
            addressField.text = contact?.address
            emailField.text = contact?.email
            phoneField.text = contact?.phone
            websiteField.text = contact?.website
            companyField.text = contact?.company
            notesField.text = try? await contact?.notes?.getValue()

            if let favorite = contact?.favorite {
                isFavorite = favorite
            }

            favoriteButtonImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            favoriteButton.setImage(favoriteButtonImage, for: .normal)

            if let hexColor = contact?.hexColor {
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
        if let contact = contact {
            createdLabel.text = "Created: \(formatter.string(from: contact.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: contact.updatedAt))"
        }
    }

    func updateModelWithInputs() -> Contact {

        // Get the passed in contact so it can be updated, or create a new one and update that.
        var contact = self.contactInput ?? Contact(name: "",
                                                   hexColor: nil,
                                                   favorite: false,
                                                   notes: nil,
                                                   address: nil,
                                                   company: nil,
                                                   dateOfBirth: nil,
                                                   email: nil,
                                                   firstName: nil,
                                                   gender: nil,
                                                   lastName: nil,
                                                   otherPhone: nil,
                                                   phone: nil,
                                                   state: nil,
                                                   website: nil)

        if let name = nameField.text {
            contact.name = name
        }
        if let gender = genderField.text {
            contact.gender = gender
        }
        if let address = addressField.text {
            contact.address = address
        }
        if let email = emailField.text {
            contact.email = email
        }
        if let phone = phoneField.text {
            contact.phone = phone
        }
        if let website = websiteField.text {
            contact.website = website
        }
        if let company = companyField.text {
            contact.company = company
        }
        if let notes = notesField.text {
            contact.notes = VaultItemValue(value: notes)
        }
        contact.favorite = isFavorite
        contact.hexColor = hexColor

        return contact
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: Contact) -> Bool {
        return model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @objc func save() {
        let item = self.updateModelWithInputs()

        guard isModelValidForSave(model: item) else {
            self.presentErrorAlert(message: "Name is required")
            return
        }

        self.presentActivityAlert(message: "Saving Contact")

        /// The add/update functions take different parameters to their closures.
        if self.contactInput == nil {
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
