//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoAdTrackerBlocker
import SafariServices

@MainActor
class RulesetsViewController: UITableViewController {
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    var rulesetList: [Ruleset] = []

    @UserDefaultsBackedWithDefault(key: "hasDisplayedHowToScreen", defaultValue: false)
    var hasDisplayedHowToScreen: Bool

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.parent?.navigationItem.title = "Rulesets"

        let helpImage = UIImage(systemName: "questionmark.circle")
        self.parent?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: helpImage, style: .plain, target: self, action: #selector(self.showHelpScreen))

        Task {
            try await listRulesets()
        }
        handleFirstTimeLaunch()
    }

    func handleFirstTimeLaunch() {
        guard self.hasDisplayedHowToScreen == false  else { return }
        self.showHelpScreen()
    }

    @objc func showHelpScreen() {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateViewController(identifier: "HowToViewController")
        self.present(vc, animated: true) {
            self.hasDisplayedHowToScreen = true
        }
    }

    private func listRulesets() async throws {
        activityIndicator.startAnimating()
        let rulesets = try await Clients.adTrackerBlockerClient.listRulesets()
        self.rulesetList.removeAll()
        for ruleset in rulesets {
            self.rulesetList.append(ruleset)
        }
        self.tableView.reloadData()
        self.activityIndicator.stopAnimating()
        // set activity indicator frame to zero in order to slide the tableview up
        self.activityIndicator.frame = CGRect.zero
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rulesetList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let ruleset = rulesetList[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.textLabel?.text = ruleset.name
        cell.detailTextLabel?.text = ruleset.type.rawValue
        cell.selectionStyle = .default
        if UserDefaults.standard.bool(forKey: ruleset.type.rawValue) {
            cell.accessoryType = .checkmark
        } else {
            cell.accessoryType = .none
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let ruleset = rulesetList[indexPath.row]
        let enabled = UserDefaults.standard.bool(forKey: ruleset.type.rawValue)
        Task {
            do {
                try await ContentBlockerHelper.toggleContentBlockerFor(ruleset: ruleset, enable: !enabled)
                if let cell = tableView.cellForRow(at: indexPath) {
                    cell.accessoryType = enabled ? .none : .checkmark
                }
            }
        }
    }
}
