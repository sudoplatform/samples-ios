//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSMobileClient
import Foundation
import SudoSiteReputation
import SudoKeyManager
import SudoUser

class Clients {
    static private(set) var userClient: SudoUserClient!
    static private(set) var keyManager: SudoKeyManager!
    static private(set) var authenticator: Authenticator!
    static private(set) var legacySiteReputationClient: LegacySudoSiteReputationClient!
    static private(set) var siteReputationClient: SudoSiteReputationClient!
    

    static func configure() throws {
        self.userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        self.keyManager = LegacySudoKeyManager(serviceName: "com.sudoplatform.sitereputation", keyTag: "com.sudoplatform", namespace: "client")
        self.authenticator = Authenticator(userClient: userClient, keyManager: keyManager)
        self.legacySiteReputationClient = try DefaultLegacySiteReputationClient(userClient: userClient)
        self.siteReputationClient = try DefaultSudoSiteReputationClient(userClient: self.userClient)
    }

    static func resetClients() async {
        do {
            try await userClient.reset()
            try await legacySiteReputationClient.clearStorage()
        } catch let error {
            NSLog("Failed to reset clients: \(error)")
        }

    }

    static func deregisterClients() async throws {
        do {
            _ = try await authenticator.deregister()
        } catch {
            NSLog("Failed to deregister: \(error)")
        }
    }
}

extension Clients {
    static func deregisterWithAlert() {
        let alert = UIAlertController(title: "Are you sure?", message: "This will attempt to deregister any accounts with the Sudo Platform service and clear any keys associated with accounts connected with this device. It is meant as option of last resort if you are unable to login or register and cannot be undone.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { (_) in
            UIApplication.shared.topController?.presentActivityAlert(message: "Deregistering")

            Task {
                await self.resetClients()
                do {
                    try await self.deregisterClients()
                    await UIApplication.shared.rootController?.dismiss(animated: true, completion: nil)
                } catch {
                    NSLog("Failed to deregister: \(error)")
                    await UIApplication.shared.topController?.dismiss(animated: true, completion: nil)
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { (_) in
        }))

        UIApplication.shared.topController?.present(alert, animated: true, completion: nil)
    }
}
