//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// List of possible errors thrown/returned by `GraphQLClient`.
///
/// - invalidInput: Input was invalid.
/// - graphQLError: GraphQL API returned errors.
public enum GraphQLClientError: Error {
    case invalidInput
    case graphQLError(cause: [Error])
}

/// GraphQL mutation result.
public enum MutationResult {
    case success(output: [String: Any])
    case failure(cause: Error)
}

/// GraphQL query result.
public enum QueryResult {
    case success(output: [[String: Any]])
    case failure(cause: Error)
}

/// Abstraction layer for GraphQL API.
public protocol GraphQLClient: AnyObject {

    /// Performs GraphQL create mutation.
    ///
    /// - Parameters:
    ///   - input: Input parameters for mutation.
    ///   - completion: The completion handler to invoke to pass back the result.
    func create(input: [String: Any], completion: @escaping (MutationResult) -> Void) throws

    /// Performs GraphQL update mutation.
    ///
    /// - Parameters:
    ///   - input: Input parameters for mutation.
    ///   - completion: The completion handler to invoke to pass back the result.
    func update(input: [String: Any], completion: @escaping (MutationResult) -> Void) throws

    /// Performs GraphQL delete mutation.
    ///
    /// - Parameters:
    ///   - input: Input parameters for mutation.
    ///   - completion: The completion handler to invoke to pass back the result.
    func delete(input: [String: Any], completion: @escaping (MutationResult) -> Void) throws

    /// Performs GraphQL list query.
    ///
    /// - Parameters:
    ///   - input: Input parameters for query.
    ///   - completion: The completion handler to invoke to pass back the result.
    func list(input: [String: Any], completion: @escaping (QueryResult) -> Void) throws

}
