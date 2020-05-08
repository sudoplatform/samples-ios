//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Custom `UITableViewCell` used to show transaction information.
class TransactionTableViewCell: UITableViewCell {

    // MARK: - Outlets

    /// Description/merchant information shown in the top left of the cell.
    @IBOutlet var desciptionLabel: UILabel!

    /// Date information shown in the bottom left of the cell.
    @IBOutlet var dateLabel: UILabel!

    /// Amount information shown in the top right of the cell.
    @IBOutlet var amountLabel: UILabel!

    /// Fee information shown in the bottom right of the cell.
    @IBOutlet var feeLabel: UILabel!

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        desciptionLabel.text = nil
        dateLabel.text = nil
        amountLabel.text = nil
        feeLabel.text = nil
    }
}
