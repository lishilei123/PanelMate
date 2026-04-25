import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/models/panel_api_exception.dart';
import 'package:panelmate/core/panel/models/panel_error_message_resolver.dart';

void main() {
  group('PanelErrorMessageResolver', () {
    test('maps fetch failures to cors friendly message', () {
      final message = PanelErrorMessageResolver.resolve(
        Exception('ClientException: Failed to fetch'),
      );

      expect(message, contains('CORS'));
      expect(message, contains('HTTPS'));
    });

    test('maps unauthorized responses to auth guidance', () {
      final message = PanelErrorMessageResolver.resolve(
        PanelApiException.http(
          statusCode: 401,
          message: 'unauthorized',
        ),
      );

      expect(message, contains('认证失败'));
    });

    test('maps not found responses to v2 guidance', () {
      final message = PanelErrorMessageResolver.resolve(
        PanelApiException.http(
          statusCode: 404,
          message: 'not found',
        ),
      );

      expect(message, contains('V2 API'));
    });

    test('keeps friendly network exception message', () {
      final message = PanelErrorMessageResolver.resolve(
        PanelApiException.network(
          message: '域名解析失败，请检查面板地址是否填写正确。',
          code: 'dns_error',
        ),
      );

      expect(message, '域名解析失败，请检查面板地址是否填写正确。');
    });
  });
}
