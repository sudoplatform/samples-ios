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

        // Support for FSSO Sign In URL redirect
        if AppDelegate.dependencies.sudoUserClient.getSupportedRegistrationChallengeType().contains(.fsso) {
            Task {
                do {
                    guard let url = URL(string: "com.sudoplatform.DIRelayApp://") else {
                            fatalError("Could not resolve FSSO URL scheme.")
                    }
                    let urlProcessed = try await AppDelegate.dependencies.sudoUserClient.processFederatedSignInTokens(url: url)
                    if !urlProcessed {
                        fatalError("Unable to process federated sign in tokens. Check federated sign in configuration")
                    }
                } catch {
                    // Handle error. An error might be thrown for unrecoverable circumstances arising
                    // from programmatic error or configuration error. For example, if the federated
                    // sign in is not configured in your environment then `invalidConfig` error might
                    // be thrown.
                    fatalError("Encountered error processing FSSO tokens \(error.localizedDescription)")
                }
            }
        }

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "register")
        window!.makeKeyAndVisible()

        return true
    }
}
