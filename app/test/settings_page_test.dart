import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/app/panel_gradient_theme.dart';
import 'package:panelmate/core/panel/models/panel_security_settings.dart';
import 'package:panelmate/core/panel/storage/panel_app_settings_repository.dart';
import 'package:panelmate/features/settings/presentation/settings_page.dart';

void main() {
  testWidgets('security switches call persistence callback', (tester) async {
    PanelSecuritySettings? savedSettings;
    var settings = const PanelSecuritySettings(
      appLockEnabled: true,
      backgroundBlurEnabled: true,
      autoLockInterval: '5m',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            servers: const [],
            resolveRuntime: (_) => null,
            pollingInterval: PanelAppSettingsRepository.defaultPollingInterval,
            onPollingIntervalChanged: (_) async {},
            gradientThemeId: PanelAppSettingsRepository.defaultGradientThemeId,
            gradientTheme: PanelGradientTheme.builtIns.first,
            customGradientTheme: PanelGradientTheme.custom(
              primary: const Color(0xFF168F8F),
              secondary: const Color(0xFF55A8D7),
              tertiary: const Color(0xFFFF9C6E),
            ),
            securitySettings: settings,
            onGradientThemeChanged: (_) async {},
            onCustomGradientThemeChanged: (_) async {},
            onSecuritySettingsChanged: (value) async {
              savedSettings = value;
              settings = value;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('settings.app_lock')));
    await tester.pump();

    expect(savedSettings?.appLockEnabled, isFalse);
  });

  testWidgets('auto lock interval sheet saves selected interval', (tester) async {
    PanelSecuritySettings? savedSettings;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SettingsPage(
            servers: const [],
            resolveRuntime: (_) => null,
            pollingInterval: PanelAppSettingsRepository.defaultPollingInterval,
            onPollingIntervalChanged: (_) async {},
            gradientThemeId: PanelAppSettingsRepository.defaultGradientThemeId,
            gradientTheme: PanelGradientTheme.builtIns.first,
            customGradientTheme: PanelGradientTheme.custom(
              primary: const Color(0xFF168F8F),
              secondary: const Color(0xFF55A8D7),
              tertiary: const Color(0xFFFF9C6E),
            ),
            securitySettings: const PanelSecuritySettings(
              appLockEnabled: true,
              backgroundBlurEnabled: true,
              autoLockInterval: '5m',
            ),
            onGradientThemeChanged: (_) async {},
            onCustomGradientThemeChanged: (_) async {},
            onSecuritySettingsChanged: (value) async {
              savedSettings = value;
            },
          ),
        ),
      ),
    );

    final intervalTile = find.byKey(
      const ValueKey('settings.auto_lock_interval'),
    );
    await tester.scrollUntilVisible(intervalTile, 280);
    await tester.pumpAndSettle();
    await tester.tap(intervalTile);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('settings.auto_lock_interval.15m')),
    );
    await tester.pumpAndSettle();

    expect(savedSettings?.autoLockInterval, '15m');
  });
}
