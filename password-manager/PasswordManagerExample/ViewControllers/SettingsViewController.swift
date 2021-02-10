//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

class SettingsViewController: UITableViewController {

    @IBOutlet weak var deregisterLabel: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.done))

        if Clients.authenticator.lastSignInMethod == .fsso {
            deregisterLabel.text = "Sign Out"
        }
        else {
            deregisterLabel.text = "Deregister"
        }

    }

    @objc func done() {
        self.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            // Change master password - Hooked up through segue.
            break
        case 1:
            // show secret code
            break
        case 2:
            // lock vaults
            Clients.passwordManagerClient.lock()
            self.dismissToUnlockScreen()
        case 3:
            // deregister / sign out
            if Clients.authenticator.lastSignInMethod == .fsso {
                Clients.authenticator.doFSSOSignOut(from: self.view.window!) { (maybeError) in
                    runOnMain {
                        switch maybeError {
                        case .some(SudoUserClientError.signInCanceled):
                            break
                        case .some(let error):
                            self.presentErrorAlert(message: "Failed to sign out: \(error)")
                        case .none:
                            Clients.resetClients()
                            UIApplication.shared.rootController?.dismiss(animated: true, completion: nil)
                        }
                    }
                }
            }
            else {
                Clients.deregisterWithAlert()
            }
            break
        case 4:
            // Entitlements
            break
        case 5:
            deregisterPasswordManagerWithAlert()
            break
        default:
            break
        }
    }

    func deregisterPasswordManagerWithAlert() {
        let alert = UIAlertController(title: "All vaults will be lost", message: "This will reset your account with the vault service and all vaults will be lost.  Your secret code/rescue kit will be reset and you will be asked to create a new master password.", cancelActionTitle: "Not now")

        alert.addAction(UIAlertAction(title: "Reset Vaults", style: .destructive, handler: { (_) in
            self.deregisterPasswordManager()
        }))

        self.present(alert, animated: true, completion: nil)
    }

    func deregisterPasswordManager() {
        self.presentActivityAlert(message: "Resetting Vaults")
        Clients.passwordManagerClient.deregister { (result) in
            switch result {
            case .success:
                DispatchQueue.main.async {
                    self.dismissToUnlockScreen()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.presentErrorAlert(message: "Something went wrong", error: error)
                }
            }
        }
    }

    func dismissToUnlockScreen() {
        ((self.presentingViewController as? UINavigationController) ?? self.presentingViewController?.navigationController)?.popToRootViewController(animated: false)
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func resetSecretCode() {
        guard let client = Clients.passwordManagerClient else { return }
        let code = client.getSecretCode()
        let alert = UIAlertController(title: "Reset Keys?", message: "This will clear all encryption keys and your secret code will be required in order to unlock the vault.\n\n For convenience your secret code will be copied to the system pasteboard before being removed.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { (_) in
        }))
        alert.addAction(UIAlertAction(title: "Reset Keys", style: .default, handler: { (action) in
            UIPasteboard.general.string = code
            do {
                try Clients.keyManager.removeAllKeys()
            } catch {
                self.presentErrorAlert(message: "Failed to remove keys", error: error)
            }
            client.lock()
            self.dismissToUnlockScreen()
        }))
        present(alert, animated: true, completion: nil)
    }
}

extension UIAlertController {

    convenience init(title: String, message: String, cancelActionTitle: String) {
        self.init(title: title, message: message, preferredStyle: .alert)
        self.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil))
    }

    static func withDefaultCancelActionAndAlert(title: String, message: String, cancelActionTitle: String = "Cancel") -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: cancelActionTitle, style: .cancel, handler: nil))
        return alert
    }

}
