//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class DriversLicenseViewController: UITableViewController {

    // Input for the vault the item belongs to
    var vault: Vault!

    // Driver license to be updated, otherwise a new item will be created upon save.
    var driversLicenseInput: DriversLicense?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var countryField: UITextField!
    @IBOutlet weak var genderField: UITextField!
    @IBOutlet weak var numberField: UITextField!
    @IBOutlet weak var stateField: UITextField!
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
        nameField.placeholder = "Enter the name of the license holder"
        countryField.placeholder =  "Enter the issuing country of this license"
        genderField.placeholder = "Enter the gender of the license holder"
        numberField.placeholder = "Enter the license number associated with this license"
        stateField.placeholder = "Enter the issuing state of this license"
        notesField.text = "" // no placeholder on textview, clear whatever is there.
        createdLabel.text = ""
        updatedLabel.text = ""
        favoriteButton.setTitle("", for: .normal)

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let license = driversLicenseInput {
            self.title = "Edit Driver License"
            self.loadDataFrom(license: license)
        }
        else {
            self.title = "Create Driver License"
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

    func loadDataFrom(license: DriversLicense?) {
        Task {
            nameField.text = license?.name
            countryField.text =  license?.country
            genderField.text = license?.gender
            numberField.text = try? await license?.number?.getValue()
            notesField.text = try? await license?.notes?.getValue()
            stateField.text = license?.state

            if let favorite = license?.favorite {
                isFavorite = favorite
            }

            favoriteButtonImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            favoriteButton.setImage(favoriteButtonImage, for: .normal)

            if let hexColor = license?.hexColor {
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
        if let license = license {
            createdLabel.text = "Created: \(formatter.string(from: license.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: license.updatedAt))"
        }
    }

    func updateModelWithInputs() -> DriversLicense {

        // Get the passed in driver license so it can be updated, or create a new one and update that.
        var license = self.driversLicenseInput ?? DriversLicense(name: "",
                                                                 hexColor: nil,
                                                                 favorite: false,
                                                                 notes: nil,
                                                                 country: nil,
                                                                 dateOfBirth: nil,
                                                                 dateOfIssue: nil,
                                                                 expires: nil,
                                                                 firstName: nil,
                                                                 gender: nil,
                                                                 lastName: nil,
                                                                 number: nil,
                                                                 state: nil)

        if let name = nameField.text {
            license.name = name
        }
        if let country = countryField.text {
            license.country = country
        }
        if let gender = genderField.text {
            license.gender = gender
        }
        if let number = numberField.text {
            license.number = VaultItemValue(value: number)
        }
        if let state = stateField.text {
            license.state = state
        }
        if let notes = notesField.text {
            license.notes = VaultItemValue(value: notes)
        }
        license.favorite = isFavorite
        license.hexColor = hexColor

        return license
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: DriversLicense) -> Bool {
        return model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @objc func save() {
        let item = self.updateModelWithInputs()

        guard isModelValidForSave(model: item) else {
            self.presentErrorAlert(message: "Name is required")
            return
        }

        self.presentActivityAlert(message: "Saving Driver License")

        /// The add/update functions take different parameters to their closures.
        if self.driversLicenseInput == nil {
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
