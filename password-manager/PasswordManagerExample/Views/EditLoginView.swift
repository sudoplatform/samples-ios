//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager

class EditLoginView: UIView {
    @IBOutlet weak var createdLabel: UILabel!
    @IBOutlet weak var updatedLabel: UILabel!
    @IBOutlet weak var loginNameField: UITextField!
    @IBOutlet weak var webAddressField: UITextField!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var notesField: UITextView!
    @IBOutlet weak var generatePasswordButton: UIButton!
    @IBOutlet weak var generatePasswordView: GeneratePasswordView!
    
    let nibName = "EditLoginView"
    var contentView: UIView?
    var login: VaultLogin?

    var allFieldsEmpty: Bool {
        return (webAddressField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty &&
            (loginNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty &&
            (usernameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty &&
            (passwordField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty &&
            (notesField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty
    }

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

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        endEditing(true)
    }

    func loadViewFromNib() -> UIView? {
        let bundle = Bundle(for: type(of: self))
        let nib = UINib(nibName: nibName, bundle: bundle)
        return nib.instantiate(withOwner: self, options: nil).first as? UIView
    }

    @IBAction func passwordTextChanged(_ sender: UITextField) {
        generatePasswordView.passwordTextChanged(sender)
    }

    @IBAction func showGeneratePassword(_ sender: Any) {
        if generatePasswordView.isHidden {
            generatePasswordView.updatePassword()
        }
        generatePasswordView.isHidden = !generatePasswordView.isHidden
    }

    func commonInit() {
        generatePasswordView.passwordTextField = passwordField
    }

    func setLogin(login: VaultLogin) {
        self.login = login
        do {
            webAddressField.text = login.url
            loginNameField.text = login.name
            usernameField.text = login.user
            passwordField.text = try login.password?.getValue()
            notesField.text = try login.notes?.getValue()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
            createdLabel.text = "Created: \(formatter.string(from: login.createdAt))"
            updatedLabel.text = "Updated: \(formatter.string(from: login.updatedAt))"
            createdLabel.isHidden = false
            updatedLabel.isHidden = false
        } catch {
            print(error)
        }
    }

    func getLogin() -> VaultLogin {
        // return updated existing login
        if let login = login {
            login.user = usernameField.text
            login.url = webAddressField.text
            login.name = (loginNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty ? "Create Login" : loginNameField.text!
            login.notes = VaultItemNote(value: notesField.text)
            login.password = VaultItemPassword(value: passwordField.text ?? "")
            return login
        } else {
            // return a new one
            return VaultLogin(user: usernameField.text,
                              url: webAddressField.text,
                              name: (loginNameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty ? "Create Login" : loginNameField.text!,
                              notes: VaultItemNote(value: notesField.text),
                              password: VaultItemPassword(value: passwordField.text ?? ""))
        }
    }
}
