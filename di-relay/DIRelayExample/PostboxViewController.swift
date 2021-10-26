//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay

class PostboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Supplementary

    var postboxIds: [String] = []
    var relayClient: SudoDIRelayClient {
        return AppDelegate.dependencies.sudoDIRelayClient
    }
    private var presentedActivityAlert: UIAlertController?

    // MARK: - Outlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.tableFooterView = UIView()
    }

    // MARK: - Table View

    /// Return the number of table rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return postboxIds.count + 1
    }

    /// Return the title of the table.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Active Postboxes"
    }

    /// Return a table cell either containing the button to create a postbox or a label containing the postbox ID.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "createPostboxCell", for: indexPath)
        } else {
            let postBoxId = postboxIds[indexPath.row - 1]
            let cell = tableView.dequeueReusableCell(withIdentifier: "postboxCell", for: indexPath)
            cell.textLabel?.text = postBoxId
            return cell
        }
    }
    
    /// After tapping on a row, if the `Create Postbox` button was tapped, attempt to provision a new postbox.
    /// If a postbox ID was tapped, either navigate to creating a new connection, or to the connection conversation screen.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        if indexPath.row == 0 {
            /// Clicked Create Postbox.
            createPostBoxAndSaveToCache()
            
        } else {
            // Clicked on an existing Postbox ID.=
            let postboxId = postboxIds[indexPath.row - 1]

            if let _ = try? KeyManagement().getPublicKeyForConnection(connectionId: postboxId) {
                // Peer has been connected
                performSegue(withIdentifier: "navigateToConnection", sender: postboxId)
            } else {
                // New connection
                performSegue(withIdentifier: "navigateToCreateConnection", sender: postboxId)
            }
        }
    }
    
    /// Swipe on an existing postbox ID to delete postbox.
    /// If swiping on the `Create Postbox` button, do nothing.
    func tableView(_ tableView: UITableView,
                   leadingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row > 0 {
            let postBoxId = postboxIds[indexPath.row - 1]
            let action = UIContextualAction(
                style: .normal,
                title: "Delete"
            ) { [weak self] (action, view, completionHandler) in
                self?.deletePostboxFromRelayAndCache(postBoxId: postBoxId)
                completionHandler(true)
            }
            action.backgroundColor = .systemRed
            return UISwipeActionsConfiguration(actions: [action])
        }
        return nil
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToConnection":
            let destination = segue.destination as! ConnectionViewController
            destination.myPostboxId = sender as? String ?? ""
        case "navigateToCreateConnection":
            let destination = segue.destination as! CreateConnectionViewController
            destination.postboxId = sender as? String
        default: break
        }
    }

    // MARK: - Actions

    @IBAction func returnToWallet(unwindSegue: UIStoryboardSegue) {}
    
    /// Show a description when tapping on the info button.
    @IBAction func infoTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "What is a Postbox?", message: "A Postbox is a store for DIDComm messages that uses a relay defined in Aries RFC 0046.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Helpers
    
    /// Attempt to create a postbox via the `SudoDIRelayClient`, using a UUID4 generated `connectionId`.
    /// If successful, store the `connectionId` to the postbox ID storage cache.
    /// If unsuccessful, display the an error alert on the UI.
    func createPostBoxAndSaveToCache() {
        presentActivityAlert(message: "Creating postbox...")
        let connectionId = UUID().uuidString

        relayClient.createPostbox(withConnectionId: connectionId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    do {
                        try KeychainPostboxIdStorage().store(postboxId: connectionId)
                        self?.dismiss(animated: true) {
                            self?.updatePostboxView()
                        }
                    } catch let error {
                        self?.dismiss(animated: true) {
                            self?.presentErrorAlert(message: "Failed to store postbox id in cache", error: error)
                        }
                        return
                    }
                case let .failure(error):
                    self?.dismiss(animated: true) {
                        self?.presentErrorAlert(message: "Failed to create postbox in relay", error: error)
                    }
                }
            }
        }
    }
    
    /// Attempt to retrieve an updated list of the postbox IDs and refresh the table.
    /// If unsuccessful, does not refresh the table.
    func updatePostboxView() {
        guard let updatedPostboxIds = retrievePostboxIdsOrAlert() else { return }
        postboxIds = updatedPostboxIds
        tableView.reloadData()
    }
    
    /// Attempt to retrieve the list of postboxes from the postbox ID storage.
    /// If unsuccessful, display an error alert on the UI.
    /// - Returns: List of postbox IDs or  nil
    func retrievePostboxIdsOrAlert() -> [String]? {
        switch Result(catching: {
            try KeychainPostboxIdStorage().retrieve()
        }) {
        case .success(.some(let ids)):
            return ids
        case .success(.none):
            self.dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to retrieve postboxes from cache:\nNot found")
            }
            return nil
        case .failure(let error):
            self.dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to retrieve postboxes in relay", error: error)
            }
            return nil
        }
    }
    
    /// Delete postbox in the relay via the `SudoDIRelayClient` and resent an activity alert on the UI.
    /// If unsuccessful, present an error alert.
    /// - Parameter postBoxId: postbox ID to delete.
    func deletePostboxFromRelayAndCache(postBoxId: String) {
        presentActivityAlert(message: "Deleting postbox...")
        relayClient.deletePostbox(withConnectionId: postBoxId) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(_):
                    KeychainPostboxIdStorage().delete(postBoxId: postBoxId)
                    self?.dismiss(animated: true) {
                        self?.updatePostboxView()
                    }
                case let .failure(error):
                    self?.dismiss(animated: true) {
                        self?.presentErrorAlert(message: "Failed to delete postbox from relay", error: error)
                    }
                }
            }
        }
    }
}
