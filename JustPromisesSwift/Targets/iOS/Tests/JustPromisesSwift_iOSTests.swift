//
//  JustPromisesSwift_iOSTests.swift
//  JustPromisesSwift_iOSTests
//
//  Created by Keith Moon on 04/12/2016.
//  Copyright © 2016 JUST EAT. All rights reserved.
//

import XCTest
import Foundation
import JustPromisesSwift_iOS

enum TestError: Error {
    case somethingWentWrong
}

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
            
            }.await().continuation(onQueue: .main) { previousPromise in
                
                return Promise<Void> { promise in
                    
                    let onMainQueue = Thread.current.isMainThread
                    XCTAssertTrue(onMainQueue)
                    
                    promise.futureState = .result()
                    asyncExpectation2.fulfill()
                }
                
            }.continuation(onQueue: .main) { _ in
                
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
        
        let _ = Promise<Bool> { promise in
            
            // Complete with result
            promise.futureState = .result(true)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithResult() { result in
                
                // This block fires with the result of the previous block
                XCTAssertTrue(result)
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseContinuedOnSuccessDoesntExecuteIfFailed() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Bool> { promise in
            
            // Complete promise with errpr
            promise.futureState = .error(TestError.somethingWentWrong)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithResult() { result in
                
                // The block shouldn't execute because
                // previous Promise completed with error.
                XCTFail()
                
            }.continuation { _ in
                
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinuedOnError() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Bool> { promise in
            
            // Complete with error
            promise.futureState = .error(TestError.somethingWentWrong)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithError() { error in
                
                guard let testError = error as? TestError else {
                    XCTFail()
                    return
                }
                
                // This block fires with the error of the previous block
                XCTAssertTrue(testError == TestError.somethingWentWrong)
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseContinuedOnErrorDoesntExecuteIfSucceed() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Bool> { promise in
            
            // Complete promise with result
            promise.futureState = .result(true)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithError() { error in
                
                // The block shouldn't execute because
                // previous Promise completed with result.
                XCTFail()
                
            }.continuation { _ in
                
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
}
