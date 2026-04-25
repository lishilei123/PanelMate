class PanelPagedPayload<T> {
  const PanelPagedPayload({
    required this.items,
    required this.total,
  });

  final List<T> items;
  final int total;

  bool get isEmpty => items.isEmpty;
}

class PanelContainerItem {
  const PanelContainerItem({
    required this.id,
    required this.name,
    required this.imageName,
    required this.state,
    required this.runTime,
    required this.createdAt,
    required this.networks,
    required this.ports,
    required this.isFromApp,
    required this.isFromCompose,
    required this.appName,
    required this.appInstallName,
    required this.isPinned,
    required this.description,
    this.cpuPercent,
    this.memoryPercent,
    this.memoryUsageBytes,
    this.memoryLimitBytes,
  });

  final String id;
  final String name;
  final String imageName;
  final String state;
  final String runTime;
  final DateTime? createdAt;
  final List<String> networks;
  final List<String> ports;
  final bool isFromApp;
  final bool isFromCompose;
  final String appName;
  final String appInstallName;
  final bool isPinned;
  final String description;
  final double? cpuPercent;
  final double? memoryPercent;
  final int? memoryUsageBytes;
  final int? memoryLimitBytes;

  factory PanelContainerItem.fromMap(
    Map<String, dynamic> json, {
    Map<String, dynamic>? stat,
  }) {
    return PanelContainerItem(
      id: _string(
        json['containerID'],
        fallback: _string(json['id'], fallback: _string(json['name'])),
      ),
      name: _string(json['name']),
      imageName: _string(json['imageName'], fallback: _string(json['image'])),
      state: _string(json['state']),
      runTime: _string(json['runTime']),
      createdAt: _dateTime(json['createTime'] ?? json['createdAt']),
      networks: _stringList(json['network']),
      ports: _stringList(json['ports']),
      isFromApp: _bool(json['isFromApp']),
      isFromCompose: _bool(json['isFromCompose']),
      appName: _string(json['appName']),
      appInstallName: _string(json['appInstallName']),
      isPinned: _bool(json['isPinned']),
      description: _string(json['description']),
      cpuPercent: _doubleOrNull(stat?['cpuPercent']),
      memoryPercent: _doubleOrNull(stat?['memoryPercent']),
      memoryUsageBytes: _intOrNull(stat?['memoryUsage']),
      memoryLimitBytes: _intOrNull(stat?['memoryLimit']),
    );
  }
}

class PanelContainerStat {
  const PanelContainerStat({
    required this.cpuPercent,
    required this.memoryMegabytes,
    required this.ioReadKilobytes,
    required this.ioWriteKilobytes,
    required this.networkRxKilobytes,
    required this.networkTxKilobytes,
    required this.shotTime,
  });

  final double cpuPercent;
  final double memoryMegabytes;
  final double ioReadKilobytes;
  final double ioWriteKilobytes;
  final double networkRxKilobytes;
  final double networkTxKilobytes;
  final DateTime? shotTime;

  factory PanelContainerStat.fromMap(Map<String, dynamic> json) {
    return PanelContainerStat(
      cpuPercent: _double(json['cpuPercent']),
      memoryMegabytes: _double(json['memory']),
      ioReadKilobytes: _double(json['ioRead']),
      ioWriteKilobytes: _double(json['ioWrite']),
      networkRxKilobytes: _double(json['networkRX']),
      networkTxKilobytes: _double(json['networkTX']),
      shotTime: _dateTime(json['shotTime']),
    );
  }
}

class PanelWebsiteItem {
  const PanelWebsiteItem({
    required this.id,
    required this.primaryDomain,
    required this.protocol,
    required this.type,
    required this.status,
    required this.alias,
    required this.remark,
    required this.sitePath,
    required this.appName,
    required this.runtimeName,
    required this.runtimeKind,
    required this.sslStatus,
    required this.favorite,
    required this.parentSite,
    required this.childSiteCount,
    required this.ipv6Enabled,
    required this.createdAt,
    required this.sslExpireDate,
  });

  final int id;
  final String primaryDomain;
  final String protocol;
  final String type;
  final String status;
  final String alias;
  final String remark;
  final String sitePath;
  final String appName;
  final String runtimeName;
  final String runtimeKind;
  final String sslStatus;
  final bool favorite;
  final String parentSite;
  final int childSiteCount;
  final bool ipv6Enabled;
  final DateTime? createdAt;
  final DateTime? sslExpireDate;

  factory PanelWebsiteItem.fromMap(Map<String, dynamic> json) {
    return PanelWebsiteItem(
      id: _int(json['id']),
      primaryDomain: _string(
        json['primaryDomain'],
        fallback: _string(json['domain']),
      ),
      protocol: _string(json['protocol']),
      type: _string(json['type']),
      status: _string(json['status']),
      alias: _string(json['alias']),
      remark: _string(json['remark']),
      sitePath: _string(json['sitePath']),
      appName: _string(json['appName']),
      runtimeName: _string(json['runtimeName']),
      runtimeKind: _string(json['runtimeType']),
      sslStatus: _string(json['sslStatus']),
      favorite: _bool(json['favorite']),
      parentSite: _string(json['parentSite']),
      childSiteCount: _mapList(json['childSites']).length,
      ipv6Enabled: _bool(json['IPV6'] ?? json['ipv6']),
      createdAt: _dateTime(json['createdAt']),
      sslExpireDate: _dateTime(json['sslExpireDate']),
    );
  }
}

class PanelAppItem {
  const PanelAppItem({
    required this.id,
    required this.name,
    required this.appName,
    required this.appKey,
    required this.version,
    required this.status,
    required this.message,
    required this.appType,
    required this.path,
    required this.httpPort,
    required this.httpsPort,
    required this.canUpdate,
    required this.container,
    required this.serviceName,
    required this.webUi,
    required this.websiteUrl,
    required this.documentUrl,
    required this.githubUrl,
    required this.favorite,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String appName;
  final String appKey;
  final String version;
  final String status;
  final String message;
  final String appType;
  final String path;
  final int? httpPort;
  final int? httpsPort;
  final bool canUpdate;
  final String container;
  final String serviceName;
  final String webUi;
  final String websiteUrl;
  final String documentUrl;
  final String githubUrl;
  final bool favorite;
  final DateTime? createdAt;

  factory PanelAppItem.fromMap(Map<String, dynamic> json) {
    return PanelAppItem(
      id: _int(json['id']),
      name: _string(json['name']),
      appName: _string(json['appName']),
      appKey: _string(json['appKey'], fallback: _string(json['key'])),
      version: _string(json['version']),
      status: _string(json['status']),
      message: _string(json['message']),
      appType: _string(json['appType']),
      path: _string(json['path']),
      httpPort: _intOrNull(json['httpPort']),
      httpsPort: _intOrNull(json['httpsPort']),
      canUpdate: _bool(json['canUpdate']),
      container: _string(json['container']),
      serviceName: _string(json['serviceName']),
      webUi: _string(json['webUI']),
      websiteUrl: _nestedString(json, const ['app', 'website']),
      documentUrl: _nestedString(json, const ['app', 'document']),
      githubUrl: _nestedString(json, const ['app', 'github']),
      favorite: _bool(json['favorite']),
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class PanelDatabaseItem {
  const PanelDatabaseItem({
    required this.id,
    required this.database,
    required this.name,
    required this.from,
  });

  final int id;
  final String database;
  final String name;
  final String from;

  factory PanelDatabaseItem.fromMap(Map<String, dynamic> json) {
    return PanelDatabaseItem(
      id: _int(json['id']),
      database: _string(json['database']),
      name: _string(json['name']),
      from: _string(json['from']),
    );
  }
}

class PanelFileDirectoryData {
  const PanelFileDirectoryData({
    required this.path,
    required this.name,
    required this.user,
    required this.group,
    required this.mode,
    required this.modTime,
    required this.itemTotal,
    required this.items,
  });

  final String path;
  final String name;
  final String user;
  final String group;
  final String mode;
  final DateTime? modTime;
  final int itemTotal;
  final List<PanelFileEntry> items;

  factory PanelFileDirectoryData.fromMap(Map<String, dynamic> json) {
    final items = _mapList(json['items'])
        .map(PanelFileEntry.fromMap)
        .toList(growable: false);

    return PanelFileDirectoryData(
      path: _string(json['path']),
      name: _string(json['name']),
      user: _string(json['user']),
      group: _string(json['group']),
      mode: _string(json['mode']),
      modTime: _dateTime(json['modTime']),
      itemTotal: _intOrNull(json['itemTotal']) ?? items.length,
      items: items,
    );
  }
}

class PanelFileEntry {
  const PanelFileEntry({
    required this.path,
    required this.name,
    required this.user,
    required this.group,
    required this.mode,
    required this.size,
    required this.isDir,
    required this.isHidden,
    required this.isSymlink,
    required this.extension,
    required this.modTime,
  });

  final String path;
  final String name;
  final String user;
  final String group;
  final String mode;
  final int size;
  final bool isDir;
  final bool isHidden;
  final bool isSymlink;
  final String extension;
  final DateTime? modTime;

  factory PanelFileEntry.fromMap(Map<String, dynamic> json) {
    return PanelFileEntry(
      path: _string(json['path']),
      name: _string(json['name']),
      user: _string(json['user']),
      group: _string(json['group']),
      mode: _string(json['mode']),
      size: _int(json['size']),
      isDir: _bool(json['isDir']),
      isHidden: _bool(json['isHidden']),
      isSymlink: _bool(json['isSymlink']),
      extension: _string(json['extension']),
      modTime: _dateTime(json['modTime']),
    );
  }
}

class PanelFileContentData {
  const PanelFileContentData({
    required this.path,
    required this.name,
    required this.content,
    required this.size,
    required this.modTime,
  });

  final String path;
  final String name;
  final String content;
  final int size;
  final DateTime? modTime;

  factory PanelFileContentData.fromMap(Map<String, dynamic> json) {
    return PanelFileContentData(
      path: _string(json['path']),
      name: _string(json['name']),
      content: _string(json['content']),
      size: _int(json['size']),
      modTime: _dateTime(json['modTime']),
    );
  }
}

class PanelBackupPageData {
  const PanelBackupPageData({
    required this.accounts,
    required this.records,
    required this.recordType,
    required this.recordWarning,
  });

  final PanelPagedPayload<PanelBackupAccountItem> accounts;
  final PanelPagedPayload<PanelBackupRecordItem> records;
  final String? recordType;
  final String? recordWarning;
}

class PanelBackupAccountItem {
  const PanelBackupAccountItem({
    required this.id,
    required this.name,
    required this.type,
    required this.isPublic,
    required this.bucket,
    required this.backupPath,
    required this.createdAt,
  });

  final int id;
  final String name;
  final String type;
  final bool isPublic;
  final String bucket;
  final String backupPath;
  final DateTime? createdAt;

  factory PanelBackupAccountItem.fromMap(Map<String, dynamic> json) {
    return PanelBackupAccountItem(
      id: _int(json['id']),
      name: _string(json['name']),
      type: _string(json['type']),
      isPublic: _bool(json['isPublic']),
      bucket: _string(json['bucket']),
      backupPath: _string(json['backupPath']),
      createdAt: _dateTime(json['createdAt']),
    );
  }
}

class PanelBackupRecordItem {
  const PanelBackupRecordItem({
    required this.id,
    required this.type,
    required this.name,
    required this.detailName,
    required this.fileName,
    required this.status,
    required this.message,
    required this.createdAt,
    required this.size,
  });

  final int id;
  final String type;
  final String name;
  final String detailName;
  final String fileName;
  final String status;
  final String message;
  final DateTime? createdAt;
  final int? size;

  factory PanelBackupRecordItem.fromMap(Map<String, dynamic> json) {
    return PanelBackupRecordItem(
      id: _int(json['id']),
      type: _string(json['type']),
      name: _string(json['name']),
      detailName: _string(json['detailName']),
      fileName: _string(json['fileName'], fallback: _string(json['file'])),
      status: _string(json['status']),
      message: _string(json['message']),
      createdAt: _dateTime(
        json['createdAt'] ?? json['updatedAt'] ?? json['startTime'],
      ),
      size: _intOrNull(json['size']),
    );
  }
}

String _string(Object? value, {String fallback = ''}) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty || text == 'null') {
    return fallback;
  }
  return text;
}

bool _bool(Object? value) {
  if (value is bool) {
    return value;
  }

  final text = value?.toString().trim().toLowerCase();
  return text == 'true' || text == '1' || text == 'yes';
}

int _int(Object? value) {
  return _intOrNull(value) ?? 0;
}

int? _intOrNull(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '');
}

double _double(Object? value) {
  return _doubleOrNull(value) ?? 0;
}

double? _doubleOrNull(Object? value) {
  if (value is double) {
    return value;
  }
  if (value is num) {
    return value.toDouble();
  }
  return double.tryParse(value?.toString() ?? '');
}

DateTime? _dateTime(Object? value) {
  final raw = value?.toString().trim();
  if (raw == null || raw.isEmpty || raw == '0001-01-01T00:00:00Z') {
    return null;
  }

  final parsed = DateTime.tryParse(raw);
  if (parsed != null) {
    return parsed;
  }

  final normalized = raw.replaceFirst(' ', 'T');
  return DateTime.tryParse(normalized);
}

List<String> _stringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value
      .map((item) => _string(item))
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _mapList(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return value
      .whereType<Map>()
      .map(
        (item) => item.map(
          (key, itemValue) => MapEntry(key.toString(), itemValue),
        ),
      )
      .toList(growable: false);
}

String _nestedString(
  Map<String, dynamic> json,
  List<String> path, {
  String fallback = '',
}) {
  Object? current = json;
  for (final segment in path) {
    if (current is Map<String, dynamic>) {
      current = current[segment];
      continue;
    }
    if (current is Map) {
      current = current[segment];
      continue;
    }
    return fallback;
  }

  return _string(current, fallback: fallback);
}
