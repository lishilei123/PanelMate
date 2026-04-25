import '../../network/panel_http_client.dart';
import '../contracts/panel_file_api.dart';
import 'v2_paths.dart';

class V2FileApi implements PanelFileApi {
  V2FileApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> loadFileContent(Map<String, dynamic> body) {
    return _client.post(V2Paths.filesContent, body: body);
  }

  @override
  Future<Map<String, dynamic>> readFileByLine(Map<String, dynamic> body) {
    return _client.post(V2Paths.filesRead, body: body);
  }

  @override
  Future<Map<String, dynamic>> searchFiles(Map<String, dynamic> body) {
    return _client.post(V2Paths.filesSearch, body: body);
  }
}
