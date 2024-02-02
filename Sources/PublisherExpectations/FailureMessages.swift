import CustomDump

/// Used by `PublisherValueExpectation` and `PublisherFinishedExpectation`
let emptyValuesDescription = "No value was emitted by the publisher"

/// Used by `PublisherFailureExpectation`
let finishedWithoutFailureDescription = "Publisher finished without failure"

/// Used by `PublisherValueExpectation` and `PublisherFinishedExpectation`
func receivedValuesDiffDescription<T>(received: [T], expected: T) -> String {
    """
    Values emitted diffing the expected one:
      \(diff(Array(repeating: expected, count: received.count), received)!)
    """
}

/// Used by `PublisherValueExpectation` and `PublisherFinishedExpectation`
func receivedValuesDescription<T>(received: [T]) -> String {
    """
    Values emitted:
      \(String(customDumping: received))
    """
}

/// Used by `PublisherFinishedExpectation` and `PublisherFailureExpectation`
func finishedWithFailureDescription(error: Error) -> String {
    "Publisher finished with error:\n\(String(customDumping: error))"
}
