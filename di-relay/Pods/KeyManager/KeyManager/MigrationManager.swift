//
//  MigrationManager.swift
//  KeyManager
//
//  Created by cchoi on 1/11/2016.
//  Copyright © 2016 Anonyome Labs, Inc. All rights reserved.
//

import Foundation

/**
    List of possible errors thrown by `MigrationManager` implementation.
 
    - InvalidOperation: Indicates the migration operation being added is invalid,
        e.g. has a version lower or equal to the preceding operation in the queue.
    - FatalError: Indicates that a fatal error occurred. This could be due to
        coding error, out-of-memory condition or other conditions that is
        beyond control of `MigrationManager` implementation.
 */
public enum MigrationManagerError: Error {
    case invalidOperation
    case fatalError
}

/**
    List of possible results returned by `MigrationManager` after the migration has
    been executed.
 
    - Success: Indicates the migration has completed successfully. Associated values
        indicate the version of the last successful migration operation, count of
        keys migrated and total elapsed time (in seconds) of migration operations.
    - Failure: Indicates the migration failed with one or more errors. Associated
        values provides the list of errors (operation decription and error), the
        version of last successful migration operation and count of keys migrated.
 */
public enum Result {
    case success(version: Int, count: Int, time: Double)
    case failure(errors: [(String, MigrationOperationError)], version: Int, count: Int)
}

/**
    Protocol encapsulating a set of methods for migrating passwords and cryptographic
    keys from one version to another.
 */
public protocol MigrationManager {
    
    /**
        Adds a migration operation to `MigrationManager`.
     
        - Parameters:
            - operation: Migration operation to add.
     
        - Throws:
            `MigrationManagerError.InvalidOperation`
     */
    func addMigrationOperation<T>(_ operation: T) throws where T: Operation, T: MigrationOperation

    /**
        Performs the migration by executing migration operations within a specific
        version range.
     
        - Parameters:
            - from: The minimum version of migration operation to execute.
            - to: The maximum version of migration operation to execute.
            - completion: Completion handler to return the migration result.
     */
    func migrate(_ from: Int, to: Int, completion: @escaping (_ result: Result) -> Void)

    /**
        Resets `MigrationManager` by removing all migration operations from its queue.
     */
    func reset()
    
}

/**
    Class encapsulating the default implementation of `MigrationManager` protocol.
 */
public class MigrationManagerImpl: MigrationManager {
    
    private struct Constants {
        
        static let migrationOperationQueueName = "com.anonyome.queue.migration.operation"
        
        static let migrationDispatchQueueName = "com.anonyome.queue.migration.dispatch"
        
    }
    
    private var operations: [Operation] = []
    
    private let operationQueue = OperationQueue()
    
    private let dispatchQueue = DispatchQueue(label: Constants.migrationDispatchQueueName, attributes: [])

    /**
        Intializes a new `MigrationManagerImpl` instance.
     
        - Returns: A new initialized `MigrationManagerImpl` instance.
     */
    public init() {
        self.operationQueue.name = Constants.migrationOperationQueueName
        self.operationQueue.maxConcurrentOperationCount = 1
    }

    public func addMigrationOperation<T>(_ operation: T) throws where T: Operation, T: MigrationOperation {
        // Each migration operation should move up the key set version.
        if !self.operations.isEmpty {
            guard let last = self.operations.last as? MigrationOperation, last.version < operation.version else {
                throw MigrationManagerError.invalidOperation
            }
        }
        
        self.operations.append(operation)
    }
    
    public func migrate(_ from: Int = 0, to: Int = 0, completion: @escaping (_ result: Result) -> Void) {
        self.dispatchQueue.async {
            let operations = self.operations.filter() {
                // Couldn't figure out how to declare a type as a subclass of NSOperation that
                // also conforms to another protocol so needed the extra casting.
                guard let operation = $0 as? MigrationOperation else {
                    return false
                }
                
                return operation.version >= from && operation.version <= to
            }
            
            self.operationQueue.addOperations(operations, waitUntilFinished: true)
            
            var errors: [(String, MigrationOperationError)] = []
            var count = 0
            var version = 0
            var time: Double = 0.0
            for operation in operations {
                if let operation = operation as? MigrationOperation {
                    count += operation.count
                    time += operation.finishTime.timeIntervalSince(operation.startTime as Date)
                    if let error = operation.error {
                        errors.append((operation.decription, error))
                    } else {
                        version = operation.version
                    }
                }
            }
            
            if errors.isEmpty {
                completion(.success(version: version, count: count, time: time))
            } else {
                completion(.failure(errors: errors, version: version, count: count))
            }
        }
    }
    
    public func reset() {
        self.operations.removeAll()
    }
    
}
