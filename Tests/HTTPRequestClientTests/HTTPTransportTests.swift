import Foundation
import Testing

@testable import HTTPRequestClient

struct HTTPTransportTests {
  struct StubTransport: HTTPTransport {
    let result: @Sendable (URLRequest) throws -> (Data, URLResponse)

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
      try result(request)
    }
  }

  struct Payload: Codable, Equatable {
    let id: Int
  }

  struct ServerError: Error, Codable {
    let message: String
  }

  static let url = URL(string: "https://example.com/items")!

  static func httpResponse(_ statusCode: Int) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil)!
  }

  @Test func liveValueSendsRequestThroughTransport() async throws {
    let transport = StubTransport { request in
      #expect(request.url == Self.url)
      #expect(request.httpMethod == "POST")
      return (Data("ok".utf8), Self.httpResponse(201))
    }
    var request = URLRequest(url: Self.url)
    request.httpMethod = "POST"

    let (data, response, _) = try await HTTPRequestClient.liveValue.send(
      request,
      urlSession: transport
    )

    #expect(data == Data("ok".utf8))
    #expect(response.statusCode == 201)
  }

  @Test func liveValueDecodesValueFromTransport() async throws {
    let transport = StubTransport { _ in
      (try JSONEncoder().encode(Payload(id: 7)), Self.httpResponse(200))
    }

    let result: SuccessResponse<Payload> = try await HTTPRequestClient.liveValue.send(
      URLRequest(url: Self.url),
      urlSession: transport
    )

    #expect(result.value == Payload(id: 7))
  }

  @Test func liveValueThrowsBadResponseForErrorStatus() async throws {
    let transport = StubTransport { _ in
      (Data("missing".utf8), Self.httpResponse(404))
    }

    await #expect {
      let _: Response<Payload, ServerError> = try await HTTPRequestClient.liveValue.send(
        URLRequest(url: Self.url),
        urlSession: transport
      )
    } throws: { error in
      guard case .badResponse(_, 404, "missing") = error as? HTTPRequestClient.Error else {
        return false
      }
      return true
    }
  }

  @Test func liveValueThrowsForNonHTTPResponse() async throws {
    let transport = StubTransport { _ in
      (
        Data(),
        URLResponse(url: Self.url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
      )
    }

    await #expect(throws: HTTPRequestClient.Error.self) {
      _ = try await HTTPRequestClient.liveValue.send(
        URLRequest(url: Self.url), urlSession: transport)
    }
  }

  @Test func liveValueWrapsTransportErrors() async throws {
    let transport = StubTransport { _ in throw URLError(.notConnectedToInternet) }

    await #expect {
      _ = try await HTTPRequestClient.liveValue.send(
        URLRequest(url: Self.url), urlSession: transport)
    } throws: { error in
      guard
        case .other(_, let underlying) = error as? HTTPRequestClient.Error,
        let urlError = underlying as? URLError
      else { return false }
      return urlError.code == .notConnectedToInternet
    }
  }

}
