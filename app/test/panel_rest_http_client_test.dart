import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:panelmate/core/network/panel_rest_http_client.dart';
import 'package:panelmate/core/panel/models/api_version.dart';
import 'package:panelmate/core/panel/models/panel_api_exception.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';

void main() {
  group('PanelRestHttpClient', () {
    test('signs api key into 1Panel-Token using timestamp seconds', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'code': 200,
            'message': '',
            'data': {'ok': true},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = PanelRestHttpClient(
        server: const PanelServerConnectionProfile(
          name: 'demo',
          baseUrl: 'panel.example.com',
          protocol: 'http',
          port: 8443,
          apiVersion: PanelApiVersion.v2,
          authMode: PanelAuthMode.apiKey,
          apiKey: 'raw-api-key',
        ),
        client: mockClient,
      );

      final result = await client.get('/api/v2/dashboard/current/all/all');

      final timestamp = capturedRequest.headers['1Panel-Timestamp']!;
      final expectedToken =
          md5.convert(utf8.encode('1panelraw-api-key$timestamp')).toString();

      expect(capturedRequest.headers['1Panel-Token'], expectedToken);
      expect(result['ok'], true);
    });

    test('unwraps data from standard panel response envelope', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 200,
            'message': '',
            'data': {
              'cpuUsedPercent': 0.5,
            },
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = PanelRestHttpClient(
        server: const PanelServerConnectionProfile(
          name: 'demo',
          baseUrl: 'panel.example.com',
          protocol: 'http',
          port: 8443,
          apiVersion: PanelApiVersion.v2,
          authMode: PanelAuthMode.apiKey,
          apiKey: 'raw-api-key',
        ),
        client: mockClient,
      );

      final result = await client.get('/api/v2/dashboard/current/all/all');

      expect(result['cpuUsedPercent'], 0.5);
    });

    test('sends DELETE requests through the REST transport', () async {
      late http.Request capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        return http.Response(
          jsonEncode({
            'code': 200,
            'message': '',
            'data': {'deleted': true},
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = PanelRestHttpClient(
        server: const PanelServerConnectionProfile(
          name: 'demo',
          baseUrl: 'panel.example.com',
          protocol: 'http',
          port: 8443,
          apiVersion: PanelApiVersion.v2,
          authMode: PanelAuthMode.apiKey,
          apiKey: 'raw-api-key',
        ),
        client: mockClient,
      );

      final result = await client.delete(
        '/api/v2/core/settings/passkey/7',
      );

      expect(capturedRequest.method, 'DELETE');
      expect(capturedRequest.url.path, '/api/v2/core/settings/passkey/7');
      expect(result['deleted'], true);
    });

    test('throws on panel business error inside 200 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'code': 401,
            'message': 'API 接口时间戳错误',
            'data': null,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = PanelRestHttpClient(
        server: const PanelServerConnectionProfile(
          name: 'demo',
          baseUrl: 'panel.example.com',
          protocol: 'http',
          port: 8443,
          apiVersion: PanelApiVersion.v2,
          authMode: PanelAuthMode.apiKey,
          apiKey: 'raw-api-key',
        ),
        client: mockClient,
      );

      await expectLater(
        () => client.get('/api/v2/dashboard/current/all/all'),
        throwsA(
          isA<PanelApiException>()
              .having((error) => error.code, 'code', 'panel_response_error')
              .having((error) => error.statusCode, 'statusCode', 401),
        ),
      );
    });
  });
}
