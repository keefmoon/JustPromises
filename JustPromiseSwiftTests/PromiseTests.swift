//
//  PromiseTests.swift
//  JustPromises
//
//  Created by Keith Moon on 12/09/2016.
//  Copyright © 2016 JUST EAT. All rights reserved.
//

import XCTest
import Foundation
import JustPromiseSwift

class PromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPromiseWillExecuteWhenAwaiting() {
        
        let asyncExpectation = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            promise.futureState = .result()
            asyncExpectation.fulfill()
        }.await()
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseWillExecuteOnMainQueueWhenAwaiting() {
        
        let asyncExpectation = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            let onMainQueue = Thread.current.isMainThread
            XCTAssertTrue(onMainQueue)
            
            promise.futureState = .result()
            asyncExpectation.fulfill()
        }.awaitOnMainQueue()
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinued() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        let asyncExpectation3 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .result()
            asyncExpectation1.fulfill()
            
            }.await().continuation { previousPromise in
                
                return Promise<Void> { promise in
                    promise.futureState = .result()
                    asyncExpectation2.fulfill()
                }
                
            }.continuation { _ in
                
                asyncExpectation3.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinuedOnMainQueue() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        let asyncExpectation3 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .result()
            asyncExpectation1.fulfill()
            
            }.await().continuationOnMainQueue { previousPromise in
                
                return Promise<Void> { promise in
                    
                    let onMainQueue = Thread.current.isMainThread
                    XCTAssertTrue(onMainQueue)
                    
                    promise.futureState = .result()
                    asyncExpectation2.fulfill()
                }
                
            }.continuationOnMainQueue { _ in
                
                let onMainQueue = Thread.current.isMainThread
                XCTAssertTrue(onMainQueue)
                
                asyncExpectation3.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinuedOnSuccess() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        let asyncExpectation3 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .result()
            asyncExpectation1.fulfill()
            
            }.await().continuationOnSuccess { previousPromise in
                
                return Promise<Void> { promise in
                    
                    promise.futureState = .result()
                    asyncExpectation2.fulfill()
                }
                
            }.continuationOnSuccess { _ in
                
                asyncExpectation3.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseContinuedOnSuccessDoesntExecuteIfFailed() {
        
        enum TestError: Error {
            case somethingWentWrong
        }
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .error(TestError.somethingWentWrong)
            asyncExpectation1.fulfill()
            
            }.await().continuationOnSuccess { previousPromise in
                
                return Promise<Void> { promise in
                    
                    promise.futureState = .result()
                    XCTFail()
                }
                
            }.continuation { _ in
                
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseFinalContinuedOnSuccessDoesntExecuteIfFailed() {
        
        enum TestError: Error {
            case somethingWentWrong
        }
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .result()
            asyncExpectation1.fulfill()
            
            }.await().continuationOnSuccess { previousPromise in
                
                return Promise<Void> { promise in
                    
                    let error = TestError.somethingWentWrong
                    promise.futureState = .error(error)
                    asyncExpectation2.fulfill()
                }
                
            }.continuationOnSuccess { promise in
                
                XCTFail()
        }
        
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinuedOnSuccessOnMainQueue() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        let asyncExpectation3 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .result()
            asyncExpectation1.fulfill()
            
            }.await().continuationOnSuccessOnMainQueue { previousPromise in
                
                return Promise<Void> { promise in
                    
                    let onMainQueue = Thread.current.isMainThread
                    XCTAssertTrue(onMainQueue)
                    
                    promise.futureState = .result()
                    asyncExpectation2.fulfill()
                }
                
            }.continuationOnSuccessOnMainQueue { _ in
                
                let onMainQueue = Thread.current.isMainThread
                XCTAssertTrue(onMainQueue)
                
                asyncExpectation3.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
}
