//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

@MainActor
class GeneratePasswordViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var lengthSlider: UISlider!
    @IBOutlet weak var lengthTextField: UITextField!
    @IBOutlet weak var strengthLabel: UILabel!
    @IBOutlet weak var lowercaseSwitch: UISwitch!
    @IBOutlet weak var uppercaseSwitch: UISwitch!
    @IBOutlet weak var numbersSwitch: UISwitch!
    @IBOutlet weak var symbolsSwitch: UISwitch!

    var length = 20

    var outputHandler: ((String) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Generate Password"

        passwordTextField.delegate = self

        lengthTextField.text = "\(length)"
        lengthSlider.maximumValue = 50
        lengthSlider.minimumValue = 6
        lengthSlider.value = 20

        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Done", style: .done, target: self, action: #selector(self.done))
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updatePassword()
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        passwordTextField.resignFirstResponder()
    }

    @IBAction func passwordTextChanged(_ sender: UITextField) {
        length = sender.text!.count
        lengthTextField.text = "\(length)"
        switch calculateStrength(of: sender.text!) {
        case .veryWeak:
            strengthLabel.text = "Very Weak"
            strengthLabel.textColor = .red
        case .weak:
            strengthLabel.text = "Weak"
            strengthLabel.textColor = .red
        case .moderate:
            strengthLabel.text = "Moderate"
            strengthLabel.textColor = .orange
        case .strong:
            strengthLabel.text = "Strong"
            strengthLabel.textColor = .green
        case .veryStrong:
            strengthLabel.text = "Very Strong"
            strengthLabel.textColor = .green
        }
        outputHandler?(passwordTextField.text ?? "")
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }

    @objc func done() {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }

    func updatePassword() {
        let password = generatePassword(length: length,
                                        allowUppercase: uppercaseSwitch.isOn,
                                        allowLowercase: lowercaseSwitch.isOn,
                                        allowNumbers: numbersSwitch.isOn,
                                        allowSymbols: symbolsSwitch.isOn)
        if let field = passwordTextField {
            field.text = password
            passwordTextChanged(field)
        }
        passwordTextField?.text = password
    }

    @IBAction func lengthSliderChanged(_ sender: UISlider) {
        // don't update password on tiny movements
        if (Int(sender.value) != length) {
            length = Int(sender.value)
            lengthTextField.text = "\(length)"
            updatePassword()
        }
    }

    @IBAction func lowercaseToggled(_ sender: UISwitch) {
        updatePassword()
    }

    @IBAction func uppercaseToggled(_ sender: UISwitch) {
        updatePassword()
    }

    @IBAction func numbersToggled(_ sender: UISwitch) {
        updatePassword()
    }

    @IBAction func symbolsToggled(_ sender: UISwitch) {
        updatePassword()
    }
}
