//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

/// This TableView Cell presents the basic contents of an `EmailMessage`.
class EmailMessageTableViewCell: UITableViewCell {

    // MARK: - Supplementary

    struct Defaults {
        static let subject = "No Subject"
    }

    // MARK: - Outlets

    @IBOutlet var recipientsLabel: UILabel!
    @IBOutlet var dateLabel: DateLabel!
    @IBOutlet var subjectLabel: UILabel!

    // MARK: - Properties

    var emailMessage: EmailMessage? {
        didSet {
            updateLabels()
        }
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        recipientsLabel?.text = nil
        dateLabel?.text = nil
        subjectLabel?.text = nil
    }

    /// Update the labels of the view.
    ///
    /// Formats the `recipientLabel` text based on the direction. If inbound, recipient will show `From: <MAIL>`. If outbound, `To: <MAIL>`. Date is formatted
    /// based on the rules of `DateLabel`. Subject will appear if available, otherwise will be shown as `No Subject`.
    /// If the `emailMessage` has been set to `nil`, all text will be removed.
    private func updateLabels() {
        guard let emailMessage = emailMessage else {
            recipientsLabel.text = nil
            dateLabel.text = nil
            subjectLabel.text = nil
            return
        }
        switch emailMessage.direction {
        case .inbound:
            recipientsLabel?.text = "From: " + (emailMessage.from[0].displayName ?? emailMessage.from[0].address)
        case .outbound:
            var toAddressLabel: [String] = []
            emailMessage.to.forEach {
                if let displayName = $0.displayName {
                    toAddressLabel.append(displayName)
                } else {
                    toAddressLabel.append($0.address)
                }
            }
            recipientsLabel?.text = "To: " + toAddressLabel.joined(separator: ", ")
        }
        dateLabel.date = emailMessage.created
        subjectLabel.text = emailMessage.subject ?? Defaults.subject
    }
}
