import Combine
import CustomDump
import XCTest

/// An expectation that is fulfilled when a publisher emits a value that matches a certain condition.
public final class PublisherValueExpectation<P: Publisher>: XCTestExpectation {
    private var cancellable: AnyCancellable?
    private let expectedValue: P.Output?
    private var isConditionFulfilled: Bool = false
    private var receivedValues: [P.Output] = []

    private init(
        _ publisher: P,
        condition: @escaping (P.Output) -> Bool,
        expectedValue: P.Output?,
        description: String,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        self.expectedValue = expectedValue
        super.init(description: description)
        cancellable = publisher.sink(
            receiveCompletion: { [weak self] completion in
                guard let self else { return }
                if !self.isConditionFulfilled {
                    self.checkImmediateFailure(file: file, line: line)
                }
            },
            receiveValue: { [weak self] value in
                guard let self else { return }
                self.receivedValues.append(value)
                if condition(value) {
                    self.fulfill()
                    self.isConditionFulfilled = true
                }
            }
        )
    }

    /// Initializes a PublisherValueExpectation that is fulfilled when the publisher emits a value that matches the condition.
    public convenience init(
        _ publisher: P,
        condition: @escaping (P.Output) -> Bool,
        description expectationDescription: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) {
        let description = expectationDescription ?? "Publisher expected to emit a value that matches the condition."
        self.init(
            publisher,
            condition: condition,
            expectedValue: nil,
            description: description,
            file: file,
            line: line
        )
    }

    /// Initializes a PublisherValueExpectation that is fulfilled when the publisher emits the expected value.
    public convenience init(
        _ publisher: P, 
        expectedValue: P.Output,
        description expectationDescription: String? = nil,
        file: StaticString = #file,
        line: UInt = #line
    ) where P.Output: Equatable
    {
        let description = expectationDescription ?? "Publisher expected to emit the value:\n\(String(customDumping: expectedValue))"
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

private extension PublisherValueExpectation {
    var failureDescription: String {
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

    func checkImmediateFailure(file: StaticString, line: UInt) {
        let description = self.description + "\n\n" + failureDescription
        // Add small delay to allow effectively setting isInverted property from outside
        DispatchQueue.main.async {
            if !self.isInverted {
                XCTFail(description, file: file, line: line)
                self.fulfill()  // required to break the `wait()` in the test and skip the timeout
            }
        }
    }
}
