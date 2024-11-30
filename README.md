# Dartcore

**Dartcore** is a minimalist, yet powerful HTTP server framework for the Dart programming language. It provides a simple API for routing and handling HTTP requests, making it perfect for lightweight (not very, can be used for complex ones that will never crash) web applications, APIs, or microservices.

## Features

- Simple and intuitive routing
- Lightweight and fast
- Minimal dependencies
- Easy to use for building RESTful APIs
- Customizable request handling
- Looks a bit like Flask :)

## Getting Started

### Installation

#### Library

First, ensure you have the Dart SDK installed. Then, add `dartcore` to your `pubspec.yaml` file as a dependency.

```yaml
dependencies:
  dartcore: any
```

Run `dart pub get` to install dependencies.

#### CLI

You can install it by running the command:

```bash
dart pub activate global dartcore
```

and then try,

```bash
dartcore --version
```

### Example Usage

Follow these simple steps to set up your Dartcore server.

### 1. Create a New Instance of Dartcore

```dart
import 'package:dartcore/dartcore.dart' as dartcore;
// "" is the config file path
final app = dartcore.App(debug: true); // replace true with false in production mode! this specifies Debugging mode
```

### 2. Add Routes

Use the `route` method to handle incoming HTTP requests. Specify the HTTP method (e.g., `GET`, `POST`, etc.) and the route.

```dart
app.route('GET', '/', (req, res) {
  res.send("Hello from Dartcore!", ContentType.text);
});

app.route('GET', '/hello', (req, res) {
  res.json({"from":"Dartcore","message":"Hello World!"});
});
```

### 3. Start the Server

Use the `start` method to start the server.

```dart
app.start(port: 8080);
```

#### Optional Parameters

- (String) **`address`**: The server's IP address (default: `0.0.0.0` --> All IP Addresses).
- (int) **`port`**: The port on which the server listens (default: `8080`).

### Full Example

See the full example on [pub.dev](https://pub.dev/packages/dartcore/example)!

### Running the Server

Run your Dart server with:

```bash
dart run
```

Visit `http://127.0.0.1:8080/`, `http://localhost:8080/`, or `http://YOUR_PRIVATE_IP:8080/` to see the server in action!

---

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests to help improve **DartCore**.

---

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
