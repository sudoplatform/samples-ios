//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import AWSS3

/// List of possible errors thrown by `S3Client` implementation.
///
public enum S3ClientError: Error {
    /// Indicates that a fatal error occurred. This could be due to coding error, out-of-memory
    /// condition or other conditions that is beyond control of `S3Client` implementation.
    case fatalError(description: String)
    /// Backed service is temporarily unavailable due to network or service availability issues.
    case serviceError(cause: Error)
}

/// S3 client wrapper protocol mainly used for providing an abstraction layer on top of
/// AWS S3 SDK.
public protocol S3Client: AnyObject {

    /// Uploads a blob to AWS S3.
    ///
    /// - Parameters:
    ///   - data: Blob to upload.
    ///   - contentType: Content type of the blob.
    ///   - bucket: Name of S3 bucket to store the blob.
    ///   - key: S3 key to be associated with the blob.
    /// - Throws: `S3ClientError`
    func upload(data: Data, contentType: String, bucket: String, key: String) async throws

    /// Downloads a blob from AWS S3.
    ///
    /// - Parameters:
    ///   - bucket: Name of S3 bucket to storing the blob.
    ///   - key: S3 key associated with the blob.
    /// - Returns: The data in the bucket
    /// - Throws: `S3ClientError`
    func download(bucket: String, key: String) async throws -> Data

    /// Deletes a blob stored AWS S3.
    ///
    /// - Parameters:
    ///   - bucket: Name of S3 bucket to storing the blob.
    ///   - key: S3 key associated with the blob.
    /// - Throws: `S3ClientError`
    func delete(bucket: String, key: String) async throws

}

/// Default S3 client implementation.
class DefaultS3Client: S3Client {

    private let s3ClientKey: String

    /// Initializes a `DefaultS3Client`.
    ///
    /// - Parameters:
    ///   - s3ClientKey: Key used for locating AWS S3 SDK clients in the shared service registry.
    init(s3ClientKey: String) {
        self.s3ClientKey = s3ClientKey
    }

    func upload(data: Data, contentType: String, bucket: String, key: String) async throws {
        guard let s3Client = AWSS3TransferUtility.s3TransferUtility(forKey: self.s3ClientKey) else {
            throw S3ClientError.fatalError(description: "Cannot find S3 client registered with key: \(self.s3ClientKey).")
        }

        do {
            try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
                s3Client.uploadData(data, bucket: bucket, key: key, contentType: contentType, expression: nil, completionHandler: { (_, error) -> Void in
                        if let error = error {
                            continuation.resume(throwing: S3ClientError.serviceError(cause: error))
                            return
                        } else {
                            continuation.resume()
                            return
                        }
                }).continueWith { (task) -> AnyObject? in
                    if let error = task.error {
                        continuation.resume(throwing: error)
                    }
                    return nil
                }
            })
        } catch {
            throw error
        }
    }

    func download(bucket: String, key: String) async throws -> Data {

        guard let s3Client = AWSS3TransferUtility.s3TransferUtility(forKey: self.s3ClientKey) else {
            throw S3ClientError.fatalError(description: "Cannot find S3 client registered with key: \(self.s3ClientKey).")
        }

        return try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Data, Error>) in
            s3Client.downloadData(fromBucket: bucket, key: key, expression: nil, completionHandler: { (_, _, data, error) in
                if let error = error {
                    continuation.resume(throwing: S3ClientError.serviceError(cause: error))
                    return
                }
                guard let data = data else {
                    continuation.resume(throwing: S3ClientError.fatalError(description: "Result did not contain JSON data."))
                    return
                }
                continuation.resume(returning: data)
            }).continueWith { (task) -> AnyObject? in
                if let error = task.error {
                    continuation.resume(throwing: error)
                }
                return nil
            }
        })
    }

    func delete(bucket: String, key: String) async throws {
        let s3Client = AWSS3.s3(forKey: self.s3ClientKey)

        guard let deleteRequest = AWSS3DeleteObjectRequest() else {
            throw S3ClientError.fatalError(description: "Failed to create a request to delete a S3 object.")
        }

        deleteRequest.bucket = bucket
        deleteRequest.key = key
        try await withCheckedThrowingContinuation({ (continuation: CheckedContinuation<Void, Error>) in
            s3Client.deleteObject(deleteRequest, completionHandler: { (_, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                continuation.resume()
            })
        })
    }
}
