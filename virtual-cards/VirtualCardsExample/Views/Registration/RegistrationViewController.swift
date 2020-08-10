//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
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
    var userClient: SudoUserClient {
        return AppDelegate.dependencies.userClient
    }

    /// Authenticator used to perform authentication during registration.
    var authenticator: Authenticator {
        return AppDelegate.dependencies.authenticator
    }

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

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
    /// `MainMenuViewController` will be presented to the user.
    @IBAction func registerButtonTapped() {
        activityIndicator.startAnimating()
        registerButton.isEnabled = false

        registerAndSignIn { registered in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.registerButton.isEnabled = true

                if registered {
                    self.navigateToMainMenu()
                }
            }
        }
    }

    // MARK: - Operations

    /// Perform registration and sign in from the Sudo user client.
    ///
    /// - Parameters:
    ///     - completion: Closure that indicates the success or failure of the registration process.
    func registerAndSignIn(completion: @escaping (Bool) -> Void) {

        func signIn() {
            do {
                if try userClient.isSignedIn() {
                    completion(true)
                    return
                }

                try userClient.signInWithKey { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.showSignInFailureAlert(error: error)
                        }
                        completion(false)
                    case .success:
                        completion(true)
                    }
                }
            } catch let signInError {
                self.showSignInFailureAlert(error: signInError)
                completion(false)
            }
        }

        if userClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            guard let navigationController = self.navigationController else {
                return completion(false)
            }

            do {
                try userClient.presentFederatedSignInUI(navigationController: navigationController) { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.showSignInFailureAlert(error: error)
                        }
                        completion(false)
                    case .success:
                        completion(true)
                    }
                }
            } catch let signInError {
                self.showSignInFailureAlert(error: signInError)
                completion(false)
            }
        } else {
            if userClient.isRegistered() {
                signIn()
            } else {
                authenticator.register { registerResult in
                    switch registerResult {
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.showRegistrationFailureAlert(error: error)
                        }
                        completion(false)
                    case .success:
                        signIn()
                    }
                }
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
