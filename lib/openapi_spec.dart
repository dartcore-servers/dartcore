// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:dartcore/dartcore.dart';

/// Generates an OpenAPI specification for the given [app].
///
/// The resulting specification is a JSON object conforming to the OpenAPI 3.0
/// specification. It includes information about the routes, methods, and
/// responses of the application.
///
/// The [usingThat] parameter is a hack to make it easier for the user to
/// document their API. It is used to remove the SwaggerUI routes from the
/// generated specification. Set it to `true` if the invoker is
/// `app.openApi()`.
Map<String, dynamic> generateOpenApiSpec(App app, bool usingThat) {
  var paths = <String, Map<String, dynamic>>{};
  var routes = app.routes();
  routes.forEach((method, routeMap) {
    List<String> pathsToRemove = [];
    if (usingThat) {
      routeMap.forEach((path, handler) {
        if (path.contains("/swagger-") || path.contains("/index.css")) {
          pathsToRemove.add(path);
        }
      });
    }
    for (var path in pathsToRemove) {
      routeMap.remove(path);
    }
  });

  routes.forEach((method, routeMap) {
    routeMap.forEach((path, handler) {
      var metadata = app.metadata()[path]?[method];

      if (!paths.containsKey(path)) {
        paths[path] = {};
      }

      paths[path]![method.toLowerCase()] = {
        'summary': " " + (metadata?['summary'] ?? 'No summary'),
        'operationId': metadata?['operationId'] ?? 'unknownOperation',
        'responses': metadata?['responses'] ??
            {
              '200': {'description': 'Success'}
            }
      };
    });
  });

  return {
    'openapi': '3.0.0',
    'info': {
      'title': app.metadata()['title'] ?? 'Unnamed',
      'version': app.metadata()['version'] ?? '0.0.0',
      'description': app.metadata()['description'] ?? 'Undescribed',
    },
    'paths': paths
  };
}
