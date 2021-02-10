//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSMobileClient
import Foundation
import SudoConfigManager
import SudoEntitlements
import SudoKeyManager
import SudoPasswordManager
import SudoProfiles
import SudoUser
import UIKit

class Clients {
    static private(set) var userClient: SudoUserClient!
    static private(set) var keyManager: SudoKeyManager!
    static private(set) var authenticator: Authenticator!
    static private(set) var passwordManagerClient: SudoPasswordManagerClient!
    static private(set) var profilesClient: SudoProfilesClient!
    static private(set) var entitlementsClient: SudoEntitlementsClient!

    static func configure() throws {
        self.userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        let documentsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        self.profilesClient = try DefaultSudoProfilesClient(sudoUserClient: self.userClient, blobContainerURL: documentsDir)
        self.entitlementsClient = try? DefaultSudoEntitlementsClient(userClient: Clients.userClient)
        self.passwordManagerClient = try DefaultSudoPasswordManagerClient(userClient: self.userClient, profilesClient: self.profilesClient, entitlementsClient: self.entitlementsClient)

        self.keyManager = SudoKeyManagerImpl(serviceName: "com.sudoplatform.passwordmanager.example", keyTag: "exampleapp", namespace: "")
        self.authenticator = Authenticator(userClient: userClient, keyManager: keyManager, entitlementsClient: self.entitlementsClient)
    }

    static func resetClients() {
        do {
            _ = try? passwordManagerClient.reset()
            try profilesClient.reset()
            try userClient.reset()
        } catch let error {
            NSLog("Failed to reset clients: \(error)")
        }
    }

    static func deregisterWithAlert() {
        let alert = UIAlertController(title: "Are you sure?", message: "This will attempt to deregister any accounts with the Sudo Platform service and clear any keys associated with accounts connected with this device. It is meant as option of last resort if you are unable to login or register and cannot be undone.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { (_) in
            UIApplication.shared.topController?.presentActivityAlert(message: "Deregistering")

            do {
                try authenticator.deregister(completion: { (result) in
                    if case .failure(let error) = result {
                        NSLog("Failed to deregister: \(error)")
                    }

                    DispatchQueue.main.async {
                        self.resetClients()
                        UIApplication.shared.rootController?.dismiss(animated: true, completion: nil)
                    }
                })
            }
            catch {
                NSLog("Failed to deregister: \(error)")
                self.resetClients()
                DispatchQueue.main.async {
                    UIApplication.shared.topController?.dismiss(animated: true, completion: nil)
                }
            }
        }))

        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: nil))

        UIApplication.shared.topController?.present(alert, animated: true, completion: nil)
    }
}
