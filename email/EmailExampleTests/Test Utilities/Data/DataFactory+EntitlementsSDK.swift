//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEntitlements

extension DataFactory {

    enum EntitlementsSDK {

        static func generateEntitlementsSet() -> EntitlementsSet {
            return EntitlementsSet(
                name: "EmailUnitTestEntitlements",
                description: "Used for unit test",
                entitlements: [.init(name: "unitTest", value: 1)],
                version: 1,
                created: Date(),
                updated: Date()
            )
        }
    }
}
