//
//  Authenticator.swift
//  EmailExample
//
//  Copyright © 2020 Anonyome Labs. All rights reserved.
//

import Foundation
import SudoUser
import SudoKeyManager

enum AuthenticatorError: LocalizedError {
    case registerFailed
    case alreadyRegistered
    case missingTestKey
    case missingTestKeyId
    case unableToRefreshTokens

    // MARK: - LocalizedError

    var errorDescription: String? {
        switch self {
        case .registerFailed: return "Something went wrong while trying to register, inspect the logs for details"
        case .alreadyRegistered: return "Already registered"
        case .missingTestKey: return "Missing TEST registration key. Please follow instructions in the README"
        case .missingTestKeyId: return "Missing TEST registration key ID. Please follow instructions in the README"
        case .unableToRefreshTokens: return "Unable to perform refresh for existing authentication session"
        }
    }
}

protocol Authenticator {

    func register(completion: @escaping (Swift.Result<Void, Error>) -> Void)

    func deregister(completion: @escaping (Swift.Result<String, Error>) -> Void) throws

    func reset() throws

}

class DefaultAuthenticator: Authenticator {

    // MARK: - Properties

    let fileReadable: FileReadable

    let userClient: SudoUserClient

    let keyManager: SudoKeyManager

    init(userClient: SudoUserClient, keyManager: SudoKeyManager, fileReadable: FileReadable = DefaultFileReadable()) {
        self.userClient = userClient
        self.keyManager = keyManager
        self.fileReadable = fileReadable
    }

    // MARK: - Conformance: Authenticator

    func register(completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        // Read key files for TEST registration and attempt to register with SudoUserClient
        do {
            if userClient.isRegistered() {
                throw AuthenticatorError.alreadyRegistered
            }
            guard let testKeyPath = fileReadable.path(forResource: "register_key", ofType: "private") else {
                throw AuthenticatorError.missingTestKey
            }
            guard let testKeyIdPath = fileReadable.path(forResource: "register_key", ofType: "id") else {
                throw AuthenticatorError.missingTestKeyId
            }
            let testKey = try fileReadable.contentsOfFile(forPath: testKeyPath)
            let testKeyId = try fileReadable.contentsOfFile(forPath: testKeyIdPath).trimmingCharacters(in: .whitespacesAndNewlines)
            let provider = try TESTAuthenticationProvider(
                name: "DIRelayExample",
                key: testKey,
                keyId: testKeyId,
                keyManager: keyManager
            )
            try userClient.registerWithAuthenticationProvider(
                authenticationProvider: provider,
                registrationId: UUID().uuidString) { result in
                    switch result {
                    case .failure(let error):
                        NSLog("Registration Failure: \(error)")
                        completion(.failure(error))
                    case .success:
                        completion(.success(()))
                    }
            }
        } catch {
            NSLog("Pre-registration Failure: \(error)")
            completion(.failure(error))
        }
    }

    func deregister(completion: @escaping (Swift.Result<String, Error>) -> Void) throws {
        try userClient.deregister(completion: completion)
    }

    func reset() throws {
        try userClient.reset()
    }
}
