//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

/// This View Controller presents a table view so that a user can navigate through each of the menu items.
///
/// - Links From:
///     - `MainMenuViewController`: A user taps the "Settings" button.
/// - Links To:
///     - `EntitlementsViewController`: If a user taps the "Entitlements" button, the`EntitlementsViewController` will
///         be presented so the user can view current status of Entitlements.
///     -  `ProtocolsController`: If a user taps the "Protocols" button, the `ProtocolsViewController`will be presented.
class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `SettingsViewController`.
    enum Segue: String, Segueable {
        /// Used to navigate to the `EntitlementsViewController`.
        case navigateToEntitlements
        /// Used to navigate to the `ProtocolsViewController`.
        case navigateToProtocols
        /// Used to navigate to the `ProfilesViewController`.
        case navigateToProfiles
    }

    /// Menu items shown on the table view.
    enum MenuItem: Int, CaseIterable {
        /// Sudos table view item.
        case entitlements
        case protocols
        case profiles

        /// Title label of the table view item shown to the user.
        var displayTitle: String {
            switch self {
            case .entitlements:
                return "Entitlements"
            case .protocols:
                return "Protocols"
            case .profiles:
                return "Profiles"
            }
        }
    }

    // MARK: - Properties

    /// Array of table view menu items used on the view.
    let tableData: [MenuItem] = MenuItem.allCases

    // MARK: - Properties: Computed

    /// Sudo user client used to perform de-registration operations.
    var userClient: SudoUserClient {
        return AppDelegate.dependencies.userClient
    }

    /// Authenticator used to perform authentication during de-registration.
    var authenticator: Authenticator {
        return AppDelegate.dependencies.authenticator
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Conformance: UITableViewDataSource

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menuItem = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        cell.textLabel?.text = menuItem.displayTitle
        cell.accessoryType = .disclosureIndicator
        return cell
    }

    // MARK: - Conformance: UITableViewDelegate

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section == 0 else {
            return
        }
        defer {
            tableView.deselectRow(at: indexPath, animated: true)
        }
        let menuItem = tableData[indexPath.row]
        switch menuItem {
        case .entitlements:
            performSegue(withSegue: Segue.navigateToEntitlements, sender: self)
        case .protocols:
            performSegue(withSegue: Segue.navigateToProtocols, sender: self)
        case .profiles:
            performSegue(withSegue: Segue.navigateToProfiles,
                sender: self)
        }
    }

}
