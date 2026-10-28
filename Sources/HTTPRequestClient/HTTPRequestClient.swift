import Dependencies
import DependenciesMacros
import Foundation
import HTTPRequestBuilder

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

@DependencyClient
public struct HTTPRequestClient: Sendable {
  public let send:
    @Sendable (
      URLRequest,
      HTTPTransport
    ) async throws -> (Data, HTTPURLResponse, UUID)
}

extension HTTPRequestClient {
  public func send(
    _ request: URLRequest,
    urlSession: HTTPTransport = URLSession.shared
  ) async throws -> (Data, HTTPURLResponse, UUID) {
    try await send(request, urlSession)
  }

  public func send(
    _ request: Request = .init(),
    baseURL: String,
    urlSession: HTTPTransport = URLSession.shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> (Data, HTTPURLResponse, UUID) {
    try await send(
      middleware()(request).urlRequest(
        baseURL: baseURL,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval
      ),
      urlSession
    )
  }

  public func send<T, ServerError>(
    _ request: URLRequest,
    decoder: JSONDecoder = .init(),
    urlSession: HTTPTransport = URLSession.shared
  ) async throws -> Response<T, ServerError>
  where
    T: Decodable,
    ServerError: Swift.Error & Decodable
  {
    let (data, response, requestID) = try await send(
      request,
      urlSession
    )

    var errorContainer = Error.invalidHTTPResponse(requestID)

    switch response.statusCode {
    case 200..<300:
      if T.self is EmptyResponse.Type {
        return .init(
          value: EmptyResponse() as! T,
          response: response,
          requestID: requestID
        )
      }

      do {
        return .init(
          value: try decoder.decode(T.self, from: data),
          response: response,
          requestID: requestID
        )
      } catch let error as DecodingError {
        errorContainer = .decodingError(requestID, error)

        return .init(
          error: try decoder.decode(ServerError.self, from: data),
          response: response,
          requestID: requestID
        )
      } catch {
        switch errorContainer {
        case .decodingError: break
        default: errorContainer = .other(requestID, error)
        }

        throw errorContainer
      }

    default:
      errorContainer = .badResponse(
        requestID,
        response.statusCode,
        String(data: data, encoding: .utf8) ?? ""
      )

      throw errorContainer
    }
  }

  public func send<T>(
    _ request: URLRequest,
    decoder: JSONDecoder = .init(),
    urlSession: HTTPTransport = URLSession.shared
  ) async throws -> SuccessResponse<T>
  where T: Decodable {
    let (data, response, requestID) = try await send(
      request,
      urlSession
    )

    var errorContainer = Error.invalidHTTPResponse(requestID)

    switch response.statusCode {
    case 200..<300:
      if T.self is EmptyResponse.Type {
        return .init(
          value: EmptyResponse() as! T,
          response: response,
          requestID: requestID
        )
      }

      do {
        return .init(
          value: try decoder.decode(T.self, from: data),
          response: response,
          requestID: requestID
        )
      } catch let error as DecodingError {
        errorContainer = .decodingError(requestID, error)
        throw errorContainer
      } catch {
        errorContainer = .other(requestID, error)
        throw errorContainer
      }

    default:
      errorContainer = .badResponse(
        requestID,
        response.statusCode,
        String(data: data, encoding: .utf8) ?? ""
      )

      throw errorContainer
    }
  }

  public func send<T, ServerError>(
    _ request: Request = .init(),
    decoder: JSONDecoder = .init(),
    baseURL: String,
    urlSession: HTTPTransport = URLSession.shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> Response<T, ServerError>
  where
    T: Decodable,
    ServerError: Swift.Error & Decodable
  {
    try await send(
      middleware()(request).urlRequest(
        baseURL: baseURL,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval
      ),
      decoder: decoder,
      urlSession: urlSession
    )
  }

  public func send<T>(
    _ request: Request = .init(),
    baseURL: String,
    decoder: JSONDecoder = .init(),
    urlSession: HTTPTransport = URLSession.shared,
    cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy,
    timeoutInterval: TimeInterval = 60,
    @RequestBuilder middleware: () -> RequestMiddleware = { identity }
  ) async throws -> SuccessResponse<T>
  where T: Decodable {
    try await send(
      middleware()(request).urlRequest(
        baseURL: baseURL,
        cachePolicy: cachePolicy,
        timeoutInterval: timeoutInterval
      ),
      decoder: decoder,
      urlSession: urlSession
    )
  }
}

extension DependencyValues {
  public var httpRequestClient: HTTPRequestClient {
    get { self[HTTPRequestClient.self] }
    set { self[HTTPRequestClient.self] = newValue }
  }
}

extension HTTPRequestClient: DependencyKey {
  public static let liveValue = Self(
    send: { request, session in
      let id = UUID()

      do {
        let (data, response) = try await session.data(for: request)

        guard
          let httpResponse = response as? HTTPURLResponse
        else {
          throw HTTPRequestClient.Error.invalidHTTPResponse(id)
        }

        return (data, httpResponse, id)
      } catch {
        throw Error.other(id, error)
      }
    }
  )
}

extension HTTPRequestClient: TestDependencyKey {
  public static let previewValue = Self(
    send: { _, _ in
      (Data(), HTTPURLResponse(), UUID())
    }
  )
}

extension HTTPRequestClient {
  public enum Error: Swift.Error {
    case invalidHTTPResponse(UUID)
    case badResponse(UUID, Int, String)
    case decodingError(UUID, DecodingError)
    case other(UUID, Swift.Error)
  }
}
