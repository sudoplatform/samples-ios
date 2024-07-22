//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
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
    /// Formats the `recipientLabel` text based on the direction.
    /// If inbound, recipient will show `From: <MAIL>`. If outbound, `To: <MAIL>`.
    /// Date is formatted based on the rules of `DateLabel`.
    /// Subject will appear if available, otherwise will be shown as `No Subject`.
    /// If message has attachments, a `paperclip` system image will prefix the subject line text.
    /// If the message is E2E-encrypted, a `lock_fill` system image will prefix the subject line text.
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
            let fromRecipient = (emailMessage.from[0].displayName != nil) ?
            "\(emailMessage.from.first?.displayName ?? "") <\(emailMessage.from.first?.address ?? "")>"
            : emailMessage.from.first?.address ?? ""
            recipientsLabel?.text = "From: " + fromRecipient
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
        @unknown default:
            fatalError("Unknown message direction \(emailMessage.direction)")
        }
        dateLabel.date = emailMessage.createdAt

        let subject = emailMessage.subject ?? Defaults.subject
        let subjectLabelText = NSMutableAttributedString()

        // Append relevant images to the beginning of the subject line (if applicable)
        if emailMessage.encryptionStatus == .ENCRYPTED {
            let isEncryptedImageString = UIImage.toAttributedString(systemName: "lock.fill", withTintColor: .systemBlue)
            subjectLabelText.append(isEncryptedImageString)
            subjectLabelText.append(NSAttributedString(string: " "))
        }
        if emailMessage.hasAttachments {
            let hasAttachmentsImageString = UIImage.toAttributedString(systemName: "paperclip", withTintColor: .systemBlue)
            subjectLabelText.append(hasAttachmentsImageString)
            subjectLabelText.append(NSAttributedString(string: " "))
        }

        subjectLabelText.append(NSAttributedString(string: subject))
        subjectLabel.attributedText = subjectLabelText
    }
}
