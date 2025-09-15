//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay

class SudoDIRelayClientMockSpy: SudoDIRelayClientSpy {
    static var defaultError: Error {
        return NSError(domain: "unit-test", code: 0, userInfo: nil) as Error
    }
}
