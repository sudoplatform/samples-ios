//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import AWSAppSync

/// Worker class to convert GraphQL Result and error to a Swift Result type.
struct GraphQLResultWorker {

    // MARK: - Methods

    /// Convert a `GraphQLResult` with optional `Error` to `Swift.Result`.
    ///
    /// All errors are converted to a `SudoDIRelayError.internalError`.
    /// If unexpected values are input or bad state with no specific error, a default error will be returned. The default error is:
    /// > Invalid result returned from Relay Service.
    /// - Parameters:
    ///   - result: `GraphQLResult` to convert. If `nil` and `error` is `nil`, default error will be returned.
    ///   - error: Optional `Error` to handle.
    /// - Returns: Converted `Swift.Result`.
    func convertToResult<D>(_ result: GraphQLResult<D>?, error: Error?) -> Swift.Result<D, Error> {
        if let error = error {
            return invalidResult(error)
        }
        guard let result = result else {
            return invalidResult()
        }
        if let error = result.errors?.first {
            return invalidResult(error)
        }
        guard let data = result.data else {
            return invalidResult()
        }
        return .success(data)
    }

    // MARK: - Helpers

    /// Invalid result has been received.
    /// - Parameter error: Optional `Error` to handle.
    /// - Returns: `Swift.Result` marked as an error.
    func invalidResult<D>(_ error: Error? = nil) -> Swift.Result<D, Error> {
        let errorDescription = error?.localizedDescription ?? "Invalid result returned from Relay Service"
        let error = SudoDIRelayError.internalError(errorDescription)
        return .failure(error)
    }

}
