//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import CommonCrypto
import CryptoKit
import Foundation

/// Errors reading or writing a key backup file.
enum KeyBackupError: LocalizedError, Equatable {
    case notKeyBackup
    case newerVersion(Int)
    case unsupportedParameters
    case wrongPasswordOrDamaged
    case cryptoFailure

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .notKeyBackup:
            return "This file isn't a Sudo key backup."
        case .newerVersion(let version):
            return "This backup was made by a newer version of the app (format version \(version)). Update the app and try again."
        case .unsupportedParameters:
            return "This backup uses encryption settings this app doesn't support."
        case .wrongPasswordOrDamaged:
            return "The password is wrong or the file is damaged. Check the password and try again."
        case .cryptoFailure:
            return "The backup couldn't be encrypted or decrypted on this device."
        }
    }
}

/// A password-protected key backup file, as defined by the Sudo Key Backup Format spec shared with the Android sample.
///
/// The file is plain JSON describing how the payload was encrypted. The payload, a `KeyBackupPayload`, is only readable with the password.
struct KeyBackupFile: Codable, Sendable {

    // MARK: - Supplementary

    struct KeyDerivation: Codable, Sendable {
        let algorithm: String
        let iterations: Int
        let salt: Data
    }

    struct Cipher: Codable, Sendable {
        let algorithm: String
        let nonce: Data
    }

    enum Constants {
        static let format = "sudoplatform-sample-key-backup"
        static let version = 1
        static let platform = "ios"
        static let keyDerivationAlgorithm = "PBKDF2-HMAC-SHA256"
        static let cipherAlgorithm = "AES-256-GCM"
        static let iterations = 600_000
        static let supportedIterations = 100_000...10_000_000
        static let saltSize = 32
        static let nonceSize = 12
        static let keySize = 32
    }

    // MARK: - Properties

    let format: String
    let version: Int
    let createdAt: Date
    let platform: String
    let kdf: KeyDerivation
    let cipher: Cipher
    let ciphertext: Data

    // MARK: - Lifecycle

    /// Reads a backup file and checks it's one this app can decrypt, before asking the user for the password.
    init(data: Data) throws {
        let file: KeyBackupFile
        do {
            file = try Self.decoder.decode(KeyBackupFile.self, from: data)
        } catch {
            throw KeyBackupError.notKeyBackup
        }
        guard file.format == Constants.format else {
            throw KeyBackupError.notKeyBackup
        }
        guard file.version <= Constants.version else {
            throw KeyBackupError.newerVersion(file.version)
        }
        guard file.kdf.algorithm == Constants.keyDerivationAlgorithm,
              Constants.supportedIterations.contains(file.kdf.iterations),
              file.cipher.algorithm == Constants.cipherAlgorithm,
              file.cipher.nonce.count == Constants.nonceSize else {
            throw KeyBackupError.unsupportedParameters
        }
        self = file
    }

    /// Encrypts `payload` with a key derived from `password`, using a new random salt and nonce.
    init(sealing payload: KeyBackupPayload, password: String, createdAt: Date = Date()) throws {
        let salt = try Self.randomData(count: Constants.saltSize)
        let nonce = try Self.randomData(count: Constants.nonceSize)
        let key = try Self.deriveKey(password: password, salt: salt, iterations: Constants.iterations)
        let plaintext = try Self.encoder.encode(payload)
        let sealedBox: AES.GCM.SealedBox
        do {
            sealedBox = try AES.GCM.seal(plaintext, using: key, nonce: AES.GCM.Nonce(data: nonce))
        } catch {
            throw KeyBackupError.cryptoFailure
        }
        self.format = Constants.format
        self.version = Constants.version
        self.createdAt = createdAt
        self.platform = Constants.platform
        self.kdf = KeyDerivation(algorithm: Constants.keyDerivationAlgorithm, iterations: Constants.iterations, salt: salt)
        self.cipher = Cipher(algorithm: Constants.cipherAlgorithm, nonce: nonce)
        self.ciphertext = sealedBox.ciphertext + sealedBox.tag
    }

    // MARK: - Methods

    func encoded() throws -> Data {
        try Self.encoder.encode(self)
    }

    /// Decrypts the payload. A wrong password and a modified file both fail the GCM tag check, so they can't be told apart.
    func open(password: String) throws -> KeyBackupPayload {
        let tagSize = 16
        guard ciphertext.count >= tagSize else {
            throw KeyBackupError.wrongPasswordOrDamaged
        }
        let key = try Self.deriveKey(password: password, salt: kdf.salt, iterations: kdf.iterations)
        let plaintext: Data
        do {
            let sealedBox = try AES.GCM.SealedBox(
                nonce: AES.GCM.Nonce(data: cipher.nonce),
                ciphertext: ciphertext.dropLast(tagSize),
                tag: ciphertext.suffix(tagSize)
            )
            plaintext = try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw KeyBackupError.wrongPasswordOrDamaged
        }
        do {
            return try Self.decoder.decode(KeyBackupPayload.self, from: plaintext)
        } catch {
            throw KeyBackupError.wrongPasswordOrDamaged
        }
    }

    // MARK: - Helpers

    private static var encoder: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }

    private static var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    /// Derives the AES key with PBKDF2-HMAC-SHA256. The password is NFC normalised first so the same characters typed on
    /// different keyboards or platforms give the same key.
    private static func deriveKey(password: String, salt: Data, iterations: Int) throws -> SymmetricKey {
        let passwordData = Data(password.precomposedStringWithCanonicalMapping.utf8)
        var key = Data(count: Constants.keySize)
        let status = key.withUnsafeMutableBytes { keyBytes in
            passwordData.withUnsafeBytes { passwordBytes in
                salt.withUnsafeBytes { saltBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2),
                        passwordBytes.baseAddress?.assumingMemoryBound(to: CChar.self),
                        passwordData.count,
                        saltBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        salt.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                        UInt32(iterations),
                        keyBytes.baseAddress?.assumingMemoryBound(to: UInt8.self),
                        Constants.keySize
                    )
                }
            }
        }
        guard status == kCCSuccess else {
            throw KeyBackupError.cryptoFailure
        }
        return SymmetricKey(data: key)
    }

    private static func randomData(count: Int) throws -> Data {
        var data = Data(count: count)
        let status = data.withUnsafeMutableBytes { bytes in
            SecRandomCopyBytes(kSecRandomDefault, count, bytes.baseAddress!)
        }
        guard status == errSecSuccess else {
            throw KeyBackupError.cryptoFailure
        }
        return data
    }
}

/// The decrypted contents of a key backup: the user it belongs to, and each SDK's exported keys, keyed by SDK.
struct KeyBackupPayload: Codable, Sendable, Equatable {

    // MARK: - Supplementary

    struct SudoProfilesKeys: Codable, Sendable, Equatable {
        let currentKeyId: String
        let keys: [SudoProfilesKey]
    }

    struct SudoProfilesKey: Codable, Sendable, Equatable {
        let id: String
        let namespace: String
        let algorithm: String
        let version: Int
        /// Base64 encoded raw key bytes.
        let key: String
    }

    /// The user the keys belong to.
    struct User: Codable, Sendable, Equatable {
        /// The user's subject, the same on every platform for the same account.
        let subject: String
    }

    struct SudoTelephonyKeys: Codable, Sendable, Equatable {
        /// The telephony SDK's key archive from `exportKeys()`, base64 encoded in the file.
        let archive: Data
    }

    private enum CodingKeys: String, CodingKey {
        case user
        case sdks
    }

    private struct SDKKey: CodingKey {
        static let sudoProfiles = SDKKey(stringValue: "sudoProfiles")
        static let sudoTelephony = SDKKey(stringValue: "sudoTelephony")
        static let recognised: Set = [sudoProfiles.stringValue, sudoTelephony.stringValue]

        let stringValue: String
        var intValue: Int? { nil }

        init(stringValue: String) {
            self.stringValue = stringValue
        }

        init?(intValue: Int) {
            nil
        }
    }

    // MARK: - Properties

    /// Absent from backups made before it was added, which can't be checked against the signed in user.
    let user: User?

    let sudoProfiles: SudoProfilesKeys?

    /// The keys phone numbers' messages are sealed to. Absent from backups made before telephony was included, or with no numbers.
    let sudoTelephony: SudoTelephonyKeys?

    /// Names of SDK entries in the backup that this app doesn't use, e.g. from a newer app. They're skipped on import.
    let unrecognisedSDKs: [String]

    // MARK: - Lifecycle

    init(user: User?, sudoProfiles: SudoProfilesKeys?, sudoTelephony: SudoTelephonyKeys?) {
        self.user = user
        self.sudoProfiles = sudoProfiles
        self.sudoTelephony = sudoTelephony
        self.unrecognisedSDKs = []
    }

    // MARK: - Conformance: Codable

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        user = try container.decodeIfPresent(User.self, forKey: .user)
        let sdks = try container.nestedContainer(keyedBy: SDKKey.self, forKey: .sdks)
        sudoProfiles = try sdks.decodeIfPresent(SudoProfilesKeys.self, forKey: .sudoProfiles)
        sudoTelephony = try sdks.decodeIfPresent(SudoTelephonyKeys.self, forKey: .sudoTelephony)
        unrecognisedSDKs = sdks.allKeys.map(\.stringValue).filter { !SDKKey.recognised.contains($0) }.sorted()
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(user, forKey: .user)
        var sdks = container.nestedContainer(keyedBy: SDKKey.self, forKey: .sdks)
        try sdks.encodeIfPresent(sudoProfiles, forKey: .sudoProfiles)
        try sdks.encodeIfPresent(sudoTelephony, forKey: .sudoTelephony)
    }
}
