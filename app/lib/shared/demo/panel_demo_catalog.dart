import 'package:flutter/material.dart';

import '../../core/panel/models/server_connection_profile.dart';
import '../../core/panel/runtime/panel_live_overview_data.dart';
import '../../core/panel/runtime/panel_server_runtime_state.dart';

enum PanelServerHealth {
  healthy,
  warning,
  critical,
  offline,
}

extension PanelServerHealthX on PanelServerHealth {
  String get label => switch (this) {
        PanelServerHealth.healthy => '在线',
        PanelServerHealth.warning => '重点关注',
        PanelServerHealth.critical => '高风险',
        PanelServerHealth.offline => '离线',
      };

  int get priority => switch (this) {
        PanelServerHealth.healthy => 0,
        PanelServerHealth.warning => 1,
        PanelServerHealth.critical => 2,
        PanelServerHealth.offline => 3,
      };

  Color get color => switch (this) {
        PanelServerHealth.healthy => const Color(0xFF1D7D5A),
        PanelServerHealth.warning => const Color(0xFFD17F14),
        PanelServerHealth.critical => const Color(0xFFC44848),
        PanelServerHealth.offline => const Color(0xFF6C7484),
      };

  IconData get icon => switch (this) {
        PanelServerHealth.healthy => Icons.check_circle_outline,
        PanelServerHealth.warning => Icons.error_outline,
        PanelServerHealth.critical => Icons.warning_amber_rounded,
        PanelServerHealth.offline => Icons.portable_wifi_off,
      };
}

class PanelServerSnapshot {
  const PanelServerSnapshot({
    required this.server,
    required this.health,
    required this.isOnline,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkInText,
    required this.networkOutText,
    required this.loadText,
    required this.ipLabel,
    required this.lastSyncedAt,
    required this.uptimeText,
    required this.groupLabel,
  });

  final PanelServerConnectionProfile server;
  final PanelServerHealth health;
  final bool isOnline;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final String networkInText;
  final String networkOutText;
  final String loadText;
  final String ipLabel;
  final DateTime lastSyncedAt;
  final String uptimeText;
  final String groupLabel;
}

class PanelDemoCatalog {
  const PanelDemoCatalog._();

  static PanelServerSnapshot snapshotFor(
    PanelServerConnectionProfile server, {
    PanelServerRuntimeState? runtime,
  }) {
    if (runtime?.hasLiveData == true && runtime?.overview != null) {
      return _snapshotFromLiveData(
        server,
        runtime!.overview!,
        syncedAt: runtime.syncedAt,
      );
    }

    final seed = _seedFor(server);
    final isOnline = runtime?.hasError != true && seed % 10 != 0;
    final health = !isOnline
        ? PanelServerHealth.offline
        : seed % 7 == 0
            ? PanelServerHealth.critical
            : seed % 4 == 0
                ? PanelServerHealth.warning
                : PanelServerHealth.healthy;

    final cpuBase = 0.24 + (seed % 41) / 100;
    final memoryBase = 0.32 + ((seed ~/ 3) % 38) / 100;
    final diskBase = 0.41 + ((seed ~/ 5) % 34) / 100;

    final cpuUsage = _normalize(
      isOnline ? cpuBase + _healthLift(health, 0.22, 0.34) : 0.0,
    );
    final memoryUsage = _normalize(
      isOnline ? memoryBase + _healthLift(health, 0.16, 0.24) : 0.0,
    );
    final diskUsage = _normalize(
      isOnline ? diskBase + _healthLift(health, 0.08, 0.15) : 0.0,
    );

    final now = DateTime.now();
    final syncMinutes = !isOnline ? 30 + seed % 120 : 2 + seed % 18;

    return PanelServerSnapshot(
      server: server,
      health: health,
      isOnline: isOnline,
      cpuUsage: cpuUsage,
      memoryUsage: memoryUsage,
      diskUsage: diskUsage,
      networkInText: '${60 + seed % 220} KB/s',
      networkOutText: '${40 + (seed ~/ 7) % 180} KB/s',
      loadText: '${(0.5 + (seed % 22) / 10).toStringAsFixed(1)} / 4c',
      ipLabel: runtime?.hasError == true
          ? server.baseUrl
          : '10.${(seed % 180) + 10}.${((seed ~/ 11) % 180) + 10}.${((seed ~/ 19) % 180) + 10}',
      lastSyncedAt:
          runtime?.syncedAt ?? now.subtract(Duration(minutes: syncMinutes)),
      uptimeText: '${9 + seed % 46} 天',
      groupLabel: server.tags.isNotEmpty ? server.tags.first : 'V2 集群',
    );
  }

  static String percent(double value) => '${(value * 100).round()}%';

  static PanelServerSnapshot _snapshotFromLiveData(
    PanelServerConnectionProfile server,
    PanelLiveOverviewData overview, {
    DateTime? syncedAt,
  }) {
    final health = _healthFromLiveData(overview);

    return PanelServerSnapshot(
      server: server,
      health: health,
      isOnline: true,
      cpuUsage: overview.cpuUsedPercent,
      memoryUsage: overview.memoryUsedPercent,
      diskUsage: overview.diskUsedPercent,
      networkInText: _formatRate(overview.netBytesRecvPerSecond),
      networkOutText: _formatRate(overview.netBytesSentPerSecond),
      loadText: '${overview.load1.toStringAsFixed(1)} / ${overview.cpuTotal}c',
      ipLabel: server.baseUrl,
      lastSyncedAt: syncedAt ?? overview.shotTime ?? DateTime.now(),
      uptimeText: overview.timeSinceUptime.isNotEmpty
          ? overview.timeSinceUptime
          : '${overview.uptime}s',
      groupLabel: server.tags.isNotEmpty ? server.tags.first : 'V2 集群',
    );
  }

  static int _seedFor(PanelServerConnectionProfile server) {
    final raw =
        '${server.name}|${server.baseUrl}|${server.port}|${server.apiVersion.name}|${server.authMode.name}';
    var value = 17;
    for (final codeUnit in raw.codeUnits) {
      value = (value * 31 + codeUnit) % 100000;
    }
    return value;
  }

  static double _normalize(double value) => value.clamp(0.0, 0.98).toDouble();

  static double _healthLift(
    PanelServerHealth health,
    double warningLift,
    double criticalLift,
  ) {
    return switch (health) {
      PanelServerHealth.healthy => 0.0,
      PanelServerHealth.warning => warningLift,
      PanelServerHealth.critical => criticalLift,
      PanelServerHealth.offline => 0.0,
    };
  }

  static PanelServerHealth _healthFromLiveData(PanelLiveOverviewData overview) {
    if (overview.cpuUsedPercent >= 0.9 ||
        overview.memoryUsedPercent >= 0.9 ||
        overview.diskUsedPercent >= 0.92) {
      return PanelServerHealth.critical;
    }

    if (overview.cpuUsedPercent >= 0.7 ||
        overview.memoryUsedPercent >= 0.75 ||
        overview.diskUsedPercent >= 0.82) {
      return PanelServerHealth.warning;
    }

    return PanelServerHealth.healthy;
  }

  static String _formatRate(double? value) {
    if (value == null) {
      return '--';
    }

    const units = <String>['B/s', 'KB/s', 'MB/s', 'GB/s'];
    var current = value;
    var unitIndex = 0;
    while (current >= 1024 && unitIndex < units.length - 1) {
      current /= 1024;
      unitIndex++;
    }
    return '${current.toStringAsFixed(unitIndex == 0 ? 0 : 1)} ${units[unitIndex]}';
  }
}
