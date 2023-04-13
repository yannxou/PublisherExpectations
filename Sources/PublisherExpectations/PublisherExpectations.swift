//
//  PublisherExpectations.swift
//
//
//  Created by Joan Duat on 16/2/23.
//

import Combine
import XCTest

/// An expectation that is fulfilled when a publisher emits a value that matches a certain condition.
public final class PublisherValueExpectation<P: Publisher>: XCTestExpectation {
    private var cancellable: AnyCancellable?
    private var isConditionFulfilled: Bool = false

    /// Initializes a PublisherValueExpectation that is fulfilled when the publisher emits a value that matches the condition.
    public init(
        _ publisher: P,
        condition: @escaping (P.Output) -> Bool,
        description expectationDescription: String? = nil,
        file: StaticString = #file, line: UInt = #line)
    {
        let description = expectationDescription ?? "Publisher expected to emit a value that matches the condition."
        super.init(description: description)
        cancellable = publisher.sink(receiveCompletion: { [weak self] completion in
            guard let self else { return }
            if !self.isConditionFulfilled {
                self.checkImmediateFailure(file: file, line: line)
            }
        }, receiveValue: { [weak self] value in
            guard let self else { return }
            if condition(value) {
                self.fulfill()
                self.isConditionFulfilled = true
            }
        })
    }

    /// Initializes a PublisherValueExpectation that is fulfilled when the publisher emits the expected value.
    public convenience init(
        _ publisher: P, expectedValue: P.Output,
        description expectationDescription: String? = nil,
        file: StaticString = #file, line: UInt = #line
    ) where P.Output: Equatable
    {
        let description = expectationDescription ?? "Publisher expected to emit the value '\(expectedValue)'"
        self.init(publisher, condition: { $0 == expectedValue }, description: description, file: file, line: line)
    }
}

/// An expectation that is fulfilled when a publisher completes successfully.
public final class PublisherFinishedExpectation<P: Publisher>: XCTestExpectation {
    private var cancellable: AnyCancellable?
    private var isConditionFulfilled = false

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully.
    public init(
        _ publisher: P,
        description expectationDescription: String = "Publisher expected to finish",
        file: StaticString = #file, line: UInt = #line)
    {
        super.init(description: expectationDescription)
        cancellable = publisher.sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                self?.fulfill()
            case .failure(_):
                self?.checkImmediateFailure(file: file, line: line)
            }
        }, receiveValue: { _ in })
    }

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully after emitting a value that matches a certain condition.
    public init(
        _ publisher: P,
        condition: @escaping (P.Output) -> Bool,
        description expectationDescription: String? = nil,
        file: StaticString = #file, line: UInt = #line)
    {
        let description = expectationDescription ?? "Publisher expected to finish after emitting a value that matches the condition."
        super.init(description: description)
        cancellable = publisher.sink(receiveCompletion: { [weak self] completion in
            guard let self else { return }
            switch completion {
            case .finished:
                if self.isConditionFulfilled {
                    self.fulfill()
                } else {
                    self.checkImmediateFailure(file: file, line: line)
                }
            case .failure(_):
                self.checkImmediateFailure(file: file, line: line)
            }
        }, receiveValue: { [weak self] value in
            guard let self, !self.isConditionFulfilled else { return }
            self.isConditionFulfilled = condition(value)
        })
    }

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully after emitting a certain value.
    public convenience init(
        _ publisher: P, expectedValue: P.Output,
        description expectationDescription: String? = nil,
        file: StaticString = #file, line: UInt = #line
    ) where P.Output: Equatable
    {
        let description = expectationDescription ?? "Publisher expected to finish after emitting the value '\(expectedValue)'"
        self.init(publisher, condition: { $0 == expectedValue }, description: description, file: file, line: line)
    }
}

/// An expectation that is fulfilled when a publisher completes with a failure.
public final class PublisherFailureExpectation<P: Publisher>: XCTestExpectation {
    private var cancellable: AnyCancellable?

    /// Initializes a PublisherFailureExpectation that is fulfilled when the publisher fails with an error that matches the condition.
    public init(
        _ publisher: P,
        condition: @escaping (P.Failure) -> Bool,
        description expectationDescription: String = "Failure was expected with an error matching the condition.",
        file: StaticString = #file, line: UInt = #line)
    {
        super.init(description: expectationDescription)
        cancellable = publisher.sink(receiveCompletion: { [weak self] completion in
            guard let self else { return }
            switch completion {
            case .finished:
                self.checkImmediateFailure(file: file, line: line)
            case .failure(let error):
                if condition(error) {
                    self.fulfill()
                } else {
                    self.checkImmediateFailure(file: file, line: line)
                }
            }
        }, receiveValue: { _ in })
    }

    /// Initializes a PublisherFailureExpectation for a publisher with the given description
    public convenience init(
        _ publisher: P,
        description expectationDescription: String = "Failure was expected",
        file: StaticString = #file, line: UInt = #line)
    {
        self.init(publisher, condition: { _ in true }, description: expectationDescription, file: file, line: line)
    }

    /// Initializes a PublisherFailureExpectation that is fulfilled when the publisher fails with an expected error.
    public convenience init(
        _ publisher: P,
        expectedError: P.Failure,
        description expectationDescription: String? = nil,
        file: StaticString = #file, line: UInt = #line
    ) where P.Failure: Equatable
    {
        let description = expectationDescription ?? "Failure was expected with '\(expectedError)'"
        self.init(publisher, condition: { $0 == expectedError }, description: description, file: file, line: line)
    }
}

private extension XCTestExpectation {
    func checkImmediateFailure(file: StaticString = #file, line: UInt = #line) {
        // Add small delay to allow effectively setting isInverted property from outside
        DispatchQueue.main.async {
            if !self.isInverted {
                XCTFail(self.description, file: file, line: line)
                self.fulfill()  // required to break the `wait()` in the test and skip the timeout
            }
        }
    }
}
