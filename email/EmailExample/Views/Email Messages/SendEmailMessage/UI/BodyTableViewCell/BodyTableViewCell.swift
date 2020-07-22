//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

protocol BodyCellDelegate: class {
    func bodyCell(_ cell: BodyTableViewCell, didUpdateInput input: String?)
}

class BodyTableViewCell: UITableViewCell, UITextViewDelegate {

    // MARK: - Outlets

    @IBOutlet var textView: UITextView!

    // MARK: - Properties

    weak var delegate: BodyCellDelegate?

    override func awakeFromNib() {
        super.awakeFromNib()
        textView.text = ""
    }

    // MARK: - Conformance: UITextViewDelegate

    func textViewDidChange(_ textView: UITextView) {
        delegate?.bodyCell(self, didUpdateInput: textView.text)
    }

}
