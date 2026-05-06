import '../../../core/panel/models/panel_error_message_resolver.dart';
import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/runtime/panel_api_session.dart';
import '../models/panel_module_models.dart';

class PanelModuleService {
  const PanelModuleService({
    this.sessionFactory = const PanelApiSessionFactory(),
  });

  final PanelApiSessionFactory sessionFactory;

  Future<PanelPagedPayload<PanelContainerItem>> loadContainers(
    PanelServerConnectionProfile server,
  ) {
    return _withSession(server, (session) async {
      final futures = await Future.wait<
          Map<String, dynamic>>(<Future<Map<String, dynamic>>>[
        session.bundle.container.searchContainers(
          <String, dynamic>{
            'page': 1,
            'pageSize': 50,
            'order': 'descending',
            'orderBy': _createdOrderBy(),
            'state': 'all',
          },
        ),
        session.bundle.container.loadContainerStats(),
      ]);

      final searchPayload = futures[0];
      final statsPayload = futures[1];
      final statsById = <String, Map<String, dynamic>>{
        for (final stat in _extractList(statsPayload))
          _string(stat['containerID']): stat,
      };

      final items = _extractPageItems(searchPayload)
          .map(
            (item) => PanelContainerItem.fromMap(
              item,
              stat: statsById[_string(item['containerID'])],
            ),
          )
          .toList(growable: false);

      return PanelPagedPayload<PanelContainerItem>(
        items: items,
        total: _extractTotal(searchPayload, items.length),
      );
    });
  }

  Future<PanelContainerStat> loadContainerStat(
    PanelServerConnectionProfile server,
    String id,
  ) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.container.loadContainerStat(id);
      return PanelContainerStat.fromMap(payload);
    });
  }

  Future<PanelPagedPayload<PanelWebsiteItem>> loadWebsites(
    PanelServerConnectionProfile server,
  ) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.website.searchWebsites(
        <String, dynamic>{
          'page': 1,
          'pageSize': 50,
          'order': 'descending',
          'orderBy': _createdOrderBy(),
        },
      );

      final items = _extractPageItems(payload)
          .map(PanelWebsiteItem.fromMap)
          .toList(growable: false);

      return PanelPagedPayload<PanelWebsiteItem>(
        items: items,
        total: _extractTotal(payload, items.length),
      );
    });
  }

  Future<PanelPagedPayload<PanelAppItem>> loadApps(
    PanelServerConnectionProfile server,
  ) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.app.searchInstalledApps(
        <String, dynamic>{
          'page': 1,
          'pageSize': 50,
          'all': true,
          'sync': false,
        },
      );

      final items = _extractPageItems(payload)
          .map(PanelAppItem.fromMap)
          .toList(growable: false);

      return PanelPagedPayload<PanelAppItem>(
        items: items,
        total: _extractTotal(payload, items.length),
      );
    });
  }

  Future<PanelPagedPayload<PanelDatabaseItem>> loadDatabases(
    PanelServerConnectionProfile server,
  ) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.database.searchDatabases(
        <String, dynamic>{
          'database': 'all',
          'page': 1,
          'pageSize': 50,
          'order': 'descending',
          'orderBy': _createdOrderBy(),
        },
      );

      final items = _extractPageItems(payload)
          .map(PanelDatabaseItem.fromMap)
          .toList(growable: false);

      return PanelPagedPayload<PanelDatabaseItem>(
        items: items,
        total: _extractTotal(payload, items.length),
      );
    });
  }

  Future<PanelFileDirectoryData> loadDirectory(
    PanelServerConnectionProfile server, {
    required String path,
  }) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.file.searchFiles(
        <String, dynamic>{
          'path': path,
          'page': 1,
          'pageSize': 100,
          'containSub': false,
          'expand': true,
          'isDetail': true,
          'showHidden': false,
          'sortBy': 'name',
          'sortOrder': 'ascending',
        },
      );

      return PanelFileDirectoryData.fromMap(payload);
    });
  }

  Future<PanelFileContentData> loadFileContent(
    PanelServerConnectionProfile server, {
    required String path,
  }) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.file.loadFileContent(
        <String, dynamic>{
          'path': path,
          'isDetail': true,
        },
      );

      return PanelFileContentData.fromMap(payload);
    });
  }

  Future<void> operateWebsite(
    PanelServerConnectionProfile server, {
    required int websiteId,
    required String operation,
  }) {
    return _withSession(server, (session) async {
      await session.bundle.website.operateWebsite(<String, dynamic>{
        'id': websiteId,
        'operate': operation,
      });
    });
  }

  Future<PanelWebsiteLogResult> loadWebsiteLog(
    PanelServerConnectionProfile server, {
    required int websiteId,
    required String logType,
    int page = 1,
    int pageSize = 500,
  }) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.website.loadWebsiteLog(
        <String, dynamic>{
          'id': websiteId,
          'logType': logType,
          'operate': 'get',
          'page': page,
          'pageSize': pageSize,
        },
      );
      return PanelWebsiteLogResult.fromMap(payload);
    });
  }

  Future<void> operateContainer(
    PanelServerConnectionProfile server, {
    required String name,
    required String operation,
  }) {
    return _withSession(server, (session) async {
      await session.bundle.container.operateContainer(<String, dynamic>{
        'names': <String>[name],
        'operation': operation,
      });
    });
  }

  Future<String> loadContainerLog(
    PanelServerConnectionProfile server, {
    required String name,
    String? since,
    int? tail,
    bool? timestamp,
  }) {
    return _withSession(server, (session) async {
      final payload = await session.bundle.container.loadContainerLogs(
        container: name,
        since: since,
        tail: tail,
        timestamp: timestamp == true ? 1 : null,
      );
      return _extractLogContent(payload);
    });
  }

  String _extractLogContent(Map<String, dynamic> payload) {
    final data = payload['data'];
    if (data is String) {
      return data;
    }
    if (data is Map) {
      final logs = data['logs'] ?? data['log'] ?? data['content'];
      if (logs is String) return logs;
    }
    final direct = payload['logs'] ?? payload['log'] ?? payload['content'];
    if (direct is String) return direct;
    return '';
  }

  Future<void> operateApp(
    PanelServerConnectionProfile server, {
    required int installId,
    required String operate,
  }) {
    return _withSession(server, (session) async {
      await session.bundle.app.operateInstalledApp(<String, dynamic>{
        'installId': installId,
        'operate': operate,
      });
    });
  }

  Future<PanelBackupPageData> loadBackups(
    PanelServerConnectionProfile server, {
    String? preferredType,
  }) {
    return _withSession(server, (session) async {
      final accounts = await _loadBackupAccounts(session);
      if (accounts.items.isEmpty) {
        return const PanelBackupPageData(
          accounts: PanelPagedPayload<PanelBackupAccountItem>(
            items: <PanelBackupAccountItem>[],
            total: 0,
          ),
          records: PanelPagedPayload<PanelBackupRecordItem>(
            items: <PanelBackupRecordItem>[],
            total: 0,
          ),
          recordType: null,
          recordWarning: null,
        );
      }

      final selectedType = preferredType?.trim().isNotEmpty == true
          ? preferredType!.trim()
          : accounts.items.first.type;

      try {
        final records = await _loadBackupRecords(
          session,
          type: selectedType,
        );

        return PanelBackupPageData(
          accounts: accounts,
          records: records,
          recordType: selectedType,
          recordWarning: null,
        );
      } catch (error) {
        return PanelBackupPageData(
          accounts: accounts,
          records: const PanelPagedPayload<PanelBackupRecordItem>(
            items: <PanelBackupRecordItem>[],
            total: 0,
          ),
          recordType: selectedType,
          recordWarning: PanelErrorMessageResolver.resolve(error),
        );
      }
    });
  }

  Future<PanelPagedPayload<PanelBackupAccountItem>> _loadBackupAccounts(
    PanelApiSession session,
  ) async {
    final payload = await session.bundle.backup.searchBackupAccounts(
      body: <String, dynamic>{
        'page': 1,
        'pageSize': 50,
      },
    );

    final items = _extractPageItems(payload, allowDirectList: true)
        .map(PanelBackupAccountItem.fromMap)
        .toList(growable: false);

    return PanelPagedPayload<PanelBackupAccountItem>(
      items: items,
      total: _extractTotal(payload, items.length),
    );
  }

  Future<PanelPagedPayload<PanelBackupRecordItem>> _loadBackupRecords(
    PanelApiSession session, {
    required String type,
  }) async {
    final payload = await session.bundle.backup.searchBackupRecords(
      <String, dynamic>{
        'page': 1,
        'pageSize': 20,
        'type': type,
      },
    );

    final items = _extractPageItems(payload)
        .map(PanelBackupRecordItem.fromMap)
        .toList(growable: false);

    return PanelPagedPayload<PanelBackupRecordItem>(
      items: items,
      total: _extractTotal(payload, items.length),
    );
  }

  Future<T> _withSession<T>(
    PanelServerConnectionProfile server,
    Future<T> Function(PanelApiSession session) loader,
  ) async {
    final session = await sessionFactory.createSession(server);
    try {
      return await loader(session);
    } finally {
      session.close();
    }
  }

  String _createdOrderBy() {
    return 'createdAt';
  }

  List<Map<String, dynamic>> _extractPageItems(
    Map<String, dynamic> payload, {
    bool allowDirectList = false,
  }) {
    final direct = payload['items'];
    if (direct is List) {
      return _extractList(<String, dynamic>{'data': direct});
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return _extractList(data);
    }
    if (data is Map) {
      return _extractList(
        data.map((key, value) => MapEntry(key.toString(), value)),
      );
    }

    if (allowDirectList && data is List) {
      return _extractList(<String, dynamic>{'data': data});
    }

    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _extractList(Map<String, dynamic> payload) {
    final value = payload['items'] ?? payload['data'];
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

  int _extractTotal(Map<String, dynamic> payload, int fallbackCount) {
    final directTotal = _intOrNull(payload['total']);
    if (directTotal != null) {
      return directTotal;
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      return _intOrNull(data['total']) ?? fallbackCount;
    }
    if (data is Map) {
      return _intOrNull(data['total']) ?? fallbackCount;
    }
    if (data is List) {
      return data.length;
    }

    return fallbackCount;
  }
}

String _string(Object? value) {
  return value?.toString().trim() ?? '';
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
