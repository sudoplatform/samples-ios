//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoProfiles

/// This View Controller presents a form so that a user can create a `Sudo`.
///
/// - Links From:
///     - `SudoListViewController`: A user chooses the "Create Sudo" option at the bottom of the table view list.
/// - Links To:
///     - `PostboxViewController`: If a user successfully creates a Sudo, the `PostboxViewController` will be presented so the user can create a postbox].
class CreateSudoViewController: UIViewController {

    // MARK: - Supplementary

    /// Segues that are performed in `SudoListViewController`.
    enum Segue: String {
        /// Navigates to `SudoListViewController` after creating a Sudo.
        case navigateToSudoList
    }

    // MARK: - Properties

    /// The created Sudo
    private var sudo: Sudo?

    // MARK: - Properties: Computed

    /// Sudo profiles client used to perform get and create Sudos.
    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }

    // MARK: - Outlets

    /// Label that provides some instruction for the Sudo label.
    @IBOutlet weak var labelTextField: UITextField!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        createButtonShouldBeEnabled(labelTextField)
        labelTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Actions

    @IBAction func didTapCreateButton(_ sender: Any) {
        Task(priority: .medium) {
            await createSudo()
            performSegue(withIdentifier: Segue.navigateToSudoList.rawValue, sender: sender.self)
        }

    }
    /// Action associated with providing input to the text field.
    ///
    /// This action will enable the "Create" button on the navigation bar.
    @IBAction func textFieldDidChange(_ textField: UITextField) {
        // enable create button when textfield is not empty
        createButtonShouldBeEnabled(textField)
    }

    // MARK: - Operations

    /// Creates a Sudo based on the view's form inputs.
    @MainActor func createSudo() async {
        await presentActivityAlert(message: "Creating sudo")
        do {
            let createdSudo = try await profilesClient.createSudo(input: .init(
                title: nil,
                firstName: nil,
                lastName: nil,
                label: labelTextField.text,
                notes: nil,
                avatar: nil
            ))
            await dismissActivityAlert()
            self.sudo = createdSudo
        } catch {
            await withCheckedContinuation { continuation in
                dismiss(animated: true) {
                    continuation.resume()
                }
            }
            await presentErrorAlert(message: "Failed to create sudo", error: error)
        }
    }

    // MARK: - Helpers

    /// Sets the create button in the navigation bar to enabled/disabled.
    func createButtonShouldBeEnabled(_ textField: UITextField) {
        let trimmedText = textField.text?.trimmingCharacters(in: .whitespacesAndNewlines)
        let isEnabled = trimmedText?.isEmpty == false
        navigationItem.rightBarButtonItem?.isEnabled = isEnabled
    }
}
