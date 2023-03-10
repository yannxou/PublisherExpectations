# PublisherExpectations

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fyannxou%2FPublisherExpectations%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/yannxou/PublisherExpectations)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fyannxou%2FPublisherExpectations%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/yannxou/PublisherExpectations)

XCTestExpectation subclasses that simplify testing Combine Publishers and help to improve the readability of unit tests.

## Motivation

Writing tests for Combine Publishers (or @Published properties) using `XCTestExpectation` usually involves some boilerplate code such as:

```swift
let expectation = XCTestExpectation(description: "Wait for the publisher to emit the expected value")
viewModel.$output.sink { _ in
} receiveValue: { value in
    if value == expectedValue {
        expectation.fulfill()
    }
}
.store(in: &cancellables)

wait(for: [expectation], timeout: 1)
```

We can try using a `XCTKeyPathExpectation` but it requires that the observed object inherits from `NSObject` and also marking the properties we want to observe with both the `@objc` attribute and the `dynamic` modifier to make them KVO-compliant:

```swift
class ViewModel: NSObject {
    @objc dynamic var isLoading = false
}

let expectation = XCTKeyPathExpectation(keyPath: \ViewModel.isLoading, observedObject: viewModel, expectedValue: true)
```

Another tempting approach would be using `XCTNSPredicateExpectation` like:

```swift
let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _,_ in
    viewModel.output == expectedValue
}, object: viewModel)
```

While this looks nice and compact, the problem with `XCTNSPredicateExpectation` is that is quite slow and best suited for UI tests. This is because it uses some kind of polling mechanism that adds a significant delay of 1 second minimum before the expectation is fulfilled. So it's better not to follow this path in unit tests.

## Description

The PublisherExpectations is a set of 3 XCTestExpectation that allows declaring expectations for publisher events in a clear and concise manner. They inherit from XCTestExpectation so they can be used in the `wait(for: [expectations])` call as with any other expectation. 

* `PublisherValueExpectation`: An expectation that is fulfilled when a publisher emits a value that matches a certain condition.
* `PublisherFinishedExpectation`: An expectation that is fulfilled when a publisher completes successfully.
* `PublisherFailureExpectation`: An expectation that is fulfilled when a publisher completes with a failure.

## Usage

### PublisherValueExpectation

* Wait for an expected value:
```swift
let publisherExpectation = PublisherValueExpectation(stringPublisher, expectedValue: "Got it")
```

* Wait for a value that matches a condition:
```swift
let publisherExpectation = PublisherValueExpectation(arrayPublisher) { $0.contains(value) }
```

* Works with `@Published` property wrappers as well:
```swift
let publisherExpectation = PublisherValueExpectation(viewModel.$isLoaded, expectedValue: true)
```
```swift
let publisherExpectation = PublisherValueExpectation(viewModel.$keywords) { $0.contains("Cool") }
```

### PublisherFinishedExpectation

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

* If the expected error conforms to Equatable:
```swift
let publisherExpectation = PublisherFailureExpectation(publisher, expectedError: ApiError(code: 100))
```

## Installation

1. From the File menu, select Add Packages...
2. Enter package repository URL: https://github.com/yannxou/PublisherExpectations
3. Confirm the version and let Xcode resolve the package

## Tips

Thanks to Combine we can adapt the publisher to check many things while keeping the test readability:

* Expect many values to be emitted:
```swift
let publisherExpectation = PublisherValueExpectation(publisher.collect(3), expectedValue: [1,2,3])
```

* Expect the first/last emitted value:
```swift
let publisherExpectation = PublisherValueExpectation(publisher.first(), expectedValue: 1)
let publisherExpectation = PublisherValueExpectation(publisher.last(), expectedValue: 5)
```

* Expect the second emitted value:
```swift
let publisherExpectation = PublisherValueExpectation(publisher.dropFirst().first(), expectedValue: 2)
```
