//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

protocol VPNConnectionManager: class {

    var isConnected: Bool { get }

}

class DefaultVPNConnectionManager: VPNConnectionManager {

    var isConnected: Bool = false

    init() {
    }

}
