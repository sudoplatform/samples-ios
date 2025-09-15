//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import XCTest
@testable import SudoProfiles

@testable import DIRelayExample

class ExitHandlingTests: XCTestCase {

    // MARK: - Properties

    var testUtility: DIRelayExampleTestUtility!
    var instanceUnderTest: PostboxesViewController!
    let sudo = Sudo(id: "id", claims: [], metadata: [:], createdAt: Date(), updatedAt: Date(), version: 0)

    // MARK: - Lifecycle

    override func setUp() {
        testUtility = DIRelayExampleTestUtility()
        instanceUnderTest = testUtility.storyBoard.resolveViewController(identifier: "postboxList")
        instanceUnderTest.sudo = sudo
        instanceUnderTest.ownershipProofs = [sudo.id: "proof"]
        instanceUnderTest.loadViewIfNeeded()
        testUtility.window.rootViewController = instanceUnderTest
        testUtility.window.makeKeyAndVisible()
    }

    func test_doExitButtonAction_ShowsAlert() {
        instanceUnderTest.doExitButtonAction(self)
        guard let resultTableViewController = instanceUnderTest.presentedViewController else {
            return XCTFail("Failed to get presented view controller")
        }

        XCTAssertTrue(resultTableViewController is UIAlertController)
    }

    func test_doDeregisterAlertAction_UnwindsToRegister() async {
        RegistrationMode.setRegistrationMode(.fsso)
        testUtility.profilesClient.listSudosResult = []
        await instanceUnderTest.doDeregisterAlertAction(UIAlertAction(title: "", style: .cancel, handler: nil))

        XCTAssertTrue(testUtility.relayClient.listPostboxesCalled)
        XCTAssertTrue(testUtility.userClient.resetCalled)
    }

}
