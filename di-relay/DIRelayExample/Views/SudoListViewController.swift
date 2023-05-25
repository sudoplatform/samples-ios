//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles
import SudoUser
import SudoDIRelay

class SudoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ExitHandling {

    // MARK: - Supplementary

    /// Segues that are performed in `SudoListViewController`.
    enum Segue: String {
        /// Navigate to the `CreateSudoViewController`.
        case navigateToCreateSudo

        /// Navigates to `PostboxViewController`
        case navigateToPostboxes

        /// Navigate to the `RegistrationViewController`.
        case unwindToRegister
    }

    // MARK: - Properties

    /// A list of `Sudos`
    var sudos: [Sudo] = []

    /// Prepared ownership proof for chosen Sudo.
    private var ownershipProofForPostbox: String?

    // MARK: - Properties: Computed

    /// Relay client required to conform to ExitHandling.
    var relayClient: SudoDIRelayClient {
        return AppDelegate.dependencies.sudoDIRelayClient
    }

    /// User client required to conform to ExitHandling.
    var sudoUserClient: SudoUserClient {
        return AppDelegate.dependencies.sudoUserClient
    }

    /// Sudo profiles client used to perform get and create Sudos.
    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }

    // MARK: - Outlets

    /// The table view that lists each Sudo.
    ///
    /// If no Sudos have been created before, then only the "Create Sudo" entry will be seen. This can be tapped to create a Sudo to
    /// append to the list.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        // configureTableView()
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task(priority: .medium) {
            await loadCacheSudosAndFetchRemote()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToPostboxes:
            guard let row = tableView.indexPathForSelectedRow?.row else {
                break
            }

            let destination = segue.destination as! PostboxesViewController
            destination.sudo = sudos[row-1]
        case .unwindToRegister:
            _ = segue.destination as! RegistrationViewController
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

    // MARK: - Operations

    /// Delete a selected Sudo.
    ///
    /// - Parameter sudo: The selected Sudo to delete.
    /// - Returns: true if successfully deleted, false if not.
    func deleteSudo(sudo: Sudo) async -> Bool {
        do {
            presentActivityAlertOnMain("Deleting Sudo")
            try await profilesClient.deleteSudo(sudo: sudo)
            self.dismissActivityAlert()
            return true
        } catch {
            presentErrorAlert(message: "Failed to delete Sudo", error: error)
            return false
        }
    }

    // MARK: - Helpers

    /// Attempts to load all Sudos from the device's cache first and then update via a remote call.
    func loadCacheSudosAndFetchRemote() async {
        do {
            sudos = try await profilesClient.listSudos(option: .cacheOnly)
            sudos = try await profilesClient.listSudos(option: .remoteOnly)
        } catch {
            presentErrorAlert(message: "Failed to list Sudos", error: error)
        }
        tableView.reloadData()
    }

    // MARK: - Table View

    /// Return the number of table rows.
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sudos.count + 1
    }

    /// Return the title of the table.
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Your Sudos"
    }

    /// Return a table cell either containing the button to create a sudo or a label containing the sudo IDs.
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "createSudoCell", for: indexPath)
        } else {
            let sudoToDisplay = sudos[indexPath.row - 1]
            let cell = tableView.dequeueReusableCell(withIdentifier: "sudoCell", for: indexPath)
            cell.textLabel?.text = sudoToDisplay.label
            return cell
        }
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        if indexPath.row == 0 {
            /// Clicked Create Sudo.
            performSegue(withIdentifier: Segue.navigateToCreateSudo.rawValue, sender: self)

        } else {
            /// Clicked on an existing Sudo
            performSegue(withIdentifier: Segue.navigateToPostboxes.rawValue, sender: self)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row != sudos.count {
            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, _ in
                let sudo = self.sudos[indexPath.row]
                // Delete sudo concurrently and update table and list in main thread
                Task(priority: .medium) {
                    if await self.deleteSudo(sudo: sudo) {
                        self.sudos.remove(at: indexPath.row)
                        self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    }
                }
            }
            delete.backgroundColor = .red
            return UISwipeActionsConfiguration(actions: [delete])
        }
        return nil
    }
}
