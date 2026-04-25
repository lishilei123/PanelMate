abstract class PanelContainerApi {
  Future<Map<String, dynamic>> searchContainers(Map<String, dynamic> body);

  Future<Map<String, dynamic>> operateContainer(Map<String, dynamic> body);

  Future<Map<String, dynamic>> loadContainerLogs({
    required String container,
    String? since,
    bool? follow,
    int? tail,
    int? timestamp,
  });

  Future<Map<String, dynamic>> loadContainerStats();

  Future<Map<String, dynamic>> loadContainerStat(String id);
}
