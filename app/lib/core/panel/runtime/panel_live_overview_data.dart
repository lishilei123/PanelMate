class PanelLiveProcessEntry {
  const PanelLiveProcessEntry({
    required this.pid,
    required this.name,
    required this.user,
    required this.command,
    required this.percent,
    required this.memoryBytes,
  });

  final int pid;
  final String name;
  final String user;
  final String command;
  final double percent;
  final int memoryBytes;

  factory PanelLiveProcessEntry.fromMap(Map<String, dynamic> json) {
    return PanelLiveProcessEntry(
      pid: PanelLiveOverviewData._toInt(json['pid']),
      name: json['name']?.toString() ?? '-',
      user: json['user']?.toString() ?? '-',
      command: json['cmd']?.toString() ?? '',
      percent: PanelLiveOverviewData._toDouble(json['percent']),
      memoryBytes: PanelLiveOverviewData._toInt(json['memory']),
    );
  }
}

class PanelLiveOverviewData {
  const PanelLiveOverviewData({
    required this.cpuUsedPercent,
    required this.memoryUsedPercent,
    required this.diskUsedPercent,
    required this.cpuTotal,
    required this.memoryTotal,
    required this.memoryUsed,
    required this.netBytesRecv,
    required this.netBytesSent,
    required this.load1,
    required this.load5,
    required this.load15,
    required this.uptime,
    required this.timeSinceUptime,
    required this.shotTime,
    required this.sampledAt,
    required this.netBytesRecvPerSecond,
    required this.netBytesSentPerSecond,
    required this.topCpuProcesses,
    required this.topMemoryProcesses,
    required this.raw,
  });

  final double cpuUsedPercent;
  final double memoryUsedPercent;
  final double diskUsedPercent;
  final int cpuTotal;
  final int memoryTotal;
  final int memoryUsed;
  final int netBytesRecv;
  final int netBytesSent;
  final double load1;
  final double load5;
  final double load15;
  final int uptime;
  final String timeSinceUptime;
  final DateTime? shotTime;
  final DateTime sampledAt;
  final double? netBytesRecvPerSecond;
  final double? netBytesSentPerSecond;
  final List<PanelLiveProcessEntry> topCpuProcesses;
  final List<PanelLiveProcessEntry> topMemoryProcesses;
  final Map<String, dynamic> raw;

  factory PanelLiveOverviewData.fromMap(
    Map<String, dynamic> json, {
    PanelLiveOverviewData? previous,
  }) {
    final diskData = (json['diskData'] is List)
        ? (json['diskData'] as List)
            .whereType<Map>()
            .map(
              (item) => item.map(
                (key, value) => MapEntry(key.toString(), value),
              ),
            )
            .toList(growable: false)
        : const <Map<String, dynamic>>[];
    final shotTime = DateTime.tryParse(json['shotTime']?.toString() ?? '');
    final sampledAt = shotTime ?? DateTime.now();
    final netBytesRecv = _toInt(json['netBytesRecv']);
    final netBytesSent = _toInt(json['netBytesSent']);

    final rootDisk = diskData.firstWhere(
      (item) => item['path'] == '/',
      orElse: () =>
          diskData.isNotEmpty ? diskData.first : const <String, dynamic>{},
    );

    return PanelLiveOverviewData(
      cpuUsedPercent: _normalizeApiPercent(json['cpuUsedPercent']),
      memoryUsedPercent: _normalizeApiPercent(json['memoryUsedPercent']),
      diskUsedPercent: _normalizeApiPercent(rootDisk['usedPercent']),
      cpuTotal: _toInt(json['cpuTotal']),
      memoryTotal: _toInt(json['memoryTotal']),
      memoryUsed: _toInt(json['memoryUsed']),
      netBytesRecv: netBytesRecv,
      netBytesSent: netBytesSent,
      load1: _toDouble(json['load1']),
      load5: _toDouble(json['load5']),
      load15: _toDouble(json['load15']),
      uptime: _toInt(json['uptime']),
      timeSinceUptime: json['timeSinceUptime']?.toString() ?? '',
      shotTime: shotTime,
      sampledAt: sampledAt,
      netBytesRecvPerSecond: _measureRate(
        currentBytes: netBytesRecv,
        previousBytes: previous?.netBytesRecv,
        currentTime: sampledAt,
        previousTime: previous?.sampledAt,
      ),
      netBytesSentPerSecond: _measureRate(
        currentBytes: netBytesSent,
        previousBytes: previous?.netBytesSent,
        currentTime: sampledAt,
        previousTime: previous?.sampledAt,
      ),
      topCpuProcesses: _toProcessList(json['topCPUItems']),
      topMemoryProcesses: _toProcessList(json['topMemItems']),
      raw: json,
    );
  }

  static double _normalizeApiPercent(Object? value) {
    final number = _toDouble(value);
    // 1Panel dashboard percent fields use a 0..100 scale, including values
    // below 1 such as 0.5 for 0.5%.
    return (number / 100).clamp(0.0, 1.0);
  }

  static double _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }

  static int _toInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static List<PanelLiveProcessEntry> _toProcessList(Object? value) {
    if (value is! List) {
      return const <PanelLiveProcessEntry>[];
    }

    return value
        .whereType<Map>()
        .map(
          (item) => item.map(
            (key, itemValue) => MapEntry(key.toString(), itemValue),
          ),
        )
        .map(PanelLiveProcessEntry.fromMap)
        .toList(growable: false);
  }

  static double? _measureRate({
    required int currentBytes,
    required int? previousBytes,
    required DateTime currentTime,
    required DateTime? previousTime,
  }) {
    if (previousBytes == null || previousTime == null) {
      return null;
    }

    final elapsedMilliseconds =
        currentTime.difference(previousTime).inMilliseconds;
    if (elapsedMilliseconds <= 0) {
      return null;
    }

    final delta = currentBytes - previousBytes;
    if (delta < 0) {
      return null;
    }

    return delta / (elapsedMilliseconds / 1000);
  }
}
