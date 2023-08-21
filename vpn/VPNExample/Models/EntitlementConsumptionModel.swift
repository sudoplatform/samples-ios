//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEntitlements

struct EntitlementConsumptionModel: Equatable {

    // MARK: Properties

    var name: String
    var value: Int
    var consumed: Int
    var available: Int

}
