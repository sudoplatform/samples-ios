//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

extension AppDelegate {

    /// Returns true if the runtime is currently being run by XCTest.
    var isUnitTestRunning: Bool {
        (ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil)
    }
}
