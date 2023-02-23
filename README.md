# PublisherExpectations
XCTestExpectation subclasses that simplify testing Combine Publishers and help to improve the readability of unit tests.

## Motivation

Writing tests for Combine Publishers using `XCTestExpectation` usually involves some boilerplate code such as:

```swift
let expectation = XCTestExpectation(description: "Wait for the publisher to emit the expected value")
publisher.sink { _ in
} receiveValue: { value in
    if value == expectedValue {
        expectation.fulfill()
    }
}
.store(in: &cancellables)

wait(for: [expectation], timeout: 1)
```

The PublisherExpectations is a set of 3 XCTestExpectation that allows declaring expectations for publisher events in a clear and concise manner. They inherit from XCTestExpectation so they can be used in the `wait(for: [expectations])` call as any other expectation. 

## Usage

### PublisherValueExpectation

An expectation that is fulfilled when a publisher emits a value that matches a certain condition.
```swift
let publisherExpectation = PublisherValueExpectation(arrayPublisher) { $0.contains(value) }
```

* Wait for expected values:
```swift
let publisherExpectation = PublisherValueExpectation(stringPublisher, expectedValue: "Got it")
```

* Works with `@Published` property wrappers as well:
```swift
let publisherExpectation = PublisherValueExpectation(viewModel.$isLoaded, expectedValue: true)
```
```swift
let publisherExpectation = PublisherValueExpectation(viewModel.$keywords) { $0.contains("Cool") }
```

### PublisherFinishedExpectation

An expectation that is fulfilled when a publisher completes successfully.

* Waiting for the publisher to finish:
```swift
let publisherExpectation = PublisherFinishedExpectation(publisher)
```

* Waiting for the publisher to finish after emitting an expected value:
```swift
let publisherExpectation = PublisherFinishedExpectation(publisher, expectedValue: 2)
```

* Waiting to finish after emitting a value that matches a certain condition:
```swift
let publisherExpectation = PublisherFinishedExpectation(arrayPublisher) { array in
    array.allSatisfy { $0 > 5 }
}
```

### PublisherFailureExpectation

An expectation that is fulfilled when a publisher completes with a failure.

* Expecting a failure:
```swift
let publisherExpectation = PublisherFailureExpectation(publisher)
```

* Expecting a failure with an error that matches a condition:
```swift
let publisherExpectation = PublisherFailureExpectation(publisher) { error in
    guard case .apiError(let code) = error, code = 500 else { return false }
    return true
}
```

## Tips

Thanks to Combine we can adapt the publisher to do many things while keeping the test readability:

* Expect many values to be emitted:
```swift
let publisherExpectation = PublisherValueExpectation(publisher.collect(3), expectedValue: [1,2,3])
```

* Expect the first/last emitted value:
```swift
let publisherExpectation1 = PublisherValueExpectation(publisher.first(), expectedValue: 1)
let publisherExpectation2 = PublisherValueExpectation(publisher.last(), expectedValue: 5)
```
