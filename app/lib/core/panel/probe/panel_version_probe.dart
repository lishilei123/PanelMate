import '../models/api_version.dart';
import '../models/compatibility_flags.dart';
import 'panel_version_probe_result.dart';

class PanelVersionProbe {
  const PanelVersionProbe._();

  static PanelVersionProbeResult fromSelectedVersion(
    PanelApiVersion selectedVersion, {
    bool apiVersionMatched = true,
    String? mismatchHint,
  }) {
    return PanelVersionProbeResult(
      selectedVersion: selectedVersion,
      apiVersionMatched: apiVersionMatched,
      compatibilityFlags: PanelCompatibilityFlags.forVersion(selectedVersion),
      mismatchHint: mismatchHint,
    );
  }
}
