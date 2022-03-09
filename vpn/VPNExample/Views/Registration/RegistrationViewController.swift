//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

class RegistrationViewController: UIViewController {

    // MARK: - Outlets

    /// Button at the bottom of the screen. This is tapped when a user wishes to regiter or login to the app.
    @IBOutlet var registerButton: UIButton!

    /// Activity indicator which indicates that the registration process is currently underway.
    @IBOutlet var activityIndicator: UIActivityIndicatorView!

    // MARK: - Supplementary

    /// Segues that are performed in `RegistrationViewController`.
    enum Segue: String {
        /// Used to navigate to the `ServerListViewController`.
        case navigateToMainMenu
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
        Task.detached(.medium) {
            guard let isRegistered = try? await userClient.isRegistered() else {
                return
            }
            if isRegistered {
                DispatchQueue.main.async {
                    self.registerButtonTapped()
                }
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
        Task.detached(priority: .medium) {
            do {
                try await self.register()
                try await self.signIn()
                try await self.redeemEntitlements()
                try await self.vpnClient.prepare()
                Task { @MainActor [weak self] in
                    self?.activityIndicator.stopAnimating()
                    self?.registerButton.isEnabled = true
                    self?.navigateToMainMenu()
                }
            } catch {
                await self.showRegistrationFailureAlert(error: error)
            }
        }
    }

    // MARK: - Operations

    @MainActor
    func register() async throws {
        if userClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            guard let presentationAnchor = self.view?.window else {
                fatalError("No window for \(String(describing: self))")
            }
            _ = try await userClient.presentFederatedSignInUI(presentationAnchor: presentationAnchor)
        } else {
            if try await userClient.isRegistered() {
                return
            }
            try await authenticator.register()
        }
    }

    func signIn() async throws {
        if try await userClient.isSignedIn() {
            guard let refreshToken = try? userClient.getRefreshToken() else {
                throw AuthenticatorError.unableToRefreshTokens
            }
            _ = try await userClient.refreshTokens(refreshToken: refreshToken)
            return
        }
        _ = try await userClient.signInWithKey()
        return
    }

    func redeemEntitlements() async throws {
        let entitlements = try await entitlementsClient.redeemEntitlements()
        guard
            let entitlement = entitlements.entitlements.first(where: { $0.name == "sudoplatform.vpn.vpnUserEntitled"}),
            entitlement.value >= 1
        else {
            throw RegistrationError.invalidEntitlements
        }
    }

    // MARK: - Helpers

    /// Presents a `UIAlertController` containing the registration `error`.
    ///
    /// - Parameters:
    ///     - error: Contains the given `Error`.
    @MainActor
    private func showRegistrationFailureAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: "Failed to register:\n\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    /// Navigates to the `ServerListViewController` via a segue.
    private func navigateToMainMenu() {
        performSegue(withIdentifier: Segue.navigateToMainMenu.rawValue, sender: self)
    }
}
