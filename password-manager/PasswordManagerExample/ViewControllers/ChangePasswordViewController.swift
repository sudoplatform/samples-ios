//
//  ChangePasswordViewController.swift
//  PasswordManagerExample
//
//  Created by Brandon Roth on 9/21/20.
//  Copyright © 2020 Sudo Platform. All rights reserved.
//

import UIKit

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
        client.changeMasterPassword(currentPassword: currentPassword, newPassword: newPassword) { (result) in
            runOnMain {
                switch result {
                case .success:
                    self.dismiss(animated: true, completion: nil)
                    self.navigationController?.popViewController(animated: true)
                case .failure(let error):
                    self.dismiss(animated: true) {
                        self.presentErrorAlert(message: "Change master password failed", error: error)
                    }
                }
            }
        }
    }
}
