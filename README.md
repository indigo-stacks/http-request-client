# 🪻 http-request-client

A dependency client that handles HTTP requests in apps using the Swift Composable Architecture (TCA).
It is part of the [Indigo Stack](https://indigostack.org).

## Installation

Add the following to your `Package.swift` file:

```swift
dependencies: [
  .package(url: "https://github.com/indigo-ce/http-request-client", from: "1.0.0")
]
```

Then, add `HTTPRequestClient` to your target dependencies:

```swift
targets: [
  .target(
    name: "YourTarget",
    dependencies: [
      "HTTPRequestClient"
    ]
  )
]
```

## Usage

The library provides a `HTTPRequestClient` that has several helpers methods to handle sending requests and decoding the response.

```swift
public func send(
  _ request: URLRequest,
  urlSession: HTTPTransport = URLSession.shared
) async throws -> (Data, HTTPURLResponse, UUID)

public func send<Success, Failure>(
    _ request: URLRequest,
    decoder: JSONDecoder = .init(),
    urlSession: HTTPTransport = URLSession.shared
) async throws -> Result<Success, Failure> where Success: Decodable, Failure: Decodable

public func send<T>(
    _ request: URLRequest,
    decoder: JSONDecoder = .init(),
    urlSession: HTTPTransport = URLSession.shared
) async throws -> T where T: Decodable
```

The above methods also have variants that support sending a `Request` type instance from the [HTTPRequestBuilder](https://github.com/4rays/http-request-builder) library.
For example:

```swift
public func send(
    _ request: Request,
    baseURL: String,
    urlSession: HTTPTransport = URLSession.shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60
) async throws -> (Data, HTTPURLResponse, UUID)
```

## Transport

The `urlSession` argument takes any `HTTPTransport`.
`URLSession` conforms by default.

```swift
public protocol HTTPTransport: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}
```

The library depends only on Foundation for networking.
To add network logging, conform your own type and pass it as `urlSession`.
For example, to log with [Pulse](https://github.com/kean/Pulse) in Debug builds only:

```swift
#if DEBUG
  import Pulse

  extension URLSessionProxy: @retroactive HTTPTransport {}

  let networkSession: any HTTPTransport = URLSessionProxy(configuration: .default)
#else
  let networkSession: any HTTPTransport = URLSession.shared
#endif
```

## Migrating from 1.x to 2.0

Version 2.0 removes the Pulse dependency.
The public API now uses `HTTPTransport` instead of `Pulse.URLSessionProtocol`.

1. Replace `URLSessionProtocol` with `HTTPTransport` in your types (for example `any URLSessionProtocol & Sendable` becomes `any HTTPTransport`).
2. If you pass a Pulse `URLSessionProxy`, add Pulse to your app and declare `extension URLSessionProxy: @retroactive HTTPTransport {}`.
3. Calls that pass `URLSession` or use the default argument do not change.

See [CHANGELOG.md](CHANGELOG.md) for details.

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details
