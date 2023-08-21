//
// Copyright © 2023 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import SudoUser

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    // MARK: - Properties: Static

    static var dependencies: AppDependencies!

    // MARK: - Properties

    var window: UIWindow?

    // MARK: - Methods

    func isSimulator() -> Bool {
        #if targetEnvironment(simulator)
        return true
        #else
        return false
        #endif
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        #if DEBUG
        guard !isUnitTestRunning else {
            return true
        }
        #endif
        if isSimulator() {
            fatalError("Simulator is currently not supported - please use a real device")
        }
        do {
            AppDelegate.dependencies = try AppDependencies()
        } catch let error as SudoUserClientError {
            switch error {
            case .invalidConfig:
                fatalError("Make sure the file config/sudoplatformconfig.json exists in the project directory (see README.md).")
            default:
                fatalError(error.localizedDescription)
            }
        } catch {
            fatalError(error.localizedDescription)
        }
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        window!.makeKeyAndVisible()
        return true
    }
}
