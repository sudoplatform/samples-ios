//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SwiftUI

/// The first screen of the app, responsible for registering and signing in the user with the Sudo Platform.
struct AuthenticationView: View {

    // MARK: - Properties

    /// True if the user is here because their session expired, which the screen explains.
    var isSessionExpired = false

    /// Called once the user is signed in.
    let onSignedIn: () -> Void

    @State private var viewModel = AuthenticationViewModel()

    @AppStorage(AuthenticationStrategy.storageKey) private var strategy: AuthenticationStrategy = .test

    // MARK: - View

    var body: some View {
        VStack {
            HStack {
                Image("sudoPlatformIcon").resizable().frame(width: 48, height: 48)
                Text("SUDO PLATFORM").font(.largeTitle).bold()
            }
            .padding(.top, 64)
            Text("Sudo Telephony Sample App").font(.body)
            Spacer()
            if isSessionExpired {
                Label("Your session has expired. Sign in again.", systemImage: "clock.badge.exclamationmark")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.bottom, 16)
            }
            SampleButton(label: "Start", isLoading: viewModel.isLoading, minWidth: 300) {
                Task {
                    await viewModel.didTapStart(strategy: strategy)
                }
            }
            Picker("Sign In Method", selection: $strategy) {
                ForEach(AuthenticationStrategy.allCases) { option in
                    Text(option.description)
                }
            }
            .disabled(viewModel.isLoading)
            .frame(maxWidth: 300, maxHeight: 100)
        }
        .padding(.bottom, 128)
        .task {
            await viewModel.didAppear()
        }
        .onChange(of: viewModel.isSignedIn) { _, isSignedIn in
            guard isSignedIn else { return }
            onSignedIn()
        }
        .alert("Failed to sign in", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
