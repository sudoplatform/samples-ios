//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoLogging
@preconcurrency import SudoUser
import UIKit

/// Whilst this app is a SwiftUI app, the app delegate is used to set up the Sudo Platform clients at launch.
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {

    // MARK: - Properties: Static

    static var dependencies: AppDependencies!

    // MARK: - Lifecycle

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        Logger.sampleLogger.info("didFinishLaunchingWithOptions")
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
        return true
    }
}
