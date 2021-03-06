//
//  PromiseTests.swift
//  Futuristics
//
//  Created by Alexander Ney on 04/08/2015.
//  Copyright © 2015 Alexander Ney. All rights reserved.
//

import Foundation
import XCTest
@testable import Futuristics


class PromiseTests: XCTestCase {

    enum TestError: ErrorType {
        case SomeError
        case AnotherError
    }
    
    func testFulfill() {
        let future = Future<String>()
        
        if case .Pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        future.fulfill("test")
        
        if case .Fulfilled(let value) = future.state where value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(future.state)")
        }
    }
    
    func testReject() {
        let future = Future<String>()
        
        if case .Pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        future.reject(TestError.AnotherError)
        
        if case .Rejected(let error) = future.state where error as? TestError == TestError.AnotherError  {
        } else {
            XCTFail("Future should be rejected with error \(TestError.AnotherError) but was \(future.state)")
        }
    }
    
    func testMultipleFulfillmentRejectment() {
        let fulfilledPromise = Future<String>()
        fulfilledPromise.fulfill("test")
        fulfilledPromise.fulfill("testA")
        fulfilledPromise.reject(TestError.AnotherError)
        
        if case .Fulfilled(let value) = fulfilledPromise.state where value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(fulfilledPromise.state)")
        }
        
        let rejectedPromise = Future<String>()
        rejectedPromise.reject(TestError.SomeError)
        rejectedPromise.fulfill("test")
        
        if case .Rejected(let error) = rejectedPromise.state where error as? TestError == TestError.SomeError  {
        } else {
            XCTFail("Future should be rejected with error \(TestError.SomeError) but was \(rejectedPromise.state)")
        }
    }
    
    func testFulfillHandler() {
        let future = Future<String>()
        let handlerExpectation = self.expectationWithDescription("Success handler called")
        
        future.onSuccess { value in
            XCTAssertEqual(value, "test")
            handlerExpectation.fulfill()
        }
        
        future.fulfill("test")
        
        self.waitForExpectationsWithTimeout(0.1, handler: nil)
    }
    
    func testFulfillMultipleHandler() {
        let future = Future<String>()
        
        let successExpectation = self.expectationWithDescription("Success handler called")
        let secondSuccessExpectation = self.expectationWithDescription("Second success handler called")
        let afterFulfillSuccessExpectation = self.expectationWithDescription("After fulfillment success handler called")
        let finallyExpectation = self.expectationWithDescription("Finally  called")
        let afterFulfillFinallyExpectation = self.expectationWithDescription("After fulfillment finally called")
        
        future.onSuccess { value in
            XCTAssertEqual(value, "test")
            successExpectation.fulfill()
        }.onFailure { _ in
            XCTFail()
        }.onSuccess { value in
            print("success")
            XCTAssertEqual(value, "test")
            secondSuccessExpectation.fulfill()
        }.finally {
            finallyExpectation.fulfill()
        }
        
        XCTAssertTrue(future.state.isPending)
        
        future.fulfill("test")
        
        XCTAssertFalse(future.state.isPending)
        
        future.finally {
           afterFulfillFinallyExpectation.fulfill()
        }.onSuccess { value in
            XCTAssertEqual(value, "test")
            afterFulfillSuccessExpectation.fulfill()
        }.onFailure { _ in
            XCTFail()
        }
    
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testRejectMultipleHandler() {
        let future = Future<String>()
        
        let failureExpectation = self.expectationWithDescription("Failure handler called")
        let afterFulfillFailureExpectation = self.expectationWithDescription("After fulfillment failure handler called")
        let finallyExpectation = self.expectationWithDescription("Finally  called")
        let afterFulfillFinallyExpectation = self.expectationWithDescription("After fulfillment finally called")
        
        future.onSuccess { value in
                XCTFail()
            }.onFailure { _ in
                failureExpectation.fulfill()
            }.onSuccess { value in
                XCTFail("second success block was not expected to be called")
            }.finally {
                finallyExpectation.fulfill()
        }
        
        XCTAssertTrue(future.state.isPending)
        
        future.reject(TestError.SomeError)
        
         XCTAssertFalse(future.state.isPending)
        
        future.finally {
            afterFulfillFinallyExpectation.fulfill()
            }.onSuccess { value in
                XCTFail()
            }.onFailure { _ in
                afterFulfillFailureExpectation.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }
    
    func testResolveRejectionWithThrowable() {
        
        func willThrow() throws -> String {
            throw TestError.SomeError
        }
        
        let future = Future<String>()
        
        if case .Pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }

        future.resolve { try willThrow() }
        
        if case .Rejected(let error) = future.state where error as? TestError == TestError.SomeError  {
        } else {
            XCTFail("Future should be rejected with error \(TestError.AnotherError) but was \(future.state)")
        }
    }
    
    func testResolveFulfillWithThrowable() {
        
        func willNotThrow() throws -> String {
            return "test"
        }
        
        let future = Future<String>()
        
        if case .Pending = future.state  {
        } else {
            XCTFail("initial state should be pending")
        }
        
        future.resolve { try willNotThrow() }
        
        if case .Fulfilled(let value) = future.state where value == "test"  {
        } else {
            XCTFail("Future should be fulfilled with value 'test' but was \(future.state)")
        }
    }


    func testSuccessDefaultContext() {
        
        let future = Future<Void>()
        
        let preFulfillExpectation = self.expectationWithDescription("Pre fulfill success should execute on background thread")
        
        future.onSuccess {
            if NSThread.isMainThread() {
                preFulfillExpectation.fulfill()
            } else {
                let queueLabel = String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
                XCTFail("wrong queue \(queueLabel)")
            }
        }
        
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            future.fulfill()
        }
        
        
        self.waitForExpectationsWithTimeout(15, handler: nil)
        let postFulfillExpectation = self.expectationWithDescription("Post fulfill success should execute on main thread")
        
        future.onSuccess {
            if NSThread.isMainThread() {
                postFulfillExpectation.fulfill()
            } else {
                let queueLabel = String(UTF8String: dispatch_queue_get_label(DISPATCH_CURRENT_QUEUE_LABEL))
                XCTFail("wrong queue \(queueLabel)")
            }
        }
        
        self.waitForExpectationsWithTimeout(10, handler: nil)
    }

    func testSuccessCustomContext() {
        
        let future = Future<Void>()
        
        let preFulfillExpectation = self.expectationWithDescription("Pre fulfill success should execute on main thread")
        
        future.onSuccess(onMainQueue) {
            if NSThread.isMainThread() {
                preFulfillExpectation.fulfill()
            }
        }
        
        let dispatchTime = dispatch_time(DISPATCH_TIME_NOW, Int64(2.0 * Double(NSEC_PER_SEC)))
        dispatch_after(dispatchTime, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
            future.fulfill()
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
        
        let postFulfillExpectation = self.expectationWithDescription("Post fulfill success should execute on background thread")
        
        future.onSuccess(onBackgroundQueue) {
            if !NSThread.isMainThread() {
                postFulfillExpectation.fulfill()
            }
        }
        
        self.waitForExpectationsWithTimeout(3, handler: nil)
    }

    
    func testBurteforceAddCompletionBlocksOnMainQueueFulfillFutureOnCustomQueue() {
       
        for _ in 1...500 {
            let future = Future<Void>()
            
            let preFulfillExpectation = self.expectationWithDescription("Bruteforce")
            
            let dispatchQueue = dispatch_queue_create("custom serial queue", DISPATCH_QUEUE_SERIAL)
            
            var successExecuted = 0
            var finallyExecuted = 0
            for i in  1...50 {
                if i == 25 {
                    dispatch_async(dispatchQueue) {
                        future.fulfill()
                    }
                }
                future.onSuccess {
                    successExecuted++
                    if successExecuted == 50 && finallyExecuted == 50 {
                        preFulfillExpectation.fulfill()
                    }
                }.finally {
                    finallyExecuted++
                    if successExecuted == 50 && finallyExecuted == 50 {
                        preFulfillExpectation.fulfill()
                    }
                }
            }
           
            self.waitForExpectationsWithTimeout(5.0, handler: { error in
                XCTAssertNil(error, "")
            })
        }
    }
    
    func testBurteforceAddCompletionBlocksOnMainQueueFulfillFutureOnMainQueue() {
        
        for _ in 1...500 {
            let future = Future<Void>()
            
            let preFulfillExpectation = self.expectationWithDescription("Bruteforce")
            
            var successExecuted = 0
            var finallyExecuted = 0
            for i in  1...50 {
                if i == 25 {
                    dispatch_async(dispatch_get_main_queue()) {
                        future.fulfill()
                    }
                }
                future.onSuccess {
                    successExecuted++
                    if successExecuted == 50 && finallyExecuted == 50 {
                        preFulfillExpectation.fulfill()
                    }
                    }.finally {
                        finallyExecuted++
                        if successExecuted == 50 && finallyExecuted == 50 {
                            preFulfillExpectation.fulfill()
                        }
                }
            }
            
            self.waitForExpectationsWithTimeout(5.0, handler: { error in
                XCTAssertNil(error, "")
            })
        }
    }
    
    func testBurteforceAddCompletionBlocksOnRandomCustomQueueFulfillFutureOnMainQueue() {
        
        for _ in 1...500 {
            let future = Future<Void>()
            
            let preFulfillExpectation = self.expectationWithDescription("Bruteforce")
            
            var successExecuted = 0
            var finallyExecuted = 0
            for i in  1...50 {
                if i == 25 {
                    future.fulfill()
                }
                let dispatchQueue = dispatch_queue_create("custom serial queue \(i)", DISPATCH_QUEUE_SERIAL)
                dispatch_async(dispatchQueue) {
                    future.onSuccess {
                        successExecuted++
                        if successExecuted == 50 && finallyExecuted == 50 {
                            preFulfillExpectation.fulfill()
                        }
                    }
                }
                dispatch_sync(dispatchQueue) {
                    future.finally {
                        finallyExecuted++
                        if successExecuted == 50 && finallyExecuted == 50 {
                            preFulfillExpectation.fulfill()
                        }
                    }
                }
            }
            
            self.waitForExpectationsWithTimeout(5.0, handler: { error in
                XCTAssertNil(error, "")
            })
        }
    }

}