import '../../network/panel_http_client.dart';
import '../contracts/panel_app_api.dart';
import 'v2_paths.dart';

class V2AppApi implements PanelAppApi {
  V2AppApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> operateInstalledApp(Map<String, dynamic> body) {
    return _client.post(V2Paths.appsInstalledOp, body: body);
  }

  @override
  Future<Map<String, dynamic>> searchInstalledApps(Map<String, dynamic> body) {
    return _client.post(V2Paths.appsInstalledSearch, body: body);
  }
}
