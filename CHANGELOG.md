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

## 0.0.6

- New Syntax!   old: app.route("GET","/",(req) {});  new: app.route("GET","/",(req,res) {});
- YAML Support for Configs
- TOML Support for Configs
- Annotation Support!!! See example for more details!
- Database integration! (Currently just MySQL and PostgreSQL)
- OpenAPI Auto-generation + SwaggerUI!!
- Improved encrypting for Rate limits
- Added IP Blocking :)
- Added Geo-blocking :)
- Added Captcha for Rate-limit (TODO)
- Fixed Rate Limits crash on second startup
- Added Shutdown-On-SIGINT (CTRL+C shuts down the server)

## 0.0.7
- Removed Annotation for Flutter and AOT support
- Better documentation for some methods

## 0.0.8
- Improved documentation for ALL methods
- Implemented Hot Reload (1. force hot reload, 2. auto-hot-reload by watching changes)