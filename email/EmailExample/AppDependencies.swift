//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEmail
import SudoKeyManager
import SudoProfiles
import SudoUser
import SudoEntitlements
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
    let profilesClient: SudoProfilesClient
    let entitlementsClient: SudoEntitlementsClient
    let emailNotificationFilterClient: SudoNotificationFilterClient
    let notificationClient: SudoNotificationClient
    let emailClient: SudoEmailClient
    let authenticator: Authenticator

    var deviceInfo: DeviceDataHolder
    var notificationConfiguration: NotificationConfiguration?

    // MARK: - Lifecycle

    init(
        userClient: SudoUserClient,
        profilesClient: SudoProfilesClient,
        emailClient: SudoEmailClient,
        entitlementsClient: SudoEntitlementsClient,
        emailNotificationFilterClient: SudoNotificationFilterClient,
        notificationClient: SudoNotificationClient,
        authenticator: Authenticator
    ) {
        self.userClient = userClient
        self.profilesClient = profilesClient
        self.entitlementsClient = entitlementsClient
        self.emailNotificationFilterClient = emailNotificationFilterClient
        self.notificationClient = notificationClient
        self.emailClient = emailClient
        self.authenticator = authenticator

        guard let deviceId = UIDevice.current.identifierForVendor?.uuidString else {
            fatalError("Cannot get device ID")
        }

        guard let bundleId = Bundle.main.bundleIdentifier else {
            fatalError("Cannot get bundle ID")
        }

        self.deviceInfo = DeviceDataHolder(deviceId: deviceId, bundleId: bundleId)
    }

    init() throws {
        let storageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]

        let keyManager = LegacySudoKeyManager(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "eml")

        let newUserClient = try DefaultSudoUserClient(keyNamespace: "ids")

        let emailNotificationFilterClient = DefaultSudoEmailNotificationFilterClient()

        self.init(
            userClient: newUserClient,
            profilesClient: try DefaultSudoProfilesClient(sudoUserClient: newUserClient, blobContainerURL: storageURL),
            emailClient: try DefaultSudoEmailClient(keyNamespace: "eml", userClient: newUserClient),
            entitlementsClient: try DefaultSudoEntitlementsClient(userClient: newUserClient),
            emailNotificationFilterClient: emailNotificationFilterClient,
            notificationClient: try DefaultSudoNotificationClient(userClient: newUserClient, notifiableServices: [emailNotificationFilterClient]),
            authenticator: DefaultAuthenticator(userClient: newUserClient, keyManager: keyManager)
        )
    }
}
