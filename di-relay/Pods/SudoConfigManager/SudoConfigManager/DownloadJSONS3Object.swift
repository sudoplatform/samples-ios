//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import SudoLogging

/// Dowloads a JSON object from AWS S3.
class DownloadJSONS3Object: SudoOperation {

    private unowned let s3Client: S3Client

    private let key: String
    
    public var jsonObject: [String: Any] = [:]

    /// Initializes an operation to download a JSON object from AWS S3.
    ///
    /// - Parameters:
    ///   - s3Client: S3 client to use for interacting with AWS S3.
    ///   - logger: Logger to use for logging.
    ///   - key: S3 key associated with the object.
    init(s3Client: S3Client,
         logger: Logger = Logger.sudoConfigManagerLogger,
         key: String) {
        self.s3Client = s3Client
        self.key = key
        
        super.init(logger: logger)
    }

    override func execute() {
        do {
            try self.s3Client.getObject(key: self.key) { (result) in
                defer {
                    self.done()
                }
                
                switch result {
                case .success(let data):
                    guard let jsonObject = data.toJSONObject() as? [String: Any] else {
                        self.error = SudoConfigManagerError.fatalError(description: "Result did not contain JSON data.")
                        return
                    }
                    
                    self.jsonObject = jsonObject
                case .failure(let cause):
                    self.error = cause
                }
            }
        } catch {
            self.error = error
            self.done()
        }
    }

}
