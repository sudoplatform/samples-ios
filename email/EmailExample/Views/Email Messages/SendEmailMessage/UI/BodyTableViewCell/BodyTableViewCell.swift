//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail

protocol BodyCellDelegate: AnyObject {
    func bodyCell(_ cell: BodyTableViewCell, didUpdateInput input: String?)
}

class BodyTableViewCell: UITableViewCell, UITextViewDelegate {

    // MARK: - Outlets

    @IBOutlet var textView: UITextView!

    // MARK: - Properties

    weak var delegate: BodyCellDelegate?

    // MARK: - Lifecycle

    override func awakeFromNib() {
        super.awakeFromNib()
        self.selectionStyle = .none
        textView.text = ""
    }

    // MARK: - Conformance: UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        delegate?.bodyCell(self, didUpdateInput: textView.text)
    }

}
