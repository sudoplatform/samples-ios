//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

/// Protocol to assign for a delegate of `InputFormTableViewCell`.
///
/// This is used to receive form updates from the cell.
protocol InputFormCellDelegate: AnyObject {

    /// Input cell has had an update in its field information from the user.
    func inputCell(_ cell: InputFormTableViewCell, didUpdateInput input: String?)
}

/// Custom `UITableViewCell` used for an input form. Contains a `UILabel` and `UITextField` in a vertical `UIStackView`.
class InputFormTableViewCell: UITableViewCell {

    // MARK: - Outlets

    /// Label associated with the input in the cell.
    @IBOutlet var label: UILabel!

    /// Input field for the cell.
    @IBOutlet var textField: UITextField!

    // MARK: - Properties

    /// Delegate used to notify of update events.
    weak var delegate: InputFormCellDelegate?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        separatorInset.left = 0
        selectionStyle = .none
    }

    // MARK: - Actions

    /// Action associated with the `editingChanged` event on the `textField`.
    ///
    /// Notifies the delegate that the text has updated on the `textField`.
    @IBAction func textFieldDidUpdate() {
        delegate?.inputCell(self, didUpdateInput: textField.text)
    }
}
