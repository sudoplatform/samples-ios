//
//  Clients.swift
//  AdTrackerBlockerExample
//
//  Copyright © 2020 Sudo Platform. All rights reserved.
//

import AWSMobileClient
import Foundation
import SudoAdTrackerBlocker
import SudoConfigManager
import SudoKeyManager
import SudoUser
import UIKit

class Clients {
    static private(set) var userClient: SudoUserClient!
    static private(set) var keyManager: SudoKeyManager!
    static private(set) var authenticator: Authenticator!
    static private(set) var adTrackerBlockerClient: SudoAdTrackerBlockerClient!

    static func configure() throws {
        self.userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        self.keyManager = SudoKeyManagerImpl(serviceName: "com.sudoplatform.adtrackerblocker", keyTag: "com.sudoplatform", namespace: "client")
        self.authenticator = Authenticator(userClient: userClient, keyManager: keyManager)
        let adTrackerBlockerConfig = try SudoAdTrackerBlockerConfig(userClient: userClient)
        self.adTrackerBlockerClient = DefaultSudoAdTrackerBlockerClient(config: adTrackerBlockerConfig)
    }

    static func resetClients() {
        do {
            try userClient.reset()
            try adTrackerBlockerClient.reset()
        } catch let error {
            NSLog("Failed to reset clients: \(error)")
        }
    }

    static func deregisterClients() throws {
        try authenticator.deregister(completion: { (result) in
            if case .failure(let error) = result {
                NSLog("Failed to deregister: \(error)")
            }
        })
    }
}

// The Extension separates the UI logic from the `Clients` main functions and properties
extension Clients {
    static func deregisterWithAlert() {
        let alert = UIAlertController(title: "Are you sure?", message: "This will attempt to deregister any accounts with the Sudo Platform service and clear any keys associated with accounts connected with this device. It is meant as option of last resort if you are unable to login or register and cannot be undone.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { (_) in
            UIApplication.shared.topController?.presentActivityAlert(message: "Deregistering")

            do {
                try self.deregisterClients()

                DispatchQueue.main.async {
                    self.resetClients()
                    UIApplication.shared.rootController?.dismiss(animated: true, completion: nil)
                }
            } catch {
                NSLog("Failed to deregister: \(error)")
                self.resetClients()
                DispatchQueue.main.async {
                    UIApplication.shared.topController?.dismiss(animated: true, completion: nil)
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { (_) in
        }))

        UIApplication.shared.topController?.present(alert, animated: true, completion: nil)
    }
}
