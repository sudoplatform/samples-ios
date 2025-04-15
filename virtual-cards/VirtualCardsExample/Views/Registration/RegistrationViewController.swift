//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoEntitlements
import SudoProfiles

/// This View Controller presents a screen to allow the user to register or login.
///
/// - Links To:
///     - `MainMenuViewController`: If a user successfully registers or logs in, the `MainMenuViewController` will be presented so that the user can perform
///      "Sudo ID Verfication", "Sudo Creation" or "Funding Source Creation".
class RegistrationViewController: UIViewController {

    // MARK: - Outlets

    /// Button at the bottom of the screen. This is tapped when a user wishes to regiter or login to the app.
    @IBOutlet weak var registerButton: UIButton!

    /// Activity indicator which indicates that the registration process is currently underway.
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    // MARK: - Supplementary

    /// Segues that are performed in `RegistrationViewController`.
    enum Segue: String {
        /// Used to navigate to the `MainMenuViewController`.
        case navigateToMainMenu
    }

    // MARK: - Properties: Computed

    /// Sudo user client used to perform sign in  and registration operations.
    var userClient: SudoUserClient = AppDelegate.dependencies.userClient

    /// Sudo user client used to perform sign in  and registration operations.
    var entitlementsClient: SudoEntitlementsClient = AppDelegate.dependencies.entitlementsClient

    /// Authenticator used to perform authentication during registration.
    var authenticator: Authenticator = AppDelegate.dependencies.authenticator

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Sign in automatically if the user is registered.
        Task { @MainActor in
            if try await userClient.isRegistered() {
                registerButtonTapped()
            }
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    @IBAction func returnToRegistration(segue: UIStoryboardSegue) {}

    /// Action associated with tapping the "Register / Login" button.
    ///
    /// This action will begin in the activity indicator animation and execute the `registerAndSignIn` operation. If registration succeeds, the
    /// `MainMenuViewController` will be presented to the user.
    @IBAction func registerButtonTapped() {
        activityIndicator.startAnimating()
        registerButton.isEnabled = false
        Task { @MainActor in
            do {
                try await registerAndSignIn()
                activityIndicator.stopAnimating()
                registerButton.isEnabled = true
                navigateToMainMenu()
            } catch {
                await showSignInFailureAlert(error: error) { [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.registerButton.isEnabled = true
                }
            }
        }
    }

    // MARK: - Operations

    /// Perform registration and sign in from the Sudo user client.
    func registerAndSignIn(retry: Bool = true) async throws {
        if !(try await userClient.isRegistered()) {
            try await authenticator.register()
        }
        do {
            _ = try await signIn()
        } catch SudoUserClientError.notAuthorized {
            if retry {
                try await userClient.reset()
                try await registerAndSignIn(retry: false)
            } else {
                throw SudoUserClientError.notAuthorized
            }
        }
    }

    func redeem() async throws {
        _ = try await entitlementsClient.redeemEntitlements()
    }

    func signIn() async throws {
        if !(try await userClient.isSignedIn()) {
            try await userClient.signOut()
            _ = try await userClient.signInWithKey()
            _ = try await redeem()
        }
    }

    // MARK: - Helpers

    /// Presents a `UIAlertController` containing the registration `error`.
    ///
    /// - Parameters:
    ///     - error: Contains the given `Error`.
    private func showRegistrationFailureAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: "Failed to register:\n\(error)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    /// Presents a `UIAlertController` containing the sign in `error`.
    ///
    /// - Parameters:
    ///     - error: Contains the given `Error`.
    private func showSignInFailureAlert(error: Error, completion: (() -> Void)? = nil) async {
        let alert = UIAlertController(title: "Error", message: "5)ign in:\n\(error)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: completion)
    }

    /// Navigates to the `MainMenuViewController` via a segue.
    private func navigateToMainMenu() {
        performSegue(withIdentifier: Segue.navigateToMainMenu.rawValue, sender: self)
    }
}
