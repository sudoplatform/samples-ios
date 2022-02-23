//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging
import AWSS3

/// List of possible errors thrown by `S3Client` implementation.
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
    
    /// Retrieves a S3 object.
    ///
    /// - Parameters:
    ///   - key: S3 key associated with the object.
    ///   - completion: Completion handler to invoke to pass the retrieved object as `Data` or error.
    /// - Throws: `S3ClientError`
    func getObject(key: String, completion: @escaping (Swift.Result<Data, Error>) -> Void) throws
    
    /// Lists the content of the S3 bucket associated with this client.
    ///
    /// - Parameters:
    ///   - completion: Completion handler to invoke to pass the list of object keys or error.
    /// - Throws: `S3ClientError`
    func listObjects(completion: @escaping (Swift.Result<[String], Error>) -> Void) throws
    
}

/// Default S3 client implementation.
class DefaultS3Client: S3Client {
    
    private struct Constants {
        // Service client key for S3 client specific to service info bucket.
        static let serviceClientKey = "com.sudoplatform.s3.serviceinfo"
    }
    
    private let bucket: String
    
    private let s3Client: AWSS3
    
    private let logger: Logger
    
    /// Initializes a `DefaultS3Client`.
    ///
    /// - Parameters:
    ///   - region: AWS region.
    ///   - bucket: Name of S3 bucket to be associated with this client.
    init(region: String, bucket: String, logger: Logger = Logger.sudoConfigManagerLogger) throws {
        self.bucket = bucket
        self.logger = logger
        guard let regionType = AWSEndpoint.regionTypeFrom(name: region),
              let configuration = AWSServiceConfiguration(region: regionType, credentialsProvider: AWSAnonymousCredentialsProvider()) else {
            throw S3ClientError.fatalError(description: "Failed to initialize S3 client: region=\(region), bucket=\(bucket)")
        }
        AWSS3.register(with: configuration, forKey: Constants.serviceClientKey)
        self.s3Client = AWSS3.s3(forKey: Constants.serviceClientKey)
    }
    
    func getObject(key: String, completion: @escaping (Swift.Result<Data, Error>) -> Void) throws {
        self.logger.info("Retrieving a S3 object. bucket: \(self.bucket), key: \(key)")
        
        guard let request = AWSS3GetObjectRequest() else {
            throw SudoConfigManagerError.fatalError(description: "Failed to instantiate S3 get object request.")
        }
        
        request.bucket = self.bucket
        request.key = key
        self.s3Client.getObject(request).continueWith { (task) -> AnyObject? in
            if let error = task.error {
                completion(.failure(S3ClientError.serviceError(cause: error)))
                return nil
            }
            
            guard let body = task.result?.body as? Data else {
                completion(.failure(S3ClientError.fatalError(description: "Result did not contain JSON data.")))
                return nil
            }
            
            completion(.success(body))
            return nil
        }
    }
    
    func listObjects(completion: @escaping (Result<[String], Error>) -> Void) throws {
        self.logger.info("Listing objects in S3 bucket: \(self.bucket)")
        
        guard let request = AWSS3ListObjectsV2Request() else {
            throw S3ClientError.fatalError(description: "Failed to instantiate S3 list objects request.")
        }
        
        request.bucket = self.bucket
        self.s3Client.listObjectsV2(request).continueWith { (task) -> AnyObject? in
            if let error = task.error {
                completion(.failure(S3ClientError.serviceError(cause: error)))
                return nil
            }
            
            guard let objects = task.result?.contents else {
                completion(.success([]))
                return nil
            }
            
            completion(.success(objects.compactMap { $0.key }))
            return nil
        }
    }
    
}
