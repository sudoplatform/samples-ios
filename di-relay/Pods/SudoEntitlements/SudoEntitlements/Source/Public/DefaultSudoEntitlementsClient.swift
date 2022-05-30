//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAppSync
import SudoApiClient
import SudoLogging
import SudoUser
import SudoConfigManager

/// Default Client API Endpoint for interacting with the Entitlements Service.
public class DefaultSudoEntitlementsClient: SudoEntitlementsClient {

    /// Configuration parameter names.
    public struct Config {

        /// Configuration namespace.
        struct Namespace {

            /// Entitlements service related configuration.
            static let entitlementsService = "entitlementsService"
        }
    }

    /// GraphQL client for peforming operations against the entitlements service.
    let graphQLClient: SudoApiClient

    /// Used to log diagnostic and error information.
    let logger: Logger

    /// Utility factory class to generate use cases.
    let useCaseFactory: UseCaseFactory
    
    /// Repository that does the work of interacting with the service via GraphQL
    let repository: EntitlementsRepository
    
    // User client used to sign-in prior to accessing service
    let userClient: SudoUserClient

    var allResetables: [Resetable] {
        return [
            repository
        ]
    }
    
    /// Initialize an instance of `DefaultSudoEntitlementsClient`. It uses configuration parameters defined in `sudoplatformconfig.json` file located in the app
    /// bundle.
    /// - Parameters:
    ///   - userClient: SudoUserClient instance used for authentication.
    /// Throws:
    ///     - `SudoEntitlementsError` if invalid config.
    public convenience init(userClient: SudoUserClient) throws {
        guard let configManager = SudoConfigManagerFactory.instance.getConfigManager(name: SudoConfigManagerFactory.Constants.defaultConfigManagerName),
              let _ = configManager.getConfigSet(namespace: "apiService") else {
            throw SudoEntitlementsError.invalidConfig
        }

        guard let _ = configManager.getConfigSet(namespace: Config.Namespace.entitlementsService) else {
            throw SudoEntitlementsError.entitlementsServiceConfigNotFound
        }

        guard let graphQLClient = try SudoApiClientManager.instance?.getClient(sudoUserClient: userClient) else {
            throw SudoEntitlementsError.invalidConfig
        }

        let repository = DefaultEntitlementsRepository(graphQLClient: graphQLClient)
        self.init(
            graphQLClient: graphQLClient,
            userClient: userClient,
            useCaseFactory: UseCaseFactory(repository: repository),
            repository: repository
        )
    }

    /// Initialize an instance of `DefaultSudoEntitlementsClient`.
    ///
    /// This is used internally for injection and mock testing.
    init(graphQLClient: SudoApiClient,
        userClient: SudoUserClient,
        useCaseFactory: UseCaseFactory,
        repository: EntitlementsRepository,
        logger: Logger = .entitlementsSDKLogger
    ) {
        self.graphQLClient = graphQLClient
        self.logger = logger
        self.useCaseFactory = useCaseFactory
        self.repository = repository
        self.userClient = userClient
    }

    public func reset() throws {
        allResetables.forEach { $0.reset() }
        try self.graphQLClient.clearCaches(options: .init(clearQueries: true, clearMutations: true, clearSubscriptions: false))
    }

    public func redeemEntitlements() async throws -> EntitlementsSet {
        guard try await userClient.isSignedIn() else {
            throw SudoEntitlementsError.notSignedIn
        }

        let useCase = useCaseFactory.generateRedeemEntitlementsUseCase()
        return try await useCase.execute()
    }

    public func consumeBooleanEntitlements(entitlementNames: [String]) async throws {
        guard try await userClient.isSignedIn() else {
            throw SudoEntitlementsError.notSignedIn
        }

        let useCase = useCaseFactory.generateConsumeBooleanEntitlementsUseCase()
        return try await useCase.execute(entitlementNames: entitlementNames)
    }

    public func getEntitlementsConsumption() async throws -> EntitlementsConsumption {
        guard try await userClient.isSignedIn() else {
            throw SudoEntitlementsError.notSignedIn
        }
  
        let useCase = useCaseFactory.generateGetEntitlementsConsumptionUseCase()
        return try await useCase.execute()
    }

    public func getExternalId() async throws -> String {
        guard try await userClient.isSignedIn() else {
            throw SudoEntitlementsError.notSignedIn
        }
  
        let useCase = useCaseFactory.generateGetExternalIdUseCase()
        return try await useCase.execute()
    }
}
