//
//  Promise.swift
//  JustPromises
//
//  Created by Keith Moon on 09/09/2016.
//  Copyright © 2016 JUST EAT. All rights reserved.
//

import Foundation


/// The state of the Promise
///
/// - Unresolved: The promise has let to be resolved
/// - Result:     There is a result, associated value is the result
/// - Error:      There is an erroe, associated value is the error
/// - Cancelled:  The promise was cancelled
public enum FutureState<FutureType> {
    case unresolved
    case result(FutureType)
    case error(Error)
    case cancelled
    
    public var result: FutureType? {
        switch self {
        case .result(let result): return result
        default: return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .error(let error): return error
        default: return nil
        }
    }
}

public let sharedPromiseQueue = OperationQueue()


/// A promise to fulfill try and fulfill a future value.
/// Built onto of Operations, so can be combined with other operations,
/// added to queues and used as a dependancy.
public class Promise<FutureType>: AsyncOperation {
    
    fileprivate var executionBlock: (Promise<FutureType>) -> Void
    
    /// The state of the promise that will potentially contain the fulfilled future
    public var futureState: FutureState<FutureType> = .unresolved {
        didSet {
            switch futureState {
            case .error(_), .result(_): finish()
            default: break
            }
        }
    }
    
    /// Create a promise with an execution block.
    ///
    /// - parameter executionBlock: Execution block that will fulfill the futureState of the Promise. Ensure that you update the futureState as part of this execution.
    ///
    /// - returns: A Promise, that has not been put on a queue. Call await() or awaitOnMainQueue() to enqueue
    public init(executionBlock: @escaping (Promise<FutureType>) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }
    
    /// Create a promise with the given future state. Useful if you are continuing from a previous promise that has failed.
    ///
    /// - parameter immediateFutureState: The future state to immediately set on the Promise.
    ///
    /// - returns: A Promise, that has not been put on a queue. Call await() or awaitOnMainQueue() to enqueue
    public convenience init(immediateFutureState state: FutureState<FutureType>) {
        self.init(executionBlock: { promise in
            promise.futureState = state
        })
    }
    
    /// Should not be called directly. This will fire the execution block.
    override public func execute() {
        executionBlock(self)
    }
    
    /// Will cancel the promise
    open override func cancel() {
        super.cancel()
        futureState = .cancelled
    }
}

extension Promise {
    
    
    /// The promise will be added to the given queue.
    ///
    /// - parameter queue: The queue to await the promise on.
    ///
    /// - returns: The same promise will be returned, allowing chaining.
    public func await(onQueue queue: OperationQueue = sharedPromiseQueue) -> Promise<FutureType> {
        queue.addOperation(self)
        return self
    }
    
    
    /// The promise will be added to the main queue.
    ///
    /// - returns: The same promise will be returned, allowing chaining.
    public func awaitOnMainQueue() -> Promise<FutureType>  {
        return await(onQueue: .main)
    }
}

extension Promise {
    
    /// Continue after this Promise with another Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining.
    public func continuation<NextFutureType>(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
        let nextPromise = executionBlock(self)
        nextPromise.addDependency(self)
        queue.addOperation(nextPromise)
        return nextPromise
    }
    
    /// Continue after this Promise with a given block
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuation(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: @escaping (Promise<FutureType>) -> Void) {
        
        let operaton = BlockOperation { [weak self] in
            guard let strongSelf = self else { return }
            executionBlock(strongSelf)
        }
        operaton.addDependency(self)
        queue.addOperation(operaton)
    }
    
    /// Continue after this Promise with another Promise on the main queue
    ///
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining.
    public func continuationOnMainQueue<NextFutureType>(withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        return continuation(onQueue: .main, withBlock: executionBlock)
    }
    
    /// Continue after this Promise a given block on the main queue
    ///
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuationOnMainQueue(withBlock executionBlock: @escaping (Promise<FutureType>) -> Void) {
        continuation(onQueue: .main, withBlock: executionBlock)
    }
    
    /// Continue after this Promise if it succeeds with another Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuationOnSuccess<NextFutureType>(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
        let nextPromise = executionBlock(self)
        
        let existingBlock = nextPromise.executionBlock
        
        nextPromise.executionBlock = { [weak self] promise in
            
            guard let strongSelf = self else { return }
            
            // If we have a result, execute the block, otherwise inherit the previous promise's state
            switch strongSelf.futureState {
            
            case .result(_):
                existingBlock(promise)
                
            case .cancelled:
                promise.futureState = .cancelled
                
            case .unresolved:
                promise.futureState = .unresolved
                
            case .error(let error):
                promise.futureState = .error(error)
            }
        }
        nextPromise.addDependency(self)
        queue.addOperation(nextPromise)
        return nextPromise
    }
    
    /// Continue after this Promise if it succeeds, with a given block on the given queue
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuationOnSuccess(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: @escaping (Promise<FutureType>) -> Void) {
        
        let operaton = BlockOperation { [weak self] in
            
            guard let strongSelf = self else { return }
            
            // If we have a result, execute the block, otherwise inherit the previous promise's state
            switch strongSelf.futureState {
            case .result(_): executionBlock(strongSelf)
            default: break
            }
        }
        operaton.addDependency(self)
        queue.addOperation(operaton)
    }
    
    /// Continue after this Promise if it succeeds with another Promise
    ///
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuationOnSuccessOnMainQueue<NextFutureType>(withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        return continuationOnSuccess(onQueue: .main, withBlock: executionBlock)
    }
    
    /// Continue after this Promise if it succeeds, with a given block on the main queue
    ///
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuationOnSuccessOnMainQueue(withBlock executionBlock: @escaping (Promise<FutureType>) -> Void) {
        continuationOnSuccess(onQueue: .main, withBlock: executionBlock)
    }
}

extension Array where Element: Operation {
    
    
    /// Continue after all these operations are finished with a Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuation<NextFutureType>(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: () -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
        let nextPromise = executionBlock()
        for operation in self {
            nextPromise.addDependency(operation)
        }
        queue.addOperation(nextPromise)
        
        return nextPromise
    }
    
    /// Continue after all these operations are finished with a Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to execute after all operations are finished
    public func continuation(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: @escaping () -> Void) {
        
        let operaton = BlockOperation(block: executionBlock)
        for operation in self {
            operation.addDependency(operation)
        }
        queue.addOperation(operaton)
    }
    
    /// Continue after all these operations are finished with a Promise on given queue
    ///
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuationOnMainQueue<NextFutureType>(withBlock executionBlock: () -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        return continuation(onQueue: .main, withBlock: executionBlock)
    }
    
    /// Continue after all these operations are finished with a Promise on main queue
    ///
    /// - parameter executionBlock: The block to execute after all operations are finished
    public func continuationOnMainQueue(withBlock executionBlock: @escaping () -> Void) {
        continuation(onQueue: .main, withBlock: executionBlock)
    }
}
