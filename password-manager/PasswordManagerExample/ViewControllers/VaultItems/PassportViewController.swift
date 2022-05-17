//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class PassportViewController: UITableViewController {

    // Input for the vault the item belongs to
    var vault: Vault!

    // Passport to be updated, otherwise a new item will be created upon save.
    var passportInput: Passport?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var genderField: UITextField!
    @IBOutlet weak var issuingCountryField: UITextField!
    @IBOutlet weak var placeOfBirthField: UITextField!
    @IBOutlet weak var passportNumberField: UITextField!
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
        nameField.placeholder = "Enter a name for the Passport"
        genderField.placeholder =  "Enter the gender of the passport holder"
        issuingCountryField.placeholder = "Enter the issuing country of the passport"
        placeOfBirthField.placeholder = "Enter the place of birth of the passport holder"
        passportNumberField.placeholder = "Enter the passport number"
        notesField.text = "" // no placeholder on textview, clear whatever is there.
        createdLabel.text = ""
        updatedLabel.text = ""
        favoriteButton.setTitle("", for: .normal)

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let passport = passportInput {
            self.title = "Edit Passport"
            self.loadDataFrom(passport: passport)
        }
        else {
            self.title = "Create Passport"
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

    func loadDataFrom(passport: Passport?) {
        Task {
            nameField.text = passport?.name
            genderField.text =  passport?.gender
            issuingCountryField.text = passport?.issuingCountry
            placeOfBirthField.text = passport?.placeOfBirth
            notesField.text = try? await passport?.notes?.getValue()
            passportNumberField.text = try? await passport?.passportNumber?.getValue()

            if let favorite = passport?.favorite {
                isFavorite = favorite
            }

            favoriteButtonImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            favoriteButton.setImage(favoriteButtonImage, for: .normal)

            if let hexColor = passport?.hexColor {
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
        if let passport = passport {
            createdLabel.text = "Created: \(formatter.string(from: passport.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: passport.updatedAt))"
        }
    }

    func updateModelWithInputs() -> Passport {

        // Get the passed in passport so it can be updated, or create a new one and update that.
        var passport = self.passportInput ?? Passport(hexColor: nil,
                                                      favorite: false,
                                                      name: "",
                                                      notes: nil,
                                                      dateOfBirth: nil,
                                                      dateOfIssue: nil,
                                                      expires: nil,
                                                      firstName: nil,
                                                      gender: nil,
                                                      issuingCountry: nil,
                                                      lastName: nil,
                                                      passportNumber: nil,
                                                      placeOfBirth: nil)

        if let name = nameField.text {
            passport.name = name
        }
        if let gender = genderField.text {
            passport.gender = gender
        }
        if let issuingCountry = issuingCountryField.text {
            passport.issuingCountry = issuingCountry
        }
        if let placeOfBirth = placeOfBirthField.text {
            passport.placeOfBirth = placeOfBirth
        }
        if let number = passportNumberField.text {
            passport.passportNumber = VaultItemValue(value: number)
        }
        if let notes = notesField.text {
            passport.notes = VaultItemValue(value: notes)
        }
        passport.favorite = isFavorite
        passport.hexColor = hexColor

        return passport
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: Passport) -> Bool {
        return model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @objc func save() {
        let item = self.updateModelWithInputs()

        guard isModelValidForSave(model: item) else {
            self.presentErrorAlert(message: "Name is required")
            return
        }

        self.presentActivityAlert(message: "Saving Passport")

        /// The add/update functions take different parameters to their closures.
        if self.passportInput == nil {
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
