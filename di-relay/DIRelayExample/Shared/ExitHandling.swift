//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//
import UIKit
import Foundation
import SudoProfiles
import SudoUser
import SudoDIRelay

// Handles actions when user taps Exit buttons.
protocol ExitHandling {
    var relayClient: SudoDIRelayClient { get }
    var sudoUserClient: SudoUserClient { get }
    var profilesClient: SudoProfilesClient { get }

    // MARK: - Deregistration and Sign Out

    /// Create an alert allowing the user to choose whether to sign out, deregister, or cancel.
    ///
    /// Unknown registration method does not require deregistration.
    /// DeviceCheck, TEST and FSSO registration methods permit both deregistration and sign out.
    ///
    /// Note that for FSSO deregistration, the user MUST still be signed in.
    ///
    /// - Parameter sender: Exit button.
    /// - Parameter postboxIds: Postbox ids to delete.
    func doExitButtonAction(_ sender: Any)

    /// Proceed to sign out the user depending on registration method.
    ///
    /// - Parameter sender: Sign out option.
    func doSignOutAlertAction(sender: UIAlertAction)

    /// Proceed to deregister the user depending on reigstration method.
    /// Delete postboxes from cache and backend upon deregistration.
    ///
    /// Note Tasks were manually used as this method is used with UI methods that don't accept async methods easily.
    ///
    /// - Parameter sender: Deregister option.
    func doDeregisterAlertAction(_ sender: UIAlertAction) async
}

extension ExitHandling where Self: UIViewController {

    // MARK: - Deregistration and Sign Out

    func doExitButtonAction(_ sender: Any) {
        let alert = UIAlertController(
            title: "Deregister or Sign Out",
            message: "Deregistering will delete all Sudos, postboxes, messages and associated data.",
            preferredStyle: .actionSheet
        )

        let signOutOption = UIAlertAction(title: "Sign out", style: .default, handler: doSignOutAlertAction.self)
        let deregisterOption = UIAlertAction(title: "Deregister", style: .default) { sender in
            Task(priority: .medium) {
                await self.doDeregisterAlertAction(sender)
            }
        }

        // Disable for unknown registration
        switch RegistrationMode.getRegistrationMode() {
        case .unknown:
            deregisterOption.isEnabled = false
        default:
            break
        }

        alert.addAction(signOutOption)
        alert.addAction(deregisterOption)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        self.present(alert, animated: true, completion: nil)
    }

    func doSignOutAlertAction(sender: UIAlertAction) {
        switch RegistrationMode.getRegistrationMode() {
        case .test:
            // Invalidate TEST registration keys to sign out
            Task {
                do {
                    try await signOutIfSignedIn()
                    RegistrationMode.setRegistrationMode(.test)
                    await self.performSegue(withIdentifier: "unwindToRegister", sender: self)
                } catch {
                    await self.presentErrorAlertOnMain("Could not sign out.", error: error)
                }
            }
        case .fsso, .unknown, .deviceCheck:
            // Should not be able to sign out with DeviceCheck, but unwind to start
            RegistrationMode.setRegistrationMode(RegistrationMode.getRegistrationMode())
            self.performSegue(withIdentifier: "unwindToRegister", sender: self)

        }
    }

    func doDeregisterAlertAction(_ sender: UIAlertAction) async {
        switch RegistrationMode.getRegistrationMode() {
        case .deviceCheck, .fsso, .test:
                await self.presentActivityAlertOnMain("Deregistering clients")
                // Note: federated users should not ideally be deregistered in the Sudo Platform
                do {
                    _ = try await deleteAllSudos()
                    try await sudoUserClient.reset()
                    try await profilesClient.reset()
                    // try self.profilesClient.generateEncryptionKey()
                    await self.dismissActivityAlert()

                    // Unwind back to registration view controller
                    Task {
                        RegistrationMode.setRegistrationMode(RegistrationMode.getRegistrationMode())
                        await self.performSegue(withIdentifier: "unwindToRegister", sender: self)
                    }
                } catch {
                    await self.presentErrorAlertOnMain("Failed to deregister", error: error)
                }
                await self.dismissActivityAlert()
        case .unknown:
            RegistrationMode.setRegistrationMode(.unknown)
            await self.performSegue(withIdentifier: "unwindToRegister", sender: self)

        }
    }

    /// Check whether user is signed in. If signed in, sign out of all devices.
    private func signOutIfSignedIn() async throws {
        guard try await sudoUserClient.isSignedIn() else {
            // Was already signed out
            return
        }

        do {
            try await sudoUserClient.globalSignOut()
        } catch {
            await self.presentErrorAlertOnMain("Could not sign out.", error: error)
            throw error
        }
    }

    // MARK: - Profiles Clean Up

    /// Iteratively delete all sudos given `sudos` list.
    ///
    /// - Returns: A list of errors that occured when deleting the sudos.
    private func deleteAllSudos() async throws {
        let sudos = try await profilesClient.listSudos(cachePolicy: .remoteOnly)
        try await withThrowingTaskGroup(of: Void.self) { group in
            for sudo in sudos {
                group.addTask {
                    try await self.profilesClient.deleteSudo(input: .init(sudoId: sudo.id, version: sudo.version))
                }
            }
            try await group.waitForAll()
        }
    }

    // MARK: - Helpers

    /// List postboxes owned by all Sudos owned by the user.
    ///
    /// - Returns: Every `Postbox`associated with the user.
    private func listAllPostboxes() async throws -> [Postbox] {
        var postboxes: [Postbox] = []
        var nextToken: String?

        repeat {
            let result = try await relayClient.listPostboxes(limit: nil, nextToken: nextToken)
            postboxes.append(contentsOf: result.items)
            nextToken = result.nextToken
        } while nextToken != nil

        return postboxes
    }

}
