//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

/// Methods for transporting data between agents.
struct HTTPTransports {
    enum TransmissionError: Error, LocalizedError {
        case unsupportedEndpoint
        case requestFailed(Error?)
        case responseMalformed
        case unexpectedHTTPResponse(Int, Data?)

        var errorDescription: String? {
            switch self {
            case .unsupportedEndpoint:
                return "Unsupported endpoint scheme"
            case .requestFailed(let error):
                return error?.localizedDescription ?? "Request failed"
            case .responseMalformed:
                return "Unable to parse response as HTTP URL response"
            case .unexpectedHTTPResponse(let code, let responseData):
                let response = responseData.map { String(decoding: $0, as: Unicode.UTF8.self) }
                return "Unexpected HTTP status code \(code)\(response.map { ": \($0)" } ?? "")"
            }
        }
    }

    /// Send data to endpoint via HTTP POST.
    /// Will throw a `TransmissionError` if not successful.
    ///
    /// - Parameters:
    ///   - data: data to send.
    ///   - endpoint: destination HTTP endpoint.
    static func transmit(
        data: Data,
        to endpoint: URL
    ) async throws {
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = data
        // Transmit as plaintext
        request.setValue("text/plain", forHTTPHeaderField: "Content-Type")

        return try await withCheckedThrowingContinuation { continuation in
            let task = URLSession.shared.dataTask(with: request) { data, response, _ in
                guard let response = response as? HTTPURLResponse else {
                    return continuation.resume(throwing: TransmissionError.responseMalformed)
                }

                switch response.statusCode {
                case 200..<300: continuation.resume(returning: ())
                default: continuation.resume(throwing: TransmissionError.unexpectedHTTPResponse(response.statusCode, data))
                }
            }
            task.resume()
        }
    }
}
