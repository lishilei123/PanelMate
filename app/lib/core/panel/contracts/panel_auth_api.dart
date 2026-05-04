abstract class PanelAuthApi {
  Future<Map<String, dynamic>> loadSetting({
    String? entranceCode,
  });

  Future<Map<String, dynamic>> loadCaptcha({
    String? entranceCode,
  });

  Future<Map<String, dynamic>> login(
    Map<String, dynamic> body, {
    String? entranceCode,
  });

  Future<Map<String, dynamic>> logout();
}
