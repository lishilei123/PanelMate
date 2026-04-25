import 'api_version.dart';

class PanelCompatibilityFlags {
  const PanelCompatibilityFlags({
    required this.useCoreAuth,
    required this.useColonRouteParams,
    required this.useDashboardCurrentGet,
    required this.useContainerLogGet,
    required this.requireEntranceCodeOnLogin,
  });

  final bool useCoreAuth;
  final bool useColonRouteParams;
  final bool useDashboardCurrentGet;
  final bool useContainerLogGet;
  final bool requireEntranceCodeOnLogin;

  factory PanelCompatibilityFlags.forVersion(PanelApiVersion version) {
    return const PanelCompatibilityFlags(
      useCoreAuth: true,
      useColonRouteParams: true,
      useDashboardCurrentGet: true,
      useContainerLogGet: true,
      requireEntranceCodeOnLogin: true,
    );
  }

  factory PanelCompatibilityFlags.fromJson(Map<String, dynamic> json) {
    return PanelCompatibilityFlags(
      useCoreAuth: _toBool(json['useCoreAuth'], fallback: true),
      useColonRouteParams: _toBool(
        json['useColonRouteParams'],
        fallback: true,
      ),
      useDashboardCurrentGet: _toBool(
        json['useDashboardCurrentGet'],
        fallback: true,
      ),
      useContainerLogGet: _toBool(json['useContainerLogGet'], fallback: true),
      requireEntranceCodeOnLogin: _toBool(
        json['requireEntranceCodeOnLogin'],
        fallback: true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'useCoreAuth': useCoreAuth,
      'useColonRouteParams': useColonRouteParams,
      'useDashboardCurrentGet': useDashboardCurrentGet,
      'useContainerLogGet': useContainerLogGet,
      'requireEntranceCodeOnLogin': requireEntranceCodeOnLogin,
    };
  }

  static bool _toBool(Object? value, {required bool fallback}) {
    if (value == null) {
      return fallback;
    }
    if (value is bool) {
      return value;
    }
    if (value is num) {
      return value != 0;
    }
    final normalized = value.toString().trim().toLowerCase();
    return normalized == 'true' || normalized == '1';
  }
}
