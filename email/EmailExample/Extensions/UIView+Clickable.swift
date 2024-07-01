//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

class ClickHandler: UITapGestureRecognizer {
    var onClick: (() -> Void)?
}

extension UIView {

    func setOnClickHandler(action: @escaping () -> Void) {
        let clickRecogniser = ClickHandler(target: self, action: #selector(onViewClicked(sender:)))
        clickRecogniser.onClick = action
        self.addGestureRecognizer(clickRecogniser)
    }

    @objc func onViewClicked(sender: ClickHandler) {
        if let onClick = sender.onClick {
            onClick()
        }
    }

}
