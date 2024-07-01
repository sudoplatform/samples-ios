//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoUser
@testable import EmailExample

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

    func performRegisterFailureTest(expectedError: AuthenticatorError, file: StaticString = #file, line: UInt = #line) async {
        do {
            try await instanceUnderTest.register()
            XCTFail("Unexpected success", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? AuthenticatorError, expectedError, file: file, line: line)
        }
    }

    // MARK: - Tests

    func test_init() {
        let instanceUnderTest = DefaultAuthenticator(userClient: userClient, keyManager: keyManager)
        XCTAssertTrue(instanceUnderTest.userClient === userClient)
    }

    func test_register_IsRegistered_ReturnsAlreadyRegistered() async {
        userClient.isRegisteredReturn = true
        await performRegisterFailureTest(expectedError: .alreadyRegistered)
    }

    func test_register_NoTestKey_ReturnsError() async {
        userClient.isRegisteredReturn = false
        fileReadable.pathResult = nil
        await performRegisterFailureTest(expectedError: .missingTestKey)
    }

    func test_register_NoTestKeyId_ReturnsError() async {
        userClient.isRegisteredReturn = false
        // Load register_key.private but not register_key.id
        fileReadable.pathResults.append("dummyRegisterKey_Private")
        await performRegisterFailureTest(expectedError: .missingTestKeyId)
    }

    func test_deregister() async throws {
        _ = try await instanceUnderTest.deregister()
        XCTAssertTrue(userClient.deregisterCalled)
    }

    func test_reset() async throws {
        try await instanceUnderTest.reset()
        XCTAssertTrue(userClient.resetCalled)
    }

}
