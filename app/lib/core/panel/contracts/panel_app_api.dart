abstract class PanelAppApi {
  Future<Map<String, dynamic>> searchInstalledApps(Map<String, dynamic> body);

  Future<Map<String, dynamic>> operateInstalledApp(Map<String, dynamic> body);
}
