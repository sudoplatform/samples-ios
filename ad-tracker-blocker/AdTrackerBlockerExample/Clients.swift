//
//  Clients.swift
//  AdTrackerBlockerExample
//
//  Copyright © 2020 Sudo Platform. All rights reserved.
//

import Foundation
import SudoAdTrackerBlocker
import SudoEntitlements
import SudoEntitlementsAdmin
import SudoKeyManager
import SudoUser
import UIKit

class Clients {
    static private(set) var userClient: SudoUserClient!
    static private(set) var keyManager: SudoKeyManager!
    static private(set) var entitlementsClient: SudoEntitlementsClient!
    static private(set) var entitlementsAdminClient: SudoEntitlementsAdminClient?
    static private(set) var authenticator: Authenticator!
    static private(set) var adTrackerBlockerClient: SudoAdTrackerBlockerClient!

    static func configure() throws {
        self.userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        self.keyManager = LegacySudoKeyManager(serviceName: "com.sudoplatform.adtrackerblocker", keyTag: "com.sudoplatform", namespace: "client")
        self.entitlementsClient = try DefaultSudoEntitlementsClient(userClient: userClient)
        self.entitlementsAdminClient = try makeEntitlementsAdminClient()
        self.authenticator = Authenticator(
            userClient: userClient,
            keyManager: keyManager,
            entitlementsClient: entitlementsClient
        )
        let adTrackerBlockerConfig = try SudoAdTrackerBlockerConfig()
        self.adTrackerBlockerClient = try DefaultSudoAdTrackerBlockerClient(config: adTrackerBlockerConfig, userClient: userClient)
    }

    /// Creates an entitlements admin client if an admin API key has been bundled with the app (see README.md).
    /// Without one the app can only redeem the entitlements the environment already grants the user.
    private static func makeEntitlementsAdminClient() throws -> SudoEntitlementsAdminClient? {
        guard
            let apiKeyPath = Bundle.main.path(forResource: "api", ofType: "key"),
            let apiKey = try? String(contentsOfFile: apiKeyPath, encoding: .utf8)
        else {
            return nil
        }
        return try DefaultSudoEntitlementsAdminClient(apiKey: apiKey.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func resetClients() async {
        do {
            try await userClient.reset()
            try await adTrackerBlockerClient.reset()
        } catch let error {
            NSLog("Failed to reset clients: \(error)")
        }
    }

    static func deregisterClients() async throws {
        do {
            try await authenticator.deregister()
        } catch {
            NSLog("Failed to deregister: \(error)")
        }
    }
}

// The Extension separates the UI logic from the `Clients` main functions and properties
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
