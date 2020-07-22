//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEmail
import SudoKeyManager
import SudoProfiles
import SudoUser

struct AppDependencies {

    // MARK: - Properties

    let userClient: SudoUserClient
    let profilesClient: SudoProfilesClient
    let emailClient: SudoEmailClient
    let authenticator: Authenticator

    // MARK: - Lifecycle

    init(userClient: SudoUserClient, profilesClient: SudoProfilesClient, emailClient: SudoEmailClient, authenticator: Authenticator) {
        self.userClient = userClient
        self.profilesClient = profilesClient
        self.emailClient = emailClient
        self.authenticator = authenticator
    }

    init() throws {
        // Setup UserClient
        userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        // Setup ProfilesClient
        let storageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        profilesClient = try DefaultSudoProfilesClient(sudoUserClient: userClient, blobContainerURL: storageURL)
        // Setup EmailClient
        emailClient = try DefaultSudoEmailClient(keyNamespace: "eml", userClient: userClient, profilesClient: profilesClient)
        // Setup KeyManager
        let keyManager = SudoKeyManagerImpl(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "eml")
        // Setup Authenticator
        authenticator = DefaultAuthenticator(userClient: userClient, keyManager: keyManager)
    }
}
