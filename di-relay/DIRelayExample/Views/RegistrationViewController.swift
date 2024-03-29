//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoEntitlements
import SudoProfiles
import DeviceCheck
import SudoDIRelay

class RegistrationViewController: UIViewController {

    // MARK: - Outlets

    /// Registration button to begin registration.
    @IBOutlet weak var registerButton: UIButton!

    // MARK: - Supplementary

    enum AppleDeviceCheckError: Error {
        case notSupported
        case tokenNotReturned
        case generateError(causedBy: Error)
    }

    /// Segues that are performed in `RegistrationViewController`.
    enum Segue: String {
        /// Navigate to the `SudoListViewController`.
        case navigateToSudoList
    }

    // MARK: - Properties

    // MARK: - Properties: Computed

    /// Sudo user client used to perform sign in and registration operations.
    lazy var userClient: SudoUserClient = AppDelegate.dependencies.sudoUserClient

    /// Authenticator used to perform authentication during registration.
    var authenticator: Authenticator {
        return AppDelegate.dependencies.authenticator
    }

    /// Sudo entitlements client used to perform entitlements operations.
    var entitlementsClient: SudoEntitlementsClient = AppDelegate.dependencies.entitlementsClient

    var registerTask: Task<Void, Never>?

    // MARK: - Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task {

            // Sign in automatically if the user is registered.
            /*if try await self.userClient.isRegistered() {
                await self.registerButtonTapped()
            }*/
            // Get entitlements from SudoEntitlements
            _ = try await self.entitlementsClient.redeemEntitlements()
        }
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToSudoList:
            let navigationController = segue.destination as! UINavigationController
            _ = navigationController.topViewController as! SudoListViewController
        default:
            break
        }
    }

    // MARK: - Actions

    /// When the 'Register / Login' button is clicked, attempt to sign in, or register if no user is available
    @IBAction func registerButtonTapped() {
        registerTask = Task { @MainActor in
            await presentActivityAlertOnMain("Registering/Signing In")
            registerButton.isEnabled = false
            await registerAndSignIn()
            await dismissActivityAlert()
            registerButton.isEnabled = true
            // Navigate to sudo list after sign in is complete
            performSegue(withIdentifier: Segue.navigateToSudoList.rawValue, sender: [])
        }
    }

    // MARK: - Operations

    /// Perform registration and sign in with the Sudo Platform.
    /// Attempts to register with FSSO, then DeviceCheck, then finally TEST registration.
    /// Must have one of these registeration methods enabled in the environment.
    @MainActor private func registerAndSignIn() async {
        let registered = try? await userClient.isRegistered()
        if registered == true {
            _ = await signIn()
            return
        }

        let supportedChallengeTypes = userClient.getSupportedRegistrationChallengeType()
        do {
            if supportedChallengeTypes.contains(.fsso) {
                RegistrationMode.setRegistrationMode(.fsso)
                _ = try await signInWithFsso()
                /// Do not need to do anything further with FSSO, so return now.
                return
            }

            /// Register with DeviceCheck, or TEST if DeviceCheck is not enabled.
            if supportedChallengeTypes.contains(.deviceCheck) {
                RegistrationMode.setRegistrationMode(.deviceCheck)
                try await registerWithDeviceCheck()
            } else if supportedChallengeTypes.contains(.test) {
                RegistrationMode.setRegistrationMode(.test)
                try await registerWithTEST()
            }
        } catch {
            showRegistrationFailureAlert(error: error)
            /// Do not proceed to sign in, if registration is unsuccessful.
            return
        }

        _ = await signIn()
    }

    /// If the access tokens have expired, will refresh tokens.
    ///
    /// Must be signed in to refresh tokens.
    /// - Returns: true if tokens have successfully refreshed or if tokens are still valid.
    ///            false if tokens have not refreshed and are invalid.
    /// - Throws: `SudoUserClientError`
    private func refreshTokens() async throws -> Bool {
        // Cannot refresh tokens unless signed in
        if try await userClient.isSignedIn() == false {
            return false
        }

        guard let tokenExpiry = try userClient.getRefreshTokenExpiry() else {
            return false
        }

        // No need to refresh if token has not expired yet
        if Date() < tokenExpiry {
            return true
        }

        guard let refreshToken = try userClient.getRefreshToken() else {
            return false
        }

        // Apply refreshed tokens
        _ = try await userClient.refreshTokens(refreshToken: refreshToken)

        return true
    }

    /// Present the Federated Single Sign On UI to allow user to continue signing in via FSSO.
    /// - Returns: Authentication tokens upon success.
    private func signInWithFsso() async throws -> AuthenticationTokens {
        guard let presentationAnchor = self.view?.window else {
            fatalError("No window for \(String(describing: self))")
        }

        return try await userClient.presentFederatedSignInUI(presentationAnchor: presentationAnchor)
    }

    /// Attempt to sign into the Sudo Platform. Present a failure alert if unsuccessful.
    /// - Returns: Authentication tokens if successful, nil if unsuccessful.
    @MainActor private func signIn() async -> AuthenticationTokens? {
        do {
            _ = try await refreshTokens()

            if RegistrationMode.getPreviousRegistrationMode() == .fsso {
                return try await signInWithFsso()
            }

            // Sign in using key with back-end
            return try await userClient.signInWithKey()
        } catch {
            showSignInFailureAlert(error: error)
            return nil
        }
    }

    /// Obtain a device check token for SudoUser self-sign up registration.
    ///
    /// - Returns: DeviceCheck token upon success, or nil if DeviceCheck is not supported.
    /// - Throws: `AppleDeviceCheckError`
    private func generateDeviceCheckToken() async throws -> Data {
        let currentDevice = DCDevice.current

        if !currentDevice.isSupported {
            throw AppleDeviceCheckError.notSupported
        }
        guard let deviceCheckToken =  try? await currentDevice.generateToken() else {
            throw AppleDeviceCheckError.tokenNotReturned
        }

        return deviceCheckToken
    }

    /// Register with the Sudo Platform via DeviceCheck.
    private func registerWithDeviceCheck() async throws {
        let deviceCheckToken = try await generateDeviceCheckToken()

        guard let vendorId = UIDevice.current.identifierForVendor else {
            throw AppleDeviceCheckError.notSupported
        }

        let uid = try await userClient.registerWithDeviceCheck(
            token: deviceCheckToken,
            buildType: "debug",
            vendorId: vendorId,
            registrationId: UUID().uuidString
        )
        NSLog("Successfully registered for uid: \(uid)")
    }

    /// Register with the Sudo Platform via TEST registration keys.
    private func registerWithTEST() async throws {
        try await authenticator.register()
    }

    // MARK: - Actions

    /// Destination ViewController for the Sign out / Deregister segue.
    ///
    /// - Parameter seg: unwind segue.
    @IBAction func unwind( _ seg: UIStoryboardSegue) {}

    // MARK: - Helpers

    /// Presents a `UIAlertController` containing the sign in `error`.
    ///
    /// - Parameters:
    ///     - error: Contains the given `Error`.
    private func showSignInFailureAlert(error: Error) {
        let alert = UIAlertController(title: "Error", message: "Failed to sign in:\n\(error.localizedDescription)", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    /// Presents a `UIAlertController` containing a sign in failure given a string describing the failure.
    ///
    /// - Parameter errorString: String describing the failure.
    private func showSignInFailureAlert(errorString: String) {
        dismiss(animated: true) {
            let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    /// Presents a `UIAlertController` containing a registration failure given an `error`.
    ///
    /// - Parameter error: Error to display.
    private func showRegistrationFailureAlert(error: Error) {
        dismiss(animated: true) {
            let alert = UIAlertController(title: "Error", message: "Failed register:\n\(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
