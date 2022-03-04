//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

@MainActor
class EditLoginViewController: UIViewController {
    @IBOutlet weak var editLoginView: EditLoginView!
    var login: VaultLogin!
    var vault: Vault!

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Edit Login"
        
        self.navigationItem.rightBarButtonItem = {
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.save))
        }()

        editLoginView.setLogin(login: login)
    }

    @objc func save() {
        if editLoginView.allFieldsEmpty {
            presentErrorAlert(message: "At least one field must be filled out")
            return
        }
        let passwordManagerClient = Clients.passwordManagerClient!
        // update login
        self.presentActivityAlert(message: "Saving Vault Item")
        Task {
            do {
                let _ = try await passwordManagerClient.update(item: editLoginView.getLogin(), in: vault)
                self.dismiss(animated: false, completion: nil)
                self.navigationController?.popViewController(animated: true)
            }
            catch {
                self.dismiss(animated: false, completion: {
                    self.presentErrorAlert(message: "Failed to update vault item", error: error)
                })
            }
        }

    }
}
