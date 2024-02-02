import Combine
import XCTest

/// An expectation that is fulfilled when a publisher completes with a failure.
public final class PublisherFailureExpectation<P: Publisher>: XCTestExpectation {
    private var cancellable: AnyCancellable?
    private var expectedError: P.Failure?

    private init(
        _ publisher: P,
        condition: @escaping (P.Failure) -> Bool,
        expectedError: P.Failure?,
        description: String,
        file: StaticString,
        line: UInt
    ) {
        self.expectedError = expectedError
        super.init(description: description)
        cancellable = publisher.sink(
            receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    self.checkImmediateFailure(
                        file: file,
                        line: line
                    )
                case .failure(let error):
                    if condition(error) {
                        self.fulfill()
                    } else {
                        self.checkImmediateFailure(
                            error: error,
                            file: file,
                            line: line
                        )
                    }
                }
            },
            receiveValue: { _ in }
        )
    }

    /// Initializes a PublisherFailureExpectation that is fulfilled when the publisher fails with an error that matches the condition.
    public convenience init(
        _ publisher: P,
        condition: @escaping (P.Failure) -> Bool,
        description expectationDescription: String = "Failure was expected with an error matching the condition.",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.init(
            publisher,
            condition: condition,
            expectedError: nil,
            description: expectationDescription,
            file: file,
            line: line
        )
    }

    /// Initializes a PublisherFailureExpectation for a publisher with the given description
    public convenience init(
        _ publisher: P,
        description expectationDescription: String = "Failure was expected",
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.init(
            publisher,
            condition: { _ in true },
            description: expectationDescription,
            file: file,
            line: line
        )
    }

    /// Initializes a PublisherFailureExpectation that is fulfilled when the publisher fails with an expected error.
    public convenience init(
        _ publisher: P,
        expectedError: P.Failure,
        description expectationDescription: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) where P.Failure: Equatable
    {
        let description = expectationDescription ?? "Failure was expected with:\n\(String(customDumping: expectedError))"
        self.init(
            publisher,
            condition: { $0 == expectedError },
            expectedError: expectedError,
            description: description,
            file: file,
            line: line
        )
    }
}

private extension PublisherFailureExpectation {
    func failureDescription(error: Error?) -> String {
        guard let error else {
            return finishedWithoutFailureDescription
        }
        guard let expectedError else {
            return finishedWithFailureDescription(error: error)
        }
        return errorDiffDescription(received: error, expected: expectedError)
    }

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
