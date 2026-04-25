import '../../network/panel_http_client.dart';
import '../contracts/panel_database_api.dart';
import 'v2_paths.dart';

class V2DatabaseApi implements PanelDatabaseApi {
  V2DatabaseApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> loadDatabaseStatus(Map<String, dynamic> body) {
    return _client.post(V2Paths.databasesStatus, body: body);
  }

  @override
  Future<Map<String, dynamic>> searchDatabases(Map<String, dynamic> body) {
    return _client.post(V2Paths.databasesSearch, body: body);
  }
}
