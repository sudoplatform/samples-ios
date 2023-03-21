//
//  Authenticator.swift
//  EmailExample
//
//  Copyright © 2020 Anonyome Labs. All rights reserved.
//

import Foundation
import SudoUser
import SudoKeyManager
import AWSAppSync

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
        case .missingTestKey: return "Missing registration TEST key. Please follow instructions in the README"
        case .missingTestKeyId: return "Missing registration TEST key ID. Please follow instructions in the README"
        case .unableToRefreshTokens: return "Unable to perform refresh for existing authentication session"
        }
    }
}

protocol Authenticator {

    func register() async throws

    func deregister() async throws -> String

    func reset() async throws

}

class DefaultAuthenticator: Authenticator {

    // MARK: - Properties

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
        do {
            return try await userClient.deregister()
        } catch SudoUserClientError.graphQLError(let cause) {
            guard let err = cause.first else {
                fatalError("No Error in cause")
            }
            guard let appSyncError = err as? AWSAppSyncClientError else {
                throw err
            }
            let error: GraphQLAuthProviderError
            switch appSyncError {
            case .authenticationError(let authError):
                guard let gqlError = authError as? GraphQLAuthProviderError else {
                    fallthrough
                }
                error = gqlError
            default:
                throw appSyncError
            }
            switch error {
            case .notAuthorized:
                // refresh tokens and try again
                do {
                    _ = try await userClient.refreshTokens()
                } catch {
                    _ = try await userClient.signInWithKey()
                }
                return try await userClient.deregister()
            default:
                throw error
            }
        }
    }

    func reset() async throws {
        try await userClient.reset()
    }
}
