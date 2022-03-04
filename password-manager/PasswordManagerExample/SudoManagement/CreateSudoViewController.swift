//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles

@MainActor
class CreateSudoViewController: UIViewController {
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBOutlet weak var labelTextField: UITextField!

    var sudoProfilesClient: SudoProfilesClient!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        labelTextField.addTarget(self, action: #selector(textFieldDidChange(_:)), for: UIControl.Event.editingChanged)
    }

    @objc func textFieldDidChange(_ textField: UITextField) {
        // enable create button when textfield is not empty
        createButton.isEnabled = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    @IBAction func createTapped(_ sender: Any) {
        let sudo = Sudo(title: nil, firstName: nil, lastName: nil, label: labelTextField.text, notes: nil, avatar: nil)
        presentActivityAlert(message: "Creating sudo")

        Task {
            do {
                _ = try await sudoProfilesClient.createSudo(sudo: sudo)
                await self.dismiss(animated: true)
                self.performSegue(withIdentifier: "returnToSudoList", sender: self)
            } catch let error {
                dismiss(animated: true) {
                    self.presentErrorAlert(message: "Failed to create sudo", error: error)
                }
            }
        }
    }
}


