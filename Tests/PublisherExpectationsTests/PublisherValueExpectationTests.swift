//
//  PublisherValueExpectationTests.swift
//  
//
//  Created by Joan Duat on 24/2/23.
//

import XCTest
import Combine
@testable import PublisherExpectations

class PublisherValueExpectationTests: XCTestCase {
    let publisher = [1, 2, 3, 4, 5].publisher
    @Published var value = 0

    func testExpectSomeValueToBeEmitted() {
        let expectation = PublisherValueExpectation(publisher, expectedValue: 3)
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectSomeValueToMatchCondition() {
        let expectation = PublisherValueExpectation(publisher) { $0 > 3 }
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectAllValuesToMatchCondition() {
        let expectation = PublisherValueExpectation(publisher) { $0 > 100 }
        expectation.isInverted = true
        wait(for: [expectation], timeout: 0.1)
    }

    func testPublishedPropertyToMatchValue() {
        let expectation = PublisherValueExpectation($value) { $0 > 3 }
        value = 100
        wait(for: [expectation], timeout: 0.1)
    }

    func testInvertedExpectation() {
        let expectation = PublisherValueExpectation(publisher, expectedValue: 7)
        expectation.isInverted = true
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectSecondEmittedValue() {
        let expectation = PublisherValueExpectation(publisher.dropFirst().first(), expectedValue: 2)
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectMultipleValues() {
        let expectation = PublisherValueExpectation(publisher.collect(3), expectedValue: [1,2,3])
        wait(for: [expectation], timeout: 0.1)
    }
}
