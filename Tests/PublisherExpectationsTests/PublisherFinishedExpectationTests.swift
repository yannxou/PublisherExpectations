//
//  PublisherFinishedExpectationTests.swift
//  
//
//  Created by Joan Duat on 24/2/23.
//

import XCTest
import Combine
@testable import PublisherExpectations

class PublisherFinishedExpectationTests: XCTestCase {
    let publisher = [1, 2, 3, 4, 5].publisher
    @Published var value = 0

    // MARK: - Expected success
    
    func testExpectPublisherToJustFinish() {
        let expectation = PublisherFinishedExpectation(publisher)
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectPublisherToFinishWithoutEmittingAnyValue() {
        let expectation = PublisherFinishedExpectation([].publisher)
        wait(for: [expectation], timeout: 0.1)
    }

    func testInvertedExpectation() {
        let expectation = PublisherFinishedExpectation($value)
        expectation.isInverted = true
        value = 100
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectPublisherToFinishAfterHavingEmittedExpectedValue() {
        let expectation = PublisherFinishedExpectation(publisher, expectedValue: 4)
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectFailureOnPublisherNotEmittingAValue() {
        let expectation = PublisherFinishedExpectation(publisher, expectedValue: 0)
        expectation.isInverted = true
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectPublisherToFinishAfterEmittingAllValues() {
        let expectation = PublisherFinishedExpectation(publisher.collect(), expectedValue: [1,2,3,4,5])
        wait(for: [expectation], timeout: 0.1)
    }

    // MARK: - Expected failures

    func testImmediateFailureWhenPublisherFinishesWithoutEmittingExpectedValue() {
        XCTExpectFailure("PublisherFinishedExpectation should fail") {
            let expectation = PublisherFinishedExpectation(publisher, expectedValue: 100)
            wait(for: [expectation], timeout: 5)
        }
    }

    func testImmediateFailureWhenPublisherFinishesWithoutMatchingCondition() {
        XCTExpectFailure("PublisherFinishedExpectation should fail") {
            let expectation = PublisherFinishedExpectation(publisher) { $0 > 100 }
            wait(for: [expectation], timeout: 5)
        }
    }

    func testImmediateFailureWhenPublisherFails() {
        XCTExpectFailure("PublisherFinishedExpectation should fail") {
            let failingPublisher = Fail(outputType: Int.self, failure: SimpleError(code: 1300))
            let expectation = PublisherFinishedExpectation(failingPublisher, expectedValue: 3)
            wait(for: [expectation], timeout: 5)
        }
    }
}
