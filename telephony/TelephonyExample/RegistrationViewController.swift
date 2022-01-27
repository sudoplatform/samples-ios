//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoEntitlements

class RegistrationViewController: UIViewController {
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!

    lazy var userClient: SudoUserClient = {
        return (UIApplication.shared.delegate as! AppDelegate).userClient
    }()

    lazy var authenticator: Authenticator = {
        return (UIApplication.shared.delegate as! AppDelegate).authenticator
    }()

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // Sign in automatically if the user is registered.
        let userClient: SudoUserClient = (UIApplication.shared.delegate as! AppDelegate).userClient
        if userClient.isRegistered() {
            self.registerButtonTapped()
        }

        let resetButton = UIBarButtonItem(title: "Reset", style: .done, target: self, action: #selector(self.resetClientsTapped))
        self.navigationItem.rightBarButtonItem = resetButton
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Set navigation bar to be translucent
        navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        navigationController?.navigationBar.shadowImage = UIImage()
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

        registerAndSignIn { registered in
            do {
                let entitlementsClient = try DefaultSudoEntitlementsClient(userClient: self.userClient)
                entitlementsClient.redeemEntitlements { result in
                    if case .failure(let error) = result {
                        self.showSignInFailureAlert(error: error)
                    } else {
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
            } catch {
                self.showSignInFailureAlert(error: error)
            }
        }
    }

    private func registerAndSignIn(completion: @escaping (Bool) -> Void) {


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
                try userClient.presentFederatedSignInUI(presentationAnchor: navigationController.view.window!) { signInResult in
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

    @objc func resetClientsTapped() {

        let alert = UIAlertController(title: "Are you sure?", message: "This will reset the application and clear all local keys associated with accounts registered with this application. This may result in orphaned data on the service, including provisioned phone numbers.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { (_) in
            self.resetClients()
        }))

        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { (_) in

        }))

        self.present(alert, animated: true, completion: nil)
    }

    private func resetClients() {
        let authenticator = (UIApplication.shared.delegate as! AppDelegate).authenticator!
        let sudoProfilesClient = (UIApplication.shared.delegate as! AppDelegate).sudoProfilesClient!
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        do {
            try authenticator.userClient.reset()
            try sudoProfilesClient.reset()
            try telephonyClient.reset()
        } catch let error {
            self.presentErrorAlert(message: "Failed to deregister", error: error)
        }
    }
}
