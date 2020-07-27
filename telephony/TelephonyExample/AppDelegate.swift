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
import SudoConfigManager
import PushKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var telephonyClient: SudoTelephonyClient!
    var authProvider: GraphQLAuthProvider!
    var userClient: SudoUserClient!
    var keyManager: SudoKeyManager!
    var authenticator: Authenticator!
    var sudoProfilesClient: SudoProfilesClient!
    var pushRegistry: PKPushRegistry!
    var callDelegate: ActiveVoiceCallViewController?

    var lastPushToken: Data?

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

            self.telephonyClient = try DefaultSudoTelephonyClient(
                sudoUserClient: self.userClient,
                sudoProfilesClient: self.sudoProfilesClient,
                callProviderConfiguration: CallProviderConfiguration(
                    localizedName: "TelephonyExample",
                    iconTemplate: nil,
                    ringtoneSound: nil,
                    includesCallsInRecents: true
                )
            )
        } catch let error {
            fatalError("Failed to initialize the telephony client: \(error)")
        }

        self.pushRegistry = PKPushRegistry(queue: nil)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]

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


// MARK: PKPushRegistryDelegate


extension AppDelegate: PKPushRegistryDelegate {

    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let description = pushCredentials.token.reduce("", {$0 + String(format: "%02X", $1)}).uppercased()
        print("didUpdatePushToken: \(description)")
        self.lastPushToken = pushCredentials.token
        self.registerForIncomingCalls()
    }

    func registerForIncomingCalls() {
        guard let pushtoken = self.lastPushToken else { return }
        try! self.telephonyClient.registerForIncomingCalls(with: pushtoken, useSandbox: true, completion: { (error) in
            if let error = error {
                print("Error updating push credentials: \(error)")
            }
            else {
                print("Push credentials updated with telephony SDK.")
            }
        })
    }

    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("Did receive incoming push: \(payload.dictionaryPayload)")
        let _ = try! self.telephonyClient.handleIncomingPushNotificationPayload(payload.dictionaryPayload, notificationDelegate: self)
        completion()
    }

    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {
        try! self.telephonyClient.deregisterForIncomingCalls(completion: { (maybeError) in
            if let error = maybeError {
                NSLog("Error de-registering for push notifications: \(error)")
            }
        })
    }
}


// MARK: IncomingCallNotificationDelegate


extension AppDelegate: IncomingCallNotificationDelegate {

    func incomingCallReceived(_ call: IncomingCall) {
        NSLog("Incoming Call received: \(call)")
        let activeCallController = UIStoryboard(name: "Main", bundle: Bundle.main).instantiateViewController(identifier: "ActiveVoiceCallViewController") as! ActiveVoiceCallViewController
        call.delegate = activeCallController
        self.callDelegate = activeCallController
    }


    func incomingCall(_ call: IncomingCall, cancelledWithError error: Error?) {
        NSLog("Incoming Call canceled: \(call), with error: \(String(describing: error))")
        self.callDelegate = nil
    }

    func incomingCallAnswered(_ call: ActiveVoiceCall) {

        guard let activeCallController = self.callDelegate else { return }

        activeCallController.startWithActive(call: call)

        let nav = UINavigationController(rootViewController: activeCallController)
        nav.modalPresentationStyle = .fullScreen

        if var topController = self.window?.rootViewController {
            while let presentedViewController = topController.presentedViewController {
                topController = presentedViewController
            }

            topController.present(nav, animated: true, completion: nil)
        }
    }
}
