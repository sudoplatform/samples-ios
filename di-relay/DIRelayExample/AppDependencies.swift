//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay
import SudoUser
import SudoKeyManager

struct AppDependencies {
    let sudoDIRelayClient: SudoDIRelayClient
    let sudoUserClient: SudoUserClient
    let authenticator: Authenticator

    init(sudoUserClient: SudoUserClient, sudoDIRelayClient: SudoDIRelayClient, authenticator: Authenticator) {
        self.sudoUserClient = sudoUserClient
        self.sudoDIRelayClient = sudoDIRelayClient
        self.authenticator = authenticator
    }

    init(sudoUserClient: SudoUserClient, sudoDIRelayClient: SudoDIRelayClient) {
        // A  key manager for only storing TEST registration keys, not  keys associated with postboxes.
        let testRegistrationkeyManager = SudoKeyManagerImpl(
            serviceName: "com.sudoplatform.DIRelayApp",
            keyTag: "com.sudoplatform",
            namespace: "DIRelayExample"
        )
        let authenticator = DefaultAuthenticator(userClient: sudoUserClient, keyManager: testRegistrationkeyManager)
        self.init(sudoUserClient: sudoUserClient, sudoDIRelayClient: sudoDIRelayClient, authenticator: authenticator)
    }


    init() throws {
        // If this line fails, this object is being initialized on a background thread.
        assert(Thread.isMainThread)
        // Setup UserClient
        sudoUserClient = try DefaultSudoUserClient(keyNamespace: "dir")

        // If this fails, check the config is set up
        sudoDIRelayClient = try DefaultSudoDIRelayClient(sudoUserClient: sudoUserClient)

        // Setup TEST registration SudoKeyManager
        let testRegistrationkeyManager = SudoKeyManagerImpl(
            serviceName: "com.sudoplatform.DIRelayApp",
            keyTag: "com.sudoplatform",
            namespace: "DIRelayExample"
        )
        
        authenticator = DefaultAuthenticator(userClient: sudoUserClient, keyManager: testRegistrationkeyManager)
    }
}
