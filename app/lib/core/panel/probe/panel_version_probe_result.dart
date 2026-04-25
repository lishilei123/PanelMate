import '../models/api_version.dart';
import '../models/compatibility_flags.dart';

class PanelVersionProbeResult {
  const PanelVersionProbeResult({
    required this.selectedVersion,
    required this.apiVersionMatched,
    required this.compatibilityFlags,
    this.mismatchHint,
  });

  final PanelApiVersion selectedVersion;
  final bool apiVersionMatched;
  final PanelCompatibilityFlags compatibilityFlags;
  final String? mismatchHint;
}
