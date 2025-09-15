//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
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
    var deviceCheckToken: Data?

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        #if DEBUG
        guard !isUnitTestRunning else {
            return true
        }
        #endif

        // Load app dependencies
        do {
            AppDelegate.dependencies = try AppDependencies()
        } catch {
            fatalError(error.localizedDescription)
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "register")
        window!.makeKeyAndVisible()

        return true
    }
}
