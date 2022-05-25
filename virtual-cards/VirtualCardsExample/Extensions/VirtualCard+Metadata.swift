//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoVirtualCards

extension VirtualCard {
    var metadataAlias: String? {
        guard case .dictionary(let dict) = metadata else {
            return nil
        }
        guard case .string(let alias) = dict["alias"] else {
            return nil
        }
        return alias
    }
}
