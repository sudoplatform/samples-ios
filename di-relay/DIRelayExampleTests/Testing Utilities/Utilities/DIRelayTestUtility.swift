//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import UIKit
import SudoDIRelay
import SudoKeyManager
import SudoUser
@testable import DIRelayExample

class DIRelayExampleTestUtility {

    // MARK: - Properties

    let window: UIWindow!
    let storyBoard: UIStoryboard
    let userClient: MockSudoUserClient
    let entitlementsClient: MockSudoEntitlementsClient
    let profilesClient: MockSudoProfilesClient
    let keyManager: SudoKeyManager
    let authenticator: AuthenticatorMockSpy
    let relayClient: SudoDIRelayClientMockSpy

    // MARK: - Lifecycle

    init() {
        window = UIWindow(frame: UIScreen.main.bounds)
        storyBoard = UIStoryboard(name: "Main", bundle: .main)
        userClient = MockSudoUserClient()
        entitlementsClient = MockSudoEntitlementsClient()
        profilesClient = MockSudoProfilesClient()
        keyManager = MockKeyManager()
        authenticator = AuthenticatorMockSpy(userClient: userClient, keyManager: keyManager)
        relayClient = SudoDIRelayClientMockSpy()

        AppDelegate.dependencies = AppDependencies(
            sudoUserClient: userClient,
            entitlementsClient: entitlementsClient,
            profilesClient: profilesClient,
            keyManager: keyManager,
            authenticator: authenticator,
            sudoDIRelayClient: relayClient
        )
    }

    deinit {
        clearWindow()
    }

    /// Will remove all subviews from the window and `nil` out the root view controller
    func clearWindow() {
        window.subviews.forEach { $0.removeFromSuperview() }
        window.rootViewController = nil
    }
}
