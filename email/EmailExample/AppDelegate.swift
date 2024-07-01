//
// Copyright © 2024 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import UIKit
import AWSAppSync
import SudoKeyManager
import SudoUser
import SudoProfiles
import SudoNotification

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
                fatalError(error.localizedDescription)
            }
        } catch {
            fatalError(error.localizedDescription)
        }

        UNUserNotificationCenter.current().delegate = self

        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
          options: authOptions,
          completionHandler: {_, _ in })

        application.registerForRemoteNotifications()

        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = UIStoryboard(name: "Main", bundle: nil).instantiateInitialViewController()!
        window!.makeKeyAndVisible()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        NSLog("Successfully registered for push notifications with token: \(deviceToken.hexString)")

        let userClient = AppDelegate.dependencies.userClient
        let notificationClient = AppDelegate.dependencies.notificationClient

        let device = DefaultNotificationDeviceInputProvider(
            deviceIdentifier: AppDelegate.dependencies.deviceInfo.deviceId,
            pushToken: deviceToken
        )

        if !AppDelegate.dependencies.deviceInfo.pushTokenRegistered || AppDelegate.dependencies.deviceInfo.pushToken != deviceToken {
            AppDelegate.dependencies.deviceInfo.pushToken = deviceToken

            Task {
                let maxAttempts = 4 * 300 // Wait up to 5 minutes - we check every 250ms
                var attempts = 0

                var registered = (try? await userClient.isRegistered()) ?? false
                while !registered && attempts < maxAttempts {
                    attempts += 1
                    guard (try? await Task.sleep(nanoseconds: 250 * 1000000)) != nil else {
                        return
                    }
                    registered = (try? await userClient.isRegistered()) ?? false
                }

                guard registered else {
                    NSLog("User not registered after checking \(maxAttempts) times")
                    return
                }

                var signedIn = (try? await userClient.isSignedIn()) ?? false
                while !signedIn && attempts < maxAttempts {
                    attempts += 1
                    guard (try? await Task.sleep(nanoseconds: 250 * 1000000)) != nil else {
                        return
                    }
                    signedIn = (try? await userClient.isSignedIn()) ?? false
                }
                guard signedIn else {
                    NSLog("User not signed in after checking \(maxAttempts) times")
                    return
                }

                do {
                    try await notificationClient.updateNotificationRegistration(
                        device: device
                    )
                } catch let error as SudoNotificationError {
                    switch error {
                    case .notFound:
                        try await notificationClient.registerNotification(
                            device: device
                        )
                    default:
                        NSLog("Notification registration failed: \(error)")
                        throw error
                    }
                } catch {
                    NSLog("updateNotificationRegistration failed: \(error)")
                }

                AppDelegate.dependencies.deviceInfo.pushTokenRegistered = true
            }
        }

        Task {
            var configuration = NotificationConfiguration(configs: [])
            if let existingConfiguration = try? await AppDelegate.dependencies.notificationClient
                .getNotificationConfiguration(device: device) {
                configuration = existingConfiguration
            }
            configuration = configuration.initEmailNotifications()

            let services = AppDelegate.dependencies.notificationClient.notifiableServices.map { $0.getSchema() }

            do {
                configuration = try await AppDelegate.dependencies.notificationClient.setNotificationConfiguration(
                    config: NotificationSettingsInput(
                        bundleId: device.bundleIdentifier,
                        deviceId: device.deviceIdentifier,
                        filter: configuration.configs,
                        services: services
                    )
                )
                AppDelegate.dependencies.notificationConfiguration = configuration
            } catch let error as SudoNotificationError {
                NSLog("Could not set notification configuration: \(error)")
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        NSLog("Failed to register for push notifications: \(error)")
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
