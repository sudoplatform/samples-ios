//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoEmail
import SudoNotification

final class EmailAddressSettingsViewController: UIViewController {

    /// Segues that are performed in `EmailAddressSettingsViewController`.
    enum Segue: String {
        /// Used to navigate back to the `EmailMessageListViewController`.
        case returnToEmailMessageList
    }

    // MARK: - Properties: Computed

    /// Notification client used to manage notification configuration
    var notificationClient: SudoNotificationClient = AppDelegate.dependencies.notificationClient

    // MARK: - Properties: Set by prior view

    /// `EmailAddress` that was selected from a previous view.
    var emailAddress: EmailAddress!

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureSwitch()
    }

    // MARK: - Outlets

    @IBOutlet var notificationsEnabledSwitch: UISwitch!

    // MARK: - Actions

    @IBAction func switchValueDidChange(sender: UISwitch) {
        let newConfig =
            AppDelegate.dependencies.notificationConfiguration!
                .setEmailNotificationsForAddressId(
                    emailAddressId: emailAddress.id, enabled: sender.isOn
                )

        Task.detached(priority: .medium) {
            await self.updateNotificatonConfiguration(config: newConfig)
        }
    }

    // MARK: - Helpers

    func configureSwitch() {
        notificationsEnabledSwitch.isOn =
            AppDelegate.dependencies
                .notificationConfiguration!
                .areNotificationsEnabled(
                    forEmailAddressWithId: emailAddress.id
                )
    }

    func updateNotificatonConfiguration(config: NotificationConfiguration) async {
        let input = NotificationSettingsInput(
            bundleId: AppDelegate.dependencies.deviceInfo.bundleId,
            deviceId: AppDelegate.dependencies.deviceInfo.deviceId,
            filter: config.configs,
            services: [AppDelegate.dependencies.emailNotificationFilterClient.getSchema()])

        do {
            let updatedConfig = try await notificationClient.setNotificationConfiguration(config: input)
            AppDelegate.dependencies.notificationConfiguration = updatedConfig
        } catch {
            NSLog("Error updating notification configuration \(error)")

            presentErrorAlert(message: "Unable to update notification configuration: \(error.localizedDescription)", error: error)
        }
    }
}
