//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles
import SudoVirtualCards

/// This View Controller presents a list of `Sudos`.
///
/// - Links From:
///     - `MainMenuViewController`: A user chooses the "Sudos" option from the main menu table view which will show this view with the list of
///         Sudos created. The assigned alias is used as the text for each Sudo.
///  - Links To:
///     - `CreateSudoViewController`: If a user taps the "Create Sudo" button, the `CreateSudoViewController` will
///         be presented so the user can create a new Sudo.
///     - `CardListViewController`:  If a user chooses a `Sudo` from the list, the `CardListViewController` will be presented so the user can add a new card
///         to their sudo.
class SudoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets

    /// The table view that lists each Sudo.
    ///
    /// If no Sudos have been created before, then only the "Create Sudo" entry will be seen. This can be tapped to create a Sudo to
    /// append to the list.
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `SudoListViewController`.
    enum Segue: String {
        /// Navigate to the `CreateSudoViewController`.
        case navigateToCreateSudo
        /// Navigate to the `CardListViewController`.
        case navigateToCardList
    }

    // MARK: - Properties

    /// A list of `Sudos`
    private var sudos: [Sudo] = []

    // MARK: - Properties: Computed

    /// Sudo profiles client used to perform get and create Sudos.
    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            await loadCacheSudosAndFetchRemote()
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToCardList:
            guard let cardList = segue.destination as? CardListViewController, let row = tableView.indexPathForSelectedRow?.row else {
                break
            }
            cardList.sudo = sudos[row]
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    ///
    /// This action will ensure that the Sudo list is up to date when returning from views - e.g. `CreateSudoViewController`.
    @IBAction func returnToSudoList(segue: UIStoryboardSegue) {
        Task {
            await loadCacheSudosAndFetchRemote()
        }
    }

    // MARK: - Operations

    /// Delete a selected Sudo.
    ///
    /// - Parameter sudo: The selected Sudo to delete.
    @MainActor func deleteSudo(sudo: Sudo) async -> Bool {
        presentActivityAlert(message: "Deleting Sudo")
        var status = false
        do {
            let input = SudoDeleteInput(sudoId: sudo.id, version: sudo.version)
            _ = try await profilesClient.deleteSudo(input: input)
            status = true
            dismissActivityAlert()
        } catch {
            dismissActivityAlert()
            presentErrorAlert(message: "Failed to delete Sudo", error: error)
        }
        return status
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view used to display the navigation elements.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "create")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Helpers

    /// Attempts to load all Sudos from the device's cache first and then update via a remote call.
    @MainActor func loadCacheSudosAndFetchRemote() async {
        do {
            sudos = try await profilesClient.listSudos(cachePolicy: .cacheOnly)
            tableView.reloadData()

            sudos = try await profilesClient.listSudos(cachePolicy: .remoteOnly)
            tableView.reloadData()
        } catch {
            presentErrorAlert(message: "Failed to list Sudos", error: error)
        }
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sudos.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)
        let cell: UITableViewCell
        if indexPath.row == sudos.count {
            cell = tableView.dequeueReusableCell(withIdentifier: "create", for: indexPath)
            cell.textLabel?.text = "Create Sudo"
            cell.textLabel?.textColor = UIColor.systemBlue
            cell.accessoryView = UIImageView(image: UIImage.init(systemName: "plus"))
            cell.semanticContentAttribute = .forceRightToLeft
        } else {
            let sudo = sudos[indexPath.row]
            cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
            cell.textLabel?.textColor = UIColor.black
            cell.textLabel?.text = sudo.label ?? "New Sudo"
            cell.accessoryType = .disclosureIndicator
        }
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        if indexPath.row == sudos.count {
            performSegue(withIdentifier: Segue.navigateToCreateSudo.rawValue, sender: self)
        } else {
            performSegue(withIdentifier: Segue.navigateToCardList.rawValue, sender: tableView)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        if indexPath.row != sudos.count {
            let delete = UIContextualAction(style: .destructive, title: "Delete") { _, _, completion in
                Task {
                    await self.deleteSudoTapped(indexPath: indexPath, completion: completion)
                }
            }
            delete.backgroundColor = .red
            return UISwipeActionsConfiguration(actions: [delete])
        }
        return nil
    }

    @MainActor func deleteSudoTapped(indexPath: IndexPath, completion: @escaping (Bool) -> Void) async {
        let sudo = sudos[indexPath.row]
        do {
            presentActivityAlert(message: "Deleting Sudo")
            let input = SudoDeleteInput(sudoId: sudo.id, version: sudo.version)
            try await profilesClient.deleteSudo(input: input)
            dismissActivityAlert()
            sudos.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .automatic)
            completion(true)
        } catch {
            dismissActivityAlert()
            presentErrorAlert(message: "Failed to delete Sudo", error: error)
            completion(false)
        }
    }
}
