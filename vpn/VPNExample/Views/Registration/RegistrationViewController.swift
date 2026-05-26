//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

@MainActor
class RegistrationViewController: UIViewController {

    // MARK: - Outlets

    /// Button at the bottom of the screen. This is tapped when a user wishes to regiter or login to the app.
    @IBOutlet var registerButton: UIButton!

    /// Activity indicator which indicates that the registration process is currently underway.
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    // MARK: - Supplementary

    /// Segues that are performed in `RegistrationViewController`.
    enum Segue: String, Segueable {
        /// Used to navigate to the `DashboardViewController`.
        case navigateToDashboard
    }

    enum RegistrationError: Error, Equatable {
        case invalidEntitlements
    }

    // MARK: - Properties

    /// Sudo user client used to perform sign in  and registration operations.
    var userClient: SudoUserClient = AppDelegate.dependencies.userClient

    var entitlementsClient = AppDelegate.dependencies.entitlementsClient

    var vpnClient = AppDelegate.dependencies.vpnClient

    /// Authenticator used to perform authentication during registration.
    var authenticator: Authenticator = AppDelegate.dependencies.authenticator

    // MARK: - Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Sign in automatically if the user is registered.
        Task {
            guard let isRegistered = try? await userClient.isRegistered() else {
                return
            }
            if isRegistered {
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
    /// `ServerListViewController` will be presented to the user.
    @IBAction func registerButtonTapped() {
        activityIndicator.startAnimating()
        registerButton.isEnabled = false
        Task {
            do {
                try await register()
                try await signIn()
                try await redeemEntitlements()
                if try await vpnClient.isProfileInstalled() {
                    print("Profile installed")
                } else {
                    print("Profile not installed")
                }
                activityIndicator.stopAnimating()
                registerButton.isEnabled = true
                navigateToDashboard()
            } catch {
                showRegistrationFailureAlert(error: error)
            }
        }
    }

    // MARK: - Operations

    func register() async throws {
        if try await userClient.isRegistered() {
            return
        }
        try await authenticator.register()
    }

    func signIn() async throws {
        if try await userClient.isSignedIn() {
            _ = try await userClient.refreshTokens()
        } else {
            _ = try await userClient.signInWithKey()
        }
    }

    func redeemEntitlements() async throws {
        let entitlements = try await entitlementsClient.redeemEntitlements()
        guard
            let entitlement = entitlements.entitlements.first(where: { $0.name == "sudoplatform.vpn.vpnUserEntitled"}),
            entitlement.value >= 0 // Allow the application to run unentitled for testing purposes.
        else {
            throw RegistrationError.invalidEntitlements
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

    /// Navigates to the `ServerListViewController` via a segue.
    private func navigateToDashboard() {
        performSegue(withSegue: Segue.navigateToDashboard, sender: self)
    }
}
