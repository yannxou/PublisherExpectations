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
    struct ParseError: Error, Equatable {
        var code: Int
    }

    func testExpectPublisherToCompleteWithFailure() {
        let publisher = ["1", "2", "3", "a", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw ParseError(code: 100) }
                return int
            }
        let expectation = PublisherFailureExpectation(publisher)
        wait(for: [expectation], timeout: 0.1)
    }

    func testInvertedExpectation() {
        let publisher = ["1", "2", "3", "4", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw ParseError(code: 100) }
                return int
            }
        let expectation = PublisherFailureExpectation(publisher)
        expectation.isInverted = true
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectPublisherToFailWithErrorMatchingCondition() {
        let publisher = ["1", "2", "3", "a", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw ParseError(code: 100) }
                return int
            }
            .mapError { $0 as? ParseError ?? ParseError(code: 0) }
        let expectation = PublisherFailureExpectation(publisher) { $0.code == 100 }
        wait(for: [expectation], timeout: 0.1)
    }

    func testExpectPublisherToFailWithExpectedError() {
        let publisher = ["1", "2", "3", "a", "5"].publisher
            .tryMap {
                guard let int = Int($0) else { throw ParseError(code: 100) }
                return int
            }
            .mapError { $0 as? ParseError ?? ParseError(code: 0) }
        let expectation = PublisherFailureExpectation(publisher, expectedError: .init(code: 100))
        wait(for: [expectation], timeout: 0.1)
    }
}
