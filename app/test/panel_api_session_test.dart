import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:panelmate/core/panel/models/api_version.dart';
import 'package:panelmate/core/panel/models/panel_api_exception.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';
import 'package:panelmate/core/panel/runtime/panel_api_session.dart';
import 'package:panelmate/core/panel/storage/panel_auth_data_store.dart';
import 'package:panelmate/core/panel/storage/panel_credential_store.dart';

class _InMemoryCredentialStore implements PanelCredentialStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_values);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

void main() {
  group('PanelApiSessionFactory', () {
    late _InMemoryCredentialStore credentialStore;
    late PanelAuthDataStore authDataStore;

    setUp(() {
      credentialStore = _InMemoryCredentialStore();
      authDataStore = PanelAuthDataStore(credentialStore: credentialStore);
    });

    test('saves account-password login session cookies in secure storage',
        () async {
      var settingCount = 0;
      var loginCount = 0;
      Map<String, dynamic>? loginBody;
      String? settingEntranceCode;
      String? loginEntranceCode;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v2/core/auth/setting') {
          settingCount++;
          settingEntranceCode = request.headers['EntranceCode'];
          expect(request.headers['1Panel-Token'], isNull);
          expect(request.headers['1Panel-Timestamp'], isNull);
          return _panelResponse(
            <String, dynamic>{'needCaptcha': false},
            headers: _publicKeyCookieHeader,
          );
        }

        if (request.url.path == '/api/v2/core/auth/login') {
          loginCount++;
          loginEntranceCode = request.headers['EntranceCode'];
          expect(request.headers['1Panel-Token'], isNull);
          expect(request.headers['1Panel-Timestamp'], isNull);
          loginBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _panelResponse(
            <String, dynamic>{
              'name': 'admin',
              'token': '',
              'mfaStatus': '',
              'mfaSession': '',
            },
            headers: _sessionCookieHeader('session-a', 'csrf-a'),
          );
        }

        return _panelResponse(<String, dynamic>{'ok': true});
      });

      final factory = PanelApiSessionFactory(
        authDataStore: authDataStore,
        httpClient: mockClient,
      );

      await factory.createSession(_accountPasswordServer);

      final cachedAuthData = await authDataStore.read(_accountPasswordServer);
      final encryptedPassword = loginBody?['password']?.toString() ?? '';

      expect(settingCount, 1);
      expect(loginCount, 1);
      expect(settingEntranceCode, _encodedEntranceCode);
      expect(loginEntranceCode, _encodedEntranceCode);
      expect(loginBody?['authMethod'], 'session');
      expect(loginBody?['name'], 'admin');
      expect(encryptedPassword, isNot('secret'));
      expect(encryptedPassword.split(':'), hasLength(3));
      expect(cachedAuthData?.token, isNull);
      expect(cachedAuthData?.cookieHeader, contains('psession=session-a'));
      expect(cachedAuthData?.cookieHeader, contains('pcsrftoken=csrf-a'));
      expect(cachedAuthData?.csrfToken, 'csrf-a');
    });

    test('prompts for captcha when required and submits answer', () async {
      var captchaCount = 0;
      Map<String, dynamic>? loginBody;

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v2/core/auth/setting') {
          return _panelResponse(
            <String, dynamic>{'needCaptcha': true},
            headers: _publicKeyCookieHeader,
          );
        }

        if (request.url.path == '/api/v2/core/auth/captcha') {
          captchaCount++;
          expect(request.headers['EntranceCode'], _encodedEntranceCode);
          return _panelResponse(
            <String, dynamic>{
              'captchaID': 'captcha-a',
              'imagePath': 'data:image/png;base64,AAAA',
            },
          );
        }

        if (request.url.path == '/api/v2/core/auth/login') {
          loginBody = jsonDecode(request.body) as Map<String, dynamic>;
          return _panelResponse(
            <String, dynamic>{
              'name': 'admin',
              'token': '',
              'mfaStatus': '',
              'mfaSession': '',
            },
            headers: _sessionCookieHeader('session-a', 'csrf-a'),
          );
        }

        return _panelResponse(<String, dynamic>{'ok': true});
      });

      final factory = PanelApiSessionFactory(
        authDataStore: authDataStore,
        httpClient: mockClient,
        captchaResolver: (challenge) async {
          expect(challenge.captchaID, 'captcha-a');
          expect(challenge.imagePath, 'data:image/png;base64,AAAA');
          expect(challenge.attempt, 1);
          expect(challenge.errorMessage, isNull);
          return ' A1B2 ';
        },
      );

      await factory.createSession(_accountPasswordServer);

      expect(captchaCount, 1);
      expect(loginBody?['captcha'], 'A1B2');
      expect(loginBody?['captchaID'], 'captcha-a');
    });

    test('reloads captcha and retries when captcha is wrong', () async {
      final loginBodies = <Map<String, dynamic>>[];
      final captchaIds = <String>['captcha-a', 'captcha-b'];

      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v2/core/auth/setting') {
          return _panelResponse(
            <String, dynamic>{'needCaptcha': true},
            headers: _publicKeyCookieHeader,
          );
        }

        if (request.url.path == '/api/v2/core/auth/captcha') {
          final id = captchaIds.removeAt(0);
          return _panelResponse(
            <String, dynamic>{
              'captchaID': id,
              'imagePath': 'data:image/png;base64,AAAA',
            },
          );
        }

        if (request.url.path == '/api/v2/core/auth/login') {
          loginBodies.add(jsonDecode(request.body) as Map<String, dynamic>);
          if (loginBodies.length == 1) {
            return http.Response(
              jsonEncode(
                <String, dynamic>{
                  'code': 401,
                  'message': 'ErrCaptchaCode',
                  'data': null,
                },
              ),
              200,
              headers: <String, String>{'content-type': 'application/json'},
            );
          }

          return _panelResponse(
            <String, dynamic>{
              'name': 'admin',
              'token': '',
              'mfaStatus': '',
              'mfaSession': '',
            },
            headers: _sessionCookieHeader('session-b', 'csrf-b'),
          );
        }

        return _panelResponse(<String, dynamic>{'ok': true});
      });

      final factory = PanelApiSessionFactory(
        authDataStore: authDataStore,
        httpClient: mockClient,
        captchaResolver: (challenge) async {
          return switch (challenge.attempt) {
            1 => 'wrong',
            2 => () {
                expect(challenge.errorMessage, contains('验证码不正确'));
                return 'right';
              }(),
            _ => fail('unexpected captcha attempt ${challenge.attempt}'),
          };
        },
      );

      await factory.createSession(_accountPasswordServer);

      expect(loginBodies, hasLength(2));
      expect(loginBodies.first['captcha'], 'wrong');
      expect(loginBodies.first['captchaID'], 'captcha-a');
      expect(loginBodies.last['captcha'], 'right');
      expect(loginBodies.last['captchaID'], 'captcha-b');
    });

    test('throws explicit mfa_required when account requires MFA', () async {
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v2/core/auth/setting') {
          return _panelResponse(
            <String, dynamic>{'needCaptcha': false},
            headers: _publicKeyCookieHeader,
          );
        }

        if (request.url.path == '/api/v2/core/auth/login') {
          return _panelResponse(
            <String, dynamic>{
              'name': 'admin',
              'token': '',
              'mfaStatus': 'Enable',
              'mfaSession': 'mfa-a',
            },
            headers: _sessionCookieHeader('session-a', 'csrf-a'),
          );
        }

        return _panelResponse(<String, dynamic>{'ok': true});
      });

      final factory = PanelApiSessionFactory(
        authDataStore: authDataStore,
        httpClient: mockClient,
      );

      await expectLater(
        factory.createSession(_accountPasswordServer),
        throwsA(
          isA<PanelApiException>().having(
            (error) => error.code,
            'code',
            'mfa_required',
          ),
        ),
      );
    });

    test('uses cached account-password session without logging in again',
        () async {
      await authDataStore.writeSession(
        _accountPasswordServer,
        cookieHeader: 'psession=cached-session; pcsrftoken=cached-csrf',
        csrfToken: 'cached-csrf',
      );

      var loginCount = 0;
      String? capturedCookie;
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v2/core/auth/login') {
          loginCount++;
        }

        capturedCookie = request.headers['Cookie'];
        return _panelResponse(<String, dynamic>{'ok': true});
      });

      final factory = PanelApiSessionFactory(
        authDataStore: authDataStore,
        httpClient: mockClient,
      );

      final session = await factory.createSession(_accountPasswordServer);
      await session.client.get('/api/v2/dashboard/current/all/all');

      expect(loginCount, 0);
      expect(capturedCookie, contains('psession=cached-session'));
      expect(capturedCookie, contains('pcsrftoken=cached-csrf'));
    });

    test('refreshes invalid cached session and retries the request', () async {
      await authDataStore.writeSession(
        _accountPasswordServer,
        cookieHeader: 'psession=stale-session; pcsrftoken=stale-csrf',
        csrfToken: 'stale-csrf',
      );

      var settingCount = 0;
      var loginCount = 0;
      final dashboardCookies = <String?>[];
      final mockClient = MockClient((request) async {
        if (request.url.path == '/api/v2/core/auth/setting') {
          settingCount++;
          return _panelResponse(
            <String, dynamic>{'needCaptcha': false},
            headers: _publicKeyCookieHeader,
          );
        }

        if (request.url.path == '/api/v2/core/auth/login') {
          loginCount++;
          expect(request.headers['1Panel-Token'], isNull);
          return _panelResponse(
            <String, dynamic>{
              'name': 'admin',
              'token': '',
              'mfaStatus': '',
              'mfaSession': '',
            },
            headers: _sessionCookieHeader('fresh-session', 'fresh-csrf'),
          );
        }

        dashboardCookies.add(request.headers['Cookie']);
        if (dashboardCookies.length == 1) {
          return http.Response(
            jsonEncode(
              <String, dynamic>{
                'code': 401,
                'message': 'ErrNotLogin',
                'data': null,
              },
            ),
            200,
            headers: <String, String>{'content-type': 'application/json'},
          );
        }

        return _panelResponse(<String, dynamic>{'ok': true});
      });

      final factory = PanelApiSessionFactory(
        authDataStore: authDataStore,
        httpClient: mockClient,
      );

      final session = await factory.createSession(_accountPasswordServer);
      final result = await session.client.get(
        '/api/v2/dashboard/current/all/all',
      );

      final cachedAuthData = await authDataStore.read(_accountPasswordServer);
      expect(result['ok'], true);
      expect(settingCount, 1);
      expect(loginCount, 1);
      expect(dashboardCookies.first, contains('psession=stale-session'));
      expect(dashboardCookies.last, contains('psession=fresh-session'));
      expect(cachedAuthData?.cookieHeader, contains('psession=fresh-session'));
      expect(cachedAuthData?.csrfToken, 'fresh-csrf');
    });
  });
}

const _accountPasswordServer = PanelServerConnectionProfile(
  name: 'demo',
  baseUrl: 'panel.example.com',
  protocol: 'http',
  port: 8443,
  apiVersion: PanelApiVersion.v2,
  authMode: PanelAuthMode.accountPassword,
  username: 'admin',
  password: 'secret',
  entranceCode: 'entrance-code',
);

const _encodedEntranceCode = 'ZW50cmFuY2UtY29kZQ==';

const _panelPublicKeyCookie =
    'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUEwNmRPMHdDU2lhNjI4NDlWMVhCMQpzeTAyL3J3Ykl0eG5zM3QycGRFeEMzQTlyazRWYkc4V3lQK2NKeHNmRjFYRnVRY2FWT2ZrR2w4VkRGeThGcklJCi9Yb004dEtic1FRaE11ZjVIOXBiTTJxNTBXZ3lsR05ua3h6UHRIU1lHSnJMd3J4Um9DOEFhdUdPNWpGdkl5c24KeUltR3RwNDI4RnNJelJmdWVUZkNKVEtqaWxqSWlxd0dEY20xaVdncGsvYzJvMFFQL2F0YnNMdVhIQ1prU1BDVQphN0ZxMjlvUjNOR0k3amN5c3c5SXZYdUw2N1pqT3Bad1NHanRUMk51cWZ1QjllNlkydkpoRXhuV2F4cElhR01tCnp5MXd2WlVrUFBBbys2K0tmUmhjdUFZMVhjZDdwVnVSb2RKZlF2enVEeWlIQ0RVSWxpNG9GSjRqSW55Vmc3eWMKcndJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg%3D%3D';

const _publicKeyCookieHeader = <String, String>{
  'content-type': 'application/json',
  'set-cookie':
      'panel_public_key=$_panelPublicKeyCookie; Path=/; Max-Age=604800',
};

Map<String, String> _sessionCookieHeader(String session, String csrf) {
  return <String, String>{
    'content-type': 'application/json',
    'set-cookie':
        'psession=$session; Path=/; HttpOnly; Secure; SameSite=Lax, pcsrftoken=$csrf; Path=/; Secure; SameSite=Lax',
  };
}

http.Response _panelResponse(
  Map<String, dynamic> data, {
  Map<String, String>? headers,
}) {
  return http.Response(
    jsonEncode(
      <String, dynamic>{
        'code': 200,
        'message': '',
        'data': data,
      },
    ),
    200,
    headers:
        headers ?? const <String, String>{'content-type': 'application/json'},
  );
}
