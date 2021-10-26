//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDIRelay

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

        // MARK: - Properties: Static

        static var dependencies: AppDependencies!
        static var mainStoryboard: UIStoryboard!


        // MARK: - Properties

        var window: UIWindow?

        func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
        ) -> Bool {

            AppDelegate.mainStoryboard = UIStoryboard(name: "Main", bundle: nil)

            #if DEBUG
            guard !isUnitTestRunning else {
                return true
            }
            #endif

            do {
                AppDelegate.dependencies = try AppDependencies()
            } catch {
                fatalError(error.localizedDescription)
            }

            window = UIWindow(frame: UIScreen.main.bounds)
            window!.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
            window!.makeKeyAndVisible()
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
}
