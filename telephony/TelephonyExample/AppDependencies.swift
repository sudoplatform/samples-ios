//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
@preconcurrency import SudoEntitlements
@preconcurrency import SudoKeyManager
@preconcurrency import SudoProfiles
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon
@preconcurrency import SudoUser

struct AppDependencies {

    // MARK: - Properties

    let userClient: SudoUserClient
    let profilesClient: SudoProfilesClient
    let entitlementsClient: SudoEntitlementsClient
    let authenticator: Authenticator
    let keyBackupService: KeyBackupService

    /// The telephony client, or `nil` if the configured environment has no telephony service.
    let telephonyClient: SudoTelephonyClient?

    /// Notices when the user's session has expired, so the app can send them back to sign in.
    let session: SessionMonitor

    /// The namespace the telephony SDK stores its keys under, which key backup imports phone number keys into.
    static let telephonyKeyNamespace = "tel"

    // MARK: - Lifecycle

    @MainActor
    init(
        userClient: SudoUserClient,
        profilesClient: SudoProfilesClient,
        entitlementsClient: SudoEntitlementsClient,
        authenticator: Authenticator,
        keyBackupService: KeyBackupService,
        telephonyClient: SudoTelephonyClient?
    ) {
        self.userClient = userClient
        self.profilesClient = profilesClient
        self.entitlementsClient = entitlementsClient
        self.authenticator = authenticator
        self.keyBackupService = keyBackupService
        self.telephonyClient = telephonyClient
        session = SessionMonitor(userClient: userClient)
    }

    @MainActor
    init() throws {
        let userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        let keyManager = LegacySudoKeyManager(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "telephony")
        let profilesClient = try DefaultSudoProfilesClient(sudoUserClient: userClient)
        let telephonyClient = try Self.makeTelephonyClient(userClient: userClient)
        self.init(
            userClient: userClient,
            profilesClient: profilesClient,
            entitlementsClient: try DefaultSudoEntitlementsClient(userClient: userClient),
            authenticator: DefaultAuthenticator(userClient: userClient, keyManager: keyManager),
            keyBackupService: DefaultKeyBackupService(userClient: userClient, profilesClient: profilesClient, telephonyClient: telephonyClient),
            telephonyClient: telephonyClient
        )
    }

    /// Creates the telephony client from the `telephonyService` section of `sudoplatformconfig.json`, or returns `nil` if the
    /// environment doesn't have one.
    private static func makeTelephonyClient(userClient: SudoUserClient) throws -> SudoTelephonyClient? {
        do {
            return try DefaultSudoTelephonyClient(keyNamespace: telephonyKeyNamespace, userClient: userClient)
        } catch SudoTelephonyError.invalidConfig {
            return nil
        }
    }

    // MARK: - Supplementary

    private enum Constants {
        /// `UserDefaults` key for the user name of the last user to sign in, used to notice when a different user signs in.
        static let lastSignedInUserKey = "com.sudoplatform.last-signed-in-user"
    }

    // MARK: - Methods

    /// Clears all local client state and keys, e.g. after deregistering or when the user signs out and removes their data.
    func reset() async throws {
        try await resetUserData()
        try await authenticator.reset()
        UserDefaults.standard.removeObject(forKey: Constants.lastSignedInUserKey)
    }

    /// Clears the local sign in only, keeping the user's keys so they can read their Sudos when they sign back in. The sign in
    /// state still has to go, otherwise a different sign in method, e.g. a TEST registration, finds the federated user registered.
    func resetSignIn() async throws {
        try await authenticator.reset()
    }

    /// Gets the clients ready for the user who has just signed in, before anything else uses them.
    ///
    /// A plain sign out keeps the user's keys so they can read their Sudos when they sign back in. If a different user signs in
    /// instead, the previous user's keys and data are removed first, so the new user neither sees them nor encrypts with them.
    func prepareForSignedInUser() async throws {
        let userName = try await userClient.getUserName()
        let lastUserName = UserDefaults.standard.string(forKey: Constants.lastSignedInUserKey)
        if let lastUserName, lastUserName != userName {
            try await resetUserData()
        }
        UserDefaults.standard.set(userName, forKey: Constants.lastSignedInUserKey)
        try ensureSudoEncryptionKey()
    }

    // MARK: - Helpers

    /// Clears the signed in user's keys and cached data, leaving the sign in itself alone.
    private func resetUserData() async throws {
        try await profilesClient.reset()
        try entitlementsClient.reset()
        try telephonyClient?.reset()
    }

    /// Makes sure SudoProfiles has a key to encrypt new Sudo claims with. Its client only generates one when it's created at launch,
    /// so signing in again after its keys were removed would otherwise leave it without one until the app is relaunched.
    private func ensureSudoEncryptionKey() throws {
        if try profilesClient.getSymmetricKeyId() == nil {
            try profilesClient.generateEncryptionKey()
        }
    }
}
