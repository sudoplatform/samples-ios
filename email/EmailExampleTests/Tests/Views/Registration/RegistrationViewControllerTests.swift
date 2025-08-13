//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import SudoUser
@testable import EmailExample

class RegistrationViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: RegistrationViewController!

    // MARK: - Lifecycle

    @MainActor
    override func setUp() {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "registration")
        instanceUnderTest.loadViewIfNeeded()
        instanceUnderTest.userClient = testUtility.userClient
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Tests: General

    func test_segueIdentifiers_containsNavigateToMainMenu() throws {
        XCTAssertSegueIdentifierExists(identifier: RegistrationViewController.Segue.navigateToMainMenu.rawValue, in: instanceUnderTest)
    }

    func test_registerButton_willInvokeRegisterButtonTapped_onTouchUpInside() throws {
        let actions = instanceUnderTest.registerButton.actions(forTarget: instanceUnderTest, forControlEvent: UIControl.Event.touchUpInside)
        XCTAssertEqual(actions?.contains("registerButtonTapped"), true)
    }

    // MARK: - Tests: Register Flow

    func test_registerButtonTapped_whenAlreadySignedIn_willNotInvokeSignInWithKeyOnUserClient() throws {
        testUtility.userClient.isSignedInReturn = true
        instanceUnderTest.registerButtonTapped()
        XCTAssertFalse(testUtility.userClient.signInWithKeyCalled)
    }

    @MainActor
    func test_registerButtonTapped_whenNotSignedIn_willInvokeSignInWithKeyOnUserClient() throws {
        testUtility.userClient.isSignedInReturn = false
        Task {
            instanceUnderTest.registerButtonTapped()
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2.0))
        XCTAssertTrue(testUtility.userClient.signInWithKeyCalled)
    }

    func test_registerButtonTapped_willDisableButton() throws {
        instanceUnderTest.registerButton.isEnabled = true
        instanceUnderTest.registerButtonTapped()
        XCTAssertFalse(instanceUnderTest.registerButton.isEnabled)
    }

    func test_registerButtonTapped_willStartAnimatingLoadingSpinner() throws {
        instanceUnderTest.activityIndicator.stopAnimating()
        instanceUnderTest.registerButtonTapped()
        XCTAssertTrue(instanceUnderTest.activityIndicator.isAnimating)
    }

    @MainActor
    func test_registerButtonTapped_signInSuccessful_willNavigateToMainMenu() throws {
        let resultTokens = AuthenticationTokens(idToken: "", accessToken: "", refreshToken: "")
        testUtility.userClient.isSignedInReturn = false
        testUtility.userClient.signInWithKeyResult = resultTokens
        testUtility.entitlementsClient.redeemEntitlementsResult = DataFactory.EntitlementsSDK.generateEntitlementsSet()
        Task {
            instanceUnderTest.registerButtonTapped()
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2.0))
        let presentedNavigation = instanceUnderTest.presentedViewController as? UINavigationController
        XCTAssertNotNil(presentedNavigation)
        XCTAssertTrue(presentedNavigation?.viewControllers.first is MainMenuViewController)
    }

    @MainActor
    func test_registerButtonTapped_signInFailure_willPresentErrorAlert() async throws {
        testUtility.userClient.isSignedInReturn = false
        testUtility.userClient.signInWithKeyError = createError()
        instanceUnderTest.registerButtonTapped()
        try await waitForAsync()
        instanceUnderTest.loadViewIfNeeded()
        try await waitForAsync()
        let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.title, "Error")
        XCTAssertEqual(presentedAlert?.actions.first?.title, "OK")
        try await waitForAsync()
    }

    @MainActor
    func test_registerButtonTapped_signInThrowsError_willPresentErrorAlert() throws {
        testUtility.userClient.isSignedInReturn = false
        testUtility.userClient.signInWithKeyError = createError()
        testUtility.entitlementsClient.redeemEntitlementsResult = DataFactory.EntitlementsSDK.generateEntitlementsSet()
        Task {
            instanceUnderTest.registerButtonTapped()
        }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 2.0))
        let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertNotNil(presentedAlert)
        XCTAssertEqual(presentedAlert?.title, "Error")
        XCTAssertEqual(presentedAlert?.actions.first?.title, "OK")
    }
}
