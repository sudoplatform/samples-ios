//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

class RegisterViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var registerButton: UIButton!
    @IBOutlet weak var registrationMethodPicker: UIPickerView!
    
    var hasAutoNavigated: Bool = false
    var registrationMethods: [ChallengeType] = []

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registrationMethodPicker.dataSource = self
        registrationMethodPicker.delegate = self

        // add TEST and FSSO sign in options if available.
        registrationMethods = Clients.userClient.getSupportedRegistrationChallengeType()
            .filter { $0 == .test || $0 == .fsso }
            .sorted(by: { $0.rawValue < $1.rawValue })

        // reload the registration method picker after options have been added.
        registrationMethodPicker.reloadAllComponents()

        // automatically sign in if we have signed in before.
        let lastMethod = Clients.authenticator.lastSignInMethod
        if let index = registrationMethods.firstIndex(of: lastMethod), !hasAutoNavigated {
            hasAutoNavigated = true

            registrationMethodPicker.selectRow(index, inComponent: 0, animated: false)
            registerButtonTapped()
        }

        if Clients.authenticator.lastSignInMethod == .fsso {
            let signOut = UIBarButtonItem(title: "Sign Out", style: .done, target: self, action: #selector(self.signOutTapped))
            self.navigationItem.rightBarButtonItem = signOut
        } else {
            let resetButton = UIBarButtonItem(title: "Reset", style: .done, target: self, action: #selector(self.resetClientsTapped))
            self.navigationItem.rightBarButtonItem = resetButton
        }
    }

    @objc func resetClientsTapped() {
        Clients.deregisterWithAlert()
    }

    @objc func signOutTapped() {
        guard let nav = self.navigationController else { return }
        Clients.authenticator.doFSSOSignOut(from: nav) { (maybeError) in
            Clients.resetClients()
            print("Failed to sign out: \(String(describing: maybeError))")
        }
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

        let selectedRow = registrationMethodPicker.selectedRow(inComponent: 0)
        let signInMethod = registrationMethods[selectedRow]
        Clients.authenticator.registerAndSignIn(from: self.navigationController!, signInMethod: signInMethod) { (result) in
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
        if let tabBarController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "TabBarController") as? UITabBarController {
            nav.viewControllers = [tabBarController]
            nav.modalPresentationStyle = .fullScreen
            self.present(nav, animated: true, completion: nil)
        }
    }

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return registrationMethods.count
    }

    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView?) -> UIView {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.text = registrationMethods[row].descriptionString
        return label
    }
}

extension ChallengeType {
    var descriptionString: String {
        switch self {
        case .test:
            return "TEST Registration"
        case .fsso:
            return "Federated Sign In"
        default:
            return self.rawValue
        }
    }
}
