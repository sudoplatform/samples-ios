//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

class ImmutableTextView: UITextView {

    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(paste(_:)) || action == #selector(UIResponderStandardEditActions.paste(_:)) ||
           action == #selector(replace(_:withText:)) ||
           action == #selector(UIResponderStandardEditActions.cut(_:)) ||
           action == #selector(UIResponderStandardEditActions.delete(_:)) {
            return false
        }
        return super.canPerformAction(action, withSender: sender)
    }
}
