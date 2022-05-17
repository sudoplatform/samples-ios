//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AuthenticationServices
import SudoPasswordManager

@MainActor
class VaultItemListViewController: UITableViewController {

    var passwordManagerClient: SudoPasswordManagerClient!
    var vault: Vault!

    var vaultItems: [VaultItemListViewModel] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Vault Items"
        passwordManagerClient = Clients.passwordManagerClient!

        self.tableView.register(VaultItemCell.self, forCellReuseIdentifier: "Login")

        self.tableView.delegate = self
        self.tableView.dataSource = self

        let newPasswordButton = UIBarButtonItem(title: "Gen Password", style: .plain, target: self, action: #selector(self.newPassword))
        self.navigationItem.rightBarButtonItems = [newPasswordButton]

        // Add pull to refresh
        self.tableView.refreshControl = UIRefreshControl()
        self.tableView.refreshControl?.addTarget(self, action: #selector(self.pullToRefreshTriggered(control:)), for: .allEvents)
    }

    @objc func pullToRefreshTriggered(control: UIRefreshControl) {
        if control.isRefreshing {
            Task {
                try await self.passwordManagerClient.updateLocalDataStore()
                control.endRefreshing()

                // force a reload/fetch of vault data
                // load data will end refreshing
                self.loadData()
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.loadData()
    }

    func loadData() {
        Task {
            do {
                let items = try await passwordManagerClient.listVaultItems(inVault: vault)
                self.vaultItems = items.compactMap({ return $0 as? VaultItemListViewModel }).sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.displayTitle <= rhs.displayTitle
                })
                self.tableView.reloadData()
            }
            catch {
                self.presentErrorAlert(message: "Failed to list vault items", error: error)
            }
            self.tableView?.refreshControl?.endRefreshing()
        }
    }

    func sortVault(_ items: [VaultItemListViewModel]) -> [VaultItemListViewModel] {
        var favoritedItems: [VaultItemListViewModel] = []
        var defaultItems: [VaultItemListViewModel] = []
        items.forEach { item in
            if item.favorite {
                favoritedItems.append(item)
            } else {
                defaultItems.append(item)
            }
        }
        return favoritedItems + defaultItems
    }

    // Actions
    func newItemSelected() {
        let actionSheet = UIAlertController(title: "Create Vault Item", message: "", preferredStyle: .actionSheet)

        actionSheet.addAction(UIAlertAction(title: "Bank Account", style: .default, handler: { (_) in
            self.showBankAccount(account: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Credit Card", style: .default, handler: { (_) in
            self.showCreditCardDetails(card: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Login", style: .default, handler: { (_) in
            self.showLoginDetails(login: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Contact", style: .default, handler: { (_) in
            self.showContact(contact: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Passport", style: .default, handler: { (_) in
            self.showPassport(passport: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Membership", style: .default, handler: { (_) in
            self.showMembership(membership: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Driver's License", style: .default, handler: { (_) in
            self.showDriversLicense(driversLicense: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Social Security Number", style: .default, handler: { (_) in
            self.showSocialSecurityNumber(socialSecurityNumber: nil)
        }))

        actionSheet.addAction(UIAlertAction(title: "Not Now", style: .cancel, handler: nil))

        // For iPad
        actionSheet.popoverPresentationController?.sourceRect = self.tableView.visibleCells.last?.frame ?? self.view.frame
        actionSheet.popoverPresentationController?.sourceView = self.view

        self.present(actionSheet, animated: true, completion: nil)
    }

    func showCreditCardDetails(card: CreditCard?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let creditCardViewController = sb.instantiateViewController(identifier: "CreditCardViewController") as! CreditCardViewController
        creditCardViewController.vault = vault
        creditCardViewController.creditCardInput = card

        let nav = UINavigationController(rootViewController: creditCardViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    func showLoginDetails(login: Login?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let loginViewController = sb.instantiateViewController(identifier: "LoginViewController") as! LoginViewController
        loginViewController.vault = vault
        loginViewController.loginInput = login

        let nav = UINavigationController(rootViewController: loginViewController)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    func showBankAccount(account: BankAccount?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = sb.instantiateViewController(identifier: "BankAccountViewController") as! BankAccountViewController
        vc.vault = vault
        vc.bankAccountInput = account

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    func showContact(contact: Contact?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = sb.instantiateViewController(identifier: "ContactViewController") as! ContactViewController
        vc.vault = vault
        vc.contactInput = contact

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    func showPassport(passport: Passport?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = sb.instantiateViewController(identifier: "PassportViewController") as! PassportViewController
        vc.vault = vault
        vc.passportInput = passport

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    func showMembership(membership: Membership?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = sb.instantiateViewController(identifier: "MembershipViewController") as! MembershipViewController
        vc.vault = vault
        vc.membershipInput = membership

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    func showDriversLicense(driversLicense: DriversLicense?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = sb.instantiateViewController(identifier: "DriversLicenseViewController") as! DriversLicenseViewController
        vc.vault = vault
        vc.driversLicenseInput = driversLicense

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    func showSocialSecurityNumber(socialSecurityNumber: SocialSecurityNumber?) {
        let sb = UIStoryboard(name: "Main", bundle: Bundle.main)
        let vc = sb.instantiateViewController(identifier: "SSNViewController") as! SSNViewController
        vc.vault = vault
        vc.socialSecurityNumberInput = socialSecurityNumber

        let nav = UINavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .fullScreen
        self.present(nav, animated: true, completion: nil)
    }

    @objc func newPassword() {
        let generatePasswordController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "GeneratePasswordViewController")
        let nav = UINavigationController(rootViewController: generatePasswordController)

        self.present(nav, animated: true, completion: nil)
    }


    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }
        else {
            return vaultItems.count
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "createCell", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Login", for: indexPath) as! VaultItemCell
            let sortedItems = sortVault(self.vaultItems)
            let item = sortedItems[indexPath.row]

            cell.textLabel?.text = item.displayTitle
            Task {
                cell.detailTextLabel?.text = await item.displaySubtitle
            }

            if item.favorite {
                cell.tintColor = .black
            } else {
                cell.tintColor = .systemBlue
            }

            if let hexString = item.hexColor {
                let color = UIColor(hexString: hexString)
                cell.backgroundColor = color
            } else {
                cell.backgroundColor = .systemBackground
            }

            cell.typeImage = item.displayTypeImage
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.section == 0 {
            newItemSelected()
        } else {
            let sortedItems = sortVault(self.vaultItems)
            let item = sortedItems[indexPath.row]

            if let login = item as? Login {
                self.showLoginDetails(login: login)
            }
            else if let card = item as? CreditCard {
                self.showCreditCardDetails(card: card)
            }
            else if let bankAccount = item as? BankAccount {
                self.showBankAccount(account: bankAccount)
            }
            else if let contact = item as? Contact {
                self.showContact(contact: contact)
            }
            else if let passport = item as? Passport {
                self.showPassport(passport: passport)
            }
            else if let membership = item as? Membership {
                self.showMembership(membership: membership)
            }
            else if let driversLicense = item as? DriversLicense {
                self.showDriversLicense(driversLicense: driversLicense)
            }
            else if let socialSecurityNumber = item as? SocialSecurityNumber {
                self.showSocialSecurityNumber(socialSecurityNumber: socialSecurityNumber)
            }
        }
    }

    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // All rows can be edited except the + cell in section 0.
        return indexPath.section != 0
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if indexPath.row < vaultItems.count && editingStyle == .delete {
            // remove vault item
            let sortedItems = sortVault(self.vaultItems)
            let item = sortedItems[indexPath.row]
            Task {
                do {
                    _ = try await passwordManagerClient.removeVaultItem(id: item.id, from: vault)
                    self.vaultItems.remove(at: indexPath.row)
                    tableView.deleteRows(at: [indexPath], with: .fade)
                }
                catch {
                    self.presentErrorAlert(message: "Failed to remove vault item", error: error)
                }
            }
        }
    }
}


// Default cell in case we want to change it.
class VaultItemCell: UITableViewCell {

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    var typeImage: UIImage? {
        set {
            self.accessoryView = UIImageView(image: newValue)
        }
        get {
            return (self.accessoryView as? UIImageView)?.image
        }
    }
}


protocol VaultItemListViewModel {
    var displayTitle: String { get }
    var displaySubtitle: String { get async }
    var displayTypeImage: UIImage? { get }
    var id: String { get }
    var favorite: Bool { get }
    var hexColor: String? { get }
}


extension Login: VaultItemListViewModel {
    var displayTitle: String { return self.name }
    var displaySubtitle: String { return self.url ?? ""}
    var displayTypeImage: UIImage? { return UIImage(systemName: "lock")?.withRenderingMode(.alwaysTemplate) }
}


extension CreditCard: VaultItemListViewModel {
    var displayTitle: String  { return self.name }
    var displaySubtitle: String {
        get async {
            return (try? await self.cardNumber?.getValue()) ?? ""
        }
    }
    var displayTypeImage: UIImage? { return UIImage(systemName: "creditcard")?.withRenderingMode(.alwaysTemplate) }
}

extension BankAccount: VaultItemListViewModel {
    var displayTitle: String { return self.name }
    var displaySubtitle: String { return self.bankName ?? "" }
    var displayTypeImage: UIImage? { return UIImage(systemName: "dollarsign.circle")?.withRenderingMode(.alwaysTemplate) }
}

extension Contact: VaultItemListViewModel {
    var displayTitle: String { return self.name }
    var displaySubtitle: String { return self.phone ?? "" }
    var displayTypeImage: UIImage? { return UIImage(systemName: "person.crop.circle")?.withRenderingMode(.alwaysTemplate) }
}

extension Passport: VaultItemListViewModel {
    var displayTitle: String { return self.name }
    var displaySubtitle: String { return self.issuingCountry ?? "" }
    var displayTypeImage: UIImage? { return UIImage(systemName: "character.book.closed")?.withRenderingMode(.alwaysTemplate) }
}

extension Membership: VaultItemListViewModel {
    var displayTitle: String { return self.name }
    var displaySubtitle: String { return self.memberID ?? "" }
    var displayTypeImage: UIImage? { return UIImage(systemName: "person.text.rectangle")?.withRenderingMode(.alwaysTemplate) }
}

extension DriversLicense: VaultItemListViewModel {
    var displayTitle: String { return self.name }
    var displaySubtitle: String { return self.country ?? "" }
    var displayTypeImage: UIImage? { return UIImage(systemName: "rectangle.inset.topleft.filled")?.withRenderingMode(.alwaysTemplate) }
}

extension SocialSecurityNumber: VaultItemListViewModel {
    var displayTitle: String { return self.name }
    var displaySubtitle: String { return "" }
    var displayTypeImage: UIImage? { return UIImage(systemName: "dock.arrow.up.rectangle")?.withRenderingMode(.alwaysTemplate) }
}

func runOnMain(_ work: @escaping () -> Void) {
    DispatchQueue.main.async(execute: work)
}
