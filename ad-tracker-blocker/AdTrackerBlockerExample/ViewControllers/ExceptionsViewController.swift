//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoAdTrackerBlocker
import SafariServices

class ExceptionsViewController: UITableViewController {

    var exceptionList: [BlockingException] = []

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.parent?.navigationItem.title = "Exceptions"
        let removeAllButton = UIBarButtonItem(title: "Remove All", style: .plain, target: self, action: #selector(removeAllExceptions))
        self.parent?.navigationItem.rightBarButtonItem = removeAllButton
        listExceptions()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.parent?.navigationItem.rightBarButtonItem = nil
    }

    func listExceptions() {
        exceptionList = Clients.adTrackerBlockerClient.getExceptions()
        tableView.reloadData()
    }

    func addException() {
        let alert = UIAlertController(title: "Add Exception", message: nil, preferredStyle: .alert)
        alert.modalPresentationStyle = .overFullScreen
        alert.addTextField { (field) in
            field.placeholder = "Exception URL"
        }
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            if let url = alert.textFields?[0].text {
                if !url.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Clients.adTrackerBlockerClient.addExceptions([BlockingException(url)])
                    self?.listExceptions()
                    self?.notifyExtensions()
                }
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }

    @objc func removeAllExceptions() {
        Clients.adTrackerBlockerClient.removeAllExceptions()
        listExceptions()
        notifyExtensions()
    }

    // notify all extensions to update
    private func notifyExtensions() {
        Clients.adTrackerBlockerClient.listRulesets { (result) in
            switch result {
            case .success(let rulesets):
                for ruleset in rulesets {
                    if UserDefaults.standard.bool(forKey: ruleset.type.rawValue) {
                        ContentBlockerHelper.toggleContentBlockerFor(ruleset: ruleset, enable: true)
                    }
                }
            case .failure(let error):
                print("Failed to list rulesets: \(error)")
            }
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return exceptionList.count + 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "AddCell", for: indexPath)
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ??
                UITableViewCell(style: .default, reuseIdentifier: "cell")
            let exception = exceptionList[indexPath.row - 1]
            cell.textLabel?.text = exception
            cell.accessoryView = UIImageView(image: UIImage(systemName: "laptopcomputer"))
            return cell
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.row == 0 {
            addException()
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete && indexPath.row > 0 {
            Clients.adTrackerBlockerClient.removeExceptions([exceptionList[indexPath.row - 1]])
            exceptionList.remove(at: indexPath.row - 1)
            tableView.deleteRows(at: [indexPath], with: .fade)
            notifyExtensions()
        }
    }
}
