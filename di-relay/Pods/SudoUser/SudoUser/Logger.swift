//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

extension Logger {

    static let sudoUserLogger = Logger(identifier: "SudoUser", driver: NSLogDriver(level: .debug))

}
