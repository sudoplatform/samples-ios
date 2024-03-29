//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AWSAppSync
import SudoKeyManager
import SudoUser
import SudoProfiles
import SudoIdentityVerification
import SudoVirtualCards

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties: Static

    static var dependencies: AppDependencies!

    // MARK: - Properties

    var window: UIWindow?

    // MARK: - Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        #if DEBUG
        guard !isUnitTestRunning else {
            return true
        }
        #endif

        do {
            AppDelegate.dependencies = try AppDependencies()
        } catch let error as SudoUserClientError {
            switch error {
            case .invalidConfig:
                fatalError("Make sure the file config/sudoplatformconfig.json exists in the project directory (see README.md).")
            default:
                fatalError("\(error)")
            }
        } catch {
            fatalError("\(error)")
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        window!.makeKeyAndVisible()
        return true
    }

    func application(
        _ application: UIApplication,
        open url: URL,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Task(priority: .medium) {
            do {
                let urlProcessed = try await AppDelegate.dependencies.userClient.processFederatedSignInTokens(url: url)
                if !urlProcessed {
                    fatalError("Unable to process federated sign in tokens. Check federated sign in configuration")
                }
            } catch {
                fatalError("\(error)")
            }
        }

        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an
        // incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your
        // application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background,
        // optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}
