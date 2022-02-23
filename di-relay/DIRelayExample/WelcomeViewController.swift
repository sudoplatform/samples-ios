//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import DeviceCheck

class WelcomeViewController: UIViewController {

    // MARK: - Outlets

    @IBOutlet weak var registerButton: UIButton!

    // MARK: - Supplementary

    enum AppleDeviceCheckError: Error {
        case notSupported
        case tokenNotReturned
        case generateError(causedBy: Error)
    }

    // MARK: - Properties

    /// Keep note of previous registration method, as sign in method differs accordingly.
    var previousRegistrationMethod: ChallengeType?

    /// Registration method used to register user.
    var currentRegistrationMethod: ChallengeType = .unknown

    /// Local postbox ID store.
    var postboxIdStorage: KeychainPostboxIdStorage = KeychainPostboxIdStorage()

    // MARK: - Properties: Computed

    /// Sudo user client used to perform sign in and registration operations.
    var userClient: SudoUserClient {
        return AppDelegate.dependencies.sudoUserClient
    }

    /// Authenticator used to perform authentication during registration.
    var authenticator: Authenticator {
        return AppDelegate.dependencies.authenticator
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToPostboxes":
            let navigationController = segue.destination as! UINavigationController
            let destination = navigationController.topViewController as! PostboxViewController
            let (postBoxIds) = sender as! [String]
            destination.postboxIds = postBoxIds
            destination.currentRegistrationMethod = self.currentRegistrationMethod
        default:
            break
        }
    }

    // MARK: - Actions

    /// When the 'Register / Login' button is clicked, attempt to register. sign in and retrieve postboxes from cache.
    @IBAction func registerButtonTapped() {
        presentActivityAlert(message: "Registering and signing in")

        registerAndSignIn { registered in
            DispatchQueue.main.async {
                self.dismiss(animated: true) { [self] in
                    if registered {
                        // Retrieve postboxes and navigate to postbox list after sign in is complete
                        if let postboxIds = self.retrievePostboxIdsFromCache() {
                            DispatchQueue.main.async {
                                self.performSegue(withIdentifier: "navigateToPostboxes", sender: postboxIds)
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Operations

    /// Perform registration and sign in from the Sudo user client.
    ///
    /// - Parameter completion: Closure that indicates the success or failure of the registration process.
    private func registerAndSignIn(completion: @escaping (Bool) -> Void) {
        func signIn() {
            do {
                if try userClient.isSignedIn() {
                    guard let tokenExpiry = try? userClient.getRefreshTokenExpiry() else {
                        self.showSignInFailureAlert(error: AuthenticatorError.unableToRefreshTokens)
                        completion(false)
                        return
                    }
                    if Date() < tokenExpiry {
                        completion(true)
                        return
                    }
                    guard let refreshToken = try? userClient.getRefreshToken() else {
                        self.showSignInFailureAlert(error: AuthenticatorError.unableToRefreshTokens)
                        completion(false)
                        return
                    }

                    try userClient.refreshTokens(refreshToken: refreshToken) { signInResult in
                        switch signInResult {
                        case .failure(let error):
                            self.showSignInFailureAlert(error: error)
                            completion(false)
                        case .success:
                            completion(true)
                        }
                    }
                    return
                }

                if self.previousRegistrationMethod == .fsso {
                    // Must sign in using FSSO UI
                    // TODO move this to another function
                    guard let presentationAnchor = self.view?.window else {
                        fatalError("No window for \(String(describing: self))")
                    }
                    do {
                        try userClient.presentFederatedSignInUI(presentationAnchor: presentationAnchor) { signInResult in
                            switch signInResult {
                            case .failure(let error):
                                self.showSignInFailureAlert(error: error)
                                completion(false)
                            case .success:
                                self.currentRegistrationMethod = .fsso
                                completion(true)
                            }
                        }
                    } catch {
                        self.showSignInFailureAlert(error: error)
                        completion(false)
                    }
                    return
                }

                // Sign in using key with back-end
                try userClient.signInWithKey { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        self.showSignInFailureAlert(error: error)
                        completion(false)
                    case .success:
                        completion(true)
                    }
                }
            } catch {
                self.showSignInFailureAlert(error: error)
                completion(false)
            }
        }

        if userClient.isRegistered() {
            signIn()
            return
        }

        if userClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            guard let presentationAnchor = self.view?.window else {
                fatalError("No window for \(String(describing: self))")
            }
            do {
                try userClient.presentFederatedSignInUI(presentationAnchor: presentationAnchor) { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        self.showSignInFailureAlert(error: error)
                        completion(false)
                    case .success:
                        self.currentRegistrationMethod = .fsso
                        completion(true)
                    }
                }
            } catch {
                self.showSignInFailureAlert(error: error)
                completion(false)
            }
        } else if userClient.getSupportedRegistrationChallengeType().contains(.deviceCheck) {
             generateDeviceCheckToken { result in
                switch result {
                case .success(let deviceCheckToken):
                    do {
                        try self.userClient.registerWithDeviceCheck(
                            token: deviceCheckToken,
                            buildType: "debug",
                            vendorId: UIDevice.current.identifierForVendor,
                            registrationId: UUID().uuidString
                        ) { (result) in
                            switch result {
                            case .success(let uid):
                                NSLog("Successfully registered for uid: \(uid)")
                                self.currentRegistrationMethod = .deviceCheck
                                signIn()
                            case .failure(let cause):
                                // A failure result may be returned if the backend is unable
                                // perform the registration due to availability or security issues.
                                self.showSignInFailureAlert(error: cause)
                                completion(false)
                            }
                        }
                    } catch {
                        // An error might be thrown for unrecoverable circumstances arising
                        // from programmatic error or configuration error.
                        self.showSignInFailureAlert(error: error)
                        completion(false)
                    }
                case .failure(let error):
                    self.showSignInFailureAlert(errorString: "Device check failed with error: \(error)")
                    completion(false)
                }
            }
        } else {
            // Try TEST registration with keys downloaded from Admin Console
            authenticator.register { registerResult in
                switch registerResult {
                case .failure(let error):
                    self.showRegistrationFailureAlert(error: error)
                    completion(false)
                case .success:
                    self.currentRegistrationMethod = .test
                    signIn()
                }
            }
        }
    }

    /// Obtain a device check token for SudoUser self-sign up registration.
    ///
    /// - Returns: DeviceCheck token upon success, or nil if DeviceCheck is not supported.
    private func generateDeviceCheckToken(completion: @escaping (Result<Data, AppleDeviceCheckError>) -> Void) {
        let currentDevice = DCDevice.current
        if currentDevice.isSupported {
            currentDevice.generateToken(completionHandler: { (data, error) in
                if let error = error {
                    completion(.failure(.generateError(causedBy: error)))
                } else {
                guard let token = data else {
                    completion(.failure(.tokenNotReturned))
                    return
                }
                    completion(.success(token))
                }
            })
        }
    }

    // MARK: - Actions

    /// Destination ViewController for the Sign out / Deregister segue.
    ///
    /// - Parameter seg: unwind segue.
    @IBAction func unwind( _ seg: UIStoryboardSegue) {}

    // MARK: - Helpers

    /// Attempt to retrieve all postbox IDs stored in the cache.
    /// If unsuccessful, present an error alert on the UI.
    /// 
    /// - Returns: Postbox IDs or nil.
    private func retrievePostboxIdsFromCache() -> [String]? {
        switch Result(catching: {
            try self.postboxIdStorage.retrieve()
        }) {
        case .success(.some(let postboxIds)):
            return postboxIds
        case .success(.none):
            return []
        case .failure(let error):
            presentErrorAlert(message: "Failed to retrieve stored postboxes", error: error)
            return nil
        }
    }

    /// Presents a `UIAlertController` containing a sign in failure given a sign in `error`.
    ///
    /// - Parameter error: Error to display.
    private func showSignInFailureAlert(error: Error) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                let alert = UIAlertController(
                    title: "Error",
                    message: "Failed to sign in:\n\(error.localizedDescription)",
                    preferredStyle: .alert
                )
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    /// Presents a `UIAlertController` containing a sign in failure given a string describing the failure.
    ///
    /// - Parameter errorString: String describing the failure.
    private func showSignInFailureAlert(errorString: String) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                let alert = UIAlertController(title: "Error", message: errorString, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    /// Presents a `UIAlertController` containing a registration failure given an `error`.
    ///
    /// - Parameter error: Error to display.
    private func showRegistrationFailureAlert(error: Error) {
        DispatchQueue.main.async {
            self.dismiss(animated: true) {
                let alert = UIAlertController(title: "Error", message: "Failed register:\n\(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
}
