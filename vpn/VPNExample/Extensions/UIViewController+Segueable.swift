//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit

extension UIViewController {

    func performSegue<Segue: Segueable>(withSegue segue: Segue, sender: Any?) {
        performSegue(withIdentifier: segue.rawValue, sender: sender)
    }
}
