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

    /// Whether every phone number shares one key pair. Chosen here because the telephony client is created with it at sign in.
    @AppStorage(TelephonyKeyMode.enforceSingletonKeyPairStorageKey) private var enforceSingletonKeyPair = false

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
                    await viewModel.didTapStart(strategy: strategy, enforceSingletonKeyPair: enforceSingletonKeyPair)
                }
            }
            Picker("Sign In Method", selection: $strategy) {
                ForEach(AuthenticationStrategy.allCases) { option in
                    Text(option.description)
                }
            }
            .disabled(viewModel.isLoading)
            .frame(maxWidth: 300, maxHeight: 100)
            VStack(alignment: .leading, spacing: 4) {
                Toggle("Single key for all numbers", isOn: $enforceSingletonKeyPair)
                    .disabled(viewModel.isLoading)
                Text(
                    enforceSingletonKeyPair
                        ? "Single key is used to decrypt content across all numbers. You should backup the key to avoid data loss. "
                            + "Refer to developer docs for more information."
                        : "Each number has its own key used to decrypt content. You should backup the keys to avoid data loss. "
                            + "Refer to developer docs for more information."
                )
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: 300)
        }
        .padding(.bottom, 128)
        .task {
            await viewModel.didAppear(enforceSingletonKeyPair: enforceSingletonKeyPair)
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
