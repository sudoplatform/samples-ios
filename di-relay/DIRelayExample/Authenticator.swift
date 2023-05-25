//
//  Authenticator.swift
//  DIRelayExample
//
//  Copyright © 2023 Anonyome Labs. All rights reserved.
//

import Foundation
import SudoUser
import SudoKeyManager

enum AuthenticatorError: LocalizedError {
    case registerFailed
    case alreadyRegistered
    case missingTestKey
    case missingTestKeyId

    var errorDescription: String? {
        switch self {
        case .registerFailed: return "Something went wrong while trying to register, inspect the logs for details"
        case .alreadyRegistered: return "Already registered"
        case .missingTestKey: return "Missing registration TEST key. Please follow instructions in the README"
        case .missingTestKeyId: return "Missing registration TEST key ID. Please follow instructions in the README"
        }
    }
}

class Authenticator {

    let fileReadable: FileReadable

    unowned let userClient: SudoUserClient
    let keyManager: SudoKeyManager

    init(userClient: SudoUserClient, keyManager: SudoKeyManager, fileReadable: FileReadable = DefaultFileReadable()) {
        self.userClient = userClient
        self.keyManager = keyManager
        self.fileReadable = fileReadable
    }

    func register() async throws {
        if try await userClient.isRegistered() { throw AuthenticatorError.alreadyRegistered }
        guard let testKeyPath = fileReadable.path(forResource: "register_key", ofType: "private") else {
            throw AuthenticatorError.missingTestKey
        }
        guard let testKeyIdPath = fileReadable.path(forResource: "register_key", ofType: "id") else {
            throw AuthenticatorError.missingTestKeyId
        }
        let testKey = try fileReadable.contentsOfFile(forPath: testKeyPath)
        let testKeyId = try fileReadable.contentsOfFile(forPath: testKeyIdPath).trimmingCharacters(in: .whitespacesAndNewlines)
        let provider = try TESTAuthenticationProvider(
            name: "testRegisterAudience",
            key: testKey,
            keyId: testKeyId,
            keyManager: keyManager
        )
        _ = try await userClient.registerWithAuthenticationProvider(
            authenticationProvider: provider,
            registrationId: UUID().uuidString
        )
    }

    func deregister() async throws -> String {
        try await userClient.deregister()
    }

    func reset() async throws {
        try await userClient.reset()
    }
}
