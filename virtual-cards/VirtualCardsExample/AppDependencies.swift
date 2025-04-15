//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import UIKit
import SudoVirtualCards
import SudoUser
import SudoEntitlements
import SudoKeyManager
import SudoProfiles
import SudoIdentityVerification
import SudoNotification

struct DeviceDataHolder {
    var pushTokenRegistered: Bool = false
    var pushToken: Data?
    let deviceId: String
    let bundleId: String

    init(deviceId: String, bundleId: String) {
        self.deviceId = deviceId
        self.bundleId = bundleId
    }
}

struct AppDependencies {

    // MARK: - Properties

    let userClient: SudoUserClient
    let entitlementsClient: SudoEntitlementsClient
    let profilesClient: SudoProfilesClient
    let identityVerificationClient: SudoIdentityVerificationClient
    let keyManager: SudoKeyManager
    let authenticator: Authenticator
    let virtualCardsNotificationFilterClient: SudoNotificationFilterClient
    let notificationClient: SudoNotificationClient
    let virtualCardsClient: SudoVirtualCardsClient

    var deviceInfo: DeviceDataHolder
    var notificationConfiguration: NotificationConfiguration?

    // MARK: - Lifecycle

    init(
        userClient: SudoUserClient,
        entitlementsClient: SudoEntitlementsClient,
        profilesClient: SudoProfilesClient,
        identityVerificationClient: SudoIdentityVerificationClient,
        keyManager: SudoKeyManager,
        authenticator: Authenticator,
        virtualCardsNotificationFilterClient: SudoNotificationFilterClient,
        notificationClient: SudoNotificationClient,
        virtualCardsClient: SudoVirtualCardsClient
    ) {
        self.userClient = userClient
        self.entitlementsClient = entitlementsClient
        self.profilesClient = profilesClient
        self.identityVerificationClient = identityVerificationClient
        self.keyManager = keyManager
        self.authenticator = authenticator
        self.virtualCardsNotificationFilterClient = virtualCardsNotificationFilterClient
        self.notificationClient = notificationClient
        self.virtualCardsClient = virtualCardsClient

        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            fatalError("Cannot get device ID")
        }

        guard let bundleId = Bundle.main.bundleIdentifier else {
            fatalError("Cannot get bundle ID")
        }

        self.deviceInfo = DeviceDataHolder(deviceId: deviceId, bundleId: bundleId)
    }

    init() throws {
        // Setup UserClient
        let userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        let keyManager = LegacySudoKeyManager(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "vcs")
        let virtualCardsNotificationFilterClient = DefaultSudoVirtualCardsNotificationFilterClient()

        self.init(
            userClient: userClient,
            entitlementsClient: try DefaultSudoEntitlementsClient(userClient: userClient),
            profilesClient: try DefaultSudoProfilesClient(sudoUserClient: userClient),
            identityVerificationClient: try DefaultSudoIdentityVerificationClient(sudoUserClient: userClient),
            keyManager: keyManager,
            authenticator: Authenticator(userClient: userClient, keyManager: keyManager),
            virtualCardsNotificationFilterClient: virtualCardsNotificationFilterClient,
            notificationClient: try DefaultSudoNotificationClient(userClient: userClient, notifiableServices: [virtualCardsNotificationFilterClient]),
            virtualCardsClient: try DefaultSudoVirtualCardsClient(keyNamespace: "vcs", userClient: userClient)
        )
    }
}
