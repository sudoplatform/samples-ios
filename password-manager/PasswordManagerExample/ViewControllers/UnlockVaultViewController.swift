//
//  UnlockVaultViewController.swift
//  PasswordManagerExample
//
//  Created by Cody Mace on 9/8/20.
//  Copyright © 2020 Sudo Platform. All rights reserved.
//

import UIKit
import SudoPasswordManager

class UnlockVaultViewController: UIViewController {
    @IBOutlet weak var instructionsLabel: UILabel!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var confirmPasswordField: UITextField!
    @IBOutlet weak var registrationStatusLoadingView: UIView!

    var passwordManagerClient: PasswordManagerClient!
    var registrationStatus: PasswordManagerRegistrationStatus = .notRegistered

    override func viewDidLoad() {
        super.viewDidLoad()
        passwordManagerClient = Clients.passwordManagerClient!

        if Clients.authenticator.lastSignInMethod == .fsso {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Sign out", style: .plain, target: self, action: #selector(self.back))
        }
        else {
            self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Deregister", style: .plain, target: self, action: #selector(self.back))
        }
    }

    @objc func back() {
        if Clients.authenticator.lastSignInMethod == .fsso {
            Clients.authenticator.doFSSOSignOut(from: self.navigationController!) { (maybeError) in
                runOnMain {
                    if let error = maybeError {
                        self.presentErrorAlert(message: "Failed to sign out: \(error)")
                        return
                    }
                    else {
                        try? Clients.resetClients()
                        self.dismiss(animated: true, completion: nil)
                    }
                }
            }
        }
        else {
            (UIApplication.shared.delegate as? AppDelegate)?.deregister()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        passwordField.text = ""
        confirmPasswordField.text = ""
        passwordManagerClient.getRegistrationStatus { [weak self] (result) in
            guard let self = self else { return }
            self.registrationStatusLoadingView.isHidden = true
            switch result {
            case .success(let status):
                self.registrationStatus = status
                switch self.registrationStatus {
                case .registered:
                    self.title = "Unlock Vaults"
                    self.confirmPasswordField.isHidden = true
                    self.passwordField.placeholder = "Enter your Master Password"
                    let unlockButton = UIBarButtonItem(title: "Unlock", style: .plain, target: self, action: #selector(self.unlockOrRegister))
                    self.navigationItem.rightBarButtonItems = [unlockButton]
                    // check if client is unlocked
                    if !self.passwordManagerClient.isLocked() {
                        self.proceedToVaults()
                    }
                case .notRegistered:
                    self.title = "Set Master Password"
                    let saveButton = UIBarButtonItem(title: "Save", style: .plain, target: self, action: #selector(self.unlockOrRegister))
                    self.passwordField.placeholder = "Enter a Master Password"
                    self.confirmPasswordField.isHidden = false
                    self.confirmPasswordField.placeholder = "Confirm Password"
                    self.navigationItem.rightBarButtonItems = [saveButton]
                case .missingSecretCode:
                    self.title = "Unlock Vaults"
                    self.passwordField.placeholder = "Enter Secret Code"
                    self.confirmPasswordField.placeholder = "Enter your Master Password"
                    self.confirmPasswordField.isHidden = false
                    let unlockButton = UIBarButtonItem(title: "Unlock", style: .plain, target: self, action: #selector(self.unlockOrRegister))
                    self.navigationItem.rightBarButtonItems = [unlockButton]
                }
            default:
                break
            }
        }
    }

    @objc func unlockOrRegister() {
        switch registrationStatus {
        case .registered:
            // unlock vault if password is correct
            if (passwordField.text ?? "").isEmpty {
                self.presentErrorAlert(message: "You must enter a password")
            } else {
                self.presentActivityAlert(message: "Unlocking Vault")
                self.passwordManagerClient.unlock(masterPassword: passwordField.text ?? "", secretCode: nil) { [weak self] (result) in
                    runOnMain {
                        switch result {
                        case .success:
                            self?.dismiss(animated: false, completion: nil)
                            self?.proceedToVaults()
                        case .failure(let error):
                            self?.dismiss(animated: false, completion: {
                                self?.presentErrorAlert(message: "Failed to unlock client", error: error)
                            })
                        }
                    }
                }
            }
        case .notRegistered:
            // register user if passwords match
            let password = passwordField.text ?? ""
            if !password.isEmpty && confirmPasswordField.text == password {
                self.presentActivityAlert(message: "Creating Vault")
                self.passwordManagerClient.register(masterPassword: password) { (result) in
                    runOnMain {
                        switch result {
                        case .success:
                            self.registrationStatus = .registered
                                self.passwordManagerClient.unlock(masterPassword: password, secretCode: nil) { (result) in
                                    DispatchQueue.main.async {
                                    switch result {
                                    case .success:
                                        self.dismiss(animated: false) {
                                            self.postRegistration()
                                        }
                                    case .failure(let error):
                                        self.dismiss(animated: false) {
                                            self.presentErrorAlert(message: "Failed to unlock client", error: error)
                                        }
                                        break
                                    }
                                }
                            }
                        case .failure(let error):
                            self.dismiss(animated: false) {
                                self.presentErrorAlert(message: "Failed to register client", error: error)
                            }
                            break
                        }
                    }
                }
            } else {
                self.presentErrorAlert(message: "The passwords must match")
            }
        case .missingSecretCode:
            self.presentActivityAlert(message: "Unlocking Vault")
            let password = confirmPasswordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let secretCode = passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            self.passwordManagerClient.unlock(masterPassword: password, secretCode: secretCode) { [weak self] (result) in
                runOnMain {
                    switch result {
                    case .success:
                        self?.dismiss(animated: false, completion: nil)
                        self?.proceedToVaults()
                    case .failure(let error):
                        self?.dismiss(animated: false, completion: {
                            self?.presentErrorAlert(message: "Failed to unlock client", error: error)
                        })
                    }
                }
            }
        }
    }

    func proceedToVaults() {
        runOnMain {
            let sudoProfilesClient = Clients.sudoProfilesClient!
            let vc = SudoListViewController.createWith(sudoProfilesClient: sudoProfilesClient, sudoSelected: { selectedSudo in
                let vaultsController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "VaultListViewController") as! VaultListViewController
                vaultsController.sudoID = selectedSudo.id!
                self.navigationController?.pushViewController(vaultsController, animated: true)
            },
            deregisterSelected: {
                (UIApplication.shared.delegate as! AppDelegate).deregister()
            })

            vc.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Lock", style: .plain, target: self, action: #selector(self.lockVault))

            self.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func postRegistration() {
        let alert = UIAlertController(title: "Your Secret Code & Rescue Kit", message: "Your secret code is used to sign in on new devices. It is unique to you and very important that you store it safely, as we cannot recover it for you. To save a copy of your secret code, download your Rescue Kit and save it somewhere safe.", preferredStyle: .alert)

        let copy = UIAlertAction(title: "Copy to clipboard", style: .default) { (_) in
            UIPasteboard.general.string = self.passwordManagerClient.getSecretCode()
        }

        let share = UIAlertAction(title: "Download", style: .default) { (_) in
            guard let pdf = self.passwordManagerClient.renderRescueKit() else { return }
            let pdfData = pdf.dataRepresentation()
            let vc = UIActivityViewController(
                activityItems: [pdfData as Any],
                applicationActivities: []
            )
            self.navigationController?.viewControllers.last?.present(vc, animated: true, completion: nil)
        }

        let notNow = UIAlertAction(title: "Not now", style: .default, handler: { _ in
        })

        alert.addAction(copy)
        alert.addAction(share)
        alert.addAction(notNow)

        self.present(alert, animated: true) {
            self.proceedToVaults()
        }
    }

    @objc func lockVault() {




        Clients.passwordManagerClient.lock()
        self.navigationController?.popToViewController(self, animated: true)
    }

    @objc func deregisterTapped() {
        let alert = UIAlertController(title: "Deregister", message: "Are you sure you want to deregister? All vaults, logins, and associated data will be deleted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Deregister", style: .default) { _ in
            (UIApplication.shared.delegate as! AppDelegate).deregister()
        })
        present(alert, animated: true, completion: nil)
    }

    @IBAction func passwordDone(_ sender: Any) {
        if registrationStatus == .notRegistered {
            confirmPasswordField.becomeFirstResponder()
        } else {
            unlockOrRegister()
        }
    }

    @IBAction func confirmPasswordDone(_ sender: Any) {
        unlockOrRegister()
    }
}
