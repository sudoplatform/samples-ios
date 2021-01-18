//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class SettingsViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        self.parent?.title = "Settings"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        self.parent?.navigationItem.title = "Settings"
    }

    @objc func done() {
        self.dismiss(animated: true, completion: nil)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch indexPath.row {
        case 0:
            signOut()
        case 1:
            clearData()
        default:
            break
        }
    }

    func signOut() {
        if Clients.authenticator.lastSignInMethod == .fsso {
            signOutFSSOWithAlert()
        } else {
            Clients.deregisterWithAlert()
        }
    }

    func clearData() {
        let alert = UIAlertController(title: "Clear Stored Data?", message: "This will clear all stored data", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Clear Storage", style: .default, handler: { _ in
            do {
                try Clients.adTrackerBlockerClient.reset()
            } catch {
                print("Failed to clear data: \(error)")
            }
        }))
        present(alert, animated: true, completion: nil)
    }

    func signOutFSSOWithAlert() {
        let alert = UIAlertController(title: "Are you sure?", message: "This will sign out of your account and will clear all stored data.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { (_) in
            UIApplication.shared.topController?.presentActivityAlert(message: "Signing out")
            Clients.authenticator.doFSSOSignOut(from: self.navigationController!) { _ in
                DispatchQueue.main.async {
                    Clients.resetClients()
                    UIApplication.shared.rootController?.dismiss(animated: true, completion: nil)
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
        }))

        UIApplication.shared.topController?.present(alert, animated: true, completion: nil)
    }
}
