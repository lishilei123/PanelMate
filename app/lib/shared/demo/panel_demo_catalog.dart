import 'package:flutter/material.dart';

import '../../core/panel/models/server_connection_profile.dart';
import '../../core/panel/runtime/panel_live_overview_data.dart';
import '../../core/panel/runtime/panel_server_runtime_state.dart';
import '../formatters/panel_value_formatters.dart';

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
    required this.hasLiveData,
    required this.cpuUsage,
    required this.memoryUsage,
    required this.diskUsage,
    required this.networkInText,
    required this.networkOutText,
    required this.networkTotalInText,
    required this.networkTotalOutText,
    required this.loadText,
    required this.ipLabel,
    required this.lastSyncedAt,
    required this.uptimeText,
    required this.groupLabel,
  });

  final PanelServerConnectionProfile server;
  final PanelServerHealth health;
  final bool isOnline;
  final bool hasLiveData;
  final double cpuUsage;
  final double memoryUsage;
  final double diskUsage;
  final String networkInText;
  final String networkOutText;
  final String networkTotalInText;
  final String networkTotalOutText;
  final String loadText;
  final String ipLabel;
  final DateTime? lastSyncedAt;
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
        isOnline: runtime.hasError != true,
      );
    }

    return _emptySnapshot(server, runtime: runtime);
  }

  static String percent(double value) => '${(value * 100).round()}%';

  static PanelServerSnapshot _snapshotFromLiveData(
    PanelServerConnectionProfile server,
    PanelLiveOverviewData overview, {
    DateTime? syncedAt,
    bool isOnline = true,
  }) {
    final health =
        isOnline ? _healthFromLiveData(overview) : PanelServerHealth.offline;

    return PanelServerSnapshot(
      server: server,
      health: health,
      isOnline: isOnline,
      hasLiveData: true,
      cpuUsage: overview.cpuUsedPercent,
      memoryUsage: overview.memoryUsedPercent,
      diskUsage: overview.diskUsedPercent,
      networkInText: _formatRate(overview.netBytesRecvPerSecond),
      networkOutText: _formatRate(overview.netBytesSentPerSecond),
      networkTotalInText: PanelValueFormatters.bytes(overview.netBytesRecv),
      networkTotalOutText: PanelValueFormatters.bytes(overview.netBytesSent),
      loadText: '${overview.load1.toStringAsFixed(1)} / ${overview.cpuTotal}c',
      ipLabel: server.baseUrl,
      lastSyncedAt: syncedAt ?? overview.shotTime ?? overview.sampledAt,
      uptimeText: overview.timeSinceUptime.isNotEmpty
          ? overview.timeSinceUptime
          : '${overview.uptime}s',
      groupLabel: server.tags.isNotEmpty ? server.tags.first : '',
    );
  }

  static PanelServerSnapshot _emptySnapshot(
    PanelServerConnectionProfile server, {
    PanelServerRuntimeState? runtime,
  }) {
    return PanelServerSnapshot(
      server: server,
      health: PanelServerHealth.offline,
      isOnline: false,
      hasLiveData: false,
      cpuUsage: 0,
      memoryUsage: 0,
      diskUsage: 0,
      networkInText: '--',
      networkOutText: '--',
      networkTotalInText: '--',
      networkTotalOutText: '--',
      loadText: '--',
      ipLabel: server.baseUrl,
      lastSyncedAt: runtime?.syncedAt,
      uptimeText: '--',
      groupLabel: server.tags.isNotEmpty ? server.tags.first : '',
    );
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
