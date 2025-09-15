//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay
import SudoUser
import SudoProfiles

class PostboxesViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ExitHandling {

    // MARK: - Supplementary

    /// Segues that are performed in `SudoListViewController`.
    enum Segue: String {

       /// Navigate to `ConnectionViewController`.
        case navigateToPostbox

        /// Navigate to the `RegistrationViewController`.
        case unwindToRegistration
    }

    // MARK: - Properties

    var sudo: Sudo!
    var postboxIds: [String] = []
    var ownershipProofs: [String: String] = [:]
    private var presentedActivityAlert: UIAlertController?
    var createPostboxTask: Task<Void, Never>?

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
        Task { @MainActor in
            await updatePostboxView()
            await fetchOwnershipProof(sudo)
        }
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
            createPostboxTask = Task {
                await self.createPostbox()
            }
        } else {
            // Clicked on an existing Postbox ID
            let postboxId = postboxIds[indexPath.row - 1]
            performSegue(withIdentifier: Segue.navigateToPostbox.rawValue, sender: postboxId)
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
            let action = UIContextualAction(style: .normal, title: "Delete") { [weak self] (_, _, completionHandler) in
                Task { @MainActor in
                    await self?.didSwipeToDeletePostbox(postboxId: postBoxId)
                    completionHandler(true)
                }
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
        case .navigateToPostbox:
            let destination = segue.destination as! PostboxViewController
            destination.postboxId = sender as? String ?? ""
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
    /// If successful, display the new postbox id in the table.
    /// If unsuccessful, display the an error alert on the UI.
    @MainActor func createPostbox() async {
        await presentActivityAlertOnMain("Creating postbox")
        let connectionId = UUID().uuidString

        do {
            guard let proof = ownershipProofs[sudo.id] else {
                await presentErrorAlertOnMain("Still fetching ownership proof. Try creating a postbox again. ", error: nil)
                return
            }

            _ = try await relayClient.createPostbox(
                withConnectionId: connectionId,
                ownershipProofToken: proof,
                isEnabled: true)
            if let updatedPostboxIds = await fetchPostboxIdsOrAlert() {
                postboxIds = updatedPostboxIds
            }
            await dismissActivityAlert()
            tableView.reloadData()
        } catch {
            await presentErrorAlertOnMain("Failed to create postbox. ", error: error)
        }

    }

    /// Attempt to retrieve an updated list of the postbox IDs and refresh the table.
    /// If unsuccessful, does not refresh the table.
    @MainActor func updatePostboxView() async {
        await presentActivityAlertOnMain("Fetching postboxes")
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
    @MainActor func fetchPostboxIdsOrAlert() async -> [String]? {
        do {
            let postboxes = try await relayClient.listPostboxes(limit: 20, nextToken: nil)
            return postboxes.items.map {$0.id}
        } catch {
            await presentErrorAlertOnMain("Could not fetch postboxes for sudo.", error: error)
            return nil
        }
    }

    /// Deletes postbox from cache and updates table view. Request to delete the postbox
    /// from the relay afterwards.
    ///
    /// If unsuccessful, present an error alert.
    ///
    /// - Parameter postboxId: postbox ID to delete.
    @MainActor func didSwipeToDeletePostbox(postboxId: String) async {
        await presentActivityAlertOnMain("Deleting postbox")

        self.postboxIds = self.postboxIds.filter {$0 != postboxId}
        self.dismiss(animated: true) {
            self.tableView.reloadData()
        }

        // Delete from relay on background thread
        Task(priority: .medium) {
            _ = try await relayClient.deletePostbox(withPostboxId: postboxId)
        }
    }

    /// Get ownership proof of the Sudo.
    @MainActor func fetchOwnershipProof(_ sudo: Sudo) async {
        let sudoId = sudo.id

        if ownershipProofs[sudoId] != nil {
            return
        }

        Task(priority: .medium) {
            let proof = try await self.profilesClient.getOwnershipProof(sudo: sudo, audience: "sudoplatform.relay.postbox")
            self.ownershipProofs[sudoId] = proof
        }
    }
}
