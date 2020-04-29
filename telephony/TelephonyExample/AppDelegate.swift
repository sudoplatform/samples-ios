//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoTelephony
import AWSAppSync
import SudoKeyManager
import SudoUser
import SudoProfiles

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var telephonyClient: SudoTelephonyClient!
    var authProvider: GraphQLAuthProvider!
    var userClient: SudoUserClient!
    var keyManager: SudoKeyManager!
    var authenticator: Authenticator!
    var sudoProfilesClient: SudoProfilesClient!

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        do {
            self.userClient = try DefaultSudoUserClient(keyNamespace: "ids")
        }
        catch {
            fatalError("Failed to initialize the sudo user client: \(error)")
        }

        do {
            let storageURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            self.sudoProfilesClient = try DefaultSudoProfilesClient(sudoUserClient: self.userClient, blobContainerURL: storageURL)
        }
        catch {
            fatalError("Failed to initialize the sudo profiles client: \(error)")
        }

        do {
            // Initialize the IdentityClient and TelephonyClient based on the config downloaded
            self.keyManager = SudoKeyManagerImpl(serviceName: "com.sudoplatform.appservicename", keyTag: "com.sudoplatform", namespace: "tel")
            self.authenticator = Authenticator(userClient: userClient, keyManager: keyManager)

            self.telephonyClient = try DefaultSudoTelephonyClient(sudoUserClient: self.userClient, sudoProfilesClient: self.sudoProfilesClient)
        } catch let error {
            fatalError("Failed to initialize the telephony client: \(error)")
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
