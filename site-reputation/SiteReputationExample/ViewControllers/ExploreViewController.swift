//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class ExploreViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var lastUpdatedLabel: UILabel!
    @IBOutlet weak var pickerView: UIPickerView!
    @IBOutlet weak var urlTextField: UITextField!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var checkButton: UIButton!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loadingLabel: UILabel!
    private let testUrls = [
        "aboveandbelow.com.au",
        "wildnights.co.uk",
        "endurotanzania.co.tz",
        "tadoo.ca",
        "tandenblekenhoofddorp.nl",
        "tentandoserfitness.000webhostapp.com",
        "anonyome.com/about.js",
        "mysudo.com/support/foo.js",
        "brisbanetimes.com.au"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.parent?.title = "Explore"

        let signOut = UIBarButtonItem(title: "Settings", style: .done, target: self, action: #selector(self.settingsTapped))
        self.navigationItem.rightBarButtonItem = signOut

        pickerView.delegate = self
        pickerView.dataSource = self
        pickerView.reloadAllComponents()
        urlTextField.text = testUrls[0]
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpdatedText()
    }

    @objc func settingsTapped() {
        guard let storyboard = self.storyboard else { return }
        guard let nav = self.navigationController else { return }
        let vc = storyboard.instantiateViewController(identifier: "SettingsViewController")
        nav.pushViewController(vc, animated: true)
    }

    @IBAction func updateTapped(_ sender: Any) {
        showLoading(text: "Updating")

        Task {
            do {
                try await Clients.siteReputationClient.update()
                self.setUpdatedText()
            } catch {
                let alert = UIAlertController(title: "Update Failed", message: error.localizedDescription, preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
            self.hideLoading()
        }
    }

    @IBAction func checkTapped(_ sender: Any) {
        showLoading(text: "Checking")
        defer { hideLoading() }

        // check that a url is entered
        if (urlTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty {
            let alert = UIAlertController(title: "Missing URL", message: "Please enter the URL to be checked", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alert, animated: true, completion: nil)
            return
        }

        // get SiteReputation result for URL to determine if Malicious or Safe
        Task {
            do {
                let siteReputation = try await Clients.siteReputationClient.getSiteReputation(url: urlTextField.text ?? "")
                if siteReputation.isMalicious {
                    resultLabel.text = "Malicious"
                    resultLabel.textColor = .red
                } else {
                    resultLabel.text = "Safe"
                    resultLabel.textColor = .green
                }
            } catch {
                let alert = UIAlertController(title: "Check Failed", message: "Unable to get site reputation: \(error.localizedDescription)", preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                present(alert, animated: true, completion: nil)
            }
        }
    }

    @IBAction func textFieldDone(_ sender: Any) {
        checkTapped(sender)
    }

    private func setUpdatedText() {
        Task {
            let date = await Clients.siteReputationClient.lastUpdatePerformedAt()
            if let date = date {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd hh:mm:ss"
                lastUpdatedLabel.text = "Last updated at: \(formatter.string(from: date))"
            } else {
                lastUpdatedLabel.text = "Update Required"
            }
        }
    }

    private func showLoading(text: String = "") {
        self.navigationItem.rightBarButtonItem?.isEnabled = false
        loadingLabel.text = text
        loadingView.isHidden = false
    }

    private func hideLoading() {
        self.navigationItem.rightBarButtonItem?.isEnabled = true
        loadingView.isHidden = true
    }

    // UIPickerViewDelegate and DataSource methods

    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }

    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return testUrls.count
    }

    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        testUrls[row]
    }

    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        urlTextField.text = testUrls[row]
    }
}
