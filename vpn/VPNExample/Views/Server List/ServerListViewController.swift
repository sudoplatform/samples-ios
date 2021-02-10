//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoVPN

class ServerListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    // MARK: - Outlets

    @IBOutlet var tableView: UITableView!

    // MARK: - Supplementary

    enum Segue: String, Segueable {
        case navigateToServerSelected
        case returnToMainMenu
    }

    // MARK: - Properties

    var vpnClient = AppDelegate.dependencies.vpnClient

    var serverList: [SudoVPNServer] = []

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        presentActivityAlert(message: "Loading Servers") { [weak self] in
            self?.loadServerList()
        }
        super.viewWillAppear(animated)
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let segueType = Segue(rawValue: segue.identifier ?? "")
        switch segueType {
        case .navigateToServerSelected:
            guard
                let serverSelected = segue.destination as? ServerSelectedViewController,
                let row = tableView.indexPathForSelectedRow?.row
            else {
                break
            }
            serverSelected.setServer(serverList[row])
        default:
            break
        }
    }

    // MARK: - Actions

    /// Action associated with returning to this view from a segue.
    @IBAction func returnToServerList(segue: UIStoryboardSegue) {}

    // MARK: - Operations

    func loadServerList() {
        vpnClient.listServers(cachePolicy: .remoteOnly) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch result {
                case let .success(servers):
                    self.updateServerList(servers)
                    self.tableView.reloadData()
                    self.dismissActivityAlert()
                case let .failure(error):
                    self.dismissActivityAlert()
                    self.presentErrorAlert(message: "Failure", error: error) { _ in
                        self.performSegue(withSegue: Segue.returnToMainMenu, sender: self)
                    }
                }
            }
        }
    }

    // MARK: - Helpers: Configuration

    /// Configures the table view.
    func configureTableView() {
        let serverTableViewCellNib = UINib(nibName: "ServerTableViewCell", bundle: .main)
        tableView.register(serverTableViewCellNib, forCellReuseIdentifier: "serverCell")
    }

    // MARK: - Helpers

    /// Update the server list of the view.
    ///
    /// Chooses a distinct server for each region, and then sorts the list by country, and then region.
    /// - Parameter servers: Raw server list from SDK.
    func updateServerList(_ servers: [SudoVPNServer]) {
        let servers = servers
            // Group servers by region
            .reduce([String: [SudoVPNServer]](), { dict, server in
                var dict = dict
                guard let region = server.region else {
                    NSLog("Server returned without region: \(server)")
                    return dict
                }
                if dict[region] != nil {
                    dict[region]?.append(server)
                } else {
                    dict[region] = [server]
                }
                return dict
            })
            // Get first server per region
            .compactMap({ $0.value.first })
            // Sort by country, then region
            .sorted(by: {
                if $0.country == $1.country {
                    if let lhsRegion = $0.region, let rhsRegion = $1.region {
                        return lhsRegion < rhsRegion
                    }
                }
                return $0.country < $1.country
            })
        self.serverList = servers
    }

    // MARK: - UITableView

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return serverList.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "serverCell") as? ServerTableViewCell else {
            NSLog("Failed to get serverCell")
            return ServerTableViewCell()
        }
        let server = serverList[indexPath.row]
        cell.setServer(server)
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        assert(indexPath.section == 0)
        performSegue(withSegue: Segue.navigateToServerSelected, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }

}
