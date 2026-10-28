# Changelog

## 2.0.0 (2026-10-28)

### Breaking changes

- Remove the Pulse dependency. The package now depends only on Foundation, HTTPRequestBuilder, and swift-dependencies.
- Add the `HTTPTransport` protocol (`data(for:)` only). `URLSession` conforms to it.
- `HTTPRequestClient.send` and all `send(...)` helpers take `urlSession: HTTPTransport` instead of `Pulse.URLSessionProtocol`. Argument labels and defaults do not change.

### Migration

- Replace `URLSessionProtocol` with `HTTPTransport` in your code.
- To keep Pulse network logging, add Pulse to your app (for example in Debug only) and declare `extension URLSessionProxy: @retroactive HTTPTransport {}`.

See the README section "Migrating from 1.x to 2.0".

## 1.6.0

- Use `URLSessionProtocol` (from Pulse) in the public API instead of `URLSession`.
