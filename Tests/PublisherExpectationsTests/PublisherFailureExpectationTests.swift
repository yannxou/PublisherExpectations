//
//  PublisherFailureExpectationTests.swift
//  
//
//  Created by Joan Duat on 24/2/23.
//

import XCTest
import Combine
@testable import PublisherExpectations

class PublisherFailureExpectationTests: XCTestCase {

    // MARK: - Expected success
    
    func testExpectPublisherToCompleteWithFailure() {
        let publisher = ["1", "2", "3", "a", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw SimpleError(code: 100) }
                return int
            }
        let expectation = PublisherFailureExpectation(publisher)
        wait(for: [expectation], timeout: 0.1)
    }

    func testInvertedExpectation() {
        let publisher = ["1", "2", "3", "4", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw SimpleError(code: 100) }
                return int
            }
        let expectation = PublisherFailureExpectation(publisher)
        expectation.isInverted = true
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectPublisherToFailWithErrorMatchingCondition() {
        let publisher = ["1", "2", "3", "a", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw SimpleError(code: 100) }
                return int
            }
            .mapError { $0 as? SimpleError ?? SimpleError(code: 0) }
        let expectation = PublisherFailureExpectation(publisher) { $0.code == 100 }
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectPublisherToFailWithExpectedError() {
        let publisher = ["1", "2", "3", "a", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw SimpleError(code: 100) }
                return int
            }
            .mapError { $0 as? SimpleError ?? SimpleError(code: 0) }
        let expectation = PublisherFailureExpectation(publisher, expectedError: .init(code: 100))
        wait(for: [expectation], timeout: 0.1)
    }

    // MARK: - Expected failures

    func testImmediateFailureWhenPublisherFailsWithoutEmittingExpectedError() {
        XCTExpectFailure("PublisherFailureExpectation should fail") {
            let failingPublisher = Fail(outputType: Int.self, failure: SimpleError(code: 1300))
            let expectation = PublisherFailureExpectation(failingPublisher, expectedError: .init(code: -100))
            wait(for: [expectation], timeout: 5)
        }
    }

    func testImmediateFailureWhenPublisherFailsWithoutErrorMatchingCondition() {
        XCTExpectFailure("PublisherFailureExpectation should fail") {
            let failingPublisher = Fail(outputType: Int.self, failure: SimpleError(code: 1300))
            let expectation = PublisherFailureExpectation(failingPublisher) { $0.code < 0 }
            wait(for: [expectation], timeout: 5)
        }
    }

    func testImmediateFailureWhenPublisherFinishesWithoutFailing() {
        XCTExpectFailure("PublisherFailureExpectation should fail") {
            let nonFailingPublisher = Just(200)
                .setFailureType(to: SimpleError.self)
                .mapError { _ in SimpleError(code: 1300) }
            let expectation = PublisherFailureExpectation(nonFailingPublisher, expectedError: SimpleError(code: 1300))
            wait(for: [expectation], timeout: 5)
        }
    }
}
