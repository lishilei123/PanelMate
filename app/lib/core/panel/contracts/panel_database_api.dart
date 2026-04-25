abstract class PanelDatabaseApi {
  Future<Map<String, dynamic>> searchDatabases(Map<String, dynamic> body);

  Future<Map<String, dynamic>> loadDatabaseStatus(Map<String, dynamic> body);
}
