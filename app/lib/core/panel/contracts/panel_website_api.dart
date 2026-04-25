abstract class PanelWebsiteApi {
  Future<Map<String, dynamic>> searchWebsites(Map<String, dynamic> body);

  Future<Map<String, dynamic>> operateWebsite(Map<String, dynamic> body);

  Future<Map<String, dynamic>> loadWebsiteLog(Map<String, dynamic> body);

  Future<Map<String, dynamic>> searchWebsiteSsl(Map<String, dynamic> body);

  Future<Map<String, dynamic>> loadWebsiteSslByWebsiteId(String websiteId);
}
