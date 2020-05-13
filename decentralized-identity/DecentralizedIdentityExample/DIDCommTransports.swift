//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoDecentralizedIdentity

/// Methods for transporting data between agents.
///
/// # Reference
/// [Aries RFC 0025: DIDComm Transports](https://github.com/hyperledger/aries-rfcs/tree/master/features/0025-didcomm-transports)
struct DIDCommTransports {
    enum TransmissionError: Error, LocalizedError {
        case unsupportedEndpoint
        case requestFailed(Error?)
        case unexpectedHTTPResponse(Int, Data?)

        var localizedDescription: String {
            switch self {
            case .unsupportedEndpoint:
                return "Unsupported endpoint scheme"
            case .requestFailed(let error):
                return error?.localizedDescription ?? "Request failed"
            case .unexpectedHTTPResponse(let code, let response):
                return "Unexpected HTTP status code \(code)\(response.map { ": \($0)" } ?? "")"
            }
        }
    }

    static func transmit(
        data: Data,
        to endpoint: String,
        completion: @escaping (Result<Void, TransmissionError>) -> Void
    ) {
        guard let endpointUrl = URL(string: endpoint),
            ["https", "http"].contains(endpointUrl.scheme) else {
                // TODO: handle websocket and XMPP endpoints
                return completion(.failure(.unsupportedEndpoint))
        }

        var request = URLRequest(url: endpointUrl)
        request.httpMethod = "POST"
        request.addValue("application/didcomm-enc-env", forHTTPHeaderField: "Content-Type")
        request.httpBody = data
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let response = response as? HTTPURLResponse else {
                return completion(.failure(.requestFailed(error)))
            }

            switch response.statusCode {
            case 200..<300: completion(.success(()))
            default: completion(.failure(.unexpectedHTTPResponse(response.statusCode, data)))
            }
        }
        task.resume()
    }
}
