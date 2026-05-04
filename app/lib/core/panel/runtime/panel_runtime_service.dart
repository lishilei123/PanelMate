import '../models/panel_api_exception.dart';
import '../models/panel_error_message_resolver.dart';
import '../models/server_connection_profile.dart';
import '../probe/panel_version_probe.dart';
import '../probe/panel_version_probe_result.dart';
import 'panel_api_session.dart';
import 'panel_live_overview_data.dart';
import 'panel_login_captcha.dart';
import 'panel_server_runtime_state.dart';

class PanelRuntimeService {
  const PanelRuntimeService();

  static const PanelApiSessionFactory _sessionFactory =
      PanelApiSessionFactory();

  Future<PanelServerRuntimeState> loadRuntime(
    PanelServerConnectionProfile server, {
    PanelLiveOverviewData? previousOverview,
    PanelLoginCaptchaResolver? captchaResolver,
  }) async {
    final sessionFactory = captchaResolver == null
        ? _sessionFactory
        : PanelApiSessionFactory(captchaResolver: captchaResolver);
    final session = await sessionFactory.createSession(server);
    try {
      final current = await session.bundle.overview.loadCurrent(
        ioOption: 'all',
        netOption: 'all',
      );
      return PanelServerRuntimeState.connected(
        PanelLiveOverviewData.fromMap(
          current,
          previous: previousOverview,
        ),
      );
    } finally {
      session.close();
    }
  }

  Future<PanelVersionProbeResult> probeServer(
    PanelServerConnectionProfile server, {
    PanelLoginCaptchaResolver? captchaResolver,
  }) async {
    String? errorMessage;
    var selectedOk = false;

    try {
      selectedOk = await _canConnect(
        server,
        captchaResolver: captchaResolver,
      );
    } on PanelApiException catch (error) {
      errorMessage = PanelErrorMessageResolver.resolve(
        error,
        authMode: server.authMode,
      );
    } catch (error) {
      errorMessage = PanelErrorMessageResolver.resolve(
        error,
        authMode: server.authMode,
      );
    }

    return PanelVersionProbe.fromSelectedVersion(
      server.apiVersion,
      apiVersionMatched: selectedOk,
      mismatchHint: errorMessage,
    );
  }

  Future<bool> _canConnect(
    PanelServerConnectionProfile server, {
    PanelLoginCaptchaResolver? captchaResolver,
  }) async {
    await loadRuntime(
      server,
      captchaResolver: captchaResolver,
    );
    return true;
  }
}
