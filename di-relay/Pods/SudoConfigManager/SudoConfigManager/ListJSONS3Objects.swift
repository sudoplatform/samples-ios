//
// Copyright © 2022 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import AWSS3
import SudoLogging

/// Lists S3 objects with extension ".json" in a given bucket.
class ListJSONS3Objects: SudoOperation {

    private unowned let s3Client: S3Client

    public var keys: [String] = []

    /// Initializes an operation to list the content of a S3 bucket.
    ///
    /// - Parameters:
    ///   - s3Client: S3 client to use for interacting with AWS S3.
    ///   - logger: Logger to use for logging.
    init(s3Client: S3Client,
         logger: Logger = Logger.sudoConfigManagerLogger) {
        self.s3Client = s3Client
        
        super.init(logger: logger)
    }

    override func execute() {
        do {
            try self.s3Client.listObjects { (result) in
                defer {
                    self.done()
                }
                
                switch result {
                case .success(let keys):
                    self.keys = keys.filter { $0.hasSuffix(".json") }
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
