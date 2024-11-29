// ignore_for_file: prefer_interpolation_to_compose_strings

import 'package:dartcore/dartcore.dart';

/// Generates an OpenAPI Spec from every route in [app]
/// only set [usingThat] to `true` if the invoker is `app.openApi()`
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
