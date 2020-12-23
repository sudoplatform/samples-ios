//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser
import SudoKeyManager
import SudoPasswordManager
import SudoProfiles
import SudoConfigManager
import AWSMobileClient

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            try Clients.configure()
        } catch {
            fatalError("Failed to initialize the sudo user client: \(error)")
        }
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


    func resetClients() {
        let authenticator = Clients.authenticator!
        let passwordClient = Clients.passwordManagerClient!
        do {
            _ = try? passwordClient.reset()
            try authenticator.userClient.reset()
            try Clients.sudoProfilesClient!.reset()
        } catch let error {
            NSLog("Failed to reset clients: \(error)")
        }
    }

    func deregister() {
        let alert = UIAlertController(title: "Are you sure?", message: "This will attempt to deregister any accounts with the Sudo Platform service and clear any keys associated with accounts connected with this device. It is meant as option of last resort if you are unable to login or register and cannot be undone.", preferredStyle: .alert)

        alert.addAction(UIAlertAction(title: "Reset", style: .destructive, handler: { (_) in
            let authenticator = Clients.authenticator!
            self.topController()?.presentActivityAlert(message: "Deregistering")

            do {
                try Clients.authenticator.deregister(completion: { (result) in
                    if case .failure(let error) = result {
                        NSLog("Failed to deregister: \(error)")
                    }

                    DispatchQueue.main.async {
                        self.resetClients()
                        self.rootController()?.dismiss(animated: true, completion: nil)
                    }
                })
            }
            catch {
                NSLog("Failed to deregister: \(error)")
                self.resetClients()
                self.rootController()?.dismiss(animated: true, completion: nil)
            }
        }))

        alert.addAction(UIAlertAction(title: "Not now", style: .cancel, handler: { (_) in
        }))

        self.topController()?.present(alert, animated: true, completion: nil)
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        try? Clients.userClient!.processFederatedSignInTokens(url: url)
        return true
    }

    func rootController() -> UIViewController? {
        return UIApplication.shared.windows.filter {$0.isKeyWindow}.first?.rootViewController
    }

    func topController() -> UIViewController? {
        let keyWindow = UIApplication.shared.windows.filter {$0.isKeyWindow}.first
        guard var topController = keyWindow?.rootViewController else { return nil }
        while let presentedViewController = topController.presentedViewController {
            topController = presentedViewController
        }
        return topController
    }
}

