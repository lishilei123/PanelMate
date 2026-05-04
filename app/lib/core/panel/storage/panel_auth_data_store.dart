import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../models/server_connection_profile.dart';
import 'panel_credential_store.dart';

class PanelAuthData {
  const PanelAuthData({
    this.token,
    this.cookieHeader,
    this.csrfToken,
    this.updatedAt,
  });

  final String? token;
  final String? cookieHeader;
  final String? csrfToken;
  final DateTime? updatedAt;

  bool get hasUsableCredentials =>
      (token != null && token!.trim().isNotEmpty) ||
      (cookieHeader != null && cookieHeader!.trim().isNotEmpty);
}

class PanelAuthDataStore {
  const PanelAuthDataStore({
    PanelCredentialStore credentialStore =
        const FlutterSecurePanelCredentialStore(),
    DateTime Function()? clock,
  })  : _credentialStore = credentialStore,
        _clock = clock;

  static const String storageKeyPrefix = 'panelmate.saved_server_auth.';

  final PanelCredentialStore _credentialStore;
  final DateTime Function()? _clock;

  Future<PanelAuthData?> read(PanelServerConnectionProfile server) async {
    final raw = await _credentialStore.read(storageKeyFor(server));
    if (raw == null || raw.trim().isEmpty) {
      return null;
    }

    try {
      final payload = decodeCredentialPayload(raw);
      final token = _nullableString(payload['token']);
      final cookieHeader = _nullableString(payload['cookieHeader']);
      final csrfToken = _nullableString(payload['csrfToken']);
      if (token == null && cookieHeader == null) {
        return null;
      }

      return PanelAuthData(
        token: token,
        cookieHeader: cookieHeader,
        csrfToken: csrfToken,
        updatedAt: DateTime.tryParse(
          _nullableString(payload['updatedAt']) ?? '',
        ),
      );
    } on FormatException {
      return null;
    }
  }

  Future<void> write(
    PanelServerConnectionProfile server,
    String token,
  ) async {
    await writeAuthData(server, PanelAuthData(token: token));
  }

  Future<void> writeSession(
    PanelServerConnectionProfile server, {
    required String cookieHeader,
    String? csrfToken,
  }) {
    return writeAuthData(
      server,
      PanelAuthData(
        cookieHeader: cookieHeader,
        csrfToken: csrfToken,
      ),
    );
  }

  Future<void> writeAuthData(
    PanelServerConnectionProfile server,
    PanelAuthData authData,
  ) async {
    final token = _nullableString(authData.token);
    final cookieHeader = _nullableString(authData.cookieHeader);
    final csrfToken = _nullableString(authData.csrfToken);
    if (token == null && cookieHeader == null) {
      await delete(server);
      return;
    }

    await _credentialStore.write(
      storageKeyFor(server),
      jsonEncode(
        <String, dynamic>{
          'token': token,
          'cookieHeader': cookieHeader,
          'csrfToken': csrfToken,
          'updatedAt': (_clock ?? DateTime.now)().toUtc().toIso8601String(),
        },
      ),
    );
  }

  Future<void> delete(PanelServerConnectionProfile server) {
    return _credentialStore.delete(storageKeyFor(server));
  }

  Future<void> deleteStaleForServers(
    List<PanelServerConnectionProfile> servers,
  ) async {
    final liveKeys = servers
        .where((server) => server.authMode == PanelAuthMode.accountPassword)
        .map(storageKeyFor)
        .toSet();
    final entries = await _credentialStore.readAll();

    for (final key in entries.keys) {
      if (!key.startsWith(storageKeyPrefix) || liveKeys.contains(key)) {
        continue;
      }
      await _credentialStore.delete(key);
    }
  }

  static String storageKeyFor(PanelServerConnectionProfile server) {
    final encodedIdentity =
        base64Url.encode(utf8.encode(server.credentialStorageKey));
    final credentialDigest = sha256.convert(
      utf8.encode(
        jsonEncode(
          <String>[
            server.authMode.value,
            server.username ?? '',
            server.password ?? '',
            server.entranceCode ?? '',
          ],
        ),
      ),
    );

    return '$storageKeyPrefix$encodedIdentity.$credentialDigest';
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }
}
