
//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoDIRelay
import SudoUser
@testable import DIRelayExample

class RegistrationViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: RegistrationViewController!

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "register")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        do {
            try testUtility.relayClient.reset()
        } catch {
            print("Unable to tear down after test. \(error)")
        }
    }

    // MARK: - Tests: General

    func test_segueIdentifiers_containsNavigateToPostboxes() throws {

    }

    func test_registerButton_willInvokeRegisterButtonTapped_onTouchUpInside() throws {
        let actions = instanceUnderTest.registerButton.actions(forTarget: instanceUnderTest, forControlEvent: UIControl.Event.touchUpInside)
        XCTAssertEqual(actions?.contains("registerButtonTapped"), true)
    }

    // MARK: - Tests: Register Flow

    @MainActor func test_registerButtonTapped_TESTRegistrationEnabled_willRegisterWithTESTRegistration() async throws {
        testUtility.userClient.isRegisteredReturn = false
        testUtility.userClient.isGetSupportedRegistrationChallengeTypeReturn = [ChallengeType.test]
        testUtility.authenticator.registerResult = .success(())
       // testUtility.userClient.presentFederatedSignInUIResult = .success(resultTokens)
        instanceUnderTest.registerButtonTapped()
        await instanceUnderTest.registerTask?.value
        XCTAssertEqual(RegistrationMode.getRegistrationMode(), .test)
    }

    func test_registerButtonTapped_whenAlreadySignedIn_willNotInvokeSignInWithKeyOnUserClient() throws {
        testUtility.userClient.isSignedInReturn = true
        instanceUnderTest.registerButtonTapped()
        XCTAssertFalse(testUtility.userClient.signInWithKeyCalled)
    }

    func test_registerButtonTapped_signInSuccessful_willSegueToPostboxView() throws {
        testUtility.userClient.isRegisteredReturn = true
        testUtility.userClient.isSignedInReturn = false
        let resultTokens = AuthenticationTokens(idToken: "", accessToken: "", refreshToken: "")
        testUtility.userClient.signInWithKeyResult = resultTokens

        instanceUnderTest.registerButtonTapped()
        waitForAsync()
        XCTAssertTrue(instanceUnderTest.shouldPerformSegue(withIdentifier: "navigateToPostboxes", sender: ["mock-id"]))
    }
}
