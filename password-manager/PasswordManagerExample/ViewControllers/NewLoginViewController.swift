//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AuthenticationServices
import SudoPasswordManager

@MainActor
class NewLoginViewController: UIViewController {
    var vault: Vault!

    @IBOutlet weak var editLoginView: EditLoginView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Create Login"

        self.navigationItem.rightBarButtonItem = {
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.save))
        }()

        self.navigationItem.leftBarButtonItem = {
            UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(self.cancel))
        }()
    }


    @objc func cancel() {
        self.dismiss(animated: true, completion: nil)
    }

    @objc func save() {
        if editLoginView.allFieldsEmpty {
            presentErrorAlert(message: "At least one field must be filled out")
            return
        }
        let passwordManagerClient = Clients.passwordManagerClient!
        // add login
        self.presentActivityAlert(message: "Saving Vault Item")
        Task {
            do {
                _ = try await passwordManagerClient.add(item: self.editLoginView.getLogin(), toVault: vault)
                (self.presentingViewController ?? self)?.dismiss(animated: true, completion: nil)
            }
            catch {
                self.dismiss(animated: false, completion: {
                    self.presentErrorAlert(message: "Failed to add vault item", error: error)
                })
            }
        }
    }
}
