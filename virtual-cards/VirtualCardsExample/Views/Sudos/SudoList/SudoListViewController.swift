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
        loadCacheSudosAndFetchRemote()
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
        loadCacheSudosAndFetchRemote()
    }

    // MARK: - Operations

    /// List Sudos from the Sudo profiles client.
    ///
    /// - Parameters:
    ///   - option: Option of either cache only or remote only when retrieving Sudos.
    ///   - success: Closure that executes on a successful retrieval of Sudos.
    func listSudos(option: SudoProfiles.ListOption, success: @escaping ([Sudo]) -> Void) {
        do {
            try profilesClient.listSudos(option: option) { result in
                switch result {
                case .success(let sudos):
                    success(sudos)
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.presentErrorAlert(message: "Failed to list Sudos", error: error)
                    }
                }
            }
        } catch {
            presentErrorAlert(message: "Failed to list Sudos", error: error)
        }
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
    func loadCacheSudosAndFetchRemote() {
        listSudos(option: .cacheOnly) { localSudos in
            DispatchQueue.main.async {
                self.sudos = localSudos
                self.tableView.reloadData()
            }

            self.listSudos(option: .remoteOnly) { remoteSudos in
                DispatchQueue.main.async {
                    self.sudos = remoteSudos
                    self.tableView.reloadData()
                }
            }
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
}
