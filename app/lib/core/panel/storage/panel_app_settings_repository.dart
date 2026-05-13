import 'package:shared_preferences/shared_preferences.dart';

class PanelAppSettingsRepository {
  const PanelAppSettingsRepository();

  static const String pollingIntervalStorageKey =
      'panelmate.app_settings.polling_interval';
  static const String gradientThemeStorageKey =
      'panelmate.app_settings.gradient_theme';
  static const String customGradientPrimaryStorageKey =
      'panelmate.app_settings.custom_gradient.primary';
  static const String customGradientSecondaryStorageKey =
      'panelmate.app_settings.custom_gradient.secondary';
  static const String customGradientTertiaryStorageKey =
      'panelmate.app_settings.custom_gradient.tertiary';
  static const String appLockEnabledStorageKey =
      'panelmate.app_settings.security.app_lock_enabled';
  static const String backgroundBlurEnabledStorageKey =
      'panelmate.app_settings.security.background_blur_enabled';
  static const String autoLockIntervalStorageKey =
      'panelmate.app_settings.security.auto_lock_interval';
  static const String defaultPollingInterval = '10s';
  static const String defaultGradientThemeId = 'mint';
  static const int defaultCustomGradientPrimaryValue = 0xFF168F8F;
  static const int defaultCustomGradientSecondaryValue = 0xFF55A8D7;
  static const int defaultCustomGradientTertiaryValue = 0xFFFF9C6E;
  static const bool defaultAppLockEnabled = true;
  static const bool defaultBackgroundBlurEnabled = true;
  static const String defaultAutoLockInterval = '5m';
  static const String disabledPollingInterval = '关闭';
  static const String disabledAutoLockInterval = '关闭';
  static const List<String> supportedPollingIntervals = <String>[
    '1s',
    '5s',
    '10s',
    '15s',
    disabledPollingInterval,
  ];
  static const List<String> supportedAutoLockIntervals = <String>[
    disabledAutoLockInterval,
    '1m',
    defaultAutoLockInterval,
    '15m',
    '30m',
  ];
  static const List<String> supportedGradientThemeIds = <String>[
    defaultGradientThemeId,
    'ocean',
    'garden',
    'dawn',
    'custom',
  ];

  Future<String> loadPollingInterval() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(pollingIntervalStorageKey);
    final normalizedValue = normalizePollingInterval(storedValue);
    if (storedValue != normalizedValue) {
      await preferences.setString(pollingIntervalStorageKey, normalizedValue);
    }
    return normalizedValue;
  }

  Future<void> savePollingInterval(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      pollingIntervalStorageKey,
      normalizePollingInterval(value),
    );
  }

  Future<String> loadGradientThemeId() async {
    final preferences = await SharedPreferences.getInstance();
    final storedValue = preferences.getString(gradientThemeStorageKey);
    final normalizedValue = normalizeGradientThemeId(storedValue);
    if (storedValue != normalizedValue) {
      await preferences.setString(gradientThemeStorageKey, normalizedValue);
    }
    return normalizedValue;
  }

  Future<void> saveGradientThemeId(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      gradientThemeStorageKey,
      normalizeGradientThemeId(value),
    );
  }

  Future<PanelCustomGradientThemeColors> loadCustomGradientThemeColors() async {
    final preferences = await SharedPreferences.getInstance();
    final colors = PanelCustomGradientThemeColors(
      primaryValue: normalizeColorValue(
        preferences.getInt(customGradientPrimaryStorageKey),
        defaultCustomGradientPrimaryValue,
      ),
      secondaryValue: normalizeColorValue(
        preferences.getInt(customGradientSecondaryStorageKey),
        defaultCustomGradientSecondaryValue,
      ),
      tertiaryValue: normalizeColorValue(
        preferences.getInt(customGradientTertiaryStorageKey),
        defaultCustomGradientTertiaryValue,
      ),
    );

    await preferences.setInt(
      customGradientPrimaryStorageKey,
      colors.primaryValue,
    );
    await preferences.setInt(
      customGradientSecondaryStorageKey,
      colors.secondaryValue,
    );
    await preferences.setInt(
      customGradientTertiaryStorageKey,
      colors.tertiaryValue,
    );

    return colors;
  }

  Future<void> saveCustomGradientThemeColors(
    PanelCustomGradientThemeColors colors,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(
      customGradientPrimaryStorageKey,
      normalizeColorValue(
        colors.primaryValue,
        defaultCustomGradientPrimaryValue,
      ),
    );
    await preferences.setInt(
      customGradientSecondaryStorageKey,
      normalizeColorValue(
        colors.secondaryValue,
        defaultCustomGradientSecondaryValue,
      ),
    );
    await preferences.setInt(
      customGradientTertiaryStorageKey,
      normalizeColorValue(
        colors.tertiaryValue,
        defaultCustomGradientTertiaryValue,
      ),
    );
  }

  Future<PanelSecuritySettings> loadSecuritySettings() async {
    final preferences = await SharedPreferences.getInstance();
    final appLockEnabled = preferences.getBool(appLockEnabledStorageKey) ??
        defaultAppLockEnabled;
    final backgroundBlurEnabled =
        preferences.getBool(backgroundBlurEnabledStorageKey) ??
            defaultBackgroundBlurEnabled;
    final storedAutoLockInterval =
        preferences.getString(autoLockIntervalStorageKey);
    final autoLockInterval = normalizeAutoLockInterval(storedAutoLockInterval);

    await preferences.setBool(appLockEnabledStorageKey, appLockEnabled);
    await preferences.setBool(
      backgroundBlurEnabledStorageKey,
      backgroundBlurEnabled,
    );
    if (storedAutoLockInterval != autoLockInterval) {
      await preferences.setString(autoLockIntervalStorageKey, autoLockInterval);
    }

    return PanelSecuritySettings(
      appLockEnabled: appLockEnabled,
      backgroundBlurEnabled: backgroundBlurEnabled,
      autoLockInterval: autoLockInterval,
    );
  }

  Future<void> saveSecuritySettings(PanelSecuritySettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(
      appLockEnabledStorageKey,
      settings.appLockEnabled,
    );
    await preferences.setBool(
      backgroundBlurEnabledStorageKey,
      settings.backgroundBlurEnabled,
    );
    await preferences.setString(
      autoLockIntervalStorageKey,
      normalizeAutoLockInterval(settings.autoLockInterval),
    );
  }

  static String normalizePollingInterval(String? value) {
    if (supportedPollingIntervals.contains(value)) {
      return value!;
    }
    return defaultPollingInterval;
  }

  static String normalizeAutoLockInterval(String? value) {
    if (supportedAutoLockIntervals.contains(value)) {
      return value!;
    }
    return defaultAutoLockInterval;
  }

  static String normalizeGradientThemeId(String? value) {
    if (supportedGradientThemeIds.contains(value)) {
      return value!;
    }
    return defaultGradientThemeId;
  }

  static int normalizeColorValue(int? value, int fallback) {
    if (value == null || value < 0 || value > 0xFFFFFFFF) {
      return fallback;
    }
    return value | 0xFF000000;
  }

  static Duration? durationForPollingInterval(String? value) {
    switch (normalizePollingInterval(value)) {
      case '1s':
        return const Duration(seconds: 1);
      case '5s':
        return const Duration(seconds: 5);
      case '10s':
        return const Duration(seconds: 10);
      case '15s':
        return const Duration(seconds: 15);
      case disabledPollingInterval:
        return null;
      default:
        return const Duration(seconds: 10);
    }
  }

  static Duration? durationForAutoLockInterval(String? value) {
    switch (normalizeAutoLockInterval(value)) {
      case disabledAutoLockInterval:
        return null;
      case '1m':
        return const Duration(minutes: 1);
      case '5m':
        return const Duration(minutes: 5);
      case '15m':
        return const Duration(minutes: 15);
      case '30m':
        return const Duration(minutes: 30);
      default:
        return const Duration(minutes: 5);
    }
  }
}

class PanelCustomGradientThemeColors {
  const PanelCustomGradientThemeColors({
    required this.primaryValue,
    required this.secondaryValue,
    required this.tertiaryValue,
  });

  final int primaryValue;
  final int secondaryValue;
  final int tertiaryValue;
}

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
}
