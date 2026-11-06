//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

@main
struct TelephonyExampleApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @State private var isSignedIn = false

    /// True if the user is back on the sign in screen because their session expired.
    @State private var isSessionExpired = false

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                Group {
                    if isSignedIn {
                        HomeView {
                            isSignedIn = false
                        }
                    } else {
                        AuthenticationView(isSessionExpired: isSessionExpired) {
                            isSessionExpired = false
                            AppDelegate.dependencies.session.didSignIn()
                            isSignedIn = true
                        }
                    }
                }
                // Any screen can find the session has expired; go back to sign in from wherever the user is.
                .onChange(of: AppDelegate.dependencies.session.hasExpired) { _, hasExpired in
                    guard hasExpired else { return }
                    isSessionExpired = true
                    isSignedIn = false
                }
                // Small titles throughout: screens pushed onto this stack inherit the display mode.
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}
