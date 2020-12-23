//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class GeneratePasswordViewController: UIViewController {
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var generatePasswordView: GeneratePasswordView!

    var length = 20

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Generate Password"
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        generatePasswordView.passwordTextField = passwordTextField
        generatePasswordView.updatePassword()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        passwordTextField.resignFirstResponder()
    }

    @IBAction func passwordTextChanged(_ sender: UITextField) {
        generatePasswordView.passwordTextChanged(sender)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
