class PanelApiEndpoint {
  const PanelApiEndpoint({
    required this.operationId,
    required this.method,
    required this.path,
    required this.summary,
    required this.tags,
    this.pathParameters = const <String>[],
    this.queryParameters = const <String>[],
    this.requestBodyRef,
    this.responseBodyRef,
  });

  final String operationId;
  final String method;
  final String path;
  final String summary;
  final List<String> tags;
  final List<String> pathParameters;
  final List<String> queryParameters;
  final String? requestBodyRef;
  final String? responseBodyRef;

  String get canonicalKey => '${method.toUpperCase()} $path';

  String resolvePath(Map<String, Object?> parameters) {
    var resolved = path;
    for (final parameter in pathParameters) {
      if (!parameters.containsKey(parameter) || parameters[parameter] == null) {
        throw ArgumentError(
          'Missing path parameter "$parameter" for $canonicalKey.',
        );
      }

      final encoded = Uri.encodeComponent(parameters[parameter].toString());
      resolved = resolved
          .replaceAll(':$parameter', encoded)
          .replaceAll('{$parameter}', encoded);
    }
    return resolved;
  }
}

abstract class PanelGenericApi {
  List<PanelApiEndpoint> get endpoints;

  PanelApiEndpoint endpointForOperation(String operationId);

  PanelApiEndpoint endpointForPath({
    required String method,
    required String path,
  });

  Future<Map<String, dynamic>> requestOperation(
    String operationId, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
  });

  Future<Map<String, dynamic>> requestPath({
    required String method,
    required String path,
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
  });

  Future<Map<String, dynamic>> requestEndpoint(
    PanelApiEndpoint endpoint, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
  });
}
