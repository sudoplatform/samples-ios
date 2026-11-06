//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoEntitlements
import SwiftUI

/// The user's entitlements, e.g. how many phone numbers they may have, and how much of each they've used.
struct EntitlementsView: View {

    // MARK: - Properties

    @State private var viewModel = EntitlementsViewModel()

    // MARK: - View

    var body: some View {
        List {
            if let setName = viewModel.entitlementsSetName {
                Section {
                    LabeledContent("Entitlement Set", value: setName)
                }
            }
            Section {
                if viewModel.usage.isEmpty && !viewModel.isLoading {
                    Text("Nothing used yet.")
                        .foregroundStyle(.secondary)
                }
                ForEach(viewModel.usage) { usage in
                    LabeledContent {
                        Text("\(usage.consumed) of \(usage.value)")
                            .monospacedDigit()
                    } label: {
                        Text(usage.name)
                        Text(usage.consumer)
                    }
                }
            } header: {
                Text("Usage")
            } footer: {
                Text("Entitlements counted per Sudo are shown for each Sudo.")
            }
            Section("Entitlements") {
                ForEach(viewModel.entitlements, id: \.name) { entitlement in
                    LabeledContent {
                        Text("\(entitlement.value)")
                            .monospacedDigit()
                    } label: {
                        Text(entitlement.name)
                        if let description = entitlement.description {
                            Text(description)
                        }
                    }
                }
            }
        }
        .overlay {
            if viewModel.isLoading && viewModel.entitlements.isEmpty {
                ProgressView()
            }
        }
        .navigationTitle("Entitlements")
        .task {
            await viewModel.didAppear()
        }
        .refreshable {
            await viewModel.didPullToRefresh()
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
