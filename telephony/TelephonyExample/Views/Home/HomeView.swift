//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoProfiles
import SwiftUI

/// The main screen once signed in, listing the user's Sudos which telephony features are accessed from.
struct HomeView: View {

    // MARK: - Properties

    /// Called once the user has signed out or deregistered.
    let onSignedOut: () -> Void

    @State private var viewModel = HomeViewModel()

    /// How the user signed in, which determines whether they deregister or sign out.
    @AppStorage(AuthenticationStrategy.storageKey) private var strategy: AuthenticationStrategy = .test

    // MARK: - View

    var body: some View {
        List {
            Section {
                if viewModel.sudosNeedKeyImport {
                    Label {
                        Text(
                            "Your Sudos were created on another device or before this device's data was removed, "
                            + "so it doesn't have the keys to read them. Import your keys from Import/Export Keys below."
                        )
                    } icon: {
                        Image(systemName: "key.slash")
                            .foregroundStyle(.orange)
                    }
                }
                ForEach(viewModel.sudos, id: \.id) { sudo in
                    NavigationLink(sudo.label ?? "New Sudo") {
                        SudoDetailView(sudo: sudo, onUpdated: viewModel.didUpdateSudo) {
                            viewModel.didDeleteSudo(sudo)
                        }
                    }
                }
                .onDelete(perform: viewModel.didSwipeToDeleteSudos)
                NavigationLink {
                    CreateSudoView(onCreated: viewModel.didCreateSudo)
                } label: {
                    Label("Create Sudo", systemImage: "plus")
                }
            } header: {
                HStack {
                    Text("Sudos")
                    if viewModel.isLoadingSudos && !viewModel.isRefreshingSudos {
                        ProgressView()
                    }
                }
            } footer: {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Phone numbers must belong to a Sudo. A Sudo is a digital identity created and owned by a real person.")
                    if let url = URL(string: "https://docs.sudoplatform.com/guides/sudos") {
                        // A link in a footer doesn't pick up the footer's font, so it would be larger than the text above it.
                        Link("Learn more", destination: url)
                            .font(.footnote)
                    }
                }
            }
            .disabled(viewModel.isLoadingSudos)
            Section {
                NavigationLink {
                    UserDetailsView()
                } label: {
                    LabeledContent("Signed in with", value: strategy.description)
                }
                NavigationLink("Entitlements") {
                    EntitlementsView()
                }
                switch strategy {
                case .test:
                    // Looks like the Federated Sign In row, but explains why key backup isn't available instead of opening it.
                    Button(action: viewModel.didTapKeyImportExportWithTestKeys) {
                        HStack {
                            Text("Import/Export Keys")
                            Spacer()
                            Image(systemName: "chevron.forward")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(Rectangle())
                    }
                    .foregroundStyle(.primary)
                    Button("Deregister", role: .destructive, action: viewModel.didTapDeregister)
                case .fsso:
                    NavigationLink("Import/Export Keys") {
                        keyImportExportView
                    }
                    Button("Sign Out") {
                        Task {
                            await viewModel.didTapSignOut()
                        }
                    }
                    Button("Sign Out and Remove Data", role: .destructive, action: viewModel.didTapSignOutAndRemoveData)
                }
            } header: {
                Text("Account")
            } footer: {
                if strategy == .fsso {
                    Text("Sign Out keeps your keys on this device, so you can read your Sudos when you sign back in. Sign Out and Remove Data deletes them.")
                }
            }
            .disabled(viewModel.isLoading)
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Home")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task {
                        await viewModel.didTapRefresh()
                    }
                }
                .disabled(viewModel.isLoadingSudos || viewModel.isLoading)
            }
        }
        .task {
            await viewModel.didAppear()
        }
        .refreshable {
            await viewModel.didPullToRefresh()
        }
        .onChange(of: viewModel.isSignedOut) { _, isSignedOut in
            guard isSignedOut else { return }
            onSignedOut()
        }
        .deleteSudoConfirmation(isPresented: $viewModel.showDeleteSudoConfirmation) {
            Task {
                await viewModel.didConfirmDeleteSudo()
            }
        }
        .alert("Deregister", isPresented: $viewModel.showDeregisterConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Deregister", role: .destructive) {
                Task {
                    await viewModel.didConfirmDeregister()
                }
            }
        } message: {
            Text("Are you sure you want to deregister? All user data will be deleted.")
        }
        .alert("Sign Out and Remove Data?", isPresented: $viewModel.showRemoveDataConfirmation) {
            Button("Export Keys First", action: viewModel.didTapExportBeforeRemovingData)
            Button("Sign Out and Remove Data", role: .destructive) {
                Task {
                    await viewModel.didConfirmSignOutAndRemoveData()
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(
                "This deletes your keys from this device. Without a key backup, "
                + "you won't be able to read your Sudos when you sign in again, here or on another device."
            )
        }
        .alert("Key Backup Needs Federated Sign In", isPresented: $viewModel.showTestKeyBackupInfo) {
            Button("OK") {}
        } message: {
            Text(
                "A TEST registration is tied to this device, so another device that signs in with a TEST key "
                + "becomes a different user and can't see these Sudos. Sign in with Federated Sign In to back up your keys."
            )
        }
        .navigationDestination(isPresented: $viewModel.showKeyImportExport) {
            keyImportExportView
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }

    // MARK: - Helpers

    private var keyImportExportView: some View {
        KeyImportExportView {
            Task {
                await viewModel.didImportKeys()
            }
        }
    }
}
