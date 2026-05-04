import 'dart:convert';

import '../../network/panel_http_client.dart';
import '../contracts/panel_auth_api.dart';
import 'v2_paths.dart';

class V2AuthApi implements PanelAuthApi {
  V2AuthApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> loadSetting({
    String? entranceCode,
  }) {
    final headers = <String, String>{};
    if (entranceCode != null && entranceCode.isNotEmpty) {
      headers['EntranceCode'] = base64.encode(utf8.encode(entranceCode));
    }
    return _client.get(
      V2Paths.authSetting,
      headers: headers,
    );
  }

  @override
  Future<Map<String, dynamic>> loadCaptcha({
    String? entranceCode,
  }) {
    final headers = <String, String>{};
    if (entranceCode != null && entranceCode.isNotEmpty) {
      headers['EntranceCode'] = base64.encode(utf8.encode(entranceCode));
    }
    return _client.get(
      V2Paths.captcha,
      headers: headers,
    );
  }

  @override
  Future<Map<String, dynamic>> login(
    Map<String, dynamic> body, {
    String? entranceCode,
  }) {
    final headers = <String, String>{};
    if (entranceCode != null && entranceCode.isNotEmpty) {
      headers['EntranceCode'] = base64.encode(utf8.encode(entranceCode));
    }
    return _client.post(
      V2Paths.login,
      headers: headers,
      body: body,
    );
  }

  @override
  Future<Map<String, dynamic>> logout() {
    return _client.post(V2Paths.logout);
  }
}
