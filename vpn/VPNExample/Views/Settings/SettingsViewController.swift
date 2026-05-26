//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoEntitlements

/// This View Controller presents a table view so that a user can navigate through each of the menu items.
///
/// - Links From:
///     - `MainMenuViewController`: A user taps the "Settings" button.
/// - Links To:
///     - `EntitlementsViewController`: If a user taps the "Entitlements" button, the`EntitlementsViewController` will
///         be presented so the user can view current status of Entitlements.
///     -  `ProtocolsController`: If a user taps the "Protocols" button, the `ProtocolsViewController`will be presented.
@MainActor
class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!
    @IBOutlet var settingsFooter: UIStackView!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var usernameTextView: ImmutableTextView!

    // MARK: - Supplementary

    /// Segues that are performed in `SettingsViewController`.
    enum Segue: String, Segueable {
        /// Used to navigate to the `EntitlementsViewController`.
        case navigateToEntitlements
        /// Used to navigate to the `ProtocolsViewController`.
        case navigateToProtocols
        /// Used to navigate to the `ProfilesViewController`.
        case navigateToProfiles
        /// Used to navigate back to the `RegistrationViewController`.
        case returnToRegistration
    }

    /// Menu items shown on the table view.
    enum MenuItem: Int, CaseIterable {
        /// Sudos table view item.
        case entitlements
        case protocols
        case profiles
        case deregister

        /// Title label of the table view item shown to the user.
        var displayTitle: String {
            switch self {
            case .entitlements:
                return "Entitlements"
            case .protocols:
                return "Protocols"
            case .profiles:
                return "Profiles"
            case .deregister:
                return "Deregister"
            }
        }

        /// The accessory type to display in the cell.
        var accessoryType: UITableViewCell.AccessoryType {
            switch self {
            case .entitlements, .protocols, .profiles:
                return .disclosureIndicator
            case .deregister:
                return .none
            }
        }

        /// The foreground color for the text in the cell's primary label.
        var textColor: UIColor {
            switch self {
            case .entitlements, .protocols, .profiles:
                return .label
            case .deregister:
                return .red
            }
        }
    }

    // MARK: - Properties

    /// Array of table view menu items used on the view.
    let tableData: [MenuItem] = MenuItem.allCases

    // MARK: - Properties: Computed

    /// Sudo user client used to perform de-registration operations.
    var userClient: SudoUserClient {
        AppDelegate.dependencies.userClient
    }

    /// Sudo entitlements client used to determine user entitlements.
    var userEntitlementsClient: SudoEntitlementsClient {
        AppDelegate.dependencies.entitlementsClient
    }

    /// Authenticator used to perform authentication during de-registration.
    var authenticator: Authenticator {
        AppDelegate.dependencies.authenticator
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureStackView()
        configureTableView()
    }

    // MARK: - Conformance: UITableViewDataSource

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return tableData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let menuItem = tableData[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "default", for: indexPath)
        cell.textLabel?.text = menuItem.displayTitle
        cell.textLabel?.textColor = menuItem.textColor
        cell.accessoryType = menuItem.accessoryType
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
        case .deregister:
            let alert = UIAlertController(
                title: "Deregister",
                message: "Are you sure you want to deregister? All user data will be deleted.",
                preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            alert.addAction(UIAlertAction(title: "Deregister", style: .default) { _ in
                Task { [weak self] in
                    await self?.deregister()
                }
            })
            present(alert, animated: true, completion: nil)
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    /// Configures the user name stack section
    func configureStackView() {
        usernameLabel.text = "Username:"
        Task {
            do {
                let externalUserId = try await userEntitlementsClient.getExternalId()
                usernameTextView.text = externalUserId
                usernameTextView.inputView = UIView()
            }
        }
    }

    // MARK: - Helpers

    /// Perform de-registration from the Sudo user client and clear all local data.
   func deregister() async {
       presentActivityAlert(message: "Deregistering")
       do {
           _ = try await AppDelegate.dependencies.authenticator.deregister()
           try await AppDelegate.dependencies.reset()
           dismissActivityAlert()
           // unwind back to registration view controller
           performSegue(withSegue: Segue.returnToRegistration, sender: self)
       } catch {
           dismissActivityAlert()
           presentErrorAlert(message: "Failed to deregister", error: error)
       }
   }
}
