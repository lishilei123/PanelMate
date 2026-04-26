import '../../network/panel_http_client.dart';
import '../contracts/panel_generic_api.dart';
import 'v2_endpoint_catalog.dart';

class V2GenericApi implements PanelGenericApi {
  V2GenericApi(this._client);

  final PanelHttpClient _client;

  static final Map<String, PanelApiEndpoint> _byOperationId =
      <String, PanelApiEndpoint>{
    for (final endpoint in V2EndpointCatalog.endpoints)
      endpoint.operationId: endpoint,
  };

  static final Map<String, PanelApiEndpoint> _byCanonicalKey =
      <String, PanelApiEndpoint>{
    for (final endpoint in V2EndpointCatalog.endpoints)
      endpoint.canonicalKey: endpoint,
  };

  @override
  List<PanelApiEndpoint> get endpoints => V2EndpointCatalog.endpoints;

  @override
  PanelApiEndpoint endpointForOperation(String operationId) {
    final endpoint = _byOperationId[operationId];
    if (endpoint == null) {
      throw ArgumentError.value(
        operationId,
        'operationId',
        'Unknown 1Panel V2 API operation.',
      );
    }
    return endpoint;
  }

  @override
  PanelApiEndpoint endpointForPath({
    required String method,
    required String path,
  }) {
    final normalizedMethod = method.toUpperCase();
    final normalizedPath = _normalizePath(path);
    final endpoint = _byCanonicalKey['$normalizedMethod $normalizedPath'];
    if (endpoint == null) {
      throw ArgumentError.value(
        '$normalizedMethod $path',
        'method/path',
        'Unknown 1Panel V2 API endpoint.',
      );
    }
    return endpoint;
  }

  @override
  Future<Map<String, dynamic>> requestOperation(
    String operationId, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
  }) {
    return requestEndpoint(
      endpointForOperation(operationId),
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
    );
  }

  @override
  Future<Map<String, dynamic>> requestPath({
    required String method,
    required String path,
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
  }) {
    return requestEndpoint(
      endpointForPath(method: method, path: path),
      pathParameters: pathParameters,
      queryParameters: queryParameters,
      body: body,
      headers: headers,
    );
  }

  @override
  Future<Map<String, dynamic>> requestEndpoint(
    PanelApiEndpoint endpoint, {
    Map<String, Object?> pathParameters = const <String, Object?>{},
    Map<String, dynamic>? queryParameters,
    Object? body,
    Map<String, String>? headers,
  }) {
    final path = endpoint.resolvePath(pathParameters);
    return switch (endpoint.method.toUpperCase()) {
      'GET' => _client.get(
          path,
          queryParameters: queryParameters,
          headers: headers,
        ),
      'POST' => _client.post(
          path,
          queryParameters: queryParameters,
          body: body,
          headers: headers,
        ),
      'DELETE' => _client.delete(
          path,
          queryParameters: queryParameters,
          body: body,
          headers: headers,
        ),
      final method => throw UnsupportedError(
          'Unsupported 1Panel V2 API method "$method".',
        ),
    };
  }

  String _normalizePath(String path) {
    final trimmed = path.trim();
    if (trimmed.startsWith('/api/v2')) {
      return trimmed;
    }
    if (trimmed.startsWith('/')) {
      return '/api/v2$trimmed';
    }
    return '/api/v2/$trimmed';
  }
}
