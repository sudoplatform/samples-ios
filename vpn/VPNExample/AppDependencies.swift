//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEntitlements
import SudoEntitlementsAdmin
import SudoKeyManager
import SudoUser
import SudoVPN

struct AppDependencies {

    // MARK: - Properties

    let userClient: SudoUserClient
    let vpnClient: SudoVPNClient
    let entitlementsClient: SudoEntitlementsClient
    let authenticator: Authenticator
    let adminEntitlementsClient: SudoEntitlementsAdminClient?

    // MARK: - Lifecycle

    init(
        userClient: SudoUserClient,
        authenticator: Authenticator,
        vpnClient: SudoVPNClient,
        entitlementsClient: SudoEntitlementsClient,
        adminEntitlementsClient: SudoEntitlementsAdminClient?
    ) {
        self.userClient = userClient
        self.authenticator = authenticator
        self.vpnClient = vpnClient
        self.entitlementsClient = entitlementsClient
        self.adminEntitlementsClient = adminEntitlementsClient
    }

    init() throws {
        // Setup UserClient
        userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        // Setup KeyManager
        let keyManager = LegacySudoKeyManager(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "vpn")
        authenticator = DefaultAuthenticator(userClient: userClient, keyManager: keyManager)
        // Setup VPNClient
        vpnClient = try DefaultSudoVPNClient(userClient: userClient)
        entitlementsClient = try DefaultSudoEntitlementsClient(userClient: userClient)
        adminEntitlementsClient = try AppDependencies.setupEntitlementsAdminClient()
    }

    func reset() async throws {
        try vpnClient.reset()
        try entitlementsClient.reset()
        try await userClient.reset()
    }

    static func setupEntitlementsAdminClient() throws -> SudoEntitlementsAdminClient? {
        // Setup Entitlements Admin Client.
        let fileReadable = DefaultFileReadable()
        var apiKey: String?
        let apiKeyPath = fileReadable.path(forResource: "api", ofType: "key")
        if apiKeyPath != nil {
            apiKey = try? fileReadable.contentsOfFile(forPath: apiKeyPath!)
        }
        guard let apiKey = apiKey ?? ProcessInfo.processInfo.environment["API_KEY"] else {
            return nil
        }
        return try DefaultSudoEntitlementsAdminClient(apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
    }
}
