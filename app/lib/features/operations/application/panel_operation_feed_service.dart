import '../../../core/panel/models/server_connection_profile.dart';
import '../../../core/panel/runtime/panel_api_session.dart';
import '../../../core/panel/v2/v2_paths.dart';

class PanelOperationFeedService {
  const PanelOperationFeedService({
    this.sessionFactory = const PanelApiSessionFactory(),
  });

  final PanelApiSessionFactory sessionFactory;

  Future<PanelOperationFeedResult> loadServerOperations(
    PanelServerConnectionProfile server, {
    int limit = 10,
  }) {
    return _withSession(server, (session) async {
      final payload = await session.client.post(
        V2Paths.operationLogsSearch,
        body: <String, dynamic>{
          'page': 1,
          'pageSize': limit,
        },
      );

      final items = _extractItems(payload)
          .asMap()
          .entries
          .map(
            (entry) => _mapOperationItem(
              entry.value,
              fallbackId: '${server.credentialStorageKey}|op|${entry.key}',
            ),
          )
          .toList()
        ..sort((left, right) => right.createdAt.compareTo(left.createdAt));

      return PanelOperationFeedResult(
        items: items,
        total: _extractTotal(payload, items.length),
      );
    });
  }

  Future<T> _withSession<T>(
    PanelServerConnectionProfile server,
    Future<T> Function(PanelApiSession session) loader,
  ) async {
    final session = await sessionFactory.createSession(server);
    return loader(session);
  }

  PanelOperationLogEntry _mapOperationItem(
    Map<String, dynamic> item, {
    required String fallbackId,
  }) {
    final detailZh = _string(item['detailZH']);
    final detailEn = _string(item['detailEN']);
    final message = _string(item['message']);
    final path = _string(item['path']);
    final method = _string(item['method']).toUpperCase();
    final source = _string(item['source']);
    final status = _string(item['status']);
    final ip = _string(item['ip']);
    final node = _string(item['node']);
    final userAgent = _string(item['userAgent']);
    final latency = _string(item['latency']);
    final createdAt = _parseDateTime(item['createdAt']);

    final title = _firstNonEmpty(
      <Object?>[
        detailZh,
        detailEn,
        message,
        if (method.isNotEmpty && path.isNotEmpty) '$method $path',
        path,
      ],
      fallback: '操作日志',
    );

    final subtitleParts = <String>[
      if (source.isNotEmpty) source,
      if (status.isNotEmpty) status,
      if (method.isNotEmpty) method,
      if (ip.isNotEmpty) ip,
    ];

    return PanelOperationLogEntry(
      id: _string(item['id']).isEmpty ? fallbackId : _string(item['id']),
      title: title,
      subtitle: subtitleParts.isEmpty ? '最近操作' : subtitleParts.join(' / '),
      source: source,
      status: status,
      method: method,
      path: path,
      ip: ip,
      node: node,
      detail: _firstNonEmpty(
        <Object?>[
          detailZh,
          detailEn,
          message,
        ],
        fallback: title,
      ),
      userAgent: userAgent,
      latency: latency,
      createdAt: createdAt,
    );
  }

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic> payload) {
    final directItems = payload['items'];
    if (directItems is List) {
      return _mapList(directItems);
    }

    final data = payload['data'];
    if (data is Map<String, dynamic>) {
      final nestedItems = data['items'];
      if (nestedItems is List) {
        return _mapList(nestedItems);
      }
    } else if (data is Map) {
      final mapped = data.map((key, value) => MapEntry(key.toString(), value));
      final nestedItems = mapped['items'];
      if (nestedItems is List) {
        return _mapList(nestedItems);
      }
    } else if (data is List) {
      return _mapList(data);
    }

    return const <Map<String, dynamic>>[];
  }

  List<Map<String, dynamic>> _mapList(List<dynamic> value) {
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

class PanelOperationFeedResult {
  const PanelOperationFeedResult({
    required this.items,
    required this.total,
  });

  final List<PanelOperationLogEntry> items;
  final int total;
}

class PanelOperationLogEntry {
  const PanelOperationLogEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.source,
    required this.status,
    required this.method,
    required this.path,
    required this.ip,
    required this.node,
    required this.detail,
    required this.userAgent,
    required this.latency,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String subtitle;
  final String source;
  final String status;
  final String method;
  final String path;
  final String ip;
  final String node;
  final String detail;
  final String userAgent;
  final String latency;
  final DateTime createdAt;
}

String _firstNonEmpty(
  List<Object?> values, {
  required String fallback,
}) {
  for (final value in values) {
    final resolved = _string(value);
    if (resolved.isNotEmpty) {
      return resolved;
    }
  }
  return fallback;
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
  return int.tryParse(_string(value));
}

DateTime _parseDateTime(Object? value) {
  final resolved = DateTime.tryParse(_string(value));
  return resolved?.toLocal() ?? DateTime.now();
}
