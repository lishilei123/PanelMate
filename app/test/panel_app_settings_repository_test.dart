import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/storage/panel_app_settings_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PanelAppSettingsRepository', () {
    const repository = PanelAppSettingsRepository();

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    test('returns 10s by default when nothing is stored', () async {
      expect(
        await repository.loadPollingInterval(),
        PanelAppSettingsRepository.defaultPollingInterval,
      );
    });

    test('saves and restores a supported polling interval', () async {
      await repository.savePollingInterval('10s');

      expect(await repository.loadPollingInterval(), '10s');
    });

    test('returns default gradient theme when nothing is stored', () async {
      expect(
        await repository.loadGradientThemeId(),
        PanelAppSettingsRepository.defaultGradientThemeId,
      );
    });

    test('saves and restores a supported gradient theme', () async {
      await repository.saveGradientThemeId('custom');

      expect(await repository.loadGradientThemeId(), 'custom');
    });

    test('saves and restores custom gradient colors', () async {
      const colors = PanelCustomGradientThemeColors(
        primaryValue: 0xFF2563EB,
        secondaryValue: 0xFF14B8A6,
        tertiaryValue: 0xFFFF8A5C,
      );

      await repository.saveCustomGradientThemeColors(colors);

      final restored = await repository.loadCustomGradientThemeColors();
      expect(restored.primaryValue, colors.primaryValue);
      expect(restored.secondaryValue, colors.secondaryValue);
      expect(restored.tertiaryValue, colors.tertiaryValue);
    });

    test('normalizes invalid persisted value back to default', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PanelAppSettingsRepository.pollingIntervalStorageKey: '7s',
        PanelAppSettingsRepository.gradientThemeStorageKey: 'unknown',
      });

      expect(
        await repository.loadPollingInterval(),
        PanelAppSettingsRepository.defaultPollingInterval,
      );
      expect(
        await repository.loadGradientThemeId(),
        PanelAppSettingsRepository.defaultGradientThemeId,
      );

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          PanelAppSettingsRepository.pollingIntervalStorageKey,
        ),
        PanelAppSettingsRepository.defaultPollingInterval,
      );
      expect(
        preferences.getString(
          PanelAppSettingsRepository.gradientThemeStorageKey,
        ),
        PanelAppSettingsRepository.defaultGradientThemeId,
      );
    });

    test('maps the disabled option to no auto refresh duration', () {
      expect(
        PanelAppSettingsRepository.durationForPollingInterval('关闭'),
        isNull,
      );
      expect(
        PanelAppSettingsRepository.durationForPollingInterval('15s'),
        const Duration(seconds: 15),
      );
    });

    test('returns default security settings when nothing is stored', () async {
      final settings = await repository.loadSecuritySettings();

      expect(settings.appLockEnabled, isTrue);
      expect(settings.backgroundBlurEnabled, isTrue);
      expect(
        settings.autoLockInterval,
        PanelAppSettingsRepository.defaultAutoLockInterval,
      );
    });

    test('saves and restores security settings', () async {
      const settings = PanelSecuritySettings(
        appLockEnabled: false,
        backgroundBlurEnabled: false,
        autoLockInterval: '15m',
      );

      await repository.saveSecuritySettings(settings);

      final restored = await repository.loadSecuritySettings();
      expect(restored.appLockEnabled, isFalse);
      expect(restored.backgroundBlurEnabled, isFalse);
      expect(restored.autoLockInterval, '15m');
    });

    test('normalizes invalid auto lock interval back to default', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PanelAppSettingsRepository.autoLockIntervalStorageKey: '7m',
      });

      final settings = await repository.loadSecuritySettings();

      expect(
        settings.autoLockInterval,
        PanelAppSettingsRepository.defaultAutoLockInterval,
      );

      final preferences = await SharedPreferences.getInstance();
      expect(
        preferences.getString(
          PanelAppSettingsRepository.autoLockIntervalStorageKey,
        ),
        PanelAppSettingsRepository.defaultAutoLockInterval,
      );
    });

    test('maps auto lock intervals to durations', () {
      expect(
        PanelAppSettingsRepository.durationForAutoLockInterval('关闭'),
        isNull,
      );
      expect(
        PanelAppSettingsRepository.durationForAutoLockInterval('1m'),
        const Duration(minutes: 1),
      );
      expect(
        PanelAppSettingsRepository.durationForAutoLockInterval('5m'),
        const Duration(minutes: 5),
      );
      expect(
        PanelAppSettingsRepository.durationForAutoLockInterval('15m'),
        const Duration(minutes: 15),
      );
      expect(
        PanelAppSettingsRepository.durationForAutoLockInterval('30m'),
        const Duration(minutes: 30),
      );
    });
  });
}
