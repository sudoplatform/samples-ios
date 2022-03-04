//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

@MainActor
class ChangePasswordViewController: UIViewController {

    @IBOutlet weak var currentPasswordField: UITextField!
    @IBOutlet weak var newPasswordField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func save(_ sender: Any) {

        guard let currentPassword = self.currentPasswordField.text, let newPassword = self.newPasswordField.text else { return }
        guard let client = Clients.passwordManagerClient else { return }

        self.presentActivityAlert(message: "Changing master password")
        Task {
            do {
                try await client.changeMasterPassword(currentPassword: currentPassword, newPassword: newPassword)
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            } catch {
                self.dismiss(animated: true) {
                    self.presentErrorAlert(message: "Change master password failed", error: error)
                }
            }
        }
    }
}
