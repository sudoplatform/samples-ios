//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

@preconcurrency import SudoTelephonyCommon
import SwiftUI

/// Searches for an available phone number by country and optional area code, then provisions the one the user picks.
struct GetPhoneNumberView: View {

    // MARK: - Properties

    /// Called with the new number, still provisioning, before this view is dismissed.
    let onProvisioned: (PhoneNumber) -> Void

    @State private var viewModel: GetPhoneNumberViewModel

    @Environment(\.dismiss) private var dismiss

    // MARK: - Lifecycle

    init(sudoId: String, onProvisioned: @escaping (PhoneNumber) -> Void) {
        self.onProvisioned = onProvisioned
        _viewModel = State(initialValue: GetPhoneNumberViewModel(sudoId: sudoId))
    }

    // MARK: - View

    var body: some View {
        Form {
            Section {
                Picker("Country", selection: $viewModel.selectedCountry) {
                    ForEach(viewModel.countries, id: \.self) { countryCode in
                        Text(GetPhoneNumberViewModel.countryName(countryCode)).tag(countryCode)
                    }
                }
                TextField("Area Code (optional)", text: $viewModel.areaCode)
                    .keyboardType(.numberPad)
                Button("Search") {
                    Task {
                        await viewModel.didTapSearch()
                    }
                }
                .disabled(!viewModel.isSearchEnabled)
            } footer: {
                Text("Numbers aren't reserved while you choose, so one can be taken before you get it.")
            }
            if let searchResult = viewModel.searchResult {
                Section {
                    if searchResult.results.isEmpty {
                        Text("No numbers available. Try a different area code.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(searchResult.results, id: \.phoneNumber) { availableNumber in
                        Button {
                            viewModel.didSelect(availableNumber)
                        } label: {
                            VStack(alignment: .leading) {
                                Text(PhoneNumberDisplay.number(availableNumber.phoneNumber))
                                    .monospacedDigit()
                                    .foregroundStyle(.primary)
                                if let place = PhoneNumberDisplay.place(locality: availableNumber.locality, region: availableNumber.region) {
                                    Text(place)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Available Numbers")
                } footer: {
                    Text("Search results expire after 15 minutes.")
                }
            }
        }
        .disabled(viewModel.isLoading)
        .overlay {
            if viewModel.isLoading {
                ProgressView()
            }
        }
        .navigationTitle("Get a Number")
        .task {
            await viewModel.didAppear()
        }
        .onChange(of: viewModel.provisionedNumber) { _, provisionedNumber in
            guard let provisionedNumber else { return }
            onProvisioned(provisionedNumber)
            dismiss()
        }
        .alert("Get This Number?", isPresented: $viewModel.showProvisionConfirmation, presenting: viewModel.numberPendingProvision) { _ in
            Button("Cancel", role: .cancel) {}
            Button("Get Number") {
                Task {
                    await viewModel.didConfirmProvision()
                }
            }
        } message: { availableNumber in
            Text("\(PhoneNumberDisplay.number(availableNumber.phoneNumber)) will be provisioned for your account.")
        }
        .alert("An error occurred", isPresented: $viewModel.showError) {
            Button("OK") {}
        } message: {
            Text(viewModel.errorMessage)
        }
    }
}
