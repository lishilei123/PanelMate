class PanelSecuritySettings {
  const PanelSecuritySettings({
    required this.appLockEnabled,
    required this.backgroundBlurEnabled,
    required this.autoLockInterval,
  });

  final bool appLockEnabled;
  final bool backgroundBlurEnabled;
  final String autoLockInterval;

  PanelSecuritySettings copyWith({
    bool? appLockEnabled,
    bool? backgroundBlurEnabled,
    String? autoLockInterval,
  }) {
    return PanelSecuritySettings(
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      backgroundBlurEnabled:
          backgroundBlurEnabled ?? this.backgroundBlurEnabled,
      autoLockInterval: autoLockInterval ?? this.autoLockInterval,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is PanelSecuritySettings &&
        appLockEnabled == other.appLockEnabled &&
        backgroundBlurEnabled == other.backgroundBlurEnabled &&
        autoLockInterval == other.autoLockInterval;
  }

  @override
  int get hashCode =>
      Object.hash(appLockEnabled, backgroundBlurEnabled, autoLockInterval);
}
