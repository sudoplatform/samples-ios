//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoTelephony

class CallRecordDetailTableViewController: UITableViewController {

    var callRecord: CallRecord!

    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var localNumberLabel: UILabel!
    @IBOutlet weak var remoteNumberLabel: UILabel!
    @IBOutlet weak var typeLabel: UILabel!
    @IBOutlet weak var durationLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var noVoicemailLabel: UILabel!
    @IBOutlet weak var voicemailCell: UITableViewCell!

    private var subscriptionToken: SubscriptionToken?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Voice Call"

        update()

        // Subscribe to updates to the call record we're displaying.
        let client = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!
        subscriptionToken = try! client.subscribeToCallRecords { [weak self] event in
            if case .success(let call) = event, call.id == self?.callRecord.id {
                self?.callRecord = call
                self?.update()
            }
        }
    }

    private func update() {
        self.statusLabel.text = "Complete"
        self.localNumberLabel.text = formatAsUSNumber(number: callRecord.localPhoneNumber)
        self.remoteNumberLabel.text = formatAsUSNumber(number: callRecord.remotePhoneNumber)

        self.typeLabel.text = {
            switch (callRecord.direction ,callRecord.state) {
            case (.inbound, .completed): return "Incoming"
            case (.inbound, .unanswered): return "Missed Incoming"
            case (.outbound, .completed): return "Outgoing"
            case (.outbound, .unanswered): return "Unanswered Outgoing"
            default: return ""
            }
        }()

        self.typeLabel.textColor = displayColor(for: callRecord)

        self.durationLabel.text = {
            let seconds = TimeInterval(exactly: NSNumber(value: callRecord.durationSeconds)) ?? 0
                let formatter = DateComponentsFormatter()
                formatter.unitsStyle = .positional
                formatter.allowedUnits = [.minute, .second]
                if seconds >= 60 * 60 {
                    formatter.allowedUnits = [.hour, .minute, .second]
                }
                formatter.zeroFormattingBehavior = [.pad]
                return formatter.string(from: seconds) ?? "00:00"
        }()

        self.dateLabel.text = {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: callRecord.created)
        }()

        if callRecord.voicemail == nil {
            noVoicemailLabel.isHidden = false
            voicemailCell.accessoryType = .none
            voicemailCell.selectionStyle = .none
        } else {
            noVoicemailLabel.isHidden = true
            voicemailCell.accessoryType = .disclosureIndicator
            voicemailCell.selectionStyle = .default
        }

        self.tableView.tableFooterView = UIView()
    }

    @IBAction func deletePressed(_ sender: Any) {
        let client = (UIApplication.shared.delegate as! AppDelegate).telephonyClient!

        self.presentActivityAlert(message: "Deleting call record")

        try! client.deleteCallRecord(id: self.callRecord.id, completion: { (result) in
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    switch result {
                    case .success(_):
                        self.navigationController?.popViewController(animated: true)
                    case .failure(let error):
                        self.presentErrorAlert(message: "Failed to delete call record", error: error)
                    }
                }
            }
        })
    }

    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        switch identifier {
        case "navigateToVoicemail":
            return callRecord.voicemail != nil
        default: return true
        }
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case "navigateToVoicemail":
            let destination = segue.destination as! VoicemailViewController
            destination.callRecord = self.callRecord
        default: break
        }
    }
}
