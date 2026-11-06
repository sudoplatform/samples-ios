//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
import SudoLogging
@preconcurrency import SudoProfiles
@preconcurrency import SudoTelephony
@preconcurrency import SudoTelephonyCommon

@Observable
@MainActor
final class GetPhoneNumberViewModel {

    // MARK: - Properties

    /// The supported countries as ISO 3166-1 alpha-2 codes.
    var countries: [String] = []

    var selectedCountry = ""

    /// Optional area code to narrow the search, where the country supports it.
    var areaCode = ""

    /// True while countries are loading or a search or provision is underway.
    var isLoading = false

    /// The latest search, whose ID is needed to provision one of its numbers.
    var searchResult: PhoneNumberSearchResult?

    /// The number the user picked, awaiting confirmation.
    var numberPendingProvision: AvailablePhoneNumber?

    /// True if the user should confirm provisioning `numberPendingProvision`.
    var showProvisionConfirmation = false

    /// The number once provisioned, still in the provisioning state.
    var provisionedNumber: PhoneNumber?

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let sudoId: String

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Properties: Computed

    var isSearchEnabled: Bool {
        !selectedCountry.isEmpty && !isLoading && (areaCode.isEmpty || areaCode.allSatisfy(\.isNumber))
    }

    // MARK: - Lifecycle

    init(sudoId: String, dependencies: AppDependencies = AppDelegate.dependencies) {
        self.sudoId = sudoId
        self.dependencies = dependencies
    }

    // MARK: - Actions

    func didAppear() async {
        guard countries.isEmpty, let telephonyClient = dependencies.telephonyClient else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            countries = try await telephonyClient.getSupportedCountries().sorted { Self.countryName($0) < Self.countryName($1) }
            selectedCountry = countries.contains("US") ? "US" : countries.first ?? ""
        } catch {
            Logger.sampleLogger.error("Failed to get supported countries: \(error)")
            await presentError(error)
        }
    }

    func didTapSearch() async {
        guard let telephonyClient = dependencies.telephonyClient else { return }
        Logger.sampleLogger.info("Searching for phone numbers...")
        isLoading = true
        defer { isLoading = false }
        do {
            let input = SearchAvailablePhoneNumbersInput(countryCode: selectedCountry, areaCode: areaCode.isEmpty ? nil : areaCode, limit: 20)
            searchResult = try await telephonyClient.searchAvailablePhoneNumbers(input)
        } catch {
            Logger.sampleLogger.error("Failed to search for phone numbers: \(error)")
            await presentError(error)
        }
    }

    func didSelect(_ availableNumber: AvailablePhoneNumber) {
        numberPendingProvision = availableNumber
        showProvisionConfirmation = true
    }

    func didConfirmProvision() async {
        guard let telephonyClient = dependencies.telephonyClient,
              let searchResult,
              let availableNumber = numberPendingProvision else { return }
        numberPendingProvision = nil
        guard Date() < searchResult.expiresAt else {
            self.searchResult = nil
            errorMessage = "These search results have expired. Search again to get a number."
            showError = true
            return
        }
        Logger.sampleLogger.info("Provisioning phone number...")
        isLoading = true
        defer { isLoading = false }
        do {
            // The ownership proof ties the number to the Sudo. The client reference ID means a retried request returns the same
            // number instead of provisioning another.
            let ownershipProof = try await dependencies.profilesClient.getOwnershipProof(
                sudoId: sudoId,
                audience: SudoTelephonyCommon.Constants.ownershipProofAudience
            )
            let input = ProvisionPhoneNumberInput(
                searchId: searchResult.id,
                phoneNumber: availableNumber.phoneNumber,
                ownershipProofToken: ownershipProof,
                clientRefId: UUID().uuidString
            )
            provisionedNumber = try await telephonyClient.provisionPhoneNumber(input)
        } catch SudoTelephonyError.insufficientEntitlements {
            // Worded to cover the limit per user today and the limit per Sudo to come.
            Logger.sampleLogger.error("Failed to provision phone number: insufficient entitlements")
            errorMessage = "You've reached the maximum number of phone numbers you can have. "
                + "Release a number to get another. Entitlements on the Home screen shows your limits."
            showError = true
        } catch {
            Logger.sampleLogger.error("Failed to provision phone number: \(error)")
            await presentError(error)
        }
    }

    // MARK: - Helpers

    /// The country's name in the user's language, e.g. "United States" for "US".
    static func countryName(_ countryCode: String) -> String {
        Locale.current.localizedString(forRegionCode: countryCode) ?? countryCode
    }

    /// Shows `error`, unless it means the session has expired, in which case the app goes back to sign in instead.
    private func presentError(_ error: Error) async {
        guard await !dependencies.session.didExpire(after: error) else { return }
        errorMessage = error.localizedDescription
        showError = true
    }
}
