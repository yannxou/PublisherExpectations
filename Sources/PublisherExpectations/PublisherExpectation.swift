//
//  PublisherExpectation.swift
//
//
//  Created by Joan Duat on 5/2/24.
//

import XCTest

protocol PublisherExpectation: XCTestExpectation {
    func failureDescription(error: Error?) -> String
}

extension PublisherExpectation {
    func checkImmediateFailure(
        error: Error? = nil,
        file: StaticString,
        line: UInt
    ) {
        let description = self.description + "\n\n" + failureDescription(error: error)
        // Add small delay to allow effectively setting isInverted property from outside
        DispatchQueue.main.async {
            if !self.isInverted {
                XCTFail(description, file: file, line: line)
                self.fulfill()  // required to break the `wait()` in the test and skip the timeout
            }
        }
    }
}

