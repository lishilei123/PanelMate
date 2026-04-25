import '../../network/panel_http_client.dart';
import '../contracts/panel_website_api.dart';
import 'v2_paths.dart';

class V2WebsiteApi implements PanelWebsiteApi {
  V2WebsiteApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> loadWebsiteLog(Map<String, dynamic> body) {
    return _client.post(V2Paths.websitesLog, body: body);
  }

  @override
  Future<Map<String, dynamic>> loadWebsiteSslByWebsiteId(String websiteId) {
    final path = V2Paths.websitesSslByWebsiteId.replaceFirst(
      ':websiteId',
      websiteId,
    );
    return _client.get(path);
  }

  @override
  Future<Map<String, dynamic>> operateWebsite(Map<String, dynamic> body) {
    return _client.post(V2Paths.websitesOperate, body: body);
  }

  @override
  Future<Map<String, dynamic>> searchWebsiteSsl(Map<String, dynamic> body) {
    return _client.post(V2Paths.websitesSslSearch, body: body);
  }

  @override
  Future<Map<String, dynamic>> searchWebsites(Map<String, dynamic> body) {
    return _client.post(V2Paths.websitesSearch, body: body);
  }
}
