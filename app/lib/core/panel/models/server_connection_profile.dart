import 'api_version.dart';
import 'compatibility_flags.dart';

enum PanelAuthMode {
  accountPassword,
  apiKey,
}

PanelAuthMode panelAuthModeFromValue(String? value) {
  return switch (value?.trim()) {
    'accountPassword' => PanelAuthMode.accountPassword,
    'apiKey' => PanelAuthMode.apiKey,
    _ => PanelAuthMode.apiKey,
  };
}

extension PanelAuthModeX on PanelAuthMode {
  String get label => switch (this) {
        PanelAuthMode.accountPassword => '账号密码',
        PanelAuthMode.apiKey => 'API Key',
      };

  String get value => name;
}

class PanelServerConnectionProfile {
  const PanelServerConnectionProfile({
    required this.name,
    required this.baseUrl,
    required this.protocol,
    required this.port,
    required this.apiVersion,
    required this.authMode,
    this.username,
    this.password,
    this.apiKey,
    this.entranceCode,
    this.remark,
    this.tags = const <String>[],
    this.certificateFingerprint,
    this.compatibilityFlags,
  });

  final String name;
  final String baseUrl;
  final String protocol;
  final int port;
  final PanelApiVersion apiVersion;
  final PanelAuthMode authMode;
  final String? username;
  final String? password;
  final String? apiKey;
  final String? entranceCode;
  final String? remark;
  final List<String> tags;
  final String? certificateFingerprint;
  final PanelCompatibilityFlags? compatibilityFlags;

  String get endpointLabel => '$protocol://$baseUrl:$port';
  String get credentialStorageKey =>
      '${apiVersion.value}|$protocol|$baseUrl|$port|$name';

  factory PanelServerConnectionProfile.fromJson(Map<String, dynamic> json) {
    final apiVersion = panelApiVersionFromValue(json['apiVersion']?.toString());
    final port = _toInt(json['port']);
    final name = json['name']?.toString().trim() ?? '';
    final baseUrl = json['baseUrl']?.toString().trim() ?? '';
    final protocol = json['protocol']?.toString().trim() ?? '';

    if (name.isEmpty || baseUrl.isEmpty || protocol.isEmpty || port == null) {
      throw const FormatException('Invalid persisted server profile.');
    }

    return PanelServerConnectionProfile(
      name: name,
      baseUrl: baseUrl,
      protocol: protocol,
      port: port,
      apiVersion: apiVersion,
      authMode: panelAuthModeFromValue(json['authMode']?.toString()),
      username: _nullableString(json['username']),
      password: _nullableString(json['password']),
      apiKey: _nullableString(json['apiKey']),
      entranceCode: _nullableString(json['entranceCode']),
      remark: _nullableString(json['remark']),
      tags: _toStringList(json['tags']),
      certificateFingerprint: _nullableString(json['certificateFingerprint']),
      compatibilityFlags: PanelCompatibilityFlags.forVersion(apiVersion),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'baseUrl': baseUrl,
      'protocol': protocol,
      'port': port,
      'apiVersion': apiVersion.value,
      'authMode': authMode.value,
      'username': username,
      'password': password,
      'apiKey': apiKey,
      'entranceCode': entranceCode,
      'remark': remark,
      'tags': tags,
      'certificateFingerprint': certificateFingerprint,
      'compatibilityFlags': compatibilityFlags?.toJson() ??
          PanelCompatibilityFlags.forVersion(apiVersion).toJson(),
    };
  }

  Map<String, dynamic> toBaseConfigJson() {
    return <String, dynamic>{
      'name': name,
      'baseUrl': baseUrl,
      'protocol': protocol,
      'port': port,
      'apiVersion': apiVersion.value,
      'authMode': authMode.value,
      'remark': remark,
      'tags': tags,
      'certificateFingerprint': certificateFingerprint,
      'compatibilityFlags': compatibilityFlags?.toJson() ??
          PanelCompatibilityFlags.forVersion(apiVersion).toJson(),
    };
  }

  Map<String, dynamic> toCredentialJson() {
    return <String, dynamic>{
      'username': username,
      'password': password,
      'apiKey': apiKey,
      'entranceCode': entranceCode,
    };
  }

  PanelServerConnectionProfile mergeCredentials(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) {
      return PanelServerConnectionProfile(
        name: name,
        baseUrl: baseUrl,
        protocol: protocol,
        port: port,
        apiVersion: apiVersion,
        authMode: authMode,
        remark: remark,
        tags: tags,
        certificateFingerprint: certificateFingerprint,
        compatibilityFlags: compatibilityFlags,
      );
    }

    return copyWith(
      username: _nullableString(json['username']),
      password: _nullableString(json['password']),
      apiKey: _nullableString(json['apiKey']),
      entranceCode: _nullableString(json['entranceCode']),
    );
  }

  PanelServerConnectionProfile copyWith({
    String? name,
    String? baseUrl,
    String? protocol,
    int? port,
    PanelApiVersion? apiVersion,
    PanelAuthMode? authMode,
    String? username,
    String? password,
    String? apiKey,
    String? entranceCode,
    String? remark,
    List<String>? tags,
    String? certificateFingerprint,
    PanelCompatibilityFlags? compatibilityFlags,
  }) {
    return PanelServerConnectionProfile(
      name: name ?? this.name,
      baseUrl: baseUrl ?? this.baseUrl,
      protocol: protocol ?? this.protocol,
      port: port ?? this.port,
      apiVersion: apiVersion ?? this.apiVersion,
      authMode: authMode ?? this.authMode,
      username: username ?? this.username,
      password: password ?? this.password,
      apiKey: apiKey ?? this.apiKey,
      entranceCode: entranceCode ?? this.entranceCode,
      remark: remark ?? this.remark,
      tags: tags ?? this.tags,
      certificateFingerprint:
          certificateFingerprint ?? this.certificateFingerprint,
      compatibilityFlags: compatibilityFlags ?? this.compatibilityFlags,
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '');
  }

  static String? _nullableString(Object? value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') {
      return null;
    }
    return text;
  }

  static List<String> _toStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}
