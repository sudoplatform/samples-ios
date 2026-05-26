//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol VPNConnectionManager: AnyObject, Sendable {

    var isConnected: Bool { get }

}

@MainActor
class DefaultVPNConnectionManager: VPNConnectionManager {

    var isConnected: Bool = false

    init() {
    }

}
