//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import UIKit
import SudoDIRelay
import SudoUser
@testable import DIRelayExample

class DIRelayExampleTestUtility {

    // MARK: - Properties

    let window: UIWindow!
    let storyBoard: UIStoryboard
    let relayClient: SudoDIRelayClientMockSpy
    let userClient: MockSudoUserClient
    let authenticator: AuthenticatorMockSpy

    // MARK: - Lifecycle

    init() throws {
        window = UIWindow(frame: UIScreen.main.bounds)
        storyBoard = UIStoryboard(name: "Main", bundle: .main)
        userClient = MockSudoUserClient()
        relayClient = SudoDIRelayClientMockSpy()
        authenticator = AuthenticatorMockSpy()
        AppDelegate.dependencies = AppDependencies(
            sudoUserClient: userClient,
            sudoDIRelayClient: relayClient,
            authenticator: authenticator
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
