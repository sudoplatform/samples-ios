//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AuthenticationServices
import SudoPasswordManager

class LoginListViewController: UITableViewController {

    var passwordManagerClient: PasswordManagerClient!
    var vault: Vault!

    var logins: [VaultLogin] = []

    // When the extension is launched it will pass in identifiers to look for. If we pass it in here, then we can
    // filter our list, or we can pass off an identifer to the new login controller
    var serviceIdentifiers: [ASCredentialServiceIdentifier]?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Logins"
        passwordManagerClient = Clients.passwordManagerClient!

        self.tableView.register(LoginCell.self, forCellReuseIdentifier: "Login")

        self.tableView.delegate = self
        self.tableView.dataSource = self

        let newPasswordButton = UIBarButtonItem(title: "Gen Password", style: .plain, target: self, action: #selector(self.newPassword))
        self.navigationItem.rightBarButtonItems = [newPasswordButton]
    }

    func addNewLogin() {

        let newItemController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "NewLoginViewController") as! NewLoginViewController
        newItemController.vault = vault
        newItemController.serviceIdentifiers = self.serviceIdentifiers
        let nav = UINavigationController(rootViewController: newItemController)

        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    @objc func newPassword() {
        let generatePasswordController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "GeneratePasswordViewController")
        let nav = UINavigationController(rootViewController: generatePasswordController)

        self.present(nav, animated: true, completion: nil)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadData()
    }

    func loadData() {
        passwordManagerClient.listVaultItems(inVault: vault) { [weak self] result in
            switch result {
            case .success(let logins):
                if let vaultLogins = logins as? [VaultLogin] {
                    self?.logins = vaultLogins
                    self?.tableView.reloadData()
                }
            case .failure(let error):
                self?.presentErrorAlert(message: "Failed to list vault items", error: error)
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return logins.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == logins.count {
            return tableView.dequeueReusableCell(withIdentifier: "createCell", for: indexPath)
        } else {
            let login = self.logins[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "Login", for: indexPath)
            cell.textLabel?.text = login.name
            cell.detailTextLabel?.text = login.url
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == logins.count {
            addNewLogin()
        } else {
            let login = self.logins[indexPath.row]

            let editLoginController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "EditLoginViewController") as! EditLoginViewController
            editLoginController.vault = vault
            editLoginController.login = login
            navigationController?.pushViewController(editLoginController, animated: true)
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.row < logins.count && editingStyle == .delete {
            // remove vault item
            passwordManagerClient.removeVaultItem(id: logins[indexPath.row].id, from: vault) { [weak self] removeResult in
                runOnMain {
                    switch removeResult {
                    case .success():
                        guard let self = self else { return }
                        self.logins.remove(at: indexPath.row)
                        tableView.deleteRows(at: [indexPath], with: .fade)
                    case .failure(let error):
                        self?.presentErrorAlert(message: "Failed to remove vault item", error: error)
                    }
                }
            }
        }
    }
}

// Default cell in case we want to change it.
class LoginCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }
}

func runOnMain(_ work: @escaping () -> Void) {
    DispatchQueue.main.async(execute: work)
}
