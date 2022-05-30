//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay
import SudoUser
import SudoProfiles

class PostboxViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ExitHandling {

    // MARK: - Supplementary

    /// Segues that are performed in `SudoListViewController`.
    enum Segue: String {
        /// Navigate to the `CreateConnectionViewController`.
        case navigateToCreateConnection

        /// Navigate to `ConnectionViewController`.
        case navigateToConnection

        /// Navigate to the `RegistrationViewController`.
        case unwindToRegistration
    }
    
    // MARK: - Properties

    var sudo: Sudo!
    var postboxIds: [String] = []
    var ownershipProofs: [String: String] = [:]
    private var presentedActivityAlert: UIAlertController?

    // MARK: - Properties: Computed

    var relayClient: SudoDIRelayClient {
        return AppDelegate.dependencies.sudoDIRelayClient
    }

    var sudoUserClient: SudoUserClient {
        return AppDelegate.dependencies.sudoUserClient
    }

    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }

    // MARK: - Outlets

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
        Task(priority: .medium) {
            await updatePostboxView()
        }
        fetchOwnershipProof(sudo)
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
            Task {
                await self.createPostBoxAndSaveToCache()
            }
        } else {
            // Clicked on an existing Postbox ID
            let postboxId = postboxIds[indexPath.row - 1]

            if let _ = try? KeyManagement().getPublicKeyForConnection(connectionId: postboxId) {
                // Peer has been connected
                performSegue(withIdentifier: Segue.navigateToConnection.rawValue, sender: postboxId)
            } else {
                // New connection
                performSegue(withIdentifier: Segue.navigateToCreateConnection.rawValue, sender: postboxId)
            }
        }
    }
    
    /// Swipe on an existing postbox ID to delete postbox.
    /// If swiping on the `Create Postbox` button, do nothing.
    func tableView(
        _ tableView: UITableView,
        trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath
    ) -> UISwipeActionsConfiguration? {
        if indexPath.row > 0 {
            let postBoxId = postboxIds[indexPath.row - 1]
            let action = UIContextualAction(style: .normal, title: "Delete") { [weak self] (action, view, completionHandler) in
                self?.didSwipeToDeletePostbox(postBoxId: postBoxId)
                completionHandler(true)
            }
            action.backgroundColor = .systemRed
            return UISwipeActionsConfiguration(actions: [action])
        }
        return nil
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToConnection:
            let destination = segue.destination as! ConnectionViewController
            destination.myPostboxId = sender as? String ?? ""
        case .navigateToCreateConnection:
            let destination = segue.destination as! CreateConnectionViewController
            destination.postboxId = sender as? String
        default:
            break
        }
    }

    // MARK: - Actions

    /// Proceed to sign out and deregister user, and then unwind to the start (RegistrationViewController).
    ///
    /// - Parameter sender: Exit button.
    @IBAction func didTapExitButton(_ sender: Any) {
        self.doExitButtonAction(sender)
    }

    // MARK: - Helpers
    
    /// Attempt to create a postbox via the `SudoDIRelayClient`, using a UUID4 generated `connectionId`.
    /// If successful, store the `connectionId` to the postbox ID storage cache.
    /// If unsuccessful, display the an error alert on the UI.
    func createPostBoxAndSaveToCache() async {
        presentActivityAlert(message: "Creating postbox")
        let connectionId = UUID().uuidString

        do {
            guard let proof = ownershipProofs[sudo.id ?? ""] else {
                presentErrorAlertOnMain("Still fetching ownership proof. Try creating a postbox again. " , error: nil)
                return
            }

            _ = try await relayClient.createPostbox(withConnectionId: connectionId, ownershipProofToken: proof)
        } catch {
            presentErrorAlertOnMain("Failed to create postbox. " , error: error)
        }

        do {
            try KeychainPostboxIdStorage().store(postboxId: connectionId)
            self.dismiss(animated: true)
            Task {
                await self.updatePostboxView()
            }
        } catch {
            self.presentErrorAlert(message: "Failed to create postbox. " , error: error)
        }
    }
    
    /// Attempt to retrieve an updated list of the postbox IDs and refresh the table.
    /// If unsuccessful, does not refresh the table.
    func updatePostboxView() async {
        presentActivityAlert(message: "Fetching postboxes")
        if let updatedPostboxIds = await fetchPostboxIdsOrAlert() {
            postboxIds = updatedPostboxIds
        }
        self.dismiss(animated: true) {
            self.tableView.reloadData()
        }
    }
    
    /// Attempt to retrieve the list of postboxes from the relay.
    /// If unsuccessful, display an error alert on the UI.
    ///
    /// - Returns: List of postbox IDs or  nil.
    func fetchPostboxIdsOrAlert() async -> [String]? {
        guard let sudoId = sudo.id else {
            presentErrorAlertOnMain("Sudo does not have identifier.", error: nil)
            return nil
        }

        do {
            let postboxes = try await relayClient.listPostboxes(withSudoId: sudoId)
            return postboxes.map{$0.connectionId}
        } catch {
            presentErrorAlertOnMain("Could not fetch postboxes for sudo.", error: error)
            return nil
        }
    }

    /// Deletes postbox from cache and updates table view. Request to delete the postbox
    /// from the relay afterwards.
    ///
    /// If unsuccessful, present an error alert.
    ///
    /// - Parameter postBoxId: postbox ID to delete.
    func didSwipeToDeletePostbox(postBoxId: String) {
        presentActivityAlertOnMain("Deleting postbox")

        // Delete from cache and update UI on main thread
        KeychainPostboxIdStorage().delete(postBoxId: postBoxId)
        self.postboxIds = self.postboxIds.filter {$0 != postBoxId}
        self.dismiss(animated: true) {
            self.tableView.reloadData()
        }

        // Delete from relay on background thread
        Task(priority: .medium) {
            _ = try await relayClient.deletePostbox(withConnectionId: postBoxId)
        }
    }

    /// Get ownership proof of the Sudo.
    func fetchOwnershipProof(_ sudo: Sudo) {
        guard let sudoId = sudo.id else {
            presentErrorAlertOnMain("Could not fetch sudo id.", error: nil)
            return
        }
        if ownershipProofs[sudoId] != nil {
            return
        }

        Task(priority: .medium) {
            let proof = try await self.profilesClient.getOwnershipProof(sudo: sudo, audience: "sudoplatform.relay.postbox")
            self.ownershipProofs[sudoId] = proof
        }
    }
}
