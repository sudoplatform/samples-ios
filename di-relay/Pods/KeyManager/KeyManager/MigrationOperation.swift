//
//  MigrationTask.swift
//  KeyManager
//
//  Created by cchoi on 1/11/2016.
//  Copyright © 2016 Anonyome Labs, Inc. All rights reserved.
//

import Foundation

/**
    List of possible errors thrown by `MigrationOperation` implementation.
 
    - PreconditionFailure: Indicates one of the preconditions for executing
        the operation was not satisfied.
    - InvalidDependency: Indicates that one or more dependencies of the
        operation was invalid, e.g. does not conform to `MigrationOperation`
        protocol.
    - UnhandledKeyManagerError: Indicates that the operation encountered an
        expected error from `KeyManager` API.
    - FatalError: Indicates that a fatal error occurred. This could be due to
        coding error, out-of-memory condition or other conditions that is
        beyond control of `MigrationOperation` implementation.
 */
public enum MigrationOperationError: Error, Equatable {
    case preconditionFailure
    case invalidDependency
    case unhandledKeyManagerError(cause: KeyManagerError)
    case fatalError
}

/**
    List of possible operation status.
 */
public enum OperationStatus: String {
    case ready = "Ready"
    case executing = "Executing"
    case cancelled = "Cancelled"
    case finished = "Finished"
    case unknown = "Unknown"
}

/**
    Protocol encapsulating a set of methods that all migration operations
    must implement.
 */
public protocol MigrationOperation {

    /**
        Operation version.
     */
    var version: Int { get }

    /**
        Operation description.
     */
    var decription: String { get }

    /**
        Operation's start time.
     */
    var startTime: Date { get }

    /**
        Operation's finish time.
     */
    var finishTime: Date { get }
    
    /**
        Count of keys migrated.
     */
    var count: Int { get}
    
    /**
        Operation status.
     */
    var status: OperationStatus { get }
    
    /**
        Any error encountered while initializing or executing the operation.
     */
    var error: MigrationOperationError? { get }
    
    /**
        Executes the operation.
     */
    func execute()
    
    /**
        Completes the operation. This method should be called regardless of
        whether the operation executed successfully or failed.
     */
    func done()
    
    /**
        Evaluates the preconditions for the operation.
     
        - Returns: true if all preconditions were satisfied.
     */
    func evaluatePreconditions() -> Bool
    
}


/**
    A migration operation which performs a simple attribute update to a key, e.g.
    changing a key's synchronizable flag from true to false.
 */
public class SimpleMigrationOperation: Operation, MigrationOperation {

    private struct Constants {
        static let KVOKeyExecuting = "isExecuting"
        static let KVOKeyFinished = "isFinished"
    }
    
    public private(set) var version: Int = 0
    
    public private(set) var decription = ""
    
    public private(set) var startTime = Date(timeIntervalSince1970: 0)
    
    public private(set) var finishTime = Date(timeIntervalSince1970: 0)
    
    public private(set) var count = 0
    
    public private(set) var status: OperationStatus = .ready
    
    public private(set) var error: MigrationOperationError?

    private var searchParams = KeyAttributeSet()
    
    private var updates = KeyAttributeSet()
    
    override public var isAsynchronous: Bool {
        get {
            return true
        }
    }
    
    override public var isReady: Bool {
        get {
            return self.status == .ready
        }
    }
    
    override public var isExecuting: Bool {
        get {
            return self.status == .executing
        }
    }
    
    override public var isFinished: Bool {
        get {
            return self.status == .finished
        }
    }
    
    private var keyManager: KeyManager

    override public var isCancelled: Bool {
        get {
            return self.status == .cancelled
        }
    }
    
    /**
        Intializes a new `SimpleMigrationOperation` instance with version, name, description,
        `KeyManager` instance, search parameters and the set of updates to perform on keys.
     
        - Returns: A new initialized `SimpleMigrationOperation` instance.
     */
    public init(version: Int, name: String, description: String, keyManager: KeyManager, searchParams: KeyAttributeSet, updates: KeyAttributeSet) {
        self.version = version
        self.decription = "\(name): \(description)"
        self.keyManager = keyManager
        self.searchParams = searchParams
        self.updates = updates
        super.init()
        self.name = name
    }
    
    public func evaluatePreconditions() -> Bool {
        guard updates.count > 0 else {
            return false
        }
        
        var status = true
        for operation in self.dependencies  {
            if let operation = operation as? MigrationOperation, operation.error != nil {
                status = false
                break
            }
        }
        
        return status
    }
    
    public func execute() {
        do {
            defer {
                self.done()
            }
            
            let attributesArray = try self.keyManager.getAttributesForKeys(self.searchParams)
            for attributes in attributesArray {
                let updates = self.updates.subtract(attributes)
                
                guard updates.count > 0 else {
                    break
                }
                
                if let type = attributes.getAttribute(.type), let name = attributes.getAttribute(.name) {
                    switch (type.value, name.value) {
                    case (.keyTypeValue(let type), .stringValue(let name)):
                        try self.keyManager.updateKeyAttributes(self.updates, name: name, type: type)
                        self.count += 1
                    default:
                        break
                    }
                }
            }
            
            // TODO: We should probably record the key set version in the keychain and not repeat
            // the migration if this operation's version is less than or equal to the current key
            // set version.
        } catch let error as KeyManagerError {
            self.error = MigrationOperationError.unhandledKeyManagerError(cause: error)
        } catch {
            self.error = MigrationOperationError.fatalError
        }
    }
    
    public func done() {
        self.finishTime = Date()
        
        let executing = self.isExecuting
        if executing {
            self.willChangeValue(forKey: Constants.KVOKeyExecuting)
        }
        
        self.willChangeValue(forKey: Constants.KVOKeyFinished)
        self.status = .finished;
        self.didChangeValue(forKey: Constants.KVOKeyFinished)
        
        if executing
        {
            self.didChangeValue(forKey: Constants.KVOKeyExecuting)
        }
    }
    
    override public func start() {
        self.startTime = Date()
        
        guard self.error == nil else {
            self.done()
            return
        }
        
        if self.status == .ready {
            if self.evaluatePreconditions() {
                self.willChangeValue(forKey: Constants.KVOKeyExecuting)
                self.status = .executing;
                self.didChangeValue(forKey: Constants.KVOKeyExecuting)
                
                self.execute()
            } else {
                self.error = .preconditionFailure
                self.done()
            }
        }
    }
    
    override public func addDependency(_ operation: Operation) {
        guard let _ = operation as? MigrationOperation else {
            // There's no good way to indicate error here since we can't add throw
            // to overriden method. Best we can do is mark this operation as
            // invalid so that we can abort the operation as quickly as possible.
            self.error = .invalidDependency
            return
        }
        
        super.addDependency(operation)
    }
    
}
