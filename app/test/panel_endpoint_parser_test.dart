import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/network/panel_endpoint_parser.dart';

void main() {
  group('PanelEndpointParser', () {
    test('parses bare host with explicit default scheme', () {
      final endpoint = PanelEndpointParser.parse(
        'panel.example.com',
        defaultScheme: 'https',
      );

      expect(endpoint.host, 'panel.example.com');
      expect(endpoint.port, isNull);
      expect(endpoint.scheme, 'https');
    });

    test('parses host with port', () {
      final endpoint = PanelEndpointParser.parse(
        'hdy-kr.972971617.xyz:8443',
        defaultScheme: 'https',
      );

      expect(endpoint.host, 'hdy-kr.972971617.xyz');
      expect(endpoint.port, 8443);
      expect(endpoint.scheme, 'https');
    });

    test('parses full url with path', () {
      final endpoint = PanelEndpointParser.parse(
        'https://panel.example.com:9443/panel',
      );

      expect(endpoint.host, 'panel.example.com');
      expect(endpoint.port, 9443);
      expect(endpoint.scheme, 'https');
      expect(endpoint.pathSegments, <String>['panel']);
    });
  });
}
