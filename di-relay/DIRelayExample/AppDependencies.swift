//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDIRelay
import SudoUser
import SudoKeyManager
import SudoEntitlements
import SudoProfiles

struct AppDependencies {
    let sudoDIRelayClient: SudoDIRelayClient
    let sudoUserClient: SudoUserClient
    let authenticator: Authenticator
    let entitlementsClient: SudoEntitlementsClient
    let profilesClient: SudoProfilesClient
    let keyManager: SudoKeyManager

    init(
        sudoUserClient: SudoUserClient,
        entitlementsClient: SudoEntitlementsClient,
        profilesClient: SudoProfilesClient,
        keyManager: SudoKeyManager,
        authenticator: Authenticator,
        sudoDIRelayClient: SudoDIRelayClient
    ) {
        self.sudoUserClient = sudoUserClient
        self.entitlementsClient = entitlementsClient
        self.profilesClient = profilesClient
        self.keyManager = keyManager
        self.authenticator = authenticator
        self.sudoDIRelayClient = sudoDIRelayClient
    }

    init(sudoUserClient: SudoUserClient, sudoDIRelayClient: SudoDIRelayClient) throws {
        // A  key manager for only storing TEST registration keys, not  keys associated with postboxes.
        let testRegistrationKeyManager = DefaultSudoKeyManager(
            serviceName: "com.sudoplatform.DIRelayApp",
            keyTag: "com.sudoplatform",
            namespace: "DIRelayExample"
        )
        // Setup EntitlementsClient
        let entitlementsClient = try DefaultSudoEntitlementsClient(userClient: sudoUserClient)
        // Setup ProfilesClient
        let storageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let profilesClient = try DefaultSudoProfilesClient(sudoUserClient: sudoUserClient, blobContainerURL: storageURL)
        let authenticator = Authenticator(userClient: sudoUserClient, keyManager: testRegistrationKeyManager)
        self.init(
            sudoUserClient: sudoUserClient,
            entitlementsClient: entitlementsClient,
            profilesClient: profilesClient,
            keyManager: testRegistrationKeyManager,
            authenticator: authenticator,
            sudoDIRelayClient: sudoDIRelayClient
        )
    }

    init() throws {
        // If this line fails, this object is being initialized on a background thread.
        assert(Thread.isMainThread)
        // Setup UserClient
        sudoUserClient = try DefaultSudoUserClient(keyNamespace: "dir")
        // Setup EntitlementsClient
        entitlementsClient = try DefaultSudoEntitlementsClient(userClient: sudoUserClient)
        // Setup ProfilesClient
        let storageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        profilesClient = try DefaultSudoProfilesClient(sudoUserClient: sudoUserClient, blobContainerURL: storageURL)
        // If this fails, check the config is set up
        sudoDIRelayClient = try DefaultSudoDIRelayClient(sudoUserClient: sudoUserClient)

        // Setup TEST registration SudoKeyManager
        keyManager = DefaultSudoKeyManager(
            serviceName: "com.sudoplatform.DIRelayApp",
            keyTag: "com.sudoplatform",
            namespace: "DIRelayExample"
        )

        authenticator = Authenticator(userClient: sudoUserClient, keyManager: keyManager)
    }
}
