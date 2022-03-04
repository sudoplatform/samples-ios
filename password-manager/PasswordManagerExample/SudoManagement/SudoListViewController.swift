//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles

import UIKit
import SudoProfiles

@MainActor
class SudoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private var sudos: [Sudo] = []

    var sudoSelected: ((Sudo) -> Void)?

    var sudoProfilesClient: SudoProfilesClient!

    static func createWith(
        sudoProfilesClient: SudoProfilesClient,
        sudoSelected: @escaping ((Sudo) -> Void)
    ) -> SudoListViewController {
        let storyboard = UIStoryboard(name: "SudoManagement", bundle: Bundle.main)
        let vc = storyboard.instantiateInitialViewController() as! SudoListViewController
        vc.sudoProfilesClient = sudoProfilesClient
        vc.sudoSelected = sudoSelected
        return vc
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        Task {
            self.sudos = try await self.listSudos(option: .cacheOnly)
            self.tableView.reloadData()
            self.sudos = try await self.listSudos(option: .remoteOnly)
            self.tableView.reloadData()
        }
    }

    private func listSudos(option: SudoProfiles.ListOption) async throws -> [Sudo] {
        let sudos = try await sudoProfilesClient.listSudos(option: option)
        // This example creates sudos without claims (i.e. all attributes nil except id).  an id is an ugly display name
        // so this assigns a number to each sudo based on their creation date.
        // The general approach is to sort by createdAt, then create a copy of each sudo with label of "Sudo X".
        // Since these claims are assigned locally they aren't encrypted and can be read.
        var count = 0
        let sudosWithSelfAssignedTitle: [Sudo] = sudos.sorted { (lhs, rhs) -> Bool in
            return lhs.createdAt < rhs.createdAt
        }
            .map {
                let copy = Sudo(id: $0.id ?? "", version: $0.version, createdAt: $0.createdAt, updatedAt: $0.updatedAt, title: $0.title, firstName: $0.firstName, lastName: $0.lastName, label: "Sudo \(count)", notes: $0.notes, avatar: $0.avatar)
                count += 1
                return copy
            }
        return sudosWithSelfAssignedTitle
    }

    private func navigateToLoginScreen() {
        self.performSegue(withIdentifier: "returnToRegistration", sender: self)
    }

    @IBAction func infoTapped() {
        let alert = UIAlertController(title: "What is a Sudo?", message: "A Sudo is a digital identity created and owned by a real person. Vaults must belong to a Sudo.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Learn More", style: .default) { action in
            let docURL = URL(string: "https://docs.sudoplatform.com/concepts/sudo-digital-identities")!
            UIApplication.shared.open(docURL, options: [:], completionHandler: nil)
        })
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sudos.count + 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        assert(indexPath.section == 0)

        if indexPath.row == sudos.count {
            return tableView.dequeueReusableCell(withIdentifier: "createCell", for: indexPath)
        } else {
            let sudo = sudos[indexPath.row]
            let cell = tableView.dequeueReusableCell(withIdentifier: "sudoCell", for: indexPath)
            cell.textLabel?.text = sudo.label ?? sudo.id ?? "Unknown Sudo"
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        if indexPath.row == sudos.count {
            self.createSudoWithoutClaims()
        } else {
            self.sudoSelected?(sudos[indexPath.row])
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "navigateToCreateSudo":
            return false
        default:
            return true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToCreateSudo":
            let vc = segue.destination as! CreateSudoViewController
            vc.sudoProfilesClient = self.sudoProfilesClient
        default: break
        }
    }

    @IBAction func returnToSudoList(segue: UIStoryboardSegue) {}

    func createSudoWithoutClaims() {
        // Create an empty sudo without claims (all parameters nil).
        // This allows testing across multiple devices without transferring keys belonging to the `SudoProfiles` SDK.
        let sudo = Sudo(title: nil, firstName: nil, lastName: nil, label: nil, notes: nil, avatar: nil)
        presentActivityAlert(message: "Creating sudo")
        Task {
            do {
                _ = try await sudoProfilesClient.createSudo(sudo: sudo)
                await self.dismiss(animated: true)
                let sudos = try await self.listSudos(option: .remoteOnly)
                self.sudos = sudos
                self.tableView.reloadData()
            } catch let error {
                await dismiss(animated: true)
                self.presentErrorAlert(message: "Failed to create sudo", error: error)
            }
        }
    }
}
