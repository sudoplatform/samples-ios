//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import SudoDecentralizedIdentity
import Indy

extension SudoDecentralizedIdentityClientError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .createWalletFailed:
            return "Failed to create wallet"
        case .openWalletFailed:
            return "Failed to open wallet"
        case .createPrimaryDidFailed, .retrievePrimaryDidFailed:
            return "Failed to retrieve primary DID"
        case .failedToDecodeMessage:
            return "Failed to decode message"
        case .failedToEncodeMessageUtf8:
            return "Failed to encode message as a UTF-8 string"
        case .general(let error):
            return error.localizedDescription
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

extension PairwiseServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .general(let error):
            return error.localizedDescription
        case .indy(let error):
            return "Indy error: \(descriptionForIndyError(error))"
        case .invalidJson:
            return "Invalid JSON"
        case .listDidJsonNotReturned:
            return "Could not list DIDs"
        case .retrieveJsonNotReturned:
            return "Could not retrieve DID"
        case .didAndVerkeyNotReturned:
            return "Could not retrieve DID and verkey"
        case .unknown:
            return "An unknown error occurred"
        }
    }
}

extension CryptoServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .failedToEncodeReceiverVerkeys(let error):
            return "Failed to encode receiver verkeys: \(error)"
        case .failedToDecodeResultingData(let error):
            return "Failed to decode packed/unpacked data: \(error)"
        case .indyError(.none):
            return "An unknown Indy error occurred"
        case .indyError(.some(let indyCode, let message)):
            return message ?? "Indy error \(indyCode.rawValue)"
        }
    }
}

extension WalletServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .general(let error):
            return error.localizedDescription
        case .indy(let error):
            return "Indy error: \(descriptionForIndyError(error))"
        case .invalidJson:
            return "Invalid JSON"
        case .unknown:
            return "An unknown error occurred"
        case .keyNotFoundForWalletId:
            return "Key for wallet not found"
        }
    }
}

private func descriptionForIndyError(_ error: Error) -> String {
    switch error {
    case let indyError as NSError where indyError.domain == "IndyErrorDomain":
        let indyErrorCode = IndyErrorCode(rawValue: indyError.code)
        return indyError.userInfo["message"] as? String ?? error.localizedDescription
    default:
        return error.localizedDescription
    }
}
