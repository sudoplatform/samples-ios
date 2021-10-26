//
// Copyright © 2020 Anonyome Labs, Inc. All rights reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Foundation

public typealias PlatformOperationConditionResult = Result<Void, Error>

/// Protocol definition for a condition that must be met by a `PlatformOperation` before it can be executed.
public protocol PlatformOperationCondition {

    /// Name of the condition.
    static var name: String { get }

    /// Returns any generated operations that are needed as a dependency.
    func dependencyForOperation(_ operation: PlatformOperation) -> Operation?

    /// Evaluates whether the operation meets the condition.
    ///
    /// - Parameter operation: Operation to assert.
    func evaluateForOperation(_ operation: PlatformOperation, completion: (PlatformOperationConditionResult) -> Void)
}

/// Evalutes a PlatformOperationCondition.
public struct PlatformOperationConditionEvaluator {

    /// Prevent ability to initialize Class.
    private init() {}

    /// Evaluate a PlatformOperationCondition.
    ///
    /// - Parameter conditions: Condition to be evaluated.
    /// - Parameter operation: Operation to be used for evaluation.
    public static func evaluate(conditions: [PlatformOperationCondition], operation: PlatformOperation, completion: @escaping ([Error]) -> Void) {
        let conditionGroup = DispatchGroup()

        var results = [PlatformOperationConditionResult?](repeating: nil, count: conditions.count)
        for (index, condition) in conditions.enumerated() {
            conditionGroup.enter()
            condition.evaluateForOperation(operation) { result in
                results[index] = result
                conditionGroup.leave()
            }
        }

        conditionGroup.notify(queue: DispatchQueue.global()) {
            var failures = results.compactMap { $0?.error }

            if operation.isCancelled {
                failures.append(PlatformOperationErrors.conditionFailed)
            }

            completion(failures)
        }
    }
}
