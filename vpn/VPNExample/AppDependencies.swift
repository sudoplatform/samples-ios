//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEntitlements
import SudoKeyManager
import SudoUser
import SudoVPN

struct AppDependencies {

    // MARK: - Properties

    let userClient: SudoUserClient
    let vpnClient: SudoVPNClient
    let entitlementsClient: SudoEntitlementsClient
    let authenticator: Authenticator

    // MARK: - Lifecycle

    init(userClient: SudoUserClient, authenticator: Authenticator, vpnClient: SudoVPNClient, entitlementsClient: SudoEntitlementsClient) {
        self.userClient = userClient
        self.authenticator = authenticator
        self.vpnClient = vpnClient
        self.entitlementsClient = entitlementsClient
    }

    init() throws {
        // Setup UserClient
        userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        // Setup KeyManager
        let keyManager = SudoKeyManagerImpl(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "vpn")
        authenticator = DefaultAuthenticator(userClient: userClient, keyManager: keyManager)
        // Setup VPNClient
        vpnClient = try DefaultSudoVPNClient(userClient: userClient)
        entitlementsClient = try DefaultSudoEntitlementsClient(userClient: userClient)
    }

    func reset() throws {
        try vpnClient.reset()
        try entitlementsClient.reset()
        try userClient.reset()
    }
}
