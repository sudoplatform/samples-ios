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

    /// Authenticator used to perform authentication during registration.
    var authenticator: Authenticator = AppDelegate.dependencies.authenticator

    // MARK: - Lifecycle

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Sign in automatically if the user is registered.
        if userClient.isRegistered() {
            self.registerButtonTapped()
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
        let completion: (Error?) -> Void = { [weak self] error in
            DispatchQueue.main.async {
                self?.activityIndicator.stopAnimating()
                self?.registerButton.isEnabled = true
                if let error = error {
                    self?.showRegistrationFailureAlert(error: error)
                } else {
                    self?.navigateToMainMenu()
                }
            }
        }
        register { [weak self] result in
            guard let self = self else { return }
            if case .failure(let error) = result {
                return completion(error)
            }
            self.signIn { [weak self] result in
                guard let self = self else { return }
                if case .failure(let error) = result {
                    return completion(error)
                }
                self.redeemEntitlements { result in
                    if case .failure(let error) = result {
                        completion(error)
                    } else {
                        completion(nil)
                    }
                }
            }
        }
    }

    // MARK: - Operations

    func register(completion: @escaping (Result<Void, Error>) -> Void) {
        if userClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            guard let presentationAnchor = self.view?.window else {
                fatalError("No window for \(String(describing: self))")
            }
            do {
                try userClient.presentFederatedSignInUI(presentationAnchor: presentationAnchor) { result in
                    switch result {
                    case .failure(let error):
                        return completion(.failure(error))
                    default:
                        return completion(.success(()))
                    }
                }
            } catch {
                completion(.failure(error))
            }
        } else {
            if userClient.isRegistered() {
                return completion(.success(()))
            }
            authenticator.register { result in
                switch result {
                case .failure(let error):
                    return completion(.failure(error))
                default:
                    return completion(.success(()))
                }
            }
        }
    }

    func signIn(completion: @escaping (Result<Void, Error>) -> Void) {
        do {
            if try userClient.isSignedIn() {
                guard let refreshToken = try? userClient.getRefreshToken() else {
                    return completion(.failure(AuthenticatorError.unableToRefreshTokens))
                }
                try userClient.refreshTokens(refreshToken: refreshToken) { result in
                    switch result {
                    case .failure(let error):
                        return completion(.failure(error))
                    default:
                        return completion(.success(()))
                    }
                }
                return
            }
            try userClient.signInWithKey { result in
                switch result {
                case .failure(let error):
                    return completion(.failure(error))
                default:
                    return completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    func redeemEntitlements(completion: @escaping (Result<Void, Error>) -> Void) {
        entitlementsClient.redeemEntitlements { result in
            switch result {
            case .success(let entitlements):
                guard
                    let entitlement = entitlements.entitlements.first(where: { $0.name == "sudoplatform.vpn.vpnUserEntitled"}),
                    entitlement.value >= 1
                else {
                    return completion(.failure(RegistrationError.invalidEntitlements))
                }
                completion(.success(()))
            case .failure(let error):
                return completion(.failure(error))
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

    /// Navigates to the `ServerListViewController` via a segue.
    private func navigateToMainMenu() {
        performSegue(withIdentifier: Segue.navigateToMainMenu.rawValue, sender: self)
    }
}
