//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoVirtualCards
import SudoUser
import SudoKeyManager
import SudoProfiles
import SudoIdentityVerification

struct AppDependencies {

    // MARK: - Properties

    let userClient: SudoUserClient
    let profilesClient: SudoProfilesClient
    let identityVerificationClient: SudoIdentityVerificationClient
    let keyManager: SudoKeyManager
    let authenticator: Authenticator
    let virtualCardsClient: SudoVirtualCardsClient

    // MARK: - Lifecycle

    init(
        userClient: SudoUserClient,
        profilesClient: SudoProfilesClient,
        identityVerificationClient: SudoIdentityVerificationClient,
        keyManager: SudoKeyManager,
        authenticator: Authenticator,
        virtualCardsClient: SudoVirtualCardsClient
    ) {
        self.userClient = userClient
        self.profilesClient = profilesClient
        self.identityVerificationClient = identityVerificationClient
        self.keyManager = keyManager
        self.authenticator = authenticator
        self.virtualCardsClient = virtualCardsClient
    }

    init() throws {
        // Setup UserClient
        userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        // Setup ProfilesClient
        let storageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        profilesClient = try DefaultSudoProfilesClient(sudoUserClient: userClient, blobContainerURL: storageURL)
        // Setup IdentityVerificationClient
        identityVerificationClient = try DefaultSudoIdentityVerificationClient(sudoUserClient: userClient)
        // Setup KeyManager
        keyManager = SudoKeyManagerImpl(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "vcs")
        // Setup Authenticator
        authenticator = Authenticator(userClient: userClient, keyManager: keyManager)
        // Setup VirtualCardsClient
        virtualCardsClient = try DefaultSudoVirtualCardsClient(
            keyNamespace: "vcs",
            userClient: userClient,
            profilesClient: profilesClient
        )
    }
}
