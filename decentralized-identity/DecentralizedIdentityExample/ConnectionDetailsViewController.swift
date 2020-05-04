//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity

class ConnectionDetailsViewController: UITableViewController {
    // MARK: Data

    var pairwiseConnection: Pairwise!

    // MARK: Controller

    override func viewDidLoad() {
        super.viewDidLoad()

        connectionNameLabel.text = pairwiseConnection.label
        theirDidLabel.text = pairwiseConnection.theirDid
        myDidLabel.text = pairwiseConnection.myDid
    }

    // MARK: View

    @IBOutlet weak var connectionNameLabel: UILabel!
    @IBOutlet weak var theirDidLabel: UILabel!
    @IBOutlet weak var myDidLabel: UILabel!
}
