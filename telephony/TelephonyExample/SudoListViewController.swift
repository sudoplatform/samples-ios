//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoProfiles

class SudoListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    @IBOutlet weak var tableView: UITableView!
    private var sudos: [Sudo] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

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

    private func listSudos(option: SudoProfiles.ListOption, onSuccess: @escaping ([Sudo]) -> Void) {
        let sudoProfilesClient = (UIApplication.shared.delegate as! AppDelegate).sudoProfilesClient!

        do {
            try sudoProfilesClient.listSudos(option: option) { result in
                switch result {
                case .success(let sudos):
                    onSuccess(sudos)
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

    @IBAction func deregisterTapped(_ sender: UIBarButtonItem) {
        let alert = UIAlertController(title: "Deregister", message: "Are you sure you want to deregister? All Sudos, numbers, and associated data will be deleted.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Deregister", style: .default) { _ in
            self.deregister()
        })
        present(alert, animated: true, completion: nil)
    }

    func deregister() {
        let authenticator = (UIApplication.shared.delegate as! AppDelegate).authenticator!
        let sudoProfilesClient = (UIApplication.shared.delegate as! AppDelegate).sudoProfilesClient!
        let telephonyClient = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        presentActivityAlert(message: "Deregistering")

        do {
            try authenticator.userClient.deregister { result in
                DispatchQueue.main.async {
                    // dismiss activity alert
                    self.dismiss(animated: true, completion: nil)

                    switch result {
                    case .success:
                        // after deregistering, clear all local data
                        do {
                            try authenticator.userClient.reset()
                            try sudoProfilesClient.reset()
                            try telephonyClient.reset()
                        } catch let error {
                            self.presentErrorAlert(message: "Failed to deregister", error: error)
                        }

                        // unwind back to registration view controller
                        self.performSegue(withIdentifier: "returnToRegistration", sender: self)
                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to deregister", error: error)
                    }
                }
            }
        } catch let error {
            self.dismiss(animated: true) {
                self.presentErrorAlert(message: "Failed to deregister", error: error)
            }
        }
    }

    @IBAction func infoTapped() {
        let alert = UIAlertController(title: "What is a Sudo?", message: "Phone numbers must belong to a Sudo. A Sudo is a digital identity created and owned by a real person.", preferredStyle: .alert)
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
            cell.textLabel?.text = sudo.label ?? "New Sudo"
            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)

        if indexPath.row == sudos.count {
            performSegue(withIdentifier: "navigateToCreateSudo", sender: self)
        } else {
            performSegue(withIdentifier: "navigateToPhoneNumberList", sender: sudos[indexPath.row])
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToCreateSudo": break
        case "navigateToPhoneNumberList":
            let phoneNumberList = segue.destination as! PhoneNumberListViewController
            let sudo = sender as! Sudo
            phoneNumberList.sudo = sudo
        default: break
        }
    }

    @IBAction func returnToSudoList(segue: UIStoryboardSegue) {}
}
