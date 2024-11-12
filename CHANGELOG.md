## 0.0.1

- Initial version.

## 0.0.2

- Added Rate limit support
- Added CORS support
- Added Custom 404 and 500 responses
- Added 0.0.0.0 support
- Added Rate limit support (Uses Memory for now)
- Added multipart support

## 0.0.3

- Longer description on pub.dev
- WASM compatibility
- Added documentation for each method :)

## 0.0.4

- A bit shorter description on pub.dev
- WASM or Web doesn't work.
- More pub points lmao

## 0.0.5

- Added a Template Engine ( supports basic variables, if conditions, loops, and inheritance (extending) )
- Added API Key System
- Added Config support (as JSON, helps reduce repeated parts of the code)
- Added `app.send(request, content, contentType);`
- Added onShutdown and onStartup events
- Added Custom Events with an Event emitter and receiver
- Added `app.shutdown();` to gracefully shutdown the server
- Added Caching for responses
- Now RateLimter uses Storage instead of memory, also encrypts it with a password