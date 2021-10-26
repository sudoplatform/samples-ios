//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class ConnectionDetailsViewController: UITableViewController {

    // MARK: - Supplementary

    var myPostboxId: String!
    var peerPostboxId: String!
    var myPublicKey: String!
    var peerPublicKey: String!

    // MARK: - Outlets

    @IBOutlet weak var myPostboxIdLabel: UILabel!
    @IBOutlet weak var peerPostboxIdLabel: UILabel!

    @IBOutlet weak var myEndpointLabel: UILabel!
    @IBOutlet weak var peerEndpointLabel: UILabel!

    @IBOutlet weak var myPublicKeyLabel: UILabel!
    @IBOutlet weak var peerPublicKeyLabel: UILabel!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let endpoint = AppDelegate.dependencies.appSyncClientHelper.getHttpEndpoint()
        
        peerPostboxIdLabel.text = peerPostboxId
        myPostboxIdLabel.text = myPostboxId
        
        myEndpointLabel.text = "\(endpoint)/\(myPostboxId ?? "")"
        peerEndpointLabel.text = "\(endpoint)/\(peerPostboxId ?? "")"


        myPublicKeyLabel.text = myPublicKey
        peerPublicKeyLabel.text = peerPublicKey

    }

    // MARK: - View

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        /// Tapping on a row.
        tableView.deselectRow(at: indexPath, animated: false)
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        /// Automatic cell height.
         return UITableView.automaticDimension
    }

}
