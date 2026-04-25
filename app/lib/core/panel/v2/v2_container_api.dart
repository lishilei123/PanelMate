import '../../network/panel_http_client.dart';
import '../contracts/panel_container_api.dart';
import 'v2_paths.dart';

class V2ContainerApi implements PanelContainerApi {
  V2ContainerApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> loadContainerLogs({
    required String container,
    String? since,
    bool? follow,
    int? tail,
    int? timestamp,
  }) {
    return _client.get(
      V2Paths.containersLogs,
      queryParameters: <String, dynamic>{
        'container': container,
        if (since != null) 'since': since,
        if (follow != null) 'follow': follow,
        if (tail != null) 'tail': tail,
        if (timestamp != null) 'timestamp': timestamp,
      },
    );
  }

  @override
  Future<Map<String, dynamic>> loadContainerStat(String id) {
    final path = V2Paths.containersStats.replaceFirst(':id', id);
    return _client.get(path);
  }

  @override
  Future<Map<String, dynamic>> loadContainerStats() {
    return _client.get(V2Paths.containersListStats);
  }

  @override
  Future<Map<String, dynamic>> operateContainer(Map<String, dynamic> body) {
    return _client.post(V2Paths.containersOperate, body: body);
  }

  @override
  Future<Map<String, dynamic>> searchContainers(Map<String, dynamic> body) {
    return _client.post(V2Paths.containersSearch, body: body);
  }
}
