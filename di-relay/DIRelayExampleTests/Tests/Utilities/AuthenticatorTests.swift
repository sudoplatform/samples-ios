//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoUser
@testable import DIRelayExample

class AuthenticatorTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: DefaultAuthenticator!

    var userClient: MockSudoUserClient!
    var keyManager: KeyManagerMock!
    var fileReadable: FileReadableMock!

    // MARK: - Lifecycle

    override func setUp() {
        userClient = MockSudoUserClient()
        keyManager = KeyManagerMock()
        fileReadable = FileReadableMock()
        instanceUnderTest = DefaultAuthenticator(userClient: userClient, keyManager: keyManager, fileReadable: fileReadable)
    }

    // MARK: - Helpers

    func performRegisterFailureTest(expectedError: AuthenticatorError, file: StaticString = #file, line: UInt = #line) {
        waitUntil { done in
            self.instanceUnderTest.register { result in
                defer { done() }
                switch result {
                case let .failure(error as AuthenticatorError):
                    XCTAssertEqual(error, expectedError, file: file, line: line)
                default:
                    XCTFail("Unexpected result: \(result)", file: file, line: line)
                }
            }
        }
    }

    // MARK: - Tests

    func test_init() {
        let instanceUnderTest = DefaultAuthenticator(userClient: userClient, keyManager: keyManager)
        XCTAssertTrue(instanceUnderTest.userClient === userClient)
    }

    func test_register_IsRegistered_ReturnsAlreadyRegistered() {
        userClient.isRegisteredReturn = true
        performRegisterFailureTest(expectedError: .alreadyRegistered)
    }

    func test_register_NoTestKey_ReturnsError() {
        userClient.isRegisteredReturn = false
        fileReadable.pathResult = nil
        performRegisterFailureTest(expectedError: .missingTestKey)
    }

    func test_register_NoTestKeyId_ReturnsError() {
        userClient.isRegisteredReturn = false
        // Load register_key.private but not register_key.id
        fileReadable.pathResults.append("dummyRegisterKey_Private")
        performRegisterFailureTest(expectedError: .missingTestKeyId)
    }

    func test_deregister() throws {
        try instanceUnderTest.deregister(completion: {_ in })
        XCTAssertTrue(userClient.deregisterCalled)
    }

    func test_reset() throws {
        try instanceUnderTest.reset()
        XCTAssertTrue(userClient.resetCalled)
    }

}
