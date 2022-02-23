//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation
import SudoLogging

/// Custom operation queue used for API operations. Mainly used to
/// rate control the operations and to record useful debugging information.
public class ApiOperationQueue {

    /// Maximum queue depth.
    public let maxQueueDepth: Int

    /// Number of operations currently queued.
    public var operationCount: Int {
        self.queue.operationCount
    }

    /// Maximum number of operations that could be executing at the same time.
    public var maxConcurrentOperationCount: Int {
        self.queue.maxConcurrentOperationCount
    }

    /// Operations currently queued.
    public var operations: [Operation] {
        self.queue.operations
    }

    private let queue: OperationQueue

    /// Instantiates an `ApiOperationQueue`.
    ///
    /// - Parameters:
    ///   - maxConcurrentOperationCount: Maximum number of operations that could be executing at the same time.
    ///   - maxQueueDepth: Maximum queue depth.
    init(maxConcurrentOperationCount: Int = 1, maxQueueDepth: Int = 10) {
        self.maxQueueDepth = maxQueueDepth
        self.queue = OperationQueue()
        self.queue.qualityOfService = .default
        self.queue.maxConcurrentOperationCount = maxConcurrentOperationCount
    }

    /// Adds an operation to the queue.
    ///
    /// - Parameter op: Operation to add to the queue.
    func addOperation(_ op: Operation) throws {
        if self.queue.operationCount >= self.maxQueueDepth {
            throw ApiOperationError.rateLimitExceeded
        }

        if let apiOp = op as? ApiOperation {
            apiOp.queuedTime = Date()
        }

        self.queue.addOperation(op)
    }

    /// Adds multiple operations to the queue.
    ///
    /// - Parameters:
    ///   - ops: Array of operations to add to the queue.
    ///   - wait: Determines whether or not to wait until all operations have completed before returning.
    func addOperations(_ ops: [Operation], waitUntilFinished wait: Bool) throws {
        if self.queue.operationCount >= self.maxQueueDepth {
            throw ApiOperationError.rateLimitExceeded
        }

        let now = Date()
        for op in ops {
            if let apiOp = op as? ApiOperation {
                apiOp.queuedTime = now
            }
        }
        self.queue.addOperations(ops, waitUntilFinished: wait)
    }

}
