//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoEmail
import SudoProfiles
@testable import EmailExample

class CreateSudoViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: CreateSudoViewController!

    // MARK: - Lifecycle

    @MainActor
    override func setUp() {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "createSudo")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Tests

    @MainActor
    func test_CreateSudoViewDisplaysCorrectly() async throws {
        try await waitForAsync()
        XCTAssertEqual(
            instanceUnderTest.labelTextField.placeholder,
            "Enter Sudo Label"
        )
        XCTAssertEqual(instanceUnderTest.learnMoreView.label.text?.starts(with: "Email addresses must belong to a Sudo"), true)
    }

    @MainActor
    func test_CreateSudoFailureIsPropagated() async {
        await instanceUnderTest.createSudo()
        XCTAssertTrue(
            testUtility.profilesClient.createSudoCalled,
            "Expected SudoProfilesClient.createSudo to be called"
        )
    }
}
