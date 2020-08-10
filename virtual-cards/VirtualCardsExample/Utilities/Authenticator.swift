//
//  Authenticator.swift
//  VirtualCardsExample
//
//  Copyright © 2020 Anonyome Labs. All rights reserved.
//

import Foundation
import SudoUser
import SudoKeyManager
@testable import SudoVirtualCards

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

    let userClient: SudoUserClient
    let keyManager: SudoKeyManager

    init(userClient: SudoUserClient, keyManager: SudoKeyManager) {
        self.userClient = userClient
        self.keyManager = keyManager
    }

    func register(completion: @escaping (Swift.Result<Void, Error>) -> Void) {
        do {
            if userClient.isRegistered() { throw AuthenticatorError.alreadyRegistered }
            guard let testKeyPath = Bundle.main.path(forResource: "register_key", ofType: "private") else {
                throw AuthenticatorError.missingTestKey
            }
            guard let testKeyIdPath = Bundle.main.path(forResource: "register_key", ofType: "id") else {
                throw AuthenticatorError.missingTestKeyId
            }

            let testKey = try String(contentsOfFile: testKeyPath)
            let testKeyId = try String(contentsOfFile: testKeyIdPath).trimmingCharacters(in: .whitespacesAndNewlines)
            let provider = try TESTAuthenticationProvider(
                name: "testRegisterAudience",
                key: testKey,
                keyId: testKeyId,
                keyMananger: keyManager
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
        } catch let error {
            NSLog("Pre-registration Failure: \(error)")
            completion(.failure(error))
        }
    }
}
