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

class SudoListViewControllerTests: XCTestCase {

    // MARK: - Properties

    var testUtility: EmailExampleTestUtility!
    var instanceUnderTest: SudoListViewController!

    // MARK: - Lifecycle

    @MainActor
    override func setUp() async throws {
        testUtility = EmailExampleTestUtility()
        testUtility.profilesClient.listSudosResult = [
            .init(
            title: "dummySudo",
            firstName: "first",
            lastName: "last",
            label: SudoProfilesClientMock.sudoLabel,
            notes: nil,
            avatar: nil
        )
        ]
        instanceUnderTest = testUtility.storyBoard.instantiateViewController(identifier: "sudoList")
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
        await waitForAsyncNoFail()
    }

    override func tearDown() {
        testUtility.clearWindow()
    }

    // MARK: - Tests

    @MainActor
    func test_ListSudosSucceeds() async throws {
        await waitForAsyncNoFail()
        instanceUnderTest.viewWillAppear(true)
        try await waitForAsync()
        let label = instanceUnderTest.tableView(instanceUnderTest.tableView, cellForRowAt: [0, 0]).textLabel?.text ?? ""
        XCTAssertEqual(label, SudoProfilesClientMock.sudoLabel)
        try await waitForAsync()
    }

    @MainActor
    func test_SudoListViewPropagatesError() async {
        await waitForAsyncNoFail()
        testUtility.profilesClient.listSudosResult = nil
        testUtility.profilesClient.listSudosError = SudoProfilesClientMock.defaultError
        instanceUnderTest.viewWillAppear(true)
        await waitForAsyncNoFail()
        let presentedAlert = instanceUnderTest.presentedViewController as? UIAlertController
        XCTAssertEqual(presentedAlert?.title, "Error")
        XCTAssertEqual(presentedAlert?.actions.first?.title, "OK")
        XCTAssertTrue(((presentedAlert?.message?.starts(with: "Failed to list Sudos")) == true))
        await waitForAsyncNoFail()
    }

    @MainActor
    func test_SudoListViewDeleteSudoPropagatesError() async {
        instanceUnderTest.viewWillAppear(true)
        let testSudo = Sudo()
        let result = await instanceUnderTest.deleteSudo(sudo: testSudo)
        XCTAssertFalse(result, "expected delete sudo to fail")
    }

    @MainActor
    func test_SudoLIstDeleteSudoSucceeds() async {
        testUtility.profilesClient.deleteSudoFailure = false
        instanceUnderTest.viewWillAppear(true)
        await waitForAsyncNoFail()
        let testSudo = Sudo()
        let result = await instanceUnderTest.deleteSudo(sudo: testSudo)
        XCTAssertTrue(result, "expected delete sudo to succeed")
    }

}
