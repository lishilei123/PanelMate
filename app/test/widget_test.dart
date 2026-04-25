import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/app/panelmate_app.dart';
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
}
