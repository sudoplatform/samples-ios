//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoLogging

extension Logger {
    /// Logger used by the sample app.
    static let sampleLogger = Logger(
        identifier: "SampleTelephony",
        driver: NSLogDriver(level: .debug)
    )
}
