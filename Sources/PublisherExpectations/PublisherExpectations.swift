//
//  File.swift
//
//
//  Created by Joan Duat on 16/2/23.
//

import Combine
import XCTest

/// An expectation that is fulfilled when a publisher emits a value that matches a certain condition.
public final class PublisherValueExpectation<Output, Failure: Error>: XCTestExpectation {
    private var cancellable: AnyCancellable?

    /// Initializes a PublisherValueExpectation that is fulfilled when the publisher emits a value that matches the condition.
    public init(_ publisher: any Publisher<Output, Failure>,
         condition: @escaping (Output) -> Bool,
         description expectationDescription: String? = nil)
    {
        let description = expectationDescription ?? "Publisher expected to emit a value that matches the condition."
        super.init(description: description)
        cancellable = publisher.sink { _ in
        } receiveValue: { [weak self] value in
            if condition(value) {
                self?.fulfill()
            }
        }
    }

    /// Initializes a PublisherValueExpectation that is fulfilled when the publisher emits the expected value.
    public convenience init(_ publisher: any Publisher<Output, Failure>, expectedValue: Output, description expectationDescription: String? = nil) where Output: Equatable {
        let description = expectationDescription ?? "Publisher expected to emit the value '\(expectedValue)'"
        self.init(publisher, condition: { $0 == expectedValue }, description: description)
    }
}

/// An expectation that is fulfilled when a publisher completes successfully.
public final class PublisherFinishedExpectation<Output, Failure: Error>: XCTestExpectation {
    private var cancellable: AnyCancellable?
    private var isConditionFulfilled = false

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully.
    public init(_ publisher: any Publisher<Output, Failure>,
         description expectationDescription: String = "Publisher expected to finish")
    {
        super.init(description: expectationDescription)
        cancellable = publisher.sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                self?.fulfill()
            case .failure(_):
                break
            }
        }, receiveValue: { _ in })
    }

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully after emitting a value that matches a certain condition.
    public init(_ publisher: any Publisher<Output, Failure>,
         condition: @escaping (Output) -> Bool,
         description expectationDescription: String? = nil)
    {
        let description = expectationDescription ?? "Publisher expected to finish after matching the condition."
        super.init(description: description)
        cancellable = publisher.sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                guard let self else { return }
                if self.isConditionFulfilled {
                    self.fulfill()
                }
                break
            case .failure(_):
                break
            }
        }, receiveValue: { [weak self] value in
            guard let self, !self.isConditionFulfilled else { return }
            self.isConditionFulfilled = condition(value)
        })
    }

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully after emitting a certain value.
    public convenience init(_ publisher: any Publisher<Output, Failure>, expectedValue: Output, description expectationDescription: String? = nil) where Output: Equatable {
        let description = expectationDescription ?? "Publisher expected to finish after emitting the value '\(expectedValue)'"
        self.init(publisher, condition: { $0 == expectedValue }, description: description)
    }
}

/// An expectation that is fulfilled when a publisher completes with a failure.
public final class PublisherFailureExpectation<Output, Failure: Error>: XCTestExpectation {
    private var cancellable: AnyCancellable?

    /// Initializes a PublisherFailureExpectation that is fulfilled when the publisher fails with an error that matches the condition.
    public init(_ publisher: any Publisher<Output, Failure>,
         condition: @escaping (Failure) -> Bool,
         description expectationDescription: String = "Failure was expected with an error matching the condition.")
    {
        super.init(description: expectationDescription)
        cancellable = publisher.sink(receiveCompletion: { [weak self] completion in
            switch completion {
            case .finished:
                break
            case .failure(let error):
                if condition(error) {
                    self?.fulfill()
                }
            }
        }, receiveValue: { _ in })
    }

    /// Initializes a PublisherFailureExpectation for a publisher with the given description
    public convenience init(_ publisher: any Publisher<Output, Failure>,
         description expectationDescription: String = "Failure was expected")
    {
        self.init(publisher, condition: { _ in true }, description: expectationDescription)
    }
}
