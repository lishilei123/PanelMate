import 'package:http/http.dart' as http;

import '../../network/panel_rest_http_client.dart';
import '../factory/panel_api_bundle.dart';
import '../factory/panel_api_factory.dart';
import '../models/panel_api_exception.dart';
import '../models/server_connection_profile.dart';
import '../storage/panel_auth_data_store.dart';
import '../v2/panel_login_password_encryptor.dart';
import 'panel_login_captcha.dart';

class PanelApiSession {
  const PanelApiSession({
    required this.client,
    required this.bundle,
  });

  final PanelRestHttpClient client;
  final PanelApiBundle bundle;

  void close() {
    client.close();
  }
}

class PanelApiSessionFactory {
  const PanelApiSessionFactory({
    PanelAuthDataStore authDataStore = const PanelAuthDataStore(),
    http.Client? httpClient,
    PanelLoginCaptchaResolver? captchaResolver,
  })  : _authDataStore = authDataStore,
        _captchaResolver = captchaResolver,
        _httpClient = httpClient;

  final PanelAuthDataStore _authDataStore;
  final http.Client? _httpClient;
  final PanelLoginCaptchaResolver? _captchaResolver;

  Future<PanelApiSession> createSession(
    PanelServerConnectionProfile server,
  ) async {
    final client = PanelRestHttpClient(
      server: server,
      client: _httpClient,
    );
    final bundle = PanelApiFactory.create(server: server, httpClient: client);

    if (server.authMode == PanelAuthMode.accountPassword) {
      Future<void> loginAndCacheAuthData() async {
        await _authDataStore.delete(server);
        final authData = await _loginAndResolveAuthData(
          client,
          bundle,
          server,
        );
        await _authDataStore.writeAuthData(server, authData);
        _applyAuthData(client, authData);
      }

      client.setRuntimeAuthRefresher(loginAndCacheAuthData);

      final cachedAuthData = await _authDataStore.read(server);
      if (cachedAuthData == null || !cachedAuthData.hasUsableCredentials) {
        await loginAndCacheAuthData();
      } else {
        _applyAuthData(client, cachedAuthData);
      }
    }

    return PanelApiSession(client: client, bundle: bundle);
  }

  Future<PanelAuthData> _loginAndResolveAuthData(
    PanelRestHttpClient client,
    PanelApiBundle bundle,
    PanelServerConnectionProfile server,
  ) async {
    final username = server.username?.trim();
    final password = server.password;
    if (username == null || username.isEmpty || password == null) {
      throw const PanelApiException(
        'Account-password login requires both username and password.',
        code: 'missing_account_password_credentials',
      );
    }

    client.clearRuntimeCredentials();
    final setting = await bundle.auth.loadSetting(
      entranceCode: server.entranceCode,
    );
    final publicKeyCookie = client.cookieValue('panel_public_key');
    if (publicKeyCookie == null || publicKeyCookie.isEmpty) {
      throw const PanelApiException(
        'Login setting did not provide panel_public_key.',
        code: 'missing_panel_public_key',
      );
    }
    var captchaAnswer = setting['needCaptcha'] == true
        ? await _resolveCaptchaAnswer(
            bundle,
            server,
            attempt: 1,
          )
        : null;

    final encryptedPassword = PanelLoginPasswordEncryptor.encryptPassword(
      password,
      panelPublicKeyCookie: publicKeyCookie,
    );
    Map<String, dynamic>? response;

    for (var attempt = 1; attempt <= 3; attempt++) {
      try {
        response = await bundle.auth.login(
          <String, dynamic>{
            'authMethod': 'session',
            'captcha': captchaAnswer?.captcha ?? '',
            'captchaID': captchaAnswer?.captchaID ?? '',
            'language': 'zh',
            'name': username,
            'password': encryptedPassword,
          },
          entranceCode: server.entranceCode,
        );
        break;
      } on PanelApiException catch (error) {
        if (!_isCaptchaError(error) || attempt >= 3) {
          rethrow;
        }
        captchaAnswer = await _resolveCaptchaAnswer(
          bundle,
          server,
          attempt: attempt + 1,
          errorMessage: '验证码不正确，请重新输入。',
        );
      }
    }

    if (response == null) {
      throw const PanelApiException(
        'Captcha verification did not complete.',
        code: 'captcha_cancelled',
      );
    }

    if (response['mfaStatus']?.toString() == 'Enable') {
      throw const PanelApiException(
        'This account requires MFA verification.',
        code: 'mfa_required',
      );
    }

    final cookieHeader = client.cookieHeader;
    final token = response['token']?.toString();
    if ((cookieHeader == null || cookieHeader.isEmpty) &&
        (token == null || token.isEmpty)) {
      throw const PanelApiException(
        'Login succeeded but no session cookie or token was returned.',
        code: 'missing_login_session',
      );
    }

    return PanelAuthData(
      token: token == null || token.isEmpty ? null : token,
      cookieHeader: cookieHeader,
      csrfToken: client.csrfToken,
    );
  }

  void _applyAuthData(PanelRestHttpClient client, PanelAuthData authData) {
    final cookieHeader = authData.cookieHeader?.trim();
    if (cookieHeader != null && cookieHeader.isNotEmpty) {
      client.setRuntimeCookies(cookieHeader);
      return;
    }
    client.setRuntimeToken(authData.token);
  }

  Future<PanelLoginCaptchaAnswer> _resolveCaptchaAnswer(
    PanelApiBundle bundle,
    PanelServerConnectionProfile server, {
    required int attempt,
    String? errorMessage,
  }) async {
    final resolver = _captchaResolver;
    if (resolver == null) {
      throw const PanelApiException(
        'This panel requires captcha verification before password login.',
        code: 'captcha_required',
      );
    }

    final captcha = await bundle.auth.loadCaptcha(
      entranceCode: server.entranceCode,
    );
    final captchaID = _nullableString(captcha['captchaID']);
    final imagePath = _nullableString(captcha['imagePath']);
    if (captchaID == null || imagePath == null) {
      throw const PanelApiException(
        'Captcha endpoint did not return captchaID or imagePath.',
        code: 'captcha_load_failed',
      );
    }

    final input = await resolver(
      PanelLoginCaptchaChallenge(
        captchaID: captchaID,
        imagePath: imagePath,
        attempt: attempt,
        errorMessage: errorMessage,
      ),
    );
    final normalizedInput = input?.trim();
    if (normalizedInput == null || normalizedInput.isEmpty) {
      throw const PanelApiException(
        'Captcha input was cancelled.',
        code: 'captcha_cancelled',
      );
    }

    return PanelLoginCaptchaAnswer(
      captchaID: captchaID,
      captcha: normalizedInput,
    );
  }

  bool _isCaptchaError(PanelApiException error) {
    return error.code == 'panel_response_error' &&
        error.message.trim() == 'ErrCaptchaCode';
  }

  String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }
}
