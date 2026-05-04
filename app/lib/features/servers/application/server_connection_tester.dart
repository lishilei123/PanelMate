import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/probe/panel_version_probe_result.dart';
import '../../../core/panel/runtime/panel_login_captcha.dart';
import '../../../core/panel/runtime/panel_runtime_service.dart';

class ServerConnectionTester {
  const ServerConnectionTester._();

  static const PanelRuntimeService _runtimeService = PanelRuntimeService();

  static Future<PanelVersionProbeResult> test(
    PanelServerConnectionProfile server, {
    PanelLoginCaptchaResolver? captchaResolver,
  }) {
    return _runtimeService.probeServer(
      server,
      captchaResolver: captchaResolver,
    );
  }
}
