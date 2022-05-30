//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoUser
import SudoLogging

/// Generic type associated with API completion/closures. Generic type O is the expected output result in a success case.
public typealias ClientCompletion<O> = (Swift.Result<O, Error>) -> Void

/// Client used to interface with the Sudo Entitlements Platform service.
///
/// It is recommended to code to this interface, rather than the implementation class (`DefaultSudoEntitlementsClient`) as
/// the implementation class is only meant to be used for initializing an instance of the client.
public protocol SudoEntitlementsClient: AnyObject {

    // MARK: - Lifecycle
    
    /// Clear all locally cached data
    func reset() throws
    
    // MARK: - Queries

    /// Get the current set of entitlements and their consumption for the user
    /// - Returns:
    ///   - Success: The set of entitlements the user currently has and consumption information for
    ///     the user and its sub-resource consumers, if any
    /// - Throws:
    ///   - `SudoEntitlementsError`
    func getEntitlementsConsumption() async throws -> EntitlementsConsumption

    /// Get the external ID as determined by the entitlements service.
    /// Useful for automated tests
    /// - Returns:
    ///   - The external ID of the authenticated user
    /// - Throws:
    ///   - `SudoEntitlementsError`
    func getExternalId() async throws -> String

    // MARK: - Mutations

    /// Redeem the entitlements for the user.
    /// - Returns:
    ///   - The current set of entitlements the user has after the redemption has completed.
    /// - Throws:
    ///     `SudoEntitlementsError`.
    func redeemEntitlements() async throws -> EntitlementsSet
    
    /// Record consumption of a set of boolean entitlements.
    ///
    /// This is to support services that want a record of
    /// usage recorded but have no service side enforcement
    /// point.
    ///
    /// - Parameters:
    ///   - entitlementNames: Boolean entitlement names to record consumption of
    ///
    /// - Throws:
    ///   - `NotSignedInException`
    ///        User is not signed in
    ///   - `InsufficientEntitlementsException`
    ///        User is not entitled to one or more of the boolean entitlements.
    ///        Check entitlements and that redeemEntitlements has been called
    ///        for the user.
    ///   - `InvalidArgumentException`
    ///        One or more of the specified entitlement names does not correspond
    ///        to a boolean entitlement defined to the entitlements service
    ///   - `ServiceException`
    ///        An error occurred within the entitlements service that indicates an
    ///        issue with the configuration or operation of the service.
    func consumeBooleanEntitlements(entitlementNames: [String]) async throws
}
