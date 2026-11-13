//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import SudoLogging
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

    /// The telephony client, or `nil` until the user signs in, or if the configured environment has no telephony service.
    ///
    /// It's created once the user is signed in, by `startTelephony(enforceSingletonKeyPair:)`, rather than at launch, so it
    /// picks up how phone numbers are keyed as chosen on the sign in screen.
    @MainActor var telephonyClient: SudoTelephonyClient? {
        telephony.client
    }

    /// True if this device created a new shared phone number key since the user last exported a key backup, so a backup
    /// made before then doesn't contain it.
    @MainActor var telephonyKeyNeedsBackup: Bool {
        telephony.keyNeedsBackup
    }

    /// Backs up and restores the user's keys, including the telephony client's once the user is signed in.
    @MainActor var keyBackupService: KeyBackupService {
        DefaultKeyBackupService(userClient: userClient, profilesClient: profilesClient, telephonyClient: telephonyClient)
    }

    /// Notices when the user's session has expired, so the app can send them back to sign in.
    let session: SessionMonitor

    /// The namespace the telephony SDK stores its keys under, which key backup imports phone number keys into.
    static let telephonyKeyNamespace = "tel"

    /// Holds the telephony client for the signed in session. A reference, so every copy of these dependencies sees the client
    /// created at sign in.
    private let telephony: TelephonySession

    // MARK: - Lifecycle

    @MainActor
    init(
        userClient: SudoUserClient,
        profilesClient: SudoProfilesClient,
        entitlementsClient: SudoEntitlementsClient,
        authenticator: Authenticator
    ) {
        self.userClient = userClient
        self.profilesClient = profilesClient
        self.entitlementsClient = entitlementsClient
        self.authenticator = authenticator
        telephony = TelephonySession()
        session = SessionMonitor(userClient: userClient)
    }

    @MainActor
    init() throws {
        let userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        let keyManager = LegacySudoKeyManager(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "telephony")
        self.init(
            userClient: userClient,
            profilesClient: try DefaultSudoProfilesClient(sudoUserClient: userClient),
            entitlementsClient: try DefaultSudoEntitlementsClient(userClient: userClient),
            authenticator: DefaultAuthenticator(userClient: userClient, keyManager: keyManager)
        )
    }

    // MARK: - Supplementary

    private enum Constants {
        /// `UserDefaults` key for the user name of the last user to sign in, used to notice when a different user signs in.
        static let lastSignedInUserKey = "com.sudoplatform.last-signed-in-user"
    }

    // MARK: - Methods

    /// Creates the telephony client for the user who has just signed in, from the `telephonyService` section of
    /// `sudoplatformconfig.json`. Leaves it `nil` if the environment doesn't have one.
    ///
    /// - Parameter enforceSingletonKeyPair: Whether every phone number shares one key pair, as chosen on the sign in screen.
    @MainActor
    func startTelephony(enforceSingletonKeyPair: Bool) throws {
        telephony.enforcesSingletonKeyPair = enforceSingletonKeyPair
        do {
            telephony.client = try DefaultSudoTelephonyClient(
                keyNamespace: Self.telephonyKeyNamespace,
                userClient: userClient,
                config: SudoTelephonyClientConfig(enforceSingletonKeyPair: enforceSingletonKeyPair)
            )
        } catch SudoTelephonyError.invalidConfig {
            telephony.client = nil
        }
    }

    /// Creates the shared phone number key if the telephony client uses one and this device doesn't have it. Provisioning
    /// never creates it, so this must run before the user gets a number.
    ///
    /// Call once the user is signed in and prepared for, since preparing for a different user removes the previous user's keys,
    /// and again after importing keys, in case the backup didn't contain one.
    @MainActor
    func prepareTelephonyKeys() async throws {
        guard let client = telephony.client, telephony.enforcesSingletonKeyPair else { return }
        let result = try await client.createSingletonKeysIfAbsent()
        telephony.keyNeedsBackup = result.keyPair.created
        if result.keyPair.created {
            Logger.sampleLogger.info("Created the shared phone number key \(result.keyPair.keyId)")
        }
    }

    /// Notes that the user has exported a key backup, which now contains the shared phone number key.
    @MainActor
    func didExportKeys() {
        telephony.keyNeedsBackup = false
    }

    /// Clears all local client state and keys, e.g. after deregistering or when the user signs out and removes their data.
    func reset() async throws {
        try await resetUserData()
        try await authenticator.reset()
        UserDefaults.standard.removeObject(forKey: Constants.lastSignedInUserKey)
        await stopTelephony()
    }

    /// Clears the local sign in only, keeping the user's keys so they can read their Sudos when they sign back in. The sign in
    /// state still has to go, otherwise a different sign in method, e.g. a TEST registration, finds the federated user registered.
    func resetSignIn() async throws {
        try await authenticator.reset()
        await stopTelephony()
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
        try await telephonyClient?.reset()
    }

    /// Drops the signed out user's telephony client, so the next sign in creates one with the key mode chosen then.
    @MainActor
    private func stopTelephony() {
        telephony.client = nil
        telephony.enforcesSingletonKeyPair = false
        telephony.keyNeedsBackup = false
    }

    /// Makes sure SudoProfiles has a key to encrypt new Sudo claims with. Its client only generates one when it's created at launch,
    /// so signing in again after its keys were removed would otherwise leave it without one until the app is relaunched.
    private func ensureSudoEncryptionKey() throws {
        if try profilesClient.getSymmetricKeyId() == nil {
            try profilesClient.generateEncryptionKey()
        }
    }
}

/// The telephony client for the signed in session, shared by every copy of `AppDependencies`. Observable so screens update
/// when the shared key needs backing up.
@MainActor
@Observable
private final class TelephonySession {
    var client: SudoTelephonyClient?
    var enforcesSingletonKeyPair = false
    var keyNeedsBackup = false
}
