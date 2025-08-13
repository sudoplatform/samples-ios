//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
import UIKit
import SudoEmail
@testable import SudoProfiles
@testable import EmailExample

class EmailAddressListViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: EmailAddressListViewController!

    var sudo = Sudo(id: "UnitTestSudoId", claims: [
        Claim(
         name: Sudo.ClaimName.label,
         value: .string(value: "UnitTestSudoLabel"),
         sudoId: "UnitTestSudoId",
         version: 1,
         algorithm: .aesCBCPKCS7Padding,
         keyId: UUID().uuidString
        )
     ], metadata: [:], createdAt: Date(), updatedAt: Date(), version: 0)

    var sudoWithNoLabel = Sudo(id: "UnitTestSudoId", claims: [], metadata: [:], createdAt: Date(), updatedAt: Date(), version: 0)

    // MARK: - Lifecycle

    @MainActor
    override func setUp() {
        testUtility = EmailExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "emailAddressList")
        instanceUnderTest.sudo = sudo
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    @MainActor
    func test_tableView_CellForRowAt_SingleEmailAddressIsDisplayed() throws {
        let emailAddress = DataFactory.EmailSDK.generateEmailAddress()
        instanceUnderTest.emailAddresses = [emailAddress]
        let result = instanceUnderTest.tableView(instanceUnderTest.tableView, cellForRowAt: [0, 0])
        XCTAssertEqual(result.textLabel?.text?.contains(emailAddress.emailAddress), true)
        guard let alias = emailAddress.alias else {
            return XCTFail("alias unexpectedly nil")
        }
        XCTAssertEqual(result.textLabel?.text?.contains(alias), true)
    }

    @MainActor
    func test_viewWillAppear_ErrorIsDisplayedForNoSudoLabel() async throws {
        instanceUnderTest.sudo = sudoWithNoLabel
        instanceUnderTest.viewWillAppear(false)
        try await waitForAsync()
        let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertEqual(presentedAlert?.title, "Error")
        XCTAssertEqual(presentedAlert?.actions.first?.title, "OK")
        XCTAssertEqual(presentedAlert?.message, "An error has occurred: no sudo label found")
    }

    @MainActor
    func test_tableView_didSelectRowAt_ZeroIndexSequesToCreateScreen() async throws {
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        try await waitForAsync()
        let resultTableViewController = instanceUnderTest.presentedViewController
        XCTAssertNotNil(resultTableViewController)
        XCTAssertTrue(resultTableViewController is CreateEmailAddressViewController)
    }

    @MainActor
    func test_tableView_didSelectRowAt_AddressIndexSequesToListViewScreen() async throws {
        instanceUnderTest.emailAddresses = [DataFactory.EmailSDK.generateEmailAddress()]
        instanceUnderTest.tableView(instanceUnderTest.tableView, didSelectRowAt: [0, 0])
        try await waitForAsync()
        let resultTableViewController = instanceUnderTest.presentedViewController
        XCTAssertNotNil(resultTableViewController)
        XCTAssertTrue(resultTableViewController is EmailMessageListViewController)
    }

    @MainActor
    func test_EmailAddressRowSwipeRequiresConfirmDelete() {
        instanceUnderTest.emailAddresses = [DataFactory.EmailSDK.generateEmailAddress()]
        let swipeActionsConfig = instanceUnderTest.tableView(
            instanceUnderTest.tableView,
            trailingSwipeActionsConfigurationForRowAt: [0, 0]
        )
        XCTAssertEqual(swipeActionsConfig?.actions[0].title, "Delete")
    }

    @MainActor
    func test_EmailAddressDeletionSucceeds() async {
        testUtility.emailClient.deprovisionEmailAddressResult = DataFactory.EmailSDK.generateEmailAddress()
        do {
            let result = try await instanceUnderTest.deleteEmailAddressWithId(self.testUtility.emailClient.emailAddress.emailAddress)
            XCTAssertEqual(
                result.emailAddress,
                self.testUtility.emailClient.emailAddress.emailAddress)
            XCTAssertEqual(
                result.alias,
                self.testUtility.emailClient.emailAddress.alias
            )
        } catch {
            XCTFail(error.localizedDescription)
        }
    }

    @MainActor
    func test_EmailAddressDeletionPropagatesFailure() async {
        // setup for failure
        testUtility.emailClient.emailAddress = DataFactory.EmailSDK.generateEmailAddress(
            address: "fail@test.org"
        )
        testUtility.emailClient.deprovisionEmailAddressResult = testUtility.emailClient.emailAddress
        do {
            let result = try await instanceUnderTest.deleteEmailAddressWithId(self.testUtility.emailClient.emailAddress.emailAddress)
            XCTFail("unexpected success result \(result)")
        } catch {
            XCTAssertTrue(error.localizedDescription.contains("unit-test error"))
        }
    }
}
