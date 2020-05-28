//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Table View Cell shown on a `TransactionDetailViewController`.
class TransactionDetailTableViewCell: UITableViewCell {

    // MARK: - Outlets

    /// Label for the title of the cell.
    @IBOutlet var titleLabel: UILabel!

    /// Label for the subtitle of the cell.
    @IBOutlet var subtitleLabel: UILabel!

    /// Label for the value of the cell.
    @IBOutlet var valueLabel: UILabel!

    // MARK: - Supplementary

    /// Name of the class.
    static var name = "TransactionDetailTableViewCell"

    // MARK: - Properties

    /// Title of the `TransactionDetailTableViewCell`.
    ///
    /// Acts as a proxy to `titleLabel.text`.
    var title: String? {
        get {
            return titleLabel.text
        }
        set {
            titleLabel.text = newValue
        }
    }

    /// Title of the `TransactionDetailTableViewCell`.
    ///
    /// Acts as a proxy to `subtitleLabel.text`.
    var subtitle: String? {
        get {
            return subtitleLabel.text
        }
        set {
            subtitleLabel.text = newValue
            subtitleLabel.isHidden = (newValue == nil)
        }
    }

    /// Title of the `TransactionDetailTableViewCell`.
    ///
    /// Acts as a proxy to `valueLabel.text`.
    var value: String? {
        get {
            return valueLabel.text
        }
        set {
            valueLabel.text = newValue
        }
    }

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        title = nil
        subtitle = nil
        value = nil
    }
}
