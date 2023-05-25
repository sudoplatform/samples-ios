//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import DIRelayExample
import SudoUser
import Foundation

class AuthenticatorMockSpy: Authenticator {

    static var defaultError: Error {
        return NSError(domain: "unit-test", code: 0, userInfo: nil) as Error
    }

    var registerCalled = false
    var registerResult: Result<Void, Error> = .failure(defaultError)
    func register(completion: @escaping (Result<Void, Error>) -> Void) {
        registerCalled = true
        completion(registerResult)
    }

    var deregisterCalled = false
    var deregisterResult: Result<String, Error> = .failure(defaultError)
    func deregister(completion: @escaping (Result<String, Error>) -> Void) throws {
        deregisterCalled = true
        completion(deregisterResult)
    }

    var resetCalled = false
    func reset() throws {
        resetCalled = true
    }
}
