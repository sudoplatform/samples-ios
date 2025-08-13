//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoEmail
import SudoNotification

class SudoNotificationClientMock: SudoNotificationClient {
    let notifiableServices: [any SudoNotificationFilterClient] = [DefaultSudoEmailNotificationFilterClient()]

    func reset() throws {
        // no-op
    }

    var getNotificationConfigurationResult: NotificationConfiguration?
    var getNotificationConfigurationError = AnyError("Please add base result to `SudoNotificationClientMock.getNotificationConfiguration`")
    func getNotificationConfiguration(device: any NotificationDeviceInputProvider) async throws -> NotificationConfiguration {
        if getNotificationConfigurationResult != nil {
            return getNotificationConfigurationResult!
        }
        throw getNotificationConfigurationError
    }

    var deRegisterNotificationResult: Bool = true
    var deRegisterNotificationError = AnyError("Please add base result to `SudoNotificationClientMock.deRegisterNotification`")
    func deRegisterNotification(device: any NotificationDeviceInputProvider) async throws {
        if deRegisterNotificationResult {
            return
        }
        throw deRegisterNotificationError
    }

    var registerNotificationResult: Bool = true
    var registerNotificationError = AnyError("Please add base result to `SudoNotificationClientMock.registerNotification`")
    func registerNotification(device: any NotificationDeviceInputProvider) async throws {
        if registerNotificationResult {
            return
        }
        throw registerNotificationError
    }

    var setNotificationConfigurationResult: NotificationConfiguration?
    var setNotificationConfigurationError = AnyError("Please add base result to `SudoNotificationClientMock.setNotificationConfiguration`")
    func setNotificationConfiguration(config: SudoNotification.NotificationSettingsInput) async throws -> NotificationConfiguration {
        if setNotificationConfigurationResult != nil {
            return setNotificationConfigurationResult!
        }
        throw setNotificationConfigurationError
    }

    var updateNotificationRegistrationResult: Bool = true
    var updateNotificationRegistrationError = AnyError("Please add base result to `SudoNotificationClientMock.updateNotificationRegistration`")
    func updateNotificationRegistration(device: any SudoNotification.NotificationDeviceInputProvider) async throws {
        if updateNotificationRegistrationResult {
            return
        }
        throw updateNotificationRegistrationError
    }

    var getUserNotificationConfigurationResult: SudoNotification.NotificationConfiguration?
    var getUserNotificationConfigurationError = AnyError("Please add base result to `SudoNotificationClientMock.getUserNotificationConfiguration`")
    func getUserNotificationConfiguration(bundleId: String) async throws -> SudoNotification.NotificationConfiguration? {
        if getUserNotificationConfigurationResult != nil {
            return getUserNotificationConfigurationResult!
        }
        throw getUserNotificationConfigurationError
    }

    var getUserAndDeviceNotificationConfigurationResult: SudoNotification.UserAndDeviceNotificationConfiguration?
    var getUserAndDeviceNotificationConfigurationError = AnyError(
        "Please add base result to `SudoNotificationClientMock.getUserAndDeviceNotificationConfiguration`"
    )
    func getUserAndDeviceNotificationConfiguration(
        device: any SudoNotification.NotificationDeviceInputProvider
    ) async throws -> SudoNotification.UserAndDeviceNotificationConfiguration {
        if getUserAndDeviceNotificationConfigurationResult != nil {
            return getUserAndDeviceNotificationConfigurationResult!
        }
        throw getUserAndDeviceNotificationConfigurationError
    }

    var setUserNotificationConfigurationResult: SudoNotification.NotificationConfiguration?
    var setUserNotificationConfigurationError = AnyError("Please add base result to `SudoNotificationClientMock.setUserNotificationConfiguration`")
    func setUserNotificationConfiguration(config: SudoNotification.UserNotificationSettingsInput) async throws -> SudoNotification.NotificationConfiguration {
        if setUserNotificationConfigurationResult != nil {
            return setUserNotificationConfigurationResult!
        }
        throw setUserNotificationConfigurationError
    }

}
