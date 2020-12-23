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

enum LastSignInMethod: String {
    case none
    case fsso
    case test
}

class Authenticator {

    let userClient: SudoUserClient
    let keyManager: SudoKeyManager

    // Keep track of the last method used to sign in.  It helps know what kind of UI to show and actions to perform to get back to a clean state.
    @UserDefaultsBackedWithDefault(key: "lastSignInMethod", defaultValue: LastSignInMethod.none.rawValue)
    private var _lastSignInMethod: String

    var lastSignInMethod: LastSignInMethod {
        get {
            return LastSignInMethod(rawValue: _lastSignInMethod)!
        }
        set {
            _lastSignInMethod = newValue.rawValue
        }
    }


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
        }
        catch let error {
            NSLog("Pre-registration Failure: \(error)")
            completion(.failure(error))
        }
    }

    func doFSSOSignOut(from nav: UINavigationController, completion: ((Error?) -> Void)?) {
        do {
            let client = Clients.userClient!

                // Present the federated sign out screen.  This will likely trigger a "do you want to allow access" alert.
                try Clients.userClient!.presentFederatedSignOutUI(navigationController: nav) { (result) in
                    switch result {
                    case .success:

                        // After federated sign out succeeds, perform global sign out.
                        do {
                            try client.globalSignOut { (result) in
                                switch result {
                                case .success:
                                    // If global sign out succeeds, we still have to launch this `SFAuthenticationSession` to really
                                    // clear the auth cookies.  This will trigger another alert, and the user will have to close the blank
                                    // page that shows up when the logout page loads.
                                    self.clearSFAuthCookies(completion: completion)
                                case .failure(let cause):
                                    completion?(cause)
                                }
                            }
                        }
                        catch {
                            // If global sign out fails we still want to complete the sign out locally, otherwise we can be left in a bad
                            // state where the auth cookies cannot be cleared.
                            self.clearSFAuthCookies(completion: completion)
                            //completion?(error)
                        }
                    case .failure(let cause):
                        completion?(cause)
                    }
                }
            } catch let error {
                completion?(error)
            }
    }

    private func clearSFAuthCookies(completion: ((Error?) -> Void)?) {
        self.authSession = SFAuthenticationSession(url: URL(string: "https://dev-98hbdgse.auth0.com/v2/logout")!, callbackURLScheme: nil, completionHandler: { (callBack:URL?, error:Error? ) in
            // The only option for the user is to cancel to dismiss the webpage, so there will be an error.
            // that we need to ignore.
            self.lastSignInMethod = .none
            completion?(nil)
        })
        self.authSession?.start()
    }

    var authSession: SFAuthenticationSession?

    func registerAndSignIn(from nav: UINavigationController, completion: @escaping (Result<Void,Error>) -> Void) {
        let userClient: SudoUserClient = Clients.userClient

        func signIn() {
            do {
                if try userClient.isSignedIn() {
                    try? DefaultSudoEntitlementsClient(userClient: Clients.userClient).redeemEntitlements(completion: { (_) in })
                    completion(.success(()))
                    return
                }

                try userClient.signInWithKey { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        try? DefaultSudoEntitlementsClient(userClient: Clients.userClient).redeemEntitlements(completion: { (_) in })
                        self.lastSignInMethod = .test
                        completion(.success(()))
                    }
                }
            } catch let signInError {
                completion(.failure(signInError))
            }
        }

        if userClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            do {
                try userClient.presentFederatedSignInUI(navigationController: nav) { signInResult in
                    switch signInResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        self.lastSignInMethod = .fsso

                        // Redeem entitlements
                        try? DefaultSudoEntitlementsClient(userClient: Clients.userClient).redeemEntitlements(completion: { (_) in })
                        completion(.success(()))
                    }
                }
            } catch let signInError {
                completion(.failure(signInError))
            }
        } else {
            if userClient.isRegistered() {
                signIn()
            } else {
                self.register { registerResult in
                    switch registerResult {
                    case .failure(let error):
                        completion(.failure(error))
                    case .success:
                        signIn()
                    }
                }
            }
        }
    }

    func deregister(completion: @escaping (DeregisterResult) -> Void) throws {
        try self.userClient.deregister { (result) in
            if case .success(_) = result {
                self.lastSignInMethod = .none
            }
            completion(result)
        }
    }
}
