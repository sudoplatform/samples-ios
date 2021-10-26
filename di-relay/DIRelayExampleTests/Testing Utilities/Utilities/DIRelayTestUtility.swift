//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//


import XCTest
import UIKit
import SudoDIRelay
@testable import DIRelayExample

class DIRelayExampleTestUtility {

    // MARK: - Properties

    let window: UIWindow!
    let storyBoard: UIStoryboard
    let relayClient: SudoDIRelayClientMockSpy
    let appSyncClientHelper: MockAppSyncClientHelper

    // MARK: - Lifecycle

    init() throws {
        print(AppDelegate.mainStoryboard)
        window = UIWindow(frame: UIScreen.main.bounds)
        storyBoard = UIStoryboard(name: "Main", bundle: .main)
        appSyncClientHelper = try MockAppSyncClientHelper()
        relayClient = SudoDIRelayClientMockSpy()
        AppDelegate.dependencies = AppDependencies(
            appSyncClientHelper: appSyncClientHelper,
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
