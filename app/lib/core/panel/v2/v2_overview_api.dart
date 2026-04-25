import '../../network/panel_http_client.dart';
import '../contracts/panel_overview_api.dart';
import 'v2_paths.dart';

class V2OverviewApi implements PanelOverviewApi {
  V2OverviewApi(this._client);

  final PanelHttpClient _client;

  @override
  Future<Map<String, dynamic>> loadBase({
    String ioOption = 'all',
    String netOption = 'all',
  }) {
    final path = V2Paths.dashboardBase
        .replaceFirst(':ioOption', ioOption)
        .replaceFirst(':netOption', netOption);
    return _client.get(path);
  }

  @override
  Future<Map<String, dynamic>> loadCurrent({
    Map<String, dynamic>? body,
    String ioOption = 'all',
    String netOption = 'all',
  }) {
    final path = V2Paths.dashboardCurrent
        .replaceFirst(':ioOption', ioOption)
        .replaceFirst(':netOption', netOption);
    return _client.get(path);
  }
}
