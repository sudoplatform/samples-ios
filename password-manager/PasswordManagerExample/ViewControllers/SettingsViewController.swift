//
//  SettingsViewController.swift
//  PasswordManagerExample
//
//  Created by Brandon Roth on 9/21/20.
//  Copyright © 2020 Sudo Platform. All rights reserved.
//

import UIKit

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
                Clients.authenticator.doFSSOSignOut(from: self.navigationController!) { (maybeError) in
                    try? Clients.resetClients()
                    (UIApplication.shared.delegate as? AppDelegate)?.rootController()?.dismiss(animated: true, completion: nil)
                }
            }
            else {
                (UIApplication.shared.delegate as? AppDelegate)?.deregister()
            }
            break
        default:
            break
        }
    }

    func dismissToUnlockScreen() {
        ((self.presentingViewController as? UINavigationController) ?? self.presentingViewController?.navigationController)?.popToRootViewController(animated: false)
        self.dismiss(animated: true, completion: nil)
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
