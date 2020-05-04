//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity

extension Pairwise {
    var label: String? {
        return metadata["LABEL"]
    }
}

class WalletViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    // MARK: Data

    var walletId: String!
    var primaryDid: Did!
    var pairwiseConnections: [Pairwise] = []

    // MARK: Controller

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        Dependencies.sudoDecentralizedIdentityClient.listPairwise(walletId: walletId) { result in
            DispatchQueue.main.async {
                switch result {
                case .success(let pairwise):
                    self.pairwiseConnections = pairwise
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentErrorAlert(message: "Failed to list pairwise connections", error: error)
                }
            }
        }
    }

    @IBAction func detailsTapped(_ sender: UIBarButtonItem) {
        performSegue(withIdentifier: "navigateToWalletDetails", sender: self)
    }

    // MARK: Table View

    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        assert(section == 0)
        return pairwiseConnections.count + 1
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        assert(section == 0)
        return "Pairwise Connections"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)

        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "createConnectionCell", for: indexPath)
        } else {
            let pairwiseConnection = pairwiseConnections[indexPath.row - 1]
            let cell = tableView.dequeueReusableCell(withIdentifier: "connectionCell", for: indexPath)
            cell.textLabel?.text = pairwiseConnection.label ?? "Their DID: \(pairwiseConnection.theirDid)"
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            performSegue(withIdentifier: "navigateToCreateConnection", sender: self)
        } else {
            performSegue(withIdentifier: "navigateToConnection", sender: pairwiseConnections[indexPath.row - 1])
        }
    }

    // MARK: Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToWalletDetails":
            let destination = segue.destination as! WalletDetailsViewController
            destination.walletId = self.walletId
            destination.primaryDid = self.primaryDid
        case "navigateToConnection":
            let pairwiseConnection = sender as! Pairwise
            let destination = segue.destination as! ConnectionViewController
            destination.walletId = self.walletId
            destination.pairwiseConnection = pairwiseConnection
        case "navigateToCreateConnection":
            let destination = segue.destination as! CreateConnectionViewController
            destination.walletId = self.walletId
            destination.did = self.primaryDid
        default: break
        }
    }

    @IBAction func returnToWallet(unwindSegue: UIStoryboardSegue) {}
}
