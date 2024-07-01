//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@testable import EmailExample
import SudoUser
import Foundation

class AuthenticatorMockSpy: Authenticator {

    static var defaultError: Error {
        return NSError(domain: "unit-test", code: 0, userInfo: nil) as Error
    }

    var registerCalled = false
    var registerFail = false
    var registerError = defaultError
    func register() async throws {
        registerCalled = true
        if registerFail {
            throw registerError
        }
    }

    var deregisterCalled = false
    var deregisterResult: String?
    var deregisterError = defaultError
    func deregister() async throws -> String {
        deregisterCalled = true
        if deregisterResult != nil {
            return deregisterResult!
        }
        throw deregisterError
    }

    var resetCalled = false
    func reset() throws {
        resetCalled = true
    }
}
