//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import UIKit
import SudoPasswordManager

class LoginViewController: UITableViewController {

    // Input for the vault the item belongs to
    var vault: Vault!

    // Login to be updated, otherwise a new item will be created upon save.
    var loginInput: Login?

    @IBOutlet weak var nameField: UITextField!
    @IBOutlet weak var urlField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var notesField: UITextView!
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var generatePasswordButton: UIButton!
    @IBOutlet weak var favoriteButton: UIButton!

    @IBOutlet var colorButtons: [UIButton]!

    lazy var generatePasswordViewController = GeneratePasswordViewController()

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
        nameField.placeholder = "Enter name or title of the website."
        urlField.placeholder =  "Enter the URL of the website login"
        usernameField.placeholder = "Enter the username you use to sign in"
        passwordField.placeholder = "Enter or create a password"
        notesField.text = "" // no placeholder on textview, clear whatever is there.
        createdLabel.text = ""
        updatedLabel.text = ""
        favoriteButton.setTitle("", for: .normal)

        tableView.separatorStyle = .none

        // Setup navigation bar, nav buttons, and initial data to display
        if let login = loginInput {
            self.title = "Edit Login"
            self.loadDataFrom(login: login)
        }
        else {
            self.title = "Create Login"
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

    // MARK: - Generate Password functions
    @IBAction func generatePasswordButtonTapped(_ sender: Any) {
        generatePasswordViewController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "GeneratePasswordViewController")
        generatePasswordViewController.outputHandler = didGeneratePassword(password:)

        let nav = UINavigationController(rootViewController: generatePasswordViewController)

        self.present(nav, animated: true, completion: nil)
    }

    func didGeneratePassword(password: String) {
        self.passwordField.text = password
    }

    // MARK: - Save/Load functions
    func loadDataFrom(login: Login?) {
        Task {
            nameField.text = login?.name
            urlField.text = login?.url
            usernameField.text = login?.user
            passwordField.text = try? await login?.password?.getValue()
            notesField.text = try? await login?.notes?.getValue()

            if let favorite = login?.favorite {
                isFavorite = favorite
            }

            favoriteButtonImage = isFavorite ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            favoriteButton.setImage(favoriteButtonImage, for: .normal)
        }

        if let hexColor = login?.hexColor {
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
        if let login = login {
            createdLabel.text = "Created: \(formatter.string(from: login.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: login.updatedAt))"
        }
    }

    func updateModelWithInputs() -> Login {

        // Get the passed in login so it can be updated, or create a new one and update that.
        var login = self.loginInput ?? Login(user: nil,
                                             url: nil,
                                             name: "",
                                             notes: nil,
                                             password: nil,
                                             hexColor: nil,
                                             favorite: false)

        if let name = nameField.text {
            login.name = name
        }
        if let url = urlField.text {
            login.url = url
        }
        if let username = usernameField.text {
            login.user = username
        }
        if let password = passwordField.text {
            login.password = VaultItemPassword(stringLiteral: password)
        }
        if let notes = notesField.text {
            login.notes = VaultItemValue(value: notes)
        }
        login.favorite = isFavorite
        login.hexColor = hexColor

        return login
    }

    @objc func cancel() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func isModelValidForSave(model: Login) -> Bool {
        return model.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    @objc func save() {
        let item = self.updateModelWithInputs()

        guard isModelValidForSave(model: item) else {
            self.presentErrorAlert(message: "Name is required")
            return
        }

        self.presentActivityAlert(message: "Saving Login")

        /// The add/update functions take different parameters to their closures.
        if self.loginInput == nil {
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
