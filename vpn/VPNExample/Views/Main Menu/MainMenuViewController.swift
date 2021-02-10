//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

/// This View Controller presents a table view so that a user can navigate through each of the menu items.
///
/// - Links From:
///     - `RegistrationViewController`: A user successfully registers or signs in to the app.
/// - Links To:
///     - `ServerListViewController`: If a user taps the "Servers" button, the`ServerListViewController` will
///         be presented so the user can view available VPN Servers and choose to select one.
///     -  `SettingsViewController`: If a user taps the "Settings" button, the `SettingsViewController`will be presented.
///     - `RegistrationViewController`: If a user taps the "Deregister" button, the`RegistrationViewController` will
///         be presented so the user can perform registration again.
class MainMenuViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets

    /// Table view that lists the menu items.
    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    /// Segues that are performed in `MainMenuViewController`.
    enum Segue: String {
        /// Used to navigate to the `ServerListViewController`.
        case navigateToServerList
        /// Used to navigate to the `SettingsViewController`.
        case navigateToSettings
    }

    /// Menu items shown on the table view.
    enum MenuItem: Int, CaseIterable {
        /// Sudos table view item.
        case servers
        case settings

        /// Title label of the table view item shown to the user.
        var displayTitle: String {
            switch self {
            case .servers:
                return "Servers"
            case .settings:
                return "Settings"
            }
        }
    }

    // MARK: - Properties

    /// Array of table view menu items used on the view.
    let tableData: [MenuItem] = MenuItem.allCases

    /// Authenticator used to perform authentication during de-registration.
    var authenticator = AppDelegate.dependencies.authenticator

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
        configureNavigationBar()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigationBar()
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    @IBAction func returnToMainMenu(segue: UIStoryboardSegue) {}

    /// Action associated with tapping the "Deregister" button on the navigation bar.
    ///
    /// This action will execute the `deregister` operation. If de-registration succeeds, the`RegistrationViewController` will be presented to the user.
    @objc func didTapDeregisterButton() {
        showDeregisterAlert()
    }

    // MARK: - Operations

     /// Perform de-registration from the Sudo user client and clear all local data.
    func deregister() {
        presentActivityAlert(message: "Deregistering")
        do {
            try authenticator.deregister { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    // dismiss activity alert
                    self.dismissActivityAlert()
                    switch result {
                    case .success:
                        // after deregistering, clear all local data
                        do {
                            try AppDelegate.dependencies.reset()
                        } catch {
                            self.presentErrorAlert(message: "Failed to reset", error: error)
                        }

                        // unwind back to registration view controller
                        self.performSegue(withIdentifier: "returnToRegistration", sender: self)
                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to deregister", error: error)
                    }
                }
            }
        } catch let error {
            self.dismissActivityAlert {
                self.presentErrorAlert(message: "Failed to deregister", error: error)
            }
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view.
    func configureTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "default")
        tableView.tableFooterView = UIView()
    }

    /// Configure the view's navigation bar.
    ///
    /// Sets the left bar to a deregister button, which will execute the de-registration operation and sets the right bar to an info button which will
    /// display an informative alert.
    func configureNavigationBar() {
        let deregisterBarButton = UIBarButtonItem(title: "Deregister", style: .plain, target: self, action: #selector(didTapDeregisterButton))
        navigationItem.leftBarButtonItem = deregisterBarButton
    }

    // MARK: - Helpers

    /// Presents a `UIAlertController` providing a warning message and actions to either cancel or continue with the operation..
    func showDeregisterAlert() {
        let alert = UIAlertController(
            title: "Deregister",
            message: "Are you sure you want to deregister? All user data will be deleted.",
            preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Deregister", style: .default) { _ in
            self.deregister()
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
        case .servers:
            performSegue(withIdentifier: Segue.navigateToServerList.rawValue, sender: self)
        case .settings:
            performSegue(withIdentifier: Segue.navigateToSettings.rawValue, sender: self)
        }
    }

}
