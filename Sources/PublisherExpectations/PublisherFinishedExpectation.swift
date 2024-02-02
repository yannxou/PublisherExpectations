import Combine
import XCTest

/// An expectation that is fulfilled when a publisher completes successfully.
public final class PublisherFinishedExpectation<P: Publisher>: XCTestExpectation {
    private var cancellable: AnyCancellable?
    private let expectedValue: P.Output?
    private var isConditionFulfilled = false
    private var receivedValues: [P.Output] = []

    private init(
        _ publisher: P,
        condition: ((P.Output) -> Bool)?,
        expectedValue: P.Output?,
        description: String,
        file: StaticString,
        line: UInt
    ) {
        self.expectedValue = expectedValue
        super.init(description: description)
        cancellable = publisher.sink(
            receiveCompletion: { [weak self] completion in
                guard let self else { return }
                switch completion {
                case .finished:
                    if condition == nil {
                        self.fulfill()
                    } else if isConditionFulfilled {
                        self.fulfill()
                    } else {
                        self.checkImmediateFailure(
                            file: file,
                            line: line
                        )
                    }
                case .failure(let failure):
                    self.checkImmediateFailure(
                        error: failure,
                        file: file,
                        line: line
                    )
                }
            },
            receiveValue: { [weak self] value in
                self?.receivedValues.append(value)
                guard
                    let self,
                    !self.isConditionFulfilled,
                    let condition
                else { return }
                self.isConditionFulfilled = condition(value)
            }
        )
    }

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully.
    public convenience init(
        _ publisher: P,
        description expectationDescription: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let description = expectationDescription ?? "Publisher expected to finish"
        self.init(
            publisher,
            condition: nil,
            expectedValue: nil,
            description: description,
            file: file,
            line: line
        )
    }

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully after emitting a value that matches a certain condition.
    public convenience init(
        _ publisher: P,
        condition: @escaping (P.Output) -> Bool,
        description expectationDescription: String? = nil,
        file: StaticString = #file, 
        line: UInt = #line
    ) {
        let description = expectationDescription ?? "Publisher expected to finish after emitting a value that matches the condition."
        self.init(
            publisher,
            condition: condition,
            expectedValue: nil,
            description: description,
            file: file,
            line: line
        )
    }

    /// Initializes a PublisherFinishedExpectation that is fulfilled when the publisher completes successfully after emitting a certain value.
    public convenience init(
        _ publisher: P, expectedValue: P.Output,
        description expectationDescription: String? = nil,
        file: StaticString = #file, 
        line: UInt = #line
    ) where P.Output: Equatable
    {
        let description = expectationDescription ?? "Publisher expected to finish after emitting the value:\n\(String(customDumping: expectedValue))"
        self.init(
            publisher,
            condition: { $0 == expectedValue },
            expectedValue: expectedValue,
            description: description,
            file: file,
            line: line
        )
    }
}

private extension PublisherFinishedExpectation {
    func failureDescription(error: Error?) -> String {
        if let error {
            return finishedWithFailureDescription(error: error)
        }
        guard !receivedValues.isEmpty else {
            return emptyValuesDescription
        }
        return if let expectedValue {
            receivedValuesDiffDescription(
                received: receivedValues,
                expected: expectedValue
            )
        } else {
            receivedValuesDescription(received: receivedValues)
        }
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
