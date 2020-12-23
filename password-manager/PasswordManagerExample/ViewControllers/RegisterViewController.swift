//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

class RegisterViewController: UIViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var registerButton: UIButton!
    
    let sudoProfilesClient = Clients.sudoProfilesClient

    var hasAutoNavigated: Bool = false

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if Clients.authenticator.lastSignInMethod != .none && !hasAutoNavigated {
            hasAutoNavigated = true
            self.registerButtonTapped()
        }

        if Clients.userClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            let signOut = UIBarButtonItem(title: "Sign Out", style: .done, target: self, action: #selector(self.signOutTapped))
            self.navigationItem.rightBarButtonItem = signOut
        }
        else {
            let resetButton = UIBarButtonItem(title: "Reset", style: .done, target: self, action: #selector(self.resetClientsTapped))
            self.navigationItem.rightBarButtonItem = resetButton
        }
    }

    @objc func signOutTapped() {
        guard let nav = self.navigationController else { return }
        Clients.authenticator.doFSSOSignOut(from: nav) { (maybeError) in
            try? Clients.resetClients()
            print("Failed to sign out: \(maybeError)")
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set navigation bar to be translucent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
        //navigationController?.navigationBar.isTranslucent = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Restore navigation bar to default state
        navigationController?.navigationBar.setBackgroundImage(nil, for: .default)
        navigationController?.navigationBar.shadowImage = nil
    }

    @IBAction func registerButtonTapped() {
        activityIndicator.startAnimating()
        registerButton.isEnabled = false

        Clients.authenticator.registerAndSignIn(from: self.navigationController!) { (result) in
            DispatchQueue.main.async {
                self.activityIndicator.stopAnimating()
                self.registerButton.isEnabled = true
                switch result {
                case .success: self.navigatePostSignIn()
                case .failure(let error): self.showRegistrationFailureAlert(error: error)
                }
            }
        }
    }

    private func registerAndSignIn(completion: @escaping (Bool) -> Void) {
        let userClient: SudoUserClient = Clients.userClient
        let authenticator: Authenticator = Clients.authenticator

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

    func navigatePostSignIn() {

        let nav = UINavigationController()
        let vaultsController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "UnlockVaultViewController") as! UnlockVaultViewController

        nav.viewControllers = [vaultsController]
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    @objc func resetClientsTapped() {
        (UIApplication.shared.delegate as! AppDelegate).deregister()
    }
}

