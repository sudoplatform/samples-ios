//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Methods for transporting data between agents.
struct HTTPTransports {

    /// Custom error for HTTP transmission.
    enum TransmissionError: Error, LocalizedError {
        case unsupportedEndpoint
        case requestFailed(Error?)
        case unexpectedHTTPResponse(Int, Data?)

        var errorDescription: String? {
            switch self {
            case .unsupportedEndpoint:
                return "Unsupported endpoint scheme"
            case .requestFailed(let error):
                return error?.localizedDescription ?? "Request failed"
            case .unexpectedHTTPResponse(let code, let responseData):
                let response = responseData.map { String(decoding: $0, as: Unicode.UTF8.self) }
                return "Unexpected HTTP status code \(code)\(response.map { ": \($0)" } ?? "")"
            }
        }
    }


    /// Transmit the given `data` to the given `endpoint`.
    ///
    /// - Parameters:
    ///   - data: The data to transmit.
    ///   - endpoint: The endpoint to POST the `data` to.
    ///   - completion: Resolves to `Void ` on success or a `TransmissionError` upon failure.
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
        request.httpBody = data
        
        // Transmit as plaintext
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")
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
