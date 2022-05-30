//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoUser
import SudoKeyManager
@testable import DIRelayExample

class AuthenticatorTests: XCTestCase {

    // MARK: - Properties

    var instanceUnderTest: Authenticator!
    var testUtility: DIRelayExampleTestUtility!
    var userClient: MockSudoUserClient!
    var keyManager: SudoKeyManager!
    var fileReadable: FileReadableMock!

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        userClient = testUtility.userClient
        keyManager = testUtility.keyManager
        fileReadable = FileReadableMock()
        instanceUnderTest = Authenticator(userClient: userClient, keyManager: keyManager, fileReadable: fileReadable)

    }

    // MARK: - Helpers

    func performRegisterFailureTest(expectedError: AuthenticatorError, file: StaticString = #file, line: UInt = #line) async  {
        do {
            _ = try await self.instanceUnderTest.register()
            XCTFail("Unexpected success. ", file: file, line: line)
        } catch {
            switch error {
                case let authenticatorError as AuthenticatorError:
                XCTAssertEqual(authenticatorError, expectedError, file: file, line: line)
            default:
                XCTFail("Unexpected error. \(error)")
            }
        }
    }

    // MARK: - Tests

    func test_init() {
        let instanceUnderTest = Authenticator(userClient: userClient, keyManager: keyManager)
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
