//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEntitlements
import SudoUser
import SudoProfiles
import SudoNotification

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

    /// Notification client is used to load current notification configuration after sign in
    var notificationClient: SudoNotificationClient = AppDelegate.dependencies.notificationClient

    // MARK: - Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Sign in automatically if the user is registered.
        Task.detached(priority: .medium) {
            if try await self.userClient.isRegistered() {
                await self.registerButtonTapped()
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

        Task.detached(priority: .medium) {
            do {
                try await self.registerAndSignIn()
                Task { @MainActor in
                    self.activityIndicator.stopAnimating()
                    self.registerButton.isEnabled = true
                    self.navigateToMainMenu()
                }
            } catch {
                Task { @MainActor in
                    self.showSignInFailureAlert(error: error)
                }
            }
        }
    }

    // MARK: - Operations

    /// Perform registration and sign in from the Sudo user client.
    func registerAndSignIn() async throws {

        func redeem() async throws {
            _ = try await self.entitlementsClient.redeemEntitlements()
        }

        func signIn() async throws {
            if !(try await self.userClient.isSignedIn()) {
                _ = try await self.userClient.signInWithKey()
                _ = try await redeem()
            }
        }

        if userClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            guard let viewControllerWindow = self.view.window else {
                return
            }

            _ = try await userClient.presentFederatedSignInUI(presentationAnchor: viewControllerWindow)
            _ = try await redeem()
        } else {
            if try await userClient.isRegistered() {
                _ = try await signIn()
            } else {
                try await authenticator.register()
                _ = try await signIn()
            }
        }
    }

    // MARK: - Helpers

    /// Presents a `UIAlertController` containing the registration `error`.
    ///
    /// - Parameters:
    ///     - error: Contains the given `Error`.
    private func showRegistrationFailureAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: "Failed to register:\n\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    /// Presents a `UIAlertController` containing the sign in `error`.
    ///
    /// - Parameters:
    ///     - error: Contains the given `Error`.
    private func showSignInFailureAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: "Failed to sign in:\n\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    /// Navigates to the `MainMenuViewController` via a segue.
    private func navigateToMainMenu() {
        performSegue(withIdentifier: Segue.navigateToMainMenu.rawValue, sender: self)
    }
}
