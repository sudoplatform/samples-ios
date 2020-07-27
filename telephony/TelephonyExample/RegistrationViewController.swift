//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

class RegistrationViewController: UIViewController {
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Sign in automatically if the user is registered.
        let userClient: SudoUserClient = (UIApplication.shared.delegate as! AppDelegate).userClient
        if userClient.isRegistered() {
            self.registerButtonTapped()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }

    @IBAction func registerButtonTapped() {
        activityIndicator.startAnimating()
        registerButton.isEnabled = false

        registerAndSignIn { registered in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.registerButton.isEnabled = true

                if registered {
                    self.navigateToSudoList()
                }

                //register for incoming calls after sign in complete
                (UIApplication.shared.delegate as! AppDelegate).registerForIncomingCalls()
            }
        }
    }

    private func registerAndSignIn(completion: @escaping (Bool) -> Void) {
        let userClient: SudoUserClient = (UIApplication.shared.delegate as! AppDelegate).userClient
        let authenticator: Authenticator = (UIApplication.shared.delegate as! AppDelegate).authenticator

        func signIn() {
            do {
                if try userClient.isSignedIn() {
                    completion(true)
                    return
                }

                try userClient.signInWithKey { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        self.showSignInFailureAlert(error: error)
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
                        self.showSignInFailureAlert(error: error)
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
                        self.showRegistrationFailureAlert(error: error)
                        completion(false)
                    case .success:
                        signIn()
                    }
                }
            }
        }
    }

    private func showRegistrationFailureAlert(error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Failed to register:\n\(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func showSignInFailureAlert(error: Error) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: "Error", message: "Failed to sign in:\n\(error.localizedDescription)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }

    private func navigateToSudoList() {
        performSegue(withIdentifier: "navigateToSudoList", sender: self)
    }

    @IBAction func returnToRegistration(segue: UIStoryboardSegue) {}
}
