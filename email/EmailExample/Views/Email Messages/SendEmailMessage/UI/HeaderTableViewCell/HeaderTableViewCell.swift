//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

protocol HeaderCellDelegate: class {
    func headerCell(_ cell: HeaderTableViewCell, didUpdateInput input: String?)
}

class HeaderTableViewCell: UITableViewCell {

    // MARK: - Outlets

    @IBOutlet var label: UILabel!
    @IBOutlet var textField: UITextField!

    // MARK: - Properties

    /// Delegate used to notify of update events.
    weak var delegate: HeaderCellDelegate?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    // MARK: - Actions

    /// Action associated with the `editingChanged` event on the `textField`.
    ///
    /// Notifies the delegate that the text has updated on the `textField`.
    @IBAction func textFieldDidUpdate() {
        delegate?.headerCell(self, didUpdateInput: textField.text)
    }

}
