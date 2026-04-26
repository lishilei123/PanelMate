import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/network/panel_http_client.dart';
import 'package:panelmate/core/panel/v2/v2_endpoint_catalog.dart';
import 'package:panelmate/core/panel/v2/v2_generic_api.dart';

void main() {
  group('V2EndpointCatalog', () {
    test('covers every operation declared by V2_api.json', () {
      final swaggerKeys = _loadSwaggerEndpointKeys();
      final catalogKeys = V2EndpointCatalog.endpoints
          .map((endpoint) => endpoint.canonicalKey)
          .toSet();

      expect(V2EndpointCatalog.endpoints, hasLength(swaggerKeys.length));
      expect(catalogKeys, swaggerKeys);
    });

    test('keeps operation ids unique', () {
      final operationIds = V2EndpointCatalog.endpoints
          .map((endpoint) => endpoint.operationId)
          .toList(growable: false);

      expect(operationIds.toSet(), hasLength(operationIds.length));
    });
  });

  group('V2GenericApi', () {
    test('requests operation with resolved path, query and body', () async {
      final client = _RecordingPanelHttpClient();
      final api = V2GenericApi(client);

      final response = await api.requestOperation(
        'postWebsitesSearch',
        queryParameters: <String, dynamic>{'node': 'local'},
        body: <String, dynamic>{'page': 1, 'pageSize': 20},
      );

      expect(response['ok'], true);
      expect(client.last.method, 'POST');
      expect(client.last.path, '/api/v2/websites/search');
      expect(client.last.queryParameters, <String, dynamic>{'node': 'local'});
      expect(client.last.body, <String, dynamic>{'page': 1, 'pageSize': 20});
    });

    test('resolves colon path parameters for GET endpoints', () async {
      final client = _RecordingPanelHttpClient();
      final api = V2GenericApi(client);

      await api.requestOperation(
        'getContainersStatsById',
        pathParameters: <String, Object?>{'id': 'container/name'},
      );

      expect(client.last.method, 'GET');
      expect(client.last.path, '/api/v2/containers/stats/container%2Fname');
    });

    test('resolves brace path parameters for DELETE endpoints', () async {
      final client = _RecordingPanelHttpClient();
      final api = V2GenericApi(client);

      await api.requestPath(
        method: 'delete',
        path: '/core/settings/passkey/{id}',
        pathParameters: <String, Object?>{'id': 7},
      );

      expect(client.last.method, 'DELETE');
      expect(client.last.path, '/api/v2/core/settings/passkey/7');
    });

    test('throws when a required path parameter is missing', () {
      final api = V2GenericApi(_RecordingPanelHttpClient());

      expect(
        () => api.requestOperation('getContainersStatsById'),
        throwsArgumentError,
      );
    });
  });
}

Set<String> _loadSwaggerEndpointKeys() {
  final source = File('../V2_api.json');
  final api = jsonDecode(source.readAsStringSync()) as Map<String, dynamic>;
  final basePath = api['basePath']?.toString() ?? '/api/v2';
  final paths = api['paths'] as Map<String, dynamic>;
  final keys = <String>{};

  for (final pathEntry in paths.entries) {
    final path = pathEntry.key;
    final pathSpec = pathEntry.value as Map<String, dynamic>;
    for (final method in <String>['get', 'post', 'put', 'patch', 'delete']) {
      if (pathSpec[method] is Map<String, dynamic>) {
        keys.add('${method.toUpperCase()} $basePath$path');
      }
    }
  }

  return keys;
}

class _RecordedRequest {
  const _RecordedRequest({
    required this.method,
    required this.path,
    required this.headers,
    required this.queryParameters,
    required this.body,
  });

  final String method;
  final String path;
  final Map<String, String>? headers;
  final Map<String, dynamic>? queryParameters;
  final Object? body;
}

class _RecordingPanelHttpClient implements PanelHttpClient {
  _RecordedRequest? _last;

  _RecordedRequest get last => _last!;

  @override
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    _last = _RecordedRequest(
      method: 'DELETE',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
    return const <String, dynamic>{'ok': true};
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
  }) async {
    _last = _RecordedRequest(
      method: 'GET',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      body: null,
    );
    return const <String, dynamic>{'ok': true};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Object? body,
  }) async {
    _last = _RecordedRequest(
      method: 'POST',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
    );
    return const <String, dynamic>{'ok': true};
  }
}
