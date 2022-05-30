//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSAppSync
import SudoApiClient

/// Errors that occur in SudoDIRelay.
public enum SudoDIRelayError: Error, Equatable, LocalizedError {

    // MARK: - Client

    /// Configuration supplied to `DefaultSudoDIRelayClient` is invalid.
    case invalidConfig
    /// User is not signed in.
    case notSignedIn

    /// The configuration related to Relay Service is not found in the provided configuration file
    /// This may indicate that the Relay Service is not deployed into your runtime instance or the
    /// configuration file that you are using is invalid.
    case relayServiceConfigNotFound

    /// Message sent to create the postbox is invalid.
    case invalidInitMessage

    // MARK: - SudoPlatformError

    case accountLocked
    case ambiguousRelay
    case decodingError
    case environmentError
    case identityInsufficient
    case identityNotVerified
    case insufficientEntitlementsError
    case internalError(_ cause: String?)
    case invalidArgument(_ msg: String?)
    case invalidTokenError
    case noEntitlementsError
    case policyFailed
    case serviceError
    case unknownTimezone
    case unauthorizedPostboxAccess
    case invalidRequest
    case notAuthorized
    case limitExceeded
    case insufficientEntitlements
    case versionMismatch
    case rateLimitExceeded
    case graphQLError(description: String?)
    case requestFailed(response: HTTPURLResponse?, cause: Error?)

    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory condition or other
    /// conditions that is beyond control of `SudoIdentityVerificationClient` implementation.
    case fatalError(description: String)

    // MARK: - Lifecycle

    /// Initialize a `SudoDIRelayError` from a `GraphQLError`.
    ///
    /// If the GraphQLError is unsupported, `nil` will be returned instead.
    init(graphQLError error: GraphQLError) {
        guard let errorType = error["errorType"] as? String else {
            self = .internalError(error.message)
            return
        }
        switch errorType {
        case "sudoplatform.relay.AmbiguousRelayError":
            self = .ambiguousRelay
        case "sudoplatform.relay.InvalidInitMessage":
            self = .invalidInitMessage
        case "sudoplatform.relay.UnauthorizedPostboxAccess":
            self = .unauthorizedPostboxAccess
        case "sudoplatform.AccountLocked":
            self = .accountLocked
        case "sudoplatform.DecodingError":
            self = .decodingError
        case "sudoplatform.EnvironmentError":
            self = .environmentError
        case "sudoplatform.IdentityVerificationInsufficientError":
            self = .identityInsufficient
        case "sudoplatform.IdentityVerificationNotVerifiedError":
            self = .identityNotVerified
        case "sudoplatform.InsufficientEntitlementsError":
            self = .insufficientEntitlementsError
        case "sudoplatform.InvalidArgumentError":
            let msg = error.message.isEmpty ? nil : error.message
            self = .invalidArgument(msg)
        case "sudoplatform.relay.InvalidTokenError":
            self = .invalidTokenError
        case "sudoplatform.NoEntitlementsError":
            self = .noEntitlementsError
        case "sudoplatform.PolicyFailed":
            self = .policyFailed
        case "sudoplatform.ServiceError":
            self = .serviceError
        case "sudoplatform.UnknownTimezoneError":
            self = .unknownTimezone
        default:
            self = .internalError("\(errorType) - \(error.message)")
        }
    }

    public var errorDescription: String? {
        switch self {
        case .accountLocked:
            return L10n.Relay.Errors.accountLocked
        case .ambiguousRelay:
            return L10n.Relay.Errors.ambiguousRelayError
        case .decodingError:
            return L10n.Relay.Errors.decodingError
        case .environmentError:
            return L10n.Relay.Errors.environmentError
        case .identityInsufficient:
            return L10n.Relay.Errors.identityInsufficient
        case .identityNotVerified:
            return L10n.Relay.Errors.identityNotVerified
        case .insufficientEntitlementsError:
            return L10n.Relay.Errors.insufficientRelayError
        case let .internalError(cause):
            return cause ?? "Internal Error"
        case .invalidArgument(let msg):
            // Breaks all localization rules but good enough for here
            guard let msg = msg else {
                return L10n.Relay.Errors.invalidArgument
            }
            return "\(L10n.Relay.Errors.invalidArgument): \(msg)"

        case .invalidConfig:
            return L10n.Relay.Errors.invalidConfig
        case .invalidTokenError:
            return L10n.Relay.Errors.invalidTokenError
        case .notSignedIn:
            return L10n.Relay.Errors.notSignedIn
        case .policyFailed:
            return L10n.Relay.Errors.policyFailed
        case .serviceError:
            return L10n.Relay.Errors.serviceError
        case .unknownTimezone:
            return L10n.Relay.Errors.unknownTimezone
        case .relayServiceConfigNotFound:
            return L10n.Relay.Errors.relayServiceConfigNotFound
        case .invalidInitMessage:
            return L10n.Relay.Errors.invalidInitMessage
        case .noEntitlementsError:
            return L10n.Relay.Errors.noEntitlementsError
        case .unauthorizedPostboxAccess:
            return L10n.Relay.Errors.unauthorizedPostboxAccess
        case .fatalError:
            return L10n.Relay.Errors.fatalError
        case .invalidRequest:
            return L10n.Relay.Errors.invalidRequest
        case .notAuthorized:
            return L10n.Relay.Errors.notAuthorized
        case .insufficientEntitlements:
            return L10n.Relay.Errors.insufficientEntitlementsError
        case .versionMismatch:
            return L10n.Relay.Errors.versionMismatch
        case .graphQLError:
            return L10n.Relay.Errors.fatalError
        case .requestFailed:
            return L10n.Relay.Errors.requestFailed
        case .limitExceeded:
            return L10n.Relay.Errors.limitExceeded
        case .rateLimitExceeded:
            return L10n.Relay.Errors.rateLimitExceeded
        }
    }

    // MARK: - Conformance: Equatable

    public static func == (lhs: SudoDIRelayError, rhs: SudoDIRelayError) -> Bool {
        switch (lhs, rhs) {
        case (.requestFailed(let lhsResponse, let lhsCause), requestFailed(let rhsResponse, let rhsCause)):
            if let lhsResponse = lhsResponse, let rhsResponse = rhsResponse {
                return lhsResponse.statusCode == rhsResponse.statusCode
            }
            return type(of: lhsCause) == type(of: rhsCause)
        case (.accountLocked, .accountLocked),
            (.environmentError, .environmentError),
            (.fatalError, .fatalError),
            (.graphQLError, .graphQLError),
            (.identityInsufficient, .identityInsufficient),
            (.identityNotVerified, .identityNotVerified),
            (.insufficientEntitlements, .insufficientEntitlements),
            (.internalError, internalError),
            (.invalidArgument, .invalidArgument),
            (.invalidConfig, .invalidConfig),
            (.invalidRequest, .invalidRequest),
            (.invalidTokenError, .invalidTokenError),
            (.limitExceeded, .limitExceeded),
            (.notAuthorized, .notAuthorized),
            (.notSignedIn, .notSignedIn),
            (.rateLimitExceeded, .rateLimitExceeded),
            (.serviceError, .serviceError),
            (.unknownTimezone, .unknownTimezone),
            (.versionMismatch, .versionMismatch),
            (.ambiguousRelay, .ambiguousRelay),
            (.decodingError, .decodingError),
            (.insufficientEntitlementsError, .insufficientEntitlementsError),
            (.noEntitlementsError, .noEntitlementsError),
            (.policyFailed, .policyFailed),
            (.unauthorizedPostboxAccess, .unauthorizedPostboxAccess):
            return true
        default:
            return false
        }
    }
}

extension SudoDIRelayError {

    struct Constants {
        static let errorType = "errorType"
    }

    static func fromApiOperationError(error: Error) -> SudoDIRelayError {
        switch error {
        case ApiOperationError.accountLocked:
            return .accountLocked
        case ApiOperationError.invalidRequest:
            return .invalidRequest
        case ApiOperationError.notSignedIn:
            return .notSignedIn
        case ApiOperationError.notAuthorized:
            return .notAuthorized
        case ApiOperationError.limitExceeded:
            return .limitExceeded
        case ApiOperationError.insufficientEntitlements:
            return .insufficientEntitlements
        case ApiOperationError.serviceError:
            return .serviceError
        case ApiOperationError.versionMismatch:
            return .versionMismatch
        case ApiOperationError.rateLimitExceeded:
            return .rateLimitExceeded
        case ApiOperationError.graphQLError(let cause):
            return .graphQLError(description: "Unexpected GraphQL error: \(cause)")
        case ApiOperationError.requestFailed(let response, let cause):
            return .requestFailed(response: response, cause: cause)
        default:
            return .fatalError(description: "Unexpected API operation error: \(error)")
        }
    }
}
