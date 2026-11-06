//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Gzip
import SudoLogging
@preconcurrency import SudoProfiles
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon
@preconcurrency import SudoUser

enum KeyBackupServiceError: LocalizedError {
    case noKeysToExport
    case noSudoKeysInBackup
    case invalidBackupContents
    case localKeysUnavailable
    case phoneNumberKeysNotImported
    case differentUser

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .noKeysToExport:
            return "There are no keys on this device to export. Sign in and try again."
        case .noSudoKeysInBackup:
            return "This backup doesn't contain any Sudo keys."
        case .invalidBackupContents:
            return "This backup's contents are incomplete, so it can't be imported."
        case .localKeysUnavailable:
            return "This device's keys couldn't be read. Sign out, sign in again and try again."
        case .differentUser:
            return "This backup belongs to a different user. Sign in as that user to import it."
        case .phoneNumberKeysNotImported:
            return "The Sudo keys were imported, but the phone number keys couldn't be, so messages may not be readable. Try the import again."
        }
    }
}

/// The outcome of a successful import.
struct KeyBackupImportResult: Sendable {

    /// The number of Sudo encryption keys imported.
    let sudoKeyCount: Int

    /// True if the backup's phone number keys were imported. False for a backup without them.
    let importedPhoneNumberKeys: Bool

    /// SDK entries in the backup that this app doesn't use, which were skipped.
    let unrecognisedSDKs: [String]
}

/// Backs up the keys this device uses to encrypt and decrypt user data, so they can be moved to another device signed in as the
/// same user: the Sudo keys, and the keys each phone number's messages are sealed to.
protocol KeyBackupService: Sendable {

    /// Exports this device's keys as a backup file protected by `password`.
    func exportBackup(password: String) async throws -> Data

    /// Reads a backup file and checks it can be imported, without needing the password.
    func readBackup(_ data: Data) throws -> KeyBackupFile

    /// Decrypts a backup with `password` and replaces this device's keys with the ones it contains.
    func importBackup(_ file: KeyBackupFile, password: String) async throws -> KeyBackupImportResult
}

final class DefaultKeyBackupService: KeyBackupService, @unchecked Sendable {

    // MARK: - Properties

    /// Identifies the signed in user, whom a backup is made for and must belong to when it's imported.
    unowned let userClient: SudoUserClient

    unowned let profilesClient: SudoProfilesClient

    /// `nil` if the environment has no telephony service, in which case phone number keys aren't backed up or restored.
    let telephonyClient: SudoTelephonyClient?

    // MARK: - Lifecycle

    init(userClient: SudoUserClient, profilesClient: SudoProfilesClient, telephonyClient: SudoTelephonyClient?) {
        self.userClient = userClient
        self.profilesClient = profilesClient
        self.telephonyClient = telephonyClient
    }

    // MARK: - Conformance: KeyBackupService

    func exportBackup(password: String) async throws -> Data {
        guard let currentKeyId = try profilesClient.getSymmetricKeyId() else {
            throw KeyBackupServiceError.noKeysToExport
        }
        let keys = try profilesClient.exportEncryptionKeys().map {
            KeyBackupPayload.SudoProfilesKey(id: $0.id, namespace: $0.namespace, algorithm: $0.algorithm, version: $0.version, key: $0.key)
        }
        guard !keys.isEmpty else {
            throw KeyBackupServiceError.noKeysToExport
        }
        let payload = KeyBackupPayload(
            user: try await userClient.getSubject().map { .init(subject: $0) },
            sudoProfiles: .init(currentKeyId: currentKeyId, keys: keys),
            sudoTelephony: try exportTelephonyKeys().map { .init(archive: $0) }
        )
        return try KeyBackupFile(sealing: payload, password: password).encoded()
    }

    func readBackup(_ data: Data) throws -> KeyBackupFile {
        try KeyBackupFile(data: data)
    }

    func importBackup(_ file: KeyBackupFile, password: String) async throws -> KeyBackupImportResult {
        let payload = try file.open(password: password)
        // Checked before any keys are replaced: another user's keys can't read this user's Sudos, and would leave the device with
        // none that can. A backup without a user, e.g. from before the field was added, can't be checked, so it's imported as before.
        if let backupSubject = payload.user?.subject, let subject = try await userClient.getSubject(), backupSubject != subject {
            throw KeyBackupServiceError.differentUser
        }
        guard let sudoKeys = payload.sudoProfiles, !sudoKeys.keys.isEmpty else {
            throw KeyBackupServiceError.noSudoKeysInBackup
        }
        guard sudoKeys.keys.contains(where: { $0.id == sudoKeys.currentKeyId }) else {
            throw KeyBackupServiceError.invalidBackupContents
        }

        // SudoProfiles deletes all existing keys, then silently skips any key whose namespace isn't its own, so keys from another
        // app or platform must be moved into this client's namespace first. It always holds a key once signed in, so read it from that.
        let existingKeys = try profilesClient.exportEncryptionKeys()
        guard let localNamespace = existingKeys.first?.namespace, let existingCurrentKeyId = try profilesClient.getSymmetricKeyId() else {
            throw KeyBackupServiceError.localKeysUnavailable
        }
        let keys = sudoKeys.keys.map {
            EncryptionKey(id: $0.id, namespace: localNamespace, algorithm: $0.algorithm, version: $0.version, key: $0.key)
        }
        do {
            try profilesClient.importEncryptionKeys(keys: keys, currentKeyId: sudoKeys.currentKeyId)
        } catch {
            // The existing keys are deleted before the import, so put them back rather than leave the device with none.
            try? profilesClient.importEncryptionKeys(keys: existingKeys, currentKeyId: existingCurrentKeyId)
            throw error
        }
        var unrecognisedSDKs = payload.unrecognisedSDKs
        var importedPhoneNumberKeys = false
        if let telephonyKeys = payload.sudoTelephony {
            if let telephonyClient {
                try importTelephonyKeys(telephonyKeys.archive, telephonyClient: telephonyClient)
                importedPhoneNumberKeys = true
            } else {
                unrecognisedSDKs.append("sudoTelephony")
            }
        }
        return KeyBackupImportResult(
            sudoKeyCount: keys.count,
            importedPhoneNumberKeys: importedPhoneNumberKeys,
            unrecognisedSDKs: unrecognisedSDKs
        )
    }

    // MARK: - Helpers

    /// The telephony SDK's key archive, or `nil` if there are no phone number keys to back up.
    private func exportTelephonyKeys() throws -> Data? {
        guard let telephonyClient else { return nil }
        do {
            return try telephonyClient.exportKeys()
        } catch SudoTelephonyError.internalError(let cause?) where cause.contains("archiveEmpty") {
            // The SDK reports a key store with nothing in it, e.g. before any number is provisioned, as an internal error wrapping
            // SudoKeyManager's `archiveEmpty`. Any other failure fails the export, so a backup never quietly leaves the keys out.
            return nil
        }
    }

    /// The archive with every key moved into `namespace`. The archive keeps each key's namespace, and the SDK's key manager skips
    /// any key whose namespace isn't its own, including keys with none, as in Android's archives. So keys from another app or
    /// platform must be moved first, as for Sudo keys. An archive that can't be read is returned unchanged, so the SDK reports why.
    private static func archive(_ archive: Data, movedToNamespace namespace: String) -> Data {
        guard let json = try? archive.gunzipped(),
              var contents = (try? JSONSerialization.jsonObject(with: json)) as? [String: Any],
              let keys = contents["Keys"] as? [[String: Any]] else {
            return archive
        }
        contents["Keys"] = keys.map { key in key.merging(["NameSpace": namespace]) { _, new in new } }
        guard let movedJSON = try? JSONSerialization.data(withJSONObject: contents), let moved = try? movedJSON.gzipped() else {
            return archive
        }
        return moved
    }

    /// Replaces this device's phone number keys with the backup's. The SDK deletes the existing keys first, so they're put back if
    /// the import fails rather than leave the device with none.
    private func importTelephonyKeys(_ archive: Data, telephonyClient: SudoTelephonyClient) throws {
        let existingArchive = try? exportTelephonyKeys()
        do {
            try telephonyClient.importKeys(archiveData: Self.archive(archive, movedToNamespace: AppDependencies.telephonyKeyNamespace))
        } catch {
            Logger.sampleLogger.error("Failed to import phone number keys: \(error)")
            if let existingArchive {
                try? telephonyClient.importKeys(archiveData: existingArchive)
            }
            throw KeyBackupServiceError.phoneNumberKeysNotImported
        }
    }
}
