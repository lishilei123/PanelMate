import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/app/panelmate_app.dart';
import 'package:panelmate/core/panel/storage/panel_app_settings_repository.dart';
import 'package:panelmate/core/panel/storage/panel_credential_store.dart';
import 'package:panelmate/core/panel/storage/panel_server_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _InMemoryCredentialStore implements PanelCredentialStore {
  final Map<String, String> _values = <String, String>{};

  @override
  Future<void> delete(String key) async {
    _values.remove(key);
  }

  @override
  Future<Map<String, String>> readAll() async {
    return Map<String, String>.from(_values);
  }

  @override
  Future<String?> read(String key) async {
    return _values[key];
  }

  @override
  Future<void> write(String key, String value) async {
    _values[key] = value;
  }
}

void main() {
  testWidgets('app boots into overview shell and exposes AI tab', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      PanelMateApp(
        repository: PanelServerRepository(
          credentialStore: _InMemoryCredentialStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('概览'), findsAtLeastNWidgets(1));
    expect(find.text('AI'), findsOneWidget);

    await tester.tap(find.text('AI'));
    await tester.pumpAndSettle();

    expect(find.text('AI 工作台'), findsOneWidget);
  });

  testWidgets('shows privacy overlay while app is backgrounded', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(
      PanelMateApp(
        repository: PanelServerRepository(
          credentialStore: _InMemoryCredentialStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    await tester.pump();

    expect(find.text('已隐藏敏感信息'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.text('已隐藏敏感信息'), findsNothing);
  });

  testWidgets('locks after the configured idle interval', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PanelAppSettingsRepository.autoLockIntervalStorageKey: '1m',
    });

    await tester.pumpWidget(
      PanelMateApp(
        repository: PanelServerRepository(
          credentialStore: _InMemoryCredentialStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 1));

    expect(find.text('PanelMate 已锁定'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('security_gate.continue')));
    await tester.pump();

    expect(find.text('PanelMate 已锁定'), findsNothing);
  });

  testWidgets('does not lock when auto lock is disabled', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      PanelAppSettingsRepository.autoLockIntervalStorageKey:
          PanelAppSettingsRepository.disabledAutoLockInterval,
    });

    await tester.pumpWidget(
      PanelMateApp(
        repository: PanelServerRepository(
          credentialStore: _InMemoryCredentialStore(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 30));

    expect(find.text('PanelMate 已锁定'), findsNothing);
  });
}
