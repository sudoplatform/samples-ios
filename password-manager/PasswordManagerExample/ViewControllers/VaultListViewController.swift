//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager
import SudoProfiles

@MainActor
class VaultListViewController: UITableViewController {
    var vaults: [Vault] = []

    var passwordManagerClient: SudoPasswordManagerClient!
    var sudoID: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vaults"
        passwordManagerClient = Clients.passwordManagerClient!

        self.tableView.register(VaultItemCell.self, forCellReuseIdentifier: "Login")

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(self.showSettings))

        // Add pull to refresh for vault list
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.addTarget(self, action: #selector(self.pullToRefreshTriggered(control:)), for: .allEvents)
    }

    @objc func pullToRefreshTriggered(control: UIRefreshControl) {
        if control.isRefreshing {
            Task {
                try? await self.passwordManagerClient.updateLocalDataStore()
                control.endRefreshing()
                await self.loadData()
            }
        }
    }

    @objc func showSettings() {
        guard let settingsVC = UIStoryboard(name: "Settings", bundle: Bundle.main).instantiateViewController(identifier: "SettingsViewController") as? SettingsViewController else { return }
        let nav = UINavigationController(rootViewController: settingsVC)
        self.present(nav, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            guard await !self.passwordManagerClient.isLocked() else {
                self.dismiss(animated: true, completion: nil)
                return
            }
            await self.loadData()
        }
    }

    func addNewVault() async {
        self.presentActivityAlert(message: "Creating Vault")
        Task {
            do {
                let vault = try await passwordManagerClient.createVault(sudoId: self.sudoID)
                self.dismiss(animated: false, completion: nil)
                self.vaults.append(vault)
                self.tableView.reloadData()
            }
            catch {
                self.dismiss(animated: false, completion: {
                    self.presentErrorAlert(message: "Failed to create vault", error: error)
                })
            }
        }
    }

    func loadData() async {
        Task {
            do {
                let vaults = try await passwordManagerClient.listVaults()
                self.tableView.refreshControl?.endRefreshing()
                self.vaults = vaults.filter({ $0.belongsToSudo(id: self.sudoID) }).sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.createdAt <= rhs.createdAt
                })
                self.tableView.reloadData()
            }
            catch {
                self.presentErrorAlert(message: "Failed to list vaults", error: error)
            }
        }
    }

    @objc func lockPasswordManager() {
        Task {
            await passwordManagerClient.lock()
            self.dismiss(animated: true, completion: nil)
        }
    }

    @objc func showSecretCode() {
        let code = passwordManagerClient.getSecretCode()
        let alert = UIAlertController(title: "Secret Code", message: "\(code ?? "")\n Clear Data to copy the code and require code entry for unlock", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Copy to clipboard", style: .default, handler: { (action) in
            UIPasteboard.general.string = code
        }))
        alert.addAction(UIAlertAction(title: "Clear Data", style: .default, handler: { (action) in
            UIPasteboard.general.string = code
            do {
                try Clients.keyManager.removeAllKeys()
            } catch {
                self.presentErrorAlert(message: "Failed to remove keys", error: error)
            }
            self.lockPasswordManager()
        }))
        present(alert, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return vaults.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == vaults.count {
            return tableView.dequeueReusableCell(withIdentifier: "createCell", for:     indexPath)
        } else {
            let vault = self.vaults[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "Login", for: indexPath)
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
            cell.textLabel?.text = formatter.string(from: vault.createdAt)
            return cell
        }

    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == vaults.count {
            Task {
                await addNewVault()
            }
        } else {
            let vault = self.vaults[indexPath.row]
            let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "LoginListViewController") as! VaultItemListViewController
            vc.vault = vault
            navigationController?.pushViewController(vc, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.row < vaults.count && editingStyle == .delete {
            self.presentActivityAlert(message: "Deleting Vault")
            Task {
                do {
                    let id = vaults[indexPath.row].id
                    _ = try await passwordManagerClient.deleteVault(withId: id)
                    self.dismiss(animated: false, completion: nil)
                    self.vaults.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
                catch {
                    self.dismiss(animated: false, completion: {
                        self.presentErrorAlert(message: "Failed to delete vault", error: error)
                    })
                }
            }
        }
    }
}


