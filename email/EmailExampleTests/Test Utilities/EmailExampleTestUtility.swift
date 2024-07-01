//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoUser
import SudoKeyManager
import SudoProfiles
@testable import EmailExample

class EmailExampleTestUtility {

    // MARK: - Properties

    let window: UIWindow!
    let storyBoard: UIStoryboard
    let userClient: MockSudoUserClient
    let profilesClient: SudoProfilesClientMock
    let emailClient: SudoEmailClientMockSpy
    let entitlementsClient: SudoEntitlementsClientMock
    let notificationClient: SudoNotificationClientMock
    let authenticator: AuthenticatorMockSpy

    // MARK: - Lifecycle

    init() {
        window = UIWindow(frame: UIScreen.main.bounds)
        storyBoard = UIStoryboard(name: "Main", bundle: Bundle.main)
        userClient = MockSudoUserClient()
        profilesClient = SudoProfilesClientMock()
        emailClient = SudoEmailClientMockSpy()
        entitlementsClient = SudoEntitlementsClientMock()
        notificationClient = SudoNotificationClientMock()
        authenticator = AuthenticatorMockSpy()
        AppDelegate.dependencies = AppDependencies(
            userClient: userClient,
            profilesClient: profilesClient,
            emailClient: emailClient,
            entitlementsClient: entitlementsClient,
            emailNotificationFilterClient: DefaultSudoEmailNotificationFilterClient(),
            notificationClient: notificationClient,
            authenticator: authenticator)
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
