//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SudoTelephony

class CreateVoiceCallViewController: UIViewController {
    var localNumber: PhoneNumber!

    @IBOutlet weak var startCallButton: UIBarButtonItem!
    @IBOutlet weak var phoneNumberField: UITextField!

    override func viewDidLoad() {
        // During testing it's likely the same number will be called over and over.  To save time save it.
        phoneNumberField.text = UserDefaults.standard.string(forKey: "LastCalledNumber")
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        phoneNumberField.becomeFirstResponder()
    }

    @IBAction func textFieldDidChange(_ textField: UITextField) {
        // Enable the "Start Call" button when the text field is not empty.
        startCallButton.isEnabled = !(textField.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }

    @IBAction func startCallTapped(_ sender: Any) {
        UserDefaults.standard.setValue(phoneNumberField.text, forKey: "LastCalledNumber")
        performSegue(withIdentifier: "navigateToActiveCall", sender: nil)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToActiveCall":
            let destination = (segue.destination as! UINavigationController).topViewController! as! ActiveVoiceCallViewController
            destination.startWithOutgoingCall(parameters: (localNumber, phoneNumberField.text ?? ""))
        default: break
        }
    }
}
