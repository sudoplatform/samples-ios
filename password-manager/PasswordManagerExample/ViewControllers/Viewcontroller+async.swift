//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit

extension UIViewController {
    func dismiss(animated: Bool) async {
        await withCheckedContinuation { c in
            DispatchQueue.main.async {
                self.dismiss(animated: true) {
                    c.resume()
                }
            }
        }
    }
}
