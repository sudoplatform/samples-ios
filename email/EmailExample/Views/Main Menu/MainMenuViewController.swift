//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoProfiles

/// This View Controller presents a table view so that a user can navigate through each of the menu items.
///
/// - Links From:
///     - `RegistrationViewController`: A user successfully registers or signs in to the app.
/// - Links To:
///     - `SudoListViewController`: If a user taps the "Sudos" button, the`SudoListViewController` will
///         be presented so the user can view or choose to create Sudos.
///     - `RegistrationViewController`: If a user taps the "Deregister" button, the`RegistrationViewController` will
///         be presented so the user can perform registration again.
class MainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `MainMenuViewController`.
    enum Segue: String {
        /// Used to navigate to the `SudoListViewController`.
        case navigateToSudoList
    }

    /// Menu items shown on the table view.
    enum MenuItem: Int, CaseIterable {
        /// Sudos table view item.
        case sudos

        /// Title label of the table view item shown to the user.
        var displayTitle: String {
            switch self {
            case .sudos:
                return "Sudos"
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

    /// Sudo profiles client used to perform Sudo lifecycle operations.
    var profilesClient: SudoProfilesClient {
        return AppDelegate.dependencies.profilesClient
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
        configureNavigationBar()
    }

    // MARK: - Actions

    /// Action associated with tapping the "Deregister" button on the navigation bar.
    ///
    /// This action will execute the `deregister` operation. If de-registration succeeds, the`RegistrationViewController` will be presented to the user.
    @objc func didTapDeregisterButton() {
        showDeregisterAlert()
    }

    // MARK: - Operations

     /// Perform de-registration from the Sudo user client and clear all local data.
    func deregister() async {
        presentActivityAlert(message: "Deregistering")
        do {
            _ = try await authenticator.deregister()
            try await self.authenticator.reset()
            try self.profilesClient.reset()
            try self.profilesClient.generateEncryptionKey()
            try await self.userClient.reset()

            Task { @MainActor in
                self.dismissActivityAlert()
                self.performSegue(withIdentifier: "returnToRegistration", sender: self)
            }
        } catch {
            self.dismissActivityAlert()
            self.presentErrorAlert(message: "Failed to deregister", error: error)
        }
    }

    // MARK: - Helpers: Configuration

    /// Configure the view's navigation bar.
    ///
    /// Sets the left bar to a deregister button, which will execute the de-registration operation and sets the right bar to an info button which will
    /// display an informative alert.
    func configureNavigationBar() {
        let deregisterBarButton = UIBarButtonItem(title: "Deregister", style: .plain, target: self, action: #selector(didTapDeregisterButton))
        navigationItem.leftBarButtonItem = deregisterBarButton
    }

    /// Configures the table view used to display the menu items.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    // MARK: - Helpers

    /// Presents a `UIAlertController` providing a warning message and actions to either cancel or continue with the operation..
    func showDeregisterAlert() {
        let alert = UIAlertController(
            title: "Deregister",
            message: "Are you sure you want to deregister? All Sudos, email addresses and associated data will be deleted.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Deregister", style: .default) { _ in
            Task.detached(priority: .medium) {
                await self.deregister()
            }
        })
        present(alert, animated: true, completion: nil)
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
        case .sudos:
            performSegue(withIdentifier: Segue.navigateToSudoList.rawValue, sender: self)
        }
    }

}
