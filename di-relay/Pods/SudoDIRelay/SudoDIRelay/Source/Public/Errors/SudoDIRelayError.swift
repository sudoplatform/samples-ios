//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoOperations
import AWSAppSync

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

    case accountLockedError
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

    // MARK: - Lifecycle

    /// Initialize a `SudoDIRelayError` from a `GraphQLError`.
    ///
    /// If the GraphQLError is unsupported, `nil` will be returned instead.
    init?(graphQLError error: GraphQLError) {
        guard let errorType = error["errorType"] as? String else {
            return nil
        }
        switch errorType {
        case "sudoplatform.relay.AmbiguousRelayError":
            self = .ambiguousRelay
        case "sudoplatform.relay.InvalidInitMessage":
            self = .invalidInitMessage
        default:
            return nil
        }
    }

    /// Initialize a `SudoDIRelayError` from a `SudoPlatformError`.
    init(platformError error: SudoPlatformError) {
        switch error {
        case .accountLockedError:
            self = .accountLockedError
        case .decodingError:
            self = .decodingError
        case .environmentError:
            self = .environmentError
        case .identityInsufficient:
            self = .identityInsufficient
        case .identityNotVerified:
            self = .identityNotVerified
        case .internalError(let cause):
            self = .internalError(cause)
        case .insufficientEntitlementsError:
            self = .insufficientEntitlementsError
        case .invalidArgument(let msg):
            self = .invalidArgument(msg)
        case .invalidTokenError:
            self = .invalidTokenError
        case .noEntitlementsError:
            self = .noEntitlementsError
        case .policyFailed:
            self = .policyFailed
        case .serviceError:
            self = .serviceError
        case .unknownTimezone:
            self = .unknownTimezone
        }
    }

    public var errorDescription: String? {
        switch self {
        case .accountLockedError:
            return L10n.Relay.Errors.accountLockedError
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
        }
    }
}
