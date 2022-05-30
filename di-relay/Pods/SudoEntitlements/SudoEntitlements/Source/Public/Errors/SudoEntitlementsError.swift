//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoApiClient
import AWSAppSync

/// Errors that occur in SudoEntitlements.
public enum SudoEntitlementsError: Error, Equatable, LocalizedError {

    // MARK: - Client

    /// Configuration supplied to `DefaultSudoEntitlementsClient` is invalid.
    case invalidConfig

    /// User is not signed in.
    case notSignedIn

    /// The configuration related to Entitlements Service is not found in the provided configuration file
    /// This may indicate that the Entitlemetns Service is not deployed into your runtime instance or the
    /// configuration file that you are using is invalid..
    case entitlementsServiceConfigNotFound

    /// Indicates the requested operation failed because the user account is locked.
    case accountLocked

    /// Indicates that the request operation failed due to authorization error. This maybe due to the authentication
    /// token being invalid or other security controls that prevent the user from accessing the API.
    case notAuthorized

    /// Indicates API call  failed due to it exceeding some limits imposed for the API. For example, this error
    /// can occur if the vault size was too big.
    case limitExceeded

    /// Indicates that an internal server error caused the operation to fail. The error is possibly transient and
    /// retrying at a later time may cause the operation to complete successfully
    case serviceError

    /// Indicates that the request failed due to connectivity, availability or access error.
    case requestFailed(response: HTTPURLResponse?, cause: Error?)

    /// Indicates that there were too many attempts at sending API requests within a short period of time.
    case rateLimitExceeded

    /// Indicates that an unexpected GraphQL error was returned by the service.
    case graphQLError(cause: GraphQLError)

    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory condition or other
    /// conditions that is beyond control of `SudoSecureVaultClient` implementation.
    case fatalError(_ description: String)

    // MARK: - ApiOperationError

    /// This section contains wrapped errors from `ApiOperationError`.
    case ambiguousEntitlements
    case insufficientEntitlements
    case invalidArgument
    case invalidRequest
    case invalidTokenError
    case noEntitlementsError
    case policyFailed

    public static func == (lhs: SudoEntitlementsError, rhs: SudoEntitlementsError) -> Bool {
        switch (lhs, rhs) {
        case (.requestFailed(let lhsResponse, let lhsCause), requestFailed(let rhsResponse, let rhsCause)):
            if let lhsResponse = lhsResponse, let rhsResponse = rhsResponse {
                return lhsResponse.statusCode == rhsResponse.statusCode
            }
            return type(of: lhsCause) == type(of: rhsCause)
        case (.invalidConfig, .invalidConfig),
             (.notSignedIn, .notSignedIn),
             (.accountLocked, .accountLocked),
             (.notAuthorized, .notAuthorized),
             (.limitExceeded, .limitExceeded),
             (.insufficientEntitlements, .insufficientEntitlements),
             (.serviceError, .serviceError),
             (.rateLimitExceeded, .rateLimitExceeded),
             (.graphQLError, .graphQLError),
             (.fatalError, .fatalError),
             (.policyFailed, .policyFailed),
             (.invalidTokenError, .invalidTokenError),
             (.ambiguousEntitlements, ambiguousEntitlements),
             (.noEntitlementsError, noEntitlementsError),
             (.entitlementsServiceConfigNotFound, entitlementsServiceConfigNotFound),
             (.invalidArgument, .invalidArgument),
             (.invalidRequest, .invalidRequest):
            return true
        default:
            return false
        }
    }

    // MARK: - Lifecycle

    /// Initialize a `SudoEntitlementsError` from a `GraphQLError`.
    ///
    /// If the GraphQLError is unsupported, `nil` will be returned instead.
    init(graphQLError error: GraphQLError) {
        guard let errorType = error["errorType"] as? String else {
            self = .graphQLError(cause: error)
            return
        }
        switch errorType {
        case "sudoplatform.entitlements.AmbiguousEntitlementsError":
            self = .ambiguousEntitlements
        case "sudoplatform.NoEntitlementsError":
            self = .noEntitlementsError
        default:
            self = .graphQLError(cause: error)
        }
    }

    public var errorDescription: String? {
        switch self {
        case .accountLocked:
            return L10n.Entitlements.Errors.accountLockedError
        case .ambiguousEntitlements:
            return L10n.Entitlements.Errors.ambiguousEntitlementsError
        case .insufficientEntitlements:
            return L10n.Entitlements.Errors.insufficientEntitlementsError
        case .invalidArgument:
            return L10n.Entitlements.Errors.invalidArgument
        case .invalidConfig:
            return L10n.Entitlements.Errors.invalidConfig
        case .invalidTokenError:
            return L10n.Entitlements.Errors.invalidTokenError
        case .noEntitlementsError:
            return L10n.Entitlements.Errors.noEntitlementsError
        case .notSignedIn:
            return L10n.Entitlements.Errors.notSignedIn
        case .policyFailed:
            return L10n.Entitlements.Errors.policyFailed
        case .serviceError:
            return L10n.Entitlements.Errors.serviceError
        case .entitlementsServiceConfigNotFound:
            return L10n.Entitlements.Errors.entitlementsServiceConfigNotFound
        case .notAuthorized:
            return L10n.Entitlements.Errors.notAuthorized
        case .limitExceeded:
            return L10n.Entitlements.Errors.limitExceeded
        case .requestFailed:
            return L10n.Entitlements.Errors.requestFailed
        case .rateLimitExceeded:
            return L10n.Entitlements.Errors.rateLimitExceeded
        case .graphQLError:
            return L10n.Entitlements.Errors.graphQLError
        case .fatalError(let description):
            return L10n.Entitlements.Errors.fatalError + ": \(description)"
        case .invalidRequest:
            return L10n.Entitlements.Errors.invalidRequest
        }
    }

    static func fromApiOperationError(error: Error) -> SudoEntitlementsError {
        // Check if ApiOperationError
        guard let apiOperationError = error as? ApiOperationError else {
            return .fatalError("Unexpected error: \(error)")
        }
        
        switch apiOperationError {
        case .accountLocked:
            return .accountLocked
        case .notSignedIn:
            return .notSignedIn
        case .notAuthorized:
            return .notAuthorized
        case .limitExceeded:
            return .limitExceeded
        case .insufficientEntitlements:
            return .insufficientEntitlements
        case .invalidArgument:
            return .invalidArgument
        case .invalidRequest:
            return .invalidRequest
        case .serviceError:
            return .serviceError
        case .rateLimitExceeded:
            return .rateLimitExceeded
        case .graphQLError(let cause):
            return SudoEntitlementsError(graphQLError: cause)
        case .requestFailed(let response, let cause):
            return .requestFailed(response: response, cause: cause)
        case .fatalError(let description):
            return .fatalError(description)
        default:
            return .fatalError("Unexpected API operation error: \(error)")
        }
    }
}

