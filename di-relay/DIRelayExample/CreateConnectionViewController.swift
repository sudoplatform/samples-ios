//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class CreateConnectionViewController: UITableViewController {

    // MARK: - Supplementary

    var walletId: String!
    var postboxId: String!

    // MARK: - Outlets

    @IBOutlet weak var invitationTableView: UITableView!

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToCreateInvitation":
            let destination = segue.destination as! CreateInvitationCodeViewController
            destination.myPostboxId = postboxId
        case "navigateToScanInvitation":
            let destination = segue.destination as! ScanInvitationViewController
            destination.postboxId = postboxId
        default:
            break
        }
    }

    // MARK: - Table View

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// Tapped on a row.
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
