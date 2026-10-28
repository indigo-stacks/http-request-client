import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// The transport that `HTTPRequestClient` uses to send a request.
///
/// `URLSession` conforms by default. To add network logging or other
/// instrumentation, conform your own type (for example a logging proxy
/// around `URLSession`) and pass it as the `urlSession` argument.
public protocol HTTPTransport: Sendable {
  func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
  #if canImport(FoundationNetworking)
    // swift-corelibs-foundation only has `data(for:delegate:)`, which cannot
    // witness the one-argument requirement.
    public func data(for request: URLRequest) async throws -> (Data, URLResponse) {
      try await data(for: request, delegate: nil)
    }
  #endif
}
