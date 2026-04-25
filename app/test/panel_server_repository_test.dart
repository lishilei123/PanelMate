import 'package:flutter_test/flutter_test.dart';
import 'package:panelmate/core/panel/models/api_version.dart';
import 'package:panelmate/core/panel/models/compatibility_flags.dart';
import 'package:panelmate/core/panel/models/server_connection_profile.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PanelServerRepository', () {
    late _InMemoryCredentialStore credentialStore;
    late PanelServerRepository repository;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      credentialStore = _InMemoryCredentialStore();
      repository = PanelServerRepository(credentialStore: credentialStore);
    });

    test('saves and restores server profiles with credentials', () async {
      const server = PanelServerConnectionProfile(
        name: 'Seoul',
        baseUrl: 'panel.example.com',
        protocol: 'http',
        port: 8443,
        apiVersion: PanelApiVersion.v2,
        authMode: PanelAuthMode.apiKey,
        apiKey: 'raw-api-key',
        entranceCode: 'gate-code',
        remark: 'prod',
        tags: <String>['prod', 'kr'],
        certificateFingerprint: 'sha256:demo',
        compatibilityFlags: PanelCompatibilityFlags(
          useCoreAuth: true,
          useColonRouteParams: true,
          useDashboardCurrentGet: true,
          useContainerLogGet: true,
          requireEntranceCodeOnLogin: true,
        ),
      );

      await repository
          .saveServers(const <PanelServerConnectionProfile>[server]);

      final restored = await repository.loadServers();

      expect(restored, hasLength(1));
      expect(restored.first.name, server.name);
      expect(restored.first.baseUrl, server.baseUrl);
      expect(restored.first.protocol, server.protocol);
      expect(restored.first.port, server.port);
      expect(restored.first.apiVersion, server.apiVersion);
      expect(restored.first.authMode, server.authMode);
      expect(restored.first.apiKey, server.apiKey);
      expect(restored.first.entranceCode, server.entranceCode);
      expect(restored.first.remark, server.remark);
      expect(restored.first.tags, server.tags);
      expect(
        restored.first.compatibilityFlags?.requireEntranceCodeOnLogin,
        true,
      );

      final preferences = await SharedPreferences.getInstance();
      final rawBaseConfig =
          preferences.getString(PanelServerRepository.storageKey)!;
      expect(rawBaseConfig.contains('raw-api-key'), false);
      expect(rawBaseConfig.contains('gate-code'), false);

      final secureEntries = await credentialStore.readAll();
      expect(secureEntries.values.single.contains('raw-api-key'), true);
      expect(secureEntries.values.single.contains('gate-code'), true);
    });

    test('skips malformed stored records and keeps valid ones', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        PanelServerRepository.storageKey:
            '[{"name":"valid","baseUrl":"panel.example.com","protocol":"http","port":8443,"apiVersion":"v2","authMode":"apiKey","apiKey":"demo"}, {"name":"","broken":true}]',
      });
      repository = PanelServerRepository(credentialStore: credentialStore);

      final restored = await repository.loadServers();

      expect(restored, hasLength(1));
      expect(restored.first.name, 'valid');
      expect(restored.first.authMode, PanelAuthMode.apiKey);
      expect(restored.first.apiVersion, PanelApiVersion.v2);
      expect(restored.first.compatibilityFlags?.useCoreAuth, true);
      expect(restored.first.apiKey, isNull);
    });

    test('removes stale credentials for deleted servers', () async {
      const serverA = PanelServerConnectionProfile(
        name: 'A',
        baseUrl: 'a.example.com',
        protocol: 'http',
        port: 8443,
        apiVersion: PanelApiVersion.v2,
        authMode: PanelAuthMode.apiKey,
        apiKey: 'key-a',
      );
      const serverB = PanelServerConnectionProfile(
        name: 'B',
        baseUrl: 'b.example.com',
        protocol: 'http',
        port: 8443,
        apiVersion: PanelApiVersion.v2,
        authMode: PanelAuthMode.apiKey,
        apiKey: 'key-b',
      );

      await repository.saveServers(
        const <PanelServerConnectionProfile>[serverA, serverB],
      );
      await repository
          .saveServers(const <PanelServerConnectionProfile>[serverA]);

      final secureEntries = await credentialStore.readAll();
      expect(secureEntries.length, 1);
      expect(secureEntries.values.single.contains('key-a'), true);
      expect(secureEntries.values.single.contains('key-b'), false);
    });
  });
}
