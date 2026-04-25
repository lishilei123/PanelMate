import '../models/panel_api_exception.dart';
import '../models/panel_error_message_resolver.dart';
import '../models/server_connection_profile.dart';
import '../probe/panel_version_probe.dart';
import '../probe/panel_version_probe_result.dart';
import 'panel_api_session.dart';
import 'panel_live_overview_data.dart';
import 'panel_server_runtime_state.dart';

class PanelRuntimeService {
  const PanelRuntimeService();

  static const PanelApiSessionFactory _sessionFactory =
      PanelApiSessionFactory();

  Future<PanelServerRuntimeState> loadRuntime(
    PanelServerConnectionProfile server, {
    PanelLiveOverviewData? previousOverview,
  }) async {
    final session = await _sessionFactory.createSession(server);
    final bundle = session.bundle;

    final current = await bundle.overview.loadCurrent(
      ioOption: 'all',
      netOption: 'all',
    );

    return PanelServerRuntimeState.connected(
      PanelLiveOverviewData.fromMap(
        current,
        previous: previousOverview,
      ),
    );
  }

  Future<PanelVersionProbeResult> probeServer(
    PanelServerConnectionProfile server,
  ) async {
    String? errorMessage;
    var selectedOk = false;

    try {
      selectedOk = await _canConnect(server);
    } on PanelApiException catch (error) {
      errorMessage = PanelErrorMessageResolver.resolve(error);
    } catch (error) {
      errorMessage = PanelErrorMessageResolver.resolve(error);
    }

    return PanelVersionProbe.fromSelectedVersion(
      server.apiVersion,
      apiVersionMatched: selectedOk,
      mismatchHint: errorMessage,
    );
  }

  Future<bool> _canConnect(PanelServerConnectionProfile server) async {
    await loadRuntime(server);
    return true;
  }
}
