import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/models/panel_api_exception.dart';
import 'package:panelmate/core/panel/models/panel_error_message_resolver.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';

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

    test('maps 1Panel captcha business error to actionable guidance', () {
      final message = PanelErrorMessageResolver.resolve(
        const PanelApiException(
          'ErrCaptchaCode',
          code: 'panel_response_error',
          statusCode: 401,
        ),
      );

      expect(message, contains('验证码'));
      expect(message, contains('重新执行连接测试'));
      expect(message, isNot(contains('ErrCaptchaCode')));
    });

    test('maps 1Panel entrance business error to readable text', () {
      final message = PanelErrorMessageResolver.resolve(
        const PanelApiException(
          'ErrEntrance',
          code: 'panel_response_error',
          statusCode: 401,
        ),
      );

      expect(message, contains('安全入口'));
      expect(message, isNot(contains('ErrEntrance')));
    });

    test('maps missing panel public key to login cookie guidance', () {
      final message = PanelErrorMessageResolver.resolve(
        const PanelApiException(
          'Login setting did not provide panel_public_key.',
          code: 'missing_panel_public_key',
        ),
      );

      expect(message, contains('Cookie'));
      expect(message, contains('panel_public_key'));
      expect(message, isNot(contains('API Key 无效')));
    });

    test('does not classify public key login errors as api key failures', () {
      final message = PanelErrorMessageResolver.resolve(
        const PanelApiException(
          'public key cookie missing',
          code: 'panel_response_error',
          statusCode: 401,
        ),
      );

      expect(message, contains('Cookie'));
      expect(message, isNot(contains('API Key 无效')));
    });

    test('maps http cookie errors before generic unauthorized guidance', () {
      final message = PanelErrorMessageResolver.resolve(
        PanelApiException.http(
          statusCode: 401,
          message: 'Set-Cookie missing',
        ),
      );

      expect(message, contains('Cookie'));
      expect(message, isNot(contains('认证失败')));
    });

    test('maps key auth errors to cookie guidance in account-password mode',
        () {
      final message = PanelErrorMessageResolver.resolve(
        const PanelApiException(
          '接口密钥错误',
          code: 'panel_response_error',
          statusCode: 401,
        ),
        authMode: PanelAuthMode.accountPassword,
      );

      expect(message, contains('Cookie'));
      expect(message, isNot(contains('API Key 无效')));
    });

    test('keeps key auth errors as api key guidance in api key mode', () {
      final message = PanelErrorMessageResolver.resolve(
        const PanelApiException(
          '接口密钥错误',
          code: 'panel_response_error',
          statusCode: 401,
        ),
        authMode: PanelAuthMode.apiKey,
      );

      expect(message, contains('API Key 无效'));
    });
  });
}
