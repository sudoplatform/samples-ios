//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay
@testable import DIRelayExample

private class DataFactoryBundleLoader {}

extension DataFactory {

    enum TestData {

        static func generateTimestamp() -> String {
            return "Thu, 1 Jan 1970 00:00:00 GMT+00"
        }

    }
}
