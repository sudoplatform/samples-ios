//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles

class CreateSudoViewController: UIViewController {
    @IBOutlet weak var createButton: UIBarButtonItem!
    @IBOutlet weak var labelTextField: UITextField!
    
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

        let sudoProfilesClient = (UIApplication.shared.delegate as! AppDelegate).sudoProfilesClient!

        presentActivityAlert(message: "Creating sudo")

        do {
            try sudoProfilesClient.createSudo(sudo: sudo) { result in
                DispatchQueue.main.async {
                    // dismiss activity alert
                    self.dismiss(animated: true) {
                        switch result {
                        case .success:
                            self.performSegue(withIdentifier: "returnToSudoList", sender: self)
                        case .failure(let error):
                            self.presentErrorAlert(message: "Failed to create sudo", error: error)
                        }
                    }
                }
            }
        } catch let error {
            dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to create sudo", error: error)
            }
        }
    }
}
