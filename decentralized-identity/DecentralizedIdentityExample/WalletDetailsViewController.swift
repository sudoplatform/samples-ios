//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity

class WalletDetailsViewController: UITableViewController {
    // MARK: Data

    var walletId: String!
    var primaryDid: Did!

    // MARK: Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        walletIdLabel.text = walletId
        primaryDidLabel.text = primaryDid.did
        primaryDidVerkeyLabel.text = primaryDid.verkey
    }

    // MARK: View

    @IBAction func infoTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "What is a Wallet / DID?", message: "A Decentralized Identifier (DID) is a new type of identifier that is globally unique, resolvable with high availability, and cryptographically verifiable. Your wallet contains the private keys for your DIDs.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @IBOutlet weak var walletIdLabel: UILabel!
    @IBOutlet weak var primaryDidLabel: UILabel!
    @IBOutlet weak var primaryDidVerkeyLabel: UILabel!
}
