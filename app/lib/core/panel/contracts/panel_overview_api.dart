abstract class PanelOverviewApi {
  Future<Map<String, dynamic>> loadCurrent({
    Map<String, dynamic>? body,
    String ioOption = 'all',
    String netOption = 'all',
  });

  Future<Map<String, dynamic>> loadBase({
    String ioOption = 'all',
    String netOption = 'all',
  });
}
