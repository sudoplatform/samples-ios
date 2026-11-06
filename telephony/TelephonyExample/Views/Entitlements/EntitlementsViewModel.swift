//
// Copyright © 2026 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import Observation
@preconcurrency import SudoEntitlements
import SudoLogging
@preconcurrency import SudoProfiles

@Observable
@MainActor
final class EntitlementsViewModel {

    // MARK: - Supplementary

    /// How much of an entitlement has been used, by the user or by one of their Sudos.
    struct Usage: Identifiable {
        let name: String
        /// Who used it: "Account" for the user, otherwise the Sudo's label or ID.
        let consumer: String
        let consumed: Int64
        let value: Int64
        var id: String { "\(name)|\(consumer)" }
    }

    private enum Constants {
        /// The issuer of a Sudo consumer.
        static let sudoServiceIssuer = "sudoplatform.sudoservice"
    }

    // MARK: - Properties

    /// Name of the entitlement set the user's entitlements come from, e.g. "TEST".
    var entitlementsSetName: String?

    // SudoProfiles has an `Entitlement` too.
    var entitlements: [SudoEntitlements.Entitlement] = []

    var usage: [Usage] = []

    var isLoading = false

    /// True if `errorMessage` should be presented to the user.
    var showError = false

    var errorMessage = ""

    @ObservationIgnored private let dependencies: AppDependencies

    // MARK: - Lifecycle

    init(dependencies: AppDependencies = AppDelegate.dependencies) {
        self.dependencies = dependencies
    }

    // MARK: - Actions

    func didAppear() async {
        guard entitlements.isEmpty else { return }
        await load()
    }

    func didPullToRefresh() async {
        await load()
    }

    // MARK: - Helpers

    private func load() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let consumption = try await dependencies.entitlementsClient.getEntitlementsConsumption()
            let sudoLabels = await sudoLabelsById()
            entitlementsSetName = consumption.entitlements.entitlementsSetName
            entitlements = consumption.entitlements.entitlements.sorted { $0.name < $1.name }
            usage = consumption.consumption
                .map { item in
                    Usage(
                        name: item.name,
                        consumer: Self.consumerName(item.consumer, sudoLabels: sudoLabels),
                        consumed: item.consumed,
                        value: item.value
                    )
                }
                .sorted { ($0.name, $0.consumer) < ($1.name, $1.consumer) }
        } catch {
            Logger.sampleLogger.error("Failed to get entitlements: \(error)")
            // If the session has expired, the app goes back to sign in instead of showing the error.
            guard await !dependencies.session.didExpire(after: error) else { return }
            errorMessage = error.localizedDescription
            showError = true
        }
    }

    /// The Sudo's label for usage counted per Sudo, otherwise "Account", e.g. for usage counted against the user.
    private static func consumerName(_ consumer: EntitlementConsumer?, sudoLabels: [String: String]) -> String {
        guard let consumer, consumer.issuer == Constants.sudoServiceIssuer else { return "Account" }
        return sudoLabels[consumer.id] ?? consumer.id
    }

    /// Labels of the user's Sudos, so usage by a Sudo can show its name. Falls back to IDs if the Sudos can't be listed.
    private func sudoLabelsById() async -> [String: String] {
        do {
            let sudos = try await dependencies.profilesClient.listSudos(cachePolicy: .cacheOnly)
            return Dictionary(sudos.compactMap { sudo in sudo.label.map { (sudo.id, $0) } }, uniquingKeysWith: { first, _ in first })
        } catch {
            Logger.sampleLogger.error("Failed to list Sudos for entitlement usage: \(error)")
            return [:]
        }
    }
}
