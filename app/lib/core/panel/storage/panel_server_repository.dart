import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/server_connection_profile.dart';
import 'panel_auth_data_store.dart';
import 'panel_credential_store.dart';

class PanelServerRepository {
  const PanelServerRepository({
    PanelCredentialStore credentialStore =
        const FlutterSecurePanelCredentialStore(),
  }) : _credentialStore = credentialStore;

  static const String storageKey = 'panelmate.saved_server_profiles.v2';
  static const String credentialKeyPrefix =
      'panelmate.saved_server_credentials.';

  final PanelCredentialStore _credentialStore;

  Future<List<PanelServerConnectionProfile>> loadServers() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(storageKey);
    if (raw == null || raw.trim().isEmpty) {
      return const <PanelServerConnectionProfile>[];
    }

    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Persisted server payload must be a list.');
    }

    final secureEntries = await _credentialStore.readAll();
    final servers = <PanelServerConnectionProfile>[];

    for (final item in decoded) {
      if (item is! Map) {
        continue;
      }

      try {
        final fullJson =
            item.map((key, value) => MapEntry(key.toString(), value));
        final profile = PanelServerConnectionProfile.fromJson(fullJson);
        final secureStorageKey = _credentialStorageKeyFor(profile);
        final secureRaw = secureEntries[secureStorageKey];
        final securePayload = secureRaw == null || secureRaw.trim().isEmpty
            ? null
            : decodeCredentialPayload(secureRaw);

        final merged = profile.mergeCredentials(securePayload);
        servers.add(merged);
      } on FormatException {
        // Skip malformed entries while keeping the rest of the list available.
      }
    }

    return servers;
  }

  Future<void> saveServers(List<PanelServerConnectionProfile> servers) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = jsonEncode(
      servers
          .map((server) => server.toBaseConfigJson())
          .toList(growable: false),
    );
    await preferences.setString(storageKey, raw);

    final liveKeys = <String>{};
    for (final server in servers) {
      final credentialKey = _credentialStorageKeyFor(server);
      final credentials = server.toCredentialJson()
        ..removeWhere(
          (_, value) => value == null || value.toString().trim().isEmpty,
        );
      if (credentials.isEmpty) {
        await _credentialStore.delete(credentialKey);
        continue;
      }
      liveKeys.add(credentialKey);
      await _credentialStore.write(credentialKey, jsonEncode(credentials));
    }

    final existingEntries = await _credentialStore.readAll();
    for (final key in existingEntries.keys) {
      if (!key.startsWith(credentialKeyPrefix) || liveKeys.contains(key)) {
        continue;
      }
      await _credentialStore.delete(key);
    }

    await PanelAuthDataStore(
      credentialStore: _credentialStore,
    ).deleteStaleForServers(servers);
  }

  String _credentialStorageKeyFor(PanelServerConnectionProfile server) {
    final encodedIdentity =
        base64Url.encode(utf8.encode(server.credentialStorageKey));
    return '$credentialKeyPrefix$encodedIdentity';
  }
}
