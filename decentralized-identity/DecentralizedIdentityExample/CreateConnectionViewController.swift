//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity

class CreateConnectionViewController: UITableViewController {
    var walletId: String!
    var did: Did!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToLabelConnectionForCreate":
            let destination = segue.destination as! LabelConnectionViewController
            destination.destinationSegue = "navigateToCreateInvitationCode"
            destination.walletId = self.walletId
            destination.did = self.did
        case "navigateToLabelConnectionForScan":
            let destination = segue.destination as! LabelConnectionViewController
            destination.destinationSegue = "navigateToScanInvitation"
            destination.walletId = self.walletId
            destination.did = self.did
        default: break
        }
    }
}

class LabelConnectionViewController: UIViewController {
    var walletId: String!
    var did: Did!

    // MARK: Navigation

    /// The "Label Connection" screen will navigate to either the "Create Invitation Code"
    /// or "Scan Invitation" screen depending on the value of this `destinationSegue`.
    var destinationSegue: String!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToCreateInvitationCode":
            let destination = segue.destination as! CreateInvitationCodeViewController
            destination.walletId = self.walletId
            destination.localDid = self.did
            destination.connectionName = labelTextField.text
        case "navigateToScanInvitation":
            let destination = segue.destination as! ScanInvitationViewController
            destination.walletId = self.walletId
            destination.localDid = self.did
            destination.connectionName = labelTextField.text
        default: break
        }
    }

    @IBAction func createButtonPressed(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: destinationSegue, sender: self)
    }

    // MARK: View

    override func viewDidLoad() {
        super.viewDidLoad()

        switch destinationSegue {
        case "navigateToCreateInvitationCode":
            navigationItem.title = "Create Invitation"
        case "navigateToScanInvitation":
            navigationItem.title = "Scan Invitation"
        default: break
        }

        labelTextField.text = UIDevice.current.name
        labelTextFieldChanged(labelTextField)
    }

    @IBOutlet weak var labelTextField: UITextField!
    @IBOutlet weak var createButton: UIBarButtonItem!

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        labelTextField.becomeFirstResponder()
    }

    @IBAction func labelTextFieldChanged(_ sender: UITextField) {
        createButton.isEnabled = !(sender.text?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true)
    }
}
