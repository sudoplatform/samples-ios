//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class GeneratePasswordView: UIView, UITextFieldDelegate {
    @IBOutlet weak var lengthSlider: UISlider!
    @IBOutlet weak var lengthTextField: UITextField!
    @IBOutlet weak var strengthLabel: UILabel!
    @IBOutlet weak var lowercaseSwitch: UISwitch!
    @IBOutlet weak var uppercaseSwitch: UISwitch!
    @IBOutlet weak var numbersSwitch: UISwitch!
    @IBOutlet weak var symbolsSwitch: UISwitch!

    let nibName = "GeneratePasswordView"
    var contentView: UIView?

    var passwordTextField: UITextField? {
        didSet {
            passwordTextField?.delegate = self
        }
    }

    var length = 20

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }


    required init?(coder: NSCoder) {
        super.init(coder: coder)
        guard let view = loadViewFromNib() else { return }
        view.frame = self.bounds
        self.addSubview(view)
        contentView = view
        commonInit()
    }

    func commonInit() {
        lengthTextField.text = "\(length)"
        lengthSlider.maximumValue = 50
        lengthSlider.minimumValue = 6
        lengthSlider.value = 20
    }

    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        passwordTextField?.resignFirstResponder()
    }

    func passwordTextChanged(_ sender: UITextField) {
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
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
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
