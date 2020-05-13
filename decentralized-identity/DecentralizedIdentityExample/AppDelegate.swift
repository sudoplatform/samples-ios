//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoDecentralizedIdentity
import Firebase

struct Dependencies {
    static let sudoDecentralizedIdentityClient = DefaultSudoDecentralizedIdentityClient()

    static let firebaseRelay: FirebaseRelay = {
        // If this line fails, this object is being initialized on a background thread.
        // Firebase requires initialization to occur on the main thread.
        assert(Thread.isMainThread)

        // If this line fails, GoogleService-Info.plist is missing.
        // Please refer to the README for Firebase configuration instructions.
        FirebaseApp.configure()
        let firebaseApp = FirebaseApp.app()!

        return FirebaseRelay(app: firebaseApp)
    }()
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NSLog("Initialized Firebase relay \(Dependencies.firebaseRelay)")
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
