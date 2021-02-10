//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoUser
import SudoKeyManager
import UIKit
import SafariServices
import AuthenticationServices
import SudoEntitlements

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
    let entitlementsClient: SudoEntitlementsClient

    // Keep track of the last method used to sign in.  It helps know what kind of UI to show and actions to perform to get back to a clean state.
    @UserDefaultsBackedWithDefault(key: "lastSignInMethod", defaultValue: ChallengeType.unknown.rawValue)
    private var _lastSignInMethod: String

    internal private(set) var lastSignInMethod: ChallengeType {
        get {
            return ChallengeType(rawValue: _lastSignInMethod) ?? .unknown
        }
        set {
            _lastSignInMethod = newValue.rawValue
        }
    }


    init(userClient: SudoUserClient, keyManager: SudoKeyManager, entitlementsClient: SudoEntitlementsClient) {
        self.userClient = userClient
        self.keyManager = keyManager
        self.entitlementsClient = entitlementsClient
    }

    private func register(completion: @escaping (Swift.Result<Void, Error>) -> Void) {
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
                keyManager: keyManager
            )
            try userClient.registerWithAuthenticationProvider(
                authenticationProvider: provider,
                registrationId: UUID().uuidString
            ) { result in
                switch result {
                case .failure(let error):
                    NSLog("Registration Failure: \(error)")
                    completion(.failure(error))
                case .success:
                    completion(.success(()))
                }
            }
        }
        catch let error {
            NSLog("Pre-registration Failure: \(error)")
            completion(.failure(error))
        }
    }

    func doFSSOSignOut(from anchor: UIWindow, completion: ((Error?) -> Void)?) {
        do {
            // Present the federated sign out screen.  This will likely trigger a "do you want to allow access" alert.
            try Clients.userClient!.presentFederatedSignOutUI(presentationAnchor: anchor) { (result) in
                // There is no way to tap into the authentication session's UI dismissal, so we have issues
                // dismissing view controllers after sign out.  As a general fix we can delay the completion handler
                // for one second to let things settle.
                //
                //https://developer.apple.com/forums/thread/123667
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    switch result {
                    case .success:
                        print("Successly signed out.")
                        self.lastSignInMethod = .unknown
                        completion?(nil)
                    case .failure(let cause):
                        completion?(cause)
                    }
                }
            }
        } catch let error {
            completion?(error)
        }
    }

    func registerAndSignIn(from anchor: UIWindow, signInMethod: ChallengeType, completion: @escaping (Result<Void, Error>) -> Void) {
        let userClient: SudoUserClient = Clients.userClient

        func signInWithTestKey() {
            do {
                if try userClient.isSignedIn() {
                    self.entitlementsClient.redeemEntitlements() { result in }
                    completion(.success(()))
                    return
                }

                try userClient.signInWithKey { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        self.lastSignInMethod = .test
                        self.entitlementsClient.redeemEntitlements() { result in }
                        completion(.success(()))
                    }
                }
            } catch let signInError {
                completion(.failure(signInError))
            }
        }

        switch signInMethod {
        case .fsso:
            do {
                try userClient.presentFederatedSignInUI(presentationAnchor: anchor) { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        self.lastSignInMethod = .fsso
                        self.entitlementsClient.redeemEntitlements() { result in }
                        completion(.success(()))
                    }
                }
            } catch let signInError {
                completion(.failure(signInError))
            }
        case .test:
            if userClient.isRegistered() {
                signInWithTestKey()
            } else {
                self.register { registerResult in
                    switch registerResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        signInWithTestKey()
                    }
                }
            }
        default:
            break
        }
    }

    func deregister(completion: @escaping (Result<String, Error>) -> Void) throws {
        try self.userClient.deregister { (result) in
            if case .success(_) = result {
                self.lastSignInMethod = .unknown
            }
            completion(result)
        }
    }
}
