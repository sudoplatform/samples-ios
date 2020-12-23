//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoPasswordManager
import SudoProfiles

class VaultListViewController: UITableViewController {
    var vaults: [Vault] = []

    var passwordManagerClient: PasswordManagerClient!
    var sudoID: String!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vaults"
        passwordManagerClient = Clients.passwordManagerClient!

        self.tableView.register(LoginCell.self, forCellReuseIdentifier: "Login")

        self.tableView.delegate = self
        self.tableView.dataSource = self

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Settings", style: .plain, target: self, action: #selector(self.showSettings))
    }

    @objc func showSettings() {
        guard let settingsVC = UIStoryboard(name: "Settings", bundle: Bundle.main).instantiateViewController(identifier: "SettingsViewController") as? SettingsViewController else { return }
        let nav = UINavigationController(rootViewController: settingsVC)
        self.present(nav, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard !self.passwordManagerClient.isLocked() else {
            self.dismiss(animated: true, completion: nil)
            return
        }
        self.loadData()
    }

    func addNewVault() {
        self.presentActivityAlert(message: "Creating Vault")
        passwordManagerClient.createVault(sudoId: self.sudoID) { [weak self] result in
            runOnMain {
                switch result {
                case .success(let vault):
                    self?.dismiss(animated: false, completion: nil)
                    self?.vaults.append(vault)
                    self?.tableView.reloadData()
                case .failure(let error):
                    self?.dismiss(animated: false, completion: {
                        self?.presentErrorAlert(message: "Failed to create vault", error: error)
                    })
                }
            }
        }
    }

    func loadData() {
        passwordManagerClient.listVaults { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case .success(let vaults):
                    self.vaults = vaults.filter({ $0.belongsToSudo(id: self.sudoID) })
                    self.tableView.reloadData()
                case .failure(let error):
                    self.presentErrorAlert(message: "Failed to list vaults", error: error)
                }
            }
        }
    }

    @objc func lockPasswordManager() {
        passwordManagerClient.lock()
        // unwind back to unlock view controller
        self.dismiss(animated: true, completion: nil)
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
            addNewVault()
        } else {
            let vault = self.vaults[indexPath.row]
            let vc = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "LoginListViewController") as! LoginListViewController
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
            passwordManagerClient.deleteVault(withId: vaults[indexPath.row].id) { [weak self] result in
                runOnMain {
                    switch result {
                    case .success():
                        self?.dismiss(animated: false, completion: nil)
                        self?.vaults.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    case .failure(let error):
                        self?.dismiss(animated: false, completion: {
                            self?.presentErrorAlert(message: "Failed to delete vault", error: error)
                        })
                    }
                }
            }
        }
    }
}


