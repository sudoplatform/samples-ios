//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoLogging

internal extension Logger {

    /// Logger used internally in the DIRelayExample.
    static let testLogger = Logger(identifier: "Test-DIRelayExample", driver: NSLogDriver(level: .debug))
}
