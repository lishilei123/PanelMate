import '../../network/panel_rest_http_client.dart';
import '../factory/panel_api_bundle.dart';
import '../factory/panel_api_factory.dart';
import '../models/panel_api_exception.dart';
import '../models/server_connection_profile.dart';

class PanelApiSession {
  const PanelApiSession({
    required this.client,
    required this.bundle,
  });

  final PanelRestHttpClient client;
  final PanelApiBundle bundle;
}

class PanelApiSessionFactory {
  const PanelApiSessionFactory();

  Future<PanelApiSession> createSession(
    PanelServerConnectionProfile server,
  ) async {
    final client = PanelRestHttpClient(server: server);
    final bundle = PanelApiFactory.create(server: server, httpClient: client);

    if (server.authMode == PanelAuthMode.accountPassword) {
      final token = await _loginAndResolveToken(bundle, server);
      client.setRuntimeToken(token);
    }

    return PanelApiSession(client: client, bundle: bundle);
  }

  Future<String> _loginAndResolveToken(
    PanelApiBundle bundle,
    PanelServerConnectionProfile server,
  ) async {
    final response = await bundle.auth.login(
      <String, dynamic>{
        'authMethod': 'jwt',
        'ignoreCaptcha': true,
        'language': 'zh',
        'name': server.username,
        'password': server.password,
      },
      entranceCode: server.entranceCode,
    );

    final token = response['token']?.toString();
    if (token == null || token.isEmpty) {
      throw const PanelApiException(
        'Login succeeded but no token was returned.',
        code: 'missing_login_token',
      );
    }

    return token;
  }
}
