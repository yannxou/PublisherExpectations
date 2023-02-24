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

    func testExpectPublisherToJustFinish() {
        let expectation = PublisherFinishedExpectation(publisher)
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
}
